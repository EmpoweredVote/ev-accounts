-- 940_asam_sheikh_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- Asam Sheikh, Torrance City Council (District 3 / At-Large, seated 2022). Evidence-only CHAIRS; 100% citation.
-- external_id -201102. Sheikh pairs enforcement (anti-camping YES) with an active services/housing record.
DO $do$
DECLARE pid uuid;
  t_civil uuid := '0bc588c6-39e1-4084-b5de-cac909b8b762';
  t_homeless uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  t_hresp uuid := '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';
  t_housing uuid := '669cac97-66a6-4087-b036-936fbe62efb3';
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/district-3']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -201102;
  IF pid IS NULL THEN RAISE EXCEPTION '940: Sheikh (-201102) not found'; END IF;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_civil, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_civil,
    $reasoning$Sheikh voted YES on the May 7, 2024 council resolution issuing a Pride Month proclamation recognizing Torrance's LGBTQ+ residents (passed 4-3) — an affirmative civil-rights / social-justice action.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness = 3 (enforcement only when shelter available — ordinance targets those who refuse offered shelter)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_homeless, 3)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_homeless,
    $reasoning$Sheikh voted YES on the September 9, 2025 anti-camping ordinance, which allows enforcement only against unhoused residents who refuse offered shelter, while his record also includes transitioning unhoused residents to permanent housing (a temporary housing village plus street outreach). This conditional-enforcement-with-services profile matches allowing enforcement when adequate shelter is available, diverting people to services rather than purely criminalizing public sleeping.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- homelessness-response = 3 (services + reasonable enforcement)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_hresp, 3)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_hresp,
    $reasoning$Sheikh's homelessness-response record combines investment in outreach, shelter and housing (campaign-documented transitions of 90+ unhoused residents to permanent housing via a temporary housing village and street outreach) with support for the September 9, 2025 anti-camping ordinance — i.e. invest in services while enforcing reasonable public-space rules.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

  -- housing = 3 (targeted programs to move people into housing)
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_housing, 3)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_housing,
    $reasoning$Sheikh promotes targeted housing programs — a temporary housing village and outreach that transitioned unhoused residents into permanent housing — consistent with targeted help (subsidies for affordable projects and supportive-housing pathways) rather than either pure public provision or a hands-off market approach.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
