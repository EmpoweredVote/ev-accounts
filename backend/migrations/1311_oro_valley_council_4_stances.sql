-- =====================================================================================
-- Compass stances: Dr. Harry "Mo" Greene II — Oro Valley (AZ) Town Council Member (at-large)
-- politician_id: 4e1a2e41-9e27-42db-8b47-00f697266987
-- Nonpartisan; physician; Town Council member (elected 2020, re-elected July 2024).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record
--     campaign-questionnaire statement of priorities / strategic-plan goals) taken during
--     his tenure, with a real cited source URL confirmed via web research.
--   * Topics with no clear documented Greene position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). Touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (4 topics):
--   growth-and-development  = 2  (managed growth aligned with community character; quality
--                                 development that maintains OV's character)
--   local-environment       = 3  ("quality development with integrated architecture and
--                                 natural open space" — balances development with preservation)
--   economic-development    = 2  (support/assist local & regional businesses; develop the OV
--                                 Marketplace — business support, not major-employer subsidies)
--   public-safety-approach  = 4  (keep officer salaries competitive, support department health
--                                 requests, keep OV among the safest communities in AZ)
--
-- DELIBERATELY BLANK (no clean attributable compass position found):
--   Local: campaign-finance, childcare, city-sanitation, civil-rights, climate-change,
--          data-centers, homelessness, homelessness-response, housing, jail-capacity,
--          local-immigration, rent-regulation, residential-zoning, taxes, trans-athletes,
--          transportation-priorities, religious-freedom.
--     (Housing remarks concern life-stage housing VARIETY, and fiscal remarks concern budget
--      tightening/revenue diversification — neither maps cleanly to a compass chair; not seeded.
--      Water-conservation/amenities remarks have no compass topic.)
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, deportation, fossil-fuels, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers, social-security,
--          tariffs, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Greene / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$In his Oro Valley council candidate questionnaire, Greene frames growth as something to manage in keeping with the town's existing character — "People come to OV because it's an excellent place to live and that accounts for its growth" — and states a strategic-plan goal to "ensure quality development with integrated architecture and natural open space, while maintaining and enhancing the character of our community," alongside "managed growth of new homes and apartments." That is a manage-growth-to-fit-capacity-and-character posture rather than actively recruiting development to grow the tax base or removing barriers.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/harry-mo-greene/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greene / local-environment (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Greene's stated strategic goal is to "ensure quality development with integrated architecture and natural open space, while maintaining and enhancing the character of our community." He couples a commitment to preserving natural open space with continued quality development, i.e. applying consistent standards that protect open space while still allowing development to proceed with reasonable flexibility — a balance rather than a strict-preservation-first or a pay-to-pave posture.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/harry-mo-greene/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greene / economic-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Greene's economic-development priority is to "support and assist local (and regional) businesses by helping to navigate the current and projected economic conditions," together with developing the Oro Valley Marketplace and diversifying town revenue. His emphasis is on helping existing local and regional businesses succeed rather than competing for major employers with large tax abatements or maximal incentives.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/harry-mo-greene/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greene / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4e1a2e41-9e27-42db-8b47-00f697266987',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Greene praises Oro Valley's police services under Chief Kara Riley as "the best public safety record in the state," pledges to "keep our officers' salaries at a competitive level," commits to supporting the department's health/resource requests, and sets a strategic goal of keeping Oro Valley "one of (if not the best) safest communities in Arizona." That is a posture of increasing/strongly sustaining police staffing, pay and resources.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/harry-mo-greene/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
