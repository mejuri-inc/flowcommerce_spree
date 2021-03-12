# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_address, class: Io::Flow::V0::Models::OrderAddress do
    country { Faker::Address.country_code }

    initialize_with { new(**attributes) }
  end
end
