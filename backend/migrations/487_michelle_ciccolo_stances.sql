-- ============================================================================
-- Migration 487: Michelle Ciccolo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michelle Ciccolo (MA House HD-72,
--   15th Middlesex District). External ID: -210112.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 15 rows in DB, several are 3.0 neutral defaults.
--   This migration corrects those with positive evidence and adds new topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Michelle Ciccolo (HD-72, external_id=-210112)
-- Politician UUID: 0748d787-7e5d-4852-b461-3459312fae45

-- ----- Michelle Ciccolo / childcare -----
-- New topic: campaign-childcare + Children/Families committee assignment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ciccolo serves on the Joint Committee on Children, Families and Persons with Disabilities — a direct committee assignment for childcare and family services policy. She also co-sponsored the Campaign Childcare bill (H.669 / S.422). These roles reflect strong support for publicly-funded childcare and family services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_C2/Committees', 'https://actonmass.org/bills/campaign-childcare/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Ciccolo / immigration -----
-- Correcting pre-existing 3.0: driver's license bill is immigration evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ciccolo co-sponsored the Work and Family Mobility Act (H.3456 / S.2289), providing driver's licenses to all Massachusetts residents regardless of immigration status. This co-sponsorship reflects support for immigrant inclusion and access.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Ciccolo / judicial-criminal-justice -----
-- New topic: life-without-parole co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Ciccolo co-sponsored the Life Without Parole reform bill (H.2398 / S.1544), which would end mandatory life-without-parole sentences for certain crimes. She also co-sponsored overdose prevention legislation, reflecting a public health approach to drug offenses. These positions reflect a reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/life-without-parole/', 'https://malegislature.gov/Bills/194/H2398'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Ciccolo / local-environment -----
-- New topic: Environment committee + environmental-justice co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ciccolo serves on the Joint Committee on Environment and Natural Resources, the primary environment committee in the MA Legislature. She also co-sponsored the Environmental Justice bill (H.1677) and the Climate Superfund Act. These roles and sponsorships reflect strong support for local environmental protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/M_C2/Committees', 'https://actonmass.org/bills/environmental-justice/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Ciccolo / local-immigration -----
-- Correcting pre-existing 3.0: no Safe Communities co-sponsor, but use WFMA + immigration committee context
-- Evidence level is weaker — using 2.0 based on WFMA co-sponsorship directional signal
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Ciccolo co-sponsored the Work and Family Mobility Act (H.3456 / S.2289), providing driver's licenses regardless of immigration status. This bill, which reduces barriers for undocumented residents accessing basic services, reflects a broader position of support for local immigrant communities.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Ciccolo / voting-rights -----
-- Correcting pre-existing 3.0: strong evidence from two voting expansion bills
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0748d787-7e5d-4852-b461-3459312fae45',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ciccolo co-sponsored same-day voter registration legislation and the Lower Voting Age to 16 bill (H.725), which would allow 16-17-year-olds to vote in Massachusetts state elections. Her co-sponsorship of two voting expansion bills reflects strong support for expanding democratic participation.$$,
        ARRAY['https://actonmass.org/bills/lower-voting-age-to-16/', 'https://malegislature.gov/Bills/194/H725'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~20 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '0748d787-7e5d-4852-b461-3459312fae45';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '0748d787-7e5d-4852-b461-3459312fae45'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '0748d787-7e5d-4852-b461-3459312fae45'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
