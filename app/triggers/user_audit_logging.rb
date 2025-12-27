# frozen_string_literal: true

# Example trigger definition using PgSqlTriggers DSL
# This trigger logs all changes to users table for audit purposes
PgSqlTriggers::DSL.pg_sql_trigger "user_audit_logging" do
  table :users
  on :insert, :update, :delete
  function "log_user_changes"
  version 1
  enabled true
  when_env :development, :test
end

