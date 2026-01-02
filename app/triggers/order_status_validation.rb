# frozen_string_literal: true

# Example trigger definition using PgSqlTriggers DSL with CONDITION feature
# This trigger validates order total only when status is not 'cancelled'
# Demonstrates the new condition (WHEN clause) feature
PgSqlTriggers::DSL.pg_sql_trigger "order_status_validation" do
  table :orders
  on :insert, :update
  function :validate_order_status
  version 1
  enabled true
  timing :before
  when_condition "NEW.status != 'cancelled'"
  when_env :development, :test
end

