import { writeFileSync, mkdirSync } from 'fs';

// ---- SD field (staging/p165-SD.csv + LIVE prod checks 2026-07-07) ----
// Phase 165-08: SD at-large create-election-first seed. DECIDED and FINAL (SD independent deadline
//   2026-04-28 passed — NO Phase-167 follow-up for SD).
//   OPEN seat: Dusty Johnson (4ec42691, -46000) filed for Governor -> REUSE-NO-ROW.
//   Field = exactly Jackley (R) + Gronli (D) per the SD SoS certified list (vip.sdsos.gov eid=774).
//   PID REUSE (Pitfall 3): Marty Jackley = sitting SD Attorney General, ALREADY in DB from the v2.18
//   state-leaders seed (pid 2537050a-cd40-460e-9751-1d982dd73c25, ext -4600003) -> race_candidates
//   INSERT only. Gronli NEW at -460001.
//   EXCLUDED PERMANENTLY: Jack Pittman (FEC filer, ABSENT from the authoritative SD SoS list).
const ELECTION = 'SD 2026 Statewide General';
const RACE_DESC = 'Confirmed general field (SD SoS certified; independent deadline 2026-04-28 passed — field final)';
const SRC = 'SD SoS certified candidate list (vip.sdsos.gov eid=774; decided; field final)';
const JACKLEY_PID = '2537050a-cd40-460e-9751-1d982dd73c25';
function sqlStr(s: string) { return "'" + s.replace(/'/g, "''") + "'"; }

writeFileSync('migrations/1280_seed_sd_2026_house_election_race.sql', `-- 1280_seed_sd_2026_house_election_race.sql
-- Phase 165-08: 'SD 2026 Statewide General' + 1 at-large race (geo 4600). DECIDED + FINAL.
--   OPEN seat (Johnson -> Governor). office_id never NULL. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT '${ELECTION}', '2026-11-03'::date, 'general', 'state', 'SD'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = '${ELECTION}');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, 'U.S. Representative At-Large', NULL, 1, ${sqlStr(RACE_DESC)}
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '4600'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = '${ELECTION}'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);

COMMIT;
`);

writeFileSync('migrations/1281_seed_sd_2026_house_candidates.sql', `-- 1281_seed_sd_2026_house_candidates.sql
-- Phase 165-08: SD OPEN-seat field — Marty Jackley (REUSE v2.18 SD-AG pid ${JACKLEY_PID},
--   race_candidates only) + Nikki Gronli NEW at -460001. Johnson (4ec42691) -> Governor, NO row.
--   Pittman EXCLUDED permanently (absent from the authoritative SD SoS list). DECIDED + FINAL.
--   NOT EXISTS guards. ANTIPARTISAN.
BEGIN;

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -460001, 'Nikki Gronli', 'Nikki', 'Gronli', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -460001);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, '${JACKLEY_PID}'::uuid, 'Marty Jackley', 'Marty', 'Jackley', false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = '${JACKLEY_PID}'::uuid);

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, 'Nikki Gronli', 'Nikki', 'Gronli', false, 'active', ${sqlStr(SRC)}
FROM essentials.races r
JOIN essentials.elections el ON el.id = r.election_id AND el.name = '${ELECTION}'
JOIN essentials.politicians p ON p.external_id = -460001
WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

COMMIT;
`);

// ---- combined MT+ND+SD reconciliation CSV ----
mkdirSync('data/seed-mt-2026-house', { recursive: true });
const notes = '# MT+ND+SD 165-08 reconciliation. ALL DECIDED, NOT PROVISIONAL. MT-1 OPEN (Zinke retired), SD OPEN (Johnson -> Governor). ' +
  'EXCLUDED -> Phase 167: MT Persico + Eisenhauer (cert to 2026-08-20), ND Neville + Tuttle (window to 2026-08-31). ' +
  'EXCLUDED PERMANENTLY: SD Jack Pittman (absent from SD SoS certified list; Apr-28 deadline passed, SD field FINAL). ' +
  'Jackley reuses the v2.18 SD-AG pid.';
const header = 'state,geo_id,full_name,party_from_field,decision,pid_or_external_id,is_incumbent';
const lines = [
  ['MT','3001','"Ryan K. Zinke"','Republican','RETIRED-NO-ROW','eb9fac1d-e596-4a78-8c14-314af94e307f',false],
  ['MT','3001','"Aaron Flint"','Republican','NEW',-300101,false],
  ['MT','3001','"Sam Forstag"','Democratic','NEW',-300102,false],
  ['MT','3001','"Nick Sheedy"','Libertarian','NEW',-300103,false],
  ['MT','3002','"Troy Downing"','Republican','REUSE-INCUMBENT',-30002,true],
  ['MT','3002','"Brian Miller"','Democratic','NEW (safe_start_seq=85)',-300285,false],
  ['MT','3002','"Patrick McCracken"','Libertarian','NEW',-300286,false],
  ['MT','3001','"Kimberly Persico"','Independent','EXCLUDE-PENDING-CERT (167; 2026-08-20)','',false],
  ['MT','3002','"Michael Eisenhauer"','Independent','EXCLUDE-PENDING-CERT (167; 2026-08-20)','',false],
  ['ND','3800','"Julie Fedorchak"','Republican','REUSE-INCUMBENT',-38000,true],
  ['ND','3800','"Trygve Hammer"','Democratic-NPL','NEW',-380001,false],
  ['ND','3800','"Helene Neville"','Independent','EXCLUDE-PENDING-PETITION (167; 2026-08-31)','',false],
  ['ND','3800','"Charles Tuttle"','Independent','EXCLUDE-PENDING-PETITION (167; 2026-08-31)','',false],
  ['SD','4600','"Dusty Johnson"','Republican','RETIRED-NO-ROW (Governor run)','4ec42691-0ce1-4f29-a6ba-0835fe35a963',false],
  ['SD','4600','"Marty Jackley"','Republican','REUSE-STATE-LEADER-PID (v2.18 SD AG)','2537050a-cd40-460e-9751-1d982dd73c25',false],
  ['SD','4600','"Nikki Gronli"','Democratic','NEW',-460001,false],
  ['SD','4600','"Jack Pittman"','Independent','EXCLUDE-PERMANENT (not SoS-certified; deadline passed)','',false],
];
writeFileSync('data/seed-mt-2026-house/165-08-mt-nd-sd-reconciliation.csv',
  [notes, header, ...lines.map(l=>l.join(','))].join('\n') + '\n');
console.log('SD: Jackley pid-reuse + Gronli -460001; Johnson NO-ROW. Wrote 1280/1281 + reconciliation CSV');
