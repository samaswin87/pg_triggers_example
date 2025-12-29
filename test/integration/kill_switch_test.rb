# frozen_string_literal: true

require "test_helper"
require "stringio"

class KillSwitchTest < ActiveSupport::TestCase
  def setup
    # Ensure we have the registry table
    unless ActiveRecord::Base.connection.table_exists?(:pg_sql_triggers_registry)
      CreatePgTriggersTables.new.change
    end

    # Store original configuration
    @original_kill_switch_enabled = PgSqlTriggers.kill_switch_enabled
    @original_kill_switch_environments = PgSqlTriggers.kill_switch_environments

    # Reset kill switch configuration
    PgSqlTriggers.kill_switch_enabled = true
    PgSqlTriggers.kill_switch_environments = [:production, :staging]
  end

  def teardown
    # Restore original configuration
    PgSqlTriggers.kill_switch_enabled = @original_kill_switch_enabled if defined?(@original_kill_switch_enabled)
    PgSqlTriggers.kill_switch_environments = @original_kill_switch_environments if defined?(@original_kill_switch_environments)
    
    # Clear any overrides
    ENV.delete("KILL_SWITCH_OVERRIDE")
    ENV.delete("CONFIRMATION_TEXT")
  end

  # Test 1: Kill switch blocks operations in production
  test "kill switch blocks operations in production without confirmation" do
    assert_raises(PgSqlTriggers::KillSwitchError) do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production"
      )
    end
  end

  # Test 2: Kill switch allows operations in development
  test "kill switch allows operations in development" do
    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "development"
      )
    end
  end

  # Test 3: Kill switch allows operations in test
  test "kill switch allows operations in test environment" do
    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "test"
      )
    end
  end

  # Test 4: Override with ENV variable works
  test "kill switch override with ENV variable works" do
    ENV["KILL_SWITCH_OVERRIDE"] = "true"

    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production"
      )
    end
  ensure
    ENV.delete("KILL_SWITCH_OVERRIDE")
  end

  # Test 5: Override with confirmation text works
  test "kill switch override with correct confirmation text works" do
    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production",
        confirmation: "EXECUTE MIGRATE_UP"
      )
    end
  end

  # Test 6: Wrong confirmation text is rejected
  test "kill switch rejects incorrect confirmation text" do
    assert_raises(PgSqlTriggers::KillSwitchError) do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production",
        confirmation: "wrong confirmation"
      )
    end
  end

  # Test 7: Programmatic override block works
  test "kill switch programmatic override block works" do
    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.override do
        PgSqlTriggers::SQL::KillSwitch.check!(
          operation: :migrate_up,
          environment: "production"
        )
      end
    end
  end

  # Test 8: Kill switch active? method works correctly
  test "kill switch active? returns true for production" do
    assert PgSqlTriggers::SQL::KillSwitch.active?(environment: "production")
  end

  test "kill switch active? returns false for development" do
    assert_not PgSqlTriggers::SQL::KillSwitch.active?(environment: "development")
  end

  # Test 9: Kill switch can be disabled via configuration
  test "kill switch can be disabled via configuration" do
    original_setting = PgSqlTriggers.kill_switch_enabled
    PgSqlTriggers.kill_switch_enabled = false

    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production"
      )
    end
  ensure
    PgSqlTriggers.kill_switch_enabled = original_setting
  end

  # Test 10: Kill switch validates confirmation pattern
  test "kill switch validates confirmation pattern for different operations" do
    # Test migrate_up
    assert_raises(PgSqlTriggers::KillSwitchError) do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production",
        confirmation: "EXECUTE MIGRATE_DOWN" # Wrong operation
      )
    end

    # Test migrate_down
    assert_raises(PgSqlTriggers::KillSwitchError) do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_down,
        environment: "production",
        confirmation: "EXECUTE MIGRATE_UP" # Wrong operation
      )
    end

    # Test correct confirmations
    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production",
        confirmation: "EXECUTE MIGRATE_UP"
      )
    end

    assert_nothing_raised do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_down,
        environment: "production",
        confirmation: "EXECUTE MIGRATE_DOWN"
      )
    end
  end

  # Test 11: Kill switch logs blocked operations
  test "kill switch logs blocked operations" do
    log_output = StringIO.new
    original_logger = PgSqlTriggers.kill_switch_logger
    PgSqlTriggers.kill_switch_logger = Logger.new(log_output)

    begin
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "production"
      )
    rescue PgSqlTriggers::KillSwitchError
      # Expected
    end

    log_content = log_output.string
    assert_match(/KILL_SWITCH.*blocked/i, log_content)
  ensure
    PgSqlTriggers.kill_switch_logger = original_logger
  end

  # Test 12: Kill switch works with staging environment
  test "kill switch blocks operations in staging" do
    assert_raises(PgSqlTriggers::KillSwitchError) do
      PgSqlTriggers::SQL::KillSwitch.check!(
        operation: :migrate_up,
        environment: "staging"
      )
    end
  end
end

