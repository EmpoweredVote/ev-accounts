-- 1022_inglewood_padilla_stances.sql
-- Phase 153 Wave 4 (INGL-01): evidence-only compass stances for Councilmember Alex Padilla
--   (Inglewood District 2; ext_id -701002, pol 123c9a42-5715-4ab2-a8bd-76e7adbca27b).
-- AUDIT-ONLY raw SQL: NOT registered in schema_migrations (ledger stays 1019). Committed to EV-Accounts.
-- CHAIRS model. 100% citation. Honest blanks for everything omitted. 2 evidence-backed stances, both
-- anchored to the verified April 12, 2022 Inglewood City Council minutes (Padilla quoted by name + Aye vote).
-- OMITTED honest blanks: local-immigration/immigration (sympathy statement, NO city enforcement-policy action;
--   Inglewood has not adopted a sanctuary ordinance), rent-regulation/housing (non-committal), growth-and-development
--   (no Padilla-specific philosophy beyond ITC -- not copied from Butts), public-safety (biographical only), + all else.

BEGIN;

-- economic-development = 3 (endorsed ITC on local-hire/community-benefit grounds)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('123c9a42-5715-4ab2-a8bd-76e7adbca27b','eb3d1247-0de1-4b7f-baec-7259861efd53',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('123c9a42-5715-4ab2-a8bd-76e7adbca27b','eb3d1247-0de1-4b7f-baec-7259861efd53',
$$At the April 12, 2022 Inglewood City Council meeting, Council Member Padilla praised the Inglewood Transit Connector and specifically highlighted its "35% local hires of residents that would gain employment from the project," citing outreach with local business owners as a reason for his support before voting Aye. Endorsing development on the explicit basis of local-hire / job-quality community benefits matches chair 3 (targeted incentives tied to community benefit), not blanket abatements.$$,
ARRAY['https://www.cityofinglewood.org/AgendaCenter/ViewFile/Minutes/_04122022-3659']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- transportation-priorities = 3 (voted for ITC; selective major transit in the dense venue corridor)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('123c9a42-5715-4ab2-a8bd-76e7adbca27b','ba59337e-30e2-4aba-a39a-426b3366eb27',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('123c9a42-5715-4ab2-a8bd-76e7adbca27b','ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Padilla voted Aye to approve the $1.2B Inglewood Transit Connector and praised its "positive impact on the traffic, which would alleviate people driving cars to events," and the same action created a Transportation Corridor Overlay Zone. His framing centered on relieving event congestion in a dense corridor (alongside road investment such as the Crenshaw Blvd improvement contract approved the same meeting) rather than a citywide transit/bike/ped-first reordering, matching chair 3.$$,
ARRAY['https://www.cityofinglewood.org/AgendaCenter/ViewFile/Minutes/_04122022-3659']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations (ledger stays 1019). 2 stances; remaining topics honest blanks.
