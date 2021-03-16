# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrdersController, type: :controller do
  let(:zone) { create(:germany_zone, :with_flow_data) }
  let(:order) { create(:order_with_line_items, :with_flow_data) }

  describe '#order_completed' do
    context 'when order is associated to flow zone' do
      before do
        allow(controller).to receive(:current_order).and_return(order)
        expect(zone).to(receive(:flow_io_active_experience?).and_return(true))
        expect(order).to(receive(:zone).and_return(zone))
        expect_any_instance_of(FlowcommerceSpree::OrderUpdater).to(receive(:complete_checkout))
      end

      subject { spree_get :order_completed, order: order.number, t: order.guest_token }

      it 'redirects to thank you page' do
        expect(subject).to(redirect_to("/thankyou?order=#{order.number}&t=#{order.guest_token}"))
      end
    end
  end
end
