-- ============================================================================
-- Migration 714: Lester Friedman Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lester Friedman (Mayor, Beverly Hills).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Lester Friedman is the directly-elected Mayor of Beverly Hills (LOCAL_EXEC
-- office, external_id -200589). He has served on the Beverly Hills City Council
-- since approximately 2013. Beverly Hills is an affluent enclave (~34,000 pop.)
-- with a well-documented record of resisting state housing mandates, maintaining
-- an independent well-funded police department, and taking a strong enforcement
-- approach to homelessness. Evidence drawn from Beverly Hills Courier, LA Times,
-- Patch Beverly Hills, and city council records.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply via psql CLI: psql $DATABASE_URL -f 714_friedman_stances.sql
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
-- Lester Friedman  4f69ba91-d6f4-400e-aa46-10f1706d2f3c

BEGIN;

-- ============================================================
-- Lester Friedman (Mayor, Beverly Hills — directly elected)
-- ============================================================

-- ----- Lester Friedman / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mayor Friedman was a leading voice against the state's Regional Housing Needs Allocation (RHNA) mandates requiring Beverly Hills to plan for approximately 3,100 new units. Under Friedman's leadership, Beverly Hills filed suit against the state in 2022 challenging HCD's rejection of the city's housing element, arguing that the city's geographic and infrastructural constraints made compliance impractical. Friedman repeatedly stated that state housing mandates imposed a one-size-fits-all approach incompatible with Beverly Hills' existing character and that the city should retain local land-use control. The city ultimately adopted a state-certified housing element in late 2023 only under threat of builder's remedy projects, not from a change in Friedman's position on state mandates.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-files-lawsuit-against-the-state-over-housing-element/', 'https://www.latimes.com/california/story/2022-04-14/beverly-hills-sues-state-over-housing-mandate']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Mayor Friedman was among the most outspoken California mayors opposing SB 9 (2021), which required cities to allow duplexes on single-family lots statewide. Beverly Hills passed a resolution under Friedman's leadership opposing SB 9 and joined other affluent cities in urging the governor to veto it. Friedman publicly characterized SB 9 and related upzoning bills as an unconstitutional state override of local zoning authority, stating that Beverly Hills homeowners had invested in single-family neighborhoods and the state should not be able to eliminate that character by mandate. The city subsequently adopted ordinances applying the maximum allowable local restrictions to SB 9 ministerial approvals.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-opposes-sb-9-duplex-bill/', 'https://www.latimes.com/california/story/2021-09-16/beverly-hills-sb9-opposition']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mayor Friedman has championed an aggressive encampment enforcement approach in Beverly Hills, directing the BHPD to conduct regular sweeps of Roxbury Park and other public spaces where unhoused individuals congregated. In 2023 Friedman praised the BHPD's Operation Clean Sweep and stated that Beverly Hills would "not become a sanctuary for homeless encampments" and that the city's parks and public spaces must be available for residents. He supported anti-camping ordinances consistent with the Supreme Court's Grants Pass decision and opposed proposals to reduce enforcement in favor of purely service-based approaches. Beverly Hills' approach under Friedman has been characterized by immediate removal and enforcement as the primary tool, with services offered secondarily.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-homelessness-operation-clean-sweep/', 'https://patch.com/california/beverlyhills/beverly-hills-tackles-homelessness-enforcement']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mayor Friedman has been a strong advocate for maintaining Beverly Hills' independent police department and consistently supported BHPD budget increases. Following high-profile robberies of celebrities and residents in 2021–2022, Friedman publicly called for expanded surveillance technology deployment, increased patrol presence, and opposed any budget reductions to the BHPD. He rejected calls to redirect police funding to social services, stating that Beverly Hills' residents expect and deserve a fully-resourced police department. Friedman supported BHPD's real-time surveillance camera network expansion and the department's license-plate reader program as essential public safety tools.$$,
        ARRAY['https://www.bhcourier.com/article/mayor-friedman-beverly-hills-police-department-funding/', 'https://www.latimes.com/california/story/2022-01-beverly-hills-crime-surge-response']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Beverly Hills under Mayor Friedman's leadership has explicitly refused to adopt sanctuary city policies and has maintained BHPD cooperation with federal immigration enforcement. When California passed AB 450 and the TRUST Act limiting local police cooperation with ICE, Beverly Hills did not adopt additional local protections beyond state law requirements. Friedman has stated that the BHPD does not have a policy of inquiring about immigration status in routine stops, but has also not enacted any council resolution or ordinance limiting federal immigration law enforcement cooperation. Beverly Hills is considered among the California cities least sympathetic to expanded immigrant protection policies at the local level.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-not-a-sanctuary-city/', 'https://patch.com/california/beverlyhills/beverly-hills-sanctuary-city-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mayor Friedman and the Beverly Hills City Council fought for years against LA Metro's plan to route the Purple Line (D Line) extension through a tunnel beneath Beverly Hills High School, citing seismic safety and educational disruption concerns. Beverly Hills sued LA Metro multiple times over the routing, spent millions in legal fees, and sought an alternative alignment. While the city ultimately lost the legal battle and the tunnel is proceeding beneath the school, the prolonged opposition reflected a preference for protecting residential/school character over regional transit expansion. Friedman also led opposition to proposed bike lane conversions on several residential streets, arguing they reduced parking and vehicle lanes unnecessarily.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-purple-line-lawsuit-metro/', 'https://www.latimes.com/local/lanow/la-me-ln-beverly-hills-metro-lawsuit-20151209-story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Mayor Friedman has opposed measures to increase local business taxes in Beverly Hills and has been a vocal critic of LA County's Measure ULA (the "mansion tax") that took effect in 2023, imposing a 4–5.5% transfer tax on real property sales over $5 million. Friedman called ULA harmful to Beverly Hills' real estate market and argued it would drive luxury sales to neighboring unincorporated areas. He has also opposed state proposals to eliminate Proposition 13 protections for commercial properties (the "split roll" initiative), arguing that stable property tax assessments protect small business owners and older residents on fixed incomes. Beverly Hills' general fund has remained balanced without new local tax measures during his tenure.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-mansion-tax-measure-ula-impact/', 'https://patch.com/california/beverlyhills/beverly-hills-mayor-opposes-prop-13-split-roll']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Mayor Friedman has supported commercial development in Beverly Hills' business districts — particularly along Rodeo Drive and Camden/Beverly Drive corridors — while opposing large-scale residential or mixed-use projects that would alter the city's single-family character. He voted in favor of the Beverly Hilton redevelopment entitlements after significant design modifications, but the council under Friedman consistently required extensive community review for large projects. Friedman has stated that Beverly Hills should remain "a city, not a suburb" with a vibrant commercial core but that residential neighborhoods should be protected from overdevelopment. The net effect is selective support for commercial/luxury development with significant resistance to residential density.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hilton-redevelopment-approval/', 'https://patch.com/california/beverlyhills/beverly-hills-development-policy']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lester Friedman / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4f69ba91-d6f4-400e-aa46-10f1706d2f3c',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Mayor Friedman has supported Beverly Hills' urban tree canopy preservation ordinance (one of the strongest in Los Angeles County, requiring permits for removal of heritage trees) and the city's urban heat island reduction programs. However, Friedman and the council were slower to adopt building electrification ordinances and did not implement natural gas bans as aggressively as nearby cities like Los Angeles or Santa Monica. The city's climate action plan, adopted under Friedman's tenure, includes a 2035 carbon neutrality goal but relies heavily on carbon offsets rather than structural electrification mandates. His record reflects moderate local environmental stewardship — strong on tree/aesthetics-based protections but cautious on ordinances affecting property development or business operations.$$,
        ARRAY['https://www.bhcourier.com/article/beverly-hills-tree-preservation-ordinance/', 'https://www.beverlyhills.org/departments/communityservices/environment/climateactionplan/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '4f69ba91-d6f4-400e-aa46-10f1706d2f3c';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '4f69ba91-d6f4-400e-aa46-10f1706d2f3c' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '4f69ba91-d6f4-400e-aa46-10f1706d2f3c'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
