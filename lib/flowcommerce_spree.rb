# frozen_string_literal: true

require 'flowcommerce'
require 'flowcommerce_spree/api'
require 'flowcommerce_spree/refresher'
require 'flowcommerce_spree/engine'
require 'flowcommerce_spree/logging_http_client'
require 'flowcommerce_spree/logging_http_handler'
require 'flowcommerce_spree/session'
require 'flow/simple_gateway'

module FlowcommerceSpree
  API_KEY = ENV.fetch('FLOW_TOKEN', 'test_key')
  ENV['FLOW_TOKEN'] = API_KEY

  def self.client(logger: FlowcommerceSpree.logger, **opts)
    FlowCommerce.instance(http_handler: LoggingHttpHandler.new(logger: logger), **opts)
  end

  def self.configure
    yield self if block_given?
  end

  def self.logger
    logger = ActiveSupport::Logger.new(STDOUT)

    logger_formatter = proc do |severity, datetime, _progname, msg|
      "\n#{datetime}, #{severity}: #{msg}\n"
    end

    logger.formatter = logger_formatter

    # Broadcast the log into the file besides STDOUT, if `log` folder exists
    if Dir.exist?('log')
      file_logger = ActiveSupport::Logger.new('log/flowcommerce_spree.log', 3, 10_485_760)
      file_logger.formatter = logger_formatter

      logger.extend(ActiveSupport::Logger.broadcast(file_logger))
    end
    logger
  end
end
