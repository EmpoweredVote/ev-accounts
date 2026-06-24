-- Migration 1058: Clark County Commission stances - Marilyn Kirkpatrick (District B) (AUDIT-ONLY)
--
-- Phase 161 (CLARK-01). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1055. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- county-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 61cac872-e8f3-4396-aacd-cf1be6509a92 (external_id -3200302, minted by mig 1055).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness-response'::text, 2, 'As commission chair, championed shifting county dollars (incl. ~$20M marijuana-tax revenue) into homelessness programs; the board approved $6.1M for permanent-housing/shelter programs that nearly doubled shelter beds to 584; stressed a non-coercive rapid re-housing model: We''re not forcing people, we''re not doing a burn and turn in three days.', ARRAY['https://thenevadaindependent.com/article/clark-county-commissioners-shift-6-1-million-toward-their-ongoing-quest-to-reduce-homelessness']::text[]),
    ('housing'::text, 3, 'Helped establish and fund Clark County''s Welcome Home Community Land Trust (Rebecca Place, 30 homes for first-time buyers under 80-100% AMI), county owns the land and uses budget set-asides for down-payment assistance; said the county put some of our dollars every budget cycle into our community land trust (Feb 2 2026).', ARRAY['https://vegasinc.lasvegassun.com/news/2026/feb/02/clark-county-puts-trust-in-community-land-approach/','https://nevadacurrent.com/2026/01/09/clark-county-land-trust-program-aims-to-provide-housing-families-can-afford/']::text[]),
    ('public-safety-approach'::text, 4, 'April 19, 2025: voted (unanimous) to extend a property tax levy funding salaries of 800+ LVMPD officers (~$155M/yr): It''s important enough that we vote to help make sure those officers stay on our streets.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/clark-county/extension-of-tax-money-approved-for-las-vegas-police-officers-3354008/']::text[]),
    ('data-centers'::text, 3, 'June 2026: voted to approve the Switch southwest-valley data center expansion only after commissioners pressured the company to withdraw its landscaping/tree waiver, amid discussion of water/energy impacts and the need for a future data-center ordinance: not willy-nilly approving things, we''ve thought about a lot of these things.', ARRAY['https://nevadacurrent.com/2026/06/18/las-vegas-data-center-expansion-approved-as-officials-ponder-need-for-future-regulations/','https://elkodaily.com/news/state-regional/nevada/article_9912236d-f1c5-5471-a43e-d485c62b706a.html']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '61cac872-e8f3-4396-aacd-cf1be6509a92'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '61cac872-e8f3-4396-aacd-cf1be6509a92'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
