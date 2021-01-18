# frozen_string_literal: true

module Spree
  module Zones
    class Product < Spree::Zone
      scope :active, -> { where(status: 'active') }

      serialize :meta, ActiveRecord::Coders::JSON.new(symbolize_keys: true)
      store_accessor :meta, :flow_data
    end
  end
end
