# frozen_string_literal: true

FactoryBot.define do
  factory :shipment, class: Spree::Shipment do
    tracking { 'U10000' }
    cost { 100.00 }
    state { 'pending' }
    order
    stock_location do
      Spree::StockLocation.find_by(id: Rails.configuration.main_warehouse_id) || FactoryBot.create(:stock_location)
    end

    after(:create) do |shipment|
      shipment.add_shipping_method(create(:shipping_method), true)

      shipment.order.line_items.each do |line_item|
        line_item.quantity.times do
          shipment.inventory_units.create(
            variant_id: line_item.variant_id,
            line_item_id: line_item.id
          )
        end
      end
    end
  end

  trait :ready do
    state { 'ready' }
  end
end
