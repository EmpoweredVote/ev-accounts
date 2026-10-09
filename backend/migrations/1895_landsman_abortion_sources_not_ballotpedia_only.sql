-- 1895_landsman_abortion_sources_not_ballotpedia_only.sql
-- One Season 2 context row, sources only. No chair moves, no reasoning changes, nothing inserted
-- or deleted. SEASON 1 IS NOT TOUCHED.
--
-- ── WHY THIS EXISTS, PLAINLY: THE SOURCING GATE CAUGHT MIGRATION 1894 AND IT WAS RIGHT ─────────
-- 1894 repaired Greg Landsman / Abortion by replacing an uncitable argument with his endorsement of
-- Ohio Issue 1 (2023), evidenced from two pages: his Ballotpedia profile, whose "notable ballot
-- measure endorsements" table records the endorsement, and Ballotpedia's page for the measure,
-- which independently lists him among its supporters and states the viability standard the chair
-- turns on. Both carry the claim. But BOTH ARE BALLOTPEDIA, which is exactly what the
-- `BALLOTPEDIA_ONLY` check in `check:stance-sources` exists to refuse, and the count moved 179 ->
-- 181. Run by hand before merging, because that gate never runs on pull requests.
--
-- ⚖ THE FIX IS A BETTER SOURCE, NOT A WIDER BASELINE. Baselining a row this migration had just
-- written would have recorded my own new defect as part of the accepted backlog -- the backlog is
-- for debt being worked off, not a place to put today's work. The endorsement is independently
-- documented outside Ballotpedia: the Wikipedia article on November 2023 Ohio Issue 1 lists, under
-- the U.S. Representatives who endorsed it, "Greg Landsman, U.S. Representative from OH-1
-- (2023-present) (Democrat)", sourced there to Politico of 29 October 2023. That page was fetched
-- and read (200, 827KB; three occurrences of "Landsman", one of them the endorsement list and one
-- the per-district result table showing Issue 1 carrying OH-1 by 63%-37%).
-- 🔑 It is also a better KIND of source for this audit: an article about the MEASURE, not a profile
-- of the person, so it is specific evidence rather than the generic person-page sourcing this whole
-- workstream is unwinding.
-- The Ballotpedia measure page is kept -- it is not wrong, it is just not sufficient on its own.
--
-- ── ⚠ SEPARATE FINDING, DELIBERATELY NOT FIXED HERE ────────────────────────────────────────────
-- 🔴 `check-stance-sources.mjs` reported TWO offending rows for this one defect: one keyed to the
-- Season 2 answer and one to the SEASON 1 answer, although the Season 1 context row was never
-- touched and still holds its original Ballotpedia+Wikipedia pair. The cause is in the check's own
-- query -- it joins answers to context on `(politician_id, topic_id)` and NOT on `season_id`, so
-- every answer row is paired with every context row for that pair, across seasons.
-- MEASURED on production, not inferred from reading it: the join yields **41,923** answer-context
-- pairs where only **36,352** are season-matched, so **5,571 pairs (~13%)** score an answer in one
-- season against a context row from another. A bad source array in either season therefore taints
-- both rows' identities, and the per-season baseline keys on identities it can mis-attribute.
-- That is a real bug worth fixing, but fixing it changes what the gate scores and would require
-- rebuilding the baseline, which does not belong inside a data migration. Recorded here so the
-- next person to see a doubled row knows it is the join and not the data.
--
-- ⚠ `check:stance-sources` re-run BY HAND after this migration: BALLOTPEDIA_ONLY back to 179.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- The row must be exactly as 1894 left it, or something else has moved and this is not safe.
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
     AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND sources = ARRAY['https://ballotpedia.org/Greg_Landsman',
                         'https://ballotpedia.org/Ohio_Issue_1,_Right_to_Make_Reproductive_Decisions_Including_Abortion_Initiative_(2023)'];
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1895: Landsman/abortion Season 2 sources are not what 1894 wrote (found %)', n;
  END IF;

  -- And the chair must still be 2. This migration has no business running if it is not.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
     AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND value = 2;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1895: Landsman/abortion Season 2 chair is not 2 (found %)', n;
  END IF;
END $$;

UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Greg_Landsman',
                       'https://en.wikipedia.org/wiki/November_2023_Ohio_Issue_1',
                       'https://ballotpedia.org/Ohio_Issue_1,_Right_to_Make_Reproductive_Decisions_Including_Abortion_Initiative_(2023)']
 WHERE politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
   AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
     AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND cardinality(sources) = 3
     AND 'https://en.wikipedia.org/wiki/November_2023_Ohio_Issue_1' = ANY(sources);
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1895: Season 2 sources not updated as expected (found %)', n;
  END IF;

  -- Not every source may be Ballotpedia any more -- the condition the gate actually tests.
  SELECT count(*) INTO n FROM inform.politician_context c
   WHERE c.politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
     AND c.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia.org%');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1895: row is still Ballotpedia-only';
  END IF;

  -- Season 1 must be untouched, sources included.
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = '6cad043f-a4c0-48d5-af76-fdf70d319920'
     AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND sources = ARRAY['https://ballotpedia.org/Greg_Landsman',
                         'https://en.wikipedia.org/wiki/Greg_Landsman'];
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1895: Season 1 row changed, which it must not have (found %)', n;
  END IF;
END $$;

COMMIT;
