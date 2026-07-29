-- 1491_dane_county_government.sql
-- Dane County government: 3 chambers, 7 countywide elected officials (1 adopted), 37 County
-- Board supervisors, 17 Circuit Court judges. STRUCTURAL. Idempotent.
--
-- PRECONDITIONS:
--   1. The 37 supervisor-district polygons must be loaded first --
--        npx tsx scripts/import-dane-supervisor-districts.ts
--      That creates geofence_boundaries + districts rows with mtfcc='X-DC-SUP',
--      geo_id='55025-sup-d{1..37}' from the WI LTSB "County Supervisory Districts (Current)"
--      layer (verified 37 features for Dane, refreshed 2026-07-14). Without it the 37
--      supervisor offices insert ZERO rows.
--   2. Migration 1480 (Madison seed) already created the County Executive office on the
--      pre-existing Dane County COUNTY district (geo_id 55025, G4020) and seated Melissa
--      Agard -- with NO chamber. Step 3 below ADOPTS that office into the new Countywide
--      chamber instead of inserting a duplicate. The (district, chamber, title) guard on
--      step 5 would NOT see the chamber-less row, hence the explicit adopt-first ordering.
--
-- WHY: Madison city is fully covered (1480) but Dane County itself had no government row --
--   a Madison address returned city + state + federal officials and NOTHING county. Treasury
--   Tracker carries Dane County as a budget entity and tethers once this exists.
--
-- SOURCES (all fetched 2026-07-29; the roster was independently re-fetched and re-verified
-- by the orchestrating session before this migration was written):
--   - 37 supervisors: board.danecounty.gov/supervisors (post-April-2026 roster: contains the
--     D1 fill, 7 member changes vs the 2024-2026 directory, 04-2026 image stamps, and the
--     current leadership slate). Cross-checked against the County Clerk's 2025-2026 directory
--     PDF (clerk.danecounty.gov/documents/pdf/directory.pdf) for the 30 returning members;
--     the 7 NEW members (D1 Barushok, D9 Trucios, D15 Larson, D16 Obieze, D20 Brandmeier,
--     D22 Lewis, D33 Dantzler) are single-source from the county roster page.
--   - Board Chair Patrick Miles (D34), per board.danecounty.gov homepage. Leadership in the
--     directory PDF is the PRIOR session -- do not re-seed leadership from it.
--   - 6 countywide officers: each office's own danecounty.gov page + directory PDF p.14.
--     Sheriff site prints 'Kalvin D. Barrett' (directory: 'Kalvin Barrett'); DA page prints
--     'Ismael R. Ozanne'. Fuller printed forms used.
--   - 17 circuit judges: courts.danecounty.gov/Judges (branch numbers) + wicourts.gov
--     circuit-judges list (names; marks Julie Genovese as Chief Judge of Judicial
--     Administrative District V). Branch numbers are single-source from the county page for
--     branches 1, 2, 8 (post-directory changes); the directory corroborates the rest.
--     'Diane Schlipper' spelling per county + directory (wicourts prints 'Dianne').
--
-- TERM STARTS -- precision is deliberate, not lazy (CLAUDE.md: don't invent dates).
--   Supervisors  2026-04-01 'month' -- all 37 seats were up in the April 2026 spring
--                election; the prior session's terms expired 2026-04-20 (directory PDF).
--                The exact swearing-in day is not stated by a fetched source, so month.
--   DA Ozanne    2010-08-01 'month' -- da.danecounty.gov: "has served since August 2010".
--   Other 5 officers + all 17 judges: term_start NULL, start_precision 'unknown' via direct
--                office_terms insert (the migration-1459 backfill precedent). Their pages
--                publish term EXPIRATIONS (directory p.14, pp.11-13), not starts, and
--                seat_officeholder correctly refuses NULL -- the direct insert records the
--                occupancy without asserting a start we cannot source.
--   Judges B1 Jones and B8 Hilton are 2025 Evers appointees who stood in the April 2026
--   election (Jones won 55.7%; Hilton unopposed); both already sitting, new 6-year terms
--   begin 2026-08-01. Seeded as sitting officeholders; is_appointed stays false because each
--   has now won election to the seat (mirrors Racine 1454's treatment of McClendon).
--
-- CHAMBER SHAPE: clones Racine County exactly (1446 + 1454): County Board + one Countywide
--   Elected Officials bucket + Circuit Court. Wisconsin county row offices are the same
--   seven; like Racine, Dane has an appointed MEDICAL EXAMINER, not an elected Coroner.
--
-- CRITICAL (office guard divergence, mirrors 1446): the 37 supervisor offices each own a
--   distinct district, so (district_id, chamber_id) guards them. The countywide offices ALL
--   share the SAME district (55025 G4020) and chamber, so they are guarded on
--   (district_id, chamber_id, title). Titles are unique within the seven.
--
-- CRITICAL (two COUNTY tiers share state='wi'): districts holds both G4020 county polygons
--   AND X-DC-SUP supervisor districts as district_type='COUNTY'. Every join below pins mtfcc
--   as well as district_type.
--
-- ANTIPARTISAN + data honesty: politicians.party stays NULL for all 60. Supervisors and the
--   judges are nonpartisan spring offices; the November row offices' party is not published
--   on the sourced pages. judge_details.election_type='nonpartisan' records the bench
--   positively; Genovese alone gets court_role='Chief Judge' (administrative designation by
--   the Supreme Court, not a separate elected office -- Racine 1454 precedent).
--
-- external_id bands (verified free 2026-07-29; WI synthetic usage previously stopped at
--   -5535022): officers -5536001..-5536006, supervisors -5536101..-5536137 (100+district),
--   judges -5536201..-5536217 (200+branch).
--
-- NO RACES here. County offices file with the County Clerk; the April 2026 election has
--   passed and the November 2026 county field is not in any parsed source.
BEGIN;

-- ── 1. Government row (no unique constraint on geo_id -> NOT EXISTS guard) ──
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Dane County, Wisconsin, US', 'County', 'WI', NULL, '55025'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US'
);

-- ── 2. Three chambers (chambers.slug is GENERATED ALWAYS -- never in the column list) ──
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'County Board', 'Dane County Board of Supervisors',
       (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US'), 37
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'County Board'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Countywide Elected Officials',
       'Dane County Countywide Elected Officials',
       (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US'), 7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Countywide Elected Officials'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, term_length)
SELECT gen_random_uuid(), 'Circuit Court', 'Dane County Circuit Court',
       (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US'), 17, '6 years'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Circuit Court'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
);

-- ── 3. ADOPT the 1480-seeded County Executive office into the Countywide chamber ──
UPDATE essentials.offices o
   SET chamber_id = c.id
  FROM essentials.districts d, essentials.chambers c
 WHERE o.district_id = d.id
   AND d.geo_id = '55025' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'
   AND o.title = 'County Executive'
   AND o.chamber_id IS NULL
   AND c.name = 'Countywide Elected Officials'
   AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US');

-- ── 4. JUDICIAL district on the existing Dane County polygon ──
--   essentialsService pairs gb.mtfcc='G4020' with district_type IN ('COUNTY','JUDICIAL'),
--   so no new geometry is needed (Racine 1454 precedent).
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials, is_judicial)
SELECT '55025', 'Dane County Circuit Court', 'JUDICIAL', 'wi', 'G4020', 17, true
WHERE EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '55025' AND mtfcc = 'G4020'
) AND NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '55025' AND district_type = 'JUDICIAL' AND mtfcc = 'G4020'
);

-- ── 5. 60 politicians (party intentionally NULL -- see header) ──
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, source, data_source,
   is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name,
       'migration 1491 — board.danecounty.gov / danecounty.gov offices / courts.danecounty.gov + wicourts.gov, fetched 2026-07-29',
       'manual', true, true, false, false
FROM (VALUES
    -- countywide constitutional officers (County Executive Melissa Agard exists from 1480)
    (-5536001::bigint, 'Scott McDonell'::text,      'Scott'::text,     'McDonell'::text),
    (-5536002,         'Adam Gallagher',            'Adam',            'Gallagher'),
    (-5536003,         'Kristi Chlebowski',         'Kristi',          'Chlebowski'),
    (-5536004,         'Kalvin D. Barrett',         'Kalvin',          'Barrett'),
    (-5536005,         'Ismael R. Ozanne',          'Ismael',          'Ozanne'),
    (-5536006,         'Jeff Okazaki',              'Jeff',            'Okazaki'),
    -- County Board supervisors, districts 1-37 (external_id = -5536100 - district)
    (-5536101,         'Colin Barushok',            'Colin',           'Barushok'),
    (-5536102,         'Heidi Wegleitner',          'Heidi',           'Wegleitner'),
    (-5536103,         'Analiese Eicher',           'Analiese',        'Eicher'),
    (-5536104,         'Matt Veldran',              'Matt',            'Veldran'),
    (-5536105,         'Henry Fries',               'Henry',           'Fries'),
    (-5536106,         'Yogesh Chawla',             'Yogesh',          'Chawla'),
    (-5536107,         'Erin Welsh',                'Erin',            'Welsh'),
    (-5536108,         'Jeffrey Glazer',            'Jeffrey',         'Glazer'),
    (-5536109,         'Aria Trucios',              'Aria',            'Trucios'),
    (-5536110,         'Keith Furman',              'Keith',           'Furman'),
    (-5536111,         'Richelle Andrae',           'Richelle',        'Andrae'),
    (-5536112,         'Tommy Rylander',            'Tommy',           'Rylander'),
    (-5536113,         'Jay Brower',                'Jay',             'Brower'),
    (-5536114,         'Anthony Gray',              'Anthony',         'Gray'),
    (-5536115,         'Amy Larson',                'Amy',             'Larson'),
    (-5536116,         'Goodwill Obieze',           'Goodwill',        'Obieze'),
    (-5536117,         'Dan Blazewicz',             'Dan',             'Blazewicz'),
    (-5536118,         'Michele Ritt',              'Michele',         'Ritt'),
    (-5536119,         'Brenda Yang',               'Brenda',          'Yang'),
    (-5536120,         'Paula Brandmeier',          'Paula',           'Brandmeier'),
    (-5536121,         'Jeffrey Kroning',           'Jeffrey',         'Kroning'),
    (-5536122,         'Gussie Lewis',              'Gussie',          'Lewis'),
    (-5536123,         'Chuck Erickson',            'Chuck',           'Erickson'),
    (-5536124,         'Sarah Smith',               'Sarah',           'Smith'),
    (-5536125,         'David Boetcher',            'David',           'Boetcher'),
    (-5536126,         'Lisa Jackson',              'Lisa',            'Jackson'),
    (-5536127,         'Kierstin Huelsemann',       'Kierstin',        'Huelsemann'),
    (-5536128,         'Michele Doolan',            'Michele',         'Doolan'),
    (-5536129,         'Don Postler',               'Don',             'Postler'),
    (-5536130,         'Patrick Downing',           'Patrick',         'Downing'),
    (-5536131,         'Jerry Bollig',              'Jerry',           'Bollig'),
    (-5536132,         'Chad Kemp',                 'Chad',            'Kemp'),
    (-5536133,         'Donald D. Dantzler, Jr.',   'Donald',          'Dantzler'),
    (-5536134,         'Patrick Miles',             'Patrick',         'Miles'),
    (-5536135,         'Michael Engelberger',       'Michael',         'Engelberger'),
    (-5536136,         'David Peterson',            'David',           'Peterson'),
    (-5536137,         'Kerry Marren',              'Kerry',           'Marren'),
    -- Circuit Court judges, branches 1-17 (external_id = -5536200 - branch)
    (-5536201,         'Benjamin Jones',            'Benjamin',        'Jones'),
    (-5536202,         'Payal Khandhar',            'Payal',           'Khandhar'),
    (-5536203,         'Diane Schlipper',           'Diane',           'Schlipper'),
    (-5536204,         'Everett Mitchell',          'Everett',         'Mitchell'),
    (-5536205,         'Nicholas McNamara',         'Nicholas',        'McNamara'),
    (-5536206,         'Nia Trammell',              'Nia',             'Trammell'),
    (-5536207,         'Mario White',               'Mario',           'White'),
    (-5536208,         'Stephanie Hilton',          'Stephanie',       'Hilton'),
    (-5536209,         'Jacob Frost',               'Jacob',           'Frost'),
    (-5536210,         'Ryan Nilsestuen',           'Ryan',            'Nilsestuen'),
    (-5536211,         'Ellen Berz',                'Ellen',           'Berz'),
    (-5536212,         'Ann Peacock',               'Ann',             'Peacock'),
    (-5536213,         'Julie Genovese',            'Julie',           'Genovese'),
    (-5536214,         'John Hyland',               'John',            'Hyland'),
    (-5536215,         'Stephen Ehlke',             'Stephen',         'Ehlke'),
    (-5536216,         'Rhonda Lanford',            'Rhonda',          'Lanford'),
    (-5536217,         'David Conway',              'David',           'Conway')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- ── 6. 6 countywide offices -> the pre-existing G4020 Dane County district ──
--    Guarded on (district_id, chamber_id, title): all share district AND chamber.
--    (The 7th, County Executive, was adopted in step 3.)
INSERT INTO essentials.offices
  (district_id, chamber_id, title, representing_state, is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, v.title, 'WI', false, false, 1
FROM (VALUES
    ('County Clerk'::text),
    ('County Treasurer'),
    ('Register of Deeds'),
    ('Sheriff'),
    ('District Attorney'),
    ('Clerk of Circuit Court')
  ) AS v(title)
JOIN essentials.districts d
  ON d.geo_id = '55025' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'Countywide Elected Officials'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = v.title
);

-- ── 7. 37 supervisor offices -> their OWN X-DC-SUP district (per-district routing) ──
INSERT INTO essentials.offices
  (district_id, chamber_id, title, representing_state, is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, 'County Board Supervisor', 'WI', false, false, 1
FROM generate_series(1, 37) AS g(n)
JOIN essentials.districts d
  ON d.geo_id = '55025-sup-d' || g.n AND d.district_type = 'COUNTY' AND d.mtfcc = 'X-DC-SUP' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'County Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id
);

-- ── 8. 17 branch offices -> the JUDICIAL district. Titles unique, title guard correct. ──
INSERT INTO essentials.offices
  (district_id, chamber_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, 'Circuit Court Judge, Branch ' || g.n, 'WI', NULL, false, false, 1
FROM generate_series(1, 17) AS g(n)
JOIN essentials.districts d
  ON d.geo_id = '55025' AND d.district_type = 'JUDICIAL' AND d.mtfcc = 'G4020' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'Circuit Court'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = 'Circuit Court Judge, Branch ' || g.n
);

-- ── 9. Seat the 37 supervisors (sourced month precision) ──
DO $$
DECLARE
  r RECORD;
  v_office uuid;
  v_pol    uuid;
BEGIN
  FOR r IN SELECT g.n AS district_no, (-5536100 - g.n)::bigint AS ext FROM generate_series(1, 37) AS g(n)
  LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = '55025-sup-d' || r.district_no
       AND d.district_type = 'COUNTY' AND d.mtfcc = 'X-DC-SUP';
    SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = r.ext;

    IF v_office IS NULL THEN RAISE EXCEPTION 'missing office for Dane supervisor district %', r.district_no; END IF;
    IF v_pol    IS NULL THEN RAISE EXCEPTION 'missing politician external_id % (district %)', r.ext, r.district_no; END IF;

    PERFORM essentials.seat_officeholder(
      v_office, v_pol, DATE '2026-04-01',
      'migration 1491 — board.danecounty.gov/supervisors, fetched 2026-07-29 (April 2026 spring election; prior terms expired 2026-04-20 per County Clerk directory)',
      'elected', 'month'
    );
  END LOOP;
END $$;

-- ── 10. Seat the officers: Ozanne with his sourced August-2010 start; the other five as
--       occupancy-only rows (NULL start, 'unknown' precision -- 1459 backfill precedent). ──
DO $$
DECLARE
  v_office uuid;
  v_pol    uuid;
  r RECORD;
BEGIN
  -- District Attorney (sourced start)
  SELECT o.id INTO v_office
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers  c ON c.id = o.chamber_id
   WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'
     AND c.name = 'Countywide Elected Officials' AND o.title = 'District Attorney';
  SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = -5536005;
  IF v_office IS NULL OR v_pol IS NULL THEN RAISE EXCEPTION 'Dane DA office/politician missing'; END IF;
  PERFORM essentials.seat_officeholder(
    v_office, v_pol, DATE '2010-08-01',
    'migration 1491 — da.danecounty.gov ("has served since August 2010"), fetched 2026-07-29',
    'elected', 'month');

  -- The other five: occupancy-only office_terms rows
  FOR r IN
    SELECT * FROM (VALUES
      ('County Clerk',           -5536001::bigint),
      ('County Treasurer',       -5536002),
      ('Register of Deeds',      -5536003),
      ('Sheriff',                -5536004),
      ('Clerk of Circuit Court', -5536006)
    ) AS t(title, ext)
  LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.chambers  c ON c.id = o.chamber_id
     WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020'
       AND c.name = 'Countywide Elected Officials' AND o.title = r.title;
    SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = r.ext;
    IF v_office IS NULL THEN RAISE EXCEPTION 'missing Dane countywide office %', r.title; END IF;
    IF v_pol    IS NULL THEN RAISE EXCEPTION 'missing politician external_id %', r.ext; END IF;

    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, source)
    SELECT v_office, v_pol, NULL, 'unknown',
           'migration 1491 — office pages publish term expirations (directory p.14), not starts; fetched 2026-07-29'
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v_office
    );
  END LOOP;
END $$;

-- ── 11. Seat the 17 judges (occupancy-only rows; starts not published) ──
DO $$
DECLARE
  r RECORD;
  v_office uuid;
  v_pol    uuid;
BEGIN
  FOR r IN SELECT g.n AS branch_no, (-5536200 - g.n)::bigint AS ext FROM generate_series(1, 17) AS g(n)
  LOOP
    SELECT o.id INTO v_office
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = '55025' AND d.district_type = 'JUDICIAL' AND d.mtfcc = 'G4020'
       AND o.title = 'Circuit Court Judge, Branch ' || r.branch_no;
    SELECT p.id INTO v_pol FROM essentials.politicians p WHERE p.external_id = r.ext;

    IF v_office IS NULL THEN RAISE EXCEPTION 'missing office for Dane circuit branch %', r.branch_no; END IF;
    IF v_pol    IS NULL THEN RAISE EXCEPTION 'missing politician external_id % (branch %)', r.ext, r.branch_no; END IF;

    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, source)
    SELECT v_office, v_pol, NULL, 'unknown',
           'migration 1491 — courts.danecounty.gov/Judges + wicourts.gov publish expirations, not starts; fetched 2026-07-29'
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t WHERE t.office_id = v_office
    );
  END LOOP;
END $$;

-- ── 12. judge_details: nonpartisan bench; Genovese alone is Chief Judge (Admin District V) ──
INSERT INTO essentials.judge_details (politician_id, court_role, election_type)
SELECT p.id,
       CASE WHEN p.external_id = -5536213 THEN 'Chief Judge' ELSE NULL END,
       'nonpartisan'
FROM essentials.politicians p
WHERE p.external_id BETWEEN -5536217 AND -5536201
  AND NOT EXISTS (
    SELECT 1 FROM essentials.judge_details jd WHERE jd.politician_id = p.id
  );

-- ── 13. Post-verify gate ──
DO $$
DECLARE
  v_gov uuid;
  n int;
  v_exec text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments WHERE name = 'Dane County, Wisconsin, US';
  IF v_gov IS NULL THEN RAISE EXCEPTION 'no Dane County government row'; END IF;

  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = v_gov;
  IF n <> 3 THEN RAISE EXCEPTION 'expected 3 Dane County chambers, found %', n; END IF;

  SELECT count(*) INTO n FROM essentials.districts
   WHERE mtfcc = 'X-DC-SUP' AND district_type = 'COUNTY' AND state = 'wi';
  IF n <> 37 THEN
    RAISE EXCEPTION 'expected 37 X-DC-SUP districts, found % -- run import-dane-supervisor-districts.ts first', n;
  END IF;

  -- countywide: 7 offices INCLUDING the adopted County Executive, and none chamber-less left
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Countywide Elected Officials' AND c.government_id = v_gov;
  IF n <> 7 THEN RAISE EXCEPTION 'countywide offices: got %, want 7 (adopt of County Executive failed?)', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '55025' AND d.district_type = 'COUNTY' AND o.chamber_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% chamber-less offices remain on the Dane COUNTY district', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'County Board' AND c.government_id = v_gov;
  IF n <> 37 THEN RAISE EXCEPTION 'supervisor offices: got %, want 37', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Circuit Court' AND c.government_id = v_gov;
  IF n <> 17 THEN RAISE EXCEPTION 'circuit court offices: got %, want 17', n; END IF;

  -- every office of the government must have a CURRENT holder (61 = 7 + 37 + 17)
  SELECT count(*) INTO n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id AND och.politician_id IS NOT NULL
   WHERE c.government_id = v_gov;
  IF n <> 61 THEN RAISE EXCEPTION 'seated Dane County officials: got %, want 61', n; END IF;

  -- no supervisor bound to the countywide/judicial district and vice versa
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND ((c.name = 'County Board' AND d.mtfcc <> 'X-DC-SUP')
       OR (c.name = 'Countywide Elected Officials' AND (d.mtfcc <> 'G4020' OR d.district_type <> 'COUNTY'))
       OR (c.name = 'Circuit Court' AND (d.mtfcc <> 'G4020' OR d.district_type <> 'JUDICIAL')));
  IF n <> 0 THEN RAISE EXCEPTION '% Dane County offices bound to the wrong district tier', n; END IF;

  -- the adopted County Executive must still be Melissa Agard
  SELECT p.full_name INTO v_exec
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE c.government_id = v_gov AND o.title = 'County Executive';
  IF v_exec IS DISTINCT FROM 'Melissa Agard' THEN
    RAISE EXCEPTION 'Dane County Exec is %, expected Melissa Agard', coalesce(v_exec, 'NULL');
  END IF;

  -- judge_details: 17 rows, exactly 1 Chief Judge
  SELECT count(*) INTO n FROM essentials.judge_details jd
    JOIN essentials.politicians p ON p.id = jd.politician_id
   WHERE p.external_id BETWEEN -5536217 AND -5536201;
  IF n <> 17 THEN RAISE EXCEPTION 'judge_details rows: got %, want 17', n; END IF;

  SELECT count(*) INTO n FROM essentials.judge_details jd
    JOIN essentials.politicians p ON p.id = jd.politician_id
   WHERE p.external_id BETWEEN -5536217 AND -5536201 AND jd.court_role = 'Chief Judge';
  IF n <> 1 THEN RAISE EXCEPTION 'Chief Judge rows: got %, want exactly 1', n; END IF;

  -- antipartisan: no party stored on any of the 60
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE external_id BETWEEN -5536217 AND -5536001 AND party IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% Dane County officials carry an unsourced party', n; END IF;

  RAISE NOTICE 'Dane County verify PASSED: 1 government, 3 chambers, 7 countywide + 37 supervisor + 17 circuit offices, 61 seated, Agard adopted, 1 Chief Judge.';
END $$;

COMMIT;
