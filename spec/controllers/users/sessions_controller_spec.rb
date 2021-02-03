# frozen_string_literal: true

require 'rails_helper'
require 'shared_examples/refresh_flow_io_session'

RSpec.describe Users::SessionsController, type: :controller do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET #checkout_url' do
    let(:current_zone) { create(:product_zone_with_flow_experience) }
    let(:order) do
      create(:order, zone_id: current_zone.id, flow_data: { exp: current_zone.flow_io_experience,
                                                            order: { id: Faker::Guid.guid },
                                                            checkout_token: token,
                                                            session_expires_at: session_expiration })
    end
    let(:session_expiration) { Time.zone.now.utc + 30.minutes }
    let(:token) { Faker::Guid.guid }

    before { allow(controller).to receive(:current_order).and_return(order) }

    context 'and the flow.io session is not expired' do
      it 'do not refresh flow.io session and checkout_token and returns http success and the flow.io checkout_url' do
        expect_any_instance_of(Io::Flow::V0::Clients::Sessions).not_to receive(:post_organizations_by_organization)
        expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
          .not_to receive(:post_checkout_and_tokens_by_organization)

        get :checkout_url

        expect(response).to have_http_status(:success)
        expect(Oj.load(response.body)).to eql('checkout_url' => "https://checkout.flow.io/tokens/#{token}")
      end
    end

    context 'and the flow.io session is expired' do
      it_behaves_like 'refreshes flow.io session and checkout_token'
    end

    context "when current_order has flow order_id, but has no flow_data['checkout_token']" do
      let(:order) do
        create(:order, zone_id: current_zone.id,
                       flow_data: { exp: current_zone.flow_io_experience, order: { id: Faker::Guid.guid } })
      end

      it_behaves_like 'refreshes flow.io session and checkout_token'
    end

    context 'when current_order has no flow order_id and no checkout_token' do
      let(:order) { create(:order, zone_id: current_zone.id, flow_data: { exp: current_zone.flow_io_experience }) }
      let(:new_session) { build(:flow_organization_session) }

      before do
        allow_any_instance_of(Io::Flow::V0::Clients::Sessions)
          .to receive(:post_organizations_by_organization).and_return(new_session)
      end

      it 'returns :unprocessable_entity and empty body' do
        get :checkout_url

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Oj.load(response.body)).to eql({})
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
              expect(current_session_attrs['external_checkout']).to eql('true')
            end
          end

          context 'current_zone attrs are not stored in session' do
            before { allow(controller).to receive(:current_zone).and_return(current_zone) }

            it 'returns http success and the current_zone zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash)
              expect(current_session_attrs['external_checkout']).to eql('true')
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
              expect(current_session_attrs['external_checkout']).to eql('false')
            end
          end

          context 'current_zone attrs are not stored in session' do
            before { allow(controller).to receive(:current_zone).and_return(current_zone) }

            it 'returns http success and the current_zone zone attributes`' do
              get :get_session_current

              expect(response).to have_http_status(:success)
              current_session_attrs = Oj.load(response.body)['current']
              expect(current_session_attrs['region']).to eql(zone_hash)
              expect(current_session_attrs['external_checkout']).to eql('false')
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
