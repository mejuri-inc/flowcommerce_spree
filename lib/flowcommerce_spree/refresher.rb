require 'pathname'

# Service class to manage product sync scheduling
module FlowcommerceSpree
  class Refresher
    SYNC_INTERVAL_IN_MINUTES = 60 unless defined?(SYNC_INTERVAL_IN_MINUTES)

    attr_reader :logger

    def initialize(logger: FlowcommerceSpree.logger)
      @logger = logger
    end

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
        logger.info 'Last refresh ended long time ago, needs refresh.'
        true
      elsif data[:force_refresh]
        logger.info 'Force refresh scheduled, refreshing.'
        true
      else
        logger.info 'No need for refresh, ended before %d seconds.' % (now - data[:end])
        @data = nil
        false
      end
    end

    def in_progress?
      # This method needs fresh data, that's why not using the memoized `data` method
      @data = FlowcommerceSpree::Config.product_catalog_upload || {}
      return false unless data[:in_progress]

      logger.info 'Could not be run, another refresh is still in progress, quitting'
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
