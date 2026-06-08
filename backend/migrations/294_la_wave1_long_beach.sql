-- Migration 294: Long Beach Wave 1 Gap-Fill
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--   Existing politicians: 9 (Rex Richardson Mayor + 8 council: Allen, Duggan, Kerr,
--   Ricks-Oddie, Saro, Supernaw, Uranga, Zendejas)
--   Gap: NONE — Long Beach is fully populated. All 9 current officeholders are in DB.
--   Note: Councilmember D4 Daryl Supernaw was the remaining question; confirmed present.
--
-- Action: geo_id backfill only. All politician INSERT blocks are idempotent no-ops
-- (ON CONFLICT DO NOTHING on external_ids already claimed by existing incumbents).
-- No new external_ids in the -700050..-700099 range are consumed.
--
-- geo_id backfill: sets geo_id='0643000' on any Long Beach district rows where it is NULL.
-- All Long Beach districts already have geo_id set (confirmed in pre-flight). UPDATE is a no-op.
--
-- CONSTRAINTS (per D-spec):
--   party = NULL (antipartisan design)
--   is_appointed = false (all elected)
--   photo_origin_url: official longbeach.gov pages

BEGIN;

-- Idempotent geo_id backfill for Long Beach districts
UPDATE essentials.districts
SET geo_id = '0643000'
WHERE label LIKE '%Long Beach%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0643000';

-- Long Beach is fully populated. No new politician inserts needed.
-- The following is a documentation comment confirming no inserts were made:
--   Rex Richardson  (Mayor)     — already in DB (positive confirmation 2026-06-08)
--   Mary Zendejas   (D1)        — already in DB
--   Cindy Allen     (D2)        — already in DB
--   Kristina Duggan (D3)        — already in DB
--   Daryl Supernaw  (D4)        — already in DB
--   Megan Kerr      (D5)        — already in DB
--   Suely Saro      (D6)        — already in DB
--   Roberto Uranga  (D7)        — already in DB
--   Joni Ricks-Oddie (D8/D9)   — already in DB
--
-- office_id back-fill for range (no-op since no new politicians inserted)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700099 AND -700050
  AND p.office_id IS NULL;

COMMIT;
