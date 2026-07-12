-- =====================================================================================
-- Compass stances: Jose Medina — Riverside County (CA) Board of Supervisors, District 1
-- ext_id: -4010001   politician_id: ea521b54-7b19-459a-9993-4ce70a84d592
-- Democrat (not displayed); sworn in as D1 Supervisor at the first 2025 Board meeting
-- (Jan 6, 2025), current sitting supervisor. Previously CA State Assemblymember for
-- AD-61 (2012-2022, Riverside area). District 1 covers Riverside, Perris, and
-- unincorporated Good Hope, Highgrove, March ARB, Mead Valley, Meadowbrook.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded
--     Board/commission vote or motion, or on-record public statement) taken during his
--     county tenure (Jan 2025 onward), with real cited source URLs confirmed via web
--     research.
--   * Topics with no clear documented Medina position emit NO row (honest blank). No
--     party inference, no neutral defaults. Assembly-era (2012-2022) record is NOT used
--     here; only county-tenure evidence is seeded.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (4 topics, all applies_local=true):
--   homelessness-response = 2  (youth-homelessness "functional zero", Mar 26 2025; shelter+services-led)
--   local-immigration     = 3  (Feb 4 2025 board resolution, 4-1 w/ Medina in majority; no proactive status checks, complies w/ law)
--   economic-development  = 3  (Cajalco Commerce Center approved w/ workforce agreement; March Innovation Hub rejected for unenforceable promises)
--   growth-and-development = 3 (same record: approves growth tied to binding infrastructure/benefit commitments, rejects unenforceable ones)
--
-- DELIBERATELY BLANK (no attributable documented county-tenure position found):
--   Local: campaign-finance, city-sanitation, childcare, civil-rights, climate-change,
--          data-centers, homelessness, housing, jail-capacity, local-environment,
--          public-safety-approach, religious-freedom, rent-regulation, residential-zoning,
--          trans-athletes, transportation-priorities.
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, fossil-fuels, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers,
--          social-security, tariffs, taxes, ukraine-support, voting-rights.
--   (Medina's sheriff-oversight/inspector-general push and public-safety budget-fairness
--    comments are real and documented, but do not cleanly map to any of the jail-capacity
--    or public-safety-approach chairs, which are framed around capacity/funding levels
--    rather than civilian-oversight structure; left blank rather than force-fit.)
-- =====================================================================================

BEGIN;

-- ----- Jose Medina / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$At a March 26, 2025 press conference, Supervisor Medina represented Riverside County and the Continuum of Care in announcing the city/county effort had reached "functional zero" for youth homelessness (ages 18-24), reporting that "94 young adults" had been assisted. The documented strategy he touted was services-and-shelter led: added transitional-age-youth shelter beds through partners like Path of Life Ministries and Operation SafeHouse, a full-time housing locator position, landlord incentives, dedicated outreach/case-management teams, mental health and aftercare programming, and job/education pathways — with no mention of camping bans or citations. That record fits expanding shelter capacity and services as the primary strategy rather than a housing-first-no-preconditions or an enforcement-led approach.$$,
        ARRAY['https://www.raincrossgazette.com/riverside-claims-victory-in-youth-homelessness-fight/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jose Medina / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Feb. 4, 2025 the Board of Supervisors adopted, 4-1, a resolution affirming Riverside County as "a vibrant, compassionate and welcoming county for all law-abiding immigrants and refugees." Supervisor Karen Spiegel cast the lone recorded dissent, meaning Medina was among the four-member majority. The resolution prohibits county agencies from independently investigating a person's immigration status, national origin, race, or ethnicity, while explicitly permitting cooperation with federal or state authorities when required by law, and does not establish sanctuary status. Medina's personal alignment with that no-proactive-enforcement, comply-when-required posture was echoed on June 13, 2025, when he joined a rally against federal ICE raids in Riverside and said, "I am here to say stop the raids. These are our neighbors. These are the students that I taught. Let's stop the raids."$$,
        ARRAY['https://kesq.com/news/2025/02/04/county-board-passes-resolution-backing-law-abiding-immigrants-refugees/',
              'https://riversiderecord.org/riverside-county-adopts-resolution-in-support-of-immigrant-community/',
              'https://www.raincrossgazette.com/hundreds-rally-in-riverside-to-support-immigrant-community-amid-ice-raids/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jose Medina / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Medina's record on two major District 1 industrial/logistics proposals shows he ties approval to enforceable community-benefit and job-quality terms rather than granting or withholding incentives outright. On May 12, 2025 he made the motion that led the March Joint Powers Commission to unanimously reject the rebranded "March Innovation Hub" (West Campus Upper Plateau) warehouse project, saying "I agree that we cannot approve something that is not in writing, something that is only a promise. I am sorry, but in 50 years [of experience] what I have seen makes me skeptical." By contrast, on Oct. 21, 2025 the Board approved the Cajalco Commerce Center warehouse project in Mead Valley after a community workforce agreement was secured; Medina said "the positive does outweigh the negative," while cautioning warehouses "are not panaceas" and would not "solve all the issues of Mead Valley," crediting the deal for delivering local jobs.$$,
        ARRAY['https://www.kvcrnews.org/local-news/2025-05-13/march-joint-powers-commission-votes-down-proposed-warehouse-project-in-riverside',
              'https://www.kvcrnews.org/local-news/2025-10-21/riverside-county-signs-off-on-cajalco-commerce-center-warehouse-in-mead-valley']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jose Medina / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea521b54-7b19-459a-9993-4ce70a84d592',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$The same two votes show Medina favors proactive growth planning tied to concrete infrastructure and benefit commitments over either blanket growth limits or hands-off approval. On Oct. 21, 2025 the Board approved the Cajalco Commerce Center warehouse project in Mead Valley, a deal that paired roughly 1 million sq ft of warehouse/industrial space with nearly $38 million in developer-funded infrastructure upgrades (flood control, drainage, road improvements) and a 13-acre park; Medina backed it, saying "the positive does outweigh the negative." Five months earlier, on May 12, 2025, he led the March Joint Powers Commission's unanimous rejection of the rebranded "March Innovation Hub" project because its commitments were not binding, stating he "cannot approve something that is not in writing, something that is only a promise." Together the record reflects approving growth when it comes bundled with proactive, enforceable infrastructure investment, and rejecting it when that investment is only promised.$$,
        ARRAY['https://www.kvcrnews.org/local-news/2025-10-21/riverside-county-signs-off-on-cajalco-commerce-center-warehouse-in-mead-valley',
              'https://www.kvcrnews.org/local-news/2025-05-13/march-joint-powers-commission-votes-down-proposed-warehouse-project-in-riverside']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
