# PgSQL Triggers Test Examples

This document provides comprehensive test examples for all the new features in `pg_sql_triggers`.

## 🚀 Quick Start

1. Start your Rails server: `bin/rails server`
2. Navigate to: `http://localhost:3000` (or your configured port)
3. Use the interactive test UI to test all trigger features

## 📋 New Features to Test

### 1. **Timing Feature** (BEFORE vs AFTER triggers)

The `timing` field allows you to specify when a trigger fires:
- `before`: Fires before the operation (can modify data, prevent operation)
- `after`: Fires after the operation (good for logging, side effects)

#### Test Examples:

**BEFORE Trigger (Post Slug Generation)**
```ruby
# In Rails console or via UI
post = Post.create!(user_id: 1, title: "My Awesome Post!", body: "Content here")
# Trigger fires BEFORE insert, so slug is generated before save
puts post.slug  # => "my-awesome-post"
```

**AFTER Trigger (User Audit Logging)**
```ruby
# In Rails console or via UI
user = User.find(1)
user.update(email: "newemail@example.com")
# Trigger fires AFTER update, creating audit log entry
audit_log = AuditLog.where(table_name: 'users', record_id: user.id).last
puts audit_log.action  # => "update"
puts audit_log.new_values  # => Contains updated user data
```

**Test via UI:**
- Go to "Test: Post Slug Generation" section
- Enter a title and submit
- Check that slug is auto-generated
- Go to "Test: User Audit Logging" section
- Update a user's email
- Check audit_logs table for new entry

---

### 2. **Condition Feature** (WHEN clause)

The `condition` field allows you to add a SQL WHEN clause to triggers, so they only fire when certain conditions are met.

#### Test Examples:

**Order Status Validation with Condition**
```ruby
# This trigger only fires when status != 'cancelled'
# So cancelled orders bypass validation

# This will trigger validation (status is 'pending')
order1 = Order.create!(user_id: 1, total_amount: 100.00, status: 'pending')
# ✅ Success

# This will trigger validation and fail (invalid status)
begin
  order2 = Order.create!(user_id: 1, total_amount: 100.00, status: 'invalid_status')
rescue => e
  puts e.message  # => "Invalid order status: invalid_status..."
end

# This will NOT trigger validation (status is 'cancelled', condition skips trigger)
order3 = Order.create!(user_id: 1, total_amount: -100.00, status: 'cancelled')
# ✅ Success (even with negative amount, because trigger didn't fire)
```

**Test via UI:**
- Go to "Test: Order Status Validation (BEFORE trigger with CONDITION)" section
- Try creating an order with status 'invalid_status' → Should fail
- Try creating an order with status 'cancelled' and negative amount → Should succeed (condition skips trigger)

---

### 3. **Kill Switch Feature**

The kill switch prevents accidental destructive operations in protected environments.

#### Test Examples:

**Testing Kill Switch in Development (should allow operations)**
```ruby
# In development, kill switch should allow operations
Rails.env = 'development'

# These should work normally
PgSqlTriggers::Registry.enable_trigger('user_email_validation')
PgSqlTriggers::Registry.disable_trigger('user_email_validation')
```

**Testing Kill Switch in Production (should block operations)**
```ruby
# Simulate production environment
Rails.env = 'production'

begin
  PgSqlTriggers::Registry.disable_trigger('user_email_validation')
rescue PgSqlTriggers::KillSwitchError => e
  puts e.message  # => Kill switch is active for this environment
end

# To override, you need confirmation
PgSqlTriggers::Registry.disable_trigger(
  'user_email_validation',
  kill_switch_override: 'EXECUTE DISABLE_TRIGGER'
)
```

**Test via UI:**
- The kill switch is configured in `config/initializers/pg_sql_triggers.rb`
- In development, you should be able to enable/disable triggers freely
- Try toggling triggers using the "Enable/Disable" buttons in the triggers table

---

## 🧪 Comprehensive Test Scenarios

### Scenario 1: User Email Validation (BEFORE trigger)

**Test Case 1.1: Valid Email**
```
Input: name="John Doe", email="john@example.com"
Expected: User created successfully
```

**Test Case 1.2: Invalid Email**
```
Input: name="John Doe", email="invalid-email"
Expected: Validation error (trigger prevents insert)
```

**Test Case 1.3: Missing Email**
```
Input: name="John Doe", email=""
Expected: Validation error
```

---

### Scenario 2: Post Slug Generation (BEFORE trigger)

**Test Case 2.1: Auto-generate Slug**
```
Input: title="My Awesome Post!"
Expected: slug="my-awesome-post"
```

**Test Case 2.2: Slug from Complex Title**
```
Input: title="Hello, World! (2024)"
Expected: slug="hello-world-2024"
```

**Test Case 2.3: Update Title Changes Slug**
```
1. Create post with title="Original Title"
2. Update title to "New Title"
Expected: slug changes to "new-title"
```

---

### Scenario 3: Order Total Validation (BEFORE trigger)

**Test Case 3.1: Valid Positive Total**
```
Input: total_amount=100.00
Expected: Order created successfully
```

**Test Case 3.2: Negative Total**
```
Input: total_amount=-10.00
Expected: Error: "Order total_amount cannot be negative"
```

**Test Case 3.3: Zero Total**
```
Input: total_amount=0.00
Expected: Order created successfully
```

---

### Scenario 4: Order Status Validation with Condition (BEFORE trigger with WHEN clause)

**Test Case 4.1: Valid Status (Trigger Fires)**
```
Input: status="pending", total_amount=100.00
Expected: Order created successfully
```

**Test Case 4.2: Invalid Status (Trigger Fires)**
```
Input: status="invalid_status", total_amount=100.00
Expected: Error: "Invalid order status: invalid_status..."
```

**Test Case 4.3: Cancelled Status (Trigger Skips - Condition)**
```
Input: status="cancelled", total_amount=-100.00
Expected: Order created successfully (trigger didn't fire due to condition)
```

**Test Case 4.4: Change from Cancelled to Active**
```
1. Create order with status="cancelled"
2. Try to update status to "pending"
Expected: Error: "Cannot change order status from cancelled to pending..."
```

---

### Scenario 5: Comment Count Update (AFTER trigger)

**Test Case 5.1: Add Comment**
```
1. Post has comment_count=0
2. Create comment on post
Expected: Post comment_count becomes 1
```

**Test Case 5.2: Delete Comment**
```
1. Post has comment_count=2
2. Delete one comment
Expected: Post comment_count becomes 1
```

**Test Case 5.3: Multiple Comments**
```
1. Create 3 comments on same post
Expected: Post comment_count becomes 3
```

---

### Scenario 6: User Audit Logging (AFTER trigger)

**Test Case 6.1: Insert User**
```
1. Create new user
Expected: Audit log entry with action="insert", new_values populated
```

**Test Case 6.2: Update User**
```
1. Update user email
Expected: Audit log entry with action="update", old_values and new_values populated
```

**Test Case 6.3: Delete User**
```
1. Delete user
Expected: Audit log entry with action="delete", old_values populated
```

---

## 🔍 Testing Trigger Registry Features

### View All Triggers
```ruby
# In Rails console
PgSqlTriggers::Registry.all.each do |trigger|
  puts "#{trigger.trigger_name}: #{trigger.table_name} (#{trigger.timing}) - #{trigger.enabled? ? 'Enabled' : 'Disabled'}"
  puts "  Condition: #{trigger.condition || 'None'}"
end
```

### Check Trigger Details
```ruby
trigger = PgSqlTriggers::Registry.find_by(trigger_name: 'order_status_validation')
puts "Timing: #{trigger.timing}"
puts "Condition: #{trigger.condition}"
puts "Enabled: #{trigger.enabled?}"
puts "Function Body: #{trigger.function_body}"
```

### Enable/Disable Triggers
```ruby
# Disable a trigger
PgSqlTriggers::Registry.disable_trigger('user_email_validation')

# Enable a trigger
PgSqlTriggers::Registry.enable_trigger('user_email_validation')

# Check if enabled
PgSqlTriggers::Registry.find_by(trigger_name: 'user_email_validation').enabled?
```

---

## 🎯 UI Testing Checklist

### Triggers Registry Table
- [ ] View all registered triggers
- [ ] See timing (BEFORE/AFTER) for each trigger
- [ ] See condition (WHEN clause) for triggers that have it
- [ ] See enabled/disabled status
- [ ] Toggle trigger enable/disable status

### Test Forms
- [ ] Test User Email Validation (valid and invalid emails)
- [ ] Test Post Slug Generation (verify slug is created)
- [ ] Test Order Total Validation (positive and negative amounts)
- [ ] Test Order Status Validation with Condition (valid, invalid, and cancelled statuses)
- [ ] Test Comment Count Update (verify count increments)
- [ ] Test User Audit Logging (verify audit log entries created)

### Data Display
- [ ] View recent users
- [ ] View recent posts (with slugs and comment counts)
- [ ] View recent orders (with statuses)
- [ ] View recent audit logs

---

## 🐛 Troubleshooting

### Trigger Not Firing
1. Check if trigger is enabled: `PgSqlTriggers::Registry.find_by(trigger_name: '...').enabled?`
2. Check if condition is preventing trigger from firing
3. Verify trigger is installed: Check `installed_at` in registry
4. Check Rails logs for errors

### Condition Not Working
1. Verify condition syntax is correct SQL
2. Check that condition uses `NEW` or `OLD` correctly based on trigger timing
3. Test condition in PostgreSQL directly: `SELECT NEW.status != 'cancelled'`

### Kill Switch Issues
1. Check current environment: `Rails.env`
2. Check kill switch configuration in `config/initializers/pg_sql_triggers.rb`
3. Verify kill switch environments include current environment

---

## 📚 Additional Resources

- PgSQL Triggers Engine UI: `/pg_sql_triggers`
- Trigger definitions: `app/triggers/*.rb`
- Trigger migrations: `db/triggers/*.rb`
- Configuration: `config/initializers/pg_sql_triggers.rb`

---

## 🎉 Success Criteria

You've successfully tested all features when:

1. ✅ All triggers appear in the registry table with correct timing
2. ✅ Triggers with conditions show the condition in the UI
3. ✅ BEFORE triggers modify data or prevent operations correctly
4. ✅ AFTER triggers create side effects (logs, updates) correctly
5. ✅ Condition (WHEN clause) properly skips triggers when condition is false
6. ✅ Enable/disable toggle works for all triggers
7. ✅ All test forms produce expected results
8. ✅ Audit logs are created for user changes
9. ✅ Comment counts update automatically
10. ✅ Kill switch prevents operations in protected environments (if testing in production/staging)

