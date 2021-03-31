# frozen_string_literal: true

FactoryBot.define do
  factory :flow_price_with_base_and_details, class: Io::Flow::V0::Models::PriceWithBaseAndDetails do
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }

    initialize_with { new(**attributes) }
  end
end
