# frozen_string_literal: true

module FlowcommerceSpree
  # responds to webhook events from flow.io
  class WebhookService
    attr_accessor :errors
    alias full_messages errors

    def self.process(data, opts = {})
      new(data, opts).process
    end

    def initialize(data, opts = {})
      @data = data
      @opts = opts
      @errors = []
    end

    def process
      hook_method = @data['discriminator']
      # If hook processing method registered an error, a self.object of WebhookService with this error will be
      # returned, else an ActiveRecord object will be returned
      return __send__(hook_method) if respond_to?(hook_method, true)

      errors << { message: "No hook for #{hook_method}" }
      self
    end

    private

    def capture_upserted_v2
      errors << { message: 'Capture param missing' } && (return self) unless (capture = @data['capture'])

      order_number = capture.dig('authorization', 'order', 'number')
      if (order = Spree::Order.find_by(number: order_number))
        order.flow_data['captures'] ||= []
        order_captures = order.flow_data['captures']
        order_captures.delete_if { |c| c['id'] == capture['id'] }
        order_captures << capture
        attrs_to_update = update_order_native_attrs(order)
        order.update_columns(attrs_to_update)
        upsert_captures(order)
        order
      else
        errors << { message: "Order #{order_number} not found" }
        self
      end
    end

    def card_authorization_upserted_v2
      errors << { message: 'Authorization param missing' } && (return self) unless (card_auth = @data['authorization'])

      errors << { message: 'Card param missing' } && (return self) unless (flow_io_card = card_auth.delete('card'))

      if (order_number = card_auth.dig('order', 'number'))
        if (order = Spree::Order.find_by(number: order_number))
          flow_io_card_expiration = flow_io_card.delete('expiration')

          card = Spree::CreditCard.find_or_initialize_by(month: flow_io_card_expiration['month'].to_s,
                                                         year: flow_io_card_expiration['year'].to_s,
                                                         cc_type: flow_io_card.delete('type'),
                                                         last_digits: flow_io_card.delete('last4'),
                                                         name: flow_io_card.delete('name'),
                                                         user_id: order.user.id)
          card.flow_data ||= {}
          card.flow_data.merge!(flow_io_card.except('discriminator')) if card.new_record?
          card.push_authorization(card_auth.except('discriminator'))
          if card.new_record?
            card.imported = true
            card.save!
          else
            card.update_column(:meta, card.meta.to_json)
          end

          return card
        else
          errors << { message: "Order #{order_number} not found" }
        end
      else
        errors << { message: 'Order number param missing' }
      end

      self
    end

    def experience_upserted_v2
      experience = @data['experience']
      Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
    end

    def fraud_status_changed
      if (order_number = @data.dig('order', 'number'))
        if @data['status'] == 'declined'
          if (order = Spree::Order.find_by(number: order_number))
            order.update_columns(fraudulent: true)
            order.cancel!
            return order
          else
            errors << { message: "Order #{order_number} not found" }
          end
        end
      else
        errors << { message: 'Order number param missing' }
      end

      self
    end

    def local_item_upserted
      errors << { message: 'Local item param missing' } && (return self) unless (local_item = @data['local_item'])

      errors << { message: 'SKU param missing' } && (return self) unless (flow_sku = local_item.dig('item', 'number'))

      if (variant = Spree::Variant.find_by(sku: flow_sku))
        variant.add_flow_io_experience_data(
          local_item.dig('experience', 'key'),
          'prices' => [local_item.dig('pricing', 'price')], 'status' => local_item['status']
        )

        variant.update_column(:meta, variant.meta.to_json)
        return variant
      else
        errors << { message: "Variant with sku [#{flow_sku}] not found!" }
      end

      self
    end

    def order_placed_v2
      errors << { message: 'Order placed param missing' } && (return self) unless (order_placed = @data['order_placed'])

      errors << { message: 'Order param missing' } && (return self) unless (flow_order = order_placed['order'])

      errors << { message: 'Order number param missing' } && (return self) unless (order_number = flow_order['number'])

      if (order = Spree::Order.find_by(number: order_number))
        order.flow_data['allocation'] = order_placed['allocation'].to_hash
        upsert_payments(flow_order, order)
        upsert_captures(order)
        upsert_order(flow_order, order)
        return order
      else
        errors << { message: "Order #{order_number} not found" }
      end

      self
    end

    def order_upserted_v2
      errors << { message: 'Order param missing' } && (return self) unless (flow_order = @data['order'])

      errors << { message: 'Order number param missing' } && (return self) unless (order_number = flow_order['number'])

      if (order = Spree::Order.find_by(number: order_number))
        upsert_payments(flow_order, order)
        upsert_captures(order)
        upsert_order(flow_order, order)
        return order
      else
        errors << { message: "Order #{order_number} not found" }
      end

      self
    end

    # send en email when order is refunded
    def refund_upserted_v2
      Spree::OrderMailer.refund_complete_email(@data).deliver

      'Email delivered'
    end

    def upsert_order(flow_io_order, order)
      order.flow_data['order'] = flow_io_order.to_hash
      attrs_to_update = update_order_native_attrs(order)
      attrs_to_update.merge!(order.prepare_flow_addresses) if order.complete? || attrs_to_update[:state] == 'complete'
      flow_data_submitted = flow_io_order['submitted_at'].present?

      if flow_data_submitted
        order.create_proposed_shipments
        order.shipment.update_amounts
        order.line_items.each(&:store_ets)
      end

      order.update_columns(attrs_to_update)

      # TODO: To be refactored once we have the capture_upserted_v2 webhook configured
      if flow_data_submitted
        order.create_tax_charge!
        order.finalize!
        order.update_totals
        order.save
      end
    end

    def update_order_native_attrs(order)
      order_flow_data = order.flow_data['order']
      attrs_to_update = { meta: order.meta.to_json }
      flow_io_total_amount = order.flow_io_total_amount&.to_d
      attrs_to_update[:total] = flow_io_total_amount if flow_io_total_amount != order.total
      attrs_to_update[:updated_at] = Time.zone.now.utc
      return attrs_to_update if order_flow_data['submitted_at'].blank? || order.complete?

      if order.flow_io_captures_sum >= flow_io_total_amount && order_flow_data.dig('balance', 'amount').to_i <= 0
        attrs_to_update[:state] = 'complete'
        attrs_to_update[:payment_state] = 'paid'
        attrs_to_update[:completed_at] = Time.zone.now.utc
        attrs_to_update[:email] = order.flow_customer_email
      else
        attrs_to_update[:state] = 'confirmed'
        attrs_to_update[:payment_state] = 'pending'
      end

      attrs_to_update
    end

    def upsert_payments(flow_order, order)
      flow_order['payments']&.each do |p|
        payment =
          order.payments.find_or_initialize_by(response_code: p['reference'], payment_method_id: payment_method_id)
        next unless payment.new_record?

        payment.amount = p.dig('total', 'amount')
        if p['type'] == 'card'
          card = Spree::CreditCard.where("user_id = ? AND meta -> 'flow_data' -> 'authorizations' @> ?",
                                         order.user.id,
                                         [{id: p['reference']}].to_json
          ).first
          payment.source = card if card
        end
        payment.save!(validate: false)

        # For now this additional update is overwriting the generated identifier with flow.io payment identifier.
        # TODO: Check and possibly refactor in Spree 3.0, where the `before_create :set_unique_identifier`
        # has been removed.
        payment.update_column(:identifier, p['id'])
      end
    end

    def upsert_captures(order)
      payments = order.flow_data.dig('order', 'payments')
      order.flow_data['captures']&.each do |c|
        next unless c['status'] == 'succeeded'

        auth = c.dig('authorization', 'id')
        next unless payments.find { |p| p['reference'] == auth }

        next unless (payment = Spree::Payment.find_by(response_code: auth))

        payment.capture_events.create!(amount: c['amount'])
      end
    end

    def payment_method_id
      @payment_method_id ||= Spree::PaymentMethod.find_by(active: true, type: 'Spree::Gateway::FlowIo').id
    end
  end
end
