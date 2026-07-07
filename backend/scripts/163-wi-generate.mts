import { writeFileSync, mkdirSync } from 'fs';

// ---- WI field (validated against 160-field-table-p163.csv WI rows; sources = Wikipedia
//      2026 US House elections in Wisconsin page + local news (postcrescent.com, wxow.com)) ----
// Phase 163-02 Task 2: WI end-to-end seed (vanilla new-election, 1-election). WI is NOT
//   redistricted -> no withholding. Late-primary (Aug-11) -> full field is PROVISIONAL,
//   cull >= 2026-08-12. Tiffany WI-7 (R) retired to run for Governor -> REUSE-NO-ROW (open seat).
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-55001,2:-55002,3:-55003,4:-55004,5:-55005,6:-55006,7:-55007,8:-55008};

const FIELD: Cand[] = [
  // WI-1 (5501): Bryan Steil renominated
  { cd:1, name:'Bryan Steil', party:'Republican', role:'R', inc:true },
  { cd:1, name:'Miguel Aranda', party:'Democratic', role:'D' },
  { cd:1, name:'Mitchell Berman', party:'Democratic', role:'D' },
  { cd:1, name:'Peter Burgelis', party:'Democratic', role:'D' },
  { cd:1, name:'Lorenzo Santos', party:'Democratic', role:'D' },
  // WI-2 (5502): Mark Pocan renominated; NO Republican filed (verified, not an error)
  { cd:2, name:'Mark Pocan', party:'Democratic', role:'D', inc:true },
  { cd:2, name:'Douglas Alexander', party:'Democratic', role:'D' },
  // WI-3 (5503): Derrick Van Orden renominated
  { cd:3, name:'Derrick Van Orden', party:'Republican', role:'R', inc:true },
  { cd:3, name:'Emily Berge', party:'Democratic', role:'D' },
  { cd:3, name:'Rebecca Cooke', party:'Democratic', role:'D' },
  { cd:3, name:'Rustin Provance', party:'Independent', role:'IND' },
  // WI-4 (5504): Gwen Moore renominated
  { cd:4, name:'Gwen Moore', party:'Democratic', role:'D', inc:true },
  { cd:4, name:'Amy Donahue', party:'Democratic', role:'D' },
  { cd:4, name:'Purnima Nath', party:'Republican', role:'R' },
  { cd:4, name:'Tim Rogers', party:'Republican', role:'R' },
  { cd:4, name:'Arthur Burks', party:'Independent', role:'IND' },
  // WI-5 (5505): Scott Fitzgerald renominated
  { cd:5, name:'Scott Fitzgerald', party:'Republican', role:'R', inc:true },
  { cd:5, name:'Andrew Beck', party:'Democratic', role:'D' },
  // WI-6 (5506): Glenn Grothman renominated
  { cd:6, name:'Glenn Grothman', party:'Republican', role:'R', inc:true },
  { cd:6, name:'Amanda Bell', party:'Democratic', role:'D' },
  { cd:6, name:'Brad Smith', party:'Democratic', role:'D' },
  { cd:6, name:'Matthew Arndt', party:'Green', role:'G' },
  { cd:6, name:'Elizabeth Fitzgibbon', party:'Independent', role:'IND' },
  { cd:6, name:'Michael Thurow', party:'Independent', role:'IND' },
  // WI-7 (5507): Thomas P. Tiffany (R) retired to run for Governor -> REUSE-NO-ROW; open seat
  { cd:7, name:'Thomas P. Tiffany', party:'Republican', role:'R', inc:true, vacate:true },
  { cd:7, name:'Michael Alfonso', party:'Republican', role:'R' },
  { cd:7, name:'Niina Baum', party:'Republican', role:'R' },
  { cd:7, name:'Jessi Ebben', party:'Republican', role:'R' },
  { cd:7, name:'Kevin Hermening', party:'Republican', role:'R' },
  { cd:7, name:'Chris Armstrong', party:'Democratic', role:'D' },
  { cd:7, name:'Fred Clark', party:'Democratic', role:'D' },
  { cd:7, name:'Ginger Murray', party:'Democratic', role:'D' },
  // WI-8 (5508): Tony Wied renominated
  { cd:8, name:'Tony Wied', party:'Republican', role:'R', inc:true },
  { cd:8, name:'Rick Crosson', party:'Democratic', role:'D' },
  { cd:8, name:'Katrina deVille', party:'Democratic', role:'D' },
  { cd:8, name:'Mark Scheffler', party:'Democratic', role:'D' },
];

const SRC_MAJOR = '160-field-table-p163.csv (WI rows), sourced from Wikipedia 2026 US House elections in Wisconsin; provisional pre-primary field, cull >= 2026-08-12';
const SRC_OTHER = '160-field-table-p163.csv (WI rows), sourced from Wikipedia/local news (postcrescent.com, wxow.com) independent/minor-party filing; provisional pre-primary field, cull >= 2026-08-12';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// WI fips = 55; formula: -(55 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 163-02 Task 1): 0 collisions confirmed against prod for
// the -550101..-550899 band before authoring. Incumbents reuse -55001..-55008.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '55' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(55 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (163-02-wi-reconciliation.csv) ----
mkdirSync('data/seed-wi-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-wi-2026-house/163-02-wi-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration N: election + 8 races ----
const mElections = `-- 1220_seed_wi_2026_house_elections_races.sql
-- Phase 163-02 Task 2: WI 2026 Statewide General election + 8 provisional U.S. House races.
-- Field source: 160-field-table-p163.csv (WI rows), from Wikipedia 2026 US House elections in
--   Wisconsin + local news. WI is NOT redistricted -> no withholding (vanilla new-election).
--   Late primary (Aug-11) -> provisional pre-primary field, culled >= 2026-08-12. ANTIPARTISAN
--   INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL.
--   WI-7 (Tiffany) is an open seat (ran for Governor) but its district office already exists --
--   NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WI 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WI 2026 Statewide General');

-- 8 provisional races on the EXISTING WI NATIONAL_LOWER US Rep offices (geo 5501..5508)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '55'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'WI 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1220_seed_wi_2026_house_elections_races.sql', mElections);

// ---- Migration N1: 28 new politicians + race_candidates ----
const newRows = rows.filter(r => r.decision === 'NEW');
const activeRows = rows.filter(r => r.decision === 'NEW' || r.decision === 'REUSE'); // excludes REUSE-NO-ROW

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
WHERE el.name = 'WI 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1221_seed_wi_2026_house_candidates.sql
-- Phase 163-02 Task 2: ${newRows.length} new WI politicians + ${activeRows.length} active race_candidates
--   onto the 8 WI 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   WI-7 Thomas P. Tiffany (-55007) ran for Governor -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5, MN-2 Craig). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv WI rows, from Wikipedia 2026 US House elections in Wisconsin
--   + local news (postcrescent.com, wxow.com). WI-2 legitimately has only 2 all-D candidates
--   (Pocan + Alexander) -- no Republican filed, verified, not an error.
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; Tiffany excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1221_seed_wi_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=8; cd++) console.log(`  WI-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new)`);
console.log('\nWrote: migrations/1220_..., migrations/1221_..., data/seed-wi-2026-house/163-02-wi-reconciliation.csv');
