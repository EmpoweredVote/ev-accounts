-- ============================================================================
-- Migration 485: Carmine L. Gentile Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Carmine L. Gentile (MA House HD-70,
--   13th Middlesex District). External ID: -210110.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 13 rows already in DB with good evidence values.
--   This migration adds 5 new topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Carmine L. Gentile (HD-70, external_id=-210110)
-- Politician UUID: a9ea7006-d595-45aa-a301-9c71d5a3af4d

-- ----- Carmine L. Gentile / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Gentile co-sponsored the Cherish Act (H.1260 / S.816) for fully-funded public higher education and serves on the Joint Committee on Higher Education. He also co-sponsored universal recess for K-5 students. His education committee role and sponsorships reflect support for publicly-funded education access from early childhood through college.$$,
        ARRAY['https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/', 'https://malegislature.gov/Legislators/Profile/CLG1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmine L. Gentile / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Gentile co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Right to Strike bill (H.1845 / S.1217), and the Stop Corporate Offshoring bill. These three co-sponsorships reflect a consistent pattern of support for worker-protective economic policies and opposition to practices that disadvantage workers.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/the-right-to-strike/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmine L. Gentile / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Gentile co-sponsored the Prison Moratorium bill (H.1795 / S.1979) to halt new prison construction, the Age of Criminal Majority to 21 bill (H.1710), and the Life Without Parole reform bill (H.2398 / S.1544), which would end mandatory LWOP sentences for certain crimes. These extensive reform co-sponsorships reflect a strongly reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/prison-moratorium/', 'https://actonmass.org/bills/life-without-parole/', 'https://malegislature.gov/Bills/194/H2398'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmine L. Gentile / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Gentile serves on the Joint Committee on Environment and Natural Resources — a direct assignment to the primary environment committee in the MA Legislature. He also co-sponsored the Environmental Justice bill (H.1677) and the Climate Superfund / Polluter Pays bills. These roles and sponsorships reflect strong support for local environmental protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CLG1/Committees', 'https://actonmass.org/bills/environmental-justice/', 'https://actonmass.org/bills/climate-superfund/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carmine L. Gentile / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9ea7006-d595-45aa-a301-9c71d5a3af4d',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Gentile co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day. This co-sponsorship reflects support for expanding ballot access and voting rights in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/carmine-gentile/', 'https://malegislature.gov/Legislators/Profile/CLG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 18):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a9ea7006-d595-45aa-a301-9c71d5a3af4d';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a9ea7006-d595-45aa-a301-9c71d5a3af4d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a9ea7006-d595-45aa-a301-9c71d5a3af4d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
