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

      it 'return previous tax value when does not have flow.io data' do
        order = create(:order_with_line_items)
        line_item = order.line_items.first

        expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
      end

      context 'when order has flow data' do
        let(:order) { create(:order_with_line_items, :with_flow_data) }
        let(:stubed_amount) { 11.97 }
        let(:line_item) { order.line_items.first }
        let(:shipment) { order.shipments.first }

        context 'when flow returns successfull allocation information' do
          let(:stubed_response) { flow_example_allocation(order.number, line_item.variant.sku, stubed_amount) }

          it 'returns amount from flow.io for line_item' do
            allow(FlowcommerceSpree::Api).to(receive(:run).and_return(stubed_response))

            expect(subject.compute(line_item)).to(eq(stubed_amount))
          end

          it 'returns amount from flow.io for shipment' do
            allow(FlowcommerceSpree::Api).to(receive(:run).and_return(stubed_response))

            expect(subject.compute(shipment)).to(eq(stubed_amount))
          end
        end

        context 'when flow does not return any data' do
          let(:stubed_response) { nil }

          it 'returns prev_tax_amount if included_in_price' do
            allow(FlowcommerceSpree::Api).to(receive(:run).and_return(stubed_response))

            expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
          end

          it 'returns additional_tax_total if not included_in_price' do
            allow(tax_rate).to(receive(:included_in_price).and_return(false))
            allow(FlowcommerceSpree::Api).to(receive(:run).and_return(stubed_response))

            expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
          end
        end
      end
    end
  end
end
