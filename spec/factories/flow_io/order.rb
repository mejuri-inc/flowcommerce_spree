# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order, class: Io::Flow::V0::Models::Order do
    id { Faker::Guid.guid }
    number { Faker::Guid.guid }
    merchant_of_record { 'flow' }
    customer { build(:flow_order_customer) }
    delivered_duty { 'paid' }
    destination { build(:flow_order_address) }
    expires_at { Time.now.utc + 7.days }
    items { [build(:flow_localized_line_item)] }
    deliveries { [build(:flow_physical_delivery)] }
    selections { [] }
    prices { [build(:flow_order_price_detail)] }
    total { build(:flow_localized_total) }
    attributes { {} }

    initialize_with { new(**attributes) }
  end
end
