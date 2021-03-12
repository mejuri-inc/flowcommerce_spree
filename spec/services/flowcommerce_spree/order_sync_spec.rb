# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::OrderSync do
  subject { FlowcommerceSpree::OrderSync }

  let(:flow_session_id) { Faker::Guid.guid }
  let(:zone) { create(:germany_zone, :with_flow_data) }

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

  describe '#synchronize!' do
    let(:flow_order) { build(:flow_order) }
    let(:flowcommerce_client) { FlowcommerceSpree.client }
    let(:checkout_token) do
      build(:flow_checkout_token, order: { number: order.number }, session: { id: flow_session_id })
    end
    let(:root_url) { Rails.application.routes.url_helpers.root_url }
    let(:confirmation_url) { "#{root_url}flow/order-completed?order=#{order.number}&t=#{order.guest_token}" }
    let(:instance) { subject.new(order: order, flow_session_id: flow_session_id) }

    context 'when the order has line items' do
      Spree::Order.state_machine.states.map { |state| state.name.to_s }.each do |state|
        context "when order`s state is #{state} " do
          let(:order) { create(:order_with_line_items, :with_flow_data, state: state, zone: zone) }

          if state == 'cart'
            before do
              allow(FlowcommerceSpree).to receive(:client).and_return(flowcommerce_client)
              allow(flowcommerce_client).to receive_message_chain(:orders, :put_by_number).and_return(flow_order)
              allow(instance).to receive(:sync_body!).and_call_original
              allow(instance).to receive(:refresh_checkout_token).and_call_original
              allow(FlowcommerceSpree)
                .to receive_message_chain(:client, :checkout_tokens, :post_checkout_and_tokens_by_organization)
                .and_return(checkout_token)
            end

            it 'returns the checkout_token' do
              expect(instance).to receive(:sync_body!)
              expect(flowcommerce_client).to receive_message_chain(:orders, :put_by_number)
              expect(instance).to receive(:refresh_checkout_token)
              expect(FlowcommerceSpree)
                .to receive_message_chain(:client, :checkout_tokens, :post_checkout_and_tokens_by_organization)
                .with(FlowcommerceSpree::ORGANIZATION,
                      discriminator: 'checkout_token_reference_form',
                      order_number: order.number,
                      session_id: flow_session_id,
                      urls: { continue_shopping: root_url,
                              confirmation: confirmation_url,
                              invalid_checkout: root_url })
                .and_return(checkout_token)

              expect(instance.synchronize!).to eql(checkout_token.id)
              expect(order.flow_io_attributes['flow_return_url']).to eql(confirmation_url)
              expect(order.flow_io_attributes['checkout_continue_shopping_url']).to eql(root_url)
            end
          else
            it 'returns nil' do
              expect(instance.synchronize!).to eql(nil)
            end
          end
        end
      end
    end

    context 'when the order has no line items' do
      Spree::Order.state_machine.states.map { |state| state.name.to_s }.each do |state|
        context "when order`s state is #{state} " do
          let(:order) { create(:order, :with_flow_data, state: state, zone: zone) }

          it 'returns nil' do
            expect(instance.synchronize!).to eql(nil)
          end
        end
      end
    end
  end
end
