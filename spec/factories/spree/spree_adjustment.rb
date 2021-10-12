# frozen_string_literal: true

FactoryBot.define do
  factory :adjustment, class: Spree::Adjustment do
    association(:adjustable, factory: :order)
    label { 'test' }
    amount { 100 }
  end

  factory :promotion_adjustment, class: Spree::Adjustment do
    association(:adjustable, factory: :line_item)
    amount { -10.0 }
    label 'Promotion'
    association(:source, factory: :per_item_promotion_action)
    eligible true
  end
end
