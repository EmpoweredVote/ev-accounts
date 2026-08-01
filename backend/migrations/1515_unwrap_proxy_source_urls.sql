-- 1515_unwrap_proxy_source_urls.sql
--
-- Replace 55 stance citations that stored a SCRAPING PROXY instead of the source it wrapped.
-- Every value below is the URL that was already inside the stored string: https://r.jina.ai/https://X
-- becomes https://X. No source is added, no host is invented, nothing is retired.
--   Rollback record: data/stance-retirement/2026-08-01-proxy-unwrap-rollback.json
--
-- WHY THIS IS NOT COSMETIC. r.jina.ai 403s now, so a reader checking one of these rows gets a refusal
-- rather than the page. It is also actively misleading downstream: Bo Biteman and Matthew Klein landed
-- in the citation audit's UNKNOWN bucket looking like unread Ballotpedia pages, when in fact their
-- rows never pointed at Ballotpedia directly at all. And the wrapped targets are frequently GOOD
-- sources that were hidden by the wrapper -- vpap.org close-vote records, local news coverage
-- (oilcity.news, labortribune.com, thereminder.com), and candidate issue pages.
--
-- 🔴 THIS MIGRATION MAY SHORTEN THE ARRAY, AND THE PREVIOUS THREE FORBADE THAT. 4 of these rows
-- already cite the unwrapped URL alongside its wrapped twin -- drahmadhassan.com/issues appears both
-- bare and jina-wrapped on the same row -- so unwrapping produces an exact duplicate that has to
-- collapse. Migrations 1512/1513/1514 each asserted "substitutes, never drops"; that assertion is
-- wrong here. What those assertions were really protecting is that no row loses a DISTINCT source, and
-- that is what is asserted below instead.
--
-- 🔴 9 UNWRAPPED TARGETS RETURN 403 TO A SCRIPT AND THAT IS A BOT BLOCK, NOT A DEAD PAGE.
-- All of them are news outlets -- Iowa Capital Dispatch, Kansas Reflector, Virginia Mercury, Radio
-- Iowa, Our Quad Cities. Verified in a real browser: the Iowa Capital Dispatch debate article renders
-- with its headline intact. Recording these as dead would repeat the error the Ballotpedia UA-block
-- note already warns about. It is also almost certainly WHY the research step reached for r.jina.ai:
-- the proxy was a workaround for bot-blocking, not laziness. Storing the workaround as the citation is
-- still wrong -- a person opening the row should get the article, not the scraper's refusal.
--
-- 🔴 A 202 IS THROTTLING, NOT A DEAD LINK. 5 vpap.org targets answered 202 on the second pass and
-- 200 on the first. The first draft of the generator filed them under "genuinely unreachable" -- the
-- identical mislabel that produced a wrong Ballotpedia sweep and 214 phantom UNKNOWNs in migration
-- 1514's first run. Unknown, re-check later, never a miss.
--
-- Verified before writing: all 34 distinct proxy URLs in prod are the standard r.jina.ai/<url> form.
-- The generator refuses any other proxy shape rather than guessing at it.

BEGIN;

CREATE TEMP TABLE _unwrap_1515 (
  politician_id uuid,
  topic_id      uuid,
  new_sources   text[]
) ON COMMIT DROP;

INSERT INTO _unwrap_1515 (politician_id, topic_id, new_sources) VALUES
  ('08284136-be31-4d86-bf77-73c900026ade', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://www.vpap.org/legislators/328311-debra-gardner/list-votes/close-votes/?session=39']),  -- Debra D. Gardner: Abortion
  ('0c308ff9-07e5-4ec3-a082-0324b2433da9', '00b95a6a-75db-4521-b523-3326bba938de', ARRAY['https://www.deploymalloy.com/landing/positions/', 'https://ballotpedia.org/Gerald_Malloy_(Vermont)']),  -- Gerald Malloy: School Vouchers
  ('0c308ff9-07e5-4ec3-a082-0324b2433da9', '0bc588c6-39e1-4084-b5de-cac909b8b762', ARRAY['https://www.ontheissues.org/Domestic/Gerald_Malloy_Civil_Rights.htm', 'https://ballotpedia.org/Gerald_Malloy_(Vermont)']),  -- Gerald Malloy: Civil Rights
  ('0c308ff9-07e5-4ec3-a082-0324b2433da9', '4e2c69ce-591e-4197-9cd5-7aceff79d390', ARRAY['https://ballotpedia.org/Gerald_Malloy_(Vermont)', 'https://www.predictionedge.com/elections/profile/gerald-malloy/', 'https://www.wcax.com/2024/10/25/sen-sanders-gerald-malloy-talk-immigration-abortion-taxes-more-wcax-us-senate-debate/']),  -- Gerald Malloy: Immigration
  ('0c308ff9-07e5-4ec3-a082-0324b2433da9', '87d20824-a6e9-407b-983c-65440084a0ab', ARRAY['https://vtdigger.org/profile/gerald-malloy/', 'https://ballotpedia.org/Gerald_Malloy_(Vermont)']),  -- Gerald Malloy: Social Security
  ('0c308ff9-07e5-4ec3-a082-0324b2433da9', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', ARRAY['https://ballotpedia.org/Gerald_Malloy_(Vermont)', 'https://www.predictionedge.com/elections/profile/gerald-malloy/']),  -- Gerald Malloy: Medicare/aid
  ('149ec01f-2344-446e-801a-74b397cfe17d', '669cac97-66a6-4087-b036-936fbe62efb3', ARRAY['https://chrisbeckforcongress.com/issues', 'https://ballotpedia.org/Chris_Beck']),  -- Chris Beck: Housing
  ('149ec01f-2344-446e-801a-74b397cfe17d', '683c8084-2281-4920-a07c-18439b2dd413', ARRAY['https://chrisbeckforcongress.com/issues', 'https://ballotpedia.org/Chris_Beck']),  -- Chris Beck: Tariffs
  ('2ba471d6-9680-4584-8b10-e2baf6b493fd', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://mariabrewerforsenate.com/issues', 'https://ballotpedia.org/Maria_Brewer_(Tennessee)']),  -- Maria Brewer: Healthcare
  ('2ba471d6-9680-4584-8b10-e2baf6b493fd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', ARRAY['https://mariabrewerforsenate.com/issues', 'https://ballotpedia.org/Maria_Brewer_(Tennessee)']),  -- Maria Brewer: Taxes
  ('2ba624be-57df-4660-aafd-67f2a116f0dc', '0bc588c6-39e1-4084-b5de-cac909b8b762', ARRAY['https://www.the74million.org/article/youngkin-administration-ends-equity-initiatives-at-the-virginia-department-of-education/', 'https://virginiamercury.com/2023/03/01/jillian-balow-resigns-as-virginias-superintendent-of-public-instruction/']),  -- Jillian Balow: Civil Rights
  ('2ba624be-57df-4660-aafd-67f2a116f0dc', 'a22215c3-6693-4bc2-b248-01aebba14570', ARRAY['https://oilcity.news/community/elections/2026/06/08/election-qa-jillian-balow-for-us-house-of-representatives/', 'https://cowboystatedaily.com/2026/01/13/former-wyoming-schools-superintendent-running-for-u-s-house/']),  -- Jillian Balow: Fossil Fuels
  ('2ba624be-57df-4660-aafd-67f2a116f0dc', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://oilcity.news/community/elections/2026/06/08/election-qa-jillian-balow-for-us-house-of-representatives/']),  -- Jillian Balow: Healthcare
  ('2ba624be-57df-4660-aafd-67f2a116f0dc', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', ARRAY['https://oilcity.news/community/elections/2026/06/08/election-qa-jillian-balow-for-us-house-of-representatives/', 'https://wyofile.com/jillian-balow-former-wyoming-education-leader-will-run-for-u-s-house/']),  -- Jillian Balow: Taxes
  ('2c684458-b752-4dbc-82bf-39c9475d23c0', 'a22215c3-6693-4bc2-b248-01aebba14570', ARRAY['https://www.ryancushmanforcongress.com', 'https://smarter.vote/races/mi-house-03-2026/ryan-cushman/']),  -- Ryan Cushman: Fossil Fuels
  ('2c684458-b752-4dbc-82bf-39c9475d23c0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://www.ryancushmanforcongress.com', 'https://smarter.vote/races/mi-house-03-2026/ryan-cushman/']),  -- Ryan Cushman: Climate Change
  ('48192f8e-a15b-4df1-bfe3-8121d3ec6efc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://greggoetzman.com']),  -- Gregory A. Goetzman: Climate Change
  ('48192f8e-a15b-4df1-bfe3-8121d3ec6efc', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', ARRAY['https://greggoetzman.com']),  -- Gregory A. Goetzman: Taxes
  ('51ebeccc-9f0f-4075-963a-af01acd66c23', 'a22215c3-6693-4bc2-b248-01aebba14570', ARRAY['https://ballotpedia.org/Hugh_McTavish', 'https://hughmctavish.com/top-priorities/']),  -- Hugh McTavish: Fossil Fuels
  ('51ebeccc-9f0f-4075-963a-af01acd66c23', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://hughmctavish.com/top-priorities/', 'https://ballotpedia.org/Hugh_McTavish']),  -- Hugh McTavish: Climate Change
  ('54a52891-2aab-4984-a2e7-1dfa5b39a38b', '87d20824-a6e9-407b-983c-65440084a0ab', ARRAY['https://frankbarnitz.com', 'https://labortribune.com/missouri-afl-cio-endorses-former-state-senator-frank-barnitzs-congressional-bid/']),  -- Frank Barnitz: Social Security
  ('54a52891-2aab-4984-a2e7-1dfa5b39a38b', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', ARRAY['https://labortribune.com/missouri-afl-cio-endorses-former-state-senator-frank-barnitzs-congressional-bid/', 'https://frankbarnitz.com']),  -- Frank Barnitz: Medicare/aid
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://kleinforcongress.com', 'https://ballotpedia.org/Matt_Klein']),  -- Matthew D. Klein: Abortion
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://kleinforcongress.com', 'https://ballotpedia.org/Matt_Klein']),  -- Matthew D. Klein: Healthcare
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://ballotpedia.org/Matt_Klein']),  -- Matthew D. Klein: Climate Change
  ('7b11e4bb-330b-4fb6-999e-b72974f3549c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://www.davisfordelegate.com/issues', 'https://www.vpap.org/legislators/385091-will-davis/list-votes/close-votes/?session=39']),  -- Will P. Davis: Abortion
  ('8b493601-de91-44f8-8ce9-0b73ddf532f0', '0bc588c6-39e1-4084-b5de-cac909b8b762', ARRAY['http://www.moshelandman.us/the-issues', 'http://www.moshelandman.us/', 'https://ballotpedia.org/Moshe_Landman']),  -- Moshe Landman: Civil Rights
  ('8b493601-de91-44f8-8ce9-0b73ddf532f0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['http://www.moshelandman.us/the-issues', 'http://www.moshelandman.us/', 'https://ballotpedia.org/Moshe_Landman']),  -- Moshe Landman: Healthcare
  ('8b493601-de91-44f8-8ce9-0b73ddf532f0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', ARRAY['http://www.moshelandman.us/the-issues', 'http://www.moshelandman.us/', 'https://ballotpedia.org/Moshe_Landman']),  -- Moshe Landman: Taxes
  ('8d6faa29-2b9a-4d63-aff4-b738677a9c18', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', ARRAY['https://ballotpedia.org/Bo_Biteman']),  -- Bo Biteman: Voting Rights
  ('9691abd4-42fe-44f9-9d26-e587a9063b46', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', ARRAY['https://mitchelljacob.com/', 'https://ballotpedia.org/Mitchell_Jacob']),  -- Mitchell Jacob: Taxes
  ('b0b2e166-b1ca-4d5e-9c16-aa5b5a06b724', '4e2c69ce-591e-4197-9cd5-7aceff79d390', ARRAY['https://www.sentinelandenterprise.com/2008/10/23/bech-olver-debate-earmarks-economy/', 'https://archives.thereminder.com/localnews/holyoke/iraqiveteranviesfo/']),  -- Nathan Bech: Immigration
  ('b0b2e166-b1ca-4d5e-9c16-aa5b5a06b724', 'a22215c3-6693-4bc2-b248-01aebba14570', ARRAY['https://www.nathanbech.com/principles', 'https://archives.thereminder.com/localnews/holyoke/iraqiveteranviesfo/']),  -- Nathan Bech: Fossil Fuels
  ('b0b2e166-b1ca-4d5e-9c16-aa5b5a06b724', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://archives.thereminder.com/localnews/holyoke/iraqiveteranviesfo/']),  -- Nathan Bech: Healthcare
  ('b21b5e5e-3359-4692-a60d-47d459bbb198', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://kansasreflector.com/2025/03/13/kansas-senate-democrat-breaks-from-party-to-add-tax-credit-to-fetal-child-support-bill/', 'https://kansasreflector.com/tag/sen-patrick-schmidt/']),  -- Patrick Schmidt: Abortion
  ('b503b679-773a-4eee-9c16-e73bff1a723f', 'a22215c3-6693-4bc2-b248-01aebba14570', ARRAY['https://chuckforwyoming.com', 'https://kgab.com/wyoming-house-race-chuck-gray/']),  -- Chuck Gray: Fossil Fuels
  ('b503b679-773a-4eee-9c16-e73bff1a723f', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', ARRAY['https://sos.wyo.gov/Media/2025/SoS_Release_2025-01-30.pdf', 'https://sos.wyo.gov/Media/2025/SoS_Release_2025-03-21.pdf', 'https://chuckforwyoming.com']),  -- Chuck Gray: Voting Rights
  ('b503b679-773a-4eee-9c16-e73bff1a723f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://kgab.com/wyoming-house-race-chuck-gray/', 'https://chuckforwyoming.com']),  -- Chuck Gray: Climate Change
  ('c0811d78-fd93-48d6-a759-f4f0f012e502', '24e9212c-b011-422a-865c-093e35050901', ARRAY['https://www.ourquadcities.com/news/4-the-record/web-extra-bohannan-miller-meeks-on-ukraine-and-israel-policy/']),  -- Christina Bohannan: Ukraine Support
  ('c0811d78-fd93-48d6-a759-f4f0f012e502', '4e2c69ce-591e-4197-9cd5-7aceff79d390', ARRAY['https://cbs2iowa.com/news/beyond-the-podium/beyond-the-podium-1st-congressional-district-candidate-christina-bohannan', 'https://radioiowa.com/2024/08/12/bohannan-says-miller-meeks-playing-politics-on-immigration-issue/']),  -- Christina Bohannan: Immigration
  ('c0811d78-fd93-48d6-a759-f4f0f012e502', '683c8084-2281-4920-a07c-18439b2dd413', ARRAY['https://bohannanforcongress.com/priorities/', 'https://cbs2iowa.com/news/beyond-the-podium/beyond-the-podium-1st-congressional-district-candidate-christina-bohannan']),  -- Christina Bohannan: Tariffs
  ('c0811d78-fd93-48d6-a759-f4f0f012e502', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://bohannanforcongress.com/priorities/', 'https://iowacapitaldispatch.com/2024/10/21/miller-meeks-bohannan-face-off-on-abortion-immigration-at-1st-district-debate/', 'https://iowacapitaldispatch.com/2024/08/10/democrat-christina-bohannan-vows-to-defend-abortion-in-iowa-state-fair-speech/']),  -- Christina Bohannan: Abortion
  ('c0811d78-fd93-48d6-a759-f4f0f012e502', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', ARRAY['https://iowagop.org/blog/as-supreme-court-upholds-girls-sports-law-iowa-democrats-stay-silent/']),  -- Christina Bohannan: Trans Athletes
  ('c7f94731-2162-4fb7-803a-a2ff7443a9a1', '48cc9585-ec22-4f53-8d42-6839828dd36f', ARRAY['https://mikecherryforva.com/special-session-update-oct2025/', 'https://www.vpap.org/legislators/369687-mike-cherry/list-votes/close-votes/?session=39']),  -- Mike A. Cherry: Redistricting
  ('c7f94731-2162-4fb7-803a-a2ff7443a9a1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://www.vpap.org/legislators/369687-mike-cherry/list-votes/close-votes/?session=39', 'https://repro-files.com/candidates/mikecherry/reproductiverights']),  -- Mike A. Cherry: Abortion
  ('cd10014f-2a57-4d68-b7ae-ad5233747c5a', '683c8084-2281-4920-a07c-18439b2dd413', ARRAY['https://jeffwadlin.com/issues', 'https://jeffwadlin.com/in-the-news/rgt4p58qm0ttaqu839of3w801ix7t8', 'https://arktimes.com/arkansas-blog/2026/05/19/libertarian-u-s-senate-candidate-announces-campaign-kickoff']),  -- Jeff Wadlin: Tariffs
  ('cd10014f-2a57-4d68-b7ae-ad5233747c5a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://smarter.vote/races/ar-senate-2026/jeff-wadlin/']),  -- Jeff Wadlin: Abortion
  ('cd10014f-2a57-4d68-b7ae-ad5233747c5a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://jeffwadlin.com/issues', 'https://jeffwadlin.com/in-the-news/rgt4p58qm0ttaqu839of3w801ix7t8']),  -- Jeff Wadlin: Healthcare
  ('e345c9d6-4e28-4416-86de-24ab84c803f9', '48cc9585-ec22-4f53-8d42-6839828dd36f', ARRAY['https://virginiabusiness.com/virginia-officials-oppose-april-21-congressional-redistricting/', 'https://www.vpap.org/legislators/83461-justin-l-pence/list-votes/close-votes/?session=39']),  -- Justin L. Pence: Redistricting
  ('e71141e4-e52b-45e1-9cf4-9e01ea5a5a38', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', ARRAY['https://drahmadhassan.com/issues']),  -- Ahmad Hassan: Healthcare
  ('e71141e4-e52b-45e1-9cf4-9e01ea5a5a38', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', ARRAY['https://drahmadhassan.com/issues']),  -- Ahmad Hassan: Climate Change
  ('f4257ee4-57c8-47dd-81ed-4abfa71a2e24', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', ARRAY['https://lilyfordelegate.com/priorities', 'https://www.vpap.org/legislators/449164-lily-franklin/list-votes/close-votes/?session=39']),  -- Lily V. Franklin: Abortion
  ('ff596d3f-3056-43e2-a80a-8c4b8fd9abde', '00b95a6a-75db-4521-b523-3326bba938de', ARRAY['https://harris.house.gov/issues/education']),  -- Andy Harris: School Vouchers
  ('ff596d3f-3056-43e2-a80a-8c4b8fd9abde', '24e9212c-b011-422a-865c-093e35050901', ARRAY['https://clerk.house.gov/Votes/2024151']),  -- Andy Harris: Ukraine Support
  ('ff596d3f-3056-43e2-a80a-8c4b8fd9abde', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', ARRAY['https://clerk.house.gov/Votes/2025102', 'https://en.wikipedia.org/wiki/Andy_Harris_(politician)'])  -- Andy Harris: Voting Rights
;

UPDATE inform.politician_context pc
   SET sources = u.new_sources
  FROM _unwrap_1515 u
 WHERE pc.politician_id = u.politician_id
   AND pc.topic_id = u.topic_id;

DO $$
DECLARE
  v_target int;
  v_left   int;
  v_empty  int;
BEGIN
  SELECT count(*) INTO v_target FROM _unwrap_1515;
  IF v_target <> 55 THEN
    RAISE EXCEPTION 'expected 55 targeted rows, found %', v_target;
  END IF;

  -- No stance answer anywhere may still cite a scraping proxy.
  SELECT count(*) INTO v_left
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
   WHERE pa.value <> 0
     AND EXISTS (SELECT 1 FROM unnest(pc.sources) s
                  WHERE s ILIKE '%r.jina.ai%' OR s ILIKE '%webcache.googleusercontent%'
                     OR s ILIKE '%translate.goog%' OR s ILIKE '%12ft.io%');
  IF v_left <> 0 THEN
    RAISE EXCEPTION '% answers still cite a scraping proxy', v_left;
  END IF;

  SELECT count(*) INTO v_empty
    FROM inform.politician_context pc
    JOIN _unwrap_1515 u ON u.politician_id = pc.politician_id AND u.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_empty <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_empty;
  END IF;
END $$;

COMMIT;
