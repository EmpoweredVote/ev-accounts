-- Migration 1081: City of Las Vegas stances - Francis Allen-Palenske (Council Member, Ward 4) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks where no city-level evidence. No defaults.
-- Council-era (Dec 2022-present) evidence; Assembly-era ("Francis Allen") not imported.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 91544dd2-07c7-4885-943f-f431836ddecf (external_id -3205005, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 5, 'Voted with council 6-0 in Nov 2024 to strengthen/expand the citywide camping ban with criminal penalties (misdemeanor enforcement); no dissent recorded.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/las-vegas-city-council-votes-to-strengthen-camping-ban-3207766/']::text[]),
    ('homelessness-response'::text, 4, 'Same Nov 2024 vote to expand the anti-camping ban citywide making enforcement the primary mechanism; she did not push the social-services-first/shelter-first alternative her colleagues raised.', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/las-vegas-city-council-votes-to-strengthen-camping-ban-3207766/']::text[]),
    ('public-safety-approach'::text, 4, 'Stated "the answer is more funding for our police officers" and being "pro getting more boots on the street," backed education incentives/longevity pay, helped establish a NW Metro substation, is LVPPA-endorsed, and serves on the Metro Fiscal Affairs Committee (2022 campaign + council tenure).', ARRAY['https://thenevadaindependent.com/article/vegas-council-hopefuls-want-to-increase-police-budget-focus-on-housing-security','https://francisallenpalenske.com/bio/']::text[]),
    ('economic-development'::text, 5, 'Defended a $12M BLM-grant pickleball project against watchdog calls to redirect funds to affordable housing: "Those are Nevada dollars being returned to Nevada, this is government working for us" (2025).', ARRAY['https://news3lv.com/news/local/las-vegas-pickleball-project-sparks-debate-over-federal-spending']::text[]),
    ('growth-and-development'::text, 2, 'On approving new master-planned communities she prioritized infrastructure first: "People need services provided particularly when we do these large master-planned communities" (2022).', ARRAY['https://thenevadaindependent.com/article/vegas-council-hopefuls-want-to-increase-police-budget-focus-on-housing-security']::text[]),
    ('housing'::text, 4, 'Frames housing affordability as a federal-land-shortage problem (88% BLM-owned), favoring opening land for homeownership rather than regulation/public funding: "make homeownership attainable... It''s why people move here" (2022).', ARRAY['https://thenevadaindependent.com/article/vegas-council-hopefuls-want-to-increase-police-budget-focus-on-housing-security']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '91544dd2-07c7-4885-943f-f431836ddecf'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '91544dd2-07c7-4885-943f-f431836ddecf'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
