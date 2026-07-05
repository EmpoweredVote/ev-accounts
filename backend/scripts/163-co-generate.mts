import { writeFileSync, mkdirSync } from 'fs';

// ---- CO field (validated against 160-field-table-p163.csv CO rows; sources = Wikipedia
//      2026 US House elections in Colorado page, per-district sections) ----
// Phase 163-03 Task 2: CO end-to-end seed (vanilla new-election, 1-election). CO is NOT
//   redistricted -> no withholding. Primaries DECIDED 2026-06-30 -> NO PROVISIONAL prefix.
//   CO-1 Diana DeGette (D) LOST her June-30 primary to Melat Kiros -> a NEW transition pattern
//   ("incumbent-lost-primary, stays incumbent-only, does not appear on the new race"): DeGette's
//   existing politicians/offices rows + 19 stances stay COMPLETELY UNTOUCHED (vacate:true, same
//   REUSE-NO-ROW mechanic as a retirement), but she is NOT wired into CO-1's race_candidates.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-8001,2:-8002,3:-8003,4:-8004,5:-8005,6:-8006,7:-8007,8:-8008};

const FIELD: Cand[] = [
  // CO-1 (0801): Diana DeGette (D, inc) LOST her primary to Melat Kiros -> vacate:true (REUSE-NO-ROW).
  //   CO-1's general field is ONLY Kiros (D) + Peterson (R) -- DeGette excluded entirely.
  { cd:1, name:'Diana DeGette', party:'Democratic', role:'D', inc:true, vacate:true },
  { cd:1, name:'Melat Kiros', party:'Democratic', role:'D' },
  { cd:1, name:'Christy Peterson', party:'Republican', role:'R' },
  // CO-2 (0802): Joe Neguse renominated
  { cd:2, name:'Joe Neguse', party:'Democratic', role:'D', inc:true },
  { cd:2, name:'Kelley Dennison', party:'Republican', role:'R' },
  // CO-3 (0803): Jeff Hurd renominated
  { cd:3, name:'Jeff Hurd', party:'Republican', role:'R', inc:true },
  { cd:3, name:'Dwayne Romero', party:'Democratic', role:'D' },
  // CO-4 (0804): Lauren Boebert renominated
  { cd:4, name:'Lauren Boebert', party:'Republican', role:'R', inc:true },
  { cd:4, name:'Eileen Laubacher', party:'Democratic', role:'D' },
  // CO-5 (0805): Jeff Crank renominated
  { cd:5, name:'Jeff Crank', party:'Republican', role:'R', inc:true },
  { cd:5, name:'Jessica Killin', party:'Democratic', role:'D' },
  // CO-6 (0806): Jason Crow renominated
  { cd:6, name:'Jason Crow', party:'Democratic', role:'D', inc:true },
  { cd:6, name:'Jason Clark', party:'Republican', role:'R' },
  // CO-7 (0807): Brittany Pettersen renominated
  { cd:7, name:'Brittany Pettersen', party:'Democratic', role:'D', inc:true },
  { cd:7, name:'Tim Bennett', party:'Republican', role:'R' },
  // CO-8 (0808): Gabe Evans renominated
  { cd:8, name:'Gabe Evans', party:'Republican', role:'R', inc:true },
  { cd:8, name:'Manny Rutinel', party:'Democratic', role:'D' },
];

const SRC_MAJOR = '160-field-table-p163.csv (CO rows), sourced from Wikipedia 2026 US House elections in Colorado; decided general field (primaries held 2026-06-30)';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// CO fips = 08; formula: -(8 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 163-03 Task 1): 0 collisions confirmed against prod for
// the -80101..-80899 band before authoring. Incumbents reuse -8001..-8008.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '08' + String(c.cd).padStart(2, '0');
  const source = SRC_MAJOR;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(8 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (163-03-co-reconciliation.csv) ----
mkdirSync('data/seed-co-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-co-2026-house/163-03-co-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration N: election + 8 races ----
const mElections = `-- 1222_seed_co_2026_house_elections_races.sql
-- Phase 163-03 Task 2: CO 2026 Statewide General election + 8 U.S. House races.
-- Field source: 160-field-table-p163.csv (CO rows), from Wikipedia 2026 US House elections in
--   Colorado. CO is NOT redistricted -> no withholding (vanilla new-election). Primaries DECIDED
--   2026-06-30 -> NOT PROVISIONAL-marked. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. CO-1 (Diana DeGette) LOST her primary to
--   Melat Kiros but the district office already exists -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'CO 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'CO'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'CO 2026 Statewide General');

-- 8 races on the EXISTING CO NATIONAL_LOWER US Rep offices (geo 0801..0808)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed nominees (primary decided 2026-06-30)'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '08'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'CO 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1222_seed_co_2026_house_elections_races.sql', mElections);

// ---- Migration N1: 9 new politicians + race_candidates ----
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
WHERE el.name = 'CO 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1223_seed_co_2026_house_candidates.sql
-- Phase 163-03 Task 2: ${newRows.length} new CO politicians + ${activeRows.length} active race_candidates
--   onto the 8 CO 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   CO-1 Diana DeGette (-8001) LOST her June-30 primary to Melat Kiros -> NO active row
--   (open-seat convention, mirrors AZ-1/AZ-5, MN-2 Craig, WI-7 Tiffany) -- she remains the sitting
--   Rep until Jan 2027 (politicians/offices rows + 19 stances untouched) but is not a CO-1
--   general-election candidate. ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p163.csv CO rows, from Wikipedia 2026 US House elections in Colorado.
BEGIN;

-- ${newRows.length} new challenger records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; DeGette excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1223_seed_co_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=8; cd++) console.log(`  CO-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new)`);
console.log('\nWrote: migrations/1222_..., migrations/1223_..., data/seed-co-2026-house/163-03-co-reconciliation.csv');
