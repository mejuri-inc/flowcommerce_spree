# frozen_string_literal: true

module FlowcommerceSpree
  module Webhooks
    class LocalItemUpserted
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
    end
  end
end
