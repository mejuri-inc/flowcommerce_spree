# frozen_string_literal: true

FactoryBot.define do
  factory :flow_carrier_reference, class: Io::Flow::V0::Models::CarrierReference do
    id { Faker::Guid.guid }

    initialize_with { new(**attributes) }
  end
end
