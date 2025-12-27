# frozen_string_literal: true

# Example trigger migration
# This creates a PostgreSQL function and trigger to validate email format
class AddUserEmailValidation < PgSqlTriggers::Migration
  def up
    # Create the function that validates email format
    execute <<-SQL
      CREATE OR REPLACE FUNCTION validate_user_email()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
          RAISE EXCEPTION 'Invalid email format: %', NEW.email;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger
    execute <<-SQL
      CREATE TRIGGER user_email_validation
      BEFORE INSERT OR UPDATE ON users
      FOR EACH ROW
      EXECUTE FUNCTION validate_user_email();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS user_email_validation ON users;
      DROP FUNCTION IF EXISTS validate_user_email();
    SQL
  end
end

