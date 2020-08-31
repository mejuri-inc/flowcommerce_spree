module FlowcommerceSpree
  class WebhooksController < ActionController::Base
    respond_to :json

    protect_from_forgery with: :exception

    # forward all incoming requests to Flow Webhook service object
    # /flow/event-target
    def handle_flow_web_hook_event
      # return render plain: 'Source is not allowed to make requests', status: 403 unless requests.ip == '52.86.80.125'
      data     = Oj.load request.body.read

      # log web hook post to separate log file
      Flow::Webhook::LOGGER.info data

      response = Flow::Webhook.process data

      response_status = response[:error] ? :unprocessable_entity : :ok
      render json: response, status: response_status
    end
  end
end
