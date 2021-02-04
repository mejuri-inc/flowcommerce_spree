# frozen_string_literal: true

require 'flowcommerce'
require 'flowcommerce_spree/api'
require 'flowcommerce_spree/refresher'
require 'flowcommerce_spree/engine'
require 'flowcommerce_spree/logging_http_client'
require 'flowcommerce_spree/logging_http_handler'
require 'flowcommerce_spree/webhook_service'
require 'flowcommerce_spree/session'
require 'flow/simple_gateway'
require 'request_store'

module FlowcommerceSpree
  def self.client(logger: FlowcommerceSpree.logger, **opts)
    FlowCommerce.instance(http_handler: LoggingHttpHandler.new(logger: logger), **opts)
  end

  def self.configure
    yield self if block_given?
  end

  def self.logger
    logger = ActiveSupport::Logger.new(STDOUT, 3, 10_485_760)

    # Broadcast the log into the file besides STDOUT, if `log` folder exists
    if Dir.exist?('log')
      logger.extend(ActiveSupport::Logger.broadcast(ActiveSupport::Logger.new('log/flowcommerce_spree.log')))
    end
    logger
  end
end
