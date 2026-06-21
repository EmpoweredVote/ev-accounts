-- 932_steve_lustro_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Steve Lustro (D5, external_id -201352; seated through 2026, scored as current member). Evidence-only chairs.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -201352;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',3),
    (pid,'e9ebefcd-c496-45e8-b816-a79f8442ba85',3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$Voted YES on the Nov 17 2025 permanent Rent Stabilization Ordinance (5% cap) after voting NO in October over budget concerns, framing the final version as balanced maintenance: 'a good compromise... adequate protections for our tenants, while also not being totally unreasonable to our housing providers' — maintaining stabilization with a balanced landlord posture rather than expanding it.$$,ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control','https://www.thepomonan.com/theopera/2025/10/28/pomona-city-council-quietly-reverses-course-on-rent-cap-ordinance']),
    (pid,'e9ebefcd-c496-45e8-b816-a79f8442ba85',$$Received ~$9,396 in Pomona Police Officers Association support in 2018 and campaigned against Measure Y (the Kids First youth-fund charter measure), opposition framed around protecting existing services including police/fire from reallocation — a posture of preserving current public-safety funding (not an affirmative staffing increase).$$,ARRAY['https://www.thepomonan.com/news/investigative-report-did-current-city-council-members-victor-preciado-and-steve-lustro-properly-disclose-the-campaign-contributions-they-received-from-pomona-police-officers-association-in-2018','https://www.thepomonan.com/measure-y'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
