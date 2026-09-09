BEGIN;

-- =============================================================================
-- CC_0081: Regalado's residential-zoning reasoning names ordinance 26-47 and
--          cites no source for it
-- =============================================================================
-- Slot CC_0081 reserved via `steward slot CC` before this file existed.
--
-- ✅ APPLIED TO PRODUCTION 2026-09-09. Dry-run first, aborted by a deliberate
--    exception because the Supabase MCP owns the transaction and a plain
--    ROLLBACK cannot be trusted through it; the revert was then confirmed by
--    re-reading the row (still 3 sources, `updated_at` untouched). After
--    applying: 4 sources, prose md5 unchanged, Season 2 still 2,795 answers /
--    2,767 context rows — the CI floor numbers, so no gate moves. Re-running the
--    guarded UPDATE afterwards rewrites 0 rows, which is the idempotency claim
--    below, measured rather than asserted.
--
-- WHAT THIS IS. One `sources` element added to one Season 2 context row. No
-- answer changes, no chair moves, no row is created or deleted.
--
-- ── WHY ──────────────────────────────────────────────────────────────────────
--
-- The voter-facing reasoning for Raquel A. Regalado on `residential-zoning`
-- (seated at chair 3 on 2026-09-08) asserts:
--
--   "She also prime-sponsored ordinance 26-47, which allows the county to accept
--    and approve Live Local Act covenants administratively for developments
--    inside transit-oriented areas"
--
-- and the row's three sources are matters 252269 (ordinance 25-90), 260764
-- (R-551-26) and 260967 (R-678-26). None of them is 26-47. `Citations.jsx`
-- renders that sentence to a voter beside three links that do not carry it.
--
-- 26-47 is matter 261065. Verified live against the county on 2026-09-08:
-- Ordinance, "Adopted as amended" 2026-06-02, sponsors "Raquel A. Regalado,
-- Prime Sponsor" and nobody else, title "ORDINANCE RELATING TO ZONING; CREATING
-- SECTION 33-39.5 ... PROVIDING FOR ADMINISTRATIVE ACCEPTANCE AND APPROVAL OF
-- COVENANTS RELATING TO THE LIVE LOCAL ACT IN CONNECTION WITH PROPOSED
-- DEVELOPMENTS LOCATED WITHIN TRANSIT-ORIENTED DEVELOPMENTS OR AREAS". The
-- claim is true. It was simply uncited.
--
-- 🔴 HOW IT SURVIVED THE PR #415 CONTROL, because the next pass needs to know:
--    that control ran SOURCES -> REALITY — every cited id resolves, names the
--    instrument the prose names, and carries the right prime sponsor. All five
--    citations on Regalado's two rows pass it. It cannot see the other
--    direction: an instrument the PROSE NAMES that no source points at. Run it
--    both ways — list every instrument the reasoning names, then check that
--    list against `sources`.
--
-- ⚠ THE CHAIR DOES NOT DEPEND ON THIS CITATION. Rung 3 is carried by 25-90 and
--   R-551-26 on their own — both cited, both station-bounded. 26-47 is
--   corroboration, which is why this is a citation fix and not a re-audit.
--
-- IDEMPOTENT: the UPDATE is guarded on the URL's absence, so re-applying is a
-- no-op and the post-verify still passes.
-- =============================================================================

DROP TABLE IF EXISTS _cc0081_target;
DROP TABLE IF EXISTS _cc0081_before;

CREATE TEMP TABLE _cc0081_target AS
SELECT c.politician_id, c.topic_id, c.season_id
  FROM inform.politician_context c
  JOIN inform.seasons s        ON s.id = c.season_id AND s.status = 'open'
  JOIN inform.compass_topics t ON t.id = c.topic_id  AND t.topic_key = 'residential-zoning'
 WHERE c.politician_id = 'ab1cf05e-cb5e-461a-8723-7ee87adac518';   -- Raquel A. Regalado

-- Everything this file must NOT move, captured before it moves anything.
CREATE TEMP TABLE _cc0081_before AS
SELECT
  (SELECT count(*)
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open')            AS n_context,
  (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                         coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                         ORDER BY c.politician_id, c.topic_id))
     FROM inform.politician_context c
     JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
    WHERE NOT EXISTS (SELECT 1 FROM _cc0081_target g
                       WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
                                                                                   AS others_digest,
  (SELECT md5(c.reasoning)
     FROM inform.politician_context c
     JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                          AND g.season_id = c.season_id)                           AS reasoning_md5,
  (SELECT array_length(c.sources, 1)
     FROM inform.politician_context c
     JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                          AND g.season_id = c.season_id)                           AS n_sources;

-- ── PRECONDITIONS ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int;
BEGIN
  -- 1. Season 2 is the open season. These sources were written against it.
  IF NOT EXISTS (SELECT 1 FROM inform.seasons WHERE status = 'open' AND number = 2) THEN
    RAISE EXCEPTION 'CC_0081: Season 2 is not the open season';
  END IF;

  -- 2. exactly one target row
  SELECT count(*) INTO v_n FROM _cc0081_target;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: % target context row(s), expected exactly 1', v_n;
  END IF;

  -- 3. 🔴 THE PROSE MUST STILL NAME 26-47. This file exists only to cite a claim
  --    the reasoning makes. If a later edit removed the claim, adding the source
  --    would attach a document to a sentence that no longer asserts it.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.reasoning LIKE '%26-47%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: the reasoning no longer names ordinance 26-47 — re-read the row before citing it';
  END IF;

  -- 4. the row is a published claim: a non-blank answer stands beside it.
  --    @zero-scope: excludes-blanks — a value of 0 is a blank spoke, and a blank
  --    publishes no sentence for a citation to support.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN _cc0081_target g ON g.politician_id = a.politician_id AND g.topic_id = a.topic_id
                         AND g.season_id = a.season_id
   WHERE a.value <> 0;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: the target pair carries no non-blank answer — nothing is published to cite';
  END IF;

  -- 5. the three existing sources are the ones this row was verified with
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE c.sources @> ARRAY[
           'https://www.miamidade.gov/govaction/matter.asp?matter=252269',
           'https://www.miamidade.gov/govaction/matter.asp?matter=260764',
           'https://www.miamidade.gov/govaction/matter.asp?matter=260967'];
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: the row no longer carries its three verified sources — read it before adding a fourth';
  END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────
-- Appended, not sorted: the existing three already ascend by matter id and
-- 261065 is the largest, so append preserves the order a reader sees.
--
-- ⚠ THE ELEMENT IS CAST EXPLICITLY. `text[] || 'literal'` is ambiguous and
--   Postgres reads the literal as an array, failing with "malformed array
--   literal" — which the dry run caught before this file went near prod.
UPDATE inform.politician_context c
   SET sources    = c.sources || ARRAY['https://www.miamidade.gov/govaction/matter.asp?matter=261065']::text[],
       updated_at = now()
  FROM _cc0081_target g
 WHERE g.politician_id = c.politician_id
   AND g.topic_id      = c.topic_id
   AND g.season_id     = c.season_id
   AND NOT ('https://www.miamidade.gov/govaction/matter.asp?matter=261065' = ANY (c.sources));

-- ── POST-VERIFY ──────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n       int;
  v_sources text[];
BEGIN
  SELECT c.sources INTO v_sources
    FROM inform.politician_context c
    JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id;

  -- 1. four sources, and the new one present exactly once
  IF array_length(v_sources, 1) <> 4 THEN
    RAISE EXCEPTION 'CC_0081: the row carries % source(s), expected 4', array_length(v_sources, 1);
  END IF;
  SELECT count(*) INTO v_n
    FROM unnest(v_sources) u
   WHERE u = 'https://www.miamidade.gov/govaction/matter.asp?matter=261065';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: matter 261065 appears % time(s), expected exactly 1', v_n;
  END IF;

  -- 2. the original three survived
  IF NOT (v_sources @> ARRAY[
            'https://www.miamidade.gov/govaction/matter.asp?matter=252269',
            'https://www.miamidade.gov/govaction/matter.asp?matter=260764',
            'https://www.miamidade.gov/govaction/matter.asp?matter=260967']) THEN
    RAISE EXCEPTION 'CC_0081: one of the three original sources is gone';
  END IF;

  -- 3. the voter-facing prose is byte-identical. This file cites; it does not edit.
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN _cc0081_target g ON g.politician_id = c.politician_id AND g.topic_id = c.topic_id
                         AND g.season_id = c.season_id
   WHERE md5(c.reasoning) = (SELECT reasoning_md5 FROM _cc0081_before);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0081: the reasoning text changed — this file must not edit prose';
  END IF;

  -- 4. 🔴 NOTHING ELSE IN THE OPEN SEASON MOVED. The digest covers every other
  --    context row's sources array, so a UPDATE whose predicate was too wide
  --    fails here rather than shipping.
  IF (SELECT md5(string_agg(c.politician_id::text || '/' || c.topic_id::text || '/' ||
                            coalesce(array_to_string(c.sources, '|'), ''), E'\n'
                            ORDER BY c.politician_id, c.topic_id))
        FROM inform.politician_context c
        JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open'
       WHERE NOT EXISTS (SELECT 1 FROM _cc0081_target g
                          WHERE g.politician_id = c.politician_id AND g.topic_id = c.topic_id))
     IS DISTINCT FROM (SELECT others_digest FROM _cc0081_before) THEN
    RAISE EXCEPTION 'CC_0081: another context row''s sources changed — the UPDATE predicate was too wide';
  END IF;

  -- 5. no row created or destroyed
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.seasons s ON s.id = c.season_id AND s.status = 'open';
  IF v_n <> (SELECT n_context FROM _cc0081_before) THEN
    RAISE EXCEPTION 'CC_0081: open-season context rows went from % to %',
      (SELECT n_context FROM _cc0081_before), v_n;
  END IF;

  RAISE NOTICE 'CC_0081 OK: Regalado residential-zoning now cites % sources, matter 261065 (ordinance 26-47) among them. Prose unchanged, % other open-season context rows untouched.',
    array_length(v_sources, 1), v_n - 1;
END $$;

DROP TABLE _cc0081_target;
DROP TABLE _cc0081_before;

COMMIT;
