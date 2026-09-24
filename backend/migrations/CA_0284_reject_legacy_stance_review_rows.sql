BEGIN;

-- ⚠ NOT APPLIED. Dry-run on production 2026-09-24 inside BEGIN…ROLLBACK (see
-- .superpowers/sdd/2026-09-23-stance-program-reconciliation/final-fix2-report.md);
-- apply only with the operator's explicit OK.

-- =============================================================================
-- CA_0284: reject the 28 legacy pending stance-review rows (ruling 2026-09-24)
-- =============================================================================
-- Final whole-branch review of claude/stance-research-hardening, finding I4.
-- Operator ruling (Chris Andrews, 2026-09-24): REJECT all 28.
--
-- inform.stance_research_review holds 28 rows with status = 'pending' that were
-- queued on 2026-06-05 by three batches:
--
--   2026-06-04-ut-house-sonnet            10
--   2026-06-05-slco-primary               11
--   2026-06-05-slco-primary-national       7
--
-- They were researched against Season 1 ladders (June 2026). None of them
-- recorded a ladder revision (topic_revision_id IS NULL — CA_0264 did not
-- backfill, on purpose), so approval would publish them into Season 2 against a
-- sentence nobody checked. Four of their topics are among the 13 whose served
-- rung text differs from the pin (public-safety-approach, residential-zoning,
-- jail-capacity, transportation-priorities), and some ask `immigration`, which
-- Season 2 does not ask at all. They would also sit in the same cohort view as
-- the Monroe County test batch.
--
-- WHAT THIS DOES: status 'pending' -> 'rejected', resolved_at = now(), and
-- APPENDS the ruling's note verbatim (an existing note is kept):
--   "researched against a Season 1 ladder (June 2026); re-research if needed — ruling 2026-09-24"
-- resolved_by stays NULL: this is a ruling applied by migration, not a person's click, and the note says whose
-- ruling it is. Nothing is deleted — the research stays readable, and a row can
-- be re-researched through a new batch if it is still wanted.
--
-- It touches NO answer, context or evidence row. None of these 28 was ever
-- approved, so nothing they proposed is published. (No @context-decision is
-- needed: nothing is deleted from inform.politician_answers.)
--
-- IDEMPOTENT: the UPDATE matches only rows still 'pending', so a second run
-- changes nothing and appends no second note. The pre-gate accepts either state
-- (28 pending, or 28 already rejected by this migration) and refuses anything
-- else, so it cannot silently act on a different set.
-- =============================================================================

-- Pre-gate: the target set is exactly the 28 rows the review measured.
DO $$
DECLARE
  v_pending int;
  v_done    int;
BEGIN
  SELECT count(*) INTO v_pending
    FROM inform.stance_research_review
   WHERE status = 'pending'
     AND topic_revision_id IS NULL
     AND created_at < '2026-09-23'
     AND batch_id IN ('2026-06-04-ut-house-sonnet', '2026-06-05-slco-primary',
                      '2026-06-05-slco-primary-national');
  SELECT count(*) INTO v_done
    FROM inform.stance_research_review
   WHERE status = 'rejected'
     AND notes LIKE '%researched against a Season 1 ladder (June 2026); re-research if needed — ruling 2026-09-24%';
  IF v_pending + v_done <> 28 THEN
    RAISE EXCEPTION 'CA_0284: expected 28 legacy rows (pending or already rejected by CA_0284), found % pending + % done',
      v_pending, v_done;
  END IF;
  -- Rows queued after 2026-09-23 (they carry topic_revision_id) are not in the
  -- set and are left alone, whatever their status.
END $$;

UPDATE inform.stance_research_review
   SET status      = 'rejected',
       resolved_at = now(),
       notes       = concat_ws(E'\n', notes,
         'researched against a Season 1 ladder (June 2026); re-research if needed — ruling 2026-09-24')
 WHERE status = 'pending'
   AND topic_revision_id IS NULL
   AND created_at < '2026-09-23'
   AND batch_id IN ('2026-06-04-ut-house-sonnet', '2026-06-05-slco-primary',
                    '2026-06-05-slco-primary-national');

-- Post-verify gate: exactly 28 rejected with the note, none of them still pending.
DO $$
DECLARE
  v_done     int;
  v_left     int;
  v_by_batch text;
BEGIN
  SELECT count(*) INTO v_done
    FROM inform.stance_research_review
   WHERE status = 'rejected'
     AND notes LIKE '%researched against a Season 1 ladder (June 2026); re-research if needed — ruling 2026-09-24%';
  SELECT count(*) INTO v_left
    FROM inform.stance_research_review
   WHERE status = 'pending' AND topic_revision_id IS NULL AND created_at < '2026-09-23';
  IF v_done <> 28 THEN
    RAISE EXCEPTION 'CA_0284: expected 28 rows rejected with the ruling note, found %', v_done;
  END IF;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'CA_0284: % legacy row(s) still pending', v_left;
  END IF;
  SELECT string_agg(batch_id || '=' || n, ', ' ORDER BY batch_id) INTO v_by_batch
    FROM (SELECT batch_id, count(*) AS n FROM inform.stance_research_review
           WHERE notes LIKE '%researched against a Season 1 ladder (June 2026); re-research if needed — ruling 2026-09-24%' GROUP BY batch_id) b;
  IF v_by_batch IS DISTINCT FROM
     '2026-06-04-ut-house-sonnet=10, 2026-06-05-slco-primary=11, 2026-06-05-slco-primary-national=7' THEN
    RAISE EXCEPTION 'CA_0284: unexpected per-batch split: %', v_by_batch;
  END IF;
  RAISE NOTICE 'CA_0284 ok: 28 legacy rows rejected (%)', v_by_batch;
END $$;

COMMIT;
