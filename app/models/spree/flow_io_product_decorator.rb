# frozen_string_literal: true

# Flow specific methods for Spree::Product
module Spree
  module FlowIoProductDecorator
    def self.prepended(base)
      base.serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

      base.store_accessor :meta, :flow_data, :zone_ids
      base.after_save :sync_variants_with_flow
    end

    def price_in_zone(currency, product_zone)
      flow_experience_key = product_zone&.flow_data&.[]('key')
      return flow_local_price(flow_experience_key) if flow_experience_key.present?

      price_in(currency)
    end

    # returns price bound to local experience from master variant
    def flow_local_price(flow_exp)
      master.flow_local_price(flow_exp) || Spree::Price.new(variant_id: id, currency: 'USD', amount: 0)
    end

    def flow_included?(flow_exp)
      return true unless flow_exp

      flow_data["#{flow_exp.key}.excluded"].to_i != 1
    end

    def price_range(product_zone, currencies = [])
      prices = {}
      master_prices_with_currencies(currencies).each do |p|
        currency = p.currency
        min = nil
        max = nil

        if variants.any?
          variants.each do |v|
            price = v.price_in(currency)
            next if price.nil? || price.amount.nil?

            min = calculate_new_min price,min
            max = calculate_new_max price,max
          end
        else
          min = max = master.price_in(currency)
        end

        rmin = round_with_precision min,0
        rmax = round_with_precision max,0

        prices[currency] = { min: rmin, max: rmax }
      end

      add_flow_price_range(prices, product_zone)
    end

    def calculate_new_min price,min
      (min.nil? || min.amount > price.amount) ? price : min
    end

    def calculate_new_max price,max
      (max.nil? || max.amount < price.amount) ? price : max
    end

    def round_with_precision number,precision
      number&.amount&.to_s(:rounded, precision: precision) || 0
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

          min = calculate_new_min price,min
          max = calculate_new_max price,max
        end
      end

      if master_price.currency == currency
        min ||= master_price
        max ||= master_price
      end

      rmin = round_with_precision min,0
      rmax = round_with_precision max,0

      prices[currency] = { min: rmin, max: rmax }
      prices
    end

    def sync_variants_with_flow
      variants_including_master.each(&:sync_product_to_flow)
    end

    Spree::Product.prepend(self) if Spree::Product.included_modules.exclude?(self)
  end
end
