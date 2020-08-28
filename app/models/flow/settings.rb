module Flow
  class Settings < ActiveRecord::Base
    self.table_name ='flow_settings'

    serialize :data, ActiveRecord::Coders::JSON.new(symbolize_keys: true)

    class << self
      # create or set value with timestamp
      def set(key, value)
        setting            = find_or_initialize_by(key: key)
        setting.data       = value
        setting.save

        value
      end
      alias :[]= :set

      def get(key)
        setting = find_by(key: key)
        setting ? setting.data : nil
      end
      alias :[] :get

      def delete(key)
        where(key: key).delete_all
      end
    end
  end
end
