-- =============================================================================
-- Seed: Monroe County 2026 Primary Election — Races & Candidates
--
-- Source: Monroe County Clerk certified candidate list (PDF)
-- Election: 2026 Indiana Primary, May 5, 2026
--
-- This script is IDEMPOTENT — safe to re-run without creating duplicates.
-- - Election: ON CONFLICT (name, election_date, state) DO UPDATE
-- - Races: ON CONFLICT (election_id, position_name, primary_party) DO UPDATE
-- - Candidates: INSERT ... WHERE NOT EXISTS (race_id, full_name)
-- - Withdrawn candidates: UPDATE after insert
--
-- Usage: psql $DATABASE_URL -f scripts/seed-monroe-county-2026-primary.sql
-- =============================================================================

BEGIN;

-- =============================================================================
-- Step 1: Upsert the election
-- =============================================================================

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
VALUES (
  '2026 Indiana Primary',
  '2026-05-05',
  'primary',
  'county',
  'IN',
  'Monroe County 2026 Primary Election — all county, judicial, town, and township races'
)
ON CONFLICT (name, election_date, state)
DO UPDATE SET
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 2: Upsert all races
-- =============================================================================

WITH election AS (
  SELECT id FROM essentials.elections
  WHERE name = '2026 Indiana Primary' AND election_date = '2026-05-05' AND state = 'IN'
)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT e.id, NULL, v.position_name, v.primary_party, v.seats, v.description
FROM election e,
(VALUES
  -- County-Wide Offices
  ('Monroe County Commissioner District 1',  'Democratic',   1, 'County Commissioner District 1'),
  ('Monroe County Council District 1',       'Democratic',   1, 'County Council District 1'),
  ('Monroe County Council District 2',       'Democratic',   1, 'County Council District 2'),
  ('Monroe County Council District 3',       'Republican',   1, 'County Council District 3'),
  ('Monroe County Council District 4',       'Democratic',   1, 'County Council District 4'),
  ('Monroe County Assessor',                 'Democratic',   1, 'County Assessor'),
  ('Monroe County Clerk',                    'Democratic',   1, 'County Clerk — Democratic Primary'),
  ('Monroe County Clerk',                    'Republican',   1, 'County Clerk — Republican Primary'),
  ('Monroe County Recorder',                 'Democratic',   1, 'County Recorder'),
  ('Monroe County Sheriff',                  'Democratic',   1, 'County Sheriff'),
  ('Monroe County Prosecuting Attorney',     'Democratic',   1, 'County Prosecuting Attorney'),

  -- Judicial
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5', 'Democratic', 1, 'Circuit Court Judge No. 5'),
  ('Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9', 'Democratic', 1, 'Circuit Court Judge No. 9'),

  -- Town Council
  ('Ellettsville Town Council Ward 4',       'Republican',   1, 'Ellettsville Town Council Ward 4'),
  ('Ellettsville Town Council Ward 5',       'Republican',   1, 'Ellettsville Town Council Ward 5'),

  -- Township Trustee
  ('Bean Blossom Township Trustee',          'Republican',   1, 'Bean Blossom Township Trustee'),
  ('Benton Township Trustee',               'Democratic',   1, 'Benton Township Trustee'),
  ('Bloomington Township Trustee',           'Democratic',   1, 'Bloomington Township Trustee'),
  ('Clear Creek Township Trustee',           'Democratic',   1, 'Clear Creek Township Trustee — Democratic Primary'),
  ('Clear Creek Township Trustee',           'Republican',   1, 'Clear Creek Township Trustee — Republican Primary'),
  ('Indian Creek Township Trustee',          'Democratic',   1, 'Indian Creek Township Trustee — Democratic Primary'),
  ('Indian Creek Township Trustee',          'Republican',   1, 'Indian Creek Township Trustee — Republican Primary'),
  ('Perry Township Trustee',                 'Democratic',   1, 'Perry Township Trustee'),
  ('Polk Township Trustee',                  'Republican',   1, 'Polk Township Trustee'),
  ('Richland Township Trustee',              'Republican',   1, 'Richland Township Trustee'),
  ('Salt Creek Township Trustee',            'Democratic',   1, 'Salt Creek Township Trustee'),
  ('Van Buren Township Trustee',             'Republican',   1, 'Van Buren Township Trustee'),
  ('Washington Township Trustee',            'Republican',   1, 'Washington Township Trustee'),

  -- Township Board (3 seats each)
  ('Benton Township Board',                  'Democratic',   3, 'Benton Township Board'),
  ('Bloomington Township Board',             'Democratic',   3, 'Bloomington Township Board'),
  ('Clear Creek Township Board',             'Democratic',   3, 'Clear Creek Township Board — Democratic Primary'),
  ('Clear Creek Township Board',             'Republican',   3, 'Clear Creek Township Board — Republican Primary'),
  ('Indian Creek Township Board',            'Republican',   3, 'Indian Creek Township Board'),
  ('Perry Township Board',                   'Democratic',   3, 'Perry Township Board'),
  ('Richland Township Board',                'Republican',   3, 'Richland Township Board'),
  ('Salt Creek Township Board',              'Democratic',   3, 'Salt Creek Township Board'),
  ('Van Buren Township Board',               'Democratic',   3, 'Van Buren Township Board — Democratic Primary'),
  ('Van Buren Township Board',               'Republican',   3, 'Van Buren Township Board — Republican Primary'),
  ('Washington Township Board',              'Republican',   3, 'Washington Township Board')
) AS v(position_name, primary_party, seats, description)
ON CONFLICT (election_id, position_name, primary_party)
DO UPDATE SET
  seats = EXCLUDED.seats,
  description = EXCLUDED.description,
  updated_at = now();

-- =============================================================================
-- Step 3: Insert all candidates (idempotent via NOT EXISTS)
--
-- Each INSERT uses a subquery to resolve the race_id from the election/race
-- tables. The NOT EXISTS check prevents duplicates on re-run.
-- =============================================================================

-- Helper function-like: resolve race_id inline via subquery
-- Pattern: (SELECT r.id FROM essentials.races r JOIN essentials.elections e
--           ON r.election_id = e.id WHERE e.name = '2026 Indiana Primary'
--           AND e.election_date = '2026-05-05' AND e.state = 'IN'
--           AND r.position_name = ? AND r.primary_party = ?)

-- ---- County-Wide Offices ----

-- Monroe County Commissioner District 1 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Commissioner District 1' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Trent Deckard',       'Trent',     'Deckard'),
  ('David G. Henry',      'David',     'Henry')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Council District 1 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Council District 1' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Peter James Iversen', 'Peter',     'Iversen')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Council District 2 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Council District 2' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Joe Davis',           'Joe',       'Davis'),
  ('Kate Wiltz',          'Kate',      'Wiltz')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Council District 3 (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Council District 3' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Matha Hawk',          'Matha',     'Hawk')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Council District 4 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Council District 4' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Jennifer Crossley',   'Jennifer',  'Crossley')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Assessor (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Assessor' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Bob Nyquist',         'Bob',       'Nyquist'),
  ('Judith A. Sharp',     'Judith',    'Sharp')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Clerk (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Clerk' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Tanner Dale Branham', 'Tanner',    'Branham'),
  ('Joe Davis',           'Joe',       'Davis'),
  ('Tree Martin Lucas',   'Tree',      'Lucas')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Clerk (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Clerk' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Julie M. Hays',       'Julie',     'Hays')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Recorder (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Recorder' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Amy Swain',           'Amy',       'Swain')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Sheriff (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Sheriff' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Ruben Marte''',       'Ruben',     'Marte''')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Monroe County Prosecuting Attorney (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Monroe County Prosecuting Attorney' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Benjamin T. Arrington', 'Benjamin', 'Arrington'),
  ('Erika Oliphant',        'Erika',    'Oliphant')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- Judicial ----

-- Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 5' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Kara Elaine Krothe',   'Kara',     'Krothe')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9 (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Judge of the Monroe Circuit Court, 10th Judicial Circuit, No. 9' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Geoff Bradley',        'Geoff',    'Bradley')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- Town Council ----

-- Ellettsville Town Council Ward 4 (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Ellettsville Town Council Ward 4' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Andrew Henry',         'Andrew',   'Henry')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Ellettsville Town Council Ward 5 (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Ellettsville Town Council Ward 5' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Marv Ulmet',           'Marv',     'Ulmet')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- Township Trustee ----

-- Bean Blossom Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Bean Blossom Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Ronald H. Hutson',     'Ronald',   'Hutson')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Benton Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Benton Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Michelle Bright',      'Michelle', 'Bright')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Bloomington Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Bloomington Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Efrat Rosser',         'Efrat',    'Rosser')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Clear Creek Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Clear Creek Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Susan Luther',         'Susan',    'Luther')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Clear Creek Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Clear Creek Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Thelma Kelley Jeffries', 'Thelma',  'Jeffries'),
  ('Ty Mungle',              'Ty',      'Mungle'),
  ('Steven A. Hinds',        'Steven',  'Hinds')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Indian Creek Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Indian Creek Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Susan Hingle',         'Susan',    'Hingle')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Indian Creek Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Indian Creek Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Christopher Reynolds', 'Christopher', 'Reynolds')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Perry Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Perry Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Levi Combs',           'Levi',     'Combs'),
  ('Leon Gordon',          'Leon',     'Gordon'),
  ('Eric S. Petry',        'Eric',     'Petry')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Polk Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Polk Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Scott Smith',          'Scott',    'Smith')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Richland Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Richland Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Dawn Marie Durnil',    'Dawn',     'Durnil')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Salt Creek Township Trustee (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Salt Creek Township Trustee' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Joan C. Hall',         'Joan',     'Hall')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Van Buren Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Van Buren Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Rita Barrow',          'Rita',     'Barrow')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Washington Township Trustee (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Washington Township Trustee' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Mary VanDeventer',     'Mary',     'VanDeventer')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- ---- Township Board (3 seats each) ----

-- Benton Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Benton Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Joe Husk',             'Joe',      'Husk')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Bloomington Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Bloomington Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Dorothy Granger',      'Dorothy',  'Granger'),
  ('Barbara E. McKinney',  'Barbara',  'McKinney'),
  ('Elizabeth Sensenstein', 'Elizabeth','Sensenstein')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Clear Creek Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Clear Creek Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Joann Calabrese',      'Joann',    'Calabrese'),
  ('Rachael Himsel',       'Rachael',  'Himsel'),
  ('Kat Reynolds',         'Kat',      'Reynolds')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Clear Creek Township Board (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Clear Creek Township Board' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Dustin Cole Dillard',  'Dustin',   'Dillard'),
  ('R. Shannon Reed',      'R.',       'Reed'),
  ('Paul Strain',          'Paul',     'Strain'),
  ('Steven E. Webb',       'Steven',   'Webb')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Indian Creek Township Board (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Indian Creek Township Board' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Katrina W. Ladwig',    'Katrina',  'Ladwig'),
  ('Wendi Reynolds',       'Wendi',    'Reynolds'),
  ('Roger L. Taylor',      'Roger',    'Taylor')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Perry Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Perry Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Jack Davis',           'Jack',     'Davis'),
  ('Jeremy Goodrich',      'Jeremy',   'Goodrich'),
  ('Susie Hamilton',       'Susie',    'Hamilton'),
  ('Jenny Olmes-Stevens',  'Jenny',    'Olmes-Stevens'),
  ('Barbara Sturbaum',     'Barbara',  'Sturbaum')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Richland Township Board (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Richland Township Board' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Traves Conyer',        'Traves',   'Conyer'),
  ('Elaine Thomsen',       'Elaine',   'Thomsen'),
  ('Jay Thrasher',         'Jay',      'Thrasher'),
  ('David Willibey',       'David',    'Willibey')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Salt Creek Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Salt Creek Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('Sharon A. Green',      'Sharon',   'Green'),
  ('Sean P. Hall',         'Sean',     'Hall'),
  ('Joseph Hickman',       'Joseph',   'Hickman')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Van Buren Township Board (D)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Van Buren Township Board' AND r.primary_party = 'Democratic'
) race,
(VALUES
  ('William E. Smith III', 'William',  'Smith III')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Van Buren Township Board (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Van Buren Township Board' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Theresa Oatman',       'Theresa',  'Oatman'),
  ('John Wilson',          'John',     'Wilson')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- Washington Township Board (R)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT rid, NULL, v.full_name, v.first_name, v.last_name, false, 'active', 'county_clerk'
FROM (
  SELECT r.id AS rid FROM essentials.races r
  JOIN essentials.elections e ON r.election_id = e.id
  WHERE e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'
    AND r.position_name = 'Washington Township Board' AND r.primary_party = 'Republican'
) race,
(VALUES
  ('Andrew Spriggs',       'Andrew',   'Spriggs'),
  ('Jerry Ayers',          'Jerry',    'Ayers'),
  ('Kenny L. Bryant',      'Kenny',    'Bryant')
) AS v(full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = rid AND rc.full_name = v.full_name
);

-- =============================================================================
-- Step 4: Mark withdrawn candidates
-- These candidates filed but subsequently withdrew from their races.
-- =============================================================================

-- Joe Davis withdrew from Monroe County Council District 2 on 2/5/2026
UPDATE essentials.race_candidates
SET candidate_status = 'withdrawn', updated_at = now()
WHERE full_name = 'Joe Davis'
  AND race_id = (
    SELECT r.id FROM essentials.races r
    JOIN essentials.elections e ON r.election_id = e.id
    WHERE e.name = '2026 Indiana Primary'
      AND e.election_date = '2026-05-05'
      AND e.state = 'IN'
      AND r.position_name = 'Monroe County Council District 2'
      AND r.primary_party = 'Democratic'
  );

-- Eric S. Petry withdrew from Perry Township Trustee on 2/10/2026
UPDATE essentials.race_candidates
SET candidate_status = 'withdrawn', updated_at = now()
WHERE full_name = 'Eric S. Petry'
  AND race_id = (
    SELECT r.id FROM essentials.races r
    JOIN essentials.elections e ON r.election_id = e.id
    WHERE e.name = '2026 Indiana Primary'
      AND e.election_date = '2026-05-05'
      AND e.state = 'IN'
      AND r.position_name = 'Perry Township Trustee'
      AND r.primary_party = 'Democratic'
  );

COMMIT;

-- =============================================================================
-- Verification queries (run manually after seeding):
--
-- Race count:
--   SELECT COUNT(*) FROM essentials.races r
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Indiana Primary';
--
-- Candidate count per race:
--   SELECT r.position_name, r.primary_party, COUNT(rc.*)
--   FROM essentials.races r
--   JOIN essentials.race_candidates rc ON rc.race_id = r.id
--   JOIN essentials.elections e ON r.election_id = e.id
--   WHERE e.name = '2026 Indiana Primary'
--   GROUP BY r.position_name, r.primary_party
--   ORDER BY r.position_name;
--
-- Withdrawn candidates:
--   SELECT full_name, candidate_status FROM essentials.race_candidates
--   WHERE candidate_status = 'withdrawn';
-- =============================================================================
