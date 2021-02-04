# frozen_string_literal: true

FactoryBot.define do
  factory :user_profile do |f|
    f.user
    f.last_name { Faker::Name.last_name }
    f.first_name { Faker::Name.first_name }
  end
end
