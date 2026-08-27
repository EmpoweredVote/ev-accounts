BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-27 21:10 UTC, on Chris Andrews' instruction.
-- Dry-run first inside BEGIN…ROLLBACK and the rollback confirmed; prod state was
-- re-read immediately before applying and was still closed/44/33,164.
--
-- Applied via scripts/apply-migration-file.mjs: stmt0 UPDATE = 1, and the
-- migration's own gate passed — "season 1 open, 44 pinned questions, 33164
-- answers untouched".
--
-- Verified AFTER, read back independently rather than trusting the clean exit:
--   season 1        = open, closed_at NULL, updated_at 2026-08-27T21:10:14Z
--   public_note     = rewritten (no longer claims the corpus is sealed)
--   writable topics = 44
--   answers         = 33,164 across 1 distinct season — unchanged
--   context rows    = 33,818 — unchanged
--   scaffolding     = BOTH INDEXES STILL UP. Season 2 remains blocked, by design.
--   season-based promoted view would return 44
--
-- 🔴 AND THE THING THAT ACTUALLY MATTERED, proved rather than assumed: the real
-- UPSERT_ANSWER_SQL shape was run against a real politician/topic pair in a
-- rolled-back transaction. It affected 1 row (it affected ZERO before this
-- migration), changed the value, and stamped both season_id and
-- topic_revision_id. The compass write path is live again.
--
-- TO REVERT: set status='closed' with a closed_at, and restore CA_0019's
-- public_note. Nothing else moved.
--
-- =============================================================================
-- CA_0020: Reopen Season 1, so the season model runs on the live path
-- =============================================================================
-- Requires CA_0017, CA_0018, CA_0019, CC_0001, CC_0002, CC_0003 — all applied.
--
-- WHAT IS WRONG RIGHT NOW
-- Season 1 is `closed` and no season is `open`. Every compass write path resolves
-- its season from `inform.seasons WHERE status = 'open'`, so every one of them
-- currently refuses:
--   · seasonService.UPSERT_ANSWER_SQL and its three siblings write ZERO rows,
--     and each caller's assertWritten turns that into a thrown Error.
--   · public.admin_update_politician_answers refuses with NO_OPEN_SEASON.
--   · connect.confirm_vq_stance refuses with NO_OPEN_SEASON_FOR_TOPIC.
-- The data is safe and the refusals are clean. But compass writing is DOWN, and
-- it has been since 2026-08-26.
--
-- 🔴 THIS MIGRATION SUPERSEDES A DELIBERATE DECISION IN CA_0019. Say so plainly.
-- CA_0019 created Season 1 closed, and its header explains why: "It is a record
-- of what already happened, not an invitation to write more into it. Because it
-- is closed it does not occupy the seasons_one_open slot, so season 2 can be
-- opened later without moving it."
--
-- That reasoning was sound ON ITS OWN ASSUMPTION — that Season 2 would open
-- shortly afterwards. Season 2 did not open, and cannot yet: CC_0002 left the
-- two legacy-pair scaffolding indexes up ON PURPOSE, and while they are up the
-- database physically cannot hold a second season. So the state CA_0019 treated
-- as a brief handover became an open-ended outage.
--
-- WHY REOPEN SEASON 1 RATHER THAN OPEN SEASON 2
-- Opening Season 2 also fixes the outage, and it is where we are going. But it
-- changes two things at once: it turns the season model on AND exercises the
-- changeover, and it requires dropping the scaffolding first — the step CC_0002
-- calls irreversible. Reopening Season 1 changes ONE thing. It proves the season
-- model works end to end across the sites against a question set already known
-- to be correct (44 topics, every pin equal to its topic's current revision,
-- verified 2026-08-27). Season 2 then changes the question set with the
-- machinery already proven.
--
-- It is also reversible: set status back to 'closed' with a closed_at.
--
-- ⚠ WHAT REOPENING COSTS, AND WHY public_note IS REWRITTEN BELOW
-- Season 1 stops being a sealed record. New answers will land in it, and they
-- will sit alongside the 33,164 backfilled rows with nothing in the row to tell
-- them apart. That is the real price, and it is accepted deliberately: the
-- alternative is leaving writes broken until Season 2 is ready.
--
-- It makes CA_0019's public_note FALSE. That note is reader-facing and currently
-- claims "Every answer written up to 2026-08-25 is recorded here", which stops
-- being true the moment anyone writes. A note in prod must not assert something
-- the data contradicts, so it is rewritten in the same statement that reopens.
--
-- The editor-of-record attribution is NOT affected and must not be touched.
-- `editor_id` is per row: the backfilled rows stay attributed to Chris Cantrell
-- (Kades, 4e6dde8f-…) as CA_0019 decided, and new rows carry whoever actually
-- wrote them.
-- =============================================================================

UPDATE inform.seasons
   SET status      = 'open',
       closed_at   = NULL,
       public_note =
         'The corpus as it stood before seasons existed, and the season now open. '
         'Every answer written up to 2026-08-25 was recorded here by backfill, '
         'pinned to the ladder revision that was current when seasons were '
         'introduced; per-row authorship was not recorded at the time, so those '
         'rows are attributed to their editor of record rather than to whoever '
         'typed each one. Season 1 was briefly closed while the season model was '
         'built, and was reopened on 2026-08-27 so that answers could be recorded '
         'again before Season 2 is ready. Answers written after that date are '
         'individually attributed.',
       updated_at  = now()
 WHERE number = 1
   AND status = 'closed';

-- -----------------------------------------------------------------------------
-- Post-verify gate.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_open int; v_pinned int; v_answers int; v_status text; v_closed timestamptz;
BEGIN
  SELECT count(*) INTO v_open FROM inform.seasons WHERE status = 'open';
  IF v_open <> 1 THEN
    RAISE EXCEPTION 'CA_0020: expected exactly 1 open season, got %', v_open;
  END IF;

  SELECT status::text, closed_at INTO v_status, v_closed
    FROM inform.seasons WHERE number = 1;
  IF v_status <> 'open' THEN
    RAISE EXCEPTION 'CA_0020: season 1 should be open, is %', v_status;
  END IF;
  IF v_closed IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0020: season 1 closed_at should be NULL, is %', v_closed;
  END IF;

  -- Every write path resolves the open season's question set. If the pins did
  -- not come with it, reopening would restore writes for SOME topics only —
  -- a far worse state than the clean refusal we have now.
  SELECT count(*) INTO v_pinned
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open';
  IF v_pinned <> 44 THEN
    RAISE EXCEPTION 'CA_0020: expected 44 pinned questions in the open season, got %',
      v_pinned;
  END IF;

  -- A status flip must not move answer rows. Assert it rather than assume it.
  SELECT count(*) INTO v_answers FROM inform.politician_answers;
  IF v_answers <> 33164 THEN
    RAISE EXCEPTION 'CA_0020: answer count changed: expected 33164, got %', v_answers;
  END IF;

  RAISE NOTICE 'CA_0020 OK — season 1 open, % pinned questions, % answers untouched',
    v_pinned, v_answers;
END $$;

COMMIT;
