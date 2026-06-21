-- 942_jon_kaji_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- Jon Kaji, Torrance City Council (District 1, seated 2022). Evidence-only CHAIRS; 100% citation. external_id 683364.
-- Pride vote not independently documented on his page -> civil-rights left honest blank.
DO $do$
DECLARE pid uuid;
  t_homeless uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  t_hresp uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  t_psafe uuid := 'e9ebefcd-c496-45e8-b816-a79f8442ba85';
  t_growth uuid := 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4';
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/district-1']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 683364;
  IF pid IS NULL THEN RAISE EXCEPTION '942: Kaji (683364) not found'; END IF;

  -- homelessness = 4 (opposed homeless-housing project; enforcement-led)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_homeless, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_homeless,
    $reasoning$Kaji opposed the Project Homekey+ / Extended Stay America supportive-housing conversion (May 23, 2025 council resolution) and his campaign states he "opposed the homeless-housing project on Torrance Blvd. and continues advocating for planning that puts the community first," favoring enforcement-led over housing-first approaches — a prohibit-encampments / enforcement posture.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness-response = 4 (explicitly enforcement-led rather than housing-first)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_hresp, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_hresp,
    $reasoning$Kaji explicitly supports enforcement-led rather than housing-first responses to homelessness and opposed the Torrance Blvd. supportive-housing project — i.e. enforcement as the primary homelessness-response tool.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- public-safety-approach = 4 (TPOA endorsement + community-first enforcement framing)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_psafe, 4)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_psafe,
    $reasoning$Kaji received the Torrance Police Officers' Association PAC endorsement ($1,000 campaign donation) and runs on an enforcement-led, "community first" public-safety platform — consistent with increasing/strengthening police resources rather than redirecting them.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- growth-and-development = 2 (final documented position: opposed annexation on fiscal/capacity grounds)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_growth, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_growth,
    $reasoning$Kaji's El Camino Village annexation record evolved — he originated the staff-research request (Aug 2024) and backed an ad-hoc committee (Jan 14, 2025) but by his April 6, 2026 Riviera HOA forum position publicly opposed annexation, calling "$27 million in startup costs and $11 million annually" disqualifying. His most recent documented position is fiscal-capacity-cautious — growth only where existing capacity supports it.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
