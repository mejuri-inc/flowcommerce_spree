# frozen_string_literal: true

module FlowcommerceSpree
  class OrdersController < ApplicationController
    wrap_parameters false

    skip_before_action :setup_tracking, only: :order_completed

    # proxy enpoint between flow and thankyou page.
    # /flow/order_completed endpoint
    def order_completed
      order = Spree::Order.find_by number: params[:order], guest_token: params[:t]

      flow_updater = FlowcommerceSpree::OrderUpdater.new(order: order)
      flow_updater.complete_checkout

      redirection_path = "/thankyou?order=#{params[:order]}&t=#{params[:t]}"
      locale = order.locale_path
      redirection_path = "/#{locale}#{redirection_path}" if locale

      redirect_to redirection_path
    end
  end
end
