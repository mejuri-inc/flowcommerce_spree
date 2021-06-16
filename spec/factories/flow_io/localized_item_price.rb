# frozen_string_literal: true

FactoryBot.define do
  factory :flow_localized_item_price, class: Io::Flow::V0::Models::LocalizedItemPrice do
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }
    base { build(:flow_price) }

    initialize_with { new(**attributes) }
  end
end
