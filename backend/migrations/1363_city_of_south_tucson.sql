-- Migration 1363: City of South Tucson government + chamber + 1 shared LOCAL district + officials + offices
--
-- Purpose: Seeds the City of South Tucson, Arizona (greenfield city deep-seed):
--   South Tucson (geo_id='0468850') — 1 gov + 1 chamber + 1 district + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed 2026-07-17; corroborated via 3+ independent WebSearch composites
-- tracing to southtucsonaz.gov's own Elections/City-Council pages, plus Tucson Spotlight Nov-2024
-- swearing-in + AZ Luminaria Jun-2026 voter guide):
--   7-member council, ALL seats elected AT-LARGE, NO wards, NO council districts. There is NO separately-
--   elected Mayor office. Mayor, Vice Mayor, AND Acting Mayor are TITLES the 7-member council chooses from
--   among its own already-elected membership (re-chosen at the first meeting after every canvass). NO custom
--   geofences this phase — the whole-city G4110 boundary (geo_id='0468850') is already live from Phase 190;
--   this migration adds the ONE essentials.districts row Phase 190 never wrote.
--
-- CRITICAL/DEVIATION (this OVERRIDES the CONTEXT.md D-02 default expectation of a LOCAL_EXEC Mayor seat,
--   mirroring Oro Valley 195 / Marana 196 / Sahuarita 197): RESEARCH confirmed South Tucson has NO
--   separately-elected Mayor. Therefore this migration reuses Sahuarita's 1354 STRUCTURE near-verbatim: the
--   "all at-large members share ONE LOCAL district row" DB shape, with NO LOCAL_EXEC row (no separately-
--   elected office to represent), PLUS the Palm-Springs/Sahuarita title-on-seat modeling — the THREE titles
--   live PURELY in the `title` string, with `role_canonical` staying NULL on all 7, and post-verify gates
--   asserting "exactly 1 office titled Mayor / Vice Mayor / Acting Mayor", re-scoped to the SINGLE shared
--   LOCAL/G4110/0468850 row. Exactly TWO deltas from Sahuarita 1354: (1) a THIRD title gate (Acting Mayor on
--   -4015003) copied verbatim from the Mayor/Vice-Mayor gate shape; (2) governments.type='City' not 'Town'.
--   DO NOT create a LOCAL_EXEC row anywhere in this file — it would be a phantom seat with no electoral
--   basis (RESEARCH Pitfall 3).
--
-- CRITICAL (D-03 enclave routing — the FIRST enclave/wholly-surrounded jurisdiction in this milestone):
--   South Tucson sits entirely inside the City of Tucson's footprint. RESEARCH resolved this BLOCKING check
--   live 2026-07-17: ST_Area(ST_Intersection(0468850, 0477000)) = 0 km² (a true topological donut hole —
--   Tucson's polygon has South Tucson cut out of it; ST_Intersects=true is merely shared boundary edges,
--   the CORRECT safe signature), and a ST_Covers point test inside South Tucson is covered EXCLUSIVELY by
--   0468850, never Tucson's 0477000. This migration carries a pre-flight DO block that RE-ASSERTS the
--   0-overlap invariant BEFORE seeding; a non-zero overlap indicates a TIGER data change requiring
--   escalation. Do NOT use the mailing-address city string ("Tucson, AZ 85713" — South Tucson has no
--   distinct USPS post office) as a jurisdiction proxy; the geo_id/geofence is authoritative.
--
-- CRITICAL: the generated identifier column (slug) on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'az' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'AZ' (uppercase). offices.representing_state = 'AZ' (uppercase).
-- CRITICAL: at-large council — NO ward geofences; ALL 7 offices (including the Mayor-, Vice-Mayor-, and
--           Acting-Mayor-titled ones) share ONE LOCAL district row. NO LOCAL_EXEC row exists in this file.
-- CRITICAL: the single LOCAL row carries mtfcc='G4110' (reuse the live Phase-190 geofence).
-- CRITICAL: party = NULL for all 7 (South Tucson runs NONPARTISAN elections — AZ Luminaria: "South Tucson
--           elections are nonpartisan") — do NOT record a party.
-- CRITICAL: geo_id '0468850' also appears in geofence_boundaries with state stored as FIPS '04' — every
--           office<->district join MUST scope district_type='LOCAL' + mtfcc='G4110' + state='az', never a
--           bare geo_id.
--
-- DEVIATION NOTE (governments.type): South Tucson is legally incorporated as a City (delta from the AZ
--   Town precedent of Oro Valley/Marana/Sahuarita) — type='City', confirmed against the live Tucson 0477000
--   governments.type='City' row at apply time (2026-07-17).
-- DEVIATION NOTE (title style): plain Palm-Springs/Sahuarita-style titles ('Mayor'/'Vice Mayor'/'Acting
--   Mayor'/'Council Member'); none of the three titles is a separately-elected office here.
--
-- CRITICAL (roster + title currency — RESEARCH's #1 risk; the sharpest in the milestone):
--   South Tucson's July 21, 2026 municipal primary is 4 days from the 2026-07-17 research date. 3 seats are
--   up (Valenzuela's, Flagg's, Aguirre's) — and uniquely, the sitting MAYOR (Roxanna Valenzuela) is herself
--   one of the three incumbent candidates. AND the three TITLES (Mayor/Vice Mayor/Acting Mayor) are re-chosen
--   by the newly-seated council at the first meeting after the canvass — a SEPARATE, SUBSEQUENT event from the
--   election. Applied 2026-07-17 under the "primary NOT yet occurred / not certified AND no new title vote"
--   branch per explicit operator decision — seeds the CURRENT seated roster below (represents residents
--   today). A POST-JULY-21 RECONCILE IS OWED: after the primary is certified and the post-canvass title
--   re-vote is held, re-verify membership + all three title holders and patch if anything changed.
--
-- Roster seeded (RESEARCH 2026-07-17; operator-approved current-roster seed 2026-07-17):
--   -4015001 Roxanna Valenzuela      title='Mayor'          [seat up 2026; incumbent candidate; title re-chosen post-canvass]
--   -4015002 Melissa Brown-Dominguez title='Vice Mayor'     [term to 2028; not up]
--   -4015003 Pablo Robles            title='Acting Mayor'   [term to 2028; not up]
--   -4015004 Dulce Jimenez           title='Council Member' [term to 2028]
--   -4015005 Paul Diaz               title='Council Member' [term to 2028; former Mayor pre-Nov-2024]
--   -4015006 Brian Flagg             title='Council Member' [seat up 2026; incumbent candidate]
--   -4015007 Cesar Aguirre           title='Council Member' [seat up 2026; incumbent candidate]

BEGIN;

-- =============================================================================
-- Pre-flight (0) — D-03 ENCLAVE CHECK (milestone's FIRST enclave/wholly-surrounded jurisdiction):
-- assert South Tucson's polygon does NOT overlap Tucson's in AREA (a true donut hole). ST_Intersects=true
-- is merely shared boundary edges; the AREA of the intersection must be ~0. A non-zero overlap indicates a
-- TIGER data change requiring escalation — RAISE EXCEPTION and roll back rather than seed a double-match.
-- =============================================================================
DO $$
DECLARE
  v_overlap_km2 numeric;
BEGIN
  SELECT ST_Area(ST_Intersection(st.geometry, tuc.geometry)::geography) / 1e6
    INTO v_overlap_km2
  FROM essentials.geofence_boundaries st, essentials.geofence_boundaries tuc
  WHERE st.geo_id = '0468850' AND tuc.geo_id = '0477000';
  IF v_overlap_km2 IS NULL OR v_overlap_km2 > 0.001 THEN
    RAISE EXCEPTION 'D-03 BLOCKING enclave check FAILED: South Tucson/Tucson intersection area = % sqkm (expected ~0, a clean donut hole) — do NOT proceed', v_overlap_km2;
  END IF;
  RAISE NOTICE 'D-03 enclave pre-flight PASSED: South Tucson/Tucson overlap area = % sqkm (clean donut hole)', v_overlap_km2;
END $$;

-- =============================================================================
-- Pre-flight (1): assert the whole-city G4110/0468850 geofence exists (Phase 190 precondition)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE geo_id = '0468850' AND mtfcc = 'G4110') < 1 THEN
    RAISE EXCEPTION 'South Tucson G4110 geofence missing — run Phase 190 first';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight (2): RAISE EXCEPTION if the South Tucson government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'City of South Tucson, Arizona, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1363 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- CITY OF SOUTH TUCSON (geo_id='0468850')
-- 7 officials, ALL at-large, ALL sharing ONE LOCAL district row
-- (Valenzuela=Mayor, Brown-Dominguez=Vice Mayor, Robles=Acting Mayor titles)
-- =============================================================================

-- Step 1: Government row (greenfield; type='City' — South Tucson is legally a City, see DEVIATION NOTE)
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'City of South Tucson, Arizona, US',
       'City', 'AZ', 'South Tucson', '0468850'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'City of South Tucson, Arizona, US'
);

-- Step 2: City Council chamber (generated slug column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'City Council',
       'South Tucson City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of South Tucson, Arizona, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'City of South Tucson, Arizona, US')
);

-- Step 3: ONE NEW LOCAL at-large district (ALL 7 council members, including the Mayor-, Vice-Mayor-, and
-- Acting-Mayor-titled seats, share this SINGLE row — Sahuarita shared-row precedent). NO LOCAL_EXEC row is
-- created anywhere in this migration (RESEARCH Pitfall 3 — no separately-elected Mayor office exists to
-- represent). mtfcc='G4110' reuses the Phase-190 geofence.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', '0468850', 'City of South Tucson (At-Large)', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0468850' AND district_type = 'LOCAL' AND state = 'az'
);

-- Step 4: Roxanna Valenzuela (-4015001) — title='Mayor' (council-chosen title on an at-large seat, NOT a
--         separately-elected office). Seat up 2026; incumbent candidate; Mayor title re-chosen post-canvass.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Roxanna Valenzuela', 'Roxanna', 'Valenzuela', NULL,
          true, false, false, true, -4015001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Melissa Brown-Dominguez (-4015002) — title='Vice Mayor' (term to 2028; not up).
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Melissa Brown-Dominguez', 'Melissa', 'Brown-Dominguez', NULL,
          true, false, false, true, -4015002)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Vice Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Pablo Robles (-4015003) — title='Acting Mayor' (term to 2028; not up). THIRD title gate — the
--         one structural delta beyond Sahuarita's two titles.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Pablo Robles', 'Pablo', 'Robles', NULL,
          true, false, false, true, -4015003)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Acting Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Dulce Jimenez (-4015004) — Council Member (term to 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Dulce Jimenez', 'Dulce', 'Jimenez', NULL,
          true, false, false, true, -4015004)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Paul Diaz (-4015005) — Council Member (term to 2028; former Mayor pre-Nov-2024)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Paul Diaz', 'Paul', 'Diaz', NULL,
          true, false, false, true, -4015005)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Brian Flagg (-4015006) — Council Member (seat up 2026; incumbent candidate)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Brian Flagg', 'Brian', 'Flagg', NULL,
          true, false, false, true, -4015006)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Cesar Aguirre (-4015007) — Council Member (seat up 2026; incumbent candidate)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Cesar Aguirre', 'Cesar', 'Aguirre', NULL,
          true, false, false, true, -4015007)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'City Council'
          AND government_id = (SELECT id FROM essentials.governments
                               WHERE name = 'City of South Tucson, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0468850'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 South Tucson officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4015001,-4015002,-4015003,-4015004,-4015005,-4015006,-4015007
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block — RAISE EXCEPTION on any failure rolls back the transaction.
-- Gate (a): government row count = 1
-- Gate (b): offices under City Council on the ONE LOCAL/G4110/0468850 district = 7
-- Gate (c): LOCAL district holds exactly 7 offices AND there is NO non-LOCAL district for 0468850 (no
--           phantom LOCAL_EXEC Mayor seat)
-- Gate (d): all 7 politicians have party IS NULL AND is_appointed=false
-- Gate (e): EXACTLY 1 office has title='Mayor' AND its politician has external_id=-4015001 (Valenzuela)
-- Gate (f): EXACTLY 1 office has title='Vice Mayor' AND its politician has external_id=-4015002 (Brown-Dominguez)
-- Gate (i): EXACTLY 1 office has title='Acting Mayor' AND its politician has external_id=-4015003 (Robles)
-- Gate (g): section-split — 0 offices reachable via this district under a non-South-Tucson government
-- Gate (h): office_id back-fill — 0 NULLs remaining across the 7 external_ids
-- =============================================================================
DO $$
DECLARE
  v_gov_count        INTEGER;
  v_office_count     INTEGER;
  v_local_count      INTEGER;
  v_non_local_count  INTEGER;
  v_party_count      INTEGER;
  v_appointed_count  INTEGER;
  v_mayor_count      INTEGER;
  v_vm_count         INTEGER;
  v_am_count         INTEGER;
  v_mayor_extid      BIGINT;
  v_vm_extid         BIGINT;
  v_am_extid         BIGINT;
  v_split_count      INTEGER;
  v_null_count       INTEGER;
BEGIN

  -- Gate (a): South Tucson government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'City of South Tucson, Arizona, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: South Tucson gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): offices under City Council on the ONE LOCAL/G4110/0468850 district
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL'
    AND c.name = 'City Council'
    AND c.government_id = (SELECT id FROM essentials.governments
                           WHERE name = 'City of South Tucson, Arizona, US');
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: South Tucson office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): LOCAL district holds exactly 7 offices AND there is NO non-LOCAL district for 0468850
  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL';
  IF v_local_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: LOCAL office_count=%, expected 7', v_local_count;
  END IF;

  -- Any district row for 0468850 that is NOT 'LOCAL' would be a phantom seat (e.g. a directly-elected
  -- Mayor district) with no electoral basis for South Tucson — assert none exists, without ever writing
  -- that other district_type's literal string in this file (see header CRITICAL/DEVIATION note).
  SELECT COUNT(*) INTO v_non_local_count
  FROM essentials.districts
  WHERE geo_id = '0468850' AND district_type <> 'LOCAL';
  IF v_non_local_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: found % non-LOCAL district(s) for 0468850 — expected 0 (South Tucson has no separately-elected Mayor; no other district_type should exist for this geo_id)', v_non_local_count;
  END IF;

  -- Gate (d): all 7 politicians nonpartisan (party IS NULL) AND not flagged appointed
  SELECT COUNT(*) INTO v_party_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4015001,-4015002,-4015003,-4015004,-4015005,-4015006,-4015007
  )
  AND party IS NOT NULL;
  IF v_party_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 politicians have a non-NULL party (expected nonpartisan)', v_party_count;
  END IF;

  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4015001,-4015002,-4015003,-4015004,-4015005,-4015006,-4015007
  )
  AND is_appointed;
  IF v_appointed_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 politicians have is_appointed=true, expected 0', v_appointed_count;
  END IF;

  -- Gate (e): exactly 1 office title='Mayor' bound to external_id=-4015001 (Valenzuela)
  SELECT COUNT(*) INTO v_mayor_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Mayor';
  IF v_mayor_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Mayor, found %', v_mayor_count;
  END IF;

  SELECT p.external_id INTO v_mayor_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Mayor';
  IF v_mayor_extid <> -4015001 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor title is on external_id % — expected -4015001 (Roxanna Valenzuela)', v_mayor_extid;
  END IF;

  -- Gate (f): exactly 1 office title='Vice Mayor' bound to external_id=-4015002 (Brown-Dominguez)
  SELECT COUNT(*) INTO v_vm_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Vice Mayor';
  IF v_vm_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Vice Mayor, found %', v_vm_count;
  END IF;

  SELECT p.external_id INTO v_vm_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Vice Mayor';
  IF v_vm_extid <> -4015002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Vice Mayor title is on external_id % — expected -4015002 (Melissa Brown-Dominguez)', v_vm_extid;
  END IF;

  -- Gate (i) [THIRD title gate]: exactly 1 office title='Acting Mayor' bound to external_id=-4015003 (Robles)
  SELECT COUNT(*) INTO v_am_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Acting Mayor';
  IF v_am_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Acting Mayor, found %', v_am_count;
  END IF;

  SELECT p.external_id INTO v_am_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Acting Mayor';
  IF v_am_extid <> -4015003 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Acting Mayor title is on external_id % — expected -4015003 (Pablo Robles)', v_am_extid;
  END IF;

  -- Gate (g): section-split — no office reachable via this district under a non-South-Tucson government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0468850' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'City of South Tucson, Arizona, US');
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-South-Tucson government', v_split_count;
  END IF;

  -- Gate (h): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4015001,-4015002,-4015003,-4015004,-4015005,-4015006,-4015007
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: South Tucson gov=1, offices=7 (all LOCAL, 0 non-LOCAL), party NULL, is_appointed=false, Mayor on -4015001, Vice Mayor on -4015002, Acting Mayor on -4015003, section-split=0, office_id back-fill complete';
END $$;

COMMIT;


-- =============================================================================
-- Supabase migration ledger entry (OUTSIDE the transaction)
-- Disk MAX confirmed 1362 on 2026-07-17 (re-verified at author time via `ls` — no drift) → next
-- structural = 1363. Follows the most recent structural migration's (1354 Sahuarita) 1-column form.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1363')
ON CONFLICT (version) DO NOTHING;
