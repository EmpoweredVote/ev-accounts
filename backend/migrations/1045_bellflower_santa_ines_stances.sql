-- 1045_bellflower_santa_ines_stances.sql
-- Phase 156 Wave 4 (BLFL-01): Sonny R. Santa Ines (pol a4ff4532, ext -701003, D3, Mayor) evidence-only stances.
-- AUDIT-ONLY — raw SQL, NOT registered in schema_migrations. Ledger stays 1043. Idempotent.
-- CHAIRS model (value = the chair the evidence matches). 100% citation. No defaults/neutral. Honest blanks.
-- NO judicial topics (council-manager city). topic_id resolved LIVE by topic_key (never hardcoded).
-- Evidence: as Bellflower's Mayor Pro Tem (now Mayor), Santa Ines is the city's documented public voice on the
-- New Hope interim shelter (50 beds, opened May 2020) — Bellflower was the first LA County city to sign on with
-- Judge Carter's order, pairing a shelter with enforcement of anti-camping ordinances (the Martin v. Boise model).
-- Only homelessness topics are individually attributable to him from loadable sources; everything else = honest blank.

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness', 3,
   $$As Bellflower's Mayor Pro Tem (now Mayor), Santa Ines is the city's documented public voice on the New Hope interim shelter (50 beds, 8833 Cedar St, opened May 20 2020). He stated the city "has a shelter" and that, with it in place, Bellflower "can enforce its ordinances against camping in public places" — an enforce-only-when-shelter-is-available posture (the Martin v. Boise model), not protecting public sleeping (chairs 1-2) nor a criminalize-first camping ban with no service link (chair 5). Matches chair 3: enforcement paired with shelter/diversion to services.$$,
   ARRAY['https://homeless.lacounty.gov/news/new-hope-in-bellflower/']::text[]),
  ('homelessness-response', 3,
   $$Santa Ines credited the New Hope shelter and a $500,000 LA County grant with significantly reducing Bellflower's homeless population, and framed the city's strategy as providing a shelter and services while continuing to enforce public-space rules ("I'm very proud of the City of Bellflower's efforts to help address homelessness"). A combined invest-in-shelter-and-services-while-enforcing-reasonable-rules approach (chair 3), not housing-first-no-enforcement (chair 1) nor enforcement-first / minimize-services (chairs 4-5).$$,
   ARRAY['https://homeless.lacounty.gov/news/new-hope-in-bellflower/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT 'a4ff4532-57d7-49e1-8eea-9313ce347d53', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'a4ff4532-57d7-49e1-8eea-9313ce347d53', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
-- Post: 2 answers + 2 paired context rows for a4ff4532; ledger unchanged (1043).
-- Honest blanks (no loadable individual evidence): all other topics, incl. national topics.
