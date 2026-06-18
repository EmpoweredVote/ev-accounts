-- ============================================================================
-- Migration 477: David P. Linsky Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David P. Linsky (MA House HD-62,
--   5th Middlesex District). External ID: -210102.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 11 rows already in DB with good evidence values.
--   This migration adds 6 new topics with AOM co-sponsorship evidence.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, verified 2026-06-12):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- David P. Linsky (HD-62, external_id=-210102)
-- Politician UUID: fa6beaf8-acfe-4365-82a2-6f282aa1b688

-- ----- David P. Linsky / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Linsky co-sponsored the Healthy Youth Act (H.544 / S.268), which requires comprehensive, medically-accurate, age-appropriate sex education including LGBTQ+ inclusive content in public schools. He also co-sponsored bills relating to Indigenous peoples' rights (Indigenous Peoples Day, Support Native Students). These sponsorships reflect support for civil rights protections for LGBTQ+ individuals and minority communities.$$,
        ARRAY['https://actonmass.org/bills/healthy-youth-act/', 'https://malegislature.gov/Bills/194/H544'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David P. Linsky / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Linsky co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), strengthening enforcement against employers who steal wages from workers. He also co-sponsored the Fair Scheduling Act (H.1974 / S.1236), requiring advance notice of schedules for hourly workers. His service on the Joint Committee on Revenue reflects engagement with economic policy issues. These positions indicate support for worker-protective economic policies.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/fair-scheduling/', 'https://malegislature.gov/Legislators/Profile/DPL1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David P. Linsky / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Linsky co-sponsored the Age of Criminal Majority to 21 bill (H.1710 / S.942), which would raise the age of adult criminal jurisdiction from 18 to 21, routing young adults through the juvenile justice system with its greater emphasis on rehabilitation. He also co-sponsored overdose prevention legislation and safe communities bills. These positions reflect a reform-oriented approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://malegislature.gov/Bills/194/H1710'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David P. Linsky / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Linsky co-sponsored the Environmental Justice bill (H.1677 / S.953) and the Climate Superfund Act (H.872 / S.481), which would make large fossil fuel companies pay for climate damage proportional to their greenhouse gas emissions. These bills reflect strong support for local and state-level environmental protections, particularly for overburdened communities.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://actonmass.org/bills/climate-superfund/', 'https://malegislature.gov/Bills/194/H1677'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David P. Linsky / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Linsky co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day. This bill, tracked by Act on Mass, reflects support for expanding ballot access and voting rights in Massachusetts.$$,
        ARRAY['https://actonmass.org/legislators/david-linsky/', 'https://malegislature.gov/Legislators/Profile/DPL1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David P. Linsky / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa6beaf8-acfe-4365-82a2-6f282aa1b688',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Linsky serves on the Joint Committee on Revenue, working on state tax policy. His committee role places him in a key position on tax legislation. Combined with his co-sponsorship of the Fair Share Amendment (a millionaires tax surcharge for public education and transportation) and worker-protective economic bills, his record suggests support for progressive taxation that funds public services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DPL1/Committees', 'https://malegislature.gov/Committees/Detail/J33'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be ~17 total after upserts):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'fa6beaf8-acfe-4365-82a2-6f282aa1b688';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'fa6beaf8-acfe-4365-82a2-6f282aa1b688'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'fa6beaf8-acfe-4365-82a2-6f282aa1b688'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
