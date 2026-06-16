-- verify-phase-125-126.sql
-- Consolidated phase gate for v2.15 (National House Rep Seeding, Tier 1).
-- Labeled assertions for USHR-01..05. Read-only; RAISE EXCEPTION on failure, RAISE NOTICE on pass.
-- Run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-125-126.sql
--
-- Batch = the Phase 125 seeded House reps: external_id BETWEEN -56999 AND -1000.
-- Known intentional unlinked NATIONAL_LOWER districts: 1198 (dup DC delegate, seeded under
-- dc-prefixed geoid), 1220 (FL-20), 1313 (GA-13), 4823 (TX-23) — last three genuine vacancies.

-- ===== USHR-01 (a): coverage — only the 4 known districts remain unlinked =====
DO $$
DECLARE v_unlinked INT; v_unexpected INT;
BEGIN
  SELECT COUNT(*) INTO v_unlinked
  FROM essentials.districts d LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='NATIONAL_LOWER' AND o.politician_id IS NULL;
  IF v_unlinked <> 4 THEN
    RAISE EXCEPTION 'USHR-01a FAILED: expected 4 unlinked NATIONAL_LOWER districts, found %', v_unlinked;
  END IF;
  SELECT COUNT(*) INTO v_unexpected
  FROM essentials.districts d LEFT JOIN essentials.offices o ON o.district_id = d.id
  WHERE d.district_type='NATIONAL_LOWER' AND o.politician_id IS NULL
    AND d.tiger_geoid NOT IN ('1198','1220','1313','4823');
  IF v_unexpected <> 0 THEN
    RAISE EXCEPTION 'USHR-01a FAILED: % unlinked district(s) outside the known set (1198/1220/1313/4823)', v_unexpected;
  END IF;
  RAISE NOTICE 'USHR-01a PASS: exactly the 4 known districts unlinked (dup DC 1198 + vacancies FL-20/GA-13/TX-23)';
END $$;

-- ===== USHR-01 (b): batch size = 299 =====
DO $$
DECLARE v INT;
BEGIN
  SELECT COUNT(*) INTO v FROM essentials.politicians WHERE external_id BETWEEN -56999 AND -1000;
  IF v <> 299 THEN RAISE EXCEPTION 'USHR-01b FAILED: expected 299 batch reps, found %', v; END IF;
  RAISE NOTICE 'USHR-01b PASS: 299 batch House reps seeded';
END $$;

-- ===== USHR-02 (a): no orphan politicians (every batch rep has an office) =====
DO $$
DECLARE v INT;
BEGIN
  SELECT COUNT(*) INTO v FROM essentials.politicians
   WHERE external_id BETWEEN -56999 AND -1000 AND office_id IS NULL;
  IF v <> 0 THEN RAISE EXCEPTION 'USHR-02a FAILED: % orphan batch politicians (office_id NULL)', v; END IF;
  RAISE NOTICE 'USHR-02a PASS: 0 orphan batch politicians';
END $$;

-- ===== USHR-02 (b): pre-existing states untouched (CA=53, VA=11, MA=9) =====
DO $$
DECLARE v_ca INT; v_va INT; v_ma INT;
BEGIN
  SELECT COUNT(*) INTO v_ca FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='06';
  SELECT COUNT(*) INTO v_va FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='51';
  SELECT COUNT(*) INTO v_ma FROM essentials.districts d JOIN essentials.offices o ON o.district_id=d.id
   WHERE d.district_type='NATIONAL_LOWER' AND LEFT(d.tiger_geoid,2)='25';
  IF v_ca <> 53 OR v_va <> 11 OR v_ma <> 9 THEN
    RAISE EXCEPTION 'USHR-02b FAILED: CA=% (exp 53), VA=% (exp 11), MA=% (exp 9)', v_ca, v_va, v_ma;
  END IF;
  RAISE NOTICE 'USHR-02b PASS: CA=53, VA=11, MA=9 (pre-existing untouched)';
END $$;

-- ===== USHR-03: party normalization =====
DO $$
DECLARE v_dem INT; v_bad INT;
BEGIN
  SELECT COUNT(*) INTO v_dem FROM essentials.politicians
   WHERE external_id BETWEEN -56999 AND -1000 AND party='Democrat';
  IF v_dem <> 0 THEN RAISE EXCEPTION 'USHR-03 FAILED: % batch reps with party=''Democrat''', v_dem; END IF;
  SELECT COUNT(*) INTO v_bad FROM essentials.politicians
   WHERE external_id BETWEEN -56999 AND -1000
     AND party NOT IN ('Democratic','Republican','Independent');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'USHR-03 FAILED: % batch reps with unexpected party value', v_bad; END IF;
  RAISE NOTICE 'USHR-03 PASS: 0 ''Democrat'' rows; all batch parties in (Democratic,Republican,Independent)';
END $$;

-- ===== USHR-04: every batch rep has a photo =====
DO $$
DECLARE v_photo INT; v_canon INT; v_noncanon_no_img INT;
BEGIN
  SELECT COUNT(*) INTO v_photo FROM essentials.politicians
   WHERE external_id BETWEEN -56999 AND -1000 AND photo_origin_url IS NOT NULL AND photo_origin_url<>'';
  IF v_photo <> 299 THEN RAISE EXCEPTION 'USHR-04 FAILED: % of 299 batch reps have a photo', v_photo; END IF;

  SELECT COUNT(*) INTO v_canon FROM essentials.politicians
   WHERE external_id BETWEEN -56999 AND -1000
     AND photo_origin_url LIKE 'https://unitedstates.github.io/images/congress/225x275/%';
  IF v_canon < 290 THEN RAISE EXCEPTION 'USHR-04 FAILED: only % batch reps use canonical congress photo URL', v_canon; END IF;

  -- Any batch rep not on the canonical URL must have a politician_images row (storage-mirrored fallback)
  SELECT COUNT(*) INTO v_noncanon_no_img
  FROM essentials.politicians p
  WHERE p.external_id BETWEEN -56999 AND -1000
    AND p.photo_origin_url NOT LIKE 'https://unitedstates.github.io/images/congress/225x275/%'
    AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);
  IF v_noncanon_no_img <> 0 THEN
    RAISE EXCEPTION 'USHR-04 FAILED: % non-canonical-photo batch reps lack a politician_images row', v_noncanon_no_img;
  END IF;
  RAISE NOTICE 'USHR-04 PASS: 299/299 batch reps have a photo (% canonical + % storage-mirrored)', v_canon, 299 - v_canon;
END $$;

-- ===== USHR-05: Path 0 spot checks (>=5 states incl at-large + DC) =====
DO $$
DECLARE
  v_name TEXT;
  -- geoid, expected last name, label
  checks TEXT[][] := ARRAY[
    ARRAY['5600','Hageman','WY-AL (at-large)'],
    ARRAY['3614','Ocasio-Cortez','NY-14'],
    ARRAY['4836','Babin','TX-36'],
    ARRAY['3905','Latta','OH-5'],
    ARRAY['1701','Jackson','IL-1']
  ];
  c TEXT[];
BEGIN
  FOREACH c SLICE 1 IN ARRAY checks LOOP
    SELECT p.last_name INTO v_name
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.politicians p ON p.id = o.politician_id
    WHERE d.district_type='NATIONAL_LOWER' AND d.tiger_geoid = c[1];
    IF v_name IS NULL OR v_name NOT ILIKE '%'||c[2]||'%' THEN
      RAISE EXCEPTION 'USHR-05 FAILED: Path 0 for % (geoid %) expected %, got %', c[3], c[1], c[2], COALESCE(v_name,'(none)');
    END IF;
    RAISE NOTICE 'USHR-05 Path 0 OK: % -> %', c[3], v_name;
  END LOOP;

  -- DC delegate via dc-prefixed geoid
  SELECT p.last_name INTO v_name
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.district_type='NATIONAL_LOWER' AND d.tiger_geoid = 'dc-national-lower' AND p.last_name ILIKE '%Norton%';
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'USHR-05 FAILED: DC delegate (Norton) not resolved via dc-national-lower';
  END IF;
  RAISE NOTICE 'USHR-05 Path 0 OK: DC delegate -> %', v_name;
  RAISE NOTICE 'USHR-05 PASS: Path 0 resolves correct reps across 5 states + at-large + DC';
END $$;

-- If we reach here with no exception, all v2.15 assertions passed.
DO $$ BEGIN RAISE NOTICE 'verify-phase-125-126: ALL USHR-01..05 ASSERTIONS PASSED'; END $$;
