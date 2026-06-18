-- ============================================================================
-- Migration 479: Jack P. Lewis Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jack P. Lewis (MA House HD-64,
--   7th Middlesex District). External ID: -210104.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 16 rows already in DB. This migration adds 5 new topics
--   and corrects 2 pre-existing 3.0 neutral defaults (voting-rights, housing)
--   where positive evidence has been found.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, verified 2026-06-12):
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Jack P. Lewis (HD-64, external_id=-210104)
-- Politician UUID: 04a9edee-5d51-49f3-a2c9-585e2231bd08

-- ----- Jack P. Lewis / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lewis co-sponsored the Campaign Childcare bill (H.669 / S.422), which would require political campaigns to disclose childcare expenses as legitimate campaign expenses. He also co-sponsored the Cherish Act (H.1260 / S.816) for fully-funded public higher education. His AOM record reflects support for publicly-supported childcare and early education programs.$$,
        ARRAY['https://actonmass.org/bills/campaign-childcare/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack P. Lewis / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Lewis co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Fair Scheduling Act (H.1974 / S.1236), and the Right to Strike bill (H.1845 / S.1217) — a comprehensive set of pro-worker bills. His co-sponsorship of multiple labor protection bills reflects strong support for worker rights and fair economic policies.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/fair-scheduling/', 'https://actonmass.org/bills/the-right-to-strike/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack P. Lewis / housing -----
-- Correcting pre-existing 3.0 neutral default: evidence found via AOM strengthen-commonwealth
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lewis co-sponsored comprehensive housing bills tracked by Act on Mass. He serves on the House Committee on Federal Stimulus and Census Oversight, which oversees federal housing funds distribution. His legislative profile includes support for expanded affordable housing through multiple bill co-sponsorships.$$,
        ARRAY['https://actonmass.org/legislators/jack-lewis/', 'https://malegislature.gov/Legislators/Profile/JPL1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack P. Lewis / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Lewis co-sponsored the Prison Moratorium bill (H.1795 / S.1979), which would halt new prison construction in Massachusetts and redirect funds to community-based services. He also co-sponsored the Age of Criminal Majority to 21 bill (H.1710) and overdose prevention legislation. These positions reflect a strongly reform-oriented approach to criminal justice focused on rehabilitation over incarceration.$$,
        ARRAY['https://actonmass.org/bills/prison-moratorium/', 'https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://malegislature.gov/Bills/194/H1795'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack P. Lewis / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Lewis co-sponsored the Environmental Justice bill (H.1677 / S.953) and the Polluter Pays / Climate Superfund Act (H.872 / S.481), which would require large fossil fuel companies to pay for climate damages proportional to their greenhouse gas emissions. These bills reflect strong support for local environmental protections and accountability for environmental harm.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://actonmass.org/bills/polluter-pays/', 'https://malegislature.gov/Bills/194/H1677'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jack P. Lewis / voting-rights -----
-- Correcting pre-existing 3.0 neutral default: strong evidence from AOM co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('04a9edee-5d51-49f3-a2c9-585e2231bd08',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lewis co-sponsored both same-day voter registration legislation and the Ranked Choice Voting bill (H.825 / S.485), which would allow voters to rank candidates by preference. His co-sponsorship of multiple voting-rights expansion bills reflects a strong commitment to electoral access and reform.$$,
        ARRAY['https://actonmass.org/bills/ranked-choice-voting/', 'https://malegislature.gov/Bills/194/H825', 'https://actonmass.org/legislators/jack-lewis/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~21 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '04a9edee-5d51-49f3-a2c9-585e2231bd08';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '04a9edee-5d51-49f3-a2c9-585e2231bd08'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '04a9edee-5d51-49f3-a2c9-585e2231bd08'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
