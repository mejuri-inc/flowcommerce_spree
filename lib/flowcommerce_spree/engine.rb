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
      # If some Rake tasks will fail in development environment, the cause could be the autoloading.
      # Uncommenting the following 3 lines will enable eager-loading for the flowcommerce_spree Rake tasks.
      # if Rails.env.development?
      #   app.config.eager_load = Rake.application.top_level_tasks.any? { |t| t.start_with?('flowcommerce_spree') }
      # end

      app.config.flowcommerce_spree[:mounted_path] = ENV.fetch('FLOW_MOUNT_PATH', '/flow')

      app.routes.prepend do
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

    initializer 'spree.flowcommerce_spree.calculators', after: 'spree.register.calculators' do |_app|
      Rails.application.config.spree.calculators.tax_rates << Spree::Calculator::FlowIo
      Rails.application.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlowIo
    end
  end
end
