BEGIN;

-- =============================================================================
-- CC_0086: re-derive the Federal Lens membership and order
-- =============================================================================
-- Slot CC_0086 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. Two topics out, two in, and the whole lens re-ordered.
--
--   OUT  immigration   (Immigration and Treatment of Immigrants)
--   OUT  medicare/aid  (Medicare / Medicaid)
--   IN   voting-rights (Voting Rights and Electoral Integrity)
--   IN   civil-rights  (Civil Rights and Social Justice)
--
-- 🔴 `immigration` HAS BEEN BROKEN SINCE SEASON 2 OPENED, and nothing said so.
-- Season 2 asks 60 questions: 43 carried, 17 new, and exactly one DROPPED — this
-- one. A lens topic the open season does not ask is a spoke with no question
-- behind it. Found 2026-09-08 while answering "what should replace it", not by any
-- check, which is why this file also adds one.
--
-- ⚠ THE SLOT DID NOT NEED ANOTHER IMMIGRATION TOPIC. `deportation` is already in
-- this lens at 488 of 603, so that ground is covered: Season 2 dropped the general
-- topic and kept the specific one. The freed slot went to the next topic by the
-- lens's own rule rather than to a thematic substitute.
--
-- -- THE RULE THIS FILE APPLIES ----------------------------------------------
--
-- Migration 1337 seeded this lens in "popularity order, derived from
-- inform.politician_answers 2026-07-12", and its description promises "8 issues
-- most U.S. House & Senate members and candidates have answered". That promise is
-- the specification, so this file re-derives it rather than substituting taste.
--
-- Measured 2026-09-08 against 603 federal people (the `federal` branch of
-- office-tiers' COMPASS_TIER_SQL - members and candidates), counting DISTINCT
-- politicians with a non-blank answer in any non-draft season, over topics the OPEN
-- SEASON asks whose compass_topic_roles admit the federal tier:
--
--     1  climate-change   510   85%   (was slot 4)
--     2  fossil-fuels     500   83%   (was slot 7)
--     3  healthcare       489   81%   (was slot 0)
--     4  deportation      488   81%   (was slot 5)
--     5  taxes            488   81%   (was slot 1)
--     6  abortion         486   81%   (was slot 3)
--     7  voting-rights    472   78%   NEW
--     8  civil-rights     450   75%   NEW
--     ---------------------------------------------------------------
--     9  medicare/aid     425   71%   REMOVED - it fell below the cut
--        immigration        -    -    REMOVED - not asked this season
--
-- ⚠ `deportation` AND `taxes` TIE AT 488 and are ordered by topic_key so the
-- derivation is deterministic. Any future re-derivation must break ties the same
-- way or it will report drift that is only a coin toss.
--
-- ⚠ THE ORDER CHANGES FOR EVERY USER, which is a visible change and is intended.
-- Half-updating - new membership in the old order - would leave the lens claiming
-- popularity order while showing something else.
--
-- -- WHAT THIS FILE DELIBERATELY DOES NOT DO ---------------------------------
--
-- 🔴 IT DOES NOT COMPUTE THE TOP 8 AT APPLY TIME. A migration that ran the
-- derivation would write a different lens depending on the day it was applied, and
-- the review would be of a query rather than of a list. The eight rows below were
-- reviewed as rows. `check-lens-freshness.mjs`, added alongside this file, runs the
-- derivation on the nightly schedule and complains when the committed lens drifts
-- from the data - the same canonical-definition-plus-tripwire shape
-- office-tiers.mjs and check:federal-cohort already use here.
--
-- ⚠ IT TOUCHES ONLY THE FEDERAL LENS. Local, Judicial and Education were not
-- measured and are not changed. Education was seeded 2026-08-31 and is the most
-- likely to have the same immigration-shaped problem; the new check covers all four
-- so the next nightly will say.

-- -----------------------------------------------------------------------------
-- The lens, as it should read
-- -----------------------------------------------------------------------------
CREATE TEMPORARY TABLE _cc0086_want (
  topic_key  text NOT NULL,
  topic_id   uuid NOT NULL,
  sort_order int  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0086_want VALUES
  ('climate-change', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 0),
  ('fossil-fuels',   'a22215c3-6693-4bc2-b248-01aebba14570', 1),
  ('healthcare',     'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2),
  ('deportation',    '44905f3b-e105-4f6c-afc7-5d223813dbac', 3),
  ('taxes',          'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4),
  ('abortion',       'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5),
  ('voting-rights',  'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 6),
  ('civil-rights',   '0bc588c6-39e1-4084-b5de-cac909b8b762', 7);

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_lens uuid;
  v_n    int;
BEGIN
  SELECT id INTO v_lens FROM inform.compass_lenses WHERE key = 'federal';
  IF v_lens IS NULL THEN
    RAISE EXCEPTION 'CC_0086: there is no federal lens to re-derive';
  END IF;

  -- Refuse if the lens is not the 8 rows this file was reviewed against. Somebody
  -- editing it between review and apply is exactly the case where a blind rewrite
  -- would destroy work without saying so.
  SELECT count(*) INTO v_n FROM inform.compass_lens_topics WHERE lens_id = v_lens;
  IF v_n <> 8 THEN
    RAISE EXCEPTION 'CC_0086: the federal lens holds % topics, not the 8 this file was written against', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.compass_lens_topics lt
    JOIN inform.compass_topics t ON t.id = lt.topic_id
   WHERE lt.lens_id = v_lens
     AND t.topic_key NOT IN ('healthcare','taxes','immigration','abortion',
                             'climate-change','deportation','medicare/aid','fossil-fuels');
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: the federal lens holds % topic(s) this file did not expect - re-review before applying', v_n;
  END IF;

  -- Every incoming topic must be asked by the open season and admit the federal
  -- tier. This is the check whose absence let `immigration` rot in place.
  SELECT count(*) INTO v_n
    FROM _cc0086_want w
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_topics_promoted pr
       JOIN inform.season_questions sq ON sq.topic_id = pr.id
       JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
      WHERE pr.id = w.topic_id
   );
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: % of the 8 target topics are not asked by the open season', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0086_want w
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.compass_topic_roles r
      WHERE r.topic_id = w.topic_id AND r.role_scope = 'federal'
   );
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: % of the 8 target topics do not admit the federal tier', v_n;
  END IF;

  -- The ids were copied from a query; prove they still name what the comment says.
  SELECT count(*) INTO v_n
    FROM _cc0086_want w JOIN inform.compass_topics t ON t.id = w.topic_id
   WHERE t.topic_key <> w.topic_key;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: % target row(s) name a topic_key their uuid does not resolve to', v_n;
  END IF;

  RAISE NOTICE 'CC_0086 preconditions OK: federal lens holds the expected 8, all 8 targets asked this season and federal-admitting.';
END $$;

-- -----------------------------------------------------------------------------
-- 2. Re-derive
-- -----------------------------------------------------------------------------
-- Delete then insert, rather than update-in-place: sort_order carries a uniqueness
-- expectation per lens and shuffling six existing rows through it would collide
-- mid-statement.
DELETE FROM inform.compass_lens_topics
 WHERE lens_id = (SELECT id FROM inform.compass_lenses WHERE key = 'federal');

INSERT INTO inform.compass_lens_topics (lens_id, topic_id, sort_order)
SELECT (SELECT id FROM inform.compass_lenses WHERE key = 'federal'), w.topic_id, w.sort_order
  FROM _cc0086_want w;

-- -----------------------------------------------------------------------------
-- 3. Post-verify
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_lens uuid;
  v_n    int;
  v_keys text;
BEGIN
  SELECT id INTO v_lens FROM inform.compass_lenses WHERE key = 'federal';

  SELECT count(*) INTO v_n FROM inform.compass_lens_topics WHERE lens_id = v_lens;
  IF v_n <> 8 THEN
    RAISE EXCEPTION 'CC_0086: federal lens holds % topics after the rewrite, expected 8', v_n;
  END IF;

  -- Membership and order both, against the reviewed list.
  SELECT count(*) INTO v_n
    FROM inform.compass_lens_topics lt
    FULL JOIN _cc0086_want w ON w.topic_id = lt.topic_id AND w.sort_order = lt.sort_order
   WHERE (lt.lens_id = v_lens OR lt.lens_id IS NULL)
     AND (lt.topic_id IS NULL OR w.topic_id IS NULL);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: % row(s) differ from the reviewed membership/order', v_n;
  END IF;

  -- Nothing in the lens may be unasked this season - the immigration failure, as an
  -- assertion rather than a comment.
  SELECT count(*) INTO v_n
    FROM inform.compass_lens_topics lt
   WHERE lt.lens_id = v_lens
     AND NOT EXISTS (
       SELECT 1 FROM inform.compass_topics_promoted pr
         JOIN inform.season_questions sq ON sq.topic_id = pr.id
         JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
        WHERE pr.id = lt.topic_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0086: % lens topic(s) are not asked by the open season', v_n;
  END IF;

  SELECT string_agg(t.topic_key, ' > ' ORDER BY lt.sort_order) INTO v_keys
    FROM inform.compass_lens_topics lt
    JOIN inform.compass_topics t ON t.id = lt.topic_id
   WHERE lt.lens_id = v_lens;

  RAISE NOTICE 'CC_0086 OK: federal lens is now %', v_keys;
  RAISE NOTICE 'CC_0086: immigration and medicare/aid are out; voting-rights and civil-rights are in. No floors move - this file writes no answers.';
END $$;

COMMIT;
