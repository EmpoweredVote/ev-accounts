-- 1529_resource_garcia_school_vouchers.sql
--
-- Re-point ONE row, Mónica García / School Vouchers, from a dead Ballotpedia URL to the live one.
--   Review: data/stance-retirement/2026-08-02-held-rows-resolution.md
--
-- 🔴 WHY THIS ROW WAS INVISIBLE, AND WHY THAT MATTERS MORE THAN THE ROW.
-- Its sources array holds ONE well-formed URL and no prose, so it was never in the 279 rows the
-- NON_URL_SOURCE work found. It is not malformed. It simply 404s:
--   https://ballotpedia.org/Monica_Garcia_(Los_Angeles_Unified_School_District_Board_of_Education,_District_2)
-- Ballotpedia renamed the page. Her other two rows reached the same dead target by a different route
-- (their copy of the URL had been split on its comma), which is the only reason it was noticed at all.
--
-- ⚠ THIS IS A CLASS, NOT A ROW: a citation that parses as a valid URL but does not resolve. No gate
-- check sees it -- every branch classifies by the SHAPE of the URL -- and the 2026-08-01 reachability
-- sweep did not either, because it probed only the bare HOSTS of the PRIMARY_SITE_NO_PATH bucket, not
-- deep paths. Sizing and sweeping that class is recorded as the next action.
--
-- The replacement was verified live and BY IDENTITY, not by status code: ballotpedia.org/Monica_Garcia
-- returns 200 and the page identifies itself as "Mónica García (Los Angeles Unified School District,
-- California)". A 200 alone would not be enough -- a Ballotpedia page matching a name has already
-- turned out to be a different person once on this workstream (neighbors4faye, 1519).

BEGIN;

UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Monica_Garcia']::text[]
 WHERE politician_id = 'a123c59e-694b-43cc-af03-6610b645e6d2'
   AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

DO $$
DECLARE v_n int;
BEGIN
  -- All three of her rows must now cite the live page, and none the dead one.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = 'a123c59e-694b-43cc-af03-6610b645e6d2'
     AND 'https://ballotpedia.org/Monica_Garcia' = ANY(sources);
  IF v_n <> 3 THEN RAISE EXCEPTION 'expected 3 García rows citing the live page, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%Board_of_Education,_District_2%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still cite the dead Ballotpedia URL', v_n; END IF;
END $$;

COMMIT;
