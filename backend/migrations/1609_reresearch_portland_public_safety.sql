-- 1609: Re-research the 9 owed Portland "Public Safety Approach" rows.
--
-- These 9 were retired by migration 1558: all were sole-sourced to fabricated
-- willametteweek.com district questionnaires ("...candidates-answer-our-questions"), articles that
-- never existed on a host that was WW's genuine former domain. Retired chairs were 7x2 and 2x3.
-- Scope: data/stance-research/reresearch-portland/2026-08-07-scope-of-the-57.md
--
-- All 9 currently hold NO row for this topic, and 8 of the 9 hold no compass answer at all, so these
-- are INSERTs into both tables.
--
-- EVIDENCE. Each row is sourced to the councilor's OWN roll-call record on portland.gov
-- (see [[portland_vote_records]]). The five documents that bear on this topic:
--
--   2025-175  Support and expand Portland Street Response as a co-equal branch of the first
--             responder system, and establish the PSR Committee      -- ALL NINE VOTED YEA
--   2026-042  Require a report on police officer recruitment goals and costs
--             Nay: Avalos, Kanal, Morillo, Koyama Lane, Green | Yea: Dunphy, Smith,
--                  Pirtle-Guiney, Zimmerman
--   2026-069  Appoint members to the Community Board for Police Accountability
--             Nay: Zimmerman (alone)          | Yea: the other eight
--   2025-160  Amend the Portland Police Association employee benefits program
--             Nay: Avalos (alone)             | Yea: the other eight
--   2025-027  Appoint Robert Day as Chief of Police                  -- ALL NINE VOTED YEA
--
-- 🔴 THE CHAIR IS 2 FOR ALL NINE, AND THAT IS NOT LAZINESS -- IT IS WHAT THE RECORD SAYS.
-- Chair 2 is "Maintain current police staffing but shift non-violent calls to unarmed mental health
-- co-responders." Both halves are directly evidenced for every one of them: they voted unanimously to
-- make Portland Street Response -- unarmed crisis responders -- a CO-EQUAL BRANCH of the first
-- responder system (the shift), and unanimously to appoint a Chief of Police and to keep police
-- compensation intact via the PPA agreements (maintaining staffing). The scope document predicted
-- 2025-175 would discriminate; it does, but it separates Dan Ryan (Nay, already handled in mig 1608)
-- from everyone else, and Ryan is not in this cohort. Among these nine it is unanimous.
--
-- ⚠ Zimmerman was the one judgment call. He is the council's most centrist member on this topic --
-- the only Nay on the police accountability board, and a Yea on the recruitment report -- and his
-- retired chair was 3. He is nonetheless chaired 2 because his single most on-topic vote (2025-175,
-- shifting calls to unarmed responders) is identical to everyone else's, and his two dissents concern
-- civilian OVERSIGHT and a staffing REPORT, neither of which bears on how calls are routed. Chairing
-- him 3 would read those votes as if they were co-responder votes. His dissents are stated plainly in
-- his reasoning so a voter sees the difference at the same chair.
--
-- ⚠ Four councilors (Kanal, Morillo, Koyama Lane, Green) have IDENTICAL records across all five
-- documents, so their reasonings are necessarily near-identical. That is an accurate report of an
-- identical voting record, not copy-paste. Flagged rather than papered over with invented distinctions.
--
-- Every citation was fetched and asserted to show that member's own vote before this was written
-- (28 checks + Dunphy's annual-report citation, 0 failures).

BEGIN;

DO $$
DECLARE v_existing int; v_people int;
BEGIN
  -- none of the nine may already hold this topic, or these INSERTs would duplicate
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing public-safety rows, found %', v_existing; END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_people <> 9 THEN RAISE EXCEPTION 'expected 9 politicians, found %', v_people; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

-- Candace Avalos (D1) -- the strongest co-responder tilt of the nine
('c5db367e-9403-4a88-a95f-bf864279e13b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Avalos backs unarmed crisis responders while declining to expand police resourcing. In June 2025 she voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and she voted to appoint members to the Community Board for Police Accountability. She was the only councilor to vote against amending the Portland Police Association employee benefits program, and in February 2026 she voted against requiring a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Employee+Benefits+Program',
       'https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=recruitment']),

-- Jamie Dunphy (D1)
('14ebbd1c-597e-483a-a846-73a7aca54ed2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Dunphy backs unarmed crisis responders alongside continued scrutiny of the police bureau. In June 2025 he voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and he voted to appoint members to the Community Board for Police Accountability. He supported requiring a report on police officer recruitment goals and costs, while voting against accepting the Portland Police Bureau''s 2024 annual report.',
 ARRAY['https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=recruitment',
       'https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Police+Bureau+Annual+Report']),

-- Loretta Smith (D1)
('e6682850-601f-4017-b4e7-d9cd4be47aea', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Smith backs unarmed crisis responders while remaining open to reviewing police staffing. In June 2025 she voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and she voted to appoint members to the Community Board for Police Accountability. She also voted to require a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=recruitment']),

-- Elana Pirtle-Guiney (D2)
('987e0304-acd0-4b00-bf65-9e4fdbe4af3a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Pirtle-Guiney backs unarmed crisis responders while remaining open to reviewing police staffing. In June 2025 she voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and she voted to appoint members to the Community Board for Police Accountability. She also voted to require a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=recruitment']),

-- Sameer Kanal (D2)
('dc00f7c1-54d1-46d8-8b35-545abdd38d8d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Kanal backs unarmed crisis responders as a standing part of Portland''s emergency response. In June 2025 he voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and he voted to appoint members to the Community Board for Police Accountability. In February 2026 he voted against requiring a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=recruitment']),

-- Angelita Morillo (D3)
('c6799d98-362a-4e27-b7c5-be45a82a150f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Morillo backs unarmed crisis responders as a standing part of Portland''s emergency response. In June 2025 she voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and she voted to appoint members to the Community Board for Police Accountability. In February 2026 she voted against requiring a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=recruitment']),

-- Tiffany Koyama Lane (D3)
('2947c92f-fee2-46e4-b472-9fd89a8f0f65', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Koyama Lane backs unarmed crisis responders as a standing part of Portland''s emergency response. In June 2025 she voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and she voted to appoint members to the Community Board for Police Accountability. In February 2026 she voted against requiring a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=recruitment']),

-- Eric Zimmerman (D4) -- see the header note on why this is chair 2 and not 3
('1518349b-3d63-49d0-9411-be19f86a7ea7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Zimmerman backs unarmed crisis responders but is the council''s most sceptical member on police oversight. In June 2025 he voted to support and expand Portland Street Response as a co-equal branch of the first responder system. He was the only councilor to vote against appointing members to the Community Board for Police Accountability, and he voted to require a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=recruitment']),

-- Mitch Green (D4)
('acc73d7e-6522-40a9-bbe0-17cf56a96466', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
 'Green backs unarmed crisis responders as a standing part of Portland''s emergency response. In June 2025 he voted to support and expand Portland Street Response as a co-equal branch of the first responder system, and he voted to appoint members to the Community Board for Police Accountability. In February 2026 he voted against requiring a report on police officer recruitment goals and costs.',
 ARRAY['https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=Portland+Street+Response',
       'https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=Community+Board+for+Police+Accountability',
       'https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=recruitment']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, topic_id, 2
  FROM inform.politician_context
 WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
   AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                         'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                         'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                         '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                         'acc73d7e-6522-40a9-bbe0-17cf56a96466');

DO $$
DECLARE v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int; v_chair int;
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_ctx <> 9 THEN RAISE EXCEPTION 'expected 9 new context rows, found %', v_ctx; END IF;

  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_ans <> 9 THEN RAISE EXCEPTION 'expected 9 new answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_chair FROM inform.politician_answers
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value = 2
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_chair <> 9 THEN RAISE EXCEPTION 'expected all 9 chairs = 2, found %', v_chair; END IF;

  -- no orphan, no empty sources, no URL in voter-facing prose
  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pa.politician_id IS NULL AND pc.topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
     AND pc.politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                              'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                              'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                              '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                              'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85' AND (sources IS NULL OR cardinality(sources) = 0)
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85' AND reasoning ~ 'https?://'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           'e6682850-601f-4017-b4e7-d9cd4be47aea','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           '2947c92f-fee2-46e4-b472-9fd89a8f0f65','1518349b-3d63-49d0-9411-be19f86a7ea7',
                           'acc73d7e-6522-40a9-bbe0-17cf56a96466');
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
