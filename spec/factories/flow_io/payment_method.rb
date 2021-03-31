# frozen_string_literal: true

FactoryBot.define do
  factory :flow_payment_method, class: Io::Flow::V0::Models::PaymentMethod do
    id { Faker::Guid.guid }
    type { 'card' }
    name { 'VISA' }
    images do
      { small: { url: '', width: 10, height: 10 },
        medium: { url: '', width: 10, height: 10 },
        large: { url: '', width: 10, height: 10 } }
    end
    regions { [] }

    initialize_with { new(**attributes) }
  end
end
