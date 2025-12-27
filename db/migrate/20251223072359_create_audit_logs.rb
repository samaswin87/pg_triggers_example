class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.string :table_name, null: false
      t.string :record_id, null: false
      t.string :action, null: false # insert, update, delete
      t.text :old_values
      t.text :new_values
      t.string :changed_by
      t.timestamp :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :audit_logs, [:table_name, :record_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :occurred_at
  end
end

