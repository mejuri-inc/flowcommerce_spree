# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderUpdater do
  subject { FlowcommerceSpree::OrderUpdater }

  context 'when no order is passed' do
    it 'raises exception' do
      expect { subject.new }.to raise_error(ArgumentError, 'missing keyword: order')
    end
  end

  context 'when order is not present' do
    it 'raises exception' do
      expect { subject.new(order: nil) }.to raise_error(ArgumentError, 'Experience not defined or not active')
    end
  end

  context 'when the order has no flow experience' do
    let(:order) { create(:order) }

    it 'raises exception' do
      expect { subject.new(order: order) }.to raise_error(ArgumentError, 'Experience not defined or not active')
    end
  end

  context 'when the order has a flow experience defined' do
    let(:zone) { create(:germany_zone, :with_flow_data) }
    let(:order) { create(:order_with_line_items, :with_flow_data, zone: zone) }
    let(:flowcommerce_client) { FlowcommerceSpree.client }

    before { allow(FlowcommerceSpree).to receive(:client).and_return(flowcommerce_client) }

    it 'initalizes successfully' do
      instance = subject.new(order: order)

      expect(instance.instance_variable_get(:@experience)).to eql(order.flow_io_experience_key)
      expect(instance.instance_variable_get(:@order)).to eql(order)
      expect(instance.instance_variable_get(:@client)).to eql(flowcommerce_client)
    end

    describe '#upsert_data' do
      context 'if order status is `complete`' do
        it 'does nothing' do
          order.state = 'complete'
          expect(order).not_to(receive(:create_proposed_shipments))
          expect(order).not_to(receive(:charge_taxes))

          subject.new(order: order).upsert_data
          expect(order.complete?).to(be_truthy)
        end
      end

      context 'if order status is not `complete`' do
        before do
          allow_any_instance_of(Io::Flow::V0::Clients::Orders)
            .to(receive(:get_by_number)
            .and_return({ submitted_at: Time.current, customer: { email: 'test@mejuri.com' } }))
        end

        it 'updates order to state `payment` and calls several methods to update the order related records' do
          expect(order).to(receive(:create_proposed_shipments))
          expect_any_instance_of(Spree::LineItem).to(receive(:store_ets))
          expect(order).to(receive(:charge_taxes))

          subject.new(order: order).upsert_data
          expect(order.payment?).to(be_truthy)
        end
      end
    end
  end
end
