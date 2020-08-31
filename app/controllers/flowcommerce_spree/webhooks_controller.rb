module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    respond_to :json

    # forward all incoming requests to Flow WebhookService object
    # /flow/event-target
    def handle_flow_web_hook_event
      response = WebhookService.process(Oj.load request.body.read)
    rescue StandardError => e
      response = { error: e.class.to_s, message: e.message, backtrace: e.backtrace }
    ensure
      response_status = response[:error] ? :unprocessable_entity : :ok
      WebhookService::LOGGER.info(response)
      render json: response.except(:backtrace), status: response_status
    end
  end
end
