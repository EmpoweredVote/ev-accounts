BEGIN;

-- =============================================================================
-- CC_0082: Regalado's transportation-priorities reasoning names the South Dade
--          Transitway grant agreements and cites none of them
-- =============================================================================
-- Slot CC_0082 reserved via `steward slot CC` before this file existed.
--
-- ✅ APPLIED TO PRODUCTION 2026-09-09. Dry-run first, aborted by a deliberate
--    exception (the Supabase MCP owns the transaction, so a plain ROLLBACK
--    cannot be trusted through it), and the revert confirmed by re-reading the
--    row — still 3 sources, `updated_at` untouched. After applying: 6 sources in
--    prose order, prose md5 unchanged, 2,814 open-season context rows unchanged.
--    Re-running a guarded UPDATE rewrites 0 rows.
--
--    ⚠ THE OPEN-SEASON ROW COUNT MOVED FROM 2,767 TO 2,814 BETWEEN CC_0081 AND
--      THIS FILE, an hour apart, because another session applied CC_0080. That
--      is why the invariants here are a digest and a count taken at run time and
--      never a literal — an absolute total in this file would already be stale.
--
-- WHAT THIS IS. Three `sources` elements added to one Season 2 context row. No
-- answer changes, no chair moves, no prose is edited, no row is created or
-- deleted. The sibling of CC_0081, found by the same two-way control.
--
-- ── WHY ──────────────────────────────────────────────────────────────────────
--
-- The voter-facing reasoning for Raquel A. Regalado on `transportation-priorities`
-- (seated at chair 3 on 2026-09-08) closes with:
--
--   "She created the Rapid Transit Zone subzone at the University Metrorail
--    station, and carried the state grant agreements funding bus operations and
--    a new park-and-ride facility on the South Dade Transitway."
--
-- The subzone half is cited — matter 252269, ordinance 25-90. The grant
-- agreements were not cited at all. The row's three sources are 260764
-- (R-551-26), 251750 (R-992-25) and 252269, and none of them is a grant
-- agreement.
--
-- ── THE THREE INSTRUMENTS, READ LIVE OFF THE COUNTY 2026-09-09 ───────────────
--
-- All three are Resolutions, Adopted, with "Raquel A. Regalado, Prime Sponsor"
-- and no other sponsor:
--
--   250461  R-281-25 …… see below, DELIBERATELY NOT CITED
--   250457  R-279-25  Adopted 2025-03-18. PTGA with FDOT, $1,000,000 in FY2025
--                     Transit Corridor Development Program funds "FOR OPERATION
--                     OF BUS ROUTES ON THE SOUTH DADE TRANSITWAY CORRIDOR".
--   260354  R-210-26  Adopted 2026-03-17. PTGA with FDOT, $920,550 in Transit
--                     Corridor Development Program funds "FOR OPERATION OF BUS
--                     ROUTES ON THE SOUTH DADE TRANSITWAY CORRIDOR".
--   260527  R-267-26  Adopted 2026-04-21. PTGA with FDOT, $1,765,148 "FOR THE
--                     DESIGN OF A NEW PARK-AND-RIDE FACILITY NEAR THE MARLIN
--                     ROAD STATION ALONG THE SOUTH MIAMI-DADE TRANSITWAY BUS
--                     RAPID TRANSIT CORRIDOR".
--
-- So "agreements" plural, "bus operations" and "a new park-and-ride facility"
-- each map to a document the county publishes. The sentence was accurate and
-- undocumented.
--
-- ⚠ 250461 (R-281-25) IS DELIBERATELY NOT CITED. It is also hers, also adopted,
--   also on this corridor — Amendment No. 2 to a PTGA, $177,000 of Park and Ride
--   Lot Program funding for "DROP-OFF/PICK-UP LOCATIONS AND OTHER ENHANCEMENTS"
--   between SW 344 Street and Dadeland South. That is not the claim the prose
--   makes: enhancements to existing stops are not "a new park-and-ride
--   facility". A citation must carry the sentence it sits beside, and padding
--   the array with adjacent-but-different instruments is how a source list stops
--   meaning anything.
--
-- ⚠ EVERY ONE OF THESE CARRIES `requester = Transportation and Public Works`.
--   They are the department's agreements, sponsored by her — which is exactly
--   why the prose says "CARRIED" and not "sponsored". Citing them does not
--   promote them to own-initiative evidence, and the chair does not rest on
--   them: rung 3 is carried by R-551-26 and R-992-25, both already cited and
--   both `requester = NONE`.
--
-- 🔴 THE CONTROL THAT FOUND THIS. A cited-id sweep runs SOURCES -> REALITY and
--    passes on this row: all three citations resolve, name the instruments the
--    prose names, and carry the right prime sponsor. The gap is the other
--    direction — an instrument the PROSE NAMES that no source points at. Lesson
--    12 in the Miami-Dade todo; CC_0081 was the first row it caught.
--
-- ORDER. This row's sources are in PROSE order, not sorted: R-551-26, R-992-25,
-- 25-90. The three appends follow the sentence — bus operations first, oldest
-- agreement first, then the park-and-ride design. The post-verify asserts the
-- whole array by equality, so the order is pinned rather than hoped for.
--
-- IDEMPOTENT: each UPDATE is guarded on its own URL's absence, so re-applying is
-- a no-op and the post-verify still passes.
-- =============================================================================

DROP TABLE IF EXISTS _cc0082_target;
DROP TABLE IF EXISTS _cc0082_before;

CREATE TEMP TABLE _cc0082_target AS
SELECT c.politician_id, c.topic_id, c.season_id
  FROM inform.politician_context c
  JOIN inform.seasons s        ON s.id = c.season_id AND s.status = 'open'
  JOIN inform.compass_topics t ON t.id = c.topic_id  AND t.topic_key = 'transportation-priorities'
 WHERE c.politician_id = 'ab1cf05e-cb5e-461a-8723-7ee87adac518';   -- Raquel A. Regalado

CREATE TEMP TABLE _cc0082_before AS
SELECT
  (SELECT count(*)
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open')            AS n_context,
  (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                         coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                         ORDER BY c.politician_id, c.topic_id))
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    WHERE NOT EXISTS (SELECT 1 FROM _cc0082_target g
                       WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
                                                                                   AS others_digest,
  (SELECT md5(c.reasoning)
     FROM inform.politician_context c
     JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                          AND g.season_id = c.season_id)                           AS reasoning_md5,
  (SELECT array_length(c.sources, 1)
     FROM inform.politician_context c
     JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                          AND g.season_id = c.season_id)                           AS n_sources;

-- ── PRECONDITIONS ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  -- 1. Season 2 is the open season. These sources were written against it.
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'open' AND number = 2) THEN
    RAISE EXCEPTION 'CC_0082: Season 2 is not the open season';
  END IF;

  -- 2. exactly one target row
  SELECT count(*) INTO v_n FROM _cc0082_target;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0082: % target context row(s), expected exactly 1', v_n;
  END IF;

  -- 3. 🔴 THE PROSE MUST STILL MAKE ALL THREE CLAIMS. This file cites a sentence.
  --    If an edit removed a clause, its document would be attached to nothing.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.reasoning LIKE '%South Dade Transitway%'
     AND c.reasoning LIKE '%bus operations%'
     AND c.reasoning LIKE '%park-and-ride%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0082: the reasoning no longer names the Transitway, bus operations and a park-and-ride facility — re-read the row before citing it';
  END IF;

  -- 4. the row is a published claim: a non-blank answer stands beside it.
  --    @zero-scope: excludes-blanks — a value of 0 is a blank spoke, and a blank
  --    publishes no sentence for a citation to support.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN _cc0082_target g ON g.politician_id = a.politician_id AND g.topic_id = a.topic_id
                         AND g.season_id = a.season_id
   WHERE a.value <> 0;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0082: the target pair carries no non-blank answer — nothing is published to cite';
  END IF;

  -- 5. the row still carries the three sources it was verified with, in order
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.sources[1:3] = ARRAY[
           'https://www.miamidade.gov/govaction/matter.asp?matter=260764',
           'https://www.miamidade.gov/govaction/matter.asp?matter=251750',
           'https://www.miamidade.gov/govaction/matter.asp?matter=252269'];
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0082: the row no longer opens with its three verified sources in prose order — read it before appending';
  END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────
-- One guarded append per document, in the order the sentence makes the claims.

-- R-279-25 — FY2025 operating funds for bus routes on the Transitway corridor
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=250457']::text[],
       updated_at = now()
  FROM _cc0082_target g
 WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id AND g.season_id = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=250457' = ANY (c.sources));

-- R-210-26 — the following year's operating funds for the same bus routes
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260354']::text[],
       updated_at = now()
  FROM _cc0082_target g
 WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id AND g.season_id = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=260354' = ANY (c.sources));

-- R-267-26 — design of the new park-and-ride facility at Marlin Road Station
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260527']::text[],
       updated_at = now()
  FROM _cc0082_target g
 WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id AND g.season_id = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=260527' = ANY (c.sources));

-- ── POST-VERIFY ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n       int;
  v_sources text[];
BEGIN
  SELECT c.sources INTO v_sources
    FROM inform.politician_context c
    JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id;

  -- 1. 🔑 THE WHOLE ARRAY, BY EQUALITY. Pins membership, count and prose order
  --    in one assertion, and refuses a duplicate.
  IF v_sources IS DISTINCT FROM ARRAY[
       'https://www.miamidade.gov/govaction/matter.asp?matter=260764',
       'https://www.miamidade.gov/govaction/matter.asp?matter=251750',
       'https://www.miamidade.gov/govaction/matter.asp?matter=252269',
       'https://www.miamidade.gov/govaction/matter.asp?matter=250457',
       'https://www.miamidade.gov/govaction/matter.asp?matter=260354',
       'https://www.miamidade.gov/govaction/matter.asp?matter=260527']::text[] THEN
    RAISE EXCEPTION 'CC_0082: the row reads % — not the six expected sources in prose order', array_to_string(v_sources, ' , ');
  END IF;

  -- 2. 250461 must NOT have crept in. See the header: it is a real instrument
  --    that supports a claim this sentence does not make.
  IF 'https://www.miamidade.gov/govaction/matter.asp?matter=250461' = ANY (v_sources) THEN
    RAISE EXCEPTION 'CC_0082: 250461 was cited — it documents stop enhancements, not a new park-and-ride facility';
  END IF;

  -- 3. the voter-facing prose is byte-identical. This file cites; it does not edit.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0082_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE md5(c.reasoning) = (SELECT reasoning_md5 FROM _cc0082_before);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0082: the reasoning text changed — this file must not edit prose';
  END IF;

  -- 4. 🔴 NOTHING ELSE IN THE OPEN SEASON MOVED. Three UPDATEs are three chances
  --    for a predicate to be too wide; the digest covers every other row.
  IF (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                            coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                            ORDER BY c.politician_id, c.topic_id))
        FROM inform.politician_context c
        JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
       WHERE NOT EXISTS (SELECT 1 FROM _cc0082_target g
                          WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
     IS DISTINCT FROM (SELECT others_digest FROM _cc0082_before) THEN
    RAISE EXCEPTION 'CC_0082: another context row''s sources changed — an UPDATE predicate was too wide';
  END IF;

  -- 5. no row created or destroyed
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open';
  IF v_n <> (SELECT n_context FROM _cc0082_before) THEN
    RAISE EXCEPTION 'CC_0082: open-season context rows went from % to %',
      (SELECT n_context FROM _cc0082_before), v_n;
  END IF;

  RAISE NOTICE 'CC_0082 OK: Regalado transportation-priorities now cites % sources (was %), the three FDOT grant agreements among them. Prose unchanged, % other open-season context rows untouched.',
    array_length(v_sources, 1), (SELECT n_sources FROM _cc0082_before), v_n - 1;
END $$;

DROP TABLE _cc0082_target;
DROP TABLE _cc0082_before;

COMMIT;
