-- =====================================================================================
-- Compass stances: Joyce Jones-Ivey — Oro Valley (AZ) Town Council Member (at-large)
-- politician_id: d9d52a86-359c-45b0-a2c6-297e67c0e669
-- Nonpartisan; retired nurse, OV resident since 2016; sitting Town Council member during
-- the Winfield-majority years; NOT seeking reelection in 2026.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Council
--     vote, on-record public statement, or stated priority) taken during her tenure, with
--     real cited source URLs confirmed via web research.
--   * Topics with no clear documented Jones-Ivey position emit NO row (honest blank). No
--     party inference, no neutral defaults. She has a thin public issue record; only the
--     topics with clean, attributable evidence are seeded.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (3 topics, all applies_local=true):
--   economic-development    = 4  (touts recruiting Leonardo Electronics/170 jobs + ~$700K
--                                 town resources for Westward Look; jobs/revenue as top goals)
--   growth-and-development  = 4  (4-1 Apr 21 2021 vote to annex/GP-amend/rezone Westward Look;
--                                 "not opposed to adding apartments and a hotel")
--   public-safety-approach  = 4  (makes safety the town's top priority; strong backing of the
--                                 police department and its leadership; community-police engagement)
--
-- DELIBERATELY BLANK (no attributable documented position found):
--   Local: campaign-finance, city-sanitation, civil-rights, climate-change, data-centers,
--          fossil-fuels, homelessness, homelessness-response, housing, jail-capacity,
--          local-environment, local-immigration, rent-regulation, residential-zoning,
--          transportation-priorities, trans-athletes, religious-freedom.
--   Non-local federal/state (a town council member has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, same-sex-marriage, school-vouchers, social-security, tariffs,
--          taxes, ukraine-support, voting-rights, childcare.
--   (Golf-subsidy reduction and Naranja Park amenities are fiscal/parks accomplishments with
--    no clean compass-chair match and are intentionally NOT seeded.)
-- =====================================================================================

BEGIN;

-- ----- Joyce Jones-Ivey / economic-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jones-Ivey has stated that "bringing prosperity, like more jobs, into Oro Valley and increasing revenue are two big goals for her," and she publicly pointed to the town's active recruitment wins as evidence of that approach — Leonardo Electronics (~170 jobs) and the Westward Look Grand Resort, for which she noted the town committed roughly $700,000 in resources. Her documented posture is actively competing for and investing town dollars/incentives to land major employers and grow revenue, rather than a no-incentive or small-business-only stance.$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/article_c4be4b78-0d53-11ed-911e-ffeb76be5540.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joyce Jones-Ivey / growth-and-development (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$In a series of 4-1 votes on April 21, 2021 — the lone dissent being Councilmember Tim Bohen — the Oro Valley Town Council, including Jones-Ivey, approved annexing the Westward Look Resort along with a General Plan amendment and zoning-code changes to enable future development on the property. Consistent with that pro-development record, Jones-Ivey said of the Oro Valley Marketplace that "I am not opposed to adding apartments and a hotel, as well as other businesses." Her documented actions favor approving annexation, rezoning, and new development to expand the town's tax base rather than imposing growth limits or slowing approvals.$$,
        ARRAY['https://www.tucsonlocalmedia.com/news/oro_valley/article_8e640b0a-a37b-11eb-b573-af111ed46c93.html',
              'https://www.tucsonlocalmedia.com/explorernews/article_c4be4b78-0d53-11ed-911e-ffeb76be5540.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joyce Jones-Ivey / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9d52a86-359c-45b0-a2c6-297e67c0e669',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jones-Ivey makes public safety her signature priority, saying "we pride ourselves here in town on being the safest city in Arizona," and she has consistently championed strong support for the Oro Valley Police Department — praising Chief Kara Riley as the most qualified of roughly 50 candidates, backing programs such as Coffee with a Cop and a 12-week Community Academy, and emphasizing keeping open communication with the department. Her documented record reflects maintaining strong support for and investment in policing rather than redirecting police resources to other services.$$,
        ARRAY['https://www.tucsonlocalmedia.com/explorernews/article_c4be4b78-0d53-11ed-911e-ffeb76be5540.html']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
