BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-25. Verified: 1 season (number 1, closed,
-- opened 2025-01-01), 44 questions pinned and numbered 1..44, 44 distinct
-- revision pins. 33,164 answers and 33,818 context rows ALL carry a season, a
-- pin and an editor — 0 without any of the three, on either table. 1 distinct
-- editor (4e6dde8f… = chris@empowered.vote). 0 rows on either table cite a
-- revision their season did not pin. Row counts unchanged: nothing created or
-- destroyed, only stamped. Dry-run first inside BEGIN…ROLLBACK; the revert was
-- confirmed (0 seasons, 0 pins, 0 seasoned rows) before applying.
--
-- Probed against real data in a rolled-back transaction, 7/7:
--   1 season 1 pins the revision that was current  -> yes
--   2 a published edit moves the topic's current   -> yes  (SETUP CONTROL:
--       without this passing, case 3 would be vacuous rather than correct)
--   3 season 1's pin after that edit               -> HELD at the old revision
--   4 answers that drifted to the new revision     -> 0
--   5 answers still citing the pinned revision     -> 6
--   6 re-running the backfill UPDATE               -> 0 rows (idempotent)
--   7 re-running the season INSERT                 -> 0 rows (idempotent)
-- Cases 3 and 4 ARE the feature: a ladder edit cannot change the meaning of an
-- answer already stored. Nothing left behind — 46 revisions, 44 current, 44
-- published, counts unchanged after the rollback.
--
-- ⚠ First attempt at this probe FAILED, correctly: a CHECK
-- (compass_topic_revisions_current_is_published) refuses to make a DRAFT
-- revision current. The probe had to publish it first. That constraint is
-- doing real work; do not route around it.
--
-- Note: closed_at landed 2026-08-26 UTC while the public_note says "up to
-- 2026-08-25". Not a contradiction — the note gives the human date seasons were
-- introduced, closed_at is the actual close instant, and prod runs in UTC ahead
-- of Chris's local date.

-- =============================================================================
-- CA_0019: Backfill season 1
-- =============================================================================
-- Task 3 of docs/superpowers/plans/2026-08-25-compass-seasons.md.
-- Requires CA_0017 (the tables) and CA_0018 (the columns).
--
-- The only large-DML task in the plan: 33,164 answers and 33,818 context rows
-- acquire a season, a pinned ladder revision and an editor. Everything stays
-- nullable — the columns are not constrained until Task 6, after every live
-- consumer is season-aware.
--
-- Season 1 is created CLOSED. It is a record of what already happened, not an
-- invitation to write more into it. Because it is closed it does not occupy the
-- seasons_one_open slot, so season 2 can be opened later without moving it.
--
-- editor_id — DECISION, Chris, 2026-08-25. All season-1 rows are stamped
-- Chris Cantrell (Kades, 4e6dde8f-2bd0-4054-824f-4164744165ea), who is the
-- editor of record for the pre-seasons corpus. Per-row authorship was never
-- recorded and cannot be reconstructed, so this is an attribution of
-- responsibility, not a claim about who typed each row — and the season's
-- public_note says exactly that. The alternative considered and rejected was
-- leaving editor_id NULL. Do not "fix" this back.
-- ⚠ It is NOT chrisandrewsedu / 854fbc06… — that is Chris ANDREWS, a different
-- person, who authored the one judicial-bail-pretrial revision. Two Chrises
-- work in this system. Never resolve either by first name or by authorship.
--
-- Pre-flight, measured against prod 2026-08-25 before writing this:
--   44 topics are_live, 44 are is_active, the two flags disagree on 0 —
--     so the is_live-only filter below is safe today.
--   0 topics lack a current published revision, and 0 have more than one,
--     so the revision join pins exactly 44 and cannot fan out.
--   0 answers and 0 context rows reference a topic outside those 44,
--     so the UPDATEs below reach every row and nothing is left stranded.
--   topic_key is unique and non-null across all 44, so the row_number()
--     numbering is reproducible rather than arbitrary.
--   654 context rows have no matching answer. They are backfilled too. They
--     publish nothing while unpaired, but they are part of the corpus.
--
-- Four gate corrections against the plan's draft, all documented at the gate.
-- =============================================================================

INSERT INTO inform.seasons (number, name, status, opened_at, closed_at, public_note)
SELECT 1, 'Season 1', 'closed',
       '2025-01-01T00:00:00Z', now(),
       'The corpus as it stood before seasons existed. Every answer written up to '
       '2026-08-25 is recorded here, pinned to the ladder revision that was current '
       'when seasons were introduced. Per-row authorship was not recorded at the '
       'time, so the whole season is attributed to its editor of record rather '
       'than to whoever typed each individual row.'
WHERE NOT EXISTS (SELECT 1 FROM inform.seasons WHERE number = 1);

-- The season's question set: every live topic, pinned to its current revision,
-- numbered and ordered by topic_key so the numbering is reproducible.
INSERT INTO inform.season_questions
  (season_id, topic_id, topic_revision_id, question_number, display_order)
SELECT s.id, t.id, r.id,
       row_number() OVER (ORDER BY t.topic_key),
       row_number() OVER (ORDER BY t.topic_key)
  FROM inform.seasons s
  CROSS JOIN inform.compass_topics t
  JOIN inform.compass_topic_revisions r
    ON r.topic_id = t.id AND r.is_current AND r.status = 'published'
 WHERE s.number = 1
   AND t.is_live
   AND NOT EXISTS (
     SELECT 1 FROM inform.season_questions sq
      WHERE sq.season_id = s.id AND sq.topic_id = t.id);

UPDATE inform.politician_answers a
   SET season_id = sq.season_id, topic_revision_id = sq.topic_revision_id,
       editor_id = '4e6dde8f-2bd0-4054-824f-4164744165ea'   -- Chris Cantrell (Kades)
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 1
 WHERE sq.topic_id = a.topic_id
   AND a.season_id IS NULL;

UPDATE inform.politician_context c
   SET season_id = sq.season_id, topic_revision_id = sq.topic_revision_id,
       editor_id = '4e6dde8f-2bd0-4054-824f-4164744165ea'   -- Chris Cantrell (Kades)
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 1
 WHERE sq.topic_id = c.topic_id
   AND c.season_id IS NULL;

DO $$
DECLARE v_q int; v_a int; v_c int; v_s int; v_status text;
BEGIN
  -- CORRECTION 1 (not in the draft): season 1 must be exactly one row, closed.
  SELECT count(*) INTO v_s FROM inform.seasons WHERE number = 1;
  IF v_s <> 1 THEN
    RAISE EXCEPTION 'season 1 should be exactly 1 row, found %', v_s; END IF;
  SELECT status::text INTO v_status FROM inform.seasons WHERE number = 1;
  IF v_status <> 'closed' THEN
    RAISE EXCEPTION 'season 1 should be closed, is %', v_status; END IF;

  SELECT count(*) INTO v_q FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id WHERE s.number = 1;
  IF v_q <> 44 THEN
    RAISE EXCEPTION 'season 1 should pin 44 questions, pinned %', v_q; END IF;

  SELECT count(*) INTO v_a FROM inform.politician_answers WHERE season_id IS NULL;
  IF v_a <> 0 THEN
    RAISE EXCEPTION '% answers left without a season', v_a; END IF;

  -- CORRECTION 2: the draft wrote '%%' here, which is a LITERAL percent sign.
  -- That leaves zero placeholders for one argument, so if this check ever
  -- fired it would die with "too many parameters specified for RAISE" instead
  -- of reporting the count. A gate that misreports on failure is not a gate.
  SELECT count(*) INTO v_c FROM inform.politician_context WHERE season_id IS NULL;
  IF v_c <> 0 THEN
    RAISE EXCEPTION '% context rows left without a season', v_c; END IF;

  IF EXISTS (SELECT 1 FROM inform.politician_answers WHERE editor_id IS NULL) THEN
    RAISE EXCEPTION 'answers left without an editor'; END IF;

  -- CORRECTION 3 (not in the draft): the same editor check for context rows.
  IF EXISTS (SELECT 1 FROM inform.politician_context WHERE editor_id IS NULL) THEN
    RAISE EXCEPTION 'context rows left without an editor'; END IF;

  -- Every answer must cite the revision its season actually pinned.
  IF EXISTS (
    SELECT 1 FROM inform.politician_answers a
     WHERE NOT EXISTS (
       SELECT 1 FROM inform.season_questions sq
        WHERE sq.season_id = a.season_id AND sq.topic_id = a.topic_id
          AND sq.topic_revision_id = a.topic_revision_id)
  ) THEN RAISE EXCEPTION 'an answer cites a revision its season did not pin'; END IF;

  -- CORRECTION 4 (not in the draft): the same pin check for context rows.
  -- Task 6 puts a composite FK on both tables, so a context row that cites an
  -- unpinned revision would fail there instead of here — far later, and after
  -- the irreversible key swap has begun.
  IF EXISTS (
    SELECT 1 FROM inform.politician_context c
     WHERE NOT EXISTS (
       SELECT 1 FROM inform.season_questions sq
        WHERE sq.season_id = c.season_id AND sq.topic_id = c.topic_id
          AND sq.topic_revision_id = c.topic_revision_id)
  ) THEN RAISE EXCEPTION 'a context row cites a revision its season did not pin'; END IF;

  RAISE NOTICE 'season 1 backfill OK — 44 questions pinned, % answers, % contexts',
    (SELECT count(*) FROM inform.politician_answers),
    (SELECT count(*) FROM inform.politician_context);
END $$;

COMMIT;
