# frozen_string_literal: true

module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    wrap_parameters false
    respond_to :json
    http_basic_authenticate_with name: FLOW_IO_WEBHOOK_USER, password: FLOW_IO_WEBHOOK_PASSWORD

    # forward incoming requests to respective Flow Webhooks Service objects
    # /flow/event-target endpoint
    def handle_flow_io_event
      %i[event_id organization discriminator].each_with_object(params) { |key, obj| obj.require(key) }
      return unless organization_valid?

      webhook_result = "FlowcommerceSpree::Webhooks::#{params['discriminator'].classify}".constantize.process(params)
      @result = {}
      @result[:error] = webhook_result.full_messages.join("\n") if webhook_result.errors.any?
    rescue StandardError => e
      @result = { error: e.class.to_s, message: e.message, backtrace: e.backtrace }
    ensure
      logger.info(@result) if (error = @result[:error])
      render json: @result.except(:backtrace), status: error ? :unprocessable_entity : :ok
    end

    private

    def organization_valid?
      org = params[:organization]
      return true if org == FlowcommerceSpree::ORGANIZATION

      @result = { error: 'InvalidParam', message: "Organization '#{org}' is invalid!" }
      false
    end
  end
end
