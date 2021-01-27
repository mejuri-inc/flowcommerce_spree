# frozen_string_literal: true

module FlowcommerceSpree
  # communicates with flow api, responds to webhook events
  class WebhookService
    attr_accessor :errors, :product, :variant
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
      capture = Io::Flow::V0::Models::Capture.new(@data['capture'])
      if (order = Spree::Order.find_by(number: capture.authorization.order.number))
        # return order
      else
        errors << { message: "Order #{order_number} not found" }
      end

      order.update_column :flow_data, order.flow_data.merge('capture': @data['capture'])
    end

    def hook_experience_upserted_v2
      experience = @data['experience']
      Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
    end

    def hook_fraud_status_changed
      errors << { message: 'Order param missing' } unless (received_order = @data['order'])

      if errors.none? && (order_number = received_order['number'])
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
      if (local_item = @data['local_item'])
        if (received_sku = local_item.dig('item', 'number'))
          if (@variant = Spree::Variant.find_by(sku: received_sku))
            @variant.add_flow_io_experience_data(
              local_item.dig('experience', 'key'),
              'prices' => [local_item.dig('pricing', 'price')], 'status' => local_item['status']
            )

            @variant.update_column(:meta, @variant.meta.to_json)
            return @variant
          else
            errors << { message: "Variant with sku [#{received_sku}] not found!" }
          end
        else
          errors << { message: 'SKU param missing' }
        end
      else
        errors << { message: 'Local item param missing' }
      end

      self
    end

    def hook_order_upserted_v2
      errors << { message: 'Order param missing' } unless (received_order = @data['order'])

      if errors.none? && (order_number = received_order['number'])
        if (order = Spree::Order.find_by(number: order_number))
          order.flow_data['order'] = received_order.to_hash
          order_flow_data = order.flow_data['order']
          attrs_to_update = { meta: order.meta.to_json }
          flow_data_submitted = order_flow_data['submitted_at'].present?
          if flow_data_submitted && !order.complete?
            if order_flow_data['payments'].present? && (order_flow_data.dig('balance', 'amount')&.to_i == 0)
              attrs_to_update[:state] = 'complete'
              attrs_to_update[:payment_state] = 'paid'
              attrs_to_update[:completed_at] = Time.zone.now.utc
            else
              attrs_to_update[:state] = 'confirmed'
            end
          end

          order.update_columns(attrs_to_update)
          order.create_tax_charge! if flow_data_submitted
          return order
        else
          errors << { message: "Order #{order_number} not found" }
        end
      else
        errors << { message: 'Order number param missing' }
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
