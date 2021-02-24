# frozen_string_literal: true

module FlowcommerceSpree
  class OrdersController < ApplicationController
    wrap_parameters false

    skip_before_action :setup_tracking, only: :order_completed

    # proxy enpoint between flow and thankyou page.
    # /flow/order_completed endpoint
    def order_completed
      flow_updater = FlowcommerceSpree::OrderUpdater.new(order: current_order)
      flow_updater.complete_checkout

      redirect_to '/thankyou', { order: params[:order], token: params[:token] }
    end
  end
end
