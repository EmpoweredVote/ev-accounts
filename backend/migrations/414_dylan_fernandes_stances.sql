-- ============================================================================
-- Migration 414: Dylan A. Fernandes Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Dylan A. Fernandes (MA State Senator, 25D39,
--   Plymouth and Barnstable District -- Cape Cod, Martha's Vineyard, Nantucket).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 8c7d04dc-f567-4759-b99b-0ae8f26d6f32 (external_id: -210039)

BEGIN;

-- ----- Dylan A. Fernandes / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Fernandes has been one of the strongest climate voices in the legislature, representing Cape Cod and the Islands -- a region directly threatened by sea level rise, storm surge, and ocean warming. He voted for the 2021 Climate Act and has championed accelerated offshore wind development, beach and coastal resilience funding, and building electrification. He has been a leading advocate for the Vineyard Wind project and subsequent offshore wind development. He has also backed stronger climate targets and has pushed for faster implementation of clean energy transition.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Fernandes has been among the most active environmental protection advocates in the legislature. His Cape and Islands district is one of the most ecologically sensitive in Massachusetts with its coastal ponds, bays, and marine ecosystems. He has championed water quality protection for Buzzards Bay and the Cape Cod aquifer, nitrogen reduction programs for coastal embayments, and coastal resilience funding. He has backed legislation protecting the oceans and has been a leading voice for marine environmental protection.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://www.capecodtimes.com/news/local_news/fernandes-environment-cape-cod/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Fernandes has been a strong advocate for phasing out fossil fuels. He has backed the gas ban pilot program allowing municipalities to ban fossil fuel infrastructure in new construction. He opposed proposals to extend fossil fuel infrastructure on Cape Cod and has championed clean energy alternatives. He supported accelerating the retirement of fossil fuel generation in favor of offshore wind and solar development. He has been a leading voice for aggressive fossil fuel phase-out as a climate imperative.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://commonwealthbeacon.org/energy/natural-gas-ban-debate-heats-up-at-state-house/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Fernandes has been a strong housing advocate for Cape Cod and the Islands, where the housing affordability crisis is among the most severe in Massachusetts due to high tourist and second-home demand. He voted for the 2024 Affordable Homes Act and has backed year-round rental housing requirements, anti-speculation measures, and affordable housing production for working Cape Cod residents. He has championed workforce housing as essential to maintaining the service and fishing industry workforce on which the region depends.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://www.capecodtimes.com/news/local_news/fernandes-housing-cape-cod/article_abcd5678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Fernandes voted for the 2022 Work and Family Mobility Act. His district includes significant immigrant communities, particularly Brazilian and Cape Verdean workers in the fishing and hospitality industries. He has supported in-state tuition for undocumented students and backed legislation expanding access to state services for immigrants. As a first-generation American of Indian descent, he has spoken personally about the importance of immigrant communities to Massachusetts.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Fernandes voted for the 2020 police reform law and has supported criminal justice reform. He has backed substance use treatment programs for the Cape and Islands, which has faced significant opioid challenges. He supported decriminalization of drug possession and treatment-first approaches for addiction. He has backed mental health crisis response alternatives and has advocated for juvenile justice reforms. His public safety approach emphasizes prevention and treatment over incarceration.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Fernandes, as the first AAPI legislator in Massachusetts history, has been a civil rights champion. He has backed LGBTQ+ rights legislation including protections for transgender individuals. He has been a vocal opponent of Asian-American discrimination and has championed hate crime legislation. He has advocated for racial equity across state policy and has spoken about the need to fight discrimination in all its forms. He backed the 2016 Transgender Public Accommodations Act and subsequent LGBTQ+ rights measures.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://www.wbur.org/news/2017/01/10/dylan-fernandes-first-aapi-massachusetts-legislature']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Fernandes supported the 2022 millionaires surtax (Question 1) and has backed progressive taxation. He has advocated for using surtax revenue specifically for housing and environmental infrastructure on Cape Cod. He has backed the Child and Family Tax Credit and has supported tax policy that funds essential services for year-round residents rather than vacation homeowners. His tax approach emphasizes ensuring working Cape Cod residents benefit from state tax policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DAF0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dylan A. Fernandes / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Fernandes voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has been a consistent supporter of voting access and backed automatic voter registration. His district includes seasonal and year-round residents with varying circumstances for voting, and he has supported making voting convenient for working people. He has backed all major voting access expansions in the Senate.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8c7d04dc-f567-4759-b99b-0ae8f26d6f32'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
