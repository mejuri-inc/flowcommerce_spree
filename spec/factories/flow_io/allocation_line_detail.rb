# frozen_string_literal: true

FactoryBot.define do
  factory :flow_allocation_line_detail, class: Io::Flow::V0::Models::AllocationLineDetail do
    id { Faker::Guid.guid }
    discriminator { 'allocation_detail_component' }
    key { 'subtotal' }
    number { 'p0001' }
    quantity { 1 }
    total { build(:flow_price_with_base) }
    price { build(:flow_price_with_base) }

    included do
      [
        build(:flow_allocation_detail_component),
        build(:flow_allocation_detail_component_rounding),
        build(:flow_allocation_detail_component_vat),
        build(:flow_allocation_detail_component_duty)
      ]
    end
    not_included { [] }

    trait :with_subsidies do
      included do
        [
          build(:flow_allocation_detail_component),
          build(:flow_allocation_detail_component_rounding),
          build(:flow_allocation_detail_component_vat),
          build(:flow_allocation_detail_component_vat_subsidy)
        ]
      end
    end

    initialize_with { new(**attributes) }
  end
end
