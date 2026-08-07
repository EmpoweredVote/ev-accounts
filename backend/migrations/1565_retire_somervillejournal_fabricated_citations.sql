-- 1565_retire_somervillejournal_fabricated_citations.sql
--
-- APPLIED 2026-08-06, operator-approved. Retire 44 Somerville stance rows citing somervillejournal.com.
--
--   Rollback: data/stance-retirement/2026-08-06-migration-1565-rollback.json — all 44 rows verbatim.
--   Evidence: sj-workset.json · sj-pages.json · sj-classification.json
--   Follows:  1564 (the main fabricated-source retirement)
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THIS OVERTURNS THIS WORKSTREAM'S OWN STANDING ADVICE
-- ---------------------------------------------------------------------------------------------------
-- Every prior note said somervillejournal.com is "a genuine paper whose domain died — RE-POINT to
-- Wayback captures, do NOT retire", and it was excluded from 1564 on that basis. Asked to perform that
-- re-point, there is nothing to point to. Four independent checks:
--
--   ✅ POSITIVE CONTROL PASSES — the host is richly archived: 3,000 captures spanning 2001 -> 2025.
--   🔴 ZERO captures of the cited paths (sampled), and ZERO archived urls under /2020*, /2022*, /2024*.
--      The date-slug scheme NEVER existed on this domain.
--   🔴 The real article scheme was NUMERIC: somervillejournal.com/20418049.htm.
--   🔴 From 2021 the domain was a PDF SPAM FARM — 1,801 of 2,000 captures are
--      cgi-bin/content/view.php?data=...&filetype=pdf (car manuals, textbooks). Yet the citations are
--      dated 2019-2025, including years when the domain served nothing but spam.
--
-- The genuine Somerville Journal was a Wicked Local paper; real coverage lives at
-- wickedlocal.com/somerville*. Matching a row's claim to one of those articles is per-row research, not
-- a mechanical re-point — the 1564 lesson that a re-point is valid ONLY if the TARGET carries the CLAIM.
--
-- 🔑 HOW THE WRONG CALL WAS MADE, and it generalises: "the publication is real" was verified at BRAND
-- level and never at DOMAIN-ERA or PATH-SCHEME level. A masthead can be real while the domain has
-- changed hands, and a host can be richly archived while the cited URL FORM never existed on it.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY ALL 44 ROWS, WHEN ONLY 3 ARE SOLE-SOURCED
-- ---------------------------------------------------------------------------------------------------
-- All 18 surviving citations were fetched and read. NOT ONE is coverage:
--   * 10 x somervillema.gov/city-council/members/<name> -> HTTP 404. 🔴 And the scheme is itself
--     invented: the real councillor pages are somervillema.gov/content/councilor-<name> and
--     /departments/city-council/councilor-<name>. That is 10 more fabricated paths on a host which
--     already carried 5 confirmed fabrications (retired by 1564).
--     ⚠ Re-pointing to the REAL councillor pages was tested and rejected: they are 451-word contact
--     pages — zoning 0, housing 0, climate 0, rent 0. A bio page states no position.
--   * somervillema.gov/somervision (10 rows) and /departments/programs/climate-forward (9 rows) are
--     real CITY PROGRAM pages that name no individual — the attribute-prior class.
--   * 6 x malegislature.gov/Bills/192/H#### are STATE bills cited for CITY COUNCILLORS, who cannot
--     sponsor them, and none names the citing official.
-- So every row is either sole-sourced (3) or nav-only (41); none keeps a real co-source.
--
-- ---------------------------------------------------------------------------------------------------
-- BLAST RADIUS — NO CHIP FLIPS REQUIRED
-- ---------------------------------------------------------------------------------------------------
--   City of Somerville            44 of 52 answers -> 8 remain, chip stays true
--   Somerville Public Schools     11 of 18 answers -> 7 remain, chip stays true
--
-- ⚠ Those two do not sum to 44: several of these officials hold BOTH a council seat and a school
-- committee seat, so a row counts under both governments. And the per-row "government" label in
-- sj-classification.json is NOT reliable for this — it comes from a LEFT JOIN LATERAL ... LIMIT 1 that
-- picks an arbitrary office. It first suggested Somerville would keep 13; measuring properly against all
-- offices gives 8. 🔑 For a chip decision, count answers per government directly, never from a
-- one-office-per-politician label.
--   12 politicians touched; 10 drop to zero answers (Mbah, Ewen-Campen, Link, Strezo, Wheeler,
--   McLaughlin, Scott, Sait, Davis, Hardt). last_stances_researched_at nulled for those emptied,
--   computed at run time rather than hard-coded.

BEGIN;

CREATE TEMP TABLE sj_urls(url text PRIMARY KEY);
INSERT INTO sj_urls(url) VALUES
    ('https://www.somervillejournal.com/2019/09/wilson-healthcare-expansion/'),
    ('https://www.somervillejournal.com/2020/06/mbah-racial-justice-statement/'),
    ('https://www.somervillejournal.com/2020/06/somerville-racial-justice-resolution/'),
    ('https://www.somervillejournal.com/2020/09/mbah-immigrant-rights-op-ed/'),
    ('https://www.somervillejournal.com/2020/12/ewen-campen-climate-emergency-resolution/'),
    ('https://www.somervillejournal.com/2021/04/ewen-campen-housing-resolution/'),
    ('https://www.somervillejournal.com/2021/06/wilson-pride-civil-rights/'),
    ('https://www.somervillejournal.com/2021/07/non-citizen-voting-somerville/'),
    ('https://www.somervillejournal.com/2021/08/ewen-campen-environmental-justice/'),
    ('https://www.somervillejournal.com/2021/11/09/wilson-climate-bill/'),
    ('https://www.somervillejournal.com/2021/11/sait-racial-equity-election/'),
    ('https://www.somervillejournal.com/2022/03/24/somerville-rent-stabilization-petition/'),
    ('https://www.somervillejournal.com/2022/03/somerville-rent-stabilization-petition/'),
    ('https://www.somervillejournal.com/2022/04/somerville-housing-equity-council/'),
    ('https://www.somervillejournal.com/2022/07/ewen-campen-zoning-resolution/'),
    ('https://www.somervillejournal.com/2022/07/somerville-ward6-environmental-updates/'),
    ('https://www.somervillejournal.com/2022/09/mbah-housing-equity/'),
    ('https://www.somervillejournal.com/2022/09/somerville-housing-debate-council/'),
    ('https://www.somervillejournal.com/2022/10/somerville-brickbottom-development/'),
    ('https://www.somervillejournal.com/2023/04/somerville-east-environment-ward1/'),
    ('https://www.somervillejournal.com/2023/05/somerville-housing-council-president/'),
    ('https://www.somervillejournal.com/2023/05/somerville-ward1-housing-development/'),
    ('https://www.somervillejournal.com/2023/06/somerville-climate-forward-update/'),
    ('https://www.somervillejournal.com/2023/11/link-council-election/'),
    ('https://www.somervillejournal.com/2023/11/somerville-at-large-council-results/'),
    ('https://www.somervillejournal.com/2024/04/link-zoning-transit/'),
    ('https://www.somervillejournal.com/2024/04/somerville-zoning-debate/'),
    ('https://www.somervillejournal.com/2024/05/somerville-rent-stabilization-debate/'),
    ('https://www.somervillejournal.com/2024/07/somerville-climate-forward-council/'),
    ('https://www.somervillejournal.com/2025/01/somerville-anti-deportation-response/'),
    ('https://www.somervillejournal.com/2025/11/somerville-ward7-council-election/');

CREATE TEMP TABLE sj_retire(politician_id uuid, topic_id uuid);
INSERT INTO sj_retire(politician_id, topic_id) VALUES
    ('9b11117c-d064-404b-8c89-0042f417c576','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('9b11117c-d064-404b-8c89-0042f417c576','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('9b11117c-d064-404b-8c89-0042f417c576','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('9b11117c-d064-404b-8c89-0042f417c576','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('9b11117c-d064-404b-8c89-0042f417c576','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('ce379255-f87e-4856-9e2c-dda38c976bdc','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('ce379255-f87e-4856-9e2c-dda38c976bdc','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('a79ac715-57a6-4a18-82a0-0b8a5ed60464','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('a79ac715-57a6-4a18-82a0-0b8a5ed60464','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('bc02a2c7-2033-40a3-89f6-e50d95ac1e4e','669cac97-66a6-4087-b036-936fbe62efb3');

DO $$
DECLARE
  v_n int; v_ans_before bigint; v_ctx_before bigint; v_nulled int; v_cohort uuid[]; v_orphans int;
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  SELECT count(*) INTO v_n FROM sj_urls;
  IF v_n <> 31 THEN RAISE EXCEPTION '1565: expected 31 urls, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM sj_retire;
  IF v_n <> 44 THEN RAISE EXCEPTION '1565: expected 44 retire rows, found %', v_n; END IF;

  -- Every row citing one of these urls must be in the retire list. This cluster has NO survivors worth
  -- keeping, so anything unaccounted for means the classification is stale and nothing should be deleted.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM sj_urls)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM sj_retire);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % affected rows are not in the retire list — classification is stale', v_n; END IF;

  -- Each targeted row must still exist and still cite one of these urls.
  SELECT count(*) INTO v_n FROM sj_retire r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM sj_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % retire rows no longer cite a somervillejournal url', v_n; END IF;

  -- Cross-check the structural half in SQL, as 1564 did.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM sj_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM sj_urls));
  IF v_n <> 3 THEN
    RAISE EXCEPTION '1565: SQL says % sole-sourced, classification says 3', v_n; END IF;

  SELECT count(*) INTO v_orphans FROM sj_retire r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id);
  RAISE NOTICE '1565: % of 44 retire rows are orphan context', v_orphans;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM sj_retire;

  DELETE FROM inform.politician_answers pa USING sj_retire r
   WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id;
  DELETE FROM inform.politician_context pc USING sj_retire r
   WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id;

  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;
  RAISE NOTICE '1565: nulled last_stances_researched_at for % emptied politicians', v_nulled;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN (SELECT url FROM sj_urls);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % somervillejournal citations survived', v_n; END IF;

  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> 44 THEN
    RAISE EXCEPTION '1565: context rows did not fall by exactly 44'; END IF;
  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> 44 - v_orphans THEN
    RAISE EXCEPTION '1565: answers fell by the wrong amount'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % emptied politicians still carry a timestamp', v_n; END IF;

  RAISE NOTICE '1565: retired 44 rows, % politicians emptied',
    (SELECT count(*) FROM unnest(v_cohort) c(id)
      WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id));
END $$;

COMMIT;
