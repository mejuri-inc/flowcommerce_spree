# frozen_string_literal: true

def flow_example_allocation(order_number, variant_sku, amount)
  response = {
    'id' => 'alc-5c6c3b5e10b44e4fb4063ec19fa10f65',
    'order' => {
      'id' => 'ord-550219e93efe4bfb8d4c32cf9e6d589e',
      'number' => order_number,
      'submitted_at' => '2021-01-27T18:29:04.266Z'
    },
    'details' =>
    [
      { 'number' => variant_sku,
        'quantity' => 1,
        'key' => 'subtotal',
        'price' => { 'currency' => 'EUR', 'amount' => 74.95, 'label' => '74,95 €', 'base' => {
          'amount' => 89.46, 'currency' => 'USD', 'label' => 'US$89.46'
        } },
        'total' => { 'currency' => 'EUR', 'amount' => 74.95, 'label' => '74,95 €', 'base' => {
          'amount' => 89.46, 'currency' => 'USD', 'label' => 'US$89.46'
        } },
        'included' =>
      [{ 'key' => 'item_price',
         'total' => { 'currency' => 'EUR', 'amount' => 62.98, 'label' => '62,98 €', 'base' => {
           'amount' => 75.17, 'currency' => 'USD', 'label' => 'US$75.17'
         } },
         'price' => { 'currency' => 'EUR', 'amount' => 62.98, 'label' => '62,98 €', 'base' => {
           'amount' => 75.17, 'currency' => 'USD', 'label' => 'US$75.17'
         } },
         'discriminator' => 'allocation_detail_component' },
       { 'key' => 'rounding',
         'total' => { 'currency' => 'EUR', 'amount' => 0, 'label' => '0,00 €', 'base' => {
           'amount' => 0, 'currency' => 'USD', 'label' => 'US$0.00'
         } },
         'price' => { 'currency' => 'EUR', 'amount' => 0, 'label' => '0,00 €', 'base' => {
           'amount' => 0, 'currency' => 'USD', 'label' => 'US$0.00'
         } },
         'discriminator' => 'allocation_detail_component' },
       { 'key' => 'vat_item_price',
         'total' => { 'currency' => 'EUR', 'amount' => amount, 'label' => '11,97 €', 'base' => {
           'amount' => 14.29, 'currency' => 'USD', 'label' => 'US$14.29'
         } },
         'rate' => 0.19,
         'name' => 'VAT',
         'accuracy' => 'calculated',
         'price' => { 'currency' => 'EUR', 'amount' => amount, 'label' => '11,97 €', 'base' => {
           'amount' => 14.29, 'currency' => 'USD', 'label' => 'US$14.29'
         } },
         'discriminator' => 'allocation_levy_component' }],
        'not_included' => [],
        'id' => 'lin-c7e3f2fdf8b547538e6f29bc01827cad',
        'discriminator' => 'allocation_line_detail' },
      { 'key' => 'shipping',
        'total' => { 'currency' => 'EUR', 'amount' => 283.46, 'label' => '283,46 €', 'base' => {
          'amount' => 338.3, 'currency' => 'USD', 'label' => 'US$338.30'
        } },
        'included' =>
        [{ 'key' => 'shipping',
           'total' => { 'currency' => 'EUR', 'amount' => 229.23, 'label' => '229.23 €', 'base' => {
             'amount' => 338.3, 'currency' => 'USD', 'label' => 'US$338.30'
           } },
           'price' => { 'currency' => 'EUR', 'amount' => 229.23, 'label' => '229.23 €', 'base' => {
             'amount' => 338.3, 'currency' => 'USD', 'label' => 'US$338.30'
           } },
           'discriminator' => 'allocation_detail_component' },
         { 'key' => 'vat_item_price',
           'total' => { 'currency' => 'EUR', 'amount' => amount, 'label' => '11,97 €', 'base' => {
             'amount' => 14.29, 'currency' => 'USD', 'label' => 'US$14.29'
           } },
           'rate' => 0.19,
           'name' => 'VAT',
           'accuracy' => 'calculated',
           'price' => { 'currency' => 'EUR', 'amount' => amount, 'label' => '11,97 €', 'base' => {
             'amount' => 14.29, 'currency' => 'USD', 'label' => 'US$14.29'
           } },
           'discriminator' => 'allocation_levy_component' }],
        'not_included' => [],
        'discriminator' => 'allocation_order_detail' }
    ],
    'total' => { 'currency' => 'EUR', 'amount' => 358.41, 'label' => '358,41 €', 'base' => {
      'amount' => 427.76, 'currency' => 'USD', 'label' => 'US$427.76'
    }, 'key' => 'localized_total' }
  }
  ::Io::Flow::V0::Models::AllocationV2.new(response)
end
