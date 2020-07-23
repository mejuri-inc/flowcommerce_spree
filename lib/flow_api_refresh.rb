# Flow.io (2017)
# helper class to manage product sync scheduling

require 'json'
require 'logger'
require 'pathname'

module FlowApiRefresh
  extend self

  SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)
  # CHECK_FILE = Pathname.new './tmp/last-flow-refresh.txt' unless defined?(CHECK_FILE)
  LOGGER = Logger.new('./log/sync.log', 3, 1024000) unless defined?(LOGGER)

  ###

  def now
    Time.now.to_i
  end

  def settings
    FlowSettings.fetch 'rake-products-refresh'
  end

  def data
    # CHECK_FILE.exist? ? JSON.parse(CHECK_FILE.read) : {}
    @data ||= JSON.load(settings.data || '{}')
  end

  def duration
    return '? (unknown)' if !data['start'] || !data['end'] || data['start'] > data['end']

    (data['end'] - data['start'])/60
  end

  def write
    yield data
    settings.update_attribute :data, data.to_json
    data
  end

  def log message
    $stdout.puts message
    LOGGER.info '%s (pid/ppid: %d/%d)' % [message, Process.pid, Process.ppid]
  end

  def schedule_refresh!
    write do |data|
      data['force_refresh'] = true
    end
  end

  def needs_refresh?
    data['end'] ||= now - 10_000

    # needs refresh if last refresh started more than treshold ago
    if data['end'] < (now - (60 * SYNC_INTERVAL_IN_MINUTES))
      puts 'Last refresh ended long time ago, needs refresh.'
      return true

    elsif data['force_refresh']
      puts 'Force refresh schecduled, refreshing.'
      true

    else
      puts 'No need for refresh, ended before %d seconds.' % (now - data['end'])
      false

    end
  end

  # for start just call log_refresh! and end it with true statement
  def log_refresh! has_ended=false
    data.delete('force_refresh')

    write do |data|
      if has_ended
        data['start']   ||= now - 60
        data['end']       = now
        data.delete('in_progress')
      else
        data['in_progress'] = true
        data['start']       = now
      end
    end
  end

  def refresh_info
    return 'No last sync data' unless data['end']

    helper = Class.new
    helper.extend ActionView::Helpers::DateHelper

    info = []
    info.push 'Sync started %d seconds ago (it is in progress).' % (Time.now.to_i - data['start'].to_i) if data['started']
    info.push 'Last sync finished %{finished} ago and lasted for %{duration}. We sync every %{every} minutes.' %
      {
        finished: helper.distance_of_time_in_words(Time.now, data['end'].to_i),
        duration: helper.distance_of_time_in_words(duration),
        every:    SYNC_INTERVAL_IN_MINUTES
      }

    info.join(' ')
  end

  def sync_products_if_needed
    return unless needs_refresh?

    log_refresh!

    log 'Sync needed, running ...'
    system 'bundle exec rake flow:sync_localized_items'

    log_refresh
  end
end
