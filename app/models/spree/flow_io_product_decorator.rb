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

        prices[currency] = { min: rmin, max: rmax }
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

      prices[currency] = { min: rmin, max: rmax }
      prices
    end

    def adjust_zone(zone)
      self.zone_ids ||= []
      zone_id_string = zone.id.to_s
      return if zone_ids.include?(zone_id_string)

      self.zone_ids << zone_id_string
      self.zone_ids = zone_ids
      update_columns(meta: meta.to_json)
    end

    def sync_variants_with_flow
      variants_including_master.each(&:sync_product_to_flow)
    end

    Spree::Product.prepend(self) if Spree::Product.included_modules.exclude?(self)
  end
end
