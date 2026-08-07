-- 1597_la_assessor_missing_candidates_and_prang_status.sql
--
-- Complete the LA County Assessor field (3 missing candidates) and fix the winner's contradictory
-- candidate_status. 3 politicians + 3 candidate rows added, 1 row repaired.
--
--   Rollback:
--     UPDATE essentials.race_candidates SET candidate_status='withdrawn'
--      WHERE id='909eb944-c7fe-4371-900a-796a0e31b14f';
--     DELETE FROM essentials.race_candidates WHERE politician_id IN
--       ('0e25f0d0-f176-43fb-af83-f1e76585b5a2','a06b3720-c24d-40d1-9993-b149b6e790ac',
--        '4290adb1-187e-4f88-bc51-567fb4a72a6b');
--     DELETE FROM essentials.politicians WHERE id IN (the same three);
--
-- ⚠ Applied as `postgres` over the supabase MCP (RLS — see migrations 1593 and 1595).
--
-- Source: LA County Registrar-Recorder certified results for June 2 2026,
-- results.lavote.gov/text-results/4338 (certified 2026-06-26, fetched 2026-08-07), contest "ASSESSOR".
--
-- ---------------------------------------------------------------------------------------------------
-- THE FIELD WAS 2 OF 5
-- ---------------------------------------------------------------------------------------------------
-- Certified field is FIVE names summing to exactly 100.00%, so it is complete as printed:
--
--   Jeffrey Prang        1,028,580   57.73%   (incumbent)   -> won outright
--   Sandy Sun              272,494   15.29%                 -> MISSING, added here
--   Rob Newland            223,986   12.57%                 -> MISSING, added here
--   Stephen A. Adamus      151,715    8.52%                 -> already recorded, lost
--   Steven B. Palty        104,919    5.89%                 -> MISSING, added here
--
-- Assessor is a NONPARTISAN county office, so Prang's 57.73% is an outright majority and the contest is
-- over — there is no November runoff and none is created. His `won` was already recorded correctly.
--
-- Stored as "Jeff Prang" in our data; the canvass prints "JEFFREY PRANG". Same person, left alone —
-- renaming him is a separate decision from completing the field.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE WINNER WAS MARKED `withdrawn`
-- ---------------------------------------------------------------------------------------------------
-- Prang carried candidate_status = 'withdrawn' alongside result = 'won'. Those cannot both be true. The
-- consequence is not cosmetic: `essentials.is_live_candidate(candidate_status, result)` returns FALSE
-- for anything 'withdrawn', so the person who WON the Assessor race was being treated as not a live
-- candidate at all 11 call sites across 7 services.
--
-- Same wrong-column mistake as the twelve Los Angeles Mayor rows repaired in migration 1594: an outcome
-- written into `candidate_status` instead of `result`. There it hid losers, which looked right by
-- accident; here it hid the winner, which does not.
--
-- ✅ SWEPT, NOT ASSUMED: the whole table was checked for the contradiction rather than just this row.
-- `candidate_status='withdrawn' AND result IS NOT NULL` returns FIVE rows corpus-wide — this one, plus
-- four with result='not_nominated' (LAUSD D2, LA City Council D3 and D15). Those four are CONSISTENT:
-- 'withdrawn' and 'not_nominated' both mean "not a live candidate", and is_live_candidate excludes them
-- either way. So Prang is the only genuine contradiction in the corpus and no broader repair is owed.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

-- is_incumbent stated explicitly: the column DEFAULTS TO TRUE and all three of these lost.
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, source, is_incumbent, is_active)
VALUES
  ('0e25f0d0-f176-43fb-af83-f1e76585b5a2', 'Sandy Sun',       'Sandy',  'Sun',     'lavote-2026', false, true),
  ('a06b3720-c24d-40d1-9993-b149b6e790ac', 'Rob Newland',     'Rob',    'Newland', 'lavote-2026', false, true),
  ('4290adb1-187e-4f88-bc51-567fb4a72a6b', 'Steven B. Palty', 'Steven', 'Palty',   'lavote-2026', false, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source,
   result, result_recorded_at, result_source)
VALUES
  ('7b292d9e-8b68-4e27-82b9-986bdd4a243a', '0e25f0d0-f176-43fb-af83-f1e76585b5a2',
   'Sandy Sun', 'Sandy', 'Sun', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Assessor (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished second of five with 272,494 / 15.29%. Prang won outright with 57.73% in a nonpartisan county contest, so there is no runoff.'),
  ('7b292d9e-8b68-4e27-82b9-986bdd4a243a', 'a06b3720-c24d-40d1-9993-b149b6e790ac',
   'Rob Newland', 'Rob', 'Newland', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Assessor (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished third of five with 223,986 / 12.57%. Prang won outright with 57.73% in a nonpartisan county contest, so there is no runoff.'),
  ('7b292d9e-8b68-4e27-82b9-986bdd4a243a', '4290adb1-187e-4f88-bc51-567fb4a72a6b',
   'Steven B. Palty', 'Steven', 'Palty', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Assessor (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished fifth of five with 104,919 / 5.89%. Prang won outright with 57.73% in a nonpartisan county contest, so there is no runoff.')
ON CONFLICT DO NOTHING;

-- He won the race; he did not withdraw from it.
UPDATE essentials.race_candidates SET candidate_status = 'active'
 WHERE id = '909eb944-c7fe-4371-900a-796a0e31b14f'
   AND result = 'won';   -- guard: only flip the row whose outcome contradicts the status

COMMIT;

-- Verification (expected: 5 candidates, 1 won + 4 lost, 0 rows where withdrawn contradicts a real result)
--   SELECT full_name, candidate_status, result FROM essentials.race_candidates
--    WHERE race_id='7b292d9e-8b68-4e27-82b9-986bdd4a243a' ORDER BY result, full_name;
--   SELECT count(*) FROM essentials.race_candidates
--    WHERE candidate_status='withdrawn' AND result IN ('won','lost','advanced','runoff');
