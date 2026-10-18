-- CC_0247_adjudicate_two_cal_access_ie_sources.sql
--
-- The last two `confirmed` CAL-ACCESS sources that published on a politician page without a
-- note saying who adjudicated them. `check:cal-access-attribution` has failed the nightly on
-- these since the guard landed (PR #972).
--
--   Gavin Newsom   <- filer 1418587, ie_committee, oppose,  402 contributions,  $33,172.80
--   Mike A. Gipson <- filer 1448127, ie_committee, support,   8 contributions, $194,000.00
--
-- 🔴 NOTHING ABOUT THE ATTRIBUTION CHANGES HERE. CC_0225 had already typed both `ie_committee`
-- and given both a direction. What was missing was the marker the guard matches on — the claim
-- that a person checked it. This migration adds that claim, and records what it rests on.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE INSTRUMENT: THE CANDIDATE PAGE, NOT THE COMMITTEE PAGE
--
-- A committee page never names a candidate. A candidate's page lists every committee they
-- control, by filer id, so absence from it is what makes a committee independent. Read
-- 2026-10-18 (cal-access.sos.ca.gov, root loaded first — Incapsula refuses a cold deep link):
--
--   GIPSON, MIKE   candidate filer 1299805 — controls 12 committees, among them
--                  GIPSON FOR ASSEMBLY 2022 .................... ID 1434878
--                  1448127 is NOT among them  =>  genuine independent expenditure
--
--   NEWSOM, GAVIN  candidate filer 1308192 — controls 11 committees, among them
--                  NEWSOM; STOP THE REPUBLICAN RECALL OF GOVERNOR  ID 1436851 ($17,394,650.98)
--                  1418587 is NOT among them  =>  genuine independent expenditure
--
-- 🔴🔴 BOTH ARE NEAR-MISSES THAT A NAME TEST GETS WRONG, WHICH IS THE WHOLE REASON THE RULE IS
-- "ASK THE CANDIDATE PAGE". CAL-ACCESS displays 1448127 as
-- "GIPSON FOR ASSEMBLY 2022; CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE" — it *starts with the
-- exact name* of the committee he really controls (1434878). And Newsom controls his OWN
-- recall-related committee (1436851, "STOP THE REPUBLICAN RECALL"), so "is it about a recall?"
-- separates nothing here either. Only the filer id separates them.
--
-- ⚠ The split-looking names are CAL-ACCESS's own rendering, not corruption on our side — the
-- committee pages display exactly these strings. Do not "repair" them.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- DIRECTION
--
--   1448127  support — the name states it ("...SUPPORTING MIKE GIPSON"), and the committee is
--            absent from his page, so it is outside money spent for him.
--   1418587  oppose  — its historical name is "...COMMITTEE TO RECALL GAVIN NEWSOME, ALEX
--            PADILLA, XAVIER BECERRA, BETTY YEE, FIONA MA, ELENI KOUNALAKIS, RICARDO LARA",
--            terminated 02/14/2020. Money raised to REMOVE him. Confirming this as a committee
--            he CONTROLS would have published $33,172.80 as money he raised.
--
-- ⚠ 1418587 TARGETS SEVEN STATEWIDE OFFICIALS, NOT ONLY NEWSOM. Attaching it to Newsom with
-- `oppose` is correct but PARTIAL: the same committee opposes six other people who are not
-- linked to it. That is a completeness gap, not an error, and it is recorded rather than fixed.
-- ⚠ Its historical name spells the surname "NEWSOME". The seven names together are the 2018
-- statewide slate, so the subject is not in doubt.
--
-- ⚠ NOT RE-VERIFIED HERE: the Form 460 citations CC_0225 recorded (#2763543 Part 7, #2463962
-- Part 6). Both committee pages now read "has not electronically filed a Form 460/461/450 for
-- this election cycle". The direction above rests on the candidate-page test and the registered
-- committee names, which is independent of those filings.
--
-- Idempotent: the guard below refuses to double-stamp, and re-running changes nothing.

BEGIN;

DO $$
DECLARE
  k_newsom CONSTANT uuid := 'ffe32d48-3903-4377-a456-f3daac53370a';
  k_gipson CONSTANT uuid := 'd40629eb-00b9-406d-b4d5-08752a9bea20';
  v_cnt    int;
  v_bad    int;
BEGIN
  -- PRE: both rows are where we think they are, and still unmarked.
  SELECT count(*) INTO v_cnt
  FROM transparent_motivations.politician_sources
  WHERE id IN (k_newsom, k_gipson)
    AND source_system = 'cal_access'
    AND source_type   = 'ie_committee'
    AND research_status = 'confirmed';
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0247: expected 2 confirmed cal_access ie_committee rows, found %', v_cnt;
  END IF;

  -- the external ids must be the ones the candidate-page test was run against
  SELECT count(*) INTO v_cnt
  FROM transparent_motivations.politician_sources
  WHERE (id = k_newsom AND external_id = '1418587' AND support_oppose = 'oppose')
     OR (id = k_gipson AND external_id = '1448127' AND support_oppose = 'support');
  IF v_cnt <> 2 THEN
    RAISE EXCEPTION 'CC_0247: filer id / direction does not match the adjudicated pair';
  END IF;

  -- every notes value must carry the ' | ' separator this migration splits on
  SELECT count(*) INTO v_bad
  FROM transparent_motivations.politician_sources
  WHERE id IN (k_newsom, k_gipson) AND strpos(coalesce(notes, ''), ' | ') = 0;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0247: % row(s) have notes without the " | " separator', v_bad;
  END IF;
END $$;

-- Add the marker INSIDE the JSON half of `notes`, which is what the guard matches
-- (/"(?:adjudicated_by|published_by|verified_by)"\s*:/ — a textual test, so the key must be
-- a real JSON key and not prose), and append the reasoning to the prose half.
UPDATE transparent_motivations.politician_sources ps
SET notes =
      (
        (left(ps.notes, strpos(ps.notes, ' | ') - 1)::jsonb
          || jsonb_build_object(
               'adjudicated_by', 'chris@empowered.vote — CC_0247 (2026-10-18)',
               'adjudication', v.adjudication
             )
        )::text
      )
      || substr(ps.notes, strpos(ps.notes, ' | '))
      || ' | ADJUDICATED CC_0247: ' || v.adjudication,
    updated_at = now()
FROM (VALUES
  ('ffe32d48-3903-4377-a456-f3daac53370a'::uuid,
   'Independent: filer 1418587 is ABSENT from Gavin Newsom''s CAL-ACCESS candidate page '
   || '(candidate filer 1308192, 11 controlled committees, read 2026-10-18). He controls '
   || '1436851 "NEWSOM; STOP THE REPUBLICAN RECALL OF GOVERNOR" instead, so a recall test '
   || 'would not separate them; only the filer id does. Direction oppose: registered as '
   || '"COMMITTEE TO RECALL GAVIN NEWSOME, ALEX PADILLA, XAVIER BECERRA, BETTY YEE, FIONA MA, '
   || 'ELENI KOUNALAKIS, RICARDO LARA", terminated 02/14/2020. NOTE: it opposes seven statewide '
   || 'officials; only Newsom is linked to it, which is a completeness gap, not an error.'),
  ('d40629eb-00b9-406d-b4d5-08752a9bea20'::uuid,
   'Independent: filer 1448127 is ABSENT from Mike Gipson''s CAL-ACCESS candidate page '
   || '(candidate filer 1299805, 12 controlled committees, read 2026-10-18). His real '
   || '"GIPSON FOR ASSEMBLY 2022" is 1434878, and 1448127 DISPLAYS a name beginning with that '
   || 'exact string, so a name test confuses them; only the filer id separates them. '
   || 'Direction support per the registered name "...CALIFORNIANS FOR SOLUTIONS SUPPORTING '
   || 'MIKE GIPSON". Terminated 12/27/2022.')
) AS v(id, adjudication)
WHERE ps.id = v.id
  AND ps.notes NOT LIKE '%"adjudicated_by"%';   -- idempotent: never double-stamp

-- POST: both rows now carry the marker, the JSON half still parses, and nothing else moved.
DO $$
DECLARE
  v_marked int;
  v_bad    int;
  v_other  int;
BEGIN
  SELECT count(*) INTO v_marked
  FROM transparent_motivations.politician_sources
  WHERE id IN ('ffe32d48-3903-4377-a456-f3daac53370a','d40629eb-00b9-406d-b4d5-08752a9bea20')
    AND notes LIKE '%"adjudicated_by"%';
  IF v_marked <> 2 THEN
    RAISE EXCEPTION 'CC_0247: expected 2 rows carrying "adjudicated_by", found %', v_marked;
  END IF;

  -- the JSON half must still be valid jsonb, or the next reader of these notes breaks
  SELECT count(*) INTO v_bad
  FROM transparent_motivations.politician_sources
  WHERE id IN ('ffe32d48-3903-4377-a456-f3daac53370a','d40629eb-00b9-406d-b4d5-08752a9bea20')
    AND (left(notes, strpos(notes, ' | ') - 1))::jsonb IS NULL;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0247: % row(s) no longer parse as jsonb', v_bad;
  END IF;

  -- 🔴 the attribution itself must be untouched: same type, status and direction as before
  SELECT count(*) INTO v_other
  FROM transparent_motivations.politician_sources
  WHERE id IN ('ffe32d48-3903-4377-a456-f3daac53370a','d40629eb-00b9-406d-b4d5-08752a9bea20')
    AND source_type = 'ie_committee'
    AND research_status = 'confirmed'
    AND support_oppose IN ('support','oppose');
  IF v_other <> 2 THEN
    RAISE EXCEPTION 'CC_0247: the attribution changed, and it must not have';
  END IF;

  RAISE NOTICE 'CC_0247 OK: 2 CAL-ACCESS IE sources adjudicated on the candidate-page test';
END $$;

COMMIT;
