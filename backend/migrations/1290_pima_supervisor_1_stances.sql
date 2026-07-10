-- =====================================================================================
-- Compass stances: Rex Scott — Pima County (AZ) Board of Supervisors, District 1
-- ext_id: -4007001   politician_id: b33f37df-5537-4eee-bb5b-b401a135bc1b
-- Democrat; sitting supervisor since Jan 2021 (elected Nov 2020), current Board member.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Board
--     vote/motion, sponsored resolution, or on-record public statement) taken during his
--     tenure, with real cited source URLs confirmed via web research.
--   * Topics with no clear documented Scott position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (9 topics, all applies_local=true):
--   childcare               = 2  (Pima Early Education Program preschool scholarships/capacity)
--   climate-change          = 3  (May 2025 CAPCO resolution; clean-energy investment)
--   data-centers            = 3  (Project Blue approval conditioned on binding commitments)
--   economic-development    = 3  (Project Blue targeted incentive + community-benefit terms)
--   housing                 = 3  (gap-funding subsidies/infill; measured, not maximalist)
--   jail-capacity           = 3  (no new-jail decision without data; maintain + Transition Center)
--   local-immigration       = 2  (Feb 2026 judicial-warrant-only ICE-on-county-property rule)
--   public-safety-approach  = 4  (backed deputy/corrections staffing + pay; COPS hiring grant)
--   transportation-priorities = 2 (championed RTA Next multimodal roads+transit+bike/ped plan)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, city-sanitation, civil-rights, fossil-fuels,
--          growth-and-development, homelessness, homelessness-response, local-environment,
--          religious-freedom, rent-regulation, residential-zoning, trans-athletes.
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs,
--          taxes, ukraine-support, voting-rights.
--   (The Feb-2026 ICE-property resolution is captured under local-immigration; it is not a
--    stance on federal immigration levels or deportation aggressiveness.)
-- =====================================================================================

BEGIN;

-- ----- Rex Scott / childcare (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$As a Board member since 2021, Scott championed the county-funded Pima Early Education Program (PEEP), which provides preschool scholarships his office credits with letting roughly 1,700 low-income children attend preschool "who would not be able to go otherwise" and with expanding preschool capacity across the county. This is a public subsidy-and-provider-support approach to making early childcare affordable for lower- and middle-income families, rather than universal free childcare or a market-only stance.$$,
        ARRAY['https://www.pima.gov/2503/Supervisor-Rex-Scott-District-1',
              'https://tucsonagenda.substack.com/p/rex-scotts-answers-to-debate-questions']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / climate-change (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$On May 6, 2025, Board Chair Scott led the 4-1 vote adopting a resolution directing staff to craft a Climate Action Plan for County Operations (CAPCO) that meets or exceeds the 2015 Paris Agreement goals and cuts county greenhouse-gas emissions to 60% of 2021 levels by the end of the decade, building on the county's long-running investments in solar, energy-efficient buildings and an electric-vehicle fleet. Scott said the county "continues to follow the science and enact new and updated policies" on climate. The documented record reflects investing in clean energy while gradually reducing fossil-fuel reliance, not an immediate ban on all emitting activity.$$,
        ARRAY['https://tucson.com/news/local/pima-county-supervisors-approve-climate-change-resolution-to-align-with/article_ca996ec2-e36d-52c4-be1e-02f3dc060215.html',
              'https://www.kgun9.com/news/local-news/pima-county-to-adopt-a-climate-action-plan',
              'https://www.pima.gov/3622/Climate-Plans']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / data-centers (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$On Dec. 16, 2025, Scott voted (3-2) to approve the binding development agreement for the "Project Blue" data center only after the county secured binding commitments — 100% renewable-energy matching with independent verification, plus $15 million in donations for science education and trade schools. Scott said the county "did a good job getting Project Blue to make binding commitments to renewable energy, and to promise donations to education and job training." His position allows data-center development conditioned on impact commitments and community-benefit requirements before approval.$$,
        ARRAY['https://www.kgun9.com/news/local-news/project-blue-datacenter-pima-co-accepts-binding-commitment-to-100-renewable-energy',
              'https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Scott's Dec. 16, 2025 vote (3-2) to approve the "Project Blue" data center exemplifies his approach of granting a targeted incentive to a specific major employer only after negotiating enforceable community-benefit conditions — a binding 100% renewable-energy commitment and $15 million for science education and trade-school job training. He publicly framed the deal around its economic benefits paired with those binding public commitments, i.e. incentives tied to community benefit and job-quality requirements rather than no-strings subsidies or a no-incentive posture.$$,
        ARRAY['https://www.kgun9.com/news/local-news/project-blue-datacenter-pima-co-accepts-binding-commitment-to-100-renewable-energy',
              'https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Scott has repeatedly backed targeted county help for affordable housing: "gap funding" subsidies for affordable projects (the Board has invested ~$21M in 28 projects / ~1,857 units since July 2022), infill development, selling county parcels to affordable-housing developers, and streamlined permitting; he calls the lack of affordable housing the single biggest driver of homelessness. On June 3, 2025 he supported the 4-1 vote adding housing funding for the coming year but, as Chair, voted no (3-2) on a much larger multi-year affordable-housing plan, saying it was "prudent to vote against it for right now" pending the housing commission's detailed options. That record fits targeted subsidies/assistance for affordable housing rather than the most expansive public-housing intervention.$$,
        ARRAY['https://www.kold.com/2025/06/04/pima-county-supervisors-vote-fund-more-affordable-housing/',
              'https://tucsonagenda.substack.com/p/rex-scotts-answers-to-debate-questions',
              'https://www.pima.gov/2503/Supervisor-Rex-Scott-District-1']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / jail-capacity (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Asked whether the county needs a new jail, Scott stated, "I do not believe that we have enough information to determine if a new jail is needed," attributing the facility's problems to age, deferred maintenance and vandalism and calling for better data on the jail population before any decision on new capacity. He also introduced the measure that created the county's Transition Center to steer people leaving jail toward community resources. His documented position is to upgrade/maintain the facility as needed without committing to expanded capacity.$$,
        ARRAY['https://tucsonagenda.substack.com/p/rex-scotts-answers-to-debate-questions',
              'https://www.pima.gov/2503/Supervisor-Rex-Scott-District-1']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / local-immigration (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Feb. 17, 2026 Scott supported the Board resolution directing county employees to deny federal immigration agents access to county property for civil enforcement unless they hold an arrest warrant signed by a judicial officer, and barring use of county property as a staging ground. Scott said "these warrantless, random sweeps ... are not going to happen on county property," while adding that "if somebody with an enforceable warrant comes in ... they're going to be able to do that." That is cooperation limited to court-ordered / judicial-warrant cases rather than proactive assistance with or full refusal of federal enforcement.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/2/17/228516-pima-county-supervisors-adopt-policy-restricting-use-of-county-property-by-federal-immigration-agents/',
              'https://azmirror.com/2026/05/06/pima-county-can-require-judicial-warrants-before-letting-ice-onto-its-property-mayes-says/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Scott supported the salary and incentive packages the sheriff and county administrator brought to the Board to increase staffing of deputies and corrections officers, and backed the county's October 2022 $1.75M federal COPS grant used to hire 14 additional sheriff's deputies. His documented votes favor increasing law-enforcement/corrections staffing and pay to improve capacity, consistent with growing police staffing rather than redirecting the police budget.$$,
        ARRAY['https://www.pima.gov/2503/Supervisor-Rex-Scott-District-1',
              'https://azluminaria.org/2025/03/04/pima-county-grapples-with-budget-shortfalls-tax-hikes-sheriffs-department/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rex Scott / transportation-priorities (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b33f37df-5537-4eee-bb5b-b401a135bc1b',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Scott, who represents the county on the Regional Transportation Authority board, publicly championed the RTA Next 20-year plan — a ~$2.67B multimodal program that funds roadway maintenance and new/improved roads alongside transit, bicycle and pedestrian improvements and safety projects. In an April 2024 guest opinion he argued the plan is "inextricably linked to economic development," backing balanced investment across roads and non-auto modes rather than a roads-only or transit-only priority.$$,
        ARRAY['https://www.pima.gov/883/Planning-for-RTA-Next',
              'https://www.tucsonsentinel.com/opinion/report/042524_scott_rta_op/rex-scott-rta-next-transportation-plan-inextricably-linked-economic-development/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
