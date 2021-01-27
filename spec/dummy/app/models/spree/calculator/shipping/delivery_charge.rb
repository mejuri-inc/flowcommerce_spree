module Spree
  module Calculator::Shipping
    # For products that are under 100
    # we charge =>
    # $25 for Int.
    # $10 for Canada
    # $10 for US
    # $15 for EU
    class DeliveryCharge < ShippingCalculator; end
  end
end
