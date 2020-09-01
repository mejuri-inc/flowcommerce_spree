module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    respond_to :json

    # forward all incoming requests to Flow WebhookService object
    # /flow/event-target endpoint
    def handle_flow_web_hook_event
      request_body_hash = Oj.load request.body.read
      result = WebhookService.process(request_body_hash)
    rescue StandardError => e
      result = { error: e.class.to_s, message: e.message, backtrace: e.backtrace }
    ensure
      response_status = result[:error] ? :unprocessable_entity : :ok
      WebhookService::LOGGER.info(request_body_hash)
      render json: result.except(:backtrace), status: response_status
    end
  end
end
