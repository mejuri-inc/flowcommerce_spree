# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_address, class: Io::Flow::V0::Models::OrderAddress do
    country { Faker::Address.country_code }
    streets { %w[fake1 fake2] }
    contact { { 'name': { 'first': 'fake', 'last': 'fake last' }, 'phone': '123' } }
    phone { '123457' }
    postal { '123' }
    city { 'test city' }
    province { 'test state' }
    initialize_with { new(**attributes) }
  end
end
