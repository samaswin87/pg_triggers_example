# frozen_string_literal: true

# Model for pg_sql_triggers_registry table
# This provides access to the registry if PgSqlTriggers::Registry is not available
class PgSqlTriggersRegistry < ApplicationRecord
  self.table_name = 'pg_sql_triggers_registry'

  # Alias for enabled? method
  def enabled?
    enabled
  end

  # Class methods for compatibility with PgSqlTriggers::Registry API
  def self.enable_trigger(trigger_name)
    trigger = find_by(trigger_name: trigger_name)
    return false unless trigger
    
    # Use the engine's method if available, otherwise update directly
    if defined?(PgSqlTriggers::Registry) && PgSqlTriggers::Registry.respond_to?(:enable_trigger)
      PgSqlTriggers::Registry.enable_trigger(trigger_name)
    else
      trigger.update(enabled: true)
      # Re-enable the actual PostgreSQL trigger
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE #{trigger.table_name} ENABLE TRIGGER #{trigger_name};"
      ) rescue nil
      true
    end
  end

  def self.disable_trigger(trigger_name)
    trigger = find_by(trigger_name: trigger_name)
    return false unless trigger
    
    # Use the engine's method if available, otherwise update directly
    if defined?(PgSqlTriggers::Registry) && PgSqlTriggers::Registry.respond_to?(:disable_trigger)
      PgSqlTriggers::Registry.disable_trigger(trigger_name)
    else
      trigger.update(enabled: false)
      # Disable the actual PostgreSQL trigger
      ActiveRecord::Base.connection.execute(
        "ALTER TABLE #{trigger.table_name} DISABLE TRIGGER #{trigger_name};"
      ) rescue nil
      true
    end
  end
end

