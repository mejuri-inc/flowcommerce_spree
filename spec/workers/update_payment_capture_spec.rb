# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::UpdatePaymentCapture, type: :worker do
  let(:gateway) { create(:flow_io_gateway) }
  let(:order) { create(:order) }
  subject(:job) { described_class.new }

  describe '#perform' do
    context 'when order has payments' do
      let!(:payment) { create(:payment, order: order, payment_method_id: gateway.id) }

      it 'calls CaptureUpsertedV2#store_payment_capture method' do
        expect_any_instance_of(FlowcommerceSpree::Webhooks::CaptureUpsertedV2).to(receive(:store_payment_capture))
        job.perform(order.number, anything)
      end
    end

    context 'when order has no payments' do
      it 'does not call CaptureUpsertedV2#store_payment_capture method' do
        expect_any_instance_of(FlowcommerceSpree::Webhooks::CaptureUpsertedV2).not_to(receive(:store_payment_capture))
        expect { job.perform(order.number, anything) }.to raise_error 'Order has no payments'
      end
    end
  end
end
