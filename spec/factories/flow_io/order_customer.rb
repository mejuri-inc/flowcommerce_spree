# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_customer, class: Io::Flow::V0::Models::OrderCustomer do
    name { build(:flow_name) }

    initialize_with { new(**attributes) }
  end
end
