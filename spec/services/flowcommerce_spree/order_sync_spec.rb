# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderSync do
  subject { FlowcommerceSpree::OrderSync }

  let(:zone) { create(:germany_zone, :with_flow_data) }
  let(:order) { create(:order_with_line_items, :with_flow_data) }

  describe '#initialize' do
    context 'when no order is passed' do
      it 'raises exception' do
        expect { subject.new }.to raise_error(ArgumentError, 'missing keyword: order')
      end
    end

    context 'when the order is not associated to flow experience' do
      before do
        allow(zone).to(receive(:flow_io_active_experience?).and_return(false))
        allow(order).to(receive(:zone).and_return(zone))
      end

      it 'raises exception' do
        expect { subject.new(order: order) }.to raise_error.with_message('Experience not defined or not active')
      end
    end
  end
end
