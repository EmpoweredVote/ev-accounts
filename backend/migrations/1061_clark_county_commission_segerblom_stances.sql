-- Migration 1061: Clark County Commission stances - Tick Segerblom (District E) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 5ffa5251-9255-44ef-a5d5-8e158f29c6e5 (external_id -3200305, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 3, 'Proposed (Sept/Oct 2024) and voted for the camping/sleeping ban the commission passed 6-1 on Nov 6, 2024; the ordinance is enforced only when the county has available shelter beds, and he framed it as redirecting people to existing services (anyone who will seek treatment, we have a place for you).', ARRAY['https://lasvegassun.com/news/2024/nov/06/clark-county-commissioners-approve-ban-on-sleeping/','https://lasvegassun.com/news/2024/sep/24/clark-county-commissioner-wants-to-battle-encampme/']::text[]),
    ('homelessness-response'::text, 3, 'In initiating the camping ban, emphasized the county had invested heavily in housing/services and shelter (we have the resources to take care of the problem) while backing enforcement of anti-camping rules conditioned on bed availability (outreach+shelter+services combined with enforcing rules).', ARRAY['https://lasvegassun.com/news/2024/sep/24/clark-county-commissioner-wants-to-battle-encampme/','https://lasvegassun.com/news/2024/nov/06/clark-county-commissioners-approve-ban-on-sleeping/']::text[]),
    ('climate-change'::text, 3, 'Drove Clark County to become the first NV county to join the County Climate Coalition, committing to Paris Climate Accord GHG-reduction goals under the Office of Sustainability with renewable energy scale-up as the central strategy (invest in clean energy / gradual).', ARRAY['https://thenevadaindependent.com/article/clark-county-seeks-to-boost-its-climate-change-efforts-with-new-position-coordinated-planning','https://www.reviewjournal.com/news/politics-and-government/clark-county/commissioners-want-clark-county-to-fight-climate-change-1853169/']::text[]),
    ('data-centers'::text, 3, 'At the mid-June 2026 unanimous approval of Switch''s expansion, said the county should adopt a data-center ordinance to consolidate its approach to facilities water/energy demands and that proactive steps to address impacts are essential, while still voting to allow the project (allow with impact assessments + community benefit).', ARRAY['https://lasvegassun.com/news/2026/jun/23/switch-wins-las-vegas-expansion-approval-even-as-d/','https://www.govtech.com/artificial-intelligence/clark-county-nev-commissioners-approve-data-center-project']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '5ffa5251-9255-44ef-a5d5-8e158f29c6e5'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '5ffa5251-9255-44ef-a5d5-8e158f29c6e5'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
