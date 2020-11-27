module FlowcommerceSpree
  ORGANIZATION = ENV.fetch('FLOW_ORGANIZATION', 'flow.io')
  BASE_COUNTRY = ENV.fetch('FLOW_BASE_COUNTRY', 'USA')
  API_KEY = ENV.fetch('FLOW_API_KEY', 'test_key')
end

# For compatibility with flowcommerce gem
ENV['FLOW_TOKEN'] = API_KEY
