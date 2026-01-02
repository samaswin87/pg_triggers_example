# Testing SQL Functions (SQL Capsules)

This document explains how to test SQL functions stored in `db/triggers/functions/` directory.

## Current SQL Functions

### `validate_comment_count.sql`
- **Location**: `db/triggers/functions/validate_comment_count.sql`
- **Purpose**: Validates that `comment_count` is greater than 0
- **Status**: Function file exists but is not currently used by any trigger

## How to Test SQL Functions

### Method 1: Test in Rails Console

```ruby
# Start Rails console
bin/rails console

# Check if function exists in database
ActiveRecord::Base.connection.execute("
  SELECT proname, prosrc 
  FROM pg_proc 
  WHERE proname = 'validate_comment_count'
").to_a

# If function doesn't exist, load it first
sql_file = Rails.root.join('db/triggers/functions/validate_comment_count.sql')
sql_content = File.read(sql_file)
ActiveRecord::Base.connection.execute(sql_content)

# Test the function by creating a test trigger
ActiveRecord::Base.connection.execute("
  CREATE OR REPLACE FUNCTION test_validate_comment_count()
  RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.comment_count <= 0 THEN
      RAISE EXCEPTION 'Invalid count: %', NEW.comment_count;
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
")

# Create a temporary trigger to test
ActiveRecord::Base.connection.execute("
  DROP TRIGGER IF EXISTS test_validate_post_comment_count ON posts;
  CREATE TRIGGER test_validate_post_comment_count
  BEFORE INSERT OR UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION test_validate_comment_count();
")

# Test with valid count (should succeed)
post = Post.create!(user_id: User.first.id, title: "Test", comment_count: 1)
puts "✅ Valid count works"

# Test with invalid count (should fail)
begin
  Post.create!(user_id: User.first.id, title: "Test", comment_count: 0)
  puts "❌ Should have failed"
rescue ActiveRecord::StatementInvalid => e
  puts "✅ Invalid count correctly rejected: #{e.message}"
end

# Clean up test trigger
ActiveRecord::Base.connection.execute("
  DROP TRIGGER IF EXISTS test_validate_post_comment_count ON posts;
  DROP FUNCTION IF EXISTS test_validate_comment_count();
")
```

### Method 2: Test via PostgreSQL Directly

```sql
-- Connect to your database
psql your_database_name

-- Load the function (if not already loaded)
\i db/triggers/functions/validate_comment_count.sql

-- Check if function exists
\df validate_comment_count

-- Create a test table to test the function
CREATE TEMP TABLE test_posts (
  id SERIAL PRIMARY KEY,
  comment_count INTEGER
);

-- Create a trigger to test
CREATE TRIGGER test_validate
BEFORE INSERT OR UPDATE ON test_posts
FOR EACH ROW
EXECUTE FUNCTION validate_comment_count();

-- Test with valid count (should succeed)
INSERT INTO test_posts (comment_count) VALUES (5);
SELECT * FROM test_posts;  -- Should show the row

-- Test with invalid count (should fail)
INSERT INTO test_posts (comment_count) VALUES (0);
-- Should raise: ERROR: Invalid count

-- Clean up
DROP TRIGGER test_validate ON test_posts;
DROP TABLE test_posts;
```

### Method 3: Create a Trigger Migration to Use the Function

To actually use the SQL function in a trigger, you would need to:

1. **Create a trigger migration** that uses the SQL file:

```ruby
# db/triggers/YYYYMMDDHHMMSS_add_comment_count_validation.rb
class AddCommentCountValidation < PgSqlTriggers::Migration
  def up
    # Load SQL function from file
    sql_file = Rails.root.join('db/triggers/functions/validate_comment_count.sql')
    execute File.read(sql_file)
    
    # Create trigger using the function
    execute <<-SQL
      CREATE TRIGGER post_comment_count_validation
      BEFORE INSERT OR UPDATE ON posts
      FOR EACH ROW
      EXECUTE FUNCTION validate_comment_count();
    SQL
  end
  
  def down
    execute "DROP TRIGGER IF EXISTS post_comment_count_validation ON posts;"
    execute "DROP FUNCTION IF EXISTS validate_comment_count();"
  end
end
```

2. **Run the trigger migration**:
```bash
bin/rails db:migrate:triggers
```

3. **Test the trigger** through the Rails app or console.

## Integration Testing

If you want to add the SQL function to your test suite, you can create a test file:

```ruby
# test/integration/validate_comment_count_test.rb
require 'test_helper'

class ValidateCommentCountTest < ActiveSupport::TestCase
  setup do
    @user = User.first || User.create!(name: "Test", email: "test@example.com")
    # Load the SQL function
    sql_file = Rails.root.join('db/triggers/functions/validate_comment_count.sql')
    ActiveRecord::Base.connection.execute(File.read(sql_file))
    # Create trigger
    ActiveRecord::Base.connection.execute("
      DROP TRIGGER IF EXISTS test_validate_post_comment_count ON posts;
      CREATE TRIGGER test_validate_post_comment_count
      BEFORE INSERT OR UPDATE ON posts
      FOR EACH ROW
      EXECUTE FUNCTION validate_comment_count();
    ")
  end
  
  teardown do
    ActiveRecord::Base.connection.execute("
      DROP TRIGGER IF EXISTS test_validate_post_comment_count ON posts;
    ")
  end
  
  test "allows positive comment_count" do
    post = Post.new(user_id: @user.id, title: "Test", comment_count: 5)
    assert post.save, "Should allow positive comment_count"
  end
  
  test "rejects zero comment_count" do
    post = Post.new(user_id: @user.id, title: "Test", comment_count: 0)
    assert_raises(ActiveRecord::StatementInvalid) do
      post.save!
    end
  end
  
  test "rejects negative comment_count" do
    post = Post.new(user_id: @user.id, title: "Test", comment_count: -1)
    assert_raises(ActiveRecord::StatementInvalid) do
      post.save!
    end
  end
end
```

## Quick Test Command

To quickly test if a SQL function file is valid SQL:

```bash
# Test SQL syntax (requires PostgreSQL connection)
bin/rails runner "
  sql_file = Rails.root.join('db/triggers/functions/validate_comment_count.sql')
  sql_content = File.read(sql_file)
  begin
    ActiveRecord::Base.connection.execute(sql_content)
    puts '✅ SQL function syntax is valid'
  rescue => e
    puts '❌ SQL function has errors: ' + e.message
  end
"
```

## Summary

- ✅ SQL function file exists: `db/triggers/functions/validate_comment_count.sql`
- ❌ SQL function is NOT currently integrated into any trigger
- ✅ You can test it manually using the methods above
- 📝 To use it, create a trigger migration that loads and uses the function

