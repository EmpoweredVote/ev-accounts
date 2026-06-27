-- Migration 1072: Seed Nov 3 2026 general-election candidates for empty statewide races
--
-- Populates the previously-empty statewide races surfaced by migrations 1067-1070.
-- Candidates are the verified Nov 3 general-election ballot (researched against
-- Ballotpedia, state election boards, and state press; primaries in MD/ME/OR have
-- concluded). Only CONFIRMED candidates are seeded — evidence-only.
--
-- Incumbents are linked to their existing politician records (politician_id) so the
-- feed shows their photo/profile via COALESCE(rc.photo_url, pi.url). Challengers
-- have no record yet (politician_id NULL); headshots can be added later via the
-- find-headshots flow. Party is intentionally NOT stored (antipartisan design).
--
-- Held back (not yet certain — add after certification):
--   * OR Gov independents LaNicia Duke / Alexander Ziwahatan (not yet ballot-certified)
--   * MD Gov "Working Class Party" ticket (unconfirmed / likely stale)
--   * VA U.S. Senate Republican nominee (Aug 4 2026 primary) + independent Mark Moran
--   * Any late-filing minor-party/independent (state lists finalize ~Aug/Sep)
-- Idempotent: skips a (race_id, full_name) row that already exists.

BEGIN;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT v.race_id::uuid, v.politician_id::uuid, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  -- MD Governor (race 8c67c58e)
  ('8c67c58e-f3a7-4822-bbbf-eb426ac13f87','21e534c8-c0c0-42f5-b52b-5eb2f246d632','Wes Moore','Wes','Moore',true,'https://elections.maryland.gov/elections/2026/'),
  ('8c67c58e-f3a7-4822-bbbf-eb426ac13f87',NULL,'Dan Cox','Dan','Cox',false,'https://elections.maryland.gov/elections/2026/'),
  ('8c67c58e-f3a7-4822-bbbf-eb426ac13f87',NULL,'Andy Ellis','Andy','Ellis',false,'https://ballotpedia.org/Andy_Ellis'),
  -- MD Attorney General (race c08f3d4e)
  ('c08f3d4e-2188-4d7c-a598-f8b2bbfaa573','60329719-1d5b-4bb4-8295-38ea18f6f378','Anthony Brown','Anthony','Brown',true,'https://en.wikipedia.org/wiki/2026_Maryland_Attorney_General_election'),
  ('c08f3d4e-2188-4d7c-a598-f8b2bbfaa573',NULL,'James B. Rutledge III','James','Rutledge',false,'https://en.wikipedia.org/wiki/2026_Maryland_Attorney_General_election'),
  -- MD Comptroller (race e80f817e)
  ('e80f817e-e292-4c8c-a10c-8b801fb32a13','b26fb5d2-90eb-4108-8ce5-838df719473d','Brooke Lierman','Brooke','Lierman',true,'https://elections.maryland.gov/elections/2026/'),
  ('e80f817e-e292-4c8c-a10c-8b801fb32a13',NULL,'Sonya Dunn','Sonya','Dunn',false,'https://elections.maryland.gov/elections/2026/'),
  -- ME Governor general (race deafeeb8) — open seat (Mills term-limited)
  ('deafeeb8-bd5e-4fb1-b55d-40d8c12309fb',NULL,'Hannah Pingree','Hannah','Pingree',false,'https://www.mainepublic.org/politics/2026-06-19/bobby-charles-hannah-pingree-win-nominations-in-maine-race-for-governor'),
  ('deafeeb8-bd5e-4fb1-b55d-40d8c12309fb',NULL,'Bobby Charles','Bobby','Charles',false,'https://www.mainepublic.org/politics/2026-06-19/bobby-charles-hannah-pingree-win-nominations-in-maine-race-for-governor'),
  ('deafeeb8-bd5e-4fb1-b55d-40d8c12309fb',NULL,'Rick Bennett','Rick','Bennett',false,'https://www.mainepublic.org/politics/2026-06-04/independent-qualifies-for-ballot-setting-up-3-way-race-for-maine-governor'),
  -- OR Governor (race 8702f03a)
  ('8702f03a-c028-42e3-b7f8-e17569dedff8','66c3bd97-94d1-4287-b1b8-86605a38cb97','Tina Kotek','Tina','Kotek',true,'https://en.wikipedia.org/wiki/2026_Oregon_gubernatorial_election'),
  ('8702f03a-c028-42e3-b7f8-e17569dedff8',NULL,'Christine Drazan','Christine','Drazan',false,'https://en.wikipedia.org/wiki/2026_Oregon_gubernatorial_election'),
  -- OR U.S. Senate (race 08051b89)
  ('08051b89-7c0d-4609-9543-e685f44f6821','0eabc969-c1a1-47b7-8d34-6113b723a170','Jeff Merkley','Jeff','Merkley',true,'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Oregon'),
  ('08051b89-7c0d-4609-9543-e685f44f6821',NULL,'David Brock Smith','David','Brock Smith',false,'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Oregon'),
  -- VA U.S. Senate (race 8857c4d8) — Warner confirmed (no Dem primary); R nominee pending Aug 4
  ('8857c4d8-fc3f-4823-b09d-542acb484bef','85d27350-e1b6-45b8-aee3-509ca88c5af4','Mark Warner','Mark','Warner',true,'https://en.wikipedia.org/wiki/2026_United_States_Senate_election_in_Virginia')
) AS v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND rc.full_name = v.full_name
);

-- Verify per-race candidate counts after seeding.
SELECT r.position_name, e.state,
       count(rc.id) AS candidates,
       count(rc.politician_id) AS linked_incumbents
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE r.id IN (
  '8c67c58e-f3a7-4822-bbbf-eb426ac13f87','c08f3d4e-2188-4d7c-a598-f8b2bbfaa573',
  'e80f817e-e292-4c8c-a10c-8b801fb32a13','deafeeb8-bd5e-4fb1-b55d-40d8c12309fb',
  '8702f03a-c028-42e3-b7f8-e17569dedff8','08051b89-7c0d-4609-9543-e685f44f6821',
  '8857c4d8-fc3f-4823-b09d-542acb484bef'
)
GROUP BY r.position_name, e.state
ORDER BY e.state, r.position_name;

COMMIT;
