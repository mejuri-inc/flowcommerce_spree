# frozen_string_literal: true

module Spree
  StockItem.class_eval do
    scope :main, -> { where "stock_location_id=#{Rails.configuration.main_warehouse_id}" }
  end
end
