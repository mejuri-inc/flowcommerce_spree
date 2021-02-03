# frozen_string_literal: true

FactoryBot.define do
  factory :product, class: Spree::Product do
    sequence(:name) { |n| "Product ##{n} - #{Kernel.rand(9999)}" }
    description { 'This is a random description for a product' }
    price { 19.99 }
    cost_price { 17.00 }
    available_on { 1.year.ago }
    deleted_at { nil }
    shipping_category { |r| Spree::ShippingCategory.first || r.association(:shipping_category) }

    trait :with_master_variant_flow_data do
      after(:create) do |product|
        flow_data = product.master.meta[:flow_data] || {}
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
        product.master.update_columns(meta: { flow_data: flow_data }.to_json)

        germany_zone = Spree::Zones::Product.find_by(name: 'Germany') || create(:germany_zone, :with_flow_data)
        france_zone = Spree::Zones::Product.find_by(name: 'France') || create(:france_zone, :with_flow_data)
        product.update_columns(meta: { zone_ids: [germany_zone.id.to_s, france_zone.id.to_s] }.to_json)
      end
    end

    trait :with_cad_price do
      after(:create) do |product|
        Spree::Price.create(variant_id: Spree::Variant.find_by(product_id: product.id).id,
                            amount: product.price, currency: 'CAD')
      end
    end

    trait :with_aud_price do
      after(:create) do |product|
        Spree::Price.create(variant_id: Spree::Variant.find_by(product_id: product.id).id,
                            amount: product.price, currency: 'AUD')
      end
    end

    trait :with_gbp_price do
      after(:create) do |product|
        Spree::Price.create(variant_id: Spree::Variant.find_by(product_id: product.id).id,
                            amount: product.price, currency: 'GBP')
      end
    end
  end
end
