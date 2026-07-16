-- =====================================================================================
-- Compass stances: Herb Kai — Council Member, Town of Marana (AZ)
-- politician_id: 84e71183-dc0c-46de-8b28-d99c41dc8579
-- Nonpartisan; longtime council member (also former Mayor/Vice Mayor) and farmer/landowner;
-- incumbent seeking re-election in the July 21, 2026 election.
-- Positions attributed only to his own on-record statements.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable Kai position — here, his
--     campaign issue platform (herbkai.com), the only outlet carrying his own words. Kai declined
--     interview requests from AZ Luminaria and the Arizona Daily Star and did not attend the
--     July 10, 2026 League of Women Voters candidate forum, so no forum/press quotes exist to
--     attribute to him.
--   * Topics with no clear documented Kai position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (4 topics):
--   growth-and-development = 3  (campaign platform: "strategically planning our infrastructure
--                                for roads, water, sewer, and new business development... preparing
--                                for growth while protecting what makes Marana special" — proactive
--                                infrastructure-ahead-of-growth, controlled expansion)
--   economic-development   = 3  (recruit quality-job employers, "particularly in manufacturing";
--                                promote Marana to businesses; decisions for residents "not special
--                                interests, not developers" — targeted, industry/job-quality focus)
--   taxes                  = 3  ("keeping property tax at zero" while still funding schools/services
--                                "without raising your taxes by a single penny" — maintain the
--                                existing zero-property-tax structure, not cut services)
--   public-safety-approach = 4  ("maintaining the fastest police response time in Arizona" and
--                                backing "our police every step of the way" — police-investment /
--                                response-time posture, no crisis/co-responder component)
--
-- DELIBERATELY BLANK (no attributable documented Kai position found):
--   data-centers: BLANK. Kai owns a parcel adjacent/related to the Beale Infrastructure data-center
--          site and RECUSED himself from the Jan. 6, 2026 rezoning vote. A recusal is not a stance,
--          and he made no separate on-record substantive statement of position on data-center
--          policy, so nothing is seeded.
--   local-immigration: BLANK. The proposed ICE detention facility dominated the race, but Kai gave
--          no statement on local police cooperation with federal immigration enforcement / detainers
--          (the actual axis of this topic); he declined all interviews and skipped the forum.
--   Local, no clear position: city-sanitation, campaign-finance, homelessness, homelessness-response,
--          housing, local-environment (his "every community... must include parks and open spaces"
--          is an amenity requirement that does not map cleanly to the development-vs-environmental-
--          review chairs), rent-regulation, residential-zoning, transportation-priorities.
--          (Water-supply protection is his signature issue but has no matching compass topic.)
--   Non-local federal/state (a town council member has no record on these): abortion, ai-regulation,
--          civil-rights, climate-change, deportation, fossil-fuels, healthcare, immigration,
--          jail-capacity, medicare/aid, misinformation, redistricting, religious-freedom,
--          same-sex-marriage, school-vouchers, social-security, tariffs, trans-athletes,
--          ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Herb Kai / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$On his 2026 re-election campaign platform Kai frames Marana's growth as a matter of getting ahead of it: he describes the work as "strategically planning our infrastructure for roads, water, sewer, and new business development," which "means preparing for growth while protecting what makes Marana special," and pledges to "continue fostering thriving growth of Marana while prioritizing protection and securing the town's water supply... while ensuring controlled business and residential development." That posture — investing in and planning infrastructure ahead of a managed, controlled expansion rather than imposing hard growth caps (chairs 1-2) or removing barriers to recruit development (chairs 4-5) — matches chair 3: plan proactively and invest in infrastructure to support responsible growth.$$,
        ARRAY['https://herbkai.com/issues/',
              'https://herbkai.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Herb Kai / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kai's campaign platform frames economic development around attracting employers that offer quality jobs — "particularly in manufacturing" — and promoting Marana to businesses across the U.S., Canada and Mexico, while insisting that "Financial decisions must be made with intentionality and with Marana residents at the front of mind. Not special interests. Not developers." Targeting specific industries (manufacturing) with an explicit job-quality emphasis, while ruling out lavish deals for developers/special interests, aligns with chair 3 (targeted incentives for specific industries with job-quality/community-benefit expectations) rather than a small-business-only posture (chair 2) or competing for any large employer with maximum abatements (chairs 4-5).$$,
        ARRAY['https://herbkai.com/issues/',
              'https://herbkai.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Herb Kai / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Kai's campaign platform lists "keeping property tax at zero" as a core commitment and says he has funded services such as school scholarships (crediting deals that put roughly $1.4 million into Marana schools) through mechanisms like landfill tipping fees "without raising your taxes by a single penny," attributing the town's continued no-property-tax status to "careful planning." Holding the existing tax structure steady (Marana levies no primary property tax) while still funding town services — rather than raising taxes to expand services (chairs 1-2) or cutting taxes and scaling back services (chairs 4-5) — matches chair 3: keep the current tax system mostly as-is.$$,
        ARRAY['https://herbkai.com/issues/',
              'https://herbkai.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Herb Kai / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84e71183-dc0c-46de-8b28-d99c41dc8579',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Kai's campaign platform puts policing squarely in the invest-and-support column: he touts "maintaining the fastest police response time in Arizona" and pledges to back "our police every step of the way." That response-time-and-support posture, with no mention of redirecting funds (chair 1) or adding unarmed/mental-health crisis co-responder teams (chairs 2-3), aligns with chair 4 — prioritizing police staffing, resources and fast response to deter crime.$$,
        ARRAY['https://herbkai.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
