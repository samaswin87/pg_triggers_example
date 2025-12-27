# frozen_string_literal: true

# Example trigger definition using PgSqlTriggers DSL
# This trigger validates user email format before insert/update
PgSqlTriggers::DSL.pg_sql_trigger "user_email_validation" do
  table :users
  on :insert, :update
  function "validate_user_email"
  version 1
  enabled true
  when_env :development, :test
end

