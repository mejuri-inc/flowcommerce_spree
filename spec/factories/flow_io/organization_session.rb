# frozen_string_literal: true

FactoryBot.define do
  factory :flow_organization_session, class: Io::Flow::V0::Models::OrganizationSession do
    id { Faker::Guid.guid }
    organization { Faker::Company.name }
    visitor { { id: Faker::Guid.guid } }
    visit { { id: Faker::Guid.guid, expires_at: Time.zone.now.utc } }
    environment { 'test' }
    attributes { {} }

    initialize_with { new(**attributes) }
  end
end
