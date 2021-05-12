# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Calculator::FlowIo, type: :model do
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
        let(:line_item) { order.line_items.first }
        let(:shipment) { order.shipments.first }

        it 'returns previous tax value when order is in cart or address state' do
          %w[cart address].each do |stubed_state|
            expect(order).to(receive(:state).and_return(stubed_state))
            expect(subject.compute(line_item)).to(eq(line_item.included_tax_total))
          end
        end

        context 'when order is not cart nor address state' do
          before(:each) do
            allow(order).to(receive(:state).and_return('complete'))
          end

          context 'when flow returns successfull allocation information' do
            let(:stubed_allocations_details) { build(:flow_allocation_line_detail, number: line_item.sku) }
            let(:stubed_order_details) { build(:flow_allocation_order_detail) }
            let(:stubed_allocations_response) do
              build(:flow_allocation, details: [stubed_allocations_details, stubed_order_details])
            end
            let(:stubed_price) { stubed_allocations_details.included.first.price.amount }

            it 'stores allocations data within flow_order data' do
              allow_any_instance_of(Io::Flow::V0::Clients::Orders).to(receive(:get_allocations_by_number)
                                                                      .and_return(stubed_allocations_response))
              expect(subject.compute(line_item)).to(eq(stubed_price))
              expect(order.reload.flow_order['allocations']).to(match(stubed_allocations_response.as_json))
            end

            it 'returns amount from flow_io for line_item or shipment' do
              allow_any_instance_of(Io::Flow::V0::Clients::Orders).to(receive(:get_allocations_by_number))
              allow(order).to(receive(:flow_allocations).and_return(stubed_allocations_response.as_json))
              [line_item, shipment].each do |item|
                expect(subject.compute(item)).to(eq(stubed_price))
              end
            end

            context 'when subsidies are present' do
              let(:stubed_allocations_details) do
                build(:flow_allocation_line_detail, :with_subsidies, number: line_item.sku)
              end

              it 'returns amount with subsidy from flow_io for line_item or shipment' do
                allow_any_instance_of(Io::Flow::V0::Clients::Orders).to(receive(:get_allocations_by_number))
                allow(order).to(receive(:flow_allocations).and_return(stubed_allocations_response.as_json))
                subsidy_amount = stubed_allocations_details.included
                                                           .find { |x| x.key.value == 'vat_subsidy' }
                                                           .price
                                                           .amount

                expect(subject.compute(line_item)).to(eq(stubed_price + subsidy_amount))
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
