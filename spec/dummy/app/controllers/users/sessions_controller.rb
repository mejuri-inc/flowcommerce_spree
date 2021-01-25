# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def get_session_current # rubocop:disable Naming/AccessorMethodName
      render json: { current: session_current }, status: 200
    end

    # This endpoint is for returning to the FrontEnd the dynamic url to an external checkout, like a flow_io.io url,
    # for example. It is not used with the clean app implementation of own internal checkout page.
    def checkout_url
      render json: { checkout_url: current_order.checkout_url || '' }, status: 200
    end

    private

    def setup
      @is_login_page = true
    end

    def build_new_resource
      log_in_params = sign_in_params
      log_in_params.delete :vote_path
      log_in_params.delete :share_path
      self.resource = resource_class.new(log_in_params)
      clean_up_passwords(resource)
    end

    def session_current
      session_current = { 'country' => request_iso_code,
                          'csrf' => form_authenticity_token,
                          'ga_cookie' => cookies[:_ga],
                          'session_id' => session[:session_id],
                          'segment_anonymous_id' => Track.anonymous_id,
                          'tests_config' => CustomConfig.get_config_by_slug('feature-testing'),
                          'pos' => pos_attrs,
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

    def pos_attrs
      current_pos_location = current_purchase_location

      pos_session? && current_pos_location.present? && {
        id: current_pos_location.external_id,
        name: current_pos_location.name,
        method: current_pos_location.method,
        currency: current_pos_location.currency,
        retail: current_pos_location.retail,
        code: current_pos_location.setup_code_hash
      } || nil
    end

    def zone_attrs
      session['region'] || { 'name' => current_zone.name, 'available_currencies' => current_zone.available_currencies }
    end

    def get_go_to_url(go_to)
      go_to_links = { 'checkout' => '/shop/checkout' }
      go_to_link = go_to_links[go_to]
      session[:previous_url] = go_to_link if go_to_link
    end

    protected

    def clear_sign_signout_flash
      flash.delete(:notice) if flash.keys.include?(:notice)
    end

    def sign_out_track
      Track.event('Signed Out', category: 'Users', email: Track.user.try(:email))
    end

    def sign_out_flash
      flash[:user_signed_out] = true
    end
  end
end
