# module for communication and customization based on Flow API
# for now all in same class

require 'logger'

module Flow
  ORGANIZATION = ENV.fetch('FLOW_ORGANIZATION', 'flow.io')
  BASE_COUNTRY = ENV.fetch('FLOW_BASE_COUNTRY', 'USA')
  API_KEY = ENV.fetch('FLOW_API_KEY', 'test_key')

  ENV['FLOW_TOKEN'] = API_KEY

  extend self

  # builds curl command and gets remote data
  def api(action, path, params = {}, body = nil)
    body ||= params.delete(:BODY)

    remote_params = URI.encode_www_form params
    remote_path   = debug_path = path.sub('%o', Flow::ORGANIZATION).sub(':organization', Flow::ORGANIZATION)
    remote_path  += '?%s' % remote_params unless remote_params.blank?

    curl = ['curl -s']
    curl.push '-X %s' % action.to_s.upcase
    curl.push '-u %s:' % API_KEY

    if body
      body = body.to_json unless body.is_a?(Array)
      curl.push '-H "Content-Type: application/json"'
      curl.push "-d '%s'" % body.gsub(%['], %['"'"']) if body
    end

    curl.push '"https://api.flow.io%s"' % remote_path
    command = curl.join(' ')

    puts command if defined?(Rails::Console)

    dir = Rails.root.join('log/api')
    Dir.mkdir(dir) unless Dir.exist?(dir)
    debug_file = '%s/%s.bash' % [dir, debug_path.gsub(/[^\w]+/, '_')]
    File.write debug_file, command + "\n"

    data = JSON.load `#{command}`

    if data.kind_of?(Hash) && data['code'] == 'generic_error'
      data
    else
      data
    end
  end

  def logger
    @logger ||= Logger.new('./log/flow.log') # or nil for no logging
  end

  def price_not_found
    'n/a'
  end

  def format_default_price(amount)
    '$%.2f' % amount
  end
end
