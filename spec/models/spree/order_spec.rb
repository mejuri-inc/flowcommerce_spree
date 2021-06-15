# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Order, type: :model do
  describe '#flow_order_with_payments?' do
    context 'when order has flow_io data' do
      let(:order) { create(:order, :with_flow_data) }

      context 'when payment is present' do
        let(:gateway) { create(:flow_io_gateway) }
        let!(:payment) { create(:payment, order: order, payment_method_id: gateway.id, state: 'completed') }

        it 'returns true if payment is associated to Flow' do
          expect(order.flow_order_with_payments?).to(be_truthy)
        end

        context 'if payment is not associated to Flow' do
          let(:gateway) { create(:flow_io_gateway, type: 'Spree::Gateway::Check') }

          it 'returns false' do
            expect(order.flow_order_with_payments?).to(be_falsy)
          end
        end
      end
    end

    context 'when payment is not present' do
      let(:order) { create(:order) }

      it 'returns false' do
        expect(order.flow_order_with_payments?).to(be_falsy)
      end
    end
  end

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

  describe '#flow_tax_for_item' do
    let(:order) { create(:order_with_line_items) }
    let(:line_item) { order.line_items.first }
    let(:stubed_allocations_details) { build(:flow_allocation_line_detail, number: line_item.sku) }
    let(:stubed_order_details) { build(:flow_allocation_order_detail) }
    let(:stubed_allocations_response) do
      build(:flow_allocation, details: [stubed_allocations_details, stubed_order_details])
    end
    let(:stubed_price) { stubed_allocations_details.included.first.price.amount }

    context 'when no flow_allocations is present' do
      it 'returns blank response' do
        allow(order).to(receive(:flow_allocations).and_return(nil))
        expect(order.__send__(:flow_tax_for_item, line_item, 'vat_item_price')).to(be_blank)
      end
    end

    context 'when flow_allocations is present' do
      before(:each) do
        allow(order).to(receive(:flow_allocations).and_return(stubed_allocations_response.as_json))
      end

      it 'returns tax information for selected item' do
        expect(order.__send__(:flow_tax_for_item, line_item, 'vat_item_price')).to(be_present)
      end

      it 'returns blank response when no key is present' do
        expect(order.__send__(:flow_tax_for_item, line_item, 'vat_subsidy')).to(be_blank)
      end
    end
  end
end
