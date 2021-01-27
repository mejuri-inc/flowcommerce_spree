# frozen_string_literal: true

FactoryBot.define do
  factory :order, class: Spree::Order do
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
             [{ 'key' => 'subtotal',
                'base' => { 'label' => 'US$88.85', 'amount' => 88.85, 'currency' => 'USD' },
                'label' => '80.95 €',
                'amount' => 80.95,
                'accuracy' => 'calculated',
                'currency' => 'EUR',
                'components' =>
                [{ 'key' => 'item _price', 'base' => { 'label' => 'US$74.66', 'amount' => 74.66, 'currency' => 'USD' }, 'name' => 'Item price', 'label' => '62.56 €', 'amount' => 62.56, 'currency' => 'EUR' },
                 { 'key' => 'vat_deminimis',
                   'base' => { 'label' => '-US$1.72', 'amount' => -1.44, 'currency' => 'USD' },
                   'name' => 'VAT de minimis adjustment',
                   'label' => '-1.44 €',
                   'amount' => -1.44,
                   'currency' => 'EUR' },
                 { 'key' => 'vat_duties_item_price',
                   'base' => { 'label' => 'US$1.44', 'amount' => 1.44, 'currency' => 'USD' },
                   'name' => 'VAT on duties on item price',
                   'label' => '1.44 €',
                   'amount' => 1.44,
                   'currency' => 'EUR' },
                 { 'key' => 'vat_item_price',
                   'base' => { 'label' => 'US$14.19', 'amount' => 14.19, 'currency' => 'USD' },
                   'name' => 'VAT on item price',
                   'label' => '11.89 €',
                   'amount' => 11.89,
                   'currency' => 'EUR' }] },
              { 'key' => 'shipping',
                'base' => { 'label' => 'US$338.30', 'amount' => 338.3, 'currency' => 'USD' },
                'name' => 'Shipping',
                'label' => '283,88 €',
                'amount' => 283.88,
                'accuracy' => 'calculated',
                'currency' => 'EUR',
                'components' =>
                [{ 'key' => 'shipping', 'base' => { 'label' => 'US$338.30', 'amount' => 338.3, 'currency' => 'USD' }, 'name' => 'Shipping', 'label' => '283,88 €', 'amount' => 283.88, 'currency' => 'EUR' },
                 { 'key' => 'vat_deminimis',
                   'base' => { 'label' => '-US$7.71', 'amount' => -7.71, 'currency' => 'USD' },
                   'name' => 'VAT de minimis adjustment',
                   'label' => '-6,47 €',
                   'amount' => -6.47,
                   'currency' => 'EUR' },
                 { 'key' => 'vat_duties_freight',
                   'base' => { 'label' => 'US$7.71', 'amount' => 7.71, 'currency' => 'USD' },
                   'name' => 'VAT on duties on freight',
                   'label' => '6,47 €',
                   'amount' => 6.47,
                   'currency' => 'EUR' },
                 { 'key' => 'vat_freight', 'base' => { 'label' => 'US$64.28', 'amount' => 64.28, 'currency' => 'USD' }, 'name' => 'VAT on freight', 'label' => '53,94 €', 'amount' => 53.94, 'currency' => 'EUR' },
                 { 'key' => 'vat_subsidy',
                   'base' => { 'label' => '-US$64.28', 'amount' => -64.28, 'currency' => 'USD' },
                   'name' => 'VAT subsidy',
                   'label' => '-53,94 €',
                   'amount' => -53.94,
                   'currency' => 'EUR' }] }] }
        } }
      end
    end
  end
end
