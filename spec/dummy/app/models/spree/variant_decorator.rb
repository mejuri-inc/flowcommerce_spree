# frozen_string_literal: true

module Spree
  Variant.class_eval do
    def available_online?(quantity = 1)
      stock_items.main.first.count_on_hand >= quantity || backorderable
    end
  end
end
