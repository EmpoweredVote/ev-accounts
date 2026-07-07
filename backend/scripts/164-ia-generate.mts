import { writeFileSync, mkdirSync } from 'fs';

// ---- IA field (validated against 160-field-table-p164.csv IA rows) ----
// Phase 164-05 Task 3: IA end-to-end seed (vanilla new-election, 1-election). IA is NOT
//   redistricted -> no withholding. DECIDED general field -> NOT PROVISIONAL. Two OPEN seats
//   (D-05): IA-2 Ashley Hinson (-19002) RETIRED -> Joe Mitchell (R) nominee; IA-4 Randy Feenstra
//   (-19004) RETIRED -> Chris McGowan (R) nominee. Both departing incumbents get NO row.
//   Renominated incumbents reused (is_incumbent): Miller-Meeks -19001 (IA-1), Nunn -19003 (IA-3).
//   IA band -190499..-190101 confirmed EMPTY live (164-05 Task 1) -> standard seq start 1.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };
const INC_EXT: Record<number, number> = {1:-19001,3:-19003}; // renominated only
const SEQ_START: Record<number, number> = {1:1,2:1,3:1,4:1};

const FIELD: Cand[] = [
  // IA-1 (1901): Miller-Meeks renominated
  { cd:1, name:'Mariannette Miller-Meeks', party:'Republican', role:'R', inc:true },
  { cd:1, name:'Christina Bohannan', party:'Democratic', role:'D' },
  { cd:1, name:'Michael Bridgford', party:'Independent', role:'IND' },
  // IA-2 (1902): OPEN — Hinson retired (EXCLUDED); Mitchell R nominee
  { cd:2, name:'Joe Mitchell', party:'Republican', role:'R' },
  { cd:2, name:'Lindsay James', party:'Democratic', role:'D' },
  { cd:2, name:'Dave Bushaw', party:'Independent', role:'IND' },
  { cd:2, name:'Rick Stewart', party:'Libertarian', role:'LIB' },
  // IA-3 (1903): Nunn renominated
  { cd:3, name:'Zachary Nunn', party:'Republican', role:'R', inc:true },
  { cd:3, name:'Sarah Trone Garriott', party:'Democratic', role:'D' },
  // IA-4 (1904): OPEN — Feenstra retired (EXCLUDED); McGowan R nominee
  { cd:4, name:'Chris McGowan', party:'Republican', role:'R' },
  { cd:4, name:'Dave Dawson', party:'Democratic', role:'D' },
];
const EXCLUDED = [
  { cd:2, name:'Ashley Hinson', ext:-19002, reason:'retired (Joe Mitchell is the R nominee)' },
  { cd:4, name:'Randy Feenstra', ext:-19004, reason:'retired (Chris McGowan is the R nominee)' },
];

const SRC_MAJOR = 'IA 2026 US House field (IA SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Iowa); decided general field';
const SRC_OTHER = 'IA 2026 US House field (independent/minor-party filing; IA SoS + Wikipedia); decided general field';

function nameParts(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '19' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
    const ext = -(19 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

mkdirSync('data/seed-ia-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
for (const e of EXCLUDED) csvLines.push([e.cd, '19'+String(e.cd).padStart(2,'0'), `"${e.name}"`, '', 'INC', 'EXCLUDED-NO-ROW', e.ext, false, `"D-05 open seat: ${e.reason}"`].join(','));
writeFileSync('data/seed-ia-2026-house/164-05-ia-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

const mElections = `-- 1240_seed_ia_2026_house_elections_races.sql
-- Phase 164-05 Task 3: IA 2026 Statewide General election + 4 U.S. House races (geo 1901..1904).
--   Decided field -> NOT PROVISIONAL. IA-2 (Hinson retired) + IA-4 (Feenstra retired) open seats —
--   offices exist, NO insert. ANTIPARTISAN INVARIANT: party never stored; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'IA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'IA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'IA 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '19'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'IA 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`;
writeFileSync('migrations/1240_seed_ia_2026_house_elections_races.sql', mElections);

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
WHERE el.name = 'IA 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}
const mCandidates = `-- 1241_seed_ia_2026_house_candidates.sql
-- Phase 164-05 Task 3: ${newRows.length} new IA politicians + ${activeRows.length} active race_candidates onto the 4
--   IA 2026 Statewide General races. Reuse 2 renominated incumbents (-19001 Miller-Meeks/-19003
--   Nunn). OPEN SEATS (D-05): Hinson -19002 (IA-2, retired) + Feenstra -19004 (IA-4, retired) NO row.
--   external_id band -(19*10000+cd*100+seq), standard seq start 1. ANTIPARTISAN: party never stored.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1241_seed_ia_2026_house_candidates.sql', mCandidates);

console.log(`IA NEW=${newRows.length} active=${activeRows.length}; EXCLUDED: ${EXCLUDED.map(e=>e.name).join(', ')}`);
console.log(`IA external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
for (let cd=1; cd<=4; cd++) console.log(`  IA-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new), new ext: ${newRows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1240_..., migrations/1241_..., data/seed-ia-2026-house/164-05-ia-reconciliation.csv');
