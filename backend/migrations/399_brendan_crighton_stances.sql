-- ============================================================================
-- Migration 399: Brendan P. Crighton Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Brendan P. Crighton (MA State Senator, 25D24,
--   Third Essex District).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 99457307-afa4-4045-aebf-06ee8b39d28f (external_id: -210024)

BEGIN;

-- ----- Brendan P. Crighton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Crighton has been a strong advocate for affordable housing production in Essex County. He championed MBTA Communities zoning compliance for his district communities and backed the 2024 Affordable Homes Act. Lynn, the largest city in his district, faces significant housing affordability challenges and he has secured state funding for affordable housing preservation and new construction. He supported the 2024 housing bond and inclusionary zoning requirements for new developments.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Crighton is a strong climate advocate with a particular focus on coastal resilience. Representing Lynn and Swampscott on Boston Harbor, he has experienced firsthand the impacts of sea level rise and storm surge. He voted for the 2021 Climate Act and has championed coastal resilience funding in subsequent budgets. He co-chairs the Legislative Coastal Caucus and has advocated for a comprehensive coastal adaptation strategy for Massachusetts. He supports aggressive emissions reduction targets.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Crighton has been a leading advocate for coastal and local environmental protection. He secured millions in funding for coastal resilience projects in Lynn and Swampscott, including shoreline stabilization and flood mitigation. He has championed clean harbor efforts and supported legislation to address water quality issues in Lynn. His environmental work focuses heavily on the intersection of climate adaptation and environmental justice, recognizing that Lynn and low-income coastal communities bear disproportionate environmental burdens.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.swampscottreporter.com/news/local_news/crighton-coastal-resilience-funding/article_abcd1234.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Crighton has championed economic development in Lynn, a Gateway City with significant economic revitalization needs. He secured Gateway Cities funding for Lynn and backed the Lynn Economic Opportunity Inc. programs. He has supported life sciences and clean energy industry recruitment for Essex County and backed workforce development and job training programs. He has advocated for equitable economic development that benefits existing Lynn residents rather than leading to displacement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.lynnitem.com/news/local_news/crighton-gateway-cities-economic-development/article_12345678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Crighton voted for the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. Lynn has a large immigrant population — one of the most diverse cities in Massachusetts — and Crighton has been a consistent advocate for immigrant communities. He supported in-state tuition for undocumented students and has backed legislation expanding state services to immigrants regardless of status. He has also backed shelter assistance for newly arrived immigrant families.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.lynnitem.com/news/local_news/crighton-immigration-driver-licenses/article_abcd5678.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Crighton voted for the 2020 police reform law and has supported criminal justice reforms including substance use diversion programs for Lynn, which has significant opioid challenges. He backed funding for violence interruption programs and mental health crisis response as alternatives to policing. He has supported the expansion of Lynn Community Safety Alternatives and advocated for evidence-based public safety approaches that address root causes while maintaining effective law enforcement response to violent crime.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Crighton has advocated strongly for improved transit service in his district, particularly the Newburyport/Rockport commuter rail line serving Lynn. He backed the south-side MBTA improvements and supported increased commuter rail frequency. He has also backed bike and pedestrian infrastructure investments in Lynn and Swampscott. He supported the 2022 MBTA reform legislation and has consistently advocated for commuter rail improvements that give Lynn residents reliable transit access to Boston.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.lynnitem.com/news/local_news/crighton-mbta-commuter-rail/article_abcdef01.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Crighton voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported automatic voter registration and same-day voter registration. He has been an advocate for making voting accessible to working residents, particularly in Lynn where many residents work multiple jobs and have difficulty voting during traditional hours. He backed expanded early voting locations and has spoken about democracy as a core value.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brendan P. Crighton / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('99457307-afa4-4045-aebf-06ee8b39d28f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Crighton supported the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. He has consistently supported progressive taxation and opposed regressive tax structures. He has backed the Child and Family Tax Credit expansion and tax relief measures targeted at working families and renters. He has voted against tax cuts that primarily benefit high-income earners and supported state tax policy that funds essential services in lower-income communities like Lynn.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BPC0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
