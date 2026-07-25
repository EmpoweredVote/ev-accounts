-- =============================================================================
-- Migration 1388: Add missing essentials.offices rows for 3 Collin County, TX
-- councils where the governing body has MORE real seats than modeled office rows
-- (Phase 218 "Missing People" — D-02).
--
-- Idempotent: each INSERT is guarded by WHERE NOT EXISTS on (chamber_id, title).
-- Re-running this migration must insert 0 additional rows.
--
-- All 3 findings were re-confirmed via a live fetch of each city's own current
-- roster page on 2026-07-23 (Phase 218 Plan 01, Task 1):
--
--   Blue Ridge (blueridgecity.com/council): Mayor Rhonda Williams + 5 distinct
--     non-mayor council members with sequential email aliases council1@ through
--     council5@ (Braly/Apple/Sissom/Mattingly/Chitwood) — genuine 5th seat, DB
--     (migration 090) only modeled Place 1-4.
--
--   Lowry Crossing (lowrycrossingtexas.org/operations/city_council.php): Mayor
--     Pat Kelly + 4 wards x 2 members each = 8 real council seats (Ward1:
--     Pitchure+Madrid, Ward2: Hodges+Rios, Ward3: Trujillo+Cash, Ward4:
--     Hijazen+Simpson) — DB (migration 090) only modeled Place 1-4 (one per
--     ward). This migration adds Place 5-8 as a parallel continuation of the
--     existing single-"Place" numbering (LOCKED mapping, Plan 218-01 Task 1):
--     Place 5 = Ward 1 2nd member (Madrid), Place 6 = Ward 2 2nd member (Rios),
--     Place 7 = Ward 3 2nd member (Cash), Place 8 = 2nd Ward 4 winner
--     (Hijazen or Simpson — resolved in Plan 218-02 from the Ward-4 special
--     election notice). People are seated in Plan 218-02; this migration only
--     creates the structural rows.
--
--   Weston (westontexas.com/page/Mayor_Aldermen): Mayor Matthew Marchiori + 5
--     aldermen (Metzger/Harrington/Roach/Hill/Johnston) — Marla Johnston
--     confirmed still the current 6th alderman ~14 months after migration 098's
--     "Weston: DB has 5 offices; city has 6 aldermen. Marla Johnston CANNOT be
--     seeded" comment. DB (migration 090) only modeled Place 1-4.
--
-- Josephine (geo_id 4838068) is explicitly NOT touched here — a read-only DB
-- check (Plan 218-01 Task 1) confirmed its Council Member Place 5 office row
-- ALREADY EXISTS (politician_id IS NULL, awaiting Plan 218-02 seating), added
-- by someone between May and July 2026. Inserting it again would violate the
-- "Josephine Place 5 NOT duplicated" must-have.
--
-- All new rows: nonpartisan (partisan_type = NULL, D-05), politician_id left
-- NULL (people seated in Plan 218-02), district_id NULL (Collin TX has no
-- geofences — matches every existing Collin office row). No governments/
-- chambers rows are touched (brownfield — they already exist).
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Blue Ridge (geo_id 4808872) — add Council Member Place 5
-- ---------------------------------------------------------------------------
INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
SELECT ch.id, 'Council Member Place 5', 'Blue Ridge', 'TX', 'Council Member', 1, NULL, false
FROM essentials.chambers ch
JOIN essentials.governments g ON g.id = ch.government_id
WHERE g.geo_id = '4808872'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = ch.id AND o.title = 'Council Member Place 5'
  );

-- ---------------------------------------------------------------------------
-- Lowry Crossing (geo_id 4844308) — add Council Member Place 5, 6, 7, 8
-- ---------------------------------------------------------------------------
INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
SELECT ch.id, t.title, 'Lowry Crossing', 'TX', 'Council Member', 1, NULL, false
FROM essentials.chambers ch
JOIN essentials.governments g ON g.id = ch.government_id
CROSS JOIN (
  VALUES
    ('Council Member Place 5'),
    ('Council Member Place 6'),
    ('Council Member Place 7'),
    ('Council Member Place 8')
) AS t(title)
WHERE g.geo_id = '4844308'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = ch.id AND o.title = t.title
  );

-- ---------------------------------------------------------------------------
-- Weston (geo_id 4877740) — add Council Member Place 5
-- ---------------------------------------------------------------------------
INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
SELECT ch.id, 'Council Member Place 5', 'Weston', 'TX', 'Council Member', 1, NULL, false
FROM essentials.chambers ch
JOIN essentials.governments g ON g.id = ch.government_id
WHERE g.geo_id = '4877740'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = ch.id AND o.title = 'Council Member Place 5'
  );

COMMIT;
