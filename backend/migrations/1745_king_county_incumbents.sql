-- 1745_king_county_incumbents.sql
-- Seats the 14 King County officials: Executive, 9 councilmembers, Prosecuting
-- Attorney, Assessor, Director of Elections, and the appointed Sheriff.
--
-- SOURCES
--   Council roster + official emails : King County's own GIS layer
--     KCCDST_AREA_185 (COUNCILMEM / EMAIL attributes), cross-checked against
--     the kingcounty.gov council page — all 9 names present on both.
--   Countywide officers : their own kingcounty.gov department pages
--     (Manion /dept/pao, Wilson /dept/assessor, Wise /dept/elections,
--      Zahilay /dept/executive).
--   Assumed-office dates : Ballotpedia's King County officers table.
--
-- NAMES — the official county source wins, and it corrected BOTH other sources:
--   D4  Jorge L. Barón      The GIS attribute says "Jorge Baron" (diacritic
--                           stripped, no middle initial) and Ballotpedia says
--                           "Jorge Barón". The county's own bio page title is
--                           "Jorge L. Barón". Both variants kept as aliases.
--   D7  Pete von Reichbauer The council landing page renders "Peter von
--                           Reichbauer" in one place, but his bio page title
--                           and 13 other occurrences say "Pete". "Pete" wins.
--
-- PARTY IS NULL for every row, and that is correct rather than missing: King
-- County offices are officially NONPARTISAN (2008 charter amendment). Recording
-- a party here would be inventing one.
--
-- EMAILS are populated only for the 9 councilmembers, where the county GIS layer
-- publishes them. The 5 countywide officers are left NULL — their addresses were
-- not published on the pages consulted, and pattern-inferred emails are never
-- acceptable.
--
-- DATE PRECISION is recorded, not fabricated: 9 rows have a full assumed-office
-- date ('day'); 4 carry only a year, stored as YYYY-01-01 with 'year' precision
-- (Dembowski 2013, Balducci 2016, von Reichbauer 1994, Dunn 2005, Wise 2016);
-- the Sheriff's May 2022 appointment is stored as 2022-05-01 with 'month'.
--
-- SHERIFF is is_appointed=true — appointed under the 2020 charter amendment,
-- re-appointed by Executive Zahilay in November 2025. Her chamber carries
-- policy_engagement_level='none' from migration 1744.
--
-- Council Chair is a title on a seat, not a separate office — no tenth row.
--
-- Single statement by necessity: the office_terms insert must resolve
-- politician_id for rows this same statement creates, so the politician insert is
-- a data-modifying CTE whose RETURNING output is unioned with pre-existing rows.
-- Offices are matched on (chamber name, title) scoped to the 53033 County
-- government — geo_id 53033 alone also matches Legislative Districts 33 upper and
-- lower, so the district_type/mtfcc predicates are load-bearing.

WITH seed (ext_id, full_name, first_name, last_name, email, aliases,
           chamber_name, title, term_start, precision, appointed) AS (
  VALUES
    (-5303301::bigint, 'Girmay Zahilay'::text, 'Girmay'::text, 'Zahilay'::text, NULL::text, ARRAY[]::text[], 'County Executive'::text,      'County Executive'::text,          DATE '2025-11-25', 'day'::text,   false),
    (-5303302, 'Rod Dembowski',       'Rod',      'Dembowski',      'Rod.Dembowski@kingcounty.gov',      ARRAY[]::text[],                              'County Council',        'Councilmember, District 1',  DATE '2013-01-01', 'year',  false),
    (-5303303, 'Rhonda Lewis',        'Rhonda',   'Lewis',          'Rhonda.Lewis@kingcounty.gov',       ARRAY[]::text[],                              'County Council',        'Councilmember, District 2',  DATE '2025-12-09', 'day',   false),
    (-5303304, 'Sarah Perry',         'Sarah',    'Perry',          'Sarah.Perry@kingcounty.gov',        ARRAY[]::text[],                              'County Council',        'Councilmember, District 3',  DATE '2022-01-01', 'day',   false),
    (-5303305, 'Jorge L. Barón',      'Jorge',    'Barón',          'Jorge.Baron@kingcounty.gov',        ARRAY['Jorge Baron','Jorge Barón']::text[],   'County Council',        'Councilmember, District 4',  DATE '2024-01-01', 'day',   false),
    (-5303306, 'Steffanie Fain',      'Steffanie','Fain',           'Steffanie.Fain@kingcounty.gov',     ARRAY[]::text[],                              'County Council',        'Councilmember, District 5',  DATE '2026-01-01', 'day',   false),
    (-5303307, 'Claudia Balducci',    'Claudia',  'Balducci',       'Claudia.Balducci@kingcounty.gov',   ARRAY[]::text[],                              'County Council',        'Councilmember, District 6',  DATE '2016-01-01', 'year',  false),
    (-5303308, 'Pete von Reichbauer', 'Pete',     'von Reichbauer', 'Pete.vonReichbauer@kingcounty.gov', ARRAY['Peter von Reichbauer']::text[],        'County Council',        'Councilmember, District 7',  DATE '1994-01-01', 'year',  false),
    (-5303309, 'Teresa Mosqueda',     'Teresa',   'Mosqueda',       'Teresa.Mosqueda@kingcounty.gov',    ARRAY[]::text[],                              'County Council',        'Councilmember, District 8',  DATE '2024-01-01', 'day',   false),
    (-5303310, 'Reagan Dunn',         'Reagan',   'Dunn',           'Reagan.Dunn@kingcounty.gov',        ARRAY[]::text[],                              'County Council',        'Councilmember, District 9',  DATE '2005-01-01', 'year',  false),
    (-5303311, 'Leesa Manion',        'Leesa',    'Manion',         NULL,                                ARRAY[]::text[],                              'Prosecuting Attorney',  'Prosecuting Attorney',       DATE '2023-01-01', 'day',   false),
    (-5303312, 'John Wilson',         'John',     'Wilson',         NULL,                                ARRAY[]::text[],                              'Assessor',              'Assessor',                   DATE '2016-01-01', 'day',   false),
    (-5303313, 'Julie Wise',          'Julie',    'Wise',           NULL,                                ARRAY[]::text[],                              'Director of Elections', 'Director of Elections',      DATE '2016-01-01', 'year',  false),
    (-5303314, 'Patti Cole-Tindall',  'Patti',    'Cole-Tindall',   NULL,                                ARRAY[]::text[],                              'Sheriff',               'Sheriff',                    DATE '2022-05-01', 'month', true)
),
ins AS (
  INSERT INTO essentials.politicians
    (external_id, full_name, first_name, last_name, party, party_short_name,
     email_addresses, alternate_names, is_incumbent, is_active, is_appointed, data_source)
  SELECT s.ext_id, s.full_name, s.first_name, s.last_name, NULL, NULL,
         CASE WHEN s.email IS NULL THEN NULL ELSE ARRAY[s.email]::text[] END,
         s.aliases, true, true, s.appointed,
         'King County GIS layer KCCDST_AREA_185 (council roster + official emails), cross-checked against the kingcounty.gov council page; countywide officers from their kingcounty.gov department pages; assumed-office dates from Ballotpedia King County officers table. Retrieved 2026-08-13.'
  FROM seed s
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id, external_id
),
pol AS (
  SELECT id, external_id FROM ins
  UNION
  SELECT p.id, p.external_id FROM essentials.politicians p
  JOIN seed s ON s.ext_id = p.external_id
)
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, source)
SELECT o.id, pol.id, s.term_start, NULL, s.precision,
       'King County GIS layer KCCDST_AREA_185 (council roster + official emails), cross-checked against the kingcounty.gov council page; countywide officers from their kingcounty.gov department pages; assumed-office dates from Ballotpedia King County officers table. Retrieved 2026-08-13.'
FROM seed s
JOIN essentials.governments g ON g.geo_id = '53033' AND g.type = 'County'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = s.chamber_name
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = s.title
JOIN pol ON pol.external_id = s.ext_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
  WHERE ot.office_id = o.id AND ot.politician_id = pol.id
);
