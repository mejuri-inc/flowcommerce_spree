# frozen_string_literal: true

module Spree
  Product.class_eval do
    def master_prices
      master.prices
    end
  end
end
