# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderSync do
  subject { FlowcommerceSpree::OrderSync }

  describe '#initialize' do
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
      let(:order) { create(:order_with_line_items, :with_flow_data) }
    end
  end
end
