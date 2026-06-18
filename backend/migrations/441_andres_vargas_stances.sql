-- ============================================================================
-- Migration 441: Andres X. Vargas Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Andres X. Vargas (MA State Rep, HD-26,
--   3rd Essex District, Haverhill).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 19b7c45b-57a7-468c-9762-82b926080646 (external_id=-210066)

BEGIN;

-- ----- Andres X. Vargas / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Vargas co-sponsored H.96 relative to the use of biometric recognition technology and H.97 on consumers' interactions with artificial intelligence systems. He also co-sponsored H.103 to establish the Massachusetts Neural Data Privacy Protection Act and H.104 to establish the Massachusetts Data Privacy Act. This legislative portfolio of four AI and data privacy bills demonstrates a consistent pro-regulation stance on AI and emerging technologies.$$,
        ARRAY['https://malegislature.gov/Bills/194/H96', 'https://malegislature.gov/Bills/194/H97', 'https://malegislature.gov/Bills/194/H103', 'https://malegislature.gov/Bills/194/H104']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Vargas co-sponsored the Safe Communities Act as tracked by Act on Mass, a Massachusetts sanctuary bill that would limit state and local law enforcement from assisting with federal immigration enforcement. This is a primary position bill with direct immigration policy impact, reflecting a strong pro-immigrant protection stance.$$,
        ARRAY['https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Legislators/Profile/AXV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Vargas co-sponsored both the 100% Renewable Energy by 2045 bill and the Environmental Justice bill as tracked by Act on Mass. He also co-sponsored the THRIVE Act which includes climate provisions. His committee role as Vice-chair of the Joint Committee on Economic Development and Emerging Technologies positions him at the intersection of clean energy and economic transition.$$,
        ARRAY['https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Legislators/Profile/AXV1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Vargas co-sponsored Medicare for All and Overdose Prevention Centers legislation as tracked by Act on Mass. He also sponsored H.1337 relative to opioid use disorder treatment and rehabilitation, H.2551 to direct the Department of Public Health to establish a registry of volunteer healthcare personnel, and the Cherish Act for fully funded higher education. He serves on the Joint Committee on Public Health, reflecting a legislative focus on expanded public health coverage.$$,
        ARRAY['https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Bills/194/H1337', 'https://malegislature.gov/Bills/194/H2551']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Vargas co-sponsored the Healthy Youth Act (LGBTQ+ inclusive sex education) as tracked by Act on Mass. He sponsored H.2030 relative to structural racism in the parole process, H.1811 relative to automated record sealing, H.2028 on juvenile justice data collection, and H.2029 to eliminate standard conditions in probation. His extensive criminal justice reform legislation targeting racial disparities reflects a strong civil rights focus.$$,
        ARRAY['https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Bills/194/H2030', 'https://malegislature.gov/Bills/194/H1811', 'https://malegislature.gov/Bills/194/H2028']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Vargas co-sponsored H.1572 for legislation to increase housing development, H.2347 on zoning ordinances for religious-owned land with multifamily housing, and H.2348 directing the Executive Office of Housing and Livable Communities to regulate exclusionary zoning. He also filed a bill on ADU zoning. This housing package reflects strong support for expanded housing access through zoning reform and anti-exclusionary measures.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1572', 'https://malegislature.gov/Bills/194/H2347', 'https://malegislature.gov/Bills/194/H2348']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Vargas serves as Vice-chair of the Joint Committee on Economic Development and Emerging Technologies. He co-sponsored the Right to Unionize for Ride Share Drivers bill (Act on Mass) and sponsored H.312 on microbusiness and small business assistance transparency, and H.2185 on wages and benefits for employees of public institutions of higher education. His economic development focus emphasizes worker rights, small business support, and clean technology transition.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AXV1/Committees', 'https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Bills/194/H312']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Vargas co-sponsored Progressive Revenue legislation as tracked by Act on Mass, which supports raising taxes on high-income earners and corporations to fund public services. He also serves on the House Committee on Ways and Means, a budget committee where revenue policy is shaped. His progressive revenue co-sponsorship reflects support for higher taxes on wealthy individuals and corporations to fund public goods.$$,
        ARRAY['https://actonmass.org/legislators/andres-vargas/', 'https://malegislature.gov/Legislators/Profile/AXV1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andres X. Vargas / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('19b7c45b-57a7-468c-9762-82b926080646',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Vargas sponsored H.876 relative to the post-election audit process, co-sponsored with Sen. Bruce Tarr, which would establish or improve audit procedures for Massachusetts elections — reflecting a bipartisan concern for election integrity. This bill addresses election transparency through auditing, a voting rights and election administration priority.$$,
        ARRAY['https://malegislature.gov/Bills/194/H876', 'https://malegislature.gov/Legislators/Profile/AXV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '19b7c45b-57a7-468c-9762-82b926080646';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '19b7c45b-57a7-468c-9762-82b926080646'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '19b7c45b-57a7-468c-9762-82b926080646'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
