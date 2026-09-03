BEGIN;

-- =============================================================================
-- CC_0058: re-point 2,685 answers onto Season 2's changed ladders
-- =============================================================================
-- Created 2026-09-03 with Chris Cantrell. The write the Season 2 read audit
-- existed to make safe.
--
-- Two Season 2 revisions change what their rungs MEAN, and both carry a
-- rung_map — Chris Andrews' decision about where each old position lands:
--
--   Affordable Housing v2   {1:1, 2:3, 3:4, 4:5, 5:5}
--   Same-Sex Marriage  v2   {1:2, 2:3, 3:"invalidated", 4:4, 5:5}
--
-- Without this migration, opening Season 2 would leave 2,685 answers indexing
-- into ladders whose positions moved — a politician's stored rung would render
-- against text that says something they never said. ADR 0004 §4 calls the
-- rung_map "five decisions per ladder change, not 2,014"; this is the mechanical
-- half it always implied, which was simply never built.
--
-- 🔴 SEASON 1 IS NOT TOUCHED. Every statement below only INSERTs into Season 2.
-- Season 1 keeps every row exactly as researched, which is what makes it the
-- historical record rather than a thing we edit when the wording changes.
--
-- WHERE THE ANSWERS GO (measured on prod 2026-09-03, asserted at the bottom):
--
--   Housing 1,785      1→1  113 stay     2→3  757     3→4  672
--                      4→5  229          5→5   14 stay
--   Same-Sex Marriage    1→2  493        2→3  145     3→∅   28 BLANKED
--          900          4→4   61 stay    5→5  173 stay
--
-- ⚠ TWO NEW RUNGS OPEN WITH NOBODY ON THEM, and that is expected, not a bug.
-- Nothing maps to Housing's new rung 2 or to Same-Sex Marriage's new rung 1 (the
-- "full legal equality" rung Andrews inserted). They fill only as people are
-- re-researched in Season 2.
--
-- ⚠ HOUSING MERGES OLD 4 AND OLD 5 INTO NEW 5 — 229 joining 14. Two positions
-- that were distinct in Season 1 become one in Season 2, and Season 2 cannot
-- tell them apart afterwards. Chris acknowledged the lost distinction on
-- 2026-09-03 and accepted it; Season 1 preserves it.
--
-- 🔴 THE 28 BLANKS. Old rung 3 was "let each state decide" — a FEDERALISM
-- position. The new ladder measures only degree of recognition and has no
-- states-rights rung, so those 28 have genuinely nowhere to sit; mapping them to
-- new rung 3 would assert a religious-exemption view they never stated. Chris
-- ruled 2026-09-02: "If there is nowhere for the 28 to go, they can be blanked.
-- We will remember the difference between seasons 1 and 2."
-- A blank is value 0, which CC_0057 made expressible and PR #350 made safe to
-- read. 28 people who show a Same-Sex Marriage position today will show a blank
-- spoke in Season 2.
--
-- USER ANSWERS ARE DELIBERATELY NOT TOUCHED (Chris's decision, 2026-09-03).
-- `inform.compass_responses` holds 10 rows across 7 users on these two topics.
-- A politician's answer is a researched claim we make about them, so re-pointing
-- it mechanically is honest. A user's answer is their own statement, and moving
-- someone from rung 1 to rung 2 would put a position in their mouth. Its CHECK
-- is `value >= 0.5` besides, so CC_0057's zero does not even apply there.
-- 🔴 THIS CREATES A FOLLOW-UP THAT GATES THE SEASON OPEN, NOT THIS MIGRATION:
-- calibration must RE-ASK these topics when a user's answer predates the current
-- ladder. Until it does, `compass_responses_current` will serve a Season 1 rung
-- against a Season 2 ladder — the exact mismeaning PRs #349/#350 removed on the
-- politician side. Do not open Season 2 before that lands.

-- -----------------------------------------------------------------------------
-- 0. Refuse to run against a state this migration was not written for
-- -----------------------------------------------------------------------------
-- Every assumption below is checked before anything is written. A migration that
-- half-applies to a shifted world is worse than one that refuses.
DO $$
DECLARE
  v_s1 uuid; v_s2 uuid; v_s2_status text;
  v_housing uuid; v_ssm uuid;
  v_map_h jsonb; v_map_s jsonb;
  v_existing int; v_writeins int;
BEGIN
  SELECT id INTO v_s1 FROM inform.seasons WHERE number = 1 AND status = 'open';
  IF v_s1 IS NULL THEN
    RAISE EXCEPTION 'CC_0058: Season 1 is not open — this migration reads it as the source of truth';
  END IF;

  SELECT id, status INTO v_s2, v_s2_status FROM inform.seasons WHERE number = 2;
  IF v_s2 IS NULL THEN RAISE EXCEPTION 'CC_0058: Season 2 does not exist'; END IF;
  IF v_s2_status <> 'draft' THEN
    RAISE EXCEPTION 'CC_0058: Season 2 is %, expected draft. Writing into an open or closed season is a different operation with different rules.', v_s2_status;
  END IF;

  SELECT id INTO v_housing FROM inform.compass_topics WHERE topic_key = 'housing';
  SELECT id INTO v_ssm     FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage';

  -- The maps are Andrews' editorial decision. If either has been re-proposed
  -- since this migration was written, the movement table above is wrong and the
  -- counts at the bottom would fail anyway — fail here instead, with the reason.
  SELECT r.rung_map INTO v_map_h FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_s2 AND sq.topic_id = v_housing;
  SELECT r.rung_map INTO v_map_s FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
   WHERE sq.season_id = v_s2 AND sq.topic_id = v_ssm;

  IF v_map_h IS DISTINCT FROM '{"1":1,"2":3,"3":4,"4":5,"5":5}'::jsonb THEN
    RAISE EXCEPTION 'CC_0058: the Housing rung_map is now %, not the map this migration was written against', v_map_h;
  END IF;
  IF v_map_s IS DISTINCT FROM '{"1":2,"2":3,"3":"invalidated","4":4,"5":5}'::jsonb THEN
    RAISE EXCEPTION 'CC_0058: the Same-Sex Marriage rung_map is now %, not the map this migration was written against', v_map_s;
  END IF;

  -- Idempotency. The PK would raise on a second run anyway, but "duplicate key"
  -- does not tell an operator that the work is already done.
  SELECT count(*) INTO v_existing FROM inform.politician_answers
   WHERE season_id = v_s2 AND topic_id IN (v_housing, v_ssm);
  IF v_existing > 0 THEN
    RAISE EXCEPTION 'CC_0058: Season 2 already holds % answer(s) on these topics — this migration has already run', v_existing;
  END IF;

  -- A write-in is a position stated between the rungs, so a rung_map cannot move
  -- it and CC_0057 forbids one on a blank. Prod holds none today; if that ever
  -- changes, the carry needs an editorial decision rather than this SQL.
  SELECT count(*) INTO v_writeins FROM inform.politician_answers
   WHERE topic_id IN (v_housing, v_ssm) AND write_in_text IS NOT NULL;
  IF v_writeins > 0 THEN
    RAISE EXCEPTION 'CC_0058: % write-in(s) exist on these topics — a rung_map cannot re-point a write-in; decide those by hand first', v_writeins;
  END IF;

  RAISE NOTICE 'CC_0058 preconditions OK: S1 open, S2 draft, both rung_maps unchanged, no prior run, no write-ins.';
END $$;

-- -----------------------------------------------------------------------------
-- 1. The answers
-- -----------------------------------------------------------------------------
-- The mapping is applied IN SQL from the stored rung_map, not from a hand-typed
-- list. The map is the editorial artefact; re-typing 2,685 destinations would
-- invent a second source of truth that could disagree with it silently.
--
-- 🔴 topic_revision_id COMES FROM season_questions, NEVER FROM THE CALLER. That
-- is the entire point of the pin: the row records which ladder text it is an
-- answer to. Sourcing it from the JOIN also makes politician_answers_pin_fkey
-- satisfied by construction rather than by hope.
--
-- 🔴 editor_id IS NULL, DELIBERATELY. Carrying the Season 1 editor forward would
-- attribute a mechanical re-point to a person who made no Season 2 judgement —
-- it would read, in the audit trail, as though they had re-researched this
-- politician. Nobody did. The human decision lives in the rung_map on the
-- revision, and the row's provenance is this migration.
INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value, write_in_text, editor_id, updated_at)
SELECT a.politician_id,
       a.topic_id,
       sq.season_id,
       sq.topic_revision_id,
       -- 'invalidated' becomes 0: researched, and no rung states what they hold.
       CASE WHEN (rev.rung_map ->> a.value::int::text) = 'invalidated'
            THEN 0
            ELSE (rev.rung_map ->> a.value::int::text)::numeric
       END,
       NULL,
       NULL,
       now()
  FROM inform.politician_answers a
  JOIN inform.seasons s1            ON s1.id = a.season_id AND s1.number = 1
  JOIN inform.compass_topics t      ON t.id  = a.topic_id
  JOIN inform.seasons s2            ON s2.number = 2
  JOIN inform.season_questions sq   ON sq.season_id = s2.id AND sq.topic_id = a.topic_id
  JOIN inform.compass_topic_revisions rev ON rev.id = sq.topic_revision_id
 WHERE t.topic_key IN ('housing', 'same-sex-marriage');

-- -----------------------------------------------------------------------------
-- 2. The context, for the mapped answers only
-- -----------------------------------------------------------------------------
-- Chris's decision, 2026-09-03: carry the reasoning and sources across for every
-- answer that MOVED to a real rung, and carry NONE for the 28 that were blanked.
--
-- Why the 28 get nothing: their reasoning argues "let each state decide", a
-- position the Season 2 row no longer records. Carrying it would put voter-facing
-- prose arguing a stance underneath a spoke that shows none.
-- The read path already renders the honest version — getPoliticianCitations only
-- shows context from the ANSWER'S OWN season, so with no Season 2 context those
-- politicians display evidence, no stance and no reasoning. Which is exactly
-- true: we researched them, and they hold no position on the current ladder.
-- Season 1 keeps their reasoning, where it still matches the rung it was written
-- against.
--
-- editor_id IS carried here, unlike on the answer above, and the difference is
-- deliberate: the prose is that editor's work and stays theirs. Only the rung
-- placement was mechanical.
--
-- ⚠ 53 context rows on these topics have no answer at all (evidence gathered,
-- never seated). They stay in Season 1 — there is no answer for them to explain
-- in Season 2, and inventing one is not this migration's job.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT c.politician_id,
       c.topic_id,
       sq.season_id,
       sq.topic_revision_id,
       c.reasoning,
       c.sources,
       c.editor_id,
       now()
  FROM inform.politician_context c
  JOIN inform.seasons s1          ON s1.id = c.season_id AND s1.number = 1
  JOIN inform.compass_topics t    ON t.id  = c.topic_id
  JOIN inform.politician_answers a
    ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id AND a.season_id = c.season_id
  JOIN inform.seasons s2          ON s2.number = 2
  JOIN inform.season_questions sq ON sq.season_id = s2.id AND sq.topic_id = c.topic_id
 WHERE t.topic_key IN ('housing', 'same-sex-marriage')
   -- the blanked 28 get no Season 2 context
   AND NOT (t.topic_key = 'same-sex-marriage' AND a.value = 3);

-- -----------------------------------------------------------------------------
-- 3. Assert the outcome, rung by rung
-- -----------------------------------------------------------------------------
-- Row totals alone would pass a migration that moved everyone to the wrong rung.
-- These are the per-rung destinations from the movement table above, so a map
-- misapplied in any direction fails here rather than in production.
DO $$
DECLARE
  v_s1 uuid; v_s2 uuid; v_housing uuid; v_ssm uuid;
  v_n int; v_s1_total int; v_all_total int;
  -- named v_row, NOT r: a bare `r` shadows a table alias later in this
  -- block, and PL/pgSQL resolves the VARIABLE first. Caught in dry run —
  -- `compass_responses r` then failed with "record r has no field topic_id".
  v_row RECORD;
  v_expected CONSTANT jsonb := jsonb_build_object(
    'housing',           jsonb_build_object('1', 113, '3', 757, '4', 672, '5', 243),
    'same-sex-marriage', jsonb_build_object('0',  28, '2', 493, '3', 145, '4',  61, '5', 173)
  );
BEGIN
  SELECT id INTO v_s1 FROM inform.seasons WHERE number = 1;
  SELECT id INTO v_s2 FROM inform.seasons WHERE number = 2;
  SELECT id INTO v_housing FROM inform.compass_topics WHERE topic_key = 'housing';
  SELECT id INTO v_ssm     FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage';

  -- 3a. every destination rung holds exactly the expected population
  FOR v_row IN
    SELECT t.topic_key, a.value::int::text AS rung, count(*)::int AS n
      FROM inform.politician_answers a
      JOIN inform.compass_topics t ON t.id = a.topic_id
     WHERE a.season_id = v_s2 AND t.topic_key IN ('housing','same-sex-marriage')
     GROUP BY t.topic_key, a.value
  LOOP
    IF (v_expected -> v_row.topic_key ->> v_row.rung)::int IS DISTINCT FROM v_row.n THEN
      RAISE EXCEPTION 'CC_0058: % rung % holds % row(s), expected %',
        v_row.topic_key, v_row.rung, v_row.n,
        coalesce(v_expected -> v_row.topic_key ->> v_row.rung, 'none');
    END IF;
  END LOOP;

  -- 3b. and no destination is missing (3a only checks rungs that got rows)
  SELECT count(*) INTO v_n FROM (
    SELECT k.topic_key, e.key AS rung
      FROM jsonb_each(v_expected) k(topic_key, rungs), jsonb_each(k.rungs) e
     EXCEPT
    SELECT t.topic_key, a.value::int::text
      FROM inform.politician_answers a
      JOIN inform.compass_topics t ON t.id = a.topic_id
     WHERE a.season_id = v_s2
  ) missing;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0058: % expected destination rung(s) received no rows at all', v_n;
  END IF;

  -- 3c. the two new rungs that must open EMPTY really are empty
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE season_id = v_s2 AND ((topic_id = v_housing AND value = 2) OR (topic_id = v_ssm AND value = 1));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0058: % row(s) landed on a rung nothing maps to (Housing 2 / SSM 1) — the map was misapplied', v_n;
  END IF;

  -- 3d. exactly 28 blanks, all on Same-Sex Marriage
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE season_id = v_s2 AND value = 0;
  IF v_n <> 28 THEN RAISE EXCEPTION 'CC_0058: % blank(s), expected 28', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE season_id = v_s2 AND value = 0 AND topic_id <> v_ssm;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CC_0058: % blank(s) outside Same-Sex Marriage', v_n; END IF;

  -- 3e. totals
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id
   WHERE a.season_id = v_s2 AND t.topic_key IN ('housing','same-sex-marriage');
  IF v_n <> 2685 THEN RAISE EXCEPTION 'CC_0058: wrote % answers, expected 2685', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE season_id = v_s2;
  IF v_n <> 2657 THEN RAISE EXCEPTION 'CC_0058: wrote % context rows, expected 2657', v_n; END IF;

  -- 3f. every carried context sits on a real stance, and no blank carries prose
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = v_s2 AND a.value = 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0058: % blanked answer(s) carry Season 2 reasoning — a blank has no position to justify', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                     WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                       AND c.season_id = a.season_id);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0058: % mapped answer(s) reached Season 2 with no reasoning', v_n;
  END IF;

  -- 3g. 🔴 SEASON 1 IS UNTOUCHED. The single most important assertion here.
  SELECT count(*) INTO v_s1_total FROM inform.politician_answers WHERE season_id = v_s1;
  IF v_s1_total <> 33022 THEN
    RAISE EXCEPTION 'CC_0058: Season 1 now holds % answers, expected 33022 — history was modified', v_s1_total;
  END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = v_s1 AND a.topic_id = v_ssm AND a.value = 3;
  IF v_n <> 28 THEN
    RAISE EXCEPTION 'CC_0058: Season 1 holds % Same-Sex Marriage rung-3 answers, expected 28 — the blanking must SHADOW them, never delete them', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE season_id = v_s1 AND value = 0;
  IF v_n <> 0 THEN RAISE EXCEPTION 'CC_0058: % Season 1 answer(s) were blanked — Season 1 is not ours to edit', v_n; END IF;

  -- 3h. user answers were not touched
  SELECT count(*) INTO v_n FROM inform.compass_responses cr
    JOIN inform.compass_topics t ON t.id = cr.topic_id
   WHERE t.topic_key IN ('housing','same-sex-marriage');
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'CC_0058: compass_responses now holds % rows on these topics, expected 10 — user answers are out of scope', v_n;
  END IF;

  SELECT count(*) INTO v_all_total FROM inform.politician_answers;
  RAISE NOTICE 'CC_0058 OK: 2685 answers + 2657 context into Season 2. Season 1 unchanged at %. Table total now %.',
    v_s1_total, v_all_total;
END $$;

COMMIT;
