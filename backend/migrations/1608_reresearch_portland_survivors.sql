-- 1608: Re-research the 15 published Portland survivors.
--
-- Context. Migration 1558 retired 57 Portland rows sourced to the composed host willametteweek.com
-- but left 15 rows standing on five other authorities. Verification 2026-08-07 (record:
-- data/stance-research/reresearch-portland/2026-08-07-survivors-verification.md) found all five fail:
--
--   portland.gov/council/agenda        (Ryan x6)  LIVE landing page; never names Ryan; every claim
--                                                  term 0; it is a rolling next-meeting agenda and has
--                                                  never held the 2020-2024 minutes the rows cite.
--   portland.gov/mayor                 (Wilson x2) LIVE per-person page; zero on every term distinctive
--                                                  to its two topics.
--   oregonlive.com/portland/2024/10/portland-mayoral-candidates-weigh-in-... (Wilson x3)
--                                                  COMPOSED: zero Wayback captures while the slug's own
--                                                  neighbourhood (/portland/2024/10/portland-m*) is
--                                                  archived.
--   oregonlive.com/portland/loretta-smith (Smith x2) and .../steve-novick (Novick x2)
--                                                  COMPOSED: the /portland/<hyphenated-name> shape does
--                                                  not exist on oregonlive -- zero captures for these two
--                                                  and for three Portland controls. The real shape is
--                                                  oregonlive.com/topic/<Name>/, where both DO have real
--                                                  archived pages. Not re-pointed there: those are index
--                                                  pages, and a landing page is not coverage.
--
-- All 15 were sole-sourced and every one embedded its URL in the voter-facing reasoning prose.
--
-- Remedy. Portland publishes PER-MEMBER ROLL-CALL RECORDS at
-- portland.gov/council/districts/<n>/<name>/votes -- named individual Yea/Nay/Absent per council
-- document, searchable via ?council_document=. This is the per-member evidence the cluster lacked, and
-- it is why these rows are REPAIRED rather than retired: a fabricated citation is not proof the claim
-- was wrong. Wilson is the exception -- under Portland's charter the mayor votes only to break ties
-- (exactly 1 vote on file), so he is sourced to his official published agenda instead.
--
--   12 REPAIRED (new sources + reasoning; 6 chairs corrected)
--    3 RETIRED  (Wilson/Environmental Protection, Wilson/Residential Zoning, Smith/Homelessness) --
--               the citation is verified absent and no free source was found that evidences a chair.
--
-- Every citation below was fetched and asserted to carry its distinctive claim terms in raw HTML
-- before this migration was written (21/21 verified).
--
-- Rollback: data/stance-retirement/2026-08-07-portland-survivors-rollback.json
--           (verified field-by-field against the DB; canonical_md5 9835bcc6030512f035ab50d1abb0b7b0)

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- Guard: the cohort is exactly the 15 rows we verified, and nothing else in the corpus -- including
-- orphan context rows -- cites any of the five bad authorities. (1602 lesson: an unscoped remedy that
-- came from live rows can silently empty an orphan row.)
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_ctx int; v_ans int; v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM inform.politician_context
   WHERE sources && ARRAY[
           'https://www.portland.gov/council/agenda',
           'https://www.portland.gov/mayor',
           'https://www.oregonlive.com/portland/loretta-smith',
           'https://www.oregonlive.com/portland/steve-novick',
           'https://www.oregonlive.com/portland/2024/10/portland-mayoral-candidates-weigh-in-on-homelessness-housing-and-public-safety.html'];
  IF v_bad <> 15 THEN
    RAISE EXCEPTION 'expected exactly 15 rows citing the five bad authorities, found %', v_bad;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff');
  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff');
  IF v_ctx <> 15 OR v_ans <> 15 THEN
    RAISE EXCEPTION 'expected 15 context and 15 answer rows for the four politicians, found % / %', v_ctx, v_ans;
  END IF;
END $$;

-- ===============================================================================================
-- REPAIRED -- DAN RYAN (D2), sourced to his own portland.gov voting record
-- ===============================================================================================

-- Environmental Protection vs. Development: chair 2 -> 3
UPDATE inform.politician_context SET
  reasoning = 'Ryan''s council votes point to steady environmental standards with room for projects to proceed, rather than preservation-first rules. In November 2024 he voted to continue Portland''s existing private-tree preservation regulations rather than tighten them, and in March 2026 he voted to streamline environmental zoning regulations so needed public infrastructure projects could proceed while supporting ongoing natural resource management.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Tree+Preservation',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Public+Infrastructure+Environmental']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa';

-- Homelessness Response: chair 2 -> 3
-- NB the earlier read that his record "contradicted" this row was wrong: he voted for shelter
-- expansion repeatedly. His two Nays are on Multnomah County Joint Office GOVERNANCE items, not on
-- shelter. The chair moves because he also voted for the camping restrictions.
UPDATE inform.politician_context SET
  reasoning = 'Ryan has funded shelter and services heavily while also backing enforcement of public-space rules. He voted for emergency shelter expansion and for zoning changes to allow more shelter options for Portlanders in need, and he separately voted for the 2023 and 2024 updates to Portland''s public camping restrictions.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=shelter',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=camping']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

-- Public Safety Approach: chair 3 unchanged
UPDATE inform.politician_context SET
  reasoning = 'Ryan keeps existing public safety funding while stopping short of restructuring the system around unarmed responders. In June 2025 he voted against making Portland Street Response a co-equal branch of the first responder system, though he voted to appoint members to the Portland Street Response Committee, and in February 2026 he voted to require a report on police officer recruitment goals and costs.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Portland+Street+Response',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=recruitment']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- Rent Regulation: chair 2 -> 3
UPDATE inform.politician_context SET
  reasoning = 'Ryan supports the tenant protections Portland already has but declined to add a new rent regulation. He has repeatedly voted to fund eviction legal defense for tenants at risk of eviction, and in November 2025 he voted against prohibiting anti-competitive rental practices including the sale and use of algorithmic pricing devices.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Eviction+Legal+Defense',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=anti-competitive']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

-- Residential Zoning: chair 2 -> 4
UPDATE inform.politician_context SET
  reasoning = 'Ryan has consistently voted to make housing easier to build. He supported the Housing Regulatory Relief Project''s temporary suspensions and permanent clarifications of development and process regulations, and voted for vehicle parking reforms in the planning and zoning code.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Housing+Regulatory+Relief',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=vehicle+parking']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d';

-- Transportation Priorities: chair 2 unchanged. Old reasoning's "TriMet funding" appears nowhere in
-- his record and is not restated.
UPDATE inform.politician_context SET
  reasoning = 'Ryan backs multimodal safety investment but has resisted new transportation charges. He voted to reaffirm Council''s commitment to the Vision Zero Action Plan and to convene a cross-bureau Vision Zero Task Force, while voting against establishing a new Transportation Utility Fee to fund basic maintenance and safety of the city''s transportation system.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Vision+Zero',
    'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Transportation+Utility+Fee']
WHERE politician_id = '60fa9870-d984-46a7-a6ed-5f6fbebe72ce' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';

-- ===============================================================================================
-- REPAIRED -- KEITH WILSON (Mayor), sourced to his official published agenda
-- ===============================================================================================

-- Economic Development Incentives: chair 2 -> 3
UPDATE inform.politician_context SET
  reasoning = 'Wilson''s published agenda makes place-based tax incentives central to Portland''s economy. He commits to activating six new tax increment financing districts, described as the City''s strategy for capturing increases in property tax revenue and reinvesting them locally in housing, infrastructure and economic improvements, delivered in partnership with Prosper Portland.',
  sources = ARRAY['https://www.portland.gov/promise/about-portlands-promise/activation']
WHERE politician_id = 'bd39d61e-3040-4ec1-815e-df16b1f9a8a0' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'bd39d61e-3040-4ec1-815e-df16b1f9a8a0' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53';

-- Homelessness Response: chair 3 unchanged. The retired citation was fabricated but the claim it
-- carried was substantively right -- shelter investment paired with enforcement.
UPDATE inform.politician_context SET
  reasoning = 'Wilson pairs large-scale shelter investment with enforcement of public space rules. The City reports overnight shelters with a total capacity of 1,500 beds alongside alternative shelters, expanded day centers, street outreach and a reunification program, and has resumed enforcement of the camping ordinance, which prohibits camping in public spaces.',
  sources = ARRAY[
    'https://www.portland.gov/homeless/homeless-crisis',
    'https://www.portland.gov/sscc/camping-ordinance']
WHERE politician_id = 'bd39d61e-3040-4ec1-815e-df16b1f9a8a0' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

-- Public Safety Approach: chair 4 unchanged, reasoning narrowed to what the source actually states.
-- The old "rebuild Portland Police Bureau, hire more officers, reduce property crime" is not on any
-- verified page and is not restated.
UPDATE inform.politician_context SET
  reasoning = 'Wilson''s public safety goals centre on adding sworn investigative capacity. He commits to adding 24 new investigators by the end of 2027 to pursue crimes including human trafficking, domestic violence, organized retail theft and vehicular homicide, alongside a Vision Zero commitment to cut traffic deaths to their lowest level in a decade.',
  sources = ARRAY['https://www.portland.gov/promise/about-portlands-promise/public-health-and-safety']
WHERE politician_id = 'bd39d61e-3040-4ec1-815e-df16b1f9a8a0' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- ===============================================================================================
-- REPAIRED -- LORETTA SMITH (D1) and STEVE NOVICK (D3)
-- ===============================================================================================

-- Smith, Local Immigration Enforcement: chair 1 unchanged, now resting on the ordinance she voted for
-- rather than on her pre-2018 county record.
UPDATE inform.politician_context SET
  reasoning = 'Smith voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=Sanctuary',
    'https://www.portland.gov/code/23/20']
WHERE politician_id = 'e6682850-601f-4017-b4e7-d9cd4be47aea' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';

-- Novick, Public Safety Approach: chair 2 unchanged
UPDATE inform.politician_context SET
  reasoning = 'Novick voted in June 2025 to support and expand Portland Street Response as a co-equal branch of the first responder system and to establish the Portland Street Response Committee, backing unarmed crisis responders alongside police rather than in place of them.',
  sources = ARRAY['https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Portland+Street+Response']
WHERE politician_id = 'c9e19031-259e-4133-b5d9-96cf1a5f31ff' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- Novick, Transportation Priorities: chair 1 -> 2. Chair 1 requires reducing parking requirements
-- communitywide; nothing in his record shows that, so the claim is not made.
UPDATE inform.politician_context SET
  reasoning = 'Novick backs both road maintenance and multimodal safety. He voted to reaffirm Council''s commitment to the Vision Zero Action Plan and to convene a cross-bureau Vision Zero Task Force, and voted to establish a new Transportation Utility Fee to fund basic maintenance and safety of the city''s transportation system.',
  sources = ARRAY[
    'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Vision+Zero',
    'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Transportation+Utility+Fee']
WHERE politician_id = 'c9e19031-259e-4133-b5d9-96cf1a5f31ff' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c9e19031-259e-4133-b5d9-96cf1a5f31ff' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';

-- ===============================================================================================
-- RETIRED -- 3 rows. Citation verified absent and no free source found that evidences a chair.
--   Wilson / Environmental Protection vs. Development -- the Green Leadership agenda is about the green
--     ECONOMY (jobs, clean energy, emissions) and says nothing about the development-vs-preservation
--     tradeoff this topic asks about.
--   Wilson / Residential Zoning -- the Housing agenda sets production targets (20,000 permits citywide
--     by 2032) and a home-share pilot; it states no zoning or density policy.
--   Smith / Homelessness Response -- her only on-topic votes are adopting the Homelessness Response
--     System Action Plan and appointing committee members; neither locates her on the service-versus-
--     enforcement scale.
-- Delete from BOTH tables so no orphan context row survives.
-- ===============================================================================================
DELETE FROM inform.politician_answers
 WHERE (politician_id, topic_id) IN (
   ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
   ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
   ('e6682850-601f-4017-b4e7-d9cd4be47aea','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'));

DELETE FROM inform.politician_context
 WHERE (politician_id, topic_id) IN (
   ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
   ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
   ('e6682850-601f-4017-b4e7-d9cd4be47aea','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'));

-- ---------------------------------------------------------------------------------------------
-- Post-conditions, asserted on row counts rather than on absence of error (RLS makes a silent no-op
-- look like success).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_bad int; v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int;
BEGIN
  -- 1. not one citation of the five bad authorities survives, anywhere in the corpus
  SELECT count(*) INTO v_bad
    FROM inform.politician_context
   WHERE sources && ARRAY[
           'https://www.portland.gov/council/agenda',
           'https://www.portland.gov/mayor',
           'https://www.oregonlive.com/portland/loretta-smith',
           'https://www.oregonlive.com/portland/steve-novick',
           'https://www.oregonlive.com/portland/2024/10/portland-mayoral-candidates-weigh-in-on-homelessness-housing-and-public-safety.html'];
  IF v_bad <> 0 THEN RAISE EXCEPTION 'bad authorities survive in % rows', v_bad; END IF;

  -- 2. the four politicians keep exactly 12 rows, matched in both tables
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff');
  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff');
  IF v_ctx <> 12 OR v_ans <> 12 THEN
    RAISE EXCEPTION 'expected 12 context and 12 answer rows, found % / %', v_ctx, v_ans;
  END IF;

  -- 3. no orphan context row created by the deletes
  SELECT count(*) INTO v_orphan
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pc.politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                              'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff')
     AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan context rows created', v_orphan; END IF;

  -- 4. zero-tolerance: no repaired row left with empty sources
  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff')
     AND (sources IS NULL OR cardinality(sources) = 0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows left with empty sources', v_empty; END IF;

  -- 5. no surviving reasoning embeds a raw URL (the Stephenson defect: invented URLs in voter-facing prose)
  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id IN ('60fa9870-d984-46a7-a6ed-5f6fbebe72ce','bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','c9e19031-259e-4133-b5d9-96cf1a5f31ff')
     AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% surviving rows still embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
