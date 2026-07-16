-- =====================================================================================
-- Compass stances: Jon Post — Mayor, Town of Marana (AZ)
-- politician_id: 3b09d8a3-641f-43f9-b3cc-0ce695b54aef
-- Nonpartisan. Appointed Mayor Jan. 7, 2025 after the death of Mayor Ed Honea (he had
-- served as Vice Mayor / a councilmember before that); running in the July 21, 2026
-- special election to finish Honea's term. Mayoral positions attributed only to his
-- time as Mayor (Jan. 2025-present); no other person's positions attributed to him.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Post position (a recorded
--     Council vote or an on-record public statement in a citable article) taken as Mayor,
--     with real cited source URLs confirmed via web research.
--   * Topics with no clear documented Post position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (6 topics):
--   data-centers              = 4  (championed the unanimous Jan. 6 2026 data-center rezoning; "cannot ignore opportunities"; relies on town ordinance guidelines + disclosed water/drainage)
--   growth-and-development    = 4  ("If you're not growing, you're dying"; 800-1,000 permits/yr; actively recruits development to grow the tax base and avoid a property tax)
--   economic-development      = 4  (data center as "catalyst" for other business; business-friendly reputation; ~$15M/yr + infrastructure investment)
--   taxes                     = 3  (defends Marana's no-property-tax status quo; fund services through growth "unless we're willing to put property tax on ourselves")
--   local-immigration         = 3  (calls the ICE facility a "federal issue," town's "hands are tied"; declines a town resolution; negotiated a 775 cap + inspection access rather than active local involvement)
--   transportation-priorities = 4  (road building "has really stepped up... something I've pushed on really, really hard"; no multimodal/transit commitments on record)
--
-- DELIBERATELY BLANK (no clean, attributable documented Post position found):
--   Local: campaign-finance, city-sanitation, homelessness, homelessness-response, housing,
--          local-environment, public-safety-approach, rent-regulation, residential-zoning.
--          (His high-permit-volume growth comments are captured under growth-and-development;
--          "maintaining public safety" and "balancing development with parks" were named as
--          priorities but with no vote/budget/standard specific enough to map to a chair.)
--   Non-local federal/state (a town mayor has no record on these): abortion, ai-regulation,
--          civil-rights, climate-change, deportation, fossil-fuels, healthcare, immigration,
--          jail-capacity, medicare/aid, misinformation, redistricting, religious-freedom,
--          same-sex-marriage, school-vouchers, social-security, tariffs, trans-athletes,
--          ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Jon Post / data-centers (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$As Mayor, Post championed the Beale Infrastructure data center. At the Jan. 6, 2026 Council meeting the Marana Town Council voted unanimously to rezone roughly 600 acres for the project, with Post declaring, "Marana cannot be the community that ignores opportunities. We are going to create an area in our community where jobs are going to come." He has said "I think data centers can be done safely in a community," that "they take careful planning, and you gotta make sure that you have the guidelines in place," and that "they're not the danger that you're reading about on social media," while touting a projected ~$15 million a year for the town, developer-funded drainage work "that the town really needs," and a "closed loop" cooling system he says will use no ongoing water. Rather than a moratorium (chair 1), self-funded power / ratepayer protection (chair 2), or new pre-approval community-benefit agreements (chair 3), Post welcomes and encourages the development while pointing to the town's existing ordinance guidelines and disclosed water/drainage/energy commitments to keep it in compliance — matching encouraging data-center development through the existing permitting framework with transparency about its impacts (chair 4).$$,
        ARRAY['https://www.azfamily.com/2026/01/09/two-southern-arizona-data-centers-move-forward-so-do-fights-over-power-water-growth/',
              'https://www.kgun9.com/news/community-inspired-journalism/marana/marana-mayor-seeks-elected-term-tackling-data-center-ice-facility-and-rapid-growth',
              'https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Post / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Post is an unabashed pro-growth mayor. He told voters "If you're not growing, you're dying," said the data center "will be a catalyst for other businesses to move into the town," and pointedly contrasted Marana with Oro Valley, which "haven't had any growth, whether it be residential or commercial, in a long time." He defends Marana's pace — "I've heard that Marana is growing too fast, but we're actually growing at the same rate that we have grown for the last 20 years," issuing 800-1,000 housing permits a year, which he calls "very important to continue to do" — and ties continued growth directly to the tax base: "We have to continue to grow unless we're willing to put property tax on ourselves." That posture of actively recruiting development and pushing stalled projects forward to grow the tax base — rather than growth caps (chair 1), pausing until infrastructure catches up (chair 2), or simply planning infrastructure ahead of growth (chair 3) — matches streamlining approvals and actively recruiting development to grow the tax base (chair 4).$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html',
              'https://www.kgun9.com/news/community-inspired-journalism/marana/marana-mayor-seeks-elected-term-tackling-data-center-ice-facility-and-rapid-growth']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Post / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Post's economic-development strategy is active recruitment of major employers to build Marana's reputation as business-friendly. On the data center he said, "My hope for Marana is that this data center leads to big job growth. It's important we try to accommodate this. The word gets out to other companies and then it's, 'Let's not go to Marana because they'll just say no,'" and framed the project as "a catalyst for other businesses to move into the town," citing a projected ~$15 million a year for the town plus developer-funded infrastructure (drainage) the town needs. Encouraging job growth is one of his stated priorities if elected. Competing aggressively for large employers and pairing recruitment with infrastructure investment — rather than no incentives / organic growth (chair 1) or small-business-only support (chair 2) — matches actively competing for major employers with infrastructure investment (chair 4).$$,
        ARRAY['https://azluminaria.org/2026/06/22/marana-2026-election-guide-what-candidates-say-about-ice-detention-center-data-center/',
              'https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html',
              'https://www.kgun9.com/news/community-inspired-journalism/marana/marana-mayor-seeks-elected-term-tackling-data-center-ice-facility-and-rapid-growth']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Post / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Post's tax posture is to preserve Marana's existing revenue structure — the town has no property tax — and fund services through growth rather than new levies. He noted that "Marana does not have a property tax" and argued "We have to continue to grow unless we're willing to put property tax on ourselves," positioning economic growth (sales-tax base, data-center revenue) as the alternative to imposing a new tax on residents. That is neither raising taxes on the wealthy/business to expand or sustain services (chairs 1-2) nor cutting existing taxes and scaling back services (chairs 4-5); it is defending the current tax system largely as-is — keeping the no-property-tax status quo and covering services through growth — which matches keeping the current tax system mostly as-is (chair 3).$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Post / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On the proposed ICE detention center at the former state prison on West Silverbell Road, Post has repeatedly framed the town's role as limited and passive: "Because it was a prison and they have the correct zoning, there's not a lot that we could do or should do to stop it. This is not a Marana issue. This is a federal issue," and, on residents' objections, "whether we agree or not agree, we don't have anything to do with that at this point in time." He declined to bring a town resolution against the facility, calling it "meaningless" and divisive, and instead directed constituents to their congressional representatives. His only assertive step was accountability-oriented, not enforcement: negotiating with operator MTC that "the Town does not support expanding the facility beyond the 775-person capacity" and securing ongoing town inspection access. Declining to use town authority either to obstruct or to proactively involve local government in federal immigration operations — treating it strictly as a federal matter the town follows but does not drive — matches following federal law as required without committing local resources to proactive immigration enforcement (chair 3), rather than refusing all cooperation (chairs 1-2) or directing local resources to assist enforcement (chairs 4-5).$$,
        ARRAY['https://azluminaria.org/2026/06/22/marana-2026-election-guide-what-candidates-say-about-ice-detention-center-data-center/',
              'https://www.kgun9.com/news/community-inspired-journalism/marana/marana-mayor-seeks-elected-term-tackling-data-center-ice-facility-and-rapid-growth',
              'https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Post / transportation-priorities (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3b09d8a3-641f-43f9-b3cc-0ce695b54aef',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Post's documented transportation emphasis is roadbuilding for a fast-growing, car-oriented town. He told voters, "Our infrastructure, our road building has really stepped up. That is something that I've pushed on really, really hard," and pointed to long-stalled projects that "have languished for many years starting to take shape." His stated transportation record centers on expanding road capacity to serve continued residential and commercial growth, with no transit, bike, or pedestrian-network commitments on record. Prioritizing road capacity to serve the driving majority — rather than prioritizing transit/cycling/pedestrian investment (chairs 1-2) or road maintenance with selective multimodal additions (chair 3) — matches focusing transportation investment on road capacity (chair 4).$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/marana-incumbents-face-voters/article_d16cd57f-a8b6-44e7-987e-4a65e6ea226d.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
