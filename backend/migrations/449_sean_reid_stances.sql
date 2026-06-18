-- ============================================================================
-- Migration 449: Sean Reid Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sean Reid (MA State Rep, HD-34,
--   11th Essex District, Lynn/Nahant).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 444ac209-7bfa-4f3a-a733-5666fd74fd66 (external_id=-210074)

BEGIN;

-- ----- Sean Reid / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Reid serves on both the Joint Committee on Public Health and the Joint Committee on Mental Health, Substance Use and Recovery, reflecting a strong legislative focus on healthcare access. He sponsored H.1295 relative to promoting consumer choice in healthcare, H.1296 to protect 340B providers (which maintain the federal drug discount program that helps safety-net hospitals and clinics serve low-income patients), and H.3218 establishing tax credits for healthcare preceptorships (which incentivize physicians to train the next generation of medical providers in underserved areas).$$,
        ARRAY['https://malegislature.gov/Bills/194/H1295', 'https://malegislature.gov/Bills/194/H1296', 'https://malegislature.gov/Bills/194/H3218', 'https://malegislature.gov/Legislators/Profile/S_R1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Reid / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Reid sponsored H.2326 to prevent nonprofit institutions from avoiding wetlands or natural resource protections — closing a loophole that allowed nonprofits to bypass environmental review for development projects. He also sponsored H.1025 and H.1026 addressing noise issues of migratory game hunters near coastal dwellings, reflecting attention to the environmental character of his coastal district. H.4058 on HVAC safety accountability and public transparency addresses indoor air quality in public buildings.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2326', 'https://malegislature.gov/Bills/194/H1025', 'https://malegislature.gov/Bills/194/H1026', 'https://malegislature.gov/Bills/194/H4058']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Reid / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Reid sponsored H.1557 to create an office of tenant protections in Massachusetts — a significant pro-renter bill that would establish a dedicated state office to enforce tenant rights and protections. He also co-sponsored H.1474 with Rep. Daniel Cahill on affordable housing in certain municipalities. These bills reflect a pro-renter and affordable housing stance for his Lynn district, where housing affordability is a major concern.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1557', 'https://malegislature.gov/Bills/194/H1474']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Reid / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('444ac209-7bfa-4f3a-a733-5666fd74fd66',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Reid sponsored H.3895 to expand career and technical education (CTE) opportunities specifically for Lynn students — investing in workforce development infrastructure for a working-class gateway city. He also sponsored H.679 relative to student teacher pay (addressing teacher compensation to attract educators), and H.3875 establishing a veterans research trust fund. These bills reflect economic development through education and workforce investment.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3895', 'https://malegislature.gov/Bills/194/H679', 'https://malegislature.gov/Bills/194/H3875']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '444ac209-7bfa-4f3a-a733-5666fd74fd66';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '444ac209-7bfa-4f3a-a733-5666fd74fd66'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '444ac209-7bfa-4f3a-a733-5666fd74fd66'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
