# frozen_string_literal: true

FactoryBot.define do
  factory :flow_capture, class: Io::Flow::V0::Models::Capture do
    id { Faker::Guid.guid }
    key { id }
    authorization { build(:flow_authorization_reference) }
    requested { build(:flow_money) }
    amount { requested.amount }
    currency { requested.currency.to_s }
    status { 'succeeded' }
    created_at { Time.now.utc }

    initialize_with { new(**attributes) }
  end
end
