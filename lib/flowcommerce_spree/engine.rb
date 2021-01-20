# frozen_string_literal: true

module FlowcommerceSpree
  class Engine < ::Rails::Engine
    require 'spree/core'
    isolate_namespace FlowcommerceSpree

    config.before_initialize do
      FlowcommerceSpree::ORGANIZATION = ENV.fetch('FLOW_ORGANIZATION', 'flow.io')
      FlowcommerceSpree::BASE_COUNTRY = ENV.fetch('FLOW_BASE_COUNTRY', 'USA')
      FlowcommerceSpree::API_KEY = ENV.fetch('FLOW_TOKEN', 'test_key')

      FlowcommerceSpree::Config = FlowcommerceSpree::Settings.new
    end

    config.flowcommerce_spree = ActiveSupport::OrderedOptions.new

    initializer 'flowcommerce_spree.configuration' do |app|
      app.config.flowcommerce_spree[:mounted_path] = ENV.fetch('FLOW_MOUNT_PATH', '/flow')

      app.routes.append do
        mount FlowcommerceSpree::Engine => app.config.flowcommerce_spree[:mounted_path]
      end
    end

    config.after_initialize do |app|
      # init Flow payments as an option
      app.config.spree.payment_methods << Spree::Gateway::FlowIo

      # Flow::SimpleGateway.clear_zero_amount_payments = true
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
