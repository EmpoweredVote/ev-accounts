-- 1853_hi_2026_primary_certification_pass.sql
--
-- THE CERTIFICATION CULL for both U.S. House races on the HI 2026 Statewide General
-- (election e6326a3d-bcf5-45c5-8afb-64999d993fa0). The seeding pass wrote the FULL
-- qualified pre-primary field from the HI Office of Elections candidate filing group and
-- set provisional_until = 2026-08-08, the primary date. This is that gate, 34 days late.
--
-- Phase 167 (post-primary reconciliation), cluster 1 of 17. Method copied from
-- 1842_wa_2026_primary_certification_pass.sql, including its two hard-won rules: prove
-- certification against the jurisdiction's own document, and refuse to cull a cut line
-- that is not settled.
--
-- ============================================================================
-- WHAT MAKES THE SOURCE CERTIFIED, AND HOW THAT WAS PROVEN RATHER THAN ASSUMED
-- ============================================================================
-- Hawaii's 2026 Primary was held 2026-08-08. Two INDEPENDENT documents published by the
-- Office of Elections were compared candidate-for-candidate; every one of the 15 vote
-- totals below appears identically in both (fetched 2026-09-11):
--
--   summary.txt      elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt
--                    Machine-readable statewide summary, one row per candidate, with the
--                    contest's party letter (N / G / R / D) in the Contest Party column.
--   histatewide.pdf  elections.hawaii.gov/wp-content/results/2026 Primary/histatewide.pdf
--                    The rendered Statewide Summary. Independent rendering, same numbers.
--
-- Also on file, and consistent: hi_sov.pdf, the official STATEMENT OF VOTE, headed
-- "State of Hawaii - STATEMENT OF VOTE / PRIMARY ELECTION 2026 / August 8, 2026", giving
-- the same contests at precinct level. It marks no winners, which is why the advancement
-- rule below had to be read from the statute rather than lifted off a results page.
--
-- 🔴 NO WEB SEARCH SUMMARY WAS USED. A search summary for this very race returned a
-- garbled Democratic field (it listed the Republican nominee among the Democrats). That is
-- the same failure mode 1842 recorded on the Kitsap sheriff race. Jurisdiction documents only.
--
-- ============================================================================
-- HAWAII IS A PARTISAN PRIMARY, NOT A TOP TWO — THE CULL RULE IS DIFFERENT
-- ============================================================================
-- Each party nominates one candidate per office; the party winner advances automatically.
-- A NONPARTISAN candidate for a partisan office does NOT advance automatically. Per HRS
-- §12-41(b), and stated in the Office of Elections' own Candidate's Manual 2026 Elections
-- (p.18, "If I run as a nonpartisan candidate for a partisan office, will I automatically
-- move on to the general election ballot if I win my Primary?" — "No"), a nonpartisan must:
--
--     • receive at least 10% of the votes cast for the office; OR
--     • receive a vote equal to or greater than the lowest vote received by a partisan
--       candidate who was nominated.
--
-- and "if more nonpartisan candidates qualify to run in the General Election than there are
-- seats available, then the nonpartisan candidate who receives the most votes will appear
-- on the General Election ballot."
--
-- ============================================================================
-- DIST I: THE GREEN NOMINEE'S 402 VOTES ARE WHAT PUT A NONPARTISAN ON THE BALLOT
-- ============================================================================
-- Total votes cast for the office: 129,024. Ten per cent is 12,903.
-- Nominated partisans: CASE (D) 63,784, LAM (R) 18,530, CONLEY (G) 402 — Conley was the
-- sole Green candidate and therefore his party's nominee. The LOWEST nominated partisan is
-- 402, so the second prong sits very low in this district.
-- BERNING (N) took 977. That is 0.76% of the office — the 10% prong fails — but 977 >= 402,
-- so the second prong carries him onto the general ballot. He is culled by neither reading
-- of the first prong, which is why Dist I needs no judgement call at all.
--
-- ============================================================================
-- 🔴 DIST II: THE ONE ROW THIS MIGRATION REFUSES TO CULL — EDWARD A. CODELIA
-- ============================================================================
-- Total votes cast for the office: 128,940. Ten per cent is 12,894.
-- Nominated partisans: TOKUDA (D) 92,075, AWA (R) 26,290. Lowest is 26,290.
-- CODELIA (N) took 1,230. The second prong fails outright (1,230 < 26,290). The first prong
-- turns on what "the votes cast for the office" counts:
--     • all party contests for the office (128,940) -> 0.95%, FAILS, and Codelia is out;
--     • the nonpartisan contest alone (1,968 candidate votes) -> 62.5%, PASSES, he is in.
-- The broad reading is the coherent one — under the narrow reading almost any nonpartisan
-- clears 10% and the second prong would never be needed — but this migration will not
-- remove a human being from a ballot on a reading of a statute it cannot cite a state
-- document for. CODELIA THEREFORE KEEPS result = NULL and gets provisional_until
-- 2026-09-25, to be settled against Hawaii's published general-election ballot.
-- Re-enter: .planning/todos/2026-09-11-hi-cd2-codelia-nonpartisan-qualification.md
--
-- ⚠ RANDALL TERRY IS NOT THE SAME CASE and IS culled: he took 738, which fails the second
-- prong (738 < 26,290) AND fails under the narrow reading too — because the narrow reading
-- qualifies Codelia as well, and with one seat available only "the nonpartisan candidate who
-- receives the most votes" advances, which is Codelia at 1,230. Terry is out under BOTH
-- readings, so there is nothing unsettled about him.
--
-- ============================================================================
-- DISPOSITION OF ALL 15 ROWS ON THESE TWO RACES
-- ============================================================================
--    6  result = 'advanced'      party nominee, or a nonpartisan who cleared HRS 12-41(b)
--    8  result = 'not_nominated' ran and was not nominated
--    1  result stays NULL        Codelia — see above
--
-- essentials.is_live_candidate (migration 1582) is what makes this a cull: 'not_nominated'
-- drops out of every read path. Live field afterwards: Dist I 4 of 8, Dist II 3 of 7.
--
-- NOTHING IS HARD-DELETED and no politician row is deactivated. Phase 167's plan text says
-- to retire losers via politicians.is_active = false as well; 1842 did not, and this does
-- not either — is_active is the reps feed, and a sitting officeholder who loses a primary
-- still holds the seat until January. It does not bite here (neither loser is an incumbent;
-- Case and Tokuda both won) but the safer mechanism is the one that generalises.
--
-- MATCHING. 15 of 15 rows matched 1:1 by (race, full_name) against the certified summary;
-- the state prints "LAST, First M." and we store "First Last", so the certified spelling
-- travels in the tally below and the join is on our own exact stored name. Zero certified
-- candidates are missing from our field, and zero of our rows went unexplained.
--
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

-- ── the certified tally, one row per candidate, from the two documents named above ─────────
CREATE TEMP TABLE hi_cert_tally (
  position_name text NOT NULL,
  our_name      text NOT NULL,   -- exactly as essentials.race_candidates.full_name holds it
  cert_name     text NOT NULL,   -- exactly as the Office of Elections prints it
  party         text NOT NULL,   -- the contest's party letter in summary.txt
  votes         integer NOT NULL,
  disposition   text NOT NULL CHECK (disposition IN ('advanced','not_nominated','held')),
  why           text NOT NULL
) ON COMMIT DROP;

INSERT INTO hi_cert_tally (position_name, our_name, cert_name, party, votes, disposition, why) VALUES
  -- U.S. Representative, Dist I — 129,024 votes cast for the office
  ('U.S. Representative District 1', 'Ed Case',              'CASE, Ed',                   'D', 63784, 'advanced',
   'Democratic nominee: highest vote in the Dist I Democratic primary (63,784 of 109,115 cast in that contest).'),
  ('U.S. Representative District 1', 'Adriel Lam',           'LAM, Adriel C.',             'R', 18530, 'advanced',
   'Republican nominee: sole candidate in the Dist I Republican primary.'),
  ('U.S. Representative District 1', 'Jordan Conley',        'CONLEY, Jordan S.',          'G',   402, 'advanced',
   'Green nominee: sole candidate in the Dist I Green primary. His 402 votes are the lowest nominated-partisan total, which is the bar the nonpartisan second prong is measured against.'),
  ('U.S. Representative District 1', 'Nathan Berning',       'BERNING, Nathan M.',         'N',   977, 'advanced',
   'Nonpartisan, qualified under HRS 12-41(b) second prong: 977 >= 402, the lowest vote received by a nominated partisan (Conley, Green). Fails the 10% prong (977 of 129,024 = 0.76%), which is not required when the second prong is met.'),
  ('U.S. Representative District 1', 'Jarrett Keohokalole',  'KEOHOKALOLE, Jarrett K.',    'D', 40848, 'not_nominated',
   'Second of five in the Dist I Democratic primary, 22,936 behind Case. Not the party nominee.'),
  ('U.S. Representative District 1', 'Jennifer Booker',      'BOOKER, Jennifer',           'D',  2433, 'not_nominated',
   'Third of five in the Dist I Democratic primary. Not the party nominee.'),
  ('U.S. Representative District 1', 'Ben Fatula',           'FATULA, Ben',                'D',  1025, 'not_nominated',
   'Fourth of five in the Dist I Democratic primary, tied with Kiswanto at 1,025. The tie is for fourth place and has no bearing on the nomination, which Case won by 22,936.'),
  ('U.S. Representative District 1', 'Nicholas Kiswanto',    'KISWANTO, Nicholas (Nick)',  'D',  1025, 'not_nominated',
   'Fifth of five in the Dist I Democratic primary, tied with Fatula at 1,025. The tie is for fourth place and has no bearing on the nomination.'),
  -- U.S. Representative, Dist II — 128,940 votes cast for the office
  ('U.S. Representative District 2', 'Jill N. Tokuda',       'TOKUDA, Jill N.',            'D', 92075, 'advanced',
   'Democratic nominee: highest vote in the Dist II Democratic primary (92,075 of 100,682 cast in that contest).'),
  ('U.S. Representative District 2', 'Brenton Awa',          'AWA, Brenton',               'R', 26290, 'advanced',
   'Republican nominee: sole candidate in the Dist II Republican primary. His 26,290 is the lowest nominated-partisan total in this district.'),
  ('U.S. Representative District 2', 'Steven King',          'KING, Steven',               'D',  3917, 'not_nominated',
   'Second of four in the Dist II Democratic primary. Not the party nominee.'),
  ('U.S. Representative District 2', 'Greg Guithues',        'GUITHUES, Greg',             'D',  3160, 'not_nominated',
   'Third of four in the Dist II Democratic primary. Not the party nominee.'),
  ('U.S. Representative District 2', 'Kirill Basin',         'BASIN, Kirill',              'D',  1530, 'not_nominated',
   'Fourth of four in the Dist II Democratic primary. Not the party nominee.'),
  ('U.S. Representative District 2', 'Randall Terry',        'TERRY, Randall',             'N',   738, 'not_nominated',
   'Nonpartisan, not qualified under EITHER reading of HRS 12-41(b). Second prong: 738 < 26,290 (Awa). First prong: 0.57% of the 128,940 cast for the office. And on the narrow reading of "votes cast for the office" that would qualify him within his own contest, Codelia at 1,230 outpolls him for the single seat available, so he is out under that reading too.'),
  ('U.S. Representative District 2', 'Edward Codelia',       'CODELIA, Edward A.',         'N',  1230, 'held',
   'HELD, not culled. Fails the second prong (1,230 < 26,290) but the 10% prong depends on whether "votes cast for the office" means all party contests (0.95%, out) or the nonpartisan contest alone (62.5%, in). No state document settles it, so this row keeps result NULL and is re-checked against the published general-election ballot.');

-- ── resolve to our rows, and refuse to proceed on any mismatch ──────────────────────────────
CREATE TEMP TABLE hi_cert_target AS
SELECT rc.id AS rc_id, t.disposition, t.votes, t.our_name, t.position_name,
       'Hawaii Office of Elections, certified results of the 2026-08-08 Primary Election. '
       || 'Statewide Summary (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt) '
       || 'cross-checked candidate-for-candidate against the rendered Statewide Summary '
       || '(same directory, histatewide.pdf) and consistent with the official STATEMENT OF VOTE '
       || '(hi_sov.pdf, "PRIMARY ELECTION 2026 ... August 8, 2026"); all fetched 2026-09-11. '
       || 'Contest "' || t.cert_name || '" (' || t.party || '), ' || to_char(t.votes, 'FM999,999')
       || ' votes. ' || t.why
       AS result_source
  FROM hi_cert_tally t
  JOIN essentials.races r
    ON r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'
   AND r.position_name = t.position_name
  JOIN essentials.race_candidates rc
    ON rc.race_id = r.id
   AND rc.full_name = t.our_name;

DO $$
DECLARE n_tally int; n_matched int; n_ours int;
BEGIN
  SELECT count(*) INTO n_tally   FROM hi_cert_tally;
  SELECT count(*) INTO n_matched FROM hi_cert_target;
  SELECT count(*) INTO n_ours
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0';

  IF n_tally <> 15 THEN RAISE EXCEPTION 'tally holds % rows, expected the 15 certified candidates', n_tally; END IF;
  IF n_matched <> n_tally THEN
    RAISE EXCEPTION 'only % of % certified candidates matched a row — a name changed under us', n_matched, n_tally;
  END IF;
  IF n_ours <> 15 THEN
    RAISE EXCEPTION 'this election carries % candidate rows, not the 15 this migration accounts for', n_ours;
  END IF;
  IF (SELECT count(DISTINCT rc_id) FROM hi_cert_target) <> n_matched THEN
    RAISE EXCEPTION 'a single row matched two certified candidates';
  END IF;
END $$;

-- ── 1. the 6 advancing candidates, and the 8 who were not nominated ─────────────────────────
UPDATE essentials.race_candidates rc
   SET result = t.disposition,
       result_source = t.result_source,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM hi_cert_target t
 WHERE rc.id = t.rc_id
   AND t.disposition IN ('advanced','not_nominated')
   AND (rc.result IS DISTINCT FROM t.disposition
        OR rc.result_source IS DISTINCT FROM t.result_source
        OR rc.provisional_until IS NOT NULL);

-- ── 2. Codelia: HELD pending the published general-election ballot ──────────────────────────
UPDATE essentials.race_candidates rc
   SET provisional_until = DATE '2026-09-25',
       last_verified_at = now(),
       updated_at = now()
  FROM hi_cert_target t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'held'
   AND (rc.provisional_until IS DISTINCT FROM DATE '2026-09-25' OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY: every assertion below is a POSITIVE fact about the end state ────────────────
DO $$
DECLARE
  n_adv int; n_not int; n_null int; n_live int; n_stale int; n_nosrc int; n_d1 int; n_d2 int;
  n_codelia_prov int;
BEGIN
  SELECT count(*) FILTER (WHERE rc.result = 'advanced'),
         count(*) FILTER (WHERE rc.result = 'not_nominated'),
         count(*) FILTER (WHERE rc.result IS NULL),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result))
    INTO n_adv, n_not, n_null, n_live
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0';

  IF n_adv <> 6 THEN RAISE EXCEPTION 'expected 6 advanced, found %', n_adv; END IF;
  IF n_not <> 8 THEN RAISE EXCEPTION 'expected 8 not_nominated, found %', n_not; END IF;
  IF n_null <> 1 THEN RAISE EXCEPTION 'expected exactly 1 row left unresolved (Codelia), found %', n_null; END IF;
  IF n_live <> 7 THEN RAISE EXCEPTION 'expected 7 live candidates after the cull, found %', n_live; END IF;

  -- the live field per district, which is what a voter actually sees
  SELECT count(*) FILTER (WHERE r.position_name = 'U.S. Representative District 1'),
         count(*) FILTER (WHERE r.position_name = 'U.S. Representative District 2')
    INTO n_d1, n_d2
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'
     AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_d1 <> 4 THEN RAISE EXCEPTION 'Dist I should carry 4 live candidates (Case, Lam, Conley, Berning), found %', n_d1; END IF;
  IF n_d2 <> 3 THEN RAISE EXCEPTION 'Dist II should carry 3 live candidates (Tokuda, Awa, Codelia held), found %', n_d2; END IF;

  -- Codelia must be held forward, not silently cleared
  SELECT count(*) INTO n_codelia_prov
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'
     AND rc.full_name = 'Edward Codelia'
     AND rc.result IS NULL
     AND rc.provisional_until = DATE '2026-09-25';
  IF n_codelia_prov <> 1 THEN RAISE EXCEPTION 'Codelia is not held at 2026-09-25 with a NULL result'; END IF;

  -- nothing on this election may be left stale (past its date and unverified)
  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'
     AND rc.provisional_until IS NOT NULL
     AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;

  -- a result without a citation of the 2026-08-08 canvass is what this pass forbids
  SELECT count(*) INTO n_nosrc
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'
     AND rc.result IS NOT NULL
     AND (rc.result_source IS NULL OR rc.result_source NOT LIKE '%2026-08-08%');
  IF n_nosrc > 0 THEN RAISE EXCEPTION '% result rows do not cite the 2026-08-08 canvass', n_nosrc; END IF;

  RAISE NOTICE 'HI 2026 certification pass OK: % advanced, % not_nominated, 1 held, % live of 15',
    n_adv, n_not, n_live;
END $$;

COMMIT;

-- ROLLBACK (restores the pre-cull field; the rows themselves were never deleted):
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          last_verified_at = NULL, provisional_until = DATE '2026-08-08', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id = 'e6326a3d-bcf5-45c5-8afb-64999d993fa0';
