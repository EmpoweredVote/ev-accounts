-- 1590_ca_statewide_2026_primary_controller_ic_spi.sql
--
-- Remove two more `incumbent_lookup` fabricated candidacies, then record the last three California
-- statewide contests on the 2026 LA County Primary election: Controller (3 rows), Insurance
-- Commissioner (11), Superintendent of Public Instruction (10). 24 rows recorded, 2 rows deleted.
--
--   Rollback: the two deleted rows are archived in full in essentials._fabricated_1590_removed.
--             UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 24 ids below>);
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1590_ca_statewide_2026_primary_controller_ic_spi.sql`.
--
-- Source: California Secretary of State, Statement of Vote, Primary Election June 2, 2026 —
--   Controller ............. elections.cdn.sos.ca.gov/sov/2026-primary/sov/58-sco.pdf  (State Totals, p.60)
--   Insurance Commissioner . elections.cdn.sos.ca.gov/sov/2026-primary/sov/67-ic.pdf   (State Totals, pp.69 and 72)
--   Superintendent ......... elections.cdn.sos.ca.gov/sov/2026-primary/sov/113-spi.pdf (State Totals, pp.115 and 118)
--   Governor (used only as disproof) .. sov/19-gov.pdf and sov/19-gov.xlsx (State Totals)
--   All fetched 2026-08-07. SoS certified the primary 2026-07-10.
--
-- Continues migration 1585, which recorded Attorney General and Secretary of State from the same
-- source. As there, the LA County canvass is NOT usable for these contests: California's top-two is
-- decided on STATEWIDE totals and the county file reports only LA's share.
--
-- Contests with many candidates are printed in PANELS, and the State Totals row repeats once per
-- panel -- Insurance Commissioner needed pp.69 and 72, Superintendent pp.115 and 118. Reading only
-- the first panel would silently drop the tail of the field.
--
-- ---------------------------------------------------------------------------------------------------
-- TWO MORE `incumbent_lookup` FABRICATIONS -- THE SAME GENERATOR AS MIGRATION 1588
-- ---------------------------------------------------------------------------------------------------
-- Both contests had ONE MORE candidate row in our data than the certified field contains, and in both
-- cases the extra row was the sitting officeholder, sourced `incumbent_lookup`:
--
--   Insurance Commissioner .. we had 12 rows; the certified field is ELEVEN names. Extra: Ricardo Lara.
--   Superintendent .......... we had 11 rows; the certified field is TEN names.    Extra: Tony Thurmond.
--
-- The count is not the proof on its own -- the proof is that in each contest the certified percentages
-- sum to ~100% (11 names -> 99.9%, 10 names -> 99.9%), so the printed field is the WHOLE ballot and
-- there is no room for a twelfth or eleventh candidate. Each is then independently disproved:
--
--   * TONY THURMOND ran for GOVERNOR. He is in the certified Governor field with 63,762 / 0.7%
--     statewide. A person cannot be on two statewide ballots in one election -- this is exactly the
--     Fiona Ma / Eleni Kounalakis situation resolved in migration 1588: positively documented on a
--     DIFFERENT ballot in the SAME election.
--   * RICARDO LARA was constitutionally INELIGIBLE. Cal. Const. art. V (Prop 140) limits the
--     Insurance Commissioner to two terms; Lara was elected in 2018 and 2022 and is termed out. He
--     could not appear on this ballot, so the candidacy was impossible, not merely unattested.
--
-- `not_nominated` is the WRONG value for both -- it asserts a person ran and failed to be nominated.
-- Neither ran. Following 1588, the rows are deleted and archived rather than annotated.
--
-- WHY THIS IS A DELETE AND SCHMERELSON (migration 1588) IS STILL `not_nominated`: the rule 1588 drew
-- is that a delete needs POSITIVE disproof of the candidacy, not mere absence from one field.
-- Schmerelson has absence only. Thurmond has a different ballot; Lara has a legal bar. Both clear the
-- bar Schmerelson does not.
--
-- THE `incumbent_lookup` AUDIT FOR THIS ELECTION IS NOW COMPLETE. Of the 14 rows it generated, 4 were
-- fabrications (Ma and Kounalakis in 1588, Lara and Thurmond here). The other 10 are genuine
-- candidacies confirmed against the certified fields: Bonta, Weber, Cohen, Bryan, Gomez, Prang, Luna,
-- Melvoin, Gonez, and Schmerelson (held as `not_nominated`). No `incumbent_lookup` row on this
-- election is left unexamined.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

CREATE TABLE IF NOT EXISTS essentials._fabricated_1590_removed AS
  SELECT rc.*, NULL::text AS reason, now() AS removed_at
  FROM essentials.race_candidates rc WHERE false;

INSERT INTO essentials._fabricated_1590_removed
  SELECT rc.*,
         'incumbent_lookup fabrication: attached the sitting officeholder to the race for the office they hold. Ricardo Lara was termed out under Cal. Const. art. V and legally could not appear; Tony Thurmond appears in the certified Governor field (63,762 / 0.7%). Both certified fields account for ~100% of the vote without them.',
         now()
  FROM essentials.race_candidates rc
 WHERE rc.id IN (
   '4d6c9543-937e-4334-89bd-75500b0f3a03',  -- Ricardo Lara  on INSURANCE COMMISSIONER (termed out)
   '42b94789-52d0-4469-9d26-72a706fce34a'   -- Tony Thurmond on SUPERINTENDENT (he ran for Governor)
 );

DELETE FROM essentials.race_candidates
 WHERE id IN ('4d6c9543-937e-4334-89bd-75500b0f3a03','42b94789-52d0-4469-9d26-72a706fce34a');

-- ---------------------------------------------------------------------------------------------------
-- CONTROLLER -- partisan top-two, 3 candidates
-- ---------------------------------------------------------------------------------------------------
-- Cohen took 56.8%, an outright majority, and STILL only `advanced`. Same rule as Bonta in 1585:
-- a top-two primary offers no outright win, so `won` would falsely assert she holds the office.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Controller, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/58-sco.pdf p.60, fetched 2026-08-07). Top-two primary: Cohen (DEM, inc) 4,909,613 / 56.8%; Morgan (REP) 3,244,252 / 37.5%. Both advance to the November 3 2026 general.'
 WHERE id IN (
  'ba525e68-8c84-4a2d-aa4a-afa90106cbd2',  -- Malia M. Cohen  4,909,613  56.8%
  'e8e7b2c5-19e0-4777-9449-a82931adf8bd'   -- Herb W Morgan   3,244,252  37.5%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Controller, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/58-sco.pdf p.60, fetched 2026-08-07). Finished third of three with 489,663 / 5.7%; did not reach the top two.'
 WHERE id = '7d434335-da68-4662-9203-922bd4d2c695';  -- Meghann Adams (PF) 489,663  5.7%

-- ---------------------------------------------------------------------------------------------------
-- INSURANCE COMMISSIONER -- partisan top-two, 11 candidates
-- ---------------------------------------------------------------------------------------------------
-- NOTE FOR THE NEXT READER: two DEMOCRATS advanced and no Republican did. That is a correct top-two
-- outcome, not a parsing error. The Republican vote split five ways (Korsgaden 15.5%, Howell 7.6%,
-- Farren 6.7%, Lee 5.4%, Aarnio 1.9%) while the top Democrat consolidated 27.4%.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Insurance Commissioner, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/67-ic.pdf pp.69 and 72, fetched 2026-08-07). Top-two primary: Kim (DEM) 2,328,836 / 27.4%; Allen (DEM) 1,649,501 / 19.4%. Both advance to the November 3 2026 general; no Republican reached the top two.'
 WHERE id IN (
  'd24de84a-78e1-4838-88a5-2b758ff99391',  -- Jane Kim   2,328,836  27.4%
  '7e051229-78ac-4d73-842c-a570c108b4a5'   -- Ben Allen  1,649,501  19.4%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Insurance Commissioner, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/67-ic.pdf pp.69 and 72, fetched 2026-08-07). Finished outside the top two of an 11-candidate field.'
 WHERE id IN (
  'b89d2130-4a3f-483d-9a51-38bc8224d647',  -- Stacy A. Korsgaden     1,320,966  15.5%
  'a1c75c7e-2c3c-4b0d-a587-782be8b3fa70',  -- Robert P Howell         649,093   7.6%
  'e976d954-cfd1-43b1-8a24-54479877c680',  -- Patrick Wolff           615,069   7.2%
  '87a29ed4-cddc-45a0-985b-ee11d03cf1bf',  -- Merritt Farren          570,669   6.7%
  '17ab0959-f78f-4b3f-90e5-9c778283fa16',  -- Sean Lee                458,056   5.4%
  '6eddc523-7e09-4c0c-b2bf-b8fa2619844f',  -- Steven Craig Bradford   416,998   4.9%
  '3fed1c35-5ed5-4d27-a0eb-e451cfdd3167',  -- Eduardo "Lalo" Vargas   248,039   2.9%
  '785a028f-62e5-4032-8858-b7089859fb6d',  -- Eric Thor Aarnio        158,603   1.9%
  '998fb6e4-2d65-4ecd-921f-6f6d5cf3b7a3'   -- Keith W. Davis           83,994   1.0%
 );

-- ---------------------------------------------------------------------------------------------------
-- SUPERINTENDENT OF PUBLIC INSTRUCTION -- NONPARTISAN, 10 candidates
-- ---------------------------------------------------------------------------------------------------
-- Migration 1585 flagged this contest as the one place the top-two rule must NOT be applied blindly:
-- Superintendent is nonpartisan, so a candidate clearing 50% in June wins outright and the value would
-- be `won`. CHECKED AGAINST THE COUNT: nobody came close. Shaw led with 22.6%, so there is no majority
-- winner and the top two advance to the November runoff. `advanced` is correct here -- the warning
-- fires only on a majority, and there is none.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Superintendent of Public Instruction, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/113-spi.pdf pp.115 and 118, fetched 2026-08-07). Nonpartisan contest: no candidate reached a majority (Shaw 1,737,735 / 22.6%; Barrera 1,558,298 / 20.3%), so the top two advance to the November 3 2026 general.'
 WHERE id IN (
  '4939c2c8-9bc4-4524-bdaf-daadff60f38c',  -- Sonja Shaw       1,737,735  22.6%
  '3ddafab8-4d1c-4a32-81e5-c60d2557527c'   -- Richard Barrera  1,558,298  20.3%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Superintendent of Public Instruction, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/113-spi.pdf pp.115 and 118, fetched 2026-08-07). Finished outside the top two of a 10-candidate nonpartisan field.'
 WHERE id IN (
  '462cbf4a-acbc-48e2-90e9-a6688d524b40',  -- Nichelle M. Henderson  738,236  9.6%
  'fa40eab6-4a7b-4a4a-a41b-7e0cfe65784a',  -- Wendy Castaneda Leal   675,968  8.8%
  '3118de3f-cd60-43c1-9881-732f35704ae9',  -- Al Muratsuchi          646,329  8.4%
  'e3608a43-7c24-49c1-a7b4-5b6c5ba92774',  -- Anthony Rendon         624,266  8.1%
  'f79bdac9-6eb5-4057-a027-8a5fc9402e85',  -- Frank Lara             578,171  7.5%
  '4920cf93-0e17-49ab-8ea8-0d65fa183f0a',  -- Josh Newman            522,758  6.8%
  '7504c634-3d35-49cc-9ad3-e6c5b6471f0d',  -- Ainye Long             426,104  5.6%
  '9112a4cc-0027-4e73-a940-d4b317c6703b'   -- Gus Mattammal          167,723  2.2%
 );

-- Frank Lara (Superintendent) and Ricardo Lara (Insurance Commissioner, deleted above) are DIFFERENT
-- people. Frank Lara is a real candidate and keeps his `lost`.

COMMIT;
