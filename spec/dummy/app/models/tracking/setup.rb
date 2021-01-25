# frozen_string_literal: true

module Tracking
  module Setup
    def self.included(base)
      base.prepend_before_action :setup_tracking
    rescue StandardError
      nil
    end

    private

    def setup_tracking
      return if request.path.start_with?('/shop/admin/')

      user_consents = UserConsent.new(cookies)
      setup_visitor_cookie(user_consents)
    end

    def setup_visitor_cookie(user_consents)
      timestamp = cookies[Tracking::Service::VISITOR_COOKIE].to_i
      return if timestamp > 0

      cookies.permanent[Tracking::Service::VISITOR_COOKIE] = Time.now.getutc.to_i if user_consents.performance?
    end
  end
end
