-- Add topic_key column to compass_topics for reliable joins with essentials.quotes.
-- Previously the /api/essentials/quotes endpoint joined via string-mangling short_title,
-- which silently dropped quotes when topic_key didn't match the slugified short_title.

ALTER TABLE inform.compass_topics
  ADD COLUMN IF NOT EXISTS topic_key TEXT;

-- Backfill from short_title: lowercase, spaces→hyphens, slash preserved
UPDATE inform.compass_topics
SET topic_key = lower(replace(short_title, ' ', '-'))
WHERE topic_key IS NULL;

-- Make it required and unique going forward
ALTER TABLE inform.compass_topics
  ALTER COLUMN topic_key SET NOT NULL;

-- Default derives topic_key from short_title so the existing
-- admin_create_topic_with_stances RPC works without modification
ALTER TABLE inform.compass_topics
  ALTER COLUMN topic_key SET DEFAULT '';

CREATE UNIQUE INDEX IF NOT EXISTS idx_compass_topics_topic_key
  ON inform.compass_topics (topic_key);

-- Trigger to auto-derive topic_key from short_title when not explicitly set
CREATE OR REPLACE FUNCTION inform.derive_topic_key()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.topic_key IS NULL OR NEW.topic_key = '' THEN
    NEW.topic_key := lower(replace(NEW.short_title, ' ', '-'));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_derive_topic_key
  BEFORE INSERT OR UPDATE ON inform.compass_topics
  FOR EACH ROW
  EXECUTE FUNCTION inform.derive_topic_key();

-- Fix mismatched topic_keys in essentials.quotes
UPDATE essentials.quotes SET topic_key = 'data-centers' WHERE topic_key = 'data-center-energy';
UPDATE essentials.quotes SET topic_key = 'homelessness' WHERE topic_key = 'homelessness-policy';
