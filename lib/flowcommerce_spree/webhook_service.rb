# frozen_string_literal: true

module FlowcommerceSpree
  # communicates with flow api, responds to webhook events
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
      discriminator = @data['discriminator']
      hook_method = "hook_#{discriminator}"
      # If hook processing method registered an error, a self.object of WebhookService with this error will be
      # returned, else an ActiveRecord object will be returned
      return __send__(hook_method) if respond_to?(hook_method, true)

      errors << { message: "No hook for #{discriminator}" }
      self
    end

    private

    def hook_capture_upserted_v2
      capture = @data['capture']
      order_number = capture.dig('authorization', 'order', 'number')
      if (order = Spree::Order.find_by(number: order_number))
        order.flow_data['captures'] ||= []
        order_captures = order.flow_data['captures']
        order_captures.delete_if do |c|
          c['id'] == capture['id']
        end
        order_captures << capture

        order.update_column(:meta, order.meta.to_json)
        order
      else
        errors << { message: "Order #{order_number} not found" }
        self
      end
    end

    def hook_experience_upserted_v2
      experience = @data['experience']
      Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
    end

    def hook_fraud_status_changed
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

    def hook_local_item_upserted
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

    def hook_order_placed_v2
      order_placed = @data['order_placed']
      flow_order = order_placed['order']
      flow_allocation = order_placed['allocation']

      errors << { message: 'Order number param missing' } && (return self) unless (order_number = flow_order['number'])

      if (order = Spree::Order.find_by(number: order_number))
        order.flow_data['order'] = flow_order.to_hash
        order.flow_data['allocations'] = flow_allocation.to_hash
        order_flow_data = order.flow_data['order']
        attrs_to_update = { meta: order.meta.to_json }
        flow_data_submitted = order_flow_data['submitted_at'].present?
        if flow_data_submitted && !order.complete?
          if order_flow_data['payments'].present? && (order_flow_data.dig('balance', 'amount')&.to_i == 0)
            attrs_to_update[:state] = 'complete'
            attrs_to_update[:payment_state] = 'paid'
            attrs_to_update[:completed_at] = Time.zone.now.utc
            attrs_to_update[:email] = order.flow_customer_email
          else
            attrs_to_update[:state] = 'confirmed'
          end
        end

        attrs_to_update.merge!(order.prepare_flow_addresses) if order.complete? || attrs_to_update[:state] == 'complete'

        if flow_data_submitted
          order.create_proposed_shipments
          order.shipment.update_amounts
          order.line_items.each(&:store_ets)
        end

        order.update_columns(attrs_to_update)
        order.create_tax_charge! if flow_data_submitted
        return order
      else
        errors << { message: "Order #{order_number} not found" }
      end

      self
    end

    def hook_order_upserted_v2
      errors << { message: 'Order param missing' } && (return self) unless (flow_order = @data['order'])

      errors << { message: 'Order number param missing' } && (return self) unless (order_number = flow_order['number'])

      if (order = Spree::Order.find_by(number: order_number))
        order.flow_data['order'] = flow_order.to_hash
        order_flow_data = order.flow_data['order']
        attrs_to_update = { meta: order.meta.to_json }
        flow_data_submitted = order_flow_data['submitted_at'].present?
        if flow_data_submitted && !order.complete?
          if order_flow_data['payments'].present? && (order_flow_data.dig('balance', 'amount')&.to_i == 0)
            attrs_to_update[:state] = 'complete'
            attrs_to_update[:payment_state] = 'paid'
            attrs_to_update[:completed_at] = Time.zone.now.utc
            attrs_to_update[:email] = order.flow_customer_email
          else
            attrs_to_update[:state] = 'confirmed'
          end
        end

        attrs_to_update.merge!(order.prepare_flow_addresses) if order.complete? || attrs_to_update[:state] == 'complete'

        order.update_columns(attrs_to_update)
        order.create_tax_charge! if flow_data_submitted
        return order
      else
        errors << { message: "Order #{order_number} not found" }
      end

      self
    end

    # send en email when order is refunded
    def hook_refund_upserted_v2
      Spree::OrderMailer.refund_complete_email(@data).deliver

      'Email delivered'
    end
  end
end
