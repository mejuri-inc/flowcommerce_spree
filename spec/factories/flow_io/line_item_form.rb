# frozen_string_literal: true

FactoryBot.define do
  factory :flow_line_item_form, class: Io::Flow::V0::Models::LineItemForm do
    number { Faker::Guid.guid }
    quantity { 1 }

    initialize_with { new(**attributes) }
  end
end
