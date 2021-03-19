# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_put_form, class: Io::Flow::V0::Models::OrderPutForm do
    # items
    # customer

    initialize_with { new(**attributes) }
  end
end
