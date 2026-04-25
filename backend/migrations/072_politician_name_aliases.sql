-- =============================================================================
-- Migration 072: politician_name_aliases
--
-- Stores alternate name forms for politicians so the discovery agent can
-- match names from official ballot sources (which often differ from how
-- a politician is known colloquially) to existing records.
--
-- Example: the LA City Clerk certified list prints "KAREN RUTH BASS" but the
-- politician has been known as "Karen Bass" in prior data ingest. Without an
-- alias, the discovery agent generates a false withdrawal for "Karen Bass" and
-- a false new-candidate row for "Karen Ruth Bass".
--
-- How it's used:
--   discoveryService.ts loads aliases alongside race_candidates and includes
--   them in the fuzzy-match loop. A discovered name that matches any alias at
--   >= NAME_MATCH_THRESHOLD (0.85) scores as 'matched' (or 'official' if the
--   domain is also on the allowlist).
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.politician_name_aliases (
  id             uuid        NOT NULL DEFAULT uuid_generate_v4(),
  politician_id  uuid        NOT NULL
                             REFERENCES essentials.politicians(id) ON DELETE CASCADE,
  alias          text        NOT NULL,
  source         text        NOT NULL DEFAULT 'manual',
  created_at     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT politician_name_aliases_pkey PRIMARY KEY (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS politician_name_aliases_unique
  ON essentials.politician_name_aliases (politician_id, lower(alias));

CREATE INDEX IF NOT EXISTS idx_politician_name_aliases_politician_id
  ON essentials.politician_name_aliases (politician_id);

-- ---------------------------------------------------------------------------
-- Seed: known name mismatches discovered during v2.1 audit (2026-04-25)
-- ---------------------------------------------------------------------------

-- Karen Ruth Bass — official ballot name. Prior ingest used "Karen Bass".
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
VALUES (
  '21c9e711-fb18-4afb-884f-08acd2b598ba',
  'Karen Bass',
  'manual'
) ON CONFLICT DO NOTHING;

-- Katy Young Yaroslavsky — official ballot name is "Katy Yaroslavsky".
-- Prior ingest used full middle name. Alias covers the longer form.
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
VALUES (
  '10678016-146d-4543-941c-00414b4c4ad2',
  'Katy Young Yaroslavsky',
  'manual'
) ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- Fix race_candidates.full_name to match official ballot spelling
-- ---------------------------------------------------------------------------

-- Karen Bass → Karen Ruth Bass (matches politicians.full_name and the PDF)
UPDATE essentials.race_candidates
   SET full_name = 'Karen Ruth Bass',
       updated_at = now()
 WHERE id = 'c13cb353-780a-4cf4-97b5-d0556a09e7cd'
   AND full_name = 'Karen Bass';

-- Katy Young Yaroslavsky → Katy Yaroslavsky (matches PDF)
UPDATE essentials.race_candidates
   SET full_name = 'Katy Yaroslavsky',
       updated_at = now()
 WHERE id = 'ce08fd8b-52a8-41c7-b736-baa9f9518825'
   AND full_name = 'Katy Young Yaroslavsky';

-- Sync politicians.full_name for Katy as well
UPDATE essentials.politicians
   SET full_name = 'Katy Yaroslavsky'
 WHERE id = '10678016-146d-4543-941c-00414b4c4ad2'
   AND full_name = 'Katy Young Yaroslavsky';

COMMIT;
