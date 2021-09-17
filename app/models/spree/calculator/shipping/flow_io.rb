# frozen_string_literal: true

module Spree
  class Calculator
    module Shipping
      class FlowIo < ShippingCalculator
        preference :lower_boundary, :decimal, default: 100
        preference :charge_default, :decimal, default: 15
        preference :sample_product_cost, :decimal, default: 9

        def self.description
          'FlowIO Calculator'
        end

        def compute_package(package)
          flow_order = flow_order(package)
          return unless flow_order

          flow_order['prices'].find { |x| x['key'] == 'shipping' }['amount'] || 0
        end

        def default_charge(_country)
          preferred_charge_default
        end

        def threshold
          preferred_lower_boundary
        end

        def default_sample_charge
          preferred_sample_product_cost
        end

        private

        def flow_order(package)
          return @flow_order if defined?(@flow_order)

          @flow_order = package.order.flow_data&.[]('order')
          @flow_order
        end
      end
    end
  end
end
