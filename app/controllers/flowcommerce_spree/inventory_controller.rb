# frozen_string_literal: true

module FlowcommerceSpree
  class InventoryController < ActionController::Base
    def stock
      response = params['items'].inject([]) { |result, item| result << check_stock(item[:id], item[:qty].to_i) }
      render json: { items: response }, status: :ok
    end

    private

    def check_stock(flow_id, quantity)
      variant = Spree::Variant.find_by("meta -> 'flow_data' ->> 'id' = ?", flow_id)
      return { id: flow_id, has_inventory: false } unless variant

      { id: flow_id, has_inventory: variant.available_online?(quantity) }
    rescue StandardError
      Rails.logger.error "[!] FlowcommerceSpree::InventoryController#stock unexpected Error: #{$ERROR_INFO}"
      { id: flow_id, has_inventory: false }
    end
  end
end
