# frozen_string_literal: true

FactoryBot.define do
  factory :state, class: Spree::State do
    sequence(:name) { |n| "STATE_NAME_#{n}" }
    sequence(:abbr) { |n| "STATE_ABBR_#{n}" }
    association :country, factory: :country_with_states
  end
end
