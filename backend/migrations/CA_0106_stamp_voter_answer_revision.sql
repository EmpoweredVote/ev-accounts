BEGIN;

-- =============================================================================
-- CA_0106: Backfill answered_revision_id on the open season's unstamped answers
-- =============================================================================
-- Implements the backfill half of ev-cto decision 0011, and the ev-cto task
-- 2026-09-07-backfill-15-unpinned-compass-answers.
--
-- 🔴 THIS FILE WAS REWRITTEN BEFORE IT WAS EVER APPLIED (2026-10-26, Chris
-- Andrews). The version merged in PR #441 (2026-09-09) was never run on prod,
-- and must not be: three of its four parts are now wrong.
--
--   * It redefined public.upsert_compass_answer with
--     `ON CONFLICT (user_id, topic_id)`. compass_responses' primary key has
--     since become (user_id, topic_id, season_id), so that RPC would have
--     raised on EVERY answer write. It would also have reverted CC_0066's
--     open-season topic gate back to is_live.
--   * It stamped on the write path from inside the RPC. CC_0067 (2026-09-04)
--     already does that, with a trigger, because the RPC is not the only
--     writer. A second stamping site is a second rule to keep in sync.
--   * Its backfill was unconditional, so it UPDATEd Season-1 rows. Season 1 is
--     closed, and compass_responses_closed_season_immutable rejects that —
--     the dry-run failure that stopped it on 2026-09-09.
--
-- So what is left is the backfill, scoped to the OPEN season.
--
-- WHAT IS UNSTAMPED, measured 2026-10-26 on prod: 15 compass_responses rows,
-- all written 2026-09-04 (Season 2 opened that day; CC_0067's trigger landed
-- hours later), all one user. 14 sit in closed Season 1 and are left NULL on
-- purpose — a closed season is sealed (ADR 0005), a closed answer is never
-- recalibrated, and CC_0061 reads NULL as "fresh". 1 sits in the open season
-- and is stamped here.
--
-- WHICH REVISION. Resolved exactly as CC_0067's trigger, getPromotedTopics()
-- and CC_0061 resolve it (ADR 0006 Option Y): the LATEST published/superseded
-- revision of the VERSION the open season PINNED — not is_current. Stamping
-- is_current would write a revision the disposition rule never compares
-- against, and the backfill would look done while changing nothing.
--
-- NEVER LOSES A VIEW. A row whose topic resolves to no revision keeps its NULL
-- and is reported, not failed (CC_0067's precedent).
--
-- OUT OF SCOPE, deliberately:
--   * inform.compass_change_history. Nothing stamps it on write — CC_0067's
--     trigger is on compass_responses only — so every history row since
--     2026-08-21 is NULL. Stamping those audit rows with today's revision would
--     assert a revision nobody recorded. A separate question.
--   * upsert_compass_answer, the trigger, and the season model.
--
-- Idempotent: guarded on IS NULL and scoped to the open season, so a re-run
-- touches nothing. Dry-run under BEGIN; ... ROLLBACK; first.
-- =============================================================================

-- The trigger would re-resolve the stamp itself on this UPDATE (NEW is NULL ->
-- restamp), but setting it explicitly keeps the rule visible here and keeps the
-- migration correct even if the trigger is ever absent.
UPDATE inform.compass_responses r
   SET answered_revision_id = (
         SELECT e.id
           FROM inform.compass_topics_promoted p
           JOIN inform.compass_topic_revisions pin ON pin.id = p.season_revision_id
           JOIN inform.compass_topic_revisions e
             ON e.topic_id = pin.topic_id
            AND e.version  = pin.version
            AND e.status IN ('published', 'superseded')
          WHERE p.id = r.topic_id
          ORDER BY e.revision DESC
          LIMIT 1)
  FROM inform.seasons s
 WHERE s.id = r.season_id
   AND s.status = 'open'
   AND r.answered_revision_id IS NULL;


-- -----------------------------------------------------------------------------
-- Post-verify. Reports what is left rather than raising on it, so a partial
-- result is visible instead of rolling back a good backfill. It raises only on
-- a stamp that disagrees with the season-pinned rule.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_open_null    int;
  v_closed_null  int;
  v_wrong        int;
BEGIN
  SELECT count(*) INTO v_open_null
    FROM inform.compass_responses r JOIN inform.seasons s ON s.id = r.season_id
   WHERE s.status = 'open' AND r.answered_revision_id IS NULL;

  SELECT count(*) INTO v_closed_null
    FROM inform.compass_responses r JOIN inform.seasons s ON s.id = r.season_id
   WHERE s.status = 'closed' AND r.answered_revision_id IS NULL;

  -- Every open-season row written 2026-09-04 (the unstamped day) must point at
  -- the season-pinned revision, joined through the season's own pin.
  SELECT count(*) INTO v_wrong
    FROM inform.compass_responses r
    JOIN inform.seasons s ON s.id = r.season_id AND s.status = 'open'
    JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = r.topic_id
    JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
   WHERE r.updated_at::date = DATE '2026-09-04'
     AND r.answered_revision_id IS DISTINCT FROM (
       SELECT e.id FROM inform.compass_topic_revisions e
        WHERE e.topic_id = pin.topic_id AND e.version = pin.version
          AND e.status IN ('published', 'superseded')
        ORDER BY e.revision DESC LIMIT 1);

  IF v_wrong <> 0 THEN
    RAISE EXCEPTION 'CA_0106: % open-season rows from 2026-09-04 do not point at the season-pinned revision', v_wrong;
  END IF;

  RAISE NOTICE 'CA_0106: open-season NULL stamps remaining = % (expected 0; any are topics with no publishable revision)', v_open_null;
  RAISE NOTICE 'CA_0106: closed-season NULL stamps left sealed = % (expected 14)', v_closed_null;
END $$;

COMMIT;
