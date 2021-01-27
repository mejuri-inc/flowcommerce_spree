FactoryBot.define do
  factory :tax_rate, class: Spree::TaxRate do
    zone
    amount { 0.1 }
    tax_category
    association(:calculator, factory: :default_tax_calculator, strategy: :build)
  end

  factory :included_tax_rate, class: Spree::TaxRate do
    association :zone, factory: %i[zone default_zone]
    amount { 0.1 }
    tax_category
    association(:calculator, factory: :default_tax_calculator, strategy: :build)

    after(:create) do |tax_rate|
      tax_rate.included_in_price = true
      tax_rate.save
    end
  end
end
