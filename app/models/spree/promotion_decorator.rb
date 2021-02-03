# frozen_string_literal: true

# Flow specific methods for Spree::Promotion
module Spree
  Promotion.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data
  end
end
