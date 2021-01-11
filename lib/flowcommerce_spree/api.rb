# frozen_string_literal: true

# module for communication and customization based on Flow API
# for now all in same class
module FlowcommerceSpree
  module Api
    extend self

    # builds curl command and gets remote data
    def run(action, path, params = {}, body = nil)
      body ||= params.delete(:BODY)

      remote_params = URI.encode_www_form params
      remote_path   = debug_path = path.sub('%o', ORGANIZATION).sub(':organization', ORGANIZATION)
      remote_path  += "?#{remote_params}" unless remote_params.blank?

      curl = ['curl -s']
      curl.push "-X #{action.to_s.upcase}"
      curl.push "-u #{API_KEY}:"

      if body
        body = body.to_json unless body.is_a?(Array)
        curl.push '-H "Content-Type: application/json"'
        curl.push "-d '#{body.gsub(%['], %['"'"'])}'" if body
      end

      curl.push "\"https://api.flow.io#{remote_path}\""
      command = curl.join(' ')

      puts command if defined?(Rails::Console)

      dir = Rails.root.join('log/api')
      Dir.mkdir(dir) unless Dir.exist?(dir)
      debug_file = "#{dir}/#{debug_path.gsub(/[^\w]+/, '_')}.bash"
      File.write debug_file, command + "\n"

      JSON.load `#{command}`
    end

    def logger
      @logger ||= Logger.new('./log/flow.log') # or nil for no logging
    end

    def format_default_price(amount)
      format('$%<price>.2f', amount)
    end
  end
end
