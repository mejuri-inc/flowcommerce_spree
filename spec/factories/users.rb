# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "person#{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    password { 'password' }
    password_confirmation { 'password' }
    current_sign_in_at { DateTime.now }

    trait :with_role do
      transient do
        role_name { 'role' }
      end

      after(:create) do |user, evaluator|
        user.spree_roles << create(:spree_role, name: evaluator.role_name)
        user.generate_spree_api_key!
      end
    end
  end
end
