-- 1602_repoint_and_strip_cosourced_dead_citations.sql
--
-- The co-sourced half of the dead-host queue: 17 live stance rows where a dead citation sits
-- ALONGSIDE a working one. **None is retired.** A surviving co-source means the evidence exists, so
-- the remedies are re-point (9) and strip (5), with 3 held back for reasons recorded below.
--   Rollback record: data/stance-retirement/2026-08-07-cosourced-rollback.json
--   Findings record: data/stance-retirement/2026-08-07-dead-host-repoint-pass.md
--   Follows 1600 (re-point, sole-sourced) and 1601 (retire, unsupportable).
--
-- ⚠ THE QUEUE WAS 23 AND IS 17. The 23 was counted against the pre-fix dead-host list, which
-- included the hosts that were never dead -- they publish an A record only on `www`, the form their
-- citations already use (see 1600 and the probe fix in citation-host-resolve.mjs).
--
-- 🔴 EVERY STATEMENT HERE IS SCOPED TO ROWS THAT HAVE AN ANSWER, AND THAT IS LOAD-BEARING.
-- Three ORPHAN context rows (reasoning with no answer) cite these same URLs: 1 on davidfbristol.com
-- and 2 on craigandresforprosper.com. **Both craigandres orphans are SOLE-sourced**, so an unscoped
-- `array_remove` would have emptied them and tripped EMPTY_SOURCES, which is zero-tolerance.
-- The first dry run caught this -- the Bristol guard read 5 rows where the live-row analysis said 4.
-- Orphans belong to the ORPHAN_CONTEXT queue (baseline 58) and are deliberately left alone here;
-- fixing their citations does not change their orphan status and would only blur two queues.
-- ⚠ Generalise: when a remedy is derived from LIVE rows, scope the SQL to live rows. politician_context
-- is the larger table -- answers are a strict subset of it.
--
-- ---------------------------------------------------------------------------------------------
-- RE-POINT (9 rows). Each target was fetched and verified to carry that row's distinctive terms.
--
--   Knudsen / Homelessness -> THE LIVE CANONICAL ARTICLE, not an archive.
--     `m.lasvegassun.com` is a RETIRED MOBILE SUBDOMAIN; the desktop host serves the same story at
--     the same path (HTTP 200, 62,292 bytes) carrying "Knudsen", "camping", "5-2" and "homeless" --
--     every term the row rests on. Always check for a canonical twin before reaching for Wayback: a
--     live original beats a capture.
--
--   Bristol x4 -> capture 20220114203456 (davidfbristol.com/).
--     🔴 CAPTURE CHOICE, AGAIN. Of four 200-captures, the 2024 pair are 114-byte stubs and the 2025
--     is 478 bytes -- the site was gone. Only the 2022 capture is substantive (62,929 bytes,
--     6,584 visible, "David Bristol - For Mayor of Prosper, TX") and carries economic development,
--     public safety, police, tax, growth. A "200" in a CDX listing is not a page; check the body.
--
--   Rosenbarger x3 -> capture 20241223130926 (kateforbloomington.org/issues/).
--     Carries "racial and social equity", "safe and accessible streets", housing, transit.
--     ⚠ Only THREE of her four rows. See the strip list for why Public Safety is excluded.
--
--   Brownley / Immigration -> capture 20171224115857 (the DREAM Act action page).
--     Her own petition page, carrying "DREAM Act" and her name. The row's DREAM Act clause has no
--     other source, so stripping it would have left that clause unsupported -- re-point, don't strip.
--
-- ---------------------------------------------------------------------------------------------
-- STRIP (5 rows). The dead citation is removed and the row keeps its verified live co-source.
-- Each surviving co-source was FETCHED and confirmed to carry the row's claim before stripping --
-- stripping a row whose evidence lived on the dead URL would leave a citation that does not support
-- what the row says (the mgaleg.maryland.gov lesson).
--
--   Rosenbarger / Public Safety  -- the issues capture does NOT contain "public safety", and the
--     reasoning itself says the assessment rests on her 2023 bsquarebulletin interview. That page
--     carries "non-police", "mental health" and "jail is not a place for recovery". The campaign
--     issues page was never this row's evidence, so re-pointing it would have dressed up a citation
--     that never supported the claim.
--   Vivio / Healthcare  -- the /about capture carries none of "medicare", "buy-in", "compete",
--     "cobra"; it is a bio page. stlmag.com carries all four.
--   Andres x2  -- the ONLY capture of craigandresforprosper.com is 2018, which PRE-DATES his 2021
--     candidacy: the Chapman domain-reuse trap in another form. weareprosper (2021 candidate
--     profile) and therealdeal carry the claims.
--   Brownley / Deportation  -- rests on her 2026 ICE press conference; the 2017 DREAM Act petition
--     adds nothing. juliabrownley.house.gov carries "ICE", "due process", "asylum", "deportation".
--
-- ---------------------------------------------------------------------------------------------
-- 🔴 HELD BACK (3 rows), deliberately untouched. Both reasons are the kind that a bulk strip hides.
--
--   Mejia x2 (kennethforla.com, zero captures) -- STRIPPING WOULD REGRESS THE GATE. His Abortion
--     row's only other source is ballotpedia.org/Kenneth_Mejia, so a strip converts it into a
--     BALLOTPEDIA_ONLY row -- a number the gate says must only ever go DOWN. Trading an unreachable
--     citation for a gate regression is not a repair. Both rows go to the re-research queue instead.
--     ⚠ The Abortion row is also a pure inference row ("As a Democratic Socialist and former
--     congressional candidate, he consistently supports...") -- the attribute-prior class. Its real
--     problem is not the dead URL.
--
--   Lungo-Koehn / Climate Change -- ITS "LIVE" CO-SOURCE IS ALSO DEAD. metromayor.org has no DNS and
--     no captures, and medfordma.org/departments/sustainability/climate-action/ returns HTTP 404
--     (so does /departments/sustainability/; the root is 200 -- the site reorganised, the
--     actonmass.org failure mode). So this row is not co-sourced at all: it is wholly unreachable and
--     was only counted as co-sourced because the earlier analysis tested HOSTS, not PATHS.
--     ⚠ Generalise: host-level liveness does not imply the cited PAGE exists. Needs re-research.

BEGIN;

DO $$
DECLARE
  v_n            int;
  v_cites_before bigint;
  v_cites_after  bigint;
  v_rows_before  bigint;
  v_rows_after   bigint;
  v_empty        int;
  -- re-point targets
  k_old text := 'https://m.lasvegassun.com/news/2019/nov/06/tense-las-vegas-council-oks-homeless-ordinance/';
  k_new text := 'https://lasvegassun.com/news/2019/nov/06/tense-las-vegas-council-oks-homeless-ordinance/';
  b_old text := 'https://davidfbristol.com/';
  b_new text := 'https://web.archive.org/web/20220114203456/https://davidfbristol.com/';
  r_old text := 'https://kateforbloomington.org/issues/';
  r_new text := 'https://web.archive.org/web/20241223130926/https://kateforbloomington.org/issues/';
  j_old text := 'https://act.juliabrownley.com/page/s/call-on-congress-to-pass-the-dream-act';
  j_new text := 'https://web.archive.org/web/20171224115857/https://act.juliabrownley.com/page/s/call-on-congress-to-pass-the-dream-act';
  a_old text := 'https://craigandresforprosper.com/';
  v_old text := 'https://vivioforcongress.com/about/';
  -- row keys
  p_rosen uuid := '4aa0dadf-a3c0-41e9-a5de-66582a393622';
  t_pubsaf uuid := 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
  p_brown uuid := '01147c2b-0f40-4255-b09e-b5a19a45fd31';
  t_deport uuid := '44905f3b-e105-4f6c-afc7-5d223813dbac';
  t_immig  uuid := '4e2c69ce-591e-4197-9cd5-7aceff79d390';
BEGIN
  SELECT count(*) INTO v_cites_before FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_rows_before  FROM inform.politician_context;

  -- ---- pre-state guards. LIVE rows only -- see the orphan note in the header. ----
  -- ⚠ KEYS ONLY. A first draft cached `sources` here too, and the post-verify then read a STALE
  -- snapshot and reported 14 surviving dead citations that had already been repaired. A temp table
  -- is a snapshot; join it for membership and always read column values from the live table.
  CREATE TEMP TABLE _live_1602 ON COMMIT DROP AS
    SELECT pc.politician_id, pc.topic_id FROM inform.politician_context pc
     WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id = pc.politician_id AND a.topic_id = pc.topic_id);

  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE k_old = ANY(pc.sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1602: expected 1 Knudsen row, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE b_old = ANY(pc.sources);
  IF v_n <> 4 THEN RAISE EXCEPTION '1602: expected 4 Bristol rows, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE r_old = ANY(pc.sources);
  IF v_n <> 4 THEN RAISE EXCEPTION '1602: expected 4 Rosenbarger rows (3 repoint + 1 strip), found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE j_old = ANY(pc.sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1602: expected 2 Brownley rows (1 repoint + 1 strip), found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE a_old = ANY(pc.sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1602: expected 2 Andres rows, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE v_old = ANY(pc.sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1602: expected 1 Vivio row, found %', v_n; END IF;

  -- The orphan overlap must be exactly what the header describes, or the scoping is wrong.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE (b_old = ANY(pc.sources) OR a_old = ANY(pc.sources))
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id = pc.politician_id AND a.topic_id = pc.topic_id);
  IF v_n <> 3 THEN RAISE EXCEPTION '1602: expected 3 orphan rows on these URLs, found %', v_n; END IF;

  -- Nothing may already hold a replacement, or array_replace would duplicate.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE k_new = ANY(sources) OR b_new = ANY(sources) OR r_new = ANY(sources) OR j_new = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1602: % rows already hold a replacement URL', v_n; END IF;

  -- Every row about to be STRIPPED must keep at least 2 sources, or the strip creates EMPTY_SOURCES,
  -- which is a zero-tolerance gate class.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id)
   WHERE ((pc.politician_id = p_rosen AND pc.topic_id = t_pubsaf AND r_old = ANY(pc.sources))
       OR (pc.politician_id = p_brown AND pc.topic_id = t_deport AND j_old = ANY(pc.sources))
       OR (a_old = ANY(pc.sources)) OR (v_old = ANY(pc.sources)))
     AND cardinality(pc.sources) < 2;
  IF v_n <> 0 THEN RAISE EXCEPTION '1602: % strip targets would be emptied', v_n; END IF;

  -- ---- re-points (9 rows). `IN (SELECT ... FROM _live_1602)` keeps orphans out. ----
  UPDATE inform.politician_context pc SET sources = array_replace(sources, k_old, k_new)
   WHERE k_old = ANY(sources)
     AND EXISTS (SELECT 1 FROM _live_1602 l WHERE l.politician_id = pc.politician_id AND l.topic_id = pc.topic_id);

  UPDATE inform.politician_context pc SET sources = array_replace(sources, b_old, b_new)
   WHERE b_old = ANY(sources)
     AND EXISTS (SELECT 1 FROM _live_1602 l WHERE l.politician_id = pc.politician_id AND l.topic_id = pc.topic_id);

  -- Rosenbarger: 3 of her 4, by topic. Public Safety is stripped instead, not re-pointed.
  UPDATE inform.politician_context SET sources = array_replace(sources, r_old, r_new)
   WHERE r_old = ANY(sources) AND politician_id = p_rosen AND topic_id <> t_pubsaf;

  UPDATE inform.politician_context SET sources = array_replace(sources, j_old, j_new)
   WHERE j_old = ANY(sources) AND politician_id = p_brown AND topic_id = t_immig;

  -- ---- strips (5 rows) ----
  UPDATE inform.politician_context SET sources = array_remove(sources, r_old)
   WHERE politician_id = p_rosen AND topic_id = t_pubsaf AND r_old = ANY(sources);

  UPDATE inform.politician_context SET sources = array_remove(sources, j_old)
   WHERE politician_id = p_brown AND topic_id = t_deport AND j_old = ANY(sources);

  -- 🔴 LIVE ROWS ONLY. Andres's two ORPHAN rows are sole-sourced to this URL; removing it there
  -- would empty them and trip the zero-tolerance EMPTY_SOURCES class.
  UPDATE inform.politician_context pc SET sources = array_remove(sources, a_old)
   WHERE a_old = ANY(sources)
     AND EXISTS (SELECT 1 FROM _live_1602 l WHERE l.politician_id = pc.politician_id AND l.topic_id = pc.topic_id);

  UPDATE inform.politician_context pc SET sources = array_remove(sources, v_old)
   WHERE v_old = ANY(sources)
     AND EXISTS (SELECT 1 FROM _live_1602 l WHERE l.politician_id = pc.politician_id AND l.topic_id = pc.topic_id);

  -- ---- post-verify ----
  -- No LIVE row may still cite a dead URL. The 3 orphan citations are expected to remain.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc JOIN _live_1602 l USING (politician_id, topic_id),
         unnest(pc.sources) s
   WHERE s IN (k_old, b_old, r_old, j_old, a_old, v_old);
  IF v_n <> 0 THEN RAISE EXCEPTION '1602: % dead citations survived on live rows', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN (b_old, a_old);
  IF v_n <> 3 THEN RAISE EXCEPTION '1602: expected the 3 orphan citations untouched, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE k_new = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1602: Knudsen re-point landed on % rows', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE b_new = ANY(sources);
  IF v_n <> 4 THEN RAISE EXCEPTION '1602: Bristol re-point landed on % rows', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE r_new = ANY(sources);
  IF v_n <> 3 THEN RAISE EXCEPTION '1602: Rosenbarger re-point landed on % rows, expected 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE j_new = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1602: Brownley re-point landed on % rows', v_n; END IF;

  -- No row may have been emptied. EMPTY_SOURCES is zero-tolerance.
  SELECT count(*) INTO v_empty FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_empty <> 404 THEN
    RAISE EXCEPTION '1602: empty-sources rows moved to % (the 404 legitimate documented blanks must be unchanged)', v_empty; END IF;

  -- 9 re-points are citation-neutral; 5 strips remove exactly one citation each.
  SELECT count(*) INTO v_cites_after FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_rows_after  FROM inform.politician_context;
  IF v_cites_before - v_cites_after <> 5 THEN
    RAISE EXCEPTION '1602: citations fell by %, expected 5', v_cites_before - v_cites_after; END IF;
  IF v_rows_after <> v_rows_before THEN
    RAISE EXCEPTION '1602: context row count moved % -> %', v_rows_before, v_rows_after; END IF;

  -- The 3 held rows must be untouched.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s LIKE '%kennethforla%' OR s LIKE '%metromayor.org%';
  IF v_n <> 3 THEN RAISE EXCEPTION '1602: held rows changed -- expected 3 citations, found %', v_n; END IF;

  -- No row TOUCHED BY THIS MIGRATION may hold a duplicate citation.
  -- 🔴 THIS CHECK WAS CORPUS-WIDE ON THE FIRST DRAFT AND FAILED THE DRY RUN AT 4 -- all four
  -- PRE-EXISTING and unrelated to these rows (Markey/Tariffs and Garland Barr/Fossil Fuels and
  -- Rick Allen/Voting Rights each hold their ontheissues.org URL twice; Quirk-Silva/Housing holds a
  -- leginfo AB670 link twice). That is the third time on this workstream an over-broad assertion has
  -- surfaced a real defect (1524, 1530): narrow the check AND record what it found, never just
  -- narrow it. Logged as a follow-up queue in the findings record; NOT fixed here, because a
  -- de-duplication is a different change with its own blast radius.
  SELECT count(*) INTO v_n FROM (
    SELECT pc.politician_id, pc.topic_id, s
      FROM inform.politician_context pc, unnest(pc.sources) s
     WHERE s IN (k_new, b_new, r_new, j_new)
        OR (pc.politician_id IN (p_rosen, p_brown) )
     GROUP BY pc.politician_id, pc.topic_id, s HAVING count(*) > 1) d;
  IF v_n <> 0 THEN RAISE EXCEPTION '1602: % duplicated citations on rows this migration touched', v_n; END IF;

  RAISE NOTICE '1602: 9 re-pointed, 5 stripped, 3 held; citations % -> %', v_cites_before, v_cites_after;
END $$;

COMMIT;
