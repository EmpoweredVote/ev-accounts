import { writeFileSync } from 'fs';

// ---- ND field (staging/p165-ND.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-08: ND at-large create-election-first seed. DECIDED (Jun-9 primary done).
//   Fedorchak (-38000) renominated reuse (won R primary 72.9%) + Trygve Hammer (D-NPL, 2024 rematch,
//   NEW -380001). EXCLUDED (Pitfall 5, ND petition window open to 2026-08-31 -> Phase 167):
//   Helene Neville, Charles Tuttle (FEC filers, NOT on the ND SoS certified list).
const ELECTION = 'ND 2026 Statewide General';
const RACE_DESC = 'Confirmed general field; ND independent-petition window open to 2026-08-31 -> Phase 167';
const SRC = 'ND SoS certified candidate list (vip.sos.nd.gov eid=346; decided Jun-9 primary; petition window to 2026-08-31 -> Phase 167)';
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

writeFileSync('migrations/1278_seed_nd_2026_house_election_race.sql', `-- 1278_seed_nd_2026_house_election_race.sql
-- Phase 165-08: 'ND 2026 Statewide General' + 1 at-large race (geo 3800). DECIDED -> NOT
--   PROVISIONAL (ND petition window to 2026-08-31 -> Phase 167). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'ND'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '3800'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`);

const rcFor = (name: string, first: string, last: string, ext: number, inc: boolean) =>
  `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
writeFileSync('migrations/1279_seed_nd_2026_house_candidates.sql', `-- 1279_seed_nd_2026_house_candidates.sql
-- Phase 165-08: Trygve Hammer (D-NPL) NEW at -380001 (band empty live) + Fedorchak (-38000)
--   renominated reuse. DECIDED. EXCLUDED pending-independents (window to 2026-08-31 -> 167):
--   Neville, Tuttle. NOT EXISTS guards. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -380001, 'Trygve Hammer', 'Trygve', 'Hammer', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -380001);

${rcFor('Trygve Hammer', 'Trygve', 'Hammer', -380001, false)}
${rcFor('Julie Fedorchak', 'Julie', 'Fedorchak', -38000, true)}
COMMIT;
`);
console.log('ND new: 1 (Hammer -380001); Fedorchak reused');
