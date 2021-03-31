# frozen_string_literal: true

FactoryBot.define do
  factory :flow_localized_price, class: Io::Flow::V0::Models::LocalizedPrice do
    key { Faker::Guid.guid }

    initialize_with { new(**attributes) }
  end
end
