-- CC_0347 — California city offices: 4 dated, 106 recorded as owed with their statutory bound.
--
-- Piece 4, California slice, third pass. After this every one of California's 337 local offices
-- for 2026-11-03 has a row. 110 city offices + 1 Sheriff carry `basis = 'estimated'` and are
-- NOT seatable; the remaining 226 are seatable.
--
-- ⚠ THIS IS THE FIRST MIGRATION IN THE PROGRAMME TO WRITE `basis = 'estimated'` ROWS, AND THE
-- EARLIER ONES ARGUED AGAINST IT. `CC_0345` left 122 offices with no row at all, reasoning that
-- "an estimated row still carries a date, and 122 guesses in a table the seeding script reads is
-- a worse artefact than an empty space the tracker can count". That reasoning holds for a GUESS.
-- It does not hold for these 106, and the difference is the point of the `basis` column:
--
--   * The rows below do not guess a handover date. They carry the **statutory floor** — the
--     earliest day the law permits a council to act — together with the rule that fixes the
--     ceiling per city. That is a measurement of what the law says, not an estimate of what will
--     happen.
--   * `basis = 'estimated'` makes them unseatable by contract, so nothing can write a term from
--     them. The partial index `office_swearing_in_basis_idx` collects them as the tracker's
--     "owed" bucket.
--   * An absent row and an owed row look identical to a human reading a count, and only one of
--     them carries the deadline. 106 seats whose handover is roughly four weeks away should be
--     visible WITH their deadline, not inferred from a gap.
--
-- ============================================================================================
-- PART A — LOS ANGELES. 4 OFFICES, A REAL DATE: 2026-12-14.
-- ============================================================================================
--
-- Los Angeles City Charter § 205(c): "The term of an official elected to City office shall
-- commence on the second Monday in December next following his or her election."
-- Second Monday in December 2026 = 2026-12-14.
--
-- ✅ Controlled against a real past seating: the City Clerk's roster records the 2024 citywide
-- officers as commencing 2024-12-09, which is the second Monday of that December.
--
-- § 205(c) also stages the cycle — the Mayor, City Attorney, Controller and ODD-numbered council
-- districts commence on each fourth anniversary of 2022, which is 2026. The four offices here
-- are Mayor, City Attorney and Council Districts 3 and 9. Both districts are odd. The charter
-- and the ballot agree, which is the check that the right cycle was read.
--
-- 🔴 LOS ANGELES IS THE EXCEPTION AMONG THE 53 CITIES, NOT THE PATTERN. Being a charter city does
-- NOT mean having a date. Burbank's charter was read the same day and fixes no commencement at
-- all: it provides only that the county canvasses and certifies to the Council, "who shall
-- thereupon declare the result". Burbank is therefore in Part B with the general law cities.
--
-- ============================================================================================
-- PART B — 106 CITY OFFICES ACROSS 52 CITIES. THE LAW FIXES A PROCESS, NOT A DAY.
-- ============================================================================================
--
-- The chain, each section read from leginfo on 2026-11-04:
--
--   Gov. Code § 36503     "City officers holding elective city office shall hold office for
--                          their prescribed terms FROM THE DATE OF THE INSTALLATION OF OFFICERS
--                          following adoption by the council of the official canvass of their
--                          election."
--   Elec. Code § 10262(b) For a consolidated election, the city elections official certifies the
--                          results to the governing body, which shall act "no later than the
--                          next regularly scheduled city council meeting following presentation
--                          of the 28-day canvass of the returns, or at a special meeting called
--                          for this purpose".
--   Elec. Code § 10263(b) The governing body shall meet "no later than the next regularly
--                          scheduled city council meeting following presentation of the 28-day
--                          canvass of the returns, or at a special meeting called for this
--                          purpose, TO DECLARE THE RESULTS AND TO INSTALL THE NEWLY ELECTED
--                          OFFICERS".
--
-- So the handover is one event — declare and install at the same meeting — and the date is that
-- council's own meeting. There is no statewide day.
--
-- WHAT IS FIXED: the 28-day canvass is 2026-12-01 (E+28), and § 10263 requires the canvass to be
-- COMPLETE before the council may install. The county's official canvass must finish within 30
-- days (2026-12-03) and the Registrar-Recorder/County Clerk is tentatively scheduled to certify
-- on 2026-11-27. So no city installs before the county certifies, and the floor written below is
-- 2026-12-01, the statute's own hinge.
--
-- 🔴 WHY `window_end_date` IS NULL AND NOT A COMPUTED MEETING DATE. "The next regularly scheduled
-- council meeting" is derivable from each city's published meeting rule — but § 10263(b) says
-- "NO LATER THAN", and expressly allows "a special meeting called for this purpose". Cities use
-- that: Glendale's June 2026 election was certified by the RR/CC on 26 June and the city held a
-- SPECIAL council meeting to administer the oath. A computed next-regular-meeting is therefore an
-- upper bound that is systematically LATE, and writing 106 upper bounds as dates would repeat
-- the mistake `CC_0346` had to correct for the municipal water districts — in bulk.
-- ▶ A bound you can defend beats a date you cannot. The floor and the rule go in; the day comes
-- from each city when it publishes it.
--
-- ⚠ NOTHING IS PUBLISHED YET, AND THAT IS EXPECTED, NOT A SEARCH FAILURE. This migration is
-- written one day after the election. The canvass does not complete for four weeks. No city in
-- the set has posted an installation date for this cycle; the dates will appear through late
-- November and early December, and each should REPLACE its row here with basis='published'.
--
-- WHAT IS KNOWN ABOUT THE 52 CITIES. 12 are confirmed charter cities, from the California
-- Department of Industrial Relations' "List of Charter Cities that Are in Compliance with Senate
-- Bill 7 (2013), Senate Bill 829 (2011), and Senate Bill 922 (2012)", current as of 2026-03-05:
-- Alhambra, Arcadia, Burbank, Compton, Culver City, Downey, Inglewood, Irwindale, Los Angeles,
-- Palmdale, Pomona, Santa Monica.
-- ⚠ THAT LIST IS A SUBSET AND ABSENCE PROVES NOTHING — it lists only charter cities in compliance
-- with three particular statutes, so a charter city missing from it is not thereby a general law
-- city. Montebello was separately confirmed general law from its own clerk's page. The other 40
-- are unclassified here, and the classification only decides WHICH DOCUMENT to read, never the
-- date, so nothing below depends on it.
--
-- No value is overwritten: every office touched here has no row in this table.

CREATE TEMP TABLE ca_2026_city ON COMMIT DROP AS
SELECT DISTINCT
       o.id AS office_id,
       -- 🔴 COALESCE IS LOAD-BEARING, AND ITS ABSENCE COST A SILENT 37-ROW HOLE.
       -- 234 of California's 337 offices have a NULL `ocd_id`, including all 37 by-district
       -- council seats whose district row carries only "District 1".."District 6". Written as
       -- `d.ocd_id LIKE '...'`, those rows evaluate to NULL rather than false — so `WHERE
       -- is_la_city` dropped them AND `WHERE NOT is_la_city` dropped them too, because NOT NULL
       -- is NULL and not true. 37 city offices fell out of BOTH branches and the inserts simply
       -- wrote fewer rows, with no error. The count gate below is what caught it: 69 instead of
       -- 106. ▶ Three-valued logic does not raise; it quietly returns a smaller set.
       (COALESCE(d.ocd_id, '') LIKE 'ocd-division/country:us/state:ca/place:los_angeles%') AS is_la_city
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND lower(d.state) = 'ca'
   AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
   -- 🔴 EXCLUDES THE DISTRICT OFFICES BY TITLE, WHICH IS SAFE HERE AND IS NOT SAFE FOR A DATE.
   -- CC_0345 and CC_0346 chose each district body BY NAME because a title predicate cannot tell
   -- a municipal water district from a county water district. This predicate is doing a
   -- different job: it only has to separate "Director/Trustee of a special district" from "city
   -- officer", and every one of the 25 district offices is already dated, so the post-verify
   -- gate below catches any leakage as a count mismatch.
   AND NOT (o.title ILIKE 'Director%' OR o.title ILIKE 'Trustee%');

-- 4 — Los Angeles.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-14', 'statute', 'ca-la-city-charter-205c',
       'Los Angeles City Charter § 205(c) — "The term of an official elected to City office shall commence on the second Monday in December next following his or her election"',
       'https://codelibrary.amlegal.com/codes/los_angeles/latest/laac/0-0-0-392 (read 2026-11-04)',
       'Controlled against a real past seating: the City Clerk''s roster records the 2024 citywide officers as commencing 2024-12-09, the second Monday of that December. § 205(c) stages the cycle so that the Mayor, City Attorney, Controller and ODD-numbered council districts commence each fourth anniversary of 2022; the four offices here are Mayor, City Attorney and Council Districts 3 and 9, both odd.'
  FROM ca_2026_city WHERE is_la_city
ON CONFLICT (office_id, election_date) DO NOTHING;

-- 106 — every other city office. NOT SEATABLE.
INSERT INTO essentials.office_swearing_in
  (office_id, election_date, swearing_in_date, basis, rule_id, authority, source, notes)
SELECT office_id, DATE '2026-11-03', DATE '2026-12-01', 'estimated', 'ca-gov-36503',
       'Cal. Gov. Code § 36503 with Cal. Elec. Code §§ 10262(b) and 10263(b) — the term runs from the installation of officers, which the council performs together with declaring the results, no later than its next regularly scheduled meeting following presentation of the 28-day canvass, or at a special meeting called for that purpose',
       'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=36503. · https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10262. · https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10263. (all read 2026-11-04)',
       'NOT SEATABLE. 2026-12-01 is the STATUTORY FLOOR (E+28, the canvass the council acts on), not a prediction of the handover. The ceiling is each council''s own next regular meeting, and § 10263(b) is a "no later than" that expressly permits a special meeting instead - Glendale used exactly that path after its June 2026 election - so a computed next-regular-meeting would be systematically late. Replace this row per city with basis=''published'' when that city posts its installation date, which will happen through late November and early December. See backend/data/ca-2026-swearing-in/RULES.md.'
  FROM ca_2026_city WHERE NOT is_la_city
ON CONFLICT (office_id, election_date) DO NOTHING;

-- --------------------------------------------------------------------------------------------
-- Post-verify. Gates the delta this file creates, in its own transaction.
-- --------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_set       bigint;
  v_la        bigint;
  v_city      bigint;
  v_total     bigint;
  v_seatable  bigint;
  v_leak      bigint;
BEGIN
  SELECT count(*) INTO v_set FROM ca_2026_city;
  IF v_set <> 110 THEN
    RAISE EXCEPTION 'CC_0347: expected 110 California city offices, found % — re-measure before trusting the class counts', v_set;
  END IF;

  SELECT count(*) INTO v_la
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-la-city-charter-205c';
  IF v_la <> 4 THEN RAISE EXCEPTION 'CC_0347: expected 4 Los Angeles rows, found %', v_la; END IF;

  SELECT count(*) INTO v_city
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-gov-36503';
  IF v_city <> 106 THEN RAISE EXCEPTION 'CC_0347: expected 106 city rows, found %', v_city; END IF;

  SELECT count(*) INTO v_total
    FROM essentials.office_swearing_in WHERE election_date = DATE '2026-11-03';
  IF v_total <> 336 THEN
    RAISE EXCEPTION 'CC_0347: expected 336 rows (226 + 110), found % — the LA County Sheriff is the one office that should still have none', v_total;
  END IF;

  -- 🔴 THE CONTRACT THE 'estimated' BASIS EXISTS FOR. Every city row except Los Angeles must be
  -- unseatable. If a later edit promotes one to 'statute' or 'published' without a real source,
  -- this is what says so.
  SELECT count(*) INTO v_seatable
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND rule_id = 'ca-gov-36503'
     AND basis <> 'estimated';
  IF v_seatable <> 0 THEN
    RAISE EXCEPTION 'CC_0347: % city row(s) under the no-statewide-date rule are marked seatable', v_seatable;
  END IF;

  -- 🔴 NO DISTRICT OFFICE MAY HAVE LEAKED THROUGH THE TITLE PREDICATE. All 25 were dated by
  -- CC_0345/CC_0346 under their own principal acts; if one is now carrying the city rule, the
  -- predicate caught something it should not have.
  -- ⚠ An earlier draft of this gate read `office_id IN (SELECT office_id FROM ca_2026_city
  -- WHERE false)`, which cannot match anything and so could never fail. A gate that cannot go
  -- red is not a gate. This one joins the real offices and reads their titles.
  SELECT count(*) INTO v_leak
    FROM essentials.office_swearing_in s
    JOIN essentials.offices o ON o.id = s.office_id
   WHERE s.election_date = DATE '2026-11-03'
     AND s.rule_id = 'ca-gov-36503'
     AND (o.title ILIKE 'Director%' OR o.title ILIKE 'Trustee%');
  IF v_leak <> 0 THEN RAISE EXCEPTION 'CC_0347: % district office(s) took the city rule', v_leak; END IF;

  SELECT count(*) INTO v_seatable
    FROM essentials.office_swearing_in
   WHERE election_date = DATE '2026-11-03' AND basis IN ('statute', 'published');
  IF v_seatable <> 230 THEN
    RAISE EXCEPTION 'CC_0347: expected 230 seatable rows (226 + Los Angeles 4), found %', v_seatable;
  END IF;

  RAISE NOTICE 'CC_0347 OK: 336 rows — 230 seatable, 106 city rows owed a published date';
END $$;
