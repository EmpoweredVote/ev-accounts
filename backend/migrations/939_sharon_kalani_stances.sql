-- 939_sharon_kalani_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- Sharon Kalani, Torrance City Council (At-Large, seated 2020; ROSTER OVERRIDE — councilmember, not Mayor).
-- Evidence-only CHAIRS model; 100% citation; honest blanks on undocumented topics. external_id 683370.
DO $do$
DECLARE pid uuid;
  t_civil uuid := '0bc588c6-39e1-4084-b5de-cac909b8b762'; -- civil-rights
  t_homeless uuid := '4938766b-b45a-46e3-93bd-b8b30651271a'; -- homelessness (criminalization)
  t_hresp uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'; -- homelessness-response
  t_growth uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'; -- growth-and-development
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/mayor']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 683370;
  IF pid IS NULL THEN RAISE EXCEPTION '939: Kalani (683370) not found'; END IF;

  -- civil-rights = 2 (Pride proclamation YES)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_civil, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_civil,
    $reasoning$Kalani voted YES on the May 7, 2024 council resolution issuing a Pride Month proclamation recognizing Torrance's LGBTQ+ residents (passed 4-3) — an affirmative civil-rights / social-justice action consistent with strengthening civil rights protections and addressing discrimination against a historically marginalized group.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness = 2 (NO on anti-camping criminalization ordinance)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_homeless, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_homeless,
    $reasoning$Kalani voted NO on the September 9, 2025 council concurrence directing staff to draft an anti-camping ordinance that would allow arresting unhoused residents who refuse offered shelter — opposing criminalization of public sleeping in favor of a decriminalized, services-oriented approach.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness-response = 2 (services-first; opposed enforcement ordinance)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_hresp, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_hresp,
    $reasoning$By voting NO on the September 9, 2025 anti-camping enforcement ordinance, Kalani signaled a services-first homelessness-response posture — prioritizing expanded shelter and services rather than enforcement as the primary tool.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- growth-and-development = 2 (opposed El Camino Village annexation on cost/capacity)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_growth, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_growth,
    $reasoning$Kalani publicly opposed the El Camino Village annexation, citing staff cost estimates of roughly $27M startup and $11M annually and a "Back to the Business of Torrance" focus on existing obligations over expansion — a cautious growth posture favoring growth only where existing capacity supports it.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
