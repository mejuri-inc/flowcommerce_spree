module FlowcommerceSpree
  class Engine < ::Rails::Engine
    require 'spree/core'
    isolate_namespace FlowcommerceSpree

    config.after_initialize do
      # init Flow payments as an option
      # app.config.spree.payment_methods << Spree::Gateway::Flow

      Flow::SimpleGateway.clear_zero_amount_payments = true
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
