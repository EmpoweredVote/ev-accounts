-- Migration 1798: seed Kitsap County, WA and the City of Bainbridge Island, WA
--                 16 elected officials, every one with a REAL term_end.
--
-- ============================================================================
-- WHY THIS ONE IS DIFFERENT: IT IS BORN WITH EXPIRY DATES
-- ============================================================================
-- 5,611 of the 5,626 real-seat office_terms rows in this corpus are OPEN-ENDED. Only 15 carry a
-- term_end. That means the corpus asserts nearly every officeholder is serving forever, and it is
-- how a dead Lawrence County councilman stayed seated for eight months (migration 1796) and how
-- Mark Hill stayed on the Frisco ISD board after becoming mayor (migration 1794). Neither was
-- detectable from inside the data — both were found by reading an official roster.
--
-- Both rosters here PUBLISH TERM EXPIRY, so every one of these 16 seats is seeded with it. Kitsap
-- and Bainbridge do not join that backlog. When these terms lapse the seats read vacant on their
-- own, with nothing scheduled and nobody remembering to look.
--
-- ── SOURCES, read 2026-08-17 ───────────────────────────────────────────────────────────────────
--   Kitsap:      kitsap.gov/auditor/Pages/Elected_Officials.aspx — a six-column table (Office /
--                Name / Term of Office / Date Elected / Next Election Year / Date Originally
--                Elected or Appointed) plus a "County History" block listing appointments and
--                resignations. Page stamped "Updated 12/31/2024".
--   Bainbridge:  bainbridgewa.gov/217/City-Council — four-column table (Name / Ward-District /
--                Contact / Term Expires) and the 2026 council photo caption.
--   GEOIDs:      verified against Census TIGERweb, NOT taken from a search result —
--                Kitsap County GEOID 53035 (MTFCC G4020); Bainbridge Island city GEOID 5303736
--                (MTFCC G4110, LSADC 25). The place lives in the Incorporated Places layer (4);
--                the County Subdivisions layer returns nothing for it.
--
-- 🔴 BOTH TABLES WERE PARSED CELL-BY-CELL, NOT SUMMARISED. Migration 1666 (Marin) records why: a
-- two-column officials page mispaired 9 of its 15 rows under text extraction, and no identity gate
-- can catch that, because the gate compares the seated name to what I INTENDED and I would have
-- intended the wrong thing. Every name/office/date pairing below comes from aligned <td> cells.
--
-- ============================================================================
-- OCCUPANCY IS NOT THE CURRENT TERM — and Kitsap publishes both
-- ============================================================================
-- The Kitsap page separates "Term of Office" (the term now being served) from "Date Originally
-- Elected or Appointed", and its County History block dates the appointments. office_terms models
-- OCCUPANCY, so term_start is when the person took the seat, not when the current term began:
--
--   Rolfes      2023-06  appointed  County History: "June 2023 - Christine Rolfes appointed
--                                   District 1 County Commissioner"; "May 2023 - Rob Gelder,
--                                   District 1 County Commissioner, resigns". Elected Nov 2024.
--                                   Her CURRENT term reads Jan 2025 - Dec 2028; occupancy is 2023.
--   Root        2025-01  elected    Elected Nov 2024, term Jan 2025 - Dec 2028. First term.
--   Walters     2023-01  elected    Elected Nov 2022, term Jan 2023 - Dec 2026.
--   Cook        2015-01  elected    "Elected Nov. 2014" in the originally-elected column.
--   Andrews     2019-01  elected    "Elected Nov. 2018".
--   Lewis       2021-09  appointed  County History: "September 2021 - David Lewis appointed County
--                                   Clerk"; "July 2021 - Alison Sonntag, County Clerk, resigns."
--   Enright     2019-01  elected    "Elected Nov. 2018".
--   Gese        2021-08  appointed  County History: "August 2021 - John Gese appointed Kitsap
--                                   County Sheriff."; "June 2021 - Gary Simpson, County Sheriff,
--                                   resigns."
--   Boissonneau 2023-01  elected    Elected Nov 2022.
--
-- ALL MONTH PRECISION. The county publishes month-and-year and never a day, so start_precision is
-- 'month' throughout and no day is invented (ADR 0002: imprecision is recorded, not manufactured).
-- term_end likewise reads "Dec. 2026"/"Dec. 2028"; encoded as the 31st, which is a month-precision
-- reading, not a claim about the swearing-in of a successor. office_terms has no end_precision
-- column, hence this note.
--
-- 🔴 BAINBRIDGE term_start IS DELIBERATELY NULL / 'unknown'. The council page publishes only "Term
-- Expires". Council terms are four years on odd-year elections, so the CURRENT term is derivable
-- (expiry 2027 => began 2024-01; expiry 2029 => began 2026-01) — but that is the term, not the
-- occupancy, and several of these members have served multiple terms. Deriving it would encode a
-- guess as a fact. NULL with start_precision 'unknown' is the policy answer. The term_end, which
-- is the load-bearing half for drift, is real and published.
--
-- ============================================================================
-- 🔴 MODELLING CALL: BAINBRIDGE HAS NO SEPARATE "MAYOR" OFFICE, AND THAT IS ON PURPOSE
-- ============================================================================
-- Bainbridge Island is council-manager. The mayor is the council's own chair, chosen biennially by
-- and from the seven members — Clarence Moriwaki took a one-year term in January 2026 and Kirsten
-- Hytopoulos a six-month deputy term. NO VOTER ELECTS A MAYOR HERE.
--
-- Creating a "Mayor" office would (a) advertise a seat nobody can vote for, and (b) put Moriwaki on
-- two concurrent seats — the exact single-row conflation signature that migration 1788 had to undo
-- and that migration 1794's merge had to be written around. So the mayoralty is recorded as a ROLE
-- in the office's representation_note, not as a seat.
-- ⚠ This DIVERGES from how Cambridge and South Portland are modelled in this corpus, where the
-- mayor-who-is-also-a-councillor holds two office rows and shows up as a known-legitimate hit in
-- the two-current-occupancy detector. Flagging the divergence rather than quietly picking a side:
-- if the house style is two rows, this is the migration to change.
--
-- ============================================================================
-- SCOPE
-- ============================================================================
-- 16 core electeds. Kitsap's Superior and District Court benches are NOT seeded here — judges carry
-- their own compass and discipline-display rules and belong in a follow-on. Bainbridge Island School
-- District is out of scope (school districts are search-only in this corpus).
-- Bainbridge has NO 2026 races: WA city elections are odd-year, which is exactly why these terms
-- expire in 2027 and 2029. The seven Kitsap offices on the 2026 ballot are migration 1799.
--
-- policy_engagement_level follows the King County precedent for matching offices and the research
-- method rule for the rest: commissioners and the Prosecuting Attorney generate attributable
-- positions, the administrative offices generally do not.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision declaration is
-- required. No IDs are hardcoded — every parent is resolved by natural key.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Governments
-- ---------------------------------------------------------------------------
INSERT INTO essentials.governments (name, type, state, city, geo_id)
VALUES ('Kitsap County, Washington, US',              'County', 'WA', NULL,               '53035'),
       ('City of Bainbridge Island, Washington, US',  'City',   'WA', 'Bainbridge Island','5303736');

-- ---------------------------------------------------------------------------
-- 2. Chambers — one per office family, matching how King County is modelled.
--    🔴 `chambers.slug` is GENERATED ALWAYS from name_formal, not from name:
--       btrim(regexp_replace(translate(replace(f_unaccent(lower(coalesce(name_formal,''))),
--       '&','and'), '''’.', ''), '[^a-z0-9]+', '-', 'g'), '-')
--    Inserting it directly raises 428C9. name_formal is therefore the thing to set, and it
--    follows the house pattern "<Government> <Office>" (King County Assessor, Seattle City
--    Council), which yields exactly the slugs the later steps join on.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, policy_engagement_level, staggered_term, website_url)
SELECT g.id, v.name, v.name_formal, v.official_count, v.term_length, v.pel::essentials.policy_engagement_level, v.staggered, v.url
FROM (VALUES
  ('53035',  'Board of Commissioners', 'Kitsap County Board of Commissioners', 3, '4', 'full', true,  'https://www.kitsap.gov/BOC_p/Pages/default.aspx'),
  ('53035',  'Assessor',               'Kitsap County Assessor',               1, '4', 'none', false, 'https://www.kitsap.gov/assessor'),
  ('53035',  'Auditor',                'Kitsap County Auditor',                1, '4', 'none', false, 'https://www.kitsap.gov/auditor'),
  ('53035',  'Clerk',                  'Kitsap County Clerk',                  1, '4', 'none', false, 'https://www.kitsap.gov/clerk'),
  ('53035',  'Prosecuting Attorney',   'Kitsap County Prosecuting Attorney',   1, '4', 'full', false, 'https://www.kitsap.gov/pros'),
  ('53035',  'Sheriff',                'Kitsap County Sheriff',                1, '4', 'none', false, 'https://www.kitsap.gov/sheriff'),
  ('53035',  'Treasurer',              'Kitsap County Treasurer',              1, '4', 'none', false, 'https://www.kitsap.gov/treasurer'),
  ('5303736','City Council',           'Bainbridge Island City Council',       7, '4', 'full', true,  'https://www.bainbridgewa.gov/217/City-Council')
) AS v(geo_id, name, name_formal, official_count, term_length, pel, staggered, url)
JOIN essentials.governments g ON g.geo_id = v.geo_id;

-- ---------------------------------------------------------------------------
-- 3. Offices. seats is left NULL, matching Seattle and King County — NOT 0.
--    A 0 in that column reads as "unset" everywhere it is consumed and makes any
--    capacity comparison fire on every single-seat office in the corpus.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.offices (chamber_id, title, representing_state, representing_city, representation_note)
SELECT c.id, v.title, 'WA', v.city, v.note
FROM (VALUES
  ('kitsap-county-board-of-commissioners','Commissioner, District 1', NULL, NULL),
  ('kitsap-county-board-of-commissioners','Commissioner, District 2', NULL, NULL),
  ('kitsap-county-board-of-commissioners','Commissioner, District 3', NULL, NULL),
  ('kitsap-county-assessor',              'Assessor',                 NULL, NULL),
  ('kitsap-county-auditor',               'Auditor',                  NULL, NULL),
  ('kitsap-county-clerk',                 'Clerk',                    NULL, NULL),
  ('kitsap-county-prosecuting-attorney',  'Prosecuting Attorney',     NULL, NULL),
  ('kitsap-county-sheriff',               'Sheriff',                  NULL, NULL),
  ('kitsap-county-treasurer',             'Treasurer',                NULL, NULL),
  ('bainbridge-island-city-council','Councilmember, District 1','Bainbridge Island','At Large. Council-manager city: the mayor is the council chair, chosen by and from the seven members. Kirsten Hytopoulos was chosen Deputy Mayor in January 2026 for a six-month term.'),
  ('bainbridge-island-city-council','Councilmember, District 2','Bainbridge Island','North Ward.'),
  ('bainbridge-island-city-council','Councilmember, District 3','Bainbridge Island','South Ward.'),
  ('bainbridge-island-city-council','Councilmember, District 4','Bainbridge Island','Central Ward.'),
  ('bainbridge-island-city-council','Councilmember, District 5','Bainbridge Island','Central Ward. Council-manager city: the mayor is the council chair, chosen by and from the seven members. Clarence Moriwaki was chosen Mayor in January 2026 for a one-year term. There is no separately elected mayoralty.'),
  ('bainbridge-island-city-council','Councilmember, District 6','Bainbridge Island','South Ward.'),
  ('bainbridge-island-city-council','Councilmember, District 7','Bainbridge Island','North Ward.')
) AS v(chamber_slug, title, city, note)
JOIN essentials.chambers c ON c.slug = v.chamber_slug;

-- ---------------------------------------------------------------------------
-- 4. People. Bainbridge council is NONPARTISAN — party stays NULL there.
--    Kitsap county offices are partisan and the roster prints the letter.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, last_name, party, is_active, is_incumbent, data_source)
VALUES
  ('Christine Rolfes','Christine','Rolfes','Democratic', true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Oran Root',       'Oran',     'Root',  'Republican', true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Katie Walters',   'Katie',    'Walters','Democratic',true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Phil Cook',       'Phil',     'Cook',  'Republican', true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Paul Andrews',    'Paul',     'Andrews','Democratic',true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('David Lewis',     'David',    'Lewis', 'Democratic', true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Chad M. Enright', 'Chad',     'Enright','Democratic',true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('John Gese',       'John',     'Gese',  'Democratic', true, true, 'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Pete Boissonneau','Pete',     'Boissonneau','Democratic',true,true,'kitsap.gov/auditor/Pages/Elected_Officials.aspx (read 2026-08-17); migration 1798'),
  ('Kirsten Hytopoulos','Kirsten','Hytopoulos',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Brenda Fantroy-Johnson','Brenda','Fantroy-Johnson',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Mike Nelson',     'Mike',     'Nelson',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Leslie Schneider','Leslie',   'Schneider',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Clarence Moriwaki','Clarence','Moriwaki',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Ashley Mathews',  'Ashley',   'Mathews',NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798'),
  ('Lara Lant',       'Lara',     'Lant',  NULL, true, true, 'bainbridgewa.gov/217/City-Council (read 2026-08-17); migration 1798');

-- ---------------------------------------------------------------------------
-- 5. Terms — every single one carries a published term_end.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, v.term_start::date, v.term_end::date, v.prec, v.how_started, v.src
FROM (VALUES
  ('kitsap-county-board-of-commissioners','Commissioner, District 1','Christine Rolfes','2023-06-01','2028-12-31','month','appointed','kitsap.gov elected-officials table + County History ("June 2023 - Christine Rolfes appointed District 1 County Commissioner"; Gelder resigned May 2023). Elected Nov 2024; current term Jan 2025 - Dec 2028. OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-board-of-commissioners','Commissioner, District 2','Oran Root','2025-01-01','2028-12-31','month','elected','kitsap.gov elected-officials table: elected Nov 2024, term Jan 2025 - Dec 2028, originally elected Nov 2024. Month precision. Read 2026-08-17.'),
  ('kitsap-county-board-of-commissioners','Commissioner, District 3','Katie Walters','2023-01-01','2026-12-31','month','elected','kitsap.gov elected-officials table: elected Nov 2022, term Jan 2023 - Dec 2026, originally elected Nov 2022. Month precision. Read 2026-08-17.'),
  ('kitsap-county-assessor',             'Assessor','Phil Cook','2015-01-01','2026-12-31','month','elected','kitsap.gov elected-officials table: current term Jan 2023 - Dec 2026; "Date Originally Elected or Appointed: Elected Nov. 2014". OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-auditor',              'Auditor','Paul Andrews','2019-01-01','2026-12-31','month','elected','kitsap.gov elected-officials table: current term Jan 2023 - Dec 2026; originally elected Nov 2018. OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-clerk',                'Clerk','David Lewis','2021-09-01','2026-12-31','month','appointed','kitsap.gov County History: "September 2021 - David Lewis appointed County Clerk"; "July 2021 - Alison Sonntag, County Clerk, resigns." Elected Nov 2022; current term Jan 2023 - Dec 2026. OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-prosecuting-attorney', 'Prosecuting Attorney','Chad M. Enright','2019-01-01','2026-12-31','month','elected','kitsap.gov elected-officials table: current term Jan 2023 - Dec 2026; originally elected Nov 2018. OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-sheriff',              'Sheriff','John Gese','2021-08-01','2026-12-31','month','appointed','kitsap.gov County History: "August 2021 - John Gese appointed Kitsap County Sheriff."; "June 2021 - Gary Simpson, County Sheriff, resigns." Elected Nov 2022; current term Jan 2023 - Dec 2026. OCCUPANCY start recorded, month precision. Read 2026-08-17.'),
  ('kitsap-county-treasurer',            'Treasurer','Pete Boissonneau','2023-01-01','2026-12-31','month','elected','kitsap.gov elected-officials table: elected Nov 2022, term Jan 2023 - Dec 2026. Month precision. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 1','Kirsten Hytopoulos',NULL,'2027-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Kirsten Hytopoulos, Deputy Mayor | At Large, District 1 | Term Expires 12/31/2027". term_start NULL: the page publishes expiry only, and deriving the current-term start would not be the occupancy start. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 2','Brenda Fantroy-Johnson',NULL,'2027-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Brenda Fantroy-Johnson | North Ward, District 2 | Term Expires 12/31/2027". term_start NULL, expiry only published. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 3','Mike Nelson',NULL,'2029-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Mike Nelson | South Ward, District 3 | Term Expires 12/31/2029". term_start NULL, expiry only published. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 4','Leslie Schneider',NULL,'2027-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Leslie Schneider | Central Ward, District 4 | Term Expires 12/31/2027". term_start NULL, expiry only published. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 5','Clarence Moriwaki',NULL,'2029-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Clarence Moriwaki, Mayor | Central Ward, District 5 | Term Expires 12/31/2029". Mayor = council chair, one-year term from January 2026, NOT a separate seat. term_start NULL, expiry only published. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 6','Ashley Mathews',NULL,'2027-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Ashley Mathews | South Ward, District 6 | Term Expires 12/31/2027". term_start NULL, expiry only published. Read 2026-08-17.'),
  ('bainbridge-island-city-council','Councilmember, District 7','Lara Lant',NULL,'2029-12-31','unknown',NULL,'bainbridgewa.gov/217/City-Council: "Lara Lant | North Ward, District 7 | Term Expires 12/31/2029". term_start NULL, expiry only published. Read 2026-08-17.')
) AS v(chamber_slug, title, full_name, term_start, term_end, prec, how_started, src)
JOIN essentials.chambers c ON c.slug = v.chamber_slug
JOIN essentials.offices  o ON o.chamber_id = c.id AND o.title = v.title
JOIN essentials.politicians p ON p.full_name = v.full_name
                             AND p.data_source LIKE '%migration 1798';

COMMIT;
