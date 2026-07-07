import { writeFileSync } from 'fs';

// ---- MT field (staging/p165-MT.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-08: MT vanilla create-election-first seed. DECIDED (Jun-2 primary done) -> NOT PROVISIONAL.
//   MT-1 OPEN: Zinke (eb9fac1d, -30001) retired Mar-2-2026 -> REUSE-NO-ROW; all 3 general candidates
//   NEW (Flint won R primary 50.1%, Forstag D 37.3%, Sheedy L direct-filed).
//   MT-2: Downing (-30002) renominated reuse + Miller (D, won primary 55.7%) + McCracken (L).
//   D-04: MT-2 safe_start_seq=85 (band top -300284, unrelated legacy record); MT-1 seq from 1.
//   EXCLUDED (Pitfall 5, MT cert deadline 2026-08-20 -> Phase 167): Kimberly Persico (MT-1),
//   Michael Eisenhauer (MT-2) — both short of petition threshold per unofficial county tallies.
const ELECTION = 'MT 2026 Statewide General';
const RACE_DESC = 'Confirmed general field; MT independent certification pending to 2026-08-20 -> Phase 167';
const SRC = 'MT candidate filing (candidatefiling.mt.gov e=450002928; decided Jun-2 primary; independent cert window to 2026-08-20 -> Phase 167)';
const INC2 = { name: 'Troy Downing', ext: -30002 };
function np(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const SEQ_START: Record<number, number> = { 1: 1, 2: 85 };
const FIELD: Array<[number, string, string]> = [
  [1, 'Aaron Flint', 'Republican'], [1, 'Sam Forstag', 'Democratic'], [1, 'Nick Sheedy', 'Libertarian'],
  [2, 'Brian Miller', 'Democratic'], [2, 'Patrick McCracken', 'Libertarian'],
];
const seq: Record<number, number> = {};
const rows = FIELD.map(([cd, name, party]) => {
  seq[cd] = (cd in seq) ? seq[cd] + 1 : SEQ_START[cd];
  return { cd, name, party, geo: '30' + String(cd).padStart(2, '0'), ext: -(30 * 10000 + cd * 100 + seq[cd]) };
});

let raceInserts = '';
for (const cd of [1, 2]) {
  const geo = '30' + String(cd).padStart(2, '0');
  raceInserts += `INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text, NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
`;
}
writeFileSync('migrations/1276_seed_mt_2026_house_election_races.sql', `-- 1276_seed_mt_2026_house_election_races.sql
-- Phase 165-08: 'MT 2026 Statewide General' + 2 races (geo 3001-3002). DECIDED -> NOT PROVISIONAL
--   (MT independent cert window to 2026-08-20 -> Phase 167). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'MT'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

${raceInserts}
COMMIT;
`);

let sql = '';
for (const r of rows) {
  const { first, last } = np(r.name);
  sql += `INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT ${r.ext}, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${r.ext});
`;
}
const rcFor = (name: string, ext: number, geo: string, inc: boolean) => {
  const { first, last } = np(name);
  return `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(name)}, ${sqlStr(first)}, ${sqlStr(last)}, ${inc}, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id = ${sqlStr(geo)}
JOIN essentials.politicians p ON p.external_id = ${ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
};
for (const r of rows) sql += rcFor(r.name, r.ext, r.geo, false);
sql += rcFor(INC2.name, INC2.ext, '3002', true);

writeFileSync('migrations/1277_seed_mt_2026_house_candidates.sql', `-- 1277_seed_mt_2026_house_candidates.sql
-- Phase 165-08: MT-1 OPEN all-new field (Flint -300101, Forstag -300102, Sheedy -300103; Zinke
--   eb9fac1d NO row) + MT-2 Miller -300285 / McCracken -300286 (D-04 safe_start_seq=85) +
--   Downing (-30002) renominated reuse. DECIDED. EXCLUDED pending-independents (cert to
--   2026-08-20 -> 167): Persico, Eisenhauer. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

${sql}
COMMIT;
`);
console.log(`MT new: ${rows.length} (${rows.map(r=>r.ext).join(', ')}); Downing reused; Zinke NO-ROW`);
