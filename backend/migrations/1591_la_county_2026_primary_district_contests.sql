-- 1591_la_county_2026_primary_district_contests.sql
--
-- Record the three district contests on the 2026 LA County Primary election: CA State Assembly
-- District 55 (4 rows), CA State Senate District 26 (8), U.S. Representative District 34 (6).
-- 18 candidate rows.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 18 ids below>);
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1591_la_county_2026_primary_district_contests.sql`.
--
-- Source: California Secretary of State, Statement of Vote, Primary Election June 2, 2026,
-- DISTRICT TOTALS (all fetched 2026-08-07; SoS certified the primary 2026-07-10) --
--   U.S. Representative by District .. elections.cdn.sos.ca.gov/sov/2026-primary/sov/76-us-rep.pdf
--   State Senator by District ........ elections.cdn.sos.ca.gov/sov/2026-primary/sov/90-state-senator.pdf (District 26 on p.93)
--   State Assemblymember by District . elections.cdn.sos.ca.gov/sov/2026-primary/sov/95-state-assembly.pdf
--   Machine-readable .xlsx siblings of the same three files were used to cross-check the numbers.
--
-- ---------------------------------------------------------------------------------------------------
-- THE ASSUMPTION MIGRATIONS 1585 AND 1589 LEFT OPEN, NOW CHECKED
-- ---------------------------------------------------------------------------------------------------
-- These three districts LOOK wholly contained in LA County, which would make the LA County canvass a
-- complete source for them. That was flagged as "must be CHECKED, not assumed". It is now checked and
-- it holds: in the SoS district tables each of the three contests has exactly ONE county row, "Los
-- Angeles", and the District Totals line equals that row. No other county contributes a vote, so no
-- statewide/multi-county aggregation problem exists here.
--
-- The numbers below are nonetheless taken from the SoS DISTRICT TOTALS rather than the county file,
-- because the SoS table is the authority for a district contest and agreed with it.
--
-- A PARSING TRAP WORTH RECORDING: in the .xlsx, State Senate District 26 spills into a second panel
-- holding a single candidate, and that candidate's NAME AND PARTY did not survive extraction -- the
-- cells came through as bare numbers while the vote total (10,199) came through fine. Only the PDF
-- (p.93) identifies him: Sang "Sam Shin" Masog (REP). A pipeline that trusted the spreadsheet alone
-- would have recorded a real vote total against no one, or dropped an 8th candidate whose votes are
-- inside the denominator. The percentages only reconcile to 100% with him included.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

-- ---------------------------------------------------------------------------------------------------
-- CA STATE ASSEMBLY DISTRICT 55 -- partisan top-two, 4 candidates, 122,993 votes
-- ---------------------------------------------------------------------------------------------------
-- Bryan took 64.6%, an outright majority, and still only `advanced` -- the Bonta rule from 1585.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, State Assemblymember by District, 55th Assembly District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/95-state-assembly.pdf, fetched 2026-08-07). Top-two primary: Bryan (DEM, inc) 79,396 / 64.6%; Brown (DEM) 23,242 / 18.9%. Both advance to the November 3 2026 general. District lies wholly within LA County.'
 WHERE id IN (
  '695fdcb0-fe58-433e-b71a-7b5101ba2219',  -- Isaac G. Bryan    79,396  64.6%
  'bb984714-2a04-4feb-b722-7a6deafedd87'   -- Ashley M. Brown   23,242  18.9%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, State Assemblymember by District, 55th Assembly District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/95-state-assembly.pdf, fetched 2026-08-07). Finished outside the top two of a 4-candidate field.'
 WHERE id IN (
  'cea1506a-d019-481d-8cdd-c853dd6f53b6',  -- Keith G. Cascio (REP)             18,847  15.3%
  'e41cbb4d-a587-443d-8df5-8970351df5b1'   -- William "Billion" Campbell (NPP)   1,508   1.2%
 );

-- ---------------------------------------------------------------------------------------------------
-- CA STATE SENATE DISTRICT 26 -- partisan top-two, 8 candidates, 175,781 votes
-- ---------------------------------------------------------------------------------------------------
-- An open seat with six Democrats on the ballot; two of them took the top two places.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, State Senator by District, 26th State Senate District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/90-state-senator.pdf p.93, fetched 2026-08-07). Top-two primary: Hernandez (DEM) 54,799 / 31.2%; Rascon (DEM) 34,158 / 19.4%. Both advance to the November 3 2026 general. District lies wholly within LA County.'
 WHERE id IN (
  '240be7d9-2c5a-40de-9448-514f740999a7',  -- Sara Hernandez  54,799  31.2%
  'ac1aba5c-24d5-41aa-b1bc-92a2b19a7405'   -- Sarah Rascon    34,158  19.4%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, State Senator by District, 26th State Senate District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/90-state-senator.pdf p.93, fetched 2026-08-07). Finished outside the top two of an 8-candidate field.'
 WHERE id IN (
  '43b0aa08-f197-48ee-b1c0-762faa7cb03c',  -- Wendy Carrillo (DEM)            24,111  13.7%
  '3d42abc6-3741-4d8f-9cc5-2e70683df16d',  -- Maebe Pudlo (DEM)               22,886  13.0%
  '61933f4f-7ad2-44f5-8467-eea925dff7be',  -- Claudia Agraz (REP)             13,736   7.8%
  '92a601c8-ba68-4d18-acc4-5554ea885b88',  -- Juan Camacho (DEM)              13,392   7.6%
  'ef7d617d-ea35-4f57-b4ee-8007cfcc835e',  -- Sang "Sam Shin" Masog (REP)     10,199   5.8%
  '63dca4cd-d224-4195-81a8-9547e3dd009e'   -- Paul A. Bowers (DEM)             2,500   1.4%
 );

-- ---------------------------------------------------------------------------------------------------
-- U.S. REPRESENTATIVE DISTRICT 34 -- partisan top-two, 6 candidates, 119,585 votes
-- ---------------------------------------------------------------------------------------------------
-- Gomez led with 46.0%, short of a majority; irrelevant either way under top-two, but it means the
-- November general is a genuine contest rather than a formality.
UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, United States Representative in Congress by District, 34th Congressional District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/76-us-rep.pdf, fetched 2026-08-07). Top-two primary: Gomez (DEM, inc) 54,993 / 46.0%; Gonzales-Torres (DEM) 36,708 / 30.7%. Both advance to the November 3 2026 general. District lies wholly within LA County.'
 WHERE id IN (
  'c24c8326-e0a3-4f5f-bd2c-b0ce240c2aed',  -- Jimmy Gomez              54,993  46.0%
  'b31da936-3dd4-4b90-85a7-7e9ec70de52d'   -- Angela Gonzales-Torres   36,708  30.7%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, United States Representative in Congress by District, 34th Congressional District Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/76-us-rep.pdf, fetched 2026-08-07). Finished outside the top two of a 6-candidate field.'
 WHERE id IN (
  '14d5a59d-cbf1-4ea1-a7ca-925cb7fad186',  -- Calvin Lee (REP)                16,321  13.6%
  '5d275e89-1706-418e-b772-4e2a4a61cca9',  -- Robert George Lucero Jr. (DEM)   6,144   5.1%
  '98c8629a-2a62-437b-8acc-4749cf97292e',  -- Arthur Dixon (DEM)               4,103   3.4%
  '29c6346b-4f2d-4d7f-908e-c418fc25fd29'   -- Loren Colin (NPP)                1,316   1.1%
 );

COMMIT;
