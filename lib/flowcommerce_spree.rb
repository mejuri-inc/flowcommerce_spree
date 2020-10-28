require 'flowcommerce_spree/api'
require 'flowcommerce_spree/api_refresh'
require 'flowcommerce_spree/engine'
require 'flowcommerce_spree/webhook_service'
require 'flow/simple_gateway'

module FlowcommerceSpree
  LOG_PATH = defined?(Rails) && Dir.exist?('log') ? 'log/flowcommerce_spree.log' : STDOUT
  LOGGER = Logger.new(LOG_PATH, 3, 10_485_760)

  def self.configure
    yield self if block_given?
  end
end
