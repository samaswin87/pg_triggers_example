# PgSQL Triggers Example

A Rails application demonstrating PostgreSQL triggers using the `pg_sql_triggers` gem. This example project showcases various trigger features including timing (BEFORE/AFTER), conditions (WHEN clauses), and interactive testing capabilities.

## Features

- **Timing Control**: Triggers can fire BEFORE or AFTER database operations
- **Conditional Triggers**: Triggers can use SQL WHEN clauses to conditionally execute
- **Interactive Test UI**: Web-based interface for testing all trigger features
- **Trigger Management**: Enable/disable triggers dynamically through the UI
- **Multiple Examples**: Email validation, slug generation, audit logging, and more

## Prerequisites

- Ruby (see Gemfile for version requirements)
- PostgreSQL
- Rails 8.0+

## Getting Started

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Set up the database:**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

3. **Start the Rails server:**
   ```bash
   bin/rails server
   ```

4. **Access the application:**
   - **Test UI**: `http://localhost:3000` - Interactive interface for testing triggers
   - **Trigger Management UI**: `http://localhost:3000/pg_sql_triggers` - Full engine UI for managing triggers

## Example Triggers

- **User Email Validation** - Validates email format before insert/update
- **Post Slug Generation** - Automatically generates slugs from titles (BEFORE trigger)
- **Order Total Validation** - Ensures order totals are positive
- **Order Status Validation** - Validates order status with conditional execution
- **User Audit Logging** - Logs user changes to audit_logs table (AFTER trigger)
- **Comment Count Update** - Updates comment counts on posts

## Testing

The application includes an interactive test UI accessible at the root path. You can test all trigger features through the web interface, or refer to `TEST_EXAMPLES.md` for comprehensive test scenarios and examples.

To run the test suite:
```bash
bin/rails test
```

## Documentation

- **Test Examples**: See `TEST_EXAMPLES.md` for detailed test scenarios
- **Environment Setup**: See `ENV_SETUP.md` for environment variable configuration

## Project Structure

- `app/triggers/` - Trigger definitions using the PgSqlTriggers DSL
- `db/triggers/` - Trigger migrations
- `app/controllers/trigger_tests_controller.rb` - Test UI controller
- `app/views/trigger_tests/` - Test UI views
- `config/initializers/pg_sql_triggers.rb` - Trigger engine configuration
