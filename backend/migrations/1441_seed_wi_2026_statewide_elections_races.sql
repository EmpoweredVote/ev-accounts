-- 1419_seed_wi_2026_statewide_elections_races.sql
-- WI 2026 statewide executive offices: the missing Aug-11 partisan primary election record
-- plus primary races (office x party) and general-election race shells.
--
-- WHY: prod had exactly ONE Wisconsin election ('WI 2026 Statewide General', 8 U.S. House
--   races). All five WI partisan executive offices are on the Nov-3 ballot -- Governor is an
--   OPEN SEAT (Evers filed Notification of Noncandidacy) -- and none of them existed as races.
--   There was also no Aug-11 partisan primary election record at all.
--
-- FIELD SOURCE: Wisconsin Elections Commission "Ballot Access Report" 6.9.2026
--   (elections.wi.gov/sites/default/files/documents/D.%20Ballot%20Access%20Report%206.9.2026.pdf,
--   printed 6/8/2026), which lists every filer with a Recommended Ballot Status of
--   Approve / Deny / Challenged. The four SoS "Challenged" rows were resolved at the
--   WEC's 6/9/2026 ballot-access meeting: Pollnow, Werner and Karas approved, Newcomer
--   DENIED (duplicated signatures) -- per Wisconsin Examiner 2026-06-09 and WUWM's
--   current SoS candidate guide, which agree.
--   Only 'Approve' candidates are seeded. Notably EXCLUDED: David D. King (Ind., Governor,
--   1731 valid sigs vs 2000 required) and Kirk Bangstad (Dem., Governor, 1504) -- both are
--   named in early local coverage as candidates but neither made the ballot.
--
-- ANTIPARTISAN INVARIANT (see essentials.races.primary_party): party is NEVER stored on
--   race_candidates and NEVER shown as a per-candidate label. On a PARTISAN PRIMARY it is
--   legitimately a property of the RACE -- which party's ballot the voter requests -- so
--   primary_party is set here, exactly as the UT 2026 Primary does. The five general-election
--   races keep primary_party NULL.
--
-- GENERAL-ELECTION SHELLS: the primary is 2026-08-11 and has not happened, so four of the
--   five general races have no determined field yet and are seeded with NO candidates.
--   ElectionsView.jsx hides candidate-less races (`if ((race.candidates || []).length === 0)
--   continue;`), so they are invisible until the nominees are attached after Aug 11 -- this
--   deliberately avoids repeating the mixed-party pre-primary field currently sitting on the
--   WI U.S. House general races. Attorney General is the exception: Kaul and Toney are each
--   unopposed in their primary, so the November field is already certain and IS seeded (1442).
--
-- WI ticket nuance: Governor and Lieutenant Governor are nominated separately in the primary
--   but run as a single ticket in November. They are modelled as separate races here, matching
--   the two separate STATE_EXEC offices that already exist. Not a bug.
BEGIN;

-- 1. Aug-11 partisan primary election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
SELECT 'WI 2026 Partisan Primary', '2026-08-11'::date, 'primary', 'state', 'WI',
       'Wisconsin partisan primary. Voters request one party''s ballot; races are split by party.'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WI 2026 Partisan Primary');

-- 2. 11 partisan-primary races on the 5 existing WI STATE_EXEC offices (geo_id '55').
--    Joined by offices.role_canonical -- unambiguous, unlike title matching.
--    'State Treasurer' (not 'Treasurer') is deliberate: ElectionsView bodyOrderScore matches
--    lower.includes('state treasurer') to sort it with the executive block; a bare 'Treasurer'
--    falls through to the "other statewide executive" bucket.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, v.primary_party, 1,
       'WEC Ballot Access Report 6.9.2026; approved filers only'
FROM essentials.elections el
CROSS JOIN (VALUES
    ('governor',          'Governor',            'Democratic'),
    ('governor',          'Governor',            'Republican'),
    ('lt_governor',       'Lieutenant Governor', 'Democratic'),
    ('lt_governor',       'Lieutenant Governor', 'Republican'),
    ('attorney_general',  'Attorney General',    'Democratic'),
    ('attorney_general',  'Attorney General',    'Republican'),
    ('secretary_of_state','Secretary of State',  'Democratic'),
    ('secretary_of_state','Secretary of State',  'Republican'),
    ('secretary_of_state','Secretary of State',  'Wisconsin Green'),
    ('treasurer',         'State Treasurer',     'Democratic'),
    ('treasurer',         'State Treasurer',     'Republican')
  ) AS v(role_canonical, position_name, primary_party)
JOIN essentials.districts d
  ON d.district_type = 'STATE_EXEC' AND d.geo_id = '55'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.role_canonical = v.role_canonical
 AND o.representing_state = 'WI'
WHERE el.name = 'WI 2026 Partisan Primary'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
     WHERE r.election_id = el.id
       AND r.office_id = o.id
       AND coalesce(r.primary_party, '') = v.primary_party
  );

-- 3. 5 general-election races on the EXISTING 'WI 2026 Statewide General'.
--    primary_party NULL (antipartisan). Candidates attached in 1442 for AG only.
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, NULL, 1, v.note
FROM essentials.elections el
CROSS JOIN (VALUES
    ('governor',          'Governor',            'Open seat (Evers noncandidacy). Nominees attached after the 2026-08-11 primary.'),
    ('lt_governor',       'Lieutenant Governor', 'Runs as a ticket with Governor in November. Nominees attached after the 2026-08-11 primary.'),
    ('attorney_general',  'Attorney General',    'Both nominees unopposed in the primary; November field already determined.'),
    ('secretary_of_state','Secretary of State',  'Open seat (Godlewski noncandidacy). Nominees attached after the 2026-08-11 primary.'),
    ('treasurer',         'State Treasurer',     'Nominees attached after the 2026-08-11 primary.')
  ) AS v(role_canonical, position_name, note)
JOIN essentials.districts d
  ON d.district_type = 'STATE_EXEC' AND d.geo_id = '55'
JOIN essentials.offices o
  ON o.district_id = d.id
 AND o.role_canonical = v.role_canonical
 AND o.representing_state = 'WI'
WHERE el.name = 'WI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r
     WHERE r.election_id = el.id
       AND r.office_id = o.id
       AND coalesce(r.primary_party, '') = ''
  );

COMMIT;
