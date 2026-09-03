BEGIN;

-- =============================================================================
-- CC_0061: one rule for "does this answer still mean what it meant"
-- =============================================================================
-- Created 2026-09-03 with Chris Cantrell. The foundation for the calibration
-- re-ask — the last thing gating the Season 2 open.
--
-- 🔴 WHY THIS EXISTS, MEASURED. The recalibration rule lives in TypeScript today
-- (compassUserLensService.compareRungs) and answers one boolean: did anything in
-- the rung neighbourhood change. Simulated against Season 2's pins on real data,
-- that flags 96 of 178 live user answers — 40-59% of EVERY user's compass. Fine
-- as a prompt; catastrophic as a suppression rule, which is what it was about to
-- become.
--
-- The 96 are not one thing. Split by what actually happened to the rung the user
-- is sitting on:
--
--     7 answers / 5 users   THEIR OWN rung moved or was invalidated
--     2 answers / 2 users   their rung stayed, a NEIGHBOUR moved
--    90 answers / 7 users   rungs unchanged, wording rewritten
--    72 answers / 7 users   no version change at all
--
-- Only the first 7 are WRONG — the stored value now points at a different
-- position. The other 90 still point exactly where they did; what changed is the
-- prose the user agreed to. Blanking those would delete a real person's stated
-- view over a copy edit.
--
-- Chris's decision 2026-09-03: SUPPRESS where their own rung moved, FLAG
-- everything else. This function is what makes that distinction expressible.
--
--   fresh        nothing to say. Keep the value, no prompt.
--   reworded     their rung still means their rung, but wording near it changed.
--                KEEP the value, RAISE a flag. 89 answers — exactly the old
--                rule's 96 minus the 7 it would have blanked.
--   moved        their rung maps somewhere else. The value is wrong.
--                SUPPRESS it, RAISE a flag.
--   invalidated  their rung no longer exists. SUPPRESS, RAISE a flag.
--                moved + invalidated = 7 answers across 5 users.
--
-- ⚠ IT REPLACES compareRungs RATHER THAN JOINING IT. Two implementations of one
-- editorial rule is how a suppression path and a prompt path come to disagree
-- about the same answer. The TypeScript is deleted in the same PR.
--
-- 🔴 TWO BUGS FIXED HERE, both found reading compareRungs.
--
--   1. IT MIS-REPORTED INVALIDATION. `IF r.mapped = 'invalidated' RETURN
--      'invalidated'` fires when ANY rung in the neighbourhood was invalidated,
--      not the user's own. Our Same-Sex Marriage user on rung 4 (neighbourhood
--      3,4,5 — rung 3 is the invalidated one) would have been told their answer
--      was invalidated, when 4->4 is unchanged. Telling someone their stated
--      view was invalidated when it was not is the worst thing this feature can
--      do. Here, `moved` and `invalidated` are decided from the user's OWN rung
--      only; a neighbour's fate can produce `reworded` and nothing worse.
--
--   2. THE `description` OVER-FIRE IS DEFUSED RATHER THAN DECIDED. Comparing
--      descriptions accounts for 11 of the 96. It stays, because whether a
--      description change is substantive is Chris Andrews' call and is parked —
--      but it can now only ever produce `reworded`, which keeps the value. The
--      parked decision no longer has the power to delete anybody's answer.
--
-- ⚠ A HALF VALUE IS A WRITE-IN BETWEEN TWO RUNGS, so "their own rung" is the
-- floor/ceil PAIR. At 2.5 the user's answer spans rungs 2 and 3 and either one
-- moving makes the stored value wrong. For a whole value floor = ceil and the
-- pair collapses to one rung.
--
-- ⚠ THE NEIGHBOURHOOD IS STILL [floor-1, ceil+1] CLAMPED 1..5 for `reworded`.
-- That is unchanged from compareRungs and deliberately wider than the user's own
-- rung: the rungs either side are what a stance is chosen AGAINST, so their
-- wording bears on the choice even when the chosen rung is untouched.

-- -----------------------------------------------------------------------------
-- 1. The rule
-- -----------------------------------------------------------------------------
-- LANGUAGE sql + STABLE so the planner can inline it into a set-based query;
-- a plpgsql function here would be a per-row call in every read that uses it.
CREATE OR REPLACE FUNCTION inform.compass_answer_disposition(
  p_answered_revision_id  uuid,
  p_effective_revision_id uuid,
  p_value                 numeric
)
RETURNS text
LANGUAGE sql
STABLE
AS $function$
  WITH ctx AS (
    SELECT
      (SELECT ar.version FROM inform.compass_topic_revisions ar WHERE ar.id = p_answered_revision_id)  AS answered_version,
      (SELECT er.version FROM inform.compass_topic_revisions er WHERE er.id = p_effective_revision_id) AS effective_version,
      (SELECT er.rung_map FROM inform.compass_topic_revisions er WHERE er.id = p_effective_revision_id) AS rung_map
  ),
  -- The rung(s) the user is actually sitting on.
  own AS (
    SELECT DISTINCT r AS rung
      FROM (VALUES (floor(p_value)::int), (ceil(p_value)::int)) v(r)
     WHERE p_value IS NOT NULL
  ),
  -- The rungs whose wording bears on that choice.
  neighbourhood AS (
    SELECT gs AS rung
      FROM generate_series(
             greatest(1, floor(p_value)::int - 1),
             least(5, ceil(p_value)::int + 1)) gs
     WHERE p_value IS NOT NULL
  ),
  own_fate AS (
    SELECT
      bool_or((SELECT rung_map FROM ctx) ->> own.rung::text = 'invalidated') AS any_invalidated,
      bool_or(((SELECT rung_map FROM ctx) ->> own.rung::text) ~ '^[0-9]+$'
              AND (((SELECT rung_map FROM ctx) ->> own.rung::text))::int <> own.rung) AS any_moved
      FROM own
  ),
  -- Anything in the neighbourhood that differs between the two revisions.
  nearby_change AS (
    SELECT bool_or(
             a.text IS NULL OR e.text IS NULL
             OR a.text        IS DISTINCT FROM e.text
             OR a.description IS DISTINCT FROM e.description
             OR (((SELECT rung_map FROM ctx) ->> n.rung::text) ~ '^[0-9]+$'
                 AND ((((SELECT rung_map FROM ctx) ->> n.rung::text))::int) <> n.rung)
             OR ((SELECT rung_map FROM ctx) ->> n.rung::text) = 'invalidated'
           ) AS changed
      FROM neighbourhood n
      LEFT JOIN inform.compass_stance_revisions a
        ON a.topic_revision_id = p_answered_revision_id AND a.value = n.rung
      LEFT JOIN inform.compass_stance_revisions e
        ON e.topic_revision_id = p_effective_revision_id AND e.value = n.rung
  )
  SELECT CASE
    -- An answer with no stamped revision is treated as fresh, not flagged.
    -- Nagging someone because of a NULL we wrote is worse than missing a
    -- genuine revision. (3 of 187 rows in prod pre-date stamping.)
    WHEN p_answered_revision_id IS NULL
      OR p_effective_revision_id IS NULL
      OR p_value IS NULL
      THEN 'fresh'
    -- ADR 0006 §2: editorial and clarifying revisions do NOT bump `version`, so
    -- a same-version comparison can never raise a flag without testing
    -- change_class at all.
    WHEN (SELECT answered_version FROM ctx) IS NULL
      OR (SELECT answered_version FROM ctx) = (SELECT effective_version FROM ctx)
      THEN 'fresh'
    WHEN (SELECT any_invalidated FROM own_fate) THEN 'invalidated'
    WHEN (SELECT any_moved       FROM own_fate) THEN 'moved'
    WHEN (SELECT changed         FROM nearby_change) THEN 'reworded'
    ELSE 'fresh'
  END
$function$;

COMMENT ON FUNCTION inform.compass_answer_disposition(uuid, uuid, numeric) IS
  'Does a user answer still mean what it meant? fresh | reworded | moved | invalidated. '
  'moved/invalidated are decided from the user''s OWN rung and SUPPRESS the value; '
  'reworded comes from the surrounding neighbourhood and only raises a prompt. '
  'Single source of truth — do not reimplement in application code (CC_0061).';

-- -----------------------------------------------------------------------------
-- 2. The set-based view every consumer reads
-- -----------------------------------------------------------------------------
-- `eff` mirrors getPromotedTopics()'s lateral exactly (ADR 0006 Option Y): the
-- season serves the LATEST revision of the version it PINNED, not is_current.
--
-- 🔴 IT FOLLOWS THE OPEN SEASON, WHICH IS WHY IT IS ALL 'fresh' TODAY. Season 1
-- is open and its pins are the versions everyone answered against, so nothing is
-- stale. The dispositions turn on at the changeover, by themselves — which is
-- the behaviour we want and the reason this must ship BEFORE the open, not after.
--
-- security_invoker so the caller's own RLS on compass_responses still applies —
-- this view must not become a way to read another user's answers.
CREATE OR REPLACE VIEW inform.compass_answer_dispositions
WITH (security_invoker = on) AS
SELECT
  r.user_id,
  r.topic_id,
  r.value,
  r.answered_revision_id,
  eff.effective_revision_id,
  inform.compass_answer_disposition(r.answered_revision_id, eff.effective_revision_id, r.value)
    AS disposition
FROM inform.compass_responses_current r
LEFT JOIN LATERAL (
  SELECT e.id AS effective_revision_id
    FROM inform.compass_topics_promoted p
    JOIN inform.compass_topic_revisions pin ON pin.id = p.season_revision_id
    JOIN inform.compass_topic_revisions e
      ON e.topic_id = pin.topic_id
     AND e.version  = pin.version
     AND e.status IN ('published', 'superseded')
   WHERE p.id = r.topic_id
   ORDER BY e.revision DESC
   LIMIT 1
) eff ON true
WHERE r.deleted_at IS NULL;

COMMENT ON VIEW inform.compass_answer_dispositions IS
  'Per user answer: fresh | reworded | moved | invalidated against the OPEN season''s '
  'ladder. Suppress the value where disposition IN (''moved'',''invalidated''); raise a '
  'recalibration prompt where disposition <> ''fresh'' (CC_0061).';

GRANT SELECT ON inform.compass_answer_dispositions TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 3. Prove the rule reproduces the measured split, then throw the proof away
-- -----------------------------------------------------------------------------
-- The view is all 'fresh' today by design, so it cannot demonstrate anything on
-- its own. This calls the FUNCTION with Season 2's pins substituted — the state
-- the day after the changeover — and asserts it reproduces the counts this
-- migration was designed against. If the rule drifts, these numbers move.
DO $$
DECLARE
  v_moved int; v_reworded int; v_fresh int; v_invalid int; v_view_stale int;
BEGIN
  CREATE TEMP TABLE cc0061_sim ON COMMIT DROP AS
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
  SELECT r.user_id, r.topic_id,
         inform.compass_answer_disposition(r.answered_revision_id, eff.eff_id, r.value) AS disposition
    FROM inform.compass_responses_current r
    JOIN eff ON eff.topic_id = r.topic_id
   WHERE r.deleted_at IS NULL;

  SELECT count(*) FILTER (WHERE disposition = 'moved'),
         count(*) FILTER (WHERE disposition = 'invalidated'),
         count(*) FILTER (WHERE disposition = 'reworded'),
         count(*) FILTER (WHERE disposition = 'fresh')
    INTO v_moved, v_invalid, v_reworded, v_fresh
    FROM cc0061_sim;

  -- 7 answers across 5 users had their own rung moved or invalidated.
  IF (v_moved + v_invalid) <> 7 THEN
    RAISE EXCEPTION 'CC_0061: % answer(s) would be SUPPRESSED at the changeover, expected 7 (moved=%, invalidated=%). The split this was designed against has changed — re-measure before shipping.',
      v_moved + v_invalid, v_moved, v_invalid;
  END IF;

  -- 89 keep their value but raise a prompt. That is exactly the old rule's 96
  -- minus the 7 it would have blanked: the split reassigns, it does not invent.
  -- (3 further version-bumped answers come out `fresh` — the version moved but
  -- nothing in their neighbourhood did.)
  IF v_reworded <> 89 THEN
    RAISE EXCEPTION 'CC_0061: % answer(s) would be flagged-but-kept, expected 89', v_reworded;
  END IF;

  -- 🔴 The number that matters most: suppression must stay far below the 96 the
  -- old rule would have blanked. If this ever approaches it, the split collapsed.
  IF (v_moved + v_invalid) > 20 THEN
    RAISE EXCEPTION 'CC_0061: suppression has grown to % answers — the rule is behaving like the old one it replaced', v_moved + v_invalid;
  END IF;

  -- And the live view must be entirely fresh while Season 1 is the open season.
  SELECT count(*) INTO v_view_stale
    FROM inform.compass_answer_dispositions WHERE disposition <> 'fresh';
  IF v_view_stale <> 0 THEN
    RAISE EXCEPTION 'CC_0061: the live view reports % non-fresh answer(s) while Season 1 is open — it should turn on at the changeover, not before', v_view_stale;
  END IF;

  RAISE NOTICE 'CC_0061 OK: at the changeover % suppressed (% moved, % invalidated), % flagged-but-kept, % fresh. Live view is all-fresh today, as designed.',
    v_moved + v_invalid, v_moved, v_invalid, v_reworded, v_fresh;
END $$;

COMMIT;
