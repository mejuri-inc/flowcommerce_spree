# frozen_string_literal: true

FactoryBot.define do
  factory :flow_money, class: Io::Flow::V0::Models::Money do
    amount { rand(0..100) }
    currency { Faker::Currency.code }

    initialize_with { new(**attributes) }
  end
end
