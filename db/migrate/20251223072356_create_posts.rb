class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :slug
      t.text :body
      t.integer :comment_count, default: 0, null: false

      t.timestamps
    end

    add_index :posts, :slug
  end
end

