-- 1607_newton_survivors_resolve.sql
--
-- Resolves the 7 published rows migration 1548 left behind when it retired 48 of Newton's 55
-- answers. 1548 deliberately did not act on them ("flipping on suspicion breaches verified absent ->
-- retire"); this is the verification it was waiting for.
--   Research record: data/stance-research/2026-08-07-newton-survivors.md
--   Rollback record: data/stance-retirement/2026-08-07-newton-survivors-rollback.json
--
-- 🔴 UNLIKE EVERY OTHER MIGRATION TODAY, THESE ROWS ARE LIVE. Both politicians are seated -- Lisle
-- Baker as Ward 7 City Councilor, Marc Laredo as Mayor -- so all 7 are voter-facing right now. This
-- is not a latent-risk cleanup.
--
-- 3 retired · 1 chair corrected · 1 chair re-grounded · 2 re-sourced and rewritten. Newton 7 -> 3.
--
-- ---------------------------------------------------------------------------------------------
-- BAKER x4 -- THE SOLE CITATION IS VERIFIED TO CARRY NOTHING.
--
-- All four cited only `law.suffolk.edu/.../r-lisle-baker/`, his Suffolk Law faculty profile. Fetched
-- 2026-08-07: HTTP 200, 6,205 visible characters, and every load-bearing term ABSENT --
-- "Newton", "council", "councillor", "MBTA", "zoning", "vote", "Climate Action". The word Newton
-- never appears on the page. The rows nonetheless assert his MBTA Communities vote, "his council
-- voting record", and his support for Newton's Climate Action Plan.
-- A live 200-returning page that supports not one claim made on it: the mgaleg.maryland.gov failure.
-- The rows also reason from his profession ("as a real estate law professor ... his academic writing
-- reflects support for smart-growth zoning reforms") -- attribute-prior.
--
-- 🔴 THE SUFFOLK CITATION IS DROPPED, AND THAT IS NOT THE SAME DECISION AS KEEPING ontheissues IN
-- 1606. There it was UNKNOWN -- the host resolved but would not connect, so nothing could be judged.
-- Here the page was READ IN FULL and verified not to mention the subject's council service at all.
-- Unknown is never grounds for removal; verified-not-to-carry is.
--
-- · Environmental Protection vs. Development -- RE-SOURCED, chair 1 -> 3. Newton Beacon,
--   27 November 2024: as CHAIR of Zoning & Planning, Baker took a straw poll, offered the motion that
--   passed, and voted to approve BERDO. Real, attributable, on the record.
--   ⚠ Chair 3, not 1, because the motion he actually offered MODERATED the ordinance: large
--   non-residential buildings meet full BERDO standards, but large residential buildings report
--   energy consumption ONLY with no emissions-reduction mandate, and Newton-Wellesley Hospital keeps
--   access to the city's exemption process rather than a total exemption. "Apply consistent
--   environmental standards while giving reasonable flexibility on implementation" is what that is.
--   Operator ruled chair 3 on 2026-08-07.
-- · Growth and Development Pace, Housing, Residential Zoning -- RETIRED. Nothing supports them: the
--   only citation carries nothing, and Baker is NOT NAMED in any coverage of the MBTA vote.
--
-- ---------------------------------------------------------------------------------------------
-- LAREDO x3 -- CHAIR 1 ON HOUSING IS CONTRADICTED BY THE RECORD.
--
-- All three cited only `newtonma.gov/government/mayor`, which is 403 to every fetcher (Akamai --
-- UNKNOWN, not absent) AND a landing page, which is not coverage under the ruling that flipped
-- Newton and Portland.
--
-- Housing chair 1 is "directly build and operate public housing so anyone who needs a home can get
-- one". Fig City News names him: "Councilor Marc Laredo, who supported an MBTA-ONLY zoning plan" --
-- minimum state compliance, not the broader Village Center Overlay District upzoning -- and he
-- seconded the motion to accept the amendments that produced the final plan. What passed was
-- substantially scaled back: five- and six-storey maximums cut to four, all VC3 converted to VC2,
-- the affordable-housing bonus narrowed. It yields ~8,745 units against a state minimum of 8,330.
-- Supporting the minimum is not chair 1. Re-chaired to 3 and re-sourced.
-- · Growth and Development Pace -- chair 2 KEPT but re-grounded: confining added capacity to
--   transit-served village centres is "allow growth only where existing infrastructure can support
--   it". The old text's "typical of progressive suburban mayors" -- a stance inferred from a
--   category -- is removed.
-- · Transportation Priorities -- RETIRED. Its claims (Green Line connectivity, bike infrastructure)
--   have no located source; the only citation is the 403 landing page.
--
-- ---------------------------------------------------------------------------------------------
-- TWO FACTUAL CORRECTIONS CARRIED OUT OF THIS, both worth more than the rows:
-- 1. The council vote was 21-2-1 on 4 DECEMBER 2023, not October. Two of these rows date it to
--    October; October was the ZAP COMMITTEE vote. Migration 1548 found this same October/December
--    confusion elsewhere -- it survived here only because 1548 did not touch these rows.
-- 2. 🔑 A 21-2-1 VOTE IS WEAK STANCE EVIDENCE. Twenty-one of twenty-four voted yes; the only NO votes
--    were Leary and Noel, with Ryan absent. "Voted for MBTA Communities compliance" distinguishes
--    almost nobody and cannot carry a housing or zoning chair by itself.
--    GENERALISE: near-unanimous votes are poor evidence of an individual position.
--
-- Newton's `hasContext` chip is already false (flipped 2026-08-04), so no chip decision rides on
-- this. Neither politician is emptied -- Baker keeps 1 answer, Laredo 2 -- so no timestamp may move.

BEGIN;

DO $$
DECLARE
  v_n         int;
  v_ctx_before bigint; v_ctx_after bigint;
  v_ans_before bigint; v_ans_after bigint;
  p_baker  uuid := '9d34705c-0a66-4c08-8936-7e63629ce435';
  p_laredo uuid := '9c64b145-cce4-4b31-a4e0-c041a12af62b';
  t_env    uuid := '1935979c-b290-42e4-baa5-8cb0138b4ffa';
  t_growth uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  t_house  uuid := '669cac97-66a6-4087-b036-936fbe62efb3';
  t_zoning uuid := 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
  t_trans  uuid := 'ba59337e-30e2-4aba-a39a-426b3366eb27';
  berdo    text := 'https://www.newtonbeacon.org/zoning-and-planning-approves-berdo-with-amended-residential-requirements/';
  figcity  text := 'https://figcitynews.com/2023/12/city-council-approves-a-compromise-zoning-plan/';
BEGIN
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;

  -- ---- guards: the exact pre-state 1548 left ----
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id IN (p_baker, p_laredo);
  IF v_n <> 7 THEN RAISE EXCEPTION '1607: expected 7 published Newton rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_baker AND topic_id = t_env AND value = 1;
  IF v_n <> 1 THEN RAISE EXCEPTION '1607: Baker/Environmental is not at chair 1'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_laredo AND topic_id = t_house AND value = 1;
  IF v_n <> 1 THEN RAISE EXCEPTION '1607: Laredo/Housing is not at chair 1'; END IF;

  -- Every Baker row must still be sole-sourced to the Suffolk profile that carries nothing.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = p_baker AND cardinality(sources) = 1
     AND sources[1] LIKE '%law.suffolk.edu%';
  IF v_n <> 4 THEN RAISE EXCEPTION '1607: expected 4 Baker rows sole-sourced to the Suffolk profile, found %', v_n; END IF;

  -- ---- Baker: retire 3 ----
  DELETE FROM inform.politician_answers
   WHERE politician_id = p_baker AND topic_id IN (t_growth, t_house, t_zoning);
  DELETE FROM inform.politician_context
   WHERE politician_id = p_baker AND topic_id IN (t_growth, t_house, t_zoning);

  -- ---- Baker: re-chair and re-source the one that survives ----
  UPDATE inform.politician_answers SET value = 3
   WHERE politician_id = p_baker AND topic_id = t_env;

  UPDATE inform.politician_context SET
    reasoning = $txt$As chair of the Zoning and Planning Committee, Baker offered the motion that advanced Newton's Building Emissions Reduction and Disclosure Ordinance (BERDO) to the full City Council on 27 November 2024, and voted to approve it. The version he moved requires large non-residential buildings to meet full BERDO standards while requiring large residential buildings to report energy consumption only, without an emissions-reduction mandate, and declines a total exemption for Newton-Wellesley Hospital while leaving it the city's established exemption process. Applying the standard consistently while allowing covered buildings flexibility on implementation matches stance 3.$txt$,
    sources = ARRAY[berdo]
   WHERE politician_id = p_baker AND topic_id = t_env;

  -- ---- Laredo: retire Transportation ----
  DELETE FROM inform.politician_answers
   WHERE politician_id = p_laredo AND topic_id = t_trans;
  DELETE FROM inform.politician_context
   WHERE politician_id = p_laredo AND topic_id = t_trans;

  -- ---- Laredo: correct Housing ----
  UPDATE inform.politician_answers SET value = 3
   WHERE politician_id = p_laredo AND topic_id = t_house;

  UPDATE inform.politician_context SET
    reasoning = $txt$Laredo supported an MBTA-only zoning plan — compliance with the state's MBTA Communities Act rather than the broader Village Center Overlay District upzoning — and seconded the motion to accept the amendments that produced the final plan. The plan the City Council adopted on 4 December 2023 was scaled back from the original proposal: village-centre maximums were reduced from five and six storeys to four, VC3 areas were converted to VC2, and the affordable-housing bonus was narrowed. It provides for roughly 8,745 housing units against a state-mandated minimum of 8,330. Easing permitting for multi-family housing near transit while retaining an affordable-housing bonus matches stance 3; he did not propose publicly built housing, rent caps, or broad deregulation.$txt$,
    sources = ARRAY[figcity]
   WHERE politician_id = p_laredo AND topic_id = t_house;

  -- ---- Laredo: re-ground Growth, chair 2 unchanged ----
  UPDATE inform.politician_context SET
    reasoning = $txt$Laredo supported an MBTA-only zoning plan rather than the broader Village Center Overlay District proposal, and seconded the motion to accept the amendments that produced the final plan adopted on 4 December 2023. That plan concentrated added housing capacity in transit-served village centres and reduced permitted heights from five and six storeys to four. Confining growth to the areas existing transit infrastructure already supports, rather than streamlining permitting citywide to recruit development, matches stance 2.$txt$,
    sources = ARRAY[figcity]
   WHERE politician_id = p_laredo AND topic_id = t_growth;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id IN (p_baker, p_laredo);
  IF v_n <> 3 THEN RAISE EXCEPTION '1607: expected 3 Newton answers after, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = p_baker;
  IF v_n <> 1 THEN RAISE EXCEPTION '1607: Baker should keep 1 answer, has %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = p_laredo;
  IF v_n <> 2 THEN RAISE EXCEPTION '1607: Laredo should keep 2 answers, has %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_baker AND topic_id = t_env AND value = 3;
  IF v_n <> 1 THEN RAISE EXCEPTION '1607: Baker/Environmental did not move to chair 3'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_laredo AND topic_id = t_house AND value = 3;
  IF v_n <> 1 THEN RAISE EXCEPTION '1607: Laredo/Housing did not move to chair 3'; END IF;

  -- The two citations verified not to carry their claims must be gone from these politicians.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE pc.politician_id IN (p_baker, p_laredo)
     AND (s LIKE '%law.suffolk.edu%' OR s LIKE '%newtonma.gov%');
  IF v_n <> 0 THEN RAISE EXCEPTION '1607: % superseded Newton citations survived', v_n; END IF;

  -- Retiring removes BOTH halves, so no orphan may be created.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.politician_id IN (p_baker, p_laredo)
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id = pc.politician_id AND a.topic_id = pc.topic_id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1607: % orphan context rows created', v_n; END IF;

  -- 4 rows removed from each table, and nothing emptied.
  SELECT count(*) INTO v_ctx_after FROM inform.politician_context;
  SELECT count(*) INTO v_ans_after FROM inform.politician_answers;
  IF v_ctx_before - v_ctx_after <> 4 THEN
    RAISE EXCEPTION '1607: context fell by %, expected 4', v_ctx_before - v_ctx_after; END IF;
  IF v_ans_before - v_ans_after <> 4 THEN
    RAISE EXCEPTION '1607: answers fell by %, expected 4', v_ans_before - v_ans_after; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_n <> 404 THEN RAISE EXCEPTION '1607: empty-sources rows moved to %, expected 404', v_n; END IF;

  RAISE NOTICE '1607: Newton 7 -> 3 published rows (3 Baker + 1 Laredo retired, 2 chairs corrected); context % -> %',
    v_ctx_before, v_ctx_after;
END $$;

COMMIT;
