-- ============================================================================
-- Migration 482: John J. Lawn Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John J. Lawn (MA House HD-67,
--   10th Middlesex District). External ID: -210107.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- John J. Lawn (HD-67, external_id=-210107)
-- Politician UUID: baddd174-93ea-47b6-9cbd-c48fc3acf2f6

-- ----- John J. Lawn / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Lawn co-sponsored the ROE Act (H.3320 / S.1209), which expanded abortion rights in Massachusetts law by removing Roe v. Wade-era restrictions and extending access beyond 24 weeks for health reasons. His co-sponsorship reflects a strongly pro-choice position.$$,
        ARRAY['https://actonmass.org/bills/the-roe-act/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Lawn filed H.848, "An Act relative to campaign finance reform," seeking to strengthen campaign finance regulations in Massachusetts. This bill reflects support for campaign finance transparency and reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H848'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lawn co-sponsored the 100% Renewable Energy by 2045 bill (H.3689), committing Massachusetts to fully renewable electricity generation. This co-sponsorship reflects a pro-climate-action legislative stance.$$,
        ARRAY['https://actonmass.org/bills/100-renewable-energy-by-2045/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lawn filed H.419, "An Act alleviating the burden of medical debt for patients and families," and H.1115 requiring health insurance coverage for vitiligo treatment. He also serves on the Joint Committee on Health Care Financing, working directly on healthcare policy. These roles and sponsorships reflect strong support for expanded healthcare access and coverage.$$,
        ARRAY['https://malegislature.gov/Bills/194/H419', 'https://malegislature.gov/Bills/194/H1115', 'https://malegislature.gov/Legislators/Profile/JJL2/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lawn co-sponsored the Work and Family Mobility Act (H.3456 / S.2289), which provides driver's licenses to all Massachusetts residents regardless of immigration status. This co-sponsorship reflects support for immigrant inclusion and access.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Lawn co-sponsored the Environmental Justice bill (H.1677 / S.953), which established environmental justice protections for overburdened communities in Massachusetts. This co-sponsorship reflects support for local environmental protections.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://malegislature.gov/Bills/194/H1677'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John J. Lawn / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lawn co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day. This co-sponsorship reflects support for expanding ballot access and voting rights in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/john-lawn/', 'https://malegislature.gov/Legislators/Profile/JJL2'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 7):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'baddd174-93ea-47b6-9cbd-c48fc3acf2f6';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'baddd174-93ea-47b6-9cbd-c48fc3acf2f6'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'baddd174-93ea-47b6-9cbd-c48fc3acf2f6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
