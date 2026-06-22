-- 1032_zizette_mullins_stances.sql
-- Phase 154 Burbank deep-seed Wave 4 — evidence-only compass stances for Zizette Mullins
-- AUDIT-ONLY: raw SQL applied live via Supabase MCP, NOT registered in supabase_migrations.schema_migrations (ledger stays 1027).
-- CHAIRS model (value = the chair the evidence matches, never a polarity axis). 100% citation (paired
-- inform.politician_answers + inform.politician_context, every stance with reasoning + >=1 real source URL).
-- No defaulted/neutral values; honest blank spokes omitted. NO judicial-* topics (council-manager city).
-- politician_id f933bd87-d397-4ef1-873b-57559b629000 | 3 stances.

BEGIN;

-- rent-regulation = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'Mullins cast the lone NO vote on the 4% soft rent cap (Oct 28, 2024, 3-1 vote), arguing the cap should be AT LEAST 5% and criticizing her colleagues for ''bending to 4%.'' She explicitly framed the 4% cap as neglecting landlords'' interests, citing a 2,200-unit vacancy glut and arguing property owners needed higher increases to cover operating costs. Her position is clearly more landlord-protective than the passing majority — closer to ''limit rent regulations / allow market rents broadly'' than to strengthening tenant protections.', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html', 'https://outlooknewspapers.com/burbankleader/news/burbank-city-council-pursues-4-rent-cap/article_af08e68a-8d7b-11ef-baad-834e020c9619.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Mullins''s 2022 campaign platform named addressing homelessness as a top priority via partnering with nonprofits (Home Again LA, Family Service Agency, BTAC) to secure federal/state/county grants for housing, shelters, and mental health services. In council discussion she acknowledged the difficulty of engaging unhoused individuals with mental health challenges and emphasized outreach. This profile — prioritizing outreach, shelter, and services while not decriminalizing camping — matches chair 3.', ARRAY['https://myburbank.com/burbank-city-council-candidate-profile-zizette-mullins/', 'https://outlooknewspapers.com/burbankleader/long-awaited-burbank-homeless-center-put-on-hold/article_e166f63c-ee2e-4317-b507-6ad2524f7f1b.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('f933bd87-d397-4ef1-873b-57559b629000', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Mullins made public safety the centerpiece of her 2022 campaign, stating ''That''s why people move here — safety'' and vowing to restore basic services including police staffing. Her campaign platform explicitly listed ''securing safety'' as a top-four priority. This is consistent with chair 4: increase police staffing, equipment, and pay to improve response times and deter crime.', ARRAY['https://myburbank.com/burbank-city-council-candidate-profile-zizette-mullins/', 'https://www.zizettemullins.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Post-apply verification:
--   SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='f933bd87-d397-4ef1-873b-57559b629000'; -> 3
--   every answer has a paired context row (0 unpaired); 0 judicial-* topics; ledger MAX unchanged (1027).
