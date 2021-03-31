# frozen_string_literal: true

FactoryBot.define do
  factory :flow_physical_delivery, class: Io::Flow::V0::Models::PhysicalDelivery do
    id { Faker::Guid.guid }
    items { [build(:flow_delivery_item)] }
    options { [build(:flow_delivery_option)] }

    initialize_with { new(**attributes) }
  end
end
