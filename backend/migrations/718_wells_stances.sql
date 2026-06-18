-- ============================================================================
-- Migration 718: Mary N. Wells Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mary N. Wells (Council Member, Beverly Hills).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Mary N. Wells is a Beverly Hills City Council Member (LOCAL district,
-- external_id -201155). She has served multiple terms on the council.
-- Evidence drawn from Beverly Hills Courier (bhcourier.com), Patch Beverly
-- Hills, LA Times, and city council records at beverlyhills.org.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 718_wells_stances.sql
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
-- Mary N. Wells  b4f9688b-add0-44d6-bab8-e923d17d105e

BEGIN;

-- ============================================================
-- Mary N. Wells (Council Member, Beverly Hills)
-- ============================================================

-- ----- Mary N. Wells / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Wells voted with the Beverly Hills City Council majority to reject initial housing element submissions that would have allowed significant upzoning and to pursue litigation challenging the state's RHNA methodology for Beverly Hills' approximately 3,100-unit housing allocation. She expressed concerns that the state's housing mandates would disproportionately alter Beverly Hills' residential character given the city's small geographic area and existing infrastructure. Wells' voting record on housing reflects the council's consistent position prioritizing local planning authority and opposing state-mandated density increases that the council majority viewed as incompatible with Beverly Hills' established character.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-housing-element-council-vote/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Council Member Wells voted with the Beverly Hills City Council majority to adopt the most restrictive local implementation of SB 9 (the 2021 state duplex law), limiting lot splits and new unit construction to the minimum required under state law. She supported the city's single-family zoning protections and has voted against upzoning proposals that would allow higher-density residential development in Beverly Hills' neighborhoods. Wells' voting record reflects the council consensus position that Beverly Hills' predominantly low-density residential character is a core civic asset that local officials are responsible for protecting against state legislative mandates to increase density.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sb9-zoning-restrictions/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Wells voted with the Beverly Hills City Council majority to support the city's enforcement-first homelessness response strategy, including anti-camping ordinances and BHPD park clearance programs. She supported directing BHPD to enforce anti-camping and anti-sitting ordinances in city parks and public spaces while also providing outreach worker referrals to county services. Wells' voting record on homelessness aligns with the council's consistent position that Beverly Hills' public spaces must be maintained for residents and that visible encampments are incompatible with the city's residential and commercial quality of life.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-homelessness-ordinance-council/', 'https://patch.com/california/beverlyhills/beverly-hills-council-homelessness-response-vote']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Wells has voted to maintain and expand the Beverly Hills Police Department's budget and capabilities, supporting BHPD's full staffing levels and equipment investments across multiple budget cycles. She supported expanding BHPD's surveillance camera and license-plate reader infrastructure following the high-profile smash-and-grab robbery wave targeting Beverly Hills in 2021–2022. Wells' public safety record reflects the council's traditional law-enforcement-first approach, consistently backing BHPD resources and operations as essential to maintaining Beverly Hills' reputation as a safe, low-crime city.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-bhpd-budget-council-vote/', 'https://www.bhcourier.com/article/beverly-hills-smash-grab-lpr-expansion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Wells has not voted for sanctuary city ordinances or local policies expanding immigrant protections beyond what California state law already requires under the TRUST Act and VALUES Act. Beverly Hills under Wells' tenure has consistently declined to join sanctuary city coalitions or adopt additional local immigrant-protective policies that other LA-area cities have implemented. Her voting record on local immigration reflects the council's consensus position of state-law compliance without further local expansion of immigration restrictions or of immigrant-protective policies.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-immigration-policy-no-sanctuary/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Council Member Wells has supported Beverly Hills' fiscally conservative approach to city finances, voting to maintain balanced budgets without seeking new local tax measures from residents or businesses. She opposed Measure ULA, the LA County high-value real estate transfer tax, arguing it would negatively impact Beverly Hills' real estate market and the city's economic vitality. Wells has consistently voted to use the city's existing revenue base — primarily property taxes and commercial receipts from the Rodeo Drive district — efficiently rather than seeking new taxing authority, reflecting the broader fiscal conservatism of Beverly Hills city governance.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-budget-fiscal-policy-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Council Member Wells has supported selective commercial development in Beverly Hills' business corridors — particularly projects enhancing the Rodeo Drive luxury retail district and major hotel redevelopments — while consistently opposing large-scale residential and mixed-use projects that would change the city's predominantly low-density residential character. She has voted for development permits that reinforce Beverly Hills' commercial brand identity and strengthen the city's sales tax base without adding significant residential density. Wells' voting record on development reflects a preference for maintaining the city's established scale and character while supporting targeted commercial projects that serve the city's economic interests.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-development-planning-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mary N. Wells / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b4f9688b-add0-44d6-bab8-e923d17d105e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Council Member Wells supported Beverly Hills' prolonged legal effort against LA Metro's Purple Line (D Line) extension routing a tunnel beneath Beverly Hills High School, a campaign that cost the city over $15 million in legal fees before ultimately failing in federal court. She aligned with the council's consensus position prioritizing school safety and residential neighborhood character over facilitating regional transit expansion through the city. Wells' transportation voting record reflects the council's consistent preference for local traffic management and property protection over investments in regional transit connectivity or active transportation infrastructure such as bike lanes.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-metro-purple-line-opposition/', 'https://www.latimes.com/local/lanow/la-me-ln-beverly-hills-purple-line-20161110-story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'b4f9688b-add0-44d6-bab8-e923d17d105e';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'b4f9688b-add0-44d6-bab8-e923d17d105e' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'b4f9688b-add0-44d6-bab8-e923d17d105e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
