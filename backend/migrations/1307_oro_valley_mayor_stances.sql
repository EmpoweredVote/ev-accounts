-- =====================================================================================
-- Compass stances: Joseph "Joe" Winfield — Mayor, Town of Oro Valley (AZ)
-- politician_id: d3009d53-a6f0-4ea0-b41d-658ce62e3753
-- Nonpartisan; Mayor since 2018 (re-elected 2022); not seeking reelection in 2026.
-- Documented tenure = 2018–present. Positions attributed only to his mayoral record.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Council
--     vote/motion or on-record public statement / State of the Town address) taken during his
--     tenure as Mayor, with real cited source URLs confirmed via web research.
--   * Topics with no clear documented Winfield position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (5 topics):
--   growth-and-development    = 3  (proactive build-out planning + infrastructure ahead of growth; opposes vertical density)
--   economic-development      = 2  (small business "heartbeat"; cut big speculative projects for fiscal prudence)
--   public-safety-approach    = 4  ($33M PSPRS full-funding, new police station, 4-yr union MOU)
--   taxes                     = 2  (Jan 14 2026 voted FOR three new taxes to fund existing services; "forward-looking governance")
--   transportation-priorities = 3  (roadway pavement preservation + selective multi-use path build-out)
--
-- DELIBERATELY BLANK (no attributable documented Winfield position found):
--   Local: campaign-finance, city-sanitation, homelessness, homelessness-response, housing,
--          local-environment, local-immigration, rent-regulation, residential-zoning.
--          (Water-resilience investment is real but has no matching compass topic; open-space /
--          parks spending does not map cleanly to the local-environment development-review chairs.)
--   Non-local federal/state (a town mayor has no record on these): abortion, ai-regulation,
--          civil-rights, climate-change, data-centers, deportation, fossil-fuels, healthcare,
--          immigration, jail-capacity, medicare/aid, misinformation, redistricting,
--          religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs,
--          trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Joe Winfield / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$In his State of the Town addresses Winfield has framed Oro Valley as "approaching build-out" and said the town is managing the transition by "planning ahead through strategic annexations, redevelopment, and tourism growth to keep revenue stable," adding that officials are "looking ten years down the road to make sure Oro Valley stays a great place to live." He cast core local-government purposes as "public safety, public works — meaning our roads, water, stormwater. Also parks and recreation and land use," i.e. investing in infrastructure to support how the community "will continue to develop physically." During the Jan. 14, 2026 tax debate he also said he believes public opinion in Oro Valley is against growing "vertically" like denser built-out Arizona cities. That record — proactive infrastructure planning ahead of a managed, low-density expansion — matches planning proactively and investing in infrastructure to support responsible growth, rather than hard growth caps or removing barriers entirely.$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/oro-valley/winfield-delivers-state-of-the-town-calls-small-business-oro-valleys-heartbeat',
              'https://www.kgun9.com/news/community-inspired-journalism/oro-valley/oro-valley-mayor-lays-foundation-for-towns-future-during-state-of-the-town-address',
              'https://news.azpm.org/p/azpmnews/2026/1/15/228000-tax-debate-in-oro-valley-signals-the-end-of-a-high-growth-era/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Winfield / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Winfield's economic-development posture centers on small business and fiscal caution rather than large subsidized megaprojects. In his State of the Town address he called small businesses "the heartbeat of the community" and said "Businesses are moving in, families are moving in, and that's what drives our local economy forward." When the Council adopted the town's leisure-travel/tourism plan on May 20 (6-1), Winfield successfully moved to strip out the "Big Ideas and Action Plans" section — proposed marquee projects such as a performing-arts venue and a public market hall — citing "the town's existing financial commitments and competing infrastructure priorities" and saying the process used to elevate those ideas "was flawed and did not provide sufficient council direction or community consensus." Backing small business and organic activity while declining to commit the town to large speculative development spending matches a small-business-focused approach that avoids large subsidies.$$,
        ARRAY['https://www.kgun9.com/news/community-inspired-journalism/oro-valley/winfield-delivers-state-of-the-town-calls-small-business-oro-valleys-heartbeat',
              'https://www.tucsonspotlight.org/oro-valley-adopts-tourism-plan-cuts-major-projects/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Winfield / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Winfield's Council has consistently invested in and expanded police resources and compensation. He championed a $33 million investment to fully fund the town's Public Safety Personnel Retirement System (PSPRS) obligation for police — which he called "a bold decision that will save taxpayers an estimated $20 million through 2038," noting that "fully funding PSPRS is still uncommon in Arizona" and crediting it with protecting core services and supporting officers. He also cited a new four-year memorandum of understanding with the police unions and the purchase and renovation of a new police station as "a practical, cost-effective way to meet community needs." That documented pattern of increasing investment in police pay, benefits and facilities aligns with strengthening police staffing/equipment/pay rather than redirecting the police budget or adding non-police crisis teams.$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/investments-for-a-resilient-tomorrow/article_cb9854b7-4343-44e8-bb99-fcd214bbb8dc.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Winfield / taxes (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Facing declining town revenue (construction-tax receipts down ~30% year-over-year, falling state shared revenue and gas-tax income), Winfield voted at the Jan. 14, 2026 Council meeting (reported by AZPM Jan. 15) in favor of all three proposed new taxes brought to the Council: a 2.5% use tax on untaxed large purchases (approved 4-3) and 2.5% taxes on telecommunications providers and on commercial landlords (both rejected). He said, "I don't believe that the town is in crisis. I believe that this is forward-looking governance." Voting to raise revenue — including levies aimed at businesses — to sustain existing town services, while explicitly denying a crisis or calling for deep cuts, matches a moderate revenue-raising approach to fund existing services rather than keeping taxes flat or cutting them.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/1/15/228000-tax-debate-in-oro-valley-signals-the-end-of-a-high-growth-era/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe Winfield / transportation-priorities (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3009d53-a6f0-4ea0-b41d-658ce62e3753',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Winfield's transportation record prioritizes maintaining the road network while selectively adding pedestrian/bike facilities where safety warrants. In his State of the Town address he highlighted that Oro Valley's pavement-preservation program "continues to extend roadway life, saving taxpayers money over time." At the same time, his administration pursued and, in November 2025, began construction of a 1.75-mile, 10-foot multi-use path along Naranja Drive — one of the only town roads then lacking a protected sidewalk or path — funded largely by ~$3.5M in federal Transportation Alternatives grants plus RTA money (town share under 9%), to connect neighborhoods to Naranja Park, the library and businesses after a 2023 pedestrian fatality. Maintaining roads while adding targeted pedestrian/bike improvements where density and safety support it matches the balanced, road-plus-selective-multimodal chair.$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/news/investments-for-a-resilient-tomorrow/article_cb9854b7-4343-44e8-bb99-fcd214bbb8dc.html',
              'https://www.kold.com/2025/11/18/oro-valley-begins-construction-multi-use-path-along-naranja-drive/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
