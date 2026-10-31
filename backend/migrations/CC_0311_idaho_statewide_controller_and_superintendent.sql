-- CC_0311_idaho_statewide_controller_and_superintendent.sql
-- Idaho statewide executive — add the two elected offices production was missing, and seat them.
--
-- Record: backend/data/seed-id-legislature-2026/ROSTERS.md (§ Sources, row 6).
--
-- ═══ THE COMPLETE LIST COMES FROM THE CONSTITUTION, NOT FROM A ROSTER PAGE ═══
--
-- Idaho Const. Art. IV §1, read from the Legislature's own text (const_art4.html in the wave
-- directory): "The executive department shall consist of a governor, lieutenant governor,
-- secretary of state, STATE CONTROLLER, state treasurer, attorney general and SUPERINTENDENT OF
-- PUBLIC INSTRUCTION, each of whom shall hold his office for four years BEGINNING ON THE FIRST
-- MONDAY IN JANUARY next after his election".
--
-- That is SEVEN offices. Production held FIVE — Governor, Lieutenant Governor, Secretary of
-- State, Attorney General and Treasurer. The State Controller and the Superintendent of Public
-- Instruction were absent entirely: no chamber, no district, no office, no holder, and nothing
-- anywhere errored. This migration adds both, matching the shape the existing five already use
-- (one chamber and one STATE_EXEC district per office).
--
-- 🟢 THE CONSTITUTIONAL SEATING RULE IS CONFIRMED BY THE DATA RATHER THAN ASSUMED. "First Monday
--    in January next after his election" predicts 2023-01-02 for everyone elected in 2022, and
--    Ballotpedia independently gives exactly 2023-01-02 for Labrador, McGrane, Bedke and
--    Critchfield. The rule and the four observations agree.
--
-- ⚠ `districts.mtfcc` IS THE EMPTY STRING FOR THESE ROWS, NOT NULL. That is what the existing
--   five Idaho STATE_EXEC districts carry, and `districts.state` is 'ID' in upper case on them.
--   Matching the neighbours matters more than matching a convention from elsewhere: a NULL mtfcc
--   here would sort these two rows differently from their five siblings in every mtfcc predicate.
--
-- ⚠ PARTY IS WRITTEN ON THESE TWO, DELIBERATELY, AND IT IS THE OPPOSITE OF CC_0310's RULE.
--   The five existing Idaho statewide rows all carry 'Republican'. Writing these two with a NULL
--   party would leave one Idaho executive department with five parties and two blanks, which
--   reads as missing data rather than as a convention. The legislature (CC_0310) keeps party
--   NULL because party belongs on `races.primary_party`; aligning the statewide rows with that
--   convention means rewriting all seven together, which is its own decision and its own
--   migration. This file matches its neighbours and changes nothing that already exists.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_gov int; v_exec int; v_exists int; v_people int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'State of Idaho' AND geo_id = '16' AND mtfcc = 'G4000';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'CC_0311 pre-flight: expected exactly 1 "State of Idaho" government, found %', v_gov;
  END IF;

  SELECT count(*) INTO v_exec FROM essentials.districts d
   WHERE d.district_type = 'STATE_EXEC' AND d.geo_id = '16' AND upper(d.state) = 'ID';
  IF v_exec <> 5 THEN
    RAISE EXCEPTION 'CC_0311 pre-flight: expected the 5 existing Idaho STATE_EXEC districts, found % — '
                    'if this is already 7 the migration has run', v_exec;
  END IF;

  SELECT count(*) INTO v_exists FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho'
     AND c.name IN ('State Controller', 'Superintendent of Public Instruction');
  IF v_exists <> 0 THEN
    RAISE EXCEPTION 'CC_0311 pre-flight: % of the two chambers already exist — read them first', v_exists;
  END IF;

  -- Identity scan, both names, against every active politician.
  SELECT count(*) INTO v_people FROM essentials.politicians p
   WHERE p.is_active AND (lower(btrim(p.last_name)), lower(btrim(p.first_name))) IN
     (('woolf','brandon'), ('critchfield','debbie'));
  IF v_people <> 0 THEN
    RAISE EXCEPTION 'CC_0311 pre-flight: % active politician(s) already match Brandon Woolf or '
                    'Debbie Critchfield on first+last name — read those rows before inserting', v_people;
  END IF;
END $$;

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. The five existing
--    Idaho statewide chambers carry name_formal '<Office> of Idaho'; these two match that.
INSERT INTO essentials.chambers (government_id, name, name_formal, website_url)
SELECT g.id, v.name, v.formal, v.url
FROM essentials.governments g
JOIN (VALUES
  ('State Controller', 'State Controller of Idaho', 'https://www.sco.idaho.gov/'),
  ('Superintendent of Public Instruction', 'Superintendent of Public Instruction of Idaho', 'https://www.sde.idaho.gov/')
) AS v(name, formal, url) ON true
WHERE g.name = 'State of Idaho'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
-- Statewide, so geo_id '16' and the EMPTY-STRING mtfcc the five siblings already use.
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT '16', v.label, 'STATE_EXEC', 'ID', ''
FROM (VALUES ('Idaho State Controller'), ('Idaho Superintendent of Public Instruction')) AS v(label)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.label = v.label AND d.district_type = 'STATE_EXEC' AND d.geo_id = '16');

-- ── Offices ───────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_vacant, voting_powers,
   is_appointed_position, description)
SELECT c.id, d.id, v.title, 'ID', false, 'full', false, v.descr
FROM (VALUES
  ('State Controller', 'Idaho State Controller', 'State Controller',
   'One of the seven officers of Idaho''s executive department (Const. Art. IV sec. 1), elected '
   || 'statewide to a four-year term beginning on the first Monday in January after the election. '
   || 'The Controller is the state''s chief fiscal officer: it audits claims against the state, '
   || 'issues every state warrant, and keeps the state''s accounting and payroll systems.'),
  ('Superintendent of Public Instruction', 'Idaho Superintendent of Public Instruction',
   'Superintendent of Public Instruction',
   'One of the seven officers of Idaho''s executive department (Const. Art. IV sec. 1), elected '
   || 'statewide to a four-year term beginning on the first Monday in January after the election. '
   || 'The Superintendent leads the State Department of Education, executes the policies of the '
   || 'State Board of Education, and administers public school funding and accountability.')
) AS v(chamber, dlabel, title, descr)
JOIN essentials.governments g ON g.name = 'State of Idaho'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber
JOIN essentials.districts d ON d.label = v.dlabel AND d.district_type = 'STATE_EXEC' AND d.geo_id = '16'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title);

-- ── People and seating ────────────────────────────────────────────────────────
CREATE TEMP TABLE id_exec(
  title       text PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  party       text NOT NULL,
  term_start  date NOT NULL,
  precision   text NOT NULL,
  how_started text NOT NULL,
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO id_exec(title, full_name, first_name, last_name, party, term_start, precision, how_started, source) VALUES
  ('State Controller', 'Brandon D. Woolf', 'Brandon', 'Woolf', 'Republican', DATE '2012-10-15', 'day', 'appointed',
   'ballotpedia.org/Ada_County,_Idaho officeholder table, read 2026-10-30 (CC_0311): Idaho Controller, '
   || 'Brandon Woolf, Republican, date assumed office 15 October 2012. A mid-term arrival rather than a '
   || 'first-Monday-in-January one, so how_started is appointed; term_start is the start of CONTINUOUS '
   || 'occupancy, not of the current term, so re-election has not moved it.'),
  ('Superintendent of Public Instruction', 'Debbie Critchfield', 'Debbie', 'Critchfield', 'Republican', DATE '2023-01-02', 'day', 'elected',
   'ballotpedia.org/Ada_County,_Idaho officeholder table, read 2026-10-30 (CC_0311): Idaho Superintendent '
   || 'of Public Instruction, Debbie Critchfield, Republican, date assumed office 2 January 2023 — the '
   || 'first Monday in January after the 2022 election, which is the rule Idaho Const. Art. IV sec. 1 '
   || 'states and which Labrador, McGrane and Bedke independently match.');

UPDATE id_exec r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'State of Idaho' AND o.title = r.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM id_exec WHERE office_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0311: % row(s) did not resolve to an office', n; END IF;
  SELECT count(*) INTO n FROM id_exec r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0311: % office(s) already carry a term', n; END IF;
END $$;

-- 🔴 is_incumbent EXPLICITLY true. It defaults to false, and a seated person inserted without it
--    is HIDDEN from address search; check:occupancy fails an INSERT that omits it.
INSERT INTO essentials.politicians (full_name, first_name, last_name, party, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, r.party, true, true, r.source
  FROM id_exec r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE id_exec r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE p.is_active
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM id_exec ORDER BY title LOOP
    IF r.politician_id IS NULL THEN RAISE EXCEPTION 'CC_0311: % did not resolve to a person', r.title; END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, r.how_started, r.source);
    n := n + 1;
  END LOOP;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0311: expected 2 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE v_exec int; v_held int; v_slug int; v_notinc int; v_termend int;
BEGIN
  -- The executive department is now complete at SEVEN, which is the constitutional number.
  SELECT count(och.politician_id) INTO v_held
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'State of Idaho' AND d.district_type = 'STATE_EXEC';
  SELECT count(*) INTO v_exec
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Idaho' AND d.district_type = 'STATE_EXEC';
  IF v_exec <> 7 OR v_held <> 7 THEN
    RAISE EXCEPTION 'CC_0311 gate: Idaho Const. Art. IV sec. 1 names SEVEN executive officers; '
                    'found % office(s) and % held', v_exec, v_held;
  END IF;

  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Idaho'
     AND c.name IN ('State Controller','Superintendent of Public Instruction')
     AND coalesce(btrim(c.slug),'') = '';
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0311 gate: % new chamber(s) generated an EMPTY slug — name_formal was not set', v_slug;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE source LIKE '%(CC_0311)%' AND (NOT is_incumbent OR NOT is_active);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'CC_0311 gate: % new officeholder(s) are not active incumbents — they would be '
                    'HIDDEN from address search', v_notinc;
  END IF;

  SELECT count(*) INTO v_termend FROM essentials.office_terms t
    JOIN id_exec r ON r.office_id = t.office_id
   WHERE t.term_end IS NOT NULL;
  IF v_termend <> 0 THEN
    RAISE EXCEPTION 'CC_0311 gate: % term(s) carry a term_end; a future term_end makes a seat '
                    'silently self-vacate', v_termend;
  END IF;

  RAISE NOTICE 'CC_0311 OK: Idaho executive department complete at 7 of 7 offices, 7 held.';
END $$;
