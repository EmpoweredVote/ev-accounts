import { writeFileSync, mkdirSync } from 'fs';

// ---- WA field (validated against 160-field-table-p161.csv WA rows) ----
// Phase 161-04 Task 1: WA end-to-end seed. WA is top-two ballot_system but is seeded EXACTLY like
// any late-primary state: one race per district, ALL qualified candidates from all parties active
// (do NOT invent WA-specific top-two logic here -- 161-RESEARCH Pitfall 4; the top-two cull is
// Phase 167's concern). WA-4 Dan Newhouse RETIRED -> REUSE-NO-ROW, full qualified field is all-new.
type Cand = { cd: number; name: string; party: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-53001,2:-53002,3:-53003,4:-53004,5:-53005,6:-53006,7:-53007,8:-53008,9:-53009,10:-53010};

const FIELD: Cand[] = [
  // WA-1: Suzan K. DelBene renominated
  { cd:1, name:'Suzan K. DelBene', party:'Democratic', inc:true },
  { cd:1, name:'Benjamin Kincaid', party:'Democratic' },
  { cd:1, name:'Bryce Nickel', party:'Democratic' },
  { cd:1, name:'James Etzkorn', party:'Independent' },
  { cd:1, name:'Hunter Gordon', party:'Democratic' },
  { cd:1, name:'Mary Silva', party:'Republican' },
  { cd:1, name:'Catherine Hildebrand', party:'Democratic' },
  // WA-2: Rick Larsen renominated
  { cd:2, name:'Rick Larsen', party:'Democratic', inc:true },
  { cd:2, name:'Edwin H. Feller', party:'Republican' },
  { cd:2, name:'Tomas Scheel', party:'Democratic' },
  { cd:2, name:'Devin Hermanson', party:'Democratic' },
  // WA-3: Marie Gluesenkamp Perez renominated
  { cd:3, name:'Marie Gluesenkamp Perez', party:'Democratic', inc:true },
  { cd:3, name:'Brent Hennrich', party:'Democratic' },
  { cd:3, name:'John P. Roco', party:'Republican' },
  { cd:3, name:'John Saulie-Rohman', party:'Independent' },
  { cd:3, name:'Troy Rasband', party:'Democratic' },
  { cd:3, name:'John Braun', party:'Republican' },
  { cd:3, name:'Antony Barran', party:'Cascade' },
  { cd:3, name:'Austin Braswell', party:'Democratic' },
  { cd:3, name:'Lawrence Kellogg', party:'Republican' },
  // WA-4: Dan Newhouse RETIRED -> REUSE-NO-ROW; full qualified field is all-new
  { cd:4, name:'Dan Newhouse', party:'Republican', inc:true, vacate:true },
  { cd:4, name:'Jacek "Jack" Kobiesa', party:'States No Party Preference' },
  { cd:4, name:'Amanda McKinney', party:'Republican' },
  { cd:4, name:'John Duresky', party:'Democratic' },
  { cd:4, name:'John C. Hughs', party:'Republican' },
  { cd:4, name:'Favian Valencia', party:'Independent' },
  { cd:4, name:'Jerrod Sessler', party:'Republican' },
  { cd:4, name:'Devin Poore', party:'Cascade' },
  { cd:4, name:'Ken Vaz', party:'Republican' },
  { cd:4, name:'Zac Rossi', party:'States No Party Preference' },
  { cd:4, name:'Elpidia Saavedra', party:'Republican' },
  { cd:4, name:'Matt Boehnke', party:'Republican' },
  // WA-5: Michael Baumgartner renominated
  { cd:5, name:'Michael Baumgartner', party:'Republican', inc:true },
  { cd:5, name:'Nate Powell', party:'Independent' },
  { cd:5, name:'Carmela Conroy', party:'Democratic' },
  { cd:5, name:'Matthew Hayes', party:'Independent' },
  { cd:5, name:'Bajun R. Mavalwalla', party:'Democratic' },
  { cd:5, name:'Michael McGarr', party:'Democratic' },
  { cd:5, name:'Kevin Fagan', party:'Democratic' },
  { cd:5, name:'Kyle Usrey', party:'Independent' },
  { cd:5, name:'Andrew Bartleson', party:'Independent' },
  { cd:5, name:'Ann Marie Danimus', party:'Independent' },
  { cd:5, name:'Richard Freudenberg', party:'Democratic' },
  { cd:5, name:'David Womack', party:'Democratic' },
  // WA-6: Emily Randall renominated
  { cd:6, name:'Emily Randall', party:'Democratic', inc:true },
  { cd:6, name:"Brian P. O'Gorman", party:'Independent' },
  { cd:6, name:'Teresa Fox', party:'Republican' },
  { cd:6, name:'Macy Jones', party:'States No Party Preference' },
  { cd:6, name:'Leon Lawson', party:'Trump Republican' },
  // WA-7: Pramila Jayapal renominated
  { cd:7, name:'Pramila Jayapal', party:'Democratic', inc:true },
  { cd:7, name:'David W. Blomstrom', party:'Fifth Republic' },
  { cd:7, name:'Nirav Sheth', party:'Republican' },
  { cd:7, name:'Gwen Kirkland', party:'Democratic' },
  // WA-8: Kim Schrier renominated
  { cd:8, name:'Kim Schrier', party:'Democratic', inc:true },
  { cd:8, name:'Trinh Ha', party:'Republican' },
  { cd:8, name:'Spencer Meline', party:'Republican' },
  { cd:8, name:'Keith Arnold', party:'Democratic' },
  { cd:8, name:'Andres Valleza', party:'Republican' },
  { cd:8, name:'Bob Hagglund', party:'Republican' },
  // WA-9: Adam Smith renominated
  { cd:9, name:'Adam Smith', party:'Democratic', inc:true },
  { cd:9, name:'Jacob Perasso', party:'Socialist Workers' },
  { cd:9, name:'Kshama Sawant', party:'Independent' },
  { cd:9, name:'Melissa Chaudhry', party:'Democratic' },
  { cd:9, name:'Doug Basler', party:'Republican' },
  // WA-10: Marilyn Strickland renominated
  { cd:10, name:'Marilyn Strickland', party:'Democratic', inc:true },
  { cd:10, name:'Adam Arafat', party:'Democratic' },
  { cd:10, name:'Kurtis Engle', party:'Union' },
  { cd:10, name:'Alex Scheel', party:'Democratic' },
  { cd:10, name:'Derek Maynes', party:'States No Party Preference' },
  { cd:10, name:'Chris D. Chung', party:'Republican' },
];

const SRC_MAJOR = 'Wikipedia 2026 WA US House elections (qualified pre-primary field), cross-checked VoteWA CandidateList';
const SRC_OTHER = 'Declared indep/minor-party (VoteWA CandidateList/Wikipedia); provisional -- pre-primary field, cull >= 2026-08-05';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// WA fips = 53; formula: -(53 * 10000 + cd * 100 + seq), seq starts at 1 per CD.
// Live collision re-check (Phase 161-04 Task 1, per 160-negative-id-audit.csv absence + re-verify
// discipline): re-checked against prod for the full computed band before authoring migration SQL.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '53' + String(c.cd).padStart(2, '0');
  const source = c.party === 'Democratic' || c.party === 'Republican' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(53 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (161-04-wa-reconciliation.csv) ----
mkdirSync('data/seed-wa-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, `"${r.party}"`, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-wa-2026-house/161-04-wa-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1189: election + 10 races ----
const m1189 = `-- 1189_seed_wa_2026_house_elections_races.sql
-- Phase 161-04 Task 1: WA 2026 Statewide General election + 10 provisional U.S. House races.
-- Field source: 160-field-table-p161.csv (WA rows). WA is ballot_system=top-two but is seeded
--   EXACTLY like any other late-primary state: one race per district, all qualified candidates
--   from all parties active (top-two cull is Phase 167's concern, NOT this migration's). Provisional
--   pre-primary field, culled >= 2026-08-05 (day after WA's Aug-4 top-two primary). ANTIPARTISAN
--   INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays NULL. WA-4
--   (Dan Newhouse) is a RETIRED open seat but its district office already exists -- NO
--   office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'WA 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'WA'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'WA 2026 Statewide General');

-- 10 provisional races on the EXISTING WA NATIONAL_LOWER US Rep offices (geo 5301..5310)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '53'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'WA 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1189_seed_wa_2026_house_elections_races.sql', m1189);

// ---- Migration 1190: ~60 new politicians + race_candidates ----
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
WHERE el.name = 'WA 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const m1190 = `-- 1190_seed_wa_2026_house_candidates.sql
-- Phase 161-04 Task 2: ${newRows.length} new WA politicians + ${activeRows.length} active race_candidates
--   onto the 10 WA 2026 Statewide General races. Reuse 9 renominated incumbents by external_id;
--   WA-4 Dan Newhouse (-53004) RETIRED -> NO active row (open-seat convention, mirrors
--   AZ-1/AZ-5 from Phase 161-02 and MI-10/MI-11 from Phase 159). ANTIPARTISAN: party never
--   stored; races untouched. Field: 160-field-table-p161.csv WA rows.
BEGIN;

-- ${newRows.length} new challenger/open-seat/indep/minor-party records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (9 incumbents reused + ${newRows.length} new; Newhouse excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1190_seed_wa_2026_house_candidates.sql', m1190);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=10; cd++) console.log(`  WA-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active`);
console.log('\nWrote: migrations/1189_..., migrations/1190_..., data/seed-wa-2026-house/161-04-wa-reconciliation.csv');
