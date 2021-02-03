# frozen_string_literal: true

FactoryBot.define do
  sequence(:random_float) { BigDecimal("#{rand(200)}.#{rand(99)}") }

  factory :base_variant, class: Spree::Variant do
    price { 19.99 }
    cost_price { 17.00 }
    sequence(:sku) { |n| "p0000#{n}" }
    is_master { 0 }

    product { |p| p.association(:product) }
    option_values { [create(:option_value)] }

    before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }

    trait :with_flow_data do
      after(:create) do |variant|
        flow_data = variant.meta[:flow_data] || {}
        flow_data[:exp] ||= {}
        flow_data[:exp][:germany] = {
          prices: [
            { key: 'localized_item_price', base: { label: 'US$88.85', amount: 88.85, currency: 'USD' },
              label: '80.95 €', amount: 80.95, currency: 'EUR', includes: { key: 'vat', label: 'Includes VAT' } }
          ], status: 'included'
        }
        flow_data[:exp][:france] = {
          prices: [
            { key: 'localized_item_price', base: { label: 'US$78.85', amount: 78.85, currency: 'USD' },
              label: '70.95 €', amount: 70.95, currency: 'EUR', includes: { key: 'vat', label: 'Includes VAT' } }
          ], status: 'included'
        }
        variant.update_columns(meta: { flow_data: flow_data }.to_json)

        germany_zone = Spree::Zones::Product.find_by(name: 'Germany') || create(:germany_zone, :with_flow_data)
        france_zone = Spree::Zones::Product.find_by(name: 'France') || create(:france_zone, :with_flow_data)
        variant.product.update_columns(meta: { zone_ids: [germany_zone.id.to_s, france_zone.id.to_s] }.to_json)
      end
    end

    trait :with_cad_price do
      after(:create) do |variant|
        Spree::Price.create(variant_id: variant.id, amount: variant.product.price, currency: 'CAD')
      end
    end

    trait :with_aud_price do
      after(:create) do |variant|
        Spree::Price.create(variant_id: variant.id, amount: variant.product.price, currency: 'AUD')
      end
    end

    trait :with_gbp_price do
      after(:create) do |variant|
        Spree::Price.create(variant_id: variant.id, amount: variant.product.price, currency: 'GBP')
      end
    end

    factory :master_variant do
      is_master { true }
    end
  end
end
