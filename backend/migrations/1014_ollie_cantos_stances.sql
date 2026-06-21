-- 1014_ollie_cantos_stances.sql
-- Phase 152 Wave 4 (WCOV-01): evidence-only compass stances for Ollie Cantos (West Covina D4 Mayor Pro Tem, ext_id 687365).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1011). Committed to EV-Accounts.
-- CHAIRS model, 100% citation, honest blanks. pol_id ecc57cd4-aebc-49b7-b324-e28a0aaf05df. 3 evidence-backed stances.
-- NOTE: civil-rights omitted on purpose — Cantos's record is disability accessibility, which does not match the
-- racial-equity/affirmative-action chairs (no forcing). taxes/environment/transportation omitted (no clean chair match).

BEGIN;
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','e9ebefcd-c496-45e8-b816-a79f8442ba85',4),
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',3),
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','eb3d1247-0de1-4b7f-baec-7259861efd53',4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','e9ebefcd-c496-45e8-b816-a79f8442ba85',$$Cantos campaigned on and has governed toward expanding police presence: stated priorities include "facilitating more police officers on West Covina streets" and "restoring park patrols," and he formally requested a Police Department public-safety presentation so residents and businesses "can feel safe." This matches increasing police staffing/resources to deter crime (chair 4).$$,ARRAY['https://philpostblog.wordpress.com/2022/09/23/former-west-covina-mayor-steve-herfert-endorses-fil-am-ollie-cantos-for-city-council/','https://olliecantos.com/about']::text[]),
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',$$Cantos pursues a multi-agency strategy combining outreach/services with reasonable enforcement rather than pure housing-first or pure-enforcement — "tackling homelessness by expanding collaboration with stakeholders with proven expertise," consistent with the city's multidisciplinary HOPE Team. This balanced services-plus-enforcement posture matches chair 3.$$,ARRAY['https://philpostblog.wordpress.com/2022/09/23/former-west-covina-mayor-steve-herfert-endorses-fil-am-ollie-cantos-for-city-council/','https://www.westcovina.gov/330/Homeless-Solutions-for-West-Covina']::text[]),
('ecc57cd4-aebc-49b7-b324-e28a0aaf05df','eb3d1247-0de1-4b7f-baec-7259861efd53',$$Cantos prioritizes active business recruitment and a "business-friendly climate to attract greater economic activity and bolster local jobs," including reaching out to niche industries to relocate to the city to generate revenue. This active competition to attract employers and grow the tax base, without stated community-benefit conditions, fits chair 4.$$,ARRAY['https://philpostblog.wordpress.com/2022/09/23/former-west-covina-mayor-steve-herfert-endorses-fil-am-ollie-cantos-for-city-council/','https://olliecantos.com/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations.
