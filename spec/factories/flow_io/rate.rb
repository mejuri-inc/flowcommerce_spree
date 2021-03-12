# frozen_string_literal: true

FactoryBot.define do
  factory :flow_rate, class: Io::Flow::V0::Models::Rate do
    id { Faker::Guid.guid }
    base { 'EUR' }
    target { 'USD' }
    effective_at { Time.now.utc }
    value { 1.15 }

    initialize_with { new(**attributes) }
  end
end
