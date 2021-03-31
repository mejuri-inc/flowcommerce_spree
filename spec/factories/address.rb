# frozen_string_literal: true

FactoryBot.define do
  factory :profile_address, class: Address do
    firstname { 'Nina' }
    lastname { 'Simone' }
    city { 'Baltimore' }
    zipcode { '89733' }
    address1 { '123 Sesame' }
    state_name { 'Chicago' }
    phone { '55555555' }
    country_id { create(:country).id }
    user_profile { nil }
  end
end
