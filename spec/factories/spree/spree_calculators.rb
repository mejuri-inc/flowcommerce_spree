# frozen_string_literal: true

FactoryBot.define do
  factory :shipping_calculator, class: Spree::Calculator::Shipping::DeliveryCharge do
    after(:create) { |c| c.set_preference(:amount, 10.0) }
  end

  factory :shipping_flow_io_calculator, class: Spree::Calculator::Shipping::FlowIo do
    after(:create) { |c| c.set_preference(:lower_boundary, 3) }
  end

  factory :default_tax_calculator, class: Spree::Calculator::DefaultTax do
  end
end
