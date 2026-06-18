-- ============================================================================
-- Migration 494: Sean Garballey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sean Garballey (MA House HD-79,
--   23rd Middlesex District). External ID: -210119.
--   Garballey chairs the House Committee on Global Warming and Climate Change.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 16 rows in DB, some at 3.0 neutral defaults.
--   This migration corrects 3.0 defaults with positive evidence and adds new topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Sean Garballey (HD-79, external_id=-210119)
-- Politician UUID: 7072bd94-b465-414e-bcf5-6e3feb7ec8dd

-- ----- Sean Garballey / childcare -----
-- New topic: campaign-childcare + Cherish Act co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Garballey co-sponsored the Campaign Childcare bill (H.669 / S.422) and the Cherish Act (H.1260 / S.816) for fully-funded public higher education. He also serves on the Joint Committee on Higher Education. These roles reflect support for publicly-funded childcare and education access.$$,
        ARRAY['https://actonmass.org/bills/campaign-childcare/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/', 'https://malegislature.gov/Legislators/Profile/S_G1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / civil-rights -----
-- Correcting pre-existing 3.0: Healthy Youth Act + Support Native Students + Indigenous Peoples Day
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Garballey co-sponsored the Healthy Youth Act (H.544 / S.268) for LGBTQ+-inclusive sex education and the Support Native Students bill (H.536 / S.318) for indigenous student protections. These co-sponsorships reflect support for civil rights protections across LGBTQ+ and indigenous communities.$$,
        ARRAY['https://actonmass.org/bills/healthy-youth-act/', 'https://actonmass.org/bills/support-native-students/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / economic-development -----
-- New topic: Fair Scheduling + Cherish Act (worker/education focus)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Garballey co-sponsored the Fair Scheduling bill (H.1974 / S.1236), which would require advance notice of work schedules for shift workers. He also co-sponsored the Cherish Act for fully-funded public higher education — expanding access to workforce preparation. These co-sponsorships reflect worker-protective and education-access economic policies.$$,
        ARRAY['https://actonmass.org/bills/fair-scheduling/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / judicial-criminal-justice -----
-- New topic: Age of Criminal Majority to 21 + Overdose Prevention + Prison Moratorium
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Garballey co-sponsored the Age of Criminal Majority to 21 bill (H.1710 / S.942), the Overdose Prevention Centers bill (H.1981 / S.1242), and the Prison Moratorium bill (H.1795 / S.1979). These three co-sponsorships reflect a reform-oriented, rehabilitative approach to criminal justice focused on reducing incarceration.$$,
        ARRAY['https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://actonmass.org/bills/overdose-prevention-centers/', 'https://actonmass.org/bills/prison-moratorium/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / local-environment -----
-- New topic: Environmental Justice co-sponsorship + House Climate Committee chair
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Garballey chairs the House Committee on Global Warming and Climate Change — a direct leadership role on the House's primary climate and environment committee. He also co-sponsored the Environmental Justice bill (H.1677 / S.953). These roles reflect strong support for local environmental protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/S_G1/Committees', 'https://actonmass.org/bills/environmental-justice/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / taxes -----
-- Correcting pre-existing 3.0: Fair Share Amendment co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Garballey co-sponsored the Fair Share Amendment (H.86), which added a surtax on household income over $1 million to fund education and transportation in Massachusetts. This co-sponsorship reflects a progressive tax stance — increasing taxes on high earners to fund public services.$$,
        ARRAY['https://actonmass.org/bills/fair-share-amendment/', 'https://malegislature.gov/Bills/194/H86'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean Garballey / voting-rights -----
-- Correcting pre-existing 3.0: same-day voter registration co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Garballey co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day in Massachusetts. This co-sponsorship reflects support for expanding ballot access and democratic participation.$$,
        ARRAY['https://actonmass.org/legislators/sean-garballey/', 'https://malegislature.gov/Legislators/Profile/S_G1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~22 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7072bd94-b465-414e-bcf5-6e3feb7ec8dd';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '7072bd94-b465-414e-bcf5-6e3feb7ec8dd'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '7072bd94-b465-414e-bcf5-6e3feb7ec8dd'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
