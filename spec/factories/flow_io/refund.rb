# frozen_string_literal: true

FactoryBot.define do
  factory :flow_refund, class: Io::Flow::V0::Models::Refund do
    id { Faker::Guid.guid }
    key { id }
    authorization { build(:flow_authorization_reference) }
    status { 'succeeded' }
    created_at { Time.now.utc }
    captures do
      capture = build(:flow_capture)
      [{ capture: capture.to_hash, amount: capture.amount }]
    end

    initialize_with { new(**attributes) }
  end
end
