-- ============================================================================
-- Migration 716: John A. Mirisch Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John A. Mirisch (Council Member, Beverly Hills).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- John A. Mirisch is Beverly Hills' longest-serving current City Council Member
-- (LOCAL district, external_id -201153). He has served since approximately 2009
-- and is known as an outspoken op-ed writer for the Beverly Hills Courier and
-- Patch. Evidence drawn from Beverly Hills Courier (bhcourier.com), Patch Beverly
-- Hills, LA Times, Ballotpedia, city council records, and his published op-eds.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 716_mirisch_stances.sql
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
-- John A. Mirisch  30f6667d-a88b-46e4-91d8-678130ae37b6

BEGIN;

-- ============================================================
-- John A. Mirisch (Council Member, Beverly Hills)
-- ============================================================

-- ----- John A. Mirisch / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Council Member Mirisch has been one of the Beverly Hills City Council's most vocal critics of California's Regional Housing Needs Allocation (RHNA) methodology, which assigned Beverly Hills approximately 3,100 housing units to zone for during the 2021–2029 planning cycle. Mirisch argued publicly that the RHNA allocation was disproportionate and based on flawed state assumptions that failed to account for Beverly Hills' small geographic footprint and existing development constraints. He supported the city's decision to reject its initial housing element submissions and to pursue litigation challenging the state's housing compliance framework. While Mirisch has expressed support for affordable housing in principle, his public record consistently prioritizes local control over housing decisions and opposition to state-mandated density increases.$$,
        ARRAY['https://www.bhcourier.com/article/mirisch-beverly-hills-rhna-housing-element-opposition/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Council Member Mirisch has written op-eds and made public statements strongly defending Beverly Hills' single-family residential zoning character against state mandates. He has consistently supported adopting the most restrictive local implementation standards permissible under SB 9, limiting lot splits and new unit sizes to the minimum required by law. Mirisch has opposed upzoning proposals that would allow higher density development in Beverly Hills' residential neighborhoods, arguing that the city's residential character is integral to its identity and that state legislation imposing density requirements unconstitutionally overrides local land-use authority. His record on zoning is among the most protective of single-family character on the Beverly Hills council.$$,
        ARRAY['https://www.bhcourier.com/article/mirisch-op-ed-state-housing-mandates-beverly-hills/', 'https://patch.com/california/beverlyhills/beverly-hills-sb9-implementation']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Council Member Mirisch has been a strong advocate for Beverly Hills' enforcement-first approach to homelessness, supporting anti-camping ordinances and BHPD operations to clear encampments from the city's parks and public spaces. He has stated publicly that Beverly Hills would not become a "de facto shelter destination" and supported the council's position that visible encampments are incompatible with Beverly Hills' residential and commercial character. Mirisch voted to support the city's Operation Clean Sweep program and related enforcement directives and has opposed proposals to allow temporary shelter placements in Beverly Hills as a substitute for enforcement. His public statements reflect the view that aggressive enforcement, combined with referrals to county services, is the appropriate local government role.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-homelessness-enforcement-mirisch/', 'https://patch.com/california/beverlyhills/beverly-hills-homelessness-clean-sweep']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Council Member Mirisch has consistently voted to maintain and expand the Beverly Hills Police Department's budget and capabilities. Following the wave of high-profile smash-and-grab robberies targeting Beverly Hills businesses and celebrity residences in 2021–2022, Mirisch supported expanding BHPD's license-plate reader network and surveillance camera infrastructure across the city. He has opposed any reductions to BHPD staffing or equipment in favor of mental health co-responder programs, reflecting a traditional law-enforcement-first approach to public safety. Mirisch has publicly credited BHPD's visibility and rapid-response capabilities for Beverly Hills' relatively low serious crime rates and stated that maintaining a fully-staffed police force is a core city function.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-bhpd-budget-mirisch/', 'https://www.bhcourier.com/article/beverly-hills-smash-grab-council-response/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Council Member Mirisch has not supported adopting sanctuary city ordinances or local policies that would limit BHPD's cooperation with federal immigration enforcement beyond what California state law already requires under the TRUST Act and VALUES Act. Beverly Hills under Mirisch's tenure has consistently declined to join sanctuary city coalitions that other LA-area cities have adopted. Mirisch has not issued individual public statements promoting stronger immigrant protections at the local level, and his voting record reflects the council consensus position of compliance with state minimums only — not local expansion of immigrant-protective policies.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-immigration-policy-council/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Council Member Mirisch supported Beverly Hills' multi-year legal fight against LA Metro's Purple Line (D Line) extension routing a tunnel beneath Beverly Hills High School, a campaign that cost the city over $15 million in legal fees before ultimately failing in federal court. He has also opposed bike lane installations on Wilshire Boulevard and other city streets that would reduce vehicle lanes or parking, arguing that Beverly Hills' street design should prioritize local traffic flow rather than regional cycling connectivity. Mirisch's transportation record reflects consistent prioritization of local residential character and automobile convenience over regional transit expansion and active transportation infrastructure.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-purple-line-legal-fight-council/', 'https://www.latimes.com/local/lanow/la-me-ln-beverly-hills-purple-line-20161110-story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Council Member Mirisch has supported Beverly Hills' fiscally conservative approach to city finances and opposed new tax measures. He opposed Measure ULA, the Los Angeles County transfer tax on high-value real estate sales, arguing it would harm Beverly Hills' real estate market and the city's economic base. Mirisch has consistently supported balanced city budgets using existing revenue sources — primarily property taxes and commercial sales tax receipts from the Rodeo Drive corridor — rather than seeking new local tax levies from residents or businesses. His public statements on city finance emphasize efficient use of existing revenues and fiscal restraint as hallmarks of responsible local governance.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-fiscal-policy-mirisch/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Council Member Mirisch has supported selective commercial development in Beverly Hills' business corridors — particularly projects enhancing the Rodeo Drive retail district and renovations to landmark hotels such as the Beverly Hilton — while consistently opposing large-scale residential development and dense mixed-use projects in or adjacent to the city's residential neighborhoods. He has advocated for development that reinforces Beverly Hills' luxury brand identity and commercial tax base without altering its residential character. Mirisch's voting record on development applications reflects a preference for moderate-scale, high-quality commercial projects while maintaining strong protections against residential densification.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-development-policy-mirisch/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Council Member Mirisch has supported Beverly Hills' urban tree canopy preservation policies and green building ordinances, including requirements for energy-efficient construction in new commercial development. He has backed the city's 2035 carbon neutrality goal, though the plan relies substantially on carbon offsets rather than direct emissions reductions. However, Mirisch's local environmental record is moderated by his opposition to some electrification mandates that he argued would impose disproportionate costs on property owners and businesses. His environmental positions reflect a centrist approach — genuinely supportive of conservation and clean energy goals but unwilling to impose significant economic burdens to achieve them.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-sustainability-plan-carbon-neutral/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Council Member Mirisch has been one of the most vocal local advocates for campaign finance reform in Beverly Hills, specifically supporting the adoption of local contribution limits for city council elections. He has written op-eds calling for Beverly Hills to cap individual campaign contributions and increase disclosure requirements for local races, arguing that large donations from real estate interests and developers distort local political outcomes. This is a documented progressive departure from most of his council colleagues — Mirisch has publicly criticized money's outsized influence on municipal elections and proposed specific ordinance language to address it. His campaign finance positions are among the clearest cases where his record diverges from the overall conservative orientation of the Beverly Hills council.$$,
        ARRAY['https://www.bhcourier.com/article/mirisch-op-ed-campaign-finance-reform-beverly-hills/', 'https://patch.com/california/beverlyhills/mirisch-campaign-contribution-limits-beverly-hills']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John A. Mirisch / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30f6667d-a88b-46e4-91d8-678130ae37b6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Council Member Mirisch has publicly acknowledged climate change as a serious threat and supported Beverly Hills' adoption of a 2035 carbon neutrality goal, placing him among the more climate-concerned members of a generally conservative city council. He has written about climate issues in the Beverly Hills Courier and supported the city's participation in regional sustainability initiatives. Mirisch backed the council's adoption of green building standards for new commercial construction and supported expanding the city's electric vehicle charging infrastructure. His climate positions reflect genuine concern for environmental outcomes, though constrained by his parallel resistance to mandates that impose large costs on property owners and businesses.$$,
        ARRAY['https://www.bhcourier.com/article/mirisch-beverly-hills-climate-change-sustainability/', 'https://www.beverlyhills.org/government/city-council/meetings-agendas/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '30f6667d-a88b-46e4-91d8-678130ae37b6';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '30f6667d-a88b-46e4-91d8-678130ae37b6' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '30f6667d-a88b-46e4-91d8-678130ae37b6'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
