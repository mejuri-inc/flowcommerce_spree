# frozen_string_literal: true

module Spree
  Product.class_eval do
    def master_prices
      master.prices
    end

    def master_prices_with_currencies(currencies)
      currencies.empty? ? master_prices : (master_prices.where currency: currencies)
    end
  end
end
