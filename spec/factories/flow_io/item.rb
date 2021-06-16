# frozen_string_literal: true

FactoryBot.define do
  factory :flow_item, class: Io::Flow::V0::Models::Item do
    id { Faker::Guid.guid }
    number { Faker::Guid.guid }
    name { 'Stacker Ring' }
    locale { 'en-US' }
    price { build(:flow_price) }
    local { build(:flow_local) }
    dimensions { build(:flow_dimensions) }

    initialize_with { new(**attributes) }
  end
end
