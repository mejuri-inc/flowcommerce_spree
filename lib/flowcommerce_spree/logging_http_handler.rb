module FlowcommerceSpree
  class LoggingHttpHandler < ::Io::Flow::V0::HttpClient::DefaultHttpHandler
    attr_reader :http_client

    def initialize(logfile_path)
      @logfile_path = logfile_path
    end

    def instance(base_uri, path )
      @http_client = LoggingHttpClient.new(base_uri, @logfile_path)
    end
  end
end
