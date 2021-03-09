# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Gateway::FlowIo do
  let(:gateway) { create(:flow_io_gateway) }

  describe '#provider_class' do
    it 'returns provider`s class`' do
      expect(gateway.provider_class.name).to eql('Spree::Gateway::FlowIo')
    end
  end

  describe '#refund' do
    let(:order) { create(:order_with_line_items) }
    let(:payment_auth) { build(:flow_authorization_reference) }
    let!(:payment) { create(:payment, order: order, payment_method_id: gateway.id, response_code: payment_auth.id) }
    let(:amount) { order.item_total }
    let(:refund) { build(:flow_refund, currency: order.currency, amount: amount, authorization: payment_auth) }

    context 'when refund has succeeded' do
      before do
        allow(FlowcommerceSpree).to receive_message_chain(:client, :refunds, :post).and_return(refund)
      end

      it 'returns a successful response, ads refund to the order`s flow_data, creates negative amount payment' do
        allow(gateway).to receive(:add_refund_to_order).and_call_original
        allow(gateway).to receive(:map_refund_to_payment).and_call_original

        expect(gateway).to receive(:add_refund_to_order).with(refund, order)
        expect(gateway).to receive(:map_refund_to_payment).with(refund, order)

        result = nil
        expect { result = gateway.refund(payment, amount) }.to change { Spree::Payment.count }.from(1).to(2)

        expect(result).to be_instance_of(ActiveMerchant::Billing::Response)
        expect(result.message).to eql(Spree::Gateway::FlowIo::REFUND_SUCCESS)
        expect(result.success?).to eql(true)

        order.reload
        order_refunds = order.flow_data['refunds']
        expect(order_refunds).to be_instance_of(Array)

        order_refund = order_refunds.first
        order_refund_captures = order_refund.delete('captures')
        expect(order_refund_captures).to be_instance_of(Array)

        refund_capture = order_refund_captures.first['capture']
        expect(order_refund.except('created_at'))
          .to eql(refund.to_hash.except(:captures, :created_at).deep_stringify_keys!)
        expect(refund_capture.except('created_at'))
          .to eql(refund.to_hash[:captures].first[:capture].deep_stringify_keys!.except('created_at'))

        created_payment = Spree::Payment.find_by(identifier: refund.id)

        expect(created_payment.amount).to eql(- amount)
      end
    end

    context 'when refund has failed' do
      before do
        allow(FlowcommerceSpree)
          .to receive_message_chain(:client, :refunds, :post).and_raise(StandardError, 'Some error')
      end

      it 'returns an unsuccessful ActiveMerchant::Billing::Response and don`t add refund to order`s flow_data' do
        allow(gateway).to receive(:add_refund_to_order).and_call_original
        expect(gateway).not_to receive(:add_refund_to_order)

        result = gateway.refund(payment, amount)

        expect(result).to be_instance_of(ActiveMerchant::Billing::Response)
        expect(result.message).to eql('Some error')
        expect(result.success?).to eql(false)
      end
    end
  end
end
