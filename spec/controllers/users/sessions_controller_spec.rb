# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET #checkout_url' do
    let(:current_zone) { create(:product_zone_with_flow_experience) }
    let(:order) do
      create(:order_with_line_items, zone_id: current_zone.id, flow_data: { exp: current_zone.flow_io_experience,
                                                                            order: { id: Faker::Guid.guid } })
    end
    let(:flow_session) { build(:flow_organization_session) }
    let(:checkout_token) do
      build(:flow_checkout_token, order: { number: order.number }, session: { id: flow_session.id })
    end

    before do
      allow(controller).to receive(:current_order).and_return(order)
      allow_any_instance_of(FlowcommerceSpree::OrderSync).to receive(:sync_body!)
    end

    context 'when flow-session-id header is present' do
      before { request.headers['flow-session-id'] = flow_session.id }

      context 'and the OrderSync returned a non-blank checkout_token' do
        before do
          allow_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
            .to receive(:post_checkout_and_tokens_by_organization).and_return(checkout_token)
        end

        it 'syncs the order, got a checkout_token and returns a successful response with checkout_url' do
          expect_any_instance_of(FlowcommerceSpree::OrderSync).to receive(:sync_body!)
          expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
            .to receive(:post_checkout_and_tokens_by_organization)

          get :checkout_url

          expect(response).to have_http_status(:success)
          expect(Oj.load(response.body))
            .to eql('checkout_url' => "https://checkout.mejuri.com/tokens/#{checkout_token.id}")
        end
      end

      context 'and the OrderSync returned a blank checkout_token' do
        before do
          allow_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
            .to receive(:post_checkout_and_tokens_by_organization).and_return(nil)
        end

        it 'returns an error' do
          expect_any_instance_of(FlowcommerceSpree::OrderSync).to receive(:sync_body!)
          expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
            .to receive(:post_checkout_and_tokens_by_organization)

          get :checkout_url

          expect(response).to have_http_status(:unprocessable_entity)
          expect(Oj.load(response.body)).to eql('error' => 'checkout_token_missing')
        end
      end

      context 'when current_order is a flow.io order, but has no line_items and, thus, returns a nil checkout_token' do
        let(:order) { create(:order, zone_id: current_zone.id, flow_data: { exp: current_zone.flow_io_experience }) }

        it 'does not request checkout_token, nor sync the order, and returns :unprocessable_entity and error' do
          expect_any_instance_of(FlowcommerceSpree::OrderSync).not_to receive(:sync_body!)
          expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
            .not_to receive(:post_checkout_and_tokens_by_organization)

          get :checkout_url

          expect(response).to have_http_status(:unprocessable_entity)
          expect(Oj.load(response.body)).to eql('error' => 'checkout_token_missing')
        end
      end
    end

    context 'when flow-session-id header is missing' do
      it 'does not request checkout_token, nor sync the order, and returns :unprocessable_entity and error' do
        expect_any_instance_of(FlowcommerceSpree::OrderSync).not_to receive(:sync_body!)
        expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
          .not_to receive(:post_checkout_and_tokens_by_organization)

        get :checkout_url

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Oj.load(response.body)).to eql('error' => 'session_id_missing')
      end
    end
  end

  describe 'GET #session_current' do
    let(:order) { build(:order) }

    it 'returns http success' do
      get :get_session_current
      expect(response).to have_http_status(:success)
    end

    it 'returns order attributes nested in session data' do
      allow(controller).to receive(:current_order).and_return(order)

      get :get_session_current
      session_response = Oj.load(response.body)
      session_attributes = %w[csrf external_checkout session_id order region country]

      expect(session_response['current'].keys).to match_array(session_attributes)
      expect(session_response['current']['order'])
        .to eql('number' => order.number, 'state' => order.state, 'token' => order.guest_token)
    end

    context 'current user attributes' do
      context 'when current user exists' do
        let(:user) { create(:user, uuid: Faker::Guid.guid) }
        let!(:user_profile) { create(:user_profile, user: user) }

        before { allow(controller).to receive(:current_user).and_return(user) }

        context 'and has a spree_api_key' do
          it 'returns http success and current user`s attributes`' do
            get :get_session_current

            expect(response).to have_http_status(:success)
            response_user_attrs = Oj.load(response.body)['current']['user']
            expect(response_user_attrs['email']).to eq(user.email)
            expect(response_user_attrs['token']).to eq(user.spree_api_key)
            expect(response_user_attrs['uuid']).to eq(user.uuid)
            expect(response_user_attrs['name']).to eq("#{user_profile.first_name} #{user_profile.last_name}")
          end
        end

        context 'and has no spree_api_key' do
          it 'returns http success and no current user attributes`' do
            user.update_column(:spree_api_key, nil)
            get :get_session_current

            expect(response).to have_http_status(:success)
            response_user_attrs = Oj.load(response.body)['current']['user']
            expect(response_user_attrs).to be_nil
          end
        end
      end

      context 'when current user does not exist' do
        it 'returns http success and no current user attributes`' do
          get :get_session_current

          expect(response).to have_http_status(:success)
          response_user_attrs = Oj.load(response.body)['current']['user']
          expect(response_user_attrs).to be_nil
        end
      end
    end

    context 'zone attributes' do
      context 'current_zone exists' do
        let(:zone_hash) { { 'name' => current_zone.name, 'available_currencies' => current_zone.available_currencies } }

        context 'and has flow experience external checkout' do
          let(:current_zone) { create(:product_zone_with_flow_experience) }

          context 'current_zone attrs are stored in session' do
            before { session['region'] = zone_hash }

            it 'returns http success, and the stored zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash.merge!('request_iso_code' => nil))
              expect(current_session_attrs['external_checkout']).to eql(true)
            end
          end

          context 'current_zone attrs are not stored in session' do
            before { allow(controller).to receive(:current_zone).and_return(current_zone) }

            it 'returns http success and the current_zone zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash)
              expect(current_session_attrs['external_checkout']).to eql(true)
            end
          end
        end

        context 'and has no flow experience' do
          let(:current_zone) { create(:product_zone) }

          context 'current_zone attrs are stored in session' do
            before { session['region'] = zone_hash }

            it 'returns http success and the stored zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash.merge!('request_iso_code' => nil))
              expect(current_session_attrs['external_checkout']).to eql(false)
            end
          end

          context 'current_zone attrs are not stored in session' do
            before { allow(controller).to receive(:current_zone).and_return(current_zone) }

            it 'returns http success and the current_zone zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash)
              expect(current_session_attrs['external_checkout']).to eql(false)
            end
          end
        end
      end

      context 'current_zone does not exist' do
        before { allow(controller).to receive(:current_zone).and_return(nil) }

        it 'returns http success and the stored zone attributes`' do
          expect { get :get_session_current }.to raise_error
        end
      end
    end
  end
end
