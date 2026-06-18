-- ============================================================================
-- Migration 490: David Robertson Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David Robertson (MA House HD-75,
--   19th Middlesex District). External ID: -210115.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 15 rows in DB, mostly 3.0 neutral defaults from prior agent.
--   This migration corrects those with positive evidence found.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- David Robertson (HD-75, external_id=-210115)
-- Politician UUID: f8ae17d7-bc53-4b74-a92e-efa122cd5f04

-- ----- David Robertson / childcare -----
-- Correcting pre-existing 3.0: campaign-childcare co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Robertson co-sponsored the Campaign Childcare bill (H.669 / S.422) and the Cherish Act (H.1260 / S.816) for fully-funded public higher education. These sponsorships reflect support for publicly-funded childcare and education access.$$,
        ARRAY['https://actonmass.org/bills/campaign-childcare/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / climate-change -----
-- Correcting pre-existing 3.0: Climate Superfund co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Robertson co-sponsored the Climate Superfund Act (H.872 / S.481) and Polluter Pays bill, requiring large fossil fuel companies to pay for climate-related damages in Massachusetts. He also serves on the Joint Committee on Telecommunications, Utilities and Energy, which handles clean energy policy. These roles reflect a pro-climate-action stance.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://malegislature.gov/Legislators/Profile/D_R1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / economic-development -----
-- Correcting pre-existing 3.0: Stop Wage Theft + Labor Committee
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Robertson serves on the Joint Committee on Labor and Workforce Development, which handles worker protection legislation. He also co-sponsored the Stop Wage Theft bill (H.1868 / S.1158). These roles reflect support for worker-protective economic policies.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/D_R1/Committees', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / fossil-fuels -----
-- Correcting pre-existing 3.0: Polluter Pays + Utilities Committee
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Robertson co-sponsored the Climate Superfund Act and Polluter Pays bill, holding fossil fuel companies financially responsible for climate damage. His membership on the Joint Committee on Telecommunications, Utilities and Energy reflects engagement with energy transition policy.$$,
        ARRAY['https://actonmass.org/bills/polluter-pays/', 'https://malegislature.gov/Legislators/Profile/D_R1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / healthcare -----
-- Correcting pre-existing 3.0: multiple healthcare bills + THRIVE Act
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Robertson filed H.1297 (colon cancer screenings) and H.1298-1299 (increasing enrollment in affordable health plan networks), and co-sponsored the THRIVE Act for comprehensive healthcare access. These sponsorships reflect strong support for expanded, accessible healthcare coverage.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1297', 'https://malegislature.gov/Bills/194/H1298', 'https://actonmass.org/legislators/david-robertson/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / local-environment -----
-- New topic: drinking water + Environment committee
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Robertson filed H.1028-1029 to protect drinking water from NDMA (a carcinogen) and H.1030 for sewer rate relief. He serves on the Joint Committee on Environment and Natural Resources. These bills and committee role reflect strong support for local environmental quality and clean water access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1028', 'https://malegislature.gov/Bills/194/H1030', 'https://malegislature.gov/Legislators/Profile/D_R1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Robertson / voting-rights -----
-- Correcting pre-existing 3.0: same-day voter registration co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f8ae17d7-bc53-4b74-a92e-efa122cd5f04',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Robertson co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day. This co-sponsorship reflects support for expanding ballot access.$$,
        ARRAY['https://actonmass.org/legislators/david-robertson/', 'https://malegislature.gov/Legislators/Profile/D_R1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~16 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f8ae17d7-bc53-4b74-a92e-efa122cd5f04';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'f8ae17d7-bc53-4b74-a92e-efa122cd5f04'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'f8ae17d7-bc53-4b74-a92e-efa122cd5f04'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
