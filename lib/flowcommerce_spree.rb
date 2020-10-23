require 'flowcommerce_spree/engine'
require 'flowcommerce_spree/webhook_service'
require 'flow'
require 'flow_api_refresh'
require 'flow/simple_gateway'

module FlowcommerceSpree
  LOG_PATH = defined?(Rails) && Dir.exist?('log') ? 'log/flow_io_webhook.log' : STDOUT
  LOGGER = Logger.new(LOG_PATH, 3, 10_485_760)

  mattr_accessor :experience_associator

  def self.configure
    yield self if block_given?
  end
end
