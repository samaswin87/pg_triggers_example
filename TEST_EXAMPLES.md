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

### Triggers Registry Table (Test UI at `/`)
- [ ] View all registered triggers
- [ ] See timing (BEFORE/AFTER) for each trigger
- [ ] See condition (WHEN clause) for triggers that have it
- [ ] See enabled/disabled status
- [ ] Toggle trigger enable/disable status

### Test Forms (Test UI at `/`)
- [ ] Test User Email Validation (valid and invalid emails)
- [ ] Test Post Slug Generation (verify slug is created)
- [ ] Test Order Total Validation (positive and negative amounts)
- [ ] Test Order Status Validation with Condition (valid, invalid, and cancelled statuses)
- [ ] Test Comment Count Update (verify count increments)
- [ ] Test User Audit Logging (verify audit log entries created)

### Data Display (Test UI at `/`)
- [ ] View recent users
- [ ] View recent posts (with slugs and comment counts)
- [ ] View recent orders (with statuses)
- [ ] View recent audit logs

---

## 🖥️ PgSQL Triggers Engine UI Testing (`/pg_sql_triggers`)

The gem provides a comprehensive UI at `/pg_sql_triggers` for managing triggers, viewing registry, and more.

### Dashboard (`/pg_sql_triggers` or `/pg_sql_triggers/dashboard`)

**Statistics Cards:**
- [ ] View Total Triggers count
- [ ] View Enabled triggers count
- [ ] View Disabled triggers count
- [ ] View Drifted triggers count (triggers that differ from registry)

**Recent Triggers Table:**
- [ ] View recent triggers with trigger name, table, version, status, source
- [ ] See trigger status (Enabled/Disabled) badges
- [ ] See source badges (migration, manual, etc.)
- [ ] View "Last Applied" timestamp for each trigger
- [ ] Enable/Disable triggers from dashboard
- [ ] Click trigger name to view trigger details
- [ ] See "Re-execute" button for drifted triggers
- [ ] See "Drop" button for triggers (if permissions allow)

**Migration Management Section:**
- [ ] View migration statistics (Total Migrations, Applied, Pending, Current Version)
- [ ] See pending migrations list (if any)
- [ ] Apply All Pending Migrations button
- [ ] Rollback Last Migration button
- [ ] Redo Last Migration button
- [ ] View Migration Status table with all migrations
- [ ] See migration status (Applied/Pending) badges
- [ ] Use "Up" button for pending migrations (applies individual migration)
- [ ] Use "Down" button for applied migrations (rollbacks individual migration)
- [ ] Use "Redo" button for applied migrations (redo individual migration)
- [ ] Navigate pagination (Previous/Next buttons)
- [ ] Change items per page (10, 20, 50, 100)
- [ ] See pagination info (Page X of Y)
- [ ] Confirmations show for migration actions (kill switch protection)

### Tables Index (`/pg_sql_triggers/tables`)

**Statistics:**
- [ ] View "Tables with Triggers" count

**Tables List:**
- [ ] View all tables that have triggers
- [ ] See table name and trigger count
- [ ] See trigger names and function names for each table
- [ ] See enabled/disabled status for each trigger
- [ ] See "DB Only" badges for triggers not in registry
- [ ] See status summary (X Enabled, Y Disabled) for each table
- [ ] Click "View Details" to see table details
- [ ] Click "Create Trigger" to generate new trigger for table

**Empty State:**
- [ ] See message when no tables with triggers found
- [ ] See "Generate New Trigger" button in empty state

### Table Details (`/pg_sql_triggers/tables/:table_name`)

**Table Information:**
- [ ] View table columns (name, data type, nullable status)
- [ ] See breadcrumb navigation (Dashboard > Tables > Table Name)

**Registered Triggers Section:**
- [ ] View all registered triggers for the table
- [ ] See trigger name (link to trigger details), status, version, source
- [ ] See environment information (if present)
- [ ] See function name and events for each trigger
- [ ] View function body (expandable details section)
- [ ] Enable/Disable trigger buttons (with confirmation modals)
- [ ] See "Re-execute" button for drifted triggers
- [ ] See "Drop" button (with confirmation modal)
- [ ] Click "Create a trigger" if no registered triggers

**Database Triggers Section (Not in Registry):**
- [ ] View triggers that exist in database but not in registry
- [ ] See "DB Only" badges
- [ ] View trigger definition (expandable details section)
- [ ] Section shows warning style (yellow background)

**Actions:**
- [ ] Click "← Back to Tables" to return to tables list
- [ ] Click "Create Trigger for this Table" button

### Trigger Details (`/pg_sql_triggers/triggers/:id`)

**Navigation:**
- [ ] See breadcrumb navigation (Dashboard > Tables > Table Name > Trigger Name)
- [ ] Click breadcrumb links to navigate

**Drift Warning:**
- [ ] See drift warning banner if trigger has drifted
- [ ] See drift type information

**Trigger Summary:**
- [ ] View trigger status (Enabled/Disabled badge)
- [ ] View table name, version, source
- [ ] View environment (if present)
- [ ] View "Last Applied" timestamp
- [ ] View "Last Verified" timestamp (if present)
- [ ] View "Created At" timestamp

**Trigger Configuration:**
- [ ] View function name
- [ ] View timing (BEFORE/AFTER badge)
- [ ] View events (INSERT, UPDATE, DELETE, TRUNCATE badges)
- [ ] View condition (WHEN clause) if present
- [ ] View environments (if specified)

**SQL Drift Comparison (if drift detected):**
- [ ] View "Expected SQL" (from DSL) in green background
- [ ] View "Actual SQL" (from database) in red background
- [ ] Compare differences between expected and actual

**Function Body:**
- [ ] View complete function body code
- [ ] Code is properly formatted in code block

**Action Buttons:**
- [ ] Enable/Disable trigger button (with confirmation modal)
- [ ] See "Re-execute Trigger" button if drift detected (with confirmation modal)
- [ ] See "Drop Trigger" button (with confirmation modal and kill switch protection)
- [ ] Click "← Back to Dashboard" to return
- [ ] Click "View Table" to see table details

### Trigger Generator (`/pg_sql_triggers/generator/new`)

**Basic Information Section:**
- [ ] Enter trigger name (lowercase, underscores only)
- [ ] Select table name from dropdown
- [ ] See table validation message (✓ Table exists or ✗ Table not found)
- [ ] See existing triggers info for selected table
- [ ] Enter function name
- [ ] Enter function body (PL/pgSQL code)
- [ ] Function body template updates when function name changes
- [ ] See validation errors for required fields

**Trigger Events Section:**
- [ ] Select timing (Before/After)
- [ ] Select events (INSERT, UPDATE, DELETE, TRUNCATE checkboxes)
- [ ] At least one event must be selected

**Configuration Section:**
- [ ] Set version number (default: 1)
- [ ] Select target environments (Development, Test, Staging, Production checkboxes)
- [ ] Enter WHEN condition (optional SQL condition)
- [ ] Check/uncheck "Enable trigger after creation"
- [ ] Check/uncheck "Generate PL/pgSQL function stub"

**Form Validation:**
- [ ] Client-side validation works (shows errors before submit)
- [ ] Server-side validation works (shows errors after submit)
- [ ] Validation for trigger name format
- [ ] Validation for function name format
- [ ] Validation for function body containing function definition
- [ ] Validation for at least one event selected

**Actions:**
- [ ] Click "Preview Generated Code" to preview
- [ ] Click "Cancel" to go back

### Trigger Generator Preview (`/pg_sql_triggers/generator/preview`)

**Preview Display:**
- [ ] View generated migration code
- [ ] View generated function code (if stub selected)
- [ ] Code is properly formatted
- [ ] Confirm to create trigger
- [ ] Go back to edit form

### SQL Capsules (`/pg_sql_triggers/sql_capsules/new`)

**Warning Banner:**
- [ ] See warning about SQL Capsules being dangerous
- [ ] Warning mentions emergency operations only

**Form Fields:**
- [ ] Enter capsule name (alphanumeric, underscores, hyphens)
- [ ] Enter environment
- [ ] Enter purpose (description text area)
- [ ] Enter SQL statement (code text area)

**Actions:**
- [ ] Click "Cancel" to return to dashboard
- [ ] Click "Create Capsule" to save

**SQL Capsule View (`/pg_sql_triggers/sql_capsules/:id`):**
- [ ] View capsule details
- [ ] View SQL code
- [ ] Execute capsule (with confirmation)

### Audit Logs (`/pg_sql_triggers/audit_logs`)

**Filters:**
- [ ] Filter by trigger name (dropdown with "All" option)
- [ ] Filter by operation (dropdown with "All" option)
- [ ] Filter by status (All, Success, Failure)
- [ ] Filter by environment (dropdown with "All" option)
- [ ] Select sort order (Newest First, Oldest First)
- [ ] Click "Apply Filters" to filter results
- [ ] Click "Clear" to reset filters

**Results:**
- [ ] See total results count
- [ ] See "(filtered)" indicator when filters applied
- [ ] View audit log entries in table format
- [ ] See time (relative and absolute), trigger name (link to trigger), operation, status, environment, actor, reason, error message
- [ ] Status badges (Success in green, Failure in red)
- [ ] Click trigger name to view trigger details
- [ ] Truncated text shows full on hover (reason, error message)

**Pagination:**
- [ ] Navigate Previous/Next pages
- [ ] See "Page X of Y" indicator
- [ ] Previous/Next buttons disabled at boundaries

**Export:**
- [ ] Click "Export CSV" to download CSV file
- [ ] CSV includes filtered results
- [ ] CSV includes all columns

**Empty State:**
- [ ] See message when no audit log entries found
- [ ] See suggestion to adjust filters if filters applied

### Kill Switch Status

**Kill Switch Active (Production/Staging):**
- [ ] See kill switch active banner (yellow/warning style)
- [ ] See environment name in banner
- [ ] Banner mentions confirmation required
- [ ] Confirmation modals appear for dangerous operations
- [ ] Must enter kill switch override text to proceed

**Kill Switch Inactive (Development/Test):**
- [ ] See kill switch inactive banner (blue/info style)
- [ ] See environment name in banner
- [ ] Banner mentions operations can be performed without confirmation
- [ ] No confirmation required for operations

### Confirmation Modals

**Modal Features:**
- [ ] Modal appears for Enable/Disable trigger actions
- [ ] Modal appears for Drop trigger actions
- [ ] Modal appears for Re-execute trigger actions
- [ ] Modal appears for migration actions (Up, Down, Redo)
- [ ] Modal shows operation title
- [ ] Modal shows confirmation message
- [ ] Modal shows kill switch override field (if kill switch active)
- [ ] Can cancel modal (closes without action)
- [ ] Can confirm action (proceeds with operation)
- [ ] Modal blocks interaction with page behind it

### General UI Features

**Navigation:**
- [ ] Navigate between Dashboard, Tables, Triggers
- [ ] Breadcrumbs work correctly
- [ ] Back buttons work correctly
- [ ] Links to related pages work correctly

**Responsive Design:**
- [ ] UI works on different screen sizes
- [ ] Tables are scrollable on small screens
- [ ] Grid layouts adapt to screen size

**Error Handling:**
- [ ] Error messages display correctly
- [ ] Flash messages show success/error/warning
- [ ] Validation errors show inline in forms
- [ ] 404 errors handled gracefully

**Permissions:**
- [ ] Buttons hidden if user lacks permissions
- [ ] Enable/Disable buttons only show if permitted
- [ ] Drop buttons only show if permitted
- [ ] Actions fail gracefully with permission errors

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

