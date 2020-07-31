class CreateFlowSettings < ActiveRecord::Migration
  def change
    unless table_exists?(:flow_settings)
      create_table :flow_settings do |t|
        t.string :key
        t.jsonb :data, default: '{}'
        t.datetime :created_at
      end
    end
  end
end
