-- 1030_nikki_perez_stances.sql
-- Phase 154 Burbank deep-seed Wave 4 — evidence-only compass stances for Nikki Perez
-- AUDIT-ONLY: raw SQL applied live via Supabase MCP, NOT registered in supabase_migrations.schema_migrations (ledger stays 1027).
-- CHAIRS model (value = the chair the evidence matches, never a polarity axis). 100% citation (paired
-- inform.politician_answers + inform.politician_context, every stance with reasoning + >=1 real source URL).
-- No defaulted/neutral values; honest blank spokes omitted. NO judicial-* topics (council-manager city).
-- politician_id 96f91743-def6-436c-9537-a4b836c1b3eb | 11 stances.

BEGIN;

-- rent-regulation = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'Perez publicly stated ''I believe in a 4% rent cap. I think it''s fair.'' and voted in the 3-1 majority (Oct/Nov 2025) directing staff to draft a soft-cap ordinance; she expressed disappointment the result was a soft rather than hard cap. She also voted for a Rental Registry and Tenant Protection Ordinance (Mar 2025). This is consistent with chair 2: strengthening existing rent stabilization and extending coverage to more units.', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '669cac97-66a6-4087-b036-936fbe62efb3', 'Perez''s 2022 campaign platform called for 12,000 new units by 2035 with a 15% minimum affordable housing requirement on new developments. As Chair of the Burbank-Glendale-Pasadena Regional Housing Trust (Jul 2024) she secured a $3.45M grant for a Homeless Solutions Center and stated ''Our residents have made it clear that they want decisive action on the housing crisis.'' Combined with her rent-cap advocacy, her position matches chair 2: use rent caps, require affordable units in new developments, and publicly fund new housing.', ARRAY['https://myburbank.com/vice-mayor-nikki-perez-appointed-chair-of-burbank-glendale-pasadena-regional-housing-trust/', 'https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'As Chair of the Regional Housing Trust, Perez secured $3.45M for a Homeless Solutions Center and publicly stated ''If housing is not your top priority, you''re not thinking.'' She actively supported pivoting to permanent supportive housing when the shelter center was shelved. Her background as a trained social worker who worked directly with families experiencing homelessness reinforces a housing-first approach. This matches chair 1: housing-first with permanent supportive housing and avoiding criminalization.', ARRAY['https://myburbank.com/vice-mayor-nikki-perez-appointed-chair-of-burbank-glendale-pasadena-regional-housing-trust/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '4938766b-b45a-46e3-93bd-b8b30651271a', 'Perez''s housing-first advocacy and social-work background indicate a decriminalization and services-focused approach. The Regional Housing Trust chairship and $3.45M shelter grant reflect investment in shelter capacity and voluntary service connections over enforcement. No direct evidence she opposes all enforcement of public-sleeping laws, so chair 2 (decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections) is the most defensible placement.', ARRAY['https://myburbank.com/vice-mayor-nikki-perez-appointed-chair-of-burbank-glendale-pasadena-regional-housing-trust/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Perez co-organized the ''Green New Deal for Burbank'' coalition before her election and helped secure unanimous adoption of the Greenhouse Gas Reduction Plan (GGRP) in May 2022, targeting 100% GHG-neutral electricity by 2040. Her personal campaign goal was 100% clean energy by 2035 — more aggressive than the GGRP. LALCV endorsed her in both 2022 and 2026 for her clean energy commitments. This is a rapid-transition position consistent with chair 2.', ARRAY['https://lalcv.org/2344-2/', 'https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 'The LALCV endorsed Perez citing her commitments to clean air, emissions reduction, renewable energy, and active transit as part of her Burbank Green New Deal coalition work. The Green New Deal framing implies developer accountability and environmental offsets, consistent with chair 2: protecting parks and tree canopy strictly and requiring developers to fully offset any environmental impact.', ARRAY['https://lalcv.org/2344-2/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-immigration = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'As Mayor, Perez initiated Burbank''s sanctuary city process with a Jan 28, 2025 council motion and voted yes on the Feb 11, 2025 sanctuary resolution. At the Dec 9, 2024 council meeting she called ICE methods ''deplorable'' and stated ''They are taking people without rightful cause, without warrants.'' She cited the $14M LA County Sheriff settlement for illegal ICE cooperation as justification for sanctuary status. This matches chair 1: refuse all ICE detainers and prohibit city employees from sharing immigration status information with federal agencies.', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-councilmembers-clash-over-views-on-ice/article_07eb9663-0ea1-43c7-87bf-95308349281a.html', 'https://outlooknewspapers.com/burbankleader/news/burbank-considers-sanctuary-city-designation/article_546bc89c-de79-11ef-ba16-27a093e67a2c.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', '0bc588c6-39e1-4084-b5de-cac909b8b762', 'Perez is the first Indigenous (K''iche'') and LGBTQIA+ council member and Mayor in Burbank history. She initiated the sanctuary city resolution (Jan 2025) specifically citing harm to immigrant communities from systemic enforcement abuses. Her social-work background and public statements about marginalized communities are consistent with a position of strengthening civil rights enforcement and addressing systemic discrimination (chair 2).', ARRAY['https://outlooknewspapers.com/burbankleader/news/burbank-considers-sanctuary-city-designation/article_546bc89c-de79-11ef-ba16-27a093e67a2c.html', 'https://outlooknewspapers.com/burbankleader/burbank-councilmembers-clash-over-views-on-ice/article_07eb9663-0ea1-43c7-87bf-95308349281a.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Perez''s 2022 campaign supported expanding Burbank''s Mental Health Evaluation Team (MHET) — a co-responder model pairing mental health clinicians with officers on non-violent calls. She also expressed explicit skepticism of police data-sharing with federal immigration enforcement (ICE) at the Dec 2024 council meeting. This is consistent with chair 2: maintain current police staffing but shift non-violent calls to unarmed mental health co-responders.', ARRAY['https://lalcv.org/2344-2/', 'https://outlooknewspapers.com/burbankleader/burbank-councilmembers-clash-over-views-on-ice/article_07eb9663-0ea1-43c7-87bf-95308349281a.html']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 'Governor Newsom appointed Perez to the California Film Commission in January 2026 — the first Burbank council member ever selected — recognizing her advocacy for the entertainment industry as ''the backbone of our local economy.'' Her push for permitting reform to support small businesses also reflects a targeted-incentives approach. This is consistent with chair 3: targeted incentives for specific industries (entertainment/film) with community benefit considerations.', ARRAY['https://myburbank.com/burbank-city-council-member-nikki-perez-appointed-to-the-california-film-commission-by-governor-newsom/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('96f91743-def6-436c-9537-a4b836c1b3eb', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 'The LALCV 2022 endorsement specifically cites Perez''s ''active transit'' commitment. She has framed transit access as an equity issue, noting she grew up relying on public buses. This is consistent with chair 2: invest equally in roads and multimodal options, requiring bike lanes and sidewalks on new road projects. No evidence of a more aggressive car-free position (chair 1).', ARRAY['https://lalcv.org/2344-2/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Post-apply verification:
--   SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='96f91743-def6-436c-9537-a4b836c1b3eb'; -> 11
--   every answer has a paired context row (0 unpaired); 0 judicial-* topics; ledger MAX unchanged (1027).
