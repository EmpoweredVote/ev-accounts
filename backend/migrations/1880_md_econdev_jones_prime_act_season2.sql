-- 1880_md_econdev_jones_prime_act_season2.sql
-- Adrienne A. Jones / Economic Development Incentives: re-source the row onto an instrument that is
-- actually on this ladder and write it forward into Season 2. Chair UNCHANGED at 1. 2 rows INSERTED.
-- Season 1 untouched.
--
-- 🔑 THE CHAIR WAS RIGHT FOR REASONS THE ROW NEVER CITED. This is the last of the Blueprint family
-- (childcare 1875/1877, vouchers = ladder-scope, taxation 1878/1879) and the only one where the stored
-- number survives contact with real evidence. What had to change is everything under it.
--
-- WHAT WAS WRONG. The Season 1 reasoning reads: *"Jones championed Blueprint for Maryland's Future as
-- economic development through public education investment — supports government-led economic
-- development with strong labor standards."*
--   * 🔴 **THE CITED INSTRUMENT IS AN EDUCATION BILL.** The stored source is `hb1413?ys=2019RS`,
--     titled — literally — **"The Blueprint for Maryland's Future"**. Calling education funding
--     "economic development" is the reasoning doing work the instrument does not do.
--   * 🔴 **THE REASONING DESCRIBES A DIFFERENT CHAIR THAN THE ONE IT SITS ON.** *"Government-led
--     economic development with strong labor standards"* is **chair 3** ("incentives … only if they
--     commit to good wages and local hiring"). The row is seated at **chair 1**, which is the refusal
--     to offer incentives at all. A row whose prose argues one rung and whose number asserts another
--     is the [[project_chair_reasoning_inversion]] shape in miniature.
--   * ⚠ Sources also carried Ballotpedia and a **session-less** member page.
--
-- 🔑🔑 THE INSTRUMENT THAT IS ACTUALLY ON THIS LADDER — AND NOBODY HAD CITED IT.
-- **SB0877 (2018), the PRIME Act, Chapter 350**: establishes a programme in the Department of Commerce
-- providing **certain FORTUNE 100 companies tax credits and benefits for up to 10 years** (the package
-- built for the Amazon HQ2 bid). **Jones voted NAY** on House third reading, which passed **78-60**.
-- A divided vote on a textbook corporate incentive, so opposing it is a position and not a formality.
-- ⚠ In 2018 she was a **Delegate, not Speaker** — the presiding officer on that sheet is **Speaker
-- Busch** — so she appears by surname, unlike the 2020 sheets where she is "Speaker".
-- 🔑 IDENTITY: the sheet contains **exactly ONE word-bounded "Jones"**. Dana Jones (`jones01`) was not
-- yet in the House, so the two-Joneses trap that applies to 2020 sheets does not bite here — but it
-- was checked rather than assumed.
-- 🔴 And the Nay block was read by **column structure**, not line range: on these sheets Yea and Nay
-- render side by side and a line-range read silently inverts votes (see migration 1878/1879).
--
-- ⚖ WHY CHAIR 1 STANDS, AND THE HONEST LIMITS. Revision 2's rungs:
--   1: "Don't give companies tax breaks or subsidies. Invest in public services and infrastructure so
--       businesses want to come on their own."
--   2: "Help small and local businesses grow, but don't offer subsidies to attract large outside
--       companies."
--   3: incentives conditioned on wages and local hiring · 4: large breaks with limits · 5: maximum
-- The NAY on a Fortune 100 credit programme excludes **4 and 5** outright and evidences chair 1's
-- first half directly. Between **1 and 2**, both share the anti-subsidy half; chair 2's distinguishing
-- half is a **small and local business** programme, and she has **none** — across 2019-2025 her only
-- bill filed under Economic Development funds the **Baltimore Symphony Orchestra**. Chair 1's
-- distinguishing half is investment in public services, which her Blueprint leadership does match.
-- ⚠ THREE LIMITS, written into the row:
--   * **One recorded vote against one programme is not a general rule against every incentive.**
--   * **Her vote on the More Jobs for Marylanders Act of 2017 (Ch. 149) CANNOT BE CHECKED** — mgaleg's
--     roll-call sheets do not reach that session (the bill page links none and the 2017 vote path
--     404s). An absolute-sounding chair rests on a record that is only verifiable from 2018 onward.
--   * She **did not present the Blueprint as a business-attraction strategy**; that half of chair 1 is
--     matched by her record, not by her stated rationale.
--
-- 🔴 The revision differs between seasons (S1 revision 1 `6291d7ff-…`, S2 revision 2 `af855dba-…`).
-- Revision 2 is a plain-language rewrite whose rungs map closely onto revision 1's, but the pin is
-- asserted rather than assumed, and the adjudication above is written against **revision 2**.
--
-- editor_id is NULL -- the established value for automated writes in this season.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

DO $$
DECLARE s1_chair numeric; s1_rev uuid; s2_rev uuid; s2_rows int;
BEGIN
  SELECT pa.value, pa.topic_revision_id INTO s1_chair, s1_rev
    FROM inform.politician_answers pa
   WHERE pa.politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND pa.topic_id      = 'eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND pa.season_id     = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
  IF s1_chair IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1880: expected Season 1 chair 1 for Jones, found % -- state has moved', s1_chair;
  END IF;
  IF s1_rev IS DISTINCT FROM '6291d7ff-cb36-48c6-8c9e-e94ccafd43ae'::uuid THEN
    RAISE EXCEPTION 'migration 1880: Season 1 no longer pins revision 6291d7ff, found %', s1_rev;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM inform.politician_context pc
     WHERE pc.politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
       AND pc.topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
       AND pc.season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
       AND pc.reasoning ILIKE '%Blueprint%'
  ) THEN
    RAISE EXCEPTION 'migration 1880: the Season 1 row no longer rests on the Blueprint -- has it already been corrected?';
  END IF;

  SELECT count(*) INTO s2_rows FROM inform.politician_context
   WHERE politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF s2_rows <> 0 THEN
    RAISE EXCEPTION 'migration 1880: Season 2 already holds % row(s) for this politician/topic', s2_rows;
  END IF;

  SELECT sq.topic_revision_id INTO s2_rev FROM inform.season_questions sq
    JOIN inform.compass_topic_revisions tr ON tr.id=sq.topic_revision_id
   WHERE sq.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND tr.topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53';
  IF s2_rev IS DISTINCT FROM 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid THEN
    RAISE EXCEPTION 'migration 1880: Season 2 pins % for this topic, not revision 2 (af855dba)', s2_rev;
  END IF;
  IF s2_rev = s1_rev THEN
    RAISE EXCEPTION 'migration 1880: the seasons now pin the SAME revision -- this migration assumes they differ';
  END IF;

  -- the two rungs the adjudication turns on must still read as argued
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions
     WHERE topic_revision_id='af855dba-96f3-4fa0-beb7-43c5edb3f499'
       AND value=1 AND text ILIKE '%tax breaks or subsidies%'
  ) THEN
    RAISE EXCEPTION 'migration 1880: revision 2 chair 1 no longer refuses tax breaks or subsidies -- that is what the PRIME Act vote evidences';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM inform.compass_stance_revisions
     WHERE topic_revision_id='af855dba-96f3-4fa0-beb7-43c5edb3f499'
       AND value=2 AND text ILIKE '%small and local businesses%'
  ) THEN
    RAISE EXCEPTION 'migration 1880: revision 2 chair 2 no longer turns on small and local business -- that absence is what excludes it';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
VALUES (
  '760cd4a7-235c-472f-a0ba-fb07098dfd57',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'af855dba-96f3-4fa0-beb7-43c5edb3f499',
  NULL,
  'As a Delegate, Jones voted against the PRIME Act (2018 SB0877), which set up a programme in the Department of Commerce offering certain Fortune 100 companies state tax credits and benefits for up to ten years. The House passed it 78 to 60 and it became Chapter 350, so a vote against it was a position rather than a formality. Declining to hand tax breaks and subsidies to large companies is what stance 1 describes, and it rules out stances 4 and 5, which compete for major employers with exactly that kind of package. Stance 2 is the near alternative, but its distinguishing feature is a programme for small and local businesses, and she has none: across the 2019 to 2025 sessions her only bill filed under Economic Development funds the Baltimore Symphony Orchestra. Three limits belong on this. One recorded vote against one programme is not a general rule against every incentive. Her vote on the More Jobs for Marylanders Act of 2017 cannot be checked, because the legislature does not publish roll call sheets reaching back to that session, so her record here is only verifiable from 2018 onward. And while stance 1 also calls for investing in public services so that business follows, and she led the Blueprint for Maryland''s Future, she did not present that investment as a business attraction strategy.',
  ARRAY[
    'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0877?ys=2018RS',
    'https://mgaleg.maryland.gov/2018RS/votes/house/1053.pdf',
    'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones?ys=2019RS'
  ]
);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
VALUES (
  '760cd4a7-235c-472f-a0ba-fb07098dfd57',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  '86d893a1-c1a2-4bbf-b4e5-69ec43221194',
  'af855dba-96f3-4fa0-beb7-43c5edb3f499',
  NULL,
  1
);

DO $$
DECLARE ctx int; ans numeric; ans_rev uuid; bad int; s1 numeric;
BEGIN
  SELECT count(*) INTO ctx FROM inform.politician_context
   WHERE politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ctx <> 1 THEN
    RAISE EXCEPTION 'migration 1880: expected exactly 1 Season 2 context row, found %', ctx;
  END IF;

  SELECT value, topic_revision_id INTO ans, ans_rev FROM inform.politician_answers
   WHERE politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF ans IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1880: expected Season 2 chair 1, found %', ans;
  END IF;
  IF ans_rev IS DISTINCT FROM 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid THEN
    RAISE EXCEPTION 'migration 1880: the new answer is pinned to %, not revision 2', ans_rev;
  END IF;

  -- the corrected row must rest on the PRIME Act, cite its roll call, and drop the education bill,
  -- Ballotpedia and the session-less member page
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning NOT ILIKE '%PRIME Act%'
          OR NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s LIKE '%/2018RS/votes/house/1053.pdf%')
          OR EXISTS (SELECT 1 FROM unnest(sources) s
                      WHERE s ILIKE '%ballotpedia%' OR s ILIKE '%hb1413%' OR s = 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones'));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'migration 1880: the corrected row fails the sourcing contract';
  END IF;

  -- history intact
  SELECT value INTO s1 FROM inform.politician_answers
   WHERE politician_id='760cd4a7-235c-472f-a0ba-fb07098dfd57'
     AND topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53'
     AND season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_revision_id='6291d7ff-cb36-48c6-8c9e-e94ccafd43ae';
  IF s1 IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'migration 1880: the Season 1 answer or its revision pin moved -- history must survive verbatim';
  END IF;
END $$;

COMMIT;
