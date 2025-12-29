# frozen_string_literal: true

class AddConditionToPgSqlTriggersRegistry < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:pg_sql_triggers_registry, :condition)
      add_column :pg_sql_triggers_registry, :condition, :text
    end
  end

  def down
    if column_exists?(:pg_sql_triggers_registry, :condition)
      remove_column :pg_sql_triggers_registry, :condition
    end
  end
end
