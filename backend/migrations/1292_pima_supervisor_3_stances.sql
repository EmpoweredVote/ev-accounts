-- =====================================================================================
-- Compass stances: Jennifer Allen — Pima County (AZ) Board of Supervisors, District 3
-- ext_id: -4007003   politician_id: f928a8f0-07fc-47c4-98b2-9801e6adf3dd
-- Democrat; longtime organizer/advocate (founding Executive Director of Border Action
-- Network, former Executive Director of ACLU of Arizona, Senior VP at League of
-- Conservation Voters, founding National Director of Chispa; water/environment background).
-- Elected Nov 5, 2024; seated Jan 1, 2025; selected 2026 Board Chair. Newer to the Board,
-- so her recorded-vote history is short — only her Jan-2025-onward tenure is attributed.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (a recorded Board
--     vote/motion she cast or sponsored while seated, or a clearly documented campaign-platform
--     / career position), with real cited source URLs confirmed via web research.
--   * All county-tenure actions cited fall within her term (seated Jan 1, 2025). Two topics
--     (immigration, civil-rights) are seeded from her own strongly and extensively documented
--     career record — founding ED of an immigrant-rights organization and former ED of the
--     ACLU of Arizona — as permitted for clearly documented positions, with specific citations.
--   * Topics with no clear documented Allen position emit NO row (honest blank). No party
--     inference, no neutral defaults. She is newer to the Board, so fewer topics are seeded.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (9 topics):
--   abortion            = 2  (campaign platform: "keep open access to abortion and reproductive
--                             healthcare"; former ACLU-AZ ED / abortion-rights advocate)
--   civil-rights        = 2  (career record: former ED of ACLU of Arizona; founder/leader of
--                             immigrant- and Latino-rights orgs — strengthen civil-rights enforcement)
--   climate-change      = 3  (voted YES on May 6, 2025 CAPCO climate resolution; clean-energy /
--                             emissions-reduction platform)
--   data-centers        = 3  (voted NO on Project Blue; introduced Sept 2, 2025 mandatory
--                             environmental-impact-review requirement before development approval)
--   housing             = 3  (voted YES on June 3, 2025 $250M/10-yr affordable-housing plan; subsidies)
--   immigration         = 2  (non-local; founding ED of Border Action Network; pro-asylum; county
--                             measures keeping services open to residents regardless of status)
--   jail-capacity       = 2  (campaign signature issue: reduce over-reliance on incarceration;
--                             diversion/treatment alternatives to a new jail — Sobering Center, etc.)
--   local-environment   = 1  (introduced Sept 2, 2025 environmental-impact/justice review before
--                             development; Sonoran Desert Conservation Plan advocacy)
--   local-immigration   = 1  (sponsored Feb 3, 2026 measures barring ICE from county property and
--                             barring county employees from assisting civil immigration enforcement)
--
-- DELIBERATELY BLANK (no attributable documented Allen position found; she is newer to the Board):
--   Local: campaign-finance, childcare, city-sanitation, economic-development, fossil-fuels,
--          growth-and-development, homelessness, homelessness-response, public-safety-approach,
--          religious-freedom, rent-regulation, residential-zoning, trans-athletes,
--          transportation-priorities.
--   Non-local federal/state: ai-regulation, deportation, healthcare, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs, taxes,
--          ukraine-support, voting-rights.
--   (The 2025-26 ICE / county-property measures are captured under local-immigration; they are not
--    a stance on federal immigration levels or deportation aggressiveness. The Project Blue no-vote
--    is captured under data-centers; her general economic-development incentive posture is not
--    clearly documented, so economic-development is left blank.)
-- =====================================================================================

BEGIN;

-- ----- Jennifer Allen / abortion (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Allen made "fighting to keep open access to abortion and reproductive healthcare" an explicit priority of her 2024 District 3 campaign, and her career includes leading the ACLU of Arizona, which litigates for abortion access; local coverage of her run noted her past work advocating for abortion rights. Her documented position is to keep abortion legal and accessible, which matches keeping it legal and broadly accessible rather than restricting or banning it. (No cited call for public funding at all stages, so value 1 is not claimed.)$$,
        ARRAY['https://www.tucsonspotlight.org/allens-priorities/',
              'https://tucson.com/news/local/government-politics/elections/pima-county-supervisors-jennifer-jen-allen-district-3-janet-jl-wittenbraker/article_6bf7d3ce-8fdd-11ef-8ae3-bf71c28bf5ed.html',
              'https://www.pima.gov/3194/Jennifer-Allen-Biography']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / civil-rights (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Seeded on Allen's own extensively documented career record: she served as Executive Director of the ACLU of Arizona, was founding National Director of Chispa and founding Executive Director of Border Action Network, and has served on the boards of Las Adelitas Arizona and GreenLatinos. Her official county biography describes her as "a life-long organizer and advocate" for "human dignity." That record centers on strengthening civil-rights enforcement and addressing systemic discrimination rather than merely maintaining the status quo or limiting enforcement.$$,
        ARRAY['https://www.pima.gov/3194/Jennifer-Allen-Biography',
              'https://runonclimate.org/jen-allen-bio',
              'https://ballotpedia.org/Jennifer_Allen_(Arizona)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / climate-change (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Allen, a former Senior VP at the League of Conservation Voters, campaigned on developing a county-wide climate action plan focused on extreme-heat mitigation, clean-energy workforce development, emissions reduction, and water conservation, saying southern Arizona needs "bold, aggressive action to combat climate change on all fronts while also ensuring our communities are resilient." As a seated supervisor she backed the Board's May 6, 2025 4-1 vote directing staff to craft a Climate Action Plan for County Operations (CAPCO) targeting a 60% cut in operational emissions below 2021 levels by 2030 and net-zero by 2050. That record supports investing in clean energy while reducing reliance on fossil fuels, rather than leaving the transition to market forces or rejecting climate policy.$$,
        ARRAY['https://runonclimate.org/jen-allen-bio',
              'https://www.aztechcouncil.org/climate-matters-pima-county-sets-bold-climate-goals-with-new-action-plan/',
              'https://www.pima.gov/3138/Climate-Change']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / data-centers (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Allen was a leading critic of the "Project Blue" data center and voted no on the Dec 16, 2025 agreement (which passed 3-2), warning that Tucson Electric Power lacked capacity so the project would "extend the lifespan of the declining coal sector" and that supervisors had "no clarity on what phases two and three ... will entail, how much energy will be required or even how many data centers are planned." Rather than a flat ban, she pushed to build guardrails first: at the Sept 2, 2025 meeting she introduced (passed 4-1) a policy requiring publicly available environmental-impact and environmental-justice reports — documenting water impacts, energy demand, and compatibility with county climate/conservation plans — before such development is approved, and helped end the county's NDAs. That matches allowing data-center development only with impact assessments and community-benefit/energy conditions before approval.$$,
        ARRAY['https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/',
              'https://news.azpm.org/p/businessnews/2025/7/2/225390-supervisors-move-to-draft-new-economic-development-policies-following-project-blue-approval/',
              'https://azluminaria.org/2025/09/03/pima-county-votes-to-change-two-policies-about-ndas-and-environmental-impact-reviews-after-lessons-learned-from-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Allen campaigned on tackling affordable housing "to ensure that the county is showing up and helping folks have the stability that four walls and a roof provides," spanning new construction, preservation of existing homes, and transitional housing. As a seated supervisor she was one of the three yes votes for the county's June 3, 2025 plan (approved 3-2, with Republican Steve Christy and Rex Scott opposed) committing roughly $250 million over ten years to subsidize affordable rental and homeownership housing. Delivered as public subsidies for affordable projects rather than rent control or county-built public housing, that matches targeted government help for affordable housing.$$,
        ARRAY['https://www.tucsonspotlight.org/allens-priorities/',
              'https://www.kold.com/2025/06/04/pima-county-supervisors-vote-fund-more-affordable-housing/',
              'https://azluminaria.org/2025/06/04/a-boost-for-affordable-housing-a-new-library-and-an-ongoing-investigation-into-sheriffs-department-3-things-to-know-from-pima-county-board-of-supervisors-meeting/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / immigration (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Non-local topic, seeded on Allen's own strongly documented record. She was the founding Executive Director of Border Action Network, an immigrant-rights organization, and ran saying she would "counteract the distorted view of the border while making sure asylum seekers get needed support." As Board Chair she sponsored the Feb 3, 2026 county measures ensuring residents "can continue to feel safe in libraries, schools and clinics" regardless of immigration status. That record supports keeping immigration open and letting residents use public services regardless of legal status.$$,
        ARRAY['https://www.pima.gov/3194/Jennifer-Allen-Biography',
              'https://tucson.com/news/local/government-politics/elections/pima-county-supervisors-jennifer-jen-allen-district-3-janet-jl-wittenbraker/article_6bf7d3ce-8fdd-11ef-8ae3-bf71c28bf5ed.html',
              'https://www.tucsonspotlight.org/pima-supervisors-approve-measures-limiting-immigration-enforcement/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / jail-capacity (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Reducing the county's "over-reliance on incarceration" and finding alternatives to building a new Pima County jail was a signature issue of Allen's campaign; she has said the rise in jail deaths prompted her to run. As a seated supervisor she describes the county's strategy as moving "beyond the usual reliance on law enforcement or incarceration," pointing to diversion and treatment programs — the Sobering Alternative for Recovery Center (medication-assisted treatment referrals), expanded access to the Transition Center at the jail, and the Pima Prosperity Initiative. That matches reducing the incarcerated population through diversion and treatment alternatives rather than building new jail capacity.$$,
        ARRAY['https://www.tucsonspotlight.org/allens-priorities/',
              'https://azluminaria.org/2026/01/30/pima-county-supervisors-share-2026-priorities-from-leadership-hire-to-addiction-response/',
              'https://tucsonagenda.substack.com/p/the-daily-agenda-allen-wants-to-get']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / local-environment (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Allen, whose career centers on "protecting our lands, air, and water," introduced the environmental-review policy the Board passed 4-1 on Sept 2, 2025, requiring publicly available environmental-impact and environmental-justice reports — documenting water impacts, energy requirements, and compatibility with county climate and conservation plans — before certain development projects are approved; she called it "an enduring commitment to see our community holistically." She has also pledged that the science-based Sonoran Desert Conservation Plan continues to be aggressively implemented and guide land-use decisions. That matches requiring significant environmental review before approving development.$$,
        ARRAY['https://azluminaria.org/2025/09/03/pima-county-votes-to-change-two-policies-about-ndas-and-environmental-impact-reviews-after-lessons-learned-from-project-blue/',
              'https://runonclimate.org/jen-allen-bio',
              'https://www.pima.gov/3194/Jennifer-Allen-Biography']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jennifer Allen / local-immigration (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f928a8f0-07fc-47c4-98b2-9801e6adf3dd',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As Board Chair, Allen requested and sponsored the trio of immigration-enforcement measures the Board advanced 4-1 on Feb 3, 2026 (Republican Steve Christy the lone no): an ordinance prohibiting federal immigration enforcement on county-owned property and barring county employees, while working, from assisting with civil immigration enforcement; a ban on masked/anonymous law-enforcement agents; and a resolution opposing a proposed ICE detention center at the former Marana jail. She said the goal was "ensuring county properties are places that are safe, that people feel secure." Refusing to let county resources or personnel be used for immigration enforcement is the most non-cooperative posture on this scale.$$,
        ARRAY['https://www.kjzz.org/fronteras-desk/2026-02-03/pima-county-leaders-vote-to-advance-trio-of-policies-outlining-how-ice-can-function-within-county',
              'https://www.tucsonspotlight.org/pima-supervisors-approve-measures-limiting-immigration-enforcement/',
              'https://www.kold.com/2026/02/04/pima-county-board-supervisors-moves-regulate-ice-activities-county/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
