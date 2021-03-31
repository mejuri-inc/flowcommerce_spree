# frozen_string_literal: true

FactoryBot.define do
  factory :flow_localized_line_item, class: Io::Flow::V0::Models::LocalizedLineItem do
    number { Faker::Guid.guid }
    name { Faker::Product.product_name }
    quantity { rand(10) }
    local { build(:flow_local) }

    initialize_with { new(**attributes) }
  end
end
