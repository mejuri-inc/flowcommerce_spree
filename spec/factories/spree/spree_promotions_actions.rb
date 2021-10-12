# frozen_string_literal: true

FactoryBot.define do
  factory :promotion_action, class: Spree::PromotionAction do
  end

  factory :per_item_promotion_action, class: Spree::Promotion::Actions::CreateItemAdjustments do
    association(:promotion, factory: :promotion, strategy: :build)
  end
end
