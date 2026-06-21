-- 1003_jessica_ancona_stances.sql
-- Phase 151 Wave 4 (ELMN-01): Jessica Ancona (Mayor of El Monte, ext_id -200669) evidence-only compass stances.
-- AUDIT-ONLY — applied via raw SQL, NOT registered in schema_migrations (ledger stays 1001). Idempotent.
-- Chairs model; 100% citation; honest blanks preserved. Mayor since ~2020 (re-elected Nov 2024). Record is
-- thin/high-level on compass-mappable policy -> 5 well-cited stances, the rest honest blanks.

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, v.value
FROM (VALUES
  ('economic-development', 3),
  ('public-safety-approach', 3),
  ('local-environment', 2),
  ('civil-rights', 3),
  ('homelessness-response', 2)
) AS v(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -200669
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, v.reasoning, v.sources
FROM (VALUES
  ('economic-development', $$Her platform pledges to attract new businesses and support existing small businesses while tying development to community benefits — workforce development, local hiring, living wages, and Project Labor Agreements (active recruitment conditioned on job-quality/community-benefit requirements).$$, ARRAY['https://www.jessicaancona.com/platfrom-issues']),
  ('public-safety-approach', $$She "strongly supports establishing Community Policing so that our officers and community can build relationships" and pledges programs to reduce crime (e.g., STOP traffic-offender program, catalytic-converter etching) — maintaining police funding while adding community/prevention programs.$$, ARRAY['https://www.jessicaancona.com/platfrom-issues','https://www.jessicaancona.com/meet-jessica']),
  ('local-environment', $$A core stated priority is "planting of more trees throughout the city to increase our urban tree canopy" and ensuring "all residents have access to green spaces," alongside reducing the city's carbon footprint — an affirmative commitment to protecting/expanding parks and tree canopy.$$, ARRAY['https://www.jessicaancona.com/platfrom-issues','https://www.jessicaancona.com/']),
  ('civil-rights', $$She brought forth "the first Proclamation in El Monte's history that proclaimed June as Pride Month" and campaigned on inclusivity — active promotion of equal opportunity/inclusion via symbolic advocacy rather than documented new enforcement mandates.$$, ARRAY['https://www.jessicaancona.com/meet-jessica']),
  ('homelessness-response', $$She emphasizes a "full on effort to tackle homelessness and finding more housing for everyone," and in a June 2025 council discussion criticized as "truly unfortunate" that El Monte under-benefits from County Measure H homelessness-services funding — a documented focus on expanding services/funding with no enforcement/anti-camping position.$$, ARRAY['https://www.jessicaancona.com/','https://midvalleynews.com/el-monte-reviews-homeless-services-grant-strategy/'])
) AS v(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -200669
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
