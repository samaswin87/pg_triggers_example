# frozen_string_literal: true

# Example trigger migration
# This creates a PostgreSQL function and trigger to update comment_count on posts
class AddPostCommentCountUpdate < PgSqlTriggers::Migration
  def up
    # Create the function that updates comment_count
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_post_comment_count()
      RETURNS TRIGGER AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          UPDATE posts
          SET comment_count = comment_count + 1
          WHERE id = NEW.post_id;
          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          UPDATE posts
          SET comment_count = GREATEST(comment_count - 1, 0)
          WHERE id = OLD.post_id;
          RETURN OLD;
        END IF;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger
    execute <<-SQL
      CREATE TRIGGER post_comment_count_update
      AFTER INSERT OR DELETE ON comments
      FOR EACH ROW
      EXECUTE FUNCTION update_post_comment_count();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS post_comment_count_update ON comments;
      DROP FUNCTION IF EXISTS update_post_comment_count();
    SQL
  end
end

