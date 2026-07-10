-- =====================================================================================
-- Compass stances: Dr. Matt Heinz — Pima County (AZ) Board of Supervisors, District 2
-- ext_id: -4007002   politician_id: be550e00-b04c-4717-99bc-75bd4e8d6608
-- Democrat; ER physician; current Board Vice Chair; sitting supervisor since Jan 2021
-- (elected Nov 2020, re-elected Nov 2024). Former AZ state representative (2009-2013) and
-- congressional candidate (2016, 2018).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Board
--     vote/motion, sponsored resolution, or on-record public statement), with real cited
--     source URLs confirmed via web research.
--   * County-tenure actions are dated within his term. Two non-local topics (healthcare,
--     same-sex-marriage) are seeded from his own strongly documented personal record as an
--     ER physician / HHS ACA official and as an openly gay LGBTQ-rights advocate and former
--     legislator, with specific citations — as permitted for clearly documented positions.
--   * Topics with no clear documented Heinz position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (12 topics):
--   abortion                  = 2  (drafted county resolution condemning AZ 1864 near-total ban)
--   climate-change            = 3  (backed CAPCO climate resolution; clean-energy investment)
--   data-centers              = 3  (Project Blue yes-vote conditioned on water/renewable commitments)
--   economic-development      = 3  (targeted recruitment: American Battery Factory, Mosaic Quarter)
--   healthcare                = 2  (non-local; ACA/HHS record + "Medicare buy-in" to universal coverage)
--   homelessness-response     = 1  (housing-first: dedicated dept, EELS, permanent-supportive-housing plan)
--   housing                   = 3  (authored tax-funded affordable-housing plan + subsidies + zoning ease)
--   jail-capacity             = 2  (opposed new jail; diversion/population-reduction for non-violent)
--   local-immigration         = 2  (Feb 2026 judicial-warrant-only / no-ICE-on-county-property vote)
--   residential-zoning        = 3  (championed 2024 transit-corridor density/TOD zoning reform)
--   same-sex-marriage         = 1  (non-local; openly gay LGBTQ-rights advocate; fought marriage bans)
--   transportation-priorities = 1  (transit-oriented development; reduced parking near transit)
--
-- DELIBERATELY BLANK (no attributable documented Heinz position found):
--   Local: campaign-finance, childcare, city-sanitation, civil-rights, fossil-fuels,
--          growth-and-development, homelessness, local-environment, public-safety-approach,
--          religious-freedom, rent-regulation, trans-athletes.
--   Non-local federal/state: ai-regulation, deportation, immigration, medicare/aid,
--          misinformation, redistricting, school-vouchers, social-security, tariffs, taxes,
--          ukraine-support, voting-rights.
--   (The Feb-2026 ICE-property vote is captured under local-immigration; it is not a stance
--    on federal immigration levels or deportation aggressiveness.)
-- =====================================================================================

BEGIN;

-- ----- Dr. Matt Heinz / abortion (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Heinz, an ER physician, drafted the Pima County resolution (passed 4-1, with Republican Steve Christy the lone no) condemning Arizona's 1864 near-total abortion ban and calling for its repeal; he mocked the "confederate-era law" and said he was "absolutely fine encouraging" disobedience to it, arguing abortion is constitutionally protected. He also urged the county to expand reproductive-health services, including telehealth counseling and advice on emergency contraception. That record supports keeping abortion legal and accessible rather than restricting or banning it.$$,
        ARRAY['https://www.kjzz.org/content/1877278/pima-county-supervisors-pass-resolution-against-1864-abortion-ban',
              'https://tucson.com/news/local/government-politics/abortion-arizona-pima-county-supervisors-resolution/article_e641fa44-fc06-11ee-a1f3-c3c06a18c425.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / climate-change (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Heinz lists climate change among his core priorities and was part of the Board's May 6, 2025 4-1 vote directing staff to craft a Climate Action Plan for County Operations. In explaining his support for the Project Blue land deal he emphasized the developer's commitment to reclaimed water and to "accelerating TEP's goal to get to 100% renewables by 2050." His documented record favors investing in clean energy and gradually reducing fossil-fuel reliance, not an immediate ban on all emitting activity.$$,
        ARRAY['https://www.tucsonsentinel.com/local/report/021324_pima_supes_d2/heinz-faces-challenge-as-he-seeks-2nd-term-pima-county-board-supervisors/',
              'https://tucson.com/news/local/pima-county-supervisors-approve-climate-change-resolution-to-align-with/article_ca996ec2-e36d-52c4-be1e-02f3dc060215.html',
              'https://www.kold.com/2025/06/18/pima-county-board-supervisors-approve-land-deal-project-blue-data-center/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / data-centers (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Initially skeptical, Heinz voted to approve the "Project Blue" data-center land deal after the developer made binding environmental commitments, saying "the fact that this group is so committed to ... using reclaimed water and accelerating TEP's goal to get to 100% renewables by 2050" is why he backed it. He conditioned his support on impact commitments (reclaimed rather than potable water) and accelerated-renewables benefits before approval, rather than a moratorium or a no-strings incentive.$$,
        ARRAY['https://www.kold.com/2025/06/18/pima-county-board-supervisors-approve-land-deal-project-blue-data-center/',
              'https://www.kold.com/2025/12/16/pima-county-votes-move-forward-with-project-blue/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Heinz touts recruiting targeted major employers as signature accomplishments: the American Battery Factory clean-energy "gigafactory" (planned for up to 1,000 jobs, backed by county incentives for job training and recruiting and a Foreign Trade Zone designation, on land leased at appraised fair-market value) and the Mosaic Quarter sports/entertainment project. That reflects targeted incentives aimed at specific industries and job creation rather than a no-incentive stance or maximum no-strings subsidies for any employer.$$,
        ARRAY['https://www.heinzforsupervisor.com/',
              'https://www.kgun9.com/news/local-news/pima-county-supervisors-approve-lithium-battery-gigafactory']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / healthcare (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Non-local topic, seeded on Heinz's own strongly documented record: an ER physician, he was appointed by President Obama as HHS Director of Provider Outreach (2013-2015) to help roll out the Affordable Care Act, and campaigned for Congress on moving "step-by-step towards universal coverage ... starting with a Medicare buy-in option." That is a mixed public-programs-plus-regulated-private-insurance path to affordable coverage for all, not immediate single-payer nor a market-only approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Matt_Heinz',
              'https://www.the-rheumatologist.org/article/advocacy-spotlight-dr-matt-heinz-candidate-congress-arizona-district-2-tucson/',
              'https://justfacts.votesmart.org/candidate/political-courage-test/68106/matthew-heinz']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / homelessness-response (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Heinz's primary documented homelessness strategy is permanent housing plus prevention: he created a dedicated county department to address housing and homelessness, launched Emergency Eviction Legal Services (EELS) to keep families in their homes, and authored the multi-year plan to fund roughly 12,000 affordable/supportive units targeted at homeless individuals and seniors, saying the aim is to "keep people housed, in a meaningful way." That housing-first, supportive-housing orientation matches providing permanent housing rather than making shelter or enforcement the primary tool.$$,
        ARRAY['https://www.heinzforsupervisor.com/',
              'https://azluminaria.org/2025/05/07/pima-county-proposes-raising-property-taxes-to-build-more-affordable-housing/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Heinz has driven the county's affordable-housing effort: he secured ~$12M that leveraged $100M+ for 1,000+ affordable units, and authored the multi-year plan the Board passed 3-2 on June 3, 2025, which incrementally raises the primary property-tax rate to invest $200M+ subsidizing construction and preservation of ~12,000 affordable units. He said "housing insecurity continues to go up and up and up ... I believe we at the county have a role to play here." Delivered as public subsidies to affordable-housing projects plus permit-easing zoning reform (not rent control or county-built/operated public housing), this matches targeted government help for affordable housing.$$,
        ARRAY['https://azluminaria.org/2025/05/07/pima-county-proposes-raising-property-taxes-to-build-more-affordable-housing/',
              'https://azluminaria.org/2025/06/04/a-boost-for-affordable-housing-a-new-library-and-an-ongoing-investigation-into-sheriffs-department-3-things-to-know-from-pima-county-board-of-supervisors-meeting/',
              'https://www.heinzforsupervisor.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / jail-capacity (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$After the county's jail study, Heinz said building a new/bigger jail was off the table because there was not enough "political will" for one. With Board Chair Adelita Grijalva he pressed the review commission to examine whether non-violent offenders should be incarcerated at all and to pursue population-reduction measures such as lowering bed capacity and expanding alternatives to incarceration for non-violent offenders. That is reducing the incarcerated population through diversion and alternatives rather than building new capacity.$$,
        ARRAY['https://tucson.com/news/local/government-politics/jail-tucson-pima-county-overcrowding-safety/article_566f7750-e178-11ee-8857-4343cc146bc7.html',
              'https://www.kgun9.com/news/local-news/pima-county-takes-steps-toward-new-jail']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / local-immigration (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$On Feb. 3, 2026 Heinz voted (4-1) to advance a trio of ICE-related policies: barring immigration agents from using county property for civil enforcement unless they hold a judicial warrant, requiring law-enforcement agents to wear visible identification, and opposing a proposed ICE detention center at the former Marana jail. Answering a colleague's worry about conflict with federal officers, Heinz said "local officers are well-trained in de-escalation tactics." Withholding county resources/property from immigration enforcement absent a court-ordered warrant, rather than proactively assisting ICE.$$,
        ARRAY['https://www.kjzz.org/fronteras-desk/2026-02-03/pima-county-leaders-vote-to-advance-trio-of-policies-outlining-how-ice-can-function-within-county',
              'https://www.kjzz.org/politics/2026-05-06/pima-county-can-restrict-ice-activity-on-its-property-arizona-ag-says']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / residential-zoning (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Heinz champions the May 21, 2024 zoning-code amendment (approved 3-1) that reduced setbacks, raised allowable building heights, and granted density bonuses for multifamily/infill housing along public-transit corridors and arterials with adequate water and wastewater capacity, while leaving most residential zoning intact. He credits himself with passing "a major zoning reform to facilitate the construction of more density and more affordable housing." That is allowing multifamily/mixed-use near corridors while protecting most residential zones, not blanket citywide upzoning or strict character preservation.$$,
        ARRAY['https://content.govdelivery.com/accounts/AZPIMA/bulletins/39e17b0',
              'https://www.signalsaz.com/articles/pima-county-amends-zoning-code-to-increase-housing-opportunities/',
              'https://www.heinzforsupervisor.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / same-sex-marriage (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Non-local topic, seeded on Heinz's own well-documented record: an openly gay former Arizona state legislator and congressional candidate and a longtime LGBTQ-rights advocate, endorsed by the LGBTQ Victory Fund and the Human Rights Campaign, who as a state lawmaker worked to defeat same-sex-marriage bans. His record supports full legal recognition of same-sex marriage with equal federal benefits and protections.$$,
        ARRAY['https://www.advocate.com/election/2016/11/02/meet-candidates-arizonas-matt-heinz',
              'https://victoryfund.org/news/lcv-action-fund-gay-lesbian-victory-fund-support-matt-heinz-congress/',
              'https://en.wikipedia.org/wiki/Matt_Heinz']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dr. Matt Heinz / transportation-priorities (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be550e00-b04c-4717-99bc-75bd4e8d6608',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Heinz's documented transportation priority is transit-oriented development: he championed the 2024 zoning reform that reduced parking requirements and setbacks to concentrate housing along public-transit corridors, and campaigns on advancing "transit-oriented development to help people of all backgrounds and abilities move safely." That emphasis on transit, walkability and reduced parking matches prioritizing pedestrian/transit access over building road capacity for drivers.$$,
        ARRAY['https://www.heinzforsupervisor.com/',
              'https://content.govdelivery.com/accounts/AZPIMA/bulletins/39e17b0']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
