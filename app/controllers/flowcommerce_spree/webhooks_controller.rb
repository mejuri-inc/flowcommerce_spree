module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    respond_to :json

    # forward all incoming requests to Flow WebhookService object
    # /flow/event-target endpoint
    def handle_flow_web_hook_event
      webhook_result_errors = WebhookService.process(params[:webhook]).errors
      result = {}
      result[:error] = webhook_result_errors.full_messages.join("\n") if webhook_result_errors.any?
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
  end
end
