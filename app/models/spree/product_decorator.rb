# Flow specific methods for Spree::Product
module Spree
  Product.class_eval do
    serialize :flow_data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    # returns price tied to local experience from master variant
    def flow_local_price(flow_exp)
      variants.first.flow_local_price(flow_exp)
    end

    def flow_included?(flow_exp)
      return true unless flow_exp

      flow_data['%s.excluded' % flow_exp.key].to_i == 1 ? false : true
    end
  end
end
