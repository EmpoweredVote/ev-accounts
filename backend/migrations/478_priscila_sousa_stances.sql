-- ============================================================================
-- Migration 478: Priscila S. Sousa Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Priscila S. Sousa (MA House HD-63,
--   6th Middlesex District). External ID: -210103.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, verified 2026-06-12):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92

BEGIN;

-- Priscila S. Sousa (HD-63, external_id=-210103)
-- Politician UUID: 2ada2d01-a77a-44f6-a569-916d9639fbdc

-- ----- Priscila S. Sousa / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sousa filed H.707, "An Act relative to public preschool facilities," which would expand access to public preschool programs in Massachusetts. She also co-sponsored the Cherish Act (H.1260 / S.816), which would fully fund public higher education. Her consistent focus on educational access from preschool through college reflects support for publicly-funded childcare and early education.$$,
        ARRAY['https://malegislature.gov/Bills/194/H707', 'https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sousa serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion — a direct assignment to the committee responsible for civil rights legislation. She also co-sponsored the Healthy Youth Act (H.544 / S.268) for inclusive sex education, and bills opposing the use of Indigenous team mascots. These assignments and sponsorships reflect strong support for civil rights protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PSS1/Committees', 'https://actonmass.org/bills/healthy-youth-act/', 'https://malegislature.gov/Bills/194/H544'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Sousa co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), strengthening enforcement against wage theft by employers. She serves on the House Committee on Human Resources and Employee Engagement, reflecting direct engagement with worker protection issues. These roles indicate support for worker-protective economic policies.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://malegislature.gov/Legislators/Profile/PSS1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sousa filed H.708, "An Act requiring a mental health wellness examination for all school children," expanding access to mental health services in public schools. She also co-sponsored the THRIVE Act — comprehensive healthcare reform tracked by Act on Mass — and overdose prevention legislation. These sponsorships reflect support for expanded, accessible healthcare including mental health services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H708', 'https://actonmass.org/legislators/priscila-sousa/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sousa filed H.1566, "An Act relative to residential assistance for families in transition (RAFT)," which strengthens the RAFT program providing emergency housing assistance to families at risk of homelessness. This bill reflects direct support for housing stability and affordable housing access for low-income residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1566'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sousa co-sponsored the Age of Criminal Majority to 21 bill (H.1710 / S.942), which would expand the juvenile justice system's rehabilitative approach to young adults aged 18-20. She also co-sponsored overdose prevention legislation, reflecting a public health rather than punitive approach to drug-related offenses. These positions indicate a reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://malegislature.gov/Bills/194/H1710'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sousa co-sponsored the Environmental Justice bill (H.1677 / S.953), which established environmental justice protections for overburdened communities in Massachusetts. She also serves on the Joint Committee on Telecommunications, Utilities and Energy, which handles energy and environmental utility policy. These roles reflect strong support for local environmental protections.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://malegislature.gov/Legislators/Profile/PSS1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Priscila S. Sousa / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2ada2d01-a77a-44f6-a569-916d9639fbdc',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Sousa co-sponsored the Safe Communities Act (H.2288 / S.1510), which restricts state and local law enforcement from cooperating with federal immigration enforcement in most circumstances. This bill, tracked by Act on Mass, reflects support for limiting local immigration enforcement and protecting immigrants in the community.$$,
        ARRAY['https://actonmass.org/bills/safe-communities-act/', 'https://malegislature.gov/Bills/194/H2288'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 8):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2ada2d01-a77a-44f6-a569-916d9639fbdc';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2ada2d01-a77a-44f6-a569-916d9639fbdc'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2ada2d01-a77a-44f6-a569-916d9639fbdc'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
