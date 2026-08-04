-- 1549_repair_schemeless_citations.sql
--
-- Prepend the missing `https://` to 372 citations across 200 context rows so they are URLs at all.
--
--   Review:   data/stance-retirement/2026-08-04-schemeless-findings.md
--   Probe:    data/stance-retirement/2026-08-04-schemeless-probe.json (what each repaired URL serves)
--   Rollback: UPDATE inform.politician_context c SET sources = r.old FROM (…) -- the inverse is mechanical:
--             strip the leading 'https://' from any element whose remainder appears in the probe artifact's
--             `raw` list. The artifact records all 71 distinct raw strings, so the pre-state is recoverable.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1549_repair_schemeless_citations.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY
-- ---------------------------------------------------------------------------------------------------
-- 372 citations are stored without a scheme -- `votemiller.com`, `laist.com/news/politics/voter-guides/…`,
-- `ballotpedia.org/John_Logsdon`. They are not URLs, so **nothing that fetches a source can read them**,
-- which means every reachability verdict ever recorded for these rows was made against an unfetchable
-- string. They were invisible until a host-extraction regex that assumed a scheme returned the whole
-- string and then failed DNS on it.
--
-- 🔴 **Every affected row is wholly uncheckable today**: measured before writing, the affected rows hold
-- **only scheme-less sources -- not one carries a citation a reader could follow.** That is what this
-- repair fixes.
--
-- 🔴 **The count is 372, not 312, and the dry run is what corrected me.** My first measurement joined
-- `politician_answers`, which silently excluded citations living on **orphan context rows** (context with
-- no answer -- the 546-row anomaly found by migration 1548's over-broad guard). The true scope:
--
--   | | rows | scheme-less citations |
--   |---|---|---|
--   | context rows WITH an answer | 166 | 312 |
--   | **orphan context rows (no answer)** | **34** | **60** |
--   | total | **200** | **372** |
--
-- All 200 rows belong to the same 20 politicians and the same 71 distinct strings -- one research batch.
-- The orphan rows are repaired too: the defect is in the data either way, and leaving 60 citations
-- unparseable to keep them out of scope would preserve exactly the invisibility this fixes. Repairing a
-- source neither creates nor blesses a stance, so it cannot make the orphan anomaly worse.
-- ⚠ **The 34 orphan rows remain an open, undiagnosed finding** — voter-facing reasoning attached to a
-- (politician, topic) pair with no answer. This migration does not resolve that, and must not be read as
-- having done so.
--
-- All 71 distinct strings are host-shaped (`^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}([/#?].*)?$`, asserted below),
-- so prepending the scheme is mechanical and asserts nothing about page content. They are one research
-- batch -- the Los Angeles 2026 primary cohort (mayor, city council, city attorney, LA County).
--
-- What the repaired URLs actually serve, probed first (`scripts/probe-schemeless-citations.mjs`):
--   * **60 distinct / 268 citations → HTTP 200.** The repair yields a live page.
--   * 2 / 10 → **403 bot-blocked** (`lapublicpress.org`, `19thnews.org`) -- valid URLs that render fine
--     for a voter. A 403 is a block, never absence.
--   * 6 / 20 → **404 gone** (`colterforla.com`, `andrej4la.com`, two `theeastsiderla.com` paths,
--     `ladowntownnews.com`, `spectrumnews1.com`).
--   * 2 / 14 → **no response** (`acostaforla.com`, `aida4la.com`) -- lapsed campaign domains, the normal
--     end state of a real campaign site.
--
-- ⚠ **The 34 citations that repair into a dead URL are still repaired here, deliberately.** The defect
-- being fixed is "this is not a URL"; whether the page is reachable is a different question with its own
-- queue and its own evidence standard. Turning a dead string into a dead-but-well-formed URL makes it
-- VISIBLE to the reachability sweep for the first time -- silently leaving it unparseable is what hid it.
-- They are recorded by name in the review doc so they enter that queue rather than looking repaired.
--
-- ⚠ **This will RAISE the CI gate count, and that is an improvement** -- the same effect migration 1527
-- had. 17 bare hosts (133 citations) become newly visible to `PRIMARY_SITE_NO_PATH`, and 6
-- `ballotpedia.org/...` strings become visible to `BALLOTPEDIA_ONLY`. Those rows were previously falling
-- through every branch of the gate because they did not parse as URLs. The baseline is ratcheted in the
-- SAME commit, with this explanation, exactly as the gate's own header instructs.
--
-- **No stance value, no reasoning, and no citation is added or removed** -- only the scheme is prefixed.
-- Element count and order are preserved and asserted.

BEGIN;

CREATE TEMP TABLE _before_1549 AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS n_answers,
       (SELECT count(*) FROM inform.politician_context) AS n_context,
       (SELECT sum(array_length(sources, 1)) FROM inform.politician_context) AS n_citations,
       (SELECT count(*) FROM inform.politician_context c
          WHERE EXISTS (SELECT 1 FROM unnest(c.sources) x WHERE x NOT ILIKE 'http://%' AND x NOT ILIKE 'https://%')) AS n_bad_rows;

-- ---- pre-flight ------------------------------------------------------------------------------------
DO $$
DECLARE v_rows int; v_pols int; v_cites int; v_n int; v_live int; v_orph int;
BEGIN
  -- Counted WITHOUT joining answers, so orphan context rows are in scope; the split is asserted below.
  SELECT count(*), count(DISTINCT c.politician_id) INTO v_rows, v_pols
    FROM inform.politician_context c
   WHERE EXISTS (SELECT 1 FROM unnest(c.sources) x WHERE x NOT ILIKE 'http%');
  IF v_rows <> 200 THEN RAISE EXCEPTION 'expected 200 affected rows, found %', v_rows; END IF;
  IF v_pols <> 20 THEN RAISE EXCEPTION 'expected 20 affected politicians, found %', v_pols; END IF;

  SELECT count(*) INTO v_cites FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s WHERE s NOT ILIKE 'http%';
  IF v_cites <> 372 THEN RAISE EXCEPTION 'expected 372 scheme-less citations, found %', v_cites; END IF;

  -- The live/orphan split must be what the review doc says, so a later reader can trust both numbers.
  SELECT count(*) INTO v_live FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
    CROSS JOIN LATERAL unnest(c.sources) AS s WHERE s NOT ILIKE 'http%';
  SELECT count(*) INTO v_orph FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s
   WHERE s NOT ILIKE 'http%'
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF v_live <> 312 OR v_orph <> 60 THEN
    RAISE EXCEPTION 'expected 312 on answered rows and 60 on orphan rows, found % and %', v_live, v_orph;
  END IF;

  -- 🔴 Every string must be HOST-SHAPED before a scheme is glued to it. Without this, prose or a torn
  -- fragment would silently become "https://<garbage>" -- and prose in `sources` is a defect class that
  -- migrations 1527-1530 spent four migrations closing. NON_URL_SOURCE is zero-tolerance for a reason.
  SELECT count(*) INTO v_n FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s
   WHERE s NOT ILIKE 'http%' AND s !~ '^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}([/#?].*)?$';
  IF v_n <> 0 THEN RAISE EXCEPTION '% scheme-less source(s) are not host-shaped — inspect by hand, do not prefix', v_n; END IF;

  -- No row may already hold the schemed twin of a bare string, or the repair would create a duplicate.
  SELECT count(*) INTO v_n FROM (
    SELECT c.politician_id, c.topic_id,
           (SELECT array_agg(CASE WHEN s ILIKE 'http%' THEN s ELSE 'https://'||s END)
              FROM unnest(c.sources) AS s) AS fixed
      FROM inform.politician_context c
     WHERE EXISTS (SELECT 1 FROM unnest(c.sources) x WHERE x NOT ILIKE 'http%')) q
   WHERE array_length(fixed,1) <> (SELECT count(DISTINCT e) FROM unnest(q.fixed) e);
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) would gain a duplicate citation', v_n; END IF;
END $$;

-- ---- repair ----------------------------------------------------------------------------------------
-- WITH ORDINALITY keeps the original element order; only the prefix changes.
UPDATE inform.politician_context c
   SET sources = r.fixed
  FROM (
    SELECT c2.politician_id, c2.topic_id,
           array_agg(CASE WHEN u.s ILIKE 'http://%' OR u.s ILIKE 'https://%' THEN u.s
                          ELSE 'https://' || u.s END ORDER BY u.ord) AS fixed
      FROM inform.politician_context c2
      CROSS JOIN LATERAL unnest(c2.sources) WITH ORDINALITY AS u(s, ord)
     WHERE EXISTS (SELECT 1 FROM unnest(c2.sources) x WHERE x NOT ILIKE 'http://%' AND x NOT ILIKE 'https://%')
     GROUP BY c2.politician_id, c2.topic_id
  ) r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

-- ---- verify ----------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_a int; v_c int; v_cites int; v_badrows int; v_sample text[];
BEGIN
  -- Not one scheme-less citation may remain, anywhere.
  SELECT count(*) INTO v_n FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s WHERE s NOT ILIKE 'http%';
  IF v_n <> 0 THEN RAISE EXCEPTION '% scheme-less citation(s) still present', v_n; END IF;

  -- Nothing added, nothing removed: the corpus-wide citation count is identical.
  SELECT n_answers, n_context, n_citations, n_bad_rows INTO v_a, v_c, v_cites, v_badrows FROM _before_1549;
  SELECT sum(array_length(sources,1)) INTO v_n FROM inform.politician_context;
  IF v_n <> v_cites THEN RAISE EXCEPTION 'citation count moved % -> %; this migration must only prefix', v_cites, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers;
  IF v_n <> v_a THEN RAISE EXCEPTION 'politician_answers moved % -> %', v_a, v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context;
  IF v_n <> v_c THEN RAISE EXCEPTION 'politician_context moved % -> %', v_c, v_n; END IF;
  IF v_badrows <> 200 THEN RAISE EXCEPTION 'snapshot disagreed on affected rows (%), abort', v_badrows; END IF;

  -- Every citation in the corpus now parses as an absolute http(s) URL.
  SELECT count(*) INTO v_n FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s WHERE s !~ '^https?://[^ ]+$';
  IF v_n <> 0 THEN RAISE EXCEPTION '% citation(s) still do not parse as an absolute URL', v_n; END IF;

  -- Spot-check two known repairs by value, not by count.
  SELECT array_agg(s) INTO v_sample FROM inform.politician_context c
    CROSS JOIN LATERAL unnest(c.sources) AS s
   WHERE s IN ('https://votemiller.com', 'https://ballotpedia.org/John_Logsdon');
  IF v_sample IS NULL OR array_length(v_sample,1) < 2 THEN
    RAISE EXCEPTION 'expected the votemiller.com and ballotpedia.org/John_Logsdon repairs to be present';
  END IF;
END $$;

DROP TABLE _before_1549;

-- Report: the repaired citations grouped by what they now serve, per the pre-migration probe.
SELECT CASE
         WHEN s LIKE 'https://colterforla.com%' OR s LIKE 'https://andrej4la.com%'
           OR s LIKE 'https://theeastsiderla.com%' OR s LIKE 'https://ladowntownnews.com%'
           OR s LIKE 'https://spectrumnews1.com%' THEN 'repaired but 404 — reachability queue'
         WHEN s LIKE 'https://acostaforla.com%' OR s LIKE 'https://aida4la.com%'
           THEN 'repaired but host dead — lapsed campaign domain'
         WHEN s LIKE 'https://lapublicpress.org%' OR s LIKE 'https://19thnews.org%'
           THEN 'repaired, 403 bot-blocked (renders for a voter)'
         ELSE 'repaired and live'
       END AS disposition,
       count(*) AS citations
  FROM inform.politician_context c
  CROSS JOIN LATERAL unnest(c.sources) AS s
 WHERE s ~ '^https://(votemiller|elmerroldan|mayorpratt|estuardo4la|raeforla|colterforla|henrymantelforla|louforcd1|timgaspar|acostaforla|dylanfordistrict13|logsdonforla|moforla|aida4la|hyman4mayor|kimforla|lamayor2026|andrej4la|lindseyhorvath)\.|^https://(laist|lapublicpress|nbclosangeles|beverlypress|patch|mynewsla|theeastsiderla|19thnews|ballotpedia|lalcv|marvistavoice|thelalocal|ladefensa|ladowntownnews|foxnews|msmagazine|spectrumnews1|therealdeal|valleynewsgroup|cityattorney)\.'
 GROUP BY 1 ORDER BY 2 DESC;

COMMIT;
