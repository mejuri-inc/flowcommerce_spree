# Flow (2017)
# Enable this modifications if you want to display flow localized line item shipment price beside Spree default
# Example: https://i.imgur.com/7v2ix2G.png
module Spree
  module Admin
    OrdersHelper.module_eval do
      # admin show line item total price
      def line_item_shipment_price(line_item, quantity)
        price = Spree::Money.new(line_item.price * quantity, { currency: line_item.currency }).to_s
        price += ' (%s)' % @order.flow_line_item_price(line_item, quantity) if @order.flow_order
        price.html_safe
      end
    end
  end
end
