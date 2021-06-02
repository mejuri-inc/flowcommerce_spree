# frozen_string_literal: true

module FlowcommerceSpree
  class ImportItemWorker
    include Sidekiq::Worker
    sidekiq_options queue: :flow_io

    def perform(variant_sku)
      variant = Spree::Variant.find_by sku: variant_sku
      return unless variant

      FlowcommerceSpree::ImportItem.run(variant)
    end
  end
end
