-- ============================================================================
-- Migration 405: Nick Collins Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Nick Collins (MA State Senator, 25D30,
--   First Suffolk District — South Boston, South End, parts of Dorchester).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 2c53dc2c-38ae-4f39-873d-9ea1841b1c4c (external_id: -210030)

BEGIN;

-- ----- Nick Collins / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Collins has supported affordable housing production and has been engaged with major development projects in South Boston and the South End. He supported the 2024 Affordable Homes Act and has backed MBTA Communities zoning requirements. South Boston has experienced dramatic gentrification and he has navigated between promoting development and protecting long-time residents. He has backed inclusionary zoning requirements and affordable unit mandates in new development in his district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Collins has been an active economic development advocate for his district, which includes South Boston, South End, and parts of Dorchester. He has supported major development projects including Seaport District expansion and has backed job creation and economic investment initiatives. He has supported small business assistance programs and workforce development. His district includes both the rapidly developing Innovation District and longer-established residential neighborhoods.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://www.bostonglobe.com/2022/11/08/metro/nick-collins-south-boston-state-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Collins voted for the 2021 Climate Act and has supported offshore wind development and clean energy investment. South Boston and the South End are coastal neighborhoods vulnerable to sea level rise, and he has backed coastal resilience funding. He has supported clean energy programs and building electrification measures. His climate record is consistent with the Democratic mainstream, though coastal resilience has been his primary emphasis given his district geography.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Collins voted for the 2020 police reform law but has taken a relatively centrist Democratic position on public safety. South Boston has historically been a neighborhood with a strong relationship with law enforcement, and he has balanced supporting police accountability measures with maintaining strong public safety funding. He has supported violence prevention programs and mental health services but has been more cautious on the most far-reaching criminal justice reforms compared to his more progressive colleagues.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Collins voted for the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. His district includes parts of Dorchester with significant immigrant communities. He has generally voted with the Democratic caucus on immigration-related legislation, including in-state tuition for undocumented students and expanding access to state services for immigrants.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Collins supported the 2023 tax relief package and the 2022 millionaires surtax. His tax record reflects his district demographics in South Boston and the South End — a mix of working-class residents and higher-income professionals who have moved in as the neighborhoods gentrified. He has backed targeted tax relief including the rental deduction increase and the Child and Family Tax Credit while supporting the progressive surtax on high earners.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://www.wgbh.org/news/politics/2023-09-29/gov-healey-signs-tax-relief-package-into-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Nick Collins / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Collins has supported transit improvements for his district, including Red Line service improvements and Silver Line BRT enhancements. He backed the 2022 MBTA reform legislation and has supported increasing MBTA capital funding. South Boston has become increasingly transit-accessible and he has backed transit and active transportation investments. He has also supported road infrastructure and parking management given his district includes both transit-rich and car-dependent areas.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/N_C0', 'https://www.wbur.org/news/2022/06/10/mbta-reform-legislation-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
