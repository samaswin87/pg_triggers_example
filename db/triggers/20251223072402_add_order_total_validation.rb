# frozen_string_literal: true

# Example trigger migration
# This creates a PostgreSQL function and trigger to validate order total is non-negative
class AddOrderTotalValidation < PgSqlTriggers::Migration
  def up
    # Create the function that validates order total
    execute <<-SQL
      CREATE OR REPLACE FUNCTION validate_order_total()
      RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.total_amount < 0 THEN
          RAISE EXCEPTION 'Order total_amount cannot be negative. Got: %', NEW.total_amount;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger
    execute <<-SQL
      CREATE TRIGGER order_total_validation
      BEFORE INSERT OR UPDATE ON orders
      FOR EACH ROW
      EXECUTE FUNCTION validate_order_total();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS order_total_validation ON orders;
      DROP FUNCTION IF EXISTS validate_order_total();
    SQL
  end
end

