-- ============================================================================
-- Migration 481: Thomas M. Stanley Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Thomas M. Stanley (MA House HD-66,
--   9th Middlesex District). External ID: -210106.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Thomas M. Stanley (HD-66, external_id=-210106)
-- Politician UUID: c70bd1f2-6ba2-446e-a40c-d07f446db214

-- ----- Thomas M. Stanley / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Stanley co-sponsored both the abortion-access bill and the ROE Act (H.3320 / S.1209), which expanded abortion rights in Massachusetts law. His co-sponsorship of these two major abortion-access bills demonstrates a strongly pro-choice legislative record.$$,
        ARRAY['https://actonmass.org/bills/the-roe-act/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Stanley co-sponsored the Campaign Childcare bill (H.669 / S.422) and the Cherish Act (H.1260 / S.816) for fully-funded public higher education. His service on the Joint Committee on Elder Affairs also involves care-related policy. These sponsorships reflect support for public investment in childcare and education.$$,
        ARRAY['https://actonmass.org/bills/campaign-childcare/', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Stanley co-sponsored the Healthy Youth Act (H.544 / S.268) for LGBTQ+-inclusive sex education in public schools, and bills relating to Indigenous rights including opposing Native mascots. These sponsorships reflect support for civil rights protections for LGBTQ+ individuals and minority communities.$$,
        ARRAY['https://actonmass.org/bills/healthy-youth-act/', 'https://malegislature.gov/Bills/194/H544'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stanley co-sponsored the 100% Renewable Energy by 2045 bill (H.3689), which commits Massachusetts to transitioning to fully renewable electricity generation. This co-sponsorship reflects a pro-climate-action legislative stance.$$,
        ARRAY['https://actonmass.org/bills/100-renewable-energy-by-2045/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Stanley co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Fair Scheduling Act (H.1974 / S.1236), and the Stop Corporate Offshoring bill. These three co-sponsorships reflect consistent support for worker-protective economic policies and opposition to practices that disadvantage workers.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/fair-scheduling/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Stanley co-sponsored both Medicare for All legislation and the THRIVE Act — comprehensive universal healthcare bills. His co-sponsorship of both universal healthcare measures reflects a strongly pro-universal-coverage position.$$,
        ARRAY['https://actonmass.org/bills/medicare-for-all/', 'https://actonmass.org/legislators/thomas-stanley/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Stanley co-sponsored the Work and Family Mobility Act (H.3456 / S.2289) providing driver's licenses regardless of immigration status. His co-sponsorship of this measure reflects support for immigrant inclusion and access.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Stanley co-sponsored the Age of Criminal Majority to 21 bill (H.1710 / S.942), which would expand the juvenile justice system's rehabilitative approach to young adults. This co-sponsorship reflects a reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://malegislature.gov/Bills/194/H1710'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Stanley co-sponsored the Environmental Justice bill (H.1677 / S.953), which established environmental justice protections for overburdened communities in Massachusetts. This co-sponsorship reflects support for local environmental protections.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://malegislature.gov/Bills/194/H1677'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Stanley co-sponsored the Safe Communities Act (H.2288 / S.1510), restricting state and local law enforcement cooperation with federal immigration enforcement. This co-sponsorship reflects support for limiting local immigration enforcement and protecting immigrants in the community.$$,
        ARRAY['https://actonmass.org/bills/safe-communities-act/', 'https://malegislature.gov/Bills/194/H2288'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Stanley co-sponsored Medicare for All legislation, supporting a single-payer healthcare system. His service on the Joint Committee on Elder Affairs also involves Medicare and Medicaid programs for seniors. These roles reflect strong support for expanded Medicare/Medicaid programs.$$,
        ARRAY['https://actonmass.org/bills/medicare-for-all/', 'https://malegislature.gov/Legislators/Profile/TMS1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas M. Stanley / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c70bd1f2-6ba2-446e-a40c-d07f446db214',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Stanley co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day. This co-sponsorship reflects support for expanding ballot access and voting rights in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/thomas-stanley/', 'https://malegislature.gov/Legislators/Profile/TMS1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 12):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c70bd1f2-6ba2-446e-a40c-d07f446db214';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c70bd1f2-6ba2-446e-a40c-d07f446db214'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c70bd1f2-6ba2-446e-a40c-d07f446db214'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
