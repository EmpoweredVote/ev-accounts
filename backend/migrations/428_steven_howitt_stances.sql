-- ============================================================================
-- Migration 428: Steven S. Howitt Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Steven S. Howitt
--   (MA State Representative, 4th Bristol District, HD-13, Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1 (external_id: -210053)

BEGIN;

-- ----- Steven S. Howitt / economic-development -----
-- Evidence: Ranking Minority Member, Joint Committee on Financial Services;
--   House Committee on Steering, Policy and Scheduling.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Howitt serves as Ranking Minority Member on the Joint Committee on Financial Services, the top Republican on the committee overseeing banks, credit unions, mortgage lending, and capital markets regulation. This leadership role reflects his economic philosophy: market-oriented, pro-business, and skeptical of heavy financial regulation. He also serves on the House Committee on Steering, Policy and Scheduling. As a Republican, he approaches economic development through deregulation and private sector incentives rather than government-directed programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SSH1', 'https://actonmass.org/legislators/steven-howitt/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven S. Howitt / fossil-fuels -----
-- Evidence: Joint Committee on Telecommunications, Utilities and Energy (Republican member);
--   did not co-sponsor 100% Renewable Energy.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Howitt serves on the Joint Committee on Telecommunications, Utilities and Energy as a Republican who did not co-sponsor the 100% Renewable Energy by 2045 bill. His Republican party affiliation and energy committee membership, combined with absence of clean energy bill co-sponsorships, indicate a position skeptical of aggressive fossil fuel phase-out mandates. Republicans on the energy committee typically advocate for a more measured energy transition that maintains fossil fuel reliability during the transition period.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SSH1', 'https://actonmass.org/legislators/steven-howitt/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '3107f5d0-2cfd-43bc-a8eb-6b8ddc75bfc1'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
