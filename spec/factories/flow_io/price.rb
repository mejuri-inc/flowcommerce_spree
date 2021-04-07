# frozen_string_literal: true

FactoryBot.define do
  factory :flow_price, class: Io::Flow::V0::Models::Price do
    amount { 118.00 }
    currency { 'USD' }
    label { 'Base price' }

    initialize_with { new(**attributes) }
  end
end
