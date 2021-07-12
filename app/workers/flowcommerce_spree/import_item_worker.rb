# frozen_string_literal: true

module FlowcommerceSpree
  class ImportItemWorker < FlowIoWorker
    sidekiq_options retry: 3, queue: :flow_io

    def perform(variant_sku)
      variant = Spree::Variant.find_by sku: variant_sku
      return unless variant

      FlowcommerceSpree::ImportItem.run(variant)
    end
  end
end
