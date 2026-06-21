-- 992_downey_mayor_correction.sql
-- Phase 150 Wave 3 pre-step — corrective STRUCTURAL migration (registers in schema_migrations).
--
-- WHY: Phase 150 RESEARCH.md identified Hector Sosa (District 2) as Downey's rotational mayor.
-- The operator's authoritative check of the official City of Downey site (2026-06-20) corrected this:
--   * Claudia Frometa (District 4) is the current rotational MAYOR.
--   * Hector Sosa (District 2) is a Council Member (not Mayor).
--   * Horacio Ortiz (District 1) is MAYOR PRO TEM.
-- "Who is mayor" is the structure-hard fact (DWNY-01 SC2), so this is corrected on production
-- before headshots/stances. Idempotent + guarded; UUID-targeted (offices keyed by office UUID,
-- which is stable). District assignments are UNCHANGED — only the rotational mayor/pro-tem TITLES move.
--
-- Survivor chamber: 7cb8a90c-1214-4840-bd75-5f6b9504532d

BEGIN;

-- Frometa (District 4, office 6fa79f0e) -> Mayor
UPDATE essentials.offices
SET title = 'Mayor'
WHERE id = '6fa79f0e-a3d8-47f3-b67d-29009818f2ee'
  AND title IS DISTINCT FROM 'Mayor';

-- Sosa (District 2, office cc3bacd0) -> Councilmember (was wrongly 'Mayor')
UPDATE essentials.offices
SET title = 'Councilmember'
WHERE id = 'cc3bacd0-5026-4914-b271-c6e40c929a9c'
  AND title IS DISTINCT FROM 'Councilmember';

-- Ortiz (District 1, office 44ca5c68) -> Mayor Pro Tem
UPDATE essentials.offices
SET title = 'Mayor Pro Tem'
WHERE id = '44ca5c68-3e7e-4e96-93eb-3c1773df842a'
  AND title IS DISTINCT FROM 'Mayor Pro Tem';

-- Assert: exactly one 'Mayor' in the chamber, and it is Frometa's office
DO $$
DECLARE
  mayor_count int;
  mayor_office uuid;
BEGIN
  SELECT count(*) INTO mayor_count
  FROM essentials.offices
  WHERE chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d' AND title = 'Mayor';
  IF mayor_count <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 Mayor in Downey chamber, found %', mayor_count;
  END IF;

  SELECT id INTO mayor_office
  FROM essentials.offices
  WHERE chamber_id = '7cb8a90c-1214-4840-bd75-5f6b9504532d' AND title = 'Mayor';
  IF mayor_office <> '6fa79f0e-a3d8-47f3-b67d-29009818f2ee' THEN
    RAISE EXCEPTION 'Mayor title is on the wrong office: %', mayor_office;
  END IF;
END $$;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('992')
ON CONFLICT (version) DO NOTHING;

COMMIT;
