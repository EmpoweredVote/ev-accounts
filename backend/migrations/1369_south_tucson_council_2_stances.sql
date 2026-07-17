-- =====================================================================================
-- Compass stances: Paul Diaz — Council Member, City of South Tucson (AZ)
-- politician_id: 1ce510bf-2eed-4335-83a8-54fa2079b8a3   (external_id -4015005)
-- Nonpartisan (antipartisan display). Current Council Member; a FORMER South Tucson Mayor
-- (pre-Nov-2024). TENURE CAVEAT: positions/actions are attributed to the role he actually
-- held at the time — post-Nov-2024 leadership actions are NOT attributed to him, and his
-- older acts (e.g. the 2013 big-box ordinance he signed as Mayor) are dated as such.
-- Recall-era / historical South Tucson politics are BACKGROUND, not current-roster fact
-- (note: Diaz himself filed a recall against Mayor Valenzuela — recorded here only as
-- context, never seeded as a compass position).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * The seeded topic is backed by his documented, attributable positions in the Tucson
--     Spotlight council profile (a non-WAF source actually fetched 2026-07-17).
--   * Topics with no clear documented position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * Discrete 1-5 "chairs" (feedback_compass_chairs_not_polarity), never a polarity scale.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers /
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live topics in scope; the 8
--   judicial-* topics are NEVER seeded for a city council official):
--     housing = 669cac97-66a6-4087-b036-936fbe62efb3
--
-- SEEDED (1 topic):
--   housing = 5  (Tucson Spotlight: opposes the city providing housing assistance — says
--                people should "just move"; prioritizes economic development over housing
--                initiatives; a market/hands-off posture)
--
-- DELIBERATELY BLANK (no clean, attributable documented position that maps to a chair):
--   public-safety-approach: Diaz advocates MERGING South Tucson's police with the Pima
--     County Sheriff's Department to address an officer shortage (and cites "liability").
--     That is an organizational/contracting mechanism, not a position on the redirect-to-
--     services-vs-increase-police-budget chair spectrum, so it does not map to a chair.
--     BLANK (honest).
--   economic-development / growth-and-development: he "supports economic development over
--     housing" and references the 2013 big-box ordinance he signed as Mayor "as an example
--     of growth failure," but that record is too ambiguous (pro- vs. anti- large retail) to
--     map to a specific incentive/growth chair. BLANK.
--   Non-local federal/state topics (a council member has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
--     deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Paul Diaz / housing (value 5) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ce510bf-2eed-4335-83a8-54fa2079b8a3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ce510bf-2eed-4335-83a8-54fa2079b8a3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Diaz takes a market/hands-off view of the city's role in housing. In the Tucson Spotlight council profile he says affordable housing "does not exist," opposes the city providing housing assistance — arguing residents who cannot afford to stay should "just move" — and says he prioritizes economic development over housing initiatives. Declining any city role in providing or subsidizing housing and leaving affordability to the market — rather than the city building/operating public housing (chair 1), rent caps and inclusionary mandates (chair 2), targeted subsidies and first-time-buyer help (chair 3), or even cutting regulations so private developers build more (chair 4, which still treats housing supply as a city concern) — matches staying out of housing entirely and letting the market decide prices and supply (chair 5).$$,
        ARRAY['https://www.tucsonspotlight.org/inside-south-tucson/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
