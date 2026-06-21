-- 945_aurelio_mattucci_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- Aurelio Mattucci, Torrance City Council (At-Large, seated 2022; ROSTER OVERRIDE — current, NOT retired).
-- external_id -201103. Evidence-only CHAIRS; 100% citation. Pride NO does not map cleanly to a civil-rights
-- chair -> honest blank (as for Chen). Enforcement record from his documented support for the anti-camping
-- ordinance. The reported "military-style camp" proposal could not be independently verified -> NOT asserted.
DO $do$
DECLARE pid uuid;
  t_homeless uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  t_hresp uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/mayor']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -201103;
  IF pid IS NULL THEN RAISE EXCEPTION '945: Mattucci (-201103) not found'; END IF;

  -- homelessness = 4 (supported the anti-camping ordinance — prohibit encampments, arrest those refusing shelter)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_homeless, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_homeless,
    $reasoning$Per Torrance Watch's documented council record, Mattucci supported the September 9, 2025 anti-camping ordinance directing staff to allow arrest of unhoused residents who refuse offered shelter — an enforcement-forward, prohibit-encampments posture (with shelter offered) consistent with prohibiting encampments on public property with graduated penalties.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness-response = 4 (enforcement as the primary tool)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_hresp, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_hresp,
    $reasoning$Mattucci's documented support for the September 9, 2025 anti-camping ordinance reflects a homelessness-response approach that prioritizes enforcement of anti-camping rules as the primary tool.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
