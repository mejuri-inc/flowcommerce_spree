require 'pathname'

# Service class to manage product sync scheduling
module FlowcommerceSpree
  module ApiRefresh
    extend self

    SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)

    def data
      @data ||= FlowcommerceSpree::Config.product_catalog_upload || {}
    end

    def duration
      return '? (unknown)' if !data[:start] || !data[:end] || data[:start] > data[:end]

      (data[:end] - data[:start])/60
    end

    def write
      yield data
      FlowcommerceSpree::Config.product_catalog_upload = data
      @data = nil
    end

    def log(message)
      $stdout.puts message
      FlowcommerceSpree::LOGGER.info '%s (pid/ppid: %d/%d)' % [message, Process.pid, Process.ppid]
    end

    def schedule_refresh!
      write do |data|
        data[:force_refresh] = true
      end
    end

    def needs_refresh?
      return false if in_progress?

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

    def in_progress?
      return false unless data[:in_progress]

      puts 'Could not be run, another refresh is still in progress, quitting'
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
end
