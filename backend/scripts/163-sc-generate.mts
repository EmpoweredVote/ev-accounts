import { writeFileSync, mkdirSync } from 'fs';

// ---- SC field (validated against 160-field-table-p163.csv SC rows; sources = Wikipedia
//      2026 US House elections in South Carolina page, per-district sections) ----
// Phase 163-05 Task 2: SC end-to-end seed (vanilla new-election, 1-election). SC is NOT
//   redistricted -> no withholding. Primaries DECIDED -> NO PROVISIONAL prefix.
//   SC-1 Nancy Mace (running for Governor) + SC-5 Ralph Norman (running for Governor) both
//   RETIRED -> vacate:true (REUSE-NO-ROW): their politicians/offices rows stay untouched (they
//   remain sitting Reps until Jan 2027) but they are NOT wired into their district's race_candidates.
//   Jul-15 independent/petition window: execution date 2026-07-05 is BEFORE the 2026-07-15
//   filing deadline -> window still OPEN; seed the known decided field now, flag SC for a
//   Phase-167 re-pull (Pitfall 4). No new independents can exist yet.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-45001,2:-45002,3:-45003,4:-45004,5:-45005,6:-45006,7:-45007};

const FIELD: Cand[] = [
  // SC-1 (4501): Nancy Mace (R, inc) retired -> Governor; open seat, 4 new candidates
  { cd:1, name:'Nancy Mace', party:'Republican', role:'R', inc:true, vacate:true },
  { cd:1, name:'Jenny Costa Honeycutt', party:'Republican', role:'R' },
  { cd:1, name:'Nancy Lacore', party:'Democratic', role:'D' },
  { cd:1, name:'Bill Reeside', party:'Libertarian', role:'L' },
  { cd:1, name:'Margo Ellis', party:'Alliance', role:'Alliance' },
  // SC-2 (4502): Joe Wilson renominated
  { cd:2, name:'Joe Wilson', party:'Republican', role:'R', inc:true },
  { cd:2, name:'Zyon Khalifa', party:'Democratic', role:'D' },
  { cd:2, name:'Dayna Alane Smith', party:'Workers', role:'Workers' },
  // SC-3 (4503): Sheri Biggs renominated
  { cd:3, name:'Sheri Biggs', party:'Republican', role:'R', inc:true },
  { cd:3, name:'Eunice Lehmacher', party:'Democratic', role:'D' },
  { cd:3, name:'Brian Corriea', party:'Libertarian', role:'L' },
  // SC-4 (4504): William R. Timmons IV renominated
  { cd:4, name:'William R. Timmons IV', party:'Republican', role:'R', inc:true },
  { cd:4, name:'Courtney McClain', party:'Democratic', role:'D' },
  { cd:4, name:'Jessica Ethridge', party:'Libertarian', role:'L' },
  // SC-5 (4505): Ralph Norman (R, inc) retired -> Governor; open seat, 3 new candidates
  { cd:5, name:'Ralph Norman', party:'Republican', role:'R', inc:true, vacate:true },
  { cd:5, name:'Wes Climer', party:'Republican', role:'R' },
  { cd:5, name:'Mallory Dittmer', party:'Democratic', role:'D' },
  { cd:5, name:'Andy Kaplan', party:'Forward', role:'Forward' },
  // SC-6 (4506): James E. Clyburn renominated
  { cd:6, name:'James E. Clyburn', party:'Democratic', role:'D', inc:true },
  { cd:6, name:'John Peterson', party:'Republican', role:'R' },
  { cd:6, name:'Joseph Oddo', party:'Alliance', role:'Alliance' },
  // SC-7 (4507): Russell Fry renominated
  { cd:7, name:'Russell Fry', party:'Republican', role:'R', inc:true },
  { cd:7, name:'John Vincent', party:'Democratic', role:'D' },
];

const SRC_MAJOR = '160-field-table-p163.csv (SC rows), sourced from Wikipedia 2026 US House elections in South Carolina; decided general field';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// SC fips = 45; formula: -(45 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 163-05 Task 1): 0 collisions confirmed against prod for
// the -450101..-450799 band before authoring. Incumbents reuse -45001..-45007.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '45' + String(c.cd).padStart(2, '0');
  const source = SRC_MAJOR;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(45 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (163-05-sc-reconciliation.csv) ----
mkdirSync('data/seed-sc-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const notes = '# Jul-15 independent window: execution 2026-07-05 is BEFORE the 2026-07-15 filing deadline -> window OPEN; seeded known decided field, SC flagged for Phase-167 re-pull. No new independents possible yet.';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-sc-2026-house/163-05-sc-reconciliation.csv', [notes, header, ...csvLines].join('\n') + '\n');

// ---- Migration 1224: election + 7 races ----
const mElections = `-- 1224_seed_sc_2026_house_elections_races.sql
-- Phase 163-05 Task 2: SC 2026 Statewide General election + 7 U.S. House races.
-- Field source: 160-field-table-p163.csv (SC rows), from Wikipedia 2026 US House elections in
--   South Carolina. SC is NOT redistricted -> no withholding (vanilla new-election). Primaries
--   DECIDED -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. SC-1 (Mace) + SC-5 (Norman) both retired to
--   run for Governor but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'SC 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'SC'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'SC 2026 Statewide General');

-- 7 races on the EXISTING SC NATIONAL_LOWER US Rep offices (geo 4501..4507)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominees (SC primary decided)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '45'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'SC 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1224_seed_sc_2026_house_elections_races.sql', mElections);

// ---- Migration 1225: 16 new politicians + race_candidates ----
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
WHERE el.name = 'SC 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1225_seed_sc_2026_house_candidates.sql
-- Phase 163-05 Task 2: ${newRows.length} new SC politicians + ${activeRows.length} active race_candidates
--   onto the 7 SC 2026 Statewide General races. Reuse 5 renominated incumbents by external_id;
--   SC-1 Nancy Mace (-45001) + SC-5 Ralph Norman (-45005) retired to run for Governor -> NO active
--   rows (open-seat convention, mirrors WI-7 Tiffany / CO-1 DeGette) -- they remain sitting Reps
--   until Jan 2027 (politicians/offices rows untouched) but are not 2026 general-election candidates.
--   ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv SC rows, from Wikipedia 2026 US House elections in South Carolina.
BEGIN;

-- ${newRows.length} new challenger records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (5 incumbents reused + ${newRows.length} new; Mace + Norman excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1225_seed_sc_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=7; cd++) console.log(`  SC-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new)`);
console.log('\nWrote: migrations/1224_..., migrations/1225_..., data/seed-sc-2026-house/163-05-sc-reconciliation.csv');
