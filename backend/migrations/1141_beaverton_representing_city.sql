-- Migration 1141: Set representing_city='Beaverton' on the 7 Beaverton offices.
--
-- The structural seed (1131, cloned from the Gresham template) left offices.representing_city
-- unset. The frontend Local section-banner derives its city from representing_city (then a
-- chamber-name regex fallback). With representing_city='' AND chamber_name='City Council'
-- (no city prefix), the derivation returns null and the Beaverton banner (cities/beaverton.jpg,
-- wired in buildingImages.js) never renders — the Local section falls back to the tier gradient.
-- Setting representing_city='Beaverton' makes getBuildingImages() match the CURATED_LOCAL key.
--
-- Idempotent: only fills blank values. Applies to the 7 Beaverton officials (-4105351..-4105357).

BEGIN;

UPDATE essentials.offices o
SET representing_city = 'Beaverton'
FROM essentials.politicians p
WHERE p.id = o.politician_id
  AND p.external_id BETWEEN -4105357 AND -4105351
  AND (o.representing_city IS NULL OR o.representing_city = '');

DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id BETWEEN -4105357 AND -4105351
    AND o.representing_city = 'Beaverton';
  IF v_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 Beaverton offices have representing_city=Beaverton', v_count;
  END IF;
  RAISE NOTICE 'Post-verification PASSED: 7 Beaverton offices now carry representing_city=Beaverton';
END $$;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1141')
ON CONFLICT (version) DO NOTHING;

COMMIT;
