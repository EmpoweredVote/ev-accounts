-- 944_jeremy_gerson_stances.sql  (AUDIT-ONLY — NOT registered in schema_migrations; ledger stays 937)
-- Jeremy Gerson, Torrance City Council (District 6, seated 2022; reform coalition). external_id 683376.
-- Thin individual documentation (not up in 2026; no district-6 race record). Evidence-only: one documented
-- coalition vote (Pride proclamation YES, part of the 4-3 majority) -> civil-rights=2. Other topics honest blanks.
DO $do$
DECLARE pid uuid;
  t_civil uuid := '0bc588c6-39e1-4084-b5de-cac909b8b762';
  src text[] := ARRAY['https://www.torrancewatch.org/races/2026/mayor']::text[];
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 683376;
  IF pid IS NULL THEN RAISE EXCEPTION '944: Gerson (683376) not found'; END IF;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (pid, t_civil, 2)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (pid, t_civil,
    $reasoning$Gerson was part of the 4-vote majority that passed the May 7, 2024 council resolution issuing a Pride Month proclamation recognizing Torrance's LGBTQ+ residents (4-3) — an affirmative civil-rights / social-justice action. His individual council record is otherwise thinly documented, so other topics are left as honest blanks rather than inferred.$reasoning$, src)
    ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;
END $do$;
