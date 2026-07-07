import { writeFileSync, mkdirSync } from 'fs';

// ---- OK field (validated against 160-field-table-p164.csv OK rows) ----
// Phase 164-05 Task 2: OK end-to-end seed (vanilla new-election, 1-election). OK is NOT
//   redistricted -> no withholding. DECIDED general field -> NOT PROVISIONAL. One OPEN seat
//   (D-05): OK-1 Kevin Hern (-40001) RETIRED -> Mark Tedford (R) nominee, Hern gets NO row.
//   Renominated incumbents reused (is_incumbent): Brecheen -40002, Lucas -40003, Cole -40004,
//   Bice -40005.
// COLLISION SUB-BAND (D-04 + 164-05 Task-1 correction): OK-1 seqs 1-43 (-400101..-400143) are
//   occupied by 43 US-Senate-cycle records. The audit's safe_start_seq=200 is UNSAFE here because
//   OK-1 has 2 new records: seq 200/201 -> -400300/-400301, and -400301 collides with OK-3 seq 1
//   (cd=3 base 400300+1). Fix: OK-1 uses the first free IN-CENTURY seqs 44/45 (-400144/-400145),
//   which stay within cd=1's 400101-400199 range and cross no district boundary. Verified free live.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };
const INC_EXT: Record<number, number> = {2:-40002,3:-40003,4:-40004,5:-40005}; // renominated only
const SEQ_START: Record<number, number> = {1:44,2:1,3:1,4:1,5:1};

const FIELD: Cand[] = [
  // OK-1 (4001): OPEN — Hern retired (EXCLUDED); Tedford R nominee
  { cd:1, name:'Mark Tedford', party:'Republican', role:'R' },
  { cd:1, name:'John Croisant', party:'Democratic', role:'D' },
  // OK-2 (4002): Brecheen renominated
  { cd:2, name:'Josh Brecheen', party:'Republican', role:'R', inc:true },
  { cd:2, name:'Brandon Wade', party:'Democratic', role:'D' },
  { cd:2, name:'Ronnie Hopkins', party:'Independent', role:'IND' },
  // OK-3 (4003): Lucas renominated
  { cd:3, name:'Frank D. Lucas', party:'Republican', role:'R', inc:true },
  { cd:3, name:'Suzie Byrd', party:'Democratic', role:'D' },
  // OK-4 (4004): Cole renominated
  { cd:4, name:'Tom Cole', party:'Republican', role:'R', inc:true },
  { cd:4, name:'Mitchell Jacob', party:'Democratic', role:'D' },
  { cd:4, name:'Rocco Bonacci', party:'Independent', role:'IND' },
  // OK-5 (4005): Bice renominated
  { cd:5, name:'Stephanie I. Bice', party:'Republican', role:'R', inc:true },
  { cd:5, name:'Jena Nelson', party:'Democratic', role:'D' },
  { cd:5, name:'Robert P. Henri', party:'Independent', role:'IND' },
  { cd:5, name:'Austin Nieves', party:'Independent', role:'IND' },
];
const EXCLUDED = [{ cd:1, name:'Kevin Hern', ext:-40001, reason:'retired (Tedford is the R nominee)' }];

const SRC_MAJOR = 'OK 2026 US House field (OK SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Oklahoma); decided general field';
const SRC_OTHER = 'OK 2026 US House field (independent/minor-party filing; OK SoS + Wikipedia); decided general field';

function nameParts(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '40' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
    const ext = -(40 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

mkdirSync('data/seed-ok-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
for (const e of EXCLUDED) csvLines.push([e.cd, '40'+String(e.cd).padStart(2,'0'), `"${e.name}"`, '', 'INC', 'EXCLUDED-NO-ROW', e.ext, false, `"D-05 open seat: ${e.reason}"`].join(','));
writeFileSync('data/seed-ok-2026-house/164-05-ok-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

const mElections = `-- 1238_seed_ok_2026_house_elections_races.sql
-- Phase 164-05 Task 2: OK 2026 Statewide General election + 5 U.S. House races (geo 4001..4005).
--   Decided field -> NOT PROVISIONAL. OK-1 open seat (Hern retired) — office exists, NO insert.
--   ANTIPARTISAN INVARIANT: party never stored on race_candidates; races.primary_party NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'OK 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'OK'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'OK 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '40'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'OK 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`;
writeFileSync('migrations/1238_seed_ok_2026_house_elections_races.sql', mElections);

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
WHERE el.name = 'OK 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}
const mCandidates = `-- 1239_seed_ok_2026_house_candidates.sql
-- Phase 164-05 Task 2: ${newRows.length} new OK politicians + ${activeRows.length} active race_candidates onto the 5
--   OK 2026 Statewide General races. Reuse 4 renominated incumbents (-40002 Brecheen/-40003 Lucas/
--   -40004 Cole/-40005 Bice). OPEN SEAT (D-05): Hern -40001 (OK-1, retired) NO row. external_id band
--   -(40*10000+cd*100+seq); OK-1 uses in-century seq 44/45 (-400144/-400145) to avoid the 43 occupied
--   seqs AND the OK-3 cross-boundary collision. ANTIPARTISAN: party never stored.
BEGIN;

${polInserts}
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1239_seed_ok_2026_house_candidates.sql', mCandidates);

console.log(`OK NEW=${newRows.length} active=${activeRows.length}; EXCLUDED: ${EXCLUDED.map(e=>e.name).join(', ')}`);
console.log(`OK external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
for (let cd=1; cd<=5; cd++) console.log(`  OK-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new), new ext: ${newRows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1238_..., migrations/1239_..., data/seed-ok-2026-house/164-05-ok-reconciliation.csv');
