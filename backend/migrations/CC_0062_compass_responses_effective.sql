BEGIN;

-- =============================================================================
-- CC_0062: one place a suppressed answer stops being an answer
-- =============================================================================
-- Created 2026-09-03 with Chris Cantrell. The read side of the calibration
-- re-ask; CC_0061 is the rule, this is where the rule takes effect.
--
-- CC_0061 decides, per answer, whether it still means what it meant:
--
--   fresh | reworded   the stored value still points where the user put it
--   moved | invalidated   it does not, and must not be shown or scored
--
-- 🔴 WHY A VIEW AND NOT ELEVEN JOINS. Eleven reads in the backend read a user's
-- answers, and every one of them would have needed the same join onto
-- inform.compass_answer_dispositions. That is eleven chances to get it wrong
-- once and eleven more every time somebody adds a twelfth read — and the failure
-- is silent and asymmetric: a missed join shows a voter a stance on a rung the
-- person never chose, with nothing anywhere reporting that it happened.
--
-- So suppression is expressed ONCE, here, and the eleven reads change one
-- identifier. This is the same argument CC_0061 makes about the rule itself, one
-- level up: `compass_responses_current` answers "which season's answer is
-- theirs", and `compass_responses_effective` answers "and does it still stand".
--
-- ⚠ IT WRAPS THE COLLAPSE, IT DOES NOT REPLACE IT. Reading FROM
-- compass_responses_current means the newest-season collapse (CC_0046) happens
-- FIRST and the suppression filter applies to its result. That ordering is
-- load-bearing for the same reason getCandidateAnswers documents for
-- `deleted_at`: filtering inside the collapse would let an older season's answer
-- stand in for a newer one that should have hidden it.
--
-- ⚠ deleted_at IS FILTERED HERE. compass_responses_current deliberately does
-- not, leaving it to consumers — but every one of the eleven applies it, and
-- compass_answer_dispositions already applies it too, so applying it here keeps
-- the two sides of the join over the identical row set. Consumers that keep
-- their own `deleted_at IS NULL` are then redundant, not wrong, and the column
-- is still exposed so those predicates continue to parse.
--
-- 🔴 IT FAILS OPEN, DELIBERATELY. LEFT JOIN plus COALESCE(disposition,'fresh'),
-- so an answer with no disposition row is SHOWN rather than hidden. By the
-- view's construction that cannot happen — both sides read the same collapsed,
-- non-deleted row set — but if it ever did, the two directions are not
-- symmetric: failing closed would blank real answers silently and at scale,
-- which is the exact harm this whole change exists to avoid. Failing open shows
-- an answer that should have prompted. Prefer the recoverable mistake.
--
-- 🔴 IT IS A NO-OP UNTIL THE SEASON OPENS, AND THAT IS THE POINT.
-- compass_answer_dispositions follows the OPEN season, which is Season 1, whose
-- pins are the versions everyone answered against — so every answer is 'fresh'
-- and this view returns compass_responses_current unchanged. It starts
-- suppressing at the changeover, by itself. That is why it can ship before the
-- open rather than during it.
--
-- The column list is explicit rather than `r.*`: a view's columns are fixed at
-- creation either way, so spelling them out is the honest contract. A column
-- added to compass_responses_current must be added here too.

CREATE OR REPLACE VIEW inform.compass_responses_effective
WITH (security_invoker = on) AS
SELECT r.user_id,
       r.topic_id,
       r.value,
       r.write_in_text,
       r.visibility,
       r.inverted,
       r.created_at,
       r.updated_at,
       r.deleted_at,
       r.answered_revision_id,
       r.season_id
  FROM inform.compass_responses_current r
  LEFT JOIN inform.compass_answer_dispositions d
    ON d.user_id = r.user_id
   AND d.topic_id = r.topic_id
 WHERE r.deleted_at IS NULL
   AND COALESCE(d.disposition, 'fresh') NOT IN ('moved', 'invalidated');

COMMENT ON VIEW inform.compass_responses_effective IS
  'A user''s answers that still stand: compass_responses_current (newest season per '
  'topic, CC_0046) minus the ones CC_0061 calls moved or invalidated. Read this, not '
  'compass_responses_current, wherever a user answer is shown to anyone or scored. '
  'All-fresh and therefore a no-op until the season changeover (CC_0062).';

-- security_invoker is on, so these grants only decide who may name the view; the
-- caller's own RLS on compass_responses still decides which rows they get. Mirrors
-- compass_responses_current and compass_answer_dispositions exactly — ev_api is
-- the backend pool's role and reads eight of the eleven sites.
GRANT SELECT ON inform.compass_responses_effective TO authenticated, service_role, ev_api;

-- -----------------------------------------------------------------------------
-- Prove it is a no-op today, that the filter is really wired, and that it would
-- suppress exactly the 7 answers the split was designed around.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_current int; v_effective int; v_def text; v_would_drop int; v_missing text;
BEGIN
  -- 1. A no-op while Season 1 is open. If these ever differ before the
  --    changeover, the disposition view stopped following the open season.
  SELECT count(*) INTO v_current
    FROM inform.compass_responses_current WHERE deleted_at IS NULL;
  SELECT count(*) INTO v_effective FROM inform.compass_responses_effective;

  IF v_current <> v_effective THEN
    RAISE EXCEPTION 'CC_0062: the view hides % of % answer(s) while Season 1 is still open — it must turn on at the changeover, not before',
      v_current - v_effective, v_current;
  END IF;

  -- 2. The filter is actually in the definition. Guards a later CREATE OR
  --    REPLACE that keeps the name and quietly drops the suppression.
  v_def := pg_get_viewdef('inform.compass_responses_effective'::regclass, true);
  IF v_def NOT LIKE '%compass_answer_dispositions%'
     OR v_def NOT LIKE '%moved%'
     OR v_def NOT LIKE '%invalidated%' THEN
    RAISE EXCEPTION 'CC_0062: the view definition no longer references the disposition rule — suppression has been dropped';
  END IF;

  -- 3. At the changeover it drops exactly 7 — the same 6 moved + 1 invalidated
  --    CC_0061 was designed against. Ties this view to that baseline rather than
  --    to a filter that merely looks right.
  WITH s2 AS (SELECT id FROM inform.seasons WHERE number = 2),
  eff AS (
    SELECT sq.topic_id, e.id AS eff_id
      FROM inform.season_questions sq
      JOIN inform.compass_topic_revisions pin ON pin.id = sq.topic_revision_id
      JOIN LATERAL (
        SELECT x.id FROM inform.compass_topic_revisions x
         WHERE x.topic_id = pin.topic_id AND x.version = pin.version
           AND x.status IN ('published','superseded','approved')
         ORDER BY x.revision DESC LIMIT 1) e ON true
     WHERE sq.season_id = (SELECT id FROM s2))
  SELECT count(*) INTO v_would_drop
    FROM inform.compass_responses_current r
    JOIN eff ON eff.topic_id = r.topic_id
   WHERE r.deleted_at IS NULL
     AND inform.compass_answer_disposition(r.answered_revision_id, eff.eff_id, r.value)
         IN ('moved','invalidated');

  IF v_would_drop <> 7 THEN
    RAISE EXCEPTION 'CC_0062: at the changeover this view would suppress % answer(s), expected 7 — re-measure before shipping', v_would_drop;
  END IF;

  -- 4. The roles that read it can actually read it. A missing ev_api grant would
  --    surface as a 500 on eight endpoints at once, only after deploy.
  SELECT string_agg(role_name, ', ') INTO v_missing
    FROM (VALUES ('authenticated'), ('service_role'), ('ev_api')) AS w(role_name)
   WHERE NOT has_table_privilege(w.role_name, 'inform.compass_responses_effective', 'SELECT');

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0062: SELECT not granted to %', v_missing;
  END IF;

  RAISE NOTICE 'CC_0062 OK: % answers visible today, identical to compass_responses_current. At the changeover 7 would be suppressed (6 moved, 1 invalidated).', v_effective;
END $$;

COMMIT;
