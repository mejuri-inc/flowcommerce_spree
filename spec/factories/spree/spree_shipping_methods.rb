FactoryBot.define do
  factory :base_shipping_method, class: Spree::ShippingMethod do
    name { 'UPS Ground' }
    admin_name { 'UPS Ground' }

    before(:create) do |shipping_method, evaluator|
      if shipping_method.shipping_categories.empty?
        shipping_method.shipping_categories << (Spree::ShippingCategory.first || create(:shipping_category))
      end
    end

    after(:create) do |shipping_method, evaluator|
      shipping_method.zones << (Spree::Zone.find_by(name: 'GlobalZone') || FactoryBot.create(:global_zone))
    end

    factory :shipping_method, class: Spree::ShippingMethod do
      association(:calculator, factory: :shipping_calculator, strategy: :build)
    end

    factory :pick_up_shipping_method, class: Spree::ShippingMethod do
      association(:calculator, factory: :pick_up_shipping_calculator, strategy: :build)
    end

    factory :walkout_shipping_method, class: Spree::ShippingMethod do
      association(:calculator, factory: :walkout_shipping_calculator, strategy: :build)
    end
  end
end
