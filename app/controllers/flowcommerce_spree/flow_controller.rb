# frozen_string_literal: true

module FlowcommerceSpree
  class FlowController < ActionController::Base
    def stock
      response = []
      params['items'].each { |data| response << check_stock(data[:id], data[:qty].to_i) }

      response = params['items'].each_with_object([]) { |item, result| result << check_stock(item[:id], item[:qty]) }
      render json: { items: response }, status: :ok
    end

    private

    def check_stock(flow_id, quantity)
      variant = Spree::Variant.find_by("meta -> 'flow_data' ->> 'id' = ?", flow_id)
      return { id: flow_id, has_inventory: false } unless variant

      { id: flow_id, has_inventory: variant.flow_stock?(quantity) }
    rescue StandardError
      Rails.logger.error "[!] FlowCommerceSpree#stock unexpected Error: #{$ERROR_INFO}"
      { id: flow_id, has_inventory: false }
    end
  end
end
