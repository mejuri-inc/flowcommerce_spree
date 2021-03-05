# frozen_string_literal: true

FactoryBot.define do
  factory :flow_io_gateway, class: Spree::Gateway::FlowIo do
    name { 'flow.io' }
    environment { 'test' }
  end
end
