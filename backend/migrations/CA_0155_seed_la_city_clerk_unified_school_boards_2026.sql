-- CA_0155_seed_la_city_clerk_unified_school_boards_2026.sql
-- Seed the Nov 3 2026 governing-board contests of the three LA-County UNIFIED school districts whose
-- candidates file with a CITY CLERK instead of the County Registrar-Recorder, so any address in one
-- of them returns its school-board contest. This closes the gap left by CA_0142 (built from the
-- RR/CC certified list, lavote.gov/Apps/CandidateList/Index?id=4348, which OMITS these districts) and
-- flagged "NOT DONE HERE, AND OWED" in CA_0153.
--
--   Santa Monica-Malibu Unified  at large, 4 of 7 seats  5 candidates  3 incumbents
--   Pasadena Unified             Districts 1, 3, 5, 7    7 candidates  3 incumbents
--   Inglewood Unified            Trustee Areas 1, 2, 3   6 candidates  2 incumbents
--
-- SOURCES (every candidate comes from the city clerk's own qualified-candidate list; read 2026-09-22):
--   * SANTA MONICA-MALIBU -- City of Santa Monica City Clerk, "General Election 2026" candidate list,
--     Candidate Type "School Board 4-year": santamonica.gov/elections/2026-11-02/general-election-2026 ;
--     ballot designations from each candidate's page santamonica.gov/elections/2026-11-03/candidates/<name>.
--     Laurie Lieberman ("School Board Vice-President"), Stacy Rouse ("Boardmember/Conflict Specialist")
--     and Alicia Mignano ("School Board President") are sitting members and current DB holders.
--     Richard Tahvildaran-Jesswein, the fourth member whose term ends 12/2026, did not file -> the
--     race has 3 incumbents for 4 seats. SMMUSD still elects at large (the list names no areas);
--     Malibu voters vote in it too (Rouse is a Malibu resident), and the TIGER polygon covers both cities.
--   * PASADENA -- City of Pasadena City Clerk, "Qualified Candidates and Ballot Designations (In Ballot
--     Order Based on Random Drawing by the Secretary of State)", PUSD Board of Education Districts 1, 3, 5
--     and 7: cityofpasadena.net/city-clerk/wp-content/uploads/sites/21/2026-General-Election-PUSD-Qualified-Candidates-EN.pdf
--     (seats per the City's Notice of Election: "Geographic Sub-Districts 1, 3, 5, and 7", four-year
--     terms). Incumbents Kimberly Kenne (D1), Michelle Richardson Bailey (D3) and Patrice Marshall
--     McKenzie (D5, unopposed) hold the seat in the DB. D7 is open: Yarma Velázquez Vargas did not file.
--   * INGLEWOOD -- City of Inglewood City Clerk, "Candidate Filing Log 2026", November 3 2026 General
--     Municipal Election, updated 08/21/2026 (after the extended filing period), column Qualified = YES:
--     cityofinglewood.org/DocumentCenter/View/22121/November-3-2026-General-Municipal-Election-72326
--     (seats per cityofinglewood.org/440/Elections: "Inglewood Unified School Board Member Numbers 1, 2
--     and 3" are held with Council Districts 1 and 2). Incumbents Joyce Randall (TA1) and Brandon Myers
--     (TA3) hold the seat in the DB; the district's board page lists both "Term Expires: 2026". TA2 is
--     open: Carliss McGhee did not file. The log gives no ballot designations, so none is stored.
--     "Yaritza A Gonzalez" on the log is written "Yaritza A. Gonzalez".
--   Names are the clerk's ballot names. first_name/last_name follow the linked holder row where one
--   exists (Marshall McKenzie, Bailey).
--
-- OFFICE BINDING.
--   * SMMUSD: the district holds 7 generic 'Board Member' offices on ONE whole-district SCHOOL row
--     (TIGER unified polygon 0635700, mtfcc G5420). The 4-seat at-large race binds to the lowest-id one
--     purely for geography -- the CA_0142 at-large pattern. No new office.
--   * Pasadena / Inglewood: CA_0153 split each board into X0002 SCHOOL sub-districts
--     ('0629940-ta-1'..'-7', '0618390-ta-1'..'-5'), one office each, each with its sitting member. Each
--     race binds to the office on its own sub-district. No new office.
--
-- INCUMBENTS are linked to the politician row that essentials.office_current_holder names for their
-- seat (the gate re-checks this); every other candidate is left unlinked. Not linked on purpose:
-- 'Cheryl Williams' (99d5d0e7..., a Tarrant County TX seed -- a different person) and the two inactive
-- 'LESHNER FOR SCHOOL BOARD 2026' NetFile committee rows (a committee, not a person).
-- 🔴 NOT FIXED HERE: a second, term-less row 'Patrice Marshall Mckenzie' (87ea3e5b-cf9e-4268-8b69-864aedf78b21)
-- duplicates the D5 holder (2518c7a6-...). The race links the holder; the duplicate is left for a dedup pass.
--
-- RACES go on '2026 LA County General' (d91a20ce-557e-4615-a31b-5b2b3df2ed14), the election every
-- CA_0142/0144-0152 school race uses; nonpartisan -> primary_party NULL; party is never stored on
-- candidates. Uncontested seats are included (decision 2026-09-22).
--
-- IDEMPOTENT: races on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

-- ─── 0. Pre-flight: every binding target exists and is unambiguous ──────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.districts d
   WHERE d.geo_id = '0635700' AND d.district_type = 'SCHOOL' AND d.mtfcc = 'G5420';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 SMMUSD SCHOOL/G5420 district row, got %', n; END IF;

  SELECT count(*) INTO n FROM (
    SELECT v.geo_id FROM (VALUES ('0629940-ta-1'), ('0629940-ta-3'), ('0629940-ta-5'), ('0629940-ta-7'),
                                 ('0618390-ta-1'), ('0618390-ta-2'), ('0618390-ta-3')) AS v(geo_id)
      LEFT JOIN essentials.districts d ON d.geo_id = v.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = 'X0002'
      LEFT JOIN essentials.offices o ON o.district_id = d.id
     GROUP BY v.geo_id HAVING count(o.id) <> 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % sub-district(s) without exactly one office', n; END IF;
END $$;

-- ─── 1. Races ───────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid, t.office_id, t.position_name, NULL, t.seats
  FROM (
    SELECT v.position_name, v.seats,
           (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
             WHERE d.geo_id = v.geo_id AND d.district_type = 'SCHOOL' AND d.mtfcc = v.mtfcc
             ORDER BY o.id LIMIT 1) AS office_id
      FROM (VALUES
    ('0635700',      'G5420', 'Santa Monica-Malibu Unified School Board', 4),
    ('0629940-ta-1', 'X0002', 'Pasadena Unified School Board - District 1', 1),
    ('0629940-ta-3', 'X0002', 'Pasadena Unified School Board - District 3', 1),
    ('0629940-ta-5', 'X0002', 'Pasadena Unified School Board - District 5', 1),
    ('0629940-ta-7', 'X0002', 'Pasadena Unified School Board - District 7', 1),
    ('0618390-ta-1', 'X0002', 'Inglewood Unified School Board - Trustee Area 1', 1),
    ('0618390-ta-2', 'X0002', 'Inglewood Unified School Board - Trustee Area 2', 1),
    ('0618390-ta-3', 'X0002', 'Inglewood Unified School Board - Trustee Area 3', 1)
      ) AS v(geo_id, mtfcc, position_name, seats)
  ) t
 WHERE t.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.races r
                    WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = t.position_name);

-- ─── 2. Candidates ──────────────────────────────────────────────────────────────────────
INSERT INTO essentials.race_candidates
       (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
        occupational_designation, source)
SELECT r.id, v.politician_id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       v.designation,
       CASE v.src
         WHEN 'sm' THEN 'City of Santa Monica City Clerk, General Election 2026 (Nov 3 2026) candidate list, School Board 4-year (santamonica.gov/elections/2026-11-02/general-election-2026; ballot designation from santamonica.gov/elections/2026-11-03/candidates/). Retrieved 2026-09-22.'
         WHEN 'pas' THEN 'City of Pasadena City Clerk, Qualified Candidates and Ballot Designations, PUSD Board of Education Nov 3 2026 General Election (cityofpasadena.net/city-clerk/wp-content/uploads/sites/21/2026-General-Election-PUSD-Qualified-Candidates-EN.pdf). Retrieved 2026-09-22.'
         WHEN 'ing' THEN 'City of Inglewood City Clerk, Candidate Filing Log 2026, November 3 2026 General Municipal Election, updated 08/21/2026, Qualified = YES (cityofinglewood.org/DocumentCenter/View/22121). Retrieved 2026-09-22.'
       END
  FROM (VALUES
    ('Santa Monica-Malibu Unified School Board', 'sm', 'Laurie Lieberman', 'Laurie', 'Lieberman', '0952f897-7414-4ad3-af88-022de9e4971c'::uuid, true, 'School Board Vice-President'),
    ('Santa Monica-Malibu Unified School Board', 'sm', 'Harry Leshner', 'Harry', 'Leshner', NULL::uuid, false, 'Executive/Education Advisor'),
    ('Santa Monica-Malibu Unified School Board', 'sm', 'Robbie Staenberg', 'Robbie', 'Staenberg', NULL::uuid, false, 'Teacher/Legislative Advisor'),
    ('Santa Monica-Malibu Unified School Board', 'sm', 'Stacy Rouse', 'Stacy', 'Rouse', '3cf22d9d-f6fd-404c-b6ba-a1e4b7fb830d'::uuid, true, 'Boardmember/Conflict Specialist'),
    ('Santa Monica-Malibu Unified School Board', 'sm', 'Alicia Mignano', 'Alicia', 'Mignano', '665372e8-49fe-4c6e-9930-fca6ed3430f0'::uuid, true, 'School Board President'),
    ('Pasadena Unified School Board - District 1', 'pas', 'Felita Kealing', 'Felita', 'Kealing', NULL::uuid, false, 'School Student Recruiter'),
    ('Pasadena Unified School Board - District 1', 'pas', 'Kimberly Kenne', 'Kimberly', 'Kenne', '820d81c8-4f1a-4a05-a739-98e1c1e35c56'::uuid, true, 'Board of Education Member, Pasadena Unified School District'),
    ('Pasadena Unified School Board - District 3', 'pas', 'Michelle Richardson Bailey', 'Michelle', 'Bailey', '5cbf44d9-91de-4fc9-b5f0-76e2ae236914'::uuid, true, 'Board Member, Pasadena Unified School District'),
    ('Pasadena Unified School Board - District 3', 'pas', 'Veronica Elias', 'Veronica', 'Elias', NULL::uuid, false, 'Educator/Parent'),
    ('Pasadena Unified School Board - District 5', 'pas', 'Patrice Marshall McKenzie', 'Patrice', 'Marshall McKenzie', '2518c7a6-f526-4df2-8364-ded34b122f21'::uuid, true, 'PUSD School Board Member'),
    ('Pasadena Unified School Board - District 7', 'pas', 'Dennis J. McNamara', 'Dennis', 'McNamara', NULL::uuid, false, 'Retired Finance Executive'),
    ('Pasadena Unified School Board - District 7', 'pas', 'Cynthia Torres', 'Cynthia', 'Torres', NULL::uuid, false, 'Education Services Consultant'),
    ('Inglewood Unified School Board - Trustee Area 1', 'ing', 'Joyce Randall', 'Joyce', 'Randall', '6aae60e6-7739-42b5-adbc-341bc1f5257e'::uuid, true, NULL),
    ('Inglewood Unified School Board - Trustee Area 1', 'ing', 'Cheryl Williams', 'Cheryl', 'Williams', NULL::uuid, false, NULL),
    ('Inglewood Unified School Board - Trustee Area 2', 'ing', 'Joe W. Bowers Jr.', 'Joe', 'Bowers', NULL::uuid, false, NULL),
    ('Inglewood Unified School Board - Trustee Area 2', 'ing', 'Shelby Richardson', 'Shelby', 'Richardson', NULL::uuid, false, NULL),
    ('Inglewood Unified School Board - Trustee Area 3', 'ing', 'Brandon Myers', 'Brandon', 'Myers', 'a0b7d1f3-6c2e-4d59-9a7e-3b1c8f4e2d61'::uuid, true, NULL),
    ('Inglewood Unified School Board - Trustee Area 3', 'ing', 'Yaritza A. Gonzalez', 'Yaritza', 'Gonzalez', NULL::uuid, false, NULL)
  ) AS v(position_name, src, full_name, first_name, last_name, politician_id, is_incumbent, designation)
  JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.position_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name));

-- ─── 3. Post-verify gate ────────────────────────────────────────────────────────────────
DO $$
DECLARE
  pos text[] := ARRAY['Santa Monica-Malibu Unified School Board',
                      'Pasadena Unified School Board - District 1', 'Pasadena Unified School Board - District 3',
                      'Pasadena Unified School Board - District 5', 'Pasadena Unified School Board - District 7',
                      'Inglewood Unified School Board - Trustee Area 1', 'Inglewood Unified School Board - Trustee Area 2',
                      'Inglewood Unified School Board - Trustee Area 3'];
  n_races int; n_cands int; n_null int; n_party int; n_badbind int; n_badcount int; n_inc int;
  n_badinc int; n_extralink int; n_overinc int; n_unreach int; n_leak int;
BEGIN
  SELECT count(*) INTO n_races FROM essentials.races r
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) INTO n_cands FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);
  SELECT count(*) FILTER (WHERE r.office_id IS NULL), count(*) FILTER (WHERE r.primary_party IS NOT NULL)
    INTO n_null, n_party FROM essentials.races r
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);

  -- each race is bound to the office on the district it names (and SMMUSD to its lowest-id office)
  SELECT count(*) INTO n_badbind FROM (VALUES
      ('Santa Monica-Malibu Unified School Board', '0635700', 4),
      ('Pasadena Unified School Board - District 1', '0629940-ta-1', 1), ('Pasadena Unified School Board - District 3', '0629940-ta-3', 1),
      ('Pasadena Unified School Board - District 5', '0629940-ta-5', 1), ('Pasadena Unified School Board - District 7', '0629940-ta-7', 1),
      ('Inglewood Unified School Board - Trustee Area 1', '0618390-ta-1', 1), ('Inglewood Unified School Board - Trustee Area 2', '0618390-ta-2', 1),
      ('Inglewood Unified School Board - Trustee Area 3', '0618390-ta-3', 1)) AS v(position_name, geo_id, seats)
    LEFT JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.position_name
    LEFT JOIN essentials.offices o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id IS DISTINCT FROM v.geo_id OR d.district_type IS DISTINCT FROM 'SCHOOL' OR r.seats IS DISTINCT FROM v.seats
      OR o.id IS DISTINCT FROM (SELECT o2.id FROM essentials.offices o2 WHERE o2.district_id = d.id ORDER BY o2.id LIMIT 1);

  -- each race carries exactly the clerk's field
  SELECT count(*) INTO n_badcount FROM (VALUES
      ('Santa Monica-Malibu Unified School Board', 5, 3),
      ('Pasadena Unified School Board - District 1', 2, 1), ('Pasadena Unified School Board - District 3', 2, 1),
      ('Pasadena Unified School Board - District 5', 1, 1), ('Pasadena Unified School Board - District 7', 2, 0),
      ('Inglewood Unified School Board - Trustee Area 1', 2, 1), ('Inglewood Unified School Board - Trustee Area 2', 2, 0),
      ('Inglewood Unified School Board - Trustee Area 3', 2, 1)) AS v(position_name, n_cand, n_inc)
    JOIN essentials.races r ON r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = v.position_name
   WHERE (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) <> v.n_cand
      OR (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) <> v.n_inc;

  -- every incumbent is linked to the CURRENT holder of a seat in that race's own district: the race's
  -- own office for a sub-district race; any SMMUSD office for the at-large race
  SELECT count(*) FILTER (WHERE rc.is_incumbent),
         count(*) FILTER (WHERE rc.is_incumbent AND NOT EXISTS (
           SELECT 1 FROM essentials.offices o2 JOIN essentials.office_current_holder och ON och.office_id = o2.id
            WHERE och.politician_id = rc.politician_id
              AND o2.district_id = (SELECT o.district_id FROM essentials.offices o WHERE o.id = r.office_id)
              AND (r.seats > 1 OR o2.id = r.office_id))),
         count(*) FILTER (WHERE NOT rc.is_incumbent AND rc.politician_id IS NOT NULL)
    INTO n_inc, n_badinc, n_extralink
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos);

  SELECT count(*) INTO n_overinc FROM essentials.races r
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.is_incumbent) > r.seats;

  -- END TO END: an interior point of each race's own polygon reaches that race
  SELECT count(*) INTO n_unreach FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.geofence_boundaries me ON me.geo_id = d.geo_id AND me.mtfcc = d.mtfcc
   WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos)
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries gb
        WHERE gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR gb.mtfcc = d.mtfcc)
          AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry)));

  -- NO CROSS-LEAK: an interior point of every Pasadena / Inglewood area reaches exactly one of this
  -- file's area races if the area is up in 2026 (P1/3/5/7, I1/2/3), and none if it is not (P2/4/6, I4/5)
  SELECT count(*) INTO n_leak FROM (
    SELECT a.geo_id, a.up,
           (SELECT count(*) FROM essentials.races r
              JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.districts d ON d.id = o.district_id
              JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR gb.mtfcc = d.mtfcc)
             WHERE r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'::uuid AND r.position_name = ANY (pos) AND r.seats = 1
               AND public.ST_Covers(gb.geometry, public.ST_PointOnSurface(me.geometry))) AS hits
      FROM (VALUES ('0629940-ta-1', 1), ('0629940-ta-2', 0), ('0629940-ta-3', 1), ('0629940-ta-4', 0),
                   ('0629940-ta-5', 1), ('0629940-ta-6', 0), ('0629940-ta-7', 1),
                   ('0618390-ta-1', 1), ('0618390-ta-2', 1), ('0618390-ta-3', 1), ('0618390-ta-4', 0),
                   ('0618390-ta-5', 0)) AS a(geo_id, up)
      JOIN essentials.geofence_boundaries me ON me.geo_id = a.geo_id AND me.mtfcc = 'X0002') x
   WHERE x.hits <> x.up;

  IF n_races <> 8 THEN RAISE EXCEPTION 'expected 8 races, got %', n_races; END IF;
  IF n_cands <> 18 THEN RAISE EXCEPTION 'expected 18 candidates, got %', n_cands; END IF;
  IF n_null <> 0 OR n_party <> 0 THEN RAISE EXCEPTION 'office-less (%) or partisan (%) race', n_null, n_party; END IF;
  IF n_badbind <> 0 THEN RAISE EXCEPTION '% race(s) not bound to the expected office / seat count', n_badbind; END IF;
  IF n_badcount <> 0 THEN RAISE EXCEPTION '% race(s) whose candidate or incumbent count differs from the clerk list', n_badcount; END IF;
  IF n_inc <> 8 THEN RAISE EXCEPTION 'expected 8 incumbents, got %', n_inc; END IF;
  IF n_badinc <> 0 THEN RAISE EXCEPTION '% incumbent(s) not linked to the current holder of their seat', n_badinc; END IF;
  IF n_extralink <> 0 THEN RAISE EXCEPTION '% non-incumbent(s) unexpectedly linked to a politician', n_extralink; END IF;
  IF n_overinc <> 0 THEN RAISE EXCEPTION '% race(s) with more incumbents than seats', n_overinc; END IF;
  IF n_unreach <> 0 THEN RAISE EXCEPTION '% race(s) not reached from inside their own district', n_unreach; END IF;
  IF n_leak <> 0 THEN RAISE EXCEPTION '% area(s) reach the wrong number of area races', n_leak; END IF;
  RAISE NOTICE 'CA_0155 applied: % races, % candidates, % incumbents linked', n_races, n_cands, n_inc;
END $$;

COMMIT;
