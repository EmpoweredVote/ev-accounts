-- Phase 112-01: VA House Delegate Stances — Wave 1 (HD-43 through HD-52, Southwest VA)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave1.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  0
--   INSERT INTO inform.politician_answers count: 0
--   INSERT INTO inform.politician_context count: 0
--   All 10 Wave 1 delegates are honest-skips (Southwest VA rural delegates — thin web presence)
--   max_migration at authoring: 325 (psql-applied waves 326–330 not tracked in schema_migrations)
--
-- Honest skips (all 10 Wave 1 delegates — no documentable evidence found):
--   James W. Morefield   (HD-43): thin Southwest VA web presence — no documentable policy positions found
--   Israel D. O'Quinn    (HD-44): thin Southwest VA web presence — no documentable policy positions found
--   Terry G. Kilgore     (HD-45): thin Southwest VA web presence — no documentable policy positions found
--   Mitchell Cornett     (HD-46): thin Southwest VA web presence — no documentable policy positions found
--   Wren M. Williams     (HD-47): thin Southwest VA web presence — no documentable policy positions found
--   Eric J. Phillips     (HD-48): thin Southwest VA web presence — no documentable policy positions found
--   Madison Whittle      (HD-49): thin Southwest VA web presence — no documentable policy positions found
--   Thomas C. Wright, Jr.(HD-50): thin Southwest VA web presence — no documentable policy positions found
--   Eric Zehr            (HD-51): thin Southwest VA web presence — no documentable policy positions found
--   Wendell S. Walker    (HD-52): thin Southwest VA web presence — no documentable policy positions found
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave1-preflight.json):
--   James W. Morefield   (HD-43, ext_id -5120043) -> df51bc00-8a69-4bd0-9418-e61a3cfe248b
--   Israel D. O'Quinn    (HD-44, ext_id -5120044) -> 36673ec0-1045-4a98-8074-12d6deed5cc8
--   Terry G. Kilgore     (HD-45, ext_id -5120045) -> 84257075-047c-46d3-ab7b-ed0e0ae0dd56
--   Mitchell Cornett     (HD-46, ext_id -5120046) -> 3b10a611-77d2-48e2-bf45-40b7bdacdd51
--   Wren M. Williams     (HD-47, ext_id -5120047) -> 38cb6796-1539-48ac-92e6-00068aa5e339
--   Eric J. Phillips     (HD-48, ext_id -5120048) -> 7da511ee-1e98-4620-8852-a0f32dd45078
--   Madison Whittle      (HD-49, ext_id -5120049) -> 4b4e3a27-dbf6-4984-a8a8-eeda9f972612
--   Thomas C. Wright, Jr.(HD-50, ext_id -5120050) -> ff50eaf3-0f12-455e-85b2-bc37f1e542db
--   Eric Zehr            (HD-51, ext_id -5120051) -> e5da439f-17bd-4337-ade5-eb7e5c9d48d4
--   Wendell S. Walker    (HD-52, ext_id -5120052) -> f830ca33-179a-4981-8b89-0b02155e374b
--
-- Migration number: 331
-- Timestamp: 20260610000001
-- Applied: 2026-06-10

BEGIN;

-- Wave 1 is a full honest-skip wave: all 10 Southwest VA delegates (HD-43 through HD-52)
-- had no documentable policy positions found via WebFetch across Ballotpedia, LIS floor votes,
-- house.virginia.gov, vpap.org, Wikipedia, and regional press (Southwest Times, Bristol Herald
-- Courier, Roanoke Times). Zero INSERT rows is the correct and expected outcome per D-07 and D-10.
-- The DO $$ verification block below confirms delegate_count=0 and unsourced_count=0, both valid.

-- Verification block scoped to Wave 1 (external_id BETWEEN -5120052 AND -5120043)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043;
  RAISE NOTICE 'VA delegates with stances (Wave 1): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 1): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
