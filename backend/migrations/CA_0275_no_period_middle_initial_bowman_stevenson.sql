-- CA_0275_no_period_middle_initial_bowman_stevenson.sql
-- Move a no-period middle initial out of last_name for the two active people who still carry one
-- ("Jay J Bowman": last_name 'J Bowman'), in essentials.politicians and essentials.race_candidates.
--
-- WHY: CA_0267 (PR #764) and CA_0274 (PR #771) fixed the 'J. Gray' shape -- an initial WITH a period -- in the two
-- tables. These two rows have the same defect without the period, so both passes left them alone (CA_0274 listed
-- Bowman's candidate row as held). Surname matchers read last_name; with 'J Bowman' there, none of them sees "Bowman".
--
-- MEASURED 2026-09-24:
--   politicians     last_name ~ '^[A-Z] \S': 14 rows, 2 active -- the two below. The other 12 are inactive
--                   cal_access_discovery committee names ('A FAIR SHARE FOR HIGHLAND', 'I BACK MAC COMMITTEE', ...),
--                   first_name NULL/''. Not people; not touched (the same call CA_0267 made for its 7).
--   race_candidates last_name ~ '^[A-Z]\.? ': 1 row -- Bowman's, the row CA_0274 held.
--   Writers: Bowman came from the KY House seed 1237 (scripts/164-ky-generate.mts, one-shot, first-space split).
--   Stevenson came from the Utah county roster loader (data_source ut-county-davis), which now splits with
--   splitPersonName (#764) -- its INITIAL pattern /^[A-Z]\.?$/ takes 'J' as an initial, so a re-run writes the same
--   target as this file.
--
-- THE PERIOD: the initial is stored as the source writes it -- here 'J', no period. Both sources write it bare: the
--   KY candidate filing ("Jay J Bowman", as seeded by 1237; FEC H6KY06234 agrees) and the Davis County roster
--   ("Bob J Stevenson"). middle_initial already holds both forms (247 rows 'X', 199 rows 'X.'); nothing normalises
--   between them, and this file does not add a period a source never printed. full_name is NOT changed, so every
--   display that reads it shows the name exactly as before.
--
-- WHAT (3 rows, per id):
--   politicians     b1baf884  Jay J Bowman     last_name 'J Bowman'     -> 'Bowman',    middle_initial '' -> 'J'
--   politicians     1e099a11  Bob J Stevenson  last_name 'J Stevenson'  -> 'Stevenson', middle_initial '' -> 'J'
--   race_candidates 505e28df  Jay J Bowman     last_name 'J Bowman'     -> 'Bowman'    (no middle_initial column;
--                   the initial stays in full_name, as CA_0274 did for its 110 rows)
--   first_name, full_name, name_suffix, preferred_name NOT changed. No INSERT, no DELETE.
--   Duplicate check: no other active politician is named Jay Bowman or Bob/Robert Stevenson, so the change exposes
--   no duplicate.
--
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews, who ran it). Dry run (BEGIN ... ROLLBACK)
--   twice before, revert confirmed each time; a control with one row forced wrong made the gate raise. Apply:
--   UPDATE 2 + UPDATE 1, gate passed, COMMIT. Verified after: 0 active politicians and 0 race_candidates rows match
--   ^[A-Z]\.? ; both people read middle_initial 'J', full_name unchanged.
-- ROLLBACK: set last_name := old_last (and middle_initial := NULL on the politicians rows) for the ids below.
-- IDEMPOTENT: each UPDATE is guarded on last_name = old_last; a re-run changes nothing and the gate still passes.

BEGIN;

CREATE TEMP TABLE _p (id uuid PRIMARY KEY, old_last text, mi text, new_last text, full_name text) ON COMMIT DROP;
INSERT INTO _p VALUES
  ('b1baf884-5fd5-4618-b380-f2790fa47ee5'::uuid, $$J Bowman$$,    'J', $$Bowman$$,    $$Jay J Bowman$$),
  ('1e099a11-9f5e-44e4-806f-d9b81204cfa1'::uuid, $$J Stevenson$$, 'J', $$Stevenson$$, $$Bob J Stevenson$$);

CREATE TEMP TABLE _rc (id uuid PRIMARY KEY, old_last text, new_last text, full_name text) ON COMMIT DROP;
INSERT INTO _rc VALUES
  ('505e28df-2e97-475a-9d0e-2ba52a659db0'::uuid, $$J Bowman$$, $$Bowman$$, $$Jay J Bowman$$);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each row is as measured, or already in its target state from a previous run of this file
  SELECT count(*) INTO v_n FROM _p JOIN essentials.politicians p ON p.id = _p.id AND p.full_name = _p.full_name
   WHERE p.is_active
     AND ((p.last_name = _p.old_last AND COALESCE(p.middle_initial, '') = '')
       OR (p.last_name = _p.new_last AND p.middle_initial = _p.mi));
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 politicians rows in their measured or target state', v_n; END IF;

  SELECT count(*) INTO v_n FROM _rc JOIN essentials.race_candidates rc ON rc.id = _rc.id AND rc.full_name = _rc.full_name
   WHERE rc.last_name IN (_rc.old_last, _rc.new_last)
     AND rc.politician_id = 'b1baf884-5fd5-4618-b380-f2790fa47ee5'::uuid;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % of 1 race_candidates rows in their measured or target state', v_n; END IF;

  -- the list is the whole population of PEOPLE with the shape: no other active politician, no other candidate row
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.is_active AND p.last_name ~ '^[A-Z]\.? \S' AND p.id NOT IN (SELECT id FROM _p);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other active politicians match ^[A-Z]\.? -- re-measure', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.last_name ~ '^[A-Z]\.? ' AND rc.id NOT IN (SELECT id FROM _rc);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other race_candidates rows match ^[A-Z]\.? -- re-measure', v_n; END IF;

  -- moving the initial exposes no namesake
  SELECT count(*) INTO v_n FROM essentials.politicians p JOIN essentials.politicians q
      ON q.id IN (SELECT id FROM _p) AND p.id <> q.id
   WHERE p.is_active AND lower(p.first_name) = lower(q.first_name)
     AND lower(p.last_name) = lower((SELECT new_last FROM _p WHERE _p.id = q.id));
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % active namesakes would appear -- review before applying', v_n; END IF;
END $$;

-- ─── Move the initial ────────────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET last_name      = _p.new_last,
       middle_initial = _p.mi
  FROM _p
 WHERE p.id = _p.id
   AND p.last_name = _p.old_last
   AND COALESCE(p.middle_initial, '') = '';

UPDATE essentials.race_candidates rc
   SET last_name  = _rc.new_last,
       updated_at = now()
  FROM _rc
 WHERE rc.id = _rc.id
   AND rc.last_name = _rc.old_last
   AND rc.full_name = _rc.full_name;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _p JOIN essentials.politicians p ON p.id = _p.id
   WHERE p.last_name = _p.new_last AND p.middle_initial = _p.mi AND p.full_name = _p.full_name;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 politicians rows in their target state', v_n; END IF;

  SELECT count(*) INTO v_n FROM _rc JOIN essentials.race_candidates rc ON rc.id = _rc.id
   WHERE rc.last_name = _rc.new_last AND rc.full_name = _rc.full_name;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % of 1 race_candidates rows in their target state', v_n; END IF;

  -- no active politician and no candidate row carries the shape, with or without the period
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE is_active AND last_name ~ '^[A-Z]\.? \S';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % active politicians still match ^[A-Z]\.?', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE last_name ~ '^[A-Z]\.? ';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % race_candidates rows still match ^[A-Z]\.?', v_n; END IF;

  -- the candidate copy agrees with the politician copy
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE rc.id IN (SELECT id FROM _rc) AND rc.last_name = p.last_name;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: candidate and politician last_name disagree for Bowman'; END IF;

  RAISE NOTICE 'CA_0275 applied: no-period middle initial moved out of last_name for Bowman (2 tables) and Stevenson';
END $$;

COMMIT;
