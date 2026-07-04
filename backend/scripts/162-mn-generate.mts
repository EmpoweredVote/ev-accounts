import { writeFileSync, mkdirSync } from 'fs';

// ---- MN field (validated against 160-field-table-p162.csv MN rows; source =
//      candidates.sos.mn.gov CandidateFilingResults 2026 federal filings) ----
// Phase 162-05 Task 2: MN end-to-end seed (vanilla new-election, 1-election). MN is NOT
//   redistricted -> no withholding. Late-primary (Aug-11) -> full field is PROVISIONAL,
//   cull >= 2026-08-12. Craig MN-2 (DFL) filed for US Senate -> REUSE-NO-ROW (open seat).
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-27001,2:-27002,3:-27003,4:-27004,5:-27005,6:-27006,7:-27007,8:-27008};

const FIELD: Cand[] = [
  // MN-1 (2701): Brad Finstad renominated
  { cd:1, name:'Brad Finstad', party:'R', role:'R', inc:true },
  { cd:1, name:'Gregory A. Goetzman', party:'R', role:'R' },
  { cd:1, name:'Oliver R. Morlan', party:'R', role:'R' },
  { cd:1, name:'Alex Eaton', party:'DFL', role:'D' },
  { cd:1, name:'Jake Johnson', party:'DFL', role:'D' },
  // MN-2 (2702): Angie Craig ran for US Senate -> REUSE-NO-ROW; full field all-new
  { cd:2, name:'Angie Craig', party:'DFL', role:'D', inc:true, vacate:true },
  { cd:2, name:'Eric Pratt', party:'R', role:'R' },
  { cd:2, name:'Abdi Abdulle', party:'DFL', role:'D' },
  { cd:2, name:'Kaela Berg', party:'DFL', role:'D' },
  { cd:2, name:'Matthew D. Klein', party:'DFL', role:'D' },
  { cd:2, name:'Matt Little', party:'DFL', role:'D' },
  { cd:2, name:'Hugh McTavish', party:'DFL', role:'D' },
  { cd:2, name:'Christopher Mosel', party:'DFL', role:'D' },
  // MN-3 (2703): Kelly Morrison renominated
  { cd:3, name:'Kelly Morrison', party:'DFL', role:'D', inc:true },
  { cd:3, name:'Tyler Bass', party:'R', role:'R' },
  { cd:3, name:'Quentin Wittrock', party:'R', role:'R' },
  // MN-4 (2704): Betty McCollum renominated
  { cd:4, name:'Betty McCollum', party:'DFL', role:'D', inc:true },
  { cd:4, name:'Gene Rechtzigel', party:'R', role:'R' },
  { cd:4, name:'Paul Wikstrom', party:'R', role:'R' },
  { cd:4, name:'Paul Xiong', party:'R', role:'R' },
  { cd:4, name:'Aswar Rahman', party:'DFL', role:'D' },
  // MN-5 (2705): Ilhan Omar renominated (largest MN field)
  { cd:5, name:'Ilhan Omar', party:'DFL', role:'D', inc:true },
  { cd:5, name:'DeVelle L. Jackson', party:'Independent', role:'IND' },
  { cd:5, name:'Dalia Al-Aqidi', party:'R', role:'R' },
  { cd:5, name:'John Nagel', party:'R', role:'R' },
  { cd:5, name:'Angie Windhauser', party:'R', role:'R' },
  { cd:5, name:'Abbey Zieska', party:'R', role:'R' },
  { cd:5, name:'Julie Trang Le', party:'DFL', role:'D' },
  { cd:5, name:'Abena A. McKenzie', party:'DFL', role:'D' },
  { cd:5, name:'Latonya T. Reeves', party:'DFL', role:'D' },
  { cd:5, name:'Nate Schluter', party:'DFL', role:'D' },
  // MN-6 (2706): Tom Emmer renominated
  { cd:6, name:'Tom Emmer', party:'R', role:'R', inc:true },
  { cd:6, name:'Chris Corey', party:'R', role:'R' },
  { cd:6, name:'Mike Foley', party:'R', role:'R' },
  { cd:6, name:'Doug Chapin', party:'DFL', role:'D' },
  // MN-7 (2707): Michelle Fischbach renominated
  { cd:7, name:'Michelle Fischbach', party:'R', role:'R', inc:true },
  { cd:7, name:'Steve Carlson', party:'DFL', role:'D' },
  { cd:7, name:'Erik Osberg', party:'DFL', role:'D' },
  // MN-8 (2708): Pete Stauber renominated
  { cd:8, name:'Pete Stauber', party:'R', role:'R', inc:true },
  { cd:8, name:'Anthony Hamilton', party:'R', role:'R' },
  { cd:8, name:'Luke Gulbranson', party:'DFL', role:'D' },
  { cd:8, name:'John Munter', party:'DFL', role:'D' },
  { cd:8, name:'Trina Swanson', party:'DFL', role:'D' },
];

const SRC_MAJOR = 'MN SoS candidate filing (candidates.sos.mn.gov, 2026 federal filings); provisional pre-primary field, cull >= 2026-08-12';
const SRC_OTHER = 'MN SoS candidate filing (candidates.sos.mn.gov, independent/minor-party filing); provisional pre-primary field, cull >= 2026-08-12';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// MN fips = 27; formula: -(27 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 162-05 Task 1): 0 collisions confirmed against prod for
// the -270101..-270899 band before authoring. Incumbents reuse -27001..-27008.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '27' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(27 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (162-05-mn-reconciliation.csv) ----
mkdirSync('data/seed-mn-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-mn-2026-house/162-05-mn-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration N: election + 8 races ----
const mElections = `-- 1210_seed_mn_2026_house_elections_races.sql
-- Phase 162-05 Task 2: MN 2026 Statewide General election + 8 provisional U.S. House races.
-- Field source: 160-field-table-p162.csv (MN rows), from candidates.sos.mn.gov 2026 federal
--   filings. MN is NOT redistricted -> no withholding (vanilla new-election). Late primary
--   (Aug-11) -> provisional pre-primary field, culled >= 2026-08-12. ANTIPARTISAN INVARIANT:
--   party is NEVER stored on race_candidates; races.primary_party stays NULL. MN-2 (Craig)
--   is an open seat (ran for US Senate) but its district office already exists -- NO office/
--   district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MN 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'MN'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MN 2026 Statewide General');

-- 8 provisional races on the EXISTING MN NATIONAL_LOWER US Rep offices (geo 2701..2708)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '27'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'MN 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1210_seed_mn_2026_house_elections_races.sql', mElections);

// ---- Migration N1: 35 new politicians + race_candidates ----
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
WHERE el.name = 'MN 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1211_seed_mn_2026_house_candidates.sql
-- Phase 162-05 Task 2: ${newRows.length} new MN politicians + ${activeRows.length} active race_candidates
--   onto the 8 MN 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   MN-2 Angie Craig (-27002) ran for US Senate -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p162.csv MN rows, from candidates.sos.mn.gov 2026 federal filings.
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; Craig excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1211_seed_mn_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=8; cd++) console.log(`  MN-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new)`);
console.log('\nWrote: migrations/1210_..., migrations/1211_..., data/seed-mn-2026-house/162-05-mn-reconciliation.csv');
