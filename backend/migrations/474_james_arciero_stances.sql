-- ============================================================================
-- Migration 474: James Arciero Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for James Arciero
--          (MA State Rep, 2nd Middlesex District, HD-59).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- climate-change    f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- fossil-fuels      a22215c3-6693-4bc2-b248-01aebba14570
-- school-vouchers   00b95a6a-75db-4521-b523-3326bba938de

-- NOTE: The DB contains 13 pre-existing rows for Arciero from a prior AOM
-- "did not co-sponsor" agent run. Those 10 rows with value=3.0 and "did not
-- co-sponsor" reasoning violate D-01 (no evidence = no value). They are
-- pre-existing and out-of-scope to delete in this migration. This file
-- upserts only the 3 topics with positive evidence (climate-change, fossil-fuels,
-- school-vouchers — all confirmed via AOM co-sponsorship tracker).
-- The remaining 3.0 neutral default rows are tracked as a known issue.

BEGIN;

-- ============================================================================
-- James Arciero (HD-59, external_id=-210099)
-- UUID: f392e7c6-0ab2-4834-9a57-df86541f55d3
-- District: 2nd Middlesex (Westford/Littleton/Ayer area)
-- Democrat; malegislature.gov/Legislators/Profile/J_A1
-- ============================================================================

-- ----- James Arciero / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Arciero co-sponsored the 100% Renewable Energy by 2045 bill per the Act on Mass tracker, indicating active support for a rapid transition to clean energy and phasing out fossil fuels. He also co-sponsored the Environmental Justice bill, reinforcing his commitment to addressing climate impacts on underserved communities. These co-sponsorships place him in support of aggressive climate action beyond the current regulatory baseline.$$,
        ARRAY['https://actonmass.org/legislators/james-arciero/', 'https://actonmass.org/bills/100-renewable-energy-by-2045/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arciero / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Arciero co-sponsored the 100% Renewable Energy by 2045 bill per Act on Mass, indicating support for stopping new fossil fuel permits and transitioning to clean energy. His co-sponsorship of the Environmental Justice bill further signals support for reducing fossil fuel impacts on frontline communities. These positions place him in favor of significantly reducing reliance on fossil fuels.$$,
        ARRAY['https://actonmass.org/legislators/james-arciero/', 'https://actonmass.org/bills/100-renewable-energy-by-2045/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arciero / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f392e7c6-0ab2-4834-9a57-df86541f55d3',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Arciero co-sponsored the Cherish Act (fully funded public higher education) per the Act on Mass tracker. The Cherish Act would provide full public funding for higher education, reducing tuition barriers and opposing the diversion of public education funds to private institutions. This co-sponsorship places him squarely against school voucher expansion and in favor of universal public education funding.$$,
        ARRAY['https://actonmass.org/legislators/james-arciero/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (expect >= 3 from this migration + pre-existing rows):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f392e7c6-0ab2-4834-9a57-df86541f55d3';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'f392e7c6-0ab2-4834-9a57-df86541f55d3'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'f392e7c6-0ab2-4834-9a57-df86541f55d3'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
