# frozen_string_literal: true

FactoryBot.define do
  factory :tax_category, class: Spree::TaxCategory do
    name { "TaxCategory - #{rand(999_999)}" }
    description { 'Random description for category' }
  end
end
