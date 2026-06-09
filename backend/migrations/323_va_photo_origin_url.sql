-- Migration 323: photo_origin_url for all non-senator VA officials (VAIN-03)
--
-- Sets photo_origin_url on essentials.politicians for 129 VA officials:
--   VA state execs       ×3   (external_ids -510001..-510003)
--   VA federal House reps ×11  (external_ids -5102001..-5102011)
--   VA House delegates   ×99  (external_ids -5120001..-5120100, excluding -5120020 vacant)
--   Alexandria council   ×7   (external_ids -5101000001..-5101000007)
--   ACPS board           ×9   (external_ids -5100090001..-5100090009)
--
-- HD-20 (-5120020, Vacant — Maldonado resigned 2026-05-31) intentionally excluded.
-- VA state senators excluded: already covered by migration 318 source URLs.
--
-- photo_origin_url = direct image download URL for execs, federal, and delegates;
--                  = canonical source page URL for Alexandria and ACPS.
-- Source URLs verified from headshot scripts (2026-06-08):
--   Execs:    backend/scripts/_tmp-va-execs-headshots.py
--   Federal:  backend/scripts/_tmp-va-federal-headshots.py
--   Delegates: DELEGATE_HID_MAP in backend/scripts/_tmp-va-delegates-headshots.py
--   Alexandria: https://www.alexandriava.gov/government/mayor-and-city-council (2026-06-09)
--   ACPS:       https://www.acps.k12.va.us/school-board/members-of-the-school-board (2026-06-09)
--
-- All UPDATEs are guarded with photo_origin_url IS NULL for idempotency.

BEGIN;

-- ============================================================
-- GROUP 1: VA State Executives (3 officials)
-- ============================================================

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.governor.virginia.gov/media/governorvirginiagov/governor-of-virginia/images/Governor-Spanberger-Official-Portrait.jpg'
WHERE external_id = -510001 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.ltgov.virginia.gov/media/governorvirginiagov/lieutenant-governor/Portrait-LT-Governor-Ghazala-Hashmi.jpg'
WHERE external_id = -510002 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.ag.virginia.gov/images/Jones-headshot-20260320.jpg'
WHERE external_id = -510003 AND photo_origin_url IS NULL;

-- ============================================================
-- GROUP 2: VA Federal House Reps (11 officials)
-- Standard CC0 mirror for 10; Walkinshaw uses walkinshaw.house.gov
-- (W000831 not yet in unitedstates/images — took office Sept 2025)
-- ============================================================

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/W000804.jpg'
WHERE external_id = -5102001 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/K000399.jpg'
WHERE external_id = -5102002 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/S000185.jpg'
WHERE external_id = -5102003 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/M001227.jpg'
WHERE external_id = -5102004 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/C001118.jpg'
WHERE external_id = -5102005 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/G000568.jpg'
WHERE external_id = -5102006 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/V000138.jpg'
WHERE external_id = -5102007 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/B001292.jpg'
WHERE external_id = -5102008 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/M001239.jpg'
WHERE external_id = -5102009 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://unitedstates.github.io/images/congress/original/S001230.jpg'
WHERE external_id = -5102010 AND photo_origin_url IS NULL;

UPDATE essentials.politicians
SET photo_origin_url = 'https://walkinshaw.house.gov/uploadedphotos/highresolution/122f9b36-4502-4307-a1dd-a6c925cda981.jpg'
WHERE external_id = -5102011 AND photo_origin_url IS NULL;

-- ============================================================
-- GROUP 3: VA House Delegates (99 active officials)
-- HD-20 (-5120020, Vacant) absent from VALUES — intentional.
-- URL pattern: https://house.vga.virginia.gov/delegate_photos/{H####}.jpg
-- H-IDs from DELEGATE_HID_MAP in _tmp-va-delegates-headshots.py (verified 2026-06-08)
-- ============================================================

UPDATE essentials.politicians AS p
SET photo_origin_url = v.url
FROM (VALUES
  (-5120001::bigint, 'https://house.vga.virginia.gov/delegate_photos/H0219.jpg'),
  (-5120002, 'https://house.vga.virginia.gov/delegate_photos/H0375.jpg'),
  (-5120003, 'https://house.vga.virginia.gov/delegate_photos/H0239.jpg'),
  (-5120004, 'https://house.vga.virginia.gov/delegate_photos/H0208.jpg'),
  (-5120005, 'https://house.vga.virginia.gov/delegate_photos/H0406.jpg'),
  (-5120006, 'https://house.vga.virginia.gov/delegate_photos/H0269.jpg'),
  (-5120007, 'https://house.vga.virginia.gov/delegate_photos/H0370.jpg'),
  (-5120008, 'https://house.vga.virginia.gov/delegate_photos/H0344.jpg'),
  (-5120009, 'https://house.vga.virginia.gov/delegate_photos/H0294.jpg'),
  (-5120010, 'https://house.vga.virginia.gov/delegate_photos/H0317.jpg'),
  (-5120011, 'https://house.vga.virginia.gov/delegate_photos/H0403.jpg'),
  (-5120012, 'https://house.vga.virginia.gov/delegate_photos/H0351.jpg'),
  (-5120013, 'https://house.vga.virginia.gov/delegate_photos/H0264.jpg'),
  (-5120014, 'https://house.vga.virginia.gov/delegate_photos/H0108.jpg'),
  (-5120015, 'https://house.vga.virginia.gov/delegate_photos/H0355.jpg'),
  (-5120016, 'https://house.vga.virginia.gov/delegate_photos/H0281.jpg'),
  (-5120017, 'https://house.vga.virginia.gov/delegate_photos/H0405.jpg'),
  (-5120018, 'https://house.vga.virginia.gov/delegate_photos/H0305.jpg'),
  (-5120019, 'https://house.vga.virginia.gov/delegate_photos/H0365.jpg'),
  (-5120021, 'https://house.vga.virginia.gov/delegate_photos/H0382.jpg'),
  (-5120022, 'https://house.vga.virginia.gov/delegate_photos/H0297.jpg'),
  (-5120023, 'https://house.vga.virginia.gov/delegate_photos/H0404.jpg'),
  (-5120024, 'https://house.vga.virginia.gov/delegate_photos/H0227.jpg'),
  (-5120025, 'https://house.vga.virginia.gov/delegate_photos/H0343.jpg'),
  (-5120026, 'https://house.vga.virginia.gov/delegate_photos/H0385.jpg'),
  (-5120027, 'https://house.vga.virginia.gov/delegate_photos/H0380.jpg'),
  (-5120028, 'https://house.vga.virginia.gov/delegate_photos/H0301.jpg'),
  (-5120029, 'https://house.vga.virginia.gov/delegate_photos/H0374.jpg'),
  (-5120030, 'https://house.vga.virginia.gov/delegate_photos/H0395.jpg'),
  (-5120031, 'https://house.vga.virginia.gov/delegate_photos/H0377.jpg'),
  (-5120032, 'https://house.vga.virginia.gov/delegate_photos/H0329.jpg'),
  (-5120033, 'https://house.vga.virginia.gov/delegate_photos/H0398.jpg'),
  (-5120034, 'https://house.vga.virginia.gov/delegate_photos/H0231.jpg'),
  (-5120035, 'https://house.vga.virginia.gov/delegate_photos/H0321.jpg'),
  (-5120036, 'https://house.vga.virginia.gov/delegate_photos/H0350.jpg'),
  (-5120037, 'https://house.vga.virginia.gov/delegate_photos/H0253.jpg'),
  (-5120038, 'https://house.vga.virginia.gov/delegate_photos/H0266.jpg'),
  (-5120039, 'https://house.vga.virginia.gov/delegate_photos/H0357.jpg'),
  (-5120040, 'https://house.vga.virginia.gov/delegate_photos/H0308.jpg'),
  (-5120041, 'https://house.vga.virginia.gov/delegate_photos/H0393.jpg'),
  (-5120042, 'https://house.vga.virginia.gov/delegate_photos/H0333.jpg'),
  (-5120043, 'https://house.vga.virginia.gov/delegate_photos/H0224.jpg'),
  (-5120044, 'https://house.vga.virginia.gov/delegate_photos/H0242.jpg'),
  (-5120045, 'https://house.vga.virginia.gov/delegate_photos/H0056.jpg'),
  (-5120046, 'https://house.vga.virginia.gov/delegate_photos/H0390.jpg'),
  (-5120047, 'https://house.vga.virginia.gov/delegate_photos/H0348.jpg'),
  (-5120048, 'https://house.vga.virginia.gov/delegate_photos/H0384.jpg'),
  (-5120049, 'https://house.vga.virginia.gov/delegate_photos/H0401.jpg'),
  (-5120050, 'https://house.vga.virginia.gov/delegate_photos/H0136.jpg'),
  (-5120051, 'https://house.vga.virginia.gov/delegate_photos/H0383.jpg'),
  (-5120052, 'https://house.vga.virginia.gov/delegate_photos/H0325.jpg'),
  (-5120053, 'https://house.vga.virginia.gov/delegate_photos/H0364.jpg'),
  (-5120054, 'https://house.vga.virginia.gov/delegate_photos/H0354.jpg'),
  (-5120055, 'https://house.vga.virginia.gov/delegate_photos/H0371.jpg'),
  (-5120056, 'https://house.vga.virginia.gov/delegate_photos/H0362.jpg'),
  (-5120057, 'https://house.vga.virginia.gov/delegate_photos/H0397.jpg'),
  (-5120058, 'https://house.vga.virginia.gov/delegate_photos/H0327.jpg'),
  (-5120059, 'https://house.vga.virginia.gov/delegate_photos/H0259.jpg'),
  (-5120060, 'https://house.vga.virginia.gov/delegate_photos/H0328.jpg'),
  (-5120061, 'https://house.vga.virginia.gov/delegate_photos/H0247.jpg'),
  (-5120062, 'https://house.vga.virginia.gov/delegate_photos/H0394.jpg'),
  (-5120063, 'https://house.vga.virginia.gov/delegate_photos/H0342.jpg'),
  (-5120064, 'https://house.vga.virginia.gov/delegate_photos/H0388.jpg'),
  (-5120065, 'https://house.vga.virginia.gov/delegate_photos/H0314.jpg'),
  (-5120066, 'https://house.vga.virginia.gov/delegate_photos/H0389.jpg'),
  (-5120067, 'https://house.vga.virginia.gov/delegate_photos/H0369.jpg'),
  (-5120068, 'https://house.vga.virginia.gov/delegate_photos/H0238.jpg'),
  (-5120069, 'https://house.vga.virginia.gov/delegate_photos/H0392.jpg'),
  (-5120070, 'https://house.vga.virginia.gov/delegate_photos/H0323.jpg'),
  (-5120071, 'https://house.vga.virginia.gov/delegate_photos/H0386.jpg'),
  (-5120072, 'https://house.vga.virginia.gov/delegate_photos/H0124.jpg'),
  (-5120073, 'https://house.vga.virginia.gov/delegate_photos/H0396.jpg'),
  (-5120074, 'https://house.vga.virginia.gov/delegate_photos/H0335.jpg'),
  (-5120075, 'https://house.vga.virginia.gov/delegate_photos/H0391.jpg'),
  (-5120076, 'https://house.vga.virginia.gov/delegate_photos/H0361.jpg'),
  (-5120077, 'https://house.vga.virginia.gov/delegate_photos/H0402.jpg'),
  (-5120078, 'https://house.vga.virginia.gov/delegate_photos/H0212.jpg'),
  (-5120079, 'https://house.vga.virginia.gov/delegate_photos/H0356.jpg'),
  (-5120080, 'https://house.vga.virginia.gov/delegate_photos/H0372.jpg'),
  (-5120081, 'https://house.vga.virginia.gov/delegate_photos/H0207.jpg'),
  (-5120082, 'https://house.vga.virginia.gov/delegate_photos/H0399.jpg'),
  (-5120083, 'https://house.vga.virginia.gov/delegate_photos/H0347.jpg'),
  (-5120084, 'https://house.vga.virginia.gov/delegate_photos/H0336.jpg'),
  (-5120085, 'https://house.vga.virginia.gov/delegate_photos/H0284.jpg'),
  (-5120086, 'https://house.vga.virginia.gov/delegate_photos/H0400.jpg'),
  (-5120087, 'https://house.vga.virginia.gov/delegate_photos/H0173.jpg'),
  (-5120088, 'https://house.vga.virginia.gov/delegate_photos/H0322.jpg'),
  (-5120089, 'https://house.vga.virginia.gov/delegate_photos/H0387.jpg'),
  (-5120090, 'https://house.vga.virginia.gov/delegate_photos/H0262.jpg'),
  (-5120091, 'https://house.vga.virginia.gov/delegate_photos/H0285.jpg'),
  (-5120092, 'https://house.vga.virginia.gov/delegate_photos/H0353.jpg'),
  (-5120093, 'https://house.vga.virginia.gov/delegate_photos/H0349.jpg'),
  (-5120094, 'https://house.vga.virginia.gov/delegate_photos/H0366.jpg'),
  (-5120095, 'https://house.vga.virginia.gov/delegate_photos/H0311.jpg'),
  (-5120096, 'https://house.vga.virginia.gov/delegate_photos/H0295.jpg'),
  (-5120097, 'https://house.vga.virginia.gov/delegate_photos/H0360.jpg'),
  (-5120098, 'https://house.vga.virginia.gov/delegate_photos/H0407.jpg'),
  (-5120099, 'https://house.vga.virginia.gov/delegate_photos/H0345.jpg'),
  (-5120100, 'https://house.vga.virginia.gov/delegate_photos/H0267.jpg')
) AS v(external_id, url)
WHERE p.external_id = v.external_id
  AND p.photo_origin_url IS NULL;

-- ============================================================
-- GROUP 4: Alexandria City Council (7 officials)
-- Canonical source page (photos sourced from alexandriava.gov council page).
-- ============================================================

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.alexandriava.gov/government/mayor-and-city-council'
WHERE external_id BETWEEN -5101000007 AND -5101000001
  AND photo_origin_url IS NULL;

-- ============================================================
-- GROUP 5: ACPS School Board (9 officials)
-- Canonical source page (photos sourced from acps.k12.va.us board page).
-- ============================================================

UPDATE essentials.politicians
SET photo_origin_url = 'https://www.acps.k12.va.us/school-board/members-of-the-school-board'
WHERE external_id BETWEEN -5100090009 AND -5100090001
  AND photo_origin_url IS NULL;

-- ============================================================
-- Post-verification
-- ============================================================

DO $$
DECLARE
  v_exec_count     INTEGER;
  v_federal_count  INTEGER;
  v_delegate_count INTEGER;
  v_alex_count     INTEGER;
  v_acps_count     INTEGER;
  v_vacant_nonull  INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.politicians
  WHERE external_id IN (-510001, -510002, -510003)
    AND photo_origin_url IS NOT NULL;

  SELECT COUNT(*) INTO v_federal_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -5102011 AND -5102001
    AND photo_origin_url IS NOT NULL;

  SELECT COUNT(*) INTO v_delegate_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -5120100 AND -5120001
    AND external_id <> -5120020
    AND photo_origin_url IS NOT NULL;

  SELECT COUNT(*) INTO v_alex_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -5101000007 AND -5101000001
    AND photo_origin_url IS NOT NULL;

  SELECT COUNT(*) INTO v_acps_count
  FROM essentials.politicians
  WHERE external_id BETWEEN -5100090009 AND -5100090001
    AND photo_origin_url IS NOT NULL;

  SELECT COUNT(*) INTO v_vacant_nonull
  FROM essentials.politicians
  WHERE external_id = -5120020
    AND photo_origin_url IS NOT NULL;

  IF v_exec_count <> 3 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 3 VA exec photo_origin_url, found %', v_exec_count;
  END IF;
  IF v_federal_count <> 11 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 11 federal rep photo_origin_url, found %', v_federal_count;
  END IF;
  IF v_delegate_count <> 99 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 99 active delegate photo_origin_url, found %', v_delegate_count;
  END IF;
  IF v_alex_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 7 Alexandria council photo_origin_url, found %', v_alex_count;
  END IF;
  IF v_acps_count <> 9 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected 9 ACPS board photo_origin_url, found %', v_acps_count;
  END IF;
  IF v_vacant_nonull <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: HD-20 vacant seat has photo_origin_url set (should be NULL)';
  END IF;

  RAISE NOTICE 'Migration 323 post-verification PASSED: exec=%, federal=%, delegates=%, alex=%, acps=%, hd20_vacant_null=OK',
    v_exec_count, v_federal_count, v_delegate_count, v_alex_count, v_acps_count;
END $$;

COMMIT;

-- ============================================================
-- Supabase migration ledger entry
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('323')
ON CONFLICT (version) DO NOTHING;
