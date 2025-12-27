class RenamePgTriggersRegistryToPgSqlTriggersRegistry < ActiveRecord::Migration[8.0]
  def up
    # Only rename if the old table exists and new one doesn't
    return unless table_exists?(:pg_triggers_registry)
    return if table_exists?(:pg_sql_triggers_registry)
    
    rename_table :pg_triggers_registry, :pg_sql_triggers_registry
    
    # Rename indexes to match new table name
    # Note: PostgreSQL doesn't automatically rename indexes when table is renamed
    connection.execute(<<-SQL)
      ALTER INDEX IF EXISTS index_pg_triggers_registry_on_trigger_name 
      RENAME TO index_pg_sql_triggers_registry_on_trigger_name;
      
      ALTER INDEX IF EXISTS index_pg_triggers_registry_on_table_name 
      RENAME TO index_pg_sql_triggers_registry_on_table_name;
      
      ALTER INDEX IF EXISTS index_pg_triggers_registry_on_enabled 
      RENAME TO index_pg_sql_triggers_registry_on_enabled;
      
      ALTER INDEX IF EXISTS index_pg_triggers_registry_on_source 
      RENAME TO index_pg_sql_triggers_registry_on_source;
      
      ALTER INDEX IF EXISTS index_pg_triggers_registry_on_environment 
      RENAME TO index_pg_sql_triggers_registry_on_environment;
    SQL
  end

  def down
    return unless table_exists?(:pg_sql_triggers_registry)
    return if table_exists?(:pg_triggers_registry)
    
    # Rename indexes back
    connection.execute(<<-SQL)
      ALTER INDEX IF EXISTS index_pg_sql_triggers_registry_on_trigger_name 
      RENAME TO index_pg_triggers_registry_on_trigger_name;
      
      ALTER INDEX IF EXISTS index_pg_sql_triggers_registry_on_table_name 
      RENAME TO index_pg_triggers_registry_on_table_name;
      
      ALTER INDEX IF EXISTS index_pg_sql_triggers_registry_on_enabled 
      RENAME TO index_pg_triggers_registry_on_enabled;
      
      ALTER INDEX IF EXISTS index_pg_sql_triggers_registry_on_source 
      RENAME TO index_pg_triggers_registry_on_source;
      
      ALTER INDEX IF EXISTS index_pg_sql_triggers_registry_on_environment 
      RENAME TO index_pg_triggers_registry_on_environment;
    SQL
    
    rename_table :pg_sql_triggers_registry, :pg_triggers_registry
  end
end
