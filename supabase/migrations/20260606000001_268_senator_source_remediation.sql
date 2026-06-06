-- Phase 101: Federal Senate Remediation
-- Requirements covered: FEDX-01, QUAL-01, QUAL-02
-- Source CSV: backend/data/stance-research/2026-06-06-senator-remediation.csv
-- Source deletion log: .planning/phases/101-candidate-profiles/101-DELETION-LOG.md
--
-- Pre-write cross-check assertion (recorded here per Task 3 spec):
--   - UPSERT row count: 0  (CSV has header only — no data rows)
--   - DELETE pair count: 1  (Deb Fischer / ai-regulation)
--   - Union of UPSERT + DELETE pairs == all flagged stances from Plan 01 (101-SENATOR-TARGETS.csv): 1 stance flagged, 0 upserted, 1 deleted ✓
--   - Intersection of UPSERT and DELETE pairs: empty ✓
--
-- Migration number: 268 (verified via SELECT MAX(version) FROM supabase_migrations.schema_migrations → 267; next = 268)
-- Applied: 2026-06-06 via psql session pooler

BEGIN;

-- ============================================================
-- UPSERT BLOCK
-- No upsert rows — research-stances found no verifiable sources
-- for any flagged senator stance. The CSV has header only.
-- All flagged stances flow to the DELETE block below.
-- ============================================================

-- (no INSERT INTO inform.politician_answers statements)
-- (no INSERT INTO inform.politician_context statements)

-- ============================================================
-- DELETE BLOCK
-- 1 deletion: Deb Fischer / ai-regulation
-- ============================================================

-- DELETED: Deb Fischer / ai-regulation / former value=3 / reason=no evidence found
-- Research: Exhaustive search (212+ press release pages, Senate Commerce Committee AI pages,
-- Senate Armed Services pages, Wikipedia, Ballotpedia, multiple news outlets) found no direct
-- statement, vote, or bill sponsorship where Fischer expressed a position on AI regulatory
-- oversight. One AI-adjacent Fox News/Cavuto appearance (July 2023) discussed AI through a
-- national security lens only — insufficient to match any of the five Chair texts.
-- Per D-04: delete if no real URL found, regardless of value. No "directional keep."

DELETE FROM inform.politician_context
WHERE politician_id = '3149d855-8d85-4080-b0d6-fb83be500533'
  AND topic_id = (
    SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'
  );

DELETE FROM inform.politician_answers
WHERE politician_id = '3149d855-8d85-4080-b0d6-fb83be500533'
  AND topic_id = (
    SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'
  );

-- ============================================================
-- POST-STATE RAISE NOTICE
-- Informational only — does NOT block commit.
-- Task 4 is responsible for formal FEDX-01 verification.
-- ============================================================

DO $$
DECLARE
  v_unsourced_count integer;
  v_homepage_only_count integer;
BEGIN
  -- V1: Unsourced senator stances (target: 0)
  SELECT COUNT(*) INTO v_unsourced_count
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE pa.politician_id IN (
    SELECT DISTINCT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
  )
  AND (
    pc.politician_id IS NULL
    OR pc.sources IS NULL
    OR array_length(pc.sources, 1) IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s(u)
      WHERE u IS NOT NULL AND trim(u) != ''
    )
  );

  RAISE NOTICE 'POST-MIGRATION unsourced senator stances: %', v_unsourced_count;

  -- V2: Senator stances with only homepage-only sources (target: 0)
  SELECT COUNT(*) INTO v_homepage_only_count
  FROM inform.politician_context pc
  WHERE pc.politician_id IN (
    SELECT DISTINCT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
  )
  AND pc.sources IS NOT NULL
  AND array_length(pc.sources, 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
      AND trim(u) !~ '^https?://[^/]+/?$'
  )
  AND EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
  );

  RAISE NOTICE 'POST-MIGRATION homepage-only senator stances: %', v_homepage_only_count;
END $$;

-- Track this migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('268', '268_senator_source_remediation')
ON CONFLICT (version) DO NOTHING;

COMMIT;
