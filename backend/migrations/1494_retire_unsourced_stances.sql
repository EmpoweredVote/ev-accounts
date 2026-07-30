-- 1494 — retire published stances that are unsourced or argue from party membership
--
-- WHAT IS BEING RETIRED (969 answers / 184 politicians)
--   921  no-context                    no inform.politician_context row at all: no reasoning,
--                                      no sources. Nothing exists that could support the chair.
--    42  empty-sources                 context row present but `sources` is an empty array.
--     6  bio-only:party-prior-language  reasoning argues from party ("Republican position on
--                                      market-based healthcare"), which is the documented
--                                      fabrication pattern, not evidence.
--
-- Every one fails the standing bar — a stance needs a chair the evidence names AND a source that
-- supports it — by construction rather than by judgement. An empty compass is honest; a
-- confabulated one is a false statement about a real person. 326 of the affected politicians are
-- seated and visible in Essentials, so these were live to voters.
--
-- WHAT IS DELIBERATELY *NOT* RETIRED (783 answers / 287 politicians)
-- Rows cited only to a Ballotpedia bio URL. They carry a source and may well be true — 407 quote
-- the official, 93 cite a specific bill. Establishing whether any given one holds requires fetching
-- the cited page, NOT a text heuristic: this project already found that 7 of 8 bill-citing rows
-- cited votes cast before the member was seated, so specific-looking content is exactly what
-- fabrication looks like here. Retiring them on suspicion would delete genuinely-evidenced
-- positions; keeping them unexamined is also not acceptable. They are therefore queued for
-- verification, not deletion. Backlog + full rollback record (committed BEFORE this migration ran):
--   data/stance-retirement/2026-07-29-suspect-stance-backlog.csv   (action = VERIFY)
--
-- RESTORING A ROW: that CSV carries politician_id, topic_id, value, write_in_text, reasoning and
-- sources for all 1,752 rows, so any retirement here is reversible from the repo.
--
-- last_stances_researched_at: 159 politicians end up with zero answers. 28 of them carry a
-- non-null research timestamp, which would then assert research that no longer exists — those are
-- nulled, so they resurface in the re-research queue instead of reading as already done. The old
-- timestamp is preserved per row in the backlog CSV, so the fact is recorded, not lost. Only
-- politicians left with NO answers are touched; a partially-retired compass keeps its timestamp
-- because research genuinely did happen for the rows that remain.
--
-- NOT the same as an honest zero: a timestamp with zero answers is legitimate when research ran and
-- nothing met the bar. Three politicians were already in that state before this migration and are
-- deliberately left alone (see the gate).
--
-- Idempotent: the target set is computed from the same predicates, so a second run finds nothing.

BEGIN;

-- Materialise the target set FIRST. The predicates join answers to context, so deleting either
-- table before the set is fixed would change what the other delete matches.
CREATE TEMP TABLE _retire_1494 ON COMMIT DROP AS
SELECT a.politician_id, a.topic_id
  FROM inform.politician_answers a
  LEFT JOIN inform.politician_context c
    ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
 WHERE c.politician_id IS NULL
    OR coalesce(array_length(c.sources,1),0) = 0
    OR (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia.org%')
        AND c.reasoning ~* '(Republican|Democratic|Democrat|party)[- ](position|line|stance|platform|orthodoxy)|as a (Republican|Democrat)|consistent with (his|her|their|the) part|aligns with (his|her|their) part|typical (Republican|Democrat)');

-- Politicians who will be left with no answers at all (computed BEFORE the delete).
CREATE TEMP TABLE _emptied_1494 ON COMMIT DROP AS
SELECT a.politician_id
  FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (
         WHERE EXISTS (SELECT 1 FROM _retire_1494 r
                        WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c
 USING _retire_1494 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a
 USING _retire_1494 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

UPDATE essentials.politicians p
   SET last_stances_researched_at = NULL
  FROM _emptied_1494 e
 WHERE p.id = e.politician_id
   AND p.last_stances_researched_at IS NOT NULL;

-- ── post-verify gate ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_left_unsourced int;
  v_left_party     int;
  v_verify_kept    int;
  v_false_stamp    int;
  v_orphan_ctx     int;
BEGIN
  -- no answer may remain without a context row, or with an empty sources array
  SELECT count(*) INTO v_left_unsourced
    FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE c.politician_id IS NULL OR coalesce(array_length(c.sources,1),0) = 0;

  IF v_left_unsourced <> 0 THEN
    RAISE EXCEPTION '1494: % answer(s) still unsourced', v_left_unsourced;
  END IF;

  -- no answer may remain whose reasoning argues from party
  SELECT count(*) INTO v_left_party
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE c.reasoning ~* '(Republican|Democratic|Democrat|party)[- ](position|line|stance|platform|orthodoxy)|as a (Republican|Democrat)|consistent with (his|her|their|the) part|aligns with (his|her|their) part|typical (Republican|Democrat)'
     AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia.org%');

  IF v_left_party <> 0 THEN
    RAISE EXCEPTION '1494: % party-prior answer(s) survived', v_left_party;
  END IF;

  -- the VERIFY cohort must be INTACT — this migration must not have eaten it
  SELECT count(*) INTO v_verify_kept
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE coalesce(array_length(c.sources,1),0) > 0
     AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia.org%');

  IF v_verify_kept <> 783 THEN
    RAISE EXCEPTION '1494: expected 783 bio-only answers still present for verification, found %',
      v_verify_kept;
  END IF;

  -- Nobody EMPTIED BY THIS MIGRATION may still carry a research timestamp. Scoped to
  -- _emptied_1494 deliberately: 3 politicians (Deidre Tyler, MacKenzie Miller, Thaddeus A. Evans,
  -- all stamped 2026-06-01) already had zero answers and a non-null timestamp before this ran.
  -- That combination is LEGITIMATE — it is how an honest zero is recorded: research happened and
  -- nothing met the bar. Nulling those would destroy the fact that we looked. Left untouched.
  SELECT count(*) INTO v_false_stamp
    FROM _emptied_1494 e
    JOIN essentials.politicians p ON p.id = e.politician_id
   WHERE p.last_stances_researched_at IS NOT NULL;

  IF v_false_stamp <> 0 THEN
    RAISE EXCEPTION '1494: % emptied politician(s) still claim research', v_false_stamp;
  END IF;

  -- No context row may be left behind for a key we retired. Scoped to _retire_1494 on purpose:
  -- 547 orphaned context rows PRE-DATE this migration (context rows whose answer no longer
  -- exists), so a global orphan assertion would fail on unrelated data rather than on this
  -- change. Those 547 are separate data debt, recorded in the backlog rather than fixed here.
  SELECT count(*) INTO v_orphan_ctx
    FROM inform.politician_context c
    JOIN _retire_1494 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;

  IF v_orphan_ctx <> 0 THEN
    RAISE EXCEPTION '1494: % retired key(s) still have a context row', v_orphan_ctx;
  END IF;

  RAISE NOTICE '1494 OK — 0 unsourced, 0 party-prior, 783 kept for verification, 0 false stamps, 0 orphans';
END $$;

COMMIT;
