-- 1469: Bring the Bend / Deschutes Nov-3-2026 field into the provisional_until convention
--
-- Migration 1415 seeded the Bend local ballot on 2026-07-24 — BEFORE Oregon's filing and
-- withdrawal deadlines closed (filing 2026-08-25 for non-incumbents / 2026-08-18 for elected
-- incumbents; withdrawals 2026-08-28). It is therefore a pre-resolution field, but it was seeded
-- with a bare source URL and no provisional_until, so it was indistinguishable from a settled one.
--
-- This adopts the mechanism migration 1456 established rather than inventing a parallel one:
--   provisional_until = the first date the row can be RE-VERIFIED (1456 pairs this with the
--   "cull >= <date>" wording in source). For Bend that is 2026-08-29 — the day after the
--   withdrawal deadline — NOT 2026-08-28, because the field is still mutable through Aug 28.
--
--   source must carry a provisional marker matching 'provisional|pre-primary|cull|filing deadline'.
--   1456's post-verify gate ASSERTS this for every dated row, so setting provisional_until on a
--   bare-URL source silently breaks a re-run of 1456. (It did: an earlier pass here dated these 15
--   rows without touching source, which left 1456's gate throwing '15 rows flagged provisional
--   without any provisional marker in source'. This migration is also that repair.)
--   source is prose+URL by convention and is NOT served to any client — electionService's
--   RACE_SELECT does not select it and no frontend reads it — so appending prose is safe.
--
-- SCOPE: the 8 LOCAL races (City of Bend + Deschutes County) = 15 candidate rows.
-- Deliberately NOT applied to OR House District 53/54, whose minor-party / independent nomination
-- window closes in the same period: all 60 Oregon House districts are equally provisional, so
-- flagging only Bend's two would show the note to HD-53 residents and nothing to HD-12's. That
-- wants an Oregon-wide pass.
--
-- The MTFCC/district_type guard is load-bearing, not decorative: geo_id '41017' is used by the
-- Deschutes County district (G4020) AND by OR State House District 17 (G5220) and State Senate
-- District 17 (G5210).
--
-- Re-check obligation: .planning/todos/2026-07-24-bend-or-postfiling-recheck.md §1.
-- Idempotent: both UPDATEs are guarded and re-running is a no-op.

BEGIN;

-- ── 1. Date the rows (first re-verifiable date, per the 1456 convention) ──
UPDATE essentials.race_candidates rc
   SET provisional_until = DATE '2026-08-29',
       updated_at = now()
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE rc.race_id = r.id
   AND e.election_date = DATE '2026-11-03'
   AND d.geo_id IN ('4105800', '41017')
   AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
   AND rc.provisional_until IS DISTINCT FROM DATE '2026-08-29';

-- ── 2. Give source the provisional marker 1456's gate requires ──
-- Matches the established wording: '<source>; provisional -- <field kind>, cull >= <date>'.
UPDATE essentials.race_candidates rc
   SET source = rc.source
        || '; provisional -- pre-deadline field (seeded 2026-07-24), cull >= 2026-08-29'
        || ' (OR filing closed 2026-08-25 / 2026-08-18 elected incumbents; withdrawals 2026-08-28)',
       updated_at = now()
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE rc.race_id = r.id
   AND e.election_date = DATE '2026-11-03'
   AND d.geo_id IN ('4105800', '41017')
   AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
   AND rc.provisional_until = DATE '2026-08-29'
   AND rc.source !~* 'provisional|pre-primary|cull|filing deadline';

-- ── 3. Gate: my 15 rows, plus BOTH of migration 1456's global invariants ──
DO $$
DECLARE
  v_rows int; v_races int; v_state int; v_decided int; v_unmarked int;
BEGIN
  SELECT count(*), count(DISTINCT rc.race_id)
    INTO v_rows, v_races
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE rc.provisional_until = DATE '2026-08-29'
     AND e.election_date = DATE '2026-11-03'
     AND d.geo_id IN ('4105800', '41017');

  IF v_rows <> 15 OR v_races <> 8 THEN
    RAISE EXCEPTION '1469 gate: expected 15 provisional rows across 8 races, got % rows / % races', v_rows, v_races;
  END IF;

  -- geo_id 41017 collision must not have leaked into the state legislative rows
  SELECT count(*) INTO v_state
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE rc.provisional_until = DATE '2026-08-29'
     AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER');
  IF v_state <> 0 THEN
    RAISE EXCEPTION '1469 gate: % state-legislative row(s) flagged — geo_id 41017 collision leaked', v_state;
  END IF;

  -- 1456 invariant A: nothing marked "decided" may be flagged provisional
  SELECT count(*) INTO v_decided FROM essentials.race_candidates
   WHERE provisional_until IS NOT NULL AND source ~* '\mdecided\M';
  IF v_decided <> 0 THEN
    RAISE EXCEPTION '1469 gate: % settled ("decided") rows are marked provisional (breaks 1456)', v_decided;
  END IF;

  -- 1456 invariant B: nothing dated may lack a provisional marker in source
  SELECT count(*) INTO v_unmarked FROM essentials.race_candidates
   WHERE provisional_until IS NOT NULL
     AND source !~* 'provisional|pre-primary|cull|filing deadline';
  IF v_unmarked <> 0 THEN
    RAISE EXCEPTION '1469 gate: % dated row(s) still lack a provisional marker (breaks 1456)', v_unmarked;
  END IF;

  RAISE NOTICE '1469 PASSED: 15 Bend rows / 8 races dated 2026-08-29; 1456 invariants intact.';
END $$;

COMMIT;
