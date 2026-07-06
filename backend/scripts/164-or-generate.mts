import { writeFileSync, mkdirSync } from 'fs';

// ---- OR field (validated against 160-field-table-p164.csv OR rows + LIVE prod checks 2026-07-06) ----
// Phase 164-03 Task 2: OR CANDIDATES-ONLY seed onto the 6 PRE-EXISTING OR U.S. House races
//   ('OR 2026 General'; existing_race_id per the field table, confirmed live). NO elections/races
//   INSERT (D-03, the MD-162/MA-161 reuse pattern). DECIDED field (OR primary done) -> NOT
//   PROVISIONAL; OR unaffiliated/minor window open to 2026-08-25 -> Phase 167 reconciles late
//   filers. 0 pre-existing race_candidates on the 6 races (confirmed live) -> each of the 6
//   renominated incumbents gets a fresh REUSE row (is_incumbent=true), + 7 new challengers.
//   COLLISION SUB-BAND (D-04): OR-1 seqs 10-13 are occupied by 4 OR LOCAL officials (Nafisa Fai/
//   Pam Treece/Jason Snider/Jerry Willey, the parallel 177/178 session's domain) -> OR-1 new
//   record starts at seq 14; OR-2..6 standard start 1. Incumbents reuse -4102001..-4102006.
const EXISTING_RACE_ID: Record<number, string> = {
  1: '8dfd6e35-f91d-4d14-bcec-ae983035da51',
  2: '504a156a-d4e6-4abe-9a85-a418c0135805',
  3: '61297fac-c98d-4ad4-b93f-b2e36722bd6a',
  4: 'c5023da0-985e-4e1c-817c-a843849ef6e9',
  5: '17a4b696-5c15-4f2b-9390-ce1864d57f37',
  6: 'dd25e913-2496-40fa-a735-c9b1d7f68df8',
};
// 6 renominated incumbents reused by external_id (each gets is_incumbent=true REUSE row).
const INC_EXT: Record<number, number> = {1:-4102001,2:-4102002,3:-4102003,4:-4102004,5:-4102005,6:-4102006};
const INC_NAME: Record<number, string> = {1:'Suzanne Bonamici',2:'Cliff Bentz',3:'Maxine Dexter',4:'Val Hoyle',5:'Janelle Bynum',6:'Andrea Salinas'};
// D-04 per-district seq starts (OR-1=14, else 1).
const SEQ_START: Record<number, number> = {1:14,2:1,3:1,4:1,5:1,6:1};

type Cand = { cd: number; name: string; party: string; role: string };
// 7 new challengers (party normalized; "Pacific Green" preserved as a party string, never on card).
const FIELD: Cand[] = [
  { cd:1, name:'Barbara Kahl', party:'Republican', role:'R' },
  { cd:2, name:'Chris Beck', party:'Democratic', role:'D' },
  { cd:3, name:'Loran Ayles', party:'Republican', role:'R' },
  { cd:4, name:'Monique DeSpain', party:'Republican', role:'R' },
  { cd:4, name:'Justin Filip', party:'Pacific Green', role:'PG' },
  { cd:5, name:'Patti Adair', party:'Republican', role:'R' },
  { cd:6, name:'David Russ', party:'Republican', role:'R' },
];

const SRC_MAJOR = 'OR SoS 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-25 -> Phase 167)';
const SRC_OTHER = 'OR SoS 2026 declared minor-party/independent general field (window open to 2026-08-25 -> Phase 167)';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids for NEW challengers: -(41*10000+cd*100+seq), seq from SEQ_START ----
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '41' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
  const ext = -(41 * 10000 + c.cd * 100 + seqByCd[c.cd]);
  rows.push({ ...c, geo, ext, source });
}

// ---- CSV reconciliation ----
mkdirSync('data/seed-or-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines: string[] = [];
for (const r of rows) csvLines.push([r.cd, r.geo, `"${r.name}"`, r.party, r.role, 'NEW', r.ext, false, `"${r.source}"`].join(','));
for (const cd of Object.keys(INC_EXT).map(Number).sort((a,b)=>a-b)) csvLines.push([cd, '41'+String(cd).padStart(2,'0'), `"${INC_NAME[cd]}"`, '', 'INC', 'REUSE-ADD-ROW', INC_EXT[cd], true, `"${SRC_MAJOR}"`].join(','));
writeFileSync('data/seed-or-2026-house/164-03-or-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1235: candidates-only onto the 6 existing OR races ----
const raceIdList = Object.values(EXISTING_RACE_ID).map(id => `'${id}'::uuid`).join(',');

// (a) 7 new politician records (idempotent on external_id)
let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

// (b) 7 new challenger race_candidates by external_id (is_incumbent=false)
let rcInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  const raceId = EXISTING_RACE_ID[r.cd];
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(r.source)}
FROM essentials.politicians p
WHERE p.external_id = ${r.ext}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}
// (c) 6 renominated incumbents by external_id (is_incumbent=true)
for (const cd of Object.keys(INC_EXT).map(Number).sort((a,b)=>a-b)) {
  const { first, last } = nameParts(INC_NAME[cd]);
  const raceId = EXISTING_RACE_ID[cd];
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(INC_NAME[cd])}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(SRC_MAJOR)}
FROM essentials.politicians p
WHERE p.external_id = ${INC_EXT[cd]}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}

const migration = `-- 1235_seed_or_2026_house_candidates.sql
-- Phase 164-03: OR CANDIDATES-ONLY seed onto the 6 PRE-EXISTING OR U.S. House races
--   ('OR 2026 General'; races NOT created here -- reuse existing_race_id, D-03). ${rows.length} new OR
--   politicians + ${rows.length} challenger race_candidates + 6 renominated-incumbent race_candidates
--   (Bonamici/Bentz/Dexter/Hoyle/Bynum/Salinas, reused by external_id -4102001..-4102006). DECIDED
--   field -> NOT PROVISIONAL (OR unaffiliated/minor window open to 2026-08-25 -> Phase 167). Every
--   race_candidates INSERT guarded by NOT EXISTS (race_id, politician_id). OR-1 new record uses seq
--   14 (D-04; seqs 10-13 = OR local officials). sqlStr()-escaped. ANTIPARTISAN: party never stored.
BEGIN;

-- Mark the 6 existing OR races with the decided/open-window wording (description-only; idempotent)
UPDATE essentials.races
SET description = 'Confirmed general field; OR unaffiliated/minor-party window open to 2026-08-25 -> Phase 167'
WHERE id IN (${raceIdList})
  AND (description IS NULL OR description NOT LIKE '%unaffiliated/minor-party window open%');

-- (a) ${rows.length} new challenger records (idempotent on external_id)
${polInserts}
-- (b)+(c) ${rows.length} challenger + 6 incumbent race_candidates (NOT EXISTS on (race_id, politician_id))
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1235_seed_or_2026_house_candidates.sql', migration);

console.log(`new challengers: ${rows.length}; active incumbents (reused): ${Object.keys(INC_EXT).length}`);
console.log(`new external_id range: ${Math.min(...rows.map(r=>r.ext))} .. ${Math.max(...rows.map(r=>r.ext))}`);
const dupExt = rows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC_NAME).map(n=>n.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
for (let cd=1; cd<=6; cd++) console.log(`  OR-${cd}: ${rows.filter(r=>r.cd===cd).length} new + 1 incumbent, new ext: ${rows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1235_seed_or_2026_house_candidates.sql, data/seed-or-2026-house/164-03-or-reconciliation.csv');
