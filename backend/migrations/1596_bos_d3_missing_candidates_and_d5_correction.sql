-- 1596_bos_d3_missing_candidates_and_d5_correction.sql
--
-- Complete the LA County Board of Supervisors District 3 field (2 missing candidates), and correct the
-- record on District 5, which migration 1589 wrongly said was up for election in 2026.
--
--   Rollback:
--     DELETE FROM essentials.race_candidates
--      WHERE politician_id IN ('1a3d5268-3f89-4e9e-a200-055ffdfbed7d','0e771fec-1763-4405-974f-4beabad6538b');
--     DELETE FROM essentials.politicians WHERE id IN (the same two);
--     UPDATE essentials._retired_1589_races SET reason = split_part(reason, ' || CORRECTED', 1);
--
-- ⚠ Applied as `postgres` over the supabase MCP (RLS — see migrations 1593 and 1595).
--
-- Source: LA County Registrar-Recorder certified results for June 2 2026,
-- results.lavote.gov/text-results/4338 (certified 2026-06-26, fetched 2026-08-07).
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 DISTRICT 5 IS NOT UP IN 2026. DO NOT SEED IT.
-- ---------------------------------------------------------------------------------------------------
-- Migration 1589 retired five synthetic `la_roster` Board of Supervisors shells and, in doing so,
-- asserted: "D2 and D4 are not up in 2026 at all (LA elects 1/3/5 in gubernatorial years, 2/4 in
-- presidential). D5 is up, but the shell showed the incumbent as sole candidate." It then recorded
-- "OWED: District 5 needs a real candidate field before November."
--
-- THAT IS WRONG, and the TODO it left behind was an instruction to fabricate a race. Three independent
-- confirmations:
--
--   1. THE CERTIFIED CANVASS. It contains exactly TWO supervisorial contests -- "SUPERVISOR 1ST
--      DISTRICT" and "SUPERVISOR 3RD DISTRICT". There is no 5th District contest anywhere in it, and
--      the county file is the complete record of what was on the ballot.
--   2. THE INCUMBENT'S TERM. Kathryn Barger (D5) won re-election OUTRIGHT in the March 5 2024 primary,
--      which cancelled that general election. Her term runs to 2028, and it is her third and final one
--      under the county's three-term limit.
--   3. THE CYCLE ITSELF. The real split is D1 and D3 in gubernatorial years (2022, 2026); D2, D4 AND
--      D5 in presidential years (2024, 2028). Barger 2016/2020/2024 and Hahn 2016/2020/2024 both sit
--      on the presidential cycle, so "1/3/5" was never the pattern.
--
-- So there is nothing to seed for D5 before November 2026 or at all this cycle. Retiring its shell in
-- 1589 was correct; the reason given for keeping the door open was not. The `_retired_1589_races`
-- annotation is amended below rather than overwritten, so the original wording survives next to the
-- correction -- someone reading the archive should see both.
--
-- 🔑 THE PATTERN THIS BELONGS TO. 1589 removed fabricated races and simultaneously wrote a fabricated
-- premise into its own explanation, which then propagated into the session handoff and came back as a
-- request to seed the race. A staggered-term claim is checkable in one place -- the certified list of
-- contests -- so check it there before believing a seat is up.
--
-- ---------------------------------------------------------------------------------------------------
-- DISTRICT 3 -- two candidates were missing
-- ---------------------------------------------------------------------------------------------------
-- Certified D3 field is FOUR names summing to 100.01%; we held three. Missing: Carmenlina Minasyan
-- (9.22%) and Tomas Sidenfaden (8.16%). Horvath's 66.35% is an outright majority in a nonpartisan
-- county primary, so her `won` is already correct and no runoff exists -- these two are `lost`, not
-- `not_nominated`: they appeared on the ballot and were beaten.
--
-- (District 1 needs nothing: its certified field of five sums to 100.00% and all five are recorded,
-- alongside James Aldana as `not_nominated`. Durazo won outright with 60.58%.)
--
-- `Tomas` is stored without the diacritic to match the plain-ASCII convention of the surrounding rows;
-- the canvass prints "TOMÁS SIDENFADEN".
-- ---------------------------------------------------------------------------------------------------

BEGIN;

-- is_incumbent stated explicitly: the column DEFAULTS TO TRUE and both of these lost.
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, source, is_incumbent, is_active)
VALUES
  ('1a3d5268-3f89-4e9e-a200-055ffdfbed7d', 'Carmenlina Minasyan', 'Carmenlina', 'Minasyan',   'lavote-2026', false, true),
  ('0e771fec-1763-4405-974f-4beabad6538b', 'Tomas Sidenfaden',    'Tomas',      'Sidenfaden', 'lavote-2026', false, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source,
   result, result_recorded_at, result_source)
VALUES
  ('a30bed88-846a-4bef-84f1-bb348d17bc17', '1a3d5268-3f89-4e9e-a200-055ffdfbed7d',
   'Carmenlina Minasyan', 'Carmenlina', 'Minasyan', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Supervisor 3rd District (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished third of four with 38,482 / 9.22%. Horvath won outright with 66.35%, so there is no runoff.'),
  ('a30bed88-846a-4bef-84f1-bb348d17bc17', '0e771fec-1763-4405-974f-4beabad6538b',
   'Tomas Sidenfaden', 'Tomas', 'Sidenfaden', false, 'active', 'lavote-2026',
   'lost', '2026-08-07T00:00:00Z',
   'LA County RR/CC certified results, June 2 2026, Supervisor 3rd District (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07). Finished fourth of four with 34,046 / 8.16%. Horvath won outright with 66.35%, so there is no runoff.')
ON CONFLICT DO NOTHING;

-- Amend, don't overwrite: the original claim stays visible beside the correction.
UPDATE essentials._retired_1589_races
   SET reason = reason || ' || CORRECTED 2026-08-07 (migration 1596): the claim "D5 is up" is FALSE, as is "LA elects 1/3/5 in gubernatorial years". The certified June 2 2026 canvass contains only the 1st and 3rd District supervisorial contests; Kathryn Barger won D5 outright in the March 2024 primary and holds it to 2028. The real cycle is D1/D3 in gubernatorial years and D2/D4/D5 in presidential years. No D5 race is owed for 2026 — do not seed one.'
 WHERE reason NOT LIKE '%CORRECTED 2026-08-07%';

COMMIT;
