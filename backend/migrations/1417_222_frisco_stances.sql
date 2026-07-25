-- =====================================================================================
-- Phase 222 (plan 222-03) — Compass stances: City of Frisco, TX (geo_id 4827684)
-- Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * Every seeded chair rests on an explicit, on-topic, dated statement in a source that
--     was actually fetched and read this session (campaign platform page, candidate
--     questionnaire, or editorial-board Voter Guide answer). No party inference, no
--     identity inference, no city-policy default, no adjacency inference (board service,
--     profession, tenure), no defaulted middle values.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Frisco, TEXAS confirmed on every source (homonym guard: Frisco also exists in CO
--     and NC). "Mark Hill" specifically confirmed as the Frisco TX mayor elected in the
--     June 13, 2026 runoff and sworn in July 7, 2026.
--
-- SCOPE: the two un-stanced Frisco officeholders on the 222-01 live worklist.
--   Brittany Colberg — Council Member Place 6 — ddcb2d35-0f94-4956-ab65-ae56a900ac11
--   Mark Hill        — Mayor              — 3579e02c-d480-48ba-8d95-3eb7f002a5b0
-- The other five seated Frisco officeholders already hold stances and are out of scope
-- per D-07 (no overwrite pass). Gopal Ponangi is un-seated and is not touched; Place 4 is
-- Jared Elad, who already holds stances and is therefore not in this file (Pitfall 3).
--
-- SEEDED (7 rows / 7 answer+context pairs):
--   Brittany Colberg (1)
--     housing                   = 3  (Voter Guide: encourage targeted additional housing for
--                                     young families/teachers/first responders/seniors while
--                                     keeping development standards consistent)
--   Mark Hill (6)
--     housing                   = 4  (platform: "Housing is and should remain market-driven.
--                                     Government is not the developer"; slash red tape)
--     residential-zoning        = 3  (platform: oppose+repeal SB 840, local control; reinvest
--                                     in Rail District corridors; protect established
--                                     neighborhoods)
--     growth-and-development    = 3  (platform: "Frisco has always built ahead of its growth,
--                                     and I will continue that discipline")
--     public-safety-approach    = 4  (platform: public-safety personnel/infrastructure/resources
--                                     "scale proactively with our growing population")
--     taxes                     = 3  (platform: protect the existing low rate, 20% homestead
--                                     exemption and senior tax freeze; no tax increase and no
--                                     service scale-back proposed)
--     transportation-priorities = 3  (platform: "We cannot build our way out of congestion";
--                                     expand DCTA transit partnership, trails, smart signals)
--
-- DELIBERATELY BLANK (15 person/topic pairs — see 222-CONFIRMED-BLANK.md for each):
--   Colberg: civil-rights, homelessness, economic-development, local-immigration,
--            public-safety-approach, residential-zoning, transportation-priorities, taxes,
--            growth-and-development, healthcare.
--   Hill:    civil-rights, homelessness, economic-development, local-immigration, healthcare.
--   Two chairs were demoted to blank during the pre-commit self-audit because the evidence,
--   while real and on-topic, could not separate two adjacent chairs: Colberg /
--   growth-and-development (chair 2 vs 3) and Hill / economic-development (chair 3 vs 4).
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Brittany Colberg — Council Member Place 6, City of Frisco, TX
-- politician_id: ddcb2d35-0f94-4956-ab65-ae56a900ac11
-- Elected May 2, 2026 (57% of the vote); sworn in May 21, 2026; term expires May 2029.
-- =====================================================================================

-- ----- Brittany Colberg / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ddcb2d35-0f94-4956-ab65-ae56a900ac11',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ddcb2d35-0f94-4956-ab65-ae56a900ac11',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $stz$Asked about housing affordability in the Dallas Morning News Voter Guide for the May 2026 Frisco Place 6 race, Colberg wrote: "I would encourage thoughtful development of additional housing for young families, teachers, first responders, and seniors with standards that remain consistent with the high-quality our community expects" (quoted in the paper's April 16, 2026 recommendation, which framed it as her answer to Frisco "becoming a place that's out of reach for young families"). She commits the city to actively encouraging additional housing aimed at specific groups priced out of Frisco, which is targeted municipal help rather than staying out of the market or building housing publicly. Her own qualifier that development standards must "remain consistent" cuts against the deregulatory chair, and the same article records her opposition to Senate Bill 840, the state law that overrides local development rules to force by-right multifamily. She proposes no rent caps, mandated affordable set-asides, or public housing funds.$stz$,
        ARRAY['https://www.yahoo.com/news/articles/frisco-city-council-place-6-070000674.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Mark Hill — Mayor, City of Frisco, TX
-- politician_id: 3579e02c-d480-48ba-8d95-3eb7f002a5b0
-- Won the June 13, 2026 mayoral runoff (58%, 19,632 votes) over Rod Vilhauer; sworn in
-- July 7, 2026. Positions below are taken from his own campaign platform page and his own
-- answers to Community Impact Newspaper's runoff candidate questionnaire.
-- =====================================================================================

-- ----- Mark Hill / housing (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $stz$Hill's campaign platform states his housing position directly under "Housing & Affordability": "Housing is and should remain market-driven. Government is not the developer. What Council can do is remove barriers, create smart incentives, and ensure zoning supports the right density in the right places." His stated route to affordability is deregulatory and supply-side — he pledges to "Deliver actual affordability by slashing red tape and streamlining permits to lower building costs and let the market drive down prices for families," and adds that "Protecting the dream of homeownership requires defending private property rights and maintaining low property taxes." That is cutting rules and costs so private builders produce more housing, rather than public development, rent regulation, or mandated affordable set-asides. He does not withdraw government entirely — he assigns Council an active role in removing barriers, offering incentives, and zoning for "the right density in the right places," and names senior and missing-middle housing as gaps to address.$stz$,
        ARRAY['https://markhill4mayor.com/policies/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Hill / residential-zoning (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$Hill's platform commits him to "Oppose and Repeal SB 840; Support local control of zoning" and, separately, to "Oppose SB 840's blanket density mandates for local cities" — SB 840 being the 2025 Texas law that forces cities to permit multifamily by right in commercially zoned areas with reduced parking, so he explicitly rejects broad by-right upzoning imposed citywide. What he affirmatively supports is directing density to specific corridors while leaving existing neighborhoods alone: he pledges to "Reinvest in Rail District corridors," to "Support market-driven, mixed-use housing solutions," and to "ensure zoning supports the right density in the right places," while promising to "honor our Comprehensive Plans established by residents, protect established neighborhoods, and ensure every land use decision is evaluated through one lens: Does it make Frisco better for the people already here?" He names senior and missing-middle housing as gaps to address, so he is not seeking to freeze all rezoning or require a community vote before any change.$stz$,
        ARRAY['https://markhill4mayor.com/policies/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Hill / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $stz$Under "Stay Ahead of Infrastructure Demands" Hill's platform states: "Frisco has always built ahead of its growth, and I will continue that discipline. I will help complete projects on time and on budget, advance northern corridor road investments, and ensure utility and underground systems are replaced strategically before they become problematic." His platform frames the issue as management rather than pace — "Frisco's greatest challenge is not growth itself; it is failing to manage that growth with discipline, foresight, and financial integrity" — a formulation he repeated in his own answer to Community Impact Newspaper's May 14, 2026 runoff questionnaire: "Frisco's greatest risk isn't growth itself; it's failing to manage growth with discipline. Increasing demands on public safety, infrastructure and city services will pressure our budget and long-term planning." With "only 13% of land remaining and most already zoned," he says Frisco's focus "must shift from new development to smart reinvestment" guided by the resident-adopted Comprehensive Plans. He proposes no growth cap or voter-approval requirement, does not propose slowing approvals until capacity catches up, and does not propose reducing fees to recruit development.$stz$,
        ARRAY['https://markhill4mayor.com/policies/',
              'https://communityimpact.com/dallas-fort-worth/frisco/election/2026/05/14/qa-meet-the-candidates-in-friscos-runoff-election-for-mayor']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Hill / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $stz$Hill's platform lists "Public Safety First" as his first priority and commits to growing the department's resourcing: "I will ensure our public safety infrastructure, personnel, and resources scale proactively with our growing population, never reactively. Frisco's reputation as one of America's safest cities did not happen by accident, and it will not maintain itself without deliberate investment." In his own answer to Community Impact Newspaper's May 14, 2026 runoff questionnaire he named "safety" his first priority and identified "Increasing demands on public safety, infrastructure and city services" as the pressure on Frisco's budget. That is a commitment to add personnel and equipment as the city grows, rather than holding funding flat, and his platform proposes no crisis-response, co-responder, or mental-health-diversion component and no reallocation of the police budget. He also does not make police spending the city's overriding budget priority — the same platform commits him to fiscal discipline, a low tax rate, infrastructure, and parks, and states that "Government should not grow faster than the people it serves can afford."$stz$,
        ARRAY['https://markhill4mayor.com/policies/',
              'https://communityimpact.com/dallas-fort-worth/frisco/election/2026/05/14/qa-meet-the-candidates-in-friscos-runoff-election-for-mayor']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Hill / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $stz$Hill's platform priority "Protect Our Low Tax Rate Through Smart Growth" keeps the existing tax arrangement in place rather than raising or cutting it: "Government should not grow faster than the people it serves can afford. I will continue attracting quality commercial development that offsets the residential tax burden, scrutinize every expenditure with business-owner discipline, and empower the EDC and CDC to keep delivering the economic results that have kept Frisco's tax rate among the lowest in the region." His fiscal bullets commit him to "Protect 20% Homestead Exemption, Senior Tax Freeze" and that "Every bond dollar must be justified with clear ROI," and in his own answer to Community Impact Newspaper's May 14, 2026 runoff questionnaire he pledged to "balance growth, keep tax rates low." He proposes no tax increase of any kind, and he proposes no reduction in public services to match a tax cut — the same platform commits him to scaling public safety, replacing utility systems, and investing in parks and trails.$stz$,
        ARRAY['https://markhill4mayor.com/policies/',
              'https://communityimpact.com/dallas-fort-worth/frisco/election/2026/05/14/qa-meet-the-candidates-in-friscos-runoff-election-for-mayor']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mark Hill / transportation-priorities (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3579e02c-d480-48ba-8d95-3eb7f002a5b0',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $stz$Hill's platform section "Transportation & Mobility" opens by rejecting road-capacity expansion as the answer: "Traffic is a regional challenge demanding regional solutions. We cannot build our way out of congestion, but we can outthink it with smart, macro, and technology-driven mobility solutions." He keeps investing in the road network — he pledges to "advance northern corridor road investments" and to "Invest in smart signals, connected vehicle data, roundabouts" — while adding transit and pedestrian connections selectively through partnerships rather than a citywide build-out: "Expand Denton County Transit Authority (DCTA) partnership and rideshare integration," "Represent Frisco's interests in Regional Transportation Council Transit 2.0," and "Focus on connectivity, trails, and universal accessibility." He does not propose reducing parking requirements citywide, and he does not propose requiring bike lanes and sidewalks on all new road projects.$stz$,
        ARRAY['https://markhill4mayor.com/policies/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
