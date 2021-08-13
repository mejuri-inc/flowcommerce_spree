# frozen_string_literal: true

module Users
  SessionsController.class_eval do
    # This endpoint is for returning to the FrontEnd the dynamic url to an external checkout, a flow.io url.
    def checkout_url
      flow_session_id = request.headers['flow-session-id']
      return render json: { error: :session_id_missing }, status: 422 if flow_session_id.blank?

      checkout_token =
        FlowcommerceSpree::OrderSync.new(order: current_order, flow_session_id: flow_session_id).synchronize!
      return render json: { error: :checkout_token_missing }, status: 422 if checkout_token.blank?

      render json: { checkout_url: "https://checkout.mejuri.com/tokens/#{checkout_token}" }, status: 200
    end

    private

    def add_optional_attrs(session_current)
      session_current['user'] = current_user_attrs if current_user&.spree_api_key?
      session_current['region'] = zone_attrs

      external_checkout = current_zone.flow_io_active_experience?
      session_current['external_checkout'] = external_checkout
      session_current['flow_session_id'] = session['flow_session_id'] if external_checkout
    end
  end
end
