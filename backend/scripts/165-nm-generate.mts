import { writeFileSync, mkdirSync } from 'fs';

// ---- NM field (validated against staging/p165-NM.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-04: NM vanilla create-election-first seed (clone of the 162-mn pattern).
//   1 election 'NM 2026 Statewide General' + 3 races on existing NATIONAL_LOWER offices (3501-3503).
//   DECIDED field (primary done) -> NOT PROVISIONAL. All 3 incumbents renominated (reuse
//   -35001..-35003, is_incumbent=true). 1 new R challenger per district.
//   D-04 safe_start_seq (live-confirmed: band tops -350125/-350250/-350381): NM-1=26, NM-2=51, NM-3=82.
const ELECTION = 'NM 2026 Statewide General';
const FIPS = 35;
const RACE_DESC = 'Confirmed general field (NM SoS certified 2026 candidate list)';
const SRC = 'NM SoS candidate portal (candidateportal.servis.sos.state.nm.us, eid=2917; decided general field)';

const INC_EXT: Record<number, number> = { 1: -35001, 2: -35002, 3: -35003 };
const INC_NAME: Record<number, string> = { 1: 'Melanie A. Stansbury', 2: 'Gabe Vasquez', 3: 'Teresa Leger Fernandez' };
const SEQ_START: Record<number, number> = { 1: 26, 2: 51, 3: 82 };

type Cand = { cd: number; name: string; party: string };
const FIELD: Cand[] = [
  { cd: 1, name: 'Didi Okpareke',   party: 'Republican' },
  { cd: 2, name: 'Greg Cunningham', party: 'Republican' },
  { cd: 3, name: 'Martin Zamora',   party: 'Republican' },
];

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number };
const rows: Row[] = [];
for (const c of FIELD) {
  seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
  rows.push({ ...c, geo: '35' + String(c.cd).padStart(2, '0'), ext: -(FIPS * 10000 + c.cd * 100 + seqByCd[c.cd]) });
}

// ---- Migration A (1256): election + 3 races ----
let raceInserts = '';
for (let cd = 1; cd <= 3; cd++) {
  const geo = '35' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
const migA = `-- 1256_seed_nm_2026_house_election_races.sql
-- Phase 165-04: 'NM 2026 Statewide General' + 3 U.S. House races on existing NATIONAL_LOWER
--   offices (geo 3501-3503). DECIDED field -> NOT PROVISIONAL. office_id never NULL.
--   ANTIPARTISAN: party never stored.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'NM'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`;
writeFileSync('migrations/1256_seed_nm_2026_house_election_races.sql', migA);

// ---- Migration B (1257): 3 new challengers + 3 incumbent reuse ----
let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
let rcInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(r.geo)}
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}
for (const cd of [1, 2, 3]) {
  const { first, last } = nameParts(INC_NAME[cd]);
  const geo = '35' + String(cd).padStart(2, '0');
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(INC_NAME[cd])}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.politicians p ON p.external_id = ${INC_EXT[cd]}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}
const migB = `-- 1257_seed_nm_2026_house_candidates.sql
-- Phase 165-04: 3 new NM R challengers (Okpareke -350126, Cunningham -350251, Zamora -350382 —
--   D-04 safe_start_seq 26/51/82) + 3 renominated incumbents reused by external_id
--   (-35001..-35003, is_incumbent=true). DECIDED. NOT EXISTS on (race_id, politician_id);
--   sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1257_seed_nm_2026_house_candidates.sql', migB);

const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`NM new: ${rows.length} (${rows.map(r=>r.ext).join(', ')}); incumbents reused: 3; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('Wrote: migrations/1256_..., migrations/1257_...');
