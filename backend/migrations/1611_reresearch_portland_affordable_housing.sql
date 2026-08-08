-- 1611: Re-research the 11 owed Portland "Affordable Housing" rows.
--
-- Retired by migration 1558, all sole-sourced to fabricated willametteweek.com district
-- questionnaires. Retired chairs were 10x2 and 1x3 (Zimmerman). None of the 11 currently holds this
-- topic, so these are INSERTs into both tables.
--
-- EVIDENCE -- four council documents, all reachable from one precise per-member citation
-- (votes?council_document=Affordable+Housing), plus Wilson's published agenda:
--
--   2025-003  Appropriate $7,000,000 in U.S. HUD grants for the Barbur Apartments affordable
--             housing development                                      -- ALL TEN YEA
--   2026-037  Adopt the Affordable Housing Opportunities Project amendments to the Comprehensive
--             Plan Map and Official Zoning Map      Absent: Ryan       | Yea: the other nine
--   2025-045  Amend Affordable Housing Code to prohibit anti-competitive rental practices
--             including algorithmic devices         Nay: Ryan · Absent: Novick, Zimmerman
--   2026-205  Amend System Development Charge exemptions for Affordable Housing Developments to
--             temporarily remove income requirements for homeownership units
--                                                   Nay: Pirtle-Guiney, Koyama Lane, Zimmerman
--                                                   Absent: Avalos | Yea: the other six
--
-- CHAIR 3 FOR ALL ELEVEN -- "Offer targeted help like subsidies for affordable projects, first-time
-- buyer assistance, and easier building permits." That is precisely the shape of the record: federal
-- subsidy for a specific affordable development, fee relief through SDC exemptions, and zoning and
-- planning changes that make affordable projects easier to build. Chair 2 ("rent caps, require new
-- developments to include affordable units") is NOT supported -- Portland's Inclusionary Housing
-- Program predates this council, so none of them voted for it, and an anti-price-fixing rule is not a
-- rent cap. Reading 2025-045 as a rent cap would be upgrading on tone.
--
-- 🔴 I DECLINED TO INFER MOTIVE FROM THE NAYS, and that is deliberate. 2026-205 splits 6-3 and it is
-- tempting to read the three Nays as insisting that subsidy stay income-targeted (a chair-2 lean).
-- But a roll call records a vote, not a reason: the same Nay is equally consistent with opposing fee
-- waivers on fiscal grounds, which is the likelier reading for Zimmerman, the council's most centrist
-- member. One vote cannot mean opposite things for different people in the same analysis. Each Nay is
-- therefore stated as a fact in that person's reasoning and left uninterpreted.
--
-- ⚠ Absences are omitted rather than described -- an absence is not a position, and writing "did not
-- vote" would imply one. Ryan is credited only with 2025-003 and 2026-205 plus his 2025-045 Nay;
-- Novick and Zimmerman are not credited with 2025-045; Avalos is not credited with 2026-205.
--
-- ⚠ Kanal's reasoning is deliberately pronoun-free: portland.gov publishes a Pronouns field per
-- councilor and Kanal's lists none (see mig 1610 Part B). Others follow their published pronouns.
--
-- All 11 citations were fetched and asserted to carry every document named, before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
     AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                           '60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                           'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                           'c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65',
                           '1518349b-3d63-49d0-9411-be19f86a7ea7','acc73d7e-6522-40a9-bbe0-17cf56a96466',
                           'bd39d61e-3040-4ec1-815e-df16b1f9a8a0');
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing affordable-housing rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

-- Candace Avalos (She/Her) -- absent on 2026-205, so not credited with it
('c5db367e-9403-4a88-a95f-bf864279e13b', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Avalos backs public subsidy and regulation of rental practices rather than direct public ownership of housing. She voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, and to prohibit anti-competitive rental practices including the sale and use of algorithmic pricing devices.',
 ARRAY['https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=Affordable+Housing']),

-- Jamie Dunphy (He/Him) -- Yea on all four
('14ebbd1c-597e-483a-a846-73a7aca54ed2', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Dunphy backs targeted subsidy and fee relief for affordable housing rather than direct public ownership. He voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, to prohibit anti-competitive rental practices including algorithmic pricing devices, and to extend system development charge exemptions for affordable housing developments.',
 ARRAY['https://www.portland.gov/council/districts/1/jamie-dunphy/votes?council_document=Affordable+Housing']),

-- Dan Ryan (He/Him) -- absent on 2026-037; Nay on 2025-045
('60fa9870-d984-46a7-a6ed-5f6fbebe72ce', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Ryan backs subsidy and fee relief for affordable housing while declining to add new regulation of rental pricing. He voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development and to extend system development charge exemptions for affordable housing developments, including temporarily removing income requirements for homeownership units. He voted against prohibiting anti-competitive rental practices including the sale and use of algorithmic pricing devices.',
 ARRAY['https://www.portland.gov/council/districts/2/dan-ryan/votes?council_document=Affordable+Housing']),

-- Elana Pirtle-Guiney (She/Her) -- Nay on 2026-205, stated but not interpreted
('987e0304-acd0-4b00-bf65-9e4fdbe4af3a', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Pirtle-Guiney backs public subsidy and regulation of rental practices rather than direct public ownership of housing. She voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, and to prohibit anti-competitive rental practices including algorithmic pricing devices. She voted against temporarily removing income requirements from the system development charge exemption for homeownership units.',
 ARRAY['https://www.portland.gov/council/districts/2/elana-pirtle-guiney/votes?council_document=Affordable+Housing']),

-- Sameer Kanal (no pronouns published) -- Yea on all four
('dc00f7c1-54d1-46d8-8b35-545abdd38d8d', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Kanal backs targeted subsidy and fee relief for affordable housing rather than direct public ownership. Kanal voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, to prohibit anti-competitive rental practices including algorithmic pricing devices, and to extend system development charge exemptions for affordable housing developments.',
 ARRAY['https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=Affordable+Housing']),

-- Angelita Morillo (She/They) -- Yea on all four
('c6799d98-362a-4e27-b7c5-be45a82a150f', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Morillo backs targeted subsidy and fee relief for affordable housing rather than direct public ownership. She voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, to prohibit anti-competitive rental practices including algorithmic pricing devices, and to extend system development charge exemptions for affordable housing developments.',
 ARRAY['https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=Affordable+Housing']),

-- Steve Novick (He/Him) -- absent on 2025-045, so not credited with it
('c9e19031-259e-4133-b5d9-96cf1a5f31ff', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Novick backs targeted subsidy and fee relief for affordable housing rather than direct public ownership. He voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, and to extend system development charge exemptions for affordable housing developments.',
 ARRAY['https://www.portland.gov/council/districts/3/steve-novick/votes?council_document=Affordable+Housing']),

-- Tiffany Koyama Lane (She/Her) -- Nay on 2026-205, stated but not interpreted
('2947c92f-fee2-46e4-b472-9fd89a8f0f65', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Koyama Lane backs public subsidy and regulation of rental practices rather than direct public ownership of housing. She voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, and to prohibit anti-competitive rental practices including algorithmic pricing devices. She voted against temporarily removing income requirements from the system development charge exemption for homeownership units.',
 ARRAY['https://www.portland.gov/council/districts/3/tiffany-koyama-lane/votes?council_document=Affordable+Housing']),

-- Eric Zimmerman (He/Him) -- absent on 2025-045; Nay on 2026-205
('1518349b-3d63-49d0-9411-be19f86a7ea7', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Zimmerman backs subsidy for affordable housing projects while being more cautious about waiving development fees. He voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development and to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map. He voted against temporarily removing income requirements from the system development charge exemption for homeownership units.',
 ARRAY['https://www.portland.gov/council/districts/4/eric-zimmerman/votes?council_document=Affordable+Housing']),

-- Mitch Green (He/Him) -- Yea on all four
('acc73d7e-6522-40a9-bbe0-17cf56a96466', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Green backs targeted subsidy and fee relief for affordable housing rather than direct public ownership. He voted to appropriate $7 million in federal Housing and Urban Development grants for the Barbur Apartments affordable housing development, to adopt the Affordable Housing Opportunities Project amendments to Portland''s Comprehensive Plan and Zoning Map, to prohibit anti-competitive rental practices including algorithmic pricing devices, and to extend system development charge exemptions for affordable housing developments.',
 ARRAY['https://www.portland.gov/council/districts/4/mitch-green/votes?council_document=Affordable+Housing']),

-- Keith Wilson (He/Him, mayor -- votes only to break ties, so sourced to his published agenda)
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Wilson''s published housing agenda relies on targeted subsidy and fee relief rather than direct public ownership. It credits Portland''s affordable housing stock to Housing Bureau funding alongside the City''s Inclusionary Housing Program and tax and development fee exemption programs, sets a goal of cutting the affordable housing vacancy rate to 5.4 percent or lower, and pilots 250 affordable Home Share rooms to make better use of existing housing.',
 ARRAY['https://www.portland.gov/promise/about-portlands-promise/housing']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT politician_id, topic_id, 3
  FROM inform.politician_context
 WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
   AND politician_id IN ('c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                         '60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                         'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                         'c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65',
                         '1518349b-3d63-49d0-9411-be19f86a7ea7','acc73d7e-6522-40a9-bbe0-17cf56a96466',
                         'bd39d61e-3040-4ec1-815e-df16b1f9a8a0');

DO $$
DECLARE v_ctx int; v_ans int; v_chair int; v_orphan int; v_empty int; v_prose int; v_kanal int;
  ids uuid[] := ARRAY['c5db367e-9403-4a88-a95f-bf864279e13b','14ebbd1c-597e-483a-a846-73a7aca54ed2',
                      '60fa9870-d984-46a7-a6ed-5f6fbebe72ce','987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
                      'dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c6799d98-362a-4e27-b7c5-be45a82a150f',
                      'c9e19031-259e-4133-b5d9-96cf1a5f31ff','2947c92f-fee2-46e4-b472-9fd89a8f0f65',
                      '1518349b-3d63-49d0-9411-be19f86a7ea7','acc73d7e-6522-40a9-bbe0-17cf56a96466',
                      'bd39d61e-3040-4ec1-815e-df16b1f9a8a0']::uuid[];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND politician_id = ANY(ids);
  IF v_ctx <> 11 THEN RAISE EXCEPTION 'expected 11 context rows, found %', v_ctx; END IF;

  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND politician_id = ANY(ids);
  IF v_ans <> 11 THEN RAISE EXCEPTION 'expected 11 answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_chair FROM inform.politician_answers
   WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND value = 3 AND politician_id = ANY(ids);
  IF v_chair <> 11 THEN RAISE EXCEPTION 'expected all 11 chairs = 3, found %', v_chair; END IF;

  -- Kanal must carry no inferred pronoun in ANY of his rows
  SELECT count(*) INTO v_kanal FROM inform.politician_context
   WHERE politician_id='dc00f7c1-54d1-46d8-8b35-545abdd38d8d' AND reasoning ~* '\m(he|him|his|she|her|hers)\M';
  IF v_kanal <> 0 THEN RAISE EXCEPTION '% Kanal rows carry a gendered pronoun', v_kanal; END IF;

  -- scoped to these politicians, never to the topic: Affordable Housing is a national topic and much
  -- of the pre-existing corpus legitimately fails these shapes (mig 1610 lesson)
  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pa.politician_id IS NULL AND pc.topic_id='669cac97-66a6-4087-b036-936fbe62efb3'
     AND pc.politician_id = ANY(ids);
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND (sources IS NULL OR cardinality(sources)=0)
     AND politician_id = ANY(ids);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND reasoning ~ 'https?://'
     AND politician_id = ANY(ids);
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
