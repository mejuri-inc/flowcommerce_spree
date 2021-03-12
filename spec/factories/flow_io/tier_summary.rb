# frozen_string_literal: true

FactoryBot.define do
  factory :flow_tier_summary, class: Io::Flow::V0::Models::TierSummary do
    id { Faker::Guid.guid }
    integration { 'direct' }
    name { Faker::Product.product_name }
    services { ['express'] }
    strategy { 'lowest_cost' }
    visibility { 'private' }
    currency { 'EUR' }

    initialize_with { new(**attributes) }
  end
end
