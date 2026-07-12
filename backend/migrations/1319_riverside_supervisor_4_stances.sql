-- =====================================================================================
-- Compass stances: V. Manuel "Manny" Perez — Riverside County (CA) Board of Supervisors, District 4
-- ext_id: -4010004   politician_id: c986a6af-f09f-4934-83ed-1d9cd26a84f1
-- Democrat; Supervisor since May 2019 (appointed to fill a vacancy, later elected; re-elected
-- June 2026). Previously CA State Assemblymember (AD-56, 2008-2014) and Assembly Majority
-- Leader. District 4 covers the eastern county / Coachella Valley (Palm Springs, Indio,
-- Coachella, Cathedral City, Desert Hot Springs) plus Blythe and the Salton Sea region.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Board
--     vote/resolution he co-authored/led, a directly quoted on-record statement, or a
--     county program he championed) taken during his county tenure (May 2019 onward), with
--     real cited source URLs confirmed via web research.
--   * Topics with no clear documented Perez position emit NO row (honest blank). No party
--     inference, no neutral defaults. His pre-2019 CA Assembly legislative record (renewable
--     energy bills, etc.) is NOT used as sole evidence for any county-era stance.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (6 topics, all applies_local=true):
--   growth-and-development    = 3  (Cook Street Substation partnership; proactive infra-ahead-
--                                    of-growth + community consent on Thousand Palms annexation)
--   homelessness-response     = 2  (shelter-capacity expansion: Galilee Center, CV Rescue
--                                    Mission, Palm Springs Navigation Center, DHS access hub)
--   housing                   = 3  (Oasis Mobile Home Park relocation/homeownership program;
--                                    Palm Villas at Millennium ARPA-funded affordable housing)
--   local-immigration         = 3  (Feb 2025 "welcoming county" resolution he co-authored:
--                                    no independent status inquiries, but complies when
--                                    required by state/federal law; explicitly not "sanctuary")
--   public-safety-approach    = 4  (backed competitive deputy/firefighter pay and staffing)
--   transportation-priorities = 3  (maintains road/freeway growth while expanding SunLine
--                                    transit service and championing rail for emissions)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance is not applicable at this level; city-sanitation, civil-rights,
--          climate-change, data-centers (Perez said on-record he was still learning about a
--          proposed AI data center and had "not even had this conversation at the county
--          level" — an explicit non-position, not evidence of any chair), economic-development
--          (arena/substation partnerships are captured under growth-and-development instead of
--          double-counted here), fossil-fuels, jail-capacity (no Perez-era vote found; the
--          only located jail-capacity board action predates his 2019 arrival), local-environment,
--          childcare (only COVID-era PPE/CARES-Act distribution found, not a documented policy
--          stance on cost/availability framework), religious-freedom, rent-regulation,
--          residential-zoning, trans-athletes.
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs,
--          taxes, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Manny Perez / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Perez publicly backed the $39.6 million Cook Street Substation (Imperial Irrigation District, with the county, Palm Desert, Rancho Mirage and the Berger Foundation as partners), saying it "would generate development opportunities for economic development, affordable housing and workforce housing" for Thousand Palms and neighboring cities that had been power-constrained. On the related Acrisure Arena-area expansion, he stated the county is "not going to annex this area or allow it to be annexed unless the Thousand Palms community decides otherwise." Together this is a documented pattern of investing in infrastructure capacity ahead of growth while deferring annexation/development-boundary decisions to the affected community — proactive planning for responsible expansion rather than either strict growth limits or deregulated, incentive-driven development.$$,
        ARRAY['https://kesq.com/news/2026/01/28/infrastructure-projects-signal-long-term-development-plans-near-acrisure-arena/',
              'https://www.nbcpalmsprings.com/2025/07/10/plans-floated-for-acrisure-arena-expansion-bringing-homes-shops-and-more-to-thousand-palms-area']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Perez / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$As chairman, Perez has pointed to a documented 19% drop in Fourth District/countywide unsheltered homelessness alongside a 57% increase in shelter-bed capacity since 2023, crediting "county, city, and nonprofit collaborations." In February 2024 the Board he sits on unanimously approved $416,219 in state funding to keep the Desert Hot Springs homeless "access hub" open, and his district expanded shelter capacity at the Galilee Center in Mecca, the Coachella Valley Rescue Mission in Indio, and secured investment in the Palm Springs Navigation Center. This is a documented strategy centered on expanding shelter capacity and services rather than a housing-first no-conditions model or an enforcement-first approach.$$,
        ARRAY['https://kesq.com/news/2024/02/28/riverside-county-board-approves-416000-in-state-funding-for-desert-hot-springs-homeless-shelter/',
              'https://rivco.gov/news/riverside-county-sees-19-decrease-unsheltered-homeless-population']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Perez / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Perez has backed targeted, subsidy-based affordable-housing programs rather than direct public-housing operation or a market-only approach. The county created the Oasis Housing Opportunity Program, using $15 million of a state relocation grant to give Oasis Mobile Home Park families flexible paths to secure homeownership after years of arsenic-contaminated water and unsafe sanitation. His district also delivered the Palm Villas at Millennium affordable-apartment community in Palm Desert (including units for domestic-violence survivors and people experiencing homelessness), made possible by a $6.7 million County ARPA investment; at its May 2026 opening Perez said the Fourth District is "leading the charge, sometimes 3 to 1 in comparison to other districts" on affordable housing production and that "we're on the right track."$$,
        ARRAY['https://rivco.org/news/riverside-county-provides-funding-advance-12-homes-oasis-mobile-home-park-relocation-efforts',
              'https://rivcohws.org/news/palm-villas-millennium-breaks-ground-palm-desert-120-affordable-homes-and-hope-families',
              'https://kesq.com/news/top-stories/2026/05/11/new-affordable-apartment-community-opens-in-palm-desert-local-leaders-highlight-the-need/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Perez / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As Board Chairman, Perez co-authored (with Supervisor Yxstian Gutierrez) the resolution the Board passed 4-1 on Feb. 4, 2025 declaring Riverside County "a vibrant, compassionate and welcoming county for all law-abiding immigrants and refugees." The resolution bars county departments from independently investigating a person's immigration status but explicitly allows "assistance or cooperation with federal authorities if required by state or federal laws." Perez said "Everybody should be protected, especially those individuals who are here because they want a better future for themselves and their families," while rejecting the "sanctuary county" label: "There is no language referring to being a sanctuary county... that's you making it all up." That is county compliance with federal/state law when legally required, without proactive local enforcement assistance — not a refusal of all cooperation and not proactive ICE assistance.$$,
        ARRAY['https://www.yahoo.com/news/riverside-county-supervisors-expected-approve-213703287.html',
              'https://kesq.com/news/local-news/2025/01/28/riverside-county-supervisors-propose-new-policy-to-protect-undocumented-immigrants/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Perez / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Asked directly about public safety in a May 2026 campaign Q&A, Perez said, "we've been able to support our deputies with better pay, competitive pay, so that we don't lose them," framing this as necessary so "the deputy shows up ... in a timely manner and is ready to engage, if necessary." He has also touted adding sheriff's deputies and firefighters to Fourth District communities and creating a Combustible Task Force to combat fire incidents. This is a documented position of increasing law-enforcement/fire staffing and pay to improve response and retention, not a budget-redirection or co-responder-first approach.$$,
        ARRAY['https://cvindependent.com/2026/05/candidate-qa-the-two-candidates-for-riverside-countys-board-of-supervisors-district-4-discuss-the-most-pressing-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Manny Perez / transportation-priorities (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c986a6af-f09f-4934-83ed-1d9cd26a84f1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$In a May 2026 campaign Q&A, Perez said of the district's growth, "we still have enough land territory where one day, we might have more freeway structures, or more roads, but at the same time, rail ... will reduce greenhouse gas emissions" — explicitly anticipating continued road capacity alongside championing rail. He also described institutionalizing free SunLine transit passes so students "go to (College of the Desert) for free" and extending free rides to veterans, while acknowledging unmet needs at bus stops ("no shade ... no water, no bathroom nearby"). This reflects maintaining/expanding roads while selectively adding transit service and pedestrian amenities, not a transit-only or roads-only priority.$$,
        ARRAY['https://cvindependent.com/2026/05/candidate-qa-the-two-candidates-for-riverside-countys-board-of-supervisors-district-4-discuss-the-most-pressing-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
