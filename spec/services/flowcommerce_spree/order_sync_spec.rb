# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderSync do
  subject { FlowcommerceSpree::OrderSync }

  let(:flow_session_id) { Faker::Guid.guid }

  describe '#initialize' do
    context 'when no order and flow_session_id are passed' do
      it 'raises exception' do
        expect { subject.new }.to raise_error(ArgumentError, 'missing keywords: order, flow_session_id')
      end
    end

    context 'when no order is passed' do
      it 'raises exception' do
        expect { subject.new(flow_session_id: flow_session_id) }.to raise_error(ArgumentError, 'missing keyword: order')
      end
    end

    context 'when no flow_session_id is passed' do
      let(:order) { create(:order) }

      it 'raises exception' do
        expect { subject.new(order: order) }.to raise_error(ArgumentError, 'missing keyword: flow_session_id')
      end
    end

    context 'when passed order is not present' do
      it 'raises exception' do
        expect { subject.new(order: nil, flow_session_id: flow_session_id) }
          .to raise_error(ArgumentError, 'Experience not defined or not active')
      end
    end

    context 'when the order has no flow experience' do
      let(:order) { create(:order) }

      it 'raises exception' do
        expect { subject.new(order: order, flow_session_id: flow_session_id) }
          .to raise_error(ArgumentError, 'Experience not defined or not active')
      end
    end

    context 'when the order has a flow experience defined' do
      let(:zone) { create(:germany_zone, :with_flow_data) }
      let(:order) { create(:order_with_line_items, :with_flow_data, zone: zone) }

      it 'initializes the ivars and public accessors and calls the `fetch_session_id` method' do
        allow(FlowcommerceSpree).to receive(:client).and_return('client instance')
        expect(FlowcommerceSpree).to receive(:client).with(
          default_headers: { "Authorization": "Session #{flow_session_id}" },
          authorization: nil
        )

        instance = subject.new(order: order, flow_session_id: flow_session_id)

        expect(instance.instance_variable_get(:@experience)).to eql(order.flow_io_experience_key)
        expect(instance.instance_variable_get(:@order)).to eql(order)
        expect(instance.instance_variable_get(:@client)).to eql('client instance')

        expect(instance.respond_to?(:order)).to be_truthy
        expect(instance.respond_to?(:response)).to be_truthy

        expect(instance.order).to eql(order)
      end
    end
  end
end
