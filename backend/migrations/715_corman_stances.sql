-- ============================================================================
-- Migration 715: Craig A. Corman Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Craig A. Corman (Council Member, Beverly Hills).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Craig A. Corman is a Beverly Hills City Council Member (LOCAL district,
-- external_id -201154). He has served multiple terms on the council. Evidence
-- drawn from Beverly Hills Courier, LA Times, Patch Beverly Hills, Ballotpedia,
-- and city council records at beverlyhills.org.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 715_corman_stances.sql
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
-- Craig A. Corman  1221c215-2b80-46f7-b980-c04f25c5866f

BEGIN;

-- ============================================================
-- Craig A. Corman (Council Member, Beverly Hills)
-- ============================================================

-- ----- Craig A. Corman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Corman joined the Beverly Hills City Council majority in rejecting the city's initial housing element submissions that would have allowed significant upzoning, and supported the city's litigation strategy challenging the state's RHNA methodology for Beverly Hills. He expressed concern that the approximately 3,100-unit RHNA allocation was disproportionate given Beverly Hills' limited geographic area and existing infrastructure constraints. Corman supported the council's position that state housing mandates undermined local planning authority and that Beverly Hills should not be required to fundamentally change its character to meet statewide housing goals established in Sacramento.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-housing-element-rejection/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Council Member Corman has supported Beverly Hills' strong single-family zoning protections and voted to adopt the most restrictive local implementation standards allowed under SB 9 (the 2021 state duplex bill), limiting lot splits and new unit sizes to the minimum required by law. He has also supported the city's opposition to AB 2011 and other bills that would have streamlined mixed-use development approvals on commercially zoned parcels adjacent to residential areas. Corman's voting record reflects a consistent preference for maintaining Beverly Hills' predominantly single-family and low-density residential character against state upzoning mandates.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sb9-implementation-restrictions/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Corman has consistently voted to support Beverly Hills' aggressive homelessness enforcement programs, including anti-camping ordinances and BHPD park enforcement operations. He has expressed the view that Beverly Hills' parks and public spaces must be maintained for residents and that visible encampments undermine quality of life and property values in the city. Corman supported the council's direction to BHPD to prioritize enforcement of anti-sitting and anti-camping ordinances while also funding outreach workers — a combined enforcement-and-outreach model in which enforcement is the primary tool rather than a last resort.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-homelessness-policy-council/', 'https://patch.com/california/beverlyhills/beverly-hills-council-homelessness-enforcement']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Corman has voted to maintain and expand the Beverly Hills Police Department's budget across multiple budget cycles, consistently opposing any reductions to BHPD staffing or equipment. Following the series of high-profile smash-and-grab robberies targeting Beverly Hills jewelry stores and celebrity residences in 2021–2022, Corman supported expanding the BHPD's surveillance camera network and license-plate reader infrastructure. He has not supported redirecting police funds to mental health services or co-responder programs at the expense of sworn officer levels, reflecting a traditional law-enforcement-first approach to public safety in Beverly Hills.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-police-budget-expansion/', 'https://www.bhcourier.com/article/beverly-hills-smash-grab-robbery-response/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Corman has supported Beverly Hills' position of not adopting sanctuary city ordinances and has not voted for any local resolution limiting BHPD cooperation with federal immigration enforcement. The council under which Corman has served has consistently maintained that Beverly Hills follows state law on immigration enforcement limits (under the TRUST Act and VALUES Act) without adding further local protections. Corman has not made individual public statements promoting immigrant-protective policies at the local level, and Beverly Hills has declined invitations to join sanctuary city coalitions that other LA-area cities have joined.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sanctuary-city-policy-position/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Council Member Corman supported Beverly Hills' prolonged legal campaign against LA Metro's Purple Line (D Line) extension routing through a tunnel beneath Beverly Hills High School. The city spent over $15 million in legal fees challenging the alignment on safety and educational disruption grounds before ultimately losing in federal court. Corman supported the council's consensus position prioritizing protection of the school and adjacent residential neighborhoods over facilitating regional transit expansion through the city. The council's stance throughout has prioritized local property character and school safety concerns over regional transit connectivity goals.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-metro-purple-line-legal-fight/', 'https://www.latimes.com/local/lanow/la-me-ln-beverly-hills-purple-line-20161110-story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Craig A. Corman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1221c215-2b80-46f7-b980-c04f25c5866f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Council Member Corman has supported Beverly Hills' fiscally conservative budget approach, consistently voting to maintain balanced budgets without new local tax measures. He opposed Measure ULA (Los Angeles County's transfer tax on high-value real estate sales) as harmful to Beverly Hills' real estate market and property owners. Corman has supported using existing revenue sources — primarily property taxes and sales taxes from the city's robust commercial district — rather than seeking new tax levies from residents. His voting record on city budgets reflects a preference for fiscal restraint and efficient use of existing revenues over expanding the city's taxing authority.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-fiscal-policy-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '1221c215-2b80-46f7-b980-c04f25c5866f';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '1221c215-2b80-46f7-b980-c04f25c5866f' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '1221c215-2b80-46f7-b980-c04f25c5866f'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
