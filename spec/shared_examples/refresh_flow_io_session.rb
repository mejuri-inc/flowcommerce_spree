# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'refreshes flow.io session and checkout_token' do
  let(:session_expiration) { Time.zone.now.utc + 3.seconds }
  let(:new_session) { build(:flow_organization_session) }
  let(:new_checkout_token) do
    build(:flow_checkout_token, order: { number: order.number }, session: { id: new_session.id })
  end

  before do
    allow_any_instance_of(Io::Flow::V0::Clients::Sessions)
      .to receive(:post_organizations_by_organization).and_return(new_session)
    allow_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
      .to receive(:post_checkout_and_tokens_by_organization).and_return(new_checkout_token)
    allow_any_instance_of(FlowcommerceSpree::OrderSync).to receive(:sync_body!)
  end

  it 'refresh the session and checkout_token on flow.io and returns the checkout_url based on new token' do
    expect_any_instance_of(Io::Flow::V0::Clients::Sessions).to receive(:post_organizations_by_organization)
    expect_any_instance_of(Io::Flow::V0::Clients::CheckoutTokens)
      .to receive(:post_checkout_and_tokens_by_organization)

    get :checkout_url

    expect(response).to have_http_status(:success)
    expect(Oj.load(response.body))
      .to eql('checkout_url' => "https://checkout.flow.io/tokens/#{new_checkout_token.id}")
  end
end
