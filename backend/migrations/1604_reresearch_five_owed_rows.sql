-- 1604_reresearch_five_owed_rows.sql
--
-- Closes the 5 rows left owed by migrations 1600-1603: 4 re-sourced and rewritten from evidence
-- fetched on 2026-08-07, 1 retired as verified absent. One chair is corrected.
--   Research record:  data/stance-research/2026-08-07-five-row-reresearch.md
--   Rollback record:  data/stance-retirement/2026-08-07-five-row-reresearch-rollback.json
--
-- 🔴 RE-RESEARCH DID NOT RETURN TO THE ORIGINAL SOURCES (1508's rule). Every citation written here
-- was fetched today. The rows arrived here because their citations were dead (Lungo-Koehn, Mejia) or
-- sole-sourced to an aggregator after 1603 removed a duplicate (Barr, Allen).
--
-- ⚠ `barr.house.gov` 403s to a plain fetcher and returns 200 to curl with a browser UA -- the
-- Ballotpedia UA-block pattern, now observed on a .gov. A 403 there is never absence.
--
-- ---------------------------------------------------------------------------------------------
-- 1. LUNGO-KOEHN / CLIMATE CHANGE -- CHAIR 1 -> 2. The only chair change here.
--
-- Chair 1 is "declare a climate emergency and ban all activities that increase carbon emissions".
-- Medford declared no emergency and banned nothing, so chair 1 asserted something that did not
-- happen. What the record does support: the Climate Action & Adaptation Plan (April 2022, released
-- by her office) committing Medford to net zero by 2050; Race to Zero (2021), pledging to "cut our
-- greenhouse gases in half by 2030 and to be carbon neutral by 2050"; and Metro Mayors Coalition
-- signatures in 2015 and 2016. That is chair 2 -- a binding, planned transition. Chair 3's
-- "gradually reducing" would understate a Race to Zero signatory.
--
-- 🔴 THE OLD REASONING OVERSTATED THE 2030 TARGET. It claimed "100% renewable electricity for city
-- operations by 2030"; Medford's actual 2030 commitment is a 50% cut. It also named a "City Climate
-- Change Commitment" document that does not exist. Neither survives into the rewrite.
-- ⚠ Its Metro Mayors clause was TRUE -- only the host cited for it (metromayor.org) died. A dead
-- citation is not proof the claim was wrong, which is why this row was re-sourced and not retired.
-- ⚠ NOT cited: medfordma.org/departments/planning-development-sustainability. It links the plan
-- without stating a single target -- a landing page is not coverage (the Newton/Portland ruling).
--
-- 2. BARR / FOSSIL FUELS -- chair 4 unchanged, reasoning replaced.
-- 🔴 THE OLD REASONING'S SPECIFICS WERE ONTHEISSUES ARTIFACTS AND ARE NOT ON HIS OWN SITE: the 2016
-- offshore-drilling votes, the wind energy tax credit, "war on coal" and "exploring proven energy
-- reserves". The terms drill / offshore / wind / tax credit all score ZERO on barr.house.gov/energy.
-- Carrying them onto a citation that does not contain them is exactly the composed-citation defect.
-- Chair 4 not 5: he wants permits expanded and expedited, and names SPECIFIC rules to repeal (WOTUS,
-- EPA anti-coal) rather than removing environmental restrictions wholesale. Do not upgrade on tone.
--
-- 3. ALLEN / VOTING RIGHTS -- chair 4 unchanged, reasoning replaced.
-- ⚠ "voter rolls" does NOT appear on the cited release, so the rewrite does not claim roll
-- maintenance -- even though chair 4's own label mentions it. Cite what the page says, not what the
-- chair says. The old "opposes same-day voter registration, per documented voter guide responses"
-- is an ontheissues artifact and is dropped. Chair 4 not 5: no evidence he would end mail voting.
--
-- 4. MEJIA / CLIMATE CHANGE -- chair 2 unchanged, reasoning replaced.
-- 🔴 THE OLD REASONING DESCRIBED HIS JOB, NOT A POSITION -- auditing sustainability spending and
-- publishing transparency reports is compatible with ANY chair, so the row was scored 2 on evidence
-- that could not distinguish 2 from 4. Real evidence exists and is now cited: he wants Los Angeles
-- at 100% clean, renewable energy by 2030. Right chair, wrong basis -- worth separating, because a
-- correct chair resting on non-evidence is still a fabrication risk.
--
-- 5. MEJIA / ABORTION -- RETIRED, verified absent.
-- This meets the strict bar that the lapsed-domain rows in 1601 did not. The reasoning was openly
-- attribute-prior ("As a Democratic Socialist and former congressional candidate, he consistently
-- supports...") -- the class 1521 retired. The LA City Controller is a fiscal-oversight office with
-- NO abortion jurisdiction, so no official record can exist. The most detailed profile of him does
-- not mention abortion at all, and a targeted search found no statement by him; the only Dobbs
-- connection in the record is post-Dobbs youth turnout aiding his 2022 campaign, a fact about the
-- ELECTORATE, not about him. Searched, not found, on an office with no role in the topic.
-- ⚠ Mejia keeps 12 answers, so nobody is emptied and no timestamp may be cleared (the 1494 rule).

BEGIN;

DO $$
DECLARE
  v_n           int;
  v_rows_before bigint;
  v_ans_before  bigint;
  v_rows_after  bigint;
  v_ans_after   bigint;
  p_lk    uuid := 'a4320764-6ba2-4563-9a58-abb1333c2f40';
  t_clim  uuid := 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  p_barr  uuid := '164fb70e-b8c1-48cd-a6ef-12d80165c67d';
  t_foss  uuid := 'a22215c3-6693-4bc2-b248-01aebba14570';
  p_allen uuid := '3de9e882-a816-42fc-ae70-aa93098c5d02';
  t_vote  uuid := 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  p_mejia uuid := '590fd6ec-3194-43af-97fc-25490490c565';
  t_abort uuid := 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';
BEGIN
  SELECT count(*) INTO v_rows_before FROM inform.politician_context;
  SELECT count(*) INTO v_ans_before  FROM inform.politician_answers;

  -- ---- pre-state: each row must exist at the chair the research was done against ----
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_lk AND topic_id = t_clim AND value = 1;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Lungo-Koehn/Climate is not at chair 1'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_barr AND topic_id = t_foss AND value = 4;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Barr/Fossil Fuels is not at chair 4'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_allen AND topic_id = t_vote AND value = 4;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Allen/Voting Rights is not at chair 4'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_mejia AND topic_id = t_clim AND value = 2;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Mejia/Climate is not at chair 2'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_mejia AND topic_id = t_abort;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Mejia/Abortion answer not found'; END IF;

  -- Barr and Allen must still be sole-sourced to ontheissues, or 1603 is not the state assumed.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE ((politician_id = p_barr  AND topic_id = t_foss)
       OR (politician_id = p_allen AND topic_id = t_vote))
     AND cardinality(sources) = 1
     AND sources[1] LIKE '%ontheissues.org%';
  IF v_n <> 2 THEN RAISE EXCEPTION '1604: Barr/Allen are not sole-sourced to ontheissues as expected'; END IF;

  -- ---- 1. Lungo-Koehn: the chair correction ----
  UPDATE inform.politician_answers SET value = 2
   WHERE politician_id = p_lk AND topic_id = t_clim;

  UPDATE inform.politician_context SET
    reasoning = $txt$Lungo-Koehn released Medford's Climate Action & Adaptation Plan in April 2022, committing the city to net-zero emissions by 2050, and described it as "our guide to creating a green, sustainable future for Medford that protects both our environment and community." Medford joined the Race to Zero campaign in 2021, pledging to "cut our greenhouse gases in half by 2030 and to be carbon neutral by 2050," and is a Metro Mayors Coalition signatory to a 2016 agreement for a net-zero region by 2050. The plan sets 32 strategies across buildings and energy, ecosystems, public health and transportation. This is a binding, scheduled transition rather than a declared emergency: the city has declared no climate emergency and banned no activities, which is why this is stance 2 rather than stance 1.$txt$,
    sources = ARRAY[
      'https://www.medfordma.org/fs/resource-manager/view/7b0737c1-07be-400f-bdfe-b8aab63ef400',
      'https://patch.com/massachusetts/medford/medford-releases-finalized-climate-action-adaptation-plan']
   WHERE politician_id = p_lk AND topic_id = t_clim;

  -- ---- 2. Barr ----
  UPDATE inform.politician_context SET
    reasoning = $txt$Barr's official energy page states that it is "imperative that our country work towards energy dominance and strong economic growth and security by rolling back onerous regulations and allowing for the innovation and development of fossil fuel technology," and lists "adamantly and actively opposing the Green New Deal and the elimination of carbon-based fuels from our energy grid." He voted for H.R. 1, the Lower Energy Costs Act, which would "fast-track the approval process for American energy production on federal lands and waters" and speed permitting for such projects, and he cosponsored legislation to nullify the Waters of the United States rule. Expanding and expediting drilling and production permits, while targeting specific regulations rather than environmental restrictions as a whole, matches stance 4.$txt$,
    sources = ARRAY['https://barr.house.gov/energy']
   WHERE politician_id = p_barr AND topic_id = t_foss;

  -- ---- 3. Allen ----
  UPDATE inform.politician_context SET
    reasoning = $txt$Allen supported the SAVE America Act, which his office describes as adding "a voter ID requirement for voting in federal elections while maintaining the original bill's proof-of-citizenship requirement for voter registration," on its House passage of 11 February 2026. He has said that "the American people are overwhelmingly supportive of requiring a photo ID to vote in federal elections." Requiring photo identification to vote and documentary proof of citizenship to register, without proposing to eliminate mail-in voting, matches stance 4.$txt$,
    sources = ARRAY['https://allen.house.gov/news/documentsingle.aspx?DocumentID=7098']
   WHERE politician_id = p_allen AND topic_id = t_vote;

  -- ---- 4. Mejia / Climate ----
  UPDATE inform.politician_context SET
    reasoning = $txt$Mejia has said Los Angeles should reach 100% clean, renewable energy by 2030, arguing "we've seen the science. We've seen that we need to get to zero emissions," and that 100% clean energy "is only unrealistic if policymakers succumb to big oil or gas." He also said he would use the Controller's office to audit the city's Green New Deal to check whether its targets are being met on schedule. A 2030 target for fully renewable electricity matches stance 2.$txt$,
    sources = ARRAY['https://knock-la.com/kenneth-mejia-progressive-city-controller-candidate/']
   WHERE politician_id = p_mejia AND topic_id = t_clim;

  -- ---- 5. Mejia / Abortion: retire, both halves ----
  DELETE FROM inform.politician_answers WHERE politician_id = p_mejia AND topic_id = t_abort;
  DELETE FROM inform.politician_context WHERE politician_id = p_mejia AND topic_id = t_abort;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE politician_id = p_lk AND topic_id = t_clim AND value = 2;
  IF v_n <> 1 THEN RAISE EXCEPTION '1604: Lungo-Koehn chair did not move to 2'; END IF;

  -- The retired pair must be gone from BOTH tables.
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = p_mejia AND topic_id = t_abort;
  IF v_n <> 0 THEN RAISE EXCEPTION '1604: Mejia/Abortion answer survived'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE politician_id = p_mejia AND topic_id = t_abort;
  IF v_n <> 0 THEN RAISE EXCEPTION '1604: Mejia/Abortion context survived'; END IF;

  -- Exactly one row left each table.
  SELECT count(*) INTO v_rows_after FROM inform.politician_context;
  SELECT count(*) INTO v_ans_after  FROM inform.politician_answers;
  IF v_rows_before - v_rows_after <> 1 THEN
    RAISE EXCEPTION '1604: context rows fell by %, expected 1', v_rows_before - v_rows_after; END IF;
  IF v_ans_before - v_ans_after <> 1 THEN
    RAISE EXCEPTION '1604: answer rows fell by %, expected 1', v_ans_before - v_ans_after; END IF;

  -- No dead or aggregator-only citation may survive on the four rewritten rows.
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE ((pc.politician_id = p_lk    AND pc.topic_id = t_clim)
       OR (pc.politician_id = p_barr  AND pc.topic_id = t_foss)
       OR (pc.politician_id = p_allen AND pc.topic_id = t_vote)
       OR (pc.politician_id = p_mejia AND pc.topic_id = t_clim))
     -- ⚠ The dead Medford path is matched on its HOST+PATH, not on the bare substring
     -- "climate-action": the replacement Patch URL also contains that substring, so the first
     -- draft of this guard flagged the NEW citation as a superseded one and failed the dry run.
     -- A pattern that matches the fix as well as the defect is not a check.
     AND (s LIKE '%ontheissues.org%' OR s LIKE '%metromayor.org%' OR s LIKE '%kennethforla%'
       OR s LIKE '%lacontroller.org%' OR s LIKE '%medfordma.org/departments/sustainability%');
  IF v_n <> 0 THEN RAISE EXCEPTION '1604: % superseded citations survived', v_n; END IF;

  -- Every rewritten row must carry a real citation, and none may be emptied.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE ((politician_id = p_lk    AND topic_id = t_clim)
       OR (politician_id = p_barr  AND topic_id = t_foss)
       OR (politician_id = p_allen AND topic_id = t_vote)
       OR (politician_id = p_mejia AND topic_id = t_clim))
     AND (cardinality(sources) = 0 OR btrim(reasoning) = '');
  IF v_n <> 0 THEN RAISE EXCEPTION '1604: % rewritten rows have no source or no reasoning', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_n <> 404 THEN RAISE EXCEPTION '1604: empty-sources rows moved to %, expected 404', v_n; END IF;

  -- Mejia keeps his other answers, so his timestamp must NOT be cleared (the 1494 rule).
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = p_mejia;
  IF v_n <> 12 THEN RAISE EXCEPTION '1604: Mejia should hold 12 answers after the retirement, holds %', v_n; END IF;

  RAISE NOTICE '1604: 4 rows re-sourced (1 chair corrected), 1 retired; context % -> %, answers % -> %',
    v_rows_before, v_rows_after, v_ans_before, v_ans_after;
END $$;

COMMIT;
