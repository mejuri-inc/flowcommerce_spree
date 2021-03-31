# frozen_string_literal: true

FactoryBot.define do
  factory :flow_localized_total, class: Io::Flow::V0::Models::LocalizedTotal do
    currency { 'EUR' }
    amount { 100.00 }
    label { 'Price in EUR' }
    base { build(:flow_price) }

    initialize_with { new(**attributes) }
  end
end
