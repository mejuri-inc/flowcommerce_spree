# frozen_string_literal: true

FactoryBot.define do
  factory :flow_delivery_item, class: Io::Flow::V0::Models::DeliveryItem do
    number { Faker::Guid.guid }
    quantity { 1 }

    initialize_with { new(**attributes) }
  end
end
