# frozen_string_literal: true

FactoryBot.define do
  factory :payment_method, class: Spree::PaymentMethod do
    description { '' }
    active { true }
    environment { 'test' }
    deleted_at { nil }
    display_on { 'both' }
    auto_capture { nil }
    publishable_key { 'pk_test_lOqm7Kap09Mb3VT2N3teqV4v' }
    private_key { 'sk_test_r4ZQWVq4juSTx6jkrXfNFvBT' }
    name { 'stripe-ca' }

    factory :spree_payment_method_flow do
      name { 'flow_io' }
      type { 'Spree::Gateway::FlowIo' }
    end
  end
end
