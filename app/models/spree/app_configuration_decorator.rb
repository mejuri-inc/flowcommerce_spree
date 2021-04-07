# frozen_string_literal: true

module Spree
  AppConfiguration.class_eval do
    preference :debug_request_ip_address, :string
  end
end