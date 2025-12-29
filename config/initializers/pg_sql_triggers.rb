# frozen_string_literal: true

PgSqlTriggers.configure do |config|
  # ========== Kill Switch Configuration ==========
  # The Kill Switch is a safety mechanism that prevents accidental destructive operations
  # in protected environments (production, staging, etc.)

  # Enable or disable the kill switch globally
  # Default: true (recommended for safety)
  config.kill_switch_enabled = true

  # Specify which environments should be protected by the kill switch
  # Default: %i[production staging]
  config.kill_switch_environments = %i[production staging]

  # Require confirmation text for kill switch overrides
  # When true, users must type a specific confirmation text to proceed
  # Default: true (recommended for maximum safety)
  config.kill_switch_confirmation_required = true

  # Custom confirmation pattern generator
  # Takes an operation symbol and returns the required confirmation text
  # Default: "EXECUTE <OPERATION_NAME>"
  config.kill_switch_confirmation_pattern = ->(operation) { "EXECUTE #{operation.to_s.upcase}" }

  # Logger for kill switch events
  # Default: Rails.logger
  config.kill_switch_logger = Rails.logger

  # Set the default environment detection
  # By default, uses Rails.env
  config.default_environment = -> { Rails.env }

  # Set a custom permission checker
  # This should return true/false based on the actor, action, and environment
  # Example:
  # config.permission_checker = ->(actor, action, environment) {
  #   # Your custom permission logic here
  #   # e.g., check if actor has required role for the action
  #   true
  # }
  config.permission_checker = nil

  # Tables to exclude from listing in the UI
  # Default excluded tables: ar_internal_metadata, schema_migrations, pg_sql_triggers_registry, trigger_migrations
  # Add additional tables you want to exclude:
  config.excluded_tables = %w[audit_logs]
end

# Load all trigger definitions from app/triggers directory
Rails.application.config.to_prepare do
  triggers_path = Rails.root.join("app/triggers")
  if triggers_path.exist?
    Dir.glob(triggers_path.join("**/*.rb")).each do |trigger_file|
      begin
        load trigger_file
      rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, PG::UndefinedTable => e
        # Database doesn't exist yet, connection unavailable, or table doesn't exist yet
        # This is expected during initial setup (e.g., running db:create or db:migrate)
        # Triggers will be loaded on subsequent boots once database and tables exist
        Rails.logger&.debug("Skipping trigger loading from #{trigger_file}: #{e.message}") if defined?(Rails.logger)
      rescue ActiveRecord::StatementInvalid => e
        # Handle StatementInvalid that wraps PG::UndefinedTable
        if e.cause.is_a?(PG::UndefinedTable)
          Rails.logger&.debug("Skipping trigger loading from #{trigger_file}: #{e.message}") if defined?(Rails.logger)
        else
          raise
        end
      end
    end
  end
end

