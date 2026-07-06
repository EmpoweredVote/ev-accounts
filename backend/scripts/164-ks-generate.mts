import { writeFileSync, mkdirSync } from 'fs';

// ---- KS field (validated against 160-field-table-p164.csv KS rows; source =
//      en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas
//      + KS SoS 2026 filings) ----
// Phase 164-01 Task 2: KS end-to-end seed (vanilla new-election, 1-election). KS is NOT
//   redistricted -> no withholding. Late-primary (Aug-4) -> full field is PROVISIONAL,
//   cull >= 2026-08-05. All 4 incumbents renominated -> reuse -20001..-20004 (is_incumbent).
//   COLLISION SUB-BANDS (D-04): the KS band -(20*10000+cd*100+seq) collides with 11 legacy
//   Massachusetts incumbents (-200101/-200102 senators, -200201..-200209 MA House). Live
//   re-check (164-01 Task 1) confirmed KS-1 seqs 1-2 + KS-2 seqs 1-9 occupied by those MA
//   records. So KS-1 seq starts at 3, KS-2 seq starts at 10; KS-3/KS-4 standard start 1.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean };
const INC_EXT: Record<number, number> = {1:-20001,2:-20002,3:-20003,4:-20004};
// D-04 per-district seq starts (KS-1=3, KS-2=10, KS-3=1, KS-4=1)
const SEQ_START: Record<number, number> = {1:3,2:10,3:1,4:1};

const FIELD: Cand[] = [
  // KS-1 (2001): Tracey Mann renominated
  { cd:1, name:'Tracey Mann', party:'Republican', role:'R', inc:true },
  { cd:1, name:'Colin McRoberts', party:'Democratic', role:'D' },
  { cd:1, name:'Lauren Reinhold', party:'Democratic', role:'D' },
  { cd:1, name:'Steven Jacob', party:'Libertarian', role:'LIB' },
  { cd:1, name:'Craig Musser', party:'United Kansas', role:'UK' },
  // KS-2 (2002): Derek Schmidt renominated
  { cd:2, name:'Derek Schmidt', party:'Republican', role:'R', inc:true },
  { cd:2, name:'Chad Young', party:'Republican', role:'R' },
  { cd:2, name:'Don Coover', party:'Democratic', role:'D' },
  { cd:2, name:'Braeden Curwick', party:'Democratic', role:'D' },
  // KS-3 (2003): Sharice Davids renominated
  { cd:3, name:'Sharice Davids', party:'Democratic', role:'D', inc:true },
  { cd:3, name:'Sarah Preu', party:'Democratic', role:'D' },
  { cd:3, name:'Eric Jenkins', party:'Republican', role:'R' },
  { cd:3, name:'Chase LaPorte', party:'Republican', role:'R' },
  { cd:3, name:'Gavin Solomon', party:'Republican', role:'R' },
  { cd:3, name:'Blake Stanley', party:'Republican', role:'R' },
  // KS-4 (2004): Ron Estes renominated (largest KS field, 10 new)
  { cd:4, name:'Ron Estes', party:'Republican', role:'R', inc:true },
  { cd:4, name:'Michael Gaynor', party:'Republican', role:'R' },
  { cd:4, name:'Frank McCollum', party:'Republican', role:'R' },
  { cd:4, name:'Chris Carmichael', party:'Democratic', role:'D' },
  { cd:4, name:'Katy Tyndell', party:'Democratic', role:'D' },
  { cd:4, name:'Cole Epley', party:'Democratic', role:'D' },
  { cd:4, name:'Ryan Gilbert', party:'Democratic', role:'D' },
  { cd:4, name:'Jordan Mitchell', party:'Democratic', role:'D' },
  { cd:4, name:'Daniel Schneider', party:'Democratic', role:'D' },
  { cd:4, name:'Drew Cranmer', party:'Libertarian', role:'LIB' },
  { cd:4, name:'Paul Catanese', party:'Independent', role:'IND' },
];

const SRC_MAJOR = 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; KS SoS 2026 federal filings); provisional pre-primary field, cull >= 2026-08-05';
const SRC_OTHER = 'KS 2026 US House field (en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kansas; minor-party/independent filing); provisional pre-primary field, cull >= 2026-08-05';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// KS fips = 20; formula: -(20 * 10000 + cd * 100 + seq). Per-CD seq start from SEQ_START
// (D-04 sub-bands). Live collision re-check (164-01 Task 1): the only in-band rows are the
// 11 legacy MA incumbents; KS-1 seq 3+, KS-2 seq 10+, KS-3/KS-4 all free. Incumbents reuse
// -20001..-20004.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '20' + String(c.cd).padStart(2, '0');
  const source = c.role === 'D' || c.role === 'R' ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
    const ext = -(20 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (164-01-ks-reconciliation.csv) ----
mkdirSync('data/seed-ks-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
writeFileSync('data/seed-ks-2026-house/164-01-ks-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1231: election + 4 races ----
const mElections = `-- 1231_seed_ks_2026_house_elections_races.sql
-- Phase 164-01 Task 2: KS 2026 Statewide General election + 4 provisional U.S. House races.
-- Field source: 160-field-table-p164.csv (KS rows), from the KS 2026 Wikipedia election page
--   + KS SoS 2026 federal filings. KS is NOT redistricted -> no withholding (vanilla new-
--   election). Late primary (Aug-4) -> provisional pre-primary field, culled >= 2026-08-05.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party
--   stays NULL. All 4 incumbents renominated -> no open-seat/office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'KS 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'KS'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'KS 2026 Statewide General');

-- 4 provisional races on the EXISTING KS NATIONAL_LOWER US Rep offices (geo 2001..2004)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '20'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'KS 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1231_seed_ks_2026_house_elections_races.sql', mElections);

// ---- Migration 1232: 22 new politicians + race_candidates ----
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
WHERE el.name = 'KS 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1232_seed_ks_2026_house_candidates.sql
-- Phase 164-01 Task 2: ${newRows.length} new KS politicians + ${activeRows.length} active race_candidates
--   onto the 4 KS 2026 Statewide General races. Reuse 4 renominated incumbents by external_id
--   (-20001 Mann / -20002 Schmidt / -20003 Davids / -20004 Estes). No open seats in KS.
--   external_id band -(20*10000+cd*100+seq); D-04 sub-bands KS-1 seq 3, KS-2 seq 10 (avoid 11
--   legacy MA records). ANTIPARTISAN: party never stored; races untouched.
--   Field: 160-field-table-p164.csv KS rows.
BEGIN;

-- ${newRows.length} new challenger/minor-party/independent records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (4 incumbents reused + ${newRows.length} new)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1232_seed_ks_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=4; cd++) console.log(`  KS-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new), new ext: ${newRows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1231_..., migrations/1232_..., data/seed-ks-2026-house/164-01-ks-reconciliation.csv');
