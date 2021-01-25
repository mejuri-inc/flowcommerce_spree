# frozen_string_literal: true

module FlowcommerceSpree
  class InventoryController < ActionController::Base
    def stock
      items = params['items'] || []
      response = items.inject([]) { |result, item| result << check_stock(item[:id], item[:qty].to_i) }
      render json: { items: response }, status: :ok
    end

    private

    def check_stock(flow_number, quantity)
      variant = Spree::Variant.find_by(sku: flow_number)
      return { id: flow_number, has_inventory: false } unless variant

      { id: flow_number, has_inventory: variant.available_online?(quantity) }
    rescue StandardError
      Rails.logger.error "[!] FlowcommerceSpree::InventoryController#stock unexpected Error: #{$ERROR_INFO}"
      { id: flow_number, has_inventory: false }
    end
  end
end
