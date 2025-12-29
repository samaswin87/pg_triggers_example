# frozen_string_literal: true

class AddTimingToPgSqlTriggersRegistry < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:pg_sql_triggers_registry, :timing)
      add_column :pg_sql_triggers_registry, :timing, :string, default: "before", null: false
    end
    
    unless index_exists?(:pg_sql_triggers_registry, :timing)
      add_index :pg_sql_triggers_registry, :timing
    end
  end

  def down
    if index_exists?(:pg_sql_triggers_registry, :timing)
      remove_index :pg_sql_triggers_registry, :timing
    end
    
    if column_exists?(:pg_sql_triggers_registry, :timing)
      remove_column :pg_sql_triggers_registry, :timing
    end
  end
end
