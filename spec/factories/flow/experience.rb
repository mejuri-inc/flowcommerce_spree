# frozen_string_literal: true

FactoryBot.define do
  factory :flow_germany_experience, class: Io::Flow::V0::Models::ExperienceGeo do
    name { 'Germany' }
    key { 'germany' }
    country { 'DEU' }
    currency { 'EUR' }
    language { 'de' }
  end
end
