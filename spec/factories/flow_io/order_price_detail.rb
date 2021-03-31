# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_price_detail, class: Io::Flow::V0::Models::OrderPriceDetail do
    key { Faker::Guid.guid }
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }
    base { build(:flow_price) }
    components { [build(:flow_order_price_detail_component)] }

    initialize_with { new(**attributes) }
  end
end
