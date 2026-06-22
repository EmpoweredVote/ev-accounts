-- 1024_inglewood_faulk_stances.sql
-- Phase 153 Wave 4 (INGL-01): evidence-only compass stances for Councilwoman Dionne Faulk
--   (Inglewood District 4, re-elected Nov 2024; ext_id 666264, pol 729bc539-3175-4e5d-96ba-c18768890e1e).
-- AUDIT-ONLY raw SQL: NOT registered in schema_migrations (ledger stays 1019). Committed to EV-Accounts.
-- CHAIRS model. 100% citation. Honest blanks for everything omitted. 2 evidence-backed stances, both from
-- verified Oct 2025 reporting on her District-4 community meetings re: the Morningside redevelopment.
-- OMITTED honest blanks: housing/rent-regulation (biography boilerplate only), public-safety/homelessness
--   (town-hall topic mentions != positions), local-immigration/immigration (no policy action), transportation,
--   residential-zoning (captured under growth), local-environment/city-sanitation/taxes + all federal/state.

BEGIN;

-- economic-development = 3 (PLA local-hire / community-benefit on the Morningside project for D4 residents)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('729bc539-3175-4e5d-96ba-c18768890e1e','eb3d1247-0de1-4b7f-baec-7259861efd53',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('729bc539-3175-4e5d-96ba-c18768890e1e','eb3d1247-0de1-4b7f-baec-7259861efd53',
$$At her October 2025 community meetings on the 571-townhome Morningside redevelopment, Faulk's documented central focus was ensuring the Project Labor Agreement delivers jobs and opportunities specifically to people who "live and work in the 4th District" -- local-hire / community-benefit conditions attached to a major project rather than unconditional abatements or no incentives. This matches chair 3 (targeted development tied to job quality and community benefit).$$,
ARRAY['https://www.pacenewsonline.com/2025/10/26/inglewood-4th-district-councilwoman-dionne-faulk-holds-second-community-meeting-for-residents-to-speak-on-proposed-project-at-site-of-morningside-high/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- growth-and-development = 3 (proactive community engagement on the R-1->R-3 rezoning)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('729bc539-3175-4e5d-96ba-c18768890e1e','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('729bc539-3175-4e5d-96ba-c18768890e1e','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Faulk personally convened multiple District 4 community meetings in October 2025 -- with the developer and the city's Development Services Director present -- to inform constituents about and take questions on the R-1-to-R-3 rezoning and 571-townhome project, surfacing traffic, parking, and security impacts. Her described role is proactive planning and community engagement on growth, not blanket barrier-removal or blocking, matching chair 3.$$,
ARRAY['https://www.pacenewsonline.com/2025/10/26/inglewood-4th-district-councilwoman-dionne-faulk-holds-second-community-meeting-for-residents-to-speak-on-proposed-project-at-site-of-morningside-high/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations (ledger stays 1019). 2 stances; remaining topics honest blanks.
