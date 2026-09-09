BEGIN;

-- =============================================================================
-- CC_0083: the housing rows name 13 instruments that nothing cites
-- =============================================================================
-- Slot CC_0083 reserved via `steward slot CC` before this file existed.
--
-- APPLIED TO PRODUCTION 2026-09-09. Dry-run first through a real
--    BEGIN ... ROLLBACK on one client -- not the Supabase MCP, which wraps every
--    call in its own transaction and so cannot dry-run a file carrying its own
--    BEGIN/COMMIT. Rollback confirmed by re-reading all three rows (still 3
--    sources each, updated_at untouched), then applied. After: 9 / 8 / 5
--    citations, prose digest unchanged, every other open-season row untouched.
--    Re-running the file rewrites 0 rows and every gate still passes.
--
-- WHAT THIS IS. `sources` rewritten on THREE Season 2 `housing` context rows, to
-- cite every instrument their own prose names. 13 URLs added, 0 removed. No
-- answer changes, no chair moves, no prose is edited, no row is created or
-- deleted. The third file in the series after CC_0081 and CC_0082.
--
-- ── WHY: THE FIRST SWEEP OF A WHOLE TOPIC, AND IT IS NOT A ONE-ROW DEFECT ────
--
-- CC_0081/0082 fixed Regalado's two rows. This is the same two-way control run
-- across all five Season 2 `housing` rows, the oldest Miami-Dade pass:
--
--   SOURCES -> REALITY   13 of 13 cited matters resolve, their reference numbers
--                        match the prose, and each prime sponsor is the person
--                        the row is about. That direction was never broken.
--   PROSE -> SOURCES     3 of 5 rows name instruments no source points at:
--                        Hardemon 9 named / 3 cited, Bastien 8 / 3, McGhee 5 / 3.
--                        Rodriguez (1/1) and Regalado (3/3) are complete.
--
-- So the defect rate on rows written before the control existed is 3 in 5, and
-- 13 named instruments in total. Every one was verified LIVE against the county
-- on 2026-09-09 before being cited here: reference number, status, requester and
-- the full sponsor list. All 13 are Adopted and all 13 carry the row's subject as
-- SOLE prime sponsor.
--
--   Hardemon  261067 R-560-26   Palmetto Homes, additional extension for 30 lots
--             250348 R-311-25   property conveyance, affordable living
--             260231 R-1086-25  MANA/MAPTON third amendment (Adopted as amended)
--             250872 R-680-25   SEOPW CRA bond issuance
--             260870 R-534-26   Claude Pepper Tower public housing site
--             251480 R-744-25   redevelopment of Claude Pepper Tower
--   Bastien   251003 R-450-25   motion re R-365-21 (the moratorium waiver)
--             261171 R-664-26   multifamily housing revenue debt, §147(f)
--             261172 R-665-26   multifamily housing revenue debt, §147(f)
--             250903 R-497-25   multifamily housing revenue debt, §147(f)
--             250906 R-498-25   multifamily housing revenue debt, §147(f)
--   McGhee    252178 R-1120-25  surplus of county-owned properties in District 9
--             251230 R-783-25   extension for a developer already holding land
--
-- ⚠ FOUR OF THESE CARRY `requester = Housing Finance Authority` (Bastien's bond
--   items) and two carry `requester = Housing and Community Development`. The
--   prose already says she "sponsors" the HFA items and names the Authority, so
--   citing them does not promote a department request to own initiative. The
--   same care as CC_0082's "carried".
--
-- 🔑 THE CHAIRS DO NOT MOVE. All five rows sit at 4, and each was already carried
--    by the cited three. These 13 are the rest of the record the prose describes
--    — corroboration, not the load-bearing evidence — which is why this is a
--    citation fix and not a re-audit.
--
-- ── WHY A REWRITE AND NOT AN APPEND ──────────────────────────────────────────
--
-- McGhee's prose runs R-569-25, R-568-25, R-1120-25, R-245-26, R-783-25, and his
-- stored array holds positions 1, 2 and 4. Appending would leave the reader with
-- 1,2,4,3,5. So each row's array is SET to its full list in prose order, guarded
-- on the array not already equalling the target. That is idempotent, fixes the
-- order, and the post-verify asserts each array by equality.
--
-- 🔴 THE PRECONDITION IS THAT THE EXISTING THREE ARE STILL EXACTLY WHAT WAS READ.
--    A rewrite that assumed the old contents could silently drop a citation added
--    by somebody else in between, so it refuses unless each row still holds its
--    three known URLs.
-- =============================================================================

DROP TABLE IF EXISTS _cc0083_want;
DROP TABLE IF EXISTS _cc0083_before;

-- The three target rows and the exact array each should end with, in prose order.
CREATE TEMP TABLE _cc0083_want AS
SELECT * FROM (VALUES
  ('5f074ffb-314c-4395-a2df-cdd37a7eb34f'::uuid, 'Keon Hardemon',
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=261263',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260911',
         'https://www.miamidade.gov/govaction/matter.asp?matter=252097']::text[],
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=261263',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260911',
         'https://www.miamidade.gov/govaction/matter.asp?matter=252097',
         'https://www.miamidade.gov/govaction/matter.asp?matter=261067',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250348',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260231',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250872',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260870',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251480']::text[]),

  ('23950def-95e8-4282-b3b5-5d0a86e29b36'::uuid, 'Marleine Bastien',
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260143',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251638',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251000']::text[],
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260143',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251638',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251000',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251003',
         'https://www.miamidade.gov/govaction/matter.asp?matter=261171',
         'https://www.miamidade.gov/govaction/matter.asp?matter=261172',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250903',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250906']::text[]),

  ('189fb6bd-55ed-4a4d-992a-ba86f8df1ead'::uuid, 'Kionne L. McGhee',
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260652',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250776',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260424']::text[],
   ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=260652',
         'https://www.miamidade.gov/govaction/matter.asp?matter=250776',
         'https://www.miamidade.gov/govaction/matter.asp?matter=252178',
         'https://www.miamidade.gov/govaction/matter.asp?matter=260424',
         'https://www.miamidade.gov/govaction/matter.asp?matter=251230']::text[])
) AS v(politician_id, who, had, want);

CREATE TEMP TABLE _cc0083_before AS
SELECT
  (SELECT count(*)
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open')            AS n_context,
  (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                         coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                         ORDER BY c.politician_id, c.topic_id))
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
     JOIN inform.compass_topics t ON t.id = c.topic_id
    WHERE NOT (t.topic_key = 'housing'
               AND c.politician_id IN (SELECT politician_id FROM _cc0083_want)))  AS others_digest,
  (SELECT md5(string_agg(md5(c.reasoning), E'\n' ORDER BY c.politician_id))
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
     JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing'
     JOIN _cc0083_want g ON g.politician_id = c.politician_id)                    AS prose_digest;

-- ── PRECONDITIONS ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  -- 1. Season 2 is open
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'open' AND number = 2) THEN
    RAISE EXCEPTION 'CC_0083: Season 2 is not the open season';
  END IF;

  -- 2. three target rows, and the uuid resolves to the person named in this file
  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN essentials.politicians p ON p.id = g.politician_id AND p.full_name = g.who;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0083: % of 3 politician_ids resolve to the name written beside them', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_context c ON c.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0083: % of 3 housing context rows found in the open season', v_n;
  END IF;

  -- 3. 🔴 EACH ROW STILL HOLDS EXACTLY THE THREE URLS THAT WERE READ. Refuse if a
  --    fourth appeared meanwhile — a rewrite would drop it.
  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_context c ON c.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing'
   WHERE c.sources IS DISTINCT FROM g.had
     AND c.sources IS DISTINCT FROM g.want;      -- already applied is fine
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0083: % row(s) no longer hold the three sources this file was written against — re-read them', v_n;
  END IF;

  -- 4. every target is a published claim at chair 4.
  --    @zero-scope: excludes-blanks — a 0 is a blank spoke and publishes no prose.
  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_answers a ON a.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'housing'
   WHERE a.value = 4;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0083: % of 3 target answers sit at chair 4', v_n;
  END IF;

  -- 5. 🔴 THE PROSE MUST STILL NAME WHAT IS BEING CITED. One reference per row is
  --    enough to prove the sentence survives; all 13 were read by hand today.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing'
    JOIN _cc0083_want g ON g.politician_id = c.politician_id
   WHERE (g.who = 'Keon Hardemon'    AND c.reasoning LIKE '%R-560-26%'  AND c.reasoning LIKE '%R-744-25%')
      OR (g.who = 'Marleine Bastien' AND c.reasoning LIKE '%R-450-25%'  AND c.reasoning LIKE '%R-664-26%')
      OR (g.who = 'Kionne L. McGhee' AND c.reasoning LIKE '%R-1120-25%' AND c.reasoning LIKE '%R-783-25%');
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0083: % of 3 rows still name the instruments being cited — re-read before citing', v_n;
  END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────
UPDATE inform.politician_context c
   SET sources    = g.want,
       updated_at = now()
  FROM _cc0083_want g, inform.seasons s, inform.compass_topics t
 WHERE c.politician_id = g.politician_id
   AND s.id = c.season_id AND s.status = 'open'
   AND t.id = c.topic_id  AND t.topic_key = 'housing'
   AND c.sources IS DISTINCT FROM g.want;

-- ── POST-VERIFY ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  -- 1. 🔑 EVERY TARGET ARRAY, BY EQUALITY. Membership, count, order and
  --    no-duplicates in one assertion, per row.
  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_context c ON c.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing'
   WHERE c.sources = g.want;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0083: % of 3 rows read back as the exact expected array', v_n;
  END IF;

  -- 2. 9 + 8 + 5 = 22 citations across the three rows, up from 9
  SELECT sum(array_length(c.sources, 1)) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_context c ON c.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing';
  IF v_n <> 22 THEN
    RAISE EXCEPTION 'CC_0083: the three rows carry % citations, expected 22', v_n;
  END IF;

  -- 3. every URL is the citable matter.asp form, and none repeats within its row
  SELECT count(*) INTO v_n
    FROM _cc0083_want g
    JOIN inform.politician_context c ON c.politician_id = g.politician_id
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing',
         unnest(c.sources) AS u
   WHERE u NOT LIKE 'https://www.miamidade.gov/govaction/matter.asp?matter=%';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0083: % source(s) are not the citable matter.asp form', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT c.politician_id, u, count(*) AS k
      FROM _cc0083_want g
      JOIN inform.politician_context c ON c.politician_id = g.politician_id
      JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
      JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing',
           unnest(c.sources) AS u
     GROUP BY 1, 2 HAVING count(*) > 1) d;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0083: % duplicated citation(s) within a row', v_n;
  END IF;

  -- 4. the voter-facing prose is byte-identical on all three. This file cites.
  IF (SELECT md5(string_agg(md5(c.reasoning), E'\n' ORDER BY c.politician_id))
        FROM inform.politician_context c
        JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
        JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'housing'
        JOIN _cc0083_want g ON g.politician_id = c.politician_id)
     IS DISTINCT FROM (SELECT prose_digest FROM _cc0083_before) THEN
    RAISE EXCEPTION 'CC_0083: a reasoning changed — this file must not edit prose';
  END IF;

  -- 5. 🔴 NOTHING ELSE MOVED, including Rodriguez's and Regalado's housing rows,
  --    which this sweep found complete and must leave alone.
  IF (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                            coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                            ORDER BY c.politician_id, c.topic_id))
        FROM inform.politician_context c
        JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
        JOIN inform.compass_topics t ON t.id = c.topic_id
       WHERE NOT (t.topic_key = 'housing'
                  AND c.politician_id IN (SELECT politician_id FROM _cc0083_want)))
     IS DISTINCT FROM (SELECT others_digest FROM _cc0083_before) THEN
    RAISE EXCEPTION 'CC_0083: another context row''s sources changed — the UPDATE was too wide';
  END IF;

  -- 6. no row created or destroyed
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open';
  IF v_n <> (SELECT n_context FROM _cc0083_before) THEN
    RAISE EXCEPTION 'CC_0083: open-season context rows went from % to %',
      (SELECT n_context FROM _cc0083_before), v_n;
  END IF;

  RAISE NOTICE 'CC_0083 OK: Hardemon 9, Bastien 8, McGhee 5 citations (22, was 9). Prose unchanged; every other open-season row untouched.';
END $$;

DROP TABLE _cc0083_want;
DROP TABLE _cc0083_before;

COMMIT;
