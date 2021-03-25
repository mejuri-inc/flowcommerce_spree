# frozen_string_literal: true

module Spree
  Variant.class_eval do
    delegate :country_of_origin, to: :product

    def available_online?(quantity = 1)
      stock_items.main.first.count_on_hand >= quantity || backorderable
    end
  end
end
