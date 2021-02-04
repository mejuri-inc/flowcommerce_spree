# frozen_string_literal: true

FactoryBot.define do
  factory :stock_location, class: Spree::StockLocation do
    id { Rails.configuration.main_warehouse_id }
    name { 'NY Warehouse' }
    address1 { '1600 Pennsylvania Ave NW' }
    city { 'Washington' }
    zipcode { '20500' }
    phone { '(202) 456-1111' }
    active { true }
    backorderable_default { true }

    country  { |stock_location| Spree::Country.first || stock_location.association(:country) }
    state do |stock_location|
      stock_location.country.states.first || stock_location.association(:state, country: stock_location.country)
    end
  end
end
