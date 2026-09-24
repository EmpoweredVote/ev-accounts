-- 1857_wy_2026_general_roster_reconciliation.sql
--
-- Phase 167 (post-primary reconciliation), cluster 4 of 17: Wyoming's U.S. Representative
-- At-Large race on the WY 2026 Statewide General (election 28ce873c-af6e-4802-9315-b47a5e0cdd9a).
-- Seeded 2026-07-07 from the pre-primary roster, provisional_until = 2026-08-18. 24 days stale.
--
-- ============================================================================
-- 🔴 THIS CLUSTER IS RECONCILED AGAINST THE GENERAL ROSTER, NOT AGAINST VOTE TOTALS
-- ============================================================================
-- Wyoming publishes no machine-readable primary result file, and the "Primary Election -
-- Official Results" link on sos.wyo.gov/Elections/2026ElectionInformation.aspx is broken —
-- its href is the literal string "INSERT LINK HERE" (observed 2026-09-11). What Wyoming does
-- publish is better for this purpose: its own roster of who is on the GENERAL ballot.
--
--   2026_WY_General_Election_Candidates.csv    sos.wyo.gov/Elections/Docs/2026/
--     The Secretary of State's general-election candidate roster, with a Date Withdrawn
--     column. Under "UNITED STATES REPRESENTATIVE" it holds FOUR names, none withdrawn:
--         GRAY, CHARLES JAN      REP   filed 05/26/2026   ballot name "Chuck Gray"
--         KINNEY, LISA           DEM   filed 05/15/2026   ballot name "Lisa Kinney"
--         JOHNSON, SHAWN A.      LBR   filed 08/17/2026   ballot name "Shawn Johnson"
--         HAGGIT, JEFFREY A.     CT    filed 07/17/2026   ballot name "Jeffrey Haggit"
--
--   2026_WY_Primary_Election_Candidates.csv    same directory
--     The primary field: 9 Republicans (Balow, Biteman, Christensen, Dodson, Friess, Giralt,
--     Goodenough, Gray, Rasner) and 2 Democrats (Del Real, Kinney).
--
--   2026_WY_Withdrawn_Primary_Election_Candidates.pdf   same directory
--     One U.S. Representative entry: "UNITED STATES REPRESENTATIVE - REPUBLICAN / Republican /
--     Frank Chapman / P.O. Box 70, Moran, WY 83013 / filed 05/14/2026 / withdrawn 07/24/2026".
--
-- All fetched 2026-09-11. Culling here is the "confirmed by absence" pattern 1842 used for its
-- five withdrawals, applied to the strongest possible document: a name absent from the state's
-- own general-election roster is not on the general-election ballot.
--
-- ============================================================================
-- 🔴 TWO ANOMALIES, BOTH RECORDED RATHER THAN SMOOTHED OVER
-- ============================================================================
-- 1. JEFFREY HAGGIT (Constitution Party) IS ON THE CERTIFIED GENERAL BALLOT AND WE DO NOT
--    HAVE HIM. He filed 07/17/2026, after our 2026-07-07 seeding run. Same class of defect as
--    Vermont in 1854: a minor-party or independent candidate who never appears in a primary
--    cannot be discovered by a results-driven cull. The race therefore KEEPS its flag.
--    .planning/todos/2026-09-11-wy-cd-al-missing-constitution-candidate.md
--
-- 2. DANIEL WORKMAN IS IN OUR DATA AND IN NO WYOMING ROSTER AT ALL — not the current primary
--    roster, not the withdrawn roster, not the general roster. His row was seeded 2026-07-07
--    from the primary roster PDF alongside the others, so either that PDF listed him and the
--    state has since removed him without a withdrawal entry, or our read of it was wrong. He
--    is culled on the same basis as everyone else (absent from the general roster, so not on
--    the ballot), but the provenance question is real and is logged in the same todo.
--
-- ============================================================================
-- DISPOSITION OF ALL 14 ROWS
-- ============================================================================
--    2  result = 'advanced'       Gray (REP) and Kinney (DEM), on the certified general roster
--    1  result = 'withdrew'       Chapman, per the state's own withdrawn-candidate roster
--   10  result = 'not_nominated'  ran in the primary and is absent from the general roster
--                                 (plus Workman, absent from every roster)
--    1  result stays NULL         Shawn Johnson — a Libertarian who filed straight for the
--                                 general on 08/17 and ran in no primary, so there is no
--                                 primary outcome to record
-- Live field afterwards: 3 of 14 — and the state says it should be 4.
--
-- Nothing is hard-deleted and no politician row is deactivated.
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

CREATE TEMP TABLE wy_target (
  our_name    text NOT NULL,
  disposition text NOT NULL CHECK (disposition IN ('advanced','not_nominated','withdrew','no_primary')),
  why         text NOT NULL
) ON COMMIT DROP;

INSERT INTO wy_target (our_name, disposition, why) VALUES
  ('Chuck Gray',          'advanced',      'Republican nominee. Listed as REP under "UNITED STATES REPRESENTATIVE" on the certified general-election roster, filed 05/26/2026, ballot name "Chuck Gray", no withdrawal date.'),
  ('Lisa Kinney',         'advanced',      'Democratic nominee. Listed as DEM under "UNITED STATES REPRESENTATIVE" on the certified general-election roster, filed 05/15/2026, ballot name "Lisa Kinney", no withdrawal date.'),
  ('Shawn Johnson',       'no_primary',    'Libertarian candidate who filed 08/17/2026, after the primary, and ran in no primary contest — he is absent from the primary candidate roster and present on the general roster as LBR. There is no primary outcome to record for him.'),
  ('Frank Chapman',       'withdrew',      'Withdrew from the Republican primary on 07/24/2026, recorded by name in the Secretary of State''s 2026 Withdrawn Primary Election Candidate Roster under "UNITED STATES REPRESENTATIVE - REPUBLICAN".'),
  ('Jillian Balow',       'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Bo Biteman',          'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Kevin Christensen',   'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Richard Dodson',      'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Steve Friess',        'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('David Giralt',        'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Keith B. Goodenough', 'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Reid Rasner',         'not_nominated', 'Ran in the Republican primary and is absent from the certified general-election roster.'),
  ('Elena Del Real',      'not_nominated', 'Ran in the Democratic primary and is absent from the certified general-election roster.'),
  ('Daniel Workman',      'not_nominated', 'Absent from the certified general-election roster, so not on the ballot. NOTE: he is also absent from the current primary candidate roster and from the withdrawn-candidate roster, although his row was seeded 2026-07-07 from the primary roster — the provenance of this record is unresolved and is logged in .planning/todos/2026-09-11-wy-cd-al-missing-constitution-candidate.md.');

CREATE TEMP TABLE wy_resolved AS
SELECT rc.id AS rc_id, t.disposition,
       'Wyoming Secretary of State 2026 general-election candidate roster '
       || '(sos.wyo.gov/Elections/Docs/2026/2026_WY_General_Election_Candidates.csv), read '
       || 'alongside the 2026 primary candidate roster and the 2026 Withdrawn Primary Election '
       || 'Candidate Roster in the same directory; all fetched 2026-09-11. The general roster '
       || 'holds exactly four names for UNITED STATES REPRESENTATIVE — Gray (REP), Kinney (DEM), '
       || 'Johnson (LBR) and Haggit (CT) — none carrying a withdrawal date. Wyoming publishes no '
       || 'machine-readable 2026-08-18 primary result file and its "Official Results" link is '
       || 'broken, so this reconciliation is against the roster of who is on the ballot rather '
       || 'than against vote totals. ' || t.why AS result_source
  FROM wy_target t
  JOIN essentials.races r ON r.election_id = '28ce873c-af6e-4802-9315-b47a5e0cdd9a'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.full_name = t.our_name;

DO $$
DECLARE n_t int; n_m int; n_ours int;
BEGIN
  SELECT count(*) INTO n_t FROM wy_target;
  SELECT count(*) INTO n_m FROM wy_resolved;
  SELECT count(*) INTO n_ours FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '28ce873c-af6e-4802-9315-b47a5e0cdd9a';
  IF n_t <> 14 THEN RAISE EXCEPTION 'target holds % rows, expected 14', n_t; END IF;
  IF n_m <> n_t THEN RAISE EXCEPTION 'only % of % names matched a row', n_m, n_t; END IF;
  IF n_ours <> 14 THEN RAISE EXCEPTION 'this election carries % rows, not the 14 accounted for', n_ours; END IF;
END $$;

-- ── 1. everything with a recordable outcome ─────────────────────────────────────────────────
-- The two survivors keep the flag (2026-09-18) because Haggit is missing; the culled rows do not
-- need one, since nothing about them is unresolved.
-- 🔴 A WITHDRAWAL NEEDS BOTH COLUMNS. essentials.is_live_candidate drops a row only on
-- candidate_status = 'withdrawn' OR result = 'not_nominated' — 'withdrew' is neither, so
-- recording the result alone would have left Chapman in the live field. 1842 never hit this
-- because its five withdrawals already carried candidate_status 'withdrawn' from the WA SoS
-- filings; Chapman's row is 'active'. The post-verify below is what caught it.
UPDATE essentials.race_candidates rc
   SET result = t.disposition,
       candidate_status = CASE WHEN t.disposition = 'withdrew' THEN 'withdrawn' ELSE rc.candidate_status END,
       result_source = t.result_source,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = CASE WHEN t.disposition = 'advanced' THEN DATE '2026-09-18' ELSE NULL END,
       updated_at = now()
  FROM wy_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition IN ('advanced','not_nominated','withdrew')
   AND (rc.result IS DISTINCT FROM t.disposition
        OR rc.result_source IS DISTINCT FROM t.result_source
        OR (t.disposition = 'withdrew' AND rc.candidate_status IS DISTINCT FROM 'withdrawn')
        OR rc.provisional_until IS DISTINCT FROM (CASE WHEN t.disposition = 'advanced' THEN DATE '2026-09-18' ELSE NULL END));

-- ── 2. Shawn Johnson: on the general ballot, but ran in no primary ──────────────────────────
UPDATE essentials.race_candidates rc
   SET last_verified_at = now(),
       provisional_until = DATE '2026-09-18',
       updated_at = now()
  FROM wy_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'no_primary'
   AND (rc.provisional_until IS DISTINCT FROM DATE '2026-09-18' OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_adv int; n_not int; n_wd int; n_null int; n_live int; n_flag int; n_stale int;
BEGIN
  SELECT count(*) FILTER (WHERE rc.result = 'advanced'),
         count(*) FILTER (WHERE rc.result = 'not_nominated'),
         count(*) FILTER (WHERE rc.result = 'withdrew'),
         count(*) FILTER (WHERE rc.result IS NULL),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)),
         count(*) FILTER (WHERE rc.provisional_until = DATE '2026-09-18')
    INTO n_adv, n_not, n_wd, n_null, n_live, n_flag
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '28ce873c-af6e-4802-9315-b47a5e0cdd9a';

  IF n_adv <> 2 THEN RAISE EXCEPTION 'expected 2 advanced (Gray, Kinney), found %', n_adv; END IF;
  IF n_wd  <> 1 THEN RAISE EXCEPTION 'expected 1 withdrew (Chapman), found %', n_wd; END IF;
  IF n_not <> 10 THEN RAISE EXCEPTION 'expected 10 not_nominated, found %', n_not; END IF;
  IF n_null <> 1 THEN RAISE EXCEPTION 'expected 1 NULL result (Johnson, no primary), found %', n_null; END IF;
  IF n_live <> 3 THEN RAISE EXCEPTION 'expected 3 live (Gray, Kinney, Johnson), found %', n_live; END IF;
  IF n_flag <> 3 THEN
    RAISE EXCEPTION 'expected the 3 surviving rows to stay flagged at 2026-09-18 while Haggit is '
      'missing from our field; found % flagged', n_flag;
  END IF;

  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '28ce873c-af6e-4802-9315-b47a5e0cdd9a'
     AND rc.provisional_until IS NOT NULL AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;

  RAISE NOTICE 'WY 2026 reconciliation OK: % advanced, % withdrew, % not_nominated, % no-primary, '
    '% live of 14; race stays flagged pending Jeffrey Haggit (CT)', n_adv, n_wd, n_not, n_null, n_live;
END $$;

COMMIT;

-- ROLLBACK:
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          last_verified_at = NULL, provisional_until = DATE '2026-08-18', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id = '28ce873c-af6e-4802-9315-b47a5e0cdd9a';
