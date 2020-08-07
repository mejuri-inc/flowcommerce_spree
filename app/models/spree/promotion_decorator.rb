# Flow specific methods for Spree::Promotion
module Spree
  Promotion.class_eval do
    serialize :flow_data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)
  end
end
