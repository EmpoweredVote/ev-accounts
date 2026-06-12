-- ============================================================================
-- Migration 456: Tram T. Nguyen Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tram T. Nguyen (MA State Rep, 18th Essex District, HD-41).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics, 44 active as of 2026-06-11):
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

-- ============================================================================
-- Tram T. Nguyen (HD-41, external_id=-210081)
-- UUID: fc1d7143-1be8-49b0-be31-6dbc5874230d
-- District: 18th Essex (Andover area)
-- Progressive Democrat; House Committee on Climate Action and Sustainability member;
-- leading immigration advocate; prolific bill sponsor across healthcare, civil rights, environment.
-- ============================================================================

-- ----- Tram T. Nguyen / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Tram Nguyen serves on the House Committee on Climate Action and Sustainability, signaling a legislative focus on climate policy. She sponsored H.1032, "An Act to establish environmental accountability in the fashion industry," targeting supply-chain emissions and environmental impact. Her committee assignment places her in a direct role shaping MA climate legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTN1/Committees', 'https://malegislature.gov/Bills/194/H1032']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Nguyen sponsored H.1012, "An Act relative to further testing after a CSO event," requiring expanded water quality testing following combined sewer overflow events — a local environmental protection measure. She also sponsored H.1032 targeting environmental accountability in the fashion industry. These bills reflect a consistent focus on local environmental health and pollution accountability.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1012', 'https://malegislature.gov/Bills/194/H1032']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Nguyen sponsored H.275, "An Act relative to child care cost transparency," which requires childcare providers to disclose cost structures to increase affordability and accountability. She also co-sponsored H.2152, "An Act extending parental leave," expanding family leave access. Both bills reflect a pro-affordability, pro-family support stance on childcare policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H275', 'https://malegislature.gov/Bills/194/H2152']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Nguyen is among MA's most active civil rights sponsors. She sponsored H.1920 "An Act relative to combating hate in the Commonwealth," H.1919 "An Act prohibiting body size discrimination," H.1921 "An Act relative to sexual harassment," H.3398 "An Act to promote diversity on public boards and commissions," H.4018 "An Act protecting assault survivors," and H.655 "An Act to promote comprehensive and inclusive curriculum in schools." This breadth of civil rights legislation places her firmly at the strong-expansion end of the spectrum.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1920', 'https://malegislature.gov/Bills/194/H1919', 'https://malegislature.gov/Bills/194/H655', 'https://malegislature.gov/Bills/194/H3398']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Nguyen sponsored multiple healthcare access bills: H.786 "An Act protecting vulnerable elders from abuse," H.1275 "An Act relative to fairness in debt collection" (protecting patients from aggressive medical debt collection), H.2150 "An Act to increase unemployment insurance benefits for low wage workers," and H.2151 "An Act to protect injured workers." She also sponsored H.2152 extending parental leave. These bills consistently expand healthcare access and worker protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H786', 'https://malegislature.gov/Bills/194/H1275', 'https://malegislature.gov/Bills/194/H2150', 'https://malegislature.gov/Bills/194/H2151']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Nguyen sponsored H.449, "An Act eliminating forced broker's fees," which bars landlords from passing real estate broker fees to tenants — a significant pro-tenant housing affordability measure. Her sponsorship of this bill alongside housing-related economic development bills indicates a consistent stance favoring expanded housing access and tenant protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H449']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Nguyen sponsored H.449, "An Act eliminating forced broker's fees," which specifically removes a financial burden placed on tenants by landlords passing broker costs. This measure directly reduces costs for renters and reflects a pro-tenant regulatory stance consistent with rent regulation advocacy in the Massachusetts legislature.$$,
        ARRAY['https://malegislature.gov/Bills/194/H449']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Tram Nguyen is among the most prominent immigration advocates in the Massachusetts Legislature. She has been a lead co-sponsor of the Safe Communities Act across multiple sessions, which limits state and local law enforcement cooperation with federal immigration enforcement. She speaks regularly at immigration rallies and has championed protections for undocumented residents, placing her at the strong-expansion end of immigration policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTN1', 'https://www.wbur.org/news/2019/07/22/safe-communities-act-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Nguyen has been a consistent lead sponsor of the Safe Communities Act, which restricts local and state law enforcement from assisting federal immigration enforcement. Her advocacy for limiting local cooperation with ICE detainer requests is among the most well-documented positions in her legislative record, placing her at the minimum-cooperation end of the local-immigration axis.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TTN1', 'https://www.wbur.org/news/2019/07/22/safe-communities-act-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Nguyen sponsored H.1913, "An Act relative to treatment, not incarceration," which prioritizes diversion to substance use treatment over criminal prosecution — a reform-focused public safety approach. She also sponsored H.1918, "An Act promoting fairness in youthful offender indictments," which limits prosecutorial discretion to charge juveniles as adults. Both bills reflect a rehabilitation and reform emphasis over punitive approaches.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1913', 'https://malegislature.gov/Bills/194/H1918']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tram T. Nguyen / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fc1d7143-1be8-49b0-be31-6dbc5874230d',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Nguyen sponsored H.1922, "An Act relative to fair investment," and H.2141, "An Act relative to employee definition harmonization," both targeting worker economic protections. She also sponsored H.2150 increasing unemployment benefits for low-wage workers and H.2151 protecting injured workers. These bills reflect a labor-aligned, worker-first economic development stance favoring broad-based economic protections over business deregulation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1922', 'https://malegislature.gov/Bills/194/H2141', 'https://malegislature.gov/Bills/194/H2150']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be ~10 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'fc1d7143-1be8-49b0-be31-6dbc5874230d'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
