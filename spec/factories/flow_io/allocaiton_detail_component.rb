# frozen_string_literal: true

FactoryBot.define do
  factory :flow_allocation_detail_component, class: Io::Flow::V0::Models::AllocationDetailComponent do
    discriminator { 'allocation_detail_component' }
    key { 'item_price' }
    total { build(:flow_price_with_base) }
    price { build(:flow_price_with_base) }

    factory :flow_allocation_detail_component_rounding do
      key { 'rounding' }
      total { build(:flow_price_with_base, amount: 0.0) }
      price { build(:flow_price_with_base, amount: 0.0) }
    end

    factory :flow_allocation_detail_component_vat do
      key { 'vat_item_price' }
    end

    factory :flow_allocation_detail_component_vat_subsidy do
      key { 'vat_subsidy' }
      total { build(:flow_price_with_base, amount: -50) }
      price { build(:flow_price_with_base, amount: -50) }
    end

    factory :flow_allocation_detail_component_duty do
      key { 'duties_item_price' }
    end

    factory :flow_allocation_detail_component_duty_subsidy do
      key { 'duty_subsidy' }
      total { build(:flow_price_with_base, amount: -50) }
      price { build(:flow_price_with_base, amount: -50) }
    end

    initialize_with { new(**attributes) }
  end
end
