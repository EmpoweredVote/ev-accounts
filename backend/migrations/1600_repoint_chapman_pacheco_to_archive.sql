-- 1600_repoint_chapman_pacheco_to_archive.sql
--
-- Re-point 7 citations across 7 stance rows (2 politicians) from two genuinely dead campaign hosts
-- to Wayback captures that were fetched and verified to carry each row's claims. No chair, value or
-- reasoning is touched; only the `sources` array changes, one URL for one URL.
--   Findings record: data/stance-retirement/2026-08-07-dead-host-repoint-pass.md
--   Rollback record: data/stance-retirement/2026-08-07-chapman-pacheco-repoint-rollback.json
--   Queue entry:     re-research worklist job 1 (dead-host classification 2026-08-04)
--
-- Numbering taken from origin/master after a fetch, never from the local checkout (the 1557 lesson).
--
-- ---------------------------------------------------------------------------------------------
-- 🔴 WHY ONLY 2 HOSTS OUT OF THE 22 IN THE QUEUE. The 2026-08-04 classification resolved each host
-- AFTER STRIPPING `www.`, but 8 of those domains publish an A record ONLY on the `www` subdomain --
-- which is the form the citations already use. Probing all 30 stored URLs exactly as stored, 14
-- return HTTP 200 with real content: davidredkey4congress, tracinskiletter, bradknott, markhenderson,
-- allenrwaters, cambridgeresidentsalliance, rightnowmn, publicleadershipinstitute. Those citations
-- were never broken and are NOT touched here.
-- Generalise: resolve the host AS CITED. Normalising `www.` away invents a dead host, the same way
-- reshaping a value before testing it hid the scheme-less citations until 1549.
-- ⚠ Tracinski's 4 rows nearly read as an eighth invented-outlet cluster -- zero Wayback captures on
-- a host whose apex fails DNS -- but all four cited articles are live 200s. Newsletter article pages
-- simply are not archived. Zero captures + dead apex is NOT evidence of fabrication.
--
-- ---------------------------------------------------------------------------------------------
-- 🔴 CAPTURE CHOICE IS A CORRECTNESS DECISION (the 1557 rule), AND CHAPMAN IS WHY.
-- `chapmanforcongress.com/issues/` holds 13 captures: 2003 x1, 2014 x11, 2026 x1. The domain was
-- REUSED ACROSS ELECTION CYCLES, so 12 of the 13 belong to a different candidate's campaign entirely.
-- Frank Chapman is a 2026 WY-AL candidate (FEC H6WY01157). Re-pointing to the earliest or the most
-- plentiful capture -- which is what the classification's `REPOINTABLE_ALL` label invites, since it
-- only ever asked "was this URL captured", never "is the capture contemporaneous" -- would have cited
-- a stranger's platform under Chapman's name.
-- The 2026-05-11 capture is the ONLY one that can support these rows, and it is the one used.
--
-- ---------------------------------------------------------------------------------------------
-- VERIFIED TO CARRY THE CLAIMS. Each capture was fetched with the `id_` modifier and `--compressed`
-- (id_ bodies are gzipped; without it every content test reports zero matches, which reads exactly
-- like a parked domain), then searched for the distinctive terms of the rows citing it.
--
--   chapmanforcongress.com/issues/  @ 20260511050003  -- 5 rows, all sole-sourced
--     Abortion       "beginning with conception"                                     PRESENT
--     Immigration    "those who follow the system"                                   PRESENT
--     Voting Rights  "SAVE Act"                                                      PRESENT
--     Taxes          "lowering taxes, cutting red tape and letting the free-market
--                     system work"                                                   PRESENT
--     Fossil Fuels   "removing government obstacles from producing American energy,
--                     while protecting our environment ... reliance on foreign oil"  PRESENT
--     ⚠ Taxes and Fossil Fuels first scored ABSENT on the literal terms "free market" and
--       "domestic energy". Both were false negatives: the page reads "free-market" (hyphenated) and
--       "producing American energy". Read the passage before recording a term as absent.
--
--   www.maryannforwhittier.com/issues @ 20231215180833  -- 2 rows, all sole-sourced
--     Housing              "affordable", "first-time", "homebuyer", "developer"      PRESENT
--     Public Safety        "community policing", "safety"                            PRESENT
--
-- The stored replacement is the ordinary `/web/<ts>/` form, NOT `id_`: id_ is a fetch modifier for
-- verification, while the voter-facing link should render with the archive's own banner.
--
-- ⚠ NOT INCLUDED, and each for a stated reason (see the findings record):
--   Monteiro 2   -- two captures exist and NEITHER carries the claims. Re-pointing would manufacture
--                   support. His archived "Priorities" sub-page may hold them, but the row cites the
--                   ROOT, and sourcing a row to a page its author never used is the thing 1557
--                   explicitly refused to do.
--   Stephenson 3 -- `boli.oregon.gov` is a COMPOSED hostname (Oregon serves BOLI at
--                   www.oregon.gov/boli, 200). No DNS, no captures: it never existed. Not
--                   re-pointable -- the cited path is a news INDEX, and a landing page is not
--                   coverage. Also has the invented URL appended into the voter-facing reasoning.
--   Martinez 2, Frometa 1 -- lapsed campaign domain / no captures. Claim probably true, unverifiable.
--                   "The page is gone" is not "verified absent", so they are NOT retired here.

BEGIN;

DO $$
DECLARE
  v_n                int;
  v_before_citations bigint;
  v_after_citations  bigint;
  v_before_rows      bigint;
  v_after_rows       bigint;
  v_dupes            int;
  v_chapman uuid := '3f841602-c711-43fe-84a7-d99fa06f4c3c';
  v_pacheco uuid := 'ae459902-7c4f-4ae9-bce6-de9d6cd93710';
  c_old text := 'https://chapmanforcongress.com/issues/';
  c_new text := 'https://web.archive.org/web/20260511050003/https://chapmanforcongress.com/issues/';
  p_old text := 'https://www.maryannforwhittier.com/issues';
  p_new text := 'https://web.archive.org/web/20231215180833/https://www.maryannforwhittier.com/issues';
BEGIN
  -- Corpus invariants are captured, never hard-coded -- a literal drifts the moment another session
  -- lands a migration (the 1545 rule).
  SELECT count(*) INTO v_before_citations FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_before_rows      FROM inform.politician_context;

  -- ---- guards: the exact pre-state, or these arrays no longer describe these rows ----
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE c_old = ANY(sources);
  IF v_n <> 5 THEN RAISE EXCEPTION '1600: expected 5 rows citing chapmanforcongress.com/issues/, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE p_old = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1600: expected 2 rows citing maryannforwhittier.com/issues, found %', v_n; END IF;

  -- Every affected row must belong to the politician whose campaign site it is. A shared campaign URL
  -- on someone else's row would mean this is not the repair it claims to be.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE sources::text ILIKE '%chapmanforcongress%' AND politician_id <> v_chapman;
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % chapmanforcongress rows belong to another politician', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE sources::text ILIKE '%maryannforwhittier%' AND politician_id <> v_pacheco;
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % maryannforwhittier rows belong to another politician', v_n; END IF;

  -- No path variant outside the two verified ones. An unverified path must stop the migration rather
  -- than ride along unrepaired (the guard that caught the 17-vs-12 undercount in 1562).
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%chapmanforcongress%' AND s <> c_old;
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % citations use an unverified chapmanforcongress path', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%maryannforwhittier%' AND s <> p_old;
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % citations use an unverified maryannforwhittier path', v_n; END IF;

  -- Nothing may already hold the archived twin, or array_replace would create a duplicate.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE c_new = ANY(sources) OR p_new = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % rows already cite the archived capture', v_n; END IF;

  -- ---- the re-point: one URL for one URL, order preserved by array_replace ----
  UPDATE inform.politician_context
     SET sources = array_replace(sources, c_old, c_new)
   WHERE c_old = ANY(sources);

  UPDATE inform.politician_context
     SET sources = array_replace(sources, p_old, p_new)
   WHERE p_old = ANY(sources);

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s = c_old OR s = p_old;
  IF v_n <> 0 THEN RAISE EXCEPTION '1600: % dead-host citations survived the re-point', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE c_new = ANY(sources);
  IF v_n <> 5 THEN RAISE EXCEPTION '1600: expected 5 Chapman rows on the capture, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE p_new = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1600: expected 2 Pacheco rows on the capture, found %', v_n; END IF;

  -- A re-point must be citation-count neutral, corpus-wide: nothing added, nothing lost.
  SELECT count(*) INTO v_after_citations FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_after_rows      FROM inform.politician_context;
  IF v_after_citations <> v_before_citations THEN
    RAISE EXCEPTION '1600: citation count moved % -> %', v_before_citations, v_after_citations; END IF;
  IF v_after_rows <> v_before_rows THEN
    RAISE EXCEPTION '1600: context row count moved % -> %', v_before_rows, v_after_rows; END IF;

  -- No row may gain a duplicate by acquiring the archived twin of a URL it already held.
  SELECT count(*) INTO v_dupes FROM (
    SELECT pc.politician_id, pc.topic_id, s
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE pc.politician_id IN (v_chapman, v_pacheco)
     GROUP BY pc.politician_id, pc.topic_id, s
    HAVING count(*) > 1
  ) d;
  IF v_dupes <> 0 THEN RAISE EXCEPTION '1600: % duplicated citations after re-point', v_dupes; END IF;

  RAISE NOTICE '1600: re-pointed 7 citations (Chapman 5, Pacheco 2); citations % rows %',
    v_after_citations, v_after_rows;
END $$;

COMMIT;
