-- =====================================================================================
-- Compass stances: Chuck Washington — Riverside County (CA) Board of Supervisors, District 3
-- ext_id: -4010003   politician_id: 8770fed4-7595-46e2-9103-246f3904a96b
-- Republican; supervisor since March 2015 (appointed, then elected; re-elected March 2024,
-- term ends Jan 8 2029) — longest-serving current Board member. Former U.S. Navy officer/
-- aviator and Delta Airlines pilot; former Temecula/Murrieta mayor and council member.
-- District 3 covers Hemet, Murrieta, San Jacinto, Temecula, Idyllwild, Anza, and Temecula
-- Valley Wine Country.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Board
--     vote/motion, budget action, or on-record public statement) taken during his tenure,
--     with real cited source URLs confirmed via web research.
--   * Topics with no clear documented Washington position emit NO row (honest blank). No
--     party inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (6 topics, all applies_local=true):
--   childcare               = 2  ($12M ARPA + up to $4M First 5 for French Valley childcare facility)
--   growth-and-development  = 3  ($20M+ Wine Country sewer/infrastructure to enable stalled projects)
--   homelessness-response   = 2  (RivCo Street Recovery: $8M field-based outreach/mental-health teams)
--   housing                 = 3  (Oak View Ranch $9.5M ARPA+vouchers; Vine Creek $2.8M PLHA)
--   jail-capacity           = 3  (June 2026 budget: resisted funding Benoit jail capacity expansion)
--   local-immigration       = 3  (Jan 28 2025 vote backing "welcoming county" measure w/ reservations)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, city-sanitation, civil-rights, climate-change (Dec 2019 energy
--          resolution vote was an ABSTENTION — no clear position, honestly left blank),
--          data-centers, economic-development, fossil-fuels, homelessness, local-environment,
--          public-safety-approach, religious-freedom, rent-regulation, residential-zoning,
--          transportation-priorities, trans-athletes.
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs,
--          taxes, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Chuck Washington / childcare (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Washington backed the French Valley Childcare and Early Childhood Learning Experience project in Winchester (Third District): the Board approved $12 million in American Rescue Plan Act funds to build a roughly 13,000-square-foot facility with about 9,000 square feet of childcare programming next to the French Valley Library, and First 5 Riverside County separately committed up to $4 million more toward the childcare/learning component. Washington said the investment was meant "to increase their opportunity for success and to raise our residents' quality of life," citing a "barrier created by the shortage of quality childcare" as parents returned to the workforce. This is a significant one-time capital/provider-grant investment expanding childcare capacity rather than a universal-program or market-only approach.$$,
        ARRAY['https://supervisorchuckwashington.com/news/riverside-county-board-supervisors-approve-15-million-american-rescue-plan-act-arpa-funding',
              'https://ceqanet.lci.ca.gov/2024071167/2']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chuck Washington / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Washington announced more than $20 million in federal American Rescue Plan Act funding, working with Eastern Municipal Water District, to build the De Portola sewer line extension and complete Rancho California Sewer Line Phase II in Temecula Valley Wine Country, plus a smaller sewer project to improve Lake Skinner campgrounds — infrastructure he said was needed to let developments "stalled in the approval process" move forward, calling it "Riverside County's single largest investment in wine country to date." He also requested the Board's June 28, 2022 unanimous $370,000 allocation for a new Wine Country gateway archway on Rancho California Road. This record reflects proactively funding infrastructure ahead of growth to support expansion, rather than growth limits or a hands-off, market-only posture.$$,
        ARRAY['https://rivco.gov/news/infrastructure-cultivating-new-growth-riverside-countys-wine-country',
              'https://www.emwd.org/what-we-do/emwd-construction-updates/temecula-projects/temecula-wine-country-sewer-infrastructure',
              'https://patch.com/california/temecula/new-gateway-temecula-wine-country-gets-supervisors-approval']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chuck Washington / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As Board Chair on Oct. 30, 2024, Washington championed the launch of RivCo Street Recovery, funded by an $8 million grant from the California Board of State and Community Corrections, calling it "a forward-thinking approach to tackling some of the County's most pressing issues — homelessness, mental health, and substance use." The program uses field-based, multidisciplinary teams — housing navigators, licensed clinicians, medical personnel, peer support and case managers — to deliver trauma-informed care and connect people to the County's coordinated entry system for permanent housing and recovery services, alongside the County's separate HOME alternative-sentencing program diverting homeless individuals facing low-level prosecution into treatment rather than jail. This reflects a strategy centered on expanding outreach, shelter connections, and services rather than leading with enforcement.$$,
        ARRAY['https://ukenreport.com/rivco-street-recovery-program-awarded-8-million/',
              'https://rivco.gov/news/riverside-county-department-housing-and-workforce-solutions-awarded-8-million-state-funding',
              'https://supervisorchuckwashington.com/news/new-program-help-homeless-facing-prosecution']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chuck Washington / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Washington has repeatedly backed targeted County subsidies for specific affordable-housing developments in his district: over $9.5 million in American Rescue Plan Act funds and Housing Choice Voucher Program project-based vouchers for the 200-unit Oak View Ranch family and senior apartments in Murrieta (groundbreaking June 29), where he said "The County of Riverside is proud to support the Oak View Ranch Family Apartments with over $9.5 million" so residents could "live, work and play in the City of Murrieta regardless of age or income"; and $2.8 million in Permanent Local Housing Allocation funding toward the 60-unit Vine Creek Apartments near Old Town Temecula, with the County crediting his leadership in guiding the project to completion. This is a pattern of targeted gap-funding subsidies for specific affordable projects rather than direct public-housing operation or a market-only, subsidy-free approach.$$,
        ARRAY['https://nationalcore.org/national-core-breaks-ground-on-affordable-housing-community-in-murrieta/',
              'https://rivcohws.org/news/vine-creek-apartments-celebrates-grand-opening-temecula']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chuck Washington / jail-capacity (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$During the FY2026-27 budget hearings, Sheriff Chad Bianco told supervisors that roughly $250 million in unmet requests would force him to cut positions and that the Benoit jail could not expand operations. Washington pushed back on the sheriff's framing on June 8, 2026, noting Bianco had previously been "somewhat tranquil" about jail funding, and on June 9 said, "We have to be careful. I'm in full support of the current (appropriations) plan," warning that "there's probably going to be more pain to come" if the County kept borrowing from reserves, adding "the pain needs to be distributed across the county departments... it cannot be helped not to feel some of the pain." Rather than committing new money to expand jail capacity, Washington's documented position was fiscal caution — funding facilities within the constrained budget without expanding overall capacity.$$,
        ARRAY['https://kesq.com/news/2026/06/08/sheriff-massive-unfilled-budget-request-will-require-reducing-positions/',
              'https://kesq.com/news/2026/06/09/tentative-2026-27-riverside-county-budget-leaves-some-agencies-short/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Chuck Washington / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8770fed4-7595-46e2-9103-246f3904a96b',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Jan. 28, 2025, Washington voted with the rest of the Board (4-0, with Supervisor Spiegel absent) to direct County staff to evaluate data protections for undocumented immigrants and DACA recipients, identify funding to assist immigrants facing deportation, and draft a resolution declaring Riverside County "a vibrant, compassionate, and inclusionary county for all law-abiding immigrants and refugees." Washington voiced reservations that parts of the proposal could "potentially create a significant legal quagmire for the County," framing the vote as balancing "two competing and important positions" — helping people versus effects on the County — but did not vote against it. The resulting resolution, formally adopted Feb. 4, 2025 by a 4-1 vote, bars county agencies from independent inquiries based solely on immigration status while explicitly preserving "assistance or cooperation with federal authorities if required by state or federal laws." Washington's documented position tracks that middle position: no proactive local enforcement of immigration status, but no bar on legally required cooperation with federal authorities.$$,
        ARRAY['https://idyllwildtowncrier.com/2025/02/06/supervisors-begin-addressing-immigration-issues/',
              'https://kesq.com/news/2025/02/04/county-board-passes-resolution-backing-law-abiding-immigrants-refugees/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
