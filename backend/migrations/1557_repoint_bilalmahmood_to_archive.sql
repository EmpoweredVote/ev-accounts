-- 1557_repoint_bilalmahmood_to_archive.sql
--
-- Re-point 14 citations across 12 stance rows from the dead host `bilalmahmood.com` to verified
-- Wayback captures. No chair, value or reasoning is touched; only the `sources` array changes,
-- one URL for one URL.
--   Rollback record: data/stance-retirement/2026-08-04-bilalmahmood-repoint-rollback.json
--   Queue entry:     .planning/decisions -> re-research worklist job 1 (dead-host findings 2026-08-04)
--
-- ⚠ NUMBERING. This is 1557, not the 1550 the worklist predicted. A concurrent session pushed
-- 1551-1556 while the CivicPatch work was in flight, and 1550 is a renumber gap (the file that
-- briefly called itself 1550 landed as 1556). Numbers were taken from origin/master after a
-- fast-forward, never from the local checkout.
--
-- RETIRED BUT REAL — a re-point, not a retirement. `bilalmahmood.com` stopped resolving (curl
-- exit 6, no A record). Bilal Mahmood is a sitting San Francisco supervisor for District 5 and the
-- site was his real campaign site, archived 66 times at the root. So the pages existed, the claims
-- were sourced, and the defect is purely that the URL can no longer be fetched.
--
-- CAPTURE CHOICE IS A CORRECTNESS DECISION, NOT A CONVENIENCE. The 2026-06-24 captures were used
-- because they POST-DATE the 2026-05 journalism cited alongside on 10 of these 12 rows. Wayback also
-- holds 2023-2024 captures of all three paths, but Mahmood took office in January 2025, so those are
-- pre-incumbency campaign material — re-pointing a 2026 claim at a 2023 snapshot would have
-- misdated the evidence, which is the willametteweek/pretenure failure in a new coat.
--
-- Every capture was fetched with the `id_` modifier — raw original bytes, no injected Wayback banner,
-- because the banner echoes the archived URL and "bilalmahmood.com" contains "mahmood", which would
-- let a surname test pass on the toolbar instead of the page.
-- ⚠ `id_` responses are gzip-encoded. Fetch them with `--compressed`; without it the body is binary
-- and every content test reports zero matches, which reads exactly like a parked domain.
--
-- Verified to name Mahmood and to carry the distinctive claim terms of the rows citing them: 3 of 3.
--   /          title "Bilal Mahmood for San Francisco District 5 Supervisor"; verbatim
--              "No corporate PAC Money. No fossil fuel money. No law enforcement money."
--   /platform  "Upgrade California", "Smart A/C", "heat pumps", "electrify", "decarboniz",
--              "state legislators", "tax credit", "EV charging"; 11 policy sections.
--   /about     "Electric Action", "Upgrade California", "zero emission buildings".
--
-- 🔴 TWO ROWS WERE WHOLLY DEAD-SOURCED and were checked individually rather than in bulk:
-- Fossil Fuel Policy cited only `/` + `/platform`, and Climate Change cited only `/platform` +
-- `/about` — so those two rows had no fetchable citation at all, and every reachability verdict ever
-- recorded for them was made against an unreachable host. Both are supported by their own archived
-- pages; see the rollback record for the term-by-term check.
-- ⚠ NOT repaired here: Fossil Fuel Policy's reasoning also asserts he "worked previously at Electric
-- Action", which appears only on /about — a page that row does not cite. Adding that citation would
-- be inventing sourcing the original author did not use, so it stays for the re-research queue.

BEGIN;

DO $$
DECLARE
  v_n                 int;
  v_before_citations  bigint;
  v_after_citations   bigint;
  v_before_rows       bigint;
  v_after_rows        bigint;
  v_dupes             int;
  v_pol uuid := 'd3c5004c-9ca0-444e-96d9-107d4315abcb';
BEGIN
  -- Corpus invariants are captured, never hard-coded: a literal drifts the moment another session
  -- lands a migration, and this one raced six of them.
  SELECT count(*) INTO v_before_citations FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_before_rows      FROM inform.politician_context;

  -- Guard: the exact pre-state must still be in place, or these arrays no longer describe these rows.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://bilalmahmood.com/platform' = ANY(sources);
  IF v_n <> 9 THEN RAISE EXCEPTION '1557: expected 9 rows citing bilalmahmood.com/platform, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://bilalmahmood.com/about' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1557: expected 2 rows citing bilalmahmood.com/about, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://bilalmahmood.com/' = ANY(sources);
  IF v_n <> 3 THEN RAISE EXCEPTION '1557: expected 3 rows citing bilalmahmood.com/, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE sources::text ILIKE '%bilalmahmood%';
  IF v_n <> 12 THEN RAISE EXCEPTION '1557: expected 12 rows citing the host at all, found %', v_n; END IF;

  -- Every affected row must belong to Mahmood. A shared campaign URL on someone else's row would
  -- mean this is not the repair it claims to be.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE sources::text ILIKE '%bilalmahmood%' AND politician_id <> v_pol;
  IF v_n <> 0 THEN RAISE EXCEPTION '1557: % rows cite bilalmahmood.com for a different politician', v_n; END IF;

  -- No path variant outside the three verified ones. An unverified fourth path must stop the
  -- migration rather than ride along unrepaired.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s ILIKE '%bilalmahmood%'
     AND s NOT IN ('https://bilalmahmood.com/', 'https://bilalmahmood.com/platform', 'https://bilalmahmood.com/about');
  IF v_n <> 0 THEN RAISE EXCEPTION '1557: % citations use an unverified bilalmahmood path', v_n; END IF;

  -- ---- the re-point: one URL for one URL, order preserved by array_replace ----
  UPDATE inform.politician_context
     SET sources = array_replace(sources,
           'https://bilalmahmood.com/platform',
           'https://web.archive.org/web/20260624203251/https://bilalmahmood.com/platform')
   WHERE 'https://bilalmahmood.com/platform' = ANY(sources);

  UPDATE inform.politician_context
     SET sources = array_replace(sources,
           'https://bilalmahmood.com/about',
           'https://web.archive.org/web/20260624203251/https://bilalmahmood.com/about')
   WHERE 'https://bilalmahmood.com/about' = ANY(sources);

  UPDATE inform.politician_context
     SET sources = array_replace(sources,
           'https://bilalmahmood.com/',
           'https://web.archive.org/web/20260624203238/https://bilalmahmood.com/')
   WHERE 'https://bilalmahmood.com/' = ANY(sources);

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s LIKE 'https://bilalmahmood.com%';
  IF v_n <> 0 THEN RAISE EXCEPTION '1557: % bare-host citations survived the re-point', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE sources::text LIKE '%web.archive.org%bilalmahmood.com%';
  IF v_n <> 12 THEN RAISE EXCEPTION '1557: expected 12 rows now citing an archived capture, found %', v_n; END IF;

  -- Nothing added, nothing lost: a re-point must be citation-count neutral, corpus-wide.
  SELECT count(*) INTO v_after_citations FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_after_rows      FROM inform.politician_context;
  IF v_after_citations <> v_before_citations THEN
    RAISE EXCEPTION '1557: citation count moved % -> %', v_before_citations, v_after_citations; END IF;
  IF v_after_rows <> v_before_rows THEN
    RAISE EXCEPTION '1557: context row count moved % -> %', v_before_rows, v_after_rows; END IF;

  -- No row may gain a duplicate by acquiring the archived twin of a URL it already held.
  SELECT count(*) INTO v_dupes FROM (
    SELECT pc.politician_id, pc.topic_id, s, count(*)
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE pc.politician_id = v_pol
     GROUP BY 1, 2, 3 HAVING count(*) > 1) d;
  IF v_dupes > 0 THEN RAISE EXCEPTION '1557: % duplicated citations on Mahmood rows', v_dupes; END IF;
END $$;

COMMIT;
