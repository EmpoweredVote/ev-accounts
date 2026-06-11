-- ============================================================================
-- Migration 411: Kelly A. Dooner Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kelly A. Dooner (MA State Senator, 25D36,
--   Third Bristol and Plymouth District -- Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 247cf8e5-426a-4104-9027-6a2a0b1b61c9 (external_id: -210036)

BEGIN;

-- ----- Kelly A. Dooner / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Dooner has supported tax reduction as a Republican. She backed the 2023 tax relief package and has advocated for further income tax reductions. She opposed the 2022 millionaires surtax (Question 1) arguing it would harm Massachusetts competitiveness. She has consistently voted with the Republican caucus for lower taxes and reduced government spending, reflecting her constituents in the Bristol-Plymouth region who prioritize tax relief.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://www.wgbh.org/news/politics/2023-09-29/gov-healey-signs-tax-relief-package-into-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Dooner voted against the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. She has taken a conservative position on immigration, supporting stronger enforcement and opposing expansion of benefits to undocumented residents. She has been critical of Massachusetts sanctuary policies and has voted against legislation expanding access to state services for immigrants. Her position reflects the Republican caucus mainstream on immigration enforcement.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Dooner has been a strong supporter of law enforcement and has been critical of the 2020 police reform law. She has backed increased public safety funding and opposed measures she views as undermining police effectiveness. She has been skeptical of bail reform and diversion programs as alternatives to prosecution and has advocated for accountability for repeat offenders. Her public safety positions align with the traditional Republican law-and-order approach.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Dooner has raised significant concerns about Massachusetts climate mandates and their economic impact on residents. She has been critical of energy costs associated with the climate transition and opposed building electrification requirements. She has voted against climate legislation she views as placing excessive burdens on ratepayers and businesses. She supports energy independence but has been skeptical of aggressive state climate mandates.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Dooner has had a mixed record on housing. She opposed MBTA Communities zoning mandates that she views as overriding local control, reflecting the position of many suburban Republican legislators protective of single-family zoning. She has supported production-focused housing policies while opposing state mandates requiring municipalities to increase density. Her suburban district communities value local control over zoning decisions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://commonwealthbeacon.org/housing/mbta-communities-act-debate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Dooner voted against the 2022 VOTES Act making expanded mail voting and early voting permanent. She raised concerns about election integrity and ballot security and has advocated for stricter voter identification requirements. She opposed automatic voter registration without adequate identity verification. Her position reflects the Republican caucus mainstream on voting access, prioritizing security over expanded access measures.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kelly A. Dooner / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('247cf8e5-426a-4104-9027-6a2a0b1b61c9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Dooner has supported restrictions on transgender athletes competing in sports aligned with their gender identity, backing legislation requiring athletes to compete based on biological sex. She has framed this as protecting competitive fairness in women's sports. Her position aligns with the Massachusetts Republican caucus on transgender athlete policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KAD0', 'https://www.masslive.com/politics/2023/04/massachusetts-republicans-file-bill-to-ban-transgender-athletes-from-girls-sports.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '247cf8e5-426a-4104-9027-6a2a0b1b61c9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
