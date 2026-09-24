-- 1856_ak_2026_primary_certification_pass.sql
--
-- 🔧 2026-09-24 (Chris Andrews, taking over Phase 167): every election-scoped read below is now also
--    scoped to r.position_name = 'U.S. Representative At-Large'. CA_0233 added the 2026 U.S. Senate race
--    to this same general election, so the original election-wide counts (and the name-to-row
--    resolution) would have counted Senate rows. The UPDATEs were already keyed by row id; no
--    disposition, source or date in this file changed.
--
-- Phase 167 (post-primary reconciliation), cluster 3 of 17: Alaska's U.S. Representative
-- At-Large race on the AK 2026 Statewide General (election aac67849-bc0f-4c54-be66-cd12c2a16548).
-- Seeded with the full pre-primary field, provisional_until = 2026-08-18. 24 days stale.
--
-- Alaska runs a TOP-FOUR open primary: the four candidates with the most votes advance to a
-- ranked-choice general, regardless of party. There is no party nomination to reason about.
--
-- ============================================================================
-- CERTIFICATION, PROVEN AGAINST TWO OF THE STATE'S OWN DOCUMENTS
-- ============================================================================
-- Both fetched 2026-09-11, both published by the Alaska Division of Elections:
--
--   ElectionSummaryReportRPT.pdf   elections.alaska.gov/enr26/results/
--       Headed "State of Alaska / 2026 PRIMARY ELECTION / Election Summary Report /
--       August 18, 2026 / OFFICIAL RESULTS", printed 8/31/2026 12:43:34 PM.
--       Precincts Reported: 401 of 403 (99.50%). Voters Cast: 166,992 of 601,906 (27.74%).
--   GA_ENR_Precinct_State_of_Alaska.csv   same directory
--       Precinct-level export, 444 precinct rows for this contest.
--
--   The results page itself (elections.alaska.gov/election-results/e/?id=26prim) states
--   "Results Status: Official — Page last updated August 31, 2026 at 2:53 pm".
--
-- 🔴 THE CSV WAS AGGREGATED INDEPENDENTLY AND MATCHES THE PDF TO THE VOTE on all fifteen
-- candidates, total 162,932. That is the cross-check 1842 requires: a status flag is the
-- publisher's own claim until a second document agrees with it.
--
-- ============================================================================
-- THE CERTIFIED TALLY (U.S. Representative, vote for 1)
-- ============================================================================
--    1  Begich, Nick               REP  72,696   44.62%   -> advances
--    2  Hill, Bill                 NON  53,008   32.53%   -> advances
--    3  Schultz, Matt              DEM  13,149    8.07%   -> advances
--    4  Hafner, Eric               DEM   6,175    3.79%   -> advances
--   ---- the cut line, 1,762 votes wide ------------------------------------------
--    5  Williams, John B.          DEM   4,413    2.71%   -> HELD, see below
--    6  Strickland, Clay           REP   3,681    2.26%
--    7  Reynoso, Yaquelin          DEM   2,928    1.80%
--    8  McDermott, James C. "Jim"  LIB   1,951    1.20%
--    9  Salazar, Melanie A.        NON   1,181    0.72%
--   10  Goldfarb, Eddie            REP     943    0.58%
--   11  Dutchess, Lady Donna       NON     715    0.44%
--   12  Williams, Matthew "Bronco" UND     632    0.39%
--   13  Richey, David              NON     579    0.36%
--   14  Ambrose, David R. II       NON     523    0.32%
--   15  Foddrill, John E. Sr.      LIB     358    0.22%
--
-- The cut line is not close: 4th beats 5th by 1,762 votes, 1.08% of all votes cast. No
-- recount margin is anywhere near it.
--
-- ============================================================================
-- 🔴 WHY FIFTH PLACE IS HELD RATHER THAN CULLED
-- ============================================================================
-- Alaska replaces a withdrawing top-four candidate with the next highest vote-getter. This
-- migration could NOT confirm the final general-election field from a state document: the
-- Division's general-election candidate list is served only through a search form that
-- returns an unfiltered, paginated list with no contest column, and no candidate-list PDF is
-- published for the general. So the question "did any of the four withdraw?" is open.
--
-- Ranks 6-15 are culled anyway, because a single withdrawal can only promote rank 5 — they
-- are out under every one-withdrawal scenario. RANK 5 (John B. Williams) IS HELD: result
-- stays NULL, provisional_until 2026-09-25, and the race therefore keeps telling readers it
-- is not fully verified.
--   .planning/todos/2026-09-11-ak-cd-al-confirm-final-four.md
--
-- ============================================================================
-- DISPOSITION OF ALL 15 ROWS
-- ============================================================================
--    4  result = 'advanced'       the certified top four
--   10  result = 'not_nominated'  ranks 6-15
--    1  result stays NULL         rank 5, held
-- Live field afterwards: 5 of 15.
--
-- Nothing is hard-deleted and no politician row is deactivated.
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

CREATE TEMP TABLE ak_cert_tally (
  our_name    text NOT NULL,
  cert_name   text NOT NULL,
  party       text NOT NULL,
  votes       integer NOT NULL,
  rank        integer NOT NULL,
  disposition text NOT NULL CHECK (disposition IN ('advanced','not_nominated','held'))
) ON COMMIT DROP;

INSERT INTO ak_cert_tally (our_name, cert_name, party, votes, rank, disposition) VALUES
  ('Nicholas J. Begich III',     'Begich, Nick',               'REP', 72696,  1, 'advanced'),
  ('Bill Hill',                  'Hill, Bill',                 'NON', 53008,  2, 'advanced'),
  ('Matt Schultz',               'Schultz, Matt',              'DEM', 13149,  3, 'advanced'),
  ('Eric Hafner',                'Hafner, Eric',               'DEM',  6175,  4, 'advanced'),
  ('John B. Williams',           'Williams, John B.',          'DEM',  4413,  5, 'held'),
  ('Clay Strickland',            'Strickland, Clay',           'REP',  3681,  6, 'not_nominated'),
  ('Yaquelin Reynoso',           'Reynoso, Yaquelin',          'DEM',  2928,  7, 'not_nominated'),
  ('James C. "Jim" McDermott',   'McDermott, James C. "Jim"',  'LIB',  1951,  8, 'not_nominated'),
  ('Melanie A. Salazar',         'Salazar, Melanie A.',        'NON',  1181,  9, 'not_nominated'),
  ('Eddie Goldfarb',             'Goldfarb, Eddie',            'REP',   943, 10, 'not_nominated'),
  ('Lady Donna Dutchess',        'Dutchess, Lady Donna',       'NON',   715, 11, 'not_nominated'),
  ('Matthew "Bronco" Williams',  'Williams, Matthew "Bronco"', 'UND',   632, 12, 'not_nominated'),
  ('David Richey',               'Richey, David',              'NON',   579, 13, 'not_nominated'),
  ('David R. Ambrose II',        'Ambrose, David R. II',       'NON',   523, 14, 'not_nominated'),
  ('John E. Foddrill Sr.',       'Foddrill, John E. Sr.',      'LIB',   358, 15, 'not_nominated');

CREATE TEMP TABLE ak_cert_target AS
SELECT rc.id AS rc_id, t.disposition, t.rank,
       'Alaska Division of Elections, OFFICIAL certified results of the 2026-08-18 Primary '
       || 'Election, "U.S. Representative (Vote for 1)". Election Summary Report '
       || '(elections.alaska.gov/enr26/results/ElectionSummaryReportRPT.pdf, headed "OFFICIAL '
       || 'RESULTS", printed 8/31/2026, 401 of 403 precincts) cross-checked by independent '
       || 'aggregation of the precinct export (same directory, '
       || 'GA_ENR_Precinct_State_of_Alaska.csv) — the two agree to the vote on all fifteen '
       || 'candidates, total 162,932; the results page states "Results Status: Official"; '
       || 'fetched 2026-09-11. This candidate: ' || t.cert_name || ' (' || t.party || ') '
       || to_char(t.votes, 'FM999,999') || ' votes, rank ' || t.rank || ' of 15. '
       || CASE t.disposition
            WHEN 'advanced' THEN 'Alaska advances the top four from an open primary to a ranked-choice general.'
            ELSE 'Finished outside the top four; 4th place (Hafner, 6,175) leads 5th by 1,762 votes.'
          END
       AS result_source
  FROM ak_cert_tally t
  JOIN essentials.races r ON r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.full_name = t.our_name;

DO $$
DECLARE n_t int; n_m int; n_ours int;
BEGIN
  SELECT count(*) INTO n_t FROM ak_cert_tally;
  SELECT count(*) INTO n_m FROM ak_cert_target;
  SELECT count(*) INTO n_ours FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large';
  IF n_t <> 15 THEN RAISE EXCEPTION 'tally holds % rows, expected 15', n_t; END IF;
  IF n_m <> n_t THEN RAISE EXCEPTION 'only % of % certified candidates matched a row', n_m, n_t; END IF;
  IF n_ours <> 15 THEN RAISE EXCEPTION 'this election carries % rows, not the 15 accounted for', n_ours; END IF;
END $$;

-- ── 1. the certified top four, and ranks 6-15 ───────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result = t.disposition,
       result_source = t.result_source,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM ak_cert_target t
 WHERE rc.id = t.rc_id
   AND t.disposition IN ('advanced','not_nominated')
   AND (rc.result IS DISTINCT FROM t.disposition
        OR rc.result_source IS DISTINCT FROM t.result_source
        OR rc.provisional_until IS NOT NULL);

-- ── 2. rank 5: HELD, because a withdrawal in the top four would promote exactly this row ────
UPDATE essentials.race_candidates rc
   SET provisional_until = DATE '2026-09-25',
       last_verified_at = now(),
       updated_at = now()
  FROM ak_cert_target t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'held'
   AND (rc.provisional_until IS DISTINCT FROM DATE '2026-09-25' OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_adv int; n_not int; n_null int; n_live int; n_stale int; n_nosrc int; n_held int;
BEGIN
  SELECT count(*) FILTER (WHERE rc.result = 'advanced'),
         count(*) FILTER (WHERE rc.result = 'not_nominated'),
         count(*) FILTER (WHERE rc.result IS NULL),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result))
    INTO n_adv, n_not, n_null, n_live
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large';

  IF n_adv <> 4 THEN RAISE EXCEPTION 'expected the certified top 4 advanced, found %', n_adv; END IF;
  IF n_not <> 10 THEN RAISE EXCEPTION 'expected 10 not_nominated (ranks 6-15), found %', n_not; END IF;
  IF n_null <> 1 THEN RAISE EXCEPTION 'expected 1 held row (rank 5), found %', n_null; END IF;
  IF n_live <> 5 THEN RAISE EXCEPTION 'expected 5 live (top four plus the held rank 5), found %', n_live; END IF;

  SELECT count(*) INTO n_held
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large'
     AND rc.full_name = 'John B. Williams' AND rc.result IS NULL
     AND rc.provisional_until = DATE '2026-09-25';
  IF n_held <> 1 THEN RAISE EXCEPTION 'rank 5 is not held at 2026-09-25 with a NULL result'; END IF;

  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large'
     AND rc.provisional_until IS NOT NULL AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;

  SELECT count(*) INTO n_nosrc
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548' AND r.position_name = 'U.S. Representative At-Large'
     AND rc.result IS NOT NULL
     AND (rc.result_source IS NULL OR rc.result_source NOT LIKE '%2026-08-18%');
  IF n_nosrc > 0 THEN RAISE EXCEPTION '% result rows do not cite the 2026-08-18 canvass', n_nosrc; END IF;

  RAISE NOTICE 'AK 2026 certification pass OK: % advanced, % not_nominated, 1 held, % live of 15',
    n_adv, n_not, n_live;
END $$;

COMMIT;

-- ROLLBACK:
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          last_verified_at = NULL, provisional_until = DATE '2026-08-18', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id = 'aac67849-bc0f-4c54-be66-cd12c2a16548';
