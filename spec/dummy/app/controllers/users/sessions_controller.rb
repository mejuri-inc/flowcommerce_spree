# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def get_session_current # rubocop:disable Naming/AccessorMethodName
      render json: { current: session_current }, status: 200
    end

    # This endpoint is for returning to the FrontEnd the dynamic url to an external checkout, like a flow.io url,
    # for example. It is not used with the clean app implementation of own internal checkout page.
    def checkout_url
      return render json: {}, status: 422 unless (url = current_order.checkout_url)

      render json: { checkout_url: url }, status: 200
    end

    private

    def session_current
      session_current = { 'country' => request_iso_code,
                          'csrf' => form_authenticity_token,
                          'session_id' => session[:session_id],
                          'order' => order_attrs }

      add_optional_attrs(session_current)
      session_current
    end

    def add_optional_attrs(session_current)
      session_current['user'] = current_user_attrs if current_user&.spree_api_key?
      session_current['region'] = zone_attrs
      session_current['external_checkout'] = external_checkout?
    end

    def current_user_attrs
      { email: current_user.email,
        name: current_user.profile.try(:full_name),
        token: current_user.spree_api_key,
        uuid: current_user.uuid }
    end

    # When using an external checkout, this method should be overridden to return 'true', like in the flowcommerce_spree
    # gem, for example. Returning 'true' will signalize the FrontEnd to make an additional request to the checkout_url
    # endpoint to get the dynamic url
    def external_checkout?
      'false'
    end

    def order_attrs
      { number: current_order.number,
        state: current_order.state,
        token: current_order.guest_token }
    end

    def zone_attrs
      session['region'] || { name: current_zone.name, available_currencies: current_zone.available_currencies }
    end
  end
end
