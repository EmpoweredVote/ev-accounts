-- Migration 884: Kristina Duggan (Long Beach Council D3, 665833) — evidence-only compass stances
-- Phase 142 Wave 4. AUDIT-ONLY (raw SQL; NOT in schema_migrations). 8 placements, 100% citation. 2026-06-19.

BEGIN;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, d.value
FROM (VALUES
  ('public-safety-approach',4),('homelessness',3),('homelessness-response',3),('residential-zoning',2),
  ('growth-and-development',2),('local-immigration',2),('fossil-fuels',3),('local-environment',2)
) AS d(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665833
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, d.reasoning, d.sources::text[]
FROM (VALUES
  ('public-safety-approach', $$Stated top priority is rebuilding/expanding the police department, and she authored a Belmont Shore late-night safety plan adding police presence and enforcement.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/','https://www.longbeach.gov/district3/councilpolicy/']),
  ('homelessness', $$Authored encampment-enforcement policies but supports outreach, CARE Court, SB 43 holds and diversion before escalation rather than blanket criminalization.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/','https://www.longbeach.gov/district3/councilpolicy/']),
  ('homelessness-response', $$Advocates a balanced approach combining compassion and accountability — expanding treatment/services while addressing problematic encampments with reasonable rules.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/','https://www.kristinaduggan.com/']),
  ('residential-zoning', $$Supports smart, targeted growth but opposes uniform density upzoning, favoring larger development downtown while protecting established neighborhoods and historic districts.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/']),
  ('growth-and-development', $$Backs concentrating major housing downtown where appropriate while protecting established neighborhoods, rather than across-the-board development.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/']),
  ('local-immigration', $$Opposes having LBPD intervene in federal ICE enforcement or escalate, and focuses on informing residents of their rights while staying within the law.$$, ARRAY['https://sigtrib.com/candidate-questionnaires-district-3-candidate-kristina-duggan/']),
  ('fossil-fuels', $$Seeks to retain/modernize Long Beach's share of existing oil revenue to fund tidelands rather than ban or expand extraction, while commissioning a climate-transition fiscal audit.$$, ARRAY['https://lbpost.com/news/politics/long-beach-oil-revenue-renegotiate-tidelands-state/','https://www.longbeach.gov/district3/councilpolicy/']),
  ('local-environment', $$Authored Colorado Lagoon restoration oversight, LA River watershed pollution advocacy, sewage-spill assessment, and a resolution supporting San Gabriel Mountains protection.$$, ARRAY['https://www.longbeach.gov/district3/councilpolicy/'])
) AS d(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = d.topic_key
JOIN essentials.politicians p ON p.external_id = 665833
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
