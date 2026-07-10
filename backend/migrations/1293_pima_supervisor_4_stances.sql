-- =====================================================================================
-- Compass stances: Steve Christy — Pima County (AZ) Board of Supervisors, District 4
-- ext_id: -4007004   politician_id: 41c2b862-78c8-4a27-96c5-50dcdb3a254e
-- Republican; the Board's lone GOP member and longtime supervisor. Elected Nov 2016,
-- seated Jan 2017 (current). A fiscal/limited-government conservative who is very
-- frequently the "1" in 4-1 (and "2" in 3-2) votes — so his positions are unusually
-- well-documented in his recorded dissents and public statements. Where a colleague's
-- file cites a Board vote, Christy typically cast the OPPOSITE vote; the chairs below
-- reflect HIS actual documented position, cited specifically.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position — a recorded
--     Board vote/motion Christy cast, or a clearly documented public statement / campaign
--     platform position while seated — with real cited source URLs confirmed via web research.
--   * All actions cited fall within his tenure (seated Jan 2017 to present).
--   * Topics with no clear documented Christy position emit NO row (honest blank). No party
--     inference, no neutral defaults. Many federal/state (non-local) topics are blank because
--     a county supervisor has no attributable record on them.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (8 topics):
--   climate-change            = 5  (voted NO on the SAPCO sustainability plan AND the Paris-
--                                   Agreement resolution; "grave doubts about the return on the
--                                   investments," called it "a political agenda" / a "swipe at the
--                                   Trump administration" — rejects climate policy, prioritizes growth)
--   data-centers              = 5  (voted YES 3-2 to approve the Project Blue data center — "from a
--                                   business proposition, it's a good deal" — then voted NO on the
--                                   post-hoc NDA-transparency policy, calling it a "farce")
--   jail-capacity             = 4  (opposed the jail "Blue Ribbon Commission" — "where good ideas
--                                   go to die" — and pushed to move directly to construction/remediation
--                                   assessments to fix jail-facility deficiencies)
--   local-environment         = 4  (lone dissent against the resolution opposing the Copper World mine;
--                                   "I want job growth. I want economic development" — sent his own letter
--                                   backing the project; prioritizes economic activity over preservation)
--   local-immigration         = 4  (voted NO on barring ICE from county property — an "overblown response
--                                   to hypothetical events" — lone NO on opposing the Marana detention
--                                   center; long a supporter of Operation Stonegarden border grants)
--   public-safety-approach    = 4  (opposes any "defunding" of the Sheriff — "I support the opposite" —
--                                   favors adding law-enforcement resources; backs Operation Stonegarden)
--   taxes                     = 4  (non-local; opposes property- and sales-tax increases, pledges
--                                   revenue-neutral primary rate / wants it lowered, and consistently
--                                   votes against new county spending)
--   transportation-priorities = 4  (roads are his signature priority — "inundated daily with complaints
--                                   about the roads," ~300 mi repaired in D4, PAYGO road program;
--                                   transportation investment should serve the majority who drive)
--
-- DELIBERATELY BLANK (no clearly attributable documented Christy position found):
--   Local: abortion (his votes against a county resolution/funding are procedural/symbolic, not a
--          documented legal-framework chair), campaign-finance, childcare, city-sanitation,
--          civil-rights, economic-development (mixed signals — small-business/deregulation posture
--          but welcomed the Project Blue major employer; no clean chair), fossil-fuels,
--          growth-and-development, homelessness, homelessness-response, housing (repeated no-votes on
--          affordable-housing funding are documented mainly via a partisan blog; no clean 4-vs-5 chair
--          from neutral corroboration), religious-freedom, rent-regulation, residential-zoning,
--          trans-athletes.
--   Non-local federal/state: ai-regulation, deportation, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers, social-security,
--          tariffs, ukraine-support, voting-rights.
--   (The 2025-26 ICE / county-property / detention-center votes are captured under local-immigration;
--    they are not a documented stance on federal immigration levels or deportation aggressiveness.
--    The Copper World dissent is captured under local-environment; his general economic-development
--    incentive posture is genuinely mixed, so economic-development is left blank.)
-- =====================================================================================

BEGIN;

-- ----- Steve Christy / climate-change (value 5) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Christy voted NO on both the updated County sustainability action plan (SAPCO) and the resolution reaffirming the Paris Agreement emissions goals, saying he had "grave doubts about the return on the investments" and that the plan was "covering up what is a political agenda," dismissing the Paris resolution as "another swipe at the Trump administration." He has similarly voted against extreme-heat mitigation spending. His documented posture is to reject climate-driven policy and prioritize economic growth — chair 5.$$,
        ARRAY['https://www.gvnews.com/news/christy-anti-trump-county-board-is-at-it-again/article_f7a52bec-d738-11e8-941e-bf15e3a7e9bf.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / data-centers (value 5) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Christy was part of the 3-2 majority approving the $3.6B Project Blue data-center agreement on Dec 16, 2025, framing it as "from a business proposition, it's a good deal," and voted NO on the county's after-the-fact NDA-transparency policy change (a 4-1 measure), calling it a "farce." He welcomed the data-center investment for its economic/tax benefits while opposing added transparency and environmental-review guardrails — chair 5.$$,
        ARRAY['https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/',
              'https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / jail-capacity (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$On the overcrowded, deficient Pima County jail, Christy opposed the Board's "Blue Ribbon Commission" study approach — "good ideas go to blue ribbon commissions to die" — and instead urged the county to obtain assessments from local construction companies on whether remediation or new construction was needed, favoring moving directly to fixing/expanding jail facilities to address the deficiencies rather than studying alternatives to incarceration — chair 4.$$,
        ARRAY['https://www.kgun9.com/news/local-news/pima-county-takes-steps-toward-new-jail',
              'https://www.gvnews.com/news/local/christy-concerned-about-new-jail-commission/article_fed5b13c-e25b-11ee-8860-e350f51b4299.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / local-environment (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Christy cast the sole dissenting vote against the Board's resolution opposing the Copper World mine (a project in his District 4), saying "I want job growth. I want economic development. I want workers to have strong family entities," and pledged to send his own letter to stakeholders declaring support for the project — directly contradicting the county's environmental opposition. He consistently prioritizes economic activity/jobs over environmental preservation — chair 4.$$,
        ARRAY['https://www.tucsonspotlight.org/pima-supervisors-pass-resolution-opposing-copper-world-mine/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / local-immigration (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Christy repeatedly opposed county measures restricting federal immigration enforcement: he voted NO (Feb 2026) on the policy barring ICE/federal immigration agents from using county property, calling it "an overblown response to hypothetical events," and cast the lone NO vote on the 4-1 resolution opposing the proposed Marana immigration detention center. He is a longtime backer of Operation Stonegarden border-enforcement grants. His documented position is to cooperate with — and not obstruct — federal immigration enforcement — chair 4.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/2/17/228516-pima-county-supervisors-adopt-policy-restricting-use-of-county-property-by-federal-immigration-agents/',
              'https://news.azpm.org/p/news-articles/2026/2/3/228293-pima-county-supervisors-pass-resolution-opposing-marana-detention-center/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Christy explicitly rejects any "defunding" of the Pima County Sheriff's Department — asked about reallocating police funds, he said "I support the opposite," favoring adding resources rather than shifting duties away from law enforcement. He supports Operation Stonegarden law-enforcement grants and has cited vaccine-mandate-driven staffing losses as a problem to reverse. His documented posture is to increase police staffing/resources — chair 4.$$,
        ARRAY['https://news.azpm.org/pimacountysupervisor.d4/',
              'https://www.tucsonspotlight.org/christy-eyes-third-term/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / taxes (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Christy opposes county property- and sales-tax increases, pledging to keep property-tax revenue neutral (and arguing the primary rate could be lowered further to offset rising assessments), while consistently voting against new county spending — he has cast ~99 dissenting "no" votes in a single year on spending items. His documented fiscal position is to cut/hold taxes and scale back public spending accordingly — chair 4.$$,
        ARRAY['https://www.tucsonspotlight.org/christy-eyes-third-term/',
              'https://news.azpm.org/pimacountysupervisor.d4/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steve Christy / transportation-priorities (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('41c2b862-78c8-4a27-96c5-50dcdb3a254e',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Road repair is Christy's signature priority: "When I first took office in 2017, I was inundated daily with complaints about the roads," and he credits ~300 miles of road repairs in District 4, championing the "Pay As You Go" (PAYGO) road-repair program and renewal of the RTA. His transportation focus is on roads/traffic flow for the majority who drive rather than multimodal/transit investment — chair 4.$$,
        ARRAY['https://www.tucsonspotlight.org/christy-eyes-third-term/',
              'https://news.azpm.org/pimacountysupervisor.d4/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
