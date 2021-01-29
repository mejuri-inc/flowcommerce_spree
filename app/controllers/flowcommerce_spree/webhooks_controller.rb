# frozen_string_literal: true

module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    wrap_parameters false
    respond_to :json

    # forward all incoming requests to Flow WebhookService object
    # /flow/event-target endpoint
    def handle_flow_web_hook_event
      result = check_organization
      if result.blank?
        webhook_result = WebhookService.process(params)
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
