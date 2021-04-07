# frozen_string_literal: true

FactoryBot.define do
  factory :flow_card, class: Io::Flow::V0::Models::Card do
    id { Faker::Guid.guid }
    token { Faker::Guid.guid }
    type { 'visa' }
    expiration { { month: (Time.now.utc + 1.year).month, year: (Time.now.utc + 1.year).year } }
    iin { '4' }
    issuer { { iin: '4' } }
    last4 { '7036' }
    name { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }

    initialize_with { new(**attributes) }
  end
end
