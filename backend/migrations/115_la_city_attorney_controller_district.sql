-- Migration 115: Link LA City Attorney and City Controller to citywide LA district
--
-- Both offices had district_id = NULL, so they were invisible in address-based
-- representative search. The Mayor already uses the citywide LA district
-- (geo_id='0644000', district_type='LOCAL_EXEC', mtfcc='G4110'), so linking
-- these two offices to the same district makes them appear for any LA City address.
--
-- Idempotent: UPDATE is a no-op if district_id is already set correctly.

UPDATE essentials.offices
SET district_id = 'feeb6b8c-f099-47b8-80eb-f984560d3d6e'   -- LA city LOCAL_EXEC district
WHERE id IN (
  '5a873c59-72ac-488f-8b2c-44dfd04d065c',  -- City Attorney (Hydee Feldstein Soto)
  'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6'   -- City Controller (Kenneth Mejia)
)
AND district_id IS DISTINCT FROM 'feeb6b8c-f099-47b8-80eb-f984560d3d6e';
