-- Phase 104: Local Remediation — City Officials
-- Requirements covered: STAX-03, QUAL-01, QUAL-02
-- Source CSVs:
--   backend/data/stance-research/2026-06-07-104-mahmood-abortion.csv      (header-only → DELETE)
--   backend/data/stance-research/2026-06-07-104-moreno-city-sanitation.csv (1 row → UPGRADE to value=2)
-- Source deletion log: .planning/phases/104-local-remediation-city-officials/104-DELETION-LOG.md
--
-- Pre-write cross-check:
--   1 UPSERT + 1 DELETE = 2 = Phase 104 target count (Mahmood + Moreno) ✓
--   Intersection of UPSERT and DELETE (politician_id, topic_id) pairs: empty ✓
--
-- Politicians in scope (UUIDs from 104-CONTEXT.md D-01 triage, verified in pre-flight):
--   Bilal Mahmood    (SF Board of Supervisors, D5)  UUID: d3c5004c-9ca0-444e-96d9-107d4315abcb  → DELETE abortion
--   Vivian Moreno    (San Diego City Council, D8)   UUID: 0b16443e-fec4-4f33-abbc-eb1331e3b42d  → UPGRADE city-sanitation
--
-- Migration number derivation:
--   SELECT MAX(version) FROM supabase_migrations.schema_migrations at pre-flight = 282
--   Next available = 283
--
-- Out-of-scope guard (D-02): this migration does NOT reference Monica Rodriguez, Chris Krupa Downs,
--   Burt Thakur, Ryan Tubbs, Shun Thomas, or external_id 695265.

BEGIN;

-- ============================================================
-- DELETE BLOCK — 1 row (Mahmood / abortion — no evidence found)
-- Order: DELETE context FIRST, then answers (defensive ordering per Phase 103 pattern)
-- ============================================================

-- DELETED: Bilal Mahmood / abortion / former value=2 / reason=no evidence found
-- Research (2026-06-07): Campaign platform page does not mention abortion/reproductive rights.
-- PPNCA endorsement appears as a list entry only — no policy statement. No board resolution,
-- press release, interview, or specific campaign page found. Per D-04: homepage URL
-- https://bilalmahmood.com/ does not satisfy QUAL-01. Single research pass complete.
DELETE FROM inform.politician_context
WHERE politician_id = 'd3c5004c-9ca0-444e-96d9-107d4315abcb'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

DELETE FROM inform.politician_answers
WHERE politician_id = 'd3c5004c-9ca0-444e-96d9-107d4315abcb'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

-- ============================================================
-- UPSERT BLOCK — 1 row (Moreno / city-sanitation / value=2 / ARRAY_CAT)
-- VALUE CHANGED: 3 → 2 (evidence shows expanded services + prioritizing underserved neighborhoods)
-- ============================================================

-- ---- Vivian Moreno / city-sanitation / value=2 / ARRAY_CAT ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0b16443e-fec4-4f33-abbc-eb1331e3b42d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'city-sanitation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0b16443e-fec4-4f33-abbc-eb1331e3b42d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'city-sanitation'),
  'Moreno has organized 65+ dumpster drop-offs removing 230+ tons of debris, providing free community disposal to historically underserved D8 residents and reducing illegal dumping. She pushed to hire two dedicated graffiti abatement officers after D8 had the lowest graffiti removal services in the city, directly expanding sanitation staffing for underserved neighborhoods. Her work prioritizes equitable service distribution in South San Diego County, matching the stance ''Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness citywide.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.vivianmorenosd.com/better'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing ['https://www.vivianmorenosd.com'] (preserves history per D-04)

-- ============================================================
-- POST-STATE RAISE NOTICE (informational — does NOT block commit)
-- STAX-03 target: V1 = 0 (unsourced city stances), V2 = 0 (weak-source city stances)
-- City cohort: external_id BETWEEN -689999 AND -630000 AND (external_id < -669999 OR external_id > -660000)
-- ============================================================

DO $$
DECLARE
  v_city_unsourced integer;
  v_city_weak integer;
BEGIN
  -- V1: v2.5 city-official cohort unsourced stances (STAX-03 target: 0)
  SELECT COUNT(*) INTO v_city_unsourced
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -689999 AND -630000
    AND (p.external_id < -669999 OR p.external_id > -660000)
    AND p.is_active = true
    AND (
      pc.politician_id IS NULL
      OR pc.sources IS NULL
      OR array_length(pc.sources, 1) IS NULL
      OR NOT EXISTS (
        SELECT 1 FROM unnest(pc.sources) AS s(url)
        WHERE url IS NOT NULL AND trim(url) <> ''
      )
    );
  RAISE NOTICE 'POST-MIGRATION v2.5 city-official cohort unsourced stances (V1): %', v_city_unsourced;

  -- V2: v2.5 city-official cohort weak-source stances (STAX-03 target: 0)
  -- A stance is weak if ALL non-blank source URLs match the homepage-only pattern
  SELECT COUNT(*) INTO v_city_weak
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -689999 AND -630000
    AND (p.external_id < -669999 OR p.external_id > -660000)
    AND p.is_active = true
    AND pc.sources IS NOT NULL
    AND array_length(pc.sources, 1) IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM unnest(pc.sources) s(u)
      WHERE u IS NOT NULL AND trim(u) != ''
    )
    AND NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) AS s(url)
      WHERE url IS NOT NULL AND trim(url) <> ''
        AND url !~ '^https?://[^/]+/?$'
    );
  RAISE NOTICE 'POST-MIGRATION v2.5 city-official cohort weak-source stances (V2): %', v_city_weak;
END $$;

-- Track this migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('283', '283_phase104_city_official_remediation')
ON CONFLICT (version) DO NOTHING;

COMMIT;
