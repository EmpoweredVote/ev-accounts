-- CC_0313_ada_county_id_structure_and_seating.sql
-- Ada County, Idaho — full greenfield seed: government, two chambers, three commissioner
-- districts, nine offices, nine officeholders. Offices and people ship TOGETHER, by programme
-- rule: an office with no `office_terms` row is invisible, so splitting them across two
-- migrations would push `essentials.offices_missing_terms` for the days in between.
--
-- Roster, sources, charter rulings and source defects:
--   backend/data/seed-ada-county-2026/ROSTERS.md
--
-- ═══ 🔴 EVERY SEAT HERE WAS ON THE 2026-11-03 BALLOT; WINNERS SEAT 2027-01-11 ═══
--
-- Idaho Code §59-404, read from the Legislature's own text (ic_59_404.html in the wave
-- directory): the oath of county elective officers is taken "on the SECOND MONDAY OF JANUARY
-- succeeding each general election" — 2027-01-11 for this cycle.
--
-- ▶ THE RE-SEAT IS NOT A RE-RUN OF THIS FILE. Use `essentials.seat_officeholder(office_id,
--   politician_id, DATE '2027-01-11', source)`, which closes the predecessor's term the day
--   before.
--
-- ⚠ Seating today is still correct today, and leaving nine offices unseated for ten weeks is not
--   the safe option — an unseated office is invisible and NOTHING ERRORS.
--
-- ═══ NINE OFFICES, AND THE LIST COMES FROM THE CONSTITUTION ═══
--
-- Idaho Const. Art. XVIII §6 (const18_6.html in the wave directory): the legislature shall
-- provide for the biennial election of COUNTY COMMISSIONERS, and for the election every four
-- years of a SHERIFF, a COUNTY ASSESSOR, a COUNTY CORONER and a COUNTY TREASURER (ex officio
-- public administrator). "No other county offices shall be established." The CLERK OF THE
-- DISTRICT COURT is ex officio AUDITOR AND RECORDER. The PROSECUTING ATTORNEY is elected under
-- Title 31. Three commissioners plus six countywide officers is NINE, and the roster is complete.
--
-- Idaho Code §31-703 sets the commissioner rotation: at each biennial election one commissioner
-- is elected to a TWO-year term and one to a FOUR-year term, the four-year term rotating through
-- districts 1 → 2 → 3. So two of the three commission seats are on every even-year ballot and
-- the board is never insulated from an election.
--
-- ═══ 🔴 THE COMMISSIONERS' CSS CLASS IS A PHOTO POSITION, NOT A DISTRICT NUMBER ═══
--
-- In the county's `bocc-nameplates` block the wrapper classes run d3, d2, d1 against districts
-- 1, 2, 3 — they index left-to-right across the group photograph. A parser keying on the class
-- name swaps Davidson and Dayley, and both are real Ada County commissioners, so nothing looks
-- wrong afterwards.
--
-- ▶ The assignments below are confirmed FIVE ways, all agreeing: the county's link slugs
--   (`ryan-davidson-district-1`), the page's visible text, the county GIS layer's own
--   `commissioner` attribute, Wikipedia, and the individual bio pages. Only the CSS class
--   disagrees, and it is not a district field. The district loader re-reads the GIS
--   `commissioner` attribute and fails if it has moved.
--
-- ═══ 🔴 THREE BALLOTPEDIA PAGES ARE SOFT-404s SERVED AS HTTP 200 ═══
--
-- /Rod_Beck, /Matt_Clifford and /Richard_Riffle each returned HTTP 200 with a 100–300 KB body
-- reading "Oops! The page you're looking for does not exist." The real pages are
-- /Matthew_Clifford and /Rich_Riffle — name variants. A status check is not an existence check.
--
-- ═══ DATES: ONE IS DELIBERATELY UNKNOWN ═══
--
-- `office_terms.term_start` is the start of CONTINUOUS OCCUPANCY, not of the current term.
--
-- 🔴 ROD BECK'S TERM IS OPEN-ENDED WITH `start_precision = 'unknown'`, AND THAT IS THE ANSWER,
--    NOT A GAP TO BE FILLED IN LATER BY GUESSWORK. No retrievable source states when he took
--    office. Search results assert he was first elected in November 2020 — which would put him
--    at 2021-01-11 beside Ryan Davidson, who won the same election — but a search-result summary
--    is a lead and not a source; Ada County publishes its canvass only as Tableau dashboards;
--    Ballotpedia has no page for him; and the contemporaneous KTVB report returns HTTP 403.
--    CLAUDE.md is explicit: if the start is genuinely unknown, write an open-ended term with
--    `start_precision => 'unknown'` — not a guess. Cheap to tighten later from the 2020 canvass.
--
-- ⚠ SHERIFF CLIFFORD'S OCCUPANCY RUNS FROM AN APPOINTMENT, NOT AN ELECTION. He was appointed
--   2021-07-02 after Sheriff Bartlett resigned, then won a 2022 special election and a full term
--   in 2024. Continuous occupancy therefore starts at the appointment.
--
-- ⚠ Two rows carry only a year (Mahn 2019, Bennetts 2014) and are written at
--   `start_precision => 'year'` on YYYY-01-01. No day is invented.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. NO `term_end`. A future term_end makes a seat silently self-vacate — and every seat here
--     turns over in January 2027.
--  2. NO party. These are partisan county offices, but party lives on `races.primary_party`,
--     the same rule CC_0310 follows for the legislature. The gate asserts it.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_poly int; v_stray int; v_county_poly int; v_county_dist int; v_gov int; v_people int;
BEGIN
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0084' AND geo_id LIKE 'ada-county-id-commissioner-district-%';
  IF v_poly <> 3 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: expected 3 X0084 Ada County commissioner polygons, found % '
                    '— run scripts/load-idaho-local-districts.mjs first. An office on a district '
                    'with no polygon is unreachable by any address and nothing errors.', v_poly;
  END IF;

  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0084' AND geo_id NOT LIKE 'ada-county-id-commissioner-district-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: % X0084 polygon(s) are not Ada County commissioner '
                    'districts — somebody else took this code', v_stray;
  END IF;

  -- (geo_id, mtfcc, state): geo_id alone is not a key anywhere in this database.
  SELECT count(*) INTO v_county_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '16001' AND mtfcc = 'G4020' AND state = '16';
  IF v_county_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: expected the TIGER county polygon 16001/G4020 in state 16 '
                    'for the six countywide offices, found %', v_county_poly;
  END IF;

  SELECT count(*) INTO v_county_dist FROM essentials.districts
   WHERE geo_id = '16001' AND mtfcc = 'G4020' AND district_type = 'COUNTY';
  IF v_county_dist <> 1 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: expected exactly 1 existing COUNTY district row on '
                    '16001/G4020 to hang the countywide offices on, found %', v_county_dist;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name ILIKE '%ada county%';
  IF v_gov <> 0 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: % government row(s) already mention Ada County — this is '
                    'meant to be a greenfield seed, so read them before going further', v_gov;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians p
   WHERE p.is_active AND (lower(btrim(p.last_name)), lower(btrim(p.first_name))) IN (
     ('davidson','ryan'), ('beck','rod'), ('dayley','tom'), ('clifford','matt'),
     ('tripple','trent'), ('mahn','elizabeth'), ('arnold','rebecca'),
     ('riffle','richard'), ('bennetts','jan'));
  IF v_people <> 0 THEN
    RAISE EXCEPTION 'CC_0313 pre-flight: % active politician(s) already match an Ada County official '
                    'on first+last name — re-read the identity scan in ROSTERS.md', v_people;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'Ada County, Idaho, US', 'County', 'ID', '', '16001', 'G4020'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Ada County, Idaho, US');

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term,
   election_method, election_rules, inauguration_rules, website_url)
SELECT g.id, v.name, v.name, v.n, v.len, v.stag, 'partisan', v.rules, v.inaug, v.url
FROM essentials.governments g
JOIN (VALUES
  ('Ada County Board of Commissioners', 3::bigint, '4', true,
   'Partisan, three single-member districts. Idaho Code sec. 31-703 staggers the board by '
   || 'rotation rather than by a fixed cycle: at each biennial election ONE commissioner is '
   || 'elected to a two-year term and ONE to a four-year term, and the four-year term rotates '
   || 'through districts 1, 2 and 3 in turn. Two of the three seats are therefore on every '
   || 'even-year ballot.',
   'County elective officers take the oath on the SECOND MONDAY OF JANUARY succeeding each '
   || 'general election (Idaho Code sec. 59-404).',
   'https://adacounty.id.gov/commissioners/'),
  ('Ada County Elected Officers', 6::bigint, '4', false,
   'Partisan, elected countywide to four-year terms. Idaho Const. Art. XVIII sec. 6 provides for '
   || 'the election every four years of a sheriff, assessor, coroner and treasurer, and states '
   || 'that "no other county offices shall be established"; the clerk of the district court is '
   || 'ex officio auditor and recorder, and the prosecuting attorney is elected under Title 31.',
   'County elective officers take the oath on the SECOND MONDAY OF JANUARY succeeding each '
   || 'general election (Idaho Code sec. 59-404).',
   'https://adacounty.id.gov/')
) AS v(name, n, len, stag, rules, inaug, url) ON true
WHERE g.name = 'Ada County, Idaho, US'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
-- Three commissioner districts on the X0084 polygons. The six countywide officers hang on the
-- EXISTING TIGER county row (16001/G4020), which the national load already wrote.
CREATE TEMP TABLE ada_districts(geo_id text, label text, num int) ON COMMIT DROP;
INSERT INTO ada_districts(geo_id, label, num) VALUES
  ('ada-county-id-commissioner-district-1', 'Ada County Commissioner District 1', 1),
  ('ada-county-id-commissioner-district-2', 'Ada County Commissioner District 2', 2),
  ('ada-county-id-commissioner-district-3', 'Ada County Commissioner District 3', 3);

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'COUNTY', 'id', 'X0084', 1
FROM ada_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0084' AND d.district_type = 'COUNTY');

-- ── Offices ───────────────────────────────────────────────────────────────────
CREATE TEMP TABLE ada_offices(geo_id text, mtfcc text, chamber_name text, title text, descr text)
  ON COMMIT DROP;
INSERT INTO ada_offices(geo_id, mtfcc, chamber_name, title, descr) VALUES
  ('ada-county-id-commissioner-district-1','X0084','Ada County Board of Commissioners','Commissioner, District 1', NULL),
  ('ada-county-id-commissioner-district-2','X0084','Ada County Board of Commissioners','Commissioner, District 2', NULL),
  ('ada-county-id-commissioner-district-3','X0084','Ada County Board of Commissioners','Commissioner, District 3', NULL),
  ('16001','G4020','Ada County Elected Officers','Sheriff',
     'Elected countywide to a four-year term under Idaho Const. Art. XVIII sec. 6. The Sheriff is '
     || 'the county''s chief law enforcement officer, runs the Ada County Jail, serves civil '
     || 'process for the courts, and in Idaho also administers driver and vehicle licensing.'),
  ('16001','G4020','Ada County Elected Officers','Clerk of the District Court',
     'Elected countywide to a four-year term. The Clerk is EX OFFICIO the county Auditor and '
     || 'Recorder (Idaho Const. Art. XVIII sec. 6) and in that capacity is also the county''s chief '
     || 'election officer, keeper of the land records, and clerk of the Board of County '
     || 'Commissioners. One elected office carrying four distinct statutory roles.'),
  ('16001','G4020','Ada County Elected Officers','Treasurer',
     'Elected countywide to a four-year term under Idaho Const. Art. XVIII sec. 6, which makes the '
     || 'Treasurer EX OFFICIO the county Public Administrator. Collects and distributes all '
     || 'property taxes and is the custodian of county funds.'),
  ('16001','G4020','Ada County Elected Officers','Assessor',
     'Elected countywide to a four-year term under Idaho Const. Art. XVIII sec. 6. Appraises every '
     || 'taxable property in the county each year and administers the homeowner''s exemption and '
     || 'the vehicle registration function.'),
  ('16001','G4020','Ada County Elected Officers','Coroner',
     'Elected countywide to a four-year term under Idaho Const. Art. XVIII sec. 6. Determines the '
     || 'cause and manner of sudden, violent or unattended deaths. Idaho does not require the '
     || 'coroner to be a physician.'),
  ('16001','G4020','Ada County Elected Officers','Prosecuting Attorney',
     'Elected countywide to a four-year term under Title 31. Prosecutes felonies and misdemeanours '
     || 'committed in the county, and acts as civil counsel to the county itself.');

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, seats, is_vacant,
   voting_powers, partisan_type, description)
SELECT c.id, d.id, n.title, 'ID', 1, false, 'full', 'partisan', n.descr
FROM ada_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = 'COUNTY'
JOIN essentials.governments g ON g.name = 'Ada County, Idaho, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ── People ────────────────────────────────────────────────────────────────────
-- term_start is NULLABLE here on purpose: Rod Beck's is genuinely unknown and is written as an
-- open-ended term rather than guessed. See the header.
CREATE TEMP TABLE ada_roster(
  title       text PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  term_start  date,
  precision   text NOT NULL,
  how_started text NOT NULL,
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO ada_roster(title, full_name, first_name, last_name, term_start, precision, how_started, source) VALUES
  ('Commissioner, District 1', 'Ryan Davidson', 'Ryan', 'Davidson', DATE '2021-01-11', 'day', 'elected',
   'adacounty.id.gov/commissioners/ryan-davidson-district-1/ and ballotpedia.org/Ryan_Davidson, read '
   || '2026-10-30 (CC_0313): his county bio says he was "elected to the Ada County Board of '
   || 'Commissioners in November 2020" and "elected to another term by a wide margin in November '
   || '2024"; Ballotpedia gives assumed office 11 January 2021, which is the second Monday of '
   || 'January 2021 and so matches Idaho Code sec. 59-404. Re-election does not end the occupancy.'),
  ('Commissioner, District 2', 'Rod Beck', 'Rod', 'Beck', NULL, 'unknown', 'elected',
   'adacounty.id.gov/commissioners/rod-beck-district-2/, the Ada County GIS Commissioner_District '
   || 'layer and en.wikipedia.org/wiki/Ada_County_Board_of_Commissioners, all read 2026-10-30 '
   || '(CC_0313): all three place Rod Beck in District 2 and name him board Chair. NONE states when '
   || 'he took office, and no retrievable source does: the county publishes its canvass only as '
   || 'Tableau dashboards, Ballotpedia has no page for him (/Rod_Beck is a soft-404 served as HTTP '
   || '200), and the contemporaneous KTVB report of the 2020 race returns HTTP 403. Written as an '
   || 'OPEN-ENDED term at start_precision unknown rather than guessed at 2021-01-11.'),
  ('Commissioner, District 3', 'Tom Dayley', 'Tom', 'Dayley', DATE '2023-01-09', 'day', 'elected',
   'adacounty.id.gov/commissioners/tom-dayley-district-3/ and ballotpedia.org/Tom_Dayley, read '
   || '2026-10-30 (CC_0313): assumed office 9 January 2023 — the second Monday of January after the '
   || '2022 general election, per Idaho Code sec. 59-404.'),
  ('Sheriff', 'Matt Clifford', 'Matt', 'Clifford', DATE '2021-07-02', 'day', 'appointed',
   'adacounty.id.gov/sheriff/ and ballotpedia.org/Matthew_Clifford, read 2026-10-30 (CC_0313): '
   || 'assumed office 2 July 2021 — APPOINTED by the Board of County Commissioners after Sheriff '
   || 'Steve Bartlett resigned, then elected at a November 2022 special election and to a full term '
   || 'on 5 November 2024. term_start is the start of continuous occupancy, so it is the '
   || 'appointment. NOTE the Ballotpedia page is /Matthew_Clifford; /Matt_Clifford is a soft-404 '
   || 'served as HTTP 200.'),
  ('Clerk of the District Court', 'Trent Tripple', 'Trent', 'Tripple', DATE '2023-01-09', 'day', 'elected',
   'adacounty.id.gov/clerk/ ("Trent Tripple, Ada County Clerk") and ballotpedia.org/Trent_Tripple, '
   || 'read 2026-10-30 (CC_0313): assumed office 9 January 2023, the second Monday of January after '
   || 'the 2022 general election.'),
  ('Treasurer', 'Elizabeth Mahn', 'Elizabeth', 'Mahn', DATE '2019-01-01', 'year', 'elected',
   'adacounty.id.gov/treasurer/ ("Elizabeth Mahn, Ada County Treasurer") and '
   || 'ballotpedia.org/Elizabeth_Mahn, read 2026-10-30 (CC_0313): Ballotpedia states she "assumed '
   || 'office in 2019" and gives NO month, so this is start_precision year at 2019-01-01 and the '
   || 'day is not invented.'),
  ('Assessor', 'Rebecca W. Arnold', 'Rebecca', 'Arnold', DATE '2023-01-09', 'day', 'elected',
   'adacounty.id.gov/assessor/about-us/meet-the-assessor/ ("REBECCA W. ARNOLD ADA COUNTY ASSESSOR") '
   || 'and ballotpedia.org/Rebecca_Arnold, read 2026-10-30 (CC_0313): assumed office 9 January 2023, '
   || 'the second Monday of January after the 2022 general election.'),
  ('Coroner', 'Richard D. Riffle', 'Richard', 'Riffle', DATE '2023-01-09', 'day', 'elected',
   'adacounty.id.gov/coroner/ ("Richard D. Riffle, Ada County Coroner") and '
   || 'ballotpedia.org/Rich_Riffle, read 2026-10-30 (CC_0313): assumed office 9 January 2023 after '
   || 'defeating the incumbent at the 2022 general election. NOTE the Ballotpedia page is '
   || '/Rich_Riffle; /Richard_Riffle is a soft-404 served as HTTP 200.'),
  ('Prosecuting Attorney', 'Jan M. Bennetts', 'Jan', 'Bennetts', DATE '2014-01-01', 'year', 'elected',
   'adacounty.id.gov/prosecutor/ ("Prosecutor Jan M. Bennetts") and ballotpedia.org/Jan_Bennetts, '
   || 'read 2026-10-30 (CC_0313): Ballotpedia states she "assumed office in 2014" and gives NO '
   || 'month, so this is start_precision year at 2014-01-01 and the day is not invented.');

UPDATE ada_roster r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'Ada County, Idaho, US' AND o.title = r.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ada_roster WHERE office_id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0313: % roster row(s) did not resolve to an Ada County office', n; END IF;
  SELECT count(*) INTO n FROM ada_roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF n <> 0 THEN RAISE EXCEPTION 'CC_0313: % Ada County office(s) already carry a term', n; END IF;
END $$;

-- 🔴 is_incumbent EXPLICITLY true. It defaults to false, and a seated person inserted without it
--    is HIDDEN from address search; check:occupancy fails an INSERT that omits it.
--    party stays NULL: it belongs on races.primary_party.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source
  FROM ada_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE ada_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE p.is_active
   AND lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name));

-- ── Seating ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM ada_roster ORDER BY title LOOP
    IF r.politician_id IS NULL THEN RAISE EXCEPTION 'CC_0313: % did not resolve to a person', r.title; END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, r.how_started, r.source);
    n := n + 1;
  END LOOP;
  IF n <> 9 THEN RAISE EXCEPTION 'CC_0313: expected 9 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_slug int; v_dist int; v_off int; v_comm int; v_row int;
  v_held int; v_party int; v_notinc int; v_nogeom int; v_termend int; v_dupe int;
  v_unknown int; v_year int; v_day int; v_d1 int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Ada County, Idaho, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0313 gate: expected 1 Ada County government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id WHERE g.name = 'Ada County, Idaho, US';
  IF v_ch <> 2 THEN RAISE EXCEPTION 'CC_0313 gate: expected 2 chambers, found %', v_ch; END IF;

  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Ada County, Idaho, US' AND coalesce(btrim(c.slug),'') = '';
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0313 gate: % Ada County chamber(s) generated an EMPTY slug — name_formal was not set', v_slug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0084' AND district_type = 'COUNTY' AND lower(state) = 'id';
  IF v_dist <> 3 THEN RAISE EXCEPTION 'CC_0313 gate: expected 3 commissioner districts, found %', v_dist; END IF;

  SELECT count(*),
         count(*) FILTER (WHERE c.name = 'Ada County Board of Commissioners'),
         count(*) FILTER (WHERE c.name = 'Ada County Elected Officers')
    INTO v_off, v_comm, v_row
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Ada County, Idaho, US';
  IF v_off <> 9 OR v_comm <> 3 OR v_row <> 6 THEN
    RAISE EXCEPTION 'CC_0313 gate: Idaho Const. Art. XVIII sec. 6 plus Title 31 give NINE elected '
                    'Ada County offices (3 commissioners + 6 countywide); found % (% + %)', v_off, v_comm, v_row;
  END IF;

  -- 🔴 count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices,
  --    so a vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_held
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'Ada County, Idaho, US';
  IF v_held <> 9 THEN RAISE EXCEPTION 'CC_0313 gate: expected 9 held offices, found %', v_held; END IF;

  -- 🔴 The defect this migration exists to survive: the CSS class d3 sits on DISTRICT 1.
  --    Believing it would put Tom Dayley here instead of Ryan Davidson.
  SELECT count(*) INTO v_d1 FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE o.title = 'Commissioner, District 1' AND p.full_name = 'Ryan Davidson';
  IF v_d1 <> 1 THEN
    RAISE EXCEPTION 'CC_0313 gate: District 1 is not held by Ryan Davidson (found %). The county '
                    'page wraps his nameplate in a div classed "d3"; that is a position on the '
                    'group photograph, not a district number.', v_d1;
  END IF;

  SELECT count(*) FILTER (WHERE t.start_precision = 'day'),
         count(*) FILTER (WHERE t.start_precision = 'year'),
         count(*) FILTER (WHERE t.start_precision = 'unknown'),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_day, v_year, v_unknown, v_termend
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Ada County, Idaho, US';
  IF v_day <> 6 OR v_year <> 2 OR v_unknown <> 1 THEN
    RAISE EXCEPTION 'CC_0313 gate: expected 6 day / 2 year / 1 unknown precisions, got % / % / %. '
                    'The single unknown is Rod Beck and is deliberate — see the header.', v_day, v_year, v_unknown;
  END IF;
  IF v_termend <> 0 THEN
    RAISE EXCEPTION 'CC_0313 gate: % Ada County term(s) carry a term_end; a future term_end makes a '
                    'seat silently self-vacate, and every seat here turns over in January 2027', v_termend;
  END IF;

  SELECT count(*) INTO v_party FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'Ada County, Idaho, US' AND coalesce(btrim(p.party),'') <> '';
  IF v_party <> 0 THEN
    RAISE EXCEPTION 'CC_0313 gate: % Ada County officeholder(s) carry a party; it belongs on races.primary_party', v_party;
  END IF;

  SELECT count(*) INTO v_notinc FROM essentials.politicians
   WHERE source LIKE '%(CC_0313)%' AND (NOT is_incumbent OR NOT is_active);
  IF v_notinc <> 0 THEN
    RAISE EXCEPTION 'CC_0313 gate: % seated Ada County official(s) are not active incumbents — they '
                    'would be HIDDEN from address search', v_notinc;
  END IF;

  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Ada County, Idaho, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0313 gate: % Ada County office(s) sit on a district with no polygon and are '
                    'unreachable by address', v_nogeom;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT och.politician_id FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Ada County, Idaho, US' AND och.politician_id IS NOT NULL
     GROUP BY och.politician_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CC_0313 gate: % person(s) hold more than one Ada County seat', v_dupe; END IF;

  RAISE NOTICE 'CC_0313 OK: Ada County government, 2 chambers, 3 commissioner districts, 9 offices, 9 held, District 1 = Ryan Davidson, 1 deliberate unknown start.';
END $$;
