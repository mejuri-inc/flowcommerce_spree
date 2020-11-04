module FlowcommerceSpree
  class LoggingHttpClient < ::Io::Flow::V0::HttpClient::DefaultHttpHandlerInstance
    attr_reader :error

    def initialize(base_uri, logger: FlowcommerceSpree.logger)
      super(base_uri)
      @logger = logger
    end

    def execute(request)
      # original_open = client.open_timeout
      # original_read = client.read_timeout

      start_time = Time.now.utc.round(10)
      @logger.info "start #{request.method} #{request.path}"

      if request.path.start_with?("/organizations")
        # Contrived example to show how client settings can be adjusted
        # client.open_timeout = 60
        # client.read_timeout = 60
      end

      begin
        super
      rescue Io::Flow::V0::HttpClient::ServerError => e
        @error = { error: e }.to_json
      ensure
        # client.open_timeout = original_open
        # client.read_timeout = original_read

        end_time = Time.now.utc.round(10)
        duration = ((end_time - start_time)*1000).round(0)
        @logger.info "complete #{request.method} #{request.path} #{duration} ms"
        @logger.info "Error: #{e.inspect}" if e
      end
    end
  end
end
