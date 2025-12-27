CREATE OR REPLACE FUNCTION validate_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.comment_count <= 0 THEN
          RAISE EXCEPTION 'Invalid count';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

