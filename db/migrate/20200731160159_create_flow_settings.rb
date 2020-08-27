class CreateFlowSettings < ActiveRecord::Migration
  def up
    unless table_exists?(:flow_settings)
      create_table :flow_settings do |t|
        t.text :type
        t.text :key
        t.jsonb :data, default: '{}'

        t.timestamps
      end
    end

    add_index :flow_settings, %i[id type key] unless index_exists?(:flow_settings, %i[id type key])
    add_index :flow_settings, :data, using: :gin unless index_exists?(:flow_settings, :data)
  end

  def down
    remove_index :flow_settings, :data if index_exists?(:flow_settings, :data)
    remove_index :flow_settings, %i[id type key] if index_exists?(:flow_settings, %i[id type key])
    drop_table :flow_settings if table_exists?(:flow_settings)
  end
end
