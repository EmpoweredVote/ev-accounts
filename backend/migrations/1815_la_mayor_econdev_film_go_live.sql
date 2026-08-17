-- 1815_la_mayor_econdev_film_go_live.sql
--
-- Two things for the LA Mayor GENERAL race (9e888818, Bass v Raman, 2026-11-03):
--
--   1. Make the film/TV production question (025217d5) rankable by selecting one quote per
--      candidate. It is currently the race's only economic-development question with any live
--      material, and the race has just 1 rankable question out of 25.
--   2. Repair an opponent-naming de-identification on Raman's downtown quote (f7625f7b) that
--      would break the blind premise if anyone selected it.
--
-- ── WHY ONLY ONE ECON-DEV QUESTION CAN BE LIVE (for now) ──────────────────────────────────────
--
-- essentials.quotes carries a partial unique index from migration 293, captioned there as
-- "Enforce at most one selected per stance":
--
--     quotes_one_selected_per_stance UNIQUE (politician_id, lower(topic_key)) WHERE readrank_selected
--
-- All eight econ-dev quotes on this race carry topic_key='economic-development', so only ONE of
-- the race's three econ-dev questions can hold selected quotes for Bass and Raman. Selecting the
-- film pair below therefore forecloses the downtown (263728ff) and pooled (ded400bd) questions for
-- these two candidates.
--
-- That foreclosure is TEMPORARY AND FIXABLE, not a permanent editorial loss, but the fix is app
-- work and deliberately out of scope here. 293 predates the question-as-unit design by ~1084
-- migrations (readrank_questions and quotes.question_id arrive in 1377), and the PLAYER path never
-- followed 1377 -- it is still topic-grouped in two places:
--
--   * getRaceBlindQuotes (readrankService.ts) buckets quotes into a Map keyed by lower(topic_key)
--     and gives each topic ONE question string, COALESCE(rq.question_text, rtq..., ct...), taken
--     from whichever row created the bucket first.
--   * getPlayableRaces counts rankable TOPICS: GROUP BY lower(q2.topic_key) HAVING
--     COUNT(DISTINCT politician_id) >= 2.
--
-- So the index is not a stale leftover that can simply be dropped: today it is what PREVENTS a
-- corruption. Two live questions in one topic would merge into a single card showing one question
-- text (chosen nondeterministically -- the ORDER BY is on topic title, leaving intra-topic order
-- unspecified) above quotes answering the other question. Making both econ-dev questions live
-- requires grouping the blind payload by question (with a topic fallback for the compass-era rows
-- where question_id IS NULL), counting rankable questions instead of topics, and only then
-- reworking the index. Tracked separately.
--
-- ── WHY THE FILM QUESTION, AND WHY THESE TWO QUOTES ──────────────────────────────────────────
--
-- POOLED (ded400bd) is unusable on BOTH sides:
--   * Bass ce9bb5b9 is pure record -- "permits were expedited", "observatory fees reduced by 70%",
--     "the industry is beginning to come back". Only an incumbent can have already done those
--     things, so its passive-voice de-identification does not restore blindness. It also fails the
--     standard applied inside this very cluster: b2d1f06d's editor_note cut Bass's record-reciting
--     half as "record rather than a position".
--   * Raman e7f20cf7 ("Small businesses are what gives a neighborhood its character") names no
--     mechanism, which is precisely why 1812 left it behind on the pooled question.
--
-- DOWNTOWN (263728ff) is strong on Bass's side (b2d1f06d) but compromised on Raman's: f7625f7b
--   names the opponent, and in a TWO-candidate race naming one candidate de-anonymises both cards.
--   Repaired below, so it is ready whenever the follow-up above unlocks it.
--
-- FILM (025217d5) has two well-sourced options per candidate and yields a legible contrast: Bass
--   removes obstacles case by case; Raman builds city capacity.
--
--   Bass 469318c6 (TheWrap) over bc34b38f (Hollywood Reporter): its note records it as her WHOLE
--     answer, verbatim, no edits and no record, where bc34b38f's "continuing to look for ways"
--     signals incumbency and so weakens the blind premise.
--   Raman 644bc8e7 (NBC LA debate) over 79641bcb: 1812 already flagged 79641bcb's uncapped tax
--     credit as a STATE lever, which paired against Bass's city levers would compare different
--     things. 644bc8e7 is city-lever throughout -- red tape in City Hall, a real film office,
--     staffing, cross-county coordination.
--
-- ── THE DE-IDENTIFICATION REPAIR ─────────────────────────────────────────────────────────────
--
-- f7625f7b's deidentified_text was a verbatim copy of quote_text, carrying "Instead, what Mayor
-- Bass has done is to dismantle our economic development department." Not reachable today -- every
-- player path gates on readrank_selected and the row is a draft -- but 1812 flagged it as a latent
-- hazard and the repair outlives the selection question.
--
-- quote_text is left VERBATIM; only deidentified_text is trimmed. The criticism is a real, sourced
-- statement and belongs in the record. deidentified_text is the served, blind-safe rendering and is
-- allowed to diverge -- ce9bb5b9 already does, flattening first person to passive. The trim is at a
-- sentence boundary with no trailing ellipsis, matching how bc34b38f was handled.
--
-- Idempotent. Dry-run as BEGIN; ... ROLLBACK; before applying.
--
-- Applied to prod 2026-08-17 via execute_sql (no schema_migrations row -- house norm).
-- Authored as 1814 and renumbered to 1815 when Fort Worth took that number mid-session;
-- nothing written to prod embeds the number, so this rename carries no data drift.

BEGIN;

-- ── 1. Select the film pair ───────────────────────────────────────────────────────────────────

UPDATE essentials.quotes
   SET readrank_selected = true,
       updated_at        = now()
 WHERE id IN ('469318c6-4f60-48b8-9e05-a5ac76630d13'::uuid,   -- Bass, TheWrap
               '644bc8e7-4545-4f50-b40e-0c2b6ae0a055'::uuid)  -- Raman, NBC LA debate
   AND readrank_selected = false;

-- Raman's debate answer arrived via 1812 with no editor_note; it is being published now, so it
-- needs the same accounting as its neighbours.
UPDATE essentials.quotes
   SET editor_note = 'Selected as Raman''s film answer over the uncapped-tax-credit quote '
                  || '(79641bcb), which 1812 flagged as a STATE lever: pairing it against Bass''s '
                  || 'city levers would compare different things. This answer is city-lever '
                  || 'throughout -- reducing red tape in City Hall, creating a real film office, '
                  || 'staffing it with people who know the industry, coordinating across county '
                  || 'jurisdictions. Verbatim, no edits, no record. Carries a mechanism '
                  || '(institutional capacity) rather than a goal.',
       updated_at  = now()
 WHERE id = '644bc8e7-4545-4f50-b40e-0c2b6ae0a055'::uuid
   AND editor_note IS NULL;

-- ── 2. Repair the opponent-naming de-identification ───────────────────────────────────────────

UPDATE essentials.quotes
   SET deidentified_text =
         'Downtown LA needs attention, and it needs real care. It needs more public safety '
      || 'officials on the streets. It needs work with businesses to ensure that businesses '
      || 'aren''t just fleeing downtown LA, that they''re actually staying there. It needs '
      || 'regular cleanups. It needs real maintenance. It needs a strategy.',
       editor_note = 'deidentified_text trimmed at a sentence boundary before "Instead, what '
                  || 'Mayor Bass has done...", dropping the closing two sentences. Naming the '
                  || 'opponent de-anonymises BOTH cards in a two-candidate race: it tells the '
                  || 'reader the other card is Bass''s and therefore that this one is not. '
                  || 'quote_text is left VERBATIM -- the criticism is real and sourced and belongs '
                  || 'in the record; deidentified_text is the served, blind-safe rendering and may '
                  || 'diverge (cf. ce9bb5b9, first person flattened to passive). What survives is '
                  || 'the whole forward answer: public safety officials, business retention, '
                  || 'cleanups, maintenance, a strategy. No trailing ellipsis, matching bc34b38f.',
       updated_at  = now()
 WHERE id = 'f7625f7b-634f-49d4-9155-ab38455ba400'::uuid
   AND deidentified_text LIKE '%Mayor Bass%';

-- ── Post-verify ───────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  n_sel      int;
  n_answer   int;
  n_stray    int;
  n_leak     int;
  n_verbatim int;
BEGIN
  -- Gate 1: exactly the two intended quotes are selected on the film question.
  SELECT count(*) INTO n_sel
    FROM essentials.quotes
   WHERE question_id = '025217d5-8c55-465c-86ae-f206634740d6'::uuid
     AND readrank_selected;
  IF n_sel <> 2 THEN
    RAISE EXCEPTION 'Aborting: expected 2 selected quotes on the film question, found %.', n_sel;
  END IF;

  -- Gate 2: the film question is RANKABLE through the real listRaceQuestions predicate --
  -- two distinct live candidates, each with readrank_selected + deidentified_text.
  SELECT count(DISTINCT rc.politician_id) INTO n_answer
    FROM essentials.quotes q
    JOIN essentials.race_candidates rc
      ON rc.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'::uuid
     AND rc.politician_id = q.politician_id
     AND essentials.is_live_candidate(rc.candidate_status, rc.result)
   WHERE q.question_id = '025217d5-8c55-465c-86ae-f206634740d6'::uuid
     AND q.readrank_selected
     AND q.deidentified_text IS NOT NULL;
  IF n_answer <> 2 THEN
    RAISE EXCEPTION 'Aborting: film question not rankable -- % live answering candidate(s).', n_answer;
  END IF;

  -- Gate 3: no econ-dev quote is selected anywhere ELSE for these two candidates. Redundant with
  -- quotes_one_selected_per_stance, but states the invariant the choice of question rests on, so a
  -- future index rework cannot silently void it.
  SELECT count(*) INTO n_stray
    FROM essentials.quotes q
   WHERE lower(q.topic_key) = 'economic-development'
     AND q.readrank_selected
     AND q.question_id IS DISTINCT FROM '025217d5-8c55-465c-86ae-f206634740d6'::uuid
     AND q.politician_id IN (SELECT politician_id FROM essentials.race_candidates
                              WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'::uuid);
  IF n_stray <> 0 THEN
    RAISE EXCEPTION 'Aborting: % selected econ-dev quote(s) outside the film question.', n_stray;
  END IF;

  -- Gate 4: the load-bearing one. NO quote served on this race may name either candidate in its
  -- deidentified_text. This is the blind premise itself, asserted over every selected quote on the
  -- race rather than just the row being repaired.
  SELECT count(*) INTO n_leak
    FROM essentials.quotes q
    JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'::uuid
     AND q.readrank_selected
     AND q.deidentified_text ~* '\y(Bass|Raman|Karen|Nithya)\y';
  IF n_leak <> 0 THEN
    RAISE EXCEPTION 'Aborting: % selected quote(s) name a candidate in deidentified_text.', n_leak;
  END IF;

  -- Gate 5: the repair touched only the served rendering. quote_text stays verbatim, so the record
  -- of what Raman actually said is intact.
  SELECT count(*) INTO n_verbatim
    FROM essentials.quotes
   WHERE id = 'f7625f7b-634f-49d4-9155-ab38455ba400'::uuid
     AND quote_text LIKE '%Mayor Bass%'
     AND deidentified_text NOT LIKE '%Bass%';
  IF n_verbatim <> 1 THEN
    RAISE EXCEPTION 'Aborting: f7625f7b should keep verbatim quote_text and a scrubbed deid.';
  END IF;

  RAISE NOTICE 'OK: film question rankable (2 candidates); no candidate named in any served quote.';
END $$;

COMMIT;
