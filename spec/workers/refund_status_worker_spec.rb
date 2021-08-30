# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::RefundStatusWorker, type: :worker do
  subject(:job) { described_class.new }
  let(:gateway) { create(:flow_io_gateway) }
  let(:order) { create(:order_with_line_items) }
  let(:payment_auth) { build(:flow_authorization_reference) }
  let!(:payment) { create(:payment, order: order, payment_method_id: gateway.id, response_code: payment_auth.id) }
  let(:amount) { order.item_total }

  context 'when state is completed' do
    let(:refund) { build(:flow_refund, currency: order.currency, amount: amount, authorization: payment_auth) }

    it 'doesnt raise exception ' do
      allow(FlowcommerceSpree).to receive_message_chain(:client, :refunds, :request_refund_status).and_return(refund)

      expect { job.perform(order, refund.key) }.not_to raise_error
    end
  end
  context 'when state is not completed' do
    let(:capture) { build(:flow_capture, status: 'pending') }
    let(:refund) do
      build(:flow_refund, captures: [{ capture: capture.to_hash, amount: capture.amount }],
            currency: order.currency, amount: amount, authorization: payment_auth)
    end

    it 'raises exception' do
      refund.captures.first.capture.status.instance_values['value'] = 'pending'
      allow(FlowcommerceSpree).to receive_message_chain(:client, :refunds, :request_refund_status).and_return(refund)
      expect { job.perform(order, refund.key) }.to raise_error
    end
  end
end