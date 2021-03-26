# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::Webhooks::CaptureUpsertedV2 do
  subject { FlowcommerceSpree::Webhooks::CaptureUpsertedV2 }

  let(:gateway) { create(:flow_io_gateway) }
  let(:order) { create(:order) }
  let(:order_auth) { build(:flow_authorization_reference, order: { number: order.number }) }
  let(:capture) { build(:flow_capture, authorization: order_auth) }
  let(:data) { { 'capture' => Oj.load(capture.to_json) } }

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

        FlowcommerceSpree::Webhooks::CaptureUpsertedV2.process(data)
      end
    end
  end

  describe 'instance methods' do
    let(:instance) { subject.new(data) }

    describe '#initialize' do
      it 'initializes the ivars, public `error` accessor and its `full_messages` alias' do
        expect(instance.instance_variable_get(:@data)).to eql(data)
        expect(instance.instance_variable_get(:@errors)).to eql([])
        expect(instance.respond_to?(:errors)).to be_truthy
        expect(instance.respond_to?(:full_messages)).to be_truthy

        instance.instance_variable_set(:@errors, %w[error1 error2])

        expect(instance.errors).to eql(%w[error1 error2])
        expect(instance.full_messages).to eql(%w[error1 error2])
      end
    end

    describe '#process' do
      context 'when @data contains no `capture` key' do
        let(:instance) { subject.new(data.except('capture')) }

        it 'returns self instance with errors' do
          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CaptureUpsertedV2)
          expect(result.errors).to eql([message: 'Capture param missing'])
        end
      end

      context 'when @data[`capture`] contains no authorization' do
        it 'returns self instance with errors' do
          data['capture'].delete('authorization')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CaptureUpsertedV2)
          expect(result.errors).to eql([message: 'Order number param missing'])
        end
      end

      context "when @data[`capture`]['authorization'] contains no order" do
        it 'returns self instance with errors' do
          data['capture']['authorization'].delete('order')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CaptureUpsertedV2)
          expect(result.errors).to eql([message: 'Order number param missing'])
        end
      end

      context "when @data[`capture`]['authorization']['order'] contains no number" do
        it 'returns self instance with errors' do
          data['capture']['authorization']['order'].delete('number')

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CaptureUpsertedV2)
          expect(result.errors).to eql([message: 'Order number param missing'])
        end
      end

      context "when @data[`capture`]['authorization']['order']['number'] isn't found in the DB" do
        it 'returns self instance with errors' do
          data['capture']['authorization']['order']['number'] = "#{order.number}_"

          result = instance.process

          expect(result).to be_a(FlowcommerceSpree::Webhooks::CaptureUpsertedV2)
          expect(result.errors).to eql([message: "Order #{order.number}_ not found"])
        end
      end

      context 'when capture authorization order number is found in the DB' do
        let(:failed_capture) do
          build(:flow_capture, id: capture.id, authorization: order_auth, status: 'failed')
        end

        before do
          order.flow_data = { 'order' => { 'captures' => [failed_capture] } }
          order.update_column(:meta, order.meta.to_json)

          allow(FlowcommerceSpree::OrderUpdater).to receive(:new).and_call_original
          allow_any_instance_of(FlowcommerceSpree::OrderUpdater).to receive(:finalize_order)
          allow(instance).to receive(:upsert_order_captures).and_call_original
          allow(instance).to receive(:map_payment_captures_to_spree).and_call_original
          allow(instance).to receive(:captured_payment).and_call_original
          allow_any_instance_of(Spree::Payment).to receive(:complete).and_call_original

          expect(instance).to receive(:upsert_order_captures).with(order, data['capture'])
        end

        context 'and the order contains no flow_io payments' do
          it 'returns the Spree::Order with upserted captures, not mapping captures to Spree' do
            expect(instance).not_to receive(:map_payment_captures_to_spree)

            result = instance.process

            expect_order_with_capture(result, 'succeeded')
          end
        end

        context 'and the order contains flow_io payments' do
          let(:flow_payment) { build(:flow_order_payment, reference: order_auth.id) }
          let(:zone) { create(:germany_zone, :with_flow_data) }

          [Time.now.utc, nil].each do |timestamp|
            context "and the order is #{timestamp ? 'completed' : 'not_completed'}" do
              let(:order) { create(:order, zone: zone, completed_at: timestamp) }
              let(:finalize) { timestamp ? false : true }

              before do
                order.flow_data['order']['payments'] = [flow_payment]
                order.update_column(:meta, order.meta.to_json)

                expect(instance).to receive(:map_payment_captures_to_spree)
              end

              context 'and received capture is successful' do
                context 'and capture authorization matches flow_io payment authorization' do
                  context 'and a Spree::Payment with received capture authorization exists' do
                    let(:payment_amount) { capture.amount }
                    let!(:payment) do
                      create(:payment,
                             payment_method_id: gateway.id, amount: payment_amount, response_code: order_auth.id)
                    end

                    context 'and no Spree::PaymentCaptureEvent exists for this payment' do
                      before { Spree::PaymentCaptureEvent.destroy_all }

                      context 'and payment state is not complete' do
                        context 'and payment amount is not bigger than capture amount' do
                          it 'creates PaymentCaptureEvent, completes payment, returns order with upserted captures' do
                            expect(instance).to receive(:captured_payment)
                            expect_any_instance_of(Spree::Payment).to receive(:complete)
                            expect_order_finalize(order_finalize: finalize)

                            result = nil
                            expect { result = instance.process }
                              .to change { Spree::PaymentCaptureEvent.count }.from(0).to(1)

                            created_capture_event = Spree::PaymentCaptureEvent.first

                            expect(created_capture_event.amount).to eql(capture.amount)
                            expect(created_capture_event.flow_data['id']).to eql(capture.id)
                            expect(payment.reload.state).to eql('completed')
                            expect_order_with_capture(result, 'succeeded')
                          end
                        end

                        context 'and payment amount is bigger than capture amount' do
                          let(:payment_amount) { capture.amount + 1 }

                          it 'creates a PaymentCaptureEvent, and returns order with upserted captures' do
                            expect(instance).to receive(:captured_payment)
                            expect_any_instance_of(Spree::Payment).not_to receive(:complete)
                            expect(FlowcommerceSpree::OrderUpdater).not_to receive(:new)
                            expect_any_instance_of(FlowcommerceSpree::OrderUpdater).not_to receive(:finalize_order)

                            result = nil
                            expect { result = instance.process }
                              .to change { Spree::PaymentCaptureEvent.count }.from(0).to(1)

                            created_capture_event = Spree::PaymentCaptureEvent.first

                            expect(created_capture_event.amount).to eql(capture.amount)
                            expect(created_capture_event.flow_data['id']).to eql(capture.id)
                            expect(payment.reload.state).to eql('checkout')
                            expect_order_with_capture(result, 'succeeded')
                          end
                        end
                      end
                    end

                    context 'and a Spree::PaymentCaptureEvent for this payment already exists' do
                      let!(:capture_event) do
                        create(:payment_capture_event, payment_id: payment.id, flow_data: { id: capture.id })
                      end

                      it 'returns the Spree::Order with upserted captures, not creating a Spree::PaymentCaptureEvent' do
                        result = expect_no_new_capture_events(order_finalize: finalize)
                        expect_order_with_capture(result, 'succeeded')
                      end
                    end
                  end

                  context 'and no Spree::Payment with received capture authorization exists' do
                    it 'returns the Spree::Order with upserted captures, not creating a Spree::PaymentCaptureEvent' do
                      result = expect_no_new_capture_events(order_finalize: finalize)
                      expect_order_with_capture(result, 'succeeded')
                    end
                  end
                end

                context 'and capture authorization does not match flow_io payment authorization' do
                  let(:flow_payment) { build(:flow_order_payment, reference: 'wrong auth') }

                  it 'returns the Spree::Order with upserted captures, not creating a Spree::PaymentCaptureEvent' do
                    result = expect_no_new_capture_events(order_finalize: finalize)
                    expect_order_with_capture(result, 'succeeded')
                  end
                end
              end

              context 'and received capture is not successful' do
                let(:data) { { 'capture' => Oj.load(failed_capture.to_json) } }

                it 'returns the Spree::Order with upserted captures' do
                  result = expect_no_new_capture_events(order_finalize: finalize)
                  expect_order_with_capture(result, 'failed')
                end
              end
            end
          end
        end
      end
    end
  end
end

def expect_no_new_capture_events(order_finalize: true)
  expect(instance).to receive(:captured_payment).and_return(nil)
  expect_order_finalize(order_finalize: order_finalize)

  result = nil
  expect { result = instance.process }.not_to(change { Spree::PaymentCaptureEvent.count })
  result
end

def expect_order_finalize(order_finalize: true)
  finalize = order_finalize ? :to : :not_to
  expect(FlowcommerceSpree::OrderUpdater).__send__(finalize, receive(:new))
  expect_any_instance_of(FlowcommerceSpree::OrderUpdater).__send__(finalize, receive(:finalize_order))
end

def expect_order_with_capture(result, capture_status)
  expect(result).to be_a(Spree::Order)
  expect(result.flow_data['captures']).to eql([data['capture']])
  expect(result.flow_data['captures'].first['status']).to eql(capture_status)
end
