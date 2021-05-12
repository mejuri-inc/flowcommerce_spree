# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_summary, class: Io::Flow::V0::Models::AllocationOrderSummary do
    id { Faker::Guid.guid }
    number { Faker::Guid.guid }
    expires_at { Time.now.utc }

    initialize_with { new(**attributes) }
  end
end
