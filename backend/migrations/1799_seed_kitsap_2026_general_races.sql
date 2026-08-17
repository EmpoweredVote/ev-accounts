-- Migration 1799: the seven Kitsap County offices on the 2026 general-election ballot
--
-- Follows migration 1798, which seeded Kitsap County, the City of Bainbridge Island and their
-- 16 sitting officials. Six of the nine Kitsap seats expire Dec 2026, plus the Treasurer, so
-- seven are on the 2026-11-03 ballot. Bainbridge has NO 2026 races — WA city elections are
-- odd-year, which is exactly why those council terms expire in 2027 and 2029.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- kitsap.gov/auditor/Documents/results.html — the county's own primary results file, read
-- 2026-08-17. Header: "Kitsap County, Washington / Primary / 8/4/2026 / Unofficial Results /
-- Run Date 08/14/2026 / Precincts Reporting 321 of 321 = 100.00% / Registered Voters 84250 of
-- 203294 = 41.44%". Parsed candidate-by-candidate from the file itself, not from a summary.
--
-- ============================================================================
-- 🔑 WHY THE UNCERTIFIED PRIMARY DOES NOT BLOCK THIS
-- ============================================================================
-- WA county canvassing boards certify the August primary on 2026-08-18 — tomorrow — and the
-- standing rule in this corpus is to gate election work on the canvass. That rule is about
-- RESULTS, and no result is recorded here.
--
-- The FIELD is separately safe, for a reason specific to these seven races: WA runs a top-two
-- primary, and EVERY ONE of these races had at most two candidates. Nobody could be eliminated.
-- Certification can move the vote totals; it cannot change who appears in November. Five races
-- had exactly two candidates and two (Auditor, Treasurer) had one.
-- ⚠ What certification does NOT rule out is a withdrawal or a qualifying write-in, so every
-- candidacy below carries provisional_until = 2026-08-18. That deliberately expires immediately:
-- a cheap re-check after the canvass confirms the field and clears the flag.
--
-- result / result_source / result_recorded_at are left NULL throughout. The general election has
-- not happened.
--
-- ============================================================================
-- WHAT THE PRIMARY SHOWS — worth reading before trusting the incumbent list
-- ============================================================================
-- 🔴 TWO SITTING OFFICIALS SEEDED IN 1798 TRAILED IN THEIR OWN PRIMARIES:
--      Assessor              Michael Simonds  52.48%  vs  Phil Cook (incumbent)     47.52%
--      Prosecuting Attorney  Joe Lombardi     53.53%  vs  Chad M. Enright (incum.)  46.47%
--    Both incumbents still hold their seats through 2026-12-31 and 1798 is correct; but if the
--    November result stands the same way, those two office_terms will need closing rather than
--    renewing. This is exactly the drift the term_end dates in 1798 were seeded to make visible.
--
-- 🔴 THE SHERIFF IS NOT ON THE BALLOT. John Gese, seeded in 1798 as the sitting Sheriff, does not
--    appear in the primary at all — the race is Brandon L. Myers vs Rick Kuss. He is not seeking
--    re-election. His term still runs to Dec 2026, so his office_term is unchanged and correct;
--    there is simply no incumbent candidate in this race, and is_incumbent is false for both.
--
-- ⚠ The Commissioner District 3 primary drew 25,143 votes against roughly 82,000 countywide in
--    the other races, so that primary was plainly district-restricted while the rest were
--    countywide. Recording the observation from the vote totals; not asserting the statute behind
--    it, which I have not read.
--
-- ⚠ NAME VARIANT: the ballot prints "David T Lewis III"; the county's elected-officials roster
--    prints "David Lewis". Same person, same office, same party. The candidacy is linked to the
--    EXISTING politician row rather than creating a second one, and the ballot form is added to
--    alternate_names. Creating a row here would have manufactured precisely the kind of
--    full_name near-duplicate that the dedup collision work has spent this whole cycle unpicking.
--
-- Six challengers are new person rows. They are candidates, not officeholders: is_incumbent
-- false, and no office_terms row is created for any of them.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision declaration is
-- required. No IDs are hardcoded — every parent is resolved by natural key.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. The six challengers. Candidates only — no office_terms rows.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, last_name, party, is_active, is_incumbent, data_source)
VALUES
  ('Kevin Tisdel',     'Kevin',   'Tisdel',  'Republican', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799'),
  ('Michael Simonds',  'Michael', 'Simonds', 'Democratic', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799'),
  ('Brien Kennedy',    'Brien',   'Kennedy', 'Democratic', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799'),
  ('Joe Lombardi',     'Joe',     'Lombardi','Democratic', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799'),
  ('Rick Kuss',        'Rick',    'Kuss',    'Republican', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799'),
  ('Brandon L. Myers', 'Brandon', 'Myers',   'Democratic', true, false, 'kitsap.gov/auditor/Documents/results.html, 2026 primary (read 2026-08-17); migration 1799');

-- ---------------------------------------------------------------------------
-- 2. Record the ballot form of the Clerk's name on the EXISTING row.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET alternate_names = array_append(alternate_names, 'David T Lewis III')
WHERE full_name = 'David Lewis'
  AND data_source LIKE '%migration 1798'
  AND NOT ('David T Lewis III' = ANY(alternate_names));

-- ---------------------------------------------------------------------------
-- 3. The seven races, each bound to the office seeded in 1798.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.races (election_id, office_id, position_name, seats, description)
SELECT e.id, o.id, v.position_name, 1, v.descr
FROM (VALUES
  ('kitsap-county-board-of-commissioners','Commissioner, District 3','Kitsap County Commissioner District 3','Top-two field from the 2026-08-04 primary. Provisional until the 2026-08-18 canvass; the field cannot change on certification (2 candidates, top-two) but a withdrawal still can.'),
  ('kitsap-county-assessor',              'Assessor',               'Kitsap County Assessor',               'Top-two field from the 2026-08-04 primary. Incumbent Phil Cook trailed 47.52% to 52.48%.'),
  ('kitsap-county-auditor',               'Auditor',                'Kitsap County Auditor',                'Sole candidate in the 2026-08-04 primary (100.00%).'),
  ('kitsap-county-clerk',                 'Clerk',                  'Kitsap County Clerk',                  'Top-two field from the 2026-08-04 primary; both candidates prefer the Democratic Party.'),
  ('kitsap-county-prosecuting-attorney',  'Prosecuting Attorney',   'Kitsap County Prosecuting Attorney',   'Top-two field from the 2026-08-04 primary; both prefer the Democratic Party. Incumbent Chad M. Enright trailed 46.47% to 53.53%.'),
  ('kitsap-county-sheriff',               'Sheriff',                'Kitsap County Sheriff',                'Top-two field from the 2026-08-04 primary. NO INCUMBENT: sitting Sheriff John Gese did not file.'),
  ('kitsap-county-treasurer',             'Treasurer',              'Kitsap County Treasurer',              'Sole candidate in the 2026-08-04 primary (100.00%).')
) AS v(chamber_slug, office_title, position_name, descr)
JOIN essentials.chambers c ON c.slug = v.chamber_slug
JOIN essentials.offices  o ON o.chamber_id = c.id AND o.title = v.office_title
CROSS JOIN (SELECT id FROM essentials.elections WHERE name = 'WA 2026 Statewide General') e;

-- ---------------------------------------------------------------------------
-- 4. The twelve candidacies. Percentages are the UNOFFICIAL primary tallies,
--    carried in `source` as evidence for the field — never as a result.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, provisional_until, source)
SELECT r.id, p.id, v.full_name, v.first_name, v.last_name, v.incumbent, 'active', DATE '2026-08-18', v.src
FROM (VALUES
  ('Kitsap County Commissioner District 3','Katie Walters',   'Katie',  'Walters',    true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 14,941 / 59.42%. Sitting Commissioner District 3. Read 2026-08-17.'),
  ('Kitsap County Commissioner District 3','Kevin Tisdel',    'Kevin',  'Tisdel',     false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 10,202 / 40.58%. Read 2026-08-17.'),
  ('Kitsap County Assessor',               'Michael Simonds', 'Michael','Simonds',    false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 43,174 / 52.48%. Read 2026-08-17.'),
  ('Kitsap County Assessor',               'Phil Cook',       'Phil',   'Cook',       true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 39,098 / 47.52%. Sitting Assessor; TRAILED in the primary. Read 2026-08-17.'),
  ('Kitsap County Auditor',                'Paul Andrews',    'Paul',   'Andrews',    true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 57,540 / 100.00%, sole candidate. Sitting Auditor. Read 2026-08-17.'),
  ('Kitsap County Clerk',                  'David T Lewis III','David', 'Lewis',      true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 40,533 / 63.48%. Sitting Clerk; the roster prints "David Lewis", the ballot "David T Lewis III". Read 2026-08-17.'),
  ('Kitsap County Clerk',                  'Brien Kennedy',   'Brien',  'Kennedy',    false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 23,320 / 36.52%. Read 2026-08-17.'),
  ('Kitsap County Prosecuting Attorney',   'Joe Lombardi',    'Joe',    'Lombardi',   false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 34,119 / 53.53%. Read 2026-08-17.'),
  ('Kitsap County Prosecuting Attorney',   'Chad M. Enright', 'Chad',   'Enright',    true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 29,624 / 46.47%. Sitting Prosecuting Attorney; TRAILED in the primary. Read 2026-08-17.'),
  ('Kitsap County Sheriff',                'Brandon L. Myers','Brandon','Myers',      false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 48,019 / 58.05%. Read 2026-08-17.'),
  ('Kitsap County Sheriff',                'Rick Kuss',       'Rick',   'Kuss',       false, 'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 34,703 / 41.95%. Read 2026-08-17.'),
  ('Kitsap County Treasurer',              'Pete Boissonneau','Pete',   'Boissonneau',true,  'kitsap.gov/auditor/Documents/results.html — 2026-08-04 primary, UNOFFICIAL: 56,503 / 100.00%, sole candidate. Sitting Treasurer. Read 2026-08-17.')
) AS v(position_name, full_name, first_name, last_name, incumbent, src)
JOIN essentials.races r ON r.position_name = v.position_name
                       AND r.election_id = (SELECT id FROM essentials.elections WHERE name = 'WA 2026 Statewide General')
JOIN essentials.politicians p ON p.first_name = v.first_name AND p.last_name = v.last_name
                             AND (p.data_source LIKE '%migration 1798' OR p.data_source LIKE '%migration 1799');

COMMIT;
