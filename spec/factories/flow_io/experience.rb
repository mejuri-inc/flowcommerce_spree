# frozen_string_literal: true

FactoryBot.define do
  factory :flow_germany_experience, class: Io::Flow::V0::Models::ExperienceGeo do
    country { 'DEU' }
    currency { 'EUR' }
    key { 'germany' }
    language { 'de' }
    measurement_system { 'metric' }
    name { 'Germany' }
    region { { id: 'deu' } }

    initialize_with { new(**attributes) }
  end
end
