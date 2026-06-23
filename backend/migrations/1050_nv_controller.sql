-- 1050_nv_controller.sql
-- Phase 159 (NV-STATE-01): Seed Andy Matthews, State Controller of Nevada.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- State of Nevada government: id=9bb67edf-1081-4941-8f7d-2e791a5d28a1, geo_id='32'
-- external_id: -3200006 (next after existing 5 officials -3200001..-3200005)
-- DB-verified 2026-06-23: 5 of 6 STATE_EXEC officials exist (Governor + Lt. Gov + AG
--   + SoS + Treasurer); Controller missing. This migration creates ONLY the Controller.
--   The 5 pre-existing officials MUST NOT be re-created.
-- CRITICAL: the chambers generated-identifier column is GENERATED ALWAYS — never include it in the INSERT column list.
-- CRITICAL: state = 'NV' UPPERCASE on STATE_EXEC district + office — lowercase silently
--   breaks backend routing (the OR-223a lesson). All government refs use geo_id='32'
--   (not '51' Virginia, not '24' Maryland, never the US Federal government).
--
-- Structure created:
--   STEP 1 — 1 chamber  (name='Controller', name_formal='Nevada State Controller')
--   STEP 2 — 1 district (STATE_EXEC / 'NV' / 'Nevada Controller')
--   STEP 3 — 1 politician (Andy Matthews, -3200006) + 1 office (title='Controller')
--   STEP 4 — office_id back-fill on the politician row
-- All inserts idempotent (WHERE NOT EXISTS / ON CONFLICT DO NOTHING).

BEGIN;

-- ===== Pre-flight: assert State of Nevada government row exists (exactly 1) =====
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE geo_id = '32') <> 1 THEN
    RAISE EXCEPTION
      'Pre-flight failed: expected exactly 1 State of Nevada government row (geo_id=32); found %',
      (SELECT COUNT(*) FROM essentials.governments WHERE geo_id = '32');
  END IF;
END $$;

-- ===== STEP 1: Insert Controller chamber under State of Nevada =====
-- CRITICAL: Do NOT include the generated-identifier column — it is GENERATED ALWAYS.
-- CRITICAL: government via geo_id='32' subquery (not geo_id='51'/'24').
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Controller',
       'Nevada State Controller',
       (SELECT id FROM essentials.governments WHERE geo_id = '32')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Controller'
    AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')
);

-- ===== STEP 2: Insert STATE_EXEC district for Controller =====
-- Mirror the 270_md_state_executives column list: district_id='' and mtfcc='' (empty).
-- CRITICAL: state = 'NV' UPPERCASE. WHERE NOT EXISTS guards (district_type, state, label)
--   — districts has no unique constraint.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'STATE_EXEC', 'NV', '32', 'Nevada Controller', '', ''
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC' AND state = 'NV' AND label = 'Nevada Controller'
);

-- ===== STEP 3: Insert politician + office for Andy Matthews (Controller) =====
-- Andy Matthews (R), State Controller since 2023-01-02. Voter-elected (not appointed).
-- chamber_id subquery MUST scope to the geo_id='32' government.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Andy Matthews', 'Andy', 'Matthews', 'Republican',
          true, false, false, true, -3200006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Controller'
          AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32')),
       p.id,
       'Controller', 'NV', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'STATE_EXEC' AND d.state = 'NV' AND d.label = 'Nevada Controller'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = (SELECT id FROM essentials.chambers
                          WHERE name = 'Controller'
                            AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '32'))
  );

-- ===== STEP 4: Back-fill office_id on the politician row =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id = -3200006
  AND p.office_id IS NULL;

COMMIT;

-- ===== Structural registration (OUTSIDE the transaction block) =====
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1050', 'nv_controller')
ON CONFLICT (version) DO NOTHING;
