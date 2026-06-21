-- 935_lorraine_canales_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Lorraine Canales (D6, external_id 675765; new Nov 2024, thin record — honest blanks preserved). Evidence-only chairs.
-- NOTE: her Oct/Nov 2025 rent-stabilization NO votes carry NO documented first-party reasoning → rent-regulation left BLANK.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 675765;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'e9ebefcd-c496-45e8-b816-a79f8442ba85',3)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'e9ebefcd-c496-45e8-b816-a79f8442ba85',$$Her campaign platform pledges to 'work closely with police and fire departments to tackle community violence and crime' and to deliver 'enhanced emergency service with faster response times to 911 calls' — a pro-police-capacity stance that rules out redirecting the budget (1) or shifting to co-responders (2), but stops short of any documented call to increase staffing/pay (4/5). Maintaining/supporting current police function with crisis support (chair 3) is the most defensible match.$$,ARRAY['https://www.lorraine4d6.com/','https://ballotpedia.org/Lorraine_Canales_(Pomona_City_Council_District_6,_California,_candidate_2024)'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
