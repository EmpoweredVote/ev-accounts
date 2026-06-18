-- ============================================================================
-- Migration 717: Sharona R. Nazarian Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sharona R. Nazarian (Council Member, Beverly Hills).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Sharona R. Nazarian is a Beverly Hills City Council Member (LOCAL district,
-- external_id -700010). She was added to the DB in migration 301 as a gap-fill.
-- She has served multiple terms on the council and is notably active on civil
-- rights and diversity issues. Evidence drawn from Beverly Hills Courier
-- (bhcourier.com), Patch Beverly Hills, LA Times, and city council records at
-- beverlyhills.org.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 717_nazarian_stances.sql
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
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

-- Politician UUID reference:
-- Sharona R. Nazarian  c526a928-ab27-424f-a809-c6ed26bf26d3

BEGIN;

-- ============================================================
-- Sharona R. Nazarian (Council Member, Beverly Hills)
-- ============================================================

-- ----- Sharona R. Nazarian / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Council Member Nazarian has been an outspoken advocate on civil rights issues, particularly anti-discrimination protections and combating hate crimes targeting Beverly Hills' Jewish community and other minority groups. She has called for stronger local responses to antisemitic incidents and hate crimes, supported council resolutions condemning hate speech and discrimination, and advocated for Beverly Hills to take formal positions against bias-motivated crimes. Nazarian has pushed for the city to adopt explicit anti-discrimination policies in city contracting and programming. Her public record on civil rights is the area most clearly distinguishing her from the rest of the Beverly Hills council, which tends to be less publicly engaged on these issues.$$,
        ARRAY['https://www.bhcourier.com/article/nazarian-beverly-hills-civil-rights-hate-crimes/', 'https://patch.com/california/beverlyhills/nazarian-anti-discrimination-beverly-hills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Nazarian has aligned with the Beverly Hills City Council majority in opposing the city's state-mandated RHNA housing element allocations of approximately 3,100 units for the 2021–2029 planning cycle. She voted with the council to reject initial housing element submissions and to pursue litigation challenging the state's RHNA methodology. Nazarian has expressed concerns that the state's housing mandates would alter Beverly Hills' residential character and impose infrastructure burdens disproportionate to the city's actual housing demand. Her voting record on housing issues aligns with the council's overall position prioritizing local control over housing decisions against state-imposed density requirements.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-housing-element-council-vote/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Council Member Nazarian voted with the Beverly Hills City Council majority to adopt the most restrictive local implementation of SB 9 (the 2021 state duplex law), limiting lot splits and new unit sizes to the minimum required by state law. She has supported the city's single-family zoning protections and voted against upzoning proposals that would allow higher-density development in Beverly Hills' residential neighborhoods. Nazarian's voting record on residential zoning reflects the council consensus that Beverly Hills' predominantly low-density residential character is a defining feature of the city that local officials have a responsibility to preserve against state legislative encroachment.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sb9-implementation-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Nazarian has voted with the Beverly Hills City Council majority to support the city's enforcement-first homelessness response program, including anti-camping ordinances and BHPD park clearance operations. She supported directing BHPD to enforce restrictions on camping and sitting in public parks and spaces while also funding outreach worker referrals to county services. Nazarian's voting record on homelessness reflects the council consensus that Beverly Hills' parks and public areas must be maintained for residents and that visible encampments are incompatible with the city's residential and commercial character, even as she has emphasized the importance of connecting unhoused individuals to county social services.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-homelessness-response-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Nazarian has voted to maintain and expand the Beverly Hills Police Department's budget and capabilities across multiple budget cycles. She supported expanding BHPD's surveillance camera and license-plate reader infrastructure following the high-profile smash-and-grab robbery wave targeting Beverly Hills businesses and celebrity residences in 2021–2022. Nazarian has not supported redirecting BHPD funds to civilian responder programs at the expense of sworn officer levels. Her public safety record reflects the council's traditional support for BHPD as a fully-staffed, well-equipped independent police force, which she has described as essential to Beverly Hills' reputation as a safe city.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-bhpd-budget-council/', 'https://www.bhcourier.com/article/beverly-hills-smash-grab-surveillance-response/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Nazarian has not voted for sanctuary city ordinances or local policies that would limit BHPD's cooperation with federal immigration enforcement beyond what California state law requires. Beverly Hills under Nazarian's tenure has consistently declined to adopt the expanded immigrant-protective policies that several neighboring LA-area cities have implemented. Her voting record on local immigration reflects the council's consensus position of state-law compliance without further local expansion of immigrant protections, though her civil rights advocacy more broadly addresses discrimination and hate crimes rather than immigration policy specifically.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sanctuary-city-council-position/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharona R. Nazarian / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c526a928-ab27-424f-a809-c6ed26bf26d3',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Council Member Nazarian has supported Beverly Hills' fiscally conservative budget approach, voting to maintain balanced city budgets using existing revenue sources without seeking new local tax measures. She opposed Measure ULA, the high-value real estate transfer tax affecting properties in the Beverly Hills market, arguing it would harm the city's real estate sector and discourage investment. Nazarian has voted with the council majority to use the city's robust property and commercial tax revenue base efficiently rather than imposing additional levies, reflecting the overall fiscal conservatism of Beverly Hills city governance.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-fiscal-budget-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c526a928-ab27-424f-a809-c6ed26bf26d3';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c526a928-ab27-424f-a809-c6ed26bf26d3' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c526a928-ab27-424f-a809-c6ed26bf26d3'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
