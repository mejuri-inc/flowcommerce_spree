FactoryBot.define do
    factory :promotion, class: Spree::Promotion do
      name { 'test' }
      description { 'description' }
    end
  
    trait :with_order_adjustment do
      transient do
        order_adjustment_amount { 10 }
      end
  
      after(:create) do |promotion, evaluator|
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = evaluator.order_adjustment_amount
        action = Spree::Promotion::Actions::CreateAdjustment.create!(calculator: calculator)
        promotion.actions << action
        promotion.save!
      end
    end
  
  end
  