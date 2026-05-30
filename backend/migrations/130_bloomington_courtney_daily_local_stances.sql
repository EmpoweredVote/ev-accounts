-- Migration 130: Local Lens compass stances for Courtney Daily
-- Bloomington City Common Council, District 5
-- politician_id: 43fd01ea-c039-4b26-87aa-49cddcb54835
-- Researched: 2026-05-11

BEGIN;

-- 1. Affordable Housing (topic_id: 669cac97-66a6-4087-b036-936fbe62efb3)
-- Value 3: Targeted help — subsidies, first-time buyer assistance, easier building permits
-- Daily explicitly advocated for increasing support for Community and Family Resources dept,
-- emphasized housing-first approach (permanent housing without preconditions), and proposed
-- working with landlords to make housing more affordable. No record of supporting rent caps,
-- rent control, or direct public housing construction. Pattern is targeted/incentive-based support.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from candidate forum statements (February 2024) and council priorities. Daily identified affordable housing and homelessness as two of her top three challenge areas for Bloomington. She said the city should increase support for the Community and Family Resources department and emphasized a housing-first approach — providing individuals with permanent housing without preconditions or barriers to entry — as the right framework for addressing homelessness. She also proposed working directly with landlords to make housing more affordable. Her approach focuses on service-side support and working with existing private market actors, not rent caps or publicly-operated housing. Housing and transportation were the two dominant priorities at the council''s April 2025 budget priority meeting, where Daily participated. The overall pattern is targeted assistance and incentive-based support rather than structural rent regulation or public construction.',
  ARRAY[
    'https://www.idsnews.com/article/2024/03/courtney-daily-selected-as-new-bloomington-city-council-district-5-representative',
    'https://www.idsnews.com/article/2024/02/district-5-city-council-candidates-discuss-public-safety-homelessness-at-forum',
    'https://www.idsnews.com/article/2025/04/housing-transportation-udo-2026-budget-city-council'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 2. Criminalization of Homelessness (topic_id: 4938766b-b45a-46e3-93bd-b8b30651271a)
-- Value 2: Decriminalize public sleeping; invest in shelter capacity, outreach, voluntary services
-- Daily explicitly championed a housing-first approach and increased social service funding.
-- She noted council focus on accessible public restrooms as a practical outreach measure.
-- Bloomington's encampment policy uses 30-day notice and deploys outreach workers before closures —
-- a decriminalization-adjacent practice Daily endorsed by consistently supporting the mayor's approach.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Inferred from candidate forum (February 2024) and September 2024 council discussion. Daily explicitly endorsed a housing-first approach — providing individuals with permanent housing without preconditions — as the right framework for homelessness. She said the city should increase support for the Community and Family Resources department and funding for organizations like the Shalom Center and Heading Home of South Central Indiana. At the September 2024 council meeting focused on street homelessness, Daily reported the council was focusing on expanding accessible public restroom hours as a direct response to unhoused people''s needs. Bloomington operates under a 30-day notice policy with outreach workers deployed before camp closures, which Daily did not oppose. There is no record of Daily supporting criminal penalties for public camping or sleeping. Her consistent emphasis on services, shelter investment, and housing-first aligns with decriminalizing public sleeping while investing in shelter capacity and voluntary service connections.',
  ARRAY[
    'https://www.idsnews.com/article/2024/02/district-5-city-council-candidates-discuss-public-safety-homelessness-at-forum',
    'https://www.idsnews.com/article/2024/03/courtney-daily-selected-as-new-bloomington-city-council-district-5-representative',
    'https://www.idsnews.com/article/2024/09/bloomington-indiana-homelessness-city-council-meeting-sept11-2024'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 3. Residential Zoning (topic_id: d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Value 2: Allow modest density increases (duplexes, accessory units) with strong design review and
-- neighborhood input. Daily voted NO on the March 2025 UDO resolutions, but her stated reason
-- was procedural (insufficient notice, community trust), not categorical opposition to density.
-- She did not align with the strongly anti-upzoning ideological position of Rollo.
-- Her "trust" rationale suggests she would support process-driven, community-input-driven increases.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from March 2025 UDO vote and stated rationale. Daily voted NO (with Rollo, Ruff, and Asare) on March 12, 2025 resolutions that would have directed the Plan Commission to draft UDO amendments allowing duplexes, triplexes, and fourplexes by right in single-family zones and eliminating parking minimums. The vote failed 4-4. However, Daily''s stated reason was procedural: she was concerned that residents believed a final zoning vote could happen that night (which was not accurate) and voted against introduction because she did not want to make people "less trustful" of the council. This is a process-and-communication objection, not an ideological rejection of density. Unlike Rollo, Daily has no record of opposing density in principle, no prior anti-upzoning amendments, and no endorsements from anti-upzoning groups. She also participated in the November 2025 housing reform community forum without opposing incremental density changes. The B Square bulletin characterized her NO vote as a concern about insufficient notice for residents rather than opposition to the substance of the UDO changes. Her position is most consistent with allowing modest density increases with strong design review and neighborhood input.',
  ARRAY[
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://www.idsnews.com/article/2025/04/city-council-mayor-upzoning-disagreement-udo-housing-density',
    'https://www.idsnews.com/article/2025/11/city-council-housing-reform-zoning-building-code-bloomington-news'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 4. Civil Rights and Social Justice (topic_id: 0bc588c6-39e1-4084-b5de-cac909b8b762)
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Daily led Indiana Moms Demand Action for Gun Sense 2017-2020 (systemic advocacy org).
-- She is a progressive Democrat on a council that has consistently passed civil rights measures.
-- Her social service agency focus and housing-first approach reflect systemic equity concerns.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from background and council alignment. Daily led the Indiana Chapter of Moms Demand Action for Gun Sense in America from 2017-2020, an organization focused on systemic policy change and racial equity in gun violence outcomes. She was selected by Monroe County Democratic Party precinct chairs and serves on a progressive council that has passed civil rights ordinances, driver card support resolutions for undocumented residents, and anti-surveillance measures on immigration enforcement grounds. Her priorities emphasize "supporting social service agencies" — a framing consistent with addressing systemic disparities through institutional support. There are no direct quotes from Daily on racial equity or reparations policy, and no direct votes on race-specific legislation found during research. Placement at value 2 (strengthen civil rights enforcement, address systemic discrimination) is inferred from her progressive coalition alignment, social-services focus, and advocacy background. Checked: bloomington.in.gov/council/district-5, idsnews.com, bsquarebulletin.com; no direct civil rights vote record found.',
  ARRAY[
    'https://www.idsnews.com/article/2024/03/courtney-daily-selected-as-new-bloomington-city-council-district-5-representative',
    'https://bloomington.in.gov/council/district-5'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 5. Public Safety Approach (topic_id: e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Value 3: Keep current public safety funding while adding crisis response teams
-- Daily explicitly said she would support policing alternatives for mental health calls
-- ("have a medical expert respond rather than a sworn officer"). She also said she would
-- support adequate police compensation. This is the co-responder / crisis team addition model,
-- not defunding police.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Direct statement at February 2024 candidate forum. Daily said she would support using policing alternatives to help handle mental health-related calls — specifically that a medical expert should respond to mental health crises rather than a sworn officer. This is the co-responder model: adding specialized civilian crisis response capacity rather than redirecting funds away from police. During the 2025 budget process, Daily stated "I will be supporting this budget," which included increased police compensation and staffing additions (the 2025 budget added seven police department personnel and 100% annual pension contributions). Her public safety committee work focuses on the Community and Family Resources department — the city''s non-sworn social service agency — as a complement to police, not a replacement. The pattern is maintain or modestly grow police while adding mental health and addiction crisis response teams alongside sworn officers.',
  ARRAY[
    'https://www.idsnews.com/article/2024/02/district-5-city-council-candidates-discuss-public-safety-homelessness-at-forum',
    'https://bsquarebulletin.com/2024/09/04/bloomington-mayor-city-council-try-to-tackle-2025-budget-tensions-ahead-of-sept-25-hearing/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 6. Local Immigration Enforcement (topic_id: b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- Value 1: Refuse ICE cooperation; prohibit sharing immigration status information
-- Daily voted with the unanimous (9-0) March 2026 council resolution to pause Flock cameras
-- and require a full briefing on immigration data-sharing concerns. Bloomington subsequently
-- ended its Flock contract. The city's broader stance is a welcoming city that does not use
-- city resources for immigration enforcement.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from unanimous council vote, March 2026. Daily voted with all other councilmembers (9-0) on March 4, 2026 to pass a resolution pausing expansion of Flock license plate reader cameras and requiring a joint report from the Bloomington Police Department and mayor''s office on data access and sharing — driven directly by community concerns that Flock data was being shared with ICE for immigration enforcement. Bloomington subsequently ended its Flock contract (April 2026), with BPD formally prohibiting use of Flock data for immigration investigations. Mayor Thomson''s statement following the April 2025 ICE arrests in southern Indiana reaffirmed that Bloomington does not inquire about immigration status and local police are focused on public safety, not federal immigration enforcement. Daily''s vote on the surveillance resolution, combined with the city''s consistent welcoming-city posture, places her at value 1: refusing city resources for ICE cooperation and opposing sharing of immigration status information.',
  ARRAY[
    'https://www.idsnews.com/article/2026/03/bloomington-city-council-flock-cameras-resolution-hopewell-affordable-housing',
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://www.idsnews.com/article/2026/04/bloomington-police-department-bans-flock-data-immigration-reproductive-investigations',
    'https://bloomington.in.gov/news/2025/05/02/6246'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 7. Economic Development Incentives (topic_id: eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Not found — no public record of Daily's position on economic development incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: bloomington.in.gov/council/district-5, idsnews.com, bsquarebulletin.com, ipm.org, candidate forum coverage (February 2024), budget priority meeting coverage (April 2025, October 2025). Daily has not made public statements about corporate tax incentives, tax abatements, or economic development strategy. She has not been named in coverage of the Bloomington Economic Development Commission or tax abatement decisions. Her stated priorities (affordable housing, homelessness, sustainability, social services) do not include economic development.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- 8. Transportation Priorities (topic_id: ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Value 2: Invest equally in roads and multimodal; require bike lanes and sidewalks on all new projects
-- Transportation and mobility was a top council priority for 2026 budget that Daily supported.
-- She backed Ruff's appointment to the new Transportation Commission (February 2025).
-- Bloomington's strong multimodal culture (pedestrian/bike grants, Safe Streets for All plan)
-- represents the city's direction, and Daily has not opposed any multimodal measures.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('43fd01ea-c039-4b26-87aa-49cddcb54835', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '43fd01ea-c039-4b26-87aa-49cddcb54835',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from council priorities and transportation commission vote. Transportation and mobility was one of the two dominant priorities at the April 2025 council budget priority meeting — alongside affordable housing — with Daily as one of the council members listing it among top outcome areas. In February 2025, Daily supported Andy Ruff''s nomination to the newly formed Transportation Commission, which merged the bicycle and pedestrian safety commission, traffic commission, and parking commission into a single body — a reform oriented toward integrated multimodal planning. Bloomington''s transportation framework includes a Safe Streets for All action plan, Local-Motion grants for pedestrian and bicycle projects, and a long-range transportation plan through 2050 prioritizing walking and cycling infrastructure. Daily has not opposed any multimodal investments or advocated for car-priority transportation policy. No direct statement from Daily specifically on transportation spending priorities was found; placement at value 2 (equal investment in roads and multimodal, bike lanes and sidewalks on all new projects) is inferred from her participation in the city''s multimodal-oriented transportation governance and stated budget priorities.',
  ARRAY[
    'https://www.idsnews.com/article/2025/04/housing-transportation-udo-2026-budget-city-council',
    'https://bsquarebulletin.com/amid-shift-in-bloomington-street-oversight-flaherty-gets-city-council-nod-for-new-transportation-group-2/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
