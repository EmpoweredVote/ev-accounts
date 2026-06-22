-- 1023_inglewood_morales_stances.sql
-- Phase 153 Wave 4 (INGL-01): evidence-only compass stances for Councilmember Eloy Morales, Jr.
--   (Inglewood District 3, since 2003; ext_id 666263, pol 6ed19c10-7b34-47f0-8705-0d154271e362).
-- AUDIT-ONLY raw SQL: NOT registered in schema_migrations (ledger stays 1019). Committed to EV-Accounts.
-- CHAIRS model. 100% citation. Honest blanks for everything omitted. 3 evidence-backed stances; each
-- confirmed via a Morales-SPECIFIC statement/motion (not copied from Butts despite unanimous votes).
-- OMITTED honest blanks: local-immigration/immigration (sympathy, no city enforcement-policy action),
--   economic-development (his ITC words focused on the development/Market St, not incentive terms), + all else.

BEGIN;

-- rent-regulation = 2 (moved Just-Cause into the 2019 rent moratorium; building toward stabilization)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$At the March 5, 2019 meeting Morales voted Aye for Inglewood's interim 45-day rent-increase moratorium (Ord. 19-07, 5% cap) and personally pushed to add "Just Cause" eviction protection into it, stating his intent was "to protect the residents within the 45-day period" while framing it as a pause to build toward rent stabilization. Supporting the creation and strengthening of tenant stabilization protections matches chair 2.$$,
ARRAY['https://www.cityofinglewood.org/AgendaCenter/ViewFile/Minutes/_03052019-2692']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- growth-and-development = 3 (seconded + praised the EIR-vetted, proactively planned ITC TOD)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$On April 12, 2022 Morales seconded and voted Aye on the Inglewood Transit Connector approvals (EIR certification Res. 22-71, General Plan amendments, zone change Ord. 22-08), calling it "an amazing development, that once was a dream and now it is reality" and a "complete benefit to Market Street." Embracing a major, EIR-vetted, proactively planned transit-oriented development serving the city's activity centers matches chair 3.$$,
ARRAY['https://www.cityofinglewood.org/AgendaCenter/ViewFile/Minutes/_04122022-3659']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- transportation-priorities = 3 (ITC second + Aye; selective transit at high-density activity centers)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','ba59337e-30e2-4aba-a39a-426b3366eb27',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ed19c10-7b34-47f0-8705-0d154271e362','ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Morales seconded and voted Aye on the Inglewood Transit Connector (an automated people-mover linking SoFi Stadium, the Forum, and Intuit Dome to Metro rail), praising it for connecting residents safely and benefiting Market Street. His support targets transit investment serving high-density activity centers rather than a citywide transit-over-cars reprioritization, matching chair 3.$$,
ARRAY['https://www.cityofinglewood.org/AgendaCenter/ViewFile/Minutes/_04122022-3659']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations (ledger stays 1019). 3 stances; remaining topics honest blanks.
