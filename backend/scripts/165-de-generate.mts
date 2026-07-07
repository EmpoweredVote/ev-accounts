import { writeFileSync } from 'fs';

// ---- DE field (staging/p165-DE.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-07: DE at-large create-election-first seed, LATE-PRIMARY -> PROVISIONAL.
//   DE 2026 primary: 2026-09-15 (verified 2026-07-07) -> cull >= 2026-09-15.
//   PITFALL 6 (D-04 MANDATORY): the DE band -(10*10000+seq) collides with 26 legacy Wave-1
//   CA-House/AL-exec records at seqs 1-47 (live-confirmed: 26 rows in -100047..-100001; 0 rows in
//   -100099..-100048) -> safe_start_seq=48; Earl Cooper = -100048. A record at seq<48 would
//   silently no-op-collide with an unrelated legacy politician.
//   McBride (-10000) renominated reuse. At-large position convention: 'U.S. Representative At-Large'.
const ELECTION = 'DE 2026 Statewide General';
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-15';
const SRC = 'DE Dept of Elections 2026 candidate list (elections.delaware.gov genl_fcddt_2026; pre-primary qualified field, cull >= 2026-09-15)';
function np(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const COOPER_EXT = -100048; // D-04 safe_start_seq=48 MANDATORY

writeFileSync('migrations/1270_seed_de_2026_house_election_race.sql', `-- 1270_seed_de_2026_house_election_race.sql
-- Phase 165-07: 'DE 2026 Statewide General' + 1 at-large race (geo 1000). PROVISIONAL (DE primary
--   2026-09-15 verified). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'DE'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '1000'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`);

const rcFor = (name: string, ext: number, inc: boolean) => {
  const { first, last } = np(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
};
writeFileSync('migrations/1271_seed_de_2026_house_candidates.sql', `-- 1271_seed_de_2026_house_candidates.sql
-- Phase 165-07: Earl Cooper (R) at -100048 — D-04 safe_start_seq=48 MANDATORY (seqs 1-47 = 26
--   unrelated legacy Wave-1 records; a lower seq would silently no-op-collide, Pitfall 6) +
--   McBride (-10000) renominated reuse. PROVISIONAL, cull >= 2026-09-15. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${COOPER_EXT}, 'Earl Cooper', 'Earl', 'Cooper', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${COOPER_EXT});

${rcFor('Earl Cooper', COOPER_EXT, false)}
${rcFor('Sarah McBride', -10000, true)}
COMMIT;
`);
console.log(`DE new: 1 (Earl Cooper ${COOPER_EXT}, safe_start_seq=48); McBride reused`);
