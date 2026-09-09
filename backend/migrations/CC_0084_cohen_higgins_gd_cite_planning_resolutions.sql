BEGIN;

-- =============================================================================
-- CC_0084: Cohen Higgins' growth-and-development row names two planning
--          resolutions and cites neither
-- =============================================================================
-- Slot CC_0084 reserved via `steward slot CC` before this file existed.
--
-- APPLIED TO PRODUCTION 2026-09-09, via a real one-client BEGIN ... ROLLBACK dry
--    run first; rollback confirmed by re-reading the row (still 3 sources,
--    updated_at untouched). After: 5 sources in prose order, prose md5 unchanged,
--    every other open-season row untouched.
--
-- WHAT THIS IS. Two `sources` elements added to one Season 2 context row. No
-- answer changes, no chair moves, no prose is edited. Fourth and last file in
-- the CC_0081..CC_0084 citation series.
--
-- ── THE SWEEP THIS CLOSES ────────────────────────────────────────────────────
--
-- All twelve Season 2 Miami-Dade rows have now had the two-way control run over
-- them. Final tally:
--
--   residential-zoning        1 row   1 defect   CC_0081
--   transportation-priorities 1 row   1 defect   CC_0082
--   housing                   5 rows  3 defects  CC_0083
--   growth-and-development    4 rows  1 defect   this file
--   economic-development      1 row   0 defects
--                            ------  ---------
--                            12 rows  6 defects
--
-- Half the corpus named an instrument nothing cited. SOURCES -> REALITY passed
-- on every row in every pass (26 of 26 citations), so the one-way control never
-- had a chance of finding this.
--
-- ── THIS ROW ─────────────────────────────────────────────────────────────────
--
-- The reasoning names five instruments and cited three (25-59 `241888`,
-- R-191-26 `260228`, R-1183-25 `252372`). Uncited:
--
--   252187  R-1173-25  Adopted, sole prime sponsor Danielle Cohen Higgins
--   260291  R-337-26   Adopted, sole prime sponsor Danielle Cohen Higgins
--
-- Both verified live on 2026-09-09. Both direct neighbourhood planning exercises
-- for an area within District 8 and INSIDE the Urban Development Boundary,
-- "RELATED TO THE UNIQUE ARCHITECTURAL, HISTORIC, AND AESTHETIC CHARACTER OF SAID
-- AREA AND THE POSSIBLE DEVELOPMENT OF A COMMUNITY-SPECIFIC THEMATIC ZONING
-- DISTRICT" — which is what the prose calls "neighbourhood planning toward a
-- character-based zoning district". The title carries the claim.
--
-- ⚠ BOTH ARE DIRECTIVES REQUIRING A REPORT, and a study directive is not a chair.
--   They are cited as corroboration only. Her chair 2 rests on the No vote on
--   25-59 and on R-191-26 / R-1183-25, all three already cited.
--
-- ── 🔴 A SEPARATE DEFECT THIS SWEEP FOUND AND THIS FILE DOES NOT TOUCH ───────
--
-- Reading `241888` in full to check the vote claims turned up a PROSE precision
-- problem in four rows, which is not a citation fix and must not be made in a
-- migration that asserts the prose is unchanged:
--
--   * Rodriguez's row says "The Board adopted it 7 votes to 3". The cited page
--     records NO TALLY for the adoption. It records a 6-4 FAILED motion, a 10-0
--     motion to reconsider, and then "the Board voted to reject staff's
--     recommendation and approve the application as presented" with no count.
--     Where 7-3 came from is unknown; 7 was the number of votes the County
--     Attorney advised were needed.
--   * The Cohen Higgins, Steinberg and Garcia rows say each "voted No" and that
--     "the Board adopted it anyway". What the record shows is a No on Chairman
--     Rodriguez's motion to reject staff's recommendation and approve the 1:1
--     ratio — the motion that FAILED 6-4 before the reconsideration. Their
--     position is not in doubt and the direction is right: they voted against
--     loosening LU-8H. But the final adoption vote is untallied, so no source
--     shows how any member voted on adoption.
--
-- Neither affects a chair. Both need a prose edit reviewed by a human, in the
-- same shape as a re-audit, not a `sources` append. Recorded in the todo.
--
-- IDEMPOTENT: appends guarded on each URL's absence; re-applying is a no-op.
-- =============================================================================

DROP TABLE IF EXISTS _cc0084_target;
DROP TABLE IF EXISTS _cc0084_before;

CREATE TEMP TABLE _cc0084_target AS
SELECT c.politician_id, c.topic_id, c.season_id
  FROM inform.politician_context c
  JOIN inform.seasons s        ON s.id = c.season_id AND s.status = 'open'
  JOIN inform.compass_topics t ON t.id = c.topic_id  AND t.topic_key = 'growth-and-development'
 WHERE c.politician_id = '0d13108c-a1ad-4747-b8b4-5db47c0e6941';   -- Danielle Cohen Higgins

CREATE TEMP TABLE _cc0084_before AS
SELECT
  (SELECT count(*)
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open')            AS n_context,
  (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                         coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                         ORDER BY c.politician_id, c.topic_id))
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    WHERE NOT EXISTS (SELECT 1 FROM _cc0084_target g
                       WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
                                                                                   AS others_digest,
  (SELECT md5(c.reasoning)
     FROM inform.politician_context c
     JOIN _cc0084_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                          AND g.season_id = c.season_id)                           AS reasoning_md5;

-- ── PRECONDITIONS ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'open' AND number = 2) THEN
    RAISE EXCEPTION 'CC_0084: Season 2 is not the open season';
  END IF;

  -- the uuid resolves to the person this file names
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                  WHERE id = '0d13108c-a1ad-4747-b8b4-5db47c0e6941'
                    AND full_name = 'Danielle Cohen Higgins') THEN
    RAISE EXCEPTION 'CC_0084: that politician_id is not Danielle Cohen Higgins';
  END IF;

  SELECT count(*) INTO v_n FROM _cc0084_target;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0084: % target context row(s), expected exactly 1', v_n;
  END IF;

  -- 🔴 THE PROSE MUST STILL NAME BOTH INSTRUMENTS.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0084_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.reasoning LIKE '%R-1173-25%' AND c.reasoning LIKE '%R-337-26%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0084: the reasoning no longer names both R-1173-25 and R-337-26 — re-read it';
  END IF;

  -- a published claim stands beside it.
  -- @zero-scope: excludes-blanks — a 0 is a blank spoke and publishes no prose.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN _cc0084_target g ON g.politician_id = a.politician_id AND g.topic_id = a.topic_id
                         AND g.season_id = a.season_id
   WHERE a.value = 2;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0084: the target answer is not chair 2 — re-read the row before citing';
  END IF;

  -- the three verified sources are still there, in prose order
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0084_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.sources[1:3] = ARRAY[
           'https://www.miamidade.gov/govaction/matter.asp?matter=241888',
           'https://www.miamidade.gov/govaction/matter.asp?matter=260228',
           'https://www.miamidade.gov/govaction/matter.asp?matter=252372'];
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0084: the row no longer opens with its three verified sources in prose order';
  END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────
-- Prose order: the two planning resolutions are named last, in this order.

-- R-1173-25 — neighbourhood planning exercises, District 8, inside the UDB
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=252187']::text[],
       updated_at = now()
  FROM _cc0084_target g
 WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id AND g.season_id = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=252187' = ANY (c.sources));

-- R-337-26 — the same exercise, renewed in 2026
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260291']::text[],
       updated_at = now()
  FROM _cc0084_target g
 WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id AND g.season_id = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=260291' = ANY (c.sources));

-- ── POST-VERIFY ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n       int;
  v_sources text[];
BEGIN
  SELECT c.sources INTO v_sources
    FROM inform.politician_context c
    JOIN _cc0084_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id;

  -- 1. 🔑 the whole array by equality: membership, count, order, no duplicate
  IF v_sources IS DISTINCT FROM ARRAY[
       'https://www.miamidade.gov/govaction/matter.asp?matter=241888',
       'https://www.miamidade.gov/govaction/matter.asp?matter=260228',
       'https://www.miamidade.gov/govaction/matter.asp?matter=252372',
       'https://www.miamidade.gov/govaction/matter.asp?matter=252187',
       'https://www.miamidade.gov/govaction/matter.asp?matter=260291']::text[] THEN
    RAISE EXCEPTION 'CC_0084: the row reads % — not the five expected sources in prose order', array_to_string(v_sources, ' , ');
  END IF;

  -- 2. the voter-facing prose is byte-identical. This file cites; it does not edit.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0084_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE md5(c.reasoning) = (SELECT reasoning_md5 FROM _cc0084_before);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0084: the reasoning changed — this file must not edit prose';
  END IF;

  -- 3. 🔴 NOTHING ELSE MOVED — including the other three growth-and-development
  --    rows and the economic-development row this sweep found complete.
  IF (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                            coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                            ORDER BY c.politician_id, c.topic_id))
        FROM inform.politician_context c
        JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
       WHERE NOT EXISTS (SELECT 1 FROM _cc0084_target g
                          WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
     IS DISTINCT FROM (SELECT others_digest FROM _cc0084_before) THEN
    RAISE EXCEPTION 'CC_0084: another context row''s sources changed — the UPDATE was too wide';
  END IF;

  -- 4. no row created or destroyed
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open';
  IF v_n <> (SELECT n_context FROM _cc0084_before) THEN
    RAISE EXCEPTION 'CC_0084: open-season context rows went from % to %',
      (SELECT n_context FROM _cc0084_before), v_n;
  END IF;

  RAISE NOTICE 'CC_0084 OK: Cohen Higgins growth-and-development now cites 5 sources. Every Season 2 Miami-Dade row now cites every instrument its prose names.';
END $$;

DROP TABLE _cc0084_target;
DROP TABLE _cc0084_before;

COMMIT;
