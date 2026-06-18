-- Migration 725: Deidre Duhart (Compton City Council, District 1) Stances
-- Phase 129 — Compton Stances. Deidre Duhart, external_id -700251, UUID a5db6e7d-2146-4dde-a778-05fa40566ac0.
-- Council Member (District 1). Appointed Apr 2022.
-- Topic UUID reference:
-- housing               = 669cac97-66a6-4087-b036-936fbe62efb3
-- economic-development  = eb3d1247-0de1-4b7f-baec-7259861efd53
-- growth-and-development= fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4

BEGIN;

-- housing = 2.0 (affordable housing in vision + successful housing developments)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Council Member Duhart names affordable housing as a core part of her vision for District 1 and counts successful housing developments among her achievements, supporting expanded housing production in Compton.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-1-deidre-duhart']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2.0 (jobs, livable wages, retail recruitment, small business)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Council Member Duhart prioritizes active economic development for District 1, calling for a robust shopping center, livable wages, and job opportunities for residents, and citing business developments among her achievements.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-1-deidre-duhart']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- growth-and-development = 2.0 (pro-growth, "Compton thriving again")
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5db6e7d-2146-4dde-a778-05fa40566ac0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Council Member Duhart's stated vision is to see Compton "thriving again" through continued economic growth and a mix of housing and business development, a pro-growth orientation toward new development in the city.$$,
ARRAY['https://www.comptoncity.org/our-city/elected-officials/district-1-deidre-duhart']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
