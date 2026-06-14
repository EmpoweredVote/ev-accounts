-- Phase 117-03: Brockton city official stances
-- 13 stances across 3 officials (9 officials honest-skipped — Enterprise News blocked)
-- Sources: wgbh.org, brockton.ma.us, jeffcharnel.com

-- ============================================================
-- Moises M. Rodrigues (Mayor) — id: 13673e69-91df-4d5b-a6af-36cc577f2487
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  $$Rodrigues made urban cleanliness and code enforcement a centerpiece of his 2025 mayoral campaign, pledging "an aggressive code enforcement initiative" to combat litter and illegal dumping. He stated: "We will hold absentee landlords accountable for maintaining their properties and open spaces." This commitment to increasing enforcement targeted especially at property owners aligns with increasing sanitation enforcement and prioritizing historically neglected neighborhoods.$$,
  ARRAY['https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor', 'https://brockton.ma.us/government/mayors-office/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  $$As a city councillor in 2016 Rodrigues personally introduced the Trust Act to formalize Brockton's existing informal policy of not detaining undocumented immigrants for federal authorities without a criminal warrant. He cited a "severe lack of trust between Brockton's police and its immigrant community" and argued police could not get crime information because immigrants feared reporting crimes. He sought to codify compliance only when there is a criminal warrant — aligning with protecting undocumented crime victims and witnesses while complying only with court-ordered detainers.$$,
  ARRAY['https://www.wgbh.org/news/local/2016-09-21/brockton-debates-becoming-a-sanctuary-city-with-an-informal-policy-to-not-detain-undocumented-immigrants', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  '4e2c69ce-591e-4197-9cd5-7aceff79d390',
  $$Rodrigues, a Cape Verdean immigrant himself and the first Cape Verdean elected to Brockton City Council, introduced the Trust Act as a councillor to protect undocumented immigrants from being detained without criminal warrants. His stated rationale was improving public safety by building trust with immigrant communities so they report crimes. His approach supports immigrants accessing public services regardless of legal status, aligning with keeping legal immigration open and allowing most residents to use public services.$$,
  ARRAY['https://www.wgbh.org/news/local/2016-09-21/brockton-debates-becoming-a-sanctuary-city-with-an-informal-policy-to-not-detain-undocumented-immigrants', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  '44905f3b-e105-4f6c-afc7-5d223813dbac',
  $$Rodrigues introduced the Brockton Trust Act as a city councillor to prevent local police from detaining undocumented immigrants for federal authorities unless there is a criminal warrant. His explicit rationale was that immigrants should not be deported or detained based on immigration status alone. He sought to limit deportation cooperation to cases with criminal warrants, aligning with only deporting people convicted of serious violent crimes.$$,
  ARRAY['https://www.wgbh.org/news/local/2016-09-21/brockton-debates-becoming-a-sanctuary-city-with-an-informal-policy-to-not-detain-undocumented-immigrants']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  $$Rodrigues' official mayoral priorities emphasize community policing alongside social investment: his office page lists "investing in community policing, youth intervention programs, and addressing crime's root causes through outreach and prevention efforts." His campaign platform also included addiction treatment and support centers. This balanced approach — maintaining police presence while adding youth intervention and treatment programs — aligns with keeping current public safety funding while adding crisis response teams for mental health and addiction calls.$$,
  ARRAY['https://brockton.ma.us/government/mayors-office/', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  $$Rodrigues' mayoral platform calls for business incentives to attract companies to Brockton and negotiating a new contract with the city's desalination facility as an economic development priority. His official mayor's page describes a Business Advisory Council to support local entrepreneurs and sustainable development alongside downtown revitalization. This targeted approach — incentives for specific development with community benefit framing and local business focus — aligns with targeted incentives for specific industries with community benefit agreements.$$,
  ARRAY['https://brockton.ma.us/government/mayors-office/', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor', 'https://brockton.ma.us/economic-development/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  $$Rodrigues' campaign platform included addiction treatment and support centers as a public safety and social services priority. The Brockton City Council (of which he was a member) passed a $200 camping ban ordinance in November 2024 (7-4 vote), though Rodrigues was not the lead sponsor — Councillor Thompson championed it. His mayoral priorities emphasize youth intervention and outreach alongside enforcement, aligning with allowing enforcement only when services are offered with citations diverting people to services rather than the criminal justice system.$$,
  ARRAY['https://www.wgbh.org/news/local/2024-11-13/brockton-will-fine-people-200-for-sleeping-outside', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor', 'https://brockton.ma.us/government/mayors-office/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  $$Rodrigues' mayoral platform includes addiction treatment support centers and youth intervention programs, suggesting a services-alongside-enforcement approach. The city under his council tenure passed a camping ban ordinance in November 2024, but his official priorities frame public safety as requiring both community policing and outreach addressing root causes. This evidence points to investing in outreach and mental health services while enforcing reasonable public space rules, aligning with stance 3.$$,
  ARRAY['https://www.wgbh.org/news/local/2024-11-13/brockton-will-fine-people-200-for-sleeping-outside', 'https://brockton.ma.us/government/mayors-office/', 'https://www.wgbh.org/news/politics/2025-11-06/five-things-to-know-about-moises-rodrigues-the-new-brockton-mayor']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  $$Brockton under Rodrigues' tenure proactively complied with the MBTA Communities Act (Form Based Zoning Code adopted by December 2024), implemented a 40R Smart Growth Program for downtown development, and developed Opportunity Zones. Rodrigues' official priority is downtown revitalization while preserving neighborhood character. This proactive infrastructure-investment approach — not imposing growth limits but also not removing all barriers — aligns with planning proactively to invest in infrastructure ahead of growth and support responsible expansion.$$,
  ARRAY['https://brockton.ma.us/city-departments/planning/', 'https://brockton.ma.us/government/mayors-office/', 'https://brockton.ma.us/economic-development/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13673e69-91df-4d5b-a6af-36cc577f2487', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '13673e69-91df-4d5b-a6af-36cc577f2487',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  $$Brockton completed MBTA Communities Act compliance with a Form Based Zoning Code covering Downtown/Trout Brook and Campello/Main Street corridors by December 2024, during Rodrigues' council tenure. Massachusetts law now permits ADUs in all Single Family Residential zones, and Brockton's Planning Department accommodates this. The city also adopted a 40R Smart Growth ordinance. This pattern — allowing multifamily and mixed-use near commercial corridors while protecting most residential zones — aligns with stance 3.$$,
  ARRAY['https://brockton.ma.us/city-departments/planning/', 'https://brockton.ma.us/economic-development/']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jeffrey A. Thompson (Ward 5) — id: 2ac58cbd-f5ac-4c45-93da-dec32b26f437
-- ============================================================

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ac58cbd-f5ac-4c45-93da-dec32b26f437', '4938766b-b45a-46e3-93bd-b8b30651271a', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2ac58cbd-f5ac-4c45-93da-dec32b26f437',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  $$Thompson voted yes on the November 2024 Brockton camping ordinance (passed 7-4) that imposes a $200 fine for sleeping outside, relying on the Supreme Court's Grants Pass decision. He argued "Our residents are fearful when they walk by an encampment" and that the ordinance was needed to restore order in commercial areas. The ordinance carries no formal shelter-availability prerequisite before enforcement, though Thompson stated it would be "enforced humanely and respectfully." This aligns with prohibiting encampments on public property with graduated warnings while requiring jurisdictions to maintain basic shelter options.$$,
  ARRAY['https://www.wgbh.org/news/local/2024-11-13/brockton-will-fine-people-200-for-sleeping-outside']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2ac58cbd-f5ac-4c45-93da-dec32b26f437', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '2ac58cbd-f5ac-4c45-93da-dec32b26f437',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  $$Thompson was a leading advocate for Brockton's November 2024 camping ban (7-4 vote), framing enforcement as the necessary response to encampments harming residents and downtown businesses. He stated the Supreme Court ruling "empowered cities like Brockton to regain control" and that "This ordinance does not target a class of people. It targets unlawful behavior." While he acknowledged the city provides shelter and social services, his primary legislative action was enforcement-first, aligning with enforcing anti-camping ordinances as the primary tool while maintaining basic outreach programs.$$,
  ARRAY['https://www.wgbh.org/news/local/2024-11-13/brockton-will-fine-people-200-for-sleeping-outside']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jeff Charnel (At-Large) — id: 9fbef309-1daf-4ddf-a7f2-0432bfffa6c1
-- ============================================================

-- economic-development
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9fbef309-1daf-4ddf-a7f2-0432bfffa6c1', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '9fbef309-1daf-4ddf-a7f2-0432bfffa6c1',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  $$Charnel's 2025 campaign platform emphasizes "smart growth that benefits the entire city" and "expanding access for small businesses and local developers" alongside streamlining city permits and licensing. As chair of the Brockton City Council's Economic Development Committee, his stated focus is on government efficiency and targeted support for local entrepreneurs rather than maximum tax incentives for large employers. This community-benefit framing aligns with targeted incentives for specific industries with community benefit requirements.$$,
  ARRAY['https://www.jeffcharnel.com', 'https://www.brockton.ma.us/government/city-council']::text[]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
