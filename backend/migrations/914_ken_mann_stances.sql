-- 914_ken_mann_stances.sql — Phase 145 Wave 4 — AUDIT-ONLY (not registered)
-- Evidence-only stances for Ken Mann (Lancaster Councilmember), external_id -201281. 3 topics.
BEGIN;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-201281),
s(topic_key,val,reasoning,sources) AS (VALUES
 ('public-safety-approach',4,$r$Mann's documented signature initiative (his reelection pitch) is standing up a hybrid city police department to support the sheriff's deputies — adding city policing capacity, the increase-staffing chair.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$,$u$https://www.cityoflancasterca.org/our-city/departments-services/public-safety/lancaster-police-department$u$]),
 ('homelessness-response',3,$r$Mann pairs expanding capacity (increasing shelter and transitional housing) with enforcement — the new hybrid officers focus on low-level crimes involving the homeless — a services-plus-reasonable-rules approach.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$]),
 ('economic-development',4,$r$Mann campaigns on actively recruiting business and jobs — touting Lancaster's Most Business-Friendly City recognition and economic-development programs that attracted thousands of jobs — an active recruitment posture.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$]))
INSERT INTO inform.politician_answers(politician_id,topic_id,value)
SELECT pol.pid,t.id,s.val FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET value=EXCLUDED.value;
WITH pol AS (SELECT id AS pid FROM essentials.politicians WHERE external_id=-201281),
s(topic_key,reasoning,sources) AS (VALUES
 ('public-safety-approach',$r$Mann's documented signature initiative (his reelection pitch) is standing up a hybrid city police department to support the sheriff's deputies — adding city policing capacity, the increase-staffing chair.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$,$u$https://www.cityoflancasterca.org/our-city/departments-services/public-safety/lancaster-police-department$u$]),
 ('homelessness-response',$r$Mann pairs expanding capacity (increasing shelter and transitional housing) with enforcement — the new hybrid officers focus on low-level crimes involving the homeless — a services-plus-reasonable-rules approach.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$]),
 ('economic-development',$r$Mann campaigns on actively recruiting business and jobs — touting Lancaster's Most Business-Friendly City recognition and economic-development programs that attracted thousands of jobs — an active recruitment posture.$r$,ARRAY[$u$https://www.avpress.com/news/mann-makes-pitch-for-council-reelection/article_99580e72-dd06-11ee-84b4-c3ccad7ed192.html$u$]))
INSERT INTO inform.politician_context(politician_id,topic_id,reasoning,sources)
SELECT pol.pid,t.id,s.reasoning,s.sources FROM s JOIN inform.compass_topics t ON t.topic_key=s.topic_key CROSS JOIN pol
ON CONFLICT (politician_id,topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning,sources=EXCLUDED.sources;
COMMIT;
