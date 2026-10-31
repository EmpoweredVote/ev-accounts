-- CC_0304_honolulu_hi_structure_and_seating.sql
-- City and County of Honolulu, Hawaii — full greenfield seed: government, three chambers,
-- nine new districts, eleven offices, eleven officeholders.
--
-- Roster, sources, charter rulings, source defects and the identity scan:
--   backend/data/seed-honolulu-2026/ROSTERS.md
--
-- ═══ 🔴 ELEVEN SEATS IS THE WHOLE ELECTED GOVERNMENT. DO NOT ADD ROW OFFICERS. ═══
--
-- Nine district councilmembers, the Mayor, the Prosecuting Attorney. That is all Honolulu
-- elects. The Legislative Reference Bureau's guide to the charter names the Salary Commission's
-- remit as "all elected City and County officials, including the Mayor, council members, and
-- Prosecuting Attorney", and separately records the City Clerk, the City Auditor (six-year
-- term), the Managing Director and the Corporation Counsel as APPOINTED. There is no elected
-- sheriff, clerk, treasurer or assessor to seed. Adding them out of habit would invent offices.
--
-- ═══ 🔴 HAWAII HAS NO INCORPORATED PLACES, SO THIS GOVERNMENT KEYS ON THE COUNTY ═══
--
-- Measured against TIGERweb on 2026-10-28: the Incorporated Places layer returns ZERO features
-- for state 15, and so does the Consolidated Cities layer. The identical query against state 06
-- returns 483, so the query works and the zero is real. There is no G4110 polygon for Honolulu
-- and there never will be — Hawaii has no municipalities at all. The City and County of Honolulu
-- is a consolidated city-county covering the whole island of Oahu plus every island not in
-- another county, and it is coterminous with Honolulu County.
--
--   geo_id '15003', mtfcc 'G4020'   ← this seed
--
-- ⚠ PRECEDENT IN THIS DATABASE IS SPLIT AND COPYING THE NEAREST ONE HAD EVEN ODDS OF BEING
--   WRONG. Nashville (47037) and Indianapolis (18097) register under the COUNTY code; Anchorage
--   (0203000) and San Francisco (0667000) under the PLACE code. For Honolulu the place code does
--   not exist, so the choice is forced rather than preferred.
--
-- 🔴 AND geo_id ALONE IS NOT A KEY HERE. Production holds a SECOND row with geo_id '15003':
--    mtfcc G6350, state 42, 16 km² of Pennsylvania. Every predicate below that touches the
--    county is written on (geo_id, mtfcc) and most also on state.
--
-- ═══ THE COUNTYWIDE DISTRICT ALREADY EXISTS AND IS REUSED ═══
--
-- essentials.districts already carries 'Honolulu County' on 15003/G4020/COUNTY, alongside the
-- other four Hawaii counties. The Mayor and the Prosecuting Attorney hang on THAT row. This
-- migration creates only the nine council districts.
--
-- ═══ GEOGRAPHY ═══
--
-- The nine council-district polygons are loaded first by
-- `scripts/load-honolulu-council-districts.mjs` as `X0082` /
-- `honolulu-hi-council-district-1..9`, from HoLIS — the city's own GIS — carrying the 2021
-- Reapportionment Commission map. This migration REFUSES TO RUN without them: an office on a
-- district with no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 THE DISTRICTS COVER 27.69% OF THE COUNTY POLYGON AND THAT IS CORRECT. They measure
--    1,553.6 km², which is Oahu's land area, inside a 5,610.5 km² county whose remainder is open
--    ocean and the uninhabited Northwestern Hawaiian Islands. The loader's GATE 4 asserts the
--    opposite direction instead — that NOTHING spills outside the county — and measured
--    0.000 km². A tiling assertion would have failed on a correct map.
--
-- ═══ DATES: THE CHARTER GIVES A SWEARING-IN DAY, SO TEN OF ELEVEN ARE DATED ═══
--
-- `office_terms.term_start` is the start of CONTINUOUS OCCUPANCY, not of the current term.
--
-- 🟢 Honolulu councilmembers take office on JANUARY 2 following their election. District VII's
--    own page states it outright — "Serving Since: Jan. 2, 2021" — and every other published
--    term string is consistent with it. That is a swearing-in date, not an election date, so
--    CLAUDE.md's "FIRST ELECTED IS NOT A TERM START" is satisfied rather than bypassed: these
--    are occupancy starts derived from a charter rule, not election days wearing a disguise.
--
-- 🔴 DISTRICT IV IS THE EXCEPTION AND IS WRITTEN AT MONTH PRECISION. The November 2018 District
--    IV election was invalidated by the Hawaii Supreme Court; a court-ordered rerun was held in
--    April 2019 and Tommy Waters was sworn in in MAY 2019, months after the term began, with the
--    seat held on an interim basis until then. Two news outlets give 6 May and 8 May. The day is
--    disputed, so it is not asserted: `term_start = 2019-05-01`, `start_precision = 'month'`.
--    The gate at the foot of this file FAILS if that row is ever promoted to 'day'.
--
-- ═══ ⚠ WHAT THIS MIGRATION DELIBERATELY DOES NOT WRITE ═══
--
--  1. THE COUNCIL CHAIR. Tommy Waters chairs the council. The chair is elected by the nine from
--     among themselves and moves without an election, so it is a role, not a seat, and caching
--     it in a column would be the same mistake as caching "current".
--  2. THE PROSECUTING ATTORNEY'S TERM LIMIT. The LRB guide says the office "is not subject to
--     term limits". But the 2020 General carried a Honolulu charter question headed "Term Limits
--     for Prosecuting Attorney" which passed 294,387 (76.4%) to 59,589 (15.5%). Either the guide
--     is stale or the question did something narrower than its title. `term_limit` is left NULL
--     rather than guessed — a blank is correct, a wrong number is asserted to voters.
--  3. ANYTHING ABOUT THE 2026 ELECTION. Districts IV and VI are contested on 2026-11-03 and
--     District IV cannot return its sitting member — he was ruled ineligible for a third term and
--     the City Clerk will not count votes for him pending appeal. Weyer (II) and Okimoto (VIII)
--     are already re-elected outright. NONE of that changes who holds a seat today: every winner
--     takes office 2027-01-02. This migration seats today's holders and nothing else.
--  4. PARTY. The council, the Mayor and the Prosecuting Attorney are elected on a NONPARTISAN
--     ballot — the Office of Elections prints these contests with no party letter, unlike every
--     state legislative race on the same sheet. `offices.partisan_type` records that;
--     `politicians.party` stays NULL.

-- ── Pre-flight ────────────────────────────────────────────────────────────────
DO $$
DECLARE v_poly int; v_stray int; v_county_poly int; v_county_dist int; v_gov int; v_people int;
BEGIN
  SELECT count(*) INTO v_poly FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0082' AND geo_id LIKE 'honolulu-hi-council-district-%';
  IF v_poly <> 9 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: expected 9 X0082 Honolulu council polygons, found % — '
                    'run scripts/load-honolulu-council-districts.mjs first. An office on a '
                    'district with no polygon is unreachable by any address and nothing errors.', v_poly;
  END IF;

  SELECT count(*) INTO v_stray FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0082' AND geo_id NOT LIKE 'honolulu-hi-council-district-%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: % X0082 polygon(s) are not Honolulu council districts '
                    '— somebody else took this code', v_stray;
  END IF;

  -- (geo_id, mtfcc, state) — geo_id '15003' alone also matches 16 km² of Pennsylvania.
  SELECT count(*) INTO v_county_poly FROM essentials.geofence_boundaries
   WHERE geo_id = '15003' AND mtfcc = 'G4020' AND state = '15';
  IF v_county_poly <> 1 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: expected the TIGER county polygon 15003/G4020 in state 15 '
                    'for the Mayor and Prosecuting Attorney, found %', v_county_poly;
  END IF;

  SELECT count(*) INTO v_county_dist FROM essentials.districts
   WHERE geo_id = '15003' AND mtfcc = 'G4020' AND district_type = 'COUNTY';
  IF v_county_dist <> 1 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: expected exactly 1 existing COUNTY district row on '
                    '15003/G4020 to hang the citywide offices on, found %', v_county_dist;
  END IF;

  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name ILIKE '%honolulu%';
  IF v_gov <> 0 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: % government row(s) already mention Honolulu — this is '
                    'meant to be a greenfield seed, so read them before going further', v_gov;
  END IF;

  -- The identity scan behind this is in ROSTERS.md and ran both ways, with a control.
  SELECT count(*) INTO v_people FROM essentials.politicians p
   WHERE p.is_active AND (lower(btrim(p.last_name)), lower(btrim(p.first_name))) IN (
     ('tupola','andria'), ('weyer','matt'), ('nishimoto','scott'),
     ('dos santos-tam','tyler'), ('okimoto','val'), ('tulba','augusto'),
     ('blangiardi','rick'), ('alm','steven'));
  IF v_people <> 0 THEN
    RAISE EXCEPTION 'CC_0304 pre-flight: % active politician(s) already match a Honolulu official '
                    'on first+last name — re-read the identity scan in ROSTERS.md', v_people;
  END IF;
END $$;

-- ── Government ────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City and County of Honolulu, Hawaii, US', 'City', 'HI', 'Honolulu', '15003', 'G4020'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City and County of Honolulu, Hawaii, US');

-- ── Chambers ──────────────────────────────────────────────────────────────────
-- 🔴 `chambers.slug` is GENERATED ALWAYS from `name_formal`, NOT from `name`. Leaving
--    name_formal NULL silently generates an EMPTY slug, and the slug is what the app routes on.
--    Both are set, and the gate below asserts every slug is non-empty.
-- ⚠ term_limit is TEXT. The Prosecuting Attorney's is deliberately NULL — see note 2 above.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, term_limit,
   staggered_term, election_method, election_rules, inauguration_rules, website_url)
SELECT g.id, v.name, v.name, v.official_count, '4', v.term_limit,
       v.staggered, 'nonpartisan', v.election_rules, v.inauguration_rules, v.website_url
FROM essentials.governments g
JOIN (VALUES
  ('Honolulu City Council', 9::bigint, '2', true,
   'Nonpartisan. A candidate who wins a majority of the votes cast FOR A CANDIDATE at the August '
   || 'primary is elected outright; a sole candidate for a county office is declared elected under '
   || 'HRS 12-41(a) regardless of vote count; and a race with exactly two candidates skips the '
   || 'primary and is decided at the November general. Seats are staggered: the odd-numbered '
   || 'districts were elected in 2020 and 2024, the even-numbered in 2022 and 2026.',
   'Members take office on January 2 following their election.',
   'https://www.honolulucitycouncil.org/'),
  ('Office of the Mayor', 1::bigint, '2', false,
   'Nonpartisan, elected county-wide. Same primary-majority rule as the council: Rick Blangiardi '
   || 'was elected outright at the 2024 primary on 78.0% of votes cast for a candidate.',
   'Takes office on January 2 following the election.',
   'https://www.honolulu.gov/mayor/'),
  ('Department of the Prosecuting Attorney', 1::bigint, NULL, false,
   'Nonpartisan, elected county-wide. The office-holder must be a licensed attorney in good '
   || 'standing before the Hawaii Supreme Court with at least five years in practice and criminal '
   || 'experience in three of the ten years before election.',
   'Takes office on January 2 following the election.',
   'https://honoluluprosecutor.org/')
) AS v(name, official_count, term_limit, staggered, election_rules, inauguration_rules, website_url) ON true
WHERE g.name = 'City and County of Honolulu, Hawaii, US'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = v.name);

-- ── Districts ─────────────────────────────────────────────────────────────────
-- Only the nine council districts. The countywide offices reuse the existing
-- 'Honolulu County' row on 15003/G4020/COUNTY.
-- ⚠ The city numbers its districts in ROMAN NUMERALS and so does the ballot. The slug keeps the
--   arabic number because that is what the polygon loader writes; the LABEL and the office TITLE
--   carry the numeral a voter actually saw.
CREATE TEMP TABLE hnl_districts(geo_id text, label text, num int) ON COMMIT DROP;
INSERT INTO hnl_districts(geo_id, label, num) VALUES
  ('honolulu-hi-council-district-1', 'Honolulu City Council District I',    1),
  ('honolulu-hi-council-district-2', 'Honolulu City Council District II',   2),
  ('honolulu-hi-council-district-3', 'Honolulu City Council District III',  3),
  ('honolulu-hi-council-district-4', 'Honolulu City Council District IV',   4),
  ('honolulu-hi-council-district-5', 'Honolulu City Council District V',    5),
  ('honolulu-hi-council-district-6', 'Honolulu City Council District VI',   6),
  ('honolulu-hi-council-district-7', 'Honolulu City Council District VII',  7),
  ('honolulu-hi-council-district-8', 'Honolulu City Council District VIII', 8),
  ('honolulu-hi-council-district-9', 'Honolulu City Council District IX',   9);

INSERT INTO essentials.districts (geo_id, label, district_type, state, city, mtfcc, num_officials)
SELECT n.geo_id, n.label, 'LOCAL', 'hi', 'Honolulu', 'X0082', 1
FROM hnl_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = n.geo_id AND d.mtfcc = 'X0082' AND d.district_type = 'LOCAL');

-- ── Offices ───────────────────────────────────────────────────────────────────
CREATE TEMP TABLE hnl_offices(geo_id text, mtfcc text, dtype text, chamber_name text, title text, descr text)
  ON COMMIT DROP;
INSERT INTO hnl_offices(geo_id, mtfcc, dtype, chamber_name, title, descr) VALUES
  ('honolulu-hi-council-district-1','X0082','LOCAL','Honolulu City Council','Councilmember, District I',    NULL),
  ('honolulu-hi-council-district-2','X0082','LOCAL','Honolulu City Council','Councilmember, District II',   NULL),
  ('honolulu-hi-council-district-3','X0082','LOCAL','Honolulu City Council','Councilmember, District III',  NULL),
  ('honolulu-hi-council-district-4','X0082','LOCAL','Honolulu City Council','Councilmember, District IV',   NULL),
  ('honolulu-hi-council-district-5','X0082','LOCAL','Honolulu City Council','Councilmember, District V',    NULL),
  ('honolulu-hi-council-district-6','X0082','LOCAL','Honolulu City Council','Councilmember, District VI',   NULL),
  ('honolulu-hi-council-district-7','X0082','LOCAL','Honolulu City Council','Councilmember, District VII',  NULL),
  ('honolulu-hi-council-district-8','X0082','LOCAL','Honolulu City Council','Councilmember, District VIII', NULL),
  ('honolulu-hi-council-district-9','X0082','LOCAL','Honolulu City Council','Councilmember, District IX',   NULL),
  ('15003','G4020','COUNTY','Office of the Mayor','Mayor',
     'Chief executive of the City and County of Honolulu, elected county-wide to a four-year term '
     || 'and limited to two consecutive full terms. Honolulu is a strong-mayor government: the '
     || 'Mayor is not a member of the Council, may veto its bills, and supervises the executive '
     || 'departments through an appointed Managing Director.'),
  ('15003','G4020','COUNTY','Department of the Prosecuting Attorney','Prosecuting Attorney',
     'Elected county-wide to a four-year term. Conducts all prosecutions in the City and County '
     || 'for offences against state law and city ordinances, and appoints deputy prosecutors and '
     || 'investigators who hold the powers of a police officer of the City.');

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant,
   voting_powers, partisan_type, description)
SELECT c.id, d.id, n.title, 'HI', 'Honolulu', 1, false, 'full', 'nonpartisan', n.descr
FROM hnl_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = n.mtfcc AND d.district_type = n.dtype
JOIN essentials.governments g ON g.name = 'City and County of Honolulu, Hawaii, US'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = n.title);

-- ── People ────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE hnl_roster(
  title       text PRIMARY KEY,
  full_name   text NOT NULL,
  first_name  text NOT NULL,
  last_name   text NOT NULL,
  term_start  date NOT NULL,
  precision   text NOT NULL,
  source      text NOT NULL,
  office_id     uuid,
  politician_id uuid
) ON COMMIT DROP;

INSERT INTO hnl_roster(title, full_name, first_name, last_name, term_start, precision, source) VALUES
  ('Councilmember, District I', 'Andria Tupola', 'Andria', 'Tupola', DATE '2021-01-02', 'day',
   'Hawaii Office of Elections certified 2020 Primary summary (City & County of Honolulu), read 2026-10-28 (CC_0304): Tupola 14,420 of 24,229 votes cast for a candidate (59.5%), a majority, so elected outright at the primary. Took office 2021-01-02 per the charter rule. Re-elected at the 2024 primary.'),
  ('Councilmember, District II', 'Matt Weyer', 'Matt', 'Weyer', DATE '2023-01-02', 'day',
   'Certified 2022 General summary, read 2026-10-28 (CC_0304): Weyer 11,613 to Rothman 9,268. Took office 2023-01-02. Re-elected outright at the 2026 primary as sole candidate; that term begins 2027-01-02 and is NOT written here.'),
  ('Councilmember, District III', E'Esther Kiaʻāina', 'Esther', E'Kiaʻāina', DATE '2021-01-02', 'day',
   'Certified 2020 General summary, read 2026-10-28 (CC_0304): Kiaaina 27,895 to Thielen 19,143. Took office 2021-01-02. Re-elected at the 2024 primary on 12,197 of 20,947 votes cast for a candidate (58.2%) — the sheet PRINTS 47.5% because its denominator includes 4,720 blank votes; the 2024 General carries no Honolulu council race, which confirms it.'),
  ('Councilmember, District IV', 'Thomas Waters', 'Thomas', 'Waters', DATE '2019-05-01', 'month',
   'The November 2018 District IV election was invalidated by the Hawaii Supreme Court and a court-ordered rerun held in April 2019, which Waters won; he was sworn in in May 2019, the seat having been held on an interim basis since 2 January. Reporting disagrees on the day (6 vs 8 May), so this is MONTH precision and must not be promoted without a primary source. Re-elected at the 2022 General, 28,512 to Nakoa 10,203.'),
  ('Councilmember, District V', 'Scott Y. Nishimoto', 'Scott', 'Nishimoto', DATE '2025-01-02', 'day',
   'Certified 2024 Primary summary, read 2026-10-28 (CC_0304): Nishimoto 13,399 of 18,839 votes cast for a candidate (71.1%), a majority, so elected outright. Took office 2025-01-02. Succeeded Calvin K.Y. Say, who won District V in 2020.'),
  ('Councilmember, District VI', 'Tyler Dos Santos-Tam', 'Tyler', 'Dos Santos-Tam', DATE '2023-01-02', 'day',
   'Certified 2022 General summary, read 2026-10-28 (CC_0304): Dos Santos-Tam 13,496 to Toguchi 11,247. Took office 2023-01-02. On the 2026 General ballot against Corey Morihara; that race is unresolved and is NOT written here.'),
  ('Councilmember, District VII', 'Radiant Cordero', 'Radiant', 'Cordero', DATE '2021-01-02', 'day',
   'The councilmember''s own page states "Serving Since: Jan. 2, 2021", and the certified 2020 General summary gives Cordero 12,730 to Aki 11,342. Read 2026-10-28 (CC_0304). This is the row that establishes the January 2 convention used for the other nine.'),
  ('Councilmember, District VIII', 'Val Aquino Okimoto', 'Val', 'Okimoto', DATE '2023-01-02', 'day',
   'Certified 2022 General summary, read 2026-10-28 (CC_0304): Okimoto 22,456 to the incumbent Ron Menor 16,745. Took office 2023-01-02. Re-elected outright at the 2026 primary as sole candidate; that term begins 2027-01-02 and is NOT written here.'),
  ('Councilmember, District IX', 'Augusto E. Tulba', 'Augusto', 'Tulba', DATE '2021-01-02', 'day',
   'Certified 2020 General summary, read 2026-10-28 (CC_0304): Tulba 21,265 to Espero 19,702. Took office 2021-01-02; his own page says "first elected to the Honolulu City Council in November 2020 and then re-elected in August 2024". The certified sheet prints the ballot name TULBA, Augusto E. (AugieT); the council calls him Augie.'),
  ('Mayor', 'Rick Blangiardi', 'Rick', 'Blangiardi', DATE '2021-01-02', 'day',
   'Certified 2020 General summary, read 2026-10-28 (CC_0304): Blangiardi 224,474 to Amemiya 149,735. Took office 2021-01-02. Re-elected outright at the 2024 primary on 125,076 of 160,302 votes cast for a candidate (78.0%).'),
  ('Prosecuting Attorney', 'Steven S. Alm', 'Steven', 'Alm', DATE '2021-01-02', 'day',
   'Certified 2020 General summary, read 2026-10-28 (CC_0304): Alm 199,399 to Kau 159,745. Took office 2021-01-02. Re-elected at the 2024 primary as the sole candidate on 127,367 votes, declared elected under HRS 12-41(a).');

UPDATE hnl_roster r SET office_id = o.id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE g.name = 'City and County of Honolulu, Hawaii, US' AND o.title = r.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM hnl_roster WHERE office_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0304: % roster row(s) did not resolve to a Honolulu office', n;
  END IF;
  SELECT count(*) INTO n FROM hnl_roster r
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = r.office_id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0304: % Honolulu office(s) already carry a term — this is meant to be a '
                    'greenfield seed, so read those rows before going further', n;
  END IF;
END $$;

-- 🔴 `is_incumbent` is set EXPLICITLY on every insert. It defaults to false, and a seated person
--    inserted without it is HIDDEN from address search; `check:occupancy` fails an INSERT that
--    omits it. `party` stays NULL: these are nonpartisan offices.
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT r.full_name, r.first_name, r.last_name, true, true, r.source
  FROM hnl_roster r
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
      AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
      AND p.is_active);

UPDATE hnl_roster r SET politician_id = p.id
  FROM essentials.politicians p
 WHERE lower(btrim(p.first_name)) = lower(btrim(r.first_name))
   AND lower(btrim(p.last_name))  = lower(btrim(r.last_name))
   AND p.is_active;

-- ── Seating ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN SELECT * FROM hnl_roster ORDER BY title LOOP
    IF r.politician_id IS NULL THEN
      RAISE EXCEPTION 'CC_0304: % did not resolve to a person', r.title;
    END IF;
    INSERT INTO essentials.office_terms
      (office_id, politician_id, term_start, start_precision, how_started, source)
    VALUES (r.office_id, r.politician_id, r.term_start, r.precision, 'elected', r.source);
    n := n + 1;
  END LOOP;
  IF n <> 11 THEN RAISE EXCEPTION 'CC_0304: expected 11 seatings, got %', n; END IF;
END $$;

-- ── Post-verify gate ──────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_slug int; v_dist int; v_off int;
  v_council int; v_mayor int; v_pros int;
  v_held int; v_month int; v_day int; v_notincumbent int; v_party int;
  v_nogeom int; v_vacant int; v_appointed int; v_limit text;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE name = 'City and County of Honolulu, Hawaii, US' AND geo_id = '15003' AND mtfcc = 'G4020';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0304 gate: expected 1 Honolulu government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'CC_0304 gate: expected 3 chambers, found %', v_ch; END IF;

  -- The generated slug is what the app routes on; an empty one is a silent 404.
  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US'
     AND (c.slug IS NULL OR btrim(c.slug) = '');
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'CC_0304 gate: % Honolulu chamber(s) generated an EMPTY slug — name_formal was not set', v_slug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE mtfcc = 'X0082' AND district_type = 'LOCAL' AND lower(state) = 'hi';
  IF v_dist <> 9 THEN RAISE EXCEPTION 'CC_0304 gate: expected 9 council districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_off <> 11 THEN RAISE EXCEPTION 'CC_0304 gate: expected 11 Honolulu offices, found %', v_off; END IF;

  SELECT count(*) FILTER (WHERE c.name = 'Honolulu City Council'),
         count(*) FILTER (WHERE c.name = 'Office of the Mayor'),
         count(*) FILTER (WHERE c.name = 'Department of the Prosecuting Attorney')
    INTO v_council, v_mayor, v_pros
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_council <> 9 OR v_mayor <> 1 OR v_pros <> 1 THEN
    RAISE EXCEPTION 'CC_0304 gate: chamber sizes are %/9 council, %/1 mayor, %/1 prosecutor',
                    v_council, v_mayor, v_pros;
  END IF;

  -- 🔴 Every office is HELD. An office with no term row is invisible and nothing errors.
  --    Counted on och.politician_id, because office_current_holder LEFT JOINs from offices and
  --    a vacancy is a NULL politician_id that would pass a count(*) vacuously.
  SELECT count(och.politician_id) INTO v_held
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_held <> 11 THEN RAISE EXCEPTION 'CC_0304 gate: expected 11 held offices, found %', v_held; END IF;

  -- District IV is the only month-precision row, and it must stay that way.
  SELECT count(*) FILTER (WHERE t.start_precision = 'month'),
         count(*) FILTER (WHERE t.start_precision = 'day')
    INTO v_month, v_day
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_month <> 1 OR v_day <> 10 THEN
    RAISE EXCEPTION 'CC_0304 gate: expected 1 month-precision start (District IV) and 10 day, got % and %',
                    v_month, v_day;
  END IF;

  SELECT count(*) INTO v_notincumbent
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US'
     AND (p.is_incumbent IS NOT TRUE OR p.is_active IS NOT TRUE);
  IF v_notincumbent <> 0 THEN
    RAISE EXCEPTION 'CC_0304 gate: % seated Honolulu official(s) are not active incumbents — they '
                    'would be hidden from address search', v_notincumbent;
  END IF;

  -- Nonpartisan offices: no party may be written on an officeholder.
  SELECT count(*) INTO v_party
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US'
     AND coalesce(btrim(p.party), '') <> '';
  IF v_party <> 0 THEN
    RAISE EXCEPTION 'CC_0304 gate: % Honolulu officeholder(s) carry a party — these are '
                    'nonpartisan offices and party belongs on races.primary_party', v_party;
  END IF;

  -- Every office resolves to a polygon on the (geo_id, mtfcc) PAIR.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0304 gate: % Honolulu office(s) sit on a district with no polygon and are '
                    'unreachable by any address', v_nogeom;
  END IF;

  SELECT count(*) FILTER (WHERE o.is_vacant), count(*) FILTER (WHERE o.is_appointed_position)
    INTO v_vacant, v_appointed
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US';
  IF v_vacant <> 0 OR coalesce(v_appointed, 0) <> 0 THEN
    RAISE EXCEPTION 'CC_0304 gate: expected 0 vacant and 0 appointed Honolulu offices, got % and %',
                    v_vacant, v_appointed;
  END IF;

  -- The Prosecuting Attorney's term limit stays unresolved on purpose (note 2).
  SELECT c.term_limit INTO v_limit FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City and County of Honolulu, Hawaii, US'
     AND c.name = 'Department of the Prosecuting Attorney';
  IF v_limit IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0304 gate: the Prosecuting Attorney term_limit is %, but the sources '
                    'conflict and it must stay NULL until the 2020 charter amendment is read', v_limit;
  END IF;

  RAISE NOTICE 'CC_0304 OK: 1 government, 3 chambers, 9 new districts, 11 offices, 11 seated.';
END $$;
