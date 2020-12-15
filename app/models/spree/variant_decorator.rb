# frozen_string_literal: true

# Flow specific methods for Spree::Variant
module Spree
  Variant.class_eval do
    def flow_stock?(quantity)
      return false unless reference_stock_item

      reference_stock_item.count_on_hand > quantity || reference_stock_item.backorderable?
    end
  end
end
