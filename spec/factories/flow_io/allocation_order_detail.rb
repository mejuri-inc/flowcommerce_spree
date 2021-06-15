# frozen_string_literal: true

FactoryBot.define do
  factory :flow_allocation_order_detail, class: Io::Flow::V0::Models::AllocationOrderDetail do
    discriminator { 'allocation_detail_component' }
    key { 'shipping' }
    total { build(:flow_price_with_base) }

    included do
      [
        build(:flow_allocation_detail_component),
        build(:flow_allocation_detail_component_rounding),
        build(:flow_allocation_detail_component_vat)
      ]
    end
    not_included { [] }

    initialize_with { new(**attributes) }
  end
end
