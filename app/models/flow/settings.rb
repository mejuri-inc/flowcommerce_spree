module Flow
  class Settings < ActiveRecord::Base
    self.table_name ='flow_settings'

    serialize :data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    class << self
      # create or set value with timestamp
      def set key, value
        settings            = find_or_initialize_by key: key
        settings.data       = value
        settings.created_at = DateTime.new
        settings.save

        value
      end
      alias :[]= :set

      def fetch key
        find_or_initialize_by key: key
      end

      def get key
        settings = find_by key: key
        settings ? settings.data : nil
      end
      alias :[] :get

      def delete key
        where(key: key).delete_all
      end
    end
  end
end
