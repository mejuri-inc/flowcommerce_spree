module FlowcommerceSpree
  class Engine < ::Rails::Engine
    require 'spree/core'
    isolate_namespace Spree

    config.after_initialize do
      # init Flow payments as an option
      # app.config.spree.payment_methods << Spree::Gateway::Flow

      Flow::SimpleGateway.clear_zero_amount_payments = true
    end
  end
end
