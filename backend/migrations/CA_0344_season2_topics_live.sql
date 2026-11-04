BEGIN;

-- =============================================================================
-- CA_0344: mark the 17 staged Season 2 topics live
-- =============================================================================
-- Created 2026-10-31 with Chris Andrews. Follows CA_0343, which gave these same
-- 17 topics their Focused Communities.
--
-- WHAT THIS DOES
-- Sets is_live = true on the seventeen Season 2 Compass topics that were created
-- staged, doing exactly what the admin Topics page's Live toggle does, seventeen
-- times. Nothing else changes.
--
-- 🔴 THIS DOES NOT PUBLISH ANYTHING TO VOTERS. THEY ARE ALREADY PUBLISHED.
-- This is the part that is easy to get backwards, so it is written down.
--
-- is_live stopped being the voter-facing gate some time ago. What voters see and
-- can answer is governed by season membership + the season's pinned revision:
--   * inform.compass_topics_promoted filters on seasons.status = 'open' and does
--     not mention is_live. All 60 Season 2 topics are already in it, these 17
--     included. (Verified on prod 2026-10-31: 60 rows, 43 live, 17 not.)
--   * compassService.getPromotedTopics() reads that view. It SELECTs is_live
--     into its response contract but never filters on it.
--   * public.upsert_compass_answer() gates on compass_topics_promoted (CC_0066),
--     not is_live, so voters can already answer all seventeen.
-- seasonService.ts calls the season predicate "the display kill switch that
-- replaced compass_topics.is_live" and cites these exact 17 rows as the worked
-- example of why. Those comments are now describing history, not current data.
--
-- 🔴 WHAT IT ACTUALLY FIXES: CANDIDATES COULD NOT ANSWER THESE QUESTIONS.
-- Two contributor pages still filter on the flag, client-side:
--   app/src/pages/contributor/CompassEditorPage.tsx:87
--   app/src/pages/contributor/CampaignManagerPage.tsx:85
--     setTopics(topicsData.filter(t => t.is_live));
-- So a campaign filling out the Compass was served 43 of the open season's 60
-- questions and had no way to reach the other 17. The data says so plainly —
-- measured 2026-10-31, before this migration:
--
--   politician answers   Season 2 topics
--   ------------------   ---------------------------------------------------
--   min 6, avg 883       all 43 topics with is_live = true
--   zero                 10 of the 17 with is_live = false
--   2 to 116             the remaining 7, all far below the live average
--
-- The seven non-zero rows were loaded by research and admin import paths, which
-- do not go through the contributor pages. The ten zeroes are voters answering a
-- question no candidate was ever shown. That asymmetry is the defect; the flip
-- is the fix.
--
-- ABOUT is_active — IT IS NOT A SECOND SWITCH, AND YOU CANNOT SET IT
-- inform.compass_topics.is_active is GENERATED ALWAYS AS (is_live) STORED. It is
-- an alias, not a flag: it follows this migration's UPDATE on its own, and naming
-- it in a SET clause would be an error. That is why all 64 rows have always had
-- the two in lockstep, and why public.admin_update_topic does not mention it.
-- Nothing in backend/src reads it anyway — the is_active filters in
-- compassService are on lenses and politicians, not topics.
--
-- went_live_at is stamped with the same CASE the RPC uses, so these rows get the
-- same provenance an admin click would have given them.
--
-- ROLLBACK (one statement, no data loss — nothing here is destructive):
--   UPDATE inform.compass_topics SET is_live = false, went_live_at = NULL
--    WHERE topic_key IN (...the 17 keys listed by the §1 gate...);
--   Voters keep every answer they gave; candidates simply lose access again.
--
-- There is no migration runner (see CLAUDE.md): this file documents the change
-- and lets a DB rebuild re-apply it. Idempotent — safe to re-run.
-- =============================================================================

-- 1. Readiness gate. Refuse to make a question live that a voter or a candidate
--    would meet half-built. Each of these is something the 43 already-live
--    Season 2 topics have without exception, verified 2026-10-31.
DO $$
DECLARE
  v_season_open BOOLEAN;
  v_bad         TEXT;
BEGIN
  SELECT EXISTS (SELECT 1 FROM inform.seasons WHERE number = 2 AND status = 'open')
    INTO v_season_open;
  IF NOT v_season_open THEN
    RAISE EXCEPTION 'CA_0344: Season 2 is not open — making its topics live would publish them into no season';
  END IF;

  SELECT string_agg(bad.topic_key || ' (' || bad.why || ')', '; ' ORDER BY bad.topic_key)
    INTO v_bad
  FROM (
    SELECT t.topic_key,
           concat_ws(', ',
             CASE WHEN btrim(coalesce(t.question_text, '')) = '' THEN 'no question text' END,
             CASE WHEN t.short_title IS NULL THEN 'no short title' END,
             CASE WHEN sq.topic_revision_id IS NULL THEN 'season pins no revision' END,
             CASE WHEN r.id IS NULL THEN 'pinned revision missing' END,
             -- 'superseded' is normal and expected: ADR 0006 Option Y serves the
             -- latest published OR superseded revision of the pinned version.
             -- 12 of the 43 live Season 2 topics sit on a superseded pin today.
             CASE WHEN r.status NOT IN ('published', 'superseded') THEN 'pinned revision is ' || r.status::text END,
             CASE WHEN st.n <> 5 THEN 'has ' || st.n || ' stances, not 5' END,
             CASE WHEN sr.n <> 5 THEN 'pinned revision has ' || sr.n || ' stance revisions, not 5' END,
             CASE WHEN cat.n = 0 THEN 'no category' END
           ) AS why
    FROM inform.compass_topics t
    JOIN inform.season_questions sq ON sq.topic_id = t.id
    JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2
    LEFT JOIN inform.compass_topic_revisions r ON r.id = sq.topic_revision_id
    LEFT JOIN LATERAL (SELECT count(*) n FROM inform.compass_stances cs WHERE cs.topic_id = t.id) st ON true
    LEFT JOIN LATERAL (SELECT count(*) n FROM inform.compass_stance_revisions x WHERE x.topic_revision_id = sq.topic_revision_id) sr ON true
    LEFT JOIN LATERAL (SELECT count(*) n FROM inform.compass_topic_categories tc WHERE tc.topic_id = t.id) cat ON true
    WHERE t.is_live = false
  ) bad
  WHERE bad.why <> '';

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0344: refusing to make incomplete topics live — %', v_bad;
  END IF;
END $$;

-- 2. The flip. This is public.admin_update_topic's UPDATE, restricted to the
--    staged Season 2 topics — same columns, same went_live_at CASE, nothing else.
UPDATE inform.compass_topics t
   SET is_live = true,
       went_live_at = CASE WHEN t.went_live_at IS NULL THEN now() ELSE t.went_live_at END,
       updated_at = now()
 WHERE t.is_live = false
   AND EXISTS (
     SELECT 1 FROM inform.season_questions sq
     JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2
     WHERE sq.topic_id = t.id
   );

-- 3. Post-verify gate — fail loudly if this did not achieve what it claims.
DO $$
DECLARE
  v_s2_total    INT;
  v_s2_not_live INT;
  v_no_stamp    INT;
  v_live_total  INT;
  v_other_live  INT;
BEGIN
  SELECT count(*) INTO v_s2_total
  FROM inform.season_questions sq JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2;

  SELECT count(*) INTO v_s2_not_live
  FROM inform.season_questions sq
  JOIN inform.seasons s ON s.id = sq.season_id AND s.number = 2
  JOIN inform.compass_topics t ON t.id = sq.topic_id
  WHERE t.is_live = false;

  IF v_s2_not_live <> 0 THEN
    RAISE EXCEPTION 'CA_0344: % of % Season 2 topics are still not live', v_s2_not_live, v_s2_total;
  END IF;

  -- Every live topic can say when it went live.
  SELECT count(*) INTO v_no_stamp
  FROM inform.compass_topics WHERE is_live AND went_live_at IS NULL;
  IF v_no_stamp <> 0 THEN
    RAISE EXCEPTION 'CA_0344: % live topics have no went_live_at', v_no_stamp;
  END IF;

  -- Nothing outside Season 2 was touched. The three remaining staged topics are
  -- campaign-transparency and election-access (in no season) and
  -- surveillance-technology (Season 3, still draft). They stay staged.
  SELECT count(*) INTO v_live_total FROM inform.compass_topics WHERE is_live;
  SELECT count(*) INTO v_other_live
  FROM inform.compass_topics t
  WHERE t.is_live
    AND NOT EXISTS (
      SELECT 1 FROM inform.season_questions sq
      JOIN inform.seasons s ON s.id = sq.season_id AND s.number IN (1, 2)
      WHERE sq.topic_id = t.id
    );
  IF v_other_live <> 0 THEN
    RAISE EXCEPTION 'CA_0344: % live topics belong to no closed or open season', v_other_live;
  END IF;

  RAISE NOTICE 'CA_0344 OK — all % Season 2 topics live, % live topics in total, 3 staged topics left untouched.',
    v_s2_total, v_live_total;
END $$;

COMMIT;
