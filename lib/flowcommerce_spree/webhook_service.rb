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
      org = @data['organization']
      if org != ORGANIZATION
        errors << { message: "Organization name mismatch for #{org}" }
      else
        discriminator = @data['discriminator']
        hook_method = "hook_#{discriminator}"
        # If hook processing method registered an error, a self.object of WebhookService with this error will be
        # returned, else an ActiveRecord object will be returned
        return __send__(hook_method) if respond_to?(hook_method, true)

        errors << { message: "No hook for #{discriminator}" }
      end

      self
    end

    private

    def hook_experience_upserted_v2
      experience = @data['experience']
      Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
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
          attrs_to_update = { meta: order.meta.to_json }
          if order.flow_data['order']['submitted_at'].present?
            attrs_to_update[:state] = 'complete'
            attrs_to_update[:completed_at] = Time.zone.now
          end

          order.update_columns(attrs_to_update)
          order.create_tax_charge!
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
