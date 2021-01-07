# frozen_string_literal: true

module FlowcommerceSpree
  class LoggingHttpHandler < ::Io::Flow::V0::HttpClient::DefaultHttpHandler
    attr_reader :http_client, :logger

    def initialize(logger: FlowcommerceSpree.logger)
      @logger = logger
    end

    def instance(base_uri, _path)
      @http_client = LoggingHttpClient.new(base_uri, logger: @logger)
    end
  end
end
