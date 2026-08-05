-- 1559_repoint_dead_campaign_about_pages.sql
--
-- Re-point 5 citations across 5 stance rows from two dead campaign `/about` pages to verified Wayback
-- captures. No chair, value or reasoning is touched; only the `sources` array changes, one URL for one URL.
--   Rollback: data/stance-retirement/2026-08-04-nav-page-sweep.md (full sweep record, all classes)
--
-- Found by the nav-page sweep that followed the operator ruling "landing pages don't count as coverage".
-- 🔴 THAT SWEEP'S FIRST TWO CUTS BOTH OVER-FIRED — see the sweep record. A shape screen (no digits in
-- path + short slugs) flagged 10,877 rows / 33% of the corpus, mostly per-person Wikipedia, OnTheIssues
-- and Ballotpedia pages and members' own `/issues` pages, all of which DO state positions. Narrowing to
-- a curated nav-path list gave 53 rows, but that list included `/about`, which on a CAMPAIGN site is
-- substantive biography rather than navigation — the bilalmahmood.com/about lesson from 1557. Of the 53,
-- only 17 are government nav pages; the rest are campaign `/about` pages and mostly fine.
--
-- These 5 are neither class: the campaign site itself is GONE, so the citation is unfetchable.
--
--   * `dutra4whittier.com` (3 rows, Fernando Dutra, Whittier CA council) — does not resolve, curl exit 6,
--     no A record. Wayback holds 41 captures of the exact cited path, newest 2026-03-06.
--   * `chaselaporte.com` (2 rows, Chase LaPorte, KS-3 candidate) — host resolves but the SITE IS EXPIRED:
--     both `/about` and the root return 404 with a Squarespace "Website Expired / This account has
--     expired" body. A lapsed campaign domain is the normal end state of a real campaign, not an invented
--     outlet. Wayback holds 3 captures, newest **2026-08-02 — two days before this migration**.
--
-- Captures fetched with the `id_` modifier and `--compressed` (1557's two lessons: raw bytes so the
-- Wayback banner cannot satisfy a name test, and gzip decoding so content tests are not run against
-- binary that looks exactly like a parked domain).
--
-- Verified to name the candidate and carry the rows' distinctive claim terms:
--   Dutra   `About Fernando - Fernando Dutra`, 129 name mentions; "prosper", "jobs", "environment",
--           "public safety" all present.
--   LaPorte `About — Chase LaPorte for Congress | Kansas 3rd District Republican`, 25 name mentions;
--           **"sanctity of life" verbatim**, plus "Constitution", "Kansas", "inflation", "red tape",
--           "keep more of what" — every distinctive term in both rows.
--
-- ⚠ NOT REPAIRED, deliberately: two of Dutra's three reasonings use phrases the page does not contain —
-- "smart economic growth" ("economic" appears 0 times) and "fighting crime" ("crime" 0). The page does
-- support the substance ("businesses ... prosper", "quality jobs", "highest priority to public safety"),
-- and this migration fixes UNFETCHABILITY, not wording. Those two phrasings go to the sourcing-quality
-- queue rather than being silently blessed by a successful re-point.

BEGIN;

DO $$
DECLARE
  v_n                int;
  v_before_citations bigint;
  v_after_citations  bigint;
BEGIN
  SELECT count(*) INTO v_before_citations FROM inform.politician_context pc, unnest(pc.sources) s;

  -- Guard: exact pre-state, and every affected row must be sole-sourced to the dead URL (which is why
  -- these rows have no checkable evidence at all today).
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE 'https://www.dutra4whittier.com/about/' = ANY(sources);
  IF v_n <> 3 THEN RAISE EXCEPTION '1559: expected 3 rows citing dutra4whittier.com/about/, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE 'https://www.chaselaporte.com/about' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1559: expected 2 rows citing chaselaporte.com/about, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE ('https://www.dutra4whittier.com/about/' = ANY(sources)
       OR 'https://www.chaselaporte.com/about' = ANY(sources))
     AND array_length(sources, 1) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '1559: % of these rows are not sole-sourced — re-review', v_n; END IF;

  -- No other path on either host may ride along unverified.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE (s ILIKE '%dutra4whittier%' OR s ILIKE '%chaselaporte%')
     AND s NOT IN ('https://www.dutra4whittier.com/about/', 'https://www.chaselaporte.com/about');
  IF v_n <> 0 THEN RAISE EXCEPTION '1559: % citations use an unverified path on these hosts', v_n; END IF;

  -- ---- the re-point ----
  UPDATE inform.politician_context
     SET sources = array_replace(sources,
           'https://www.dutra4whittier.com/about/',
           'https://web.archive.org/web/20260306195604/https://www.dutra4whittier.com/about/')
   WHERE 'https://www.dutra4whittier.com/about/' = ANY(sources);

  UPDATE inform.politician_context
     SET sources = array_replace(sources,
           'https://www.chaselaporte.com/about',
           'https://web.archive.org/web/20260802055115/https://www.chaselaporte.com/about')
   WHERE 'https://www.chaselaporte.com/about' = ANY(sources);

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN ('https://www.dutra4whittier.com/about/', 'https://www.chaselaporte.com/about');
  IF v_n <> 0 THEN RAISE EXCEPTION '1559: % bare dead-host citations survived', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE sources::text LIKE '%web.archive.org%dutra4whittier%'
      OR sources::text LIKE '%web.archive.org%chaselaporte%';
  IF v_n <> 5 THEN RAISE EXCEPTION '1559: expected 5 rows citing a capture, found %', v_n; END IF;

  SELECT count(*) INTO v_after_citations FROM inform.politician_context pc, unnest(pc.sources) s;
  IF v_after_citations <> v_before_citations THEN
    RAISE EXCEPTION '1559: citation count moved % -> %', v_before_citations, v_after_citations; END IF;

  RAISE NOTICE '1559 OK: 5 citations re-pointed, corpus citations %', v_after_citations;
END $$;

COMMIT;
