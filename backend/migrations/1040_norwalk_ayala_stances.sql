-- 1040_norwalk_ayala_stances.sql
-- Phase 155 Wave 4 (NRWK-01): Tony Ayala (pol 5e8bcf17, ext -200876) evidence-only stances.
-- AUDIT-ONLY — NOT registered. Ledger stays 1035. Idempotent. CHAIRS model, 100% citation, honest blanks.
-- topic_id resolved LIVE by topic_key. NO judicial topics. Mayor Dec 2024-Dec 2025 (Newsom suit/settlement); shelter-ban YES.

BEGIN;
WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
  ('homelessness-response', 4,
   'Ayala (seated since 2017) voted YES on Norwalk''s unanimous Aug 6 2024 emergency-shelter/supportive-housing moratorium and its Sept 17 2024 extension, making blocking new shelter/supportive/transitional housing the near-term posture (state later sued; Norwalk settled, repealing the ban + paying $250K). As Mayor in 2025 he framed strategy as ''effective, balanced, and community-supported'' via the H.O.P.E. team + a dedicated Norwalk Enforcement Team (45% drop in encampments) — an enforcement-and-services blend with the moratorium making restriction primary.',
   ARRAY['https://abc7.com/post/norwalk-council-votes-expand-moratorium-building-new-homeless-shelters/15320866/','https://oag.ca.gov/news/press-releases/attorney-general-bonta-newsom-administration-reach-settlement-city-norwalk-over']),
  ('housing', 4,
   'Ayala voted YES on the Aug 6 2024 moratorium (extended Sept 17 2024) that blocked new emergency shelters, SRO, supportive and transitional housing — restricting affordable/supportive housing production via zoning. The state sued and Norwalk settled in 2025, agreeing to repeal the ordinance, fund a $250K housing trust, and implement overdue housing-element programs.',
   ARRAY['https://www.calonews.com/communities/norwalk/norwalk-votes-to-expand-moratorium-on-building-new-homeless-shelters-and-housing/article_3631142c-75f6-11ef-aa93-0fd3f267eb8d.html','https://oag.ca.gov/news/press-releases/attorney-general-bonta-newsom-administration-reach-settlement-city-norwalk-over']),
  ('homelessness', 3,
   'Under Mayor Ayala''s 2025 leadership Norwalk pairs enforcement with services: the H.O.P.E. team coordinates social workers, Public Safety and Public Services, and a second Norwalk Enforcement Team operates alongside outreach (150+ engaged, 108 placed in housing, 45% fewer encampments). Ayala calls it ''effective, balanced, and community-supported'' — encampment enforcement coupled with diversion into shelter/housing.',
   ARRAY['https://norwalkca.gov/news_detail_T3_R54.html','http://www.thenorwalkpatriot.com/news/2022/10/27/tony-ayala-lets-keep-moving-norwalk-forward']),
  ('public-safety-approach', 4,
   'Ayala championed a $3.9 million public-safety plan that adds more city public-safety officers, a second homeless-response team and a second Norwalk Enforcement Team, crediting it for declining crime (burglaries down 43%) — favoring increased public-safety staffing and enforcement capacity.',
   ARRAY['http://www.thenorwalkpatriot.com/news/2022/10/27/tony-ayala-lets-keep-moving-norwalk-forward']),
  ('economic-development', 3,
   'Ayala touts five key commercial developments that ''will bring good jobs to our residents'' and advocates ensuring ''Norwalk money supports Norwalk businesses,'' tying development to local job creation and a robust tax base — targeted, community-benefit-oriented growth rather than blanket incentives.',
   ARRAY['http://www.thenorwalkpatriot.com/news/2022/10/27/tony-ayala-lets-keep-moving-norwalk-forward','https://www.calonews.com/sela-cities-mayors-speak-about-their-priorities-for-their-new-term/article_aac87588-bcae-11ef-995d-7f619c5c2169.html']),
  ('childcare', 2,
   'Ayala highlights Norwalk''s Childcare Services providing assistance to nearly 400 families and made expanding the family ''safety net'' — including childcare assistance and employment support — a centerpiece of his 2025 mayoral agenda, backing broad public childcare subsidy programs.',
   ARRAY['http://www.thenorwalkpatriot.com/news/2022/10/27/tony-ayala-lets-keep-moving-norwalk-forward','https://norwalkca.gov/news_detail_T3_R23.html']),
  ('growth-and-development', 3,
   'Ayala says ''Norwalk has done a fantastic job building a strong economic foundation — now it''s time to ensure families are part of Norwalk''s growth,'' framing growth as planned and inclusive (jobs, childcare, senior nutrition built around development) rather than unrestrained or barrier-removing.',
   ARRAY['https://www.calonews.com/sela-cities-mayors-speak-about-their-priorities-for-their-new-term/article_aac87588-bcae-11ef-995d-7f619c5c2169.html','https://norwalkca.gov/news_detail_T3_R23.html'])
),
t AS (SELECT s.*, ct.id AS topic_id FROM s JOIN inform.compass_topics ct ON ct.topic_key=s.topic_key AND ct.is_live=true),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb', topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT '5e8bcf17-3a4d-4614-a71c-c4ea8396f7cb', topic_id, reasoning, sources FROM t
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
COMMIT;
-- Post: 7 answers + 7 paired context for 5e8bcf17; ledger unchanged (1035).
