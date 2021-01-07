# frozen_string_literal: true

# Flow (2017)
# Enable this modifications if you want to display flow localized line item
# Example: https://i.imgur.com/7v2ix2G.png
module Spree
  LineItem.class_eval do
    # admin show line item price
    def single_money
      price  = display_price.to_s
      price += ' (%s)' % order.flow_line_item_price(self) if order.flow_order
      price
    end
  end
end
