-- Migration 1938 — merge the two duplicate pairs that were publishing CONTRADICTING stances.
--
-- Tier 1 of the unreviewed duplicate-people backlog: pairs where BOTH active rows answer the same
-- compass topic and DISAGREE. A census of all 52 unreviewed pairs found exactly three such pairs.
-- One of the three is not a duplicate (Padilla, below). The other two are merged here.
--
-- 🔴🔴 WHAT THIS MIGRATION DELIBERATELY DOES NOT DO, AND WHY — READ THIS BEFORE EXTENDING IT.
-- The first attempt tried to delete the losing side of each conflict and move the rest. The database
-- refused it:
--     CLOSED_SEASON_IMMUTABLE: DELETE on inform.politician_answers targets season
--     2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3, which is closed. A closed season is the historical
--     record (ADR 0005 §1.6 step 5).
-- ALL SEVEN CONTRADICTIONS LIVE IN SEASON 1, WHICH IS CLOSED. The guard offers an escape --
-- SET LOCAL inform.allow_closed_season_write = 'on' -- and it is NOT taken here. Overriding a
-- database-level history guard is an operator's decision, not a migration author's, and the
-- contradiction can be resolved without editing history at all. Nothing in inform.* is touched.
--
-- HOW THE CONTRADICTION IS RESOLVED INSTEAD: by reachability. A duplicate with no seat and no
-- candidacy is not reachable by any route a voter has. Measured, not assumed:
--   * is_active = false does NOT hide a profile -- the retired Seth Moulton row still answers 200
--     on /api/essentials/politicians/<id>. Retiring alone would have been a hollow fix.
--   * /api/search does not return politicians at all; it returns meetings and media.
--   * So the live route to a seatless duplicate is its CANDIDACY, via the race listing. Nguyen's
--     duplicate holds the MA-06 candidacy, so the 2026 race page showed her campaign-sourced
--     answers while her state-house seat page showed her bill-record answers. Same person, two
--     answers, depending on which page a voter landed on.
-- Moving the candidacy to the survivor closes that route. race_candidates is not season-gated.
--
-- THE SEVEN CONTRADICTIONS, all Season 1 (checked per season -- a Season 1 vs Season 2 difference
-- is not a contradiction a voter sees, and the first measurement did not filter by season):
--   Marshall  Fossil Fuel Policy 4.0 vs 5.0 · Religious Freedom 5.0 vs 4.0
--             Voting Rights and Electoral Integrity 5.0 vs 4.0
--   Nguyen    Civil Rights 2.0 vs 1.0 · Climate Change 3.0 vs 2.0
--             Healthcare Access 1.0 vs 2.0 · Immigration 2.0 vs 1.0
--
-- IDENTITY, established per pair and never on the name:
--   Marshall  THE TWO ROWS CARRY THE SAME PHOTOGRAPH, differently cropped -- same tie, shirt, suit,
--             background, expression. FEC S6AL00450 is "MARSHALL, STEVEN T", Republican, Alabama
--             Senate 2026; the seated row is Alabama's Attorney General, who is running for it.
--   Nguyen    Headshot pair: two sittings, plainly the same person, both against a Boston backdrop.
--             FEC H6MA06160 is "NGUYEN, TRAM", Democrat, MA-06 2026; the seated row is the
--             Representative for the 18th Essex District.
--
-- ⚖ THE OPERATOR'S RULING ON THE CONFLICTS, recorded here even though no answer row is written:
-- the SEATED row's values stand, because its sourcing is primary and the duplicate's is not.
--   Marshall  duplicate: 11 rows, ontheissues.org ONLY, 1.0 sources each
--             survivor:  10 rows, alabamaag.gov -- his own office -- 1.9 sources each
--   Nguyen    duplicate:  7 rows, tramforcongress.com issue pages plus one local news article
--             survivor:  13 rows, malegislature.gov BILL RECORDS, plus 2 Season 2 rows at 3.0
-- That is the migration-1661 (Cisneros) shape: primary .gov beat ontheissues-only. Because the
-- duplicate's rows are merely made unreachable rather than deleted, this ruling is satisfied
-- without touching the closed season.
--
-- ▶ STILL OPEN, and it needs an operator decision. The duplicates publish 8 topics the survivors do
-- not cover (Marshall 5, Nguyen 3). The operator asked for those to be carried across; the closed
-- season makes it impossible to move them. Two routes remain, neither taken here:
--   (a) re-research those 8 and write them into Season 2 on the survivor, through the normal
--       chair-evidence gate -- new published stances, not a move;
--   (b) set inform.allow_closed_season_write and move the Season 1 rows, editing history.
-- Doing nothing costs 8 answered topics that were only ever on a row voters could barely reach.
--
-- 🔴 ALEX PADILLA IS TWO DIFFERENT PEOPLE AND MUST NEVER BE MERGED.
--   2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f  U.S. SENATOR Alex Padilla (California)
--   123c9a42-5715-4ab2-a8bd-76e7adbca27b  Alex Padilla, COUNCILMEMBER, Inglewood District 2
-- Migrations 1647, 1649 and 1651 were spent DE-CONFLATING these two after the councilmember's
-- email, urls, bio and term dates were found on the senator's record. Their "contradiction"
-- (Economic Development 3.0 vs 2.0, Transportation 3.0 vs 2.0) is two people holding different
-- views. Recorded as different_people in backend/data/duplicate-people-baseline.json. Guard 1
-- fails this transaction if either Padilla id ever appears in the merge set.
--
-- check:stance-sources was run BY HAND before applying, because the live-DB jobs never run on a PR:
-- "OK — no stance row cites Ballotpedia and nothing else beyond the recorded backlog."
--
-- Duplicates are retired, never deleted (the person-merge recipe).
--
-- No migration runner exists; this file records SQL applied by hand via
-- mcp__supabase-local__execute_sql as `postgres`.

BEGIN;

CREATE TEMP TABLE mig1938_merges (
  survivor uuid NOT NULL,
  dup      uuid NOT NULL,
  label    text NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1938_merges (survivor, dup, label) VALUES
  ('d33b1fb5-bac7-48b9-9628-8169e28f4e16','a9e04e1e-92d4-44e4-a411-b6fe4814290a','AL Steve Marshall'),
  ('fc1d7143-1be8-49b0-be31-6dbc5874230d','0896566a-c773-4227-aca3-18cf573b60fe','MA Tram Nguyen');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1938_merges;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1938 pre-check: merge set is %, expected 2', n; END IF;

  -- GUARD 1 — the Padilla rows must never be here.
  SELECT count(*) INTO n FROM mig1938_merges
   WHERE survivor IN ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','123c9a42-5715-4ab2-a8bd-76e7adbca27b')
      OR dup      IN ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','123c9a42-5715-4ab2-a8bd-76e7adbca27b');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938: Alex Padilla the senator and Alex Padilla the Inglewood councilmember are different people'; END IF;

  -- GUARD 2 — all four rows active, survivors seated, duplicates not.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.is_active AND (p.id IN (SELECT survivor FROM mig1938_merges) OR p.id IN (SELECT dup FROM mig1938_merges));
  IF n <> 4 THEN RAISE EXCEPTION 'migration 1938 pre-check: expected 4 active rows, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1938_merges m
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = m.survivor)
      OR EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = m.dup);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938 pre-check: % pair(s) are not the expected seated/candidate shape', n; END IF;

  -- GUARD 3 — the seven contradictions are still present. If this has changed, someone has worked
  -- these rows and the ruling must be re-derived rather than re-applied.
  SELECT count(*) INTO n
    FROM mig1938_merges m
    JOIN inform.politician_answers da ON da.politician_id = m.dup      AND da.value IS DISTINCT FROM 0
    JOIN inform.politician_answers sa ON sa.politician_id = m.survivor AND sa.topic_id = da.topic_id
                                     AND sa.season_id = da.season_id   AND sa.value IS DISTINCT FROM 0
   WHERE da.value <> sa.value;
  IF n <> 7 THEN RAISE EXCEPTION 'migration 1938 pre-check: % contradiction(s), expected 7', n; END IF;
END $$;

-- 1. The candidacy. This is the route that made the contradiction reachable.
UPDATE essentials.race_candidates rc
   SET politician_id = m.survivor
  FROM mig1938_merges m
 WHERE rc.politician_id = m.dup;

-- 2. The FEC source follows the person.
UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = m.survivor,
       notes = coalesce(ps.notes,'') || ' | MERGED (migration 1938, 2026-10-22): moved from duplicate'
             || ' person row ' || m.dup::text || '. Same person; identity established by the headshot'
             || ' pair and the FEC candidate record. See the migration header.',
       updated_at = now()
  FROM mig1938_merges m
 WHERE ps.essentials_politician_id = m.dup;

-- 3. Both survivors already carry an image, so the duplicate's stays on the retired row rather than
--    creating a second 'default'.

-- 4. Retire the duplicates. Their Season 1 answers stay where they are, untouched and now
--    unreachable, which is what ADR 0005 asks for.
UPDATE essentials.politicians p
   SET is_active = false,
       is_incumbent = false,
       notes = coalesce(p.notes, '{}'::text[]) || ARRAY[
         'RETIRED by migration 1938 (2026-10-22): duplicate person row that published stances'
         || ' CONTRADICTING ' || m.survivor::text || ' on shared Season 1 topics. One person.'
         || ' The seated row''s answers stand, its sourcing being primary. This row''s Season 1'
         || ' answers were NOT moved or deleted -- Season 1 is closed and immutable (ADR 0005'
         || ' §1.6) -- they remain here as history, no longer reachable.']
  FROM mig1938_merges m
 WHERE p.id = m.dup;

DO $$
DECLARE n int;
BEGIN
  -- Nothing reachable is left on a duplicate.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.politician_id IN (SELECT dup FROM mig1938_merges);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938 post-check: % candidacy(ies) still on a duplicate', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM mig1938_merges);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938 post-check: % source(s) still on a duplicate', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN (SELECT dup FROM mig1938_merges) AND p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938 post-check: % duplicate(s) still active', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN (SELECT survivor FROM mig1938_merges) AND NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1938 post-check: % survivor(s) retired by mistake', n; END IF;

  -- HISTORY IS UNTOUCHED. 18 answers (Marshall 11, Nguyen 7) stay on the retired rows, and the
  -- survivors keep exactly what they had.
  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.politician_id IN (SELECT dup FROM mig1938_merges);
  IF n <> 18 THEN RAISE EXCEPTION 'migration 1938 post-check: duplicates hold % answers, expected 18 untouched', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.politician_id = 'd33b1fb5-bac7-48b9-9628-8169e28f4e16';
  IF n <> 10 THEN RAISE EXCEPTION 'migration 1938 post-check: Marshall holds % answers, expected 10 unchanged', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a
   WHERE a.politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d';
  IF n <> 13 THEN RAISE EXCEPTION 'migration 1938 post-check: Nguyen holds % answers, expected 13 unchanged', n; END IF;

  -- Both Padilla rows untouched and active.
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id IN ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','123c9a42-5715-4ab2-a8bd-76e7adbca27b')
     AND p.is_active;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1938 post-check: the Padilla rows should be untouched, % active', n; END IF;
END $$;

COMMIT;
