-- 1749_seattle_incumbents.sql
-- Seats the 11 City of Seattle officials: Mayor, 9 councilmembers, City Attorney.
--
-- SOURCES
--   Roster + seat mapping + emails : seattle.gov/council/members — the page
--     publishes an explicit "District N:" -> name list, so seats are read, never
--     inferred from the order members appear on the page.
--   Terms + appointment status     : the City Clerk's Terms of Office page
--     (seattle.gov/city-clerk/.../terms-of-office-for-elected-officials).
--   Assumed-office dates           : Ballotpedia's Seattle officers table,
--     which gives FIRST assumption of the seat rather than current-term start.
--
-- WHY TWO DATE SOURCES MATTER. The City Clerk lists the CURRENT term ("Elected
-- 11/2023, expires 12/2027"), which for several members is not when they began
-- serving. Dan Strauss has held District 6 since 2020-01-01, and Alexis Mercedes
-- Rinck has held Position 8 since 2024-11-26 (won at a special election), not the
-- start of their current terms. Using the Clerk's dates alone would have
-- understated both tenures. term_start here is FIRST assumption of the seat,
-- matching the convention used for the 147 legislators.
--
-- EMAILS are the ones published on the council page, never pattern-inferred:
-- Rinck's is AlexisMercedes.Rinck@seattle.gov, which does NOT follow the
-- firstname.lastname form every other member uses. The Mayor and City Attorney
-- are left NULL — their addresses are not published on the pages consulted.
--
-- PARTY IS NULL on every row and that is correct, not missing: Seattle city
-- offices are NONPARTISAN (Ballotpedia lists every one of them as such).
--
-- DEBORA JUAREZ (District 5) is is_appointed=true. She was appointed 2025-07-28
-- to replace Cathy Moore, who resigned in July 2025, and under the City Charter
-- serves "until a successor is elected and qualified" at a special election held
-- in concert with the 2026 state general election. That is exactly why Seattle
-- HAS a 2026 council race — District 5 — even though every other city seat runs
-- on the odd-year cycle. She is not a candidate for it.
--
-- ROBERT KETTLE is seeded under his formal name, which the City Clerk and his
-- own seattle.gov address (robert.kettle@seattle.gov) use; "Bob Kettle" appears
-- on the council page and in Ballotpedia and is kept as an alternate name.
--
-- Single statement by necessity: the office_terms insert must resolve
-- politician_id for rows this same statement creates, so the politician insert is
-- a data-modifying CTE whose RETURNING output is unioned with pre-existing rows.

WITH seed (ext_id, full_name, first_name, last_name, email, aliases,
           chamber_name, title, term_start, precision, appointed) AS (
  VALUES
    (-5363001::bigint, 'Katie Wilson'::text, 'Katie'::text, 'Wilson'::text, NULL::text, ARRAY[]::text[], 'Mayor'::text, 'Mayor'::text, DATE '2026-01-01', 'day'::text, false),
    (-5363002, 'Rob Saka',              'Rob',      'Saka',          'rob.saka@seattle.gov',              ARRAY[]::text[],              'City Council',  'Councilmember, District 1',            DATE '2024-01-01', 'day', false),
    (-5363003, 'Eddie Lin',             'Eddie',    'Lin',           'eddie.lin@seattle.gov',             ARRAY[]::text[],              'City Council',  'Councilmember, District 2',            DATE '2026-01-01', 'day', false),
    (-5363004, 'Joy Hollingsworth',     'Joy',      'Hollingsworth', 'joy.hollingsworth@seattle.gov',     ARRAY[]::text[],              'City Council',  'Councilmember, District 3',            DATE '2024-01-01', 'day', false),
    (-5363005, 'Maritza Rivera',        'Maritza',  'Rivera',        'maritza.rivera@seattle.gov',        ARRAY[]::text[],              'City Council',  'Councilmember, District 4',            DATE '2024-01-01', 'day', false),
    (-5363006, 'Debora Juarez',         'Debora',   'Juarez',        'debora.juarez@seattle.gov',         ARRAY[]::text[],              'City Council',  'Councilmember, District 5',            DATE '2025-07-28', 'day', true),
    (-5363007, 'Dan Strauss',           'Dan',      'Strauss',       'dan.strauss@seattle.gov',           ARRAY[]::text[],              'City Council',  'Councilmember, District 6',            DATE '2020-01-01', 'day', false),
    (-5363008, 'Robert Kettle',         'Robert',   'Kettle',        'robert.kettle@seattle.gov',         ARRAY['Bob Kettle']::text[],  'City Council',  'Councilmember, District 7',            DATE '2024-01-01', 'day', false),
    (-5363009, 'Alexis Mercedes Rinck', 'Alexis',   'Rinck',         'AlexisMercedes.Rinck@seattle.gov',  ARRAY[]::text[],              'City Council',  'Councilmember, Position 8 (Citywide)', DATE '2024-11-26', 'day', false),
    (-5363010, 'Dionne Foster',         'Dionne',   'Foster',        'dionne.foster@seattle.gov',         ARRAY[]::text[],              'City Council',  'Councilmember, Position 9 (Citywide)', DATE '2026-01-01', 'day', false),
    (-5363011, 'Erika Evans',           'Erika',    'Evans',         NULL,                                ARRAY[]::text[],              'City Attorney', 'City Attorney',                        DATE '2026-01-01', 'day', false)
),
ins AS (
  INSERT INTO essentials.politicians
    (external_id, full_name, first_name, last_name, party, party_short_name,
     email_addresses, alternate_names, is_incumbent, is_active, is_appointed, data_source)
  SELECT s.ext_id, s.full_name, s.first_name, s.last_name, NULL, NULL,
         CASE WHEN s.email IS NULL THEN NULL ELSE ARRAY[s.email]::text[] END,
         s.aliases, true, true, s.appointed,
         'seattle.gov/council/members for roster, explicit district mapping and published emails; City Clerk Terms of Office page for term and appointment status; Ballotpedia Seattle officers table for first-assumption dates. Retrieved 2026-08-13.'
  FROM seed s
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id, external_id
),
pol AS (
  SELECT id, external_id FROM ins
  UNION
  SELECT p.id, p.external_id FROM essentials.politicians p JOIN seed s ON s.ext_id = p.external_id
)
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, source)
SELECT o.id, pol.id, s.term_start, NULL, s.precision,
       'seattle.gov/council/members for roster, explicit district mapping and published emails; City Clerk Terms of Office page for term and appointment status; Ballotpedia Seattle officers table for first-assumption dates. Retrieved 2026-08-13.'
FROM seed s
JOIN essentials.governments g ON g.geo_id = '5363000' AND g.type = 'City'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = s.chamber_name
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = s.title
JOIN pol ON pol.external_id = s.ext_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
  WHERE ot.office_id = o.id AND ot.politician_id = pol.id
);
