-- CC_wip_baldwin_coroner_succession.sql
--
-- Knight Foundation cities program -- CORRECTION to wave GA-3 (Baldwin County).
--
--   * 1 new politician  (Steve Chapple, -1331019)
--   * 1 term closed     (John Gonzalez, term_end 2026-05-01, how_ended 'retired')
--   * 1 term opened     (Chapple, term_start 2026-05-02, start_precision 'month')
--
-- Roster: backend/data/seed-columbus-2026/ROSTERS.md (GA-4 session)
-- Source: The Union-Recorder, 2026-05-14,
--         "Chapple sworn into office as new coroner; Gonzalez retires"
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 GA-3 SEATED A CORONER WHO HAD RETIRED FOUR MONTHS EARLIER, AND EVERY
--    GATE PASSED. `CC_0029` seated John Gonzalez from the Secretary of State's
--    certified 2024 return. That return is correct and still correct: he won
--    that election. He then RETIRED MID-TERM, on 2026-05-01, and a certified
--    result cannot report a change that postdates it.
--
--    This is the GA-2 SD-12 failure exactly -- the one the change-check rule
--    exists to stop -- and it reached production because GA-3's change-check
--    was run against the SOURCES rather than against the SEATS. The county's
--    own directory had already dropped Gonzalez; nobody re-read it per person.
--
-- ⚠ HOW IT WAS FOUND: not by a gate. It was found while hunting the four
--    Baldwin headshots still owed, because the Coroner is one of the four. The
--    headshot search surfaced the retirement notice. **A BODY'S ROSTER IS A
--    REDUNDANCY CHECK ON OCCUPANCY** -- this is the third time that has paid.
--
-- ---------------------------------------------------------------------------
-- 🔴 WHAT IS SOURCED, AND WHAT IS DELIBERATELY NOT
--
--   SOURCED, day precision:  "Gonzalez officially retired as coroner on May 1."
--     -> the predecessor's term_end is a real date, not an artifact. Rare here;
--        say so, because GA-3's own header had to record the opposite.
--
--   NOT SOURCED, hence 'month':  Chapple "took the oath of office ... during a
--     special swearing-in ceremony Thursday morning". The article ran Thursday
--     2026-05-14 and says "last Thursday", which reads as 2026-05-07 -- but that
--     is an INFERENCE from a relative phrase, so it is recorded HERE IN PROSE
--     and NOT as data. term_start is 2026-05-02 at 'month' precision: the day
--     is a placeholder the precision explicitly disclaims, and it is chosen so
--     seat_officeholder() closes Gonzalez on exactly the sourced 2026-05-01.
--
--   NOT SOURCED, hence 'unknown':  how_started. The article never states the
--     mechanism. It says Chapple "was serving as chief deputy coroner"; the
--     nearby sentence about a chief deputy being "appointed the new coroner"
--     is about GONZALEZ succeeding Wayne Brooks in the 1990s, not about
--     Chapple. Reading it as Chapple's would be a misattributed citation.
--     'appointed' and 'succeeded' are both plausible and neither is written
--     down, so this stays 'unknown' pending a primary source -- the same open
--     question already carried for Wanda T. Paul.
--
-- ⚠ Chapple takes -1331019, the next free id after GA-3's -1331001..-1331018.
--    GA-4 (Columbus) therefore starts at -1331020, not -1331019.
-- ---------------------------------------------------------------------------

BEGIN;

-- --- 1. Pre-flight ----------------------------------------------------------
-- Refuse rather than guess if the world is not what this migration expects.
DO $$
DECLARE
  v_office uuid;
  v_holder text;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga'
     AND d.geo_id = '13009' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
     AND o.title = 'Coroner';

  IF v_office IS NULL THEN
    RAISE EXCEPTION 'baldwin coroner: the Coroner office on Baldwin County (13009/G4020/COUNTY) does not exist -- apply CC_0029 first';
  END IF;

  SELECT p.full_name INTO v_holder
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = v_office;

  -- Idempotent: a second run finds Chapple already seated and stops cleanly.
  IF v_holder = 'Steve Chapple' THEN
    RAISE NOTICE 'OK: Baldwin Coroner already held by Steve Chapple -- nothing to do';
  ELSIF v_holder IS DISTINCT FROM 'John Gonzalez' THEN
    RAISE EXCEPTION 'baldwin coroner: expected the seat to be held by John Gonzalez (or already corrected to Steve Chapple), found %. Re-read the roster before writing.', coalesce(v_holder, '(vacant)');
  END IF;
END $$;

-- --- 2. The successor -------------------------------------------------------
-- 🔴 Identity is keyed on external_id, never on name. Guard the sub-range so a
--    neighbouring wave's legitimate rows are not mistaken for a collision --
--    the FL-4 correction: claim ONLY this row's id, never the shared band.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text || ' ' || full_name, ', ')
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id = -1331019
     AND full_name <> 'Steve Chapple';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'baldwin coroner: id -1331019 is owned by something else (%). Pick another id rather than colliding.', v_foreign;
  END IF;
END $$;

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
VALUES
  (-1331019, 'Steve Chapple', 'Steve', 'Chapple', NULL, NULL,
   '{}'::text[], true, true, 'unionrecorder-2026-05-14-chapple-sworn-gonzalez-retires')
ON CONFLICT (external_id) DO NOTHING;

-- --- 3. The succession ------------------------------------------------------
-- seat_officeholder() closes the predecessor's term the day BEFORE the start it
-- is given. 2026-05-02 therefore closes Gonzalez at exactly 2026-05-01, which
-- is the date the source states.
DO $$
DECLARE
  v_office uuid;
  v_chapple uuid;
  v_current text;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga'
     AND d.geo_id = '13009' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
     AND o.title = 'Coroner';

  SELECT p.full_name INTO v_current
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = v_office;

  IF v_current = 'Steve Chapple' THEN
    RAISE NOTICE 'OK: succession already applied -- skipping seat_officeholder()';
  ELSE
    SELECT id INTO v_chapple FROM essentials.politicians WHERE external_id = -1331019;

    PERFORM essentials.seat_officeholder(
      v_office,
      v_chapple,
      DATE '2026-05-02',
      'unionrecorder-2026-05-14-chapple-sworn-gonzalez-retires',
      p_how_started    => 'unknown',   -- mechanism never stated; see header
      p_start_precision=> 'month',     -- "Thursday morning" is not a date
      p_how_ended_prev => 'retired'    -- "decided recently to retire from office"
    );
  END IF;
END $$;

-- --- 4. Post-verify ---------------------------------------------------------
DO $$
DECLARE
  v_office uuid;
  v_holder text;
  v_gonzalez_end date;
  v_terms int;
BEGIN
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ga'
     AND d.geo_id = '13009' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY'
     AND o.title = 'Coroner';

  SELECT p.full_name INTO v_holder
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = v_office;

  IF v_holder IS DISTINCT FROM 'Steve Chapple' THEN
    RAISE EXCEPTION 'baldwin coroner: expected Steve Chapple to hold the seat, found %', coalesce(v_holder, '(vacant)');
  END IF;

  SELECT ot.term_end INTO v_gonzalez_end
    FROM essentials.office_terms ot
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.office_id = v_office AND p.external_id = -1331017;

  IF v_gonzalez_end IS DISTINCT FROM DATE '2026-05-01' THEN
    RAISE EXCEPTION 'baldwin coroner: expected Gonzalez term_end 2026-05-01 (the sourced retirement date), found %', coalesce(v_gonzalez_end::text, 'NULL');
  END IF;

  -- Exactly two terms on this seat, and no third from a double-run.
  SELECT count(*) INTO v_terms FROM essentials.office_terms WHERE office_id = v_office;
  IF v_terms <> 2 THEN
    RAISE EXCEPTION 'baldwin coroner: expected exactly 2 term rows on this office, found %', v_terms;
  END IF;

  RAISE NOTICE 'OK: Baldwin Coroner -- Gonzalez closed 2026-05-01 (retired), Chapple seated from 2026-05 (month precision, how_started unknown)';
END $$;

COMMIT;
