# frozen_string_literal: true

# Flow (2017)
# api error logger and formater

require 'digest/sha1'

class Flow::Error < StandardError
  # logs error to file for easy discovery and fix
  def self.log(exception, request)
    history = exception.backtrace.reject { |el| el.index('/gems/') }.map { |el| el.sub(Rails.root.to_s, '') }.join($/)

    msg  = '%s in %s' % [exception.class, request.url]
    data = [msg, exception.message, history].join("\n\n")
    key  = Digest::SHA1.hexdigest exception.backtrace.first.split(' ').first

    folder = Rails.root.join('log/exceptions').to_s
    Dir.mkdir(folder) unless Dir.exists?(folder)

    folder += "/#{exception.class.to_s.tableize.gsub('/', '-')}"
    Dir.mkdir(folder) unless Dir.exists?(folder)

    "#{folder}/#{key}.txt".tap do |path|
      File.write(path, data)
    end
  end

  def self.format_message(exception)
    # format Flow errors in a special way
    # Io::Flow::V0::HttpClient::ServerError - 422 Unprocessable Entity: {"code":"invalid_number","messages":["Card number is not valid"]}
    # hash['code']    = 'invalid_number'
    # hash['message'] = 'Card number is not valid'
    # hash['title']   = '422 Unprocessable Entity'
    # hash['klass']   = 'Io::Flow::V0::HttpClient::ServerError'
    if exception.class == Io::Flow::V0::HttpClient::ServerError
      parts = exception.message.split(': ', 2)
      hash  = JSON.load(parts[1])

      hash[:message] = hash['messages'].join(', ')
      hash[:title]   = parts[0]
      hash[:klass]   = exception.class
      hash[:code]    = hash['code']
    else
      msg = exception.message.is_a?(Array) ? exception.message.join(' - ') : exception.message

      hash = {}
      hash[:message] = msg
      hash[:title]   = '-'
      hash[:klass]   = exception.class
      hash[:code]    = '-'
    end

    hash
  end

  def self.format_order_message(order, flow_experience = nil)
    message = if order['messages']
                msg = order['messages'].join(', ')

                if order['numbers']
                  msg += ' (%s)' % Spree::Variant.where(id: order['numbers']).map(&:name).join(', ')
                end

                msg
              else
                'Order not properly localized (sync issue)'
              end

    # sub_info = 'Flow.io'
    # sub_info += ' - %s' % flow_experience.key[0, 15] if flow_experience

    # '%s (%s)' % [message, sub_info]

    message
  end
end
