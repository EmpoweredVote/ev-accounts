-- ============================================================================
-- Migration 401: Sal N. DiDomenico Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sal N. DiDomenico (MA State Senator, 25D26,
--   Middlesex and Suffolk District — Everett, Cambridge, parts of Somerville).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: c7e94dda-1862-40fe-bda5-5fa2fe68f536 (external_id: -210026)

BEGIN;

-- ----- Sal N. DiDomenico / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$DiDomenico has been one of the leading champions of early childhood education and childcare in the Massachusetts legislature. As Senate Chair of the Joint Committee on Children, Families and Persons with Disabilities, he has championed major investments in early education. He co-chaired the Early Education and Care Economic Review Commission and has backed legislation to dramatically increase childcare worker compensation and expand subsidized childcare access. He supported the major early education investment in the FY2024 budget.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://www.wbur.org/news/2023/07/31/massachusetts-childcare-funding-budget']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$DiDomenico has supported affordable housing production in his district, which includes Everett and parts of Cambridge and Somerville — all cities with significant housing affordability pressures. He voted for the 2024 Affordable Homes Act and has backed MBTA Communities zoning compliance. He has supported state funding for affordable housing preservation and new construction in Everett, which has seen rapid development pressure in recent years.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$DiDomenico has been a strong healthcare access advocate, particularly for children and families. His work on the Children, Families and Persons with Disabilities committee has included championing mental health services for children and expanding pediatric healthcare coverage. He supported the 2022 mental health parity law and has backed legislation improving access to behavioral health services. He has consistently voted for MassHealth expansion and healthcare access measures.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$DiDomenico voted for the 2021 MA Climate Act and has supported subsequent clean energy legislation. His district includes Everett, which historically has had significant industrial pollution and environmental justice concerns. He has backed climate justice provisions ensuring environmental benefits reach low-income communities. He supported offshore wind procurement and building electrification policies.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$DiDomenico voted for the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. His district includes significant immigrant communities in Everett and Cambridge. He has supported in-state tuition for undocumented students and backed immigrant services funding in the state budget. He has generally supported policies expanding access for immigrant residents though his profile on immigration is not as central as senators representing more impacted communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$DiDomenico voted for the 2020 police reform law and has supported criminal justice reforms. His work on children and families issues extends to juvenile justice reform, where he has advocated for alternatives to detention and rehabilitative approaches for youth. He has supported funding for youth violence prevention programs in Everett. His approach balances support for effective policing with reform measures and prevention investments.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$DiDomenico supported the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. He has consistently backed progressive taxation and supported the Child and Family Tax Credit expansion. His budget priorities focus on early education and childcare funding, and he has supported tax policy that generates revenue for those programs. He has voted for budgets that invest heavily in social services funded through progressive revenue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SND0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sal N. DiDomenico / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7e94dda-1862-40fe-bda5-5fa2fe68f536',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$DiDomenico voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported measures to make voting more accessible and has backed automatic voter registration proposals. His consistent Democratic voting record includes support for all major voting access expansions passed by the Senate.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
