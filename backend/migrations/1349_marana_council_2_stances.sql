-- =====================================================================================
-- Compass stances: Patrick Cavanaugh — Council Member, Town of Marana (AZ)
-- politician_id: cb526b61-89e2-4c0f-b60c-f359e7193192
-- Nonpartisan; sitting Town Council member. His seat is mid-term (NOT on the July 21,
-- 2026 ballot), so candidate-forum coverage does not feature him. Positions are
-- attributed only from his own recorded Council votes and on-record statements.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Cavanaugh position (a
--     recorded Council vote plus his stated reasoning) with real cited source URLs
--     confirmed via web research.
--   * Topics with no clear documented Cavanaugh position emit NO row (honest blank). No
--     party inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (2 topics):
--   data-centers            = 4  (voted YES on the Jan 6 2026 Beale/Luckett Rd 600-acre
--                                 hyperscale data-center rezoning, 6-0; entered leaning no,
--                                 swayed by rate-guarantee assurances; approved development
--                                 while focused on transparency about energy demand/rate impact)
--   growth-and-development  = 2  (one of only two votes AGAINST the Linda Vista 52 residential
--                                 annexation, Aug 6 2025, 4-2; opposed a major annexation-driven
--                                 housing expansion the majority backed on growth-need grounds —
--                                 a growth-restraining posture)
--
-- DELIBERATELY BLANK (no clearly-mapping documented Cavanaugh position found):
--   Local: campaign-finance, city-sanitation, economic-development, homelessness,
--          homelessness-response, housing, local-environment, public-safety-approach,
--          rent-regulation, residential-zoning, transportation-priorities.
--          local-immigration: a documented position exists (on the proposed Marana ICE
--          detention center he said the town lacks authority to bar a private business —
--          "We can't tell someone, 'you cannot make a living'" — opposed a town resolution
--          against it, while personally hoping it would not be built), but that stance is
--          about a private federal-contract facility's right to operate, NOT about local
--          police cooperation with federal immigration enforcement / detainers, so it does
--          not map to any discrete chair on this topic's axis. Left blank.
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, childcare, civil-rights, climate-change, deportation, fossil-fuels,
--          healthcare, immigration, jail-capacity, medicare/aid, misinformation,
--          redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--          social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Patrick Cavanaugh / data-centers (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb526b61-89e2-4c0f-b60c-f359e7193192',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb526b61-89e2-4c0f-b60c-f359e7193192',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$On Jan. 6, 2026 the Marana Town Council voted 6-0 (Council Member Herb Kai recused for a family conflict of interest) to approve the rezoning of roughly 600 acres for Beale Infrastructure's Luckett Road hyperscale data center, and Cavanaugh was one of the six yes votes. Per Tucson Spotlight, his main concern was "whether energy rates would remain locked in amid grid stress and potential power shortages"; he "entered the meeting leaning toward a no vote but was swayed after hearing arguments in favor of the data center," including a Tucson Electric Power representative's account of rate guarantees before the Arizona Corporation Commission. He framed his yes vote around not letting costs fall on residents ("Nothing goes on the Marana citizens"). Approving the development while conditioning his support on transparency and assurances about projected energy demand and residential rate impacts — rather than demanding a moratorium (1), cost-sharing/community-benefit conditions before approval (3), or welcoming it with minimal scrutiny (5) — best matches encouraging data-center development while requiring transparency about energy demand and rate impacts.$$,
        ARRAY['https://www.tucsonspotlight.org/marana-approves-rezoning-for-massive-data-center-project/',
              'https://news.azpm.org/p/news-topical-politics/2026/1/8/227908-marana-town-council-approves-rezoning-for-luckett-road-project-600-acre-hyperscale-data-center/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick Cavanaugh / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cb526b61-89e2-4c0f-b60c-f359e7193192',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cb526b61-89e2-4c0f-b60c-f359e7193192',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$At the Aug. 6, 2025 Council meeting Cavanaugh was one of only two members to vote against the Linda Vista 52 annexation, which the Council approved 4-2 (Mayor Jon Post recused for a family conflict). The annexation brought roughly 52 acres into the town for a large-scale residential development (conceptual plans of about 212 homes), and the majority backing it cited the town's projected need for more than 14,000 new homes by 2045 to keep pace with population growth. By voting no on a major annexation-driven housing expansion that the pro-growth majority actively supported, Cavanaugh took a growth-restraining posture — favoring slowing large annexation/development approvals rather than streamlining permitting to recruit growth (4-5) or planning proactively to accommodate it (3). That maps to allowing growth cautiously and slowing approvals for major new development.$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/marana/marana-town-council-approves-linda-vista-52-annexation']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
