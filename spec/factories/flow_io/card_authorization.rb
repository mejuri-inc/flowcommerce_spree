# frozen_string_literal: true

FactoryBot.define do
  factory :flow_card_authorization, class: Io::Flow::V0::Models::CardAuthorization do
    id { Faker::Guid.guid }
    key { id }
    add_attribute(:method) { build(:flow_payment_method) }
    order { { number: Faker::Guid.guid } }
    card { build(:flow_card) }
    amount { rand(0..100) }
    currency { 'EUR' }
    customer { build(:flow_order_customer) }
    created_at { Time.now.utc }
    attributes { {} }
    result { { status: 'succeeded' } }

    initialize_with { new(**attributes) }
  end
end
