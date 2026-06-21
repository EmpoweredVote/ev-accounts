-- 917_rocio_castellanos_stances.sql — Phase 145 Wave 4 — AUDIT-ONLY (not registered)
-- Evidence-only stances for Rocio Castellanos (Lancaster Councilmember, sworn in Apr 28 2026), external_id -700656.
-- 2 topics (platform-only; just sworn in). NOTE: 915 (Hughes-Leslie) intentionally omitted — 0 citable stances (honest blank).
BEGIN;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-700656),
s(topic_key,val,reasoning,sources) AS (VALUES
 ('economic-development',3,$r$Her platform supports small businesses with incentives and grants while seeking to attract new industries that bring quality jobs — targeted economic development tied to community jobs benefit rather than blanket big-business abatements or no-incentive purism.$r$,ARRAY[$u$https://www.avdailynews.com/single-post/meet-rocio-castellanos-a-hopeful-candidate-for-the-lancaster-city-council-2026$u$]),
 ('housing',3,$r$Her documented housing position is to expand affordable housing by investing in mixed-income developments and preserving existing affordable units — public investment plus preservation/targeted approach, without rent caps/inclusionary mandates or developer deregulation.$r$,ARRAY[$u$https://www.avdailynews.com/single-post/meet-rocio-castellanos-a-hopeful-candidate-for-the-lancaster-city-council-2026$u$]))
INSERT INTO inform.politician_answers(politician_id,topic_id,value)
SELECT pol.pid,t.id,s.val FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET value=EXCLUDED.value;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-700656),
s(topic_key,reasoning,sources) AS (VALUES
 ('economic-development',$r$Her platform supports small businesses with incentives and grants while seeking to attract new industries that bring quality jobs — targeted economic development tied to community jobs benefit rather than blanket big-business abatements or no-incentive purism.$r$,ARRAY[$u$https://www.avdailynews.com/single-post/meet-rocio-castellanos-a-hopeful-candidate-for-the-lancaster-city-council-2026$u$]),
 ('housing',$r$Her documented housing position is to expand affordable housing by investing in mixed-income developments and preserving existing affordable units — public investment plus preservation/targeted approach, without rent caps/inclusionary mandates or developer deregulation.$r$,ARRAY[$u$https://www.avdailynews.com/single-post/meet-rocio-castellanos-a-hopeful-candidate-for-the-lancaster-city-council-2026$u$]))
INSERT INTO inform.politician_context(politician_id,topic_id,reasoning,sources)
SELECT pol.pid,t.id,s.reasoning,s.sources FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning,sources=EXCLUDED.sources;
COMMIT;
