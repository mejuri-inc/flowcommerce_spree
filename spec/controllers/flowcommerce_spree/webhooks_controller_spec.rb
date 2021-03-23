# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FlowcommerceSpree::WebhooksController, type: :controller do
  routes { FlowcommerceSpree::Engine.routes }

  describe 'POST #handle_flow_io_event' do
    let(:id) { Faker::Guid.guid }
    let(:event_id) { Faker::Guid.guid }
    let(:discriminator) { 'unhandled_event' }
    let(:org) { FlowcommerceSpree::ORGANIZATION }
    let(:required_params) { { id: id, event_id: event_id, organization: org, discriminator: discriminator } }

    context 'on not authenticated requests' do
      it 'returns error' do
        post :handle_flow_io_event, required_params

        expect(response.body).to eq("HTTP Basic: Access denied.\n")
        expect(response.status).to eql(401)
      end
    end

    context 'on authenticated requests' do
      before do
        @request.env['HTTP_AUTHORIZATION'] =
          ActionController::HttpAuthentication::Basic
          .encode_credentials(FlowcommerceSpree::FLOW_IO_WEBHOOK_USER, FlowcommerceSpree::FLOW_IO_WEBHOOK_PASSWORD)
      end

      context 'when a required parameter is missing' do
        %i[id event_id organization discriminator].each do |p|
          context "when `#{p}` is missing" do
            it 'returns error' do
              required_params.delete(p)
              post :handle_flow_io_event, required_params

              expect(Oj.load(response.body))
                .to eq('error' => 'ActionController::ParameterMissing',
                       'message' => "param is missing or the value is empty: #{p}")
            end
          end
        end
      end

      context 'when organization does not match' do
        let(:org) { 'wrong org' }

        it 'returns error' do
          post :handle_flow_io_event, id: id, event_id: event_id, organization: org, discriminator: discriminator

          expect(Oj.load(response.body))
            .to eq('error' => 'InvalidParam',
                   'message' => "Organization '#{org}' is invalid!")
        end
      end

      context 'when event handling service object does not exists' do
        it 'returns error' do
          post :handle_flow_io_event, required_params

          expect(Oj.load(response.body))
            .to eq('error' => 'NameError',
                   'message' => 'uninitialized constant FlowcommerceSpree::Webhooks::UnhandledEvent')
        end
      end

      context 'when event handling service object exists' do
        FlowcommerceSpree::Webhooks.constants.select { |c| FlowcommerceSpree::Webhooks.const_get(c).is_a? Class }
                                   .each do |handler|
          discriminator = handler.to_s.underscore
          context "when #{discriminator} event arrives on controller" do
            let(:discriminator) { discriminator }

            before do
              allow("FlowcommerceSpree::Webhooks::#{handler}".constantize)
                .to receive(:process).and_return(handler_responce)
            end

            context 'and the event handler`s response does not contain errors' do
              let(:handler_responce) { OpenStruct.new(errors: []) }

              it 'returns an empty hash and a successful response status' do
                post :handle_flow_io_event, required_params

                expect(Oj.load(response.body)).to eq({})
                expect(response.status).to eql(200)
              end
            end

            context 'and the event handler`s response is not successful' do
              let(:error1) { '1st error' }
              let(:error2) { '2nd error' }
              let(:handler_responce) do
                OpenStruct.new(errors: ['error'], full_messages: [error1, error2], backtrace: 'backtrace')
              end

              it 'returns and logs the new line separated errors' do
                expect_any_instance_of(ActiveSupport::Logger).to receive(:info).with(error: "#{error1}\n#{error2}")

                post :handle_flow_io_event, required_params

                expect(Oj.load(response.body)).to eq('error' => "#{error1}\n#{error2}")
                expect(response.status).to eql(422)
              end
            end
          end
        end
      end
    end
  end
end
