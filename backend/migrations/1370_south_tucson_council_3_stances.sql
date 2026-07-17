-- =====================================================================================
-- Compass stances: Brian Flagg — Council Member, City of South Tucson (AZ)
-- politician_id: 932bed88-cb72-4611-8394-05f6f476d307   (external_id -4015006)
-- Nonpartisan (antipartisan display). Council Member (term thru 2026 — up in the July 21,
-- 2026 primary). Longtime director of Casa Maria Catholic Worker (neighborhood soup
-- kitchen / aid house). Positions attributed ONLY to his own on-record candidate
-- statements; no other member's views. Recall-era / historical South Tucson politics are
-- BACKGROUND, never current-roster fact.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by his documented, attributable candidate statements in
--     the AZ Luminaria 2026 voter guide (a non-WAF source actually fetched 2026-07-17).
--   * Topics with no clear documented position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * Discrete 1-5 "chairs" (feedback_compass_chairs_not_polarity), never a polarity scale.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers /
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live topics in scope; the 8
--   judicial-* topics are NEVER seeded for a city council official):
--     public-safety-approach = e9ebefcd-c496-45e8-b816-a79f8442ba85
--     economic-development   = eb3d1247-0de1-4b7f-baec-7259861efd53
--     taxes                  = f7e5678d-dadd-4556-a2fc-446e24642ceb
--
-- SEEDED (3 topics):
--   public-safety-approach = 1  (voter guide: emphasizes "community policing" — officers
--                                "out of your cars, out of the station, talking with the
--                                people, demanding accountability" — and funds "the John
--                                Valenzuela Youth Center" as a public-safety measure:
--                                community-investment/prevention over enforcement)
--   economic-development   = 3  (voter guide: willing to "take some money out of our budget
--                                and do some economic development, to try to get businesses
--                                in here, especially a grocery store" — targeted public
--                                investment to land a specific community-benefit business)
--   taxes                  = 3  (voter guide: "There's no grocery tax now and that's a good
--                                thing because people will pay less"; unbothered by a
--                                not-"totally balanced" budget — a targeted regressive-tax
--                                cut, structure otherwise intact, services preserved)
--
-- DELIBERATELY BLANK (no clean, attributable documented position that maps to a chair):
--   housing / homelessness-response: as Casa Maria's director he serves the poor and
--     unhoused daily, but the voter guide records no specific city housing/homelessness
--     POLICY chair from him (subsidies vs. rent caps vs. public build vs. enforcement), so
--     inferring one from his vocation would be inference, not evidence. BLANK (honest).
--   local-immigration, growth-and-development, etc.: no citable Flagg position mapping to a
--     chair.
--   Non-local federal/state topics (a council member has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
--     deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Brian Flagg / public-safety-approach (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Flagg frames public safety around community investment, community policing, and accountability rather than expanding police staffing or hardware. In the AZ Luminaria 2026 voter guide he emphasizes "community policing" — officers "being out of your cars, out of the station, talking with the people, demanding accountability" — and highlights funding "the John Valenzuela Youth Center" as a public-safety measure. Prioritizing community programs and prevention (a youth center) and a reform/accountability posture toward policing, rather than increasing police staffing and pay (chair 4) or maintaining staffing while adding co-responders/crisis teams (chairs 2-3), sits at the community-investment end of the spectrum — redirecting emphasis and resources toward social services, youth, and community programs (chair 1).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Flagg / economic-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Flagg supports using public budget dollars to recruit a specific, community-needed business. In the AZ Luminaria voter guide he says he is willing to "take some money out of our budget and do some economic development, to try to get businesses in here, especially a grocery store" — South Tucson being an underserved food-access area. Committing targeted city funds to land a specific community-benefit business (a grocery store) — rather than offering no incentives and relying on organic growth (chair 1), limiting help to small-business/entrepreneur programs (chair 2), or competing for major employers with large tax abatements (chair 4) — matches targeted incentives/investment for specific businesses with clear community benefit (chair 3).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Flagg / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('932bed88-cb72-4611-8394-05f6f476d307',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Flagg's fiscal comments favor a targeted regressive-tax cut while keeping the broader structure and spending intact. In the AZ Luminaria voter guide he says "There's no grocery tax now and that's a good thing because people will pay less," and adds "I don't think it's the end of the world if the budget isn't totally balanced" — i.e., he supports removing the grocery tax and is willing to run a modest deficit to sustain services rather than cut them. Removing one regressive tax while preserving (even deficit-financing) services — rather than raising taxes on the wealthy/companies (chairs 1-2) or broadly cutting taxes and shrinking government/services (chairs 4-5) — matches keeping the current tax system mostly as-is with a small, targeted adjustment (chair 3).$$,
        ARRAY['https://azluminaria.org/2026/06/22/your-voter-guide-where-south-tucson-city-council-candidates-stand-on-key-issues/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
