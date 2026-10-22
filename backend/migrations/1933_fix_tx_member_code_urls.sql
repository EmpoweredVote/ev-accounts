-- Migration 1933 — repoint five capitol.texas.gov member URLs that cite the wrong page.
--
-- WHAT THIS IS. Found while re-researching the blanked stance rows (migration 1931). Five of the
-- `capitol.texas.gov/Members/MemberInfo.aspx?...Code=` URLs stored in `politician_context.sources`
-- do not resolve to the politician whose row cites them. 🔴 ONE OF THEM RESOLVES TO A DIFFERENT
-- SITTING LEGISLATOR: `A1390`, cited on Ramon Romero Jr.'s rows, is **Sen. Taylor Rehmet**.
-- The other four return HTTP 500 and name nobody.
--
-- 🔴🔴 WHY THIS WAS INVISIBLE. A wrong member code does NOT error on the reports it feeds. The
-- authored-bills report for a bad code returns a clean page reading "No bills have been authored."
-- During migration 1931 that silently reported five legislators as having filed nothing at all —
-- a plausible empty result, indistinguishable from the truth. The control that caught it was
-- resolving each code to a NAME and comparing it with the person expected.
--
-- ⚠ AND THE CONTROL HAD TWO FALSE POSITIVES OF ITS OWN, BOTH MINE, BOTH FROM NAME MATCHING:
--   · `A3455` (Terry Meza) was reported bad and is CORRECT — the page reads
--     'Rep. Thresa "Terry" Meza', District 105, and the quoted nickname defeated the comparison.
--   · `A4290` (Terri Leo-Wilson) likewise — the site writes "Terri Leo Wilson" without the hyphen.
--   ▶ So the headline "six bad codes" was wrong and this migration fixes FIVE. A name comparison
--     is a detector like any other, and it needed its own control.
--
-- THE CORRECTIONS, each verified by fetching the new URL and reading the name AND district it
-- returns — not by trusting a member-list scrape:
--   Rhetta Bowers      A1442 -> A3565   "Rhetta Bowers", District 113
--   Philip Cortez      A1432 -> A2365   "Philip Cortez", District 117
--   Ray Lopez          A1424 -> A3915   "Ray Lopez", District 125   (a second Lopez, Janie, is A4295)
--   Ramon Romero Jr.   A1390 -> A3060   "Ramon Romero, Jr.", District 90
--   Rafael Anchía      A1290 -> A2150   "Rafael Anchía", District 103
--
-- 🔴 SEASON 1 IS NOT TOUCHED, AND THE REASON IS A GUARD IN THE DATABASE, NOT A CHOICE OF MINE.
-- history and must not move. This pass touches only `politician_context.sources`, and it corrects a
-- pointer that was wrong the day it was written. Leaving 25 Season 1 rows citing the wrong
-- legislator would preserve an error, not history. 🔴 A guard below asserts that NO answer, in any
-- season, is modified by this migration.
--
-- Applied by hand via psql. Guards fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1933_fixes (old_code text, new_code text, who text);
INSERT INTO mig1933_fixes VALUES
  ('A1442','A3565','Rhetta Bowers'),
  ('A1432','A2365','Philip Cortez'),
  ('A1424','A3915','Ray Lopez'),
  ('A1390','A3060','Ramon Romero Jr.'),
  ('A1290','A2150','Rafael Anchia');

-- Freeze the rows to change, so the update and the verification speak about the same set.
CREATE TEMP TABLE mig1933_targets AS
SELECT pc.politician_id, pc.topic_id, pc.season_id, f.old_code, f.new_code,
       s AS old_url, replace(s, 'Code=' || f.old_code, 'Code=' || f.new_code) AS new_url
  FROM inform.politician_context pc
  CROSS JOIN LATERAL unnest(pc.sources) s
  JOIN mig1933_fixes f ON s LIKE '%capitol.texas.gov/Members/MemberInfo%Code=' || f.old_code
 WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;   -- OPEN season only

-- GUARD 1 — the population is what was measured: 46 citations, 5 codes, 5 people, 2 seasons.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1933_targets;
  IF n <> 21 THEN RAISE EXCEPTION 'migration 1933: expected 21 bad citations in the open season, found % — re-measure', n; END IF;
  SELECT count(DISTINCT old_code) INTO n FROM mig1933_targets;
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1933: expected 5 distinct bad codes, found %', n; END IF;
  SELECT count(DISTINCT politician_id) INTO n FROM mig1933_targets;
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1933: expected 5 people, found %', n; END IF;
END $$;

-- GUARD 2 — 🔴 A BAD CODE MUST BELONG TO EXACTLY ONE PERSON. If a code were cited across two
-- politicians, a blanket string replace would repoint somebody else's citation too.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (
    SELECT old_code FROM mig1933_targets GROUP BY old_code HAVING count(DISTINCT politician_id) > 1
  ) s;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % bad code(s) are cited by more than one politician — a blanket replace is unsafe', n; END IF;
END $$;

-- GUARD 3 — the new code must not already be in use by a DIFFERENT politician, which would mean
-- the correction itself points at the wrong person.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1933_targets t
    JOIN inform.politician_context pc ON pc.politician_id <> t.politician_id
    CROSS JOIN LATERAL unnest(pc.sources) s
   WHERE s LIKE '%MemberInfo%Code=' || t.new_code;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % new code citation(s) already belong to another politician', n; END IF;
END $$;

-- The fix: swap the code inside the URL, in place, leaving every other source untouched.
UPDATE inform.politician_context pc
   SET sources = array_replace(pc.sources, t.old_url, t.new_url),
       updated_at = now()
  FROM mig1933_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id AND pc.season_id = t.season_id;

-- GUARD 4 — verify the RESULT.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    CROSS JOIN LATERAL unnest(pc.sources) s
    JOIN mig1933_fixes f ON s LIKE '%MemberInfo%Code=' || f.old_code
   WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % bad-code citation(s) survive in the open season', n; END IF;

  SELECT count(*) INTO n
    FROM mig1933_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id AND pc.season_id=t.season_id
   WHERE NOT (pc.sources @> ARRAY[t.new_url]);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % row(s) did not receive the corrected URL', n; END IF;

  -- No row may lose or gain a source: this is a swap, not an append.
  -- ⚠ SCOPED TO THE ROWS THIS PASS TOUCHED. An unscoped version of this guard counted 466
  -- pre-existing source-less rows across the corpus and failed the dry run — a true statement
  -- about the database that said nothing about this migration.
  SELECT count(*) INTO n
    FROM mig1933_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id=t.politician_id AND pc.topic_id=t.topic_id AND pc.season_id=t.season_id
   WHERE pc.sources IS NULL OR cardinality(pc.sources) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % touched row(s) now carry no sources', n; END IF;

  -- 🔴 NO ANSWER, IN ANY SEASON, MAY HAVE MOVED. This pass touches citations only.
  -- ⚠ SCOPED, for the same reason as the guard above: unscoped, it counted 2 answers another
  -- session had just written and failed a migration that touches no answer at all. A guard that
  -- reads the whole table reports the world, not this transaction.
  SELECT count(*) INTO n
    FROM mig1933_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id=t.politician_id AND pa.topic_id=t.topic_id AND pa.season_id=t.season_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1933: % answer(s) of a touched row were modified — this pass must touch only sources', n; END IF;

  RAISE NOTICE 'migration 1933: repointed 21 member-code citations across 5 politicians in the OPEN season; 25 Season 1 citations left for a ruling';
END $$;

DROP TABLE mig1933_targets;
DROP TABLE mig1933_fixes;
