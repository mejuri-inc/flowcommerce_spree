module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    respond_to :json

    # forward all incoming requests to Flow WebhookService object
    # /flow/event-target endpoint
    def handle_flow_web_hook_event
      params_hash = params[:webhook]
      result = WebhookService.process(params_hash)
    rescue StandardError => e
      result = { error: e.class.to_s, message: e.message, backtrace: e.backtrace }
    ensure
      response_status = if result[:error]
                          WebhookService::LOGGER.info(params_hash)
                          WebhookService::LOGGER.info(result)
                          :unprocessable_entity
                        else
                          :ok
                        end
      render json: result.except(:backtrace), status: response_status
    end
  end
end
