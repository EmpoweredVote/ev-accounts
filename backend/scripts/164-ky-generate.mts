import { writeFileSync, mkdirSync } from 'fs';

// ---- KY field (validated against 160-field-table-p164.csv KY rows) ----
// Phase 164-04 Task 2: KY end-to-end seed (vanilla new-election, 1-election). KY is NOT
//   redistricted -> no withholding. DECIDED general field -> NOT PROVISIONAL. Two OPEN seats
//   (D-05): KY-4 Thomas Massie (-21004) LOST his primary -> Ed Gallrein (R) nominee, Massie
//   gets NO row; KY-6 Andy Barr (-21006) RETIRED -> Ralph Alvarado (R) nominee, Barr gets NO row.
//   Renominated incumbents reused (is_incumbent): Comer -21001, Guthrie -21002, McGarvey -21003,
//   Harold Rogers -21005. COLLISION SUB-BAND (D-04): KY-1 seqs 1-98 (-210101..-210198) are
//   occupied by 98 MA state legislators -> KY-1 new record uses seq 200 (-210300); KY-2..6 seq 1.
type Cand = { cd: number; name: string; party: string; role: string; inc?: boolean };
// Only the 4 RENOMINATED incumbents (Massie/Barr are departing -> omitted entirely, no row, D-05).
const INC_EXT: Record<number, number> = {1:-21001,2:-21002,3:-21003,5:-21005};
// D-04 per-district seq starts (KY-1=200, else 1).
const SEQ_START: Record<number, number> = {1:200,2:1,3:1,4:1,5:1,6:1};

const FIELD: Cand[] = [
  // KY-1 (2101): Comer renominated
  { cd:1, name:'James Comer', party:'Republican', role:'R', inc:true },
  { cd:1, name:'John "Drew" Williams', party:'Democratic', role:'D' },
  // KY-2 (2102): Guthrie renominated
  { cd:2, name:'Brett Guthrie', party:'Republican', role:'R', inc:true },
  { cd:2, name:'Megan Wingfield', party:'Democratic', role:'D' },
  { cd:2, name:'Thomas A. Loecken', party:'Independent', role:'IND' },
  // KY-3 (2103): McGarvey renominated
  { cd:3, name:'Morgan McGarvey', party:'Democratic', role:'D', inc:true },
  { cd:3, name:'Maria Teresa Rodriguez', party:'Republican', role:'R' },
  // KY-4 (2104): OPEN — Massie lost primary (EXCLUDED); Gallrein R nominee
  { cd:4, name:'Ed Gallrein', party:'Republican', role:'R' },
  { cd:4, name:'Melissa Claire Strange', party:'Democratic', role:'D' },
  { cd:4, name:'Mohammad Wael Ahmad', party:'Kentucky Party', role:'KY' },
  { cd:4, name:'Jeremy Todd', party:'Libertarian', role:'LIB' },
  // KY-5 (2105): Harold Rogers renominated
  { cd:5, name:'Harold Rogers', party:'Republican', role:'R', inc:true },
  { cd:5, name:'Ned Pillersdorf', party:'Democratic', role:'D' },
  { cd:5, name:'Gerardo Serrano', party:'Independent', role:'IND' },
  { cd:5, name:'Mikel Wein', party:'Independent', role:'IND' },
  // KY-6 (2106): OPEN — Barr retired (EXCLUDED); Alvarado R nominee
  { cd:6, name:'Ralph Alvarado', party:'Republican', role:'R' },
  { cd:6, name:'Zach Dembo', party:'Democratic', role:'D' },
  { cd:6, name:'Jay J Bowman', party:'Independent', role:'IND' },
  { cd:6, name:'Pete Lynch', party:'Kentucky Party', role:'KY' },
];
// Departing incumbents (documented in CSV only; NO migration row) — D-05.
const EXCLUDED = [
  { cd:4, name:'Thomas Massie', ext:-21004, reason:'lost-primary (Gallrein is the R nominee)' },
  { cd:6, name:'Andy Barr', ext:-21006, reason:'retired (Alvarado is the R nominee)' },
];

const SRC_MAJOR = 'KY 2026 US House field (KY SoS candidate filings + en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Kentucky); decided general field';
const SRC_OTHER = 'KY 2026 US House field (minor-party/independent filing; KY SoS + Wikipedia); decided general field';

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

// ---- assign external_ids per district (seq in FIELD order, incumbents skipped) ----
// KY fips = 21; formula: -(21 * 10000 + cd * 100 + seq). Per-CD seq start from SEQ_START (D-04).
const seqByCd: Record<number, number> = {};
type Row = Cand & { geo: string; ext: number; decision: string; is_incumbent: boolean; source: string };
const rows: Row[] = [];
for (const c of FIELD) {
  const geo = '21' + String(c.cd).padStart(2, '0');
  const source = (c.role === 'D' || c.role === 'R') ? SRC_MAJOR : SRC_OTHER;
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: 'REUSE', is_incumbent: true, source });
  } else {
    seqByCd[c.cd] = (c.cd in seqByCd) ? seqByCd[c.cd] + 1 : SEQ_START[c.cd];
    const ext = -(21 * 10000 + c.cd * 100 + seqByCd[c.cd]);
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false, source });
  }
}

// ---- CSV (164-04-ky-reconciliation.csv) ----
mkdirSync('data/seed-ky-2026-house', { recursive: true });
const header = 'cd,geo_id,full_name,party_from_field,role,decision,assign_external_id,is_incumbent,source';
const csvLines = rows.map(r => [r.cd, r.geo, `"${r.name}"`, r.party, r.role, r.decision, r.ext, r.is_incumbent, `"${r.source}"`].join(','));
for (const e of EXCLUDED) csvLines.push([e.cd, '21'+String(e.cd).padStart(2,'0'), `"${e.name}"`, '', 'INC', 'EXCLUDED-NO-ROW', e.ext, false, `"D-05 open seat: ${e.reason}"`].join(','));
writeFileSync('data/seed-ky-2026-house/164-04-ky-reconciliation.csv', [header, ...csvLines].join('\n') + '\n');

// ---- Migration 1236: election + 6 races ----
const mElections = `-- 1236_seed_ky_2026_house_elections_races.sql
-- Phase 164-04 Task 2: KY 2026 Statewide General election + 6 U.S. House races.
-- Field source: 160-field-table-p164.csv (KY rows), KY SoS filings + Wikipedia. KY is NOT
--   redistricted -> no withholding (vanilla new-election). DECIDED general field -> NOT
--   PROVISIONAL. Two open seats (KY-4 Massie lost-primary, KY-6 Barr retired) — the district
--   offices already exist, NO office/district insert. ANTIPARTISAN INVARIANT: party is NEVER
--   stored on race_candidates; races.primary_party stays NULL.
BEGIN;

-- 1 election (idempotent on name)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'KY 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'KY'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'KY 2026 Statewide General');

-- 6 races on the EXISTING KY NATIONAL_LOWER US Rep offices (geo 2101..2106)
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id,
       o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL,
       1,
       'Confirmed 2026 general-election field'
FROM essentials.elections el
JOIN essentials.districts d
  ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = '21'
JOIN essentials.offices o
  ON o.district_id = d.id
WHERE el.name = 'KY 2026 Statewide General'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id
  );

COMMIT;
`;
writeFileSync('migrations/1236_seed_ky_2026_house_elections_races.sql', mElections);

// ---- Migration 1237: new politicians + race_candidates ----
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
WHERE el.name = 'KY 2026 Statewide General' AND d.geo_id = ${sqlStr(r.geo)}
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(${sqlStr(r.name)}));
`;
}

const mCandidates = `-- 1237_seed_ky_2026_house_candidates.sql
-- Phase 164-04 Task 2: ${newRows.length} new KY politicians + ${activeRows.length} active race_candidates
--   onto the 6 KY 2026 Statewide General races. Reuse 4 renominated incumbents by external_id
--   (-21001 Comer / -21002 Guthrie / -21003 McGarvey / -21005 Harold Rogers). OPEN SEATS (D-05):
--   Massie -21004 (KY-4, lost primary) and Barr -21006 (KY-6, retired) get NO active row. external_id
--   band -(21*10000+cd*100+seq); KY-1 seq 200 (-210300) avoids 98 MA state-leg collisions.
--   ANTIPARTISAN: party never stored; races untouched.
BEGIN;

-- ${newRows.length} new challenger/open-seat/minor-party records (idempotent on external_id)
${polInserts}
-- ${activeRows.length} active race_candidates (4 incumbents reused + ${newRows.length} new; Massie/Barr excluded)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1237_seed_ky_2026_house_candidates.sql', mCandidates);

console.log(`CSV rows: ${rows.length} (active=${activeRows.length}); EXCLUDED (open-seat departing): ${EXCLUDED.map(e=>e.name).join(', ')}`);
console.log(`NEW records: ${newRows.length}`);
console.log(`external_id range: ${Math.min(...newRows.map(r=>r.ext))} .. ${Math.max(...newRows.map(r=>r.ext))}`);
const dupExt = newRows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
const dupName = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}`);
console.log(`dup full_name: ${dupName.length ? dupName : 'none'}`);
for (let cd=1; cd<=6; cd++) console.log(`  KY-${cd}: ${activeRows.filter(r=>r.cd===cd).length} active (${newRows.filter(r=>r.cd===cd).length} new), new ext: ${newRows.filter(r=>r.cd===cd).map(r=>r.ext).join(',')}`);
console.log('\nWrote: migrations/1236_..., migrations/1237_..., data/seed-ky-2026-house/164-04-ky-reconciliation.csv');
