-- =====================================================================================
-- Compass stances: Pablo Robles — Acting Mayor, City of South Tucson (AZ)
-- politician_id: a6888435-018b-448c-8272-163a330fd5e3   (external_id -4015003)
-- Nonpartisan (antipartisan display). Elected to the City Council November 2024 (term
-- thru 2028 — NOT up in the July 21, 2026 primary); chosen Acting Mayor by the council
-- (a council-selected TITLE, not a directly elected office). Housing counselor for
-- Chicanos por la Causa. Positions attributed ONLY to his own on-record statements; no
-- other member's views. Recall-era / historical South Tucson politics are BACKGROUND,
-- never current-roster fact.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * The seeded topic is backed by his documented, attributable candidate statement in
--     the Tucson Agenda 2024 South Tucson candidate profile (fetched via the
--     tucsonagenda.substack.com mirror 2026-07-17 — the tucsonagenda.com/p/ copy 404'd;
--     the Substack mirror is the actually-fetched source and is what is cited).
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
--   housing = 3  (Tucson Agenda: the council should "review the available options to help
--                people stay in their homes, support first-time buyers, protect renters
--                and stabilize" the community, working with community partners for "more
--                safe and secure housing" — targeted assistance framing)
--
-- DELIBERATELY BLANK (no clean, attributable documented position found):
--   public-safety-approach: Robles names public safety as residents' "primary concern"
--     and says people "no longer feel safe," but states no APPROACH (more police vs.
--     social services vs. crisis teams) that maps to a chair — a salience statement, not a
--     method. BLANK (honest).
--   homelessness-response, economic-development, taxes, local-immigration, etc.: no
--     citable Robles position mapping to a chair (his "rebrand South Tucson" / "beauty and
--     culture" comments are civic-vision, not a topical policy chair).
--   Non-local federal/state topics (an acting mayor has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
--     deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Pablo Robles / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a6888435-018b-448c-8272-163a330fd5e3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a6888435-018b-448c-8272-163a330fd5e3',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Robles — a housing counselor for Chicanos por la Causa — framed his housing platform around targeted assistance to keep residents housed. In the Tucson Agenda South Tucson candidate profile he said the city council needs to "review the available options to help people stay in their homes, support first-time buyers, protect renters and stabilize" the community, and that he wants to work with community partners to put the city "in a better position, with more safe and secure housing." That mix of first-time-buyer support, stay-in-home assistance, and renter protection delivered through programs and partners — rather than the city directly building and operating public housing for all comers (chair 1) or imposing rent caps and inclusionary mandates and publicly funding new construction (chair 2) — matches offering targeted help like subsidies, first-time-buyer assistance, and stabilization programs (chair 3).$$,
        ARRAY['https://tucsonagenda.substack.com/p/the-daily-agenda-meet-the-rest-of']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
