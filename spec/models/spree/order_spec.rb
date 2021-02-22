# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order, type: :model do
  describe '#prepare_flow_addresses' do
    context 'when order flow_io data' do
      let(:order) { create(:order, :with_flow_data) }
      let(:flow_destination) do
        { 'city' => 'Aachen',
          'postal' => '52064',
          'contact' => { 'name' => { 'last' => 'Test', 'first' => 'Random' },
                         'email' => 'test@mailiniator.com', 'phone' => '1234567890' },
          'country' => 'DEU',
          'streets' => ['Karlsgraben 15'] }
      end
      let(:flow_payments) do
        [{ 'id' => 'opm-2d5aab2bd81649bfae4a9a5269bac270',
           'date' => '2021-02-01T19:42:29.445Z',
           'type' => 'card',
           'total' => { 'base' => { 'label' => 'US$115.22', 'amount' => 115.22, 'currency' => 'USD' },
                        'label' => '96,80 <E2><82><AC>', 'amount' => 96.8, 'currency' => 'EUR' },
           'address' => { 'city' => 'Aachen', 'name' => { 'last' => 'Test', 'first' => 'Random' },
                          'postal' => '52064', 'country' => 'DEU', 'streets' => ['Karlsgraben 15'] },
           'reference' => 'aut-Hxh73jeU9OBynuNwsb7iKzDQlOvMXBRK',
           'attributes' => {},
           'description' => 'VISA 4242',
           'merchant_of_record' => 'flow' }]
      end

      before(:each) do
        create(:country, iso3: 'DEU')
        flow_data = order.flow_data
        flow_data[:order][:destination] = flow_destination
        flow_data[:order][:payments] = flow_payments
        order.flow_data = flow_data
        order.save
      end

      context 'when address does not exists for order' do
        it 'sets ship_address based on customer information' do
          expect { order.prepare_flow_addresses }.to(change(Spree::Address, :count).by(2))
          expect(order.ship_address).to(be_present)
        end

        it 'sets bill_address based on payment information' do
          expect { order.prepare_flow_addresses }.to(change(Spree::Address, :count).by(2))
          expect(order.bill_address).to(be_present)
        end
      end

      context 'when order already has address created' do
        before(:each) { order.prepare_flow_addresses }

        it 'updates current ship address' do
          new_street = 'Gartenstrasse'
          order.flow_data['order']['destination']['streets'][0] = new_street
          order.save
          expect { order.prepare_flow_addresses }.to(change(Spree::Address, :count).by(0))
          expect(order.ship_address.address1).to(eq(new_street))
        end
      end
    end
  end
end
