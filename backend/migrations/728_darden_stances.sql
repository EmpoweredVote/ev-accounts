-- Migration 728: Lillie P. Darden (Compton City Council, District 4) Stances
-- Phase 129 — Compton Stances. Lillie P. Darden, external_id -700254, UUID 10429226-b00b-4b96-b306-753c2094d719.
-- Council Member (District 4), Mayor Pro Tem. Appointed July 2021.
-- NOTE: Thin public-policy record. Most coverage is biographical (former Compton Municipal Water
-- Department GM, youth/financial-literacy programs) rather than directional stances. Only the
-- HOPICS homeless-services engagement establishes a clear positional stance. Remaining spokes are
-- left blank per the evidence-only rule (no defaulting).
-- Topic UUID reference:
-- homelessness-response = 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f

BEGIN;

-- homelessness-response = 2.0 (HOPICS Access Center + housing/care programs engagement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10429226-b00b-4b96-b306-753c2094d719', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10429226-b00b-4b96-b306-753c2094d719', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Council Member Darden toured the HOPICS Compton Access Center and adjacent housing programs with Mayor Sharif, publicly backing comprehensive care and supportive-housing services for unhoused residents — a services-oriented approach to homelessness rather than enforcement-first.$$,
ARRAY['https://www.comptoncity.org/Home/Components/News/News/97/16']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
