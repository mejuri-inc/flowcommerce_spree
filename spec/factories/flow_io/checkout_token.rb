# frozen_string_literal: true

FactoryBot.define do
  factory :flow_checkout_token, class: Io::Flow::V0::Models::CheckoutToken do
    id { Faker::Guid.guid }
    organization { { id: Faker::Guid.guid } }
    checkout { { id: Faker::Guid.guid } }
    order {}
    urls { {} }
    expires_at { Time.zone.now.utc + 30.minutes }
    session {}

    initialize_with { new(**attributes) }
  end
end
