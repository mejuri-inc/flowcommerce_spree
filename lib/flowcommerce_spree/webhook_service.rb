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
        if respond_to?(hook_method, true)
          hook_processor_result = __send__(hook_method)

          # If hook processing method registered an error, return self.object of WebhookService with this error, else
          # return hook_processor_result, which will be an ActiveRecord object
          return hook_processor_result unless errors.any?
        else
          errors << { message: "No hook for #{discriminator}" }
        end
      end

      self
    end

    private

    def hook_experience_upserted_v2
      experience = @data['experience']
      Spree::Zones::Product.find_or_initialize_by(name: experience['key'].titleize).store_flow_io_data(experience)
    end

    def hook_local_item_upserted
      local_item = @data['local_item']
      return errors << { message: 'Local item param missing' } unless local_item

      received_sku = local_item.dig('item', 'number')
      return errors << { message: 'SKU param missing' } unless received_sku

      exp_key = local_item.dig('experience', 'key')

      # TODO: Check if this is really necessary
      # for testing we need ability to inject dependency for variant class
      variant_class = @opts[:variant_class] || Spree::Variant
      @variant      = variant_class.find_by(sku: received_sku)

      return errors << { message: "Variant with sku [#{received_sku}] not found!" } unless @variant

      @variant.add_flow_io_experience_data(
        exp_key, { 'prices' => [local_item.dig('pricing', 'price')], 'status' => local_item['status']}
      )

      @variant.update_column(:meta, @variant.meta.to_json)
      @variant
    end

    def hook_order_upserted_v2
      return errors << { message: 'Order param missing' } unless (received_order = @data['order'])

      return errors << { message: 'Order number param missing' } unless (order_number = received_order['number'])

      order = Spree::Order.find_by(number: order_number)
      return errors << { message: "Order #{order_number} not found" } unless order

      order.flow_data['order'] = received_order.to_hash
      order.update_column(:meta, order.meta.to_json)
      order
    end

    # send en email when order is refunded
    def hook_refund_upserted_v2
      Spree::OrderMailer.refund_complete_email(@data).deliver

      'Email delivered'
    end
  end
end
