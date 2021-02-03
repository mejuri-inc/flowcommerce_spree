# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Auth
  include CurrentZoneLoader

  before_action :prepare_order

  def prepare_order
    set_order_for_bag
  end

  def set_order_for_bag
    @bag_order_data = { number: bag_order.number, token: bag_order.guest_token,
                        openBag: params[:open_bag] || false }
  end

  def bag_order
    @bag_order ||= current_order(create_order_if_necessary: true)
  end
end
