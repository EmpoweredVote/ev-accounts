-- CC_0270_relink_sonja_shaw_candidacies.sql
--
-- Re-links the TWO Sonja Shaw candidacies that CC_0263 made and CC_0264 reverted:
--
--   4939c2c8-9bc4-4524-bdaf-daadff60f38c  CA Superintendent of Public Instruction,
--                                         2026 LA County Primary (result 'advanced')
--   3e2a7783-ebf5-4d35-b9cb-f396c30dceab  Superintendent of Public Instruction,
--                                         CA 2026 Statewide General (2026-11-03)
--     -> politician 5f76110b-eb6c-59b4-8c6a-c97e8722cc05  "Sonja Shaw"
--
-- Operator ruling 2026-10-20: re-link.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE EVIDENCE DID NOT ARRIVE. IT WAS ALREADY IN OUR OWN DATABASE AND I DID NOT LOOK.
--
-- CC_0264 reverted the link saying her designation "names a ROLE TYPE and no district", and
-- listed what would settle it: "anything naming the district beside the name. The Chino Valley
-- USD board roster, a CDE or county registrar filing..."
--
-- That roster was ALREADY RECORDED. `CA_0308` wrote her office_terms row on **2026-10-14**,
-- five days before CC_0264 was written, seating her as Board Member (Trustee Area 3) of Chino
-- Valley Unified School District from 2022-11-01, and its own `source` column quotes the
-- district: "Sonja Shaw was elected to the Board of Education in November 2022".
--
-- ⚠ SO CC_0264 IS NOT BEING OVERTURNED BY NEW FACTS. It reached the right verdict on the
-- evidence it considered and considered the wrong set: it examined the ballot designation and
-- the race geometry, and never asked what WE record about her. The lesson is not "re-check
-- later", it is **read your own database before declaring evidence absent**. A revert justified
-- by an absence that a single join would have filled is a reasoning failure, not bad luck.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- WHAT NOW CLEARS THE CC_0263 BAR. The standard is: the office the candidate states under
-- penalty of perjury matches an office we independently record them holding.
--
--   1. BALLOT DESIGNATION (CA SOS certified list, cited in CC_0263): "School District
--      President". Her own sworn statement of occupation.
--   2. THE DISTRICT, FROM ITS OWN SITE -- the same source our office_term cites:
--      https://www.chino.k12.ca.us/145710_3, read 2026-10-20, reads verbatim:
--        "Board President  SONJA SHAW  Elected 2022  Term Expires 2026
--         Sonja Shaw was elected to the Board of Education in November 2022."
--      The page is the district's own Board Member Biographies entry. It names her as
--      PRESIDENT of that board, which is exactly the role the designation states.
--   3. OUR RECORD: office_terms seats her on Chino Valley Unified School District,
--      Board Member (Trustee Area 3), term_start 2022-11-01 (precision 'month').
--   4. EXACTLY ONE Sonja Shaw exists in the corpus, active, asserted in the guard below.
--   5. CROSS-STATE TEST PASSES: the seat she holds is in California (district.state 'ca') and
--      the race is a California statewide race. This is the test that caught Cheryl Williams,
--      Amanda Campbell, Ed Delgado, Mike Murphy and Tony Rodriguez.
--
-- 🔴 WHAT STILL CANNOT BE DONE, STATED SO IT IS NOT MISTAKEN FOR STRENGTH: Superintendent of
-- Public Instruction is a STATEWIDE office, so the ST_Intersects corroborator cannot run at
-- all -- there is no district to intersect. That was true in CC_0264 and is still true. What
-- replaces it is that "School District President" is no longer a role type floating free: it
-- now names a specific board, that board's own website names her as its president, and we
-- independently record her on it. The designation and the record agree on ONE seat.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ▶ WHAT THE LINK CARRIES. Nothing but a connection. Measured 2026-10-20:
--      0 compass answers · 0 context rows · 0 default images · photo_custom_url NULL
--      0 other candidacies pointing at her
-- Both candidacy rows have photo_url NULL, so neither ballot page gains a photograph and no
-- stance moves into view. A voter sees her name tied to a profile that is currently empty.
-- That is a smaller change than CC_0262's (13 answers) or CC_0269's Umberg (23), and it is
-- stated here because CC_0262 made stating it the rule.
-- ⚠ She remains OWED A PHOTOGRAPH; she is one of the blanks this programme has not filled.
--
-- ▶ BOTH ROWS, not one. She advanced from the June primary for the same office, so the primary
-- row and the general row are the same candidacy continued -- the same continuity instrument
-- CC_0268 used for Morgan, Rascón, Brown, Hawks and Gates.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _relink (
  rc_id  uuid PRIMARY KEY,
  seeks  text NOT NULL
) ON COMMIT DROP;

INSERT INTO _relink VALUES
  ('4939c2c8-9bc4-4524-bdaf-daadff60f38c','CA Superintendent of Public Instruction'),
  ('3e2a7783-ebf5-4d35-b9cb-f396c30dceab','Superintendent of Public Instruction');

DO $$
DECLARE r record; v_name text; v_pid uuid; v_seeks text;
        v_active bool; v_namesakes int; v_seat int; v_state text;
  c_pol CONSTANT uuid := '5f76110b-eb6c-59b4-8c6a-c97e8722cc05';
BEGIN
  -- the person
  SELECT p.full_name, p.is_active INTO v_name, v_active
    FROM essentials.politicians p WHERE p.id = c_pol;
  IF v_name IS DISTINCT FROM 'Sonja Shaw' OR NOT coalesce(v_active,false) THEN
    RAISE EXCEPTION 'CC_0270: politician % is "%" active=% - expected an active Sonja Shaw',
                    c_pol, v_name, v_active;
  END IF;

  -- exactly one of her
  SELECT count(*) INTO v_namesakes FROM essentials.politicians
   WHERE is_active AND lower(full_name) = 'sonja shaw';
  IF v_namesakes <> 1 THEN
    RAISE EXCEPTION 'CC_0270: % active politicians are named Sonja Shaw - the name no longer '
                    'identifies anyone, REFUSING', v_namesakes;
  END IF;

  -- 🔴 THE PREMISE: she must still be recorded on the Chino Valley board. If that term is
  -- gone, the entire argument above evaporates and this becomes CC_0263's thin link again.
  SELECT count(*), min(d.state) INTO v_seat, v_state
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE ot.politician_id = c_pol
     AND d.label = 'Chino Valley Unified School District';
  IF v_seat < 1 THEN
    RAISE EXCEPTION 'CC_0270: we no longer record Sonja Shaw on the Chino Valley Unified '
                    'School District board - the fact this re-link rests on is gone, REFUSING';
  END IF;

  -- and that seat must be in the same state as the race (the wrong-person test)
  IF lower(coalesce(v_state,'')) <> 'ca' THEN
    RAISE EXCEPTION 'CC_0270: her recorded seat is in state "%", not CA - cross-state mismatch',
                    v_state;
  END IF;

  -- the candidacy rows
  FOR r IN SELECT * FROM _relink LOOP
    SELECT rc.full_name, rc.politician_id, ra.position_name
      INTO v_name, v_pid, v_seeks
      FROM essentials.race_candidates rc
      JOIN essentials.races ra ON ra.id = rc.race_id
     WHERE rc.id = r.rc_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0270: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> 'Sonja Shaw' THEN
      RAISE EXCEPTION 'CC_0270: row % is "%", expected "Sonja Shaw"', r.rc_id, v_name;
    END IF;
    IF v_seeks IS DISTINCT FROM r.seeks THEN
      RAISE EXCEPTION 'CC_0270: row % seeks "%", expected "%"', r.rc_id, v_seeks, r.seeks;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> c_pol THEN
      RAISE EXCEPTION 'CC_0270: row % is linked to %, not Sonja Shaw - REFUSING to repoint it',
                      r.rc_id, v_pid;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid
FROM _relink rl
WHERE rc.id = rl.rc_id
  AND rc.politician_id IS DISTINCT FROM '5f76110b-eb6c-59b4-8c6a-c97e8722cc05'::uuid;

-- post-verify
DO $$
DECLARE n_linked int; n_other int; n_unlinked int; n_offsite int;
  c_pol CONSTANT uuid := '5f76110b-eb6c-59b4-8c6a-c97e8722cc05';
BEGIN
  SELECT count(*) INTO n_linked
    FROM essentials.race_candidates rc JOIN _relink rl ON rl.rc_id = rc.id
   WHERE rc.politician_id = c_pol;
  IF n_linked <> 2 THEN
    RAISE EXCEPTION 'CC_0270: expected 2 linked Shaw rows, found %', n_linked;
  END IF;

  SELECT count(*) INTO n_other FROM essentials.race_candidates rc
   WHERE rc.politician_id = c_pol AND rc.id NOT IN (SELECT rc_id FROM _relink);
  IF n_other <> 0 THEN
    RAISE EXCEPTION 'CC_0270: % unexpected candidacy row(s) point at her', n_other;
  END IF;

  -- 🟢 CC_0269's property completes: the CA 2026 Statewide General now has NO unlinked rows.
  SELECT count(*) INTO n_unlinked FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.name = 'CA 2026 Statewide General' AND rc.politician_id IS NULL;
  IF n_unlinked <> 0 THEN
    RAISE EXCEPTION 'CC_0270: % CA general row(s) are still unlinked, expected 0', n_unlinked;
  END IF;

  SELECT count(*) INTO n_offsite FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url,'') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0270: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0270 OK - Shaw re-linked on both rows; CA 2026 Statewide General fully linked';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE RULE: READ YOUR OWN DATABASE BEFORE DECLARING EVIDENCE ABSENT.
-- CC_0264 refused this link for want of a district, wrote down which document would supply one,
-- and the document had been loaded into our own office_terms five days earlier by another
-- author's migration. The revert was correct about the DESIGNATION and never asked what we
-- already held. Before concluding "there is no evidence", join the tables that would carry it.
-- ⚠ AND DISTINGUISH THE TWO CASES WHEN YOU REVERSE A RULING. "New facts arrived" and "I did not
-- look" demand different write-ups: the first vindicates the earlier decision, the second
-- corrects it. This is the second, and saying so is the only way the next pass learns anything.
-- 🟢 The weakest-row discipline still paid: CC_0263 named Shaw as its thinnest link, which made
-- both the revert and this reversal two-line decisions instead of audits.
-- ───────────────────────────────────────────────────────────────────────────────────────────
