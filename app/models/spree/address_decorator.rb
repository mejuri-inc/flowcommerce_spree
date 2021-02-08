# frozen_string_literal: true

module Spree
  Address.class_eval do
    def update_attributes_from_params(address_data)
      self.attributes = {
        first_name: address_data.dig('name', 'first'),
        last_name: address_data.dig('name', 'last'),
        phone: address_data['phone'],
        address1: address_data['streets'][0],
        address2: address_data['streets'][1],
        zipcode: address_data['postal'],
        city: address_data['city'],
        state_name: address_data['province'] || 'something',
        country: Spree::Country.find_by(iso3: address_data['country'])
      }
    end
  end
end
