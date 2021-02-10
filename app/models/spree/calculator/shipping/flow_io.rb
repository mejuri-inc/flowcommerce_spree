# frozen_string_literal: true

module Spree
  class Calculator
    module Shipping
      class FlowIo < ShippingCalculator
        def self.description
          'FlowIO Calculator'
        end

        def compute_package(package)
          flow_order = flow_order(package)
          return unless flow_order

          flow_order['prices'].find { |x| x['key'] == 'shipping' }['amount'] || 0
        end

        def default_charge(_country)
          0
        end

        def threshold
          0
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
