-- ============================================================================
-- Migration 234: CA State Senate Stances -- 27 Senators
-- ============================================================================
-- Purpose: Insert/upsert stance data for 27 CA State Senators (researched 2026-05-22).
--
-- Scope: 27 senators, 577 stance rows
--
-- Missing senators (need research): Susan Rubio (SD-22), Suzette Martinez Valladares (SD-23),
--   Sasha Rene Perez (SD-25), Thomas Umberg (SD-34), Tony Strickland (SD-36),
--   Steve Padilla (SD-18), Rosilicie Ochoa Bogh (SD-19), Sabrina Cervantes (SD-31),
--   Steven Choi (SD-37), Scott Wiener (SD-11), Shannon Grove (SD-12),
--   Tim Grayson (SD-9), Roger Niello (SD-6)
--
-- Idempotency: ON CONFLICT DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Aisha Wahab / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Wahab's campaign site explicitly lists 'reproductive freedom and women's rights' as a core priority. She authored SB 257 (2025) to add pregnancy as a qualifying life event for health insurance special enrollment, signaling strong pro-access framing. No bills restricting abortion access; consistent with California mainstream pro-choice Democratic caucus supporting legal access through second trimester and beyond.$$,
        ARRAY['https://aishawahab.com/about', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB257']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Wahab has been one of California's most active AI regulators in her caucus. She authored SB 398 (2023-24) requiring a government feasibility study on AI risks and equity impacts, SB 981 and SB 926 requiring platform removal of AI-generated nonconsensual intimate images, SB 1381 banning AI-generated CSAM, and SB 384 (2025-26) banning algorithmic price-fixing in housing and goods markets. This pattern reflects close monitoring and government approval before deploying AI systems in sensitive domains, aligning with value 4.$$,
        ARRAY['https://sd10.senate.ca.gov/2024-legislative-package', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB398', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB384']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Wahab authored SB 573 (2023-24) imposing one-year post-employment lobbying restrictions on legislative committee consultants under the Political Reform Act â an ethics/transparency measure but not a campaign finance bill. No bills specifically limiting corporate donations, dark money, or establishing public campaign funding were found in her legislative record. Her about page frames work as serving constituents over corporate interests, suggesting rhetorical support for reform, but evidence supports a moderate transparency position rather than a strong structural reform stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB573', 'https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Wahab's campaign site states she protects 'funding for food assistance, healthcare, and public education' and her 2025 legislative package passed SCR 72 (Childcare Awareness Month). Her women's issues bills (SB 257, SB 258) and support for expanded social services point toward significant subsidy expansion for working families. No universal public childcare bill authored, placing her at value 2 â significantly expanding subsidies and provider grants for low- and middle-income families.$$,
        ARRAY['https://aishawahab.com/about', 'https://sd10.senate.ca.gov/2025-legislative-package']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wahab authored SB 403 (2023) to add caste to California's list of protected classes under anti-discrimination law â the first such bill in the nation, though it was vetoed by Governor Newsom. She also authored SCR 105 (2025) urging international human rights norms in Gaza. Her campaign site cites 'first-in-the-nation civil rights protections' and 'championing' anti-discrimination. This record reflects strong civil rights enforcement and addressing systemic discrimination, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB403', 'https://sd10.senate.ca.gov/2023-legislative-package', 'https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wahab authored SB 983 (2023-24) creating an Alternative Fuels Infrastructure Taskforce to support EV charging and hydrogen at gas stations, and SB 332 (2025-26) studying transition of investor-owned utilities to public/nonprofit ownership to improve grid and ratepayer outcomes. She also co-led SB 254 on transmission acceleration for clean energy. These bills invest in clean energy while gradually reducing fossil fuel reliance, consistent with value 3 â no GND-style rapid phase-out legislation authored.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB983', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB332', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB254']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Wahab's SB 332 (2025-26) requires utilities to conduct triennial audits of aging infrastructure and study public ownership models that could affect data center energy allocation; SB 254 (2025) addresses transmission expansion and ratepayer cost protections. Her SB 398 (2023-24) required impact assessments of AI applications in government services including equity and cost-efficiency reviews. Together these reflect a stance of allowing development with impact assessments and cost-sharing agreements, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB332', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB398', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB254']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Wahab's office maintains a dedicated immigration resources page and she authored SB 465 (2023) to expand refugee resource accessibility at state and county websites. Her about page frames her work around immigrant community support in a district covering large immigrant populations in Fremont and Hayward. No pro-enforcement or deportation-supportive bills authored; pattern is consistent with protecting undocumented residents and providing legal status pathways while only deporting serious violent offenders.$$,
        ARRAY['https://sd10.senate.ca.gov/', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB465']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Wahab's SB 983 (2023-24) created a taskforce to study converting gas station infrastructure to support alternative fuels (EV/hydrogen) defined as non-fossil-fuel alternatives, signaling support for transition away from fossil fuels but through managed infrastructure planning. SB 254 (2025) accelerates clean energy transmission. She has not authored bills banning new fossil fuel permits, placing her at value 3 â maintaining current production levels while investing in clean energy alternatives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB983', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB254']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wahab co-authored SB 40 (2025) capping insulin copayments at $35/30-day supply, authored SB 1354 (2024) preventing Medi-Cal payment discrimination at nursing facilities, SB 1320 (2024) requiring health plans to cover integrated behavioral health, SB 1319 (2023-24) addressing psychiatric medication consent, and SB 1355 (2023-24) protecting Medi-Cal in-home supportive services. Her campaign site explicitly says she 'protects funding for healthcare.' This record supports expanding public coverage through regulation without proposing a single-payer system, consistent with value 2.$$,
        ARRAY['https://sd10.senate.ca.gov/2024-legislative-package', 'https://sd10.senate.ca.gov/2025-legislative-package', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1354']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wahab reduced homelessness by 22% during her Hayward City Council tenure per her campaign site. Her SB 262 (2025) expanded prohousing designations to include safe parking programs and safe camping with services, connecting people to navigation centers and shelters â a decriminalization-with-services approach. SB 555 (2023) funded a social housing study. This pattern reflects decriminalizing public sleeping while investing in shelter and service connections, consistent with value 2.$$,
        ARRAY['https://aishawahab.com/about', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB262', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB555']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wahab has authored over 20 housing bills including SB 466 (rent control expansion), SB 555 (social housing study), SB 436 (eviction notice extension to 14 days), SB 681 (landlord fee caps, ADU protections, seismic retrofitting), SB 722 (mobile home park transit-oriented development protections), and SB 262 (prohousing designations expanded). Her campaign site calls for 'stopping Wall Street from purchasing homes,' expanding affordable housing, and strengthening rent stabilization. This is a strong affordable housing and rental assistance expansion agenda, consistent with value 2.$$,
        ARRAY['https://sd10.senate.ca.gov/2025-legislative-package', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB681', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB555']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Wahab authored SB 465 (2023) expanding refugee resource accessibility, maintains an immigration resources page for constituents, and her about page emphasizes community support for immigrant residents. Her district includes large immigrant communities in Hayward, Fremont, and Union City. No restrictionist immigration legislation authored. Pattern consistent with significantly increasing legal pathways and creating easy citizenship access, though as a state senator she focuses on services rather than federal admission levels.$$,
        ARRAY['https://sd10.senate.ca.gov/', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB465', 'https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Wahab authored SB 1354 (2024) preventing Medi-Cal payment discrimination at nursing facilities ensuring equitable care for Medi-Cal recipients, SB 1355 (2023-24) protecting Medi-Cal in-home supportive services redetermination processes, and SB 462 (2023) clarifying county information sharing for safety net programs. Co-authored SB 40 ($35 insulin cap). Her campaign site explicitly protects 'healthcare funding.' This reflects a strong expand-and-protect position for Medi-Cal/Medicare, consistent with value 2 â significantly expanding Medicaid coverage.$$,
        ARRAY['https://sd10.senate.ca.gov/2024-legislative-package', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1354', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1355']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Wahab's SB 384 (2025-26) bans algorithmic price-fixing but focuses on antitrust rather than content moderation. Her SB 981 (2024) and SB 926 (2024) require platforms to remove nonconsensual AI-generated intimate images â a content removal mandate but focused on illegal content, not misinformation. SB 435 (2025-26) strengthens CCPA privacy protections. The pattern reflects platform regulation for specific harms (illegal content, consumer protection) while not broadly mandating fact-checking or content moderation algorithms â consistent with value 4, protecting free speech while preventing government overreach in content decisions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB384', 'https://sd10.senate.ca.gov/2024-legislative-package', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB435']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Wahab authored SB 461 (2023) allowing state workers to use existing holiday time for their own cultural or religious observances â a religious accommodation bill. She also authored SCR 45 (American Muslim Appreciation Month), SCR 19 and 125 (Ramadan), and SCR 134 (Nowroz), reflecting strong support for religious expression in public. Her SB 399 (2023-24) protected employees from employer-mandated religious speech meetings. As the first Muslim California state senator, she navigates religious freedom as both personal identity and policy â balancing protection with anti-discrimination, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB461', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB399', 'https://sd10.senate.ca.gov/2023-legislative-package']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wahab's campaign site explicitly states she advocates for 'LGBTQ+ equality.' As a California state senator in a Democratic caucus, she operates in a state that has led on marriage equality. No anti-LGBTQ legislation authored; her civil rights focus (SB 403 on caste discrimination) and about page framing of broad civil rights protection are consistent with supporting same-sex marriage nationwide while protecting some organizations' right to decline participation, aligning with mainstream California Democratic position at value 2.$$,
        ARRAY['https://aishawahab.com/about', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB403']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Wahab's campaign site explicitly states she 'protects funding for food assistance, healthcare, and public education' and frames public schools as a core priority. Her about page emphasizes 'protecting public education.' As an Alameda County-district senator, no voucher bills authored; her framing of public education funding as essential, combined with her social equity focus (her district includes high-need communities), reflects opposition to programs diverting taxpayer money to private institutions, consistent with value 1.$$,
        ARRAY['https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Wahab has authored multiple bills protecting Medi-Cal beneficiaries and expanding safety net programs (SB 1354, SB 1355, SB 462, SB 463). Her campaign site emphasizes protecting the social safety net including food assistance, healthcare, and public benefits. While she has not authored federal SS legislation (state jurisdiction), her consistent pattern of protecting and expanding safety net programs, including pension-related senior care bills, is consistent with value 2 â modestly increasing benefits while raising taxes on higher earners.$$,
        ARRAY['https://sd10.senate.ca.gov/2024-legislative-package', 'https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Wahab's campaign site states she demands 'stable rates and accountability from utility and insurance companies,' raises minimum wage standards, and frames governance as 'serving people not the powerful.' Her SB 332 (2025-26) studying public utility ownership, and SB 254 creating ratepayer savings mechanisms, reflect progressive economic populism. No specific tax legislation authored as a state senator (tax bills typically authored through Finance Committee), but her overall economic platform â protecting working families while holding corporations accountable â aligns with value 2: modestly increasing taxes on high earners while maintaining middle-class rates.$$,
        ARRAY['https://aishawahab.com/about', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB332']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Aisha Wahab / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Wahab's campaign site emphasizes civic engagement and her office provides voter registration assistance as a constituent service. Her civil rights legislative focus (SB 403 anti-discrimination, SB 573 ethics/transparency, SB 399 worker rights) and consistent Democratic caucus alignment suggest support for expanding voting access. No specific voting rights bills authored, but her overall equity-focused and anti-discrimination legislative record is consistent with expanding early voting and no-excuse mail voting, aligning with value 2.$$,
        ARRAY['https://sd10.senate.ca.gov/', 'https://aishawahab.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Weber Pierson authored AB-576 (2023) requiring Medi-Cal to update coverage policies for medication abortion in line with evidence-based clinical guidelines. She also authored SB-528 (2025) to explicitly maintain and expand state health coverage â including abortion services and gender-affirming care â if federal Medicaid funding is reduced. This is a strong pro-access position focused on public insurance coverage, consistent with keeping abortion legal and accessible with Medi-Cal funding.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB576', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB528']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Weber Pierson authored SB-503 (2025) requiring developers of AI systems used in healthcare clinical decision-making to conduct annual independent audits, submit compliance reports to the state Department of Public Health starting 2027, and publish audit summaries publicly. AB-1791 (2023) required social media platforms to preserve and disclose digital content provenance data to ensure content authenticity. This pattern reflects mandating basic safety testing and auditing before AI systems are deployed in sensitive domains, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB503', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1791']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Weber Pierson authored AB-1057 (2023) codifying the California Home Visiting Program providing state-funded support to pregnant individuals and parents of young children in underserved communities. She authored AB-1701 (2023) expanding the California Perinatal Equity Initiative to address Black infant mortality disparities. SB-528 (2025) expands Medi-Cal health services for families. This record reflects significantly expanding subsidies and provider support for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1057', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1701', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB528']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Weber Pierson authored AB-1815 (2024, chaptered) expanding the CROWN Act to protect hair textures and protective hairstyles as race-associated traits in employment, housing, and schools. She authored SB-518 (2025) establishing a Bureau for Descendants of American Slavery within the Civil Rights Department. AB-797 (2023) required all California cities and counties to create independent police oversight commissions. ACR-135 (2023) acknowledged California's responsibility for historical harms against African Americans. This is a strong systemic civil rights enforcement record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1815', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB518', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB797']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Weber Pierson authored SB-89 (2025) prohibiting retail sale of glyphosate-containing products to unlicensed users as an environmental and public health measure. Her legislative focus is primarily on public health, healthcare equity, and consumer safety rather than direct climate legislation. No authored bills mandating rapid renewable energy transition or banning fossil fuel extraction were found. Her environmental record reflects investing in clean energy and public health protections consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB89', 'https://sd39.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Weber Pierson authored SB-1210 (2025) expanding oversight of gang databases statewide and explicitly prohibiting law enforcement from sharing gang database records for federal immigration enforcement purposes unless required by statute. The bill requires immigration services organizations on oversight committees. This protects undocumented immigrants from civil immigration enforcement while allowing deportation only for serious criminal offenders, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1210']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$No direct fossil fuel extraction or permitting bills were found in Weber Pierson's 2023-2026 legislative record. Her environmental bills focus on pesticide restrictions (SB-89) and public health rather than fossil fuel policy. As a California Democrat and physician representing San Diego County, her overall positioning aligns with maintaining current environmental regulations while supporting clean energy investment, consistent with value 3.$$,
        ARRAY['https://sd39.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Weber Pierson authored multiple bills expanding and regulating health coverage: AB-576 (Medi-Cal abortion coverage), AB-874 (manufacturer discounts count toward patient out-of-pocket maximums), AB-1895 (maternity ward closure protections), SB-32 (perinatal access geographic standards), SB-528 (maintain and expand Medi-Cal against federal cuts), SB-987 (health access fund using Medi-Cal savings to cover displaced beneficiaries), and SB-1037 (insurance rate review reform incorporating affordability). As a physician-legislator her work consistently expands public coverage and regulates insurance costs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB576', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB528', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB987']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Weber Pierson authored SB-1210 (2025) prohibiting gang database sharing with ICE for immigration enforcement, with immigration services organizations on oversight committees. SB-528 (2025) maintains Medi-Cal coverage for populations whose immigration status may affect federal funding eligibility. As a San Diego area senator representing communities near the US-Mexico border, her legislative record consistently protects immigrant residents and creates service pathways rather than supporting restriction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1210', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB528']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Weber Pierson authored multiple Medi-Cal bills: AB-576 (Medi-Cal abortion reimbursement), AB-1241 and AB-1943 (Medi-Cal telehealth expansion), AB-317 (pharmacist service Medi-Cal coverage), SB-528 (expand state-only health programs when federal Medi-Cal funding reduced), and SB-987 (health access fund using state Medi-Cal savings to cover beneficiaries displaced by federal cuts). This extensive record reflects strongly expanding and protecting Medi-Cal, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1241', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB528', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB987']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Weber Pierson authored AB-1791 (2023) requiring social media platforms to preserve digital content provenance data (device type, authenticity proof) while redacting personal user data â a transparency mechanism to help users verify content authenticity. This is a technical standards approach enabling verification tools rather than mandating removal of false information or regulating content promotion algorithms, consistent with value 3 of encouraging voluntary/technical standards for combating misinformation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1791']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Weber Pierson serves in California's Democratic caucus which unanimously supports marriage equality with full federal protections. Her comprehensive civil rights record â AB-1815 (CROWN Act), SB-518 (reparations bureau), AB-797 (police oversight) â reflects support for full federal recognition and benefits for same-sex couples. No anti-LGBTQ legislation authored; consistent with California Democrats requiring all states to recognize same-sex marriages with full federal benefits.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1815', 'https://sd39.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Weber Pierson's education bills consistently strengthen public school accountability: AB-1919 (restorative justice mandates in public schools), AB-1466 (transparency on restraint/seclusion in public schools), AB-1984 (discipline transfer reporting), AB-1327 (racial discrimination tracking in public school athletics). No voucher or private school funding bills authored. Her pattern reflects fully funding public schools and opposing programs that divert taxpayer money to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1919', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1466', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1984']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Weber Pierson authored AB-1381 (2023) requiring state contracts to keep at least 90% of call center jobs in California â protecting working-class employment. AB-699 (2023) expanded workers' compensation presumptions for public safety workers. SB-987 (2025) creates a health access fund using state Medi-Cal savings to maintain coverage â implying support for state revenue to fund social services. Her economic orientation consistently protects working families and expands public programs, consistent with modestly increasing taxes on high earners.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1381', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB699', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB987']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Akilah Weber Pierson / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5470008-3c0d-4970-a485-053621d8f0a6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Weber Pierson's AB-797 (2023) mandated independent police oversight commissions for all California cities and counties â a structural accountability reform protecting communities' rights to fair governance. Her civil rights legislative record (AB-1815 CROWN Act, SB-518 reparations bureau) consistently addresses systemic inequities affecting historically disenfranchised communities. No voter suppression bills authored; consistent with California Democratic position of expanding early voting and making mail-in voting available to all voters.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB797', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1815']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ashby serves as California Senate Majority Leader in the pro-choice Democratic supermajority and has not authored any abortion-restriction bills. Her SB-989 (2023-24, chaptered) expanded domestic violence fatality investigation protections, and SB-963 (2023-24, chaptered) required trauma-informed care protocols for trafficking and DV victims at hospitals. These women's rights bills signal a strong pro-access framing consistent with the mainstream California Democratic position of keeping abortion legal and accessible through the second trimester.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB989', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB963']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Ashby authored SB-11 (2025-26, enacted) requiring AI digital replica providers to display consumer warnings and establishing court rules for AI-generated evidence admissibility. She also authored SB-1111 (2025-26) extending civil and criminal liability for unauthorized digital replica creation, and SB-1050 (2025-26) mandating disclosure of synthetic digital performers in advertising. These bills require basic safety transparency and accountability before deployment without imposing heavy pre-approval mandates, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB11', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1111', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1050']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$No specific campaign finance reform or dark money bills were found in Ashby's 2023-26 legislative record. Her SB-314 (2023-24, chaptered) creating an independent redistricting commission for Sacramento County reflects support for government accountability and transparency. As Senate Majority Leader operating within California's existing Political Reform Act framework, her record suggests requiring full disclosure of political donations while not pursuing structural bans on corporate spending.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB314', 'https://sd08.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Ashby's SB-961 (2025-26) expands student CalFresh eligibility and creates a data-sharing pipeline to reach approximately 300,000 eligible students missing roughly $140 million in food assistance annually. Her 2023-24 legislative package included bills for foster youth college funding. As Sacramento Majority Leader she has consistently pushed to expand public assistance programs for low- and middle-income families, aligning with significantly expanding subsidies and provider grants for access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB961', 'https://sd08.senate.ca.gov/press-releases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ashby's SB-578 (2023-24, chaptered) strengthened juvenile court protections for dependent children and tribal child welfare rights, SB-963 (2023-24, chaptered) required trauma-informed care for trafficking and DV victims, and SB-989 (2023-24, chaptered) enhanced domestic violence death investigation including family access rights. Wikipedia notes she spent 12 years on Sacramento City Council focused on economic development in underserved communities. Her record reflects strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB578', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB963', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB989']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ashby authored SB-1010 (2025-26) establishing a refrigerant stewardship program to prevent high-global-warming-potential gases from entering the atmosphere. SB-147 (2023-24, chaptered) enabled wind and solar energy project permits. SB-1283 (2025-26) streamlines EV charging station installation permits. These are targeted clean energy facilitation bills without a comprehensive fossil-fuel phase-out mandate. Her SB-659 and SB-639 reflect infrastructure pragmatism for the Sacramento Valley agricultural economy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1010', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB147', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1283']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$No direct data center bills appear in Ashby's 2023-26 legislative record. Her SB-1010 (refrigerant stewardship for cooling appliances) and SB-1283 (EV charging permit streamlining with equipment standards and community notification requirements) reflect a pattern of targeted energy and environmental accountability with reasonable industry flexibility. As Sacramento area Majority Leader with a significant tech corridor in her district, her approach aligns with allowing development with impact assessments and energy cost-sharing requirements before approval.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1010', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1283']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$In January 2026 Ashby's office issued a public statement condemning the Minneapolis ICE raids, characterizing them as part of actions by a federal government acting in an unhinged manner and calling the raids unfathomably cruel. This strong opposition to aggressive immigration enforcement signals she supports deporting only serious violent criminals while providing legal protection to long-term residents and families, consistent with California Senate Democratic caucus policy.$$,
        ARRAY['https://sd08.senate.ca.gov/press-releases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ashby's SB-147 (2023-24, chaptered) enabled permits for wind and solar energy projects but also covered water infrastructure and transportation. Her water supply bill SB-659 and flood management SB-639 reflect infrastructure pragmatism for the Sacramento Valley agricultural and water economy. She has not authored bills to ban new fossil fuel permits or expand fossil fuel drilling. Her record reflects maintaining current production levels with existing environmental regulations while facilitating renewable energy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB147', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB659']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ashby authored SB-1180 (2023-24, chaptered) requiring health plans and Medi-Cal to reimburse community paramedicine and mobile integrated health programs, expanding coverage to alternative emergency care models with equal patient cost-sharing. SB-1464 (2023-24, chaptered) modernized cardiac catheterization lab regulations to expand the types of procedures hospitals can offer. Her food assistance and social services bills reflect consistent support for expanding public coverage through regulated insurance without authoring single-payer legislation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1180', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1464']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Ashby authored SB-802 (2025-26) transforming Sacramento's Housing and Redevelopment Agency into a regional authority coordinating affordable housing and homelessness services across Sacramento County and member cities, with a mandatory advisory board including homeless individuals and service providers. Her office issued a statement responding to Sacramento's 2024 Point-in-Time Count. The bill prioritizes extremely low-income households and trauma survivors. Her approach is coordinated regional investment in shelter and services as the primary strategy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB802', 'https://sd08.senate.ca.gov/press-releases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ashby authored SB-802 (2025-26) creating a regional housing and homelessness coordination authority for Sacramento County. SB-916 (2025-26) extends litigation protection bonds to student housing developments to reduce lawsuit barriers to affordable housing projects. SB-639 (2025-26, chaptered) extended flood protection deadlines for Sacramento Valley jurisdictions to facilitate housing development. Wikipedia notes housing was a 12-year focus during her city council tenure, making her a consistent advocate for expanding affordable housing production.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB802', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB916', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB639']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ashby's January 2026 statement strongly condemned federal ICE raids as unfathomably cruel and characterized the administration's immigration enforcement as unhinged. Her SB-961 (2025-26) expanding CalFresh eligibility benefits immigrant college students. As California Senate Majority Leader in a pro-immigration Democratic caucus, her legislative and rhetorical record is oriented toward protecting immigrants and providing public services rather than enforcement, aligning with significantly increasing legal pathways and creating protections for current residents.$$,
        ARRAY['https://sd08.senate.ca.gov/press-releases', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB961']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Ashby's SB-1180 (2023-24, chaptered) explicitly required Medi-Cal to cover community paramedicine and mobile integrated health programs pending federal approval. SB-961 (2025-26) expands CalFresh food assistance to eligible college students. Her foster youth college funding bills and social services provisions reflect consistent support for expanding Medicaid coverage and safety net programs for vulnerable populations, consistent with lowering the Medicare eligibility age and significantly expanding Medicaid access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1180', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB961']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Ashby authored SB-11 (2025-26, enacted), SB-1111, and SB-1050 addressing AI-generated synthetic media. These bills require consumer warnings, consent, and advertising disclosure for digital replicas and synthetic performers but do not mandate broad content moderation or algorithmic fact-checking. Her approach targets specific categories of synthetic media deception through disclosure requirements without mandating platform removal of false information, reflecting encouragement of targeted disclosure standards rather than broad government content moderation mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB11', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1111', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1050']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Ashby authored SB-314 (2023-24, chaptered) establishing a Citizens Redistricting Commission for Sacramento County. The 14-member commission is selected through random drawing from a qualified applicant pool, with members prohibited from considering incumbent positions or political affiliation when drawing supervisorial district maps. The commission must hold public hearings across all supervisorial districts with translation services. This reflects strong support for independent redistricting commissions with equal community representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct religious freedom legislation was found in Ashby's 2023-26 legislative record. As Sacramento Majority Leader serving a highly diverse district including Elk Grove (one of the most diverse cities in California), her governance approach reflects balancing religious practices with equal treatment under the law. Her social services and civil rights focus does not include either strict secularist bills or broad religious exemption legislation, placing her at the mainstream California Democratic balance position.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby', 'https://sd08.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Ashby serves as California Senate Majority Leader in the Democratic caucus which uniformly supports same-sex marriage with full legal protections. She has not authored any bills restricting LGBTQ rights, and her civil rights legislative record reflects a rights-protective posture. Her position is consistent with allowing same-sex marriage nationwide while protecting some religious organizations' right to decline participation in ceremonies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby', 'https://sd08.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '00b95a6a-75db-4521-b523-3326bba938de', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ashby authored SB-414 (2025-26, enacted) creating an independent Office of the Education Inspector General to conduct forensic audits of public school finances and combat fraud, extending oversight to charter schools. SB-478 (2025-26) addressed school library leadership and SB-914 (2025-26) strengthened school audit requirements. Her entire education legislative record focuses on strengthening and holding accountable public institutions. No voucher expansion bills authored; consistent with prioritizing public school funding with vouchers restricted to low-income families without adequate local options.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB414', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB914']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Social Security is a federal program outside California state legislative jurisdiction, and no direct SS bills appear in Ashby's record. Her consistent pattern of expanding safety net access through SB-961 (CalFresh for students), SB-1180 (Medi-Cal expansion), and foster youth benefits reflects strong support for protecting and expanding public benefit programs. This record is consistent with modestly increasing Social Security benefits while raising taxes on higher earners to strengthen the program, though direct evidence on SS specifically is limited.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB961', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1180']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Tariffs are a federal issue outside California state legislative jurisdiction and no tariff-related statements or bills appear in Ashby's legislative record. As Sacramento area Majority Leader with a district including agricultural interests in Elk Grove and light manufacturing, she would be expected to support selective trade protections for key industries. Insufficient direct evidence exists to score this topic; her state-level role limits exposure to this federal issue.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ashby has not authored tax-cut legislation and serves in California's Democratic supermajority which consistently supports progressive taxation to fund public services. Her SB-961 (CalFresh expansion), SB-1180 (Medi-Cal coverage), SB-802 (housing authority), and SB-1010 (refrigerant stewardship) all require sustained public investment funded by tax revenue. As Sacramento Majority Leader she supports California's progressive tax framework, consistent with modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB961', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB802']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$No direct transgender athlete legislation was authored by Ashby in her 2023-26 legislative record. As California Senate Majority Leader in the Democratic caucus, she operates under California's existing law allowing students to participate in school sports and activities consistent with their gender identity. No evidence of supporting restrictions on transgender athletes was found. Her civil rights record reflects support for transgender inclusion, consistent with allowing transgender athletes to compete on teams matching their gender identity after documenting their transition.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby', 'https://sd08.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', '24e9212c-b011-422a-865c-093e35050901',
        $$Ukraine aid is a federal issue outside California state legislative jurisdiction, and no Ukraine-specific bills or statements appear in Ashby's record. As California Senate Majority Leader in the Democratic caucus, she operates within a caucus that has broadly supported continued US aid to Ukraine. Insufficient direct evidence exists to score this topic with full confidence; however her Democratic caucus alignment suggests continuing current levels of aid to help Ukraine defend itself.$$,
        ARRAY['https://en.wikipedia.org/wiki/Angelique_Ashby']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Angelique Ashby / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ashby authored SB-314 (2023-24, chaptered) establishing an independent Citizens Redistricting Commission for Sacramento County with strong public participation requirements including hearings across all supervisorial districts and translation services for non-English speakers. Her commitment to transparent independent redistricting and public access reflects alignment with California's voting rights framework. No voter suppression or photo ID bills authored; consistent with expanding early voting and making mail-in voting available to all voters without requiring excuses.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB314', 'https://sd08.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Caballero authored SB-520 (2025) establishing a California Nurse-Midwifery Education Fund to expand reproductive healthcare access infrastructure, addressing maternity care deserts including in her Central Valley district where over 50 maternity wards have closed since 2013. She authored SB-1386 (2024) strengthening evidence protections for sexual assault plaintiffs and SCR-44 (2023) designating Sexual Assault Awareness Month. No bills restricting abortion access were found in her legislative record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB520', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1386', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SCR44']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Caballero authored SB-785 (2025) creating a 50% income tax credit for families' unreimbursed durable medical equipment expenses for children with complex medical conditions and SB-624 (2025) ensuring foster youth receive tax credit guidance and free filing assistance. Her approach is targeted tax credits and subsidies for families below an income threshold rather than universal public childcare programs. No universal childcare bill was found in her record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB785', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB624']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Caballero authored SB-734 (2025) expanding the California Racial Justice Act to strengthen protections against racial discrimination in criminal proceedings, SB-1386 (2024) limiting defendant use of plaintiff sexual history to attack credibility in civil assault cases, and SJR-6 (2024) urging federal action to restore veterans benefits to approximately 14000 LGBTQ servicemembers discharged under discriminatory Don't Ask Don't Tell policies. This reflects a consistent pattern of strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB734', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SJR6', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1386']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Caballero authored SB-306 (2024) requiring reporting and planning for building decarbonization and extreme heat resilience, SB-643 (2025) establishing a $50M Carbon Dioxide Removal Purchase Program, SB-88 (2025) developing a biomass-to-carbon-removal strategy, and SB-80 (2025) creating a Fusion R&D Innovation Initiative. Her approach invests in clean energy and climate infrastructure but emphasizes pragmatic transition given Central Valley agriculture interests rather than declaring a climate emergency or banning fossil fuels.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB306', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB643', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB88']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Caballero authored SB-831 (2024) authorizing California's Governor to negotiate a federal parole program specifically to protect undocumented agricultural workers from deportation risk, reflecting her Central Valley district's reliance on immigrant farm labor. The bill explicitly seeks to provide legal status pathways to undocumented workers facing deportation, consistent with the stance of deporting only serious violent criminals while providing legal status to others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Caballero authored SB-438 (2024) creating a narrow exception allowing incidental oil residue from carbon sequestration Class VI wells â a pragmatic accommodation for the fossil-fuel-adjacent Central Valley economy â while also authoring SB-1420 (2024) streamlining CEQA review for non-fossil hydrogen production facilities and SB-88 (2025) on biomass alternatives to open burning. Her record reflects maintaining current fossil fuel production levels with existing environmental regulations while investing in clean alternatives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB438', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1420', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB88']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Caballero authored SB-870 (2024) extending the Medi-Cal managed care provider tax with the explicit legislative finding that Medi-Cal underfunding has created a two-tiered system exacerbating health inequities and that reimbursement covers only 74 cents per dollar of actual care costs â specifically targeting rural hospital closures in her Central Valley district. She also authored SB-621 (2024) expanding biosimilar drug coverage and SB-524 (2024) extending pharmacist prescription authority and Medi-Cal coverage for testing services.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB870', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB621', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB524']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Caballero authored SB-657 (2024) requiring the Interagency Council on Homelessness to develop staff training for workers assisting older adults experiencing homelessness, SB-37 (2024) creating the Older Adults and Adults with Disabilities Housing Stability Pilot Program providing housing subsidies for at-risk seniors and disabled persons, and SB-17 (2024) increasing low-income housing tax credit allocations for senior housing. Her approach emphasizes shelter capacity expansion and targeted services over criminalization.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB657', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB37', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB17']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Caballero authored a major housing supply package: SB-684 (2024) streamlining ministerial approval for small residential subdivisions up to 10 units with 60-day approval timelines, SB-1123 (2024) expanding ministerial approval to vacant single-family-zoned lots, SB-747 (2024) strengthening surplus land requirements to produce affordable housing with 55-year affordability covenants, SB-225 (2024) creating an anti-displacement acquisition program, and SB-808 (2025) expediting judicial review of housing permit denials. She is among California's most active legislators on housing supply and affordability.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB747', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB808']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Caballero authored SB-831 (2024) authorizing the Governor to negotiate a federal parole program for undocumented agricultural workers in California's farming sector. The bill's findings document California produces over 13% of US agricultural value and that undocumented workers face deportation risks despite essential economic contributions. Her Central Valley district has one of California's largest Latino immigrant populations and her legislation reflects support for significantly increasing legal pathways and legal status for long-term undocumented residents.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Caballero authored SB-870 (2024) extending the Medi-Cal managed care organization provider tax with the explicit finding that state reimbursement covers only 74 cents per dollar of actual care costs and that Medi-Cal underfunding has created a two-tiered healthcare system. The bill specifically targets rural hospital closures in her district. She authored SB-524 (2024) extending Medi-Cal coverage to pharmacist testing and medication services. Her record reflects strong support for expanding and adequately funding Medicaid programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB870', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB524']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Caballero authored SJR-6 (2024) urging federal action to upgrade discharges and restore benefits to approximately 14000 LGBTQ servicemembers dismissed under Don't Ask Don't Tell and predecessor discriminatory military policies from the 1940s through 2010. As a CA Democratic state senator she has not authored any legislation restricting same-sex marriage. SJR-6 demonstrates active LGBTQ rights advocacy consistent with supporting nationwide same-sex marriage recognition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SJR6']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '00b95a6a-75db-4521-b523-3326bba938de', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Caballero authored SB-609 (2024) strengthening local public school accountability by requiring school districts to post Local Control and Accountability Plans on the California School Dashboard. She has not authored any school voucher or private school choice legislation. Her focus on public school transparency and accountability reflects prioritization of public school funding and opposition to diverting taxpayer money to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB609']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Caballero / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8b15f324-ed8b-4cc9-92b4-fdaf07896b20', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Caballero's tax record shows targeted relief rather than broad progressive restructuring: SB-565 (2024) created free tax filing assistance for low-income CalEITC and foster youth credit recipients, SB-785 (2025) created a 50% tax credit capped at $5000 annually for children with complex medical conditions, and SB-419 (2025) created a temporary hydrogen fuel sales tax exemption for zero-emission vehicle parity. SR-58 expressed support for the California Earned Income Tax Credit. Her approach reflects keeping current tax rates while closing gaps and providing targeted credits rather than broad rate increases.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB565', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB785', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB419']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Allen is a coastal LA Democratic senator with no abortion-restriction bills and a consistent pro-choice voting record in the CA Democratic caucus. Co-authored SB 277 (2015) mandating school vaccine requirements alongside Sen. Pan â demonstrating comfort with government-enforced health access. No bills limiting reproductive access found; aligned with CA mainstream position of keeping abortion legal and accessible through the second trimester and beyond.$$,
        ARRAY['https://sd24.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB277']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Allen authored SB 254 (2016) placing a voter advisory on the November ballot directing California officials to use all of their constitutional authority including proposing constitutional amendments to overturn Citizens United v. FEC, citing that the ruling allows unlimited corporate spending to influence elections. He also authored SB 459 (2021) requiring specific bill-by-bill disclosure of lobbying activity and rapid pre-adjournment reporting of new lobbying contracts. This is a strong anti-dark-money and pro-structural-reform record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB254', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB459']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Allen authored SB 812 (2025-26) expanding Medi-Cal and insurance coverage for youth mental health and substance use treatment at drop-in centers serving ages 12-25 without prior authorization requirements. He authored SB 502 (mobile optometry for children) and SB 3 (higher education coordination). His pattern of expanding government-funded youth health and education services for low- and middle-income families is consistent with significantly expanding subsidies and provider grants for childcare and youth services access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB812', 'https://sd24.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Allen authored SCA 2 (2022) to repeal Article XXXIV of the California Constitution â a provision historically used to block public housing in white neighborhoods by requiring local voter approval â directly removing a structural barrier to housing equity. He authored SB 1365 (2025-26) strengthening anti-price-gouging and anti-rent-gouging enforcement. His decade-long legislative record consistently addresses systemic barriers facing low-income and historically marginalized communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SCA2', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1365']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Allen chairs the Senate Environmental Quality Committee and authored SB 867 (2024) â a $10 billion climate bond for wildfire prevention, drinking water, coastal resilience, and clean energy transmission with a 40% equity set-aside. He authored SB 1161 (2016) extending the statute of limitations to hold fossil fuel companies accountable for decades of climate deception campaigns, and the SB 54 Plastic Pollution Prevention Act (2022). This record reflects a strong commitment to rapidly transitioning to clean energy and reducing fossil fuel reliance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB1161', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB54']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Allen authored SB 1161 (2016) holding fossil fuel companies legally accountable for multi-decade climate deception campaigns, extending the statute of limitations for unfair competition suits. SB 601 (2025-26) restores California Clean Water Act protections for streams and wetlands degraded by point-source discharges, reversing federal rollbacks. As Senate Environmental Quality Committee chair he has consistently legislated against fossil fuel industry harm. His $10B climate bond (SB 867) prioritizes clean energy transition infrastructure.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB1161', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB601', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Allen authored SB 812 (2025-26) expanding Medi-Cal and private insurance coverage for youth mental health and substance use disorder services at drop-in centers without prior authorization. He co-authored SB 277 (2015) with Sen. Pan mandating school vaccinations â demonstrating support for government-enforced public health standards. SB 367 (2025-26) strengthens LPS conservatorship and mental health care access. His record reflects consistently expanding public and Medi-Cal coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB812', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB277', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB367']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Allen authored SB 1444 (2022) establishing the South Bay Regional Housing Trust â a joint powers authority to fund housing for homeless individuals and extremely low-income households in LA's South Bay region. He authored SB 1365 (2025-26) banning rent gouging during emergencies and SB 749 (2025-26) strengthening mobilehome park preservation for low-income residents. His approach emphasizes building affordable housing capacity and expanding rental assistance programs as the primary homelessness response.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1444', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1365', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB749']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Allen authored SCA 2 (2022) to repeal Article XXXIV â the voter-approval barrier that historically blocked public housing â establishing him as one of California's most aggressive pro-affordable housing legislators. He created the South Bay Regional Housing Trust (SB 1444), authored SB 715 adjusting RHNA housing allocations for fire risk areas, SB 815 requiring wildfire-resilient housing planning, and SB 1092/1093 protecting mobilehome park residents. His consistent record reflects building millions of affordable units and expanding rental assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SCA2', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1444', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB715']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Allen authored SB 812 (2025-26) expanding Medi-Cal managed care coverage for youth mental health at drop-in centers without prior authorization. SB 367 (2025-26) strengthens LPS conservatorship and mental health care system access. His repeated Medi-Cal expansion bills and consistent support for government-funded healthcare services reflect strong alignment with significantly expanding Medicaid coverage and removing barriers to access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB812', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB367']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Allen authored SB 139 (2019) requiring all California counties over 400,000 residents to establish independent redistricting commissions with bipartisan composition requirements, public hearings in each supervisorial district, translation services, and a court-ordered fallback if commissions miss deadlines. This directly established independent redistricting commissions with equal representation from both major parties â aligning precisely with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201920200SB139', 'https://sd24.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Benjamin Allen / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4486f856-118b-475c-83f0-078581a7b268', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Allen authored SB 450 (2016), the California Voter's Choice Act, expanding all-mail elections statewide, requiring vote centers for every 10,000 registered voters, mandating ballot drop boxes, and requiring multilingual accessibility â a landmark voting access expansion. He authored SB 212 (2019) authorizing ranked choice voting for local elections. Both bills substantively expanded early and mail-in voting access, aligning with value 2 of expanding early voting and making mail-in voting available to all voters.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201520160SB450', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201920200SB212']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Archuleta voted Aye on SB 1375 (2022) expanding nurse practitioners scope of practice for abortion services and Aye on AB 2099 (2024) addressing crimes against reproductive health services. No anti-abortion bills authored or supported. His voting record is consistent with California mainstream Democratic support for legal abortion access through at least the second trimester.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1375', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Archuleta voted Aye on SB 1047 (2024) the Safe and Secure Innovation for Frontier Artificial Intelligence Models Act which passed the Senate 30-9 and would have required basic safety testing before deploying frontier AI models. He serves on the Energy Utilities and Communications Committee giving him jurisdiction over AI energy infrastructure. Voting record supports requiring basic safety testing before AI deployment consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://sd30.senate.ca.gov/committees']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$No campaign finance bills authored or clear public statements found. Archuleta focuses legislatively on veterans military public safety and energy infrastructure rather than political reform. As a standard California Democratic legislator his pattern is consistent with maintaining current disclosure requirements without strong advocacy for structural limits on corporate money aligning with value 3.$$,
        ARRAY['https://sd30.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Archuleta voted Aye on SB 976 (2022) the Universal Preschool Act supporting expanded early childhood education access for all California families. His support for expanded social services and constituent focus on working-class families in Whittier and Pico Rivera is consistent with significantly expanding subsidies and provider grants aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB976', 'https://sd30.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Archuleta voted Aye on AB 1078 (2023) requiring diverse instructional materials and curriculum and Aye on SB 857 (2023) establishing an LGBTQ pupil needs advisory task force. He authored SB 1158 extending the Carl Moyer air quality program benefiting environmental justice communities in his district. His voting record supports strengthening civil rights protections consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB857']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Archuleta authored SB 1158 (2024) extending the Carl Moyer Memorial Air Quality program SCR 21 (2023) recognizing hydrogen in clean energy transition SB 895 (2020) redirecting technical assistance to zero-emission fuels and SB 1418 (2024) requiring expedited permitting for hydrogen fueling stations. He voted Aye on SB 867 (2024) the climate and clean air bond. These actions invest in clean energy while maintaining a pragmatic infrastructure approach rather than rapid fossil fuel phase-out consistent with value 3.$$,
        ARRAY['https://sd30.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1418']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Archuleta chairs the Select Committee on Hydrogen Energy and serves on the Energy Utilities and Communications Committee giving him direct oversight of energy demand from large facilities. He authored SB 1418 (2024) requiring impact assessments expedited permitting and safety compliance for hydrogen fueling infrastructure a similar regulatory framework applicable to data centers. No data-center-specific bills found but his committee work and infrastructure record suggest a community impact assessment approach consistent with value 3.$$,
        ARRAY['https://sd30.senate.ca.gov/committees', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1418']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Archuleta district office website maintains an immigration rights resource page stating he will stand with immigrant families and connecting residents with CHIRLA the National Immigration Law Center and other immigrant legal aid organizations responding to ICE enforcement activity. No pro-enforcement or deportation-supportive bills authored. Record is consistent with protecting undocumented residents except for serious violent crime aligning with value 2.$$,
        ARRAY['https://sd30.senate.ca.gov/immigration']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Archuleta authored SB 1418 (2024) for hydrogen fueling infrastructure SB 895 (2020) redirecting zero-emission fuel technical assistance SB 643 (2021) requiring statewide fuel cell vehicle infrastructure assessment and SCR 21 (2023) recognizing hydrogen in clean energy. He voted Aye on SB 867 the clean air bond. His approach supports transitioning to clean fuels through infrastructure investment without explicitly banning new fossil fuel permits consistent with maintaining current production while investing in alternatives at value 3.$$,
        ARRAY['https://sd30.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB643', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1418']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Archuleta voted Aye on AB 1085 (2023) adding housing support services to Medi-Cal Aye on SB 525 (2023) establishing minimum wages for healthcare workers and Aye on SB 1375 (2022) expanding nurse practitioner scope for reproductive healthcare. He authored SB 289 (2019) maintaining Medi-Cal waitlist positions for military families. Record shows consistent support for expanding public coverage alongside private insurance aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1085', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1375']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Archuleta voted Aye on SB 344 (2021) providing grants for homeless shelters Aye on SB 326 (2023) the Behavioral Health Services Act expanding mental health and substance abuse services and Aye on AB 1085 (2023) adding housing support to Medi-Cal. His record supports investing in shelter capacity outreach and services consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB344', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB326', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1085']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Archuleta voted Aye on SB 9 (2021) allowing duplexes on single-family lots statewide SB 10 (2021) enabling higher density near transit AB 1287 (2023) strengthening density bonus law SB 4 (2023) allowing housing on religious institution land and AB 2011 (2022) the Affordable Housing and High Road Jobs Act. This consistent Aye record on California pro-housing legislation supports building millions of affordable units aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1287']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Archuleta office page states he will stand with immigrant families and connects constituents to immigration legal resources including CHIRLA and the National Immigration Law Center. He authored employment anti-discrimination bills protecting immigrants and SB 289 (2019) protecting Medi-Cal access for military families. His district is heavily Latino and immigrant-populated. Record is consistent with significantly increasing legal pathways to status aligning with value 2.$$,
        ARRAY['https://sd30.senate.ca.gov/immigration', 'https://sd30.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Archuleta voted Aye on AB 1085 (2023) expanding Medi-Cal to include housing support services Aye on SB 525 (2023) establishing minimum wages for healthcare workers to stabilize the Medi-Cal provider base and authored SB 289 (2019) protecting Medi-Cal waitlist positions for active duty military families. No privatization votes found. Record shows consistent support for expanding Medi-Cal coverage consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1085', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201920200SB289']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Archuleta voted Aye on AB 2655 (2024) the Defending Democracy from Deepfake Deception Act and Aye on AB 2839 (2024) prohibiting deceptive media in election advertisements. Both bills narrowly targeted election-related AI misinformation rather than broad platform content moderation. No bills requiring general fact-checking mandates or algorithm transparency authored. Pattern supports targeted voluntary standards for specific harms without mandating broad government content moderation consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2839']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No religious freedom bills authored or clear public statements found. Archuleta voted Aye on SB 107 (2022) protecting gender-affirming healthcare which intersects with religious exemption debates. His district includes both Latino Catholic communities and diverse immigrant populations. No strong signals in either direction on religious exemptions from civil rights laws. Evidence supports a balance between protecting religious practices and equal treatment consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://sd30.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Archuleta voted Aye on SB 107 (2022) protecting gender-affirming healthcare Aye on SB 857 (2023) establishing an LGBTQ student needs advisory task force and Aye on AB 1078 (2023) requiring diverse instructional materials. As a California Democrat representing a majority-minority urban district no anti-LGBTQ positions found. His record supports nationwide same-sex marriage while protecting some organizational religious conscience rights consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB857']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '00b95a6a-75db-4521-b523-3326bba938de', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Archuleta authored SB 1315 (2024) requiring state accountability reporting on local educational agencies supporting public school oversight. He voted Aye on AB 1078 (2023) ensuring diverse instructional materials in public schools. As a California Democrat with a working-class district dependent on strong public schools his record reflects prioritizing public school funding while opposing voucher diversion consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1315', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$No Social Security-specific state bills authored as SS is a federal program. Archuleta authored SB 1407 (2026) excluding military retirement and survivor pay from California income tax expanding tax relief for veterans and their families. His strong veterans advocacy record and support for expanded social services for seniors and low-income residents is consistent with modestly increasing benefits and strengthening retirement programs aligning with value 2.$$,
        ARRAY['https://sd30.senate.ca.gov/press-releases', 'https://sd30.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '683c8084-2281-4920-a07c-18439b2dd413',
        $$No direct tariff legislation at the state level as tariffs are federal policy. Archuleta focus on hydrogen energy infrastructure domestic manufacturing of clean energy equipment and support for California industries aligns with selective use of trade protections for key American industries. As a military veteran and pragmatic centrist Democrat representing a working-class LA County district value 3 is the best mapping of available evidence.$$,
        ARRAY['https://sd30.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Archuleta authored SB 296 (2025) expanding the disabled veteran property tax exemption and SB 1407 (2026) excluding military retirement pay from California income taxation. He voted Aye on SB 525 (2023) raising healthcare worker minimum wages. His support for social services expansion and working-class constituents combined with targeted rather than broad tax cuts is consistent with modestly increasing taxes on high earners while protecting middle-class families aligning with value 2.$$,
        ARRAY['https://sd30.senate.ca.gov/press-releases', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB296']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Archuleta voted Aye on SB 107 (2022) protecting gender-affirming healthcare broadly for transgender individuals. No bills specifically restricting or fully permitting transgender athletes found. His pragmatic centrist approach and absence from both trans-inclusive sports advocacy and anti-trans sports legislation camps suggests a case-by-case approach. Value 3 is the best mapping given his Aye vote on gender-affirming care generally with insufficient direct evidence on athlete-specific policy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', '24e9212c-b011-422a-865c-093e35050901',
        $$No Ukraine-specific legislation at the state level. As chair of the Senate Military and Veterans Affairs Committee and a former paratrooper with the 82nd Airborne Division Archuleta has consistently championed U.S. military readiness and allied defense commitments. His military background and committee leadership suggest support for continued defense engagement consistent with helping Ukraine defend itself. No anti-Ukraine-aid statements found. Value 2 is the best inference from his military record.$$,
        ARRAY['https://sd30.senate.ca.gov/committees', 'https://en.wikipedia.org/wiki/Bob_Archuleta']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bob Archuleta / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29e15a5d-d98f-4536-ad62-05b2612f30ca', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Archuleta voted Aye on SB 1174 (2024) which prohibits local governments from requiring voter identification citing the Legislature finding that voter ID requirements have historically been used to disenfranchise low-income voters voters of color voters with disabilities and senior voters. He voted Aye on SB 789 (2023) a constitutional amendment related to election administration. Record supports expanding voting access without restrictive requirements consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jones voted NO on SB 345 (2023), California's bill protecting reproductive healthcare from out-of-state legal actions and ensuring California providers cannot lose licenses for offering abortion services. He opposes California's broad abortion protections and as CA Senate Minority Leader has sponsored no bills expanding abortion access, consistent with complete opposition to abortion access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB345', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '666bf03d-81fc-4138-ab15-69ae734c9023', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Jones did not cast a recorded vote (NVR) on SB 1047 (2024), California's AI safety bill requiring evaluations for frontier AI models. As Senate Minority Leader his legislative record shows no AI regulation bills authored and his general stance is to reduce regulations on businesses including the tech sector, consistent with allowing AI companies to develop freely without government interference.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '92730f69-ae57-401c-8ad1-2d07834a895d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Jones's signature Assembly bill AB 860 would prohibit direct political contributions by corporations and unions to candidates and restrict government deduction of funds for union political activities. This is framed as limiting organized labor's political power rather than establishing public financing. As Minority Leader he receives substantial business PAC contributions and has not backed broad campaign finance reform.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Jones's platform centers on reducing regulatory burdens and government spending; no childcare subsidy or access bills were found in his 2023-26 legislative record. As California Senate Minority Leader he consistently opposes new social spending programs. His platform of private sector job creation and lower taxes is inconsistent with expanded government childcare subsidies.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Jones was the sole vote against SB 403 (2023), which would have added caste discrimination to California's protected classes. He also voted NO on SB 345 protecting LGBTQ and reproductive rights. He previously sought to repeal the California DREAM Act. This record reflects opposition to new civil rights enforcement mandates and expanding protected classes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB345']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jones authored SB-2 (2025) to void California's updated Low-Carbon Fuel Standard regulations, arguing they would raise gas prices. He voted NO on SB 867 (climate bond, 2024) and NO on SB 253 (Climate Corporate Data Accountability Act, 2023). These actions reflect rejection of climate policies in favor of economic growth.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB2', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4559b513-0fd8-4ed1-babd-f3b554162f40', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Jones's legislative record shows no data center regulation bills authored. His consistent stance of opposing environmental and regulatory burdens on businesses  authoring SB-2 to void fuel standards and opposing energy-related compliance bills  is consistent with welcoming data center investment with minimal regulatory barriers and trusting economic growth to benefit residents.$$,
        ARRAY['https://sr40.senate.ca.gov/legislation', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '44905f3b-e105-4f6c-afc7-5d223813dbac', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Jones authored SB 554 (Safety Before Criminal Sanctuary Act, 2025) to weaken California's Values Act and require law enforcement to cooperate with ICE for individuals with criminal convictions. He voted NO on AB 1306 (HOME Act, 2023), which prohibited state corrections from honoring ICE detainers. He also previously sought to repeal the California DREAM Act.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB554', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1306', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'a22215c3-6693-4bc2-b248-01aebba14570', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Jones authored SB-2 (2025) to void California Air Resources Board amendments to the Low-Carbon Fuel Standard, framing cost reduction as economic relief. He voted NO on SB 867 (climate bond) and NO on SB 253 (corporate climate disclosure). His record reflects opposition to fossil fuel restrictions and support for removing environmental regulatory burdens.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB2', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jones voted NO on SB 729 (2023, health insurance coverage for infertility and fertility services) and NO on SB 112 (2023, Distressed Hospital Loan Program). His platform emphasizes private sector job creation and reducing regulatory burdens; no bills expanding healthcare coverage were found. He opposes state-mandated coverage expansions, consistent with leaving healthcare to private markets.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB112', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Jones's district page references public safety priorities and his general Republican stance opposes new government social spending. No homelessness housing-first legislation authored. His pattern favoring enforcement-based approaches to public order is consistent with prohibiting encampments with warnings and penalties while requiring basic shelter options, rather than investing primarily in services.$$,
        ARRAY['https://sr40.senate.ca.gov/', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jones voted YES on SB-4 (2023), allowing housing development by right near transit, reflecting support for market-driven supply expansion. He voted NO on ACA 1 (2023), which would have lowered the supermajority threshold for affordable housing bonds, reflecting opposition to government-funded affordable housing. This split record reflects preferring private development deregulation over government housing subsidies.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jones authored SB 554 (2025) to require law enforcement cooperation with ICE, voted NO on AB 1306 (2023) which restricted state corrections from assisting ICE, and previously sought to repeal the California DREAM Act per Wikipedia. His 2025 immigration priorities focus on restricting sanctuary policies and expanding deportation enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB554', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1306', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Jones voted NO on SB 112 (2023, Distressed Hospital Loan Program supporting healthcare facilities serving Medi-Cal patients). His platform consistently opposes new government healthcare spending. As California Senate Minority Leader he has not supported any Medi-Cal expansion bills and his record of opposing healthcare mandates is consistent with partial privatization and reduced Medicaid coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB112', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No specific misinformation bills were found in Jones's legislative record. As a conservative Republican Minority Leader, his general stance favoring limited government and opposing new content regulation is consistent with protecting free speech online and preventing government censorship, placing him at value 4.$$,
        ARRAY['https://sr40.senate.ca.gov/', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '48cc9585-ec22-4f53-8d42-6839828dd36f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$No specific redistricting reform bills authored by Jones were found. As a Republican Minority Leader in California, he has not sponsored independent redistricting commission legislation. The California Republican Party has historically preferred state legislative control with court oversight rather than independent citizen commissions, consistent with value 4.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Jones's opposition to SB 345 (reproductive healthcare protections), SB 403 (expanded civil rights), and AB 1955 (transgender student privacy) reflects voting in favor of religious organizations' ability to maintain traditional beliefs over anti-discrimination requirements. His profile as a conservative Republican from a faith-heavy East San Diego County district is consistent with strongly protecting religious freedom and complete organizational autonomy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB345']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Jones's consistent opposition to LGBTQ-protective legislation  including voting NO on SB 345 (gender-affirming care protections) and AB 1955 (SAFETY Act for transgender students)  and his profile as a conservative Republican representing inland San Diego County are consistent with opposition to same-sex marriage recognition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB345', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '00b95a6a-75db-4521-b523-3326bba938de', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Jones's platform favors expanding school choice and reducing public education mandates. As a conservative Republican he supports charter school expansion and private school options. His general stance of reducing regulatory burdens and supporting private sector over government extends to education, consistent with universal vouchers so education funding follows students to any school.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '87d20824-a6e9-407b-983c-65440084a0ab', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$As a state legislator Jones has no direct Social Security votes (a federal program). His platform of lower taxes, private sector job creation, and reducing government spending is most consistent with gradually raising the retirement age and reducing benefits for higher earners to preserve the program, rather than expanding it or fully privatizing it. No direct privatization statements found.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Jones has made no public statements specifically on federal tariff policy. As California Minority Leader his focus is on state economic issues. His support for lower taxes and private sector growth could align with selective tariffs to protect key American industries and jobs, but no direct evidence establishes a strong position on either side of the tariff debate.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Jones campaigned on private sector job creation through lower taxes on individuals and corporations and reducing regulatory burdens on businesses per Wikipedia. He introduced legislation to protect employers from payroll tax increases related to unemployment insurance debt. His consistent legislative platform is to reduce taxes broadly across income levels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Jones voted NO on AB 1955 (SAFETY Act, 2024), which protected transgender students' privacy and prohibited schools from requiring disclosure of gender identity to parents. His consistent opposition to all transgender-protective legislation reflects a stance of banning transgender athletes from competing on teams matching their gender identity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', '24e9212c-b011-422a-865c-093e35050901',
        $$No direct statements on Ukraine aid found in Jones's state legislative record. Social Security is a federal program outside his legislative scope. As a mainstream conservative Republican (not isolationist), he likely supports continued aid to help Ukraine defend itself but not significant escalation. Insufficient direct evidence exists to score this definitively; scored at 2 as the most defensible inference given his non-isolationist Republican profile.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Brian W. Jones / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ee130fd3-649d-49e1-bda4-13d9bbed2f6c', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jones's Republican identity and legislative record align with supporting strict voter verification requirements and opposing expansions to mail-in voting. He voted NO on SB 567 (tenant protection, showing consistent conservative pattern) and his San Diego district conservative base supports strict election integrity measures. As Minority Leader he has championed election security positions consistent with strict in-person voting with photo ID requirements.$$,
        ARRAY['https://en.wikipedia.org/wiki/Brian_Jones_(California_politician)', 'https://sr40.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Menjivar voted Aye on SB-233 (2024) extending California abortion services to Arizona patients fleeing that state's 1864 abortion ban, and Aye on SB-541 requiring schools to provide free condoms and banning age-based contraceptive sale refusals. She also authored SB-418 (2025, enacted) requiring health plans to cover prescription hormone therapy. Her record is consistently pro-reproductive-access with no evidence of any restrictions, aligning with legal access through the second trimester and beyond.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB233', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB541', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB418']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Menjivar voted Aye on SB-1047 (2024, major AI safety bill requiring pre-deployment evaluations), Aye on SB-53 (2025, frontier AI safety transparency and incident reporting requirements), Aye on SB-243 (2025, companion chatbot safety regulations), and Aye on SB-813 (2026, establishing CA AI Standards and Safety Commission). This pattern of supporting government-mandated safety testing and oversight before deployment aligns with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB813']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Menjivar authored SB-1027 (2024, enacted) modifying the Political Reform Act to require the Secretary of State to redact bank account numbers and authorized-person names from campaign committee filings before public disclosure. This is a narrow privacy-protection reform within the existing disclosure framework, not a structural limit on corporate donations or a public financing program, placing her at value 3 (require full disclosure of political donations).$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Menjivar authored SB-1112 (2024, enacted) expanding what childcare alternative payment programs can fund, including developmental screening information for families. She chairs the Senate Health and Human Services budget subcommittee and her overall legislative record reflects consistent support for subsidies and provider grants to expand access for low- and middle-income families, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1112', 'https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Menjivar voted Aye on SCA-2 (2023, repealing Art. 34 public housing supermajority requirement), Aye on ACA-5 (2023, removing the state constitutional ban on same-sex marriage), Aye on SB-403 (2023, caste discrimination protections), and Aye on AB-1955 (2024, SAFETY Act protecting LGBTQ+ student privacy). Her record reflects consistent support for strengthening civil rights enforcement and addressing systemic discrimination, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Menjivar voted Aye on SB-867 (2024, $10 billion climate bond), Aye on SB-540 (2025, renewable energy regional market framework to accelerate clean energy transition), and Aye on SJR-7 (2025, opposing Trump tariffs in part due to harm to clean energy supply chains). Her overall Senate record is strongly aligned with rapidly transitioning to renewable energy and phasing out fossil fuel reliance, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB540', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Menjivar voted Aye on SB-57 (2025, Ratepayer and Technological Innovation Protection Act), which authorizes the Public Utilities Commission to assess whether data center infrastructure costs create burdens for residential ratepayers and report findings to the Legislature by January 2027. This reflects a data-gathering and impact-assessment approach before approving large data center loads, consistent with value 3 (impact assessments and cost-sharing agreements before approval).$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Menjivar voted Aye on SB-831 (2023, agricultural worker parole and immigration protections), and her district office lists immigration services as a key constituent resource. She represents a district with a large immigrant population and has publicly cited her own family's Salvadoran immigrant roots. Her full Senate voting record consistently opposes deportation enforcement cooperation and supports legal pathways, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831', 'https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Menjivar voted Aye on SB-867 (2024, $10B climate bond) and Aye on SB-540 (2025, renewable energy grid market reform supporting California's fossil fuel phase-out goals). Her legislative record on energy is consistently aligned with California's stated policy to stop new fossil fuel permits and transition to renewables, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB540']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Menjivar's core legislative focus is healthcare access through regulated insurance. She authored SB-729 (2024, enacted) mandating infertility and IVF coverage, SB-62 (2025, enacted) expanding essential health benefits including hearing aids and durable medical equipment, and SB-418 (2025, enacted) requiring hormone therapy coverage. These bills expand coverage through a mix of regulated private insurance and Medi-Cal mandates rather than a single-payer system, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB62', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB418']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Menjivar serves on the Senate Health and Human Services budget subcommittee and her district office highlights social services and mental health resources as key constituent priorities. Her overall Senate voting record is consistent with California's shelter-expansion and outreach-first approach, reflecting support for investing in shelter capacity, outreach workers, and voluntary service connections rather than purely enforcement-based responses, aligning with value 2.$$,
        ARRAY['https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Menjivar voted Aye on SCA-2 (2023, repealing Art. 34 supermajority requirement for public housing), Aye on SB-4 (2023, housing near colleges), Aye on SB-684 (2023, small-unit housing), and Aye on SB-484 (2025, affordable housing coastal permitting streamlining). Her one NVR on SB-79 (2025) was due to stated concern about transit adequacy for working-class constituents, not opposition to density. Overall record strongly favors building more affordable housing units, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SCA2', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB484']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Menjivar voted Aye on SB-323 (2025, expanding Dream Act financial aid for undocumented students) and Aye on SB-831 (2023, agricultural worker parole protections). Her district office explicitly lists immigration services as a key resource, and she has publicly cited her family's Salvadoran immigrant roots. Her record reflects strong support for legal pathways and protecting immigrant residents, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831', 'https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Menjivar authored SB-62 (2025, enacted) and SB-729 (2024, enacted) expanding mandatory Medi-Cal and insurance coverage for fertility, hearing, and essential health benefits, and SB-471 (2025) expanding the Developmental Services ombudsperson. She chairs the Health and Human Services budget subcommittee. These actions reflect consistent support for significantly expanding Medicaid coverage and lowering eligibility barriers, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB62', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB471', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Menjivar voted Aye on SB-976 (2024, social media addiction restrictions for minors addressing algorithmic content harms) and Aye on SB-243 (2025, companion chatbot safety requiring deceptive-AI disclosures and prohibiting suicidal content). These votes address specific algorithmic and AI harms but do not mandate broad government-directed content removal or compelled fact-checking, placing her at value 3 (encourage voluntary standards with targeted safety requirements).$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$California uses an independent citizens redistricting commission and the Democratic caucus has consistently defended it against partisan interference. Menjivar's broader legislative record reflects support for independent redistricting commissions with equal-party representation. Her vote on SCA-2 (2023, a structural democratic reform ballot measure) further demonstrates support for direct-democracy checks on legislative power, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SCA2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No bills authored by Menjivar directly address religious freedom or exemptions. Her votes on LGBTQ rights (ACA-5, AB-1955) show she prioritizes equal treatment over broad religious carve-outs, but she has not authored legislation explicitly restricting religious organizations either. Her overall record suggests a balance between protecting religious practices and maintaining equal treatment under the law, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Menjivar voted Aye on ACA-5 (2023, enacted), the California constitutional amendment removing the state's same-sex marriage ban and establishing marriage as a fundamental right. She voted Aye on AB-1955 (2024) protecting LGBTQ+ student privacy. As the first LGBTQ legislator to represent the San Fernando Valley, she has been a public champion for full marriage equality and LGBTQ protections, aligning with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://en.wikipedia.org/wiki/Caroline_Menjivar']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Menjivar voted Aye on SB-494 (2025) tightening restrictions on nonclassroom-based charter schools and modifying renewal procedures to limit diversions from public education. Her budget subcommittee focus and authored bills on public services reflect consistent support for investing in public institutions over private alternatives, aligning with value 1: fully funding public schools and opposing voucher programs that divert taxpayer money.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB494']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Social Security is a federal program outside California legislators' direct jurisdiction; no direct votes are available. Menjivar's consistent pattern of expanding the social safety net through authored bills (SB-62 expanding health benefits, SB-471 developmental services, SB-729 infertility coverage) and her Health and Human Services subcommittee role reflect the Democratic mainstream of modestly increasing benefits and strongly opposing any privatization, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB62', 'https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Menjivar voted Aye on SJR-7 (July 2025), a California resolution urging President Trump to rescind his sweeping 10% base tariff on foreign goods and refund Americans for increased costs, citing projected $2,800/year household purchasing-power losses and supply chain disruption. This reflects opposition to broad blanket tariffs, consistent with selective use to protect key industries while opposing indiscriminate ones, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$No direct tax-rate legislation authored; state budget committee chairs typically lead on rates. Menjivar's extensive social safety net expansion (SB-62, SB-729, SB-471, childcare) and Health and Human Services budget subcommittee role are financed through California's progressive tax structure, which she supports. Her record aligns with the Democratic mainstream of modestly increasing taxes on high earners while maintaining current rates for middle-class families, consistent with value 2.$$,
        ARRAY['https://sd20.senate.ca.gov/', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB62']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Menjivar voted Aye on AB-1955 (2024, SAFETY Act protecting transgender students' privacy and identity in schools) and authored SB-418 (2025, enacted) requiring health plan coverage of hormone therapy without discrimination based on gender identity. As an openly LGBTQ legislator, she consistently supports transgender rights and has no record of supporting restrictions on transgender participation, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB418', 'https://en.wikipedia.org/wiki/Caroline_Menjivar']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', '24e9212c-b011-422a-865c-093e35050901',
        $$No Ukraine-specific votes are available in the California Legislature. Menjivar voted Aye on SJR-4 (May 2025) opposing Trump administration cuts to research funding, reflecting alignment with the Democratic mainstream opposing policy retrenchment. California Democratic caucus consensus consistently supports continued aid to Ukraine; no evidence of deviation from Menjivar. Low confidence stance â inferred from caucus alignment rather than direct vote.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Caroline Menjivar / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Menjivar voted Aye on SB-1174 (2024, anti-voter-ID measure) in the Senate Elections committee. Her broader Democratic voting record reflects consistent support for expanding early voting, mail-in access, and automatic voter registration. No evidence of supporting restrictive voter ID measures or opposing mail-in voting. Aligns with value 2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Blakespear voted Aye on SB 487 (2023, abortion provider protections shielding California providers from other states' laws), SB 385 (2023, abortion by aspiration training for physician assistants), and AB 2099 (2024, reproductive rights). Her issues page highlights civil rights and reproductive access as core livability priorities. Consistent votes on every abortion-access bill confirm support for legal, accessible abortion through the second trimester and beyond with no restriction bills authored or supported.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB487', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB385', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Blakespear voted Aye on SB 1047 (2024, AI safety requiring large model testing), SB 53 (2025, AI safety framework, passed 37-0), SB 813 (2026, AI oversight regulation), and AB 2013 (2024, AI training data transparency). Her votes support requiring basic safety testing before AI companies release new systems, without authoring expansive government-approval mandates. This pattern aligns with value 3 â basic safety testing required before public deployment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Blakespear authored SB 644 (2025), extending California's $3,000-per-election contribution limits to judicial, school district, and community college candidates previously exempt from state limits. She also voted Aye on SB 1027 (2024, campaign finance disclosure and transparency). This record of authoring new contribution limit legislation and supporting disclosure requirements reflects a stance of strictly limiting corporate donations and dark money, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB644', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Blakespear voted Aye on SB 1112 (2024, strengthening alternative payment programs for childcare and developmental screening for low-income families). Her issues page identifies healthcare access and livability as core priorities, and her 2025-26 legislative package of 46 bills reflects broad social services investment. The childcare payment program vote reflects support for significantly expanding subsidies and provider grants for low- and middle-income families, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Blakespear voted Aye on SB 403 (2023, adding caste to protected civil rights classes), SB 1137 (2024, expanding combination-of-characteristics discrimination claims), and AB 665 (2023, transgender youth civil rights protections). She authored SB 477 (2025, FEHA enforcement procedures) and SB 1237 (2025, Civil Rights Department improvements). This pattern of authoring FEHA enforcement bills and voting for expanded protections reflects a stance of strengthening civil rights enforcement and addressing systemic discrimination, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB477', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB665']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As Senate Environmental Quality Committee Chair, Blakespear helped establish California's cap-and-invest greenhouse gas reduction program. She voted Aye on SB 867 (climate bond), SB 253 (2023, corporate GHG emissions disclosure), and SB 261 (2023, climate-related financial risk disclosures), and authored SB 755 (2025, California Contractor Climate Transparency Act) and SB 1053 (plastic bag prohibition). This record reflects rapid transition to clean energy and phasing out fossil fuel reliance, consistent with value 2.$$,
        ARRAY['https://sd38.senate.ca.gov/issues', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB261']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$No bills authored or votes found specifically addressing data center energy costs or ratepayer protections. Her role as Environmental Quality Committee Chair and authorship of SB 755 (2025, Contractor Climate Transparency Act) and SB 253 (corporate emissions disclosure) indicates support for impact assessments and transparency requirements for major energy users. This suggests a balanced position allowing development with impact assessments and community benefit requirements, consistent with value 3.$$,
        ARRAY['https://sd38.senate.ca.gov/issues', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB755']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Blakespear voted Aye on SJR 9 (Jan 2026, condemning mass immigration raids by ICE/CBP in California, emphasizing harm to children and families, affirming rights of all Californians regardless of immigration status) and SB 831 (2023, immigration-related worker protections). These votes reflect consistent opposition to mass deportation and support for limiting enforcement to serious violent offenders while protecting immigrant communities, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As Environmental Quality Committee Chair, Blakespear was central to California's cap-and-invest GHG program. She voted Aye on SB 253 (corporate GHG disclosure) and SB 261 (climate financial risk disclosure), and authored SB 1259 (2025, requiring refineries to file detailed decommissioning and remediation plans with the State Water Resources Control Board). This authorship of industry wind-down planning legislation combined with cap-and-invest and climate transparency work reflects support for stopping new fossil fuel permits and planning a managed phase-out, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1259', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Blakespear voted Aye on SB 729 (2023, expanded IVF and fertility services insurance coverage) and authored SB 1257 (2024, Geographic Managed Care Pilot for San Diego, authored) and SB 242 (2025, Medicare supplement open enrollment protections removing barriers for people locked out of Medigap coverage). Her issues page identifies healthcare as a core livability priority. This record of expanding insurance access through mandated coverage and public program improvements reflects value 2 â public option alongside regulated private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB242', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Blakespear authored SB 16 (2025, Ending Street Homelessness Act) requiring jurisdictions to adopt housing-now action plans with targets to achieve functional zero unsheltered homelessness by 2031, and SB 1361 (2024, CEQA exemption for homelessness services contracts). She also authored SB 967 (2025, interim housing units zoning). Her issues page states: no one should be forced to sleep on the street. This authorship record reflects major investment in shelter capacity and affordable housing, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB16', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1361', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Blakespear authored SB 7 (2023, regional housing need), SB 482 (2023, multifamily supportive housing), SB 1077 (2024, coastal programs for dwelling units), SB 92 (2025, density bonuses), and SB 866 (2025-26, housing element reform). She voted Aye on SB 4 (2023, housing near colleges), SB 423 (2023, affordable housing), SB 684 (2023, small subdivision development), and ACA 1 (2023, housing bonds). This robust record of housing development authorship reflects strong support for building affordable housing at scale, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB92']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Blakespear voted Aye on SJR 9 (Jan 2026, strongly condemning mass immigration raids, affirming rights of all Californians regardless of immigration status, and calling for expanded legal services to protect immigrant families) and SB 831 (2023, immigration-related worker protections). These votes reflect support for significantly expanding immigration protections and creating legal pathways for long-term residents, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Blakespear authored SB 242 (2025), establishing a new annual 90-day open enrollment period for Medicare supplement insurance with guaranteed issue protections and eliminating the ESRD exclusion, lowering barriers to coverage for seniors locked out after initial enrollment. She also voted Aye on SB 729 (expanded fertility/infertility insurance) and SB 1289 (Medi-Cal call center standards). This record of authoring Medicare access expansion legislation reflects support for lowering the Medicare age barrier and expanding Medicaid, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB242', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Blakespear voted Aye on SB 976 (2024, social media algorithm transparency and child safety) and SB 896 (2024, AI-generated deepfakes in elections). No bills authored specifically targeting government content moderation or broad misinformation removal mandates. Her votes support transparency-based industry standards for combating misinformation rather than government mandates to remove content, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB896']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Blakespear voted Aye on SB 314 (2023), which creates independent redistricting commissions with equal representation from both major parties. This direct vote for bipartisan independent commissions rather than legislative control reflects value 2 â independent redistricting commissions with equal representation from both parties.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct bills authored or strong public statements found specifically on religious freedom exemptions from civil rights laws. Blakespear's civil rights votes (SB 403 anti-discrimination, SB 477 FEHA enforcement) indicate she does not support allowing religious exemptions to override anti-discrimination protections, but she has not authored legislation specifically targeting religious organizations. Her record suggests a balanced approach protecting religious practice while maintaining equal treatment under the law, consistent with value 3.$$,
        ARRAY['https://sd38.senate.ca.gov/issues', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB477']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Blakespear voted Aye on ACA 5 (Jul 2023, California constitutional amendment establishing marriage equality, Senate floor vote 31-0) and AB 1955 (Jun 2024, SAFETY Act protecting transgender and LGBTQ students from forced disclosure). Her legislative record consistently reflects full LGBTQ equality. These votes support requiring all states to recognize same-sex marriages with full federal benefits and protections, consistent with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Blakespear's legislative record shows no support for voucher programs and strong investment in public institutions across 46+ authored bills. Her housing, homelessness, and public program bills reflect consistent opposition to redirecting public funds to private alternatives. Her issues page emphasizes civil rights and public access. Consistent with the California Democratic supermajority position, she reflects a stance of fully funding public schools and opposing voucher programs that divert taxpayer money, consistent with value 1.$$,
        ARRAY['https://sd38.senate.ca.gov/issues', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Social Security is a federal program; no direct California state votes are available. Blakespear authored SB 242 (2025) improving Medicare supplement access for seniors, reflecting support for protecting and strengthening public retirement-age programs. Her broad social safety net investment across dozens of bills and consistent support for public programs are consistent with the Democratic mainstream of modestly increasing Social Security benefits while strengthening funding and opposing privatization, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB242', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Blakespear voted Aye on SJR 7 (Jul 2025), a California resolution urging President Trump to rescind blanket tariffs imposed since January 2025 and calling on Congress to terminate the national emergency declaration authorizing them, citing inflation, agricultural harm, and supply chain disruption. This vote opposes blanket indiscriminate tariffs while not calling for eliminating all tariffs, consistent with selective use of tariffs to protect key industries, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Blakespear voted Aye on ACA 1 (2023, public infrastructure bond financing) and authored SB 710 (2025, property tax exemption for active solar energy systems as a targeted clean-energy incentive). Her extensive public program authorship (SB 16, SB 242, SB 92, SB 482) requires sustained revenue and implies support for California's progressive tax structure. This record is consistent with modestly increasing taxes on high earners while maintaining current rates for middle-class families to fund public programs, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA1', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB710', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Blakespear voted Aye on AB 1955 (Jun 2024, SAFETY Act protecting transgender students from forced disclosure of their gender identity in schools, shielding educators who support LGBTQ youth). Her civil rights votes (SB 403, SB 477 FEHA enforcement) and LGBTQ-supportive record show no support for restrictions on transgender athletes. Evidence reflects support for allowing transgender athletes to compete consistent with their gender identity after completing basic documentation, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', '24e9212c-b011-422a-865c-093e35050901',
        $$No direct California state votes exist on Ukraine military aid (a federal issue). Blakespear voted Aye on SJR 9 (Jan 2026) opposing mass federal enforcement actions in California, reflecting Democratic alignment on federal policy matters. Her overall record is consistent with the California Democratic caucus position of supporting continued military and economic aid for Ukraine's defense. Low confidence stance â inferred from caucus alignment rather than direct vote.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://sd38.senate.ca.gov/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Catherine S. Blakespear / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Blakespear voted Aye on SB 1174 (May 2024, anti-strict voter ID and voting rights bill, passed 30-8) and authored SB 1493 (2024, elections reform) and SB 1476 (2024, Political Reform Act elections). Her consistent pro-access voting record reflects support for expanding early voting, making mail-in voting available without an excuse, and opposing strict photo ID requirements, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1493']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cabaldon has not yet authored a standalone abortion bill in his first Senate session (2025-26), but his consistent Aye votes on reproductive-adjacent healthcare bills (SB-418 covering gender-affirming care and nondiscrimination, SB-403 extending End of Life Option Act), his authorship of three Medi-Cal expansion bills, and his identity as an openly gay civil-rights champion place him squarely in California pro-choice mainstream supporting legal access without restriction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB418', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB403', 'https://en.wikipedia.org/wiki/Christopher_Cabaldon']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Cabaldon chairs the Senate Committee on Privacy, Digital Technologies and Consumer Protection and authored the most aggressive AI oversight package in 2025-26: SB-719 (mandatory state agency inventory of high-risk AI systems), SB-430 (local agency AI safeguards with human review mandates before adverse determinations), SB-1248 (state AI governance with bias monitoring), and SB-1159 (excluding AI from public-records and CEQA participation). He voted Aye on SB-53 (frontier AI safety reporting) and SB-243 (companion chatbot safety). This pattern reflects close government monitoring with required approval mechanisms before advanced AI deployment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB719', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB430', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cabaldon voted Aye on SB-644 (2025-26), which extends California contribution limits to judicial, school district, and community college district candidates. No public financing or dark-money ban bill authored. His record supports requiring disclosure and extending contribution limits but does not yet reflect advocacy for strict corporate donation limits or public campaign funding.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB644', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB644']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cabaldon voted Aye on SB-518 (2025, reparations for descendants of enslaved persons) and SB-477 (FEHA enforcement strengthening). As West Sacramento mayor, he authored a sweeping LGBTQ civil rights resolution (2009) supporting marriage equality, hate crimes legislation, and employment nondiscrimination, and chaired the LGBTQ Mayors Alliance (2019). This record reflects consistent support for strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB518', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB477', 'https://en.wikipedia.org/wiki/Christopher_Cabaldon']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cabaldon voted Aye on SB-540 (renewable energy portfolio standards expansion, 2025), SB-684 (Polluters Pay Climate Superfund Act of 2025), and SJR-7 (opposing Trump tariffs that disrupt clean energy supply chains). His authored SB-1259 requires oil refineries to file decommissioning and remediation cost plans with the State Water Board, facilitating managed closure of fossil fuel facilities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB540', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1259']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Cabaldon voted Aye on SB-57 (2025), which directs the California PUC to assess whether data center growth shifts infrastructure costs onto residential ratepayers, requiring transparency and impact analysis. As chair of the Privacy/Digital Technologies Committee he authored AI governance frameworks (SB-719, SB-430) requiring impact assessments before government technology deployments. This reflects allowing data center development with impact assessments and cost-sharing requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB57', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://sd03.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Cabaldon voted Aye on SJR-9 (January 2026), a resolution condemning federal mass immigration raids in California. He also voted Aye on SB-1210 (2025-26), which restricts law enforcement from sharing gang database information with federal immigration authorities for deportation purposes. These votes reflect a stance of protecting undocumented residents except in serious violent crime cases, consistent with California sanctuary framework.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1210', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1210']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Cabaldon authored SB-1259 (2025-26) requiring oil refineries to submit decommissioning and remediation cost plans to the State Water Board, facilitating managed closure of California refineries. He voted Aye on SB-540 (renewable energy portfolio standards). His legislative record investing in clean energy and renewable infrastructure is consistent with stopping new fossil fuel permits and planning phase-out of existing operations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1259', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB540']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cabaldon authored three Medi-Cal bills in his first Senate session: SB-278 (improving HIV care quality under Medi-Cal), SB-339 (increasing Medi-Cal reimbursement rates for STI lab testing to maintain providers), and SB-351 (prohibiting private equity from interfering with physician clinical decisions). He voted Aye on SB-62 (essential health benefits) and SB-418 (gender-affirming care coverage mandate). This reflects expanding public healthcare options alongside regulated private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB278', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB351', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB339']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Cabaldon authored SB-417 (Affordable Housing Bond Act of 2026), a 10 billion dollar bond that allocates 1.75 billion for supportive housing with operating subsidies and 500 million for acquiring and rehabilitating housing to prevent displacement. His district office highlighted HHAP (Homelessness Housing, Assistance and Prevention) funding as a district priority. He voted Aye on SB-802 establishing the Sacramento Area Housing and Homelessness Agency.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB417', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802', 'https://sd03.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cabaldon authored SB-417 (10 billion dollar affordable housing bond), SB-772 (infill infrastructure grants for suburban revitalization), and SB-1216 (housing leadership designation incentivizing jurisdictions to meet production targets). He voted Aye on SB-9 (ADU ordinances), SB-802 (Sacramento Housing and Homelessness Agency), and SB-1383 (density bonus). This represents one of the most active housing portfolios in the 2025-26 session focused on expanding affordable housing supply.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB417', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1216', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB772']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cabaldon voted Aye on SJR-9 (condemning mass federal immigration raids, January 2026), SB-323 (extending Dream Act financial aid to undocumented college students), and SB-1210 (restricting law enforcement sharing of gang databases with ICE). No restrictive immigration bill authored. His record reflects support for significantly expanding legal pathways and protections for undocumented immigrants while maintaining a sanctuary framework.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1210']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Cabaldon authored SB-278 (improving HIV care quality under Medi-Cal), SB-339 (increasing Medi-Cal reimbursement rates for STI laboratory tests to maintain provider participation), and SB-351 (restricting private equity interference with clinical decisions). These bills reflect an active effort to expand Medi-Cal quality, access, and coverage, aligned with significantly expanding Medicaid and improving current programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB278', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB339', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB351']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Cabaldon chairs the Senate Privacy, Digital Technologies and Consumer Protection Committee and authored SB-1159 (excluding AI from public records and CEQA to prevent automated abuse of government processes), SB-1104 (CCPA data broker deletion requirements), and SB-1106 (data broker regulations). He voted Aye on SB-243 (companion chatbot safety disclosure) and SB-53 (frontier AI safety reporting). This pattern targets specific harmful practices through safeguards rather than mandating broad algorithmic fact-checking or government content moderation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1159', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1104', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Cabaldon publicly came out as gay in his 2006 State of the City address, the first sitting California mayor to do so. He authored a sweeping 2009 LGBTQ civil rights resolution through the US Conference of Mayors supporting marriage equality, hate crimes legislation, and employment nondiscrimination, and co-published a USA Today column in 2013 framing marriage equality as a question of justice. He chaired the LGBTQ Mayors Alliance (2019). His record unambiguously supports requiring all states to recognize same-sex marriages with full federal protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Christopher_Cabaldon', 'https://sd03.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Cabaldon served as Vice Chancellor of the California Community Colleges and CEO of EdVoice, a public education nonprofit. He voted Aye on SB-494 (2025-26), which extends the prohibition on approving new nonclassroom-based charter schools through January 2027. His universal preschool initiative as West Sacramento mayor and co-founding of the West Sacramento Home Run college pathway reflect a career-defining commitment to fully funding public schools rather than diverting funding to private alternatives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB494', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB494', 'https://en.wikipedia.org/wiki/Christopher_Cabaldon']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Cabaldon voted Aye on SJR-7 (July 2025), a Senate Joint Resolution opposing the Trump administration broad blanket tariff policy. His authored SB-790 supports interstate higher education reciprocity agreements facilitating cross-border educational commerce. This places him at value 3: opposing broad blanket tariffs while supporting selective trade frameworks that protect California agricultural and trade interests rather than advocating for free trade elimination of all tariffs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Christopher Cabaldon / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5c4d4194-a7a1-4efa-80cb-af848e338b8d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Cabaldon voted Aye on SB-418 (2025-26), which mandates health insurance coverage for hormone therapy for gender transition and prohibits discrimination based on gender identity. His decades-long LGBTQ civil rights advocacy including authoring the 2009 LGBTQ mayors resolution and chairing the LGBTQ Mayors Alliance is consistent with allowing transgender athletes to compete on teams matching their gender identity after completing basic transition documentation, aligned with California existing law.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB418', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB418', 'https://en.wikipedia.org/wiki/Christopher_Cabaldon']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cortese has no authored abortion-restriction bills and his legislative record reflects the California Democratic mainstream of protecting legal access through second trimester and beyond. He voted Aye on ACA-5 (2023) and authored SB-999 (2024, mental health and reproductive healthcare parity), consistent with keeping abortion legal and accessible.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999', 'https://en.wikipedia.org/wiki/Dave_Cortese']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Cortese voted Aye on SB-1047 (2024, AI safety testing requirements before deployment) and Aye on SB-53 (2024, AI safety incident reporting). He has not authored AI-specific bills, placing him in the mainstream California position of requiring basic safety testing before companies release new AI systems, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB53']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cortese voted Aye on SB-1027 (2024, Political Reform Act disclosure requirements). No authored campaign finance bills targeting corporate donations or dark money were found in his 2021-2026 legislative record. His stance reflects support for full disclosure of political donations without advancing broader structural reforms, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Cortese voted Aye on SB-1112 (2024, childcare expansion) and authored SB-1341 (2022, SOAR Guaranteed Income Program for homeless pupils) and SB-333 (2023-24, renewed SOAR program for homeless students). His labor-focused legislative portfolio and Santa Clara County working-family constituency support significantly expanding subsidies and provider grants for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1341', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB333']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cortese voted Aye on SB-403 (2023, caste discrimination civil rights protection) and Aye on AB-1955 (2024, protecting gender-affirming support for trans students). His record of authoring labor protections and anti-discrimination measures reflects a consistent stance of strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cortese authored a three-bill building decarbonization package in 2021-22 (SB-30/31/32) prohibiting new state buildings from connecting to the natural gas grid and requiring carbon-neutral state facilities by 2035. He also authored SB-1297 (2022, low-embodied carbon building materials) and voted Aye on SB-867 (2024, climate bond), reflecting rapid transition to renewable energy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB30', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1297', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Cortese authored SB-1298 (2024), which streamlines permitting for data center backup generators up to 150 MW while requiring full air quality mitigation, skilled workforce standards, and community benefit requirements as conditions of approval. This bill allows data center development with impact assessments and cost-sharing agreements before approval, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1298', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240SB1298']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Cortese voted Aye on SB-831 (2023, agricultural worker parole protections) and Aye on SJR-9 (2026, resolution opposing mass immigration raids in California). His district covers Santa Clara County with a large immigrant workforce; no enforcement or pro-deportation bills authored. Consistent with deporting only serious violent offenders and providing legal status to others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Cortese authored SB-30 (2022), which stops new state facilities from connecting to the natural gas grid and requires carbon-neutral state buildings by 2035, halting new state-funded fossil fuel infrastructure. His full decarbonization package (SB-30 through SB-32) and SB-1297 (low-carbon building materials) reflect a stance of stopping new fossil fuel permits in state-funded construction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB30', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220SB30', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1297']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cortese authored SB-999 (2024, health coverage parity for mental health and substance use disorders), voted Aye on SB-729 (2023, IVF coverage mandate), and authored SB-525 (2023, healthcare worker minimum wage increase). His record reflects expanding coverage through regulated private insurance and public program enhancement, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Cortese authored SB-1341 (2022) and SB-333 (2023-24), both versions of the SOAR Guaranteed Income Program for homeless students in California. He voted Aye on SB-657 (2023, homelessness services staff training) and SB-37 (2023, housing stability for older adults). His record reflects expanding shelter capacity and services as a primary homelessness strategy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1341', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB657', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB37']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cortese authored SB-649 (2022, affordable housing local tenant preference), SB-739 (2021, private golf course conversion to housing), SB-406 (2023, CEQA exemption for residential housing), and SB-735 (2023, Bay Area Regional Housing Finance Act). He voted Aye on SB-4 (2023, housing near transit). His prolific housing authorship reflects building affordable units and expanding rental assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB649', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB406', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cortese voted Aye on SB-831 (2023, agricultural worker parole pathways) and SJR-9 (2026, opposing mass immigration raids). His Santa Clara County district has one of the largest immigrant populations in California; his legislative record shows no restriction bills and strong support for legal pathways and immigrant protections, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Cortese voted Aye on SJR-1 (2023, resolution urging Congress to repeal Social Security and Medicare benefit reductions), authored SB-999 (2024, mental health parity in health coverage), and voted Aye on SB-525 (2023, healthcare worker minimum wage). These actions reflect expanding Medicaid coverage and strengthening Medicare benefits while opposing cuts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SJR1', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Cortese voted Aye on SB-976 (2024, social media platform safety for children with algorithmic transparency provisions). No authored misinformation-specific bills were found in his 2021-2026 record. His position reflects supporting modest platform accountability requirements rather than mandating broad government content censorship, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Cortese voted Aye on SB-314 (2023, independent citizens redistricting commissions authored by Ashby). His support for structural redistricting reform is consistent with value 2 - independent redistricting commissions with equal representation from both major parties.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Cortese authored SB-309 (2023), which requires correctional facilities to provide religious accommodations to incarcerated individuals - the bill passed 80-0 in the Assembly and 40-0 in the Senate. This reflects a balanced approach to protecting religious practices while maintaining equal treatment under the law, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB309']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Cortese voted Aye on ACA-5 (2023), a constitutional amendment to remove Proposition 8 from the California Constitution and re-affirm the right to same-sex marriage at the state level. This reflects requiring full legal recognition of same-sex marriages and all associated rights and protections, consistent with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Cortese authored SB-494 (2025-26), extending the moratorium on approving new nonclassroom-based charter schools through 2027 and maintaining strict charter renewal standards requiring verified performance data. This reflects a stance of fully funding public schools and restricting programs that divert taxpayer money away from public institutions, consistent with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB494', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260SB494']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Cortese voted Aye on SJR-1 (2023), a resolution urging Congress to repeal Social Security benefit reductions including the Windfall Elimination Provision and Government Pension Offset. This reflects supporting modest Social Security benefit increases while ensuring program solvency, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SJR1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Cortese voted Aye on SJR-7 (2025), a California resolution opposing the Trump administration broad blanket tariff regime. The resolution opposes indiscriminate tariffs while implicitly supporting targeted trade tools to protect key industries, consistent with value 3 - using tariffs selectively to protect key American industries and jobs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cortese authored SCA-5 (2025-26), the Education Equalization Act to redistribute school funding more equitably across California. His labor-focused portfolio (minimum wage, healthcare worker pay, apprenticeship programs) reflects support for modestly increasing taxes on high earners to fund expanded public services, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB743', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Cortese voted Aye on AB-1955 (2024), which protects students from being compelled to disclose gender identity and prohibits interference with gender-affirming support in schools. His record shows no bills restricting transgender student participation in sports or school activities. This reflects allowing transgender athletes to compete consistent with their gender identity, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dave Cortese / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0dc83f8-f72d-4869-8d79-532002408028', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cortese voted Aye on SB-1174 (2024), which restricts new voter ID requirements and protects mail-in and early voting access. He also voted Aye on SB-1493 (2024, elections access bill). His record reflects expanding early voting periods and making mail-in voting available to all voters without requiring an excuse, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1493']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As a California Assembly Democrat and member of the Legislative Progressive Caucus, Reyes voted Aye on AB 2223 (Reproductive Health Equity Act, 2022) expanding abortion access and affirming no criminal liability for abortion, and Aye on SB 1142 (2022) expanding abortion services coverage. Her record reflects consistent support for legal abortion access through the second trimester and beyond, aligned with California pro-choice framework.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1142']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Reyes authored SB 951 (California Worker Technological Displacement Act, 2025-26) requiring employers to give 60-day advance written notice before AI-driven workforce displacement affecting 25+ workers, disclosing specific AI technology details and retraining opportunities, with civil penalties up to $500/day. She also voted Aye on SB 1047 (Safe and Secure Innovation for Frontier AI Models Act, 2024). Authorship of mandatory AI accountability legislation reflects close monitoring and required disclosure before AI deployment in employment contexts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB951', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$No direct evidence of authored campaign finance legislation was found. As a Progressive Caucus member her public statements focus on constituent service over corporate interests, consistent with mainstream Democratic disclosure and transparency positions rather than a strong structural reform or deregulatory stance. Assigned 3 (require full disclosure of all political donations) as best supported given absence of contrary evidence.$$,
        ARRAY['https://sd29.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Reyes authored SB 271 (Transforming Higher Ed for Student Parents, signed 2025), expanding childcare services and financial aid referrals at all three California public university systems. She also authored SB 1099 (2026) extending public benefits including healthcare to undocumented immigrants, and voted Aye on SB 1112 (2024, UPK expansion). This pattern reflects significant expansion of childcare subsidies and provider support for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB271', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Reyes voted Aye on ACA 5 (2023, unanimous vote to repeal Prop 209 and restore affirmative action) and Aye on SB 403 (2023, caste discrimination protections in civil rights law). As Progressive Caucus Majority Leader her record reflects consistent support for strengthening civil rights enforcement and addressing systemic discrimination, including expansions of anti-discrimination protections to new categories.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Reyes authored SB 352 (Environmental Justice Protection Act, signed Sept 2025), establishing sustained community air monitoring in disadvantaged communities and continuing the Bureau of Environmental Justice. She authored SB 1075 (air pollution mitigation, 2026) and SB 1213 (Clean Truck Price Transparency Act, 2026) expanding zero-emission vehicle incentives. She voted Aye on SB 867 (climate bond, 2024). Her record reflects rapid investment in clean energy and emissions reduction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB352', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1213', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$No authored bill specifically targeting data center development or energy cost allocation was found in Reyes 2025-26 legislative package. Her AI and clean energy bills (SB 951, SB 1213, SB 352) focus on workforce and emissions rather than data center siting or rate impacts. Assigned 3 (impact assessments and cost-sharing before approval) as consistent with her general pro-environment, pro-worker legislative pattern.$$,
        ARRAY['https://sd29.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Reyes authored SB 873 (Kick ICE Out of Courts, 2026) prohibiting civil arrests including by ICE at California courthouses and within a 1,000-foot radius, creating a private right of action for violations and $10,000 in statutory damages per violation. Her district office features Know Your Rights immigration resources in English and Spanish, and she authored SB 1099 (2026) extending public benefits to undocumented residents. This reflects deporting only those with serious violent criminal histories.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB873', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099', 'https://sd29.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Reyes authored SB 1213 (Clean Truck Price Transparency Act, 2026) expanding zero-emission vehicle incentives and requiring transparency from manufacturers in state incentive programs; authored SB 352 (Environmental Justice, signed 2025) focusing on toxic emissions in disadvantaged communities; and SB 1075 (2026) targeting community air pollution. She voted Aye on SB 867 (climate bond). Her record reflects stopping new fossil fuel permits while investing in clean alternatives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1213', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB352', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Reyes authored SB 548 (Overdose Death and Addiction Reduction Act, 2025) setting a goal of 50% reduction in addiction deaths by 2033 and expanding Medi-Cal treatment access; and SB 1099 (2026) extending public healthcare benefits to undocumented residents at the local level. Her record of expanding Medi-Cal and public benefit access reflects support for a public healthcare option alongside private insurance, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB548', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Reyes authored SB 686 (Affordable Housing Financing, signed Sept 2025) expanding debt financing for affordable housing rehabilitation and new development while maintaining HCD regulatory oversight. She voted Aye on SB 684 (2023) and SB 4 (2023) to streamline affordable housing production. Her housing-first orientation reflects significant investment in shelter capacity and permanent affordable housing rather than enforcement-first approaches.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB686', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Reyes authored SB 686 (Affordable Housing Financing, signed 2025) expanding equity extraction and debt financing for affordable housing developments. She voted Aye on SB 4 (housing near transit, 2023), SB 684 (housing streamlining, 2023), and SB 9 (2021, statewide upzoning). Her active authorship of affordable housing financing legislation and support for supply-side reforms reflects building millions of affordable units and expanding rental assistance programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB686', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Reyes authored SB 873 (2026) protecting courthouse access for immigrants including undocumented litigants, witnesses, and crime victims from ICE civil arrests. She authored SB 1099 (2026) affirming local authority to extend public benefits including healthcare to undocumented immigrants. Her district office prominently features multilingual Know Your Rights resources. This record reflects significantly expanded legal protections and pathways consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB873', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099', 'https://sd29.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Reyes authored SB 1099 (2026) extending public benefits including Medi-Cal-equivalent services to undocumented immigrants, and SB 548 (2025) expanding Medi-Cal access for substance use treatment. Authored SB 271 connecting student parents to Medi-Cal and CalWORKs. As a Progressive Caucus member representing high-poverty Inland Empire communities, her record reflects lowering eligibility thresholds and significantly expanding Medicaid coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB548']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Reyes authored SB 930 (Encrypted Info and Student Safety, 2026) addressing online safety for students in digital spaces, and voted Aye on SB 976 (Protecting Our Kids from Social Media Addiction Act, 2024) targeting algorithmic harms to minors. Her approach targets specific online harms to youth without mandating broad government content removal, consistent with encouraging voluntary platform standards for combating misinformation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB930', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Reyes authored SB 1414 (2026) establishing an independent citizens redistricting commission for San Bernardino County with 14 commissioners selected through a merit-based public application process, removing board of supervisors control over supervisorial district boundaries. She voted Aye on SB 314 (2023) establishing independent redistricting commissions statewide. Her record reflects strong support for independent commissions with equal partisan representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1414', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct evidence of authored religious freedom or religious exemption legislation was found. As a progressive Democrat representing a religiously diverse Inland Empire district with a large Catholic Latino community, her baseline position appears consistent with balancing religious practice protections with equal treatment under the law for all citizens. Assigned 3 in the absence of more specific evidence.$$,
        ARRAY['https://sd29.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Reyes voted Aye on ACA 5 (2023, restoring anti-discrimination protections including for LGBTQ+ Californians) and Aye on SB 107 (2022, gender-affirming care protecting trans healthcare access). As a founding member of the California Legislative Progressive Caucus and consistent LGBTQ+ rights supporter, her record aligns with full federal marriage equality protections and benefits for same-sex couples, consistent with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Reyes authored SB 334 (Education Against Harassment Act, 2025) and SB 271 (student parent support at public universities, 2025), both focused on strengthening public education institutions. No voucher-supporting legislation was found in her record. As a Progressive Caucus member with a legislative focus on improving public school and university systems, her record reflects opposition to diverting taxpayer funding to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB334', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB271']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$No direct authored Social Security legislation was found. As a Progressive Caucus member representing high-poverty Inland Empire communities with significant senior populations, Reyes pattern of expanding public benefit access (SB 1099, SB 548, SB 271) and Medi-Cal enrollment is consistent with value 2: modestly increasing Social Security benefits while raising taxes on higher earners. Assigned with low-to-moderate confidence.$$,
        ARRAY['https://sd29.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Reyes was NVR (no vote recorded) on the 2025-26 SJR 7 tariff resolution. No authored tariff or trade legislation was found. Her Inland Empire district includes logistics and warehouse workers sensitive to trade policy, but no strong public stance was identified. Assigned 3 (selective tariffs to protect key American industries and jobs) as the most defensible default for a California Democrat with no contrary evidence.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Reyes legislative record focuses on expanding public programs requiring revenue: SB 548, SB 686, SB 1099, SB 847 (Uninsured Employers Benefits Trust Fund, signed 2025), and PLANS Act (SB 415, signed 2025) expanding financial planning access. As a Progressive Caucus member representing a high-poverty Inland Empire district, her pattern of expanding public services is consistent with modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB847', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Reyes voted Aye on AB 1955 (SAFETY Act, 2024) protecting transgender students privacy from forced disclosure of their gender identity, and Aye on SB 107 (2022) protecting access to gender-affirming care for transgender minors. Her consistent record of supporting trans-inclusive legislation reflects allowing transgender athletes to compete on teams matching their gender identity after completing documentation, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', '24e9212c-b011-422a-865c-093e35050901',
        $$No authored Ukraine-related legislation or direct public statements on Ukraine aid were found. Her district office communications focused on domestic issues. As a California Democratic Progressive Caucus member she aligns with the mainstream Democratic position of continuing military and economic aid to help Ukraine defend itself. Assigned value 2 as consistent with California Democratic caucus but flagged as low-confidence inference.$$,
        ARRAY['https://sd29.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Eloise Gómez Reyes / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1571da4a-b832-4792-917c-184c155b1700', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Reyes authored SB 316 (High School Voter Registration Act, 2025) requiring all California 11th-grade students receive voter registration information and allowing student poll worker programs. She voted Aye on SB 1174 (2024) strengthening provisions requiring free IDs for all eligible voters while opposing restrictive voter ID requirements. Her authorship of youth voter access legislation reflects strong support for expanding voting access consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB316', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Stern voted AYE on SCA 10 (2022) — California's constitutional amendment establishing the fundamental right to abortion and contraceptives (Prop 1) — and AYE on SB 233 (2024) protecting Arizona physicians providing abortion care to California patients. His votes reflect support for broad legal abortion access through the second trimester and beyond, consistent with California mainstream Democratic pro-choice position.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SCA10', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB233']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Stern voted AYE on SB 1047 (2024) — the Safe and Secure Innovation for Frontier Artificial Intelligence Models Act — which requires government safety assessment and third-party audits before advanced AI systems can be commercially deployed. This aligns with value 4: closely monitoring AI development and requiring government approval before releasing advanced AI systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Stern voted AYE on SB 1027 (2024) — a disclosure-only campaign finance transparency bill under the Political Reform Act — which passed 39-0-1. No bills sponsored to ban private campaign money or limit corporate donations were found. His vote reflects support for full disclosure of political donations rather than structural spending limits or public financing.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Stern voted AYE on SB 1112 (2024) which expands childcare alternative payment programs to improve subsidy access for families. His SD-27 district priorities and Senate committee work on budget matters reflect support for expanded childcare subsidies for low- and middle-income families, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Stern voted AYE on SB 403 (2023) extending California civil rights protections to cover caste discrimination and AYE on AB 1078 (2023) protecting diverse and inclusive curriculum in public schools. These votes reflect active support for civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Stern serves as Vice Chair of the Joint Legislative Committee on Climate Change Policies and voted AYE on SB 867 (2024 clean energy bond), SB 253 (2023 Climate Corporate Data Accountability Act), SB 261 (2023 climate-related financial risk disclosure), and SJR 2 (2023 Fossil Fuel Non-Proliferation Treaty resolution). His career background as an environmental attorney and cap-and-invest advocacy reflect rapid transition to clean energy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SJR2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Stern voted AYE on SB 57 (2025-26) requiring electrical corporations to report on data center energy demand impacts including transparency on projected rate impacts for residential ratepayers. This aligns with value 3 — allowing data center development with impact assessments and transparency requirements — rather than imposing a moratorium or offering incentives without review.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Stern voted AYE on SJR 9 (2026) — a resolution opposing mass immigration raids in California and protecting immigrant communities — and AYE on SB 323 (2025) extending Dream Act student aid to undocumented students. These votes reflect a position of deporting only those who commit serious violent crimes while providing protections and pathways for others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Stern voted AYE on SJR 2 (2023) urging a global Fossil Fuel Non-Proliferation Treaty to stop new fossil fuel extraction and AYE on SB 867 (2024) and SB 253 (2023) advancing the clean energy transition. His environmental attorney background and vice chairship on the Joint Committee on Climate Change Policies reinforce a clear stance against new fossil fuel expansion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SJR2', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Stern voted AYE on SB 525 (2023 healthcare workers minimum wage), SB 999 (2024 mental health parity in insurance coverage), and SB 729 (2024 mandating IVF infertility coverage). He does not appear to have authored a single-payer bill. These votes reflect support for expanding regulated coverage alongside private insurance, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$No authored bills specific to homelessness funding were found in Stern's record. His SD-27 page focuses on climate, emergency management, and mental health in the criminal justice system. His committee assignments do not include housing or homelessness committees. Available evidence supports a mainstream position of improving current programs with outreach and shelter while controlling costs.$$,
        ARRAY['https://sd27.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB820']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Stern voted AYE on SB 684 (2023 streamlined small housing approvals), SB 423 (2023 multifamily infill housing streamlining), and SB 92 (2025 housing density bonuses). This pattern across multiple legislative cycles reflects support for building more affordable housing units and expanding housing supply.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB92']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Stern voted AYE on SJR 9 (2026) opposing mass immigration raids and AYE on SB 323 (2025) extending Dream Act aid to undocumented students. These votes reflect support for significantly expanded legal pathways and protections for immigrants currently in the country, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Stern voted AYE on SB 316 (2021 expanded Medi-Cal reimbursements for federally qualified health centers and rural health clinics) and SB 525 (2023 healthcare worker wages tied to Medi-Cal funding). His consistent vote pattern on healthcare expansion bills reflects support for significantly expanding Medicaid coverage and lowering eligibility barriers.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB316', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Stern voted AYE on SB 976 (2024) strengthening online safety and data protections for minors from algorithmic amplification of harmful content and AYE on SB 1027 (2024) expanding political donation disclosure requirements. These votes reflect support for targeted platform standards and transparency requirements without mandating broad government-directed content removal.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Stern voted AYE on SB 314 (2023) which strengthens California's independent redistricting commission process. This vote is consistent with support for independent bipartisan commissions with equal-party representation drawing district maps without elected official interference.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct evidence of Stern authoring or casting a decisive vote specifically on religious freedom or religious exemption legislation was found. His committee assignment (Senate Judiciary) and overall civil-rights-supportive legislative record suggest a balanced position protecting religious practices while maintaining equal treatment under the law for all citizens.$$,
        ARRAY['https://sd27.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Stern voted AYE on ACA 5 (2023) — California constitutional amendment establishing the right to marry as a fundamental right and removing language limiting marriage to opposite-sex couples — which passed the Senate 31-0. He also voted AYE on SCA 10 (2022) establishing reproductive freedom as a constitutional right. This reflects full support for same-sex marriage recognition with federal benefits and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SCA10']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Stern voted AYE on AB 1078 (2023) protecting diverse and inclusive public school curriculum and his voting record shows no support for any school voucher expansion. As a Democrat representing a public-school-heavy Los Angeles County district with a consistent record of supporting public services his record aligns with fully funding public schools and opposing voucher programs that divert taxpayer money.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Social Security is a federal program with no direct California state vote. Stern's consistent pattern of supporting expanded Medi-Cal, healthcare worker wages, and social safety net programs reflects the mainstream California Democratic position of modestly increasing Social Security benefits while raising taxes on higher earners to strengthen the program. Confidence is moderate — inferred from overall safety-net record.$$,
        ARRAY['https://sd27.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Stern voted AYE on SJR 7 (2025-26) urging the federal government to rescind Trump blanket tariffs on imports — citing projected household purchasing-power losses — while not calling for eliminating all tariffs. This positions him as opposing blanket indiscriminate tariffs while being consistent with selective use of trade tools to protect key industries.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Stern voted AYE on SB 525 (2023) raising minimum wages for healthcare workers funded through Medi-Cal and state revenue, effectively requiring public investment funded by progressive taxation. His consistent support for expanded social programs and healthcare coverage reflects a position of modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Stern voted AYE on SB 107 (2022) protecting transgender youth healthcare including gender-affirming care in California and was NVR on AB 1955 (2024). His AYE on SB 107 reflects support for transgender rights and participation in activities consistent with gender identity. No direct trans-athletes legislation was found but his trans-protective voting record aligns with allowing competition on teams matching gender identity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', '24e9212c-b011-422a-865c-093e35050901',
        $$No California state votes directly on Ukraine military aid exist. Stern's voting record consistently supports Democratic foreign policy positions and he chairs emergency management committees signaling awareness of national security issues. California Democratic caucus consensus supports continued aid to Ukraine; no evidence of deviation from Stern. Low confidence stance — inferred from caucus alignment rather than a direct vote.$$,
        ARRAY['https://sd27.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Henry Stern / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Stern voted AYE on SB 314 (2023 strengthening independent redistricting) and his consistent Democratic voting record reflects support for expanded voter access. California Democratic caucus uniformly opposes strict photo ID requirements. His overall voting pattern aligns with expanding early voting and making mail-in voting available to all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McNerney strongly supported abortion access throughout his congressional career and publicly condemned the Supreme Court's Dobbs decision as reflecting a far-right agenda. He consistently backed funding abortion services, emergency contraception access at military facilities, and full reproductive freedom. His record aligns with keeping abortion legal and accessible through the second trimester and beyond, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$McNerney authored SB 813 (2025-26) establishing California's first comprehensive AI safety commission with Independent Verification Organizations to audit and certify AI models before deployment, and SB 833 requiring human oversight of AI in critical infrastructure with incident reporting timelines. He also authored the AI in Government Act (H.R. 2575, 2019) in Congress. This pattern reflects requiring government approval before releasing advanced AI systems, aligning with value 4.$$,
        ARRAY['https://sd05.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB813', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB833']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$McNerney's congressional record reflects opposition to Citizens United-style unlimited corporate money in politics, support for disclosure requirements, and consistent support for limiting dark money and corporate donations throughout his 16-year congressional career. He backed measures to restrict corporate political spending and supported campaign finance reform legislation, consistent with strictly limiting corporate donations and dark money groups.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$McNerney's congressional record reflects broad support for social investments including early childhood programs, and his SD-5 priorities include economic development for working families. His 100% Biden alignment score in the 117th Congress included votes for the American Rescue Plan and Build Back Better expansions of childcare subsidies. No evidence of universal public childcare authorship, placing him at value 2 - significantly expanding subsidies and provider grants for low- and middle-income families.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McNerney co-founded the Congressional Freethought Caucus (2018) to advance policy based on reason and science while opposing discrimination against non-religious persons. His voting record reflects strong support for civil rights enforcement, opposition to discrimination, and support for constitutional amendments protecting women's equality and racial discrimination protections. He consistently backed strengthening civil rights laws, consistent with value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jerry_McNerney', 'https://www.ontheissues.org/CA/Jerry_McNerney.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McNerney spent 20+ years as a wind energy engineer before entering politics and has made clean energy development a career-defining issue. He authored SB 86 (2025, signed into law) extending California's tax incentives for clean energy manufacturing and adding nuclear fusion, and SB 31 expanding recycled water. His congressional record consistently backed CO2 pollution limits and renewable energy tax credits. This reflects rapid transition toward clean energy, consistent with value 2.$$,
        ARRAY['https://sd05.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB86', 'https://www.ontheissues.org/CA/Jerry_McNerney.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$McNerney authored SB 327 (2025, signed into law) protecting utility ratepayers from being charged for corporate lobbying costs, reflecting consumer protection against large energy users passing infrastructure costs to residents. His SB 813 establishes AI safety certification frameworks applicable to data center AI systems. His overall approach to large-scale energy development focuses on cost-sharing and impact assessments, consistent with value 3 - allowing development with impact assessments and community benefit requirements.$$,
        ARRAY['https://sd05.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB327', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB813']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$McNerney's congressional voting record reflects consistent support for immigrant communities, DREAMer protections, and pathways to legal status. His SD-5 Senate office maintains immigration resources. His 100% Biden alignment score included supporting humanitarian immigration approaches. No evidence of support for mass deportation; pattern aligns with deporting only serious violent offenders while providing legal status pathways to others.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://sd05.senate.ca.gov/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McNerney authored SB 237 (2025, signed into law) directing California's Energy Commission to develop strategies for transitioning away from petroleum fuels and convening a working group to coordinate the shift from fossil fuels. He also co-authored SB 614 (carbon capture and removal, signed 2025) and SB 80 (nuclear fusion hubs). His career background as a wind energy engineer and legislative record reflect stopping new fossil fuel expansion, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB237', 'https://sd05.senate.ca.gov/legislation', 'https://www.ontheissues.org/CA/Jerry_McNerney.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McNerney consistently supported expanding the ACA and health insurance coverage throughout his congressional career, opposing privatization and backing government-negotiated prescription drug prices for Medicare. He stated the GOP cannot beat ObamaCare so they pretend it is a disaster (Feb 2015). His record reflects support for a public option and expanding coverage alongside private insurance, with no evidence of supporting single-payer Medicare for All, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$McNerney authored SB 543 (2025, signed into law) streamlining ADU/JADU construction approvals to add affordable housing supply, and SB 1196 (2025) accelerating utility hookups for ADUs. These supply-side interventions reflect a housing-first infrastructure approach. His SD-5 priorities include housing affordability and development. The approach emphasizes building shelter capacity through housing supply expansion, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB543', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1196', 'https://sd05.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McNerney authored SB 543 (2025, signed into law) streamlining ADU/JADU approvals and banning impact fees on small units, and SB 1196 (2025) requiring utilities to fast-track service connections for ADUs. These are structural supply-expansion bills removing regulatory barriers to affordable housing construction. His SD-5 priorities explicitly include housing affordability. The focus on building new affordable units through deregulation and infrastructure investment aligns with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB543', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1196', 'https://sd05.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McNerney's congressional record reflects support for significantly expanding legal immigration pathways, including DREAMer legalization, increased visa caps for high-skill and family-based categories, and pathways to citizenship. His OnTheIssues profile documents his position that the US needs a federal immigration policy supporting legal access. His SD-5 office maintains immigration resources for constituents. Consistent with significantly increasing legal immigration limits and creating easy pathways to citizenship.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://sd05.senate.ca.gov/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$McNerney voted to require government-negotiated prescription drug prices for Medicare and opposed the Ryan Budget's proposals to partially privatize the program. He consistently voted to expand Medicaid and was rated 96% by the American Retirees Association for protecting retirement program trust funds. His record reflects significant Medicaid expansion and strengthening Medicare while maintaining the programs' public structure, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$McNerney's record reflects support for internet regulation (Save the Internet Act/net neutrality), opposition to warrantless data sharing (voted NO on CISPA), and support for government cybercrime enforcement. His SB 813 (AI safety standards) includes provisions addressing malign persuasion as an AI risk. No evidence of legislation mandating platform removal of false content. Pattern reflects encouraging voluntary standards and targeted cybercrime enforcement, consistent with value 3.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB813']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McNerney's congressional record reflects support for independent redistricting reforms and anti-gerrymandering legislation. His 100% Biden alignment score and progressive voting record included support for the For the People Act (H.R. 1) in the 117th Congress, which contained independent redistricting commission requirements. Consistent Democratic caucus support for independent commissions with equal representation from both major parties aligns with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$McNerney co-founded the Congressional Freethought Caucus (2018) to promote evidence-based policy and oppose discrimination against non-religious persons, while also advocating tolerance across beliefs. His Freethought Caucus work reflects balancing secular governance with protecting individual religious practices - neither a strict separationist nor a strong exemptions supporter. No evidence of authoring bills imposing or restricting religious exemptions. Consistent with value 3.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jerry_McNerney', 'https://www.ontheissues.org/CA/Jerry_McNerney.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$McNerney's voting record includes support for repealing Don't Ask Don't Tell, employment non-discrimination protections for LGBTQ persons, and prohibiting sexual-identity discrimination. As a California Democrat, he voted for the Respect for Marriage Act (2022) codifying same-sex marriage nationwide with full federal benefits and protections. His consistent record of supporting LGBTQ equality and federal protections aligns with value 1.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '00b95a6a-75db-4521-b523-3326bba938de',
        $$McNerney consistently opposed school vouchers and private school subsidies throughout his 16-year congressional career, explicitly supporting public school funding and opposing diversion of taxpayer money to private institutions. His OnTheIssues record documents direct opposition to school vouchers and support for fully funding public schools. Consistent with value 1.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$McNerney was rated 96% by the American Retirees Association for protecting Social Security trust funds and strongly opposed privatization into private investment accounts. He voted against proposals converting Social Security to personal accounts and supported modest benefit expansions while opposing structural cuts. His record reflects increasing benefits modestly while raising taxes on higher earners to strengthen the program, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '683c8084-2281-4920-a07c-18439b2dd413',
        $$McNerney's congressional record shows mixed trade positions - he generally opposed multilateral free trade agreements (NAFTA, CAFTA, GATT) but voted for USMCA implementation. His OnTheIssues profile notes support for tariffs against currency manipulators (targeted use) but not broad protectionism. This reflects selective use of tariffs to protect key American industries and jobs rather than either free trade or across-the-board high tariffs, consistent with value 3.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McNerney consistently opposed estate tax repeal, opposed making Bush-era tax cuts permanent for top earners, favored closing offshore business loopholes, and supported higher taxes on wealthy individuals to fund programs. His voting record reflected opposition to regressive tax cuts and support for progressive tax increases on high earners while maintaining current rates for middle-class families, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$McNerney's congressional record includes consistent support for LGBTQ non-discrimination protections, including prohibiting sexual-identity discrimination in schools and repealing Don't Ask Don't Tell. His California Democratic caucus record reflects support for allowing transgender athletes to compete consistent with their gender identity after basic documentation of transition, with no evidence of support for restrictions or bans. Consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', '24e9212c-b011-422a-865c-093e35050901',
        $$McNerney voted with President Biden's stated position 100% of the time during the 117th Congress (2021-2023), which included voting for Ukraine military and economic aid packages. As a member of the Democratic caucus, he supported continued assistance to Ukraine to help the country defend itself against Russian aggression. Consistent with value 2.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jerry_McNerney', 'https://www.ontheissues.org/CA/Jerry_McNerney.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jerry McNerney / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0267f457-cd3f-4790-b0c8-76ec616de3f0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McNerney strongly advocated for voting access throughout his congressional career, supporting automatic voter registration, early voting expansion, and opposing strict voter ID requirements as suppressive. His voting record included support for the For the People Act and John Lewis Voting Rights Advancement Act. His record reflects expanding early voting and making mail-in voting available to all voters without requiring an excuse, consistent with value 2.$$,
        ARRAY['https://www.ontheissues.org/CA/Jerry_McNerney.htm', 'https://en.wikipedia.org/wiki/Jerry_McNerney']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Arreguín received a Planned Parenthood endorsement in his 2016 Berkeley mayoral race and maintained pro-choice policies throughout. As a CA Senate Democrat representing Berkeley/Oakland, he is consistent with the CA Dem caucus position of keeping abortion legal and accessible through the second trimester and beyond. No restrictive abortion bills authored or supported.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Arreguin', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Arreguín voted YES on SB 53 (2025, AI-generated deepfakes), YES on SB 813 (2025, CA AI Standards and Safety Commission), and YES on SB 243 (2025, companion chatbots regulation). As Chair of the Public Safety Committee he oversees AI safety legislation. This pattern supports requiring basic safety testing before AI systems are deployed, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Arreguín voted YES on SB 477 (2025, strengthening FEHA enforcement), YES on SB 352 (environmental justice air monitoring), and YES on SB 277 (criminal procedure reform limiting warrantless searches). As Berkeley mayor he championed civil rights including sanctuary city status and reaffirmed protections for undocumented residents. This reflects strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB477', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB352', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB277']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Arreguín voted YES on SB 684 (Polluters Pay Climate Superfund Act of 2025), YES on SB 540 (California Renewables Portfolio Standard expansion), and YES on SB 352 (environmental justice air monitoring). As Berkeley mayor he pledged to uphold Paris Agreement goals after U.S. withdrawal in 2017. This record reflects commitment to rapidly transitioning to renewable energy and phasing out fossil fuels.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB540', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB352']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4559b513-0fd8-4ed1-babd-f3b554162f40', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Arreguín voted YES on SB 57 (2025), which requires electrical corporations to report on data center energy demand and grid impacts. He sits on the Senate Energy, Utilities and Communications Committee. Supporting energy-demand transparency reporting rather than blocking development aligns with value 4: encouraging data center development while requiring transparency about projected energy demand and rate impacts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Arreguín voted YES on SJR 9 (2025) condemning mass immigration raids in California and opposing federal mass deportation operations. As Berkeley mayor he reaffirmed sanctuary city status and backed divestment from border wall construction companies. His senate office maintains dedicated immigration rights resources. This reflects deporting only serious violent offenders while protecting long-term undocumented residents.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://en.wikipedia.org/wiki/Jesse_Arreguin', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Arreguín voted YES on SB 684 (Polluters Pay Climate Superfund Act), YES on SB 540 (Renewables Portfolio Standard expansion), and YES on SB 352 (environmental justice air monitoring). He supports the Golden Gate Fields waterfront park conversion away from industrial land use. This record supports stopping new fossil fuel permits in favor of clean energy development.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB540', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Arreguín voted YES on SB 62 (2025, health care essential benefits coverage), YES on SB 418 (prescription hormone therapy and nondiscrimination coverage), and chairs the Senate Human Services Committee. His consistent support for expanding health coverage through essential benefit mandates aligns with value 2: offering a public option alongside private insurance plans.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB62', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB418', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Arreguín chairs the Senate Housing Committee and voted YES on SB 802 (2025, Sacramento Area Housing and Homelessness Agency/Homekey/Homeless Housing Assistance and Prevention). His district page highlights funding affordable housing as a top priority. He backed 125 homeless housing units at Berkeley People's Park as mayor. This reflects a primary strategy of expanding shelter capacity and housing programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802', 'https://sd07.senate.ca.gov', 'https://en.wikipedia.org/wiki/Jesse_Arreguin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Arreguín chairs the Senate Housing Committee and authored SB 9 (2025), enforcing ADU ordinance compliance and requiring local governments to allow more accessory dwelling units. He voted YES on SB 802 (Homekey/homeless housing) and backed 1100 student housing units and 125 homeless units at People's Park as mayor. This reflects building millions of affordable housing units and expanding housing assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802', 'https://en.wikipedia.org/wiki/Jesse_Arreguin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Arreguín voted YES on SJR 9 (2025) condemning mass immigration raids. As Berkeley mayor he vowed the city would remain a sanctuary city and backed divestment from border wall companies. His senate office features dedicated immigration rights resources. This reflects support for significantly expanding legal immigration pathways and creating easier pathways to citizenship for existing undocumented residents.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://en.wikipedia.org/wiki/Jesse_Arreguin', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Arreguín voted YES on SB 62 (2025, health care essential benefits) and SB 418 (hormone therapy/nondiscrimination coverage), and chairs the Senate Human Services Committee overseeing Medi-Cal programs. His consistent support for expanding health coverage through essential benefit mandates and public programs aligns with lowering Medicare age and significantly expanding Medicaid coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB62', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB418', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Arreguín voted YES on SB 53 (deepfakes/AI-generated content), YES on SB 243 (companion chatbots), and YES on SB 813 (CA AI Standards Commission). These votes target specific categories of AI-driven harmful content rather than mandating comprehensive platform fact-checking. This reflects support for targeted regulation and voluntary standards rather than broad government mandates on content moderation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Arreguín voted YES on SB 1414 (2026), establishing a Citizens Redistricting Commission for San Bernardino County to replace partisan legislative line-drawing. His support for independent redistricting reflects a preference for independent commissions with equal representation from major parties.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1414', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Arreguín voted YES on SB 494 (2025), prohibiting new charter school establishment and restricting renewal procedures — a strong signal favoring public school funding over privatization. As Berkeley mayor he consistently supported Berkeley public schools. This reflects fully funding public schools and opposing voucher programs that divert taxpayer money to private or charter institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB494', 'https://en.wikipedia.org/wiki/Jesse_Arreguin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Arreguín voted YES on SJR 7 (2025), a California Senate resolution opposing the Trump administration's broad tariff policy and calling for selective rather than blanket tariff application. This positions him as supporting selective tariffs to protect key industries and jobs while opposing across-the-board high tariffs, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Arreguín voted YES on SB 418 (2025), prohibiting health coverage discrimination based on gender identity and mandating coverage of prescription hormone therapy — a strong signal of support for transgender rights and inclusion. His Berkeley progressive record includes consistent LGBTQ-inclusive policies. This reflects support for allowing trans athletes to compete on teams matching their gender identity after basic documentation of transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB418', 'https://en.wikipedia.org/wiki/Jesse_Arreguin', 'https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jesse Arreguín / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Arreguín voted YES on SB 316 (2025), expanding voter registration for high school students to make registration more accessible. As Berkeley mayor he supported broad civic participation. This reflects expanding early voting periods and making voter registration accessible to all eligible citizens without restrictive ID requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB316', 'https://en.wikipedia.org/wiki/Jesse_Arreguin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Laird chaired the California Legislative LGBT Caucus and has a long record of supporting reproductive and social rights. He voted AYE on AB 1955 (SAFETY Act 2024) protecting transgender students and is part of the California Democratic caucus that passed ACA 5 (marriage equality) 31-0 in the Senate. No abortion-restricting bills authored or supported; consistent with California mainstream pro-choice Democratic position of keeping abortion legal and accessible through second trimester and beyond.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Laird voted AYE on SB 1047 (2023-24 major AI oversight bill), AYE on SB 53 (2025-26 AI models large-developer oversight signed Oct 2025), AYE on SB 813 (2025-26 AI Standards and Safety Commission), and AYE on SB 719 (2025-26 requiring state agencies to inventory high-risk automated decision systems). This pattern of supporting multiple close-government-oversight AI bills reflects value 4: closely monitoring AI development and requiring government approval before releasing advanced AI systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB719']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Laird voted AYE on SB 1027 (2024) a Political Reform Act disclosure bill requiring greater transparency in political spending. No bills found banning private money or strictly limiting corporate donations in his authored legislation. His record aligns with value 3: requiring full disclosure of all political donations without seeking to ban or dramatically restrict private campaign contributions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Laird voted AYE on SB 1112 (2024) which expanded childcare alternative payment programs to increase access for low- and middle-income families. His broader legislative record investing in social services and public education funding is consistent with significantly expanding subsidies and provider grants to make childcare more affordable placing him at value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Laird voted AYE on SB 403 (2023) to add caste/ancestry to California anti-discrimination protections and AYE on SB 16 (2024) strengthening civil rights enforcement. He chaired the California Legislative LGBT Caucus and founded the International Network of Gay and Lesbian Officials demonstrating a career-long commitment to expanding civil rights protections and addressing systemic discrimination consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB16', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Laird served as California Natural Resources Agency Secretary (2011-2019) under Governor Brown worked to secure Monterey Bay National Marine Sanctuary designation and authored SB 283 (Clean Energy Safety Act of 2025). He voted AYE on SB 253 (Climate Corporate Data Accountability Act 2023) and SB 867 (Clean Air and Drought Bond 2024). His record reflects rapidly investing in clean energy and phasing out fossil fuel reliance consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202520260SB283']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Laird voted AYE on SB 57 (2025-26) which requires electrical corporations to report on data center energy demand and ratepayer cost impacts. This is a transparency and impact assessment measure short of blocking development or requiring dedicated power generation aligning with value 3: allowing data center development with impact assessments and community benefit requirements before approval.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Laird voted AYE on SJR 9 (Jan 2026) condemning mass immigration raids in California and AYE on SB 831 (2023) creating a parole pathway for agricultural workers. His overall legislative record consistently supports immigrant communities and opposes aggressive deportation aligning with value 2: deporting only serious violent criminals while providing legal status pathways for others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As California Natural Resources Agency Secretary (2011-2019) Laird opposed offshore oil drilling and secured marine sanctuary protections. He authored SB 931 (2026) supporting communities affected by Diablo Canyon nuclear operations and SB 283 (Clean Energy Safety Act of 2025). He voted AYE on SB 867 (clean energy bond 2024). His record supports stopping new fossil fuel expansion while investing in alternatives consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB931', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Laird voted AYE on SB 525 (2023 healthcare worker minimum wage) SB 999 (2024 mental health and substance use disorder parity) SB 729 (2024 infertility coverage) and SB 873 (2023 prescription drug cost sharing). These votes demonstrate consistent support for expanding healthcare coverage and reducing costs through regulated private markets and program expansions consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Laird voted AYE on SB 37 (2024 Older Adults and Adults with Disabilities Housing Stability Act) and AYE on SB 657 (2023 requiring homelessness services staff training). His record of supporting housing stability programs and shelter investments reflects value 2: expanding shelter capacity and services as a primary homelessness strategy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB37', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB657']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Laird voted AYE on SB 4 (2023 housing on religious/educational lands) SB 684 (2023 streamlined approval for small housing on urban lots) SB 9 (2021 duplex by-right) and ACA 1 (2023 local affordable housing financing). This consistent record of supporting housing production reforms and affordable housing financing aligns with value 2: building affordable housing units and expanding housing access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Laird voted AYE on SJR 9 (Jan 2026) opposing mass immigration raids in California and AYE on SB 831 (2023 agricultural worker immigration parole). His broader legislative support for immigrant communities combined with no evidence of supporting restrictive immigration measures places him at value 2: significantly supporting immigrants with pathways to legal status.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Laird voted AYE on SB 525 (2023 healthcare worker minimum wage expanding Medi-Cal provider capacity) SB 999 (2024 mental health parity under Medi-Cal) and SB 1339 (2024 step-down care transition programs). His consistent support for expanding healthcare programs through Medi-Cal aligns with value 2: lowering the Medicare eligibility age and significantly expanding Medicaid.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB999', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1339']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Laird voted AYE on SB 976 (2024 Protecting Our Kids from Social Media Addiction Act) which mandates transparency in how algorithms promote content and restricts addictive content delivery to minors. This vote reflects support for requiring platforms to implement algorithmic transparency and content protection requirements placing him at value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Laird voted AYE on SB 314 (2023 Sacramento County independent redistricting commission) and AYE on AB 1248 (2023 Local Redistricting: Independent Redistricting Commissions for local agencies). These votes support moving redistricting authority to independent commissions with equal bipartisan representation consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Laird voted AYE on SB 309 (2023) requiring state correctional facilities to make reasonable religious accommodations for incarcerated individuals. His overall record balancing LGBTQ rights with religious expression reflects value 3: balancing protection of religious practices with equal treatment under the law for all citizens.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB309']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Laird voted AYE on ACA 5 (2023 California marriage equality constitutional amendment) which passed the Senate 31-0. He chaired the California Legislative LGBT Caucus and founded the International Network of Gay and Lesbian Officials. His record is fully consistent with value 1: requiring all states to recognize same-sex marriages and provide full federal benefits and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Laird voted AYE on SB 494 (2023) which strengthened public school district governance and accountability. His career Wikipedia record confirms advocacy for expanding public education access. His record as a California progressive Democrat is fully consistent with value 1: fully funding public schools and opposing voucher programs that divert taxpayer money to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Laird voted AYE on SJR 7 (July 2025) California resolution opposing blanket federal tariffs and calling for targeted trade policy. This reflects value 3: using tariffs selectively to protect key American industries and jobs rather than eliminating all tariffs or imposing high tariffs on all imports.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Laird's legislative record consistently supports expanding public programs funded through progressive taxation including healthcare worker wages housing subsidies childcare and homelessness services. He voted AYE on SB 167 (2024 a Revenue and Taxation Code adjustment bill). His career affiliation with the California progressive Democratic caucus reflects a consistent position of modestly increasing taxes on high earners to fund expanded social programs consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB167', 'https://en.wikipedia.org/wiki/John_Laird_(California_politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Laird voted AYE on AB 1955 (SAFETY Act 2024) prohibiting schools from outing transgender students and requiring respect for students gender identity and AYE on SB 107 (2021-22) providing gender-affirming healthcare protections for transgender individuals. These votes reflect consistent support for transgender rights including participating in activities matching gender identity consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Laird / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('178a41d4-42b5-4ffd-be06-d1059d54eacb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Laird voted AYE on SB 1174 (2024 protecting voting access against burdensome ID requirements) AYE on SB 518 (2023 election certification procedures) and AYE on SB 1027 (2024 Political Reform Act disclosure). His record reflects support for expanding voting access and opposing restrictive voter ID requirements consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB518']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Becker authored SB 570 (2023, protecting prenatal genetic screening access) and SB 771 (2021, noninvasive prenatal testing access protections), and voted Aye on SB 487 (2023, abortion provider protections). His legislative record consistently supports reproductive healthcare access with no evidence of any restrictions, aligning with keeping abortion legal and accessible through the second trimester and beyond.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB570', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB487', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB771']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Becker authored SB 942 (2024, AI-generated content disclosure, chaptered), SB 468 (2025, duty to protect personal data in high-risk AI), and SB 1000 (2026, California AI Transparency Act). He voted Aye on SB 53 (2025, AI large developer requirements) and SB 243 (2025). His pattern favors mandatory disclosure and basic safety testing before deployment rather than a government pre-approval regime.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB942', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1000', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Becker voted Aye on SB 1027 (2024, disclosure requirements for political contributions). His authored bills address data privacy and transparency broadly but no bills directly limiting corporate donations or establishing public campaign financing were found. This pattern reflects support for disclosure and transparency standards without strong structural reform advocacy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB362']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Becker authored SB 1307 (2024, childcare worker enrollment priority and eligibility), SB 1481 (2022, childcare free meal program expansion), and SB 1110 (2025, early learning and care reimbursement rates reform). He voted Aye on SB 1112 (2024, statewide childcare expansion). This legislative record consistently supports significantly expanding subsidies and provider support for working and low-to-middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1307', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1110', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Becker voted Aye on ACA 5 (2023, constitutional amendment protecting same-sex marriage), AB 1955 (2024, Support Academic Futures and Educators Act protecting transgender students), and SB 107 (2022, transgender youth healthcare). His consistent votes for anti-discrimination and civil rights legislation reflect support for strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Becker authored SB 1203 (2022, state agencies net-zero emissions by 2035, chaptered), SB 67 (2021, 24/7 renewable energy standard), SB 596 (2021, cement net-zero strategy), and SB 285 (2025, restricting carbon removal for offset gaming). He voted Aye on SB 867 (2023, climate bond), SB 253 (2023, corporate climate disclosure), and SB 261 (2023, climate risk disclosure). His record demonstrates a commitment to rapidly transitioning to clean energy while phasing out fossil fuel reliance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1203', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Becker voted Aye on SB 57 (2025, requiring electrical corporations to report projected energy demand from data centers with ratepayer impact analysis). He authored SB 540 (2025, ISO regional participation in voluntary energy markets) and SB 1000 (2026, California AI Transparency Act). This record reflects allowing development with impact assessments and energy cost-sharing transparency rather than moratoriums or unconstrained incentives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB540', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1000']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Becker voted Aye on SJR 9 (January 2026, condemning mass immigration raids in California communities, 29-10 Senate vote). This resolution explicitly rejects ICE mass operations and asserts protection for immigrant residents. His vote reflects a clear policy position of limiting deportation to serious violent offenders while protecting long-term community members.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Becker authored a sustained body of decarbonization legislation: SB 48 (2023, building efficiency, chaptered), SB 49 (2023, solar on highway rights-of-way, chaptered), SB 1112 (2022, on-bill building decarbonization programs, chaptered), SB 596 (2021, cement net-zero), SB 1203 (2022, state agency net-zero by 2035). His record consistently targets phasing out fossil fuel use in state operations and infrastructure without calling for an immediate blanket ban on new drilling permits.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1203', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1112', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB48']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Becker authored SB 306 (2025, requiring insurers to end prior authorizations for services approved at 90-plus percent rates), SB 338 (2025, Virtual Health Hub rural Medi-Cal pilot, chaptered), and SB 784 (2023, public hospital physician hiring). He voted Aye on SB 729 (2024, mandating insurance coverage for infertility treatment). His record reflects expanding regulated access through a mix of public programs and private insurance mandates rather than full single-payer or pure market approaches.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB306', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB338', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Becker authored SB 606 (2025, Functional Zero Unsheltered Act requiring detailed housing needs assessments for HHAP applicants), SB 1395 (2024, extending shelter crisis exemptions through 2036, chaptered), and SB 634 (2023, navigation centers use-by-right). His legislation emphasizes building shelter capacity, service funding, and measurable progress toward housing all unsheltered residents consistent with investing in shelter and voluntary service connections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB606', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1395', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1395']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Becker authored SB 341 (2023, expanding state affordable housing funding access, chaptered), SB 358 (2025, reducing traffic mitigation fees by at least 50 percent to spur housing production, chaptered), and SB 948 (2022, pooled reserve model for affordable housing). He voted Aye on SB 4 (2023, affordable housing on religious/nonprofit land), SB 684 (2023, streamlined affordable housing), and SB 477 (2024, ADU expansion). His record reflects building millions of affordable units and strongly expanding housing supply.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB341', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB358', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Becker voted Aye on SJR 9 (January 2026, condemning mass immigration raids and defending immigrant communities, 29-10 Senate vote). His authored bills include no restrictive immigration measures. His position aligns with protecting current undocumented residents from deportation except for serious violent offenders and supporting legal pathways to status.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Becker authored SB 338 (2025, Virtual Health Hub expanding Medi-Cal access in rural areas, chaptered) and SB 784 (2023, enabling public hospital physician hiring to expand Medicaid-covered services). He voted Aye on SB 729 (2024, IVF insurance coverage mandate) and consistently supports Medi-Cal expansion legislation. His record reflects expanding Medicaid significantly and lowering barriers to coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB338', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB784']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Becker authored SB 942 (2024, requiring generative AI providers to disclose AI-generated content, chaptered) and SB 1000 (2026, California AI Transparency Act). He voted Aye on SB 976 (2024, Protecting Our Kids from Social Media Addiction Act). His approach focuses on mandatory disclosure and labeling standards rather than requiring removal of false content or mandating algorithm redesign, consistent with encouraging transparency with targeted mandatory standards.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB942', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1000']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Becker voted Aye on SB 314 (2023, establishing independent citizens redistricting commissions with equal bipartisan representation), which passed the Senate 31-7. His support for citizen-driven redistricting reflects a consistent position that fair district drawing should be handled by independent commissions without elected official interference.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Becker voted Aye on ACA 5 (2023, constitutional amendment to protect same-sex marriage rights in California), which passed the Senate 31-0. His consistent support for full LGBTQ+ civil rights legislation reflects strong advocacy for requiring all jurisdictions to recognize same-sex marriages with full legal protections and federal benefits.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Becker authored SB 767 (2021, Digital Equity Program for school districts expanding public school technology access, chaptered) and SB 876 (2022, educational technology assistance and teacher development). His legislative focus is exclusively on strengthening public school resources with no authored or co-authored voucher bills found. This record reflects strong commitment to fully funding public schools and opposing diversion of taxpayer money to private institutions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB767', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB876']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Becker authored SB 1301 (2022, clean energy manufacturing tax credit), SB 935 (2024, 20 percent housing tax credit for school staff housing), and SB 993 (2024, discounted electricity rates for clean energy industry). He has not authored flat tax or broad rate-cut bills, and his expansive social and infrastructure program bills reflect support for adequate public revenue. His record aligns with modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1301', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB935', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB993']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Becker voted Aye on AB 1955 (2024, Support Academic Futures and Educators Act protecting transgender youth in schools including gender identity protections) and SB 107 (2022, transgender youth healthcare refuge bill). His consistent support for transgender rights legislation reflects support for allowing transgender athletes to compete consistent with their gender identity after completing transition documentation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Josh Becker / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('64eda290-d172-48de-8827-6ebca668cf5a', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Becker authored SB 503 (2021, ballot signature verification improvements, chaptered) and SB 504 (2021, military and overseas voter registration clarifications, chaptered). He voted Aye on SB 1174 (2024, protecting mail-in voting access and opposing strict voter ID mandates). His record reflects expanding early voting and mail-in voting access for all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB503', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB504', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Seyarto voted No on AB 2223 (2022, reproductive health/abortion access) and No on SB 1142 (2022, abortion services/out-of-state travel funding), both as an Assembly member. His consistent opposition to pro-choice legislation aligns with the most restrictive end of the scale, reflecting a position that abortion should be banned or severely restricted.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1142']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Seyarto voted No on SB 867 (2024, climate bond/clean energy investment) and No on SB 253 (2023, Climate Corporate Data Accountability Act requiring greenhouse gas reporting), and No on SB 1391 (2022, greenhouse gas market-based compliance). This consistent opposition to climate legislation aligns with rejecting climate change policies and focusing on economic growth.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1391']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'a22215c3-6693-4bc2-b248-01aebba14570', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Seyarto voted No on SB 867 (2024, climate bond opposing fossil fuel reduction) and No on SB 1221 (2024, Gas Corporations ceasing service / decarbonization zones), opposing restrictions on fossil fuel infrastructure. His pattern of opposition to climate and clean energy legislation indicates support for maintaining or expanding fossil fuel use rather than restricting it.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1221']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Seyarto voted No on SB 525 (2023, healthcare worker minimum wage), No on SB 729 (2024, IVF insurance coverage mandate), and No on SB 873 (2023, prescription drug cost sharing reduction). This consistent opposition to healthcare access expansions and cost controls indicates a strong preference for leaving healthcare to private markets.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB873']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Seyarto voted No on SB 4 (2023, affordable housing near religious/nonprofit land), No on SB 9 (2021, statewide duplexes), and No on SB 10 (2021, zoning upzoning for density). He consistently opposed state-mandated housing density and affordable housing production bills, reflecting a view that housing supply should be driven by local control and market forces rather than state mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB10']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Seyarto voted No on SB 831 (2023, agricultural workers immigration parole protections), indicating opposition to creating pathways for undocumented immigrants to obtain legal status. As a Republican from Riverside County, his record reflects a reduce-legal-immigration and enforcement-first posture consistent with a value-4 stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '44905f3b-e105-4f6c-afc7-5d223813dbac', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Seyarto voted No on SB 831 (2023, protections for undocumented agricultural workers from deportation/immigration enforcement). His overall Republican positioning in Riverside County and opposition to immigrant-protective legislation indicates support for deporting people without legal status with criminal history prioritized, aligning with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Seyarto voted No on SB 976 (2024, Protecting Our Kids from Social Media Addiction Act, which required platforms to restrict algorithmic content to minors and conduct age verification). His opposition to government-mandated content moderation and algorithm regulation aligns with protecting free speech online and preventing government censorship.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '48cc9585-ec22-4f53-8d42-6839828dd36f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Seyarto voted No on SB 314 (2023, independent redistricting commissions for local governments) in both the Governance and Finance Committee and Senate Appropriations. His opposition to independent redistricting bodies indicates a preference for state legislatures retaining redistricting control with court oversight rather than independent commissions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Seyarto recorded NVR (No Vote Recorded) on ACA 5 (2023, constitutional amendment affirming same-sex marriage rights), declining to vote in favor of equal marriage protections. While he did not vote to ban same-sex marriage, his refusal to support ACA 5 alongside a Republican voting record suggests a position closer to reserving marriage for opposite-sex couples or supporting civil unions only.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Seyarto is a Republican state senator who has consistently voted against bills increasing government spending and has not supported progressive tax increases. He voted against SB 525 (healthcare worker minimum wage increase) and other spending expansion bills. His party affiliation and overall voting record reflect support for reducing tax rates across income levels.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Seyarto voted No on SB 107 (2023, gender-affirming care protections for transgender individuals) and No on AB 1955 (2024, school notification/transgender student support). His consistent opposition to transgender-protective legislation indicates support for banning or severely restricting transgender participation in alignment with biological sex categories.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Seyarto voted No on SB 1174 (2024, anti-voter ID / standardization of registration) and No on SB 386 (2023, election procedures/signature verification extension). His opposition to voter access expansion measures indicates a preference for stricter voting requirements including photo ID and maintenance of voter rolls.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB386']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kelly Seyarto / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4fccbf85-d794-4cdc-a8b8-674ff1b48784', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Seyarto voted No on SJR 7 (2025-26, California Senate resolution opposing President Trump's tariffs on imported goods), which passed 26-9. His opposition to the anti-tariff resolution signals at minimum a more protectionist or at least non-interventionist stance on federal tariff policy, placing him closer to the middle of the scale rather than free trade.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Richardson's congressional record shows she voted against banning federal healthcare coverage that includes abortion and supported allowing military facilities to perform abortions in cases of rape or incest (OTI). Her consistent pro-choice voting pattern in Congress aligns with keeping abortion legal and accessible, without a record of funding all abortions at public expense.$$,
        ARRAY['https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Richardson voted YES on SB 53 (2025, AI incident reporting and oversight), SB 813 (AI Standards and Safety Commission), and SB 719 (inventory of high-risk automated decision systems in government). This pattern — supporting safety testing and safety commissions — aligns with requiring basic safety testing before deployment rather than heavy pre-approval requirements or a laissez-faire approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB719']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Richardson's OTI profile shows a 0% rating from CEI (pro-business group) and strong labor alignment; her congressional record reflects support for campaign finance restrictions and worker protections over corporate influence. No specific 2025-26 campaign finance bill authored or voted on was found, but her consistent progressive-populist record in Congress supports stricter limits on corporate donations and dark money.$$,
        ARRAY['https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Richardson authored SB 530 (2025) expanding Medi-Cal managed care access standards and SB 535 (obesity prevention) as part of a health equity-focused legislative package. Her SD35 legislation page lists priorities around healthcare equity and serving low-income constituents in Compton and Carson. Her broader legislative profile — Medi-Cal expansion and housing affordability bills — is consistent with significantly expanding subsidies for low- and middle-income families.$$,
        ARRAY['https://sd35.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Richardson authored SB 510 (2025) requiring California's Instructional Quality Commission to include African American contributions and encounters with discriminatory laws in the state history-social science curriculum. She voted YES on SB 477 (2025, strengthening FEHA enforcement procedures) and is a member of the California Legislative Black Caucus. This record reflects strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB510', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB477', 'https://sd35.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Richardson authored SB 34 (2025) on port emissions oversight with explicit protections against cargo throughput caps, balancing environmental goals with economic activity. She voted YES on SB 1259 (refinery decommission cost estimates) and authored SB 752 (extending ZEV transit bus tax exemption). This pattern reflects investing in clean energy and managed transitions while preserving existing economic structures rather than rapid phase-out.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB34', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1259', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB752']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Richardson voted YES on SB 57 (2025, data centers energy cost transparency and ratepayer protections), which requires impact assessments of data center energy demand on residential ratepayers. This vote reflects allowing data center development while requiring transparency and community impact review before approval — consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Richardson voted YES on SJR 9 (2025, California resolution opposing mass immigration raids) and voted YES on SB 323 (Dream Act financial aid for undocumented students). Her congressional record shows opposition to border fence construction and support for citizenship paths for undocumented immigrants. This consistent record supports deporting only serious violent offenders while providing legal status pathways to others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Richardson authored SB 34 (2025) on port emissions reductions but included explicit provisions against caps on cargo throughput and worker protections — balancing emissions reductions with economic continuity. She authored SB 767 (2025) requiring monthly crude oil pipeline reporting, a transparency measure. She voted YES on SB 1259 (refinery decommission estimates). This reflects maintaining current fossil fuel production with tightened environmental oversight rather than banning new drilling.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB34', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB767', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1259']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Richardson authored SB 530 (2025) extending Medi-Cal managed care network access standards through 2029 with secret-shopper testing requirements. Her congressional record shows she opposed Medicare privatization and supported the public insurance option and expanded SCHIP coverage for children. This record consistently reflects offering a public option alongside private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530', 'https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Richardson authored SB 748 (2025) addressing safe parking programs for people living in RVs as part of California's Encampment Resolution Funding framework, and SB 611 streamlining housing development approvals to address the homelessness and housing crisis. She voted YES on SB 802 (2025, Sacramento Area Housing and Homelessness Agency / Homekey expansion). This legislative pattern supports building shelter capacity and services as a primary strategy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB748', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB611']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Richardson authored SB 611 (2025) streamlining CEQA review for community plan updates to accelerate housing development, explicitly characterized as addressing the ongoing housing and homelessness crisis. She also authored SB 757 (vacant lot nuisance abatement with proceeds funding housing permit streamlining) and co-authored SB 625 (wildfire recovery residential rebuilding). This record reflects building affordable housing and expanding access as an active legislative priority.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB611', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB757', 'https://sd35.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Richardson voted YES on SJR 9 (2025, opposing mass immigration raids), SB 323 (Dream Act financial aid for undocumented students), and her congressional record shows consistent opposition to border fence construction with support for citizenship paths for undocumented immigrants. This record reflects expanding legal pathways and protecting undocumented residents rather than restriction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Richardson authored SB 530 (2025) expanding Medi-Cal managed care network adequacy standards for three more years with direct testing methods to verify access compliance. Her congressional record shows she consistently opposed Medicare privatization and supported expanding SCHIP. This record reflects lowering barriers and expanding Medicaid significantly while opposing privatization.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530', 'https://www.ontheissues.org/CA/Laura_Richardson.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$No direct bill authorships or strong votes on misinformation or platform regulation were found in Richardson's 2025-26 legislative record. She voted YES on SB 243 (companion chatbot regulation) which includes consumer protection against deceptive AI practices. Her general orientation and absence of extreme positions on either censorship or free speech absolutism suggests support for encouraging voluntary standards with some targeted enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Richardson voted YES on SB 1414 (2026, San Bernardino County Citizens Redistricting Commission), which establishes an independent citizens redistricting commission. Her vote in favor of independent citizen-led redistricting aligns with value 2 — independent commissions with equal representation from both major parties rather than legislative control.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1414']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No direct bills on religious freedom exemptions were found in Richardson's 2025-26 record. Her broader voting pattern — supporting civil rights enforcement via SB 477 (FEHA) and non-discrimination protections — suggests she balances protecting religious practices with maintaining equal treatment under law. The absence of bills on either extreme supports a centrist position consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB477', 'https://www.ontheissues.org/CA/Laura_Richardson.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Richardson's OTI congressional record explicitly states she co-authored the bill legalizing same-sex marriage in California and supports prohibiting employment discrimination based on sexual orientation. As a co-author of SSM legislation, her record reflects requiring all states to recognize same-sex marriages with full federal benefits and protections.$$,
        ARRAY['https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '00b95a6a-75db-4521-b523-3326bba938de', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Richardson voted YES on SB 494 (2025, charter school establishment prohibition and renewal procedure restrictions), which passed 27-10 and restricts charter school expansion. She also authored SB 631 (charter school revolving loan fund with tightened accountability requirements). This record supports restricting vouchers and charter expansion while prioritizing public school accountability — consistent with restricting vouchers to limited cases with accountability requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB494', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB631']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Richardson's congressional record shows she supported the $825 billion economic recovery package and opposed cuts to social safety net programs. As a progressive Democrat representing a low-income district (Compton, Carson, Hawthorne), her consistent record of expanding public programs and opposing privatization of Medicare and Medicaid aligns with modestly increasing Social Security benefits while raising taxes on higher earners to strengthen the program.$$,
        ARRAY['https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '683c8084-2281-4920-a07c-18439b2dd413', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Richardson voted YES on SJR 7 (2025-26), California's Senate resolution opposing President Trump's broad tariffs on imported goods, which passed 26-9. A YES vote on an anti-tariff resolution reflects opposition to blanket high tariffs on all imports but does not indicate support for eliminating all tariffs. The Port of LA/Long Beach is in her district; her SB 34 on port emissions also shows sensitivity to trade-related economic activity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB34']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Richardson's congressional record shows she supported the $825 billion economic stimulus package, backed auto industry bailouts, opposed terminating mortgage assistance programs, and received a 0% rating from CEI indicating strongly pro-worker and pro-government intervention stances. Her district (Compton, Carson) legislative priorities reflect modest tax increases on high earners while protecting middle-class families.$$,
        ARRAY['https://www.ontheissues.org/CA/Laura_Richardson.htm', 'https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$No direct bills or votes specifically on transgender athlete participation were found in Richardson's 2025-26 record. As a Democratic California senator who voted YES on SB 477 (FEHA anti-discrimination enforcement) and consistently supported LGBTQ rights in Congress including same-sex marriage co-authorship, her record is consistent with allowing transgender athletes to compete with documentation requirements. Scored 2 based on consistent LGBTQ-supportive record with no contrary evidence.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB477', 'https://www.ontheissues.org/CA/Laura_Richardson.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', '24e9212c-b011-422a-865c-093e35050901',
        $$Ukraine aid is a federal matter not directly voted on in the California legislature. Richardson's congressional record shows she backed withdrawal timelines for Iraq and Afghanistan but also voted for the 2008 FISA Amendments Act reflecting pragmatic security instincts. Her overall progressive Democratic profile is consistent with continuing current levels of aid to Ukraine to help the country defend itself.$$,
        ARRAY['https://en.wikipedia.org/wiki/Laura_Richardson', 'https://www.ontheissues.org/CA/Laura_Richardson.htm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Laura Richardson / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9edc0c37-f213-4aae-9212-c9cb4780d854', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Richardson voted YES on SB 316 (2025, high school voter registration expansion), which passed 28-9 over Republican opposition. She voted YES on SJR 9 opposing federal immigration raids that could suppress minority voter participation. Her congressional record reflects consistent support for expanding voter access. This record aligns with expanding early voting and making mail-in voting available to all voters.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB316', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Gonzalez authored SB 1131 (2024) on Medi-Cal providers and family planning, and voted YES on SB 523 (Contraceptive Equity Act of 2022). Her record reflects consistent support for abortion access and publicly funded reproductive healthcare through Medi-Cal, consistent with keeping abortion legal and accessible and funding it through public health programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1131', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB523']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Gonzalez voted YES on SB 1047 (2024), the landmark AI safety bill requiring pre-release safety testing for frontier AI systems. She also authored SB 1146 (2026) requiring disclosure of AI-generated digital replicas in health product advertisements. This pattern reflects support for close government monitoring and approval requirements before deploying AI systems in sensitive contexts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1146']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Gonzalez authored SB 1349 (2026) requiring legislative review of corporate tax expenditures to ensure taxpayer dollars benefit working families -- a transparency and accountability measure targeting tax loopholes rather than a direct campaign finance bill. No bills specifically limiting corporate donations or establishing public financing were found, suggesting a transparency-focused stance rather than full structural reform.$$,
        ARRAY['https://sd33.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1349']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Gonzalez voted YES on SB 1112 (2024), the childcare access and subsidy expansion bill, which passed 40-0. Her broader legislative record prioritizing worker benefits (SB 1349, SB 338 port truck driver protections) and CalFresh expansion (SB 1077) reflects consistent support for significantly expanding social supports and subsidies for working and low-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://sd33.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Gonzalez voted YES on SB 403 (2023, adding caste to protected discrimination classes), SB 16 (2023, civil rights enforcement), and authored SB 1016 (2024, the Latino and Indigenous Disparities Reduction Act, signed into law). This record reflects a consistent pattern of strengthening civil rights enforcement and addressing systemic discrimination through legislation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1016', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB16']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Gonzalez co-authored SB 252 (2023) requiring CalPERS/CalSTRS to divest from fossil fuel companies by 2031, authored SJR 2 supporting the Fossil Fuel Non-Proliferation Treaty, and authored SB 1182 (2024) on climate-resilient schools. She voted YES on SB 867 (2024 climate bond), SB 253 (climate corporate disclosure), and SB 1 (sea level rise). Wikipedia describes her as a frequent critic of Big Oil who authored a 2022 law banning new oil and gas wells near homes and schools.$$,
        ARRAY['https://en.wikipedia.org/wiki/Lena_Gonzalez', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB252', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Gonzalez voted YES on SB 57 in the 05/28/25 Senate third-reading floor vote (Aye among 25), which requires ratepayer impact assessments and cost-sharing agreements for data center energy demand, but was NVR on the final 09/13/25 concurrence vote. The earlier affirmative vote and NVR on final passage indicate general support for data center development with impact assessments and community cost-sharing requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Gonzalez authored SB 12 (2025) establishing a new Immigrant and Refugee Affairs Agency in state government, and voted YES on SJR 9 (2025-26) condemning mass immigration raids in California. Her district covers Long Beach and southeast LA with large immigrant communities; her legislative record consistently supports protecting undocumented residents from deportation except for serious criminal offenses.$$,
        ARRAY['https://sd33.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB12']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Gonzalez co-authored SB 252 (2023) requiring CalPERS/CalSTRS to divest from the 200 largest fossil fuel companies by 2031. She authored Senate Joint Resolution 2 (2024) supporting the Fossil Fuel Non-Proliferation Treaty. Wikipedia notes she authored 2022 legislation banning new oil and gas wells near homes and schools. She authored SB 674 (2023) adding air quality fence-line monitoring requirements for industrial facilities. This record reflects stopping new fossil fuel permits and investment rather than maintaining current levels.$$,
        ARRAY['https://en.wikipedia.org/wiki/Lena_Gonzalez', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB252', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB674']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gonzalez authored SB 1131 (2024, Medi-Cal providers: family planning, signed), SB 1016 (2024, Latino and Indigenous Disparities Reduction Act expanding healthcare access, signed), and the Equal Insurance HIV Act prohibiting coverage denials based on HIV status. She voted YES on SB 729 (IVF/fertility coverage expansion). Her record consistently supports expanding public healthcare coverage through Medi-Cal and regulating private insurance alongside a public option.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1131', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1016', 'https://en.wikipedia.org/wiki/Lena_Gonzalez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Gonzalez authored SB 1077 (2025) to ensure CalFresh recipients continue receiving benefits during federal shutdowns, protecting vulnerable populations from disruption. She voted YES on housing supply bills SB 4 and SB 684 (both 2023). Her legislative record as Senate Majority Leader consistently prioritizes expanding services and shelter capacity over enforcement-first approaches to homelessness.$$,
        ARRAY['https://sd33.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Gonzalez voted YES on SB 4 (2023, allowing housing on religious and nonprofit land near transit, 32-2) and SB 684 (2023, small infill housing development, 37-0). As Senate Majority Leader she has been part of the Democratic leadership coalition advancing major housing supply legislation. Her consistent YES votes on pro-supply housing bills reflect support for significantly expanding affordable housing production.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Gonzalez authored SB 12 (2025) creating an Immigrant and Refugee Affairs Agency to support immigrant and refugee communities statewide. She voted YES on SJR 9 (2025-26) opposing mass immigration raids in California. Her district encompasses large immigrant communities in Long Beach and SE Los Angeles and her legislative record reflects consistent support for significantly expanding immigrant services and legal pathways.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB12', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://sd33.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Gonzalez authored SB 1131 (2024, Medi-Cal providers: family planning), voted YES on SB 873 (prescription drug cost sharing), and authored SB 1016 (2024, health disparities reduction expanding Medi-Cal access for Latino and Indigenous communities). Her record consistently reflects expanding Medicaid (Medi-Cal) coverage and lowering healthcare costs for lower-income Californians, consistent with significantly expanding Medicaid and lowering Medicare age.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1131', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1016', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB873']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Gonzalez voted YES on SB 976 (2024, Protecting Our Kids from Social Media Addiction Act, restricting algorithmic content promotion to minors) and authored SB 1146 (2026, requiring disclosure when AI-generated digital replicas are used in health advertisements). These actions reflect support for transparency standards and targeted mandatory disclosure around harmful content rather than broad government content removal mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1146']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Gonzalez voted YES on SB 314 (2023), establishing independent citizens redistricting commissions with equal party representation to draw legislative district maps, which passed the Senate 31-7 and was signed into law. This directly reflects support for independent redistricting commissions with equal representation from both major parties.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Gonzalez voted YES on ACA 5 (2023), the California constitutional amendment to enshrine marriage equality in the state constitution and ensure all same-sex marriages receive full state recognition and benefits, passing the Senate 31-0. This reflects full support for requiring all states to recognize same-sex marriages with complete federal and state benefits and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Gonzalez voted YES on SB 494 (2023), which imposed a moratorium on new charter schools authorized by non-school-district entities -- a direct restriction on mechanisms that divert public education funding to private-adjacent institutions. This reflects a strong preference for fully funding public schools and limiting programs that divert taxpayer money away from public schools.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Gonzalez authored SB 263 (2025), requiring a state study of tariff impacts on California workers and businesses, which passed the Senate 40-0. She voted YES on SJR 7 (2025), the resolution opposing blanket federal tariffs while supporting targeted trade protections for specific industries. This record reflects selective use of tariffs to protect key American industries and jobs rather than across-the-board protectionism.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB263', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Gonzalez authored SB 1349 (2026) requiring legislative review of corporate tax expenditures to ensure they benefit working families, specifically targeting ineffective corporate tax breaks and loopholes. Her career focus on worker protections (SB 338, SB 616 paid sick leave) and social safety net expansion reflects a consistent position of modestly increasing taxes on high earners and corporations while protecting working and middle-class families.$$,
        ARRAY['https://sd33.senate.ca.gov/legislation', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1349']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Gonzalez voted YES on AB 1955 (2024, the Safe and Supportive Schools Act protecting transgender student privacy and participation, passing 29-8) and SB 107 (2022, gender-affirming healthcare, passing 30-9). Her votes reflect consistent support for allowing transgender individuals to participate in activities and teams matching their gender identity, with basic documentation of transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lena Gonzalez / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1cede4d2-3075-4860-b133-1ab34cdacff5', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Gonzalez voted YES on SB 1174 (2024), which prohibits local jurisdictions from requiring voter ID beyond what state law mandates, effectively opposing strict photo ID requirements and protecting mail-in voting access. This reflects support for expanding early voting periods and making mail-in voting available to all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Smallwood-Cuevas has not authored abortion-specific legislation, but voted YES on SB 729 (2024) requiring health coverage for infertility and fertility services, reflecting strong reproductive healthcare access support. Her labor-organizing and civil rights background aligns with California mainstream pro-choice Democratic caucus; no restrictive reproductive bills in her record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://sd28.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on SB 1047 (2024), California's landmark frontier AI safety bill requiring developer safety protocols and oversight before deploying powerful AI models. Authored SB 366 (2025-26) requiring AI employment impact disclosures, signaling support for monitoring and government oversight of AI in the workplace. Pattern aligns with closely monitoring AI development and requiring government involvement before advanced systems are released.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB366']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Voted YES on SB 1027 (2024), the Political Reform Act of 1974 disclosure bill strengthening campaign finance transparency requirements (passed 39-0). Her labor-organizer background and civil rights advocacy align with limiting corporate influence in politics; authored employer pay data transparency bill (SB 464, 2025, chaptered). Pattern suggests strict limits on corporate and dark money beyond mere disclosure.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB464']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Voted YES on SB 1112 (2024) expanding childcare alternative payment programs for working families. Her founding of the LA Black Worker Center and 20-year labor organizing career centered on economic equity for working families and single mothers. Bill pattern and background strongly support significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://en.wikipedia.org/wiki/Lola_Smallwood-Cuevas']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored SB 16 (2023) empowering local agencies to enforce fair employment and housing laws, SB 303 (2025, chaptered) requiring bias mitigation training, SB 809 (2023) restricting employer use of criminal convictions in hiring, and SB 497 (2023) creating anti-retaliation protections for wage complaints. Also voted YES on SB 403 (2023) adding ancestry/caste to anti-discrimination law. Record reflects strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB303', 'https://sd28.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted YES on SB 867 (2024), California's $10 billion climate bond package for rapid clean energy investment. Authored SB 823 (2023) establishing utility EV charging discount programs for households without home chargers, directly accelerating fossil fuel phase-out. Pattern reflects rapid renewable energy transition and proactive climate investment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://sd28.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Voted YES on SB 57 (2025) requiring data centers to report projected energy demand and rate impacts before approval. The bill requires impact assessments and cost transparency without imposing a moratorium or requiring dedicated power generation. Aligns with allowing data center development with impact assessments, energy cost-sharing agreements, and community benefit requirements before approval.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted YES on SJR 9 (Jan 2026) condemning mass immigration raids in California, and YES on SB 323 (2025) expanding Dream Act financial aid for undocumented students. Voted YES on SB 1099 (2026) expanding state and local public benefits access. As LA Black Worker Center founder she advocated for immigrant workers. Pattern supports deporting only serious violent offenders while providing legal status to others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB1099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted YES on SB 867 (2024, California climate bond) funding rapid clean energy transition; voted YES on SB 419 (2025, hydrogen fuel infrastructure). Authored SB 823 (2023) establishing EV charging discount programs as a concrete fossil fuel displacement measure. No bills expanding fossil fuel drilling; consistent pattern of phasing out fossil fuels in favor of renewables and clean alternatives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB419', 'https://sd28.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored and championed SB 525 (2023, chaptered) raising minimum wage for healthcare workers to $25/hour, one of the most significant healthcare access bills of the 2023 session. Voted YES on SB 729 (2024) mandating insurance coverage for infertility/fertility services. Voted YES on SB 873 (2023) reducing prescription drug cost sharing. Record reflects expanding coverage and regulating costs through mandates and regulated insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB873']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES on SB 802 (2025) funding the Homekey homeless housing program and homelessness prevention efforts. Voted YES on ACA 1 (2023) enabling local government financing for affordable housing projects. Her SD 28 district includes Inglewood and South LA communities with high homelessness rates; district office resources highlight housing support. Pattern reflects expanding shelter capacity, services, and housing investment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA1']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES on SB 4 (2023) allowing residential development on religious and higher-ed land; YES on SB 684 (2023) streamlining small-scale urban residential development approval; YES on SB 802 (2025) expanding housing and homelessness funding; YES on ACA 1 (2023) enabling local affordable housing financing. Consistently supported supply expansion and affordable housing investment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB802']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted YES on SJR 9 (2026) condemning mass immigration raids; YES on SB 323 (2025) expanding Dream Act financial aid; YES on SB 1099 (2026) expanding public benefits access for immigrants. District office highlights immigration resources and know-your-rights information. As LA Black Worker Center founder, she advocated for immigrant workers. Pattern reflects significantly expanding pathways and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB323', 'https://sd28.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted YES on SB 525 (2023) raising healthcare worker wages, directly supporting Medi-Cal provider capacity and retention. Voted YES on SB 873 (2023) reducing prescription drug cost sharing for patients. Her district encompasses Inglewood and West LA communities with high Medi-Cal enrollment. Pattern reflects expanding Medicare/Medicaid significantly and lowering barriers to coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB873']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES on SB 976 (2024), the Protecting Our Kids from Social Media Addiction Act, which restricts algorithmic content feeds for minors. No authored legislation mandating platform-wide fact-checking or algorithm transparency beyond targeted protections for vulnerable groups. Pattern reflects encouraging voluntary standards with targeted mandatory protections rather than broad government content removal mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES on SB 314 (2023) establishing independent redistricting commissions with equal representation from both major parties, passing the Senate 32-7. Consistent with her civil rights and equal representation advocacy background. Aligns with value 2: independent commissions with balanced partisan representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES on ACA 5 (July 2023), the constitutional amendment to restore same-sex marriage equality in California's constitution, with the Senate vote passing 31-0 unanimously. This affirms full constitutional marriage equality requiring all state recognition with complete federal-equivalent benefits and protections, aligning with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Voted YES on SJR 7 (2025-26 session), a California Senate resolution opposing blanket federal tariffs while expressing support for targeted trade enforcement to protect specific industries and workers. Consistent with her labor-organizing background prioritizing American workers over either blanket protectionism or complete free trade. Aligns with using tariffs selectively to protect key American industries and jobs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored SB 497 (2023) strengthening anti-retaliation protections for workers filing wage complaints, SB 464 (2025, chaptered) mandating employer pay data reporting, and SB 725 (2023) requiring severance pay during grocery chain acquisitions. Her 20-year labor organizing career and founding of the LA Black Worker Center reflect strong support for progressive taxation on high earners to fund worker programs. Pattern aligns with modestly increasing taxes on high earners while protecting middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB464', 'https://sd28.senate.ca.gov/legislation', 'https://en.wikipedia.org/wiki/Lola_Smallwood-Cuevas']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES on AB 1955 (June 2024, the Safe and Supportive Schools Act protecting transgender students' rights and privacy in school settings, passing 29-8 in the Senate). No authored legislation restricting transgender athletes; consistent with California Democratic caucus supporting transgender participation rights. Pattern reflects allowing transgender athletes to compete on teams matching their gender identity after basic transition documentation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lola Smallwood-Cuevas / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES on SB 1174 (May 2024) opposing restrictive voter ID requirements and protecting mail-in voting accessibility, passing 30-8. Consistent with her civil rights and community advocacy background emphasizing voting access for marginalized communities in West LA and Inglewood. Pattern reflects expanding early voting periods and making mail-in voting available to all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Durazo is a consistent California Democratic caucus vote on reproductive rights. She voted YES on SB 729 (2024) requiring health insurance coverage for infertility and fertility services, and has authored and co-authored multiple healthcare access bills. No anti-abortion bills or statements found; her record is consistent with keeping abortion legal and accessible through the second trimester and beyond, in line with California law.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Durazo voted YES on SB 1047 (2024, AI safety requirements, 32-1), SB 243 (2025, AI safety, 33-3), SB 813 (2026, AI regulation, 31-7), and SB 719 (2026, AI inventory, 39-0). She also voted YES in the Labor Committee on SB 366 (2025, employment AI protections). Her pattern reflects consistent support for basic safety testing and oversight before AI systems are released, without authoring the most aggressive oversight packages, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Durazo's labor union background as AFL-CIO VP and UNITE HERE Local 11 president places her firmly in the tradition of limiting corporate money in politics. She voted YES on SB 976 (2024, social media transparency, 35-2). Her AFL-CIO institutional ties and progressive base reflect strong commitment to limiting corporate donations and dark money groups rather than merely requiring disclosure, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Durazo voted YES on SB 1112 (2024, childcare subsidies for low- and middle-income families, unanimous 40-0) and SB 616 (2023, paid sick leave expansion covering childcare needs, 27-9). Her labor background and repeated votes expanding workplace protections and social services place her consistently in the significant subsidy expansion tier for childcare access for working families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB616']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Durazo voted YES on SB 403 (2023, adding caste to anti-discrimination protected classes, 31-5), ACA 5 (2023, same-sex marriage constitutional amendment, 31-0), and AB 1955 (2024, LGBTQ student protections, 29-8). She co-authored SJR 9 (2026) condemning mass immigration raids as a civil rights matter. Her labor union career was built on fighting discrimination in low-wage immigrant worker communities, reflecting strengthening civil rights enforcement and addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Durazo voted YES on SB 867 (2024, $10B climate bond, 33-6) and SB 770 (2023, unified healthcare financing research). Her YES on SB 57 (2025, data center energy reporting, 29-8) reflects attention to clean energy costs. Her consistent progressive caucus votes reflect rapidly transitioning to renewable energy and phasing out fossil fuels, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Durazo voted YES on SB 57 (2025, data centers energy cost reporting to PUC, 29-8), which requires evaluating whether data center electrical loads create financial burdens for other utility customers. This is an impact-assessment and cost-sharing approach, allowing development with community benefit review before approval, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Durazo authored SB 580 (2025, requiring AG model policies limiting state cooperation with ICE, chaptered) and SB 635 (2025, protecting street vendors from immigration enforcement inquiries, chaptered). She voted YES on SJR 9 (2026, condemning mass immigration raids, 29-10). This record reflects only deporting immigrants who commit serious violent crimes while providing legal status protections to all others.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB580', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB635', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Durazo voted YES on SB 867 (2024, $10B climate bond funding renewable energy infrastructure, 33-6) and consistently supports California's clean energy transition. Her voting record on climate and energy bills reflects stopping new fossil fuel permits and transitioning to renewables, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Durazo authored SB 525 (2023), establishing a pathway to $25/hour minimum wage for 400,000+ healthcare workers (signed October 2023). She championed the Health4All Medi-Cal expansion and authored SB 1422 (2026) to restore Medi-Cal access for undocumented immigrants. She voted YES on SB 770 (2023, unified healthcare financing research, 29-9). Her record reflects expanding public coverage alongside private insurance rather than a full single-payer system, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1422', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB770']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Durazo issued statements on the 2025 Point in Time Count framing decreased LA homelessness as requiring continued housing investment. She voted YES on SB 326 (2023, Behavioral Health Services Act directing mental health funding toward unsheltered individuals, 40-0). Her housing and behavioral health record consistently reflects building affordable housing units and expanding services as the primary homelessness strategy.$$,
        ARRAY['https://sd26.senate.ca.gov/press-releases', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB326']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Durazo voted YES on SB 4 (2023, housing on religious/college land, 32-2), SB 684 (2023, streamlined small-lot housing, 37-0), and SB 79 (2025, housing near transit, 21-8). She authored SB 346 (2025, short-term rental tax enforcement to protect housing stock, 40-0). Wikipedia notes she initially raised affordability concerns about SB 79 but ultimately voted YES on final passage. Her record reflects building affordable units and expanding housing access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Durazo authored SB 580 (2025, AG model policies limiting state cooperation with ICE), SB 635 (2025, street vendor immigration protections), and SB 1422 (2026, restoring Medi-Cal to undocumented immigrants). She voted YES on SJR 9 (2026, condemning mass immigration raids). Her 25-year career organizing immigrant hotel and restaurant workers and consistent legislative record reflect significantly increasing protections and creating easy pathways to legal status.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB580', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1422', 'https://sd26.senate.ca.gov/press-releases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Durazo authored SB 525 (2023) raising healthcare worker wages to support Medi-Cal provider capacity, championed Health4All Medi-Cal expansion, and authored SB 1422 (2026) to restore full Medi-Cal to undocumented immigrants. She voted YES on SB 770 (2023, unified healthcare financing research). Her record reflects expanding Medicaid significantly and lowering barriers to coverage for all Californians.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1422', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB770']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Durazo voted YES on SB 976 (2024, Social Media Youth Addiction Act mandating algorithmic transparency and opt-out tools for minors, 35-2). This is a targeted transparency approach rather than requiring broad removal of false content or heavy content moderation. No bills authored requiring platform-wide misinformation removal found, placing her at value 3 — targeted transparency measures and voluntary standards.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Durazo voted YES on SB 314 (2023, strengthening California's independent citizens' redistricting commission, 31-7). SB 314 expanded the commission's authority and reform provisions. Her vote reflects support for independent redistricting commissions with equal party representation rather than legislative control.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No bills authored or major votes found specifically targeting religious freedom exemptions. Durazo's labor background organizing hotel workers at religiously affiliated institutions reflects balancing worker rights with institutional autonomy rather than either extreme. Absent specific legislative action, her record is consistent with value 3 — balancing religious practices with equal treatment under the law.$$,
        ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Durazo voted YES on ACA 5 (2023, constitutional amendment requiring recognition of same-sex marriages with full federal benefits and protections, Senate vote 31-0 with no opposing votes). ACA 5 places same-sex marriage equality in the state constitution, requiring full recognition and equal protections, aligning with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Durazo voted YES on SB 494 (2023, imposing a moratorium on new charter school approvals, 32-7). Her AFL-CIO institutional alignment reflects the labor movement's firm opposition to vouchers that divert taxpayer money from public schools to private institutions. SB 494 restricting charter expansion is the strongest available evidence of opposing public school fund diversion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$No direct California Senate votes on federal Social Security exist as it is a federal program. Durazo's AFL-CIO career reflects the labor movement's institutional position of modestly increasing Social Security benefits and raising taxes on higher earners to strengthen it. Her consistent record protecting worker retirement security through state legislation aligns with value 2. Assigned low confidence; inferred from career alignment.$$,
        ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Durazo voted YES on SJR 7 (2025-26, condemning Trump's blanket tariffs and calling for return to negotiated trade policy, 26-9). The resolution opposes unilateral broad tariffs while leaving room for targeted measures to protect American workers and industries, consistent with using tariffs selectively rather than either free trade or blanket protectionism.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Durazo authored SB 525 (2023) establishing minimum wages for 400,000+ healthcare workers funded partly through progressive state healthcare expenditures, and SB 1422 (2026) expanding Medi-Cal funded by general revenues. Her AFL-CIO background and voting record on healthcare and social services reflect supporting modestly increasing taxes on high earners while maintaining rates for middle-class families to fund expanded public programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB525', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Durazo voted YES on AB 1955 (2024, protecting transgender students' rights and privacy in schools, passing 29-8 in the Senate). No anti-trans-athlete bills supported or authored. Consistent with California Democratic caucus supporting transgender athletes competing on teams matching their gender identity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '24e9212c-b011-422a-865c-093e35050901', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', '24e9212c-b011-422a-865c-093e35050901',
        $$No specific California Senate votes on Ukraine aid found, as foreign policy is a federal matter. Durazo's progressive Democratic profile and AFL-CIO alignment reflect consistent support for continuing military and economic aid to Ukraine to help it defend itself — the mainstream Democratic position. No contrary statements or votes found. Assigned low confidence; inferred from party and career alignment.$$,
        ARRAY['https://en.wikipedia.org/wiki/Maria_Elena_Durazo']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Maria Elena Durazo / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Durazo voted YES on SB 1174 (2024, prohibiting restrictive voter ID mandates and protecting mail-in voting access, 30-8). This reflects expanding early voting and making mail-in voting available to all voters without requiring an excuse, consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Alvarado-Gil voted No on SB 365 (2023, Wiener -- removing Medi-Cal and insurance barriers to abortion), one of few Democrats to oppose it. She was NVR on SB 729 (IVF insurance mandate, 2024). After switching to the Republican Party in August 2024, her pattern aligns with restricting abortion to cases of rape, incest, or maternal health rather than broad access -- more restrictive than the CA Democratic mainstream but short of a full ban.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB365', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '666bf03d-81fc-4138-ab15-69ae734c9023', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Alvarado-Gil voted No on SB 1047 (AI safety, final passage 08/29/24), No on SB 813 (2026 AI regulation), and No on SB 243 (2025 AI/misinformation bill). She voted Aye on SB 719 (2026, basic AI transparency, unanimous 39-0). Her consistent opposition to substantive AI regulation places her at value 1 -- preferring AI companies to develop and deploy technology freely without government interference.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Alvarado-Gil voted Aye on SB 1027 (2024, campaign finance disclosure) and SB 1439 (2024, Ashby -- campaign finance ethics). Both are disclosure/transparency measures rather than donation limits or public financing. Her record supports transparency requirements without evidence of broader structural reform positions, placing her at value 3 -- requiring full disclosure of all political donations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1439']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Alvarado-Gil voted Aye on SB 1112 (2024, childcare subsidies/provider support). She has not authored universal childcare bills; her fiscal-conservative record suggests support for targeted rather than broad subsidies. Her authorship of SB 353 (income tax credits for food banks) shows comfort with targeted tax relief, placing her at value 3 -- targeted credits and subsidies for families below a set income threshold with provider support.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB353']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '0bc588c6-39e1-4084-b5de-cac909b8b762', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Alvarado-Gil voted Aye on SB 457 (2023, civil rights/anti-discrimination) and later Aye on the SB 403 concurrence (caste discrimination). Her moderate record -- neither authoring civil rights bills nor opposing them -- and her Republican Party switch in 2024 suggest she maintains current civil rights laws without prioritizing systemic enforcement expansion, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB457', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Alvarado-Gil voted Aye on SB 867 (2024, climate bond) and SB 306 (2023, climate/environment). She voted No on SB 253 (2023, Climate Corporate Data Accountability Act -- corporate emissions disclosure mandate). Her rural district focus and opposition to regulatory mandates on businesses, alongside support for the climate bond, places her at value 3 -- investing in clean energy while avoiding strict emission mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB306']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4559b513-0fd8-4ed1-babd-f3b554162f40', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Alvarado-Gil voted No on SB 57 (2025, data centers -- requiring ratepayer impact assessments and energy cost-sharing before approval). She was among a small minority opposing this bill. Her opposition to energy regulation and rural/economic-development orientation indicate a preference for welcoming data center investment with minimal regulatory barriers, consistent with value 5.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://sr04.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '44905f3b-e105-4f6c-afc7-5d223813dbac', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Alvarado-Gil voted No on SJR 9 (01/22/26, condemning federal immigration enforcement operations). She was NVR on SB 873 (2023, protecting immigrants from deportation in courts). Her Republican Party switch in August 2024 and vote against the anti-deportation resolution signal support for deporting those without legal status, processing cases in order of criminal history, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB873', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Alvarado-Gil voted Aye on SB 1420 (2024, hydrogen/fossil fuel transition) and SB 867 (2024, climate bond). She has not authored bills to expand drilling or remove environmental restrictions. Her rural district includes agricultural and energy concerns; her wildfire legislation signals environmental awareness alongside economic pragmatism. Her record places her at value 3 -- maintaining current levels of fossil fuel production with existing environmental regulations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1420', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://sr04.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Alvarado-Gil voted No on SB 525 (2023, $25 minimum wage for healthcare workers), one of 11 senators opposing it. She was NVR on SB 729 (IVF coverage mandate, 2024). Her fiscal conservatism and opposition to healthcare workforce cost mandates, combined with her Republican Party switch in 2024, suggest she supports limited government assistance for those who cannot afford healthcare rather than broad coverage expansion, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Alvarado-Gil voted Aye on SB 363 (2023, Eggman -- shelter crisis/homelessness, 40-0 unanimous vote). Her district office secured $12.4 million in rural homelessness funding (October 2024). She has not authored major housing-first bills. Her pragmatic approach -- funding services and infrastructure without broad structural change -- places her at value 3, providing tax incentives and targeted homelessness assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB363', 'https://sr04.senate.ca.gov/news']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Alvarado-Gil voted Aye on SB 4 (2023, housing on religious/college land), SB 684 (2023, small homes/infill), SB 423 (2023, infill housing), and AB 1279 (2023, housing). She did not author major housing reform bills. Her support for practical housing production without authoring upzoning mandates or opposing market-rate development places her at value 3 -- providing tax incentives for affordable housing while helping first-time buyers.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Alvarado-Gil voted Aye on SB 831 (2023, agricultural worker immigration parole -- protecting ag workers in her rural district). She was NVR on SB 873 (ICE court access) and voted No on SJR 9 (2026, condemning federal immigration enforcement). Her mixed record -- supporting protections for agricultural workers while opposing broader advocacy resolutions -- reflects maintaining current immigration levels while streamlining the legal process, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Alvarado-Gil voted Aye on SB 244 (2023, Medi-Cal expansion for undocumented immigrants) and AB 1114 (2023, Medi-Cal expansion). She has not authored bills to expand or cut these programs. Her fiscal conservatism and opposition to healthcare wage mandates suggest she supports maintaining and improving current programs while controlling costs, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB244', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1114']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Alvarado-Gil voted No on SB 243 (2025, requiring platforms to label AI-generated content). She voted Aye on SB 1018 (2024, social media misinformation involving minors). Her No vote on the more comprehensive misinformation bill, combined with broader opposition to AI regulation, suggests a free-speech protective stance -- preferring to prevent government censorship over mandating content moderation, aligning with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1018']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Alvarado-Gil voted Aye on SB 314 (2023, independent redistricting commissions with equal party representation) and SB 1414 (2024, redistricting reform). Both bills support independent or bipartisan commissions rather than pure legislative control, consistent with value 2 -- independent redistricting commissions with equal representation from both major parties.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1414']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Alvarado-Gil switched to the Republican Party in August 2024, aligning with a caucus that strongly supports religious liberty exemptions. She authored SB 1109 (short-term residential therapeutic programs involving faith-based settings). Her rural, conservative-district representation and Republican affiliation post-2024 suggest support for faith-based exemptions from laws that conflict with sincere religious beliefs, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1109', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Alvarado-Gil voted Aye on ACA 5 (07/13/23, the constitutional amendment restoring same-sex marriage protections in California), which passed the Senate 31-0. Despite later switching to the Republican Party in August 2024, her affirmative vote on this landmark civil rights measure -- the only direct SSM floor vote available -- places her at value 1, requiring all states to recognize same-sex marriages with full federal benefits and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '00b95a6a-75db-4521-b523-3326bba938de', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Alvarado-Gil authored SCR 116 (2025-2026, National School Choice Week resolution), co-authored with Republican senators Choi, Jones, Ochoa Bogh, Seyarto, and Valladares. The resolution expressly states school choice programs provide pupils and parents access to high-quality schools and are especially valuable for low-income and rural families. She also voted Aye on SB 494 (2023, charter school accountability reform). Authoring the school choice resolution demonstrates an expanding-voucher-eligibility orientation, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SCR116', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '87d20824-a6e9-407b-983c-65440084a0ab', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Alvarado-Gil voted Aye on SB 474 (2023, Social Security protection/pension reform). Her fiscal conservative record and Republican Party switch do not indicate support for privatizing Social Security, but also not major benefit expansion. Her rural district with a significant retiree population constrains cuts. Her record is consistent with value 3 -- making small adjustments to both benefits and taxes to keep Social Security stable for future generations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB474', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Alvarado-Gil was NVR on SJR 7 (07/17/25, resolution opposing Trump tariffs -- she neither opposed tariffs nor endorsed the anti-tariff resolution alongside most Democrats). Her agricultural and rural district depends on both export markets and domestic manufacturing. Her abstention suggests a selective, industry-protective approach rather than opposition to or full embrace of tariffs, consistent with value 3 -- using tariffs selectively to protect key American industries.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7', 'https://sr04.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Alvarado-Gil voted No on SB 525 (healthcare minimum wage), No on SB 616 (expanded paid sick leave mandate), and No on SB 553 (workplace safety mandates). She authored SB 353 (tax credits for food banks), SB 1118 (tax credits for solar/backup generators), and SB 1084 (fire safe home tax credits) -- all tax relief/credit approaches. Her fiscal conservative record and Republican Party switch in 2024 align with value 4 -- reducing tax rates across all income levels.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB353', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1084']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Alvarado-Gil voted No on SB 107 (03/20/25, transgender youth protection bill, passed 28-10). She was NVR on AB 1955 (2024, transgender student privacy). Her opposition to transgender protective legislation and Republican Party switch in August 2024 indicate she supports requiring transgender athletes to compete on teams matching their biological sex assigned at birth, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / ukraine-support
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '24e9212c-b011-422a-865c-093e35050901', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', '24e9212c-b011-422a-865c-093e35050901',
        $$No direct California legislative vote on federal Ukraine aid was found in her record. Her rural, fiscally conservative district and Republican Party switch in August 2024 suggest she likely prioritizes domestic spending over open-ended foreign military aid commitments, consistent with value 3 -- providing limited humanitarian aid to Ukraine while encouraging diplomatic negotiations to end the war.$$,
        ARRAY['https://en.wikipedia.org/wiki/Marie_Alvarado-Gil', 'https://sr04.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Marie Alvarado-Gil / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Alvarado-Gil was NVR on SB 1174 (2024, anti-voter-ID bill -- NVR alongside Republicans Dahle, Grove, Nguyen, Niello, Ochoa Bogh, Wilk). Her rural Republican-district orientation and Republican Party switch in August 2024 suggest she supports photo ID requirements for voting and regular voter roll maintenance, consistent with value 4 -- requiring photo ID for voting and regularly updating voter rolls.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://en.wikipedia.org/wiki/Marie_Alvarado-Gil']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Dahle voted NO on SB 1142 (abortion services expansion, 2022) and NO on AB 2223 (reproductive health bill removing criminal penalties for abortion at any stage, 2022). Both votes reflect opposition to any legislative expansion of abortion access, consistent with a near-complete restriction stance. No pro-choice legislation authored or supported was found.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1142', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$As a 2025-2026 State Senator, Dahle voted YES (37-0) on SB 53 (May 2025), requiring basic AI safety testing and incident reporting before deploying advanced AI systems, and YES (39-0) on SB 719 (Jan 2026), establishing government AI accountability frameworks. These bipartisan votes suggest she supports baseline safety testing requirements without opposing AI development broadly, consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB719']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '0bc588c6-39e1-4084-b5de-cac909b8b762', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Dahle voted NO on SB 403 (September 2023 concurrence vote), which would have added caste to protected civil rights classes. Her conservative Republican record and rural Northern California district reflect opposition to expanding civil rights enforcement categories and race-based government programs, consistent with value 5.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Dahle voted NO on SB 867 (July 2024, clean energy and climate investment bond) and NO on SB 253 (September 2023, corporate climate emissions disclosure). She represents a rural agricultural and resource-extraction district and has been consistent in opposing major climate legislation, reflecting rejection of climate change policies in favor of economic growth.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '4559b513-0fd8-4ed1-babd-f3b554162f40', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Dahle voted NO on SB 57 (May 2025 Senate floor vote, 25-9) and NO in the April 2025 committee vote. SB 57 would have required data centers to fund their own power generation and barred utilities from passing data center infrastructure costs to residential customers. Her NO vote signals preference for welcoming data center investment with minimal regulatory barriers.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'a22215c3-6693-4bc2-b248-01aebba14570', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Dahle voted NO on SB 867 (July 2024, clean energy and climate bond) and NO on SB 253 (September 2023, corporate climate emissions disclosure), consistently opposing legislation that would constrain fossil fuel production or require emissions accountability. Her rural Northern California district is heavily dependent on agriculture, logging, and resource extraction industries, reinforcing a pro-extraction stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$As an Assembly member, Dahle voted NO on SB 525 (September 2023 concurrence, healthcare worker minimum wages affecting Medi-Cal providers). She also NVR on SB 729 (IVF coverage mandate, 2023 and 2024). Her pattern of opposing healthcare expansion legislation reflects a preference for private markets over government involvement in healthcare coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Dahle voted NO on SB 450 (housing development streamlined approvals, May 2023 and August 2024 concurrence) and NO on SB 4 (housing on religious and institutional land, May 2023). She voted YES on SB 684 (infill housing) on the September 2023 final concurrence. Her mixed record leans toward opposing state-mandated housing density while allowing limited private market flexibility, consistent with reducing regulations rather than government-driven affordable housing programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB450', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Dahle has consistently voted against expansion of public health programs. She opposed SB 525 (healthcare worker minimum wages for Medi-Cal providers, 2023) and NVR on SB 729 (IVF coverage mandate). Her conservative rural Republican record reflects a preference for private insurance over public program expansion, consistent with phasing out public programs in favor of private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Dahle voted YES on SB 976 (May 2024 Senate floor, 35-2 vote), which restricts addictive social media features for minors but does not require algorithmic transparency or broad fact-checking mandates. This targeted vote protecting children from addictive design rather than mandating platform-wide content moderation is consistent with value 4 (protect free speech online, prevent government censorship) with narrow exceptions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '48cc9585-ec22-4f53-8d42-6839828dd36f', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Dahle voted NO on SB 314 (May 2023), which would have established independent redistricting commissions with equal party representation. Her NO vote aligns with the Republican preference for party-controlled redistricting, consistent with the party controlling the state legislature drawing districts without outside interference.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Dahle was NVR on ACA 5 (July 2023 Senate vote, which passed 31-0 among those voting), the constitutional amendment to enshrine same-sex marriage in California. Rather than vote in support alongside all present senators, she did not record a vote. Combined with voting NO on SB 107 (transgender youth protections) and opposing LGBTQ-protective legislation broadly, her record reflects opposition to same-sex marriage recognition requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '683c8084-2281-4920-a07c-18439b2dd413', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Dahle voted NO on SJR 7 (July 17, 2025, Senate floor 26-9), a resolution opposing broad tariff policies as harmful to California exporters and agricultural producers. Voting against this anti-tariff resolution signals support for using tariffs as a trade policy tool against countries that do not trade fairly with America, consistent with value 4. Her rural farming district in Northern California is affected by agricultural trade policy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Dahle voted NO on SB 525 (September 2023 concurrence, healthcare minimum wage increases for public sector healthcare workers) and has a consistent record opposing bills that increase government spending or expand public sector compensation. No bills increasing taxes are found in her record; her voting pattern reflects support for reducing tax rates rather than targeted increases on high earners or corporations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Dahle voted NO on SB 107 (March 2023), which prohibited removing transgender youth from supportive parents, and NVR on AB 1955 (June 2024 Assembly floor), which prohibited schools from outing transgender students to parents. Her opposition to LGBTQ-protective legislation reflects a stance of banning or heavily restricting transgender participation in organized sports, consistent with value 5.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Megan Dahle / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c1215ce9-430e-411d-869c-353c93fe1cac', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Dahle voted NO on SB 1174 (May 2024 Senate floor, 30-8 vote), which prohibited local governments from imposing voter ID requirements on state and federal elections. Her NO vote reflects support for photo ID requirements and stricter voter eligibility verification, consistent with value 4 (require photo ID and regularly update voter rolls to remove inactive registrations).$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted Aye on AB 576 (2023) which expanded abortion access in California passing 30-8 in the Senate. As a Central Valley moderate Democrat she has not authored abortion-restriction bills and consistently aligns with the California pro-choice caucus supporting legal access through the second trimester and beyond.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB576']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted Aye on SB 1047 (AI safety 2024) and Aye on SB 813 (AI safety 2026). Aye on SB 53 concurrence (2024). NVR on SB 243 (companion chatbots 2025). Her legislative priorities page emphasizes holding the powerful accountable through algorithmic price-manipulation oversight, suggesting support for basic safety testing before AI deployment rather than heavy pre-approval requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB813', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Voted Aye on SB 644 (2023 campaign contribution limits bill by Glazer passed 34-0). NVR on SB 1027 (2024 campaign finance disclosure). Her stated priority of holding the powerful accountable and ethics reforms points to a transparency stance requiring full disclosure of political donations rather than banning private money or eliminating limits.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB644', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Voted Aye on SB 1112 (2024 childcare alternative payment programs) across all committee and floor votes. Her legislative priorities emphasize food security and basic needs affordability for Central Valley families consistent with significantly expanding childcare subsidies and provider grants for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted Aye on SB 403 (2023 caste discrimination civil rights 31-7 final passage) AB 1815 (2024 CROWN Act expansion 40-0) and SB 107 (2023 transgender youth healthcare protections 27-12). This pattern reflects strengthening civil rights enforcement and addressing systemic discrimination consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1815', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted Aye on SB 867 (2023 climate bond on all three Senate votes) and SB 1418 (2024 hydrogen infrastructure). However recorded NVR on SB 253 and SB 261 (2023 major climate disclosure bills). Her legislative priorities highlight water management and climate preparedness in schools but protect emergency fleets from costly mandates — a Central Valley pragmatic approach investing in clean energy while gradually reducing fossil fuel reliance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1418', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Voted Aye on SB 57 (2025 electrical corporations data centers reporting requirements) in committee (Apr 2025) and floor (May 2025). Her broader energy accountability priorities including protecting ratepayers and utility transparency align with allowing data center development with impact assessments and cost-sharing agreements rather than moratoria or unrestricted incentives.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted Aye on SJR 9 (2026 opposing federal mass immigration raids in California passed 29-10 Jan 2026). Her Central Valley district has a large agricultural and farmworker immigrant community. Voted Aye on SB 686 (2023 domestic workers protections). No evidence of pro-enforcement deportation positions consistent with protecting undocumented residents except for serious violent offenders.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB686']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted Aye on SB 438 (2023 carbon sequestration and pragmatic fossil fuel transition) and SB 1418 (2024 hydrogen infrastructure). NVR on SB 1259 (2024 refinery decommission). Her legislative priorities mention protecting emergency fleets from costly mandates and energy pragmatism for the Central Valley agriculture economy consistent with maintaining current production levels with existing regulations rather than a ban or expansion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB438', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1418', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Healthcare access is a stated top priority for Hurtado. Voted Aye on SB 729 (2023 IVF and reproductive healthcare insurance coverage) and SB 870 (2023 Medi-Cal rural hospital support). Her legislative priorities website highlights Valley Fever screening and expanding healthcare availability in underserved Central Valley communities reflecting support for expanded coverage and significant access improvements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB870', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted Aye on SB 37 (2023 homelessness support services) in the Senate Human Services committee. No evidence of enforcement-first homelessness policies. Her broader priorities around food security and basic needs for the Central Valley underserved population are consistent with investing in shelter and outreach services as the primary strategy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB37', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted Aye on SB 4 (2023 affordable housing on religious and educational land 34-0) SB 684 (2023 infill housing 34-0) and SB 450 (2024 housing development approvals). Her Central Valley district has severe housing affordability challenges; consistent pattern of supporting expanded affordable housing supply and reduced barriers to development.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB450']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted Aye on SJR 9 (2026 opposing mass immigration raids in California). Her Central Valley district depends heavily on immigrant farmworkers. She consistently voted Aye on immigrant worker protections including SB 686 (2023 domestic workers). This reflects strongly supporting existing immigrant communities and significantly increasing legal pathways consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB686']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted Aye on SB 870 (2023 Medi-Cal rural hospital support and expansion). Healthcare access is a named top priority for her district; her website highlights expanding healthcare availability in the Central Valley and reducing disparities in underserved communities. These reflect significant Medicaid expansion and program improvements for lower-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB870', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted Aye on SB 976 (2024 Protecting Our Kids from Social Media Addiction Act passed 35-2). NVR on SB 243 (2025 companion chatbots regulation). Her priority of holding the powerful accountable includes algorithmic price manipulation oversight suggesting support for targeted regulation of specific harms rather than broad government content mandates consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://sd16.senate.ca.gov/legislative-priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted Aye on SB 314 (2023 redistricting reform 31-7) and SB 1414 (2024 redistricting 36-0). Both bills moved California toward more independent redistricting commission oversight with equal partisan representation consistent with supporting independent commissions to prevent extreme partisan bias.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1414']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted Aye on ACA 5 (2023 California constitutional amendment to enshrine same-sex marriage recognition and full state benefits and protections passed 31-3 in Senate). No evidence of any opposition to same-sex marriage equality or carve-outs for organizations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '00b95a6a-75db-4521-b523-3326bba938de', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Voted Aye on SB 494 (2023 charter school accountability and restrictions on voucher-like diversions of public school funds passed 32-0). Her Central Valley district has significant public school funding needs. The Aye vote on accountability requirements while restricting private fund diversions reflects prioritizing public school funding while restricting vouchers to accountable programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB494']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Voted NO on SJR 7 (2023-24 session anti-tariff resolution) — a cross-caucus position for a Central Valley Democrat whose agricultural district could benefit from some trade protections. Later voted Aye on SJR 7 (2025-26 anti-Trump blanket tariff resolution passed 26 Ayes Jul 2025). The pattern reflects opposition to broad uniform tariffs while retaining support for selective protections for key industries like agriculture consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SJR7', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted Aye on AB 1955 (2024 prohibiting schools from outing transgender students passed 29-8) and Aye on SB 107 (2023 transgender youth healthcare protections). No bills authored or votes found supporting bans on transgender athlete participation. Consistent with allowing transgender athletes to compete on teams matching their gender identity after documentation of transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Melissa Hurtado / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted Aye on SB 1174 (2024 legislation prohibiting local governments from imposing voter ID requirements on state and federal elections passed Senate floor vote). This reflects expanding access to voting and opposing strict photo ID requirements consistent with making mail-in voting available without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$McGuire voted Aye on SB 385 (2023) expanding physician assistant scope to perform aspiration abortions and Aye on SB 729 (2023) requiring health insurance coverage for IVF and infertility treatments. He authored SB 669 (2025) protecting rural hospital perinatal services. His record reflects strong support for legal abortion access consistent with keeping abortion legal and accessible through the second trimester.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB385', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB669']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$McGuire voted Aye on SB 1047 (2023-24 Wiener AI safety bill requiring safety testing for frontier models) on 08/29/24 and Aye on SB 53 (2025-26 AI large developers) on 09/13/25 and Aye on SB 243 (2025 companion chatbots regulation). His votes reflect support for basic safety testing before AI release rather than heavy pre-approval regulation or a laissez-faire stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$McGuire authored SB 658 (2023-24 chaptered) requiring gubernatorial candidates to disclose tax returns and voted Aye on SB 1027 (2024) expanding disclosure under the Political Reform Act. His record centers on transparency and disclosure requirements rather than structural limits on corporate donations or public campaign funding.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB658', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$McGuire voted Aye on SB 1112 (2024) on childcare alternative payment programs passing 40-0. His district priorities list healthcare and social services as core focus areas for his rural North Coast district. Record is consistent with significantly expanding subsidies and provider grants for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112', 'https://sd02.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$McGuire voted Aye on SB 403 (2023) adding caste to California anti-discrimination protected classes (31-5 Senate vote) and authored SB 791 (2023-24 chaptered) requiring universities to disclose sexual harassment settlements. He voted Aye on SB 525 (2023) establishing minimum wages for healthcare workers. His record reflects strong civil rights enforcement addressing systemic discrimination.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB791', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$McGuire authored SB 286 (2023 chaptered) developing California offshore wind energy and SB 319 (2023 chaptered) on electricity transmission permitting to accelerate clean energy deployment. He voted Aye on SB 867 (2024 climate bond) and SB 253 (2023 Climate Corporate Data Accountability Act). His authored legislation directly drives rapid clean energy transition consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB286', 'https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB319', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$McGuire voted Aye on SB 57 (2025-26) on 05/28/25 (passed 25-9) requiring data centers to report projected energy demand and assess ratepayer cost impacts before utility approval. This reflects allowing data center development with transparency requirements and energy cost-sharing assessments consistent with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$McGuire voted Aye on SB 831 (2023 chaptered) providing immigration parole protections for agricultural workers. No enforcement-supportive immigration bills found in his record. His pattern is consistent with deporting only serious violent offenders while providing legal pathways for long-term residents.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$McGuire authored SB 286 (2023 chaptered) establishing California offshore wind energy to displace fossil fuel generation and SB 319 (2023 chaptered) accelerating clean electricity transmission permitting. He did not author any oil and gas expansion bills. His legislation reflects stopping new fossil fuel permits and shifting to renewables consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB286', 'https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB319']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McGuire voted Aye on SB 525 (2023) setting minimum wages for healthcare workers and SB 729 (2023) requiring IVF and fertility insurance coverage and SB 339 (2024) mandating HIV PrEP/PEP coverage. He authored SB 669 (2025 chaptered) protecting rural hospital perinatal standby services. His consistent support for coverage expansion and mandates aligns with a public option or expanded access approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB669']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$McGuire voted Aye on SB 43 (2023) addressing behavioral health services for homeless individuals. Wikipedia reports that as Senate President pro Tempore he selected committee chairs who opposed dense apartment buildings near transit hubs suggesting a moderate approach. His record is consistent with improving current programs while controlling costs rather than aggressive expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Mike_McGuire_(politician)', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB43']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McGuire authored SB 1187 (2023-24 chaptered) on Tribal Housing Reconstitution and voted Aye on SB 7 (2023 regional housing need) and SB 450 (2023 housing approvals). However he recorded NVR on SB 4 (housing near colleges) and Wikipedia reports he placed committee chairs opposing high-density transit-adjacent housing as Senate Pro Tempore. His record reflects targeted housing investment without broad upzoning.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB1187', 'https://en.wikipedia.org/wiki/Mike_McGuire_(politician)', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$McGuire voted Aye on SB 831 (2023 chaptered) providing immigration parole for agricultural workers seeking legal status. His North Coast district has large immigrant farming communities. No restrictive immigration bills authored. Record is consistent with significantly expanding protections and legal pathways.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB831']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$McGuire voted Aye on SB 525 (2023) raising wages for healthcare workers funded partly through Medi-Cal and authored SB 669 (2025 chaptered) preserving rural hospital perinatal services serving primarily Medi-Cal patients. His district priorities list healthcare access as a core focus for his rural North Coast district. Record consistent with expanding Medicaid and lowering Medicare eligibility age.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB669', 'https://sd02.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$McGuire voted Aye on SB 976 (2024) addressing social media platform design and addictive algorithms requiring platforms to implement transparency measures around algorithmic content promotion to minors (passed 35-0). This reflects support for mandating fact-checking and transparency in how platforms promote content consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$McGuire voted Aye on SB 314 (2023) establishing a Sacramento County Redistricting Commission with independent and balanced bipartisan representation. His support for independent redistricting commissions with equal party representation is consistent with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$McGuire voted Aye on ACA 5 (July 5 2023) in the Senate Elections and Constitutional Amendments Committee supporting a California constitutional amendment to enshrine marriage equality and provide full state benefits and protections to same-sex couples. Supporting a constitutional amendment requiring recognition of same-sex marriage reflects the strongest possible stance consistent with value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', '683c8084-2281-4920-a07c-18439b2dd413',
        $$McGuire voted Aye on SJR 7 (2025-26 Senate floor 07/17/25) condemning the Trump administration sweeping tariff policy as harmful to California agriculture and trade. The resolution opposed broad blanket tariffs while not calling for elimination of all trade protections consistent with selective use of tariffs to protect key industries.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$McGuire authored SB 946 (2023-24 chaptered) providing wildfire mitigation tax relief for rural property owners and SB 658 (2023-24) extending tax disclosure requirements for candidates. As Senate Pro Tempore and a mainstream California Democrat his record reflects support for modest progressive taxation favoring higher rates on high earners while maintaining current rates for the middle class.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB946', 'https://leginfo.legislature.ca.gov/faces/billStatusClient.xhtml?bill_id=202320240SB658']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$McGuire voted Aye on AB 1955 (2024) protecting transgender students from being forcibly outed by school staff and Aye on SB 107 (2023) protecting transgender youth access to gender-affirming healthcare. No authored bills restricting trans athlete participation found. His consistent support for transgender rights reflects a stance of allowing trans athletes to compete consistent with their gender identity after completing transition documentation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mike McGuire / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('974bfe8b-afb8-424c-bfd2-7805f033b1a0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$McGuire voted Aye on SB 1174 (2024) prohibiting local jurisdictions from requiring photo identification to vote passing 30-0 among Democrats. This reflects strong support for expanded voting access and removing ID barriers consistent with making mail-in voting available to all voters without requiring an excuse.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Limón authored SB 421 (cancer treatment coverage, 2023) and SB 496 (biomarker testing coverage) expanding healthcare access, and voted Aye on SB 729 (2024, IVF/fertility coverage). No restrictive reproductive bills; consistent with keeping abortion legal and accessible through second trimester and beyond in line with the California mainstream Democratic caucus.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB421']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Limón voted Aye on SB 1047 (Safe and Secure Innovation for Frontier AI, May 2024) and Aye on SB 53 (AI large developers regulation, Sep 2025). She supports safety testing requirements before AI systems are deployed publicly, aligning with value 3, but has not authored primary AI legislation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Limón voted Aye on SB 1027 (2024, Political Reform Act disclosures for AI-generated political ads) and authored SB 702 (gubernatorial appointments transparency). Her record emphasizes transparency and disclosure requirements rather than hard limits on corporate donations or public financing.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB702']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Limón authored SB 533 (childcare tax credit, 2023), SB 380 (childcare provider reimbursement reform, 2024), and SB 778 (Migrant Childcare and Development Programs, chaptered Sep 2025). Her multi-year authorship record reflects significant expansion of subsidies and provider grants to make childcare affordable for low- and middle-income families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB778', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB380', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB533']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Limón voted Aye on SB 403 (Sep 2023, adding caste to anti-discrimination protections in civil rights law, 31-5). Consistent record of strengthening civil rights enforcement through her legislative work on labor, healthcare access, and anti-discrimination measures.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Limón authored SB 840 (Greenhouse Gas Reduction Fund studies, chaptered Sep 2025), SB 1036 (voluntary carbon offsets regulation, 2024), and SB 1101/SB 675 (prescribed fire and grazing for wildfire prevention). She voted Aye on SB 867 (2024 climate bond) and SB 253 (2023 corporate climate disclosure). Her authorship reflects rapid transition to clean energy and reduced fossil fuel reliance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB840', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Limón voted Aye on SB 57 (2025, data center energy demand transparency and ratepayer impact assessments, final passage Sep 2025). Her authorship of SB 840 (Greenhouse Gas Reduction Fund) and energy storage bills reflects allowing data center development with impact assessments and community benefit requirements before approval.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB57', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$In January 2026 Limón participated in a Senate package titled Stand Up Speak Out protecting California from ICE, and issued a statement on ICE aggressive tactics against a U.S. citizen (Oct 2025). She authored SB 778 (Migrant Childcare, 2025). Her record indicates she would deport only immigrants who commit serious violent crimes while providing legal status to others.$$,
        ARRAY['https://sd21.senate.ca.gov/news/issues/immigration', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB778']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Limón authored SB 567 (gravity-based energy storage pilot, chaptered Sep 2025), SB 1433 (gravity energy storage wells), and SB 47 (abandoned oil well plugging funding, 2022). She voted Aye on SB 867 (2024 climate bond). Her legislative pattern reflects stopping new fossil fuel permits and redirecting investment to renewables.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB567', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB867']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Limón authored SB 421 (cancer treatment coverage, chaptered 2023), SB 496 (biomarker testing prior authorization removal), SB 48 (Medi-Cal cognitive health assessments), SB 280 (large group health insurance coverage), and SB 1061 (medical debt credit reporting removal, 2024). Her record consistently expands coverage through a regulated public-private system, aligning with a public option alongside private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB421', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1061', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB496']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Limón authored SB 584 (Laborforce Housing Fund, 2023) and voted Aye on SB 684 (housing streamline, unanimous 37-0). She backed SB 827 (high-transit housing production) per Wikipedia. Her approach focuses on building affordable units and expanding services as the primary strategy to reduce homelessness.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://en.wikipedia.org/wiki/Monique_Lim%C3%B3n']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Limón voted Aye on SB 684 (2023, streamline small housing approval, 37-0) and authored SB 507 (tribal RHNA participation, 2025). Wikipedia confirms she backed SB 827 (transit-oriented housing density) and SB 676 (wildfire community rebuilding). Legislative record supports building millions of affordable units, with one noted local-project contradiction in 2025.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://sd21.senate.ca.gov/legislation', 'https://en.wikipedia.org/wiki/Monique_Lim%C3%B3n']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Limón authored SB 778 (Migrant Childcare and Development Programs, chaptered Sep 2025) and participated in a Jan 2026 Senate package protecting California from ICE enforcement. Her statements opposing ICE aggressive tactics and legislation expanding services for migrant families reflect support for significantly increased legal immigration pathways.$$,
        ARRAY['https://sd21.senate.ca.gov/news/issues/immigration', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB778']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Limón authored SB 48 (Medi-Cal cognitive health assessments), SB 1220 (public benefits human service workers, 2024), and SB 1061 (medical debt credit reporting removal, 2024). Her consistent Medi-Cal expansion bills and public benefits protection legislation align with significantly expanding Medicaid coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1220', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1061']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Limón voted Aye on SB 976 (2024, Protecting Our Kids from Social Media Addiction Act) and Aye on SB 1027 (2024, political disclosure for AI-generated campaign content). Her bills address transparency and targeted harms rather than broad government platform censorship, consistent with encouraging voluntary standards with targeted disclosure requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB976', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1027']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Limón voted Aye on SB 314 (Sep 2023, Sacramento County Redistricting Commission reform, 31-7). Her vote for independent redistricting commissions and Democratic caucus alignment on fair election reform reflects support for independent commissions with equal party representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB314']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Limón voted Aye on ACA 5 (Jul 2023, marriage equality constitutional amendment to enshrine same-sex marriage rights in the California constitution, 31-0 in the Senate). Her vote affirms requiring full state recognition of same-sex marriages with complete legal benefits and protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Limón authored SB 737 (California Student Opportunity Program Modernization, 2022), SB 1094 (Civic Education Seal, 2024), and SB 1195 (Advanced Placement scheduling, 2024), all targeting public school investment. No voucher support or private school funding bills authored across her entire legislative record, reflecting fully funding public schools and opposing diversion of taxpayer money to private institutions.$$,
        ARRAY['https://sd21.senate.ca.gov/legislation', 'https://en.wikipedia.org/wiki/Monique_Lim%C3%B3n']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Limón voted Aye on SJR 7 (Jul 2025, resolution opposing Trump blanket tariffs, 26-9). The resolution calls for selective rather than across-the-board tariffs, reflecting support for using tariffs to protect key American industries from unfair trade while opposing indiscriminate import levies.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SJR7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Limón authored SB 533 (childcare income tax credit, 2023) and SB 497 (public benefits account protections, 2022). Her targeted tax credits for working families and consistent Medi-Cal and public benefits expansion reflect modestly increasing taxes on high earners while maintaining current rates for middle-class families.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB533']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Limón voted Aye on SB 107 (Mar 2023, transgender healthcare protections, 29-8). She recorded NVR on AB 1955 (Jun 2024, parental notification ban) but her affirmative SB 107 vote reflects consistent support for transgender protections. Her overall record aligns with allowing transgender athletes to compete on teams matching their gender identity after basic documentation of transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Monique Limón / voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c7a56941-597a-456b-8fd8-e4bd840014c1', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Limón authored SB 846 (Motor Voter Enhancement, 2023) and SB 299 (voter registration enhancement, 2024) — the latter vetoed by Governor Newsom only for cost reasons. She voted Aye on SB 1174 (May 2024, opposing strict voter ID requirements, 30-8). Her record reflects expanding early voting periods and making voter registration broadly accessible without ID barriers.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://en.wikipedia.org/wiki/Monique_Lim%C3%B3n']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;