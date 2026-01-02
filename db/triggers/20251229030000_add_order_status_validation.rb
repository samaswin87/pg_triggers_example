# frozen_string_literal: true

# Example trigger migration with CONDITION (WHEN clause)
# This creates a PostgreSQL function and trigger to validate order status
# The trigger only fires when status is not 'cancelled' (demonstrates condition feature)
class AddOrderStatusValidation < PgSqlTriggers::Migration
  def up
    # Create the function that validates order status
    execute <<-SQL
      CREATE OR REPLACE FUNCTION validate_order_status()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Only validate if status is being changed to something invalid
        IF NEW.status NOT IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') THEN
          RAISE EXCEPTION 'Invalid order status: %. Valid statuses are: pending, processing, shipped, delivered, cancelled, refunded', NEW.status;
        END IF;
        
        -- Prevent changing status from cancelled/refunded to active statuses
        IF OLD.status IN ('cancelled', 'refunded') AND NEW.status NOT IN ('cancelled', 'refunded') THEN
          RAISE EXCEPTION 'Cannot change order status from % to %. Once cancelled or refunded, order cannot be reactivated.', OLD.status, NEW.status;
        END IF;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger with WHEN condition
    # This trigger only fires when status is not 'cancelled'
    # Demonstrates the new condition feature
    execute <<-SQL
      CREATE TRIGGER order_status_validation
      BEFORE INSERT OR UPDATE ON orders
      FOR EACH ROW
      WHEN (NEW.status != 'cancelled')
      EXECUTE FUNCTION validate_order_status();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS order_status_validation ON orders;
      DROP FUNCTION IF EXISTS validate_order_status();
    SQL
  end
end

