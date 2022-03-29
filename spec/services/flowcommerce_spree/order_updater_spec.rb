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
    let(:order) { create(:order_with_line_items, :with_flow_data, line_items_count: 2, zone: zone) }
    let(:flowcommerce_client) { FlowcommerceSpree.client }

    before do
      allow(FlowcommerceSpree).to receive(:client).and_return(flowcommerce_client)
      allow_any_instance_of(FlowcommerceSpree::OrderSync).to receive(:synchronize!)
    end

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
            .and_return(submitted_at: Time.current, customer: { email: 'test@mejuri.com' }))
        end

        it 'updates order to state `payment` and calls several methods to update the order related records' do
          expect(order).to(receive(:create_proposed_shipments))
          order.line_items.each { |item| expect(item).to(receive(:store_ets).exactly(1).times) }
          expect(order).to(receive(:charge_taxes))

          subject.new(order: order).upsert_data
          expect(order.payment?).to(be_truthy)
        end
      end
    end

    describe '#finalize_order' do
      it 'Sets order as completed with completed_at filled' do
        expect(order).to(receive(:finalize!)).and_call_original
        expect(order).to(receive(:update_totals)).and_call_original
        expect(order).to(receive(:after_completed_order)).and_call_original

        subject.new(order: order).finalize_order

        expect(order.completed_at).to(be_present)
      end
    end

    describe '#complete_checkout' do
      let(:payment_method) { create(:spree_payment_method_flow) }
      let(:order_payment) { create(:payment, :completed) }
      before do
        order.payments << order_payment
        allow(Spree::PaymentMethod).to receive(:find_by).and_return(payment_method)
        expect_any_instance_of(FlowcommerceSpree::OrderUpdater).to(receive(:upsert_data))
        expect_any_instance_of(FlowcommerceSpree::OrderUpdater).to(receive(:map_payments_to_spree)).and_call_original
      end

      context 'when payments amount is equal or greater than order`s amount' do
        before do
          allow(order).to(receive(:amount).and_return(order.payments.sum(:amount)))
        end

        it 'calls finalize_order method' do
          expect_any_instance_of(FlowcommerceSpree::OrderUpdater).to(receive(:finalize_order))
          subject.new(order: order).complete_checkout
        end
      end

      context 'when payments amount is less than order`s amount' do
        it 'does not call finalize_order if order is not updated to`complete`' do
          allow(order).to(receive(:flow_io_total_amount).and_return(order.payments.sum(:amount) + 1))
          expect_any_instance_of(FlowcommerceSpree::OrderUpdater).not_to(receive(:finalize_order))
          subject.new(order: order).complete_checkout
        end
      end
    end

    describe '#map_payments_to_spree' do
      before do
        FactoryBot.create(:flow_io_gateway)
      end

      context 'when payment amount is equal or greater than the order`s amount' do
        let(:flow_io_payments) { build(:flow_order_payment) }
        it 'creates payment using information from flow' do
          allow(order).to(receive(:flow_io_payments).and_return([flow_io_payments.to_hash.with_indifferent_access]))
          subject.new(order: order).map_payments_to_spree

          payment = order.payments.first
          expect(payment.response_code).to(eq(flow_io_payments.reference))
          expect(payment.identifier).to(eq(flow_io_payments.id))
          expect(payment.amount).to(eq(flow_io_payments.total.amount))
          expect(order.complete?).to(be_truthy)
        end
      end

      context 'when there is no flow payments information' do
        it 'does updates order as complete with placeholder payment' do
          allow(order).to(receive(:flow_io_payments).and_return([]))
          allow(order).to(receive(:flow_io_total_amount).and_return(100))
          subject.new(order: order).map_payments_to_spree

          expect(order.complete?).to(be_truthy)
          expect(order.payments.first.response_code).to be(nil)
        end
      end
    end
  end
end
