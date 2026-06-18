-- ============================================================================
-- Migration 453: Ryan M. Hamilton Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Ryan M. Hamilton (MA State Rep, HD-38,
--   15th Essex District, Haverhill/Methuen).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: bdc19d3c-1169-4923-9ed9-f914b73f63e9 (external_id=-210078)

BEGIN;

-- ----- Ryan M. Hamilton / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hamilton co-sponsored the Cherish Act (fully funded public higher education including mental health support) and the THRIVE Act as tracked by Act on Mass. He also sponsored H.595 providing for mental health professionals in public schools — a direct healthcare investment in school-based mental health — and H.1165 providing for certain health insurance coverage. His combination of school mental health and insurance access bills reflects a comprehensive healthcare access priority.$$,
        ARRAY['https://actonmass.org/legislators/ryan-hamilton/', 'https://malegislature.gov/Bills/194/H595', 'https://malegislature.gov/Bills/194/H1165']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan M. Hamilton / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Hamilton co-sponsored LGBTQ+ Rights legislation as tracked by Act on Mass (green checkmark). He serves on the Joint Committee on Election Laws, which oversees voting rights and electoral access. His co-sponsorship of Voting Rights Restoration further reflects an expansive view of civil and political rights.$$,
        ARRAY['https://actonmass.org/legislators/ryan-hamilton/', 'https://malegislature.gov/Legislators/Profile/RMH2/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan M. Hamilton / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Hamilton co-sponsored Voting Rights Restoration legislation as tracked by Act on Mass (green checkmark), which would restore voting rights to incarcerated individuals in Massachusetts. He also serves on the Joint Committee on Election Laws, the legislative body responsible for voting access and election administration reform — a direct structural role in shaping voting rights policy.$$,
        ARRAY['https://actonmass.org/legislators/ryan-hamilton/', 'https://malegislature.gov/Legislators/Profile/RMH2/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan M. Hamilton / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hamilton sponsored H.1509 to promote housing cooperatives in Massachusetts — a community ownership model that allows residents to collectively own and manage their housing, creating permanently affordable housing without reliance on government subsidies. This innovative housing supply and affordability mechanism reflects a commitment to expanding affordable housing options in the Haverhill/Methuen area.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1509', 'https://malegislature.gov/Legislators/Profile/RMH2']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ryan M. Hamilton / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bdc19d3c-1169-4923-9ed9-f914b73f63e9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Hamilton serves on the Joint Committee on Labor and Workforce Development and sponsored H.2121 providing opportunities for apprentices to complete their training — directly investing in trades workforce development. He also sponsored H.2858 relative to employee rights of Massachusetts Water Resources Authority employees. His apprenticeship and labor bills reflect a worker-rights and workforce pipeline focus for a manufacturing/trades district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2121', 'https://malegislature.gov/Bills/194/H2858', 'https://malegislature.gov/Legislators/Profile/RMH2/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'bdc19d3c-1169-4923-9ed9-f914b73f63e9';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'bdc19d3c-1169-4923-9ed9-f914b73f63e9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'bdc19d3c-1169-4923-9ed9-f914b73f63e9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
