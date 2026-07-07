import { writeFileSync } from 'fs';

// ---- VT field (staging/p165-VT.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-07: VT at-large create-election-first seed, LATE-PRIMARY -> PROVISIONAL.
//   VT 2026 primary: 2026-08-11 (verified 2026-07-07) -> cull >= 2026-08-11.
//   Full qualified field: BOTH R primary candidates (Coester + Malloy) seeded provisionally per the
//   full-qualified-field rule, + Independent Adam Ortiz (present on VT's official qualified-candidates
//   XLSX though absent from Wikipedia — official source trusted). Balint (-50000) renominated reuse.
//   D-04 safe_start_seq=6 (seqs 1-5 occupied live) -> Coester -500006, Malloy -500007, Ortiz -500008.
const ELECTION = 'VT 2026 Statewide General';
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-11';
const SRC = 'VT SoS qualified-candidates list (sos.vermont.gov; pre-primary qualified field, cull >= 2026-08-11)';
function np(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const NEW_FIELD: Array<[string, string, number]> = [
  ['Mark Coester', 'Republican', -500006],
  ['Gerald Malloy', 'Republican', -500007],
  ['Adam Ortiz', 'Independent', -500008],
];

writeFileSync('migrations/1272_seed_vt_2026_house_election_race.sql', `-- 1272_seed_vt_2026_house_election_race.sql
-- Phase 165-07: 'VT 2026 Statewide General' + 1 at-large race (geo 5000). PROVISIONAL (VT primary
--   2026-08-11 verified). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'VT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '5000'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`);

let sql = '';
for (const [name, , ext] of NEW_FIELD) {
  const { first, last } = np(name);
  sql += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${ext}, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${ext});
`;
}
const rcFor = (name: string, ext: number, inc: boolean) => {
  const { first, last } = np(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
};
for (const [name, , ext] of NEW_FIELD) sql += rcFor(name, ext, false);
sql += rcFor('Becca Balint', -50000, true);

writeFileSync('migrations/1273_seed_vt_2026_house_candidates.sql', `-- 1273_seed_vt_2026_house_candidates.sql
-- Phase 165-07: 3 new VT candidates (Coester -500006, Malloy -500007, Ortiz -500008 — D-04
--   safe_start_seq=6, seqs 1-5 occupied live; both R primary rivals seeded per the
--   full-qualified-field rule; Ortiz per the official VT SoS XLSX) + Balint (-50000) reuse.
--   PROVISIONAL, cull >= 2026-08-11. ANTIPARTISAN.
BEGIN;

${sql}
COMMIT;
`);
console.log(`VT new: 3 (-500006..-500008, safe_start_seq=6); Balint reused`);
