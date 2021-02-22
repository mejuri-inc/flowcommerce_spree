# frozen_string_literal: true

FactoryBot.define do
  factory :flow_germany_country, class: Io::Flow::V0::Models::Country do
    iso_3166_2 { 'DE' }
    iso_3166_3 { 'DEU' }
    languages { ['DE'] }
    measurement_system { 'metric' }
    name { 'Germany' }
    timezones { [] }

    initialize_with { new(**attributes) }
  end
end
