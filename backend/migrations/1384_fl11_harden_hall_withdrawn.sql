-- 1384: FL-11 Barbie Harden Hall — mark not running (campaign suspended)
--
-- WHY: Barbie Harden Hall (D), added to the FL-11 2026 field in Phase 164.2-04
--   (external_id -1211111), SUSPENDED her congressional campaign citing recurring
--   illness ahead of the 2026-08-18 FL primary. Confirmed via Florida Politics
--   ("...suspends campaign in CD 11", floridapolitics.com, June 2026), surfaced during
--   the 164.2 stance-research wave (2026-07-22). She should no longer show as an active
--   candidate on /elections.
--
-- EFFECT: two-path retire (same convention as the Daniel Webster untangle, mig 1381) —
--   race_candidates.candidate_status='withdrawn' for her FL-11 (geo_id 1211) 2026 row
--   AND politicians.is_active=false. NEVER hard-DELETE (record preserved). No stances were
--   pushed for her, so nothing to unwind there.
--
-- Idempotent: guarded on the pre-change values; re-run touches 0 rows.

BEGIN;

UPDATE essentials.race_candidates rc
SET candidate_status = 'withdrawn', updated_at = now()
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices   o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE rc.race_id = r.id
  AND rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -1211111)
  AND d.geo_id = '1211' AND d.district_type = 'NATIONAL_LOWER'
  AND e.name = 'FL 2026 Statewide General'
  AND rc.candidate_status = 'active';

UPDATE essentials.politicians
SET is_active = false
WHERE external_id = -1211111 AND is_active = true;

COMMIT;
