# frozen_string_literal: true

FactoryBot.define do
  factory :flow_authorization_reference, class: Io::Flow::V0::Models::AuthorizationReference do
    id { Faker::Guid.guid }
    key { id }
    order { { number: Faker::Guid.guid } }

    initialize_with { new(**attributes) }
  end
end
