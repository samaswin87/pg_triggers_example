# Environment Setup Guide

This guide will help you set up environment variables for the PgTriggers Example application.

## Quick Setup

1. **Create your `.env` file** (copy from example):
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env`** with your PostgreSQL credentials if needed:
   ```bash
   # For most local PostgreSQL setups, these can be left blank
   # to use your system user (default PostgreSQL behavior)
   PG_TRIGGERS_EXAMPLE_DATABASE_USERNAME=
   PG_TRIGGERS_EXAMPLE_DATABASE_PASSWORD=
   
   # Or use DATABASE_URL for complete connection string
   # DATABASE_URL=postgres://username:password@localhost:5432/pg_triggers_example_development
   ```

3. **The `.env` file is automatically loaded** by the `dotenv-rails` gem in development and test environments.

## Environment Variables

### Database Configuration

- **`PG_TRIGGERS_EXAMPLE_DATABASE_USERNAME`** (optional)
  - PostgreSQL username
  - Leave blank to use your system user (default)

- **`PG_TRIGGERS_EXAMPLE_DATABASE_PASSWORD`** (optional)
  - PostgreSQL password
  - Leave blank if your PostgreSQL doesn't require a password

- **`DATABASE_URL`** (alternative)
  - Complete database connection string
  - Format: `postgres://username:password@host:port/database`
  - If set, this takes precedence over individual database config

### Rails Configuration

- **`PORT`** (default: 3000)
  - Port for the Rails server

- **`RAILS_MAX_THREADS`** (default: 5 for DB, 3 for Puma)
  - Maximum threads for Puma server
  - Should match or be less than database pool size

- **`RAILS_MASTER_KEY`** (optional)
  - Master key for encrypted credentials
  - Usually found in `config/master.key`
  - Only needed if using encrypted credentials

### Optional Configuration

- **`RAILS_LOG_LEVEL`** (default: info)
  - Options: debug, info, warn, error, fatal

- **`SOLID_QUEUE_IN_PUMA`** (default: false)
  - Set to `true` to run Solid Queue supervisor inside Puma

- **`JOB_CONCURRENCY`** (default: 1)
  - Number of processes dedicated to Solid Queue

- **`WEB_CONCURRENCY`** (default: 1)
  - Number of cores available to the application

## Testing Your Setup

1. **Check if PostgreSQL is running**:
   ```bash
   # macOS
   brew services list | grep postgresql
   
   # Or check if you can connect
   psql -l
   ```

2. **Create and migrate the database**:
   ```bash
   rails db:create
   rails db:migrate
   rake trigger:migrate
   ```

3. **Start the Rails server**:
   ```bash
   rails server
   ```

4. **Verify environment variables are loaded**:
   ```bash
   rails runner "puts ENV['PG_TRIGGERS_EXAMPLE_DATABASE_USERNAME']"
   ```

## Troubleshooting

### Database Connection Issues

If you get connection errors:

1. **Check PostgreSQL is running**:
   ```bash
   brew services start postgresql  # macOS
   ```

2. **Verify your credentials**:
   ```bash
   psql -U your_username -d postgres
   ```

3. **Try using DATABASE_URL**:
   ```bash
   # In .env file
   DATABASE_URL=postgres://your_username@localhost:5432/pg_triggers_example_development
   ```

### Environment Variables Not Loading

1. **Ensure dotenv-rails is installed**:
   ```bash
   bundle install
   ```

2. **Check .env file exists**:
   ```bash
   ls -la .env
   ```

3. **Restart your Rails server** after changing .env

## Production Setup

For production, use your deployment platform's environment variable configuration (not .env files):

- Heroku: `heroku config:set KEY=value`
- Kamal: Configure in `config/deploy.yml` under `env:`
- Docker: Use `-e` flags or docker-compose environment section

