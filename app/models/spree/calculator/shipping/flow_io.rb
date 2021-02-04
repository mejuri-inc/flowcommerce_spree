# frozen_string_literal: true

module Spree
  module Calculator::Shipping
    class FlowIo < ShippingCalculator
      preference :lower_boundary, :decimal, default: 100

      def self.description
        'FlowCommerce'
      end

      def compute_package(package)
        flow_order = flow_order(package)
        return unless flow_order

        flow_order&.prices&.find { |x| x.key('shipping') }&.amount || 0
      end

      def threshold
        preferred_lower_boundary
      end

      private

      def flow_order(package)
        return @flow_order if defined?(@flow_order)

        @flow_order = package.order.flow_order
        @flow_order
      end
    end
  end
end
