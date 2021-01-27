# frozen_string_literal: true

FactoryBot.define do
  factory :global_zone, class: Spree::Zone do
    name { 'GlobalZone' }
    status { 'active' }
    description { "Description for Global Zone #{name}" }
    after(:create) do |zone, _evaluator|
      Spree::Country.all.map do |c|
        Spree::ZoneMember.create(zoneable: c, zone: zone)
      end
    end
  end

  factory :zone, class: Spree::Zone do
    name { Faker::Address.country }
    description { 'Description for Zone' }
    status { 'active' }

    trait :default_zone do
      default_tax true
    end
  end

  factory :germany_zone, class: Spree::Zones::Product do
    name { 'Germany' }
    description { 'Germany Zone' }
    status { 'active' }

    zone_members do |proxy|
      zone = proxy.instance_eval { @instance }
      country = create(:country, iso: ISO3166::Country.find_country_by_name(name).alpha2)
      [Spree::ZoneMember.create(zoneable: country, zone: zone)]
    end

    trait :with_flow_data do
      meta { { flow_data: { name: 'Germany', key: 'germany', country: 'DEU', currency: 'EUR' } } }
    end
  end

  factory :france_zone, class: Spree::Zones::Product do
    name { 'France' }
    description { 'France Zone' }
    status { 'active' }

    zone_members do |proxy|
      zone = proxy.instance_eval { @instance }
      country = create(:country, iso: ISO3166::Country.find_country_by_name(name).alpha2)
      [Spree::ZoneMember.create(zoneable: country, zone: zone)]
    end

    trait :with_flow_data do
      meta { { flow_data: { name: 'France', key: 'france', country: 'FRA', currency: 'EUR' } } }
    end
  end
end
