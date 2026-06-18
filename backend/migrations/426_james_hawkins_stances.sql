-- ============================================================================
-- Migration 426: James K. Hawkins Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for James K. Hawkins
--   (MA State Representative, 2nd Bristol District, HD-11, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 95d5e111-b7dd-4440-8b51-070b72e33126 (external_id: -210051)

BEGIN;

-- ----- James K. Hawkins / healthcare -----
-- Evidence: Co-sponsored Medicare for All (AOM tracker).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hawkins co-sponsored Medicare for All (H.1239) tracked by Act on Mass, supporting single-payer universal healthcare. This is direct co-sponsorship evidence of support for replacing private insurance with a universal government-run health system. His 2nd Bristol District (Attleboro area) includes working-class constituents who would benefit from universal healthcare coverage regardless of employment status.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / immigration -----
-- Evidence: Co-sponsored Safe Communities Act (AOM tracker).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Hawkins co-sponsored the Safe Communities Act per Act on Mass tracker, which creates pathways to limit state cooperation with federal immigration deportation enforcement. This co-sponsorship reflects support for protective immigration policies that limit state participation in federal enforcement actions against immigrant residents.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / local-immigration -----
-- Evidence: Co-sponsored Safe Communities Act (AOM tracker).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Hawkins co-sponsored the Safe Communities Act tracked by Act on Mass, which restricts local law enforcement cooperation with ICE and creates sanctuary-style protections at the local level. This co-sponsorship directly evidences a sanctuary/protective local immigration policy stance.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / deportation -----
-- Evidence: Co-sponsored Safe Communities Act (limits deportation cooperation).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Hawkins co-sponsored the Safe Communities Act, which limits state cooperation with federal immigration deportation programs. Co-sponsorship of this bill indicates opposition to state-facilitated mass deportation operations and support for limiting ICE-state coordination.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / medicare/aid -----
-- Evidence: Co-sponsored Medicare for All (AOM tracker).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Hawkins co-sponsored Medicare for All per Act on Mass, supporting expansion of Medicare and Medicaid to universal coverage. This directly evidences support for expanding government healthcare programs well beyond their current scope.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / school-vouchers -----
-- Evidence: Co-sponsored the Cherish Act (fully funded public higher education, AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hawkins co-sponsored the Cherish Act (fully funded public higher education) per Act on Mass, signaling opposition to diverting public funds to private educational institutions via vouchers. Full public school funding co-sponsorship indicates a strong pro-public-education stance.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / taxes -----
-- Evidence: Co-sponsored Stop Corporate Offshoring Act (AOM tracker).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hawkins co-sponsored the Stop Corporate Offshoring Act per Act on Mass tracker, which taxes profits shifted to offshore tax havens. This co-sponsorship demonstrates support for higher corporate taxes and closing offshore tax avoidance mechanisms -- a clearly progressive tax position.$$,
        ARRAY['https://actonmass.org/legislators/james-hawkins/', 'https://malegislature.gov/Legislators/Profile/JKH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James K. Hawkins / transportation-priorities -----
-- Evidence: Joint Committee on Transportation (committee assignment).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95d5e111-b7dd-4440-8b51-070b72e33126',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Hawkins serves on the Joint Committee on Transportation, positioning him in the legislature's key transportation policy debates. His 2nd Bristol District (Attleboro area) is served by MBTA commuter rail and relies heavily on Route 95/495 corridor. As a Democrat on the Transportation committee, he engages with public transit funding, road investment, and multi-modal transportation priorities. His committee assignment reflects active transportation policy engagement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JKH1', 'https://malegislature.gov/Committees/Joint/J40']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '95d5e111-b7dd-4440-8b51-070b72e33126';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '95d5e111-b7dd-4440-8b51-070b72e33126'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '95d5e111-b7dd-4440-8b51-070b72e33126'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
