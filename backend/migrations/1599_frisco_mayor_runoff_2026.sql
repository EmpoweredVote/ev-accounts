-- 1599_frisco_mayor_runoff_2026.sql
--
-- Seed the June 13 2026 Frisco (TX) mayoral runoff, which had no race row: 1 election + 1 race +
-- 2 candidate rows. Closes the "Frisco Mayor runoff which has no race row" item.
--
--   Rollback:
--     DELETE FROM essentials.race_candidates WHERE race_id='33db10de-c9d3-4cd9-b6a3-24e396b048b4';
--     DELETE FROM essentials.races     WHERE id='33db10de-c9d3-4cd9-b6a3-24e396b048b4';
--     DELETE FROM essentials.elections WHERE id='6f57a94b-6638-4c10-9c4b-1c5ed2dca9bb';
--
-- ⚠ Applied as `postgres` over the supabase MCP (RLS — see migrations 1593 and 1595).
--
-- Source (fetched 2026-08-07): CITY OF FRISCO ORDINANCE NO. 2026-06-43, "AN ORDINANCE ... CANVASSING
-- THE ELECTION RETURNS OF THE JUNE 13, 2026, RUNOFF ELECTION ... DECLARING THE RESULTS", adopted at
-- the June 23 2026 council meeting. Section 2: "The returns of the Runoff Election as set forth herein
-- are declared to be official. Accordingly, Mark Hill is hereby declared elected as mayor of the City
-- of Frisco."
--   friscotexas.gov/DocumentCenter/View/42402/Ordinance-Canvassing-the-June-2026-Runoff-Election52029571---Final-Totals-Signed
-- Corroborated by the city's Final Canvass Totals sheet (updated 6/23/2026, "REPORTING IS FINAL"):
--   friscotexas.gov/DocumentCenter/View/42403/June-13-2026-Runoff-Election-Final-Canvass-Results_23-June-2026
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE TWO-COUNTY TRAP — WHY THE OBVIOUS SOURCE WAS THE WRONG ONE
-- ---------------------------------------------------------------------------------------------------
-- The convenient source for this was a Collin County all-races precinct CSV, whose COUNTY TOTALS row
-- gives Hill 10,963 and Vilhauer 6,718. Those numbers are WRONG for this contest, and not by a little:
--
--   Collin CSV county totals ....... Hill 10,963  Vilhauer  6,718   (17,681 votes)
--   Frisco canvass, citywide ....... Hill 19,688  Vilhauer 14,162   (33,850 votes)
--
-- FRISCO SPANS COLLIN AND DENTON COUNTIES. The canvassing ordinance says so explicitly — the election
-- "was administered by the Collin County Elections Administrator and the Denton County Elections
-- Administrator", with the two counties' returns attached as Exhibit A and Exhibit B. The city's
-- canvass sheet puts Denton at 16,175 of 33,871 ballots cast: 48% of the electorate. A Collin-only
-- figure omits nearly half the votes.
--
-- This is the same error class as reading LA County's share of a statewide California contest
-- (migrations 1585, 1590). The winner happens to survive it here — Hill leads in both — but the vote
-- totals would have been off by 8,725 and 7,444, and nothing about a county subtotal guarantees the
-- leader is the same as citywide.
--
-- 🔑 THE RULE: for a city that straddles a county line, the CITY's canvass is the authority, never one
-- county's return. Frisco is the known instance in this corpus.
--
-- ▶ FOLLOW-UP OWED, NOT FIXED HERE. The MAY 2 2026 Frisco Mayor rows (race
-- 19a1cb6f-8d7c-4f24-9efb-205003f96f9d) carry exactly this defect: their result_source quotes
-- "Mark Hill 4,803 (36.94%), Rod Vilhauer 3,702 (28.47%)" from the Collin County summary report, which
-- is Collin's share only. The `runoff` and `lost` VALUES are still correct — Hill and Vilhauer did
-- advance, and Keating and Sowell did not — so nothing voter-facing is false. But the quoted numbers
-- understate the contest and should be replaced with the city's May canvass figures. Not done here
-- because the city's May canvass document was not located; the runoff pages are at friscotexas.gov/1962
-- and the May equivalent was not found by page-ID probing. Do not "fix" it by scaling the Collin
-- numbers.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

INSERT INTO essentials.elections (id, name, election_date, election_type, jurisdiction_level, state, description)
VALUES ('6f57a94b-6638-4c10-9c4b-1c5ed2dca9bb', 'Frisco TX Mayor Runoff 2026', '2026-06-13',
        'special', 'city', 'TX',
        'Runoff for Mayor of Frisco. No candidate reached a majority in the May 2 2026 general election, so the top two advanced; City Council confirmed the runoff on May 12 2026. Administered jointly by the Collin and Denton County Elections Administrators. Canvassed by Ordinance 2026-06-43 on June 23 2026. Term of three years.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description)
VALUES ('33db10de-c9d3-4cd9-b6a3-24e396b048b4', '6f57a94b-6638-4c10-9c4b-1c5ed2dca9bb',
        '2087a453-d1c4-47ab-904d-13ca58118fd1', 'Frisco Mayor', NULL, 1,
        'June 13 2026 runoff between the top two finishers in the May 2 2026 Frisco mayoral general election.')
ON CONFLICT DO NOTHING;

-- politician_id left NULL to match every existing Frisco Mayor candidate row on the May race, which
-- are all NULL. Creating person records is a separate decision from recording a result.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source,
   result, result_recorded_at, result_source)
VALUES
  ('33db10de-c9d3-4cd9-b6a3-24e396b048b4', NULL,
   'Mark Hill', 'Mark', 'Hill', false, 'active', 'friscotexas-canvass-2026',
   'won', '2026-08-07T00:00:00Z',
   'City of Frisco Ordinance No. 2026-06-43, canvassing the June 13 2026 runoff election, adopted June 23 2026 (friscotexas.gov/DocumentCenter/View/42402/Ordinance-Canvassing-the-June-2026-Runoff-Election52029571---Final-Totals-Signed, fetched 2026-08-07). Mark Hill 19,688 / 58.16%; Rod Vilhauer 14,162 / 41.84%. Section 2: "The returns of the Runoff Election as set forth herein are declared to be official. Accordingly, Mark Hill is hereby declared elected as mayor of the City of Frisco." CITYWIDE totals: the election was administered by both the Collin and Denton County Elections Administrators, Denton supplying 16,175 of 33,871 ballots cast.'),
  ('33db10de-c9d3-4cd9-b6a3-24e396b048b4', NULL,
   'Rod Vilhauer', 'Rod', 'Vilhauer', false, 'active', 'friscotexas-canvass-2026',
   'lost', '2026-08-07T00:00:00Z',
   'City of Frisco Ordinance No. 2026-06-43, canvassing the June 13 2026 runoff election, adopted June 23 2026 (friscotexas.gov/DocumentCenter/View/42402/Ordinance-Canvassing-the-June-2026-Runoff-Election52029571---Final-Totals-Signed, fetched 2026-08-07). Rod Vilhauer 14,162 / 41.84% against Mark Hill 19,688 / 58.16%. CITYWIDE totals covering both Collin and Denton counties.')
ON CONFLICT DO NOTHING;

COMMIT;
