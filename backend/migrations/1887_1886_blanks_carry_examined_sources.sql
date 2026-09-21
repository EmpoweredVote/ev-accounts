-- 1887_1886_blanks_carry_examined_sources.sql
-- Carry the examined sources onto migration 1886's 11 Season 2 blanks. 11 context rows UPDATED in
-- the OPEN season. No answers touched, no rows created or deleted, SEASON 1 NOT TOUCHED.
--
-- 🔴 WHY THIS EXISTS: I SHIPPED 1886 WITH `sources = ARRAY[]::text[]` AND TURNED MASTER RED.
-- `EMPTY_SOURCES` is a ZERO-TOLERANCE check in `npm run check:stance-sources`, and it caught all 11
-- immediately on merge: *"Cite what the chair actually rests on, or retire the answer."* The gate is
-- right. Migration 1882's blanks carried their LD 427 roll-call sources and passed for exactly this
-- reason; 1886 did not copy that part.
--
-- ⚠ AND THE GATE COULD NOT HAVE CAUGHT IT EARLIER: `stance sourcing` is `if: github.event_name !=
-- 'pull_request'`, so it never ran on PR #574. It runs on push to master. Everything else on that PR
-- was green. When a zero-tolerance data check is PR-invisible, "CI green on the PR" is not evidence
-- about the data — run `npm run check:stance-sources` by hand before merging anything that writes
-- stance rows.
--
-- ⚖ WHY SOURCES, NOT A RETIREMENT. A blank is not "no research"; it is "researched, and the evidence
-- does not reach any rung". The honest sources for such a row are THE PAGES THAT WERE EXAMINED AND
-- FOUND INSUFFICIENT -- here the Season 1 row's own citations (Texas House/Senate member pages,
-- Wikipedia biographies, one campaign site). Carrying them forward makes the blank auditable: a
-- reader can see what was looked at. This is the same shape as the 62 exemplary Local Immigration
-- Enforcement blanks in this corpus, which name the sources checked.
-- 🔑 It is also the point of the finding: a member-info page IS the evidence those chairs rested on,
-- and a member-info page cannot state a deportation position. Recording it is the argument, not a
-- concession.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context c
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND coalesce(cardinality(c.sources), 0) = 0;
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1887: expected 11 empty-source Season 2 blanks, found % -- state has moved', n;
  END IF;

  -- every one of them must have a Season 1 row with sources to carry forward
  SELECT count(*) INTO n
    FROM inform.politician_context c2
    JOIN inform.politician_context c1
      ON c1.politician_id = c2.politician_id AND c1.topic_id = c2.topic_id
     AND c1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   WHERE c2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c2.topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND coalesce(cardinality(c2.sources), 0) = 0
     AND coalesce(cardinality(c1.sources), 0) > 0;
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1887: only % of 11 blanks have a sourced Season 1 row to carry', n;
  END IF;
END $$;

UPDATE inform.politician_context c2
   SET sources = c1.sources
  FROM inform.politician_context c1
 WHERE c1.politician_id = c2.politician_id
   AND c1.topic_id      = c2.topic_id
   AND c1.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   AND c2.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND c2.topic_id      = '44905f3b-e105-4f6c-afc7-5d223813dbac'
   AND coalesce(cardinality(c2.sources), 0) = 0;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1887: % Season 2 blank(s) still carry no sources', n;
  END IF;

  -- the answers must still be blanks, and still 11 of them
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac' AND value = 0;
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1887: expected 11 Season 2 blanks to survive, found %', n;
  END IF;

  -- 🔴 Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac' AND value = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1887: % Season 1 answer(s) were blanked -- history was edited', n;
  END IF;
END $$;

COMMIT;
