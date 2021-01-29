# frozen_string_literal: true

require 'rails_helper'
require 'support/flowcommerce_example_response'

RSpec.describe Spree::Calculator::FlowcommerceCalculator, type: :model do
  describe '#compute' do
    context 'when taxes and duties are included in price' do
      let(:tax_rate) { create(:included_tax_rate) }

      before(:each) do
        allow(subject).to(receive(:rate).and_return(tax_rate))
      end

      it 'return previous tax value when does not have flow_io data' do
        order = create(:order_with_line_items)
        line_item = order.line_items.first

        expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
      end

      context 'when order has flow data' do
        let(:order) { create(:order_with_line_items, :with_flow_data) }
        let(:stubed_amount) { 11.97 }
        let(:line_item) { order.line_items.first }
        let(:shipment) { order.shipments.first }

        it 'returns previous tax value when order is in cart, address or delivery state' do
          %w[cart address delivery].each do |stubed_state|
            expect(order).to(receive(:state).and_return(stubed_state))
            expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
          end
        end

        context 'when order is not cart, address not delivery state' do
          before(:each) do
            allow(order).to(receive(:state).and_return('complete'))
          end

          context 'when flow returns successfull allocation information' do
            let(:stubed_response) { flow_example_allocation(order.number, line_item.variant.sku, stubed_amount) }

            it 'returns amount from flow_io for line_item or shipment' do
              allow_any_instance_of(Io::Flow::V0::Clients::Orders).to(receive(:get_allocations_by_number)
                                                                      .and_return(stubed_response))
              [line_item, shipment].each do |item|
                expect(subject.compute(item)).to(eq(stubed_amount))
              end
            end
          end

          context 'when flow does not return any data' do
            let(:stubed_response) { nil }
            before(:each) do
              allow_any_instance_of(Io::Flow::V0::Clients::Orders).to(receive(:get_allocations_by_number)
                                                                      .and_return(stubed_response))
            end

            it 'returns prev_tax_amount if included_in_price' do
              expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
            end

            it 'returns additional_tax_total if not included_in_price' do
              allow(tax_rate).to(receive(:included_in_price).and_return(false))

              expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
            end
          end
        end
      end
    end
  end
end
