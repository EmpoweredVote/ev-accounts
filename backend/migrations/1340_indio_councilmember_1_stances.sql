-- =====================================================================================
-- Compass stances: Glenn Miller — City of Indio (CA) City Council, District 1
-- ext_id: -4012001   politician_id: 13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2
-- Nonpartisan municipal office (party not stored/displayed). Four-term councilmember
-- (first elected 2008); District Director for a CA State Senator; longtime Indio businessman.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record campaign
--     platform statement or council action) with a real cited source URL confirmed via web research.
--   * Topics with no clearly attributable Miller position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--   * City Council is a legislative (non-court-scoped) office — no court-scoped topics are referenced.
--   * Reasoning is dollar-quoted ($$...$$); sources are a text[] literal — no scraped text is
--     interpolated into DDL (injection-safe).
--
-- SEEDED (5 topics):
--   housing                = 4  (pro-supply via private builders: 2,700+ units planned/under
--                                construction, longtime developer/home-builder relationships,
--                                "leader in building activity" in Eastern Riverside County)
--   homelessness-response  = 3  ($1M to Martha's Village & Kitchen + 3 dedicated homeless-outreach
--                                police officers / Quality-of-Life Team: services + shelter with
--                                reasonable public-space enforcement)
--   economic-development   = 4  (actively recruits/retains businesses as a stated priority; touts
--                                Indio as among the fastest-growing cities and the regional
--                                business-activity leader)
--   growth-and-development = 4  (actively recruits development and streamlines building to grow the
--                                city's tax base — "leader in generating the most building activity")
--   public-safety-approach = 4  ("a safe city is a prosperous city"; public safety is the "most
--                                important issue of local government"; added officers and strongly
--                                opposes any reduction to police/fire operating budgets)
--
-- DELIBERATELY BLANK (no clearly attributable individual documented position found this pass):
--   transportation-priorities, local-environment, climate-change, residential-zoning,
--   rent-regulation, city-sanitation, campaign-finance, redistricting, local-immigration,
--   childcare, civil-rights, data-centers, homelessness (national), jail-capacity, and all
--   non-local state/federal topics (abortion, immigration, deportation, healthcare, medicare/aid,
--   social-security, taxes, tariffs, fossil-fuels, ai-regulation, misinformation, religious-freedom,
--   same-sex-marriage, trans-athletes, school-vouchers, voting-rights, ukraine-support, etc.) — a
--   city councilmember has no governing record on those.
-- =====================================================================================

BEGIN;

-- ----- Glenn Miller / housing (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Miller's documented housing approach is supply-through-private-development. He has led the effort to build more housing — his platform notes more than 2,700 housing units planned or under construction — and frames it around jobs and growth: "if we want to create more jobs, we need more homes for people to live." Over more than a decade he has built working relationships with home builders and developers, and touts Indio as the leader in generating the most building activity in Eastern Riverside County. That record — facilitating private builders to increase overall housing production, rather than directly building public housing or leading with rent caps/affordability mandates — aligns with reducing regulatory and zoning friction so private developers can build more housing.$$,
        ARRAY['https://glennmiller4indio.com/the-issues',
              'https://ukenreport.com/glenn-miller-seeks-fourth-term-in-indio/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Glenn Miller / homelessness-response (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Miller's documented homelessness record combines service/shelter investment with public-space enforcement. He states "nobody should be homeless in Indio," committed $1 million to Martha's Village & Kitchen for regional shelter and services, and separately added three full-time police officers dedicated to homeless-population outreach and expanded the Police Department's "Quality of Life Team." Pairing shelter/service funding with a dedicated police outreach/quality-of-life presence — rather than a pure housing-first, no-enforcement model or an enforcement-first camping-ban model — aligns with investing in outreach, shelter, and services while enforcing reasonable public-space rules.$$,
        ARRAY['https://glennmiller4indio.com/the-issues']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Glenn Miller / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Miller runs on aggressive business attraction and growth. He names recruiting and retaining businesses as a top priority, highlights Indio as among the fastest-growing cities in California and the nation, and points to the city leading Eastern Riverside County in new business start-ups and building activity. That posture — competing actively to bring in and grow employers and development as a central economic strategy — aligns with actively competing for major employers and investment rather than limiting the city to small-business programs or forgoing recruitment.$$,
        ARRAY['https://glennmiller4indio.com/the-issues',
              'https://ukenreport.com/glenn-miller-seeks-fourth-term-in-indio/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Glenn Miller / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Miller actively promotes growth and new development as a path to a larger tax base and more jobs. He highlights that Indio leads Eastern Riverside County in building activity and new business start-ups and was among the fastest-growing cities in Southern California, and his record centers on recruiting builders and development rather than slowing or capping growth. That pro-growth, recruit-and-streamline posture aligns with actively recruiting development and streamlining approvals to grow the city, rather than imposing growth limits or restricting expansion to existing infrastructure capacity.$$,
        ARRAY['https://glennmiller4indio.com/the-issues',
              'https://ukenreport.com/glenn-miller-seeks-fourth-term-in-indio/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Glenn Miller / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13bc36a0-3984-4ba1-9a2f-d4791bfa2ca2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Miller places public safety at the center of his platform, calling it the "most important issue of local government" and stating "a safe city is a prosperous city." His record includes increasing police presence in parks and public spaces, expanding the Police Department's Quality of Life Team, adding dedicated officers, and pledging to be a vocal advocate for the Police Department and Fire Protection Services while strongly opposing any attempts to reduce their operating budgets. Prioritizing added police staffing and protected/expanded public-safety funding aligns with increasing police staffing and resources to improve response and deter crime.$$,
        ARRAY['https://glennmiller4indio.com/the-issues']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
