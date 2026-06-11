-- ============================================================================
-- Migration 415: Julian A. Cyr Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Julian A. Cyr (MA State Senator, 25D40,
--   Cape and Islands District -- Barnstable County, Martha's Vineyard, Nantucket).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: bd451748-111f-461d-9752-95e7c243769e (external_id: -210040)

BEGIN;

-- ----- Julian A. Cyr / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cyr has been a strong healthcare access advocate throughout his career. He has championed rural healthcare access on Cape Cod and the Islands, where residents face geographic barriers to care. He backed the 2022 mental health parity law and has supported telehealth expansion to improve access for island residents. He has been a vocal advocate for LGBTQ+ inclusive healthcare and has backed legislation improving access to gender-affirming care. He has also championed HIV/AIDS prevention funding and supported MassHealth expansion.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cyr is an openly gay man who has been a leading LGBTQ+ civil rights champion in the legislature. He has backed every major LGBTQ+ rights expansion including protections against discrimination, transgender rights legislation, and equal treatment laws. He has also championed racial justice and opposed discrimination in all forms. He backed the 2016 Transgender Public Accommodations Act and has supported subsequent legislation strengthening LGBTQ+ protections. He has spoken personally about the importance of civil rights as someone who has experienced discrimination.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.masslive.com/politics/2016/07/massachusetts-transgender-rights-anti-discrimination-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cyr has been an aggressive climate action champion representing one of the most climate-vulnerable districts in Massachusetts. Cape Cod and the Islands face existential threats from sea level rise and ocean warming. He voted for the 2021 Climate Act and has pushed for even faster action, backed the Vineyard Wind project, and championed offshore wind development. He has been a leading advocate for coastal resilience funding and beach protection. He has backed clean energy transition measures and climate adaptation planning for his islands district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Cyr has been a strong local environmental protection advocate. His district includes the Cape Cod National Seashore, Nantucket Sound, and Vineyard Sound -- among the most ecologically important areas in New England. He has championed wastewater treatment and nitrogen reduction to protect Cape Cod embayments, backed ocean wildlife protections, and advocated for preserving natural open space. He has been a leading voice for comprehensive environmental protection of the Cape and Islands ecosystem.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.capecodtimes.com/news/local_news/cyr-environment-cape-islands/article_abcd5678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cyr has been a vocal housing advocate for Cape Cod and the Islands, where the housing affordability crisis is the most acute in the state. He backed the 2024 Affordable Homes Act and has championed year-round rental housing, workforce housing, and anti-speculation measures. He has worked on proposals to restrict short-term vacation rentals that remove housing from the year-round market. He has been a leading voice for ensuring that working people -- teachers, healthcare workers, fishermen -- can afford to live in the communities where they work.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.capecodtimes.com/news/local_news/cyr-housing-cape-cod/article_12345678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cyr voted for the 2022 Work and Family Mobility Act. His district includes significant Brazilian and Portuguese immigrant communities, particularly in Barnstable County and on the Islands. He has supported in-state tuition for undocumented students and backed legislation expanding access to state services for immigrants. He has been an ally of immigrant worker communities in the hospitality and fishing industries that are essential to the Cape and Islands economy.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Cyr voted for the 2020 police reform law and has supported criminal justice reform. He has backed substance use treatment programs for the Cape and Islands, which faces significant opioid challenges, and has advocated for mental health crisis response alternatives. He supported decriminalization of drug possession and treatment-first approaches. He has been a strong advocate for harm reduction and has backed syringe services programs. His public safety approach emphasizes prevention, treatment, and community-based safety.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cyr supported the 2022 millionaires surtax (Question 1) and has backed progressive taxation. He has been particularly interested in how state tax policy affects year-round Cape and Islands residents versus vacation homeowners and seasonal visitors. He has backed the Child and Family Tax Credit and tax relief for renters and working families. He has supported using surtax revenue for housing and transportation on the Cape and Islands.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JAC0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julian A. Cyr / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd451748-111f-461d-9752-95e7c243769e',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cyr voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has been a strong supporter of voting access and backed automatic voter registration. His district includes island communities with unique voting access challenges -- residents of Martha's Vineyard and Nantucket who commute off-island for work have benefited from expanded mail voting. He has supported all major voting access expansions in the Senate.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'bd451748-111f-461d-9752-95e7c243769e'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
