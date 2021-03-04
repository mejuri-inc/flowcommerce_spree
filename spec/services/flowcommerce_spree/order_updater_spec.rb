# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderUpdater do
  let(:zone) { create(:germany_zone, :with_flow_data) }
  let(:order) { create(:order_with_line_items, :with_flow_data) }

  context 'when order is not present' do
    subject { FlowcommerceSpree::OrderUpdater.new(order: nil) }

    it 'raises exception' do
      expect { subject }.to(raise_error.with_message('Experience not defined or not active'))
    end
  end

  context 'when the order has no flow experience' do
    let(:order) { create(:order) }

    subject { FlowcommerceSpree::OrderUpdater.new(order: order) }

    it 'raises exception' do
      expect { subject }.to(raise_error.with_message('Experience not defined or not active'))
    end
  end
end
