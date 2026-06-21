-- 941_george_chen_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- George Chen, Mayor of Torrance (seated; ROSTER OVERRIDE — NOT retired). Evidence-only CHAIRS; 100% citation.
-- external_id -201036. Pride NO and the SST/Sister-Cities/airport items do not map cleanly to a live chair -> honest blanks.
DO $do$
DECLARE pid uuid;
  t_homeless uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  t_hresp uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  t_growth uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/mayor']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -201036;
  IF pid IS NULL THEN RAISE EXCEPTION '941: Chen (-201036) not found'; END IF;

  -- homelessness = 4 (supported anti-camping ordinance; opposed supportive-housing hotel)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_homeless, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_homeless,
    $reasoning$Chen voted YES on the September 9, 2025 council concurrence to draft an anti-camping ordinance allowing arrest of unhoused residents who refuse offered shelter, and YES on the May 23, 2025 resolution opposing conversion of the Extended Stay America hotel into supportive housing. This enforcement-forward, prohibit-encampments posture (with shelter offered) matches prohibiting encampments on public property with graduated penalties.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness-response = 4 (enforcement as primary tool)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_hresp, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_hresp,
    $reasoning$Chen supported the September 9, 2025 anti-camping enforcement ordinance and opposed the LA County/Weingart supportive-housing hotel conversion (May 23, 2025) — favoring enforcement of anti-camping rules as the primary homelessness-response tool over expanding supportive-housing capacity.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- growth-and-development = 4 (backed El Camino Village annexation to grow tax base)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_growth, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_growth,
    $reasoning$Chen publicly backed advancing the El Camino Village annexation (January 14, 2025 council meeting and 2026 forums), framing it around cultural exchange, tourism and investment growth — an actively pro-expansion posture aimed at growing the city's footprint and tax base.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
