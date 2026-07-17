-- =====================================================================================
-- Compass stances: Melissa Brown-Dominguez — Vice Mayor, City of South Tucson (AZ)
-- politician_id: cbee242a-e992-46e6-a7ea-5aad11816c50   (external_id -4015002)
-- Nonpartisan (antipartisan display). Elected to the City Council November 2024 (term
-- thru 2028 — NOT up in the July 21, 2026 primary); chosen Vice Mayor by the council
-- (Vice Mayor is a council-selected TITLE, not a directly elected office). Positions
-- attributed ONLY to her own on-record statements/actions; no other member's views.
-- Recall-era / historical South Tucson politics are BACKGROUND, never current-roster fact.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * The seeded topic is backed by her documented, attributable on-record position (the
--     Tucson Spotlight council profile — a non-WAF source actually fetched 2026-07-17).
--   * As a 2024-seated member she is NOT in the 2026 candidate voter guide, so her public
--     policy record is thin; topics with no clear documented position emit NO row (honest
--     blank). No party inference, no neutral defaults.
--   * Discrete 1-5 "chairs" (feedback_compass_chairs_not_polarity), never a polarity scale.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers /
--     inform.politician_context. The orchestrator applies it.
--
-- Reference: topic UUIDs used below (36 non-judicial live topics in scope; the 8
--   judicial-* topics are NEVER seeded for a city council official):
--     public-safety-approach = e9ebefcd-c496-45e8-b816-a79f8442ba85
--
-- SEEDED (1 topic):
--   public-safety-approach = 4  (Tucson Spotlight: advocated for "safer neighborhoods and
--                                a well-funded police department")
--
-- DELIBERATELY BLANK (no clean, attributable documented position found):
--   Her documented civic identity — co-owner of Galeria Mitotera, a gallery celebrating
--     Latinx and queer local artists — is a personal/cultural fact, NOT a stated policy
--     position; inferring a civil-rights or same-sex-marriage chair from it would be
--     inference, not evidence. BLANK (honest).
--   collaboration statements ("this has to work collaboratively") describe process, not a
--     topical policy chair. BLANK.
--   All other local topics (taxes, housing, economic-development, homelessness-response,
--     growth-and-development, local-immigration, etc.): no citable Brown-Dominguez position.
--   Non-local federal/state topics (a vice mayor has no governing record on these):
--     abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
--     deportation, fossil-fuels, healthcare, immigration, jail-capacity, medicare/aid,
--     misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--     social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- ----- Melissa Brown-Dominguez / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cbee242a-e992-46e6-a7ea-5aad11816c50',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cbee242a-e992-46e6-a7ea-5aad11816c50',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Brown-Dominguez's one clearly documented policy priority is public safety through police funding. The Tucson Spotlight council profile reports she "advocated for 'safer neighborhoods and a well-funded police department.'" Naming a well-funded police department as an affirmative goal places her on the pro-police-resourcing side — not redirecting police money to social services (chair 1), shifting calls to unarmed responders (chair 2), or merely holding funding flat (chair 3) — consistent with increasing police staffing, equipment, and funding to improve neighborhood safety (chair 4). (No further specifics on crisis-response teams or budget mechanics are on record, so only this directional priority is seeded.)$$,
        ARRAY['https://www.tucsonspotlight.org/inside-south-tucson/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
