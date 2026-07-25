-- 1381_seed_wi_2026_statewide_candidates.sql
-- 18 new WI politicians + 25 race_candidates onto the races created in 1380:
--   23 on the 11 Aug-11 partisan-primary races, 2 on the Attorney General general race.
--
-- FIELD SOURCE + exclusions: see the header of 1380. Only WEC-approved filers are seeded.
--
-- ANTIPARTISAN: party is NOT written to race_candidates and NOT written to the new
--   politicians rows (matching 1221, the WI U.S. House precedent). Party lives only on
--   races.primary_party, i.e. which party's ballot the voter requests.
--
-- INCUMBENCY: is_incumbent is true ONLY for a candidate seeking re-election to the SAME
--   office -- Josh Kaul (AG) and John Leiber (Treasurer). Everyone else is false, including
--   two sitting officials seeking a DIFFERENT office: Lt. Gov. Sara Rodriguez (running for
--   Governor) and Sec. of State Sarah Godlewski (running for Lieutenant Governor). Governor
--   and Secretary of State are both open seats, so neither has an incumbent candidate.
--
-- REUSED politician records (linked, not duplicated):
--   Sara Rodriguez   -5500002  -> Governor / Democratic
--   Josh Kaul        -5500003  -> Attorney General / Democratic (primary + general)
--   Sarah Godlewski  -5500004  -> Lieutenant Governor / Democratic
--   John Leiber      -5500005  -> State Treasurer / Republican
--   Thomas P. Tiffany  -55007  -> Governor / Republican. Sitting WI-7 U.S. Rep; the ballot
--     name is "Tom Tiffany", stored as race_candidates.full_name while still linking to the
--     existing politician record (name divergence between ballot and politician is expected).
--
-- external_id block -559001..-559042 (statewide exec); -5501xx..-5508xx is the U.S. House
--   challenger block from 1221 and -55000xx the state-exec incumbents, so no overlap.
BEGIN;

-- 1. 18 new politician records (idempotent on external_id). No party stored -- see header.
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-559001::bigint, 'Mandela Barnes'::text,    'Mandela'::text,  'Barnes'::text),
    (-559002,         'Joel Brennan',            'Joel',           'Brennan'),
    (-559003,         'David Crowley',           'David',          'Crowley'),
    (-559004,         'Francesca Hong',          'Francesca',      'Hong'),
    (-559005,         'Missy Hughes',            'Missy',          'Hughes'),
    (-559006,         'Kelda Roys',              'Kelda',          'Roys'),
    (-559007,         'Andy Manske',             'Andy',           'Manske'),
    (-559011,         'Will Martin',             'Will',           'Martin'),
    (-559012,         'David Varnam',            'David',          'Varnam'),
    (-559021,         'Eric Toney',              'Eric',           'Toney'),
    (-559031,         'JoCasta Zamarripa',       'JoCasta',        'Zamarripa'),
    (-559032,         'Brayden Myer',            'Brayden',        'Myer'),
    (-559033,         'Nate Pollnow',            'Nate',           'Pollnow'),
    (-559034,         'Jay Schroeder',           'Jay',            'Schroeder'),
    (-559035,         'Cindy Werner',            'Cindy',          'Werner'),
    (-559036,         'Pete Karas',              'Pete',           'Karas'),
    (-559041,         'Dylan Helmenstine',       'Dylan',          'Helmenstine'),
    -- Hmong name: Xiong is the surname, "Yee Leng" the given name.
    (-559042,         'Yee Leng Xiong',          'Yee Leng',       'Xiong')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- 2. 23 partisan-primary race_candidates, matched to (office role, ballot party).
INSERT INTO essentials.race_candidates (
  race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source
)
SELECT r.id, p.id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       'WEC Ballot Access Report 6.9.2026 (approved filers only); SoS challenges resolved at the WEC 6/9/2026 meeting'
FROM (VALUES
    -- Governor -- OPEN SEAT (Evers noncandidacy); no incumbent candidate.
    ('governor',          'Democratic'::text,      -559001::bigint, 'Mandela Barnes'::text,   'Mandela'::text,   'Barnes'::text,      false),
    ('governor',          'Democratic',            -559002,         'Joel Brennan',           'Joel',            'Brennan',           false),
    ('governor',          'Democratic',            -559003,         'David Crowley',          'David',           'Crowley',           false),
    ('governor',          'Democratic',            -559004,         'Francesca Hong',         'Francesca',       'Hong',              false),
    ('governor',          'Democratic',            -559005,         'Missy Hughes',           'Missy',           'Hughes',            false),
    ('governor',          'Democratic',            -559006,         'Kelda Roys',             'Kelda',           'Roys',              false),
    ('governor',          'Democratic',            -5500002,        'Sara Rodriguez',         'Sara',            'Rodriguez',         false),
    ('governor',          'Republican',            -559007,         'Andy Manske',            'Andy',            'Manske',            false),
    ('governor',          'Republican',            -55007,          'Tom Tiffany',            'Tom',             'Tiffany',           false),
    -- Lieutenant Governor -- incumbent Rodriguez is running for Governor, so no incumbent here.
    ('lt_governor',       'Democratic',            -5500004,        'Sarah Godlewski',        'Sarah',           'Godlewski',         false),
    ('lt_governor',       'Republican',            -559011,         'Will Martin',            'Will',            'Martin',            false),
    ('lt_governor',       'Republican',            -559012,         'David Varnam',           'David',           'Varnam',            false),
    -- Attorney General -- both unopposed; 2022 Kaul/Toney rematch.
    ('attorney_general',  'Democratic',            -5500003,        'Josh Kaul',              'Josh',            'Kaul',              true),
    ('attorney_general',  'Republican',            -559021,         'Eric Toney',             'Eric',            'Toney',             false),
    -- Secretary of State -- OPEN SEAT (Godlewski noncandidacy).
    ('secretary_of_state','Democratic',            -559031,         'JoCasta Zamarripa',      'JoCasta',         'Zamarripa',         false),
    ('secretary_of_state','Republican',            -559032,         'Brayden Myer',           'Brayden',         'Myer',              false),
    ('secretary_of_state','Republican',            -559033,         'Nate Pollnow',           'Nate',            'Pollnow',           false),
    ('secretary_of_state','Republican',            -559034,         'Jay Schroeder',          'Jay',             'Schroeder',         false),
    ('secretary_of_state','Republican',            -559035,         'Cindy Werner',           'Cindy',           'Werner',            false),
    ('secretary_of_state','Wisconsin Green',       -559036,         'Pete Karas',             'Pete',            'Karas',             false),
    -- State Treasurer
    ('treasurer',         'Democratic',            -559041,         'Dylan Helmenstine',      'Dylan',           'Helmenstine',       false),
    ('treasurer',         'Democratic',            -559042,         'Yee Leng Xiong',         'Yee Leng',        'Xiong',             false),
    ('treasurer',         'Republican',            -5500005,        'John S. Leiber',         'John',            'Leiber',            true)
  ) AS v(role_canonical, primary_party, external_id, full_name, first_name, last_name, is_incumbent)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.districts d  ON d.district_type = 'STATE_EXEC' AND d.geo_id = '55'
JOIN essentials.offices o    ON o.district_id = d.id
                            AND o.role_canonical = v.role_canonical
                            AND o.representing_state = 'WI'
JOIN essentials.races r      ON r.election_id = el.id
                            AND r.office_id = o.id
                            AND r.primary_party = v.primary_party
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
   WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name)
);

-- 3. Attorney General general-election field. Seeded because both nominees are unopposed in
--    the primary, so the November ballot is already determined. The other four general races
--    stay candidate-less (and therefore hidden) until after 2026-08-11.
INSERT INTO essentials.race_candidates (
  race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source
)
SELECT r.id, p.id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       'WEC Ballot Access Report 6.9.2026; both AG nominees unopposed in the 2026-08-11 primary'
FROM (VALUES
    (-5500003::bigint, 'Josh Kaul'::text, 'Josh'::text, 'Kaul'::text,  true),
    (-559021,          'Eric Toney',      'Eric',       'Toney',       false)
  ) AS v(external_id, full_name, first_name, last_name, is_incumbent)
JOIN essentials.elections el ON el.name = 'WI 2026 Statewide General'
JOIN essentials.districts d  ON d.district_type = 'STATE_EXEC' AND d.geo_id = '55'
JOIN essentials.offices o    ON o.district_id = d.id
                            AND o.role_canonical = 'attorney_general'
                            AND o.representing_state = 'WI'
JOIN essentials.races r      ON r.election_id = el.id
                            AND r.office_id = o.id
                            AND r.primary_party IS NULL
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
   WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
