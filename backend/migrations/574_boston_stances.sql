-- ============================================================================
-- Migration 574: Boston City Officials Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for 14 Boston city officials:
--   At-large: Mayor Michelle Wu, Councillors Louijeune, Mejia, Murphy, Santana
--   District: Coletta Zapata (D1), Flynn (D2), FitzGerald (D3), Worrell (D4),
--             Pepén (D5), Weber (D6), Culpepper (D7), Durkan (D8), Breadon (D9)
--
-- Total rows: 162 (81 at-large + 81 district; 3 dropped for ambiguity)
-- Dropped: Flynn/voting-rights (status-quo posture), Flynn/school-vouchers
--          (charter≠voucher), Weber/school-vouchers (inferential only)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP.
-- Research CSV sources:
--   backend/data/stance-research/2026-06-12-boston-wu-atlarge.csv
--   backend/data/stance-research/2026-06-12-boston-district-councillors.csv
-- ============================================================================

-- Politician UUID reference:
-- Michelle Wu                d63def16-7510-4745-83d8-01901e450429
-- Ruthzee Louijeune          1e3a621a-2424-469e-8c1a-7a0dd635d3a2
-- Julia M. Mejia             cd9d9fd5-c20f-4b57-9065-f52516adca84
-- Erin J. Murphy             c9419f85-8e38-4b64-a816-7b3caba5c674
-- Henry Santana              3bd4af01-0ce8-415f-87fa-09dc248ca6cc
-- Gabriela Coletta Zapata    c3007368-5c5d-4933-8bb3-048d9df6a411
-- Edward M. Flynn            b8c7510c-20d7-4bd7-a765-07b77d3a5b6c
-- John FitzGerald            3b546ec5-a7fe-4f64-9537-a19c58809631
-- Brian Worrell              9f94a985-cb9d-497b-bd36-fffa48931ab2
-- Enrique J. Pepén           ce971c69-7b28-49f2-b530-783291a08863
-- Benjamin J. Weber          703f9005-8767-4c2b-97c1-155b3fc36fee
-- Miniard Culpepper          10a52f8b-bd19-4076-9a8f-46ae2e8552ce
-- Sharon Durkan              161c754c-2161-49aa-9722-f0e5dbc07cef
-- Liz Breadon                6e63a642-91f7-4c2b-949d-b3a936e6343e

BEGIN;
-- ----- Michelle Wu / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wu urged Massachusetts lawmakers to adopt the Roe Act in 2019 to codify Roe v. Wade protections and has stated she supports protecting access to abortion care. Her position aligns with keeping abortion legal and accessible at least through the second trimester — she has not publicly advocated for full public funding at all stages of pregnancy, nor supported restrictions below standard trimesters. Value 2 best matches her documented record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wu signed a fossil fuel divestment ordinance in November 2021 divesting $65 million from fossil fuel companies, signed an executive order in July 2023 halting fossil fuels in new municipal buildings, and set goals of 100% renewable energy citywide by 2030 and carbon neutrality by 2040. She implemented BERDO requiring large buildings to reach net-zero by 2050 and established the Boston Climate Council. This is a rapid renewable-energy-transition agenda aligned with value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment', 'https://www.boston.gov/departments/environment/berdo']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wu signed an executive order in July 2023 halting fossil fuels in all new municipal buildings, proposed a Home Rule Petition for a municipal fossil fuel ban in new buildings, and signed a $65 million fossil fuel divestment ordinance in November 2021. At every level of city authority available to her, she has moved to stop new fossil fuel investment and infrastructure — consistent with value 2: stop issuing new permits and funding for fossil fuels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wu co-authored a city ordinance guaranteeing comprehensive healthcare including gender-affirming care to transgender city employees, and has consistently backed expanded coverage through public programs and regulated private insurance. She has not called for a fully public single-payer system, but her public record reflects support for ensuring everyone has affordable coverage through a mix of public programs and regulated private insurance — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wu has pursued rent stabilization through a Home Rule Petition (March 2023), established Inclusionary Zoning requiring 15-17% affordable units in market-rate developments of 7+ units (effective October 2024), created the Boston Acquisition Fund to preserve affordable multi-family housing, and signed an executive order eliminating parking minimums for affordable developments. Her approach combines rent caps, inclusionary requirements, and publicly funded affordable housing — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/housing/rent-stabilization', 'https://www.boston.gov/departments/neighborhood-development']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wu is the nation's most prominent sanctuary-city defender: she has upheld the Boston Trust Act (which lets all immigrants use public services without immigration-status inquiry), testified before Congress defending these policies in March 2025, and issued an executive order in June 2025 affirming due process rights regardless of status. She stated the city does not ask about immigration status when delivering services — consistent with value 2: keep legal immigration open and let most residents use public services regardless of status.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Wu explicitly stated she does not support mass deportation, calling it devastating for the economy and for millions of people running small businesses and attending schools. She defended the Boston Trust Act, which limits police referrals to criminal detainers only — not civil immigration status. Her position is consistent with value 2: only deport people convicted of serious violent crimes, protecting everyone else.$$,
        ARRAY['https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://en.wikipedia.org/wiki/Michelle_Wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$The Boston Trust Act — which Wu has vigorously defended in court and before Congress — prohibits Boston police from honoring civil ICE detainers and from inquiring about or sharing immigration status with federal authorities. Her June 2025 executive order reinforced these protections. She stated police cooperate only on criminal detainers, not civil immigration enforcement. This is value 1: refuse all civil ICE detainers and prohibit city employees from sharing immigration status.$$,
        ARRAY['https://commonwealthbeacon.org/politics/are-you-out-of-your-mind-five-moments-from-mayor-michelle-wus-immigration-testimony/', 'https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Wu championed fare-free public transit (Routes 23, 28, 29 made free in 2022), proposed eliminating MBTA fares entirely in a 2019 op-ed, oversaw Vision Zero's 'people-first approach' targeting pedestrians and cyclists, reduced parking requirements for affordable developments, funded Better Bike Lanes and Neighborhood Slow Streets citywide, and Go Boston 2030 targets a 50% reduction in drive-alone commuting. This record is firmly at value 1: prioritize pedestrian infrastructure, cycling, and public transit while reducing parking requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/transportation/vision-zero', 'https://www.boston.gov/departments/transportation/go-boston-2030']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wu signed the Affirmatively Furthering Fair Housing policy in January 2022 (making Boston the largest U.S. city with such a policy), assembled a diverse cabinet across racial backgrounds, organized an Electeds of Color affinity group, awarded the largest non-construction contract in city history to a Black-owned business, and co-authored anti-discrimination ordinances protecting transgender employees. Her record reflects strengthening civil rights enforcement and addressing systemic discrimination — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wu co-authored an ordinance in June 2014 guaranteeing comprehensive healthcare including gender-affirming care to transgender city employees, and has been a consistent public advocate for full LGBTQ equality. Her record and public statements support full federal recognition of same-sex marriages with complete protections and benefits — value 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wu moved hundreds of unhoused individuals from Mass and Cass to temporary housing in her early months as mayor, connecting them to services rather than using criminal penalties. Boston secured $4 million in state funding for Mass and Cass services. Her approach focuses on outreach, shelter, and housing placements rather than criminalization — consistent with value 2: decriminalizing public sleeping while investing in shelter capacity and voluntary service connections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/homelessness', 'https://www.nbcboston.com/tag/michelle-wu/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Wu's approach to homelessness centers on connecting people to services and shelter rather than enforcement. She cleared the Mass and Cass encampment only after providing housing placements to displaced individuals, and secured state and federal funds for outreach and shelter services. The Boston Public Health Commission operates over 40 programs including emergency shelter and recovery services. Her primary strategy is expanding shelter and services — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/homelessness', 'https://www.boston.gov/departments/boston-public-health-commission']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Wu submitted a Home Rule Petition in March 2023 seeking state permission for rent stabilization (capping annual rent increases), established a Rent Stabilization Advisory Committee in March 2022, and endorsed the state ballot measure for rent control in February 2026. She has also strengthened tenant protections through the Boston Acquisition Fund preserving affordable multi-family homes. Her position is to strengthen existing rent stabilization and extend its coverage — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/housing/rent-stabilization']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Wu signed an executive order eliminating parking minimums for affordable developments with 60%+ income-restricted units, implemented Inclusionary Zoning requiring 15-17% affordable units in 7+ unit market-rate developments, and explored ADUs through the Housing Innovation Lab. However, she has not pursued broad upzoning or elimination of single-family zoning citywide. Her approach allows multifamily and mixed-use development alongside affordable requirements, while maintaining most residential zone protections — value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/neighborhood-development', 'https://www.boston.gov/housing/housing-innovation-lab']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Wu vetoed a $5 million police budget cut in June 2023 calling it 'illusory,' appointed Police Commissioner Michael Cox, negotiated accountability reforms in the police contract (officers lose arbitration appeals for certain convictions, public pay transparency), and achieved record-low gun violence. As councilor she introduced an unarmed community safety crisis response ordinance in June 2020. Her approach keeps current police staffing while adding crisis response teams — value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Boston's economic development under Wu emphasizes supplier diversity, small business support, and community wealth-building over large corporate tax abatements. Wu called for government transparency around corporate tax breaks as city councilor and introduced an ordinance to that effect in 2019. The city's economic development department explicitly focuses on equitable procurement and local entrepreneur programs — consistent with value 2: small business support and avoiding large corporate subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/economic-development', 'https://www.boston.gov/departments/small-business']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wu created the Cabinet for Worker Empowerment in September 2022 tasked with establishing a childcare trust fund, expanded developer contributions to childcare, launched the Essential Worker Childcare Fund and Stimulus and Stability Fund for childcare centers, and expanded Universal Pre-K programming. The Office of Early Childhood is accelerating a universal pre-K system. Her record is consistent with value 2: significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/early-childhood', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wu pursued a temporary property tax shift to protect middle-class homeowners from spikes caused by declining commercial property values, stating residents would face consequences if the legislature did not act. As city councilor she introduced ordinances for corporate tax transparency. Her fiscal approach prioritizes protecting lower- and middle-income residents through tax policy — moderately aligned with value 2: modestly raising or shifting taxes on commercial and high-value properties to fund existing services.$$,
        ARRAY['https://commonwealthbeacon.org/government/state-government/spilka-hosts-opposing-camps-on-wus-property-tax-shift-proposal/', 'https://en.wikipedia.org/wiki/Michelle_Wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Wu has pursued proactive infrastructure investment alongside housing production — expanding affordable housing, transit-oriented development, and the Boston Planning Advisory Council to plan ahead of growth. She has not imposed growth limits or required voter approval for developments, nor has she removed all regulatory barriers. Her approach of planning proactively and investing in infrastructure to support responsible expansion is consistent with value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/transportation/go-boston-2030', 'https://www.boston.gov/departments/neighborhood-development']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Wu signed an executive order eliminating parking minimums for affordable developments, implemented BERDO requiring building emissions reductions, doubled annual tree planting, launched a Heat Resilience for Boston plan targeting environmental justice communities, and passed a wetlands protection ordinance. Developers operating in Boston face significant environmental review and offset requirements. This reflects value 2: protecting parks and tree canopy and requiring developers to fully offset environmental impacts.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/environment', 'https://www.boston.gov/departments/environment/berdo']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$The Wu administration has invested in sanitation improvements with an equity lens, prioritizing historically underserved neighborhoods. Her environmental justice framing across climate, heat resilience, and community clean air programs reflects a commitment to equalizing service levels across neighborhoods. This aligns with value 2: increasing sanitation investment and prioritizing underserved neighborhoods to equalize cleanliness citywide.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wu has been a consistent and vocal public school advocate who funded summer jobs for all BPS students, expanded Universal Pre-K in public school settings, and made museums free for school-age children through public investment. She has not supported diverting public education funds to private institutions through vouchers. Her platform explicitly centers fully funding public schools — value 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Wu co-authored an ordinance in June 2014 guaranteeing healthcare including gender reassignment surgery and hormone therapy to transgender city employees, with no restrictions on eligibility based on biological sex assignment. Her record reflects full inclusion of transgender individuals in all public programs and institutions — consistent with value 1: allow all transgender athletes to compete on teams matching their gender identity without restrictions.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Wu introduced an ordinance as city councilor in June 2020 establishing an unarmed community safety crisis response system as an alternative to policing and incarceration. Her administration has invested in mental health co-responders, diversion programs, and addiction treatment rather than building new jail capacity. Her record aligns with value 2: reducing incarceration through pretrial diversion and treatment alternatives rather than expanding jail capacity.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Wu co-authored an ordinance prohibiting city contracting with health insurers that discriminate based on gender identity and has consistently protected LGBTQ employees from discrimination. Her record reflects protecting religious freedom while ensuring it does not override anti-discrimination protections in employment and city services — value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://www.boston.gov/departments/mayors-office/michelle-wu']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle Wu / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d63def16-7510-4745-83d8-01901e450429',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Wu has backed transparency measures for corporate tax breaks and political spending through her city council record. While she has accepted Super PAC support from labor unions, her legislative record favors strict limits on corporate political donations and dark money — not just disclosure. Her overall position aligns with value 2: strictly limiting corporate donations and dark money groups.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Wu', 'https://commonwealthbeacon.org/politics/super-pac-aligned-with-mayor-wu-receives-six-figure-donation/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Louijeune co-authored a resolution urging Mayor Wu to raise affordable unit requirements in new developments from 13% to 20% (and lower the threshold to 5+ unit buildings), passed legislation prioritizing conversion of surplus municipal buildings into affordable housing, and secured additional city housing vouchers through budget advocacy. She also advanced anti-displacement strategies including the Acquisition Opportunity Program. This record fits value 2: requiring new developments to include affordable units and publicly funding new housing.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Louijeune co-introduced the resolution (unanimously adopted, June 2022) apologizing for Boston's historical role in the Atlantic slave trade, chaired the Committee on Civil Rights and Immigrant Advancement, codified the Office of Returning Citizens to protect reentry rights, and centered civil rights and equity throughout her work. Her record consistently reflects value 2: strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Louijeune voted in December 2023 to approve a home rule petition granting local election voting rights to legal immigrants (noting over 28% of Boston's population are immigrants with legal status), expanded support for immigrants and new arrivals as a council priority, and chaired the Committee on Civil Rights and Immigrant Advancement. She condemned Trump's anti-Haitian targeting (September 2024). Her position fits value 2: keep legal immigration open and let most residents use public services regardless of legal status.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Louijeune chaired the Committee on Civil Rights and Immigrant Advancement, voted in favor of immigrant voting rights, and publicly condemned Trump's anti-Haitian rhetoric targeting Haitian immigrants in September 2024. Her consistent advocacy for immigrant communities is incompatible with mass deportation. Her record fits value 2: only deport people convicted of serious violent crimes, protecting all other residents.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Louijeune has been a vocal supporter of Boston's sanctuary city policies and championed expanded support for immigrants and new arrivals. She chaired the Committee on Civil Rights and Immigrant Advancement and advocated for Boston's LGBTQIA+ Sanctuary City designation, which extends protections to LGBTQ immigrants. Her record is consistent with value 1: refusing civil ICE detainers and prohibiting city employees from sharing immigration status with federal agencies.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Louijeune was a leading advocate for Boston's LGBTQIA+ Sanctuary City designation and has consistently defended LGBTQ+ rights throughout her council career. As the first Haitian American elected to Boston's city government, she has linked immigrant and LGBTQ protections as inseparable civil rights issues. Her record reflects value 1: requiring all states to recognize same-sex marriages and provide full federal benefits and protections.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Louijeune championed Boston's LGBTQIA+ Sanctuary City designation, which explicitly includes protections for transgender individuals, and has consistently defended full LGBTQ+ rights without carve-outs. There is no evidence she has supported restrictions on transgender athlete participation. Her overall LGBTQ rights record is consistent with value 1: allowing all transgender athletes to compete on teams matching their gender identity without restrictions.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Louijeune was the lead sponsor of Boston's 2025 home rule petition for ranked choice/instant runoff voting (council voted 8-4 to approve in May 2025), voted in December 2023 to expand local voting rights to legal immigrants, and fought voting rights cases before the U.S. Supreme Court in her legal career. Her record reflects value 2: expanding voter access broadly including mail-in voting and early voting, while opposing suppression.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Louijeune is a Boston Public Schools alumna who has championed investments in student mental health services, advocated for school facilities improvements, promoted fair wages for educators, and expanded language access for BPS families. Her entire education platform centers strengthening public schools. Her record is consistent with value 1: fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Louijeune advanced community-centered violence prevention approaches, provided survivor support services, and codified the Office of Returning Citizens (ORC) for long-term reentry support — reflecting a philosophy of shifting some public safety investment toward community programs. She served on the Public Safety and Criminal Justice committee. Her record fits value 2: maintaining current police staffing while shifting non-violent calls to unarmed mental health co-responders.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ruthzee Louijeune / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Louijeune codified the Office of Returning Citizens (ORC) to support reintegration, championed community-centered violence prevention over incarceration-first approaches, and served on the Public Health, Homelessness, and Recovery committee. Her record reflects reducing the incarcerated population through community alternatives and reentry support rather than building jail capacity. This fits value 2: reducing incarceration through diversion and treatment alternatives.$$,
        ARRAY['https://www.boston.gov/departments/city-council/ruthzee-louijeune', 'https://en.wikipedia.org/wiki/Ruthzee_Louijeune']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Mejia has actively worked to strengthen the Boston Trust Act by closing data-sharing loopholes so local institutions such as schools, health centers, and faith centers cannot share immigration status with federal agencies. Her June 2025 re-election letter declared her intent to make Boston an LGBTQIA2S+ Sanctuary City and she voted against BRIC funding citing the gang database's racial profiling of Black and Brown immigrants. This record fits value 1: refuse all civil ICE detainers and prohibit city employees from sharing immigration status information with federal agencies.$$,
        ARRAY['https://www.boston.gov/departments/city-council/julia-mejia', 'https://juliaforboston.com/about/', 'https://www.dotnews.com/2023/10/25/three-councillors-three-decisions-how-single-vote-can-alter-city-life/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Mejia is an immigrant herself (from the Dominican Republic) who has made immigrant protection a centerpiece of her council work — establishing the Office of Immigrant Advancement, opposing BRIC's gang database that targets Black and Brown immigrants, and declaring Boston a sanctuary city for LGBTQIA2S+ residents including undocumented immigrants. She stated she is 'prepared to stand up to Trump' on immigration and focuses on educating immigrants about their rights. This fits value 2: keep legal immigration open and let most residents use public services regardless of legal status.$$,
        ARRAY['https://www.boston.gov/departments/city-council/julia-mejia', 'https://juliaforboston.com/about/', 'https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Mejia is a Dominican-born immigrant who has consistently defended undocumented residents, declared Boston an LGBTQIA2S+ sanctuary city protecting undocumented immigrants, and fought against BRIC funding whose gang database disproportionately targets immigrants of color. She has not called for stopping all deportations but has organized to protect immigrant communities from enforcement actions broadly. This fits value 2: only deport people convicted of serious violent crimes.$$,
        ARRAY['https://www.boston.gov/departments/city-council/julia-mejia', 'https://juliaforboston.com/about/', 'https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mejia supports rent control, has advocated for requiring 50% affordable units in new developments as an opening negotiating position, co-sponsored a displacement tax to fight gentrification, and has called for 'robust policies that lower housing costs, preserve public housing, and fight displacement.' She has stated she wants policies that partner with developers 'doing the right thing' on affordability. This combination of rent caps, inclusionary requirements, and displacement protections fits value 2.$$,
        ARRAY['https://commonwealthbeacon.org/politics/riding-high-on-1-vote-win-for-city-council/', 'https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/', 'https://www.dotnews.com/2025/06/25/julia-mejia-my-job-be-your-microphone/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$At a May 2025 candidate forum, Mejia voted yes in a speed round on statewide rent control. She has backed rent control since at least 2019, co-sponsored a displacement tax to fight gentrification, and has called for policies that lower housing costs and prevent displacement. Her support for statewide rent control extends beyond existing stabilization — fitting value 1: expand rent control to all rental units with strong tenant protections and just-cause eviction requirements.$$,
        ARRAY['https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/', 'https://commonwealthbeacon.org/politics/riding-high-on-1-vote-win-for-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Mejia sponsored and led the 2022 City Council ordinance establishing Boston's Reparations Task Force — making Boston one of the first major cities to study reparations. She also created the Office of Black Male Advancement (with $1.8M operating budget), passed the Fair Chance Act establishing a Chief Diversity Officer overseeing equity in hiring and promotion for minorities, women, LGBTQ+, and disabled employees, and made Juneteenth an official citywide holiday. This record of mandating racial equity requirements and pursuing reparations fits value 1.$$,
        ARRAY['https://juliaforboston.com/policy/', 'https://commonwealthbeacon.org/opinion/why-boston-should-pursue-reparations/', 'https://www.dotnews.com/2023/02/08/wu-taps-ten-reparations-panel/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Mejia created and codified the Office of LGBTQIA2S+ Advancement (with $1M+ budget), championed Boston's designation as a Trans and LGBTQIA2S+ Sanctuary City, filed an ordinance to establish an LGBTQIA2S+ Oversight Commission, and has consistently supported full LGBTQ+ equality with no carve-outs. Her record reflects value 1: require all states to recognize same-sex marriages and provide full federal benefits and protections.$$,
        ARRAY['https://juliaforboston.com/about/', 'https://juliaforboston.com/policy/', 'https://www.dotnews.com/2025/06/25/julia-mejia-my-job-be-your-microphone/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Mejia is leading the effort to make Boston a Trans and LGBTQIA2S+ Sanctuary City, codified the permanent Office of LGBTQIA2S+ Advancement, and has filed an ordinance for an LGBTQIA2S+ Oversight Commission. Her advocacy for transgender inclusion is unconditional and without restriction — consistent with value 1: allow all transgender athletes to compete on teams matching their gender identity without any restrictions.$$,
        ARRAY['https://juliaforboston.com/about/', 'https://juliaforboston.com/policy/', 'https://www.dotnews.com/2025/06/25/julia-mejia-my-job-be-your-microphone/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$In July 2020, Mejia co-sponsored an ordinance establishing an 'unarmed, trained alternative to 911 crisis response system' to shift non-violent calls to mental health professionals. She also co-sponsored a Civilian Review Board for the BPD and a transparency office for police misconduct data. In October 2023, she voted against BRIC gang database funding citing racial profiling. Her approach maintains police staffing while shifting non-violent calls to unarmed responders — fitting value 2.$$,
        ARRAY['https://www.dotnews.com/2020/07/02/councillors-propose-crisis-response-system-non-violent-911-calls/', 'https://www.dotnews.com/2020/07/15/pitch-civilian-review-board-probe-complaints-against-bpd/', 'https://www.dotnews.com/2023/10/25/three-councillors-three-decisions-how-single-vote-can-alter-city-life/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Mejia stated 'We have to address this with compassion. We can't arrest ourselves out of this situation' when discussing Mass and Cass in 2021. She voted 'present' on the October 2023 tent removal ordinance — neither endorsing nor opposing enforcement — and has consistently advocated for services-first approaches. The 'present' vote signals discomfort with criminalization rather than outright support for it. Her record fits value 2: decriminalizing public sleeping while investing in shelter capacity, outreach, and voluntary service connections.$$,
        ARRAY['https://www.dotnews.com/2021/10/27/st-brendan-s-large-candidates-weigh-mass-and-cass/', 'https://www.dotnews.com/2023/10/27/notices-warn-mass-and-cass-tent-removals-will-begin-nov-1/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mejia co-sponsored the 2020 ordinance establishing an unarmed crisis response system as an alternative to 911 — designed to divert people in mental health and addiction crises from the criminal justice system to services. She advocated for compassion-based approaches at Mass and Cass and voted 'present' rather than supporting enforcement-first tent removal. Her city-level homelessness strategy expands shelter capacity and services as the primary approach, using enforcement only as a last resort. Value 2 fits.$$,
        ARRAY['https://www.dotnews.com/2020/07/02/councillors-propose-crisis-response-system-non-violent-911-calls/', 'https://www.dotnews.com/2021/10/27/st-brendan-s-large-candidates-weigh-mass-and-cass/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Mejia co-sponsored the 2025 home rule petition for instant runoff voting (which passed 8-4 and was signed by Mayor Wu), lowered Boston's voting age to 16 for municipal elections, and co-sponsored the 2023 measure granting local voting rights to legal immigrants. These actions expand voter access and participation broadly — consistent with value 2: expand early voting and make voting accessible to all without strict requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Julia_Mejia', 'https://juliaforboston.com/policy/', 'https://www.dotnews.com/2025/08/20/survey-offers-new-insights-council-large-field/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Mejia serves as Vice Chair of the Census, Redistricting, and Elections committee and co-sponsored the 2025 home rule petition for instant runoff voting — a structural reform that reshapes how votes are counted and who draws effective political power. Her advocacy for participatory democracy, ranked choice voting, and co-governance models reflects support for independent or bipartisan oversight of electoral processes rather than pure party control. Value 2 fits.$$,
        ARRAY['https://www.boston.gov/departments/city-council/julia-mejia', 'https://en.wikipedia.org/wiki/Julia_Mejia', 'https://www.dotnews.com/2025/08/20/survey-offers-new-insights-council-large-field/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Mejia chairs the Education Committee, has championed public school funding (including restoring the elected school committee for democratic control), and has described charter schools as 'labs of innovation' that should partner with — not compete against — district public schools. Her platform centers public education investment and she has not supported voucher programs diverting funds to private institutions. Value 1: fully funding public schools and eliminating voucher programs.$$,
        ARRAY['https://www.boston.gov/departments/city-council/julia-mejia', 'https://juliaforboston.com/policy/', 'https://commonwealthbeacon.org/politics/riding-high-on-1-vote-win-for-city-council/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Mejia co-sponsored the July 2020 unarmed crisis response ordinance routing non-violent 911 calls to mental health professionals, co-sponsored the BPD Civilian Review Board, and voted against BRIC gang database funding on racial justice grounds. Her consistent approach substitutes community-based mental health and social interventions for incarceration rather than expanding jail capacity. Value 2: reducing incarceration through diversion and treatment alternatives.$$,
        ARRAY['https://www.dotnews.com/2020/07/02/councillors-propose-crisis-response-system-non-violent-911-calls/', 'https://www.dotnews.com/2020/07/15/pitch-civilian-review-board-probe-complaints-against-bpd/', 'https://www.dotnews.com/2023/10/25/three-councillors-three-decisions-how-single-vote-can-alter-city-life/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mejia championed the Retail Kitchen Ordinance — eliminating barriers for home food entrepreneurs and aspiring small business owners — and the Fair Chance Act establishing equitable hiring practices. Her website emphasizes small business development and community wealth-building rather than large corporate tax abatements. She has not supported large corporate subsidies. Value 2: small business support and local entrepreneur programs only; avoid large corporate subsidies.$$,
        ARRAY['https://juliaforboston.com/about/', 'https://juliaforboston.com/policy/', 'https://www.dotnews.com/2025/08/20/survey-offers-new-insights-council-large-field/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$In June 2020, Mejia was one of five council members who voted against Mayor Walsh's FY2021 operating budget, stating: 'I am no longer interested in having drip-drop incremental changes that expect us to continue to hope and pray and wait some more about finally having the type of budget that really reflects the needs our people find themselves in today.' In April 2026 she organized a speak-out around 'No taxation without representation' demanding the city not cut services to vulnerable communities. Her record reflects significantly raising spending on public services and rejecting budgets that fail low-income residents — value 1.$$,
        ARRAY['https://en.wikipedia.org/wiki/Julia_Mejia', 'https://www.dotnews.com/2026/04/21/councillors-advocates-press-team-wu-for-budget-answers/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Mejia has codified the Office of LGBTQIA2S+ Advancement and declared Boston a Trans and LGBTQIA2S+ Sanctuary City, reflecting a firm commitment to anti-discrimination protections. At the same time, her broader approach to governance emphasizes community-centered inclusivity across faith communities (the Trust Act protects people at faith centers regardless of status). Her record is consistent with value 2: protect religious freedom while ensuring it does not override anti-discrimination protections in employment and housing.$$,
        ARRAY['https://juliaforboston.com/about/', 'https://juliaforboston.com/policy/', 'https://www.dotnews.com/2025/06/25/julia-mejia-my-job-be-your-microphone/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Julia M. Mejia / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd9d9fd5-c20f-4b57-9065-f52516adca84',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mejia advocated for equity-based transportation reform (sliding-scale parking ticket fees based on income), stated that bike lane policy should not be 'one size fits all' suggesting neighborhood customization, and has consistently framed transportation access as an equity issue. Her equity-centered approach to transportation — investing in multiple modes while addressing barriers for low-income residents — fits value 2: invest equally in roads and multimodal options while ensuring bike infrastructure on new road projects.$$,
        ARRAY['https://www.dotnews.com/2020/03/05/mejia-asks-hearing-parking-tickets-tow-fees-reaction-council-mixed/', 'https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erin J. Murphy / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Murphy voted YES on accepting a $3.4 million state grant for the Boston Regional Intelligence Center (BRIC) in a 7-5 vote that split along racial lines in October 2023. She sided with six other white councillors in favor of the controversy-plagued police intelligence program while the five councillors of color voted no. She is consistently described as more conservative than most Boston City councillors on public safety and opposed the 2020 police budget cuts. This aligns with value 4: increase police resources and staffing to improve response times and deter crime.$$,
        ARRAY['https://commonwealthbeacon.org/criminal-justice/boston-city-council-approves-controversy-plagued-police-grants/', 'https://www.boston.gov/departments/city-council/erin-murphy']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erin J. Murphy / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$In June 2024 Murphy appeared at a roadside rally in Winthrop displaying signs reading 'Stop State Mandated Zoning' opposing the MBTA Communities rezoning law. While she claimed not to have taken a formal stance, her presence at an anti-upzoning protest and her statement supporting 'any group anywhere that feels as though things are being shoved upon them' reflects a preference for community control over housing density decisions — consistent with value 2: allow modest density increases with strong design review and neighborhood input.$$,
        ARRAY['https://commonwealthbeacon.org/politics/sjc-clerk-candidate-steps-into-mbta-communities-fight-thats-now-before-the-court/', 'https://www.boston.gov/departments/city-council/erin-murphy']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erin J. Murphy / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Murphy served as a Boston Public Schools teacher for over 20 years and is a proud Boston Teachers Union (BTU) member. Her campaign platform advocates for 'inclusive schools, expanded enrichment, and equitable resources' for public schools. As a career BPS teacher and union member she has no record of supporting school vouchers or private school diversion of public funds. Value 1: fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.$$,
        ARRAY['https://www.boston.gov/departments/city-council/erin-murphy', 'https://www.dotnews.com/opinion/erin-murphy']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erin J. Murphy / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9419f85-8e38-4b64-a816-7b3caba5c674',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Murphy chairs the Human Services Committee overseeing homeless services. Her platform cites expanding 'programs for seniors, youth, veterans, and working families' and advocating for substance use disorder and mental health services (raising $60,000 for the Gavin Foundation). Combined with her public safety stance (supportive of police), her approach reflects investing in outreach and mental health services while enforcing reasonable public space rules — value 3.$$,
        ARRAY['https://www.boston.gov/departments/city-council/erin-murphy', 'https://www.dotnews.com/opinion/erin-murphy']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Santana co-sponsored the 110 million dollar Housing Accelerator Fund and stated in his 2025 Dotnews questionnaire that he wants higher affordable housing requirements through inclusionary zoning and Mixed-Income Social Housing models — combining rent protection, inclusionary requirements, and publicly funded housing to expand affordable units and prevent displacement.$$,
        ARRAY['https://www.boston.gov/departments/city-council/henry-santana', 'https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Santana voted YES on statewide rent control legislation at a May 2025 candidate forum and his 2025 questionnaire states rent control deserves serious consideration as part of the fight to keep Boston affordable for everyone. He also supports protecting tenants from unfair evictions and building more affordable housing as part of a broader toolkit — consistent with strengthening existing rent stabilization and extending coverage.$$,
        ARRAY['https://www.dotnews.com/2025/05/27/council-forum-topics-run-gamut-affordable-housing-immigration-rent/', 'https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Santana supports zoning reform to spur development but pairs it with community-driven planning and strong tenant protections against displacement in his 2025 questionnaire. He supports inclusionary zoning and Mixed-Income Social Housing models while insisting on community input before changes — allowing multifamily and mixed-use development while protecting existing residential areas from displacement.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Santana stated in his 2025 questionnaire that increasing housing supply is essential but must be done in a way that protects existing residents and prevents displacement. He supports zoning reform and development incentives while insisting on community-driven planning and affordable housing investment — a proactive infrastructure-investment approach that neither imposes growth limits nor removes all regulatory barriers.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Santana stated in his 2025 questionnaire that his top priority for Mass and Cass is having more resources and support for those in addiction including somewhere safe and inside where they can sleep at night. He called for expanding the City Coordinated Response Team addressing homelessness, addiction, and public health — a services-first approach that decriminalizes while investing in shelter capacity and outreach.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Santana stated he wants more investment and expansion of the City Coordinated Response Team as the primary strategy for Mass and Cass — a services, outreach, and housing-placement approach. He supports immediate sanitation and safety interventions while building the long-term infrastructure for treatment and housing. This prioritizes shelter capacity and services as the primary strategy while allowing reasonable enforcement of public space rules.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Santana co-sponsored traffic calming and Safety Surge expansion, preserved a 27-mile green biking and walking path, expanded Bluebikes citywide, pushed for a municipal bus service for last-mile and late-night connections, and supported sidewalk improvements — all documented in his 2025 questionnaire. He stated investing in public transit, protected bike lanes, and safer streets makes Boston work for everyone.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$As Chair of the Public Safety Committee Santana worked to maintain historically low crime rates while implementing community-focused strategies. His 2025 questionnaire states we cannot arrest our way out of gun violence and explicitly supports violence interruption programs, wraparound services, and community-directed solutions alongside maintaining current police capacity. Value 3: keep current public safety funding while adding crisis response and community programs.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$In his 2025 questionnaire Santana stated he believes housing and healthcare are human rights. He co-sponsored a resolution calling for the Boston Public Health Commission to declare a public health emergency after Carney Hospital closure and pushed for expanded community health centers and mobile health units for underserved neighborhoods — consistent with ensuring everyone has affordable coverage through public programs and regulated private insurance.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Santana lists the MIRA Coalition — dedicated to informing and protecting immigrant communities — as a key civic affiliation in his 2025 questionnaire. He was reported in early 2026 as pressing Boston Police Department on collaboration with federal law enforcement, suggesting opposition to BPD-ICE cooperation. As a Dominican-born immigrant working with immigrant-protection organizations his record is consistent with refusing civil ICE detainers and prohibiting immigration status sharing.$$,
        ARRAY['https://www.boston.gov/departments/city-council/henry-santana', 'https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Santana was born in the Dominican Republic and explicitly lists the MIRA Coalition as a key civic affiliation in his 2025 questionnaire — a group dedicated to informing and protecting immigrant communities. His advocacy centers on keeping public services and opportunities accessible to all immigrant residents, consistent with value 2: keep legal immigration open and let most residents use public services regardless of legal status.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Santana is a Dominican-born immigrant who works with the MIRA Coalition to protect immigrant communities and who pressed BPD on federal law enforcement collaboration in early 2026 — consistent with opposing mass deportation. His record reflects protecting long-term immigrant residents from removal, aligning with value 2: only deport people convicted of serious violent crimes while protecting all others.$$,
        ARRAY['https://www.boston.gov/departments/city-council/henry-santana', 'https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Santana stated explicitly in his 2025 questionnaire that he proudly stands with the LGBTQIA2S+ community as a core political value. He also cited GBLC as an endorsing organization. His unconditional LGBTQIA2S+ support is consistent with value 1: require all states to recognize same-sex marriages and provide full federal benefits and protections.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Santana stated in his 2025 questionnaire he proudly stands with the LGBTQIA2S+ community with no carve-outs or restrictions. His political identity explicitly includes unconditional LGBTQIA2S+ support, consistent with value 1: allow all transgender athletes to compete on teams matching their gender identity without any restrictions or requirements.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Santana stated in his 2025 questionnaire that he proudly stands with the LGBTQIA2S+ community, partners with the MIRA Coalition on immigrant rights, and collaborates with DeeDee Cry on mental health resources for the Black community. He serves on civil rights and education committees focused on advancing opportunities for underrepresented communities — reflecting value 2: strengthen civil rights enforcement and address systemic discrimination.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Santana stated in his 2025 questionnaire he is a proud product of public schools and youth programs and supports returning to an elected School Committee for democratic accountability. He chairs the Education Committee focused on expanded bilingual education and financial literacy programs entirely within the public system. There is no evidence of voucher support. Value 1: fully funding public schools and eliminating voucher programs.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Santana stated in his 2025 questionnaire that residents and businesses near Mass and Cass deserve safe clean streets and he supports immediate interventions for sanitation and needle cleanup while building long-term infrastructure for treatment and housing. His approach treats sanitation as a public health investment requiring city resources — consistent with value 2: increase sanitation investment and prioritize historically underserved areas.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Santana stated in his 2025 questionnaire he wants PILOT program reform, local hiring requirements to put money back into communities, and value capture from existing developments through linkage fees — not large corporate tax abatements. He stated we need to diversify revenue streams and be smarter about development incentives. This is consistent with value 2: small business support and local programs while avoiding large corporate subsidies.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Santana stated in his 2025 questionnaire that we cannot arrest our way out of gun violence and explicitly supports violence interruption programs, community-based wraparound services including mentorship, job training, educational opportunities, and mental health support, and hospitals as intervention points — prioritizing diversion and community investment over expanding incarceration. Value 2: reduce incarcerated population through diversion and treatment alternatives.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Henry Santana / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bd4af01-0ce8-415f-87fa-09dc248ca6cc',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Santana stated in his 2025 questionnaire he supports increased transportation to and from the polls, voter registration booths at polling places, and using Same Day Registration — all aimed at expanding voter access. He explicitly highlights mobility-impaired voters as a group facing barriers. This is consistent with value 2: expand early voting and make voting accessible to all voters without strict requirements.$$,
        ARRAY['https://www.dotnews.com/wp-content/uploads/2025/08/Henry-Santana.pdf', 'https://www.boston.gov/departments/city-council/henry-santana']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Introduced a 2026 ordinance strengthening tenant protections against landlord retaliation during code-violation inspections, raised landlord penalties to $300/day, and expanded coordination between Inspectional Services and the Office of Housing Stability. Secured expanded city housing vouchers, eviction defense counsel, and a Tenant Stabilization Fund in the FY26 budget. Also introduced a Good Landlord Tax Abatement to incentivize affordable rental units and championed a 20% inclusionary development unit minimum in PLAN: East Boston.$$,
        ARRAY['https://eastietimes.com/2026/05/06/coletta-zapata-introduces-legislation-strengthening-tenant-protections/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/', 'https://eastietimes.com/2025/02/14/coletta-zapata-introduces-legislation-providing-tax-exemptions/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Introduced tenant protection ordinance (2026) raising daily penalties for landlords in violation, strengthening anti-retaliation safeguards, and improving enforcement coordination citywide. Secured Tenant Stabilization Fund and eviction defense counsel in FY26 budget. Held oversight hearing on short-term rental violations to tighten STR enforcement and close loopholes that reduce long-term housing stock.$$,
        ARRAY['https://eastietimes.com/2026/05/06/coletta-zapata-introduces-legislation-strengthening-tenant-protections/', 'https://eastietimes.com/2025/11/05/coletta-zapata-holds-oversight-hearing-on-short-term-rentals/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chairs the City Council's Committee on Environmental Justice, Resiliency, and Parks; released a 19-page climate action report in January 2025 calling for municipal climate bank, building electrification, geothermal solutions, and clean energy transitions. Oversaw $33M in climate/parks/clean energy funding in 2024. Co-delivered remarks at Mayor Wu's 2030 Climate Action Plan launch in April 2026 and called for equity-centered climate strategies, framing the plan as a shift from planning to action.$$,
        ARRAY['https://eastietimes.com/2026/04/29/edwards-coletta-zapata-deliver-remarks-at-climate-change-plan/', 'https://eastietimes.com/2025/01/15/coletta-zapata-publishes-report-on-local-climate-action/', 'https://eastietimes.com/2025/11/26/coletta-zapata-highlights-need-for-coordinated-climate-action/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Oversaw adoption of BERDO 2.0 (building emissions reduction ordinance) and the Equitable Emissions Investment Fund as Chair of the Environmental Justice Committee. Her January 2025 climate report explicitly calls for building electrification, geothermal solutions, and clean energy transitions as replacements for fossil fuels. Championed a municipal climate bank to fund clean energy and resilience projects and integrated climate science into Boston Public Schools curriculum.$$,
        ARRAY['https://eastietimes.com/2025/01/15/coletta-zapata-publishes-report-on-local-climate-action/', 'https://eastietimes.com/2025/04/15/coletta-zapata-holds-hearing-to-explore-creating-municipal-climate-bank/', 'https://eastietimes.com/2026/01/27/coletta-zapata-named-chair-of-government-operations-and-city-council-vice-president/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Co-introduced a tree mitigation fund with Councilor Bok requiring developers to financially compensate when trees are lost, noting East Boston has only 7% tree canopy versus 27% citywide. Secured greenway protection in PLAN: East Boston against excessive height and density. Championed BERDO 2.0 and required developer-funded environmental offsets in Article 80 development review reforms. Oversaw $33M in parks and open green space grants.$$,
        ARRAY['https://eastietimes.com/2022/08/31/coletta-bok-seek-tree-mitigation-fund/', 'https://eastietimes.com/2024/05/02/coletta-pushes-zba-to-uphold-and-enforce-new-zoning-with-plan-east-boston/', 'https://eastietimes.com/2024/07/23/coletta-zapata-sponsors-hearing-on-ongoing-reform-of-article-80-development-review-process/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Led a five-year community-driven PLAN: East Boston process establishing height ceilings, density limits, setbacks, parking requirements, and greenway protections in residential areas. Pushed ZBA to enforce the new zoning and opposed egregious variances that deviate from community-negotiated standards. Introduced ZBA reform Home Rule Petition adding oversight, community representation, and conflict-of-interest rules. Ensured 20% minimum inclusionary development units in Article 80 projects.$$,
        ARRAY['https://eastietimes.com/2024/01/24/coletta-comments-on-plan-east-boston/', 'https://eastietimes.com/2024/05/02/coletta-pushes-zba-to-uphold-and-enforce-new-zoning-with-plan-east-boston/', 'https://eastietimes.com/2025/03/18/coletta-zapata-seeks-to-reform-the-zoning-board-of-aappeal/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Demanded full community benefits from the Kraft Group's proposed soccer stadium (benchmarking Encore Casino's $68M package), insisted on infrastructure mitigation, and rejected a $750K initial offer as inadequate. Led Article 80 development review reforms requiring standardized mitigation formulas tied to community needs assessments. Supported new housing development tied to affordable unit requirements. Her approach is not anti-growth but requires accountability and community benefit at scale.$$,
        ARRAY['https://eastietimes.com/2025/08/06/councilor-coletta-zapata-joins-mayor-wu-at-press-conference-to-discuss-community-benefits-agreement-agreement-for-proposed-soccer-stadium/', 'https://eastietimes.com/2024/07/23/coletta-zapata-sponsors-hearing-on-ongoing-reform-of-article-80-development-review-process/', 'https://eastietimes.com/2025/07/15/coletta-zapata-leads-hearing-on-proposal-to-reform-the-zba/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Required community benefits and infrastructure mitigation from the proposed East Boston soccer stadium. Supported Article 80 reforms mandating standardized mitigation formulas tied to neighborhood needs including affordable housing and climate resilience. Launched a Food Cart Pilot Program for small food vendors. Secured $300K in small business storefront revitalization grants in FY26 budget. Supports targeted incentives only when paired with community benefit agreements.$$,
        ARRAY['https://eastietimes.com/2025/08/06/councilor-coletta-zapata-joins-mayor-wu-at-press-conference-to-discuss-community-benefits-agreement-agreement-for-proposed-soccer-stadium/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/', 'https://eastietimes.com/2024/07/23/coletta-zapata-sponsors-hearing-on-ongoing-reform-of-article-80-development-review-process/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Introduced a Home Rule Petition to raise the maximum recruitment age for Boston police from 40 to 45 to fill personnel shortages and reduce overtime costs. Simultaneously secured $700K for mental health services in the FY26 budget and $75K for public safety youth summer weekend programming. Her approach combines maintaining police staffing capacity with parallel investment in mental health and youth diversion services.$$,
        ARRAY['https://eastietimes.com/2024/06/12/coletta-zapata-seeks-to-hire-more-officers/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Launched a multi-layered District 1 trash initiative in 2023 combining barrel expansion, civic education, and community cleanup events. Secured seasonal street cleaners (hokies), trash containerization to address rodents, and expanded pest control in the FY23 and FY26 budgets. Explicitly frames poor sanitation as a services failure requiring expanded city investment, coordinated contractor oversight, and multilingual civic education.$$,
        ARRAY['https://eastietimes.com/2023/05/17/coletta-announces-community-trash-initiative-in-district-1/', 'https://eastietimes.com/2024/05/09/coletta-advocates-priorities-during-budget-hearings/', 'https://eastietimes.com/2026/01/27/coletta-zapata-named-chair-of-government-operations-and-city-council-vice-president/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Led passage of a road safety ordinance (2025) requiring food delivery platforms to register with the city, carry insurance, and share safety data — framed around protecting pedestrians and cyclists, not drivers. FY24 budget priorities included Vision Zero infrastructure improvements, street and sidewalk repairs, and replacing flexible posts with green infrastructure. Her District 1 brief explicitly notes it is 'a highly walkable district' requiring multimodal investment.$$,
        ARRAY['https://eastietimes.com/2025/04/09/coletta-zapata-stewards-passage-of-legislation-on-road-safety-regarding-food-delivery-apps/', 'https://eastietimes.com/2024/05/09/coletta-advocates-priorities-during-budget-hearings/', 'https://eastietimes.com/2025/03/05/coletta-zapata-holds-hearing-on-road-safety-ordinance/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-authored a 2022 op-ed supporting Massachusetts Question 4 (driver's licenses for undocumented immigrants), arguing it improves public safety and generates tax revenue without conferring additional government benefits. Secured $100K for the Immigrants Lead Boston civic leadership program in FY23 and $350K for school family immigration legal counsel in FY26. ESOL programs for parents and immigrant-serving services have been consistent budget priorities.$$,
        ARRAY['https://eastietimes.com/2022/10/27/guest-op-ed-yes-on-4-practical-safe-economic-policy/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/', 'https://eastietimes.com/2022/07/20/city-councilor-coletta-secures-budget-amendment/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Co-authored a 2022 op-ed endorsing Massachusetts Question 4 to expand driving privileges for undocumented immigrants. Secured $100K for the Immigrants Lead Boston program and $350K for school family immigration legal counsel. East Boston is a heavily immigrant district and she has consistently funded immigrant public services. Boston operates under the Trust Act (refusing ICE detainers without judicial warrants), which Coletta has supported through her funding priorities and statements about centering immigrant community needs.$$,
        ARRAY['https://eastietimes.com/2022/10/27/guest-op-ed-yes-on-4-practical-safe-economic-policy/', 'https://eastietimes.com/2025/06/10/council-invests-in-basic-city-services-public-safety-youth-jobs-housing-stability-in-recommended-fy26-budget/', 'https://eastietimes.com/2022/07/20/city-councilor-coletta-secures-budget-amendment/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Gabriela Coletta Zapata / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3007368-5c5d-4933-8bb3-048d9df6a411',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Passed ordinance establishing the Office of LGBTQIA2S+ Advancement (2024). Co-authored food justice ordinance making Boston first U.S. city with a mandatory food donation requirement, framed around food access as a human right. Condemned Trump administration's SNAP cuts in a 2025 Council resolution, stating 'access to food is a basic human right.' Secured ESOL programs and immigration legal services for underserved populations; championed environmental justice framing for coastal communities.$$,
        ARRAY['https://eastietimes.com/2025/11/05/coletta-zapata-condemns-trump-administrations-decision-to-end-snap-benefits/', 'https://eastietimes.com/2026/01/27/coletta-zapata-named-chair-of-government-operations-and-city-council-vice-president/', 'https://eastietimes.com/2023/03/01/arroyo-coletta-file-ordinance-to-make-boston-first-in-the-country-to-establish-food-recovery-program/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Voted against January 2021 and April 2021 ordinances restricting police use of rubber bullets, tear gas, and pepper spray (passed 8-5). Voted against 2023 budget amendments that cut the police department by $31M, citing concerns about officer staffing. Pushed for acceptance of a $13M federal counter-terrorism grant (January 2024). Filed a hearing order on police staffing shortages in August 2024, warning mandatory overtime from retirements was exhausting officers. Stated: "Many city officials do not support the police and their families and it is impacting recruiting and retention."$$,
        ARRAY['https://www.wbur.org/news/2021/01/05/tear-gas-rubber-bullet-restriction-veto', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://www.boston.com/news/local-news/2024/08/16/city-councilors-call-for-downtown-events-to-be-canceled-draws-pushback-from-colleagues-mayor-wu/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted for the October 2023 Mass & Cass ordinance (9-3) banning temporary shelters and tents at the intersection. As acting mayor in August 2023, toured the area with Boston Police and called for tent removal. Signed a September 2023 letter with three colleagues requesting a public health emergency declaration. His framing was enforcement-first with services secondary. Quote: "The number one reason is these tents need to come down. They've been up long enough."$$,
        ARRAY['https://whdh.com/news/boston-city-council-approves-ordinance-to-ban-tents-other-temporary-shelters-at-mass-and-cass/', 'https://www.boston.com/news/local-news/2023/08/09/with-wu-out-of-town-acting-mayor-ed-flynn-keeps-focus-on-mass-and-cass/', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As acting mayor and council president, Flynn's primary approach to Mass & Cass was enforcement: voting for the 2023 ordinance banning tents, calling for warrant sweeps, and touring with police. He did reference connecting people to drug treatment services, but the enforcement mechanism was the centerpiece. His repeated public statements framed the tent encampments as a public safety crisis requiring removal, with services as a secondary goal.$$,
        ARRAY['https://whdh.com/news/boston-city-council-approves-ordinance-to-ban-tents-other-temporary-shelters-at-mass-and-cass/', 'https://www.boston.com/news/local-news/2023/08/09/with-wu-out-of-town-acting-mayor-ed-flynn-keeps-focus-on-mass-and-cass/', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported the 2018 short-term rental ordinance restricting STRs to owner-occupied units, stating a goal to "defend our communities from commercialization, investor speculation." Supported Wu's 6% plus CPI rent stabilization proposal as "reasonable." Opposed a 70-unit housing development on Dorchester Avenue in 2025 for lacking parking despite transit proximity, showing a neighborhood-character focus. His housing record centers on protecting working-class residents from displacement and speculation.$$,
        ARRAY['https://www.southbostontoday.com/flynn-votes-to-ban-airbnb-investor-units/', 'https://www.wbur.org/news/2023/02/23/boston-rent-control-legislature-massachusetts-debate', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Described Mayor Wu's 6% plus CPI rent stabilization cap as "reasonable" and "like a compromise" in 2023. Supported short-term rental restrictions in 2018 to protect housing stock from investor speculation. His approach is to support moderate, politically viable rent stabilization rather than either full rent control or full market deregulation.$$,
        ARRAY['https://www.wbur.org/news/2023/02/23/boston-rent-control-legislature-massachusetts-debate', 'https://www.southbostontoday.com/flynn-votes-to-ban-airbnb-investor-units/', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Opposed a proposed 70-unit housing development on Dorchester Avenue in 2025 for lacking parking requirements despite its proximity to transit, citing displacement concerns for working-class residents. His record on STR ordinances and neighborhood character shows preference for development with strong design review and community input rather than broad upzoning or pure market deregulation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://www.southbostontoday.com/flynn-votes-to-ban-airbnb-investor-units/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Opposed 70-unit housing development lacking parking (2025). Broadly protective of neighborhood character and existing infrastructure. Criticized BPDA for recommending an urgent care clinic over community objections (February 2024). His redistricting opposition also stemmed from concern about community cohesion in existing neighborhoods. His overall approach favors growth only where it fits the existing built environment and community character.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://www.wgbh.org/news/politics/2022/11/01/city-council-president-flynn-seeks-to-put-boston-redistricting-on-hold']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '7687de4f-4d0b-462a-b803-bdfb23b16b42',
        $$Introduced the concept of a "rat czar" pest management position in 2023 and formally introduced a resolution creating an Office of Pest Control with a dedicated director in January 2024; the council unanimously adopted the ordinance on January 31, 2024. He partnered with Councilor Liz Breadon on the proposal. This represents a proactive government-services approach to sanitation, treating the rat problem as a city services failure requiring dedicated institutional response.$$,
        ARRAY['https://www.wbur.org/news/2023/04/26/boston-rat-czar-ed-flynn-newsletter', 'https://www.wcvb.com/article/boston-city-council-votes-to-create-office-of-pest-control-amid-rat-problem/', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Wrote an opinion piece opposing congestion pricing for Boston, arguing "we should be wary of any plan that could harm the fragile post-pandemic downtown economy." Opposed a 2025 housing development near transit because it lacked parking, demonstrating a pro-parking/pro-car stance. His district (South Boston) is car-dependent and his transportation instincts reflect constituent preference for road access and parking over multimodal investment.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://commonwealthbeacon.org/?s=ed+flynn+boston']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Called in November 2022 for halting the redistricting process and replacing it with an independent "blue-ribbon" panel comprising appointments from the City Council, Mayor's Office, Secretary of State, and Boston Election Department. Stated the process had become "tainted and flawed" due to lack of transparency and alleged outside influence. He funded litigation challenging the approved map with $10,000 of personal funds.$$,
        ARRAY['https://www.wgbh.org/news/politics/2022/11/01/city-council-president-flynn-seeks-to-put-boston-redistricting-on-hold', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Boston operates under the Trust Act, which limits cooperation with ICE to court-ordered detainers. Flynn has not publicly opposed this policy but voted against a home rule petition to extend municipal voting rights to non-citizen legal residents. He also organized a 2020 hearing on language barriers for non-English speakers during COVID-19, suggesting some concern for immigrant communities. No evidence he has advocated for proactive ICE cooperation or sanctuary city expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://commonwealthbeacon.org/?s=ed+flynn+boston']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted against a Boston home rule petition to allow non-citizen legal residents to vote in municipal elections, signaling a more cautious stance on extending government benefits beyond legal residents. No evidence of calls to significantly expand or restrict legal immigration levels. His positions are consistent with maintaining current frameworks rather than liberalizing or restricting them.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Has gone to considerable lengths to promote racial harmony: defended a Spanish-speaking colleague from a heckler, co-organized COVID-era hearings on barriers for non-English speakers, and framed his redistricting opposition around protecting minority communities in South Boston public housing. However, he has not supported reparations, equity mandates, or systemic reform measures. His opposition to non-citizen voting and conservative instincts place him closer to "maintain current civil rights laws while promoting equal opportunity."$$,
        ARRAY['https://commonwealthbeacon.org/politics/for-ed-flynn-awkward-roles-of-race-healer-and-redistricting-foe/', 'https://en.wikipedia.org/wiki/Ed_Flynn_(politician)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Edward M. Flynn / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8c7510c-20d7-4bd7-a765-07b77d3a5b6c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Criticized BPDA for recommending an urgent care clinic application over neighborhood objections (February 2024), calling it a "ruthless disregard" for residents. His overall record shows selective community-benefit-focused development advocacy: supports STR restrictions and housing protections for working-class residents, while opposing specific projects he views as harmful to neighborhood character. Approach is targeted incentives with community fit requirements rather than maximizing development or rejecting it outright.$$,
        ARRAY['https://en.wikipedia.org/wiki/Ed_Flynn_(politician)', 'https://www.southbostontoday.com/flynn-votes-to-ban-airbnb-investor-units/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Campaign website advocates for increasing housing supply with affordability prioritized, supporting multi-bedroom units, first-time homebuyer programs with reduced down payments and lower mortgage rates, and property tax relief to help families and seniors stay in place. He emphasizes residents having meaningful input on development projects rather than uniform approaches. This aligns with targeted subsidies, first-time buyer assistance, and streamlined permitting rather than a mandate-heavy or fully market-only approach.$$,
        ARRAY['https://www.fitzforboston.com/housing', 'https://www.boston.gov/departments/city-council/john-fitzgerald']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Campaign website states FitzGerald will ensure 'residents have meaningful input on development projects rather than applying uniform approaches across neighborhoods' and advocates for diverse housing types with affordability prioritized. He supports increasing housing supply but emphasizes community input and multi-bedroom affordability targets — consistent with allowing density increases through design review and neighborhood engagement rather than broad upzoning or strict neighborhood preservation.$$,
        ARRAY['https://www.fitzforboston.com/housing', 'https://www.boston.gov/departments/city-council/john-fitzgerald']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Campaign website commits to supporting Massachusetts's mandate to reduce greenhouse gas emissions by 2050 and advocates investing in clean energy infrastructure to lower carbon emissions. He supports a gradual transition emphasizing 'homeowner engagement, job training, and cross-sector participation' and cites grid resilience and employment as goals. Does not call for banning fossil fuels or emergency declarations; frames climate action as a long-term investment-and-transition agenda.$$,
        ARRAY['https://www.fitzforboston.com/climate-sustainability-and-resilience', 'https://www.boston.gov/departments/city-council/john-fitzgerald']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Campaign website calls for strict coastal protection measures including flood pathways, sea walls, and water-absorbing green spaces in response to Dorchester's projected 36 inches of sea level rise by 2070. He champions green infrastructure (urban gardens, bike paths, renewable energy), addresses pollution from I-93 and disproportionate asthma rates as environmental justice issues, and commits to applying sustainability standards to transportation and school building decisions.$$,
        ARRAY['https://www.fitzforboston.com/climate-sustainability-and-resilience']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Campaign website explicitly proposes establishing 'truly universal child care and early education to all children in Boston ages 0 to 5' by leveraging community partnerships and various funding sources. This directly matches the value=1 stance of publicly funded universal childcare regardless of income.$$,
        ARRAY['https://www.fitzforboston.com/education']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Campaign website calls for working with police and community leaders to develop a 'multifaceted, coordinated public safety plan that puts community policing first,' and supports increased investments in 'community-focused public safety programs and other initiatives that help reduce crime and get to the root cause of violence.' Also chairs the Public Health, Homelessness, and Recovery committee and pushed for $200K in FY27 budget for a coordinated substance use response team. Not calling to defund or significantly expand police; supports current staffing with parallel community investment.$$,
        ARRAY['https://www.fitzforboston.com/publicsafety', 'https://www.boston.gov/departments/city-council/john-fitzgerald', 'https://www.dotnews.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$As Chair of the Committee on Public Health, Homelessness, and Recovery, FitzGerald has called for declaring Mass & Cass a public health emergency, advocated for substance use treatment outside jail settings (endorsing a county sheriff's facility as a 'model' for treatment), and sought $200K in FY27 budget for a coordinated response team to address substance use disorder beyond the Mass & Cass area. He wants enforcement in that area tied to services, not purely punitive — consistent with enforcement-when-services-available.$$,
        ARRAY['https://www.boston.gov/departments/city-council/john-fitzgerald', 'https://www.dotnews.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$FitzGerald has pushed for treating Mass & Cass as a public health emergency and sought funding for a coordinated response team linking outreach, services, and enforcement. He endorsed a county sheriff's treatment facility as a model for diverting substance use cases out of jails while maintaining some enforcement presence in public spaces. This reflects a middle approach: invest in outreach and shelter while enforcing reasonable public space rules.$$,
        ARRAY['https://www.boston.gov/departments/city-council/john-fitzgerald', 'https://www.dotnews.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Campaign website commits to working with MBTA and state and federal delegations to secure funding for reliable and accessible public transit throughout Boston. Climate platform also promotes resilient urban planning including bike paths and renewable energy installations tied to transportation infrastructure. Supports maintaining roads and parks but treats transit investment as a co-equal priority.$$,
        ARRAY['https://www.fitzforboston.com/basiccityservices', 'https://www.fitzforboston.com/climate-sustainability-and-resilience']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John FitzGerald / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b546ec5-a7fe-4f64-9537-a19c58809631',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Served as Director of Finance for the City of Boston's Office of Economic Development for 17 years, where he worked to increase investments in communities and secured funds for locally owned small businesses without access to capital. Campaign website emphasizes local economic development through small business support and community investment rather than large corporate incentives.$$,
        ARRAY['https://www.fitzforboston.com/meet-john', 'https://www.fitzforboston.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted NO on the $3.4M BRIC police intelligence center grant in October 2023, joining four other councillors of color in opposing a surveillance program linked to a racially biased gang database. Chairs the Boston City Council's Committee on Civil Rights and Immigrant Advancement, reflecting a systemic discrimination-enforcement focus rather than a reparations or equity-mandate approach.$$,
        ARRAY['https://commonwealthbeacon.org/2023/10/boston-city-council-approves-controversy-plagued-police-grants/', 'https://www.boston.gov/departments/city-council/brian-worrell']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$In a November 2022 op-ed on gun violence, Worrell called simultaneously for 'more community policing,' removing guns from the street, more trauma response, after-school programs, and investments in at-risk youth — explicitly stating 'There isn't one easy answer to this. There are many answers.' He did not call to defund police or to expand the police budget as a top priority; his approach is maintaining public safety funding while adding community-based and crisis-response investment.$$,
        ARRAY['https://commonwealthbeacon.org/criminal-justice/we-must-stop-the-cycle-of-violence-in-hard-hit-boston-neighborhoods/', 'https://www.boston.gov/departments/city-council/brian-worrell']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Established and funded a Housing Acceleration Fund for affordable housing preservation targeting displacement-vulnerable neighborhoods; championed senior property tax exemptions and created a new veterans property tax exemption to help fixed-income residents remain housed; launched a study on accessible and affordable housing production in District 4. His approach centers on subsidies and anti-displacement preservation rather than public ownership or full market deregulation.$$,
        ARRAY['https://www.boston.gov/departments/city-council/brian-worrell']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$At a January 2025 council hearing on zoning density changes, Worrell questioned whether residents have adequate information about displacement consequences: 'Is that need presented to the community, so that they know when they're having these conversations about the zoning what they're voting for — and who?' He framed zoning decisions as requiring community transparency on demographic impacts, aligning with allowing density increases only with strong community input and anti-displacement safeguards.$$,
        ARRAY['https://www.dotnews.com/2025/council-hearing-probes-pros-cons-changes-zoning-upgrade-density', 'https://www.boston.gov/departments/city-council/brian-worrell']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Launched a study on building accessible and affordable housing in District 4 and established a Housing Acceleration Fund, reflecting a proactive infrastructure-investment stance rather than either imposing growth limits or removing regulatory barriers. His zoning hearing questions were about transparency and community readiness, not outright opposition to development.$$,
        ARRAY['https://www.boston.gov/departments/city-council/brian-worrell', 'https://www.dotnews.com/2025/council-hearing-probes-pros-cons-changes-zoning-upgrade-density']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Worrell / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f94a985-cb9d-497b-bd36-fffa48931ab2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Led passage of a home-rule petition expanding liquor license access in underserved Boston neighborhoods, framed as equity-minded economic development: 'Breaking down the $625,000 barrier to opening a restaurant is a multimillion-dollar idea for our communities.' His economic development record centers on removing barriers for small and local businesses rather than subsidizing large employers or using corporate tax abatements.$$,
        ARRAY['https://commonwealthbeacon.org/2023/11/creating-equity-in-bostons-liquor-license-market/', 'https://www.boston.gov/departments/city-council/brian-worrell']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Pepén played a key role in re-establishing and strengthening the Boston Trust Act, which prohibits Boston Police from honoring ICE civil detainers and bars city employees from sharing immigration status information with federal agencies. His official city profile identifies immigrant protections and the Trust Act as one of his four signature priorities.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen', 're-establishing and strengthening the Boston Trust Act, ensuring that all residents, regardless of immigration status, feel safe accessing city services']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$His official profile identifies him as "one of the most outspoken Councilors defending and uplifting Boston's immigrant communities" and credits him with strengthening the Trust Act so all residents regardless of status can access city services. This indicates support for keeping legal immigration open and allowing all residents — including undocumented — to access public services.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Pepén's central role in re-establishing the Boston Trust Act — which prohibits BPD from honoring ICE civil detainers and bars sharing immigration status with federal authorities — signals he opposes routine deportation cooperation and would only defer to court-ordered processes for serious violent crime. District 5 has large Dominican and Caribbean immigrant communities he explicitly advocates for.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chair of the Housing and Community Development committee; "spearheaded the successful effort to eliminate forced paid broker fees" (a tenant-protection measure); collaborated on the Squares + Streets citywide rezoning initiative to facilitate affordable housing development; secured millions in affordable housing investments via capital budgeting advocacy. His record combines public funding, tenant protections, and affordable unit requirements.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen', 'spearheaded the successful effort to eliminate forced paid broker fees, helping reduce financial barriers for renters across Boston']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Led the successful effort to eliminate forced paid broker fees — a direct tenant-protection measure reducing upfront rental costs. As Housing and Community Development committee chair, his housing agenda centers on reducing financial barriers for renters and increasing affordable housing supply through the Squares + Streets plan, consistent with strengthening tenant protections and extending coverage.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Collaborated with the Boston Planning & Development Agency on the Squares + Streets citywide rezoning initiative, which allows mixed-use and multifamily development near commercial nodes and transit corridors while preserving most residential zones. This plan-based approach with community input aligns with the middle-ground position of allowing multifamily/mixed-use near commercial corridors while protecting most residential areas.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$His official profile describes him as "one of the strongest voices on the Council for equitable mobility" who advocates for "safer roads for all modes of transportation" and championed uniform safe school zones across the city. "Equitable mobility" language signals equal investment in roads and multimodal options rather than a purely car-centric approach.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Member of the Civil Rights, Racial Equity, and Immigrant Advancement committee; described as "one of the most outspoken Councilors defending and uplifting Boston's immigrant communities"; grew up in Boston public housing as the son of Dominican immigrants and frames equity explicitly in his work. His advocacy pattern aligns with strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Secured capital budget investments for parks, schools, and community spaces in District 5 through proactive capital budgeting advocacy and Community Preservation Committee work. Collaborated on the Squares + Streets rezoning — a planned, infrastructure-linked approach to growth. Neither a growth-limit advocate nor an unconstrained-development advocate; consistent with investing in infrastructure ahead of growth to support responsible expansion.$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Enrique J. Pepén / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce971c69-7b28-49f2-b530-783291a08863',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Chairs the Community Preservation Act committee, which funds community investments tied to benefit requirements (affordable housing, historic preservation, open space). Secured millions in investments for parks, schools, and affordable housing in District 5 via capital budgeting. This approach — targeted public investment with community benefit requirements — aligns with value 3 (specific incentives with community benefit agreements).$$,
        ARRAY['https://www.boston.gov/departments/city-council/enrique-j-pepen']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Championed the Access to Counsel pilot program giving free legal representation to tenants in eviction proceedings, noting that 95% of landlords are represented by attorneys while less than 5% of tenants have counsel. Secured rental vouchers for certain undocumented immigrants and free eviction defense counsel as accepted budget amendments in FY2025. Also supported special protection zones for affordable housing stock.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/02/09/weber-discusses-his-time-in-office-so-far/', 'https://www.jamaicaplaingazette.com/2024/07/12/jpa-hears-of-webers-amendments-to-budget/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Weber co-filed formal information requests in March 2026 seeking disclosure of BPD collaboration with federal law enforcement, signaling oversight concern rather than support for ICE cooperation. His FY2025 budget amendment secured rental vouchers for undocumented immigrants, committing city resources to protecting undocumented residents. His actions align with Boston Trust Act policy limiting police-ICE cooperation.$$,
        ARRAY['https://www.boston.gov/departments/city-council/benjamin-j-weber', 'https://www.jamaicaplaingazette.com/2024/07/12/jpa-hears-of-webers-amendments-to-budget/', 'https://www.dotnews.com/?s=ben+weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Secured rental vouchers for undocumented immigrants in the FY2025 city budget and co-filed an inquiry into BPD collaboration with federal law enforcement in March 2026. His background includes a 2005 fellowship with Texas Rio Grande Legal Aid representing migrant farmworkers. These actions reflect a stance of keeping legal immigration open and providing public services to immigrants regardless of status.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/07/12/jpa-hears-of-webers-amendments-to-budget/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber', 'https://www.dotnews.com/?s=ben+weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Weber secured rental vouchers for undocumented immigrants in his FY2025 budget amendments and co-filed inquiries into BPD-federal law enforcement collaboration. He has not called for deportation of any category of undocumented residents; his documented actions consistently prioritize housing stability for undocumented people in his district.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/07/12/jpa-hears-of-webers-amendments-to-budget/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Weber spent 18 years as a workers rights attorney combating wage theft and was part of a legal team that sued the Boston Police Department over discriminatory promotional exams. He drafted a heat illness prevention ordinance for city employees and contractors and focused his committee work on labor protections and diverse local hiring, consistent with strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://www.boston.gov/departments/city-council/benjamin-j-weber', 'https://www.jamaicaplaingazette.com/2024/02/09/weber-discusses-his-time-in-office-so-far/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Vice Chair of the Labor and Economic Development committee, Weber focused on wage theft enforcement and diverse local hiring, proposed a commercial vacancy ordinance to discourage long-term vacancies and redirect fees to neighborhood improvements, and discussed potential wage theft ordinances. His approach prioritizes worker protections and small business vitality rather than large corporate tax incentives.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/02/09/weber-discusses-his-time-in-office-so-far/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Weber serves as Vice Chair of the Environmental Justice, Resiliency, and Parks committee and discussed tree protection ordinances in his first months in office. He intervened at Forest Hills Cemetery to protect trees after neighbors raised concerns about removal, citing the historical public-access obligation of the cemetery land grant as requiring preservation of open green space.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/02/09/weber-discusses-his-time-in-office-so-far/', 'https://www.jamaicaplaingazette.com/2024/08/23/weber-going-to-bat-for-those-disappointed-and-frustrated-with-forest-hills-cemetery/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Weber serves as Vice Chair of the Public Safety and Criminal Justice committee and co-filed formal information requests in March 2026 about BPD collaboration with federal law enforcement, reflecting accountability-focused oversight. He drafted a heat illness prevention ordinance for city workers. No evidence of calls to redirect the police budget to social services, nor of calls to significantly expand police staffing and equipment.$$,
        ARRAY['https://www.boston.gov/departments/city-council/benjamin-j-weber', 'https://www.dotnews.com/?s=ben+weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Benjamin J. Weber / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('703f9005-8767-4c2b-97c1-155b3fc36fee',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Weber serves on the Public Health, Homelessness, and Recovery committee and championed the Access to Counsel program to prevent homelessness by keeping tenants in their homes during eviction proceedings. His FY2025 budget amendments included rental vouchers for undocumented immigrants. His approach is service-investment led, working to prevent homelessness upstream through legal and housing assistance rather than enforcement.$$,
        ARRAY['https://www.jamaicaplaingazette.com/2024/02/09/weber-discusses-his-time-in-office-so-far/', 'https://www.jamaicaplaingazette.com/2024/07/12/jpa-hears-of-webers-amendments-to-budget/', 'https://www.boston.gov/departments/city-council/benjamin-j-weber']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$As New England Regional Counsel for HUD, Culpepper helped implement Boston's first Civil Rights Protection Plan in public housing and secured $25 million in federal funds for public housing improvements. On the Boston City Council, he chairs the Committee on Civil Rights, Racial Equity, and Immigrant Advancement. His career has centered on strengthening civil rights enforcement and addressing systemic discrimination in housing and public institutions.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As HUD Regional Counsel, Culpepper helped secure $25 million in federal funds for public housing rebuilds and focused on tenants' rights and fair housing. His official boston.gov profile identifies housing stability as a cornerstone priority and his District 7 vision is for "longtime residents can stay." He serves as Vice Chair of the Housing and Community Development committee on the City Council.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Culpepper chairs the Boston City Council's Committee on Civil Rights, Racial Equity, and Immigrant Advancement. Boston operates under the Trust Act, which prohibits BPD from honoring civil ICE detainers and bars sharing immigration status with federal agencies. His committee leadership and his District 7 constituency (Roxbury, which has significant immigrant communities) align with full sanctuary-city posture.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chairs the Committee on Civil Rights, Racial Equity, and Immigrant Advancement, signaling a focus on protecting immigrant communities and keeping public services accessible regardless of immigration status. His District 7 includes large communities of color including many immigrant residents. His stated platform emphasizes that every resident, regardless of background, should benefit from Boston's prosperity.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$As chair of the Civil Rights, Racial Equity, and Immigrant Advancement committee and a representative of Roxbury, Culpepper has focused on immigrant community protection consistent with Boston's Trust Act posture, which limits deportation cooperation to court-ordered warrants and prioritizes only serious violent offenders. No statements supporting broad deportation enforcement found.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Culpepper founded the Trotter Peace Program for youth mentorship and employment and led the Six Point Peace Plan to address community violence — both community-based, non-policing approaches to public safety. His official profile frames safety through community investment and violence reduction strategies rather than police expansion. He sits on the Public Health, Homelessness, and Recovery committee, further indicating a public-health-adjacent approach to safety.$$,
        ARRAY['https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Miniard Culpepper / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$A 2026 Dorchester Reporter search summary notes Culpepper has advocated for greater minority-owned business participation in White Stadium project contracts. He serves on the Labor and Economic Development committee. His HUD background focused on economic equity for underserved communities rather than either blanket corporate subsidies or exclusively small-business-only support.$$,
        ARRAY['https://www.dotnews.com/', 'https://www.boston.gov/departments/city-council/miniard-culpepper']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharon Durkan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('161c754c-2161-49aa-9722-f0e5dbc07cef',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('161c754c-2161-49aa-9722-f0e5dbc07cef',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$At a March 2024 city council hearing, Durkan testified in favor of the Squares + Streets zoning initiative, stating the plan respects neighborhood character while prioritizing community input on changes. Squares + Streets allows multifamily and mixed-use near commercial corridors while leaving most residential zones unchanged — the plan does not upzone citywide or ban density. Her support aligns with value 3.$$,
        ARRAY['https://www.dotnews.com/2024/squares-streets', 'https://www.boston.gov/departments/city-council/sharon-durkan']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sharon Durkan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('161c754c-2161-49aa-9722-f0e5dbc07cef',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('161c754c-2161-49aa-9722-f0e5dbc07cef',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$At the March 2024 Squares + Streets hearing, Durkan backed the initiative as a vehicle for responsible growth, arguing that growth in Boston's population depends on growth in its built environment and relief from housing costs. This reflects a proactive, infrastructure-linked growth stance rather than either imposing growth limits or removing all regulatory barriers.$$,
        ARRAY['https://www.dotnews.com/2024/squares-streets', 'https://www.boston.gov/departments/city-council/sharon-durkan']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Breadon's official city council page states Boston 'must continue to lead by protecting immigrants' as a core commitment. Boston operates under the Trust Act prohibiting BPD from honoring ICE civil detainers without a judicial warrant and barring sharing of immigration status with federal agencies. Breadon's explicit public framing aligns with full sanctuary-city posture.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Official page commitment to protecting immigrants and ensuring all residents benefit from city services regardless of status, combined with her alignment with the Trust Act framework. She has framed immigrant protection as a leadership priority without calling for expanded open immigration.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Breadon is the first openly LGBTQ woman elected to Boston City Council and the first openly LGBTQ council president. She publicly identifies as married to her spouse Mary McCarthy. Her personal identity and public record reflect unambiguous support for full federal recognition of same-sex marriages.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon', 'https://en.wikipedia.org/wiki/Liz_Breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Breadon explicitly frames her platform around 'racial and economic justice' and LGBTQ equality. As redistricting chair she sponsored the Unity Map aimed at increasing minority representation. In June 2023 she was the only white council member to vote for a budget supported by six councilors of color, despite all other white members opposing it — a significant cross-racial solidarity signal.$$,
        ARRAY['https://en.wikipedia.org/wiki/Liz_Breadon', 'https://www.boston.gov/departments/city-council/liz-breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Official city council page states she 'secured record-breaking commitments to affordable housing' and advocates treating 'housing as a human right' with 'bold solutions to our housing crisis.' This language aligns with subsidized affordable housing requirements and public funding rather than either full public ownership or pure market solutions.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$In June 2023 Breadon was the sole white council member to vote YES on a budget that included $31M in police cuts, signaling willingness to redirect public safety spending toward other priorities. However, she voted YES on the $3.4M BRIC police intelligence center grant (October 2023, 7-5), supporting a contested police surveillance program. Together these votes place her as maintaining current public safety funding while open to adding community-based alternatives.$$,
        ARRAY['https://en.wikipedia.org/wiki/Liz_Breadon', 'https://commonwealthbeacon.org/2023/10/boston-city-council-approves-controversy-plagued-police-grants/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$As chair of the City Council's Redistricting Committee, Breadon sponsored and championed the 'Unity Map' following the 2020 Census, which passed with support of all six minority council members and was designed to increase minority representation. She pushed the process forward over Flynn's calls to halt it. The Unity Map approach reflects an independent-commission-adjacent, equity-driven redistricting model.$$,
        ARRAY['https://en.wikipedia.org/wiki/Liz_Breadon', 'https://www.wgbh.org/news/politics/2022/11/01/city-council-president-flynn-seeks-to-put-boston-redistricting-on-hold']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Official city council page lists 'improvements to public transit' and 'safer streets' as signature priorities alongside her district's central role in the Allston Multimodal Project (Mass Pike reconstruction with new transit and pedestrian facilities). Her stated platform explicitly elevates transit improvement as a core commitment.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Breadon / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e63a642-91f7-4c2b-949d-b3a936e6343e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Official city council page lists 'increased climate resiliency' as a district priority. As council president, Breadon committed to 'equity, affordability, resilience' as core goals. The climate resiliency framing reflects investment in adaptation and clean energy infrastructure without an emergency-declaration or fossil fuel ban stance.$$,
        ARRAY['https://www.boston.gov/departments/city-council/liz-breadon', 'https://www.dotnews.com/2026/01/05/breadon-beats-out-worrell-for-council-presidency/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row counts per official (should match approved table):
-- SELECT p.full_name, COUNT(*) as stances
-- FROM inform.politician_answers pa
-- JOIN essentials.politicians p ON p.id = pa.politician_id
-- WHERE pa.politician_id IN (
--   'd63def16-7510-4745-83d8-01901e450429','1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
--   'cd9d9fd5-c20f-4b57-9065-f52516adca84','c9419f85-8e38-4b64-a816-7b3caba5c674',
--   '3bd4af01-0ce8-415f-87fa-09dc248ca6cc','c3007368-5c5d-4933-8bb3-048d9df6a411',
--   'b8c7510c-20d7-4bd7-a765-07b77d3a5b6c','3b546ec5-a7fe-4f64-9537-a19c58809631',
--   '9f94a985-cb9d-497b-bd36-fffa48931ab2','ce971c69-7b28-49f2-b530-783291a08863',
--   '703f9005-8767-4c2b-97c1-155b3fc36fee','10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
--   '161c754c-2161-49aa-9722-f0e5dbc07cef','6e63a642-91f7-4c2b-949d-b3a936e6343e'
-- )
-- GROUP BY p.full_name ORDER BY p.full_name;
--
-- Unpaired answers (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN (
--   'd63def16-7510-4745-83d8-01901e450429','1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
--   'cd9d9fd5-c20f-4b57-9065-f52516adca84','c9419f85-8e38-4b64-a816-7b3caba5c674',
--   '3bd4af01-0ce8-415f-87fa-09dc248ca6cc','c3007368-5c5d-4933-8bb3-048d9df6a411',
--   'b8c7510c-20d7-4bd7-a765-07b77d3a5b6c','3b546ec5-a7fe-4f64-9537-a19c58809631',
--   '9f94a985-cb9d-497b-bd36-fffa48931ab2','ce971c69-7b28-49f2-b530-783291a08863',
--   '703f9005-8767-4c2b-97c1-155b3fc36fee','10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
--   '161c754c-2161-49aa-9722-f0e5dbc07cef','6e63a642-91f7-4c2b-949d-b3a936e6343e'
-- ) AND pc.politician_id IS NULL;
--
-- Unsourced context (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id IN (
--   'd63def16-7510-4745-83d8-01901e450429','1e3a621a-2424-469e-8c1a-7a0dd635d3a2',
--   'cd9d9fd5-c20f-4b57-9065-f52516adca84','c9419f85-8e38-4b64-a816-7b3caba5c674',
--   '3bd4af01-0ce8-415f-87fa-09dc248ca6cc','c3007368-5c5d-4933-8bb3-048d9df6a411',
--   'b8c7510c-20d7-4bd7-a765-07b77d3a5b6c','3b546ec5-a7fe-4f64-9537-a19c58809631',
--   '9f94a985-cb9d-497b-bd36-fffa48931ab2','ce971c69-7b28-49f2-b530-783291a08863',
--   '703f9005-8767-4c2b-97c1-155b3fc36fee','10a52f8b-bd19-4076-9a8f-46ae2e8552ce',
--   '161c754c-2161-49aa-9722-f0e5dbc07cef','6e63a642-91f7-4c2b-949d-b3a936e6343e'
-- ) AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);