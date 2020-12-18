# Flow specific methods for Spree::Product
module Spree
  module FlowIoProductDecorator
    def self.prepended(base)
      base.serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

      base.store_accessor :meta, :flow_data, :zone_ids
    end

    def price_in_zone(currency, product_zone)
      flow_experience_key = product_zone&.flow_data&.[]('key')
      return flow_local_price(flow_experience_key) if flow_experience_key.present?

      price_in(currency)
    end

    # returns price bound to local experience from master variant
    def flow_local_price(flow_exp)
      master.flow_local_price(flow_exp) || Spree::Price.new(variant_id: self.id, currency: 'USD', amount: 0)
    end

    def flow_included?(flow_exp)
      return true unless flow_exp

      flow_data['%s.excluded' % flow_exp.key].to_i == 1 ? false : true
    end

    def price_range(product_zone)
      prices = {}
      master_prices.each do |p|
        currency = p.currency
        min = nil
        max = nil

        if variants.any?
          variants.each do |v|
            price = v.price_in(currency)
            next if price.nil? || price.amount.nil?

            min = price if min.nil? || min.amount > price.amount
            max = price if max.nil? || max.amount < price.amount
          end
        else
          min = max = master.price_in(currency)
        end

        rmin = min&.amount&.to_s(:rounded, precision: 0) || 0
        rmax = max&.amount&.to_s(:rounded, precision: 0) || 0

        prices[currency] = rmin == rmax ? { amount: rmin } : { min: rmin, max: rmax }
      end

      add_flow_price_range(prices, product_zone)
    end

    def add_flow_price_range(prices, product_zone)
      flow_experience_key = product_zone&.flow_data&.[]('key')
      return prices if flow_experience_key.blank?

      master_price = master.flow_local_price(flow_experience_key)
      currency = product_zone.flow_io_experience_currency
      min = nil
      max = nil

      if variants.any?
        variants.each do |v|
          price = v.flow_local_price(flow_experience_key)
          next if price.amount.nil? || price.currency != currency

          min = price if min.nil? || min.amount > price.amount
          max = price if max.nil? || max.amount < price.amount
        end
      end

      if master_price.currency == currency
        min ||= master_price
        max ||= master_price
      end

      rmin = min&.amount&.to_s(:rounded, precision: 0) || 0
      rmax = max&.amount&.to_s(:rounded, precision: 0) || 0

      prices[currency] = rmin == rmax ? { amount: rmin } : { min: rmin, max: rmax }
      prices
    end

    Spree::Product.prepend(self) if Spree::Product.included_modules.exclude?(self)
  end
end
