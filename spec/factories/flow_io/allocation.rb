# frozen_string_literal: true

FactoryBot.define do
  factory :flow_allocation, class: Io::Flow::V0::Models::AllocationV2 do
    id { Faker::Guid.guid }
    discriminator { 'allocation_line_detail' }

    details { [build(:flow_allocation_line_detail)] }
    order { build(:flow_order_summary) }
    total { build(:flow_localized_total) }

    initialize_with { new(**attributes) }
  end
end
