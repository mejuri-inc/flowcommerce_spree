# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_price_detail_component, class: Io::Flow::V0::Models::OrderPriceDetailComponent do
    key { Faker::Guid.guid }
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }
    base { build(:flow_price) }
    name { Faker::Product.product_name }

    initialize_with { new(**attributes) }
  end
end
