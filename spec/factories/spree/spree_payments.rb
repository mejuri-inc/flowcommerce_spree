# frozen_string_literal: true

FactoryBot.define do
  factory :payment, class: Spree::Payment do
    order
    payment_method { create(:spree_payment_method_flow) }
    response_code { Faker::Guid.guid }
  end

  trait :completed do
    state { 'completed' }
  end

  trait :void do
    state { 'void' }
  end
end
