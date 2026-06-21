-- 1009_cindy_galvan_stances.sql
-- Phase 151 Wave 4 (ELMN-01): Cindy Galvan (El Monte City Council District 5, ext_id -201203) evidence-only
-- compass stances. AUDIT-ONLY — raw SQL, NOT registered (ledger stays 1001). Idempotent.
-- Seated Nov 2024 (~7-month record). PRE-TENURE rule bars pre-Nov-2024 votes. Record thin -> 1 stance.
-- local-immigration scored 2 (not 1): her documented action is a protective IMMIGRANT SUPPORT FUND (legal
-- referrals/attorney access/protection guidance for families facing enforcement) — clearly protective, but it
-- does NOT establish the specific detainer-refusal/info-sharing mechanism of chair 1, so the conservative
-- "protect ... from referral" chair 2 is the more defensible match.

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT p.id, t.id, v.value
FROM (VALUES ('local-immigration',2)) AS v(topic_key, value)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -201203
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT p.id, t.id, v.reasoning, v.sources
FROM (VALUES
  ('local-immigration', $$As a seated councilmember (post-Nov-2024), Galvan served on El Monte's immigration ad hoc committee that "helped guide the proposal and worked with county officials" to create an Immigrant Support Fund providing referrals to immigration attorneys, legal guidance, and support for "families facing immigration proceedings or enforcement concerns" — the city proactively deploying resources to protect immigrant residents from enforcement (a protective posture).$$, ARRAY['https://midvalleynews.com/el-monte-immigrant-support-fund-announced/'])
) AS v(topic_key, reasoning, sources)
JOIN inform.compass_topics t ON t.topic_key = v.topic_key
JOIN essentials.politicians p ON p.external_id = -201203
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
