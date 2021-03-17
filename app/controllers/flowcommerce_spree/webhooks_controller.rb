# frozen_string_literal: true

module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    wrap_parameters false
    respond_to :json
    http_basic_authenticate_with name: FLOW_IO_WEBHOOK_USER, password: FLOW_IO_WEBHOOK_PASSWORD

    # forward incoming requests to respective Flow Webhooks Service objects
    # /flow/event-target endpoint
    def handle_flow_io_event
      %i[id event_id organization discriminator].each_with_object(params) { |key, obj| obj.require(key) }
      result = check_organization
      if result.blank?
        webhook_result = "FlowcommerceSpree::Webhooks::#{params['discriminator'].classify}".constantize.process(params)
        result[:error] = webhook_result.full_messages.join("\n") if webhook_result.errors.any?
      end
    rescue StandardError => e
      result = { error: e.class.to_s, message: e.message, backtrace: e.backtrace }
    ensure
      response_status = if result[:error]
                          logger.info(result)
                          :unprocessable_entity
                        else
                          :ok
                        end
      render json: result.except(:backtrace), status: response_status
    end

    private

    def check_organization
      org = params[:organization]
      return {} if org == FlowcommerceSpree::ORGANIZATION

      { error: 'InvalidParam', message: "Organization '#{org}' is invalid!" }
    end
  end
end
