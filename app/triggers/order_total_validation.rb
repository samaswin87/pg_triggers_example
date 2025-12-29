# frozen_string_literal: true

# Example trigger definition using PgSqlTriggers DSL
# This trigger validates that order total_amount is non-negative before insert/update
PgSqlTriggers::DSL.pg_sql_trigger "order_total_validation" do
  table :orders
  on :insert, :update
  function :validate_order_total
  version 1
  enabled true
  when_env :development, :test
end

