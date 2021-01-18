# frozen_string_literal: true

FactoryBot.define do
  factory :country, class: Spree::Country do
    iso { Faker::Address.country_code }
    iso_name { ISO3166::Country[iso].name }
    name { ISO3166::Country[iso].translations['en'] }
    iso3 { ISO3166::Country[iso].alpha3 }
    numcode { ISO3166::Country[iso].number }

    factory :country_with_states do
      states_required { true }
    end

    factory :country_with_no_states, class: Spree::Country do
      states_required { false }
    end
  end
end
