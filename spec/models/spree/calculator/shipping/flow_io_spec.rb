# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Calculator::Shipping::FlowIo, type: :model do
  describe '#compute_package' do
    context 'when order does not have flow_io data' do
      let(:order) { create(:order_with_line_items) }
      let(:package) { double(Spree::Stock::Package, order: order) }

      it 'returns amount from flow_io info' do
        expect(subject.compute_package(package)).to(be(nil))
      end
    end

    context 'when order has flow_io data' do
      let(:order) { create(:order_with_line_items, :with_flow_data) }
      let(:package) { double(Spree::Stock::Package, order: order) }

      it 'returns amount from flow_io info' do
        expected_amount = package.order.flow_data.dig('order', 'prices')&.find { |x| x.key('shipping') }&.[]('amount')
        expect(subject.compute_package(package)).to(be(expected_amount))
      end
    end
  end
end
