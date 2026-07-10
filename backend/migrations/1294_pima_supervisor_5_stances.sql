-- =====================================================================================
-- Compass stances: Andrés Cano — Pima County (AZ) Board of Supervisors, District 5
-- ext_id: -4007005   politician_id: 0e4bebcf-76b4-49df-9197-c114e84d3bd1
-- Democrat. APPOINTED to the D5 seat on Apr 15, 2025 (3-0) to succeed Adelita Grijalva.
-- Before the Board he served in the Arizona House of Representatives 2019-2023, rising to
-- House Minority Leader (Jan-Jun 2023); ranking Democrat on Ways & Means (56th Leg.) and on
-- Natural Resources, Energy & Water (55th Leg.). That legislative record is well-documented
-- and is used below where a topic has a clear, specifically-cited legislative position; his
-- newer supervisor record (Apr 2025 -> present) supplies the county-level evidence.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position — a recorded
--     legislative floor vote, a Board of Supervisors vote/statement he cast while seated, a
--     candidate/campaign platform statement, or an official priority — with real cited source
--     URLs confirmed via web research.
--   * NO PRE-TENURE BOARD ATTRIBUTION: no Board of Supervisors action before Apr 15, 2025 is
--     credited to him (nothing his predecessor Adelita Grijalva did counts here). His pre-2023
--     legislative votes ARE his own record and are attributed as legislative evidence.
--   * Topics with no clear documented Cano position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (15 topics):
--   abortion              = 2  (LEG: voted against the 2022 15-week ban; Planned Parenthood AZ board member)
--   childcare             = 2  (SUPV: official D5 priority = "expanding access to pre-school")
--   civil-rights          = 2  (LEG/career: LGBTQ+ Alliance Fund director; opposed anti-LGBTQ/anti-trans bills)
--   climate-change        = 3  (LEG: ranking Dem Nat. Resources/Energy/Water; co-led 2022 environmental priorities)
--   data-centers          = 1  (SUPV: repeated NO on Project Blue; op-ed "hit the brakes" until enforceable guardrails)
--   economic-development  = 3  (SUPV: demanded enforceable community-benefit contracts + NDA-transparency reform)
--   growth-and-development= 2  (SUPV: "grow responsibly," slow Project Blue on water/energy-capacity grounds)
--   homelessness          = 2  (SUPV: forum — decriminalize, compassion + services, jails not de-facto shelters)
--   homelessness-response = 2  (SUPV: forum — "holistic regional all-hands-on-deck intervention," services-led)
--   housing               = 3  (LEG/SUPV: negotiated budget "historic investments in affordable housing")
--   jail-capacity         = 2  (SUPV: forum — divert unsheltered/mental-health/substance-abuse cases from jail)
--   local-environment     = 1  (SUPV: Sonoran Desert Conservation Plan advocacy; backed post-Project-Blue enviro review)
--   school-vouchers       = 2  (LEG: NO on HB2853 universal-ESA expansion, 6/22/2022; public-school-funding priority)
--   trans-athletes        = 1  (LEG: opposed SB1165 trans-sports ban; defended trans kids' participation)
--   voting-rights         = 2  (LEG: opposed "dozens of laws restricting our freedom to vote")
--
-- DELIBERATELY BLANK (no clearly attributable documented Cano position found):
--   Local: campaign-finance, city-sanitation, fossil-fuels, local-immigration, public-safety-approach,
--          rent-regulation, religious-freedom, residential-zoning, transportation-priorities.
--   Non-local federal/state: ai-regulation, deportation, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, social-security, tariffs, ukraine-support.
--   (His strong LGBTQ+ advocacy is captured under civil-rights and trans-athletes; it is not seeded
--    as same-sex-marriage because no specific statement on marriage-recognition law was found. His
--    Project Blue environmental opposition is captured under data-centers/local-environment/growth,
--    not as a fossil-fuels-extraction chair. Federal/immigration topics are blank absent a specific
--    cited Cano position on those exact questions.)
-- =====================================================================================

BEGIN;

-- ----- Andrés Cano / abortion (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As a state representative Cano voted against Arizona's 2022 15-week abortion ban and, in his Clean Elections candidate statement, listed opposing that ban among his record; he has also served as a board member of Planned Parenthood Arizona. Opposing a 15-week cutoff (i.e., supporting continued access into the second trimester) and his Planned Parenthood role place him at chair 2 — keep abortion legal and accessible through the second trimester — rather than the "all stages / publicly funded" chair, for which no explicit statement was found.$$,
        ARRAY['https://www.azcleanelections.gov/arizona-elections/voter-education-guide/general-text-legislative20',
              'https://ballotpedia.org/Andres_Cano']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / childcare (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Cano's official Pima County District 5 page and his April 2025 appointment coverage list "expanding access to pre-school" among his core stated priorities as supervisor, alongside tackling poverty and creating high-paying jobs. A commitment to expanding publicly-provided early-childhood/pre-school access maps to chair 2 — significantly expanding subsidies and access to make early care affordable for working families — short of an explicit universal-childcare pledge (chair 1).$$,
        ARRAY['https://www.pima.gov/2528/Supervisor-Andrs-Cano-District-5',
              'https://azluminaria.org/2025/04/15/supervisors-appoint-andres-cano-to-represent-pima-countys-district-5/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / civil-rights (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cano served as the first director of the LGBTQ+ Alliance Fund (2020-2023) and was an HRC HIV360 fellow doing HIV-prevention work in Southern Arizona's Latino community; as a legislator he publicly opposed 2022 bills targeting transgender youth ("We're talking about our kids... to be able to be who they are"). A documented record of strengthening protections for marginalized communities and opposing discriminatory legislation maps to chair 2 — strengthen civil rights enforcement and address systemic discrimination.$$,
        ARRAY['https://ballotpedia.org/Andres_Cano',
              'https://en.wikipedia.org/wiki/Andr%C3%A9s_Cano',
              'https://www.npr.org/2022/03/24/1088624777/arizona-legislature-passes-2-bills-to-curb-transgender-rights']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / climate-change (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As ranking Democrat on the House Natural Resources, Energy & Water Committee, Cano co-released the 2022 Environmental Priorities for the Arizona Legislature, calling drought mitigation and "creating a smarter, more sustainable economy" an "urgent and historic opportunity." His documented record backs clean-energy investment and gradual reduction of reliance on fossil fuels, matching chair 3; no explicit "phase out fossil fuels by 2030" pledge (chair 2) was found, so the more measured chair is used.$$,
        ARRAY['https://www.sierraclub.org/arizona/blog/2022/01/groups-release-environmental-priorities-for-arizona',
              'https://en.wikipedia.org/wiki/Andr%C3%A9s_Cano']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Supervisor Cano voted NO on the Project Blue data-center land deal (June 2025) and again NO on the binding development agreement (Dec 16, 2025, which passed 3-2), and authored a Nov 2025 op-ed titled "Why Pima County must hit the brakes on Project Blue." He warned that "communities are warning us what happens when local governments approve massive data center deals without enforceable guardrails," citing strain on water and energy and long-term public-health risk. Refusing to approve even a guardrail-laden deal and calling to "hit the brakes" until the county gets it right maps to chair 1 — a moratorium until infrastructure can support the demand.$$,
        ARRAY['https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/',
              'https://www.tucsonsentinel.com/opinion/report/111325_cano_project_blue_op/cano-why-pima-county-must-hit-brakes-project-blue/',
              'https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$On the Project Blue economic-development deal, Cano pushed for enforceable community-benefit terms and greater transparency: he backed the September 2025 policy requiring disclosure of non-disclosure agreements in economic-development projects ("Sunlight is the greatest disinfectant"), and pressed for binding local-investment and job-quality/apprenticeship commitments rather than an incentives-first approval. Conditioning major-employer deals on community-benefit agreements and job-quality requirements maps to chair 3.$$,
        ARRAY['https://azluminaria.org/2025/09/03/pima-county-votes-to-change-two-policies-about-ndas-and-environmental-impact-reviews-after-lessons-learned-from-project-blue/',
              'https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$On the Project Blue proposal Cano urged the county to "grow responsibly," saying "Generations of Tucsonans have worked to protect our water, preserve open space, and grow responsibly. We owe it to them to get this right," and voted to slow the deal over water and energy-capacity concerns. Insisting that large-scale development wait until water/energy infrastructure can support it maps to chair 2 — allow growth only where existing infrastructure can support it and slow approvals until capacity catches up.$$,
        ARRAY['https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/',
              'https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / homelessness (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$At the April 2025 District 5 candidate forum Cano argued against criminalizing unsheltered people, saying "we need to not have our county jails be a place that is trying to be a place of compassion and care for people who are unsheltered, who are poor and who have mental health... and substance abuse issues" — favoring services and care over enforcement. Decriminalizing public sleeping while investing in outreach and services maps to chair 2.$$,
        ARRAY['https://news.azpm.org/p/pimaelections/2025/4/9/224379-pima-county-district-5-supervisor-candidates-address-housing-poverty-and-conservation-in-public-forum/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Describing his approach to homelessness at the April 2025 forum, Cano called for "a holistic approach that's going to need a regional all-hands-on-deck intervention," emphasizing shelter, care, and services for unsheltered, poor, and mental-health/substance-abuse populations rather than enforcement. A services-and-shelter-led primary strategy maps to chair 2 — expand shelter capacity and services as the primary strategy.$$,
        ARRAY['https://news.azpm.org/p/pimaelections/2025/4/9/224379-pima-county-district-5-supervisor-candidates-address-housing-poverty-and-conservation-in-public-forum/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As House Minority Leader Cano helped negotiate the bipartisan state budget that "secured historic investments in affordable housing" (cited on his official county page), and in his Clean Elections candidate statement he pledged to use the state surplus to lower housing costs for working families. Backing public funding/subsidies for affordable housing production and cost relief — without a documented rent-cap or inclusionary-mandate position — maps to chair 3, targeted help such as subsidies for affordable projects and first-time buyer assistance.$$,
        ARRAY['https://www.pima.gov/2528/Supervisor-Andrs-Cano-District-5',
              'https://www.azcleanelections.gov/arizona-elections/voter-education-guide/general-text-legislative20']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / jail-capacity (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$At the April 2025 forum Cano said the county jail should not be the default place of "compassion and care for people who are unsheltered, who are poor and who have mental health... and substance abuse issues," signaling that such cases belong in community treatment and diversion rather than incarceration. Prioritizing diversion and treatment alternatives over expanding jail capacity maps to chair 2.$$,
        ARRAY['https://news.azpm.org/p/pimaelections/2025/4/9/224379-pima-county-district-5-supervisor-candidates-address-housing-poverty-and-conservation-in-public-forum/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / local-environment (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Supervisor Cano is a vocal champion of the Sonoran Desert Conservation Plan (he headlined the plan's 25th-anniversary event) and, after Project Blue, backed the September 2025 county reforms expanding the environmental-impact-assessment framework required before approving development. He voted against Project Blue specifically on water/open-space/environmental grounds. Requiring robust environmental review and preservation before approving development maps to chair 1.$$,
        ARRAY['https://azluminaria.org/2025/09/03/pima-county-votes-to-change-two-policies-about-ndas-and-environmental-impact-reviews-after-lessons-learned-from-project-blue/',
              'https://www.pima.gov/2528/Supervisor-Andrs-Cano-District-5',
              'https://www.tucsonspotlight.org/project-blue-secures-pima-county-approval-in-narrow-board-vote/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / school-vouchers (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$As a state representative Cano voted NO on HB2853, the 2022 universal-ESA voucher expansion (House final passage 31-26-3, June 22, 2022), and his Clean Elections candidate statement emphasized that Arizona ranks last in K-12 spending and prioritized funding public schools, teacher pay, and restoring community-college funding. Opposing universal voucher eligibility while championing public-school funding maps to chair 2 — prioritize public schools and restrict vouchers.$$,
        ARRAY['https://fastdemocracy.com/bill-search/az/55th-2nd-regular/bills/AZB00014470/',
              'https://www.azcleanelections.gov/arizona-elections/voter-education-guide/general-text-legislative20']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / trans-athletes (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Cano opposed Arizona's 2022 SB1165 ("Save Women's Sports Act"), which barred transgender girls from girls' school sports, defending trans youth on the floor: "We're talking about our kids, who are already going to be taking the proper steps with their parents to be able to be who they are." Opposing the ban and defending trans athletes competing as who they are — with no documented documentation/eligibility condition attached — maps to chair 1.$$,
        ARRAY['https://www.npr.org/2022/03/24/1088624777/arizona-legislature-passes-2-bills-to-curb-transgender-rights',
              'https://en.wikipedia.org/wiki/Arizona_Senate_Bill_1165']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrés Cano / voting-rights (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e4bebcf-76b4-49df-9197-c114e84d3bd1',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$In his Clean Elections candidate statement Cano cited his record opposing "dozens of laws restricting our freedom to vote" during the wave of Arizona voting-restriction bills he faced as a Democratic legislator and leader. A documented pattern of opposing measures that curtail ballot access — favoring expanded, no-excuse voting access — maps to chair 2, expand early voting and no-excuse mail-in voting.$$,
        ARRAY['https://www.azcleanelections.gov/arizona-elections/voter-education-guide/general-text-legislative20']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
