import { writeFileSync, mkdirSync } from 'fs';

// ---- CT field (validated against 160-field-table-p164.csv CT rows + a Task-1 D-02 directly-
//      fetched re-verification pass via FEC candidate API + Ballotpedia) ----
// Phase 164-02 Task 2: CT end-to-end seed (vanilla new-election, 1-election). CT is NOT
//   redistricted -> no withholding. Late-primary (Aug-11) -> full convention/petition field is
//   PROVISIONAL, cull >= 2026-08-12. ALL 5 incumbents run (Larson CT-1 LOST the Dem convention
//   endorsement to Bronin 214-204 but is a genuine 4-way primary candidate, D-01 -> is_incumbent
//   reuse row). D-02 re-verification (Task 1, FEC + Ballotpedia directly fetched):
//     - Bueno CT-4 (FEC H6CT04176, SoC 4/8/2026)          -> INCLUDE (provisional-with-note)
//     - Cerreta CT-4 (FEC H0CT04237, IND filed)           -> INCLUDE (provisional-with-note)
//     - Miressi CT-4 (FEC H6CT04150 status=C, convention) -> INCLUDE
//     - Botelho CT-5 (FEC H2CT05230 status=C statutory + Ballotpedia lists her in the Aug-11
//       3-way GOP primary) -> INCLUDE. This CHANGES the field-table HOLD; the stale May-16
//       "two-way primary" report is superseded by directly-fetched sources (D-02 concrete-in).
//   Result: 17 new records (not 16 — Botelho promoted HOLD->INCLUDE on re-verification).
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean; vacate?: boolean; note?: string };
const INC_EXT: Record<number, number> = {1:-9001,2:-9002,3:-9003,4:-9004,5:-9005};

const FIELD: Cand[] = [
  // CT-1 (0901): Larson lost convention endorsement but is a genuine 4-way Dem primary candidate (D-01)
  { cd:1, name:'John B. Larson', party:'Democratic', role:'D', inc:true },
  { cd:1, name:'Luke Bronin', party:'Democratic', role:'D', note:'Dem convention-endorsed nominee (beat Larson 214-204, May-11-2026 convention)' },
  { cd:1, name:'Jillian Gilchrest', party:'Democratic', role:'D', note:'qualified at convention with 15%+ delegates' },
  { cd:1, name:'Ruth Fortune', party:'Democratic', role:'D', note:'petitioned onto ballot with 3,743 signatures' },
  { cd:1, name:'Amy Chai', party:'Republican', role:'R', note:'only GOP candidate, nominated by acclamation' },
  // CT-2 (0902): Courtney renominated
  { cd:2, name:'Joe Courtney', party:'Democratic', role:'D', inc:true },
  { cd:2, name:'George Austin', party:'Republican', role:'R', note:'GOP convention-endorsed by acclamation, unopposed' },
  // CT-3 (0903): DeLauro renominated
  { cd:3, name:'Rosa L. DeLauro', party:'Democratic', role:'D', inc:true },
  { cd:3, name:'Christopher Lancia', party:'Republican', role:'R', note:'GOP convention-endorsed via roll call' },
  { cd:3, name:'Rafael Irizarry', party:'Republican', role:'R', note:'qualified for primary at convention' },
  { cd:3, name:'Andrew Rice', party:'Independent', role:'IND', note:'petitioning independent for general (eliminated at Dem convention)' },
  // CT-4 (0904): Himes renominated
  { cd:4, name:'James A. Himes', party:'Democratic', role:'D', inc:true },
  { cd:4, name:'Michael Goldstein', party:'Republican', role:'R', note:'GOP convention-endorsed via roll call (FEC H6CT04143 status=C)' },
  { cd:4, name:'Daniel Miressi', party:'Republican', role:'R', note:'D-02 re-verified: qualified for primary at convention; FEC H6CT04150 status=C' },
  { cd:4, name:'Luz Helena Bueno', party:'Republican', role:'R', note:'D-02 re-verified: FEC Statement of Candidacy H6CT04176 filed 2026-04-08 (concrete signal, provisional-with-note)' },
  { cd:4, name:'Joseph Perez-Caputo', party:'Independent', role:'IND', note:'eliminated at Dem convention (1.7%); running independent for general (FEC H6CT04127)' },
  { cd:4, name:'Damon Lawrence Cerreta', party:'Independent', role:'IND', note:'D-02 re-verified: FEC candidacy H0CT04237 (concrete signal, provisional-with-note)' },
  // CT-5 (0905): Hayes renominated
  { cd:5, name:'Jahana Hayes', party:'Democratic', role:'D', inc:true },
  { cd:5, name:'Chris Shea', party:'Republican', role:'R', note:'GOP convention-endorsed via roll call (FEC H6CT05231 status=C)' },
  { cd:5, name:'Jonathan De Barros', party:'Republican', role:'R', note:'qualified for primary at convention (FEC H6CT05223 status=C)' },
  { cd:5, name:'Michele Botelho', party:'Republican', role:'R', note:'D-02 re-verified HOLD->INCLUDE: FEC H2CT05230 status=C statutory + Ballotpedia lists her in the Aug-11 3-way GOP primary (supersedes stale May-16 two-way report)' },
  { cd:5, name:'Jackson Taddeo-Waite', party:'Independent', role:'IND', note:'former Dem convention candidate; filed FEC candidacy (H6CT05215) to run independent for general' },
];

const SRC_MAJOR = 'CT 2026 US House field (ctmirror.org / ctpublic.org / ctinsider.com convention coverage + FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12';
const SRC_OTHER = 'CT 2026 US House field (petitioning independent / minor-party; FEC candidate filings); provisional pre-primary convention/petition field, cull >= 2026-08-12';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// CT fips = 9; formula: -(9 * 10000 + cd * 100 + seq), standard seq start 1 per CD.
// Live collision re-check (164-02 Task 1): 0 rows in -90599..-90101. Incumbents reuse -9001..-9005.
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '09' + String(c.cd).padStart(2, '0');
  const baseSrc = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  const source = c.note ? `${baseSrc} — ${c.note}` : baseSrc;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(9 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (164-02-ct-reconciliation.csv) ----
mkdirSync('data/seed-ct-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,d02_note,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${(r.note||'').replace(/"/g,'""')}"`, `"${r.source.replace(/"/g,'""')}"`].join(','));
// Record the HELD decision explicitly (Botelho was promoted, so nothing currently held; keep an audit line if any future HOLD)
writeFileSync('data/seed-ct-2026-house/164-02-ct-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1233: election + 5 races ----
const mElections = `-- 1233_seed_ct_2026_house_elections_races.sql
-- Phase 164-02 Task 2: CT 2026 Statewide General election + 5 provisional U.S. House races.
-- Field source: 160-field-table-p164.csv (CT rows) + Task-1 D-02 directly-fetched re-verification
--   (FEC candidate API + Ballotpedia). CT is NOT redistricted -> no withholding (vanilla new-
--   election). Late primary (Aug-11) -> provisional convention/petition field, culled >= 2026-08-12.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party stays
--   NULL. All 5 incumbents renominated/running (Larson lost endorsement but is a primary candidate)
--   -> no open-seat/office/district insert.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'CT 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'CT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'CT 2026 Statewide General');

-- 5 provisional races on the EXISTING CT NATIONAL_LOWER US Rep offices (geo 0901..0905)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'PROVISIONAL: pre-primary convention/petition qualified field, cull >= 2026-08-12'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '09'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'CT 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1233_seed_ct_2026_house_elections_races.sql', mElections);

// ---- Migration 1234: new politicians + race_candidates ----
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
WHERE el.name = 'CT 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1234_seed_ct_2026_house_candidates.sql
-- Phase 164-02 Task 2: ${newRows.length} new CT politicians + ${activeRows.length} active race_candidates
--   onto the 5 CT 2026 Statewide General races. Reuse 5 renominated/running incumbents by
--   external_id (-9001 Larson / -9002 Courtney / -9003 DeLauro / -9004 Himes / -9005 Hayes;
--   Larson is_incumbent reuse row = a genuine 4-way primary candidate, D-01). external_id band
--   -(9*10000+cd*100+seq), standard seq start 1. D-02 unconfirmed names all INCLUDED after a
--   directly-fetched re-verification (FEC + Ballotpedia): Bueno/Cerreta/Miressi/Botelho — Botelho
--   promoted HOLD->INCLUDE. ANTIPARTISAN: party never stored; races untouched.
BEGIN;

-- ${newRows.length} new challenger/convention/petition records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (5 incumbents reused + ${newRows.length} new)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1234_seed_ct_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}, REUSE-NO-ROW=${rows.filter(r=>r.decision==='REUSE-NO-ROW').length})`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('per-district active counts:');
for (let cd=1; cd<=5; cd++) console.log(`  CT-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new), new ext: ${newRows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1233_..., migrations/1234_..., data/seed-ct-2026-house/164-02-ct-reconciliation.csv');
