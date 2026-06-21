-- 916_cedric_white_stances.sql — Phase 145 Wave 4 — AUDIT-ONLY (not registered)
-- Evidence-only stances for Cedric White (Lancaster Councilmember, sworn in Apr 28 2026), external_id -700655.
-- 1 topic (platform-only; just sworn in → mostly honest blanks).
BEGIN;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-700655),
s(topic_key,val,reasoning,sources) AS (VALUES
 ('housing',3,$r$His campaign site states housing must meet the needs of working-class families and that through smart development and tenant protections people who work in Lancaster can afford to live there — pairing development with tenant protections/affordability (chair 3) rather than pure deregulation or specific rent caps.$r$,ARRAY[$u$https://whiteforlancasterca.net/$u$]))
INSERT INTO inform.politician_answers(politician_id,topic_id,value)
SELECT pol.pid,t.id,s.val FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET value=EXCLUDED.value;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-700655),
s(topic_key,reasoning,sources) AS (VALUES
 ('housing',$r$His campaign site states housing must meet the needs of working-class families and that through smart development and tenant protections people who work in Lancaster can afford to live there — pairing development with tenant protections/affordability (chair 3) rather than pure deregulation or specific rent caps.$r$,ARRAY[$u$https://whiteforlancasterca.net/$u$]))
INSERT INTO inform.politician_context(politician_id,topic_id,reasoning,sources)
SELECT pol.pid,t.id,s.reasoning,s.sources FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning,sources=EXCLUDED.sources;
COMMIT;
