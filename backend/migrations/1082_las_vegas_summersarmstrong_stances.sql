-- Migration 1082: City of Las Vegas stances - Shondra Summers-Armstrong (Council Member, Ward 5) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model). 100% cited; honest blanks where no city-level evidence. No defaults.
-- Council-era + 2024 campaign evidence; rent-regulation maps her Assembly AB340
-- eviction-reform record explicitly reaffirmed as a council housing-justice priority.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 6f433371-e691-41ed-9f0e-580626e0cb32 (external_id -3205006, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('housing'::text, 3, 'Favors using city land-use tools and incentives plus pushing developers to set aside affordable units - targeted approach, not citywide public housing or rent caps: "I think the city of Las Vegas has a role with land use and possibly with incentives to get us more affordable housing" (2024), with focus on seniors.', ARRAY['https://www.yahoo.com/news/shondra-summers-armstrong-discusses-key-234013964.html','https://www.shondraarmstrong.org/priorities/']::text[]),
    ('growth-and-development'::text, 3, 'As Ward 5 councilwoman sought a planning commissioner "aligned with the city''s long-range planning and land use goals, and with Ward 5''s commitment to smart development strategies that enhance quality of life and expand economic opportunity" - plan/invest ahead with managed smart growth, not deregulated market growth (Jan 2026).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/las-vegas-planning-official-quits-under-pressure-before-key-council-vote-3605016/']::text[]),
    ('homelessness-response'::text, 3, 'Praises the city''s Courtyard Homeless Resource Center and frames homelessness response around shelter plus mental health, legal aid and job training, coupled with regional coordination ("It cannot be a city of Las Vegas-only task... we need help from others," 2024) - outreach+shelter+services, not pure housing-first or enforcement-first.', ARRAY['https://www.yahoo.com/news/shondra-summers-armstrong-discusses-key-234013964.html','https://thenevadaindependent.com/article/democratic-legislator-shondra-summers-armstrong-to-run-for-las-vegas-city-council']::text[]),
    ('public-safety-approach'::text, 3, 'Backs community-oriented policing and adding social-issue partnerships/crisis-style supports while continuing police community work; praised Sheriff McMahill''s community policing ("We need to see an expansion and a continuation of that kind of work in the community," 2024) and cites partnering with orgs on underlying social issues.', ARRAY['https://nevadacurrent.com/2024/10/18/democratic-legislators-vying-for-open-city-of-las-vegas-council-seat/','https://www.shondraarmstrong.org/priorities/']::text[]),
    ('economic-development'::text, 3, 'Favors targeted, community-benefit-oriented development: prioritizing local/minority-owned businesses for city contracts, streamlined permitting, the Historic Westside Education and Training Center workforce pipeline, and (Assembly AB335) requiring businesses receiving city tax benefits to hire locally - incentives tied to local hiring/community benefit, not maximal abatements (2024-2025).', ARRAY['https://www.shondraarmstrong.org/priorities/','https://lasvegassun.com/news/2025/feb/17/las-vegas-councilwoman-aims-to-reinvigorate-commun/']::text[]),
    ('rent-regulation'::text, 2, 'Sponsored AB340 to reform Nevada''s summary eviction process (require landlords to file in court first), arguing "the state''s summary eviction process is not fair to tenants" and "These are regular folks. They don''t have attorneys on speed dial" - strengthening tenant/renter protections; Assembly-era but reaffirmed as a council housing-justice priority (2023, cited in 2024 run).', ARRAY['https://thenevadaindependent.com/article/state-lawmaker-wants-to-change-not-repeal-summary-eviction-process','https://thenevadaindependent.com/article/democratic-legislator-shondra-summers-armstrong-to-run-for-las-vegas-city-council']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '6f433371-e691-41ed-9f0e-580626e0cb32'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '6f433371-e691-41ed-9f0e-580626e0cb32'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
