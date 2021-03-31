# frozen_string_literal: true

FactoryBot.define do
  factory :flow_delivery_option, class: Io::Flow::V0::Models::DeliveryOption do
    id { Faker::Guid.guid }
    items { build(:flow_delivery_item) }
    cost { build(:flow_price_with_base_and_details) }
    delivered_duty { 'paid' }
    price { build(:flow_price_with_base_and_details) }
    service { build(:flow_service_summary) }
    tier { build(:flow_tier_summary) }
    window { { from: Time.now.utc, to: Time.now.utc + 7.days } }

    initialize_with { new(**attributes) }
  end
end
