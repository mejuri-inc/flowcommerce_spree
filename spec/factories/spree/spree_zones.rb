# frozen_string_literal: true

FactoryBot.define do
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
