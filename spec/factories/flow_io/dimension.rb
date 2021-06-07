# frozen_string_literal: true

FactoryBot.define do
  factory :flow_dimensions, class: Io::Flow::V0::Models::Dimensions do
    initialize_with { new(**attributes) }
  end
end
