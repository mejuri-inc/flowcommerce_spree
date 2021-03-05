# frozen_string_literal: true

FactoryBot.define do
  factory :order, class: Spree::Order do

    sequence(:email) { |n| "person#{n}@example.com" }

    transient do
      line_items_price { BigDecimal(10) }
    end

    factory :order_with_line_items do
      transient do
        line_items_count { 1 }
        shipment_cost { 100 }
      end

      after(:create) do |order, evaluator|
        order.shipments << create(:shipment, order: order, cost: evaluator.shipment_cost)

        create_list(:line_item, evaluator.line_items_count, order: order, price: evaluator.line_items_price)
        order.line_items.reload
        order.update!
      end
    end

    trait :with_flow_data do |_product|
      meta do
        { flow_data: {
          'exp' => 'germany',
          'order' =>
        { 'id' => 'ord-f30ff51cb798466ba2574d0b9fac5fb7',
          'geo' => { 'ip' => '34.231.21.161', 'country' => 'DEU', 'currency' => 'EUR', 'language' => nil },
          'items' =>
          [{ 'id' => 'lin-a33d82d72ca5451cbf59fab9d56800c3',
             'name' => 'Small Hoops',
             'local' =>
            { 'rates' => [],
              'prices' =>
              [{ 'key' => 'localized_item_price',
                 'base' => { 'label' => 'US$88.85', 'amount' => 88.85, 'currency' => 'USD' },
                 'label' => '70.95 €', 'amount' => 80.95, 'currency' => 'EUR',
                 'includes' => { 'key' => 'vat', 'label' => 'Includes VAT' } }],
              'status' => 'included' },
             'price' => { 'amount' => 80.95, 'currency' => 'EUR' },
             'number' => 'p52505531',
             'discount' => nil,
             'quantity' => 1,
             'discounts' => nil,
             'price_source' => { 'price' => { 'amount' => 80.95, 'currency' => 'EUR' }, 'discriminator' => 'provided' },
             'shipment_estimate' => nil }],
          'lines' =>
          [{ 'id' => 'lin-a33d82d72ca5451cbf59fab9d56800c3',
             'price' => { 'base' => { 'label' => 'US$88.85', 'amount' => 88.85, 'currency' => 'USD' },
                          'label' => '80.95 €', 'amount' => 80.95, 'currency' => 'EUR' },
             'total' => { 'base' => { 'label' => 'US$88.85', 'amount' => 88.85, 'currency' => 'USD' },
                          'label' => '80.95 €', 'amount' => 80.95, 'currency' => 'EUR' },
             'quantity' => 2,
             'item_number' => 'p52505531' }],
          'prices' =>
          [{ 'key' => 'shipping',
             'currency' => 'EUR',
             'amount' => 283.3,
             'label' => '283,30 €',
             'base' => { 'amount' => 338.3, 'currency' => 'USD', 'label' => 'US$338.30' },
             'components' =>
              [{ 'key' => 'shipping', 'currency' => 'EUR', 'amount' => 283.3, 'label' => '283,30 €', 'base' =>
                { 'amount' => 338.3, 'currency' => 'USD', 'label' => 'US$338.30' }, 'name' => 'Shipping' },
               { 'key' => 'vat_deminimis', 'currency' => 'EUR', 'amount' => -6.46,
                 'label' => '-6,46 €', 'base' => { 'amount' => -7.71, 'currency' => 'USD', 'label' => '-US$7.71' },
                 'name' => 'VAT de minimis adjustment' },
               { 'key' => 'vat_duties_freight', 'currency' => 'EUR', 'amount' => 6.46,
                 'label' => '6,46 €', 'base' => { 'amount' => 7.71, 'currency' => 'USD', 'label' => 'US$7.71' },
                 'name' => 'VAT on duties on freight' },
               { 'key' => 'vat_freight', 'currency' => 'EUR', 'amount' => 53.83, 'label' => '53,83 €', 'base' =>
               { 'amount' => 64.28, 'currency' => 'USD', 'label' => 'US$64.28' }, 'name' => 'VAT on freight' },
               { 'key' => 'vat_subsidy', 'currency' => 'EUR', 'amount' => -53.83,
                 'label' => '-53,83 €', 'base' => { 'amount' => -64.28, 'currency' => 'USD', 'label' => '-US$64.28' },
                 'name' => 'VAT subsidy' }],
             'accuracy' => 'calculated',
             'name' => 'Shipping' }] }
        } }
      end
    end
  end
end
