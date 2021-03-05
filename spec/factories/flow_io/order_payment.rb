# frozen_string_literal: true

FactoryBot.define do
  factory :flow_order_payment, class: Io::Flow::V0::Models::OrderPayment do
    id { Faker::Guid.guid }
    date { Time.current }
    type { 'card' }
    total { { 'base' => { 'label' => 'US$108.02', 'amount' => 108.02, 'currency' => 'USD' }, 'label' => '91,98 €', 'amount' => 91.98, 'currency' => 'EUR' } }
    address do
      { 'city' => 'Berlin',
        'name' => { 'last' => '2nzfkkdvo2', 'first' => '2nzfkkdvo2' },
        'postal' => '10969',
        'company' => nil,
        'country' => 'DEU',
        'streets' => ['Prinzessinnenstraße 14'],
        'province' => nil }
    end
    reference { 'aut-YRZJyuhpPdfq6vf9DnTd4ubQTuk5FsyP' }
    description { 'VISA 4242' }
    merchant_of_record { 'flow' }

    initialize_with { new(**attributes) }
  end
end
