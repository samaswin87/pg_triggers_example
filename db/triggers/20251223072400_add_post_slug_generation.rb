# frozen_string_literal: true

# Example trigger migration
# This creates a PostgreSQL function and trigger to auto-generate slug from title
class AddPostSlugGeneration < PgSqlTriggers::Migration
  def up
    # Create the function that generates slug from title
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_post_slug()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Only generate slug if it's not already set or title changed
        IF NEW.slug IS NULL OR (TG_OP = 'UPDATE' AND OLD.title != NEW.title) THEN
          -- Convert title to lowercase, replace non-alphanumeric with hyphens
          NEW.slug := lower(regexp_replace(NEW.title, '[^a-zA-Z0-9]+', '-', 'g'));
          -- Remove leading/trailing hyphens
          NEW.slug := trim(both '-' from NEW.slug);
          -- Ensure slug is not empty
          IF NEW.slug = '' THEN
            NEW.slug := 'post-' || COALESCE(NEW.id::text, 'new');
          END IF;
        END IF;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger
    execute <<-SQL
      CREATE TRIGGER post_slug_generation
      BEFORE INSERT OR UPDATE ON posts
      FOR EACH ROW
      EXECUTE FUNCTION generate_post_slug();
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER IF EXISTS post_slug_generation ON posts;
      DROP FUNCTION IF EXISTS generate_post_slug();
    SQL
  end
end

