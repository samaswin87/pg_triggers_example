# frozen_string_literal: true

# Example trigger migration
# This creates a PostgreSQL function and trigger to log all changes to users table
class AddUserAuditLogging < PgSqlTriggers::Migration
  def up
    # Create the function that logs user changes
    execute <<-SQL
      CREATE OR REPLACE FUNCTION log_user_changes()
      RETURNS TRIGGER AS $$
      DECLARE
        old_json jsonb;
        new_json jsonb;
      BEGIN
        IF TG_OP = 'DELETE' THEN
          old_json := to_jsonb(OLD);
          INSERT INTO audit_logs (table_name, record_id, action, old_values, occurred_at, created_at, updated_at)
          VALUES ('users', OLD.id::text, 'delete', old_json::text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
          RETURN OLD;
        ELSIF TG_OP = 'UPDATE' THEN
          old_json := to_jsonb(OLD);
          new_json := to_jsonb(NEW);
          INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, occurred_at, created_at, updated_at)
          VALUES ('users', NEW.id::text, 'update', old_json::text, new_json::text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
          RETURN NEW;
        ELSIF TG_OP = 'INSERT' THEN
          new_json := to_jsonb(NEW);
          INSERT INTO audit_logs (table_name, record_id, action, new_values, occurred_at, created_at, updated_at)
          VALUES ('users', NEW.id::text, 'insert', new_json::text, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
          RETURN NEW;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger
    execute <<-SQL
      CREATE TRIGGER user_audit_logging
      AFTER INSERT OR UPDATE OR DELETE ON users
      FOR EACH ROW
      EXECUTE FUNCTION log_user_changes();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS user_audit_logging ON users;
      DROP FUNCTION IF EXISTS log_user_changes();
    SQL
  end
end

