import { writeFileSync, mkdirSync } from 'fs';

// ---- WY field (staging/p165-WY.csv + WY SoS 2026 primary roster PDF, re-fetched 2026-07-07) ----
// Phase 165-07: WY at-large create-election-first seed, LATE-PRIMARY -> PROVISIONAL, OPEN seat.
//   WY 2026 primary: 2026-08-18 (verified 2026-07-07) -> cull >= 2026-08-18.
//   Hageman (pid 1e08c7c7, -56000) ran for US Senate -> REUSE-NO-ROW; no incumbent on the race.
//   FIELD COUNT DEVIATION (documented): the plan text said "18 candidates / 14-R primary" but the
//   AUTHORITATIVE sources — 160-field-table-p165.csv AND the live WY SoS 2026 Primary Election
//   Candidate Roster PDF (re-fetched 2026-07-07: exactly 10 R + 2 D for U.S. Representative) — both
//   give 10 R + 2 D + 1 Libertarian + 1 Independent = 14 total. The field table is trusted per the
//   plan's own "trust the CSV" rule; 18 was an authoring arithmetic slip.
//   PID REUSE (Pitfall 3): Chuck Gray = the sitting WY Secretary of State, ALREADY in the DB from the
//   v2.18 state-leaders seed (pid b503b679-773a-4eee-9c16-e73bff1a723f, ext -5600002) -> race_candidates
//   INSERT only, NO new politician. The other 13 are NEW at -(56*10000+seq), seq from 1 (band empty).
const ELECTION = 'WY 2026 Statewide General';
const RACE_DESC = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-18';
const SRC = 'WY SoS 2026 Primary Election Candidate Roster (sos.wyo.gov 2026_WY_Primary_Election_Candidates.pdf; open seat — Hageman -> Senate; pre-primary qualified field, cull >= 2026-08-18)';
const GRAY = { name: 'Chuck Gray', pid: 'b503b679-773a-4eee-9c16-e73bff1a723f' };
function np(n: string) { const p = n.trim().split(/\s+/); return { first: p[0], last: p.slice(1).join(' ') }; }
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

const NEW_FIELD: Array<[string, string]> = [
  ['Jillian Balow', 'Republican'], ['Bo Biteman', 'Republican'], ['Frank Chapman', 'Republican'],
  ['Kevin Christensen', 'Republican'], ['Richard Dodson', 'Republican'], ['Steve Friess', 'Republican'],
  ['David Giralt', 'Republican'], ['Reid Rasner', 'Republican'], ['Keith B. Goodenough', 'Republican'],
  ['Lisa Kinney', 'Democratic'], ['Elena Del Real', 'Democratic'],
  ['Shawn Johnson', 'Libertarian'], ['Daniel Workman', 'Independent'],
];
const rows = NEW_FIELD.map(([name, party], i) => ({ name, party, ext: -(56 * 10000 + 1 + i) }));

writeFileSync('migrations/1274_seed_wy_2026_house_election_race.sql', `-- 1274_seed_wy_2026_house_election_race.sql
-- Phase 165-07: 'WY 2026 Statewide General' + 1 at-large race (geo 5600). PROVISIONAL (WY primary
--   2026-08-18 verified). OPEN seat (Hageman -> Senate). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'WY'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '5600'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

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
// Chuck Gray: reuse the v2.18 state-leader pid by UUID literal (no politicians INSERT)
sql += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '${GRAY.pid}'::uuid, 'Chuck Gray', 'Chuck', 'Gray', false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '${GRAY.pid}'::uuid);
`;
for (const r of rows) {
  const { first, last } = np(r.name);
  sql += `INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, ${sqlStr(r.name)}, ${sqlStr(first)}, ${sqlStr(last)}, false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = ${r.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);
`;
}

writeFileSync('migrations/1275_seed_wy_2026_house_candidates.sql', `-- 1275_seed_wy_2026_house_candidates.sql
-- Phase 165-07: WY OPEN-seat field — 14 active candidates = Chuck Gray (REUSE v2.18 WY-SoS pid
--   ${GRAY.pid}, race_candidates only) + 13 NEW (-560001..-560013, band empty
--   live). Hageman (1e08c7c7, -56000) -> Senate run, NO row. Field = 10 R + 2 D + 1 L + 1 I per the
--   authoritative WY SoS roster (plan's "18" was an authoring slip — see generator header).
--   PROVISIONAL, cull >= 2026-08-18. NOT EXISTS guards; sqlStr()-escaped. ANTIPARTISAN.
BEGIN;

${sql}
COMMIT;
`);

// ---- combined RI+DE+VT+WY reconciliation CSV ----
mkdirSync('data/seed-wy-2026-house', { recursive: true });
const notes = '# RI+DE+VT+WY 165-07 reconciliation. ALL LATE-PRIMARY -> PROVISIONAL (culls: RI 2026-09-09, DE 2026-09-15, VT 2026-08-11, WY 2026-08-18; all verified 2026-07-07). ' +
  'DE safe_start_seq=48 (26 legacy records at seqs 1-47). VT safe_start_seq=6. WY OPEN (Hageman -> Senate, NO-ROW); WY field = 14 per authoritative WY SoS roster (plan said 18 — authoring slip); Chuck Gray reuses the v2.18 WY-SoS pid.';
const header = 'state,full_name,party_from_field,decision,pid_or_external_id,is_incumbent';
const lines: string[] = [
  ['RI','"Gabe Amo"','Democratic','REUSE-INCUMBENT',-44001,true].join(','),
  ['RI','"Kellie Keenan"','Republican','NEW',-440101,false].join(','),
  ['RI','"Pedro DeSouza"','Independent','NEW',-440102,false].join(','),
  ['RI','"Seth Magaziner"','Democratic','REUSE-INCUMBENT',-44002,true].join(','),
  ['RI','"Victor Mellor"','Republican','NEW',-440201,false].join(','),
  ['RI','"Stephen Skoly"','Republican','NEW',-440202,false].join(','),
  ['DE','"Sarah McBride"','Democratic','REUSE-INCUMBENT',-10000,true].join(','),
  ['DE','"Earl Cooper"','Republican','NEW (safe_start_seq=48)',-100048,false].join(','),
  ['VT','"Becca Balint"','Democratic','REUSE-INCUMBENT',-50000,true].join(','),
  ['VT','"Mark Coester"','Republican','NEW',-500006,false].join(','),
  ['VT','"Gerald Malloy"','Republican','NEW',-500007,false].join(','),
  ['VT','"Adam Ortiz"','Independent','NEW (official VT SoS XLSX)',-500008,false].join(','),
  ['WY','"Harriet M. Hageman"','Republican','RETIRED-NO-ROW (US Senate run)','1e08c7c7-68c1-4498-90b2-20850bac1c80',false].join(','),
  ['WY','"Chuck Gray"','Republican','REUSE-STATE-LEADER-PID (v2.18 WY SoS)','b503b679-773a-4eee-9c16-e73bff1a723f',false].join(','),
  ...rows.map(r => ['WY',`"${r.name}"`,r.party,'NEW',r.ext,false].join(',')),
];
writeFileSync('data/seed-wy-2026-house/165-07-ri-de-vt-wy-reconciliation.csv', [notes, header, ...lines].join('\n') + '\n');
const dup = rows.map(r=>r.name.toLowerCase()).filter((v,i,a)=>a.indexOf(v)!==i);
console.log(`WY: 14 active (Gray reuse + 13 new -560001..-560013); Hageman NO-ROW; dup: ${dup.length?dup:'none'}`);
console.log('Wrote: migrations/1274_..., 1275_..., data/seed-wy-2026-house/165-07-ri-de-vt-wy-reconciliation.csv');
