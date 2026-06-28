-- Migration 1077: City of Las Vegas stances - Shelley Berkley (Mayor) (AUDIT-ONLY)
--
-- Phase 162 (CLARK-02). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1075. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- Pre-tenure rule applied: her 1999-2013 U.S. House record is EXCLUDED; all
-- stances rest on 2024 mayoral-campaign or 2025 mayoral-era statements/actions.
-- politician_id = 2568b40c-a517-4eaa-b0da-eb946f9b6df9 (external_id -3205001, minted by mig 1075).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness'::text, 4, 'As mayor-elect/mayor she said of the LV camping ban "I would have supported it had I been in office" (Jan 2025), while rejecting "warehousing the homeless" and busing them out, pairing enforcement with shelter/services and a proposed 395-bed veterans facility - prohibit encampments coupled with shelter/diversion.', ARRAY['https://lasvegasweekly.com/news/2025/jan/16/new-mayor-shelley-berkley-hits-the-ground-running/','http://nevadanewsmakers.com/RayHagar/article.asp?ID=429','https://news3lv.com/news/local/las-vegas-mayor-addresses-homelessness-crisis-strategy-expected-by-2026']::text[]),
    ('homelessness-response'::text, 3, 'Retooled the city''s MORE (Multi-Agency Outreach Resource Engagement) teams to pair police officers with mental-health professionals doing street outreach, and committed to improving Courtyard Resource Center services (therapy, addiction, workforce) to move people to self-sufficiency - outreach + shelter + reasonable rules, not housing-first-only nor strict-enforcement-only (2025).', ARRAY['https://news3lv.com/news/local/las-vegas-faces-12m-cut-in-homeless-funding-mayor-strategizes-response','https://lasvegasweekly.com/news/2025/jan/16/new-mayor-shelley-berkley-hits-the-ground-running/']::text[]),
    ('housing'::text, 2, 'Campaigned on and supports inclusionary zoning requiring developers to include affordable/workforce units or pay into a city housing fund; city is adding inventory "at all income levels" via developments like ShareWESTSIDE and Desert Pines, plus backing SB28 to raise affordable-housing income thresholds (2024-2025).', ARRAY['https://nevadacurrent.com/2024/10/15/berkley-seaman-vie-to-be-mayor-of-las-vegas/','https://lasvegasweekly.com/news/2025/jan/16/new-mayor-shelley-berkley-hits-the-ground-running/']::text[]),
    ('local-immigration'::text, 4, 'Publicly supported Sheriff McMahill''s 287(g) agreement with ICE; stated that when someone here illegally is arrested and jailed "it''s our responsibility to notify ICE that they are there," and was "adamant and very vocal" that LV is not a sanctuary city (2025) - honoring detainers/notification and information-sharing.', ARRAY['https://thenevadaindependent.com/article/las-vegas-mayor-voices-support-for-agreement-between-ice-las-vegas-police','https://www.reviewjournal.com/news/politics-and-government/las-vegas/mayor-says-las-vegas-is-not-a-sanctuary-city-3316441/']::text[]),
    ('public-safety-approach'::text, 3, 'Says there is "nothing more important" than public safety, promised to work closely with Metro, and as mayor advanced a new police substation and a joint 911 center while expanding the co-responder MORE teams (police + mental-health professionals) - sustaining funding and adding crisis-response capacity (2025).', ARRAY['https://www.reviewjournal.com/news/politics-and-government/las-vegas/las-vegas-mayor-berkley-set-to-give-annual-state-of-the-city-address-3791209/','https://news3lv.com/news/local/las-vegas-faces-12m-cut-in-homeless-funding-mayor-strategizes-response']::text[]),
    ('economic-development'::text, 3, 'Touted a public-private partnership (ManiFlex, UNLV, CSN) creating a downtown advanced-manufacturing hub projected at 200 jobs and $224M revenue over 10 years, and backs regional assets (children''s hospital, sports franchises) as economic drivers - targeted partnerships tied to jobs/community benefit (2025).', ARRAY['https://www.ktnv.com/news/las-vegas-mayor-elect-shelley-berkley-outlines-her-plans-for-the-citys-future','https://lasvegasweekly.com/news/2025/jan/16/new-mayor-shelley-berkley-hits-the-ground-running/']::text[]),
    ('growth-and-development'::text, 3, 'First-order priority was resolving the Badlands dispute via a ~$286M land settlement to unlock orderly development; backs SB48 mandating updated master-plan elements (housing, conservation, economic development, public health) and is permitting thousands of new homes at Badlands/Desert Pines - plan and invest ahead of growth (2025).', ARRAY['https://thenevadaindependent.com/article/vegas-mayor-candidates-agree-on-ending-badlands-drama-but-spar-on-how','https://lasvegasweekly.com/news/2025/jan/16/new-mayor-shelley-berkley-hits-the-ground-running/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '2568b40c-a517-4eaa-b0da-eb946f9b6df9'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '2568b40c-a517-4eaa-b0da-eb946f9b6df9'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
