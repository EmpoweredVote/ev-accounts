-- Migration 150: Commonwealth of Massachusetts government row + legislative chambers
--
-- Creates the state government row and both legislative chambers required for
-- Phase 39 legislator migrations (151 = Senate, 152 = House).
--
-- governments table columns: id (uuid, default gen_random_uuid()), name, type, state, city, geo_id
-- MA FIPS state code: 25
--
-- TX analogue: migration 087 (State of Texas, type='STATE', state='TX', city='', geo_id='48')
--
-- CRITICAL: DO NOT include `slug` in column list — it is GENERATED ALWAYS (migration 060).
-- CRITICAL: state='MA' (uppercase) for the governments table (matches TX pattern 'TX').
--           The districts table uses state='ma' (lowercase) — different convention.
--
-- Idempotency: all inserts guarded by NOT EXISTS. Safe to re-run.

BEGIN;

-- Government row
INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Commonwealth of Massachusetts', 'STATE', 'MA', '', '25'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Commonwealth of Massachusetts'
);

-- Massachusetts Senate chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Massachusetts Senate',
       'Massachusetts Senate',
       (SELECT id FROM essentials.governments WHERE name = 'Commonwealth of Massachusetts')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts Senate'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Commonwealth of Massachusetts')
);

-- Massachusetts House of Representatives chamber
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'Massachusetts House of Representatives',
       'Massachusetts House of Representatives',
       (SELECT id FROM essentials.governments WHERE name = 'Commonwealth of Massachusetts')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Massachusetts House of Representatives'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Commonwealth of Massachusetts')
);

COMMIT;
