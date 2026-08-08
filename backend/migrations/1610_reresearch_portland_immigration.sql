-- 1610: Re-research the 8 owed Portland "Local Immigration Enforcement" rows,
--       and correct a pronoun in migration 1609.
--
-- PART A -- the 8 immigration rows.
-- Retired by migration 1558, all sole-sourced to fabricated willametteweek.com district
-- questionnaires. None of the 8 currently holds this topic, so these are INSERTs into both tables.
-- Loretta Smith's row for this topic was a survivor and was already repaired at chair 1 in mig 1608;
-- these 8 rest on the same ordinance and reach the same chair.
--
-- EVIDENCE -- each councilor's own portland.gov roll-call record, plus the operative code text:
--   2025-402  *Add Code to enact Sanctuary City status protections (add Code Chapter 23.20)
--   2025-401  Denounce any attempts to deploy the U.S. Armed Forces, the National Guard, or
--             militarized Federal Immigration Enforcement in Portland; establish the Protect
--             Portland Initiative
--   2026-053  Reallocate $150,000 to support refugee and immigration legal services
--
-- 🔴 ALL EIGHT VOTED YEA ON ALL THREE. Searched widely to avoid assuming unanimity -- sanctuary,
-- immigration, immigrant, refugee, National Guard, federal, ICE, Protect Portland -- and there is
-- genuinely ZERO variation among them. So all 8 are chair 1 and the reasonings are near-identical.
-- That is an accurate report of an identical voting record, not copy-paste, and it is invisible to a
-- voter, who sees one councilor's profile at a time. No artificial distinctions were invented.
-- The only honest differentiator is Dan Ryan, whose earlier council term adds two immigrant-services
-- votes the others could not have cast.
--
-- Chair 1 is "Refuse all ICE detainers; prohibit local employees from sharing immigration status
-- information with federal agencies." Both halves are in the operative text of Code Ch. 23.20.030:
-- A.2 bars any agreement with a federal immigration authority relating to detention, and A.3 bars
-- collecting, inquiring into or disclosing immigration or citizenship status for enforcement
-- purposes. The carve-outs in A.4 are judicial (court order, warrant, subpoena), which is what
-- distinguishes chair 1 from chair 2's "comply only with court-ordered detainers".
--
-- All 25 citations were fetched and asserted to carry their claim terms before this was written.
--
-- PART B -- pronoun correction to migration 1609.
-- ⚠ In 1609 Sameer Kanal's reasoning used "he", which I inferred from a name. portland.gov publishes
-- a Pronouns field on each councilor page; Kanal's page lists NONE, so the inference was unfounded.
-- Rewritten pronoun-free below. Checked all eleven councilors against their official pages while
-- fixing this: Avalos She/Her, Dunphy He/Him, Smith She/Her, Ryan He/Him, Pirtle-Guiney She/Her,
-- Morillo She/They, Novick He/Him, Koyama Lane She/Her, Zimmerman He/Him, Green He/Him -- all of
-- which match what 1608 and 1609 already say. Kanal was the only error.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce',
                           '987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d',
                           'c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing immigration rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

('c5db367e-9403-4a88-a95f-bf864279e13b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Avalos voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. She also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

('60fa9870-d984-46a7-a6ed-5f6fbebe72ce', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Ryan voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. He also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services. In his earlier council term he voted to fund immigrant and refugee services directly, including an interpretation-services contract with the Immigrant and Refugee Community Organization and a legal access and referral clinic run with Portland Community College.',
 ARRAY['https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=immigration',
       'https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Immigrant+and+Refugee',
       'https://www.portland.gov/code/23/20']),

('987e0304-acd0-4b00-bf65-9e4fdbe4af3a', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Pirtle-Guiney voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. She also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

-- Kanal: pronoun-free, no pronouns published
('dc00f7c1-54d1-46d8-8b35-545abdd38d8d', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Kanal voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. Kanal also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

('c6799d98-362a-4e27-b7c5-be45a82a150f', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Morillo voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. She also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

('c9e19031-259e-4133-b5d9-96cf1a5f31ff', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Novick voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. He also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

('2947c92f-fee2-46e4-b472-9fd89a8f0f65', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Koyama Lane voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. She also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']),

('acc73d7e-6522-40a9-bbe0-17cf56a96466', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Green voted to codify Portland''s sanctuary protections into binding city law. The ordinance bars City facilities, property, money, equipment and personnel from being used to investigate, detain or hold people for federal immigration enforcement; bars any City entity or law enforcement agency from entering an agreement with a federal immigration authority relating to detention; and bars collecting, inquiring into or disclosing a person''s immigration or citizenship status for enforcement purposes, except where a court order, warrant or other compulsory legal process requires it. He also voted to denounce any deployment of militarized federal immigration enforcement in Portland and to establish the Protect Portland Initiative, and to fund refugee and immigration legal services.',
 ARRAY['https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=Sanctuary',
       'https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=immigration',
       'https://www.portland.gov/code/23/20']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, topic_id, 1
  FROM inform.politician_context
 WHERE topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'
   AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce',
                         '987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d',
                         'c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff',
                         '2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');

-- PART B: remove the unfounded pronoun from Kanal's 1609 Public Safety reasoning.
UPDATE inform.politician_context SET
  reasoning = 'Kanal backs unarmed crisis responders as a standing part of Portland''s emergency response. In June 2025 Kanal voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and to appoint members to the Community Board for Police Accountability. In February 2026 Kanal voted against requiring a report on police officer recruitment goals and costs.'
WHERE politician_id = 'dc00f7c1-54d1-46d8-8b35-545abdd38d8d'
  AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

DO $$
DECLARE v_ctx int; v_ans int; v_chair int; v_orphan int; v_empty int; v_prose int; v_kanal int;
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_ctx <> 8 THEN RAISE EXCEPTION 'expected 8 context rows, found %', v_ctx; END IF;

  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_ans <> 8 THEN RAISE EXCEPTION 'expected 8 answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_chair FROM inform.politician_answers
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value = 1
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_chair <> 8 THEN RAISE EXCEPTION 'expected all 8 chairs = 1, found %', v_chair; END IF;

  -- Kanal carries no inferred pronoun in either of his rows
  SELECT count(*) INTO v_kanal FROM inform.politician_context
   WHERE politician_id = 'dc00f7c1-54d1-46d8-8b35-545abdd38d8d'
     AND reasoning ~* '\m(he|him|his|she|her|hers)\M';
  IF v_kanal <> 0 THEN RAISE EXCEPTION '% Kanal rows still carry a gendered pronoun', v_kanal; END IF;

  -- ⚠ These three MUST be scoped to the 8 politicians, not to the topic. Local Immigration
  -- Enforcement is a national topic held by thousands of politicians, and much of that pre-existing
  -- corpus does embed URLs in reasoning -- a topic-wide assertion would abort this migration over
  -- rows it never touched.
  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pa.politician_id IS NULL AND pc.topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92'
     AND pc.politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan immigration rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND (sources IS NULL OR cardinality(sources)=0)
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_empty <> 0 THEN RAISE EXCEPTION '% immigration rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND reasoning ~ 'https?://'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a','dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f','c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65','acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_prose <> 0 THEN RAISE EXCEPTION '% immigration rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
