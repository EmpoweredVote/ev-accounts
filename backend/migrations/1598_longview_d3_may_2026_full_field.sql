-- 1598_longview_d3_may_2026_full_field.sql
--
-- Record the May 2 2026 Longview (TX) Council District 3 primary: 2 existing rows get `runoff`,
-- 3 missing candidates are added as `lost`. 3 politicians + 3 candidate rows added, 2 repaired.
--
--   Rollback:
--     UPDATE essentials.race_candidates SET result=NULL, result_source=NULL, result_recorded_at=NULL
--      WHERE id IN ('f5a5c4fe-9b70-462e-a069-a161ad25211a','2c518637-16df-4033-92f5-263b83fad807');
--     DELETE FROM essentials.race_candidates WHERE politician_id IN
--       ('b99a3cdc-0e58-4227-ba69-0e65989ca91a','69b30806-16cd-49ec-89db-db5f05c39eb9',
--        '5f160c88-b986-4e61-8b7a-f37b720390cb');
--     DELETE FROM essentials.politicians WHERE id IN (the same three);
--
-- ⚠ Applied as `postgres` over the supabase MCP (RLS — see migrations 1593 and 1595).
--
-- Sources, both fetched 2026-08-07:
--   Gregg County Elections, OFFICIAL Cumulative Results Report, "City of Longview District 3
--   Election", 5/2/2026, run 05/11/2026 — 3 of 3 polling places reporting, 532 of 6,030 ballots
--   (8.82% turnout), 531 cast votes + 1 undervote.
--     greggcountyvotes.com/wp-content/uploads/2026/05/2026-May-Official-Cumulative-Results-LVD3.pdf
--   City of Longview, City Elections page, for the runoff rule and the fact a runoff was called:
--   "With no candidate receiving over 50% of the vote for the District 3 Election on May 2, a run-off
--   election is being held between the two candidates who received the highest percentage of votes."
--     longviewtexas.gov/2153/City-Elections
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE FIELD WAS 2 OF 5
-- ---------------------------------------------------------------------------------------------------
-- We held only Smith and Cooper — the two who reached the runoff. The certified field is FIVE names
-- summing to 99.99%, so it is complete as printed:
--
--   Brandon Smith            196   36.91%   -> runoff
--   Marlena Cooper           160   30.13%   -> runoff
--   Brenda J. Woolridge       78   14.69%   -> lost, ADDED here
--   Darrin "Rudy" Rudolph     64   12.05%   -> lost, ADDED here
--   G Floyd                   33    6.21%   -> lost, ADDED here
--
-- Holding only the runoff pair is a specific and misleading shape: it makes a five-way race look
-- like a two-way one, and 175 of 531 votes cast — a third of the electorate's choices — had no row to
-- belong to. It also makes Smith's 36.91% unreadable, because in a two-candidate field a plurality
-- like that is impossible.
--
-- WHY `runoff` AND NOT `won`/`lost`: Texas municipal elections require a MAJORITY, and the city states
-- outright that no candidate cleared 50%, so the top two advanced. Smith's separate `won` and Cooper's
-- `lost` on the June 13 runoff race (election 90a6fe99… is Princeton; Longview's runoff is
-- ee1e4b5e-67fb-4ede-8119-d42ff723d033) are already recorded and remain correct — `result` is per-race,
-- not per-person.
--
-- ⚠ Marlena Cooper's row has politician_id NULL and is left that way. Creating a person record for her
-- is a separate decision from recording the result, and inventing one here would be a silent change to
-- who exists in the corpus.
-- ---------------------------------------------------------------------------------------------------

BEGIN;

-- is_incumbent stated explicitly: the column DEFAULTS TO TRUE and all three lost.
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, source, is_incumbent, is_active)
VALUES
  ('b99a3cdc-0e58-4227-ba69-0e65989ca91a', 'Brenda J. Woolridge',   'Brenda', 'Woolridge', 'greggcountyvotes-2026', false, true),
  ('69b30806-16cd-49ec-89db-db5f05c39eb9', 'Darrin "Rudy" Rudolph', 'Darrin', 'Rudolph',   'greggcountyvotes-2026', false, true),
  ('5f160c88-b986-4e61-8b7a-f37b720390cb', 'G Floyd',               'G',      'Floyd',     'greggcountyvotes-2026', false, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source,
   result, result_recorded_at, result_source)
VALUES
  ('e6a641fa-e158-4435-a86d-86f936f83b01', 'b99a3cdc-0e58-4227-ba69-0e65989ca91a',
   'Brenda J. Woolridge', 'Brenda', 'Woolridge', false, 'active', 'greggcountyvotes-2026',
   'lost', '2026-08-07T00:00:00Z',
   'Gregg County Elections OFFICIAL Cumulative Results, City of Longview District 3 Election, May 2 2026 (greggcountyvotes.com/wp-content/uploads/2026/05/2026-May-Official-Cumulative-Results-LVD3.pdf, fetched 2026-08-07). Finished third of five with 78 / 14.69%; did not reach the June 13 2026 runoff.'),
  ('e6a641fa-e158-4435-a86d-86f936f83b01', '69b30806-16cd-49ec-89db-db5f05c39eb9',
   'Darrin "Rudy" Rudolph', 'Darrin', 'Rudolph', false, 'active', 'greggcountyvotes-2026',
   'lost', '2026-08-07T00:00:00Z',
   'Gregg County Elections OFFICIAL Cumulative Results, City of Longview District 3 Election, May 2 2026 (greggcountyvotes.com/wp-content/uploads/2026/05/2026-May-Official-Cumulative-Results-LVD3.pdf, fetched 2026-08-07). Finished fourth of five with 64 / 12.05%; did not reach the June 13 2026 runoff.'),
  ('e6a641fa-e158-4435-a86d-86f936f83b01', '5f160c88-b986-4e61-8b7a-f37b720390cb',
   'G Floyd', 'G', 'Floyd', false, 'active', 'greggcountyvotes-2026',
   'lost', '2026-08-07T00:00:00Z',
   'Gregg County Elections OFFICIAL Cumulative Results, City of Longview District 3 Election, May 2 2026 (greggcountyvotes.com/wp-content/uploads/2026/05/2026-May-Official-Cumulative-Results-LVD3.pdf, fetched 2026-08-07). Finished fifth of five with 33 / 6.21%; did not reach the June 13 2026 runoff.')
ON CONFLICT DO NOTHING;

UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Gregg County Elections OFFICIAL Cumulative Results, City of Longview District 3 Election, May 2 2026 (greggcountyvotes.com/wp-content/uploads/2026/05/2026-May-Official-Cumulative-Results-LVD3.pdf, fetched 2026-08-07): Smith 196 / 36.91%; Cooper 160 / 30.13% of a 5-candidate field. No candidate reached a majority, so the top two advanced to the June 13 2026 runoff — per the City of Longview (longviewtexas.gov/2153/City-Elections, fetched 2026-08-07): "With no candidate receiving over 50% of the vote for the District 3 Election on May 2, a run-off election is being held between the two candidates who received the highest percentage of votes."'
 WHERE id IN (
  'f5a5c4fe-9b70-462e-a069-a161ad25211a',  -- Brandon Smith   196  36.91%
  '2c518637-16df-4033-92f5-263b83fad807'   -- Marlena Cooper  160  30.13%
 );

COMMIT;
