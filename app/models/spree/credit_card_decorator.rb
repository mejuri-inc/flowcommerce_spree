# frozen_string_literal: true

module Spree
  CreditCard.class_eval do
    serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    store_accessor :meta, :flow_data
  end
end
