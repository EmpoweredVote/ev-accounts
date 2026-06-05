-- ============================================================================
-- Migration 219: Fremont Officials Stances — 7 Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data for 7 Fremont city officials.
--
-- Politicians: Raj Salwan (Mayor), Desrie Campbell (D1), Kathy Kimberlin (D3),
--              Raymond Liu (D2), Teresa Keng (D6), Yajing Zhang (D5), Yang Shao (D4)
--
-- Stance count: 56 rows (politician_answers + politician_context)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- city-sanitation          7687de4f-4d0b-462a-b803-bdfb23b16b42
-- climate-change           f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers             4559b513-0fd8-4ed1-babd-f3b554162f40
-- economic-development     eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels             a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development   fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- homelessness             4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response    6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                  669cac97-66a6-4087-b036-936fbe62efb3
-- local-environment        1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration        b9ccee94-ad96-4f10-b655-889d8e5abe92
-- public-safety-approach   e9ebefcd-c496-45e8-b816-a79f8442ba85
-- residential-zoning       d4f18138-a2e0-4110-b925-7387d9d0d16d
-- transportation-priorities ba59337e-30e2-4aba-a39a-426b3366eb27

-- Politician UUID reference (essentials.politicians):
-- Raj Salwan       71124b00-549d-460c-8f84-41a01d99e037
-- Desrie Campbell  28839e39-6db1-4253-94a4-94ae234c241e
-- Kathy Kimberlin  f886f6da-d08f-4294-81bc-faf4a1eaad4d
-- Raymond Liu      42e95c4c-4e02-4d60-805c-6a3d857dd95a
-- Teresa Keng      fecd31b9-fc2e-4d90-80f2-15ac89fb0eff
-- Yajing Zhang     d6d492b6-cbaf-4398-9301-4fbd10da571f
-- Yang Shao        7db82a3d-5aa2-4150-996e-b170b50b47fe

BEGIN;

-- ============================================================
-- Raj Salwan (Mayor)
-- ============================================================

-- ----- Raj Salwan / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Voted for a Fremont encampment ordinance in February 2025 addressing fire-prone public-space encampments, framing it as a public safety measure while continuing outreach and shelter access. The council unanimously removed a controversial aiding-or-abetting clause in March 2025 after community backlash, showing openness to limits on punitive enforcement. The approach prioritizes enforcement with baseline outreach rather than decriminalization.$$,
ARRAY['https://en.wikipedia.org/wiki/Raj_Salwan', 'https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Campaign priorities call for working collaboratively with community organizations, developing affordable housing options, and providing support services for people experiencing homelessness, including dedicated mental health and addiction services. Simultaneously supports the MET program pairing mental health experts, social workers, and police officers on crisis calls. Blends enforcement (encampment ordinance) with services and outreach, aligning with a middle-ground invest-in-services-while-enforcing-reasonable-rules approach.$$,
ARRAY['https://rajsalwan.com/priorities', 'https://en.wikipedia.org/wiki/Raj_Salwan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Salwan's stated vision is for every Fremont resident to have access to an affordable home, and his campaign platform includes developing affordable housing options as part of his homelessness response. As council member he championed the Innovation District in Warm Springs to bring jobs, which includes mixed-use development elements. The campaign site frames affordable housing as a core community need requiring proactive government action, suggesting support for expanding affordable units.$$,
ARRAY['https://rajsalwan.com/priorities', 'https://rajsalwan.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$No direct vote record is accessible for Fremont zoning decisions. Campaign platform supports affordable housing development and economic growth through the Innovation District (which includes mixed-use/commercial zoning) without explicit opposition to density. As a consensus-builder focused on quality of life and neighborhood improvement, the available evidence suggests a balanced approach allowing density near commercial corridors while managing neighborhood impacts rather than either blocking all density or upzoning broadly.$$,
ARRAY['https://rajsalwan.com/about', 'https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Salwan emphasizes strengthening law enforcement partnerships and community policing, while also proposing to expand the MET program which pairs mental health experts, social workers, and police officers on crisis and homelessness calls. This co-responder model represents adding crisis response capacity alongside current police staffing rather than either defunding or dramatically expanding the police budget. He describes it as a balanced public safety investment.$$,
ARRAY['https://rajsalwan.com/priorities', 'https://rajsalwan.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Salwan championed the Warm Springs Innovation District, directly attracting major employers Tesla, Seagate, and Lam Research to Fremont with significant city support. His campaign platform prioritizes job creation, small business support, and sustainable growth. The Innovation District approach reflects active city recruitment of large employers with incentives and streamlined support, and he lists economic development as a top priority alongside public safety.$$,
ARRAY['https://rajsalwan.com/about', 'https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$As a city council member Salwan reduced traffic congestion by 33% and implemented modern signal timing and citywide cut-through traffic reduction strategies. He served as an alternate on the Alameda County Transportation Commission and voted on freeway interchange improvements. His approach focuses on road infrastructure and congestion management rather than explicit multimodal or transit-first investment, while also noting openness to innovative transit options.$$,
ARRAY['https://rajsalwan.com/priorities', 'https://rajsalwan.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Campaign platform explicitly commits to achieving net-zero emissions by 2045 or sooner, with a 55% greenhouse gas reduction target by 2030 or sooner — targets more aggressive than baseline state requirements. Salwan lists climate as a distinct priority on his campaign site. This reflects a rapid clean-energy transition stance with firm interim targets, aligning with investing in clean energy while phasing down fossil fuel reliance.$$,
ARRAY['https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$No specific votes on development-versus-environment tradeoffs are accessible. Salwan's platform commits to sustainable growth and balancing innovation with environmental responsibility. His Innovation District work brought in clean technology companies like Seagate and Tesla rather than heavy polluters. The available evidence suggests applying consistent environmental standards while giving reasonable flexibility to developers, without either strict preservation requirements or removing environmental review.$$,
ARRAY['https://rajsalwan.com/priorities', 'https://rajsalwan.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Salwan supports sustainable growth and proactive investment in infrastructure to support Fremont's development. His Innovation District initiative attracted major employers and supported expanded commercial/industrial development. Campaign platform calls for smart growth prioritizing commuter efficiency. This reflects planning proactively and investing in infrastructure ahead of growth rather than either imposing growth limits or removing all regulatory barriers.$$,
ARRAY['https://rajsalwan.com/about', 'https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Campaign platform identifies street cleanup, improving neighborhoods and commercial districts, and maintaining public facilities as explicit priorities. Salwan lists clean streets as a quality-of-life issue he intends to address. No evidence of a significantly expanded sanitation staffing plan or privatization stance. The approach suggests maintaining and improving current sanitation services with enforcement of anti-dumping laws as the primary tool.$$,
ARRAY['https://rajsalwan.com/priorities']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raj Salwan / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '4559b513-0fd8-4ed1-babd-f3b554162f40', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('71124b00-549d-460c-8f84-41a01d99e037', '4559b513-0fd8-4ed1-babd-f3b554162f40',
$$As mayor and the champion who founded Fremont's Warm Springs Innovation District, Salwan welcomed rapid lease-up of the Fremont Technology Center by 'leading companies in AI hardware and electric vehicle manufacturing,' stating it 'affirms Fremont's role as a premier hub for advanced industries in Silicon Valley.' The city unanimously approved rezoning for advanced manufacturing facilities. His stated economic priority is attracting and retaining technology employers with business-friendly, pro-growth leadership.$$,
ARRAY['https://www.tricityvoice.com/fremont-technology-center-hits-milestone-with-lease/', 'https://rajsalwan.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Desrie Campbell (District 1)
-- ============================================================

-- ----- Desrie Campbell / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Campbell hosted a public town hall in August 2025 on Fremont's Homeless Response Plan, emphasizing that community engagement is critical to serving the city's most vulnerable residents. She also asked during the March 2026 emergency shelter crisis declaration whether the Winter Relief program could be extended, indicating support for shelter capacity alongside enforcement. The council voted 6-1 to ban encampments in February 2025 (individual dissenter not identified), and Campbell's documented positions show she voted with the majority while also advocating for sustained shelter services.$$,
ARRAY['https://www.tricityvoice.com/desrie-campbell-hosts-town-hall-on-homelessness/', 'https://www.tricityvoice.com/fremont-declares-emergency-shelter-crisis/', 'https://www.tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Desrie Campbell / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Campbell's town hall (August 2025) convened expert panelists including the CEO of Abode Services and former city officials to discuss outreach strategies, framing her approach as investing in services that reflect community values. During the March 2026 shelter crisis meeting she thanked outreach workers for doing hard work with grace and compassion, and asked to explore extending the Winter Relief program. This pattern — enforcement accepted, shelter expansion actively sought — aligns with investing in outreach and shelter while enforcing reasonable public space rules.$$,
ARRAY['https://www.tricityvoice.com/desrie-campbell-hosts-town-hall-on-homelessness/', 'https://www.tricityvoice.com/fremont-declares-emergency-shelter-crisis/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Desrie Campbell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Campbell voted unanimously with the council in July 2024 to fund a $1.75 million police department chillers replacement project and supported the FY 2025-26 budget that included hiring over 40 sworn police officers in 18 months. In May 2026 she asked a clarifying safety question about police military equipment (baffled gas canisters) rather than opposing acquisition, suggesting neither opposition to police resourcing nor a push for major expansion. Evidence supports current public safety funding with incremental service improvements.$$,
ARRAY['https://www.tricityvoice.com/fremont-city-council/', 'https://www.tricityvoice.com/fremont-approves-annual-police-military-equipment-list/', 'https://www.tricityvoice.com/fremont-adopts-balanced-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Desrie Campbell / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Campbell voted unanimously with the council in July 2024 to accept a $4.1 million Metropolitan Transportation Commission grant for street projects along Fremont Boulevard, and supported the FY 2025-26 budget which included over $1 billion in downtown mixed-use development. No evidence of specific large corporate incentive advocacy or opposition; the available record reflects support for infrastructure-linked development with community benefit elements.$$,
ARRAY['https://www.tricityvoice.com/fremont-city-council/', 'https://www.tricityvoice.com/economic-momentum-shows-in-fremonts-state-of-the-city-address/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Desrie Campbell / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Voted unanimously with the council in July 2024 to accept a $4.1 million Metropolitan Transportation Commission grant for street projects along Fremont Boulevard. No evidence of specific multi-modal, transit-first, or highway-priority positions; the available record reflects support for road infrastructure improvements and maintenance funding consistent with a balanced approach.$$,
ARRAY['https://www.tricityvoice.com/fremont-city-council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Desrie Campbell / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('28839e39-6db1-4253-94a4-94ae234c241e', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Campbell voted unanimously with the council on infrastructure and development contracts in July 2024, and the council's FY 2025-26 budget reflects proactive planning including fire station expansion and downtown investment. No evidence of growth-limit advocacy or deregulatory push; the available record is consistent with allowing growth where infrastructure supports it, which reflects the council majority's approach.$$,
ARRAY['https://www.tricityvoice.com/fremont-city-council/', 'https://www.tricityvoice.com/fremont-adopts-balanced-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Kathy Kimberlin (District 3)
-- ============================================================

-- ----- Kathy Kimberlin / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Kimberlin voted with a 6-1 council majority to pass Fremont's encampment ban in February 2025, maintaining a prohibition on camping on public property with fines and potential jail time. She subsequently spearheaded a March 2025 amendment to clarify that nonprofits and faith-based organizations providing food, water, and warmth would not face criminal penalties — but the underlying ban remained intact. Her approach is enforcement-primary while protecting basic humanitarian aid provision.$$,
ARRAY['https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/', 'https://tricityvoice.com/fremont-amends-camping-ordinance/', 'https://tricityvoice.com/fremont-residents-say-ban-revision-falls-short/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Kimberlin jointly referred the March 2025 amendment with Mayor Salwan to remove the encampment ban's 'aiding and abetting' clause, stating: 'We need to ensure that those who are helping our unhoused neighbors are not penalized for their compassion.' Her campaign platform lists wraparound services, food, shelter, and social services for unhoused neighbors as priorities. She supports allowing enforcement when adequate services are available while actively protecting outreach organizations from criminalization.$$,
ARRAY['https://tricityvoice.com/fremont-amends-camping-ordinance/', 'https://tricityvoice.com/fremont-residents-say-ban-revision-falls-short/', 'https://www.kathykimberlin.com/community']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Campaign platform explicitly lists 'Affordable housing action' as a stated priority, and she supports 'developing affordable housing options' as part of her homelessness response. Kimberlin ran on ensuring Fremont remains accessible to residents and families, and her community page references support for services providing unhoused neighbors with shelter and wraparound resources. The emphasis on proactive affordable housing investment rather than market-only solutions aligns with significantly expanding subsidies and affordable units.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://www.kathykimberlin.com/community']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Public safety is listed as a top campaign priority; Kimberlin co-founded the Tri-City Nonprofit Coalition and worked on police-community partnerships through the Chamber of Commerce Government Affairs Committee. The city's December 2024 $100,000 police hiring bonus passed with council support. No evidence of calls to defund police or dramatically expand the police budget; the available record is consistent with keeping current public safety funding while adding co-response capacity for social service calls.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://tricityvoice.com/fremont-appoints-new-city-council-member/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Kimberlin's campaign emphasizes bringing jobs to Fremont, supporting small businesses and nonprofits, and fostering economic development through collaboration with the Centerville Business and Community Association and Chamber of Commerce. She co-founded the Tri-City Nonprofit Coalition in 2020 and served on the Chamber's Government Affairs Committee. Evidence reflects targeted support for local businesses and job creation rather than maximum corporate tax abatements or ideological opposition to incentives.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://tricityvoice.com/fremont-appoints-new-city-council-member/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Campaign platform calls for 'Smart growth' and community development alongside public safety improvements. Kimberlin's background in the Chamber of Commerce and economic development suggests support for proactive infrastructure investment to support responsible growth. No evidence of growth-limit advocacy or calls to remove regulatory barriers entirely; the platform language reflects planning ahead for infrastructure needs while managing quality-of-life impacts.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://www.kathykimberlin.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Campaign emphasizes affordable housing action and smart growth without specifying density positions. As a council member in District 3 (Centerville area), Kimberlin has not produced a public record of votes on specific zoning changes during her short appointed term. Her support for affordable housing investment and smart growth suggests openness to density increases near commercial corridors while protecting existing residential neighborhoods — consistent with the Fremont council majority's approach.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://tricityvoice.com/fremont-appoints-new-city-council-member/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathy Kimberlin / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f886f6da-d08f-4294-81bc-faf4a1eaad4d', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Campaign platform explicitly names 'Blight reduction' — particularly in the Centerville commercial district — as a named priority for Kimberlin. This enforcement-oriented framing focuses on holding property owners and businesses responsible for maintaining clean storefronts and public spaces. No evidence of a major sanitation staffing expansion plan; the blight-reduction priority aligns primarily with enforcement of anti-littering and property maintenance laws.$$,
ARRAY['https://www.kathykimberlin.com/priorities', 'https://tricityvoice.com/fremont-appoints-new-city-council-member/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Raymond Liu (District 2)
-- ============================================================

-- ----- Raymond Liu / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Liu voted YES in December 2024 on a Fremont ordinance allowing removal of personal property left on public spaces, alongside Mayor Salwan, Zhang, and Shao (Kimberlin and Campbell voted against). He was also part of the 6-1 council majority that passed the February 11 2025 camping/encampment ban on public property. His voting pattern consistently aligns with the enforcement-primary approach on homelessness.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raymond Liu / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Liu voted YES on the December 2024 property-removal ordinance and was part of the 6-1 majority approving the February 2025 encampment ban. His recorded votes support enforcement tools as the primary municipal response to homelessness. No evidence of statements supporting shelter expansion or outreach-first alternatives comparable to Campbell or Kimberlin's positions.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raymond Liu / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Liu voted YES on the December 2024 ordinance to remove personal property from public spaces, framed by Mayor Salwan as a public safety measure; the council that session also approved a $100,000 police lateral hiring bonus. His voting record with the pro-enforcement majority (Salwan, Zhang, Shao) on homelessness-related public-space ordinances suggests support for increasing police capacity and enforcement tools as a primary public safety strategy.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/city-of-fremont-announces-100000-hiring-bonus-for-lateral-police-officers/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raymond Liu / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Liu voted YES on the December 2024 ordinance allowing Fremont to remove unattended personal property from public spaces (streets, parks, waterways) after 24 hours, a measure framed as a cleanliness and public safety initiative. This is the strongest direct evidence of his city-sanitation stance — enforcement of anti-dumping and public-space maintenance laws as the primary tool.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Raymond Liu / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('42e95c4c-4e02-4d60-805c-6a3d857dd95a', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$In September 2025 and January 2026 council discussions on California's Daylighting Law, Liu advocated for a proactive pedestrian safety pilot program, suggesting red curb painting near schools would be 'a good trial run' — indicating pragmatic support for pedestrian safety infrastructure while not endorsing broader transit or cycling investment.$$,
ARRAY['https://www.tricityvoice.com/community-member-requests-to-paint-curb-red/', 'https://www.tricityvoice.com/fremont-continues-red-curbs-discussion/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Teresa Keng (District 6)
-- ============================================================

-- ----- Teresa Keng / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Voted with the 6-1 council majority to pass Fremont's homeless encampment ban on February 11, 2025, prohibiting camping and storage of personal property in public spaces. She also voted with the majority on a December 2024 property-removal ordinance that preceded the camping ban, and supported the March 2025 amendment that removed the aiding-and-abetting clause while keeping the ban intact. Her votes indicate a primary enforcement posture on visible homelessness.$$,
ARRAY['https://www.tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/', 'https://www.tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://www.tricityvoice.com/fremont-amends-camping-ordinance/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$In March 2026 Keng was quoted expressing concern about delayed Measure W funding for homeless services: 'Our taxpayers have paid towards Measure W and we have this huge need.' This suggests she supports investing in shelter and services alongside enforcement rather than relying on enforcement alone. While she voted for the camping ban, her public frustration about unfunded services signals support for a balanced invest-in-services-while-enforcing-rules approach.$$,
ARRAY['https://www.tricityvoice.com/fremont-declares-emergency-shelter-crisis/', 'https://www.tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Voted unanimously on routine consent items in July 2024 including police department equipment upgrades. Supported the city's FY2025-26 budget that funded 40+ new police officers and a new fire truck company. No evidence of defunding advocacy or calls for major police expansion beyond standard budget support. The available record is consistent with maintaining current public safety funding while adding crisis response components (MET co-responder program) rather than either defunding or dramatically expanding the police budget.$$,
ARRAY['https://www.tricityvoice.com/fremont-city-council/', 'https://www.tricityvoice.com/fremont-adopts-balanced-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$In February 2025 Keng publicly questioned whether Fremont's proposed 'Fremont-First' policy of neutrality on international affairs would restrict charitable initiatives, citing a 2021 fundraiser for Afghan refugees. Her concern was that the neutrality policy might obstruct humanitarian support for immigrant communities. This signals she is protective of city resources and charitable capacity for immigrant communities, aligning with a comply-with-federal-law-but-protect-undocumented-crime-victims approach rather than proactive enforcement or full sanctuary status.$$,
ARRAY['https://www.tricityvoice.com/fremont-narrows-focus-to-local-matters/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted unanimously with the full Fremont City Council on June 18 2024 to request Ava Community Energy switch Fremont's default electricity to the Renewable 100 plan consisting of 100% solar and wind energy. Also voted unanimously on December 3 2024 to adopt a Power Purchase Agreement with Ava Community Energy to install solar panels and battery storage at six municipal facilities with no upfront cost.$$,
ARRAY['https://tricityvoice.com/fremont-transitioning-to-100-renewable-energy/', 'https://tricityvoice.com/fremont-advances-green-goals/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Supported Fremont's unanimous June 2024 transition to 100% renewable electricity via Ava Community Energy and the December 2024 solar PPA adding onsite generation at city facilities. These votes represent a consistent council posture of moving away from fossil-fuel-sourced grid power toward renewables rather than expanding extraction.$$,
ARRAY['https://tricityvoice.com/fremont-transitioning-to-100-renewable-energy/', 'https://tricityvoice.com/fremont-advances-green-goals/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$Voted unanimously June 2024 for 100% renewable electricity and December 2024 for a solar and battery storage Power Purchase Agreement at city facilities. These green energy actions align with Fremont's 2023 Climate Action Plan targeting a 30% reduction in greenhouse gas emissions by 2030.$$,
ARRAY['https://tricityvoice.com/fremont-transitioning-to-100-renewable-energy/', 'https://tricityvoice.com/fremont-advances-green-goals/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Voted yes as part of the unanimous consent agenda on July 16 2024 to accept a $4.098 million grant from the Metropolitan Transportation Commission for Complete Streets Projects along Fremont Boulevard, which supports pedestrian and multimodal improvements. No evidence of opposition to transit or bike infrastructure.$$,
ARRAY['https://tricityvoice.com/fremont-city-council/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teresa Keng / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fecd31b9-fc2e-4d90-80f2-15ac89fb0eff', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Voted yes on the unanimous community center approval ($35.5M at Central Park) and supported renewable energy infrastructure investments. No evidence of growth restrictions or strong pro-density advocacy — consistent with moderate managed growth posture.$$,
ARRAY['https://tricityvoice.com/fremont-city-council-approves-new-community-center/', 'https://tricityvoice.com/fremont-moves-forward-with-charter-city-plans/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Yajing Zhang (District 5)
-- ============================================================

-- ----- Yajing Zhang / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Voted YES on December 17 2024 property-removal ordinance authorizing police to remove personal belongings from public spaces after 24 hours, and was part of the 6-1 majority that passed the citywide camping/encampment ban on February 11 2025. Both votes favor enforcement-first responses over shelter or service investment.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Supported the December 2024 property-removal ordinance and February 2025 camping ban without recorded calls for expanded shelter or service alternatives, contrasting with Campbell who explicitly argued for shelter beds instead. Zhang's votes align with an enforcement-and-compliance posture rather than a service-first or housing-first framework.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Campaign platform listed public safety as a top priority; while on the FUSD school board she reinstated the School Resource Officer program. As a council member she voted to approve a $874,151 contract for a Real Time Information Center at the Fremont Police Department (June 17 2025) and backed the $100,000 lateral officer hiring bonus program. No evidence of redirecting police funding to social services.$$,
ARRAY['https://tricityvoice.com/new-fremont-center-aims-to-improve-policing/', 'https://tricityvoice.com/2024-general-elections-candidates/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Voted for the December 2024 ordinance authorizing removal of personal property from public spaces including parks, streets, and waterways after 24 hours — a measure that functions as a public-space cleanliness and order enforcement tool. Supported the February 2025 camping ban which also restricts public camping paraphernalia.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Campaign platform listed affordable housing expansion as a priority alongside public safety and supporting small businesses. However, her recorded council votes on homelessness have favored enforcement over housing investment, suggesting a market-oriented rather than strongly government-interventionist housing stance.$$,
ARRAY['https://tricityvoice.com/2024-general-elections-candidates/', 'https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Campaign platform emphasized supporting local small businesses and efficient use of city resources through data-driven problem-solving. As Vice Mayor she championed the charter city proposal citing faster execution speed and accountability for results, signaling a pro-business and streamlined-government orientation.$$,
ARRAY['https://tricityvoice.com/fremont-moves-forward-with-charter-city-plans/', 'https://tricityvoice.com/2024-general-elections-candidates/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yajing Zhang / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6d492b6-cbaf-4398-9301-4fbd10da571f', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Initiated the March 2026 charter city proposal specifically to increase leadership clarity and execution speed at city hall, favoring faster permitting and policy implementation. Her stated goal of reducing bureaucratic friction and improving accountability for results aligns with streamlined development facilitation.$$,
ARRAY['https://tricityvoice.com/fremont-moves-forward-with-charter-city-plans/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Yang Shao (District 4)
-- ============================================================

-- ----- Yang Shao / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '4938766b-b45a-46e3-93bd-b8b30651271a', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Voted YES on the December 2024 property-removal ordinance authorizing removal of personal property left unattended on public spaces for 24+ hours, joining Mayor Salwan, Liu, and Zhang in a 4-2 vote against Campbell and Kimberlin. Also part of the 6-1 majority that passed the February 11, 2025 encampment ban prohibiting camping on public property with penalties up to $1,000 and six months jail.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Consistently voted with the enforcement-first bloc (Salwan, Liu, Zhang) on both the December 2024 property-removal ordinance and the February 2025 encampment ban, prioritizing removal and criminalization of public camping over shelter-first or service-first approaches. No evidence of him championing shelter bed expansion or outreach funding as alternatives.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Voted with the council majority on police equipment approval and enforcement-oriented homelessness ordinances. The Fremont FY2025-26 budget approved $100,000 lateral police signing bonuses and expanded fire services, with council majority (including Shao) backing the public safety spending priorities.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremont-adopts-balanced-budget/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Supported the December 2024 ordinance removing unattended personal property from public spaces and the February 2025 encampment ban, both of which are framed as public-space cleanliness and order measures. Voted with the enforcement-oriented majority on both measures.$$,
ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/', 'https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$In February 2025, Shao proposed a formal policy directing Fremont to focus on local matters and remain neutral on international affairs, explicitly to avoid divisive resolutions. He clarified the policy would not block charitable fundraisers for groups like Afghan refugees, but the city would not take positions on issues outside its jurisdiction. This is a localism posture, not pro-ICE or sanctuary advocacy.$$,
ARRAY['https://tricityvoice.com/fremont-narrows-focus-to-local-matters/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$The Fremont City Council voted unanimously in June 2024 to transition all residential customers to Ava Community Energy's Renewable 100 plan (100% solar and wind), consistent with the city's Climate Action Plan goal of reducing greenhouse gas emissions 30% by 2030. Shao was part of that unanimous council.$$,
ARRAY['https://tricityvoice.com/fremont-transitioning-to-100-renewable-energy/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$As part of the Fremont City Council, Shao participated in unanimous approval of the city's Power Purchase Agreement for 100% renewable energy at municipal facilities and the transition to renewable default for all residential customers under the 2023 Climate Action Plan.$$,
ARRAY['https://tricityvoice.com/fremont-advances-green-goals/', 'https://tricityvoice.com/fremont-transitioning-to-100-renewable-energy/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Voted as part of the Fremont City Council majority on routine economic development items including short-term rental compliance services and fleet procurement. The council's overall direction under Mayor Salwan emphasizes Innovation District development, BART transit-oriented development, and downtown revitalization, with no evidence of Shao taking a dissenting or distinctive position.$$,
ARRAY['https://tricityvoice.com/fremont-city-council/', 'https://tricityvoice.com/economic-momentum-shows-in-fremonts-state-of-the-city-address/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Yang Shao / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7db82a3d-5aa2-4150-996e-b170b50b47fe', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Fremont is actively planning for BART Irvington station expansion and an Active Transportation Plan covering walking, biking, and transit. Shao has voted unanimously with the council on transportation funding including MTC grants and road maintenance. No evidence of him taking a distinctive pro-car or pro-transit individual position.$$,
ARRAY['https://tricityvoice.com/fremont-residents-can-now-view-and-comment-on-transportation-plan/', 'https://tricityvoice.com/officials-pressure-bart-to-apply-for-funding/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
