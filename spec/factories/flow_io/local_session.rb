# frozen_string_literal: true

FactoryBot.define do
  factory :flow_germany_local_session, class: Io::Flow::V0::Models::LocalSession do
    country { build(:flow_germany_country) }
    currency { build(:flow_euro_currency) }
    language { build(:flow_german_language) }
    locale { build(:flow_german_locale) }
    experience { build(:flow_germany_experience) }

    initialize_with { new(**attributes) }
  end
end
