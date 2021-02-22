# frozen_string_literal: true

FactoryBot.define do
  factory :flow_german_locale, class: Io::Flow::V0::Models::Locale do
    id { 'de' }
    country { 'DEU' }
    language { 'de' }
    name { 'German - Germany' }
    numbers { { decimal: ',', group: ',' } }

    initialize_with { new(**attributes) }
  end
end
