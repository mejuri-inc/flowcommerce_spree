# frozen_string_literal: true

FactoryBot.define do
  factory :flow_euro_currency, class: Io::Flow::V0::Models::Currency do
    iso_4217_3 { 'EUR' }
    name { 'Euro' }
    number_decimals { 2 }

    initialize_with { new(**attributes) }
  end
end
