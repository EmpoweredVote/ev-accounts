-- Migration 111: Add alternate_names to politicians
--
-- Civic leaders are often known by shortened, hyphenated, or variant names
-- (e.g. "Katy Young Yaroslavsky" vs "Katy Yaroslavsky"). This column lets the
-- stance research pipeline match agent CSV output to the canonical DB record
-- regardless of which variant the researcher used.
--
-- Usage: stored as a text[] of known alternate full_name values. The Step 4a
-- ID resolution query in the research-stances skill checks this column in
-- addition to full_name.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS, UPDATE is safe to re-run.

BEGIN;

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS alternate_names text[] NOT NULL DEFAULT '{}';

-- Seed known alternate names for current LA politicians
UPDATE essentials.politicians
  SET alternate_names = array_append(alternate_names, 'Katy Young Yaroslavsky')
  WHERE lower(full_name) = 'katy yaroslavsky'
    AND NOT ('Katy Young Yaroslavsky' = ANY(alternate_names));

UPDATE essentials.politicians
  SET alternate_names = array_cat(alternate_names, ARRAY['Curren Price', 'Curren Price Jr.'])
  WHERE lower(full_name) = 'curren d. price jr.'
    AND NOT ('Curren Price' = ANY(alternate_names));

UPDATE essentials.politicians
  SET alternate_names = array_append(alternate_names, 'Ysabel Jurado')
  WHERE lower(full_name) = 'ysabel j. jurado'
    AND NOT ('Ysabel Jurado' = ANY(alternate_names));

UPDATE essentials.politicians
  SET alternate_names = array_append(alternate_names, 'Karen Bass')
  WHERE lower(full_name) = 'karen ruth bass'
    AND NOT ('Karen Bass' = ANY(alternate_names));

-- Verify
SELECT full_name, alternate_names
FROM essentials.politicians
WHERE array_length(alternate_names, 1) > 0
ORDER BY full_name;

COMMIT;
