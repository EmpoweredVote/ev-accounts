-- ============================================================================
-- Migration 480: James Arena-DeRosa Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for James Arena-DeRosa (MA House HD-65,
--   8th Middlesex District). External ID: -210105.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 13 rows already in DB. This migration adds 6 new topics
--   and corrects 1 pre-existing 3.0 neutral default (climate-change).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, verified 2026-06-12):
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa

BEGIN;

-- James Arena-DeRosa (HD-65, external_id=-210105)
-- Politician UUID: ea8ed274-32d6-499d-a787-7ad1f0624280

-- ----- James Arena-DeRosa / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Arena-DeRosa co-sponsored the Campaign Childcare bill (H.669 / S.422), which would allow political campaigns to cover childcare expenses as legitimate campaign costs, removing a financial barrier for parents seeking public office. He also co-sponsored the Cherish Act (H.1260 / S.816) for fully-funded public higher education. These sponsorships reflect support for publicly-supported childcare access.$$,
        ARRAY['https://actonmass.org/bills/campaign-childcare/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Arena-DeRosa co-sponsored the Healthy Youth Act (H.544 / S.268) for LGBTQ+-inclusive sex education in public schools, and the Racially Inclusive Education bill to expand anti-racism education in curricula. He also co-sponsored bills supporting Native students and opposing the use of Indigenous mascots. These sponsorships reflect strong support for civil rights protections for LGBTQ+ individuals and racial minorities.$$,
        ARRAY['https://actonmass.org/bills/healthy-youth-act/', 'https://actonmass.org/bills/racially-inclusive-education/', 'https://malegislature.gov/Bills/194/H544'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / climate-change -----
-- Correcting pre-existing 3.0 neutral default: strong evidence from AOM co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Arena-DeRosa co-sponsored both the Climate Superfund Act (H.872 / S.481) and the Polluter Pays bill, which would require large fossil fuel companies to pay for climate-related damages in Massachusetts proportional to their historical greenhouse gas emissions. These co-sponsorships demonstrate a pro-climate-action legislative stance.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/polluter-pays/', 'https://malegislature.gov/Bills/194/H872'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Arena-DeRosa co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Right to Strike bill (H.1845 / S.1217), and the Stop Corporate Offshoring bill — a comprehensive set of pro-worker, anti-offshoring economic bills. He also serves on the Joint Committee on Community Development and Small Businesses. These positions reflect strong support for worker protections and local economic development.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/the-right-to-strike/', 'https://malegislature.gov/Legislators/Profile/JCD1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Arena-DeRosa co-sponsored the Climate Superfund Act (H.872 / S.481) and Polluter Pays bill, both of which hold fossil fuel companies financially responsible for climate damage. His co-sponsorship of these bills placing liability on fossil fuel producers reflects opposition to continued fossil fuel industry expansion.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/polluter-pays/', 'https://malegislature.gov/Bills/194/H872'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Arena-DeRosa co-sponsored both the Prison Moratorium bill (H.1795 / S.1979) to halt new prison construction and the Age of Criminal Majority to 21 bill (H.1710 / S.942). He also co-sponsored overdose prevention legislation, reflecting a public health approach to drug offenses. These positions reflect a strongly reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/prison-moratorium/', 'https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://malegislature.gov/Bills/194/H1710'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- James Arena-DeRosa / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea8ed274-32d6-499d-a787-7ad1f0624280',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Arena-DeRosa co-sponsored the Climate Superfund Act and Polluter Pays bill, requiring fossil fuel companies to pay for local climate-related damages. He serves on the Joint Committee on Agriculture, which handles local environmental quality issues related to land use. These roles reflect support for local environmental protections and climate accountability.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/polluter-pays/', 'https://malegislature.gov/Legislators/Profile/JCD1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~20 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ea8ed274-32d6-499d-a787-7ad1f0624280';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ea8ed274-32d6-499d-a787-7ad1f0624280'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ea8ed274-32d6-499d-a787-7ad1f0624280'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
