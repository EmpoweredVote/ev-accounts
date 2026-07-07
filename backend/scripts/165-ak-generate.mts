import { writeFileSync, mkdirSync } from 'fs';

// ---- AK field (validated against staging/p165-AK.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-03: AK nonpartisan top-four-RCV seed — single at-large district (geo_id 0200).
//   1 new election 'AK 2026 Statewide General' + 1 race on the EXISTING NATIONAL_LOWER office,
//   modeled primary_party=NULL (the proven LA/CA jungle convention, 163-la-generate.mts). RCV is a
//   research-thoroughness discipline, NOT a DB schema feature (no ballot_system/rcv column; Pitfall 4
//   — no ALTER TABLE). Claude's Discretion per RESEARCH A1/OQ3, documented in the reconciliation CSV.
//   LATE-PRIMARY: AK top-four primary is 2026-08-18 (re-verified live from elections.alaska.gov
//   2026-07-07) -> full declared field seeded PROVISIONAL, cull >= 2026-08-18.
//   RCV OVER-INDULGENCE (standing preference): the FULL 15-candidate declared field is captured —
//   14 new + Begich III reuse (pid 07c7a121, external_id -2000, is_incumbent=true).
//   D-04: AK band -(2*10000+seq); seqs 1-4 occupied by unrelated KS records (polluted band) ->
//   safe_start_seq=5, first new = -20005. Band confirmed clear at seq 5+ live 2026-07-07.
const ELECTION = 'AK 2026 Statewide General';
const PRIMARY_DATE = '2026-08-18';
const RACE_DESC = `PROVISIONAL: pre-primary qualified field (top-four-RCV), cull >= ${PRIMARY_DATE}`;
const SRC = 'AK Division of Elections 2026 primary candidate list (elections.alaska.gov/candidates/?election=26prim; top-four-RCV, all parties one ballot; declared field, cull >= 2026-08-18)';

const BEGICH = { name: 'Nicholas J. Begich III', pid: '07c7a121-520f-4651-a1a0-5f38d20f8e0b', ext: -2000 };

type Cand = { name: string; party: string };
// FULL declared top-four-primary field from staging/p165-AK.csv (RCV over-indulgence: every declared
// candidate captured, staging order preserved; seq assigned from 5).
const FIELD: Cand[] = [
  { name: 'David R. Ambrose II',       party: 'Nonpartisan' },
  { name: 'Lady Donna Dutchess',       party: 'Nonpartisan' },
  { name: 'John E. Foddrill Sr.',      party: 'Libertarian' },
  { name: 'Eddie Goldfarb',            party: 'Republican' },
  { name: 'Eric Hafner',               party: 'Democratic' },
  { name: 'Bill Hill',                 party: 'Nonpartisan' },
  { name: 'James C. "Jim" McDermott',  party: 'Libertarian' },
  { name: 'Yaquelin Reynoso',          party: 'Democratic' },
  { name: 'David Richey',              party: 'Nonpartisan' },
  { name: 'Melanie A. Salazar',        party: 'Nonpartisan' },
  { name: 'Matt Schultz',              party: 'Democratic' },
  { name: 'Clay Strickland',           party: 'Republican' },
  { name: 'John B. Williams',          party: 'Democratic' },
  { name: 'Matthew "Bronco" Williams', party: 'Undeclared' },
];

function nameParts(n: string) {
  const parts = n.trim().split(/\s+/);
  return { first: parts[0], last: parts.slice(1).join(' ') };
}
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

type Row = Cand & { ext: number };
const rows: Row[] = FIELD.map((c, i) => ({ ...c, ext: -(2 * 10000 + 5 + i) }));

// ---- CSV reconciliation ----
mkdirSync('data/seed-ak-2026-house', { recursive: true });
const notes = '# AK top-four-RCV modeling decision (Claude\'s Discretion per RESEARCH A1/OQ3): single at-large race ' +
  'with primary_party=NULL (LA/CA jungle convention). RCV is research-thoroughness only — no schema change. ' +
  'PROVISIONAL: full declared field, cull >= 2026-08-18 (AK top-four primary, verified elections.alaska.gov ' +
  '2026-07-07). Position name: U.S. Representative At-Large (office title is \'U.S. Representative\'; no prior ' +
  'AK race existed — this sets the at-large convention).';
const header = 'geo_id,full_name,party_from_field,decision,pid_or_external_id,is_incumbent,source';
const csvLines: string[] = [];
csvLines.push(['0200', '"Nicholas J. Begich III"', 'Republican', 'REUSE-INCUMBENT', BEGICH.ext, true, `"${SRC}"`].join(','));
for (const r of rows) csvLines.push(['0200', `"${r.name.replace(/"/g, '""')}"`, r.party, 'NEW', r.ext, false, `"${SRC}"`].join(','));
writeFileSync('data/seed-ak-2026-house/165-03-ak-reconciliation.csv', [notes, header, ...csvLines].join('\n') + '\n');

// ---- Migration A (1254): election + 1 at-large jungle race ----
const migA = `-- 1254_seed_ak_2026_house_election_race.sql
-- Phase 165-03: 'AK 2026 Statewide General' election + 1 at-large U.S. House race on the EXISTING
--   NATIONAL_LOWER office for geo_id 0200. JUNGLE/TOP-FOUR MODEL: primary_party=NULL (LA/CA
--   convention; the idx_races_election_position_no_party unique index supports this shape). RCV is
--   research-only — no schema change. PROVISIONAL: declared pre-primary field, cull >= ${PRIMARY_DATE}
--   (AK top-four primary date verified from elections.alaska.gov 2026-07-07). office_id never NULL.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'AK'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '0200'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`;
writeFileSync('migrations/1254_seed_ak_2026_house_election_race.sql', migA);

// ---- Migration B (1255): 14 new politicians + 15 race_candidates ----
let polInserts = '';
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  polInserts += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}

let rcInserts = `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '${BEGICH.pid}'::uuid, ${sqlStr(BEGICH.name)}, 'Nicholas', 'Begich', true, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '${BEGICH.pid}'::uuid);
`;
for (const r of rows) {
  const { first, last } = nameParts(r.name);
  rcInserts += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}

const migB = `-- 1255_seed_ak_2026_house_candidates.sql
-- Phase 165-03: FULL AK top-four-RCV declared field — 14 new politicians (-20005..-20018,
--   D-04 safe_start_seq=5: seqs 1-4 are unrelated KS records in the polluted band) + Begich III
--   reuse (pid ${BEGICH.pid}, external_id -2000, is_incumbent=true) = 15 active
--   race_candidates on the single at-large jungle race. RCV over-indulgence: every declared
--   candidate captured. NOT EXISTS guards on (race_id, politician_id); sqlStr()-escaped.
--   ANTIPARTISAN: party never stored on the card.
BEGIN;

-- (a) 14 new AK candidates (idempotent on external_id)
${polInserts}
-- (b) 15 race_candidates (Begich reuse + 14 new)
${rcInserts}
COMMIT;
`;
writeFileSync('migrations/1255_seed_ak_2026_house_candidates.sql', migB);

const allNames = [BEGICH.name.toLowerCase(), ...rows.map(r=>r.name.toLowerCase())];
const dupName = allNames.filter((v,i,a)=>a.indexOf(v)!==i);
const dupExt = rows.map(r=>r.ext).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`new: ${rows.length} (ext ${Math.min(...rows.map(r=>r.ext))} .. ${Math.max(...rows.map(r=>r.ext))}); +Begich reuse = ${rows.length+1} active`);
console.log(`dup external_id: ${dupExt.length ? dupExt : 'none'}; dup full_name: ${dupName.length ? dupName : 'none'}`);
console.log('Wrote: migrations/1254_seed_ak_2026_house_election_race.sql, migrations/1255_seed_ak_2026_house_candidates.sql, data/seed-ak-2026-house/165-03-ak-reconciliation.csv');
