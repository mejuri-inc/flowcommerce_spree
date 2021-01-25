# frozen_string_literal: true

FactoryBot.define do
  factory :flow_german_language, class: Io::Flow::V0::Models::Language do
    iso_639_2 { 'de' }
    name { 'german' }

    initialize_with { new(**attributes) }
  end
end
