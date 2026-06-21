-- 954_jason_lyon_stances.sql  AUDIT-ONLY (NOT registered in schema_migrations; ledger stays 947)
-- Jason Lyon (D7, ext 657582) — evidence-only compass stances (chairs model), 100% citation.
-- Resolves politician_id by external_id and topic_id by topic_key at apply time (live topics only).
BEGIN;
WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 657582),
d(topic_key, val, reasoning, sources) AS (
 VALUES
  ('rent-regulation', 2::numeric, $stz$As a 2022 candidate Lyon endorsed Pasadena's rent-control/eviction-protection initiative, and as the District 7 councilmember he publicly championed implementing voter-approved Measure H, calling it a groundbreaking initiative and saying now begins the work of making the program a reality — consistent with strengthening and implementing rent stabilization rather than expanding to all units or opposing it.$stz$, ARRAY[$stz$https://www.pasadenanow.com/main/saturdays-third-post-election-ballot-count-update-shows-pasadenas-rent-control-measure-h-maintaining-lead$stz$,$stz$https://www.cityofpasadena.net/rent-stabilization/measure-h/$stz$]::text[]),
  ('homelessness-response', 2::numeric, $stz$Lyon helped establish a 2025 City Council budget priority to create a year-round homeless shelter and backed earmarking excess city funds toward it, framing the city's approach as addressing homelessness with compassion and expanding shelter capacity/services as the primary response.$stz$, ARRAY[$stz$https://pasadenanow.com/main/pasadena-floats-2-million-first-step-on-a-homeless-shelter$stz$]::text[]),
  ('climate-change', 2::numeric, $stz$Lyon prioritized and the City Council under his tenure approved Pasadena Water & Power's plan to reach 100% carbon-free electricity by 2030 — a rapid transition to renewable energy on an aggressive 2030 timeline.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-councilmember-jason-lyon-building-on-progress-meeting-seizing-opportunities-pasadena-in-2026$stz$,$stz$https://laist.com/news/politics/voter-guides/2026-election-california-primary-pasadena-city-councilmember-district-7$stz$]::text[]),
  ('transportation-priorities', 2::numeric, $stz$Lyon advocates a paradigm shift toward multimodal mobility — planned Greenways with traffic-calmed corridors for safer walking and biking, a comprehensive bike network, and pedestrian safety — describing the goal as a Pasadena where you can walk, bike, ride, or drive with equal ease.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-councilmember-jason-lyon-building-on-progress-meeting-seizing-opportunities-pasadena-in-2026$stz$,$stz$https://www.coloradoboulevard.net/events/greenways-ride-with-pasadena-council-members-jason-lyon-and-rick-cole/$stz$]::text[]),
  ('local-immigration', 3::numeric, $stz$In his own op-ed Lyon wrote approvingly that the City Council chose to preserve the rule of law by joining multiple lawsuits against aggressive federal immigration enforcement; the city's filing stressed enforcement forced local police to divert resources — signaling the city follows federal law but does not commit city resources to proactive immigration enforcement.$stz$, ARRAY[$stz$https://pasadenanow.com/main/guest-opinion-councilmember-jason-lyon-building-on-progress-meeting-seizing-opportunities-pasadena-in-2026$stz$,$stz$https://www.cityofpasadena.net/city-manager/news/city-of-pasadenas-legal-filing-regarding-aggressive-and-dangerous-federal-immigration-enforcement-practices/$stz$]::text[])
),
ans AS (
 INSERT INTO inform.politician_answers (politician_id, topic_id, value)
 SELECT pol.id, t.id, d.val
 FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
 ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value
 RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, t.id, d.reasoning, d.sources
FROM d JOIN inform.compass_topics t ON t.topic_key=d.topic_key AND t.is_live=true CROSS JOIN pol
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
COMMIT;
