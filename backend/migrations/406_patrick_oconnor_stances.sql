-- ============================================================================
-- Migration 406: Patrick M. O'Connor Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Patrick M. O'Connor (MA State Senator, 25D31,
--   First Plymouth and Norfolk District).
--   Note: Apostrophe in last name handled via dollar-quoting throughout.
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: e1f72270-5809-4d0e-969c-48d1ab34fbdc (external_id: -210031)

BEGIN;

-- ----- Patrick M. O'Connor / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$O'Connor is a Republican who has consistently supported tax reduction. He backed the 2023 tax relief package and has advocated for further income tax cuts and capital gains tax reductions. He has opposed the 2022 millionaires surtax (Question 1) arguing it harms Massachusetts competitiveness. He has filed legislation to reduce the state income tax rate and has been a consistent voice for lower taxes as part of the Republican minority caucus.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.wgbh.org/news/politics/2023-09-29/gov-healey-signs-tax-relief-package-into-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$O'Connor voted against the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. He has taken a conservative position on immigration, supporting stronger enforcement and opposing expansion of state services to undocumented residents. He has been critical of Massachusetts sanctuary policies and voted against legislation expanding benefits for immigrants regardless of immigration status. His position reflects the Republican caucus mainstream on immigration.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$O'Connor has been critical of the 2020 police reform law and has consistently supported law enforcement. He has advocated against measures he views as undermining police effectiveness and has backed increased law enforcement funding. He has been skeptical of bail reform measures and diversion programs as alternatives to prosecution of repeat offenders. His position on public safety reflects the traditional Republican law-and-order approach emphasizing consequences for criminal behavior.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$O'Connor has raised concerns about the pace and economic costs of Massachusetts climate legislation. He voted against the most ambitious provisions of the 2021 Climate Act and has criticized climate mandates that raise energy costs for residents. He has opposed building electrification requirements and has raised questions about the reliability of the grid with rapid fossil fuel retirement. His position reflects skepticism about aggressive climate timelines and their economic impact on his suburban constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$O'Connor has had a mixed record on housing. He supported the 2024 Affordable Homes Act provisions focused on production but has raised concerns about MBTA Communities zoning mandates overriding local control. His district includes suburban communities protective of single-family neighborhood character. He has been more supportive of homeownership programs and less supportive of dense multifamily development mandates, reflecting tensions between housing production needs and local zoning preferences in his suburban district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$O'Connor voted against the 2022 VOTES Act making expanded mail voting and early voting permanent, raising concerns about election security and ballot integrity. He has opposed automatic voter registration and has advocated for stricter ID requirements as conditions for voting. His position reflects the Republican caucus mainstream on election integrity issues.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$O'Connor has supported school choice and parental rights in education. He backed the 2016 Question 2 charter school expansion and has supported education savings account proposals giving families more control over educational choices. He has advocated for expanded charter school availability as an option for families in districts with underperforming public schools. His school choice position aligns with Republican education priorities of parental choice and market competition in education.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.masslive.com/politics/2016/10/question_2_charter_schools_massachusetts.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick M. O'Connor / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e1f72270-5809-4d0e-969c-48d1ab34fbdc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$O'Connor has supported restrictions on transgender athletes competing in sports aligned with their gender identity, backing legislation requiring student athletes to compete based on biological sex. He has framed this as a matter of competitive fairness in women's sports rather than discrimination. His position aligns with the Massachusetts Republican caucus on this issue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMO', 'https://www.masslive.com/politics/2023/04/massachusetts-republicans-file-bill-to-ban-transgender-athletes-from-girls-sports.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
