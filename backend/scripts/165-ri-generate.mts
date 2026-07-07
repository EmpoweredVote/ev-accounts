import { writeFileSync } from 'fs';

// ---- RI field (staging/p165-RI.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-07: RI vanilla create-election-first seed, LATE-PRIMARY -> PROVISIONAL.
//   RI 2026 primary: 2026-09-09 (verified 2026-07-07) -> cull >= 2026-09-09. Filing closed 7/10 —
//   field re-verified against the RI wiki roster at execution. Incumbents renominated:
//   Amo -44001 / Magaziner -44002. Band -440299..-440101 EMPTY live -> seq from 1.
const ELECTION = 'RI 2026 Statewide General';
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-09-09';
const SRC = 'RI 2026 general field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Rhode_Island; pre-primary qualified field, cull >= 2026-09-09)';
const INC: Array<[number, string, number]> = [[1, 'Gabe Amo', -44001], [2, 'Seth Magaziner', -44002]];
const FIELD: Array<[number, string, string]> = [
  [1, 'Kellie Keenan', 'Republican'], [1, 'Pedro DeSouza', 'Independent'],
  [2, 'Victor Mellor', 'Republican'], [2, 'Stephen Skoly', 'Republican'],
];
function np(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seq: Record<number, number> = {};
const rows = FIELD.map(([cd, name, party]) => {
  seq[cd] = (seq[cd] || 0) + 1;
  return { cd, name, party, geo: '44' + String(cd).padStart(2, '0'), ext: -(44 * 10000 + cd * 100 + seq[cd]) };
});

let raceInserts = '';
for (const cd of [1, 2]) {
  const geo = '44' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
writeFileSync('migrations/1268_seed_ri_2026_house_election_races.sql', `-- 1268_seed_ri_2026_house_election_races.sql
-- Phase 165-07: 'RI 2026 Statewide General' + 2 races (geo 4401-4402). PROVISIONAL (RI primary
--   2026-09-09 verified). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'RI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`);

let sql = '';
for (const r of rows) {
  const { first, last } = np(r.name);
  sql += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
const rcFor = (name: string, ext: number, geo: string, inc: boolean) => {
  const { first, last } = np(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
};
for (const r of rows) sql += rcFor(r.name, r.ext, r.geo, false);
for (const [cd, name, ext] of INC) sql += rcFor(name, ext, '44' + String(cd).padStart(2, '0'), true);

writeFileSync('migrations/1269_seed_ri_2026_house_candidates.sql', `-- 1269_seed_ri_2026_house_candidates.sql
-- Phase 165-07: 4 new RI challengers (-440101/-440102 RI-1; -440201/-440202 RI-2, band empty live)
--   + Amo (-44001) and Magaziner (-44002) renominated reuse. PROVISIONAL, cull >= 2026-09-09.
--   NOT EXISTS on (race_id, politician_id); sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

${sql}
COMMIT;
`);
console.log(`RI new: ${rows.length} (${rows.map(r => r.ext).join(', ')}); incumbents reused: 2`);
