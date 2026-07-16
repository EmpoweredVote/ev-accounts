-- =====================================================================================
-- Compass stances: Patti Comerford — Council Member, Town of Marana (AZ)
-- politician_id: ad923125-6ce2-44ea-ac1d-a8eb701bff01
-- Nonpartisan; sitting Council Member (NOT seeking re-election in 2026, open seat) still
-- serving out her term. Positions attributed only to her documented council record —
-- recorded votes and on-record public statements made while in office.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Comerford position — either
--     her own on-record statement or a recorded council vote she participated in — with real
--     cited source URLs confirmed via web research.
--   * Topics with no clear documented Comerford position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (2 topics):
--   growth-and-development = 3  (on-record "growth is good" but "well-planned growth" with roads,
--                               utilities and water kept up to serve it — proactive/managed growth)
--   data-centers           = 3  (Jan 6 2026 unanimous 6-0 rezoning [Kai recused] approving the
--                               Beale/Luckett Rd hyperscale data center WITH negotiated conditions:
--                               air-cooled/minimal potable water, ACC-guaranteed power rates, jobs
--                               and workforce training, third-party noise monitoring, decommissioning
--                               requirement — i.e. allowing the project with impact/community-benefit
--                               conditions attached before approval)
--
-- DELIBERATELY BLANK (no attributable documented Comerford position found):
--   Local/community: campaign-finance, childcare, city-sanitation, economic-development,
--          homelessness, homelessness-response, housing, local-environment, local-immigration,
--          public-safety-approach, rent-regulation, residential-zoning, taxes,
--          transportation-priorities.
--          (On local-immigration: the ICE detention facility was a live 2026 Marana issue, but
--          this axis measures local police cooperation with ICE / honoring detainers — NOT whether
--          a private federal facility may operate — and no Comerford statement on detainers or
--          police-ICE cooperation was found; forcing a map would be inaccurate. As a non-candidate
--          she also did not appear in the 2026 candidate forums where ICE was debated.)
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, civil-rights, climate-change, deportation, fossil-fuels, healthcare,
--          immigration, jail-capacity, medicare/aid, misinformation, redistricting,
--          religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs,
--          trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Patti Comerford / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad923125-6ce2-44ea-ac1d-a8eb701bff01',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad923125-6ce2-44ea-ac1d-a8eb701bff01',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$On the record (Tucson Local Media, June 16 2022) Comerford framed town growth as fundamentally positive but insisted it be well-managed: "We go through spurts and when this happens, you can't tell somebody who's been holding on to the property, waiting for their time... 'No, I'm sorry, you can't build right now.' You know, we're keeping up infrastructure-wise, we're keeping up with what a municipality is supposed to do." She said her priority for another term was to "keep a well-planned growth... The necessities of our growth, for example roads and utilities and everything that comes with that growth. To keep up and make sure we are providing the quality of service we have been fortunate to provide," and noted growth "wouldn't be happening if there wasn't enough water available." That posture — welcoming growth while investing in roads, utilities and water to keep pace and preserve service quality — matches planning proactively and investing in infrastructure to support responsible growth (rather than hard growth caps or removing barriers entirely). Consistent with a selective, project-by-project approach, she also voted NO on the Aug. 6 2025 Linda Vista 52 annexation (approved 4-2) for a 212-home development amid resident concerns over roads and infrastructure.$$,
        ARRAY['https://www.tucsonlocalmedia.com/news/marana/comerford-says-town-growth-is-good-as-she-seeks-another-term-on-marana-town-council/article_87ae8e3e-eccc-11ec-a348-7bdf12cf9184.html',
              'https://www.kgun9.com/news/community-inspired-journalism/marana/marana-town-council-approves-linda-vista-52-annexation']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patti Comerford / data-centers (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ad923125-6ce2-44ea-ac1d-a8eb701bff01',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ad923125-6ce2-44ea-ac1d-a8eb701bff01',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$At the Jan. 6 2026 council meeting Comerford participated in the unanimous 6-0 vote (Councilmember Herb Kai recused, his family owning the south parcel) to rezone the two ~300-acre Luckett Road parcels from residential (R-144) to Specific Plan, clearing the way for Beale Infrastructure's ~600-acre hyperscale data center over vocal resident opposition. The approval was not a bare green-light: it carried negotiated conditions and community-benefit commitments secured before the vote — an air-cooled design using little to no potable water (with non-potable supply from the Cortaro-Marana Irrigation District), power from Trico and Tucson Electric Power under Arizona Corporation Commission-approved contracts said to guarantee rates, developer-funded third-party noise monitoring, promised job creation and workforce training, and a first-of-its-kind requirement that all data-center hardware and infrastructure be removed if the use is ever discontinued. Voting to allow a large data center with those impact and community-benefit conditions attached — rather than imposing a moratorium or requiring the facility fund fully separate power, but also rather than a minimal-barrier or purely streamlined approval — maps to allowing data-center development with impact assessments, energy arrangements and community-benefit requirements before approval.$$,
        ARRAY['https://news.azpm.org/p/news-articles/2026/1/8/227908-marana-town-council-approves-rezoning-for-luckett-road-project-600-acre-hyperscale-data-center/',
              'https://www.tucsonspotlight.org/marana-approves-rezoning-for-massive-data-center-project/',
              'https://news.azpm.org/s/102502-marana-data-center-vote-sparks-backlash-three-residents-launch-council-runs/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
