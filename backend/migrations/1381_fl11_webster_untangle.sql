-- 1381: FL-11 Webster untangle (Phase 164.2-04 Task 2)
--
-- WHY: politician external_id=-12011 is the real Daniel Webster (long-serving FL-11
--   incumbent; carries his 15 federal-24 stances) but his denormalized
--   race_candidates.full_name copy was mislabeled 'Royal Webster'. Daniel Webster is
--   retiring (not on the 2026 ballot); Royal Webster (D) is a real, separate challenger.
--
-- EFFECT:
--   (1) fix the mislabeled rc.full_name copy back to 'Daniel Webster';
--   (2) retire Daniel Webster via BOTH paths (rc.candidate_status='withdrawn' +
--       politicians.is_active=false) -- NEVER hard-DELETE (stances preserved on his UUID);
--   (3) add a distinct 'Royal Webster' (party Democratic, external_id -1211109, next free
--       FL-11 seq) with an active FL-11 race_candidates row (NON-NULL politician_id).
--   Party recorded on politicians.party only; never on the candidate card.
--
-- Idempotent: guarded on pre-change values / NOT EXISTS; re-run touches 0 rows.

BEGIN;

-- 1) Fix the mislabeled rc.full_name copy on Daniel Webster's row (guard on the wrong value).
UPDATE essentials.race_candidates rc
SET full_name = 'Daniel Webster', first_name = 'Daniel', last_name = 'Webster', updated_at = now()
WHERE rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -12011)
  AND rc.full_name = 'Royal Webster';

-- (defensive) ensure the politician record itself reads 'Daniel Webster' (no-op if already correct).
UPDATE essentials.politicians
SET full_name = 'Daniel Webster', first_name = 'Daniel', last_name = 'Webster'
WHERE external_id = -12011 AND full_name = 'Royal Webster';

-- 2) Retire Daniel Webster (both paths), never delete.
UPDATE essentials.race_candidates rc
SET candidate_status = 'withdrawn', updated_at = now()
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices   o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE rc.race_id = r.id
  AND rc.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -12011)
  AND d.geo_id = '1211' AND d.district_type = 'NATIONAL_LOWER'
  AND e.name = 'FL 2026 Statewide General'
  AND rc.candidate_status = 'active';

UPDATE essentials.politicians
SET is_active = false
WHERE external_id = -12011 AND is_active = true;

-- 3) Add Royal Webster (D) as a distinct challenger + active FL-11 rc row.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, is_incumbent, is_active, source)
SELECT -1211109, 'Royal Webster', 'Royal', 'Webster', 'Democratic', false, true,
       'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_11'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -1211109);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source, external_id)
SELECT r.id, p.id, 'Royal Webster', 'Royal', 'Webster', false, 'active',
       'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_11',
       '-1211109'
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices   o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.external_id = -1211109
WHERE d.geo_id = '1211' AND d.district_type = 'NATIONAL_LOWER'
  AND e.name = 'FL 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc2
    WHERE rc2.race_id = r.id AND rc2.politician_id = p.id);

COMMIT;
