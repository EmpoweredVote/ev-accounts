-- 1585_ca_statewide_2026_primary_ag_sos.sql
--
-- Record the two California statewide contests whose STATEWIDE totals have been read in full:
-- Attorney General and Secretary of State. 7 candidate rows.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 7 ids below>);
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1585_ca_statewide_2026_primary_ag_sos.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THESE ARE A SEPARATE MIGRATION FROM 1583/1584
-- ---------------------------------------------------------------------------------------------------
-- These contests sit on the "2026 LA County Primary" election row, but they are STATEWIDE offices and
-- California's top-two is decided on statewide totals. The LA County canvass used in migrations 1583
-- and 1584 reports only LA's share — for Attorney General it shows Bonta 1,305,327 against a
-- statewide 4,979,967. Using it would have been a confident, wrong answer about who advances.
--
-- Source: California Secretary of State, Statement of Vote, Primary Election June 2, 2026 —
--   Attorney General .... elections.cdn.sos.ca.gov/sov/2026-primary/sov/64-ag.pdf   (State Totals, p.66)
--   Secretary of State .. elections.cdn.sos.ca.gov/sov/2026-primary/sov/55-sos.pdf  (State Totals, p.57)
--   Both fetched 2026-08-07. SoS certified the primary 2026-07-10.
--
-- THE RULE: these are partisan statewide offices under California's top-two primary. The top two
-- finishers advance to November REGARDLESS of party and regardless of majority — there is no outright
-- win available here, which is why `advanced` and not `won` is the correct value even for Bonta at
-- 56.6%. `won` would assert he holds the office; he has only reached the general election.
-- ---------------------------------------------------------------------------------------------------

UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Attorney General, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/64-ag.pdf, fetched 2026-08-07). Top-two primary: Bonta (DEM, inc) 4,979,967 / 56.6%; Gates (REP) 3,337,433 / 37.9%. Both advance to the November 3 2026 general.'
 WHERE id IN (
  '52077105-6ab1-4342-b902-c49df02fc0f5',  -- Rob Bonta        4,979,967  56.6%
  '4409cfaa-13e8-4ab3-ac8e-b318fa02a9bf'   -- Michael E. Gates 3,337,433  37.9%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Attorney General, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/64-ag.pdf, fetched 2026-08-07). Finished third of three with 478,450 / 5.4%; did not reach the top two.'
 WHERE id = '5b15e1f5-be22-488c-8850-9a805f8d2587';  -- Marjorie Mikels (GRN) 478,450  5.4%

UPDATE essentials.race_candidates SET result='advanced', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Secretary of State, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/55-sos.pdf, fetched 2026-08-07). Top-two primary: Weber (DEM, inc) 5,092,491 / 58.7%; Wagner (REP) 3,187,180 / 36.7%. Both advance to the November 3 2026 general.'
 WHERE id IN (
  '95f16413-5a78-4862-ba64-7f86417328f0',  -- Shirley N. Weber   5,092,491  58.7%
  '91bb3edc-7e11-4656-a333-387d5896330a'   -- Donald P. Wagner   3,187,180  36.7%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='CA Secretary of State Statement of Vote, June 2 2026 Primary, Secretary of State, State Totals (elections.cdn.sos.ca.gov/sov/2026-primary/sov/55-sos.pdf, fetched 2026-08-07). Did not reach the top two: Feinstein (GRN) 207,602 / 2.4%; Blenner (GRN) 187,925 / 2.2%.'
 WHERE id IN (
  '2fd15e57-6383-4478-927d-f69bf395efb0',  -- Michael Feinstein  207,602  2.4%
  '0d592ca7-2eb9-422d-bb23-696f846b0077'   -- Gary N. Blenner    187,925  2.2%
 );

-- ---------------------------------------------------------------------------------------------------
-- ▶ REMAINING ON THIS ELECTION — exactly what is left and where to get it
-- ---------------------------------------------------------------------------------------------------
-- Five statewide contests, same source pattern, State Totals on the final page of each PDF:
--   Controller (3 rows) ........ sov/58-sco.pdf
--   Treasurer (7 rows) ......... sov/61-treasurer.pdf
--   Lieutenant Governor (17) ... sov/46-lt-gov.pdf
--   Insurance Commissioner (12)  sov/67-ic.pdf
--   Superintendent of Public Instruction (11) ... sov/113-spi.pdf
--
-- ⚠️ SUPERINTENDENT IS NOT A TOP-TWO CONTEST. It is NONPARTISAN, so >50% in June is an outright win
-- and the value is `won`, not `advanced`. Applying the top-two rule to it would be the same class of
-- error as reading LA's county share for a statewide office.
--
-- Three district contests are also unrecorded. All three appear to lie wholly within LA County, so
-- the LA canvass may be complete for them — but that must be CHECKED, not assumed, against the SoS
-- district totals before use:
--   CA State Assembly District 55 (4 rows) · CA State Senate District 26 (8) · U.S. Rep District 34 (6)
--
-- 🔴 A DEFECT TO RESOLVE FIRST: `Fiona Ma` and `Eleni Kounalakis` each appear as candidates in BOTH
-- the Lieutenant Governor race AND the State Treasurer race on this election. They cannot be running
-- for both. Ma is the sitting Treasurer and Kounalakis the sitting Lieutenant Governor, so a
-- roster-derived cross-listing is the likely cause — the same shape as the five `la_roster` Board of
-- Supervisors shells found in migration 1583. Whichever of the two races is wrong will produce a
-- fabricated candidacy if results are written to it. Resolve the cross-listing BEFORE recording
-- Lieutenant Governor or Treasurer.
