import { writeFileSync, mkdirSync } from 'fs';

// ---- AR field (validated against 160-field-table-p164.csv AR rows) ----
// Phase 164-06 Task 2: AR end-to-end seed (vanilla new-election, 1-election). AR is NOT
//   redistricted -> no withholding. DECIDED general field -> NOT PROVISIONAL. All 4 incumbents
//   renominated (no open seats) -> reuse -5001..-5004 (is_incumbent). Band -50499..-50101 empty
//   live (164-06 Task 1) -> standard seq start 1.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };
const INC_EXT: Record<number, number> = {1:-5001,2:-5002,3:-5003,4:-5004};
const INC_NAME: Record<number, string> = {1:'Eric A. "Rick" Crawford',2:'J. French Hill',3:'Steve Womack',4:'Bruce Westerman'};

const FIELD: Cand[] = [
  { cd:1, name:INC_NAME[1], party:'Republican', role:'R', inc:true },
  { cd:1, name:'Terri Yarbrough Green', party:'Democratic', role:'D' },
  { cd:1, name:'Steve Parsons', party:'Libertarian', role:'LIB' },
  { cd:2, name:INC_NAME[2], party:'Republican', role:'R', inc:true },
  { cd:2, name:'Chris Jones', party:'Democratic', role:'D' },
  { cd:3, name:INC_NAME[3], party:'Republican', role:'R', inc:true },
  { cd:3, name:'Robb Ryerse', party:'Democratic', role:'D' },
  { cd:3, name:'Bobby Wilson', party:'Libertarian', role:'LIB' },
  { cd:4, name:INC_NAME[4], party:'Republican', role:'R', inc:true },
  { cd:4, name:'James Russell', party:'Democratic', role:'D' },
];

const SRC_MAJOR = 'AR 2026 US House field (AR SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Arkansas); decided general field';
const SRC_OTHER = 'AR 2026 US House field (minor-party/independent filing; AR SoS + Wikipedia); decided general field';

function nameParts(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '05' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(5 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

mkdirSync('data/seed-ar-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-ar-2026-house/164-06-ar-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

const mElections = `-- 1242_seed_ar_2026_house_elections_races.sql
-- Phase 164-06 Task 2: AR 2026 Statewide General election + 4 U.S. House races (geo 0501..0504).
--   Decided field -> NOT PROVISIONAL. All incumbents renominated (no open seats). ANTIPARTISAN
--   INVARIANT: party never stored on race_candidates; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AR 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AR'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AR 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '05'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AR 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`;
writeFileSync('migrations/1242_seed_ar_2026_house_elections_races.sql', mElections);

const newRows = rows.filter(r => r.decision === 'NEW');
const activeRows = rows.filter(r => r.decision === 'NEW' || r.decision === 'REUSE');
let polInserts = '';
for (const r of newRows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
let rcInserts = '';
for (const r of activeRows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${r.is_incumbent}, 'active', ${sqlStr(r.source)}
FROM essentials.races r
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.elections el ON el.id = r.election_id
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE el.name = 'AR 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}
const mCandidates = `-- 1243_seed_ar_2026_house_candidates.sql
-- Phase 164-06 Task 2: ${newRows.length} new AR politicians + ${activeRows.length} active race_candidates onto the 4
--   AR 2026 Statewide General races. Reuse 4 renominated incumbents (-5001..-5004). No open seats.
--   external_id band -(5*10000+cd*100+seq), standard seq 1. ANTIPARTISAN: party never stored.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1243_seed_ar_2026_house_candidates.sql', mCandidates);

console.log(`AR NEW=${newRows.length} active=${activeRows.length}`);
console.log(`AR external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}; dup full_name: ${dupName.length ? dupName : 'none'}`);
for (let cd=1; cd<=4; cd++) console.log(`  AR-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new)`);
console.log('Wrote: migrations/1242_..., migrations/1243_..., data/seed-ar-2026-house/164-06-ar-reconciliation.csv');
