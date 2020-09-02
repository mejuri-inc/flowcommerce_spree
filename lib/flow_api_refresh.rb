require 'logger'
require 'pathname'

# Service class to manage product sync scheduling
module FlowApiRefresh
  extend self

  SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)
  LOGGER = Logger.new('log/flowcommerce.log', 3, 1024000)

  def settings
    FlowcommerceSpree::Settings.find_or_initialize_by(key: 'rake-products-refresh')
  end

  def data
    @data ||= settings.data
  end

  def duration
    return '? (unknown)' if !data[:start] || !data[:end] || data[:start] > data[:end]

    (data[:end] - data[:start])/60
  end

  def write
    yield data
    settings.update_attribute(:data, data)
    @data = nil
  end

  def log(message)
    $stdout.puts message
    LOGGER.info '%s (pid/ppid: %d/%d)' % [message, Process.pid, Process.ppid]
  end

  def schedule_refresh!
    write do |data|
      data[:force_refresh] = true
    end
  end

  def needs_refresh?
    now = Time.zone.now.to_i
    data[:end] ||= now - 10_000

    # needs refresh if last refresh started more than threshold ago
    if data[:end] < (now - (60 * SYNC_INTERVAL_IN_MINUTES))
      puts 'Last refresh ended long time ago, needs refresh.'
      true
    elsif data[:force_refresh]
      puts 'Force refresh scheduled, refreshing.'
      true
    else
      puts 'No need for refresh, ended before %d seconds.' % (now - data[:end])
      @data = nil
      false
    end
  end

  # for start just call log_refresh! and end it with has_ended: true statement
  def log_refresh!(has_ended: false)
    data.delete(:force_refresh)

    write do |data|
      if has_ended
        data[:end]       = Time.zone.now.to_i
        data.delete(:in_progress)
      else
        data[:in_progress] = true
        data[:start]       = Time.zone.now.to_i
      end
    end
  end
end
