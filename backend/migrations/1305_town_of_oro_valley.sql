-- Migration 1305: Town of Oro Valley government + chamber + districts + officials + offices
--
-- Purpose: Seeds the Town of Oro Valley, Arizona (greenfield town deep-seed):
--   Oro Valley (geo_id='0451600') — 1 gov + 1 chamber + 2 districts + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed 2026-07-10, valid <=7 days — active 2026 election):
--   Council-manager. Mayor is DIRECTLY ELECTED at-large. 6 Council Members elected AT-LARGE with
--   NO wards and NO seat numbering (Torrance block-voting shape). NO custom geofences this phase —
--   the whole-town G4110 boundary (geo_id='0451600') is already live from Phase 190; this migration
--   only adds the TWO essentials.districts rows Phase 190 never wrote.
--
-- CRITICAL: the generated identifier column (slug) on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'az' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'AZ' (uppercase). offices.representing_state = 'AZ' (uppercase).
-- CRITICAL: district_type='LOCAL_EXEC' for Mayor; district_type='LOCAL' for council (NOT 'COUNTY').
-- CRITICAL: at-large council — NO ward geofences; all 6 council offices share ONE LOCAL district row.
-- CRITICAL: BOTH district rows carry mtfcc='G4110' (reuse the live Phase-190 geofence) — do NOT copy
--           the Beaverton analog's mtfcc=NULL; that migration predates the G4110-reuse convention.
-- CRITICAL: party = NULL for all 7 (Oro Valley runs NONPARTISAN elections) — do NOT record a party value.
-- CRITICAL: geo_id '0451600' also appears in geofence_boundaries with state stored as FIPS '04' — every
--           office<->district join MUST scope district_type + mtfcc='G4110' + state='az', never bare geo_id.
--
-- DEVIATION NOTE (governments.type): Beaverton analog (1131) used the generic tier tag type='LOCAL', but
--   that migration predates the human-readable type convention. The most recent AZ precedent, Tucson
--   (1296), uses type='City'. Following that convention (and RESEARCH's explicit call), Oro Valley uses
--   type='Town'.
-- DEVIATION NOTE (council titles): Beaverton titles seats with a numbered Position-N suffix. Oro Valley
--   uses the Torrance-precedent plain 'Council Member' (no seat numbers) per RESEARCH Pitfall 3.
-- DEVIATION NOTE (Vice Mayor): Melanie Barrett is Vice Mayor — modeled as a TITLE ANNOTATION on her
--   council seat ('Council Member (Vice Mayor)'), NOT a separate 8th office (Pima/Beaverton precedent).

BEGIN;

-- =============================================================================
-- Pre-flight (1): assert the whole-town G4110/0451600 geofence exists (codifies Pitfall 4)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE geo_id = '0451600' AND mtfcc = 'G4110') < 1 THEN
    RAISE EXCEPTION 'Oro Valley G4110 geofence missing — run Phase 190 first';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight (2): RAISE EXCEPTION if the Oro Valley government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Town of Oro Valley, Arizona, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1305 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- TOWN OF ORO VALLEY (geo_id='0451600')
-- 7 officials: Mayor Winfield + 6 council members (at-large; Barrett = Vice Mayor annotation)
-- =============================================================================

-- Step 1: Government row (greenfield; type='Town' per Tucson AZ convention — see DEVIATION NOTE)
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Town of Oro Valley, Arizona, US',
       'Town', 'AZ', 'Oro Valley', '0451600'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Town of Oro Valley, Arizona, US'
);

-- Step 2: Town Council chamber (generated slug column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Town Council',
       'Oro Valley Town Council',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Oro Valley, Arizona, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Town Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Town of Oro Valley, Arizona, US')
);

-- Step 3: LOCAL_EXEC district (Mayor — town-wide). mtfcc='G4110' reuses the Phase-190 geofence.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'az', '0451600', 'Town of Oro Valley (Mayor)', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0451600' AND district_type = 'LOCAL_EXEC' AND state = 'az'
);

-- Step 4: LOCAL at-large district (all 6 council members share this ONE row — Torrance precedent).
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', '0451600', 'Town of Oro Valley (At-Large)', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0451600' AND district_type = 'LOCAL' AND state = 'az'
);

-- Step 5: Mayor Joseph "Joe" Winfield (-4009001) — directly elected at-large (LOCAL_EXEC)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joseph "Joe" Winfield', 'Joseph', 'Winfield', NULL,
          true, false, false, true, -4009001)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL_EXEC'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Council Member Melanie Barrett (-4009002) — Vice Mayor (title annotation, NOT a separate seat)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melanie Barrett', 'Melanie', 'Barrett', NULL,
          true, false, false, true, -4009002)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member (Vice Mayor)', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Council Member Joyce Jones-Ivey (-4009003)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Joyce Jones-Ivey', 'Joyce', 'Jones-Ivey', NULL,
          true, false, false, true, -4009003)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Council Member Josh Nicolson (-4009004)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Josh Nicolson', 'Josh', 'Nicolson', NULL,
          true, false, false, true, -4009004)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Council Member Dr. Harry "Mo" Greene II (-4009005)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dr. Harry "Mo" Greene II', 'Harry', 'Greene', NULL,
          true, false, false, true, -4009005)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Council Member Mary Murphy (-4009006)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Mary Murphy', 'Mary', 'Murphy', NULL,
          true, false, false, true, -4009006)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 11: Council Member Elizabeth Robb (-4009007)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Robb', 'Elizabeth', 'Robb', NULL,
          true, false, false, true, -4009007)
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Town Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'Town of Oro Valley, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0451600'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Oro Valley officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4009001,-4009002,-4009003,-4009004,-4009005,-4009006,-4009007
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block — RAISE EXCEPTION on any failure rolls back the transaction.
-- Gate (a): government row count = 1
-- Gate (b): offices under Town Council on LOCAL/LOCAL_EXEC G4110/0451600 districts = 7
-- Gate (c): LOCAL_EXEC holds exactly 1 office AND LOCAL holds exactly 6 offices
-- Gate (d): all 7 politicians have party IS NULL (nonpartisan gate)
-- Gate (e): exactly 1 office carries a '(Vice Mayor)' annotation AND it is the -4009002 (Barrett) seat
-- Gate (f): section-split — 0 offices reachable via these 2 districts under a non-Oro-Valley government
-- Gate (g): office_id back-fill — 0 NULLs remaining across the 7 external_ids
-- =============================================================================
DO $$
DECLARE
  v_gov_count      INTEGER;
  v_office_count   INTEGER;
  v_exec_count     INTEGER;
  v_local_count    INTEGER;
  v_party_count    INTEGER;
  v_vm_count       INTEGER;
  v_vm_extid       BIGINT;
  v_split_count    INTEGER;
  v_null_count     INTEGER;
BEGIN

  -- Gate (a): Oro Valley government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'Town of Oro Valley, Arizona, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Oro Valley gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): offices under Town Council on the 2 G4110 districts
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type IN ('LOCAL','LOCAL_EXEC')
    AND c.name = 'Town Council'
    AND c.government_id = (SELECT id FROM essentials.governments
                           WHERE name = 'Town of Oro Valley, Arizona, US');
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Oro Valley office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): LOCAL_EXEC holds exactly 1, LOCAL holds exactly 6
  SELECT COUNT(*) INTO v_exec_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL_EXEC';
  IF v_exec_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: LOCAL_EXEC office_count=%, expected 1', v_exec_count;
  END IF;

  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL';
  IF v_local_count <> 6 THEN
    RAISE EXCEPTION 'Post-verification FAILED: LOCAL office_count=%, expected 6', v_local_count;
  END IF;

  -- Gate (d): all 7 politicians nonpartisan (party IS NULL)
  SELECT COUNT(*) INTO v_party_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4009001,-4009002,-4009003,-4009004,-4009005,-4009006,-4009007
  )
  AND party IS NOT NULL;
  IF v_party_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 politicians have a non-NULL party (expected nonpartisan)', v_party_count;
  END IF;

  -- Gate (e): exactly 1 office carries a '(Vice Mayor)' annotation AND it is the -4009002 (Barrett) seat
  SELECT COUNT(*) INTO v_vm_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title LIKE '%(Vice Mayor)%';
  IF v_vm_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with a (Vice Mayor) annotation, found %', v_vm_count;
  END IF;

  SELECT p.external_id INTO v_vm_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title LIKE '%(Vice Mayor)%';
  IF v_vm_extid <> -4009002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: (Vice Mayor) annotation is on external_id % — expected -4009002 (Melanie Barrett)', v_vm_extid;
  END IF;

  -- Gate (f): section-split — no office reachable via these 2 districts under a non-Oro-Valley government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0451600' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type IN ('LOCAL','LOCAL_EXEC')
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'Town of Oro Valley, Arizona, US');
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Oro-Valley government', v_split_count;
  END IF;

  -- Gate (g): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4009001,-4009002,-4009003,-4009004,-4009005,-4009006,-4009007
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Oro Valley gov=1, offices=7 (1 LOCAL_EXEC + 6 LOCAL), party NULL, Vice Mayor on -4009002, section-split=0, office_id back-fill complete';
END $$;

COMMIT;


-- =============================================================================
-- Supabase migration ledger entry (OUTSIDE the transaction)
-- Disk MAX confirmed 1304 on 2026-07-10 → next structural = 1305
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1305')
ON CONFLICT (version) DO NOTHING;
