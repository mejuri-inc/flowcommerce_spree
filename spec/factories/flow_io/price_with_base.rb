# frozen_string_literal: true

FactoryBot.define do
  factory :flow_price_with_base, class: Io::Flow::V0::Models::PriceWithBase do
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }

    initialize_with { new(**attributes) }
  end
end
