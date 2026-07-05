import { writeFileSync, mkdirSync } from 'fs';

// ---- MD field (validated against 160-field-table-p162.csv MD rows + LIVE prod dedup 2026-07-05) ----
// Phase 162-08 Task 2: MD CANDIDATES-ONLY seed onto the 8 PRE-EXISTING MD U.S. House races
//   (2026 Maryland General Election; existing_race_id per 160-race-preexistence-audit.csv).
//   NO elections/races INSERT. DECIDED field (Jun-23 primary done; unaffiliated/minor window
//   open to 2026-08-03 → Phase 167 reconciles late independents). MD has 0 pre-existing
//   race_candidates rows (confirmed live) → every active incumbent gets a fresh REUSE row (no
//   Clark/Pressley-style skip). Hoyer MD-5 RETIRED (Boafo won primary) → no incumbent row.
//   DEDUP (live): Adrian Boafo (MD-5 D nominee) already exists as pid 1da26040 / external_id
//   -2420067 (prior MD state-delegate record, already has a headshot) → REUSE by pid, keep his
//   external_id, is_incumbent=false. The other 12 challengers are genuinely new.

const EXISTING_RACE_ID: Record<number, string> = {
  1: 'cb9a70c8-626b-43ed-9267-9531d2403535',
  2: '01c39962-63fe-4f5d-ac56-a546e09374a6',
  3: '34ae857f-a68e-40c6-a1bd-1bc9266dce5b',
  4: '1df5607b-36f4-45f6-a94f-adabba5811da',
  5: 'b927bbd3-be7b-4ca1-a5f0-0fcd743a9997',
  6: 'd5d7f27a-e421-46d8-af73-da225ea625a0',
  7: 'a6b83f0d-bc99-4f29-9d39-a87025d55a01',
  8: '52874d42-9b2b-47c9-a87b-c11801627eb2',
};

// 7 ACTIVE incumbents (Hoyer MD-5 retired → excluded). Reuse existing pid + external_id.
const INC: Record<number, { pid: string; name: string }> = {
  1: { pid: 'ff596d3f-3056-43e2-a80a-8c4b8fd9abde', name: 'Andy Harris' },
  2: { pid: '504ff19d-5db9-4093-9cba-d36fcb70f1b6', name: 'Johnny Olszewski' },
  3: { pid: '87560825-eced-4690-be06-88549f0f83cf', name: 'Sarah Elfreth' },
  4: { pid: 'e59ec991-3948-4369-913c-63c62dc3ece5', name: 'Glenn Ivey' },
  6: { pid: 'da087947-83af-4ca2-91c8-1f9e0bf887a9', name: 'April McClain Delaney' },
  7: { pid: '6e2f5cf7-4e00-4a83-b1d7-b3f2ea4c1ffd', name: 'Kweisi Mfume' },
  8: { pid: '731c674f-8f44-4df3-8b04-3b70be39a1bd', name: 'Jamie Raskin' },
};

type Disp = 'NEW' | 'REUSE_PID';
type Cand = { cd: number; name: string; party: string; role: string; disp: Disp; pid?: string; ext?: number };

// 13 challengers: 12 NEW + Boafo REUSE_PID. Party normalized (never "Democrat").
const FIELD: Cand[] = [
  { cd:1, name:'Dan Schwartz', party:'Democratic', role:'D', disp:'NEW' },
  { cd:2, name:'Dave Wallace', party:'Republican', role:'R', disp:'NEW' },
  { cd:3, name:'Berney Flowers', party:'Republican', role:'R', disp:'NEW' },
  { cd:4, name:'George McDermott', party:'Republican', role:'R', disp:'NEW' },
  // MD-5 open seat (Hoyer retired): Boafo won the D primary — REUSE his existing state-delegate record
  { cd:5, name:'Adrian Boafo', party:'Democratic', role:'D', disp:'REUSE_PID', pid:'1da26040-98b4-4eb0-aa1f-3ec05b297a29', ext:-2420067 },
  { cd:5, name:'Chris Chaffee', party:'Republican', role:'R', disp:'NEW' },
  { cd:5, name:'Jonathan Burruss', party:'Unaffiliated', role:'IND', disp:'NEW' },
  { cd:5, name:'Brian Jordan', party:'Unaffiliated', role:'IND', disp:'NEW' },
  { cd:6, name:'Robin Ficker', party:'Republican', role:'R', disp:'NEW' },
  { cd:6, name:'Moshe Landman', party:'Green', role:'G', disp:'NEW' },
  { cd:7, name:'Scott Collier', party:'Republican', role:'R', disp:'NEW' },
  { cd:8, name:'Cheryl Riley', party:'Republican', role:'R', disp:'NEW' },
  { cd:8, name:'Nancy Wallace', party:'Green', role:'G', disp:'NEW' },
];

const SRC_MAJOR = 'MD SBE 2026 primary results + declared general field (decided; unaffiliated/minor window open to 2026-08-03)';
const SRC_OTHER = 'MD SBE 2026 declared unaffiliated/minor-party general field (window open to 2026-08-03)';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids: NEW get -(24*10000+cd*100+seq); REUSE_PID keeps its own ----
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; source: string; decision: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '24' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  if (c.disp === 'REUSE_PID') {
    rows.push({ ...c, geo, ext: c.ext!, source, decision: 'REUSE-PID' });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(24 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, source, decision: 'NEW' });
  }
}
const newRows = rows.filter(r => r.decision === 'NEW');

// ---- CSV reconciliation ----
mkdirSync('data/seed-md-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,existing_pid,is_incumbent,source';
const csvLines: string[] = [];
for (const r of rows) csvLines.push([r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.pid || '', false, `"${r.source}"`].join(','));
for (const cd of Object.keys(INC).map(Number).sort((a,b)=>a-b)) csvLines.push([cd, '24'+String(cd).padStart(2,'0'), `"${INC[cd].name}"`, '', 'INC', 'REUSE-ADD-ROW', '', INC[cd].pid, true, `"${SRC_MAJOR}"`].join(','));
csvLines.push([5, '2405', '"Steny Hoyer"', '', 'INC', 'RETIRED-NO-ROW', '', '', false, '"open seat -- retired, no incumbent row"'].join(','));
writeFileSync('data/seed-md-2026-house/162-08-md-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration: candidates-only onto the 8 existing races ----
const raceIdList = Object.values(EXISTING_RACE_ID).map(id => `'${id}'::uuid`).join(',');

// (a) 12 new politician records (idempotent on external_id); Boafo NOT inserted (reuse)
let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

// (b) race_candidates: 13 challengers (12 new by external_id + Boafo by pid, all is_incumbent=false)
let rcInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  const raceId = EXISTING_RACE_ID[r.cd];
  const match = r.decision === 'REUSE-PID' ? `p.id = '${r.pid}'::uuid` : `p.external_id = ${r.ext}`;
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(r.source)}
FROM essentials.politicians p
WHERE ${match}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}
// (c) 7 active incumbents by pid (is_incumbent=true; Hoyer excluded)
for (const cd of Object.keys(INC).map(Number).sort((a,b)=>a-b)) {
  const { first, last } = nameParts(INC[cd].name);
  const raceId = EXISTING_RACE_ID[cd];
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '${raceId}'::uuid, p.id, ${sqlStr(INC[cd].name)}, ${sqlStr(first)}, ${sqlStr(last)}, true, 'active', ${sqlStr(SRC_MAJOR)}
FROM essentials.politicians p
WHERE p.id = '${INC[cd].pid}'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '${raceId}'::uuid AND rc.politician_id = p.id);
`;
}

const migration = `-- 1217_seed_md_2026_house_candidates.sql
-- Phase 162-08: MD CANDIDATES-ONLY seed onto the 8 PRE-EXISTING MD U.S. House races
--   (2026 Maryland General Election; races NOT created here -- reuse existing_race_id).
--   ${newRows.length} new MD politicians + 13 challenger race_candidates (12 new by external_id + Adrian
--   Boafo reused by pid 1da26040/external_id -2420067) + 7 renominated-incumbent race_candidates
--   (Harris/Olszewski/Elfreth/Ivey/McClain Delaney/Mfume/Raskin, reusing existing pids). Hoyer
--   MD-5 RETIRED -> NO incumbent row (open seat). DECIDED field -> NOT PROVISIONAL. Every
--   race_candidates INSERT guarded by NOT EXISTS (race_id, politician_id). sqlStr()-escaped.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party untouched.
BEGIN;

-- Mark the 8 existing MD races with the decided/open-window wording (description-only; idempotent)
UPDATE essentials.races
SET description = 'Confirmed nominees + declared-so-far minor-party field; unaffiliated window open to 2026-08-03'
WHERE id IN (${raceIdList})
  AND (description IS NULL OR description NOT LIKE '%unaffiliated window open%');

-- (a) ${newRows.length} new challenger/open-seat/minor-party records (idempotent on external_id)
${polInserts}
-- (b)+(c) 13 challenger + 7 incumbent race_candidates (NOT EXISTS on (race_id, politician_id))
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1217_seed_md_2026_house_candidates.sql', migration);

console.log(`challengers: ${rows.length} (NEW=${newRows.length}, REUSE-PID=${rows.length-newRows.length}); active incumbents: ${Object.keys(INC).length}`);
console.log(`new external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = [...rows.map(r=>r.name.toLowerCase()), ...Object.values(INC).map(i=>i.name.toLowerCase())].filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts (challengers + incumbent):');
for (let cd=1; cd<=8; cd++) console.log(`  MD-${cd}: ${rows.filter(r=>r.cd===cd).length} challengers + ${INC[cd]?1:0} incumbent`);
console.log('\nWrote: migrations/1217_seed_md_2026_house_candidates.sql, data/seed-md-2026-house/162-08-md-reconciliation.csv');
