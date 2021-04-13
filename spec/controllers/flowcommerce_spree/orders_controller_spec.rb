# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrdersController, type: :controller do
  let(:zone) { create(:germany_zone, :with_flow_data) }
  let(:order) { create(:order_with_line_items, :with_flow_data) }

  describe '#order_completed' do
    let(:params) { { order: order.number, t: order.guest_token } }
    subject { spree_get :order_completed, params }

    before do
      allow_any_instance_of(Spree::Order).to(receive(:zone).and_return(zone))
      allow_any_instance_of(FlowcommerceSpree::OrderUpdater).to(receive(:complete_checkout))
    end

    context 'when order is associated to active flow zone' do
      before do
        allow(zone).to(receive(:flow_io_active_or_archiving_experience?).and_return(true))
      end

      it 'redirects to thank you page' do
        expect(subject).to(redirect_to("/thankyou?order=#{order.number}&t=#{order.guest_token}"))
      end

      context 'when order params are not present' do
        let(:params) { {} }

        it 'raises error' do
          expect { subject }.to raise_error(ArgumentError, 'Experience not defined or not active')
        end
      end
    end

    context 'when order is associated to archiving/archived flow zone' do
      before do
        expect(zone).to(receive(:flow_io_active_or_archiving_experience?).and_return(false))
      end

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError, 'Experience not defined or not active')
      end
    end
  end
end
