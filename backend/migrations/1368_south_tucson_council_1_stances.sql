-- =====================================================================================
-- Compass stances: Dulce Jimenez — Council Member, City of South Tucson (AZ)
-- politician_id: 0a258242-d8c2-43ca-89ae-b891db3e21d8   (external_id -4015004)
-- Nonpartisan (antipartisan display). Elected to the City Council November 2024 (term
-- thru 2028 — NOT up in the July 21, 2026 primary). Positions attributed ONLY to her own
-- on-record statements; no other member's views (she is married to Acting Mayor Robles,
-- but each stance below is her OWN stated position, not shared-by-marriage inference).
-- Recall-era / historical South Tucson politics are BACKGROUND, never current-roster fact.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by her documented, attributable candidate statements in
--     the Tucson Agenda 2024 South Tucson candidate profile (fetched via the
--     tucsonagenda.substack.com mirror 2026-07-17 — the actually-fetched, cited source).
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
--     housing                = 669cac97-66a6-4087-b036-936fbe62efb3
--     homelessness-response  = 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
--
-- SEEDED (4 topics):
--   public-safety-approach = 4  (Tucson Agenda: "reinvesting in fire, police, public works"
--                                to make communities safer)
--   economic-development   = 2  (Tucson Agenda: supports "local and small businesses" for
--                                economic growth)
--   housing                = 3  (Tucson Agenda: "supporting renters and homeowners"; the
--                                article notes she made housing affordability and support
--                                for first-time buyers central to her platform)
--   homelessness-response  = 2  (Tucson Agenda: create "resources for people on the streets
--                                to get secure housing and jobs" — services/housing-provision
--                                framing, no criminalization)
--
-- DELIBERATELY BLANK (no clean, attributable documented position found):
--   city-sanitation / blight: she mentions addressing "streetlights" and "abandoned
--     properties," but that is code-enforcement/infrastructure, not the sanitation-and-
--     cleanliness chair spectrum. BLANK.
--   local-immigration, taxes, growth-and-development, residential-zoning, etc.: no citable
--     Jimenez position mapping to a chair.
--   Non-local federal/state topics (a council member has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
--     deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Dulce Jimenez / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jimenez ties public safety to reinvesting in the city's uniformed and service departments. In the Tucson Agenda South Tucson candidate profile she calls for "reinvesting in fire, police, public works" to make communities safer. Putting money back into police (and fire/public works) to improve safety — rather than redirecting police funding to social services (chair 1), shifting calls to unarmed responders (chair 2), or merely holding funding flat (chair 3) — matches increasing/restoring police staffing and funding to improve safety (chair 4). (Seeded only as this directional funding priority; she gives no further budget mechanics.)$$,
        ARRAY['https://tucsonagenda.substack.com/p/the-daily-agenda-meet-the-rest-of']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dulce Jimenez / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jimenez roots economic growth in the city's own small businesses. The Tucson Agenda profile reports she supports "local and small businesses" as her economic-development approach. For a one-square-mile city, that local/small-business-and-entrepreneur focus — rather than offering no incentives at all (chair 1), targeted industry incentives with community-benefit agreements (chair 3), or competing for major employers with significant tax abatements (chair 4) — matches small business support and local entrepreneur programs (chair 2).$$,
        ARRAY['https://tucsonagenda.substack.com/p/the-daily-agenda-meet-the-rest-of']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dulce Jimenez / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jimenez centered housing affordability on her platform. The Tucson Agenda profile reports she prioritizes "supporting renters and homeowners," and notes that she (with Robles) made "housing affordability and support for first-time buyers central to their platforms." Assisting both renters and homeowners and supporting first-time buyers through programs — rather than the city directly building/operating public housing for all comers (chair 1) or imposing rent caps and inclusionary mandates with publicly funded construction (chair 2) — matches offering targeted help like affordability subsidies and first-time-buyer assistance (chair 3).$$,
        ARRAY['https://tucsonagenda.substack.com/p/the-daily-agenda-meet-the-rest-of']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Dulce Jimenez / homelessness-response (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0a258242-d8c2-43ca-89ae-b891db3e21d8',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$On homelessness, Jimenez emphasizes providing services and pathways rather than enforcement. The Tucson Agenda profile reports she wants to create "resources for people on the streets to get secure housing and jobs." Leading with housing and employment resources for unsheltered residents, with no mention of camping bans or trespassing enforcement — rather than a strict housing-first, no-preconditions, no-criminalization model (chair 1), a services-plus-reasonable-enforcement mix (chair 3), or enforcement-first approaches (chairs 4-5) — matches expanding services and pathways to secure housing as the primary strategy (chair 2).$$,
        ARRAY['https://tucsonagenda.substack.com/p/the-daily-agenda-meet-the-rest-of']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
