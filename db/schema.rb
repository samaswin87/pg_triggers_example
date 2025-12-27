# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_27_131711) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "table_name", null: false
    t.string "record_id", null: false
    t.string "action", null: false
    t.text "old_values"
    t.text "new_values"
    t.string "changed_by"
    t.datetime "occurred_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["occurred_at"], name: "index_audit_logs_on_occurred_at"
    t.index ["table_name", "record_id"], name: "index_audit_logs_on_table_name_and_record_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "pg_sql_triggers_registry", force: :cascade do |t|
    t.string "trigger_name", null: false
    t.string "table_name", null: false
    t.integer "version", default: 1, null: false
    t.boolean "enabled", default: false, null: false
    t.string "checksum", null: false
    t.string "source", null: false
    t.string "environment"
    t.text "definition"
    t.text "function_body"
    t.datetime "installed_at", precision: nil
    t.datetime "last_verified_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_pg_sql_triggers_registry_on_enabled"
    t.index ["environment"], name: "index_pg_sql_triggers_registry_on_environment"
    t.index ["source"], name: "index_pg_sql_triggers_registry_on_source"
    t.index ["table_name"], name: "index_pg_sql_triggers_registry_on_table_name"
    t.index ["trigger_name"], name: "index_pg_sql_triggers_registry_on_trigger_name", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "slug"
    t.text "body"
    t.integer "comment_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_posts_on_slug"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "trigger_migrations", force: :cascade do |t|
    t.string "version", null: false
    t.index ["version"], name: "index_trigger_migrations_on_version", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "orders", "users"
  add_foreign_key "posts", "users"
end
