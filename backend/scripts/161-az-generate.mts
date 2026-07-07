import { writeFileSync, mkdirSync } from 'fs';

// ---- AZ field (validated against 160-field-table-p161.csv AZ rows, cross-checked
//      Wikipedia "2026 United States House of Representatives elections in Arizona") ----
// Phase 161-02 Task 1: AZ end-to-end seed (D-02 hard target: live before Jul-21 primary).
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-4001,2:-4002,3:-4003,4:-4004,5:-4005,6:-4006,7:-4007,8:-4008,9:-4009};

const FIELD: Cand[] = [
  // AZ-1: David Schweikert RETIRED -> REUSE-NO-ROW; full qualified field is all-new
  { cd:1, name:'David Schweikert', party:'R', role:'R', inc:true, vacate:true },
  { cd:1, name:'Joseph Chaplik', party:'R', role:'R' },
  { cd:1, name:'Jay Feely', party:'R', role:'R' },
  { cd:1, name:'John Trobough', party:'R', role:'R' },
  { cd:1, name:'Marlene Galán-Woods', party:'D', role:'D' },
  { cd:1, name:'Rick McCartney', party:'D', role:'D' },
  { cd:1, name:'Amish Shah', party:'D', role:'D' },
  { cd:1, name:'Jonathan Treble', party:'D', role:'D' },
  { cd:1, name:'Christopher Ajluni', party:'IND', role:'IND' },
  { cd:1, name:'Monica Alponte', party:'L', role:'L' },
  { cd:1, name:'David Redkey', party:'G', role:'G' },
  // AZ-2: Elijah Crane renominated
  { cd:2, name:'Elijah Crane', party:'R', role:'R', inc:true },
  { cd:2, name:'Eric Descheenie', party:'D', role:'D' },
  { cd:2, name:'Jonathan Nez', party:'D', role:'D' },
  { cd:2, name:'Curtis Goodwin', party:'L', role:'L' },
  // AZ-3: Yassamin Ansari renominated
  { cd:3, name:'Yassamin Ansari', party:'D', role:'D', inc:true },
  { cd:3, name:'Alan Aversa', party:'IND', role:'IND' },
  // AZ-4: Greg Stanton renominated
  { cd:4, name:'Greg Stanton', party:'D', role:'D', inc:true },
  { cd:4, name:'Kai Newkirk', party:'D', role:'D' },
  { cd:4, name:'Jerone Davison', party:'R', role:'R' },
  { cd:4, name:'Zuhdi Jasser', party:'R', role:'R' },
  { cd:4, name:'Tisha Benoit', party:'IND', role:'IND' },
  { cd:4, name:'John Fillmore', party:'IND', role:'IND' },
  // AZ-5: Andy Biggs RETIRED -> REUSE-NO-ROW; full qualified field is all-new
  { cd:5, name:'Andy Biggs', party:'R', role:'R', inc:true, vacate:true },
  { cd:5, name:'Mark Lamb', party:'R', role:'R' },
  { cd:5, name:'Daniel Keenan', party:'R', role:'R' },
  { cd:5, name:'Blake Bracht', party:'D', role:'D' },
  { cd:5, name:'Brian Hualde', party:'D', role:'D' },
  { cd:5, name:'Chris James', party:'D', role:'D' },
  { cd:5, name:'Elizabeth Lee', party:'D', role:'D' },
  // AZ-6: Juan Ciscomani renominated
  { cd:6, name:'Juan Ciscomani', party:'R', role:'R', inc:true },
  { cd:6, name:'JoAnna Mendoza', party:'D', role:'D' },
  { cd:6, name:'Iman Bah', party:'IND', role:'IND' },
  { cd:6, name:'Jereme Peters', party:'L', role:'L' },
  // AZ-7: Adelita Grijalva renominated
  { cd:7, name:'Adelita S. Grijalva', party:'D', role:'D', inc:true },
  { cd:7, name:'Daniel Butierez', party:'R', role:'R' },
  // AZ-8: Abraham Hamadeh renominated
  { cd:8, name:'Abraham J. Hamadeh', party:'R', role:'R', inc:true },
  { cd:8, name:'Bernadette Greene-Placentia', party:'D', role:'D' },
  { cd:8, name:'Raymond Keeler', party:'D', role:'D' },
  // AZ-9: Paul Gosar renominated
  { cd:9, name:'Paul A. Gosar', party:'R', role:'R', inc:true },
  { cd:9, name:'Danielle Sterbinsky', party:'D', role:'D' },
];

const SRC_MAJOR = 'Wikipedia 2026 AZ US House elections (qualified pre-primary field), cross-checked Ballotpedia';
const SRC_OTHER = 'Declared indep/L/G (Wikipedia/Ballotpedia); provisional — pre-primary field, cull >= 2026-07-22';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// AZ fips = 04; formula: -(4 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 161-02 Task 1, per 160-negative-id-audit.csv absence + re-verify
// discipline): 0 collisions confirmed against prod for the full -40101..-40901 band before authoring.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '04' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(4 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (161-02-az-reconciliation.csv) ----
mkdirSync('data/seed-az-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-az-2026-house/161-02-az-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1187: election + 9 races ----
const m1187 = `-- 1187_seed_az_2026_house_elections_races.sql
-- Phase 161-02 Task 1: AZ 2026 Statewide General election + 9 provisional U.S. House races.
-- Field source: 160-field-table-p161.csv (AZ rows), cross-checked Wikipedia "2026 United States
--   House of Representatives elections in Arizona" (per-district pages). Provisional pre-primary
--   field (FL-151 D-04 pattern), culled >= 2026-07-22 (day after AZ's Jul-21 primary). D-02 hard
--   target: AZ live before its primary. ANTIPARTISAN INVARIANT: party is NEVER stored on
--   race_candidates; races.primary_party stays NULL. AZ-1 (Schweikert) and AZ-5 (Biggs) are
--   RETIRED open seats but their district offices already exist -- NO office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AZ 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AZ'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AZ 2026 Statewide General');

-- 9 provisional races on the EXISTING AZ NATIONAL_LOWER US Rep offices (geo 0401..0409)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-07-22'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '04'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'AZ 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1187_seed_az_2026_house_elections_races.sql', m1187);

// ---- Migration 1188: 32 new politicians + race_candidates ----
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
WHERE el.name = 'AZ 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const m1188 = `-- 1188_seed_az_2026_house_candidates.sql
-- Phase 161-02 Task 2: ${newRows.length} new AZ politicians + ${activeRows.length} active race_candidates
--   onto the 9 AZ 2026 Statewide General races. Reuse 7 renominated incumbents by external_id;
--   AZ-1 David Schweikert (-4001) + AZ-5 Andy Biggs (-4005) RETIRED -> NO active row (open-seat
--   convention, mirrors MI-10/MI-11). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p161.csv AZ rows, cross-checked Wikipedia per-district AZ House pages.
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep/L/G records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (7 incumbents reused + ${newRows.length} new; Schweikert/Biggs excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1188_seed_az_2026_house_candidates.sql', m1188);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=9; cd++) console.log(`  AZ-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active`);
console.log('\nWrote: migrations/1187_..., migrations/1188_..., data/seed-az-2026-house/161-02-az-reconciliation.csv');
