# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_customer_form, class: Io::Flow::V0::Models::OrderCustomerForm do
    # name
    # number
    # phone
    # email
    # address

    initialize_with { new(**attributes) }
  end
end
