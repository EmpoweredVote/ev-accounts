-- CC_0342 — correct the 9 politicians.is_incumbent flags that genuinely disagree with
--            office_terms. NOT the 429 a first measurement reported.
--
-- 🔴🔴 THE 429 WAS A BAD MEASUREMENT, AND 420 OF THOSE ROWS ARE CORRECT AS THEY STAND.
-- `scripts/reconcile-incumbency.mjs` first reported 429 drift rows across three columns. Reading
-- actual rows in each class — rather than trusting the predicate that caught them — found that
-- only 9 are drift. The other three classes are the script's rules being wrong:
--
--   politicians.is_incumbent      31 reported → 9 real. 22 of the 25 "missing incumbents" hold a
--                                 'Candidate for U.S. Senate — X' PLACEHOLDER office (migration
--                                 196). They are candidates, so false is CORRECT. The truth
--                                 predicate has to exclude those offices, exactly as
--                                 essentialsService.ts:360 already does
--                                 (`COALESCE(o.title,'') NOT ILIKE 'Candidate for%'`); the
--                                 reconciler did not. Setting those 22 to true would have
--                                 published Roy Cooper, Sherrod Brown, Mary Peltola and 19 other
--                                 CANDIDATES as sitting incumbents.
--
--   politicians.office_id         101 reported → 0 real. It is a DEPRECATED POINT-IN-TIME
--                                 SNAPSHOT (ADR 0002); it was never supposed to equal the current
--                                 holder, which is the whole reason the view replaced it. All 101
--                                 point at real offices, none dangling. Nulling them would
--                                 destroy a historical value that exists nowhere else — there is
--                                 no history table — to satisfy a rule nobody agreed.
--
--   race_candidates.is_incumbent  297 reported → 0 applied. This column is SEAT-SCOPED: it means
--                                 "is this candidate the incumbent OF THE SEAT BEING CONTESTED",
--                                 not "does this person hold office somewhere". Brent Taylor
--                                 holds a state Senate seat and runs for U.S. House; Eleni
--                                 Kounalakis is Lt. Governor running for Treasurer. false is
--                                 CORRECT for both. ⚠ AND THE DATA CARRIES BOTH CONVENTIONS:
--                                 234 cross-office candidates are stored true while others like
--                                 those are stored false. Nobody can say which is intended, so
--                                 this migration writes NONE of them. Deciding that is a separate
--                                 ruling, and `compassService.ts:629` reads the column
--                                 ('challengers only'), so a wrong guess is voter-facing.
--
-- ▶ WHAT THIS FILE DOES: 9 rows, all `politicians.is_incumbent`, all verified one at a time.
--
-- 🔴 THE OVERWRITE RECORD (there is no history table; these values exist nowhere else once this
-- commits):
--
--   false → true   (they hold a REAL office and were HIDDEN FROM ADDRESS SEARCH by the flag)
--     5bcf2a31-2fb6-43e5-88d7-ca9c25d5fb6f  Chad Bianco          Sheriff-Coroner, CA county, term from 2019-01-01, open
--     5d8acfc7-5643-418b-a474-3d87898f4e17  Jared Elad           Council Member Place 4, TX
--     237ac7cd-7835-4fb4-a69a-cd6524e40fdc  Keith E. Sonderling  Secretary of Labor, NATIONAL_EXEC
--
--   true → false   (departed officeholders: each HAS a term row, and it has ENDED. This is the
--                   CA_0188 shape — an active "incumbent" holding no seat — which that pass
--                   cleared 1,817 times.)
--     7de0d70b-81ba-484c-aa82-43dfb4dadd0a  Brian Birdwell       snapshot → Senator (seat now flagged vacant)
--     b67611e0-a274-4db6-80ae-281563f36a13  Jeffrey Lytton       snapshot → Council - District 4
--     d415038d-19b9-46c8-a0ee-67fd8bbd0c5c  John Gese            snapshot → (none)
--     339d118e-2de4-4d44-a489-fe3ff6cf5e3e  John Gonzalez        snapshot → (none)
--     c7670a65-abc2-43af-8375-eeb212a25e71  Margret G Robb       snapshot → Indiana Appeals Court Judge - District 5
--     2a054186-d76d-4e50-81f8-2f4e9dd9e871  Terry Crone          snapshot → Indiana Appeals Court Judge - District 3
--
-- ⚠ `office_id` IS DELIBERATELY LEFT ALONE on all nine, including the six whose snapshot now
-- disagrees with the flag. It is deprecated and historical; see above.
--
-- IDEMPOTENT: every UPDATE is guarded on the value it changes, so a re-run writes nothing.

BEGIN;

UPDATE essentials.politicians SET is_incumbent = true
 WHERE id IN (
   '5bcf2a31-2fb6-43e5-88d7-ca9c25d5fb6f',
   '5d8acfc7-5643-418b-a474-3d87898f4e17',
   '237ac7cd-7835-4fb4-a69a-cd6524e40fdc'
 ) AND is_incumbent IS DISTINCT FROM true;

UPDATE essentials.politicians SET is_incumbent = false
 WHERE id IN (
   '7de0d70b-81ba-484c-aa82-43dfb4dadd0a',
   'b67611e0-a274-4db6-80ae-281563f36a13',
   'd415038d-19b9-46c8-a0ee-67fd8bbd0c5c',
   '339d118e-2de4-4d44-a489-fe3ff6cf5e3e',
   'c7670a65-abc2-43af-8375-eeb212a25e71',
   '2a054186-d76d-4e50-81f8-2f4e9dd9e871'
 ) AND is_incumbent IS DISTINCT FROM false;

-- Post-verify gate. Asserts the END STATE of these nine rows and, separately, that the
-- repo-wide drift under the CORRECTED predicate is now zero. It deliberately does NOT assert a
-- total anyone else can move while this file is being written.
DO $$
DECLARE
  v_wrong_nine int;
  v_drift_all  int;
  v_candidates_flipped int;
BEGIN
  SELECT count(*) INTO v_wrong_nine FROM essentials.politicians
   WHERE (id IN ('5bcf2a31-2fb6-43e5-88d7-ca9c25d5fb6f','5d8acfc7-5643-418b-a474-3d87898f4e17',
                 '237ac7cd-7835-4fb4-a69a-cd6524e40fdc') AND is_incumbent IS DISTINCT FROM true)
      OR (id IN ('7de0d70b-81ba-484c-aa82-43dfb4dadd0a','b67611e0-a274-4db6-80ae-281563f36a13',
                 'd415038d-19b9-46c8-a0ee-67fd8bbd0c5c','339d118e-2de4-4d44-a489-fe3ff6cf5e3e',
                 'c7670a65-abc2-43af-8375-eeb212a25e71','2a054186-d76d-4e50-81f8-2f4e9dd9e871')
          AND is_incumbent IS DISTINCT FROM false);

  SELECT count(*) INTO v_drift_all
    FROM essentials.politicians p
    LEFT JOIN LATERAL (
      SELECT 1 AS held FROM essentials.office_current_holder och
       JOIN essentials.offices o ON o.id = och.office_id
      WHERE och.politician_id = p.id AND o.title NOT ILIKE 'Candidate for%' LIMIT 1
    ) h ON true
   WHERE p.is_active = true
     AND p.is_incumbent IS DISTINCT FROM (h.held IS NOT NULL);

  -- 🔴 The guard that would have caught the bad version of this migration: no candidate holding
  -- only a placeholder office may come out of this flagged as an incumbent.
  SELECT count(*) INTO v_candidates_flipped
    FROM essentials.politicians p
   WHERE p.is_active = true AND p.is_incumbent = true
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   JOIN essentials.offices o ON o.id = och.office_id
                  WHERE och.politician_id = p.id AND o.title ILIKE 'Candidate for%')
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                       JOIN essentials.offices o ON o.id = och.office_id
                      WHERE och.politician_id = p.id AND o.title NOT ILIKE 'Candidate for%');

  IF v_wrong_nine <> 0 THEN
    RAISE EXCEPTION 'CC_0342: % of the 9 targeted rows do not hold their intended value', v_wrong_nine;
  END IF;

  IF v_drift_all <> 0 THEN
    RAISE EXCEPTION 'CC_0342: % active politician(s) still disagree with office_terms under the corrected predicate', v_drift_all;
  END IF;

  IF v_candidates_flipped <> 0 THEN
    RAISE EXCEPTION 'CC_0342: % candidate(s) holding only a placeholder office are flagged incumbent', v_candidates_flipped;
  END IF;

  RAISE NOTICE 'CC_0342 OK: 9 rows correct, 0 drift repo-wide, 0 placeholder-only candidates flagged incumbent';
END $$;

COMMIT;
