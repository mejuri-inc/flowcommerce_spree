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
          get_flow_tax_data(order)
          tax_for_item(item)
        else
          prev_tax_amount(item)
        end
      end
      alias compute_shipment compute_shipment_or_line_item
      alias compute_line_item compute_shipment_or_line_item

      def get_tax_rate(taxable)
        order = taxable.class.to_s == 'Spree::Order' ? taxable : taxable.order
        get_flow_tax_data(order) if order.flow_allocations.empty?
        response = order.flow_tax_for_item(taxable.adjustable, 'vat_item_price', rate.included_in_price)
        response.nil? ? 0 : response['rate']&.to_f
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
          response = FlowcommerceSpree.client.orders
                                      .get_allocations_by_number(FlowcommerceSpree::ORGANIZATION, order.number)
          return nil unless response.present?

          order.flow_order['allocations'] = response.to_hash
          order.update_column(:meta, order.meta.to_json)
          response
        end
        flow_io_tax_response
      end

      def tax_for_item(item)
        order = item.order
        prev_tax_amount = prev_tax_amount(item)
        tax_data = order.flow_tax_for_item(item, 'vat_item_price', rate.included_in_price)
        return prev_tax_amount if tax_data.blank?

        subsidy_data = order.flow_tax_for_item(item, 'vat_subsidy', rate.included_in_price)
        amount = tax_data.dig('total', 'amount')
        amount += subsidy_data.dig('total', 'amount') if subsidy_data.present?
        amount.present? && amount > 0 ? amount : prev_tax_amount
      end
    end
  end
end
