-- Migration 298: Wave 1 Gap-Fill — Lancaster, Norwalk, Palmdale, Pomona
-- Applied: 2026-06-08
--
-- Pre-flight confirmed 2026-06-08 (migration 293):
--
--   Lancaster (geo_id=0640130): 4 council + Mayor = 5. FULLY POPULATED.
--     Roster: R. Rex Parris (Mayor), Marvin Crist, Lauren Hughes-Leslie, Raj Malhi, Ken Mann
--     Lancaster has 4 at-large council seats + separately elected Mayor = 5 total.
--
--   Norwalk (geo_id=0652526): 4 council + Mayor = 5. FULLY POPULATED.
--     Roster: Tony Ayala (Mayor), Jennifer Perez, Rick Ramirez, Margarita L. Rios, Ana Valencia
--     Norwalk has 4 at-large council seats + separately elected Mayor = 5 total.
--
--   Palmdale (geo_id=0655156): 4 council members. Mayor district exists but no politician.
--     Roster in DB: Austin Bishop, Andrea Alarcón, Richard J. Loa, Eric Ohlsen
--     Gap: Palmdale Mayor
--     VERIFICATION-PENDING: The current Palmdale Mayor is uncertain. Austin Bishop appears
--     as "Council Member" in the DB but may have won the Mayor race. The Palmdale Mayor
--     LOCAL_EXEC district (id: a2732964-32e5-4419-96a0-5ddc56ad45c3) is empty.
--     Per D-03 conservative default: NOT inserting a Mayor record without name verification.
--     A future migration should add the Palmdale Mayor after confirming the current occupant
--     via cityofpalmdale.org/City-Council.
--
--   Pomona (geo_id=0658072): 5 council + Mayor = 6. FULLY POPULATED.
--     Roster: Tim Sandoval (Mayor), Lorraine Canales, Nora Garcia, Steve Lustro,
--             Debra Martin, Victor Preciado
--
-- External_ids used: NONE (all cities in this migration are fully populated or
--   have VERIFICATION-PENDING gaps that are deferred)
--
-- All actions: geo_id backfill only (idempotent no-ops for politicians)

BEGIN;

-- ============= Lancaster (geo_id=0640130) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0640130'
WHERE label LIKE '%Lancaster%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0640130';
-- No new politician inserts needed — Lancaster is fully populated.

-- ============= Norwalk (geo_id=0652526) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0652526'
WHERE label LIKE '%Norwalk%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0652526';
-- No new politician inserts needed — Norwalk is fully populated.

-- ============= Palmdale (geo_id=0655156) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0655156'
WHERE label LIKE '%Palmdale%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0655156';
-- VERIFICATION-PENDING: Palmdale Mayor — 1 additional seat remains unverified.
-- The Palmdale Mayor LOCAL_EXEC district (a2732964-32e5-4419-96a0-5ddc56ad45c3) is empty.
-- Current Mayor identity is uncertain; deferred per D-03 conservative default.
-- Next step: verify at cityofpalmdale.org/City-Council and add in a follow-up migration.

-- ============= Pomona (geo_id=0658072) =============
-- Idempotent geo_id backfill
UPDATE essentials.districts
SET geo_id = '0658072'
WHERE label LIKE '%Pomona%'
  AND state = 'CA'
  AND district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND geo_id IS DISTINCT FROM '0658072';
-- No new politician inserts needed — Pomona is fully populated.

-- office_id back-fill for range (no-op since no new politicians inserted)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -700179 AND -700170
  AND p.office_id IS NULL;

COMMIT;
