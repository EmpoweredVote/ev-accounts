-- Migration 891: Dawn McIntosh (Long Beach City Attorney, -700051) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 5 placements (incl. 3 judicial), 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('local-immigration',2),('judicial-transparency',2),('judicial-police-accountability',3),
  ('judicial-access-to-justice',4),('homelessness-response',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700051
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('local-immigration', $$Advised on and implemented Long Beach's Values Act sanctuary policy, which bars ICE from non-public city grounds without a judicial warrant, limits data sharing, and disciplines employees who cooperate, while preserving narrow exceptions she said are needed to survive legal challenge.$$, ARRAY['https://laist.com/news/long-beach-will-discipline-city-employees-who-disobey-sanctuary-policies']),
  ('judicial-transparency', $$Committed as City Attorney to push for staff training and resources to fully comply with the Public Records Act, favoring default-open access to city records.$$, ARRAY['https://cyc.lbpost.com/2022-long-beach-city-attorney/dawn-mcintosh/']),
  ('judicial-police-accountability', $$Described a data-driven claims approach in which her office reviews claims and lawsuits to spot trends and works with departments to fix underlying problems, representing the city while acknowledging and addressing meritorious systemic issues.$$, ARRAY['https://cyc.lbpost.com/2022-long-beach-city-attorney/dawn-mcintosh/']),
  ('judicial-access-to-justice', $$Warned against creating a private right of action against the city under the sanctuary ordinance, arguing it would waive legal immunities and invite expensive, meritless litigation, favoring higher bars to suing the city.$$, ARRAY['https://laist.com/news/long-beach-will-discipline-city-employees-who-disobey-sanctuary-policies']),
  ('homelessness-response', $$Stated homelessness requires comprehensive services including mental health and drug rehabilitation, safe transitional housing, jobs, and permanent affordable housing, while noting federal and state law constrain local enforcement.$$, ARRAY['https://cyc.lbpost.com/2022-long-beach-city-attorney/dawn-mcintosh/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = -700051
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
