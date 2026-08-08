-- 1613: Rent Regulation x4 and the rest of Keith Wilson's owed rows.
--
-- 7 INSERTs. Two owed rows are deliberately NOT restored -- see "NOT INSERTED" below.
--
-- ================================= RENT REGULATION (chair 2 x4) ==============================
-- Six rows were owed. The ENTIRE rent-regulation record of this council is ONE document:
--   2025-045  Amend Affordable Housing Code to prohibit anti-competitive rental practices
--             including the sale and use of algorithmic devices  (Nov 20, 2025)
-- Searched eviction / rental / Rental Services / tenant / security deposit / anti-competitive /
-- Housing Code across all five councilors: nothing else on topic exists in their terms.
--
-- Avalos, Smith, Kanal and Morillo voted Yea and are chaired 2 -- "strengthen existing rent
-- stabilization and extend coverage to more units". They added a rent regulation that Dan Ryan
-- declined: Ryan voted Nay and was chaired 3 in migration 1608 ("maintain current tenant protections"),
-- so placing the Yea voters at 2 is what makes that vote carry information. Chairing them 3 as well
-- would make the only on-topic vote in the record mean nothing.
-- ⚠ Thin, and said plainly: one vote is a narrow base for a five-point scale. It is nonetheless a
-- real, named, directly on-topic roll call, which is the standard -- "verified absent -> retire", not
-- "thin -> retire".
-- ⚠ Context deliberately NOT built into any chair: Oregon caps rent statewide under SB 608 (2019), so
-- a Portland councilor cannot vote for local rent caps. That explains why the local lever looks like
-- this; it is not evidence about any individual and is not cited.
--
-- ================================== KEITH WILSON x3 =========================================
-- The mayor votes only to break ties (1 vote on file), so all three rest on his published positions.
--
-- Criminalization of Homelessness, chair 3 (retired 4). Portland's Public Camping Ordinance
-- "prohibits camping in public spaces WHEN PEOPLE HAVE ACCESS TO REASONABLE ALTERNATE SHELTER";
-- officers "may issue a citation" and "will not be arresting individuals for violation of the
-- ordinance"; the Mayor's office has given guidance that people "should be referred to resources
-- (shelter, detox, etc.) whenever possible". That is chair 3 almost verbatim -- "allowing enforcement
-- only when adequate shelter beds are available, with citations diverting people to services rather
-- than the criminal justice system" -- and it is paired with 1,500 overnight shelter beds. The retired
-- chair 4 ("prohibiting encampments with graduated warnings and penalties") overstated it.
--
-- Local Immigration Enforcement, chair 1 (retired 2). Wilson is the FIRST SIGNATORY of the City
-- Leaders statement committing to "uphold our sanctuary values using every lawful tool", and the
-- sanctuary regime he is committing to is Code Ch. 23.20, which bars detention agreements with
-- federal immigration authorities and bars collecting or disclosing immigration status. Same chair as
-- the nine councilors in migs 1608/1610, on his own signature rather than on a vote.
-- ⚠ A signed statement is a personal commitment; a City accomplishments page is not. The
-- federal-resource hub is not cited for that reason.
--
-- Transportation Priorities, chair 1 (retired 2). ⚠ THIS IS THE JUDGMENT CALL IN THIS MIGRATION.
-- His published goals set a moonshot that Portland "leads nation as America's highest bike mode city
-- by 2030", commit to Vision Zero and to cleaning streets, sidewalks and bike lanes, and contain NO
-- road-capacity or parking goal at all. Chair 1's lead clause -- "prioritize pedestrian
-- infrastructure, cycling networks, and public transit" -- is squarely evidenced. Chair 1 also
-- mentions reducing parking requirements communitywide, which he does NOT say, so that is not claimed
-- in the reasoning (cite what the page says, not what the chair says).
-- ⚠ Note this is a HIGHER chair than Novick's 2 in mig 1608, deliberately: Novick's record balances
-- road maintenance funding against multimodal safety, while Wilson's agenda states a bike-mode
-- leadership goal and no road-capacity goal. Different evidence, different chair.
--
-- ================================ NOT INSERTED (2 rows) =====================================
-- 🔴 Steve Novick / Rent Regulation -- he was ABSENT for 2025-045, the only rent vote in the record,
--    so there is no evidence of his position at all. Not restored. This is the same standard that
--    retired Smith's Homelessness row in mig 1608: an absence is not a position.
-- 🔴 Keith Wilson / Rent Regulation -- no attributable source. His agenda pages score tenant 0,
--    eviction 0, landlord 0 and rent 1 (incidental). The homeless-crisis page does mention an
--    eviction defense program serving 3,800 families, but that is a CITY accomplishment listed
--    alongside work from 2021 onward, predating his term -- attributing it to Wilson would repeat the
--    "unanimously approved is not per-member evidence" error.
--
-- All 9 citations were fetched and asserted to carry their claim terms before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (
     ('c5db367e-9403-4a88-a95f-bf864279e13b','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
     ('e6682850-601f-4017-b4e7-d9cd4be47aea','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
     ('dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
     ('c6799d98-362a-4e27-b7c5-be45a82a150f','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
     ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','4938766b-b45a-46e3-93bd-b8b30651271a'),
     ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
     ('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','ba59337e-30e2-4aba-a39a-426b3366eb27'));
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing rows, found %', v_existing; END IF;
END $$;

-- ---- Rent Regulation, chair 2 ----
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('c5db367e-9403-4a88-a95f-bf864279e13b', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 'Avalos voted to add a new limit on how landlords set rents. In November 2025 she supported amending Portland''s Affordable Housing Code to prohibit anti-competitive rental practices, including the sale and use of algorithmic pricing devices that let landlords coordinate rents.',
 ARRAY['https://www.portland.gov/council/districts/1/candace-avalos/votes?council_document=anti-competitive']),
('e6682850-601f-4017-b4e7-d9cd4be47aea', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 'Smith voted to add a new limit on how landlords set rents. In November 2025 she supported amending Portland''s Affordable Housing Code to prohibit anti-competitive rental practices, including the sale and use of algorithmic pricing devices that let landlords coordinate rents.',
 ARRAY['https://www.portland.gov/council/districts/1/loretta-smith/votes?council_document=anti-competitive']),
('dc00f7c1-54d1-46d8-8b35-545abdd38d8d', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 'Kanal voted to add a new limit on how landlords set rents, supporting a November 2025 amendment to Portland''s Affordable Housing Code that prohibits anti-competitive rental practices, including the sale and use of algorithmic pricing devices that let landlords coordinate rents.',
 ARRAY['https://www.portland.gov/council/districts/2/sameer-kanal/votes?council_document=anti-competitive']),
('c6799d98-362a-4e27-b7c5-be45a82a150f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 'Morillo voted to add a new limit on how landlords set rents. In November 2025 she supported amending Portland''s Affordable Housing Code to prohibit anti-competitive rental practices, including the sale and use of algorithmic pricing devices that let landlords coordinate rents.',
 ARRAY['https://www.portland.gov/council/districts/3/angelita-morillo/votes?council_document=anti-competitive']),

-- ---- Keith Wilson ----
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0', '4938766b-b45a-46e3-93bd-b8b30651271a',
 'Wilson enforces Portland''s camping rules only where shelter is genuinely available, and through citations rather than arrests. The City''s Public Camping Ordinance prohibits camping in public spaces when people have access to reasonable alternate shelter or decline an offer of it; officers may issue a citation but are not arresting people for violating the ordinance, and the Mayor''s office has directed that people be referred to shelter, detox and other resources whenever possible. Enforcement resumed in November 2025 alongside overnight shelters with a total capacity of 1,500 beds.',
 ARRAY['https://www.portland.gov/sscc/camping-ordinance',
       'https://www.portland.gov/homeless/homeless-crisis']),
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
 'Wilson is the first signatory of a City leaders'' statement pledging to uphold Portland''s sanctuary values using every lawful tool and denouncing intensified federal immigration enforcement. The sanctuary code he is committing to bars City facilities, money, equipment and personnel from being used to investigate or detain people for federal immigration enforcement, bars any agreement with a federal immigration authority relating to detention, and bars collecting or disclosing a person''s immigration or citizenship status for enforcement purposes except where a court order or warrant requires it.',
 ARRAY['https://www.portland.gov/hello/news/2026/7/21/city-leaders-we-stand-our-immigrant-neighbors',
       'https://www.portland.gov/code/23/20']),
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
 'Wilson''s published transportation goals put cycling, walking and street safety first. He sets a goal for Portland to lead the nation in bike mode share by 2030, commits to Portland''s Vision Zero target of cutting traffic deaths to their lowest level in a decade by rebuilding the streets and intersections where most serious crashes happen, and pledges to clear and maintain 20,000 miles of streets, sidewalks and bike lanes. His published goals set no road-capacity target.',
 ARRAY['https://www.portland.gov/promise/about-portlands-promise/public-health-and-safety']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('c5db367e-9403-4a88-a95f-bf864279e13b','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
('e6682850-601f-4017-b4e7-d9cd4be47aea','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
('dc00f7c1-54d1-46d8-8b35-545abdd38d8d','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
('c6799d98-362a-4e27-b7c5-be45a82a150f','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','4938766b-b45a-46e3-93bd-b8b30651271a',3),
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','b9ccee94-ad96-4f10-b655-889d8e5abe92',1),
('bd39d61e-3040-4ec1-815e-df16b1f9a8a0','ba59337e-30e2-4aba-a39a-426b3366eb27',1);

DO $$
DECLARE v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int; v_kanal int; v_novick int; v_wrent int;
  pairs text[] := ARRAY[
    'c5db367e-9403-4a88-a95f-bf864279e13b|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'e6682850-601f-4017-b4e7-d9cd4be47aea|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'dc00f7c1-54d1-46d8-8b35-545abdd38d8d|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'c6799d98-362a-4e27-b7c5-be45a82a150f|c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'bd39d61e-3040-4ec1-815e-df16b1f9a8a0|4938766b-b45a-46e3-93bd-b8b30651271a',
    'bd39d61e-3040-4ec1-815e-df16b1f9a8a0|b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'bd39d61e-3040-4ec1-815e-df16b1f9a8a0|ba59337e-30e2-4aba-a39a-426b3366eb27'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(pairs);
  IF v_ctx <> 7 THEN RAISE EXCEPTION 'expected 7 context rows, found %', v_ctx; END IF;
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(pairs);
  IF v_ans <> 7 THEN RAISE EXCEPTION 'expected 7 answer rows, found %', v_ans; END IF;

  -- the two deliberately-unrestored rows must still be absent
  SELECT count(*) INTO v_novick FROM inform.politician_context
   WHERE politician_id='c9e19031-259e-4133-b5d9-96cf1a5f31ff' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v_novick <> 0 THEN RAISE EXCEPTION 'Novick rent row should not exist'; END IF;
  SELECT count(*) INTO v_wrent FROM inform.politician_context
   WHERE politician_id='bd39d61e-3040-4ec1-815e-df16b1f9a8a0' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF v_wrent <> 0 THEN RAISE EXCEPTION 'Wilson rent row should not exist'; END IF;

  SELECT count(*) INTO v_kanal FROM inform.politician_context
   WHERE politician_id='dc00f7c1-54d1-46d8-8b35-545abdd38d8d' AND reasoning ~* '\m(he|him|his|she|her|hers)\M';
  IF v_kanal <> 0 THEN RAISE EXCEPTION '% Kanal rows carry a gendered pronoun', v_kanal; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id::text||'|'||pc.topic_id::text = ANY(pairs) AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;
  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs) AND (sources IS NULL OR cardinality(sources)=0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;
  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(pairs) AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;
END $$;

COMMIT;
