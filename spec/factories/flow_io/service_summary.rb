# frozen_string_literal: true

FactoryBot.define do
  factory :flow_service_summary, class: Io::Flow::V0::Models::ServiceSummary do
    id { Faker::Guid.guid }
    carrier { build(:flow_carrier_reference) }
    name { Faker::Product.product_name }

    initialize_with { new(**attributes) }
  end
end
