-- 934_debra_martin_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Debra Martin (D1, external_id 675752; new Nov 2024, thin record — honest blanks preserved). Evidence-only chairs.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 675752;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',5),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',5)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$Voted NO on Pomona's permanent Rent Stabilization Ordinance (5% cap) at both the Oct 21 2025 (4-3) and Nov 17 2025 final votes, with stated reasoning that a 5% cap is unworkable for small landlords of older properties (a $20,000 replumb would wipe out annual profit). CAA-backed and 'business-friendly' — opposition to the rent-control measure itself.$$,ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control','https://caanet.org/pomona-council-approves-permanent-rent-control-ordinance-with-5-cap/']),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',$$Her platform centers aggressively attracting business: she touts bringing 'over $500 million dollars of new business (Starbucks, Superior Market & Target Shopping Centers)' to her district and campaigns on thriving businesses and good jobs, bringing a 'business-friendly perspective' — economic growth as a top priority via broad business attraction.$$,ARRAY['https://debramartinforcouncil.com/about/','https://caanet.org/pomona-council-approves-permanent-rent-control-ordinance-with-5-cap/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
