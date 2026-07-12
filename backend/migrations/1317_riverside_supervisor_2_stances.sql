-- =====================================================================================
-- Compass stances: Karen Spiegel — Riverside County (CA) Board of Supervisors, District 2
-- ext_id: -4010002   politician_id: 9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f
-- Republican (not displayed); D2 Supervisor since December 2018 — longest-serving member
-- of the current Board — re-elected June 2026. Selected by colleagues as 2026 Board
-- Chair (seated Jan 13, 2026; previously Chair in 2021). Former Corona mayor/council
-- member. District 2 covers Corona, Norco, Eastvale, Jurupa Valley, Lake Elsinore,
-- Canyon Lake, and unincorporated communities in western Riverside County.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded
--     Board vote/motion or on-record public statement) taken during her county tenure
--     (Dec 2018 onward), with real cited source URLs confirmed via web research
--     (fetched and verified, not inferred from search-snippet summaries alone).
--   * Topics with no clear documented Spiegel position emit NO row (honest blank). No
--     party inference, no neutral defaults. As the Board's longest-serving member and
--     2026 Chair she has a broader public record than a freshman supervisor, but several
--     areas (childcare, climate, data centers, growth/zoning specifics, jail capacity)
--     turned up no attributable on-record position and are left blank rather than
--     force-fit from her general law-and-order / fiscally cautious profile.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (5 topics, all applies_local=true):
--   homelessness-response     = 2  (Jan 28 2020 co-sponsored Homeless Ad Hoc Committee w/
--                                    Perez; collaborative, services/housing-access focus)
--   housing                   = 3  (Jun 18 2025 quote backing county investment in
--                                    preserving/improving affordable housing communities)
--   local-immigration         = 3  (Feb 4 2025 lone dissent, 4-1, on welcoming-immigrants
--                                    resolution; wanted county to stay out of the issue
--                                    and avoid risking federal funding, not proactive ICE
--                                    assistance)
--   public-safety-approach    = 4  (2020 lone dissent on George Floyd/police-conduct
--                                    resolution + backed FY2020-21 Sheriff's Dept budget
--                                    increase; consistent Riverside Sheriffs' Assn support)
--   transportation-priorities = 3  (2025 RCTC Chair; balanced portfolio of highway
--                                    interchange projects and Metrolink rail/station
--                                    investment)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, childcare, city-sanitation, civil-rights, climate-change,
--          data-centers, economic-development, growth-and-development, homelessness,
--          jail-capacity, local-environment, religious-freedom, rent-regulation,
--          residential-zoning, trans-athletes.
--   Non-local federal/state (a county supervisor has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers,
--          social-security, tariffs, taxes, ukraine-support, voting-rights.
--   (The Feb-2025 resolution dissent is captured under local-immigration only; it is not
--    evidence of a stance on federal immigration levels, deportation, or general
--    civil-rights policy, so those topics remain blank.)
-- =====================================================================================

BEGIN;

-- ----- Karen Spiegel / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$On Jan. 28, 2020, Spiegel co-proposed the creation of the county's Homeless Ad Hoc Committee together with Supervisor V. Manuel Perez, building on the Board's 2018 Homeless Action Plan. Their joint statement said addressing homelessness "requires unique, thoughtful and collaborative strategies designed to reduce the current number of homeless individuals and families, increase access to and availability of affordable housing" and strengthen coordination among stakeholders and service providers. The framing centers on expanding services, shelter access, and affordable housing coordination rather than enforcement or camping bans, consistent with a services/shelter-led primary strategy.$$,
        ARRAY['https://patch.com/california/temecula/new-homelessness-committee-approved-riverside-county',
              'https://www.kvcrnews.org/local-news/2026-06-03/riverside-county-supervisors-on-track-for-reelection-wins']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Spiegel / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$At a June 18, 2025 celebration marking the renovation of the Corona del Rey and Corona de Oro affordable-housing communities in Corona, Spiegel said "The County of Riverside is a strong supporter of affordable housing, including investing in the preservation and improvement of existing communities," and described the county's partnership on the rehabilitation to keep the developments as valuable regional assets. That reflects targeted county support (partnership funding/investment in specific affordable projects) rather than direct public-housing operation or a market-only, hands-off approach.$$,
        ARRAY['https://nationalcore.org/national-core-celebrates-newly-renovated-sister-communities/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Spiegel / local-immigration (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Feb. 4, 2025, Spiegel cast the lone dissenting vote (4-1) against a Board resolution affirming Riverside County as a "welcoming" county for "law-abiding immigrants and refugees" and committing to safeguard residents' civil rights. She called the measure "just words," warned of "unintended consequences" including risk to federal funding given Congress's and the Trump administration's moves to penalize sanctuary jurisdictions, and urged colleagues to "focus on issues we supervisors have adjudication over that have a current impact on our residents." Her stated concern was keeping the county neutral and compliant with federal law/funding conditions rather than adopting either a sanctuary-style non-cooperation stance or a call for county resources to proactively assist federal immigration enforcement.$$,
        ARRAY['https://www.kvcrnews.org/local-news/2025-02-04/tensions-continue-to-rise-as-riverside-county-passes-resolution-supporting-immigrants']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Spiegel / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$In June 2020, Spiegel cast the lone vote against a Board resolution condemning the murder of George Floyd and the conduct of the Minneapolis police officers involved, calling the measure "over-broad" and saying it "unfairly mischaracterized peace officers as a whole" (3-1, with one supervisor abstaining); that same month she joined Supervisors Hewitt and Jeffries in voting for the FY2020-21 county budget's roughly 3%/$17 million increase to the Sheriff's Department. She has been described as "an unerring law enforcement supporter" and has consistently drawn endorsement from the Riverside Sheriffs' Association. The documented record favors increasing/maintaining sheriff staffing and funding and resisting police-reform-framed measures, rather than redirecting public-safety funding to other services.$$,
        ARRAY['https://www.kvcrnews.org/local-news/2026-06-03/riverside-county-supervisors-on-track-for-reelection-wins',
              'https://patch.com/california/lakeelsinore-wildomar/supervisor-karen-spiegel-who-represents-lake-elsinore-favored',
              'https://www.change.org/p/riverside-county-board-of-supervisors-don-t-give-the-riverside-county-sheriff-s-department-an-increased-budget']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Karen Spiegel / transportation-priorities (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9c4ae0c3-81fe-4034-8f64-e5cd6f815f6f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Selected for a second term as Chair of the Riverside County Transportation Commission for 2025, Spiegel's stated priorities for the year paired road-capacity projects (completing the 71/91 Interchange, advancing the 79 Realignment and Potrero Interchange) with rail investment (Moreno Valley/March Field Metrolink Station improvements and "various Metrolink initiatives"); she also serves on the Metrolink Board of Directors and has publicly backed the "Experience Metrolink" free-ticket program encouraging rail ridership. The documented record shows sustained investment in highway capacity alongside selective transit/rail expansion, rather than a roads-only or transit-only priority.$$,
        ARRAY['https://www.rctc.org/commission-selects-2025-chair-karen-spiegel/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
