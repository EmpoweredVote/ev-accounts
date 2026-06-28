-- Migration 1078: City of Las Vegas stances - Brian Knudsen (Council Member, Ward 1 / Mayor Pro Tem) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks where no city-level evidence. No defaults.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 169596c9-1ece-4a8a-b601-ce87af369a33 (external_id -3205002, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 2, 'One of only two council members to vote AGAINST the Las Vegas homeless camping ban (passed 5-2, Nov 6 2019); publicly opposed criminalizing homelessness, arguing the right approach is adequate housing, mental health and health-care services rather than fines/jail.', ARRAY['https://m.lasvegassun.com/news/2019/nov/06/tense-las-vegas-council-oks-homeless-ordinance/','https://battlebornprogress.org/homelessordinancevote/']::text[]),
    ('homelessness-response'::text, 2, 'Champions the $200M Campus for Hope - 900 shelter beds bundled with health care, job training and housing placement (modeled on San Antonio''s Haven for Hope); frames homelessness response around expanding shelter + wraparound services rather than enforcement.', ARRAY['https://newdealleaders.org/idea/las-vegas-city-councilman-brian-knudsen-fights-homelessness-with-nevadas-new-campus-for-hope/']::text[]),
    ('housing'::text, 2, '2024 re-election campaign site states he is committed to "promoting neighborhood density and affordable housing solutions that will allow all residents to afford a place to live."', ARRAY['https://www.electbrianknudsen.com/']::text[]),
    ('public-safety-approach'::text, 3, '2024 priority is building a crisis response system in collaboration with LVMPD, the State, Clark County and hospital systems - adding mental-health crisis-response capacity alongside police rather than cutting or making police the top priority.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/knudsen-launches-re-election-bid-to-las-vegas-council-2736638/']::text[]),
    ('civil-rights'::text, 2, 'First openly gay Las Vegas council member and Mayor Pro Tem; recognized for LGBTQ+ leadership - directed city financial support to the LGBTQ+ Center of Southern Nevada and worked with city staff on LGBTQ+ policy implementation, an active equal-protection/enforcement posture.', ARRAY['https://lasvegassun.com/news/2024/sep/12/las-vegas-mayor-pro-tem-to-receive-award-for-leade/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '169596c9-1ece-4a8a-b601-ce87af369a33'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '169596c9-1ece-4a8a-b601-ce87af369a33'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
