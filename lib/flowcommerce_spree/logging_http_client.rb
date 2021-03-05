# frozen_string_literal: true

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

      # Contrived example to show how client settings can be adjusted
      # if request.path.start_with?('/organizations')
      #   client.open_timeout = 60
      #   client.read_timeout = 60
      # end

      begin
        response = super
      rescue Io::Flow::V0::HttpClient::ServerError => e
        @error = { error: Oj.load(e.body), code: e.code, status: e.details }
        raise StandardError, @error.dig(:error, 'messages')
      ensure
        # client.open_timeout = original_open
        # client.read_timeout = original_read

        duration = ((Time.now.utc.round(10) - start_time) * 1000).round(0)

        @logger.info(
          "Started #{request.method} #{request.path}\n"\
          "headers: #{request.instance_variable_get(:@header)}\nbody: #{request.body}\n"\
          "response: #{response&.force_encoding('utf-8')}\n"\
          "Completed #{request.method} #{request.path} #{duration} ms\n"
        )

        @logger.info "Error: #{@error.inspect}" if @error
      end
    end
  end
end
