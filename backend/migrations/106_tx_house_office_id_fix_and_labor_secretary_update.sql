-- Migration 106: Fix TX House office_id + Update Secretary of Labor
--
-- Two fixes:
--
-- 1. politicians.office_id back-fill for 37 TX US House reps
--    Migration 105 inserted offices with politician_id set, but never did the
--    reverse: politicians.office_id remained NULL. This caused politician
--    profiles to render without title/district. The offices.politician_id
--    linkage (used by the PostGIS browse path) was correct; this fixes the
--    politicians.office_id linkage used by profile rendering.
--
-- 2. Acting Secretary of Labor change: Lori Chavez-DeRemer → Keith E. Sonderling
--    Chavez-DeRemer resigned 2026-04-29; Sonderling designated Acting
--    Secretary by President Trump. Office record updated; old politician
--    marked is_active=false.

BEGIN;

-- ===== FIX 1: TX House politicians.office_id back-fill =====
-- Joins offices → politicians via offices.politician_id, sets politicians.office_id
-- Scoped to US House chamber + TX state to avoid touching any other chamber.

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND o.chamber_id = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76'  -- United States House of Representatives
  AND o.representing_state = 'TX'
  AND p.office_id IS NULL;

-- ===== FIX 2: Secretary of Labor change =====
-- Deactivate Lori Chavez-DeRemer
UPDATE essentials.politicians
SET is_active = false
WHERE id = '95cb342b-9b34-4a67-9297-2baa447da356';  -- Lori Chavez-DeRemer

-- Insert Keith E. Sonderling as Acting Secretary of Labor
-- external_id 696805 (next after highest-used federal official 696804)
INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, is_active, is_appointed, is_vacant, is_incumbent, external_id, source)
VALUES (
  gen_random_uuid(),
  'Keith E. Sonderling',
  'Keith',
  'Sonderling',
  true,
  true,   -- Acting appointment
  false,
  false,  -- Not elected — acting appointee
  696805,
  'manual'
)
ON CONFLICT (external_id) DO NOTHING;

-- Update the Secretary of Labor office to point to Sonderling
-- and set Sonderling's office_id via a CTE
WITH sonderling AS (
  SELECT id FROM essentials.politicians WHERE external_id = 696805
)
UPDATE essentials.offices
SET politician_id = sonderling.id
FROM sonderling
WHERE essentials.offices.id = '06d7d298-5c01-4e01-9cf6-479e2a860317';  -- Secretary of Labor office

-- Set Sonderling's office_id (reverse link)
WITH sonderling AS (
  SELECT id FROM essentials.politicians WHERE external_id = 696805
)
UPDATE essentials.politicians p
SET office_id = '06d7d298-5c01-4e01-9cf6-479e2a860317'  -- Secretary of Labor office
FROM sonderling
WHERE p.id = sonderling.id;

COMMIT;
