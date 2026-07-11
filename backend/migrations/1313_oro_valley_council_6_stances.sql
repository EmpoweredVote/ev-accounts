-- =====================================================================================
-- Compass stances: Elizabeth Robb — Oro Valley (AZ) Town Council Member (at-large)
-- politician_id: 3bb254c4-0335-4377-b4ae-1313453c8ae9
-- Nonpartisan; small-business owner (Elizabeth's Garden), U.S. Army veteran; Town Council
-- member seated July 2024.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (on-record
--     campaign-questionnaire statement of priorities) taken during her candidacy/tenure,
--     with a real cited source URL confirmed via web research.
--   * Topics with no clear documented Robb position emit NO row (honest blank). No party
--     inference, no neutral defaults.
--   * AUDIT-ONLY / unregistered. Touches only inform.politician_answers and
--     inform.politician_context. The orchestrator applies it.
--
-- SEEDED (5 topics):
--   growth-and-development  = 2  (OV ~95% built out with 3,100 units already zoned; direct new
--                                 development only to areas with adequate infrastructure)
--   local-environment       = 2  (preserving OV's identity/aesthetic a top priority; limit
--                                 apartment heights to protect scenic corridors/open space)
--   residential-zoning       = 3  (favors mixed-use near commercial corridors — the Marketplace/
--                                 Village Center — with height limits protecting residential character)
--   taxes                    = 3  (town's "No Property Tax" founding principle; examine spending
--                                 before any secondary user tax or bonding — hold current structure)
--   public-safety-approach  = 4  (endorses continued strong OVPD support; credits Chief Riley
--                                 for keeping OV one of the safest towns in Arizona)
--
-- DELIBERATELY BLANK (no clean attributable compass position found):
--   Local: campaign-finance, childcare, city-sanitation, civil-rights, climate-change,
--          data-centers, economic-development, homelessness, homelessness-response, housing,
--          jail-capacity, local-immigration, rent-regulation, trans-athletes,
--          transportation-priorities, religious-freedom.
--     (Mixed-use / sales-tax-revenue remarks are folded into growth/zoning; water remarks have
--      no compass topic — not separately seeded.)
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, deportation, fossil-fuels, healthcare, immigration, medicare/aid,
--          misinformation, redistricting, same-sex-marriage, school-vouchers, social-security,
--          tariffs, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Robb / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Robb notes Oro Valley is "95% built out with 3,100 new residential units already zoned but not yet built," which she considers sufficient through 2040, and she advocates directing new development to areas that already have adequate infrastructure (citing the Oro Valley Marketplace as a model). That is a manage-growth-within-existing-capacity posture rather than actively recruiting new development or deregulating to accelerate it.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/elizabeth-robb/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robb / local-environment (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Robb describes preserving Oro Valley's "unique identity and aesthetic appeal" as "as high a priority" for her as for residents, and specifically supports limiting apartment heights at the Marketplace to protect scenic corridors and the town's "small-town feel." Her documented position leans toward strictly protecting the town's scenic/open-space character against development impacts.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/elizabeth-robb/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robb / residential-zoning (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Robb views mixed-use development favorably where it sits on commercial corridors — she cites the Oro Valley Village Center as growth that adds housing and boosts "sales tax revenues" without disturbing "desert open space" — while advocating apartment-height limits at the Marketplace to protect residential scenic character. That maps to allowing multifamily/mixed-use near commercial corridors while protecting the surrounding residential zones.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/elizabeth-robb/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robb / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Robb invokes the town's founding principle of "No Property Tax" and opposes new property taxes, urging that expenditures be examined before seeking "secondary user taxes" and opposing bonding until spending is reduced "everywhere we responsibly can." Oro Valley currently has no property tax, so her position is to hold the current tax structure as-is (no new property tax) with spending restraint — not to raise taxes, nor to cut existing taxes and scale back services.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/elizabeth-robb/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Robb / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3bb254c4-0335-4377-b4ae-1313453c8ae9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Robb says she feels "great about living in one of the safest towns in Arizona" and credits Police Chief Kara Riley's improvements to the department. Her documented position endorses continuing the town's strong support for and resourcing of the Oro Valley Police Department that produced that safety record, rather than redirecting or reducing police funding.$$,
        ARRAY['https://iloveov.com/candidates-for-town-council/elizabeth-robb/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
