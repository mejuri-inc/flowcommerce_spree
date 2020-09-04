require 'flowcommerce_spree/engine'
require 'flowcommerce_spree/webhook_service'
require 'flow'
require 'flow_api_refresh'
require 'flow/simple_gateway'

module FlowcommerceSpree
  mattr_accessor :experience_associator

  def self.configure
    yield self if block_given?
  end
end
