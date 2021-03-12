# frozen_string_literal: true

FactoryBot.define do
  factory :flow_name, class: Io::Flow::V0::Models::Name do
    first { Faker::Name.first_name }
    last { Faker::Name.last_name }

    initialize_with { new(**attributes) }
  end
end
