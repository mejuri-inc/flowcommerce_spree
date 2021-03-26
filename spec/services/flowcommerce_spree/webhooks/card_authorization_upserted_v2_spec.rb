# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2 do
  subject { FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2 }

  let(:gateway) { create(:flow_io_gateway) }
  let(:user) { create(:user) }
  let(:order1) { create(:order, user: user) }
  let(:order2) { create(:order, user: user) }
  let(:card1) { build(:flow_card) }
  let(:card_auth1) { build(:flow_card_authorization, order: { number: order1.number }, card: card1) }
  let(:card_auth2) { build(:flow_card_authorization, order: { number: order2.number }, card: card1) }
  let(:data) { { 'authorization' => Oj.load(card_auth1.to_json), 'discriminator' => 'card_authorization_upserted_v2' } }

  before do
    allow(subject).to receive(:new).and_call_original
    allow(subject).to receive(:process).and_call_original
  end

  describe 'class methods' do
    context '#process' do
      it 'initializes the object instance with received data and calls `process` instance method on it' do
        allow_any_instance_of(subject).to receive(:process)

        expect(subject).to receive(:new).with(data)
        expect_any_instance_of(subject).to receive(:process)

        FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2.process(data)
      end
    end
  end

  describe 'instance methods' do
    let(:instance) { subject.new(data) }

    describe '#initialize' do
      it 'initializes the ivars, public `error` accessor and its `full_messages` alias' do
        expect(instance.instance_variable_get(:@data)).to eql(data['authorization']&.to_hash)
        expect(instance.instance_variable_get(:@errors)).to eql([])
        expect(instance.respond_to?(:errors)).to be_truthy
        expect(instance.respond_to?(:full_messages)).to be_truthy

        instance.instance_variable_set(:@errors, %w[error1 error2])

        expect(instance.errors).to eql(%w[error1 error2])
        expect(instance.full_messages).to eql(%w[error1 error2])
      end
    end

    describe '#process' do
      context 'when data contains no `authorization` key' do
        let(:instance) { subject.new(data.except('authorization')) }

        it 'returns self instance with errors' do
          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2)
          expect(result.errors).to eql([message: 'Authorization param missing'])
        end
      end

      context 'when data[`authorization`] contains no `card` key' do
        it 'returns self instance with errors' do
          data['authorization'].delete('card')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2)
          expect(result.errors).to eql([message: 'Card param missing'])
        end
      end

      context "when data['authorization'] contains no order" do
        it 'returns self instance with errors' do
          data['authorization'].delete('order')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2)
          expect(result.errors).to eql([message: 'Order number param missing'])
        end
      end

      context "when data['authorization']['order'] contains no number" do
        it 'returns self instance with errors' do
          data['authorization']['order'].delete('number')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2)
          expect(result.errors).to eql([message: 'Order number param missing'])
        end
      end

      context "when data['authorization']['order']['number'] isn't found in the DB" do
        it 'returns self instance with errors' do
          data['authorization']['order']['number'] = "#{order1.number}_"

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CardAuthorizationUpsertedV2)
          expect(result.errors).to eql([message: "Order #{order1.number}_ not found"])
        end
      end

      context "when data['authorization']['order']['number'] is found in the DB" do
        let!(:payment1) do
          create(:payment, order: order1, response_code: card_auth1.id, payment_method: gateway)
        end

        before do
          allow(instance).to receive(:upsert_card).and_call_original
          allow_any_instance_of(Spree::CreditCard).to receive(:push_authorization).and_call_original

          expect(instance).to receive(:upsert_card)
        end

        context 'and the credit card is not found in the DB' do
          it 'creates and returns the new Spree::CreditCard, updating the payment source' do
            expect_nil_payment_source(payment1)

            result = nil

            expect { result = instance.process }.to change { Spree::CreditCard.count }.from(0).to(1)
            expect(result).to be_instance_of(Spree::CreditCard)

            card = expect_card_attributes

            card_auth_hash = Oj.load(card_auth1.to_json)

            expect_card_attrs_in_flow_data(card, card_auth_hash)
            expect(card.flow_data['authorizations'].first).to eql(card_auth_hash.except('discriminator'))

            expect_payment_source_presence(payment1, card)
          end
        end

        context 'and the credit card is found in the DB' do
          let(:data2) do
            { 'authorization' => Oj.load(card_auth2.to_json), 'discriminator' => 'card_authorization_upserted_v2' }
          end
          let!(:payment2) do
            create(:payment, order: order2, response_code: card_auth2.id, payment_method: gateway)
          end

          it 'returns the found Spree::CreditCard with added authorization, updating the payment source' do
            expect_nil_payment_source(payment1)

            expect { instance.process }.to change { Spree::CreditCard.count }.from(0).to(1)

            card = expect_card_attributes

            expect_payment_source_presence(payment1, card)

            expect_nil_payment_source(payment2)

            result = nil
            expect { result = subject.new(data2).process }.not_to(change { Spree::CreditCard.count })
            expect(result).to be_instance_of(Spree::CreditCard)

            card.reload

            card_auth_hash = Oj.load(card_auth2.to_json)
            expect_card_attrs_in_flow_data(card, card_auth_hash)

            card_authorizations = card.flow_data['authorizations']

            expect(card_authorizations).to be_instance_of(Array)
            expect(card_authorizations.size).to eql(2)
            expect(card_authorizations.last).to eql(card_auth_hash.except('discriminator'))

            expect_payment_source_presence(payment2, card)
          end
        end
      end
    end
  end
end

def expect_nil_payment_source(payment)
  expect(payment.source_id).to be_nil
  expect(payment.source_type).to be_nil
end

def expect_payment_source_presence(payment, card)
  payment.reload
  expect(payment.source_id).to eql(card.id)
  expect(payment.source_type).to eql('Spree::CreditCard')
end

def expect_card_attributes
  card = Spree::CreditCard.first

  expect(card.month).to eql(card1.expiration.month.to_s)
  expect(card.year).to eql(card1.expiration.year.to_s)
  expect(card.cc_type).to eql(card1.type.value)
  expect(card.last_digits).to eql(card1.last4)
  expect(card.name).to eql(card1.name)
  expect(card.user_id).to eql(user.id)

  card
end

def expect_card_attrs_in_flow_data(card, card_auth_hash)
  card_auth_hash['method'].delete('images')
  card_hash = card_auth_hash.delete('card')

  expect(card.flow_data.except('authorizations'))
    .to eql(card_hash.except('discriminator', 'expiration', 'type', 'last4', 'name'))
end
