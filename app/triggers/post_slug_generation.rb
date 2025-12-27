# frozen_string_literal: true

# Example trigger definition using PgSqlTriggers DSL
# This trigger automatically generates a slug from the title before insert/update
PgSqlTriggers::DSL.pg_sql_trigger "post_slug_generation" do
  table :posts
  on :insert, :update
  function "generate_post_slug"
  version 1
  enabled true
  when_env :development, :test
end

