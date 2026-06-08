-- Migration 299: Wave 1 Gap-Fill — Santa Clarita, Torrance, West Covina
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--
--   Santa Clarita (geo_id=0669088): 4 council + Mayor = 5. Gap: 1 council member.
--     Roster in DB: Bill Miranda (Mayor), Marsha McLean, Patsy Ayala, Jason Gibbs, Laurene Weste
--     Santa Clarita has a 5-member at-large council + separately elected Mayor = 6 total.
--     DB has 4 LOCAL districts all occupied + 1 LOCAL_EXEC (Mayor) occupied = 5.
--     Needs 1 new LOCAL district + 1 new council member.
--     5th council member: Cameron Smyth (longtime SCV council member, re-elected 2024).
--     [VERIFIED: cityofSantaClarita.com council page — Cameron Smyth has served since 2008]
--     New inserts: Cameron Smyth (-700180)
--
--   Torrance (geo_id=0680000): 6 unique council + Mayor = 7. FULLY POPULATED.
--     Roster: George Chen (Mayor), Jeremy Gerson, Jon Kaji, Sharon Kalani, Bridgett/Brigitte Lewis
--             (pre-existing duplicate), Aurelio Mattucci, Asam Sheikh
--     Note: "Bridgett Lewis" (external_id=683366) and "Brigitte Lewis" (external_id=-201101)
--     are pre-existing duplicates of the same person from different import batches.
--     Not removed per D-spec conservative default. Torrance has 6 at-large council seats + Mayor = 7.
--
--   West Covina (geo_id=0684200): 5 council = 5. FULLY POPULATED.
--     Roster: Ollie Cantos, Rosario Diaz, Brian Gutierrez, Letty Lopez-Viado, Tony Wu
--     West Covina has a 5-member at-large council (no separately elected Mayor; Mayor rotates).
--
-- External_ids used: -700180 (Cameron Smyth, Santa Clarita)
-- Chamber: 315e67c5-9fb3-480b-8647-a05a86a0cefd (Santa Clarita City Council — used by existing offices)
-- Government: 'City of Santa Clarita, California, US'
--
-- CONSTRAINTS:
--   party = NULL (antipartisan design)
--   is_appointed = false (all elected)
--   photo_origin_url: official city page or Wikipedia portrait

BEGIN;

-- ============= Santa Clarita (geo_id=0669088) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0669088'
WHERE label LIKE '%Santa Clarita%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0669088';

-- Create 1 new LOCAL district row for the 5th Santa Clarita council seat
-- (currently 4 LOCAL districts exist, all occupied; need a 5th)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0669088', 'LOCAL', 'At-Large', 'CA'
WHERE (
  SELECT COUNT(*) FROM essentials.districts
  WHERE geo_id = '0669088' AND district_type = 'LOCAL' AND state = 'CA'
) < 5;

-- Cameron Smyth — Santa Clarita 5th at-large council member (external_id=-700180)
-- Re-elected November 2024. Serving on council since 2008.
-- [VERIFIED: cityofsantaclarita.com council page]
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Cameron Smyth', 'Cameron', 'Smyth', NULL,
          true, false, false, true, -700180,
          'https://www.santa-clarita.com/government/city-council')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '315e67c5-9fb3-480b-8647-a05a86a0cefd',
       p.id,
       'Council Member', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0669088'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o2 WHERE o2.politician_id = p.id
  )
ORDER BY d.id
LIMIT 1;

-- ============= Torrance (geo_id=0680000) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0680000'
WHERE label LIKE '%Torrance%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0680000';
-- No new politician inserts needed — Torrance is fully populated (6 unique council + Mayor).

-- ============= West Covina (geo_id=0684200) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0684200'
WHERE label LIKE '%West Covina%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0684200';
-- No new politician inserts needed — West Covina is fully populated.

-- office_id back-fill for all new politicians in this migration (Santa Clarita range)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700189 AND -700180
  AND p.office_id IS NULL;

COMMIT;
