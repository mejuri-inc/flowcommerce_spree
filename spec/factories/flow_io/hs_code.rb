# frozen_string_literal: true

FactoryBot.define do
  factory :flow_hs_code, class: Io::Flow::V0::Models::Hs10 do
    id { Faker::Guid.guid }
    origin { 'CAN' }
    destination { 'DEU' }
    code { '71131910' }
    item do
      Io::Flow::V0::Models::HarmonizedItemReference.new(
        description: 'jewellery precious_metal',
        id: 'cit-b1d68224735e4828a51b0be90ad37c6f',
        number: Spree::Variant.first&.sku || create(:base_variant).sku
      )
    end
    initialize_with { new(**attributes) }
  end
end
