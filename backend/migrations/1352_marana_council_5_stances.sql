-- =====================================================================================
-- Compass stances: Teri Murphy — Council Member, Town of Marana (AZ)
-- politician_id: e974aae0-fd87-4bf7-91dc-6935533a80ba
-- Nonpartisan; APPOINTED Jan/Feb 2025 to fill the council seat vacated by Jon Post
-- (appointed Mayor). Running in the July 21, 2026 election for voter approval.
-- Documented tenure = Jan 2025–present. Positions attributed ONLY to her council
-- record (Jan 2025→present) or her 2026 campaign — no pre-appointment attribution.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Murphy position (a
--     recorded Council vote plus on-record statements / candidate-forum answers) taken
--     during her tenure or her 2026 campaign, with real cited source URLs confirmed via
--     web research.
--   * Topics with no clear documented Murphy position emit NO row (honest blank). No
--     party inference, no neutral defaults. Her tenure is short; thin coverage is expected.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (2 topics):
--   data-centers            = 4  (voted FOR the 600-acre data-center rezoning; defended the
--                                 ordinance citing benefit to "fire, police, and our community";
--                                 welcoming/encouraging, not moratorium or cost-sharing conditions)
--   growth-and-development  = 4  ("only 35% of our land is developed... gives us an opportunity
--                                 for growth"; wants "more employment opportunities come to the
--                                 community" — actively welcomes/recruits development)
--
-- DELIBERATELY BLANK (no attributable documented Murphy position found):
--   Local: city-sanitation, homelessness, homelessness-response, housing, jail-capacity,
--          local-environment, public-safety-approach, rent-regulation, residential-zoning,
--          transportation-priorities.
--          - economic-development: she wants "more employment opportunities," but stated NO
--            incentive strategy (tax abatements, community-benefit / job-quality requirements),
--            so the incentive-axis chairs cannot be placed; her general growth/jobs posture is
--            already captured under growth-and-development.
--          - local-immigration: her only ICE-facility remark was procedural (an expansion would
--            need Council approval); she took NO stance on local police cooperation with ICE or
--            honoring detainers, which is what this axis measures. No forced mismatch.
--          - campaign-finance: she declines PAC/corporate donations as a personal campaign
--            practice, but has not advocated any legal framework for money in politics.
--          - taxes: the $407M figure is the data center's projected revenue, not a Murphy
--            position on town taxation or spending levels.
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, civil-rights, climate-change, deportation, fossil-fuels, healthcare,
--          immigration, medicare/aid, misinformation, redistricting, religious-freedom,
--          same-sex-marriage, school-vouchers, social-security, tariffs, trans-athletes,
--          ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Teri Murphy / data-centers (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e974aae0-fd87-4bf7-91dc-6935533a80ba',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e974aae0-fd87-4bf7-91dc-6935533a80ba',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$In January 2026 the Marana Town Council approved the rezoning of ~600 acres for a large data-center project; AZ Luminaria and AZPM report that Council members Officer and Murphy voted in favor (Council member Kai, whose family owns one of the parcels, was absent/recused). Defending the ordinance to critics, Murphy said: "I'm with you guys. I think that there's a lot of research that needs to be done, but at the same time what it does for the fire, police, and our community is kind of something that we really need to look at as well." She voted to enable/encourage the development and framed it around its benefit to town services and the community (the project is projected to generate ~$407M in tax revenue over ten years), while acknowledging that more research is needed — she did not seek a moratorium, bar cost pass-throughs, or attach energy cost-sharing / community-benefit conditions to her vote, nor did she advocate special incentives or removing regulatory barriers. That record — approving and encouraging the data-center development through the normal rezoning process, welcoming it for its fiscal/community benefit while noting open questions — best matches encouraging data-center development while acknowledging the need for scrutiny, rather than the moratorium/hard-conditions end (chairs 1–3) or a minimal-barriers-with-incentives posture (chair 5).$$,
        ARRAY['https://azluminaria.org/2026/06/22/marana-2026-election-guide-what-candidates-say-about-ice-detention-center-data-center/',
              'https://tucson.com/news/local/government-politics/elections/article_675b18f9-b117-4be9-b64d-266288fc3815.html',
              'https://news.azpm.org/p/news-splash/2026/7/11/230486-marana-town-council-candidates-discuss-data-center-growth-and-proposed-ice-detention-facility-at-forum/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Teri Murphy / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e974aae0-fd87-4bf7-91dc-6935533a80ba',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e974aae0-fd87-4bf7-91dc-6935533a80ba',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$At the July 10, 2026 League of Women Voters candidate forum (reported by AZPM July 11), Murphy framed Marana's large stock of undeveloped land as an opportunity to grow: "The good news about Marana is we have 123 miles and only 35% of our land is developed. I think that gives us an opportunity for us to have growth." She added, "I think that it's important that we have more employment opportunities come to the community." That, together with her January 2026 vote to approve the 600-acre data-center rezoning, reflects an actively pro-growth posture that welcomes and recruits new development to expand employment and the tax base, rather than imposing growth limits (chair 1), gating growth on existing infrastructure capacity (chair 2), or a cautious infrastructure-ahead-of-growth approach (chair 3). She did not call for removing regulatory barriers entirely (chair 5), so value 4 — streamlining and actively recruiting development to grow the tax base — is the best fit.$$,
        ARRAY['https://news.azpm.org/p/news-splash/2026/7/11/230486-marana-town-council-candidates-discuss-data-center-growth-and-proposed-ice-detention-facility-at-forum/',
              'https://azluminaria.org/2026/06/22/marana-2026-election-guide-what-candidates-say-about-ice-detention-center-data-center/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
