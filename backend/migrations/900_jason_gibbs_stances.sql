-- 900_jason_gibbs_stances.sql
-- Phase 143 / Plan 04 — Jason Gibbs (Councilmember, external_id 665692) evidence-only compass stances.
-- AUDIT-ONLY: apply via raw SQL; does NOT register in schema_migrations (ledger MAX stays 895).
-- Chairs model; evidence-only; 100% citation; honest blanks. 4 evidenced topics.
-- Gibbs seated Dec 2020 -> SB54 (2018) NOT attributed; local-immigration left blank.

BEGIN;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665692)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pol.id, v.topic_id, v.value
FROM pol, (VALUES
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 4),  -- public-safety-approach
  ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),  -- taxes
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid, 2),  -- growth-and-development
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid, 1)   -- residential-zoning
) AS v(topic_id, value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH pol AS (SELECT id FROM essentials.politicians WHERE external_id = 665692)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pol.id, v.topic_id, v.reasoning, v.sources
FROM pol, (VALUES
  ('e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,
   $$Gibbs repeatedly states he will 'invest in public safety by ensuring our law enforcement and first responders have the resources they need,' 'support law enforcement,' and oppose 'soft-on-crime' policies. His emphasis on resourcing and backing police matches chair 4.$$,
   ARRAY['https://signalscv.com/2025/07/jason-gibbs-asking-for-your-trust-in-the-27th-district/','https://laclc.org/uncategorized/candidate-for-the-27th-congressional-district-jason-gibbs/','https://www.jasongibbsforcongress.com/']::text[]),
  ('f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,
   $$Gibbs's consistent stated position is to 'lower costs, oppose new taxes, and hold government accountable' by 'cutting wasteful spending' and demanding 'balanced budgets.' That combination of cutting taxes/spending and scaling back government matches chair 4.$$,
   ARRAY['https://laclc.org/uncategorized/candidate-for-the-27th-congressional-district-jason-gibbs/','https://signalscv.com/2025/07/jason-gibbs-asking-for-your-trust-in-the-27th-district/','https://www.jasongibbsforcongress.com/']::text[]),
  ('fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,
   $$Gibbs has 'battled the overbearing policies of Sacramento that force housing density and development into neighborhoods with little to no regard to needed infrastructure and good planning,' and as Mayor backed 'smart planning that preserves open spaces while fostering thoughtful growth.' Tying approvals to adequate infrastructure matches chair 2.$$,
   ARRAY['https://www.santaclarita.gov/city-council/jason-gibbs/','https://signalscv.com/2025/07/jason-gibbs-asking-for-your-trust-in-the-27th-district/']::text[]),
  ('d4f18138-a2e0-4110-b925-7387d9d0d16d'::uuid,
   $$Gibbs opposes state-forced housing density 'into neighborhoods with little to no regard to needed infrastructure,' arguing housing decisions should be made by local communities rather than Sacramento. His record of resisting forced upzoning to protect neighborhood character matches chair 1.$$,
   ARRAY['https://www.santaclarita.gov/city-council/jason-gibbs/','https://laclc.org/uncategorized/candidate-for-the-27th-congressional-district-jason-gibbs/']::text[])
) AS v(topic_id, reasoning, sources)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
