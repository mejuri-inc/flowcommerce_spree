# frozen_string_literal: true

module Spree
  class Calculator
    class FlowIo < Calculator::DefaultTax
      def self.description
        'FlowIO Calculator'
      end

      def compute_shipment_or_line_item(item)
        order = item.order

        if can_calculate_tax?(order)
          flow_response = get_flow_tax_data(order)
          tax_for_item(item, flow_response)
        else
          prev_tax_amount(item)
        end
      end
      alias compute_shipment compute_shipment_or_line_item
      alias compute_line_item compute_shipment_or_line_item

      def get_tax_rate(taxable)
        order = taxable.class.to_s == 'Spree::Order' ? taxable : taxable.order
        flow_response = get_flow_tax_data(order)
        response = tax_data_for_item(taxable.adjustable, flow_response)
        response.nil? ? 0 : response&.rate&.to_f
      end

      private

      def prev_tax_amount(item)
        if rate.included_in_price
          item.included_tax_total
        else
          item.additional_tax_total
        end
      end

      def can_calculate_tax?(order)
        return false if order.flow_data.blank?
        return false if %w[cart address].include?(order.state)

        true
      end

      def get_flow_tax_data(order)
        flow_io_tax_response = Rails.cache.fetch(order.flow_tax_cache_key, time_to_idle: 5.minutes) do
          response = FlowcommerceSpree.client.orders.get_allocations_by_number(FlowcommerceSpree::ORGANIZATION, order.number)
          return nil unless response.present?

          order.flow_order['allocations'] = response.to_hash
          order.update_column(:meta, order.meta.to_json)
          response
        end
        flow_io_tax_response
      end

      def tax_data_for_item(item, flow_response)
        item_details = flow_response.details&.find do |el|
          item.is_a?(Spree::LineItem) ? el.number == item.variant.sku : el.key.value == 'shipping'
        end
        price_components = rate.included_in_price ? item_details.included : item_details.not_included

        price_components&.find { |el| el.key.value == 'vat_item_price' }
      end

      def tax_for_item(item, flow_response)
        prev_tax_amount = prev_tax_amount(item)
        return prev_tax_amount if flow_response.nil?

        tax_data = tax_data_for_item(item, flow_response)
        amount = tax_data&.total&.amount

        amount.present? && amount > 0 ? amount : prev_tax_amount
      end
    end
  end
end
