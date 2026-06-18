-- Migration 774: fix Travis Hoban link (UT 2026 Primary)
--
-- Travis Hoban is a sitting Provo City Council member running for Utah County Auditor.
-- Migration 772 linked his candidate row to his Provo council record 36fa56a1 (ut-city-provo,
-- 'Council Ward 4') — but that record is is_active=false (a stale pre-redistricting ward seat),
-- so the profile may not render. Re-point to his ACTIVE record b0626ad5 ('Council District 4').
--
-- Idempotent: only updates if currently pointing at the inactive record.
-- NOTE: already applied to production 2026-06-18 (recorded here for history).

BEGIN;

WITH e AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Utah Primary' AND election_date = '2026-06-23' AND state = 'UT'
)
UPDATE essentials.race_candidates rc
SET politician_id = 'b0626ad5-3d9d-4136-bad3-5be899ed0329', updated_at = now()
FROM essentials.races r, e
WHERE r.election_id = e.id
  AND rc.race_id = r.id
  AND lower(rc.full_name) = 'travis hoban'
  AND rc.politician_id = '36fa56a1-fe67-440a-a8fd-dccb34845e2a';

COMMIT;
