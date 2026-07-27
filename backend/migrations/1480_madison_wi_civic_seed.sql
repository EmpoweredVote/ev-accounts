-- 1480_madison_wi_civic_seed.sql
--
-- Seed the Madison, WI civic layer: Mayor, all 20 Common Council alders, and the Dane County
-- Executive. Before this migration WI's only local coverage was Racine County (17 localities,
-- 95 holders); Madison and Dane County had a district shell (geo_id 55025) with ZERO offices and
-- ZERO holders, so the state's capital and largest-by-influence city was invisible in Essentials.
--
-- Structure copies the Racine template exactly (the only prior WI local seed):
--   * one LOCAL district per city holding every council seat (NOT one district per ward), and
--   * a second district, same geo_id, district_type LOCAL_EXEC, holding the mayor.
-- geo_id is not unique across district_type; Racine relies on that and so does this.
-- Dane County already exists as a COUNTY district, so the County Executive office is added to it
-- rather than creating a new district. Title matches Racine County's 'County Executive'.
--
-- SOURCES (fetched 2026-07-27)
--   Roster      https://www.cityofmadison.com/council/council-members            (live, current)
--   Cross-check https://www.cityofmadison.com/council/documents/CouncilMembersRoster.pdf
--   Election    https://www.cityofmadison.com/news/2026-04-20/common-council-welcomes-new-members-committed-to-serving-madisons-future
--   Mayor       https://www.cityofmadison.com/mayor
--   County Exec https://www.danecounty.gov/
--
-- ⚠ THE ROSTER PDF IS STALE — DO NOT RE-SEED FROM IT. It is stamped "Updated 9/28/25" and predates
-- the 2026-04-07 spring election, so it still lists District 8 as MGR Govindarajan and District 14
-- as Isadore Knox, Jr. Both seats changed hands: D8 is Ellen Zhang, D14 is Noah L. Lieberman, each
-- independently confirmed by the 2026-04-20 council news release. The PDF also has the previous
-- leadership (Vidaver President / Govindarajan VP) rather than the current Madison / Glenn.
-- The live page and the PDF agree on the other 18 districts, which is what makes this two-source.
--
-- TERM STARTS — precision is deliberate, not lazy (CLAUDE.md: don't invent dates).
--   Even districts  2026-04-21 'day'   — the news release names the April 21 swearing-in.
--   Odd districts   2025-04-01 'month' — elected April 2025; Wis. Stat. § 62.09(3) puts the
--                                        take-office day on the third Tuesday of April, which
--                                        would be 2025-04-15, but that is INFERENCE from a statute
--                                        rather than a sourced fact, so the day is not asserted.
--                                        (The rule does predict 2026-04-21 correctly.)
--   Mayor           2023-04-01 'month' — re-elected April 2023, exact day not sourced.
--   County Exec     2024-04-01 'month' — elected April 2024, exact day not sourced.
--
-- DEDUP: Dina Nina Martinez-Rutherford (D15) ALREADY EXISTS as external_id -5507104 — she is an
-- active 2026 candidate for Assembly District 76 against incumbent Francesca Hong. Her existing
-- politician row is REUSED, not duplicated. Every other name was checked first+last against
-- essentials.politicians and had no match.
--
-- external_id band -5535001..-5535022. Verified free: WI usage stops at -5530008.
--
-- Idempotent: re-running inserts nothing and re-seats nobody (seat_officeholder is idempotent).

BEGIN;

-- ---------------------------------------------------------------- districts
INSERT INTO essentials.districts (label, district_type, state, geo_id, num_officials)
SELECT 'City of Madison', 'LOCAL', 'wi', '5548000', 20
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts
    WHERE geo_id = '5548000' AND district_type = 'LOCAL'
 );

INSERT INTO essentials.districts (label, district_type, state, geo_id, num_officials)
SELECT 'City of Madison', 'LOCAL_EXEC', 'wi', '5548000', 1
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts
    WHERE geo_id = '5548000' AND district_type = 'LOCAL_EXEC'
 );

-- ---------------------------------------------------------------- politicians
-- Madison uses "Alder", not "Alderman" — that is the city's own current term, and unlike Racine's
-- title it is what appears on cityofmadison.com. Titles are per-city already, so no conflict.
WITH incoming(ext, full_name, first_name, last_name) AS (VALUES
  (-5535001, 'Satya Rhodes-Conway',          'Satya',    'Rhodes-Conway'),
  (-5535002, 'John W. Duncan',               'John',     'Duncan'),
  (-5535003, 'Will Ochowicz',                'Will',     'Ochowicz'),
  (-5535004, 'Derek Field',                  'Derek',    'Field'),
  (-5535005, 'Michael E. Verveer',           'Michael',  'Verveer'),
  (-5535006, 'Regina M. Vidaver',            'Regina',   'Vidaver'),
  (-5535007, 'Davy Mayer',                   'Davy',     'Mayer'),
  (-5535008, 'Badri Lankella',               'Badri',    'Lankella'),
  (-5535009, 'Ellen Zhang',                  'Ellen',    'Zhang'),
  (-5535010, 'Joann Pritchett',              'Joann',    'Pritchett'),
  (-5535011, 'Yannette Figueroa Cole',       'Yannette', 'Figueroa Cole'),
  (-5535012, 'Bill Tishler',                 'Bill',     'Tishler'),
  (-5535013, 'Julia Matthews',               'Julia',    'Matthews'),
  (-5535014, 'Tag Evers',                    'Tag',      'Evers'),
  (-5535015, 'Noah L. Lieberman',            'Noah',     'Lieberman'),
  (-5535016, 'Sean O''Brien',                'Sean',     'O''Brien'),
  (-5535017, 'Sabrina V. Madison',           'Sabrina',  'Madison'),
  (-5535018, 'Carmella Glenn',               'Carmella', 'Glenn'),
  (-5535019, 'John P. Guequierre',           'John',     'Guequierre'),
  (-5535020, 'Barbara Harrington-McKinney',  'Barbara',  'Harrington-McKinney'),
  (-5535021, 'Melissa Agard',                'Melissa',  'Agard')
)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, data_source, is_active, is_incumbent)
SELECT i.ext, i.full_name, i.first_name, i.last_name,
       'migration 1480 — cityofmadison.com / danecounty.gov, fetched 2026-07-27',
       'manual', true, true
  FROM incoming i
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = i.ext);

-- ---------------------------------------------------------------- offices
-- Mayor (LOCAL_EXEC)
INSERT INTO essentials.offices (district_id, title, representing_state, representing_city, seats, faces_retention_vote)
SELECT d.id, 'Mayor', 'WI', 'Madison', 1, false
  FROM essentials.districts d
 WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL_EXEC'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.offices o
      WHERE o.district_id = d.id AND o.title = 'Mayor'
   );

-- 20 alder seats (LOCAL)
INSERT INTO essentials.offices (district_id, title, representing_state, representing_city, seats, faces_retention_vote)
SELECT d.id, 'Alder, District ' || g.n, 'WI', 'Madison', 1, false
  FROM essentials.districts d
 CROSS JOIN generate_series(1, 20) AS g(n)
 WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.offices o
      WHERE o.district_id = d.id AND o.title = 'Alder, District ' || g.n
   );

-- Dane County Executive, on the EXISTING Dane County district
INSERT INTO essentials.offices (district_id, title, representing_state, seats, faces_retention_vote)
SELECT d.id, 'County Executive', 'WI', 1, false
  FROM essentials.districts d
 WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.offices o
      WHERE o.district_id = d.id AND o.title = 'County Executive'
   );

-- ---------------------------------------------------------------- seat everyone
-- Districts 1-20 mapped to their alder. D15 resolves to the PRE-EXISTING Martinez-Rutherford row
-- (-5507104), which is why the mapping is by external_id rather than by band arithmetic.
DO $$
DECLARE
  r RECORD;
  v_office uuid;
  v_pol    uuid;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ( 1, -5535002, DATE '2025-04-01', 'month'),
      ( 2, -5535003, DATE '2026-04-21', 'day'),
      ( 3, -5535004, DATE '2025-04-01', 'month'),
      ( 4, -5535005, DATE '2026-04-21', 'day'),
      ( 5, -5535006, DATE '2025-04-01', 'month'),
      ( 6, -5535007, DATE '2026-04-21', 'day'),
      ( 7, -5535008, DATE '2025-04-01', 'month'),
      ( 8, -5535009, DATE '2026-04-21', 'day'),
      ( 9, -5535010, DATE '2025-04-01', 'month'),
      (10, -5535011, DATE '2026-04-21', 'day'),
      (11, -5535012, DATE '2025-04-01', 'month'),
      (12, -5535013, DATE '2026-04-21', 'day'),
      (13, -5535014, DATE '2025-04-01', 'month'),
      (14, -5535015, DATE '2026-04-21', 'day'),
      (15, -5507104, DATE '2025-04-01', 'month'),   -- pre-existing row, see DEDUP note
      (16, -5535016, DATE '2026-04-21', 'day'),
      (17, -5535017, DATE '2025-04-01', 'month'),
      (18, -5535018, DATE '2026-04-21', 'day'),
      (19, -5535019, DATE '2025-04-01', 'month'),
      (20, -5535020, DATE '2026-04-21', 'day')
    ) AS t(district_no, ext, term_start, precision_)
  LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL'
       AND o.title = 'Alder, District ' || r.district_no;
    SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = r.ext;

    IF v_office IS NULL THEN RAISE EXCEPTION 'missing office for Madison district %', r.district_no; END IF;
    IF v_pol    IS NULL THEN RAISE EXCEPTION 'missing politician external_id % (district %)', r.ext, r.district_no; END IF;

    PERFORM essentials.seat_officeholder(
      v_office, v_pol, r.term_start,
      'migration 1480 — cityofmadison.com/council/council-members, fetched 2026-07-27',
      'elected', r.precision_
    );
  END LOOP;

  -- Mayor
  SELECT o.id INTO v_office
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL_EXEC' AND o.title = 'Mayor';
  SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = -5535001;
  IF v_office IS NULL OR v_pol IS NULL THEN RAISE EXCEPTION 'Madison mayor office/politician missing'; END IF;
  PERFORM essentials.seat_officeholder(
    v_office, v_pol, DATE '2023-04-01',
    'migration 1480 — cityofmadison.com/mayor, fetched 2026-07-27', 'elected', 'month');

  -- Dane County Executive
  SELECT o.id INTO v_office
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY' AND o.title = 'County Executive';
  SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = -5535021;
  IF v_office IS NULL OR v_pol IS NULL THEN RAISE EXCEPTION 'Dane County Exec office/politician missing'; END IF;
  PERFORM essentials.seat_officeholder(
    v_office, v_pol, DATE '2024-04-01',
    'migration 1480 — danecounty.gov, fetched 2026-07-27', 'elected', 'month');
END $$;

-- ---------------------------------------------------------------- post-verify gate
DO $$
DECLARE
  v_alders    int;
  v_seated    int;
  v_mayor     text;
  v_exec      text;
  v_dupes     int;
  v_d8        text;
  v_d14       text;
BEGIN
  SELECT count(*) INTO v_alders
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL';
  IF v_alders <> 20 THEN RAISE EXCEPTION 'expected 20 Madison alder offices, found %', v_alders; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL';
  IF v_seated <> 20 THEN RAISE EXCEPTION 'expected 20 seated Madison alders, found %', v_seated; END IF;

  SELECT p.full_name INTO v_mayor
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL_EXEC' AND o.title = 'Mayor';
  IF v_mayor IS DISTINCT FROM 'Satya Rhodes-Conway' THEN
    RAISE EXCEPTION 'Madison mayor is %, expected Satya Rhodes-Conway', coalesce(v_mayor,'NULL');
  END IF;

  SELECT p.full_name INTO v_exec
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY' AND o.title = 'County Executive';
  IF v_exec IS DISTINCT FROM 'Melissa Agard' THEN
    RAISE EXCEPTION 'Dane County Exec is %, expected Melissa Agard', coalesce(v_exec,'NULL');
  END IF;

  -- The stale-PDF trap: assert the two seats that changed hands in April 2026.
  SELECT p.full_name INTO v_d8
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL' AND o.title = 'Alder, District 8';
  IF v_d8 IS DISTINCT FROM 'Ellen Zhang' THEN
    RAISE EXCEPTION 'D8 is %, expected Ellen Zhang (the 9/28/25 PDF''s Govindarajan is STALE)', coalesce(v_d8,'NULL');
  END IF;

  SELECT p.full_name INTO v_d14
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '5548000' AND d.district_type = 'LOCAL' AND o.title = 'Alder, District 14';
  IF v_d14 IS DISTINCT FROM 'Noah L. Lieberman' THEN
    RAISE EXCEPTION 'D14 is %, expected Noah L. Lieberman (the 9/28/25 PDF''s Knox is STALE)', coalesce(v_d14,'NULL');
  END IF;

  -- No duplicate person: Martinez-Rutherford must appear exactly once in essentials.politicians.
  SELECT count(*) INTO v_dupes
    FROM essentials.politicians WHERE full_name = 'Dina Nina Martinez-Rutherford';
  IF v_dupes <> 1 THEN
    RAISE EXCEPTION 'Martinez-Rutherford appears % times — the D15 dedup failed', v_dupes;
  END IF;

  RAISE NOTICE 'OK: 20 alders seated, mayor %, Dane County Exec %', v_mayor, v_exec;
END $$;

COMMIT;
