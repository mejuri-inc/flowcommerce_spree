# Flow specific methods for Spree::Product
module Spree
  Product.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data, :zone_ids

    def price_in_zone(currency, product_zone)
      flow_experience_key = product_zone.flow_data&.[]('key')
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
  end
end
