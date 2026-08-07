-- 1588_ca_ltgov_treasurer_and_incumbent_lookup_fabrications.sql
--
-- Remove two fabricated candidacies created by `incumbent_lookup`, then record the two contests they
-- were blocking: California Lieutenant Governor (16 rows) and State Treasurer (6 rows).
--
--   Rollback: the two deleted rows are archived in full in essentials._fabricated_1588_removed.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1588_ca_ltgov_treasurer_and_incumbent_lookup_fabrications.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE DEFECT: TWO OFFICEHOLDERS SWAPPED SEATS AND A ROSTER LOOKUP DID NOT NOTICE
-- ---------------------------------------------------------------------------------------------------
-- Fiona Ma and Eleni Kounalakis each appeared as a candidate in BOTH the Lieutenant Governor and the
-- State Treasurer race. Two sources disagreed, and the source tells you which is which:
--
--   ca-sos-2026      (real candidate filings)  Fiona Ma → LT GOVERNOR      Kounalakis → TREASURER
--   incumbent_lookup (synthetic)               Kounalakis → LT GOVERNOR    Fiona Ma → TREASURER
--
-- Ma is the sitting Treasurer; Kounalakis is the sitting Lieutenant Governor. They ran for each
-- other's offices, and `incumbent_lookup` — which attaches the CURRENT HOLDER of an office to that
-- office's race — asserted the one thing that was not true of either of them.
--
-- PROVEN AGAINST THE CERTIFIED COUNT, not inferred from the source names:
--   * Treasurer's certified field is SIX names and Fiona Ma is not among them. Kounalakis leads it
--     with 3,154,323 / 36.7%.
--   * Lieutenant Governor's certified field is SIXTEEN names, Fiona Ma leads it with 1,631,935 /
--     19.1%, and Kounalakis is in neither of its two panels.
-- A person cannot be on two statewide ballots in one election, so each `incumbent_lookup` row is a
-- candidacy that never existed. `not_nominated` would be the wrong value — it says someone ran and
-- failed to become the nominee. These rows are deleted and archived instead.
--
-- 🔑 THE GENERALISABLE POINT — "THE INCUMBENT IS PRESUMABLY RUNNING" IS NOT A FACT, IT IS A GUESS.
-- There are 14 `incumbent_lookup` rows in the database, all on this election, one per race. Most are
-- harmless because the incumbent genuinely did run (Bonta, Weber, Prang, Luna, Melvoin, Gonez). The
-- guess fails silently whenever an officeholder retires, is termed out, or runs for something else —
-- and it fails invisibly, because a fabricated candidate looks exactly like a real one.
--
-- This is the SAME generator as the five `la_roster` Board of Supervisors race shells recorded in
-- migration 1583, which put Hilda Solis on a 2026 ballot for a seat Maria Elena Durazo won outright.
-- Both take a roster of who holds office and emit candidates from it.
--
-- ⚠️ A THIRD SUSPECT, DELIBERATELY NOT DELETED. `incumbent_lookup` also placed Scott Schmerelson on
-- LAUSD Board District 2. He is a sitting LAUSD member — for District 3 — and District 2's certified
-- field is Rivas and Zamora. That looks like the same fabrication, but the evidence is only ABSENCE
-- from one field, where Ma and Kounalakis are each positively documented on a DIFFERENT ballot. He
-- keeps the `not_nominated` recorded in migration 1583 pending a check of LAUSD district assignment.
-- ---------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS essentials._fabricated_1588_removed AS
  SELECT rc.*, NULL::text AS reason, now() AS removed_at
  FROM essentials.race_candidates rc WHERE false;

INSERT INTO essentials._fabricated_1588_removed
  SELECT rc.*,
         'incumbent_lookup fabrication: attached the sitting officeholder to the race for the office they hold, but they ran for a different office in 2026. Disproved by the CA SoS certified field for BOTH contests.',
         now()
  FROM essentials.race_candidates rc
 WHERE rc.id IN (
   '00113d1f-b168-474c-a425-4d6a7d8b6ce9',  -- Eleni Kounalakis on LT GOVERNOR (she ran for Treasurer)
   '44960ac3-3bb8-4975-996b-bb44f9a0134a'   -- Fiona Ma on TREASURER (she ran for Lt Governor)
 );

DELETE FROM essentials.race_candidates
 WHERE id IN ('00113d1f-b168-474c-a425-4d6a7d8b6ce9','44960ac3-3bb8-4975-996b-bb44f9a0134a');

-- ---------------------------------------------------------------------------------------------------
-- LIEUTENANT GOVERNOR — top-two, 16 candidates
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Lieutenant Governor, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/46-lt-gov.pdf, pp.48 and 51, fetched 2026-08-07). Top-two primary: Fiona Ma (DEM) 1,631,935 / 19.1%; Gloria Romero (REP) 1,521,181 / 17.8%. Both advance to the November 3 2026 general.'
 WHERE id IN (
  'e134566b-9779-4979-9c9d-2ecb43637f45',  -- Fiona Ma        1,631,935  19.1%
  '6de587b4-fc3f-4920-a76c-5eb357e95282'   -- Gloria Romero   1,521,181  17.8%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Lieutenant Governor, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/46-lt-gov.pdf, pp.48 and 51, fetched 2026-08-07). Finished outside the top two of a 16-candidate field.'
 WHERE id IN (
  '8d8e0987-5a50-4321-9b51-04d49de5636f',  -- Josh Fryday          1,256,824  14.7%
  'ac423fb9-f335-47d6-9127-c02f57da45cc',  -- Michael Tubbs        1,132,160  13.3%
  'f3a3c38b-f34e-47f8-b7ab-6d0f95edf089',  -- Oliver Ma              621,147   7.3%
  'a30b03d6-fa0b-4230-a31c-f565e3d8aeb8',  -- David Collenberg       594,336   7.0%
  '1aaa849c-a9c4-4d59-a57d-65af593619a9',  -- David Fennell          521,455   6.1%
  '158f4a71-a2c1-4533-a89f-0eebc85bb382',  -- Skip Shelton           345,324   4.0%
  '59901e2c-c478-487a-b1af-a4306422f7ba',  -- Janelle Kellman        311,237   3.6%
  '59c773c4-64d1-434c-80aa-f21bd6fd07bc',  -- Ebie Lynch             156,714   1.8%
  'ccb11ead-b334-4676-83df-d9cb07a10486',  -- Tim Myers              132,564   1.6%
  '1ab5fbef-a181-499a-b607-c94635ef36f2',  -- Alice Stek             125,100   1.5%
  'cd1f57ff-001f-45d5-9b27-2098860ccc98',  -- Jeyson Lopez            94,058   1.1%
  'a436e986-100e-4e65-91ac-aa327268c927',  -- Abdur Rahman Sikder     51,620   0.6%
  '3048566e-0799-4f49-b94e-301e6c183fdb',  -- Sean Collinson          24,927   0.3%
  '721e7a9f-b0e5-466c-b0a6-71ca16ea01de'   -- Rakesh Christian        12,870   0.2%
 );

-- ---------------------------------------------------------------------------------------------------
-- STATE TREASURER — top-two, 6 candidates
-- ---------------------------------------------------------------------------------------------------
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Treasurer, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/61-treasurer.pdf, p.63, fetched 2026-08-07). Top-two primary: Kounalakis (DEM) 3,154,323 / 36.7%; Hawks (REP) 2,063,253 / 24.0%. Both advance to the November 3 2026 general.'
 WHERE id IN (
  'cdffadbf-ff42-4fbc-8711-f0a9513d9ac5',  -- Eleni Kounalakis  3,154,323  36.7%
  'fc80f907-f0d0-4f29-b92d-b66bde0da58c'   -- Jennifer Hawks    2,063,253  24.0%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Treasurer, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/61-treasurer.pdf, p.63, fetched 2026-08-07). Finished outside the top two of a 6-candidate field.'
 WHERE id IN (
  '41384741-37e3-4e16-8282-9775619ae941',  -- Anna M. Caballero  1,410,005  16.4%
  'c4298104-0fe1-4e41-9047-d740e0245322',  -- David Serpa        1,106,595  12.9%
  '62e27cf6-2806-4f69-91ca-3a3d37395193',  -- Tony Vazquez         609,482   7.1%
  'c9cdbeaa-4fb8-4a03-8af4-653159edb7e7'   -- Glenn Turner         254,085   3.0%
 );
