-- =====================================================================================
-- Data fix: clear the stray representing_city on Alex Padilla's U.S. Senate office.
--
-- BUG: politician -6000201 (Alex Padilla) had representing_city='Inglewood' on his
--   U.S. Senate - California office (district geo_id='06', NATIONAL_UPPER). This almost
--   certainly bled over from his early-career Inglewood City Council record
--   (politician -701002, City of Inglewood). A U.S. Senator represents the whole state,
--   not a city, so representing_city must be NULL.
--
-- IMPACT: because the Senate office sits on the statewide '06' geofence, it is returned
--   for EVERY California address. The results page derives the local city banner from the
--   first official in the list carrying a representing_city; where the actual local
--   officials have none (e.g. Riverside County supervisors, representing_city NULL), this
--   stray value hijacked the banner — a Corona (Riverside County) address rendered under
--   an "Inglewood, CA" banner. Nulling it restores correct city-banner resolution for all
--   CA addresses. Surfaced during Phase 201 (Riverside County) live UAT.
--
-- AUDIT-ONLY / unregistered (no schema_migrations ledger entry). Idempotent.
-- =====================================================================================

BEGIN;

UPDATE essentials.offices o
SET representing_city = NULL
FROM essentials.politicians p, essentials.districts d
WHERE o.politician_id = p.id
  AND o.district_id  = d.id
  AND p.external_id  = -6000201
  AND d.district_type = 'NATIONAL_UPPER'
  AND o.representing_city = 'Inglewood';

COMMIT;
