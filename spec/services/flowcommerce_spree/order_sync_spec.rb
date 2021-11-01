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

      it 'initializes the ivars and public accessors and sets the client with the flow_session_id' do
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
            let(:line_item) { order.line_items.first }
            let(:order_line_item) do
              { number: line_item.variant.sku,
                discounts: { discounts: [] },
                price: { amount: line_item.variant.price,
                         currency: line_item.variant.cost_currency },
                center: FlowcommerceSpree::OrderSync::FLOW_CENTER,
                quantity: order.line_items.size }
            end
            let(:line_item_form) { build(:flow_line_item_form, order_line_item) }

            before do
              ENV['ENCRYPTION_KEY'] = Faker::Guid.guid

              allow(FlowcommerceSpree).to receive(:client).and_return(flowcommerce_client)
              allow(instance).to receive(:sync_body!).and_call_original
              allow(instance).to receive(:try_to_add_customer).and_call_original
              allow(Io::Flow::V0::Models::OrderPutForm).to receive(:new).and_return(order_put_form)
              allow(flowcommerce_client).to receive_message_chain(:orders, :put_by_number).and_return(flow_order)
              allow(instance).to receive(:refresh_checkout_token).and_call_original
              allow(FlowcommerceSpree)
                .to receive_message_chain(:client, :checkout_tokens, :post_checkout_and_tokens_by_organization)
                .and_return(checkout_token)

              expect(instance).to receive(:sync_body!)
              expect(flowcommerce_client)
                .to receive_message_chain(:orders, :put_by_number)
                .with(FlowcommerceSpree::ORGANIZATION,
                      order.number, order_put_form, expand: ['experience'], experience: order.flow_io_experience_key)
              expect(instance).to receive(:refresh_checkout_token)
            end

            context 'has promotions on line_items' do
              let(:line_item) { create(:line_item) }
              let(:order_put_form) { build(:flow_order_put_form, items: [line_item_form]) }
              let(:expected_result) do
                { center: FLOW_CENTER,
                  number: variant.sku,
                  quantity: line_item.quantity,
                  price: { amount: line_item.variant.price,
                           currency: line_item.variant.cost_currency },
                  discounts: [{ offer: { discriminator: 'discount_offer_fixed',
                                         money: { amount: 0.0, currency: 'USD' } },
                                target: 'item', label: 'Promotion' }] }
              end
              before do
                allow(instance).to receive(:add_item).and_call_original
                line_item.adjustments << create(:promotion_adjustment,
                                                adjustable: line_item, order: line_item.order)
              end

              it 'adds discounts to flow payload' do
                expect(instance).to receive(:add_item).and_return(:expected_result)

                instance.synchronize!
              end
            end

            context 'has locale set' do
              let(:order_put_form) { build(:flow_order_put_form, items: [line_item_form]) }
              let(:locale_path) { 'de/de' }

              before do
                allow_any_instance_of(Spree::Order).to(receive(:locale_path).and_return(locale_path))
                expect(FlowcommerceSpree)
                  .to receive_message_chain(:client, :checkout_tokens, :post_checkout_and_tokens_by_organization)
                  .with(FlowcommerceSpree::ORGANIZATION, discriminator: 'checkout_token_reference_form',
                                                         order_number: order.number,
                                                         session_id: flow_session_id,
                                                         urls: { continue_shopping: root_url + locale_path,
                                                                 confirmation: confirmation_url,
                                                                 invalid_checkout: root_url + locale_path })
                  .and_return(checkout_token)
              end

              it 'fills in locale in url paths' do
                instance.synchronize!
              end
            end

            context 'has no locale set' do
              before do
                expect(FlowcommerceSpree)
                  .to receive_message_chain(:client, :checkout_tokens, :post_checkout_and_tokens_by_organization)
                  .with(FlowcommerceSpree::ORGANIZATION, discriminator: 'checkout_token_reference_form',
                                                         order_number: order.number,
                                                         session_id: flow_session_id,
                                                         urls: { continue_shopping: root_url,
                                                                 confirmation: confirmation_url,
                                                                 invalid_checkout: root_url })
                  .and_return(checkout_token)
              end

              context 'and the order is a guest order, i.e. has no associated user' do
                let(:order_put_form) { build(:flow_order_put_form, items: [line_item_form]) }

                it 'syncs the order to flow.io without customer info and returns the checkout_token' do
                  expect(instance).to receive(:try_to_add_customer).and_return(nil)

                  expect(instance.synchronize!).to eql(checkout_token.id)
                  expect(order.flow_io_attributes['flow_return_url']).to eql(confirmation_url)
                  expect(order.flow_io_attributes['checkout_continue_shopping_url']).to eql(root_url)
                  expect(order.flow_data.dig('order', 'customer', 'email')).to be_falsey
                  expect(order.flow_data.dig('order', 'customer', 'name', 'first')).to be_falsey
                  expect(order.flow_data.dig('order', 'customer', 'name', 'last')).to be_falsey
                end
              end

              context 'and the order is a user order, i.e. has an associated user' do
                let(:user_profile) { create(:user_profile, user: user) }
                let(:customer_form) { build(:flow_order_customer_form, customer_hash) }
                let(:customer_hash) do
                  { name: { first: address&.firstname || user_profile&.first_name,
                            last: address&.lastname || user_profile&.last_name },
                    number: user.flow_number, email: user.email, phone: address.phone }
                end
                let(:destination_hash) do
                  { streets: [address.address1, address.address2].reject(&:nil?),
                    city: address&.city,
                    province: address&.state_name,
                    postal: address&.zipcode,
                    country: (address&.country&.iso3 || ''),
                    contact: customer_hash }.delete_if { |_k, v| v.nil? }
                end
                let(:flow_order) { build(:flow_order, customer: build(:flow_order_customer, customer_hash)) }
                let(:order) { create(:order_with_line_items, :with_flow_data, user: user, state: state, zone: zone) }
                let(:order_put_form) { build(:flow_order_put_form, items: [line_item_form], customer: customer_form) }

                before { allow(instance).to receive(:add_customer_address).and_call_original }

                context 'user has no ship address, and no user_profile address' do
                  let(:user) { create(:user) }
                  let(:country) { create(:country, iso: 'DE') }
                  let!(:user_profile) { create(:user_profile, user: user) }
                  let(:customer_hash) do
                    { name: { first: user_profile.first_name, last: user_profile.last_name },
                      number: user.flow_number, email: user.email, phone: nil }
                  end

                  it 'syncs the order to flow.io with customer info, without address, and returns the checkout_token' do
                    expect(instance).to receive(:try_to_add_customer)
                    expect(instance).not_to receive(:add_customer_address)
                    expect(Io::Flow::V0::Models::OrderPutForm)
                      .to receive(:new)
                      .with(items: [order_line_item], customer: customer_hash,
                            attributes: nil, selections: nil, delivered_duty: nil)

                    expect(instance.synchronize!).to eql(checkout_token.id)
                    expect(order.flow_io_attributes['flow_return_url']).to eql(confirmation_url)
                    expect(order.flow_io_attributes['checkout_continue_shopping_url']).to eql(root_url)
                    expect(order.flow_data.dig('order', 'customer', 'email')).to eql(user.email)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'first')).to eql(user_profile.first_name)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'last')).to eql(user_profile.last_name)
                    expect(order.flow_data.dig('order', 'customer', 'number')).to eql(user.flow_number)
                  end
                end

                context 'user has no ship address, and user_profile.address.country = order`s flow experience country' do
                  let(:user) { create(:user) }
                  let(:country) { create(:country, iso: 'DE') }
                  let(:address) { create(:profile_address, country_id: country.id) }
                  let!(:user_profile) { create(:user_profile, user: user, address: address) }

                  it 'syncs the order to flow.io with customer info, profile address, and returns the checkout_token' do
                    expect(instance).to receive(:try_to_add_customer)
                    expect(instance).to receive(:add_customer_address).with(address)
                    expect(Io::Flow::V0::Models::OrderPutForm)
                      .to receive(:new)
                      .with(items: [order_line_item], customer: customer_hash,
                            destination: destination_hash, attributes: nil, selections: nil, delivered_duty: nil)

                    expect(instance.synchronize!).to eql(checkout_token.id)
                    expect(order.flow_io_attributes['flow_return_url']).to eql(confirmation_url)
                    expect(order.flow_io_attributes['checkout_continue_shopping_url']).to eql(root_url)
                    expect(order.flow_data.dig('order', 'customer', 'email')).to eql(user.email)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'first')).to eql(address.firstname)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'last')).to eql(address.lastname)
                    expect(order.flow_data.dig('order', 'customer', 'number')).to eql(user.flow_number)
                  end
                end

                context 'user has a ship address equal to order`s flow experience country' do
                  let(:user) { create(:user, ship_address_id: address.id) }
                  let(:country) { create(:country, iso: 'DE') }
                  let(:profile_address) { create(:profile_address, country_id: country.id) }
                  let(:address) { create(:ship_address, country_id: country.id) }
                  let!(:user_profile) { create(:user_profile, user: user, address: profile_address) }

                  it 'syncs the order to flow.io with customer info and ship_address, and returns the checkout_token' do
                    expect(instance).to receive(:try_to_add_customer)
                    expect(instance).to receive(:add_customer_address).with(address)
                    expect(Io::Flow::V0::Models::OrderPutForm)
                      .to receive(:new)
                      .with(items: [order_line_item], customer: customer_hash,
                            destination: destination_hash, attributes: nil, selections: nil, delivered_duty: nil)

                    expect(instance.synchronize!).to eql(checkout_token.id)
                    expect(order.flow_io_attributes['flow_return_url']).to eql(confirmation_url)
                    expect(order.flow_io_attributes['checkout_continue_shopping_url']).to eql(root_url)
                    expect(order.flow_data.dig('order', 'customer', 'email')).to eql(user.email)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'first')).to eql(address.firstname)
                    expect(order.flow_data.dig('order', 'customer', 'name', 'last')).to eql(address.lastname)
                    expect(order.flow_data.dig('order', 'customer', 'number')).to eql(user.flow_number)
                  end
                end
              end
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
