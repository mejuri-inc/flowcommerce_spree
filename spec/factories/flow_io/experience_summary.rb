# frozen_string_literal: true

FactoryBot.define do
  factory :flow_experience_summary, class: Io::Flow::V0::Models::ExperienceSummary do
    id { Faker::Guid.guid }
    key { 'germany' }
    name { 'Germany' }
    currency { 'EUR' }

    initialize_with { new(**attributes) }
  end
end
