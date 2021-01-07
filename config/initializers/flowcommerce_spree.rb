# frozen_string_literal: true

module FlowcommerceSpree
  ORGANIZATION = ENV.fetch('FLOW_ORGANIZATION', 'flow.io')
  BASE_COUNTRY = ENV.fetch('FLOW_BASE_COUNTRY', 'USA')
  API_KEY = ENV.fetch('FLOW_TOKEN', 'test_key')
end
