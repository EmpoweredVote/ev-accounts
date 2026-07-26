-- 1435_race_candidates_provisional_until.sql
-- Replace machine-unreadable expiry PROSE in race_candidates.source with a real date column.
-- Idempotent. NATIONAL in scope, not Racine-specific.
--
-- THE PROBLEM: across the whole table, hundreds of candidate rows carry their own expiry
--   instruction as English inside the `source` text, e.g.
--     "...provisional pre-primary field, cull >= 2026-08-12"
--     "...pre-primary qualified field, cull >= 2026-09-08; independent window to 2026-11-03"
--     "Declared indep/3rd-party (Wikipedia/politics1); provisional -- VA filing deadline 2026-08-04"
--   spanning at least MO, MN, LA, TN, AL, KS, NH, WA, CO, MD, VA, MI and WI, with 13 distinct
--   dates. Nothing can act on that. It is a note to a human who will never read it, and the
--   rows keep being served as if final long after the date passes.
--
--   AS OF 2026-07-25, 17 rows are ALREADY PAST their stated cull date (2026-07-16 and
--   2026-07-22) and are still being presented as current fields. That is the bug this closes.
--
-- THE FIX: `provisional_until date`. Semantics, deliberately narrow so it is unambiguous:
--     NULL      -> not provisional. The field is final as far as we know.
--     <a date>  -> this row is a PRE-RESOLUTION placeholder. On/after that date it must not be
--                  presented as a settled field without re-verification.
--   Pairs with the existing `last_verified_at`: a row is STALE when
--     provisional_until <= CURRENT_DATE AND (last_verified_at IS NULL OR last_verified_at < provisional_until)
--   That is the machine-actionable form of what the prose was trying to say, and it needs no
--   cron to become true — like ELECTION_VISIBILITY_WINDOW, it is simply a fact about the row
--   that the read path can evaluate.
--
-- BACKFILL SAFETY — the important part. A naive "any date in source" regex would have been
--   badly wrong. Classified over the full table:
--     309  provisional wording + parseable date        -> BACKFILLED
--     247  says "decided"                              -> NOT touched. These are settled fields;
--                                                         marking them provisional would hide
--                                                         real candidates.
--     163  provisional wording, NO parseable date      -> left NULL, reported below for review.
--                                                         A migration must not invent a date.
--      57  a date but no provisional wording           -> NOT touched. The date is descriptive,
--                                                         e.g. "Official sample ballot ...
--                                                         (2026-08-11)" or "both AG nominees
--                                                         unopposed in the 2026-08-11 primary".
--   So the backfill requires BOTH a provisional marker AND a parseable date AND the absence of
--   "decided". Three patterns are recognised: `cull >= DATE`, `window [open] to DATE`,
--   `filing deadline DATE`.
--
-- `source` text is intentionally left as-is: it is still the provenance record. What changes is
--   that the *instruction* embedded in it is now also structured data.
--
-- FOLLOW-UP, not done here: the 163 provisional rows with no parseable date need a date from
--   their own election. The general answer is that a pre-primary field resolves on its primary's
--   election_date, which is already in essentials.elections — but mapping each general race to
--   the primary that resolves it is not reliably derivable in one migration across every state's
--   rules (LA's jungle primary has no separate partisan primary at all). Query
--   essentials.stale_provisional_candidates plus the reported list to work through them.
BEGIN;

-- ── 1. The column ──
ALTER TABLE essentials.race_candidates
  ADD COLUMN IF NOT EXISTS provisional_until date;

COMMENT ON COLUMN essentials.race_candidates.provisional_until IS
  'NULL = field is final as far as we know. A date = this row is a pre-resolution placeholder '
  'and must not be presented as a settled field on/after that date without re-verification. '
  'Replaces expiry instructions that used to live as English prose inside source (migration 1456). '
  'Stale when provisional_until <= CURRENT_DATE AND (last_verified_at IS NULL OR last_verified_at < provisional_until).';

-- ── 2. Backfill: requires a provisional marker AND a parseable date AND NOT "decided" ──
UPDATE essentials.race_candidates rc
   SET provisional_until = parsed::date
  FROM (
    SELECT id,
           coalesce(
             substring(source from 'cull\s*>=\s*(\d{4}-\d{2}-\d{2})'),
             substring(source from 'window (?:open )?to\s*(\d{4}-\d{2}-\d{2})'),
             substring(source from 'filing deadline\s*(\d{4}-\d{2}-\d{2})')
           ) AS parsed
      FROM essentials.race_candidates
     WHERE source ~* 'provisional|pre-primary|cull|filing deadline'
       AND source !~* '\mdecided\M'
  ) s
 WHERE s.id = rc.id
   AND s.parsed IS NOT NULL
   AND rc.provisional_until IS DISTINCT FROM s.parsed::date;

-- ── 3. Index for the staleness sweep ──
CREATE INDEX IF NOT EXISTS race_candidates_provisional_until_idx
  ON essentials.race_candidates (provisional_until)
  WHERE provisional_until IS NOT NULL;

-- ── 4. A view the pipeline can actually act on, replacing the prose reminder ──
CREATE OR REPLACE VIEW essentials.stale_provisional_candidates AS
SELECT rc.id                AS race_candidate_id,
       rc.race_id,
       rc.full_name,
       rc.candidate_status,
       rc.provisional_until,
       rc.last_verified_at,
       e.name              AS election_name,
       e.election_date,
       r.position_name,
       r.primary_party,
       CURRENT_DATE - rc.provisional_until AS days_overdue
  FROM essentials.race_candidates rc
  JOIN essentials.races r     ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
 WHERE rc.provisional_until IS NOT NULL
   AND rc.provisional_until <= CURRENT_DATE
   AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);

COMMENT ON VIEW essentials.stale_provisional_candidates IS
  'Candidate rows whose provisional_until date has passed without re-verification. These are '
  'pre-resolution placeholders now being served as if final — the condition that used to be '
  'expressed only as "cull >= <date>" prose inside race_candidates.source.';

-- ── 5. Post-verify gate ──
DO $$
DECLARE n_set int; n_decided int; n_undated int; n_stale int; n_wrong int;
BEGIN
  SELECT count(*) INTO n_set FROM essentials.race_candidates WHERE provisional_until IS NOT NULL;
  IF n_set < 300 THEN
    RAISE EXCEPTION 'provisional_until backfill set only % rows; expected ~309', n_set;
  END IF;

  -- nothing marked "decided" may have been flagged provisional
  SELECT count(*) INTO n_decided FROM essentials.race_candidates
   WHERE provisional_until IS NOT NULL AND source ~* '\mdecided\M';
  IF n_decided <> 0 THEN
    RAISE EXCEPTION '% settled ("decided") rows were wrongly marked provisional', n_decided;
  END IF;

  -- nothing lacking a provisional marker may have been flagged
  SELECT count(*) INTO n_wrong FROM essentials.race_candidates
   WHERE provisional_until IS NOT NULL
     AND source !~* 'provisional|pre-primary|cull|filing deadline';
  IF n_wrong <> 0 THEN
    RAISE EXCEPTION '% rows flagged provisional without any provisional marker in source', n_wrong;
  END IF;

  SELECT count(*) INTO n_undated FROM essentials.race_candidates
   WHERE provisional_until IS NULL
     AND source ~* 'provisional|pre-primary|cull|filing deadline'
     AND source !~* '\mdecided\M';
  RAISE NOTICE 'provisional_until: % rows dated, % provisional rows still undated (need a date from their election)', n_set, n_undated;

  SELECT count(*) INTO n_stale FROM essentials.stale_provisional_candidates;
  RAISE NOTICE 'stale_provisional_candidates: % rows are ALREADY past their date and being served as final', n_stale;

  RAISE NOTICE 'provisional_until verify PASSED: 0 decided rows flagged, 0 unmarked rows flagged.';
END $$;

COMMIT;
