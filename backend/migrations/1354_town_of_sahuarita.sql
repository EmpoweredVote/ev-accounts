-- Migration 1354: Town of Sahuarita government + chamber + 1 shared LOCAL district + officials + offices
--
-- Purpose: Seeds the Town of Sahuarita, Arizona (greenfield town deep-seed):
--   Sahuarita (geo_id='0462140') — 1 gov + 1 chamber + 1 district + 7 officials + 7 offices
--
-- Form of government (RESEARCH-confirmed 2026-07-16, valid <=5 days — active 2026 election;
-- CONFIRMED via 4 independent sources: Town Code Ch. 2.05/2.10, Wikipedia, sahuaritaaz.gov's own
-- Election-Information page, tucson.com composite):
--   Council-manager. ALL 7 seats are elected AT-LARGE, NO wards, NO council districts. There is NO
--   separately-elected Mayor office. The Mayor and Vice Mayor are TITLES the 7-member council chooses
--   from among its own already-elected membership (Town Code 2.10.010: nomination + roll-call vote,
--   4 affirmative votes, re-chosen at the first meeting after every canvass). NO custom geofences this
--   phase — the whole-town G4110 boundary (geo_id='0462140') is already live from Phase 190; this
--   migration adds the ONE essentials.districts row Phase 190 never wrote.
--
-- CRITICAL/DEVIATION (this OVERRIDES the CONTEXT.md D-02 default expectation of a LOCAL_EXEC Mayor
--   seat, mirroring Oro Valley 195 / Marana 196): RESEARCH's 4-source verification confirmed Sahuarita
--   has NO separately-elected Mayor. Therefore this migration is a HYBRID: the Oro-Valley/Marana
--   "all at-large members share ONE LOCAL district row" DB shape, MINUS Marana's LOCAL_EXEC half (there
--   is no separately-elected office it would represent), PLUS the Palm-Springs (1329)/Indio
--   title-on-seat office-modeling pattern — Mayor/Vice-Mayor live PURELY in the `title` string, with
--   `role_canonical` staying NULL on all 7, and a post-verify gate asserting "exactly 1 office titled
--   Mayor" / "exactly 1 office titled Vice Mayor", re-scoped here to the SINGLE shared LOCAL/G4110/
--   0462140 row (not a LIKE across per-seat districts, since Palm Springs/Indio each have their own
--   per-district geofence and Sahuarita does not). DO NOT create a LOCAL_EXEC row anywhere in this file
--   — it would be a phantom seat with no electoral basis (RESEARCH Pitfall 3).
--
-- CRITICAL: the generated identifier column (slug) on essentials.chambers is NEVER included in an INSERT.
-- CRITICAL: essentials.governments has NO unique constraint on geo_id — use WHERE NOT EXISTS guard on name.
-- CRITICAL: districts.state must be 'az' (lowercase) to match routing queries.
-- CRITICAL: governments.state = 'AZ' (uppercase). offices.representing_state = 'AZ' (uppercase).
-- CRITICAL: at-large council — NO ward geofences; ALL 7 offices (including the Mayor- and
--           Vice-Mayor-titled ones) share ONE LOCAL district row. NO LOCAL_EXEC row exists in this file.
-- CRITICAL: the single LOCAL row carries mtfcc='G4110' (reuse the live Phase-190 geofence).
-- CRITICAL: party = NULL for all 7 (Sahuarita runs NONPARTISAN elections, confirmed via Ballotpedia's
--           "Sahuarita Town Council At-large" candidate-page naming convention) — do NOT record a party.
-- CRITICAL: geo_id '0462140' also appears in geofence_boundaries with state stored as FIPS '04' — every
--           office<->district join MUST scope district_type='LOCAL' + mtfcc='G4110' + state='az', never
--           a bare geo_id.
--
-- DEVIATION NOTE (governments.type): following the AZ Town precedent (Oro Valley 1305, Marana 1345),
--   type='Town'. (Confirm against the live Marana 1345 governments.type row at apply time.)
-- DEVIATION NOTE (title style): plain Palm-Springs-style titles ('Mayor'/'Vice Mayor'/'Council Member')
--   are used rather than Marana's parenthetical-annotation style ('Council Member (Vice Mayor)') — per
--   RESEARCH A4, this is the closer structural analog since NEITHER Mayor nor Vice Mayor is a
--   separately-elected office here (unlike Marana, where only Vice Mayor rotates and Mayor is directly
--   elected). Either style renders correctly; this is a stylistic choice, not a technical requirement.
--
-- CRITICAL (roster + title currency — RESEARCH's #1 risk, Task 2 in the plan is a BLOCKING re-verify):
--   Sahuarita's July 21, 2026 municipal primary is 5 days from the 2026-07-16 research date (may already
--   be past at apply time). 3 seats are up (Murphy's, Egbert's, Morales's). Vice Mayor Kara Egbert is
--   CONFIRMED NOT seeking re-election (running for Precinct 7 Justice of the Peace instead) — her seat
--   is guaranteed to change hands. AND, uniquely to this phase, the Mayor/Vice-Mayor TITLES are
--   re-chosen by the newly-seated council at the first meeting after the canvass (Town Code 2.10.010) —
--   a SEPARATE, SCHEDULED event from the election itself. Winning re-election to Council does NOT
--   guarantee retaining the Mayor/Vice-Mayor title. Task 2 (ORCHESTRATOR-RUN, blocking) re-verifies BOTH
--   the membership AND the current Mayor/Vice-Mayor title holders against a live source before this
--   migration is applied; the external_id -> name -> title assignments below and the post-verify gate's
--   expected external_ids may be patched by the orchestrator per Task 2's decision before apply.
--
-- Roster seeded (RESEARCH 2026-07-16, subject to Task 2 re-verification):
--   -4014001 Tom Murphy         title='Mayor'          [seat up 2026; Mayor title re-chosen post-canvass]
--   -4014002 Kara Egbert        title='Vice Mayor'      [OPEN SEAT — confirmed NOT seeking re-election]
--   -4014003 Deborah Morales    title='Council Member'  [seat up 2026 — running as incumbent]
--   -4014004 Steven Gillespie   title='Council Member'  [term to 2028]
--   -4014005 Diane Priolo       title='Council Member'  [term to 2028]
--   -4014006 Kim Lisk           title='Council Member'  [term to 2028]
--   -4014007 Edgar Lytle        title='Council Member'  [term to 2028]

BEGIN;

-- =============================================================================
-- Pre-flight (1): assert the whole-town G4110/0462140 geofence exists (codifies RESEARCH Pitfall 3 precondition)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.geofence_boundaries
      WHERE geo_id = '0462140' AND mtfcc = 'G4110') < 1 THEN
    RAISE EXCEPTION 'Sahuarita G4110 geofence missing — run Phase 190 first';
  END IF;
END $$;

-- =============================================================================
-- Pre-flight (2): RAISE EXCEPTION if the Sahuarita government row already exists (hard abort guard)
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name = 'Town of Sahuarita, Arizona, US') > 0 THEN
    RAISE EXCEPTION 'Migration 1354 already applied — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- TOWN OF SAHUARITA (geo_id='0462140')
-- 7 officials, ALL at-large, ALL sharing ONE LOCAL district row (Murphy=Mayor, Egbert=Vice Mayor titles)
-- =============================================================================

-- Step 1: Government row (greenfield; type='Town' per AZ Oro-Valley/Marana convention — see DEVIATION NOTE)
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(),
       'Town of Sahuarita, Arizona, US',
       'Town', 'AZ', 'Sahuarita', '0462140'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'Town of Sahuarita, Arizona, US'
);

-- Step 2: Town Council chamber (generated slug column omitted intentionally)
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(),
       'Town Council',
       'Sahuarita Town Council',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Sahuarita, Arizona, US'),
       7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'Town Council'
    AND government_id = (SELECT id FROM essentials.governments
                         WHERE name = 'Town of Sahuarita, Arizona, US')
);

-- Step 3: ONE NEW LOCAL at-large district (ALL 7 council members, including the Mayor- and
-- Vice-Mayor-titled seats, share this SINGLE row — Oro-Valley/Marana shared-row precedent). NO
-- LOCAL_EXEC row is created anywhere in this migration (RESEARCH Pitfall 3 — no separately-elected
-- Mayor office exists to represent). mtfcc='G4110' reuses the Phase-190 geofence.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'az', '0462140', 'Town of Sahuarita (At-Large)', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0462140' AND district_type = 'LOCAL' AND state = 'az'
);

-- Step 4: Tom Murphy (-4014001) — title='Mayor' (council-chosen title on an at-large seat, NOT a
--         separately-elected office; Town Code 2.10.010). Re-verify at Task 2 before apply.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Tom Murphy', 'Tom', 'Murphy', NULL,
          true, false, false, true, -4014001)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Kara Egbert (-4014002) — title='Vice Mayor'. OPEN SEAT — confirmed NOT seeking re-election
--         (running for Precinct 7 Justice of the Peace instead); re-verify at Task 2 before apply.
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kara Egbert', 'Kara', 'Egbert', NULL,
          true, false, false, true, -4014002)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Vice Mayor', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 6: Deborah Morales (-4014003) — Council Member (seat up 2026 — running as incumbent)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Deborah Morales', 'Deborah', 'Morales', NULL,
          true, false, false, true, -4014003)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 7: Dr. Steven Gillespie (-4014004) — Council Member (term to 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Steven Gillespie', 'Steven', 'Gillespie', NULL,
          true, false, false, true, -4014004)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 8: Diane Priolo (-4014005) — Council Member (term to 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Diane Priolo', 'Diane', 'Priolo', NULL,
          true, false, false, true, -4014005)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 9: Kim Lisk (-4014006) — Council Member (term to 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Kim Lisk', 'Kim', 'Lisk', NULL,
          true, false, false, true, -4014006)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 10: Edgar Lytle (-4014007) — Council Member (term to 2028)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edgar Lytle', 'Edgar', 'Lytle', NULL,
          true, false, false, true, -4014007)
  ON CONFLICT (external_id) DO NOTHING
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
                               WHERE name = 'Town of Sahuarita, Arizona, US')),
       p.id,
       'Council Member', 'AZ', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '0462140'
  AND d.district_type = 'LOCAL'
  AND d.state = 'az'
  AND d.mtfcc = 'G4110'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- =============================================================================
-- office_id back-fill (all 7 Sahuarita officials)
-- Explicit IN list; WHERE p.office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (
    -4014001,-4014002,-4014003,-4014004,-4014005,-4014006,-4014007
  )
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification DO block — RAISE EXCEPTION on any failure rolls back the transaction.
-- Gate (a): government row count = 1
-- Gate (b): offices under Town Council on the ONE LOCAL/G4110/0462140 district = 7
-- Gate (c): LOCAL district holds exactly 7 offices AND there is NO LOCAL_EXEC district for 0462140
-- Gate (d): all 7 politicians have party IS NULL AND is_appointed=false
-- Gate (e): EXACTLY 1 office has title='Mayor' AND its politician has external_id=-4014001 (Murphy)
-- Gate (f): EXACTLY 1 office has title='Vice Mayor' AND its politician has external_id=-4014002 (Egbert)
-- Gate (g): section-split — 0 offices reachable via this district under a non-Sahuarita government
-- Gate (h): office_id back-fill — 0 NULLs remaining across the 7 external_ids
-- =============================================================================
DO $$
DECLARE
  v_gov_count       INTEGER;
  v_office_count    INTEGER;
  v_local_count     INTEGER;
  v_local_exec_count INTEGER;
  v_party_count     INTEGER;
  v_appointed_count INTEGER;
  v_mayor_count     INTEGER;
  v_vm_count        INTEGER;
  v_mayor_extid     BIGINT;
  v_vm_extid        BIGINT;
  v_split_count     INTEGER;
  v_null_count      INTEGER;
BEGIN

  -- Gate (a): Sahuarita government row
  SELECT COUNT(*) INTO v_gov_count FROM essentials.governments
  WHERE name = 'Town of Sahuarita, Arizona, US';
  IF v_gov_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Sahuarita gov_count=%, expected 1', v_gov_count;
  END IF;

  -- Gate (b): offices under Town Council on the ONE LOCAL/G4110/0462140 district
  SELECT COUNT(*) INTO v_office_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL'
    AND c.name = 'Town Council'
    AND c.government_id = (SELECT id FROM essentials.governments
                           WHERE name = 'Town of Sahuarita, Arizona, US');
  IF v_office_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Sahuarita office_count=%, expected 7', v_office_count;
  END IF;

  -- Gate (c): LOCAL district holds exactly 7 offices AND there is NO LOCAL_EXEC district for 0462140
  SELECT COUNT(*) INTO v_local_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL';
  IF v_local_count <> 7 THEN
    RAISE EXCEPTION 'Post-verification FAILED: LOCAL office_count=%, expected 7', v_local_count;
  END IF;

  -- Any district row for 0462140 that is NOT 'LOCAL' would be a phantom seat (e.g. a directly-elected
  -- Mayor district) with no electoral basis for Sahuarita — assert none exists, without ever writing
  -- that other district_type's literal string in this file (see header CRITICAL/DEVIATION note).
  SELECT COUNT(*) INTO v_local_exec_count
  FROM essentials.districts
  WHERE geo_id = '0462140' AND district_type <> 'LOCAL';
  IF v_local_exec_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: found % non-LOCAL district(s) for 0462140 — expected 0 (Sahuarita has no separately-elected Mayor; no other district_type should exist for this geo_id)', v_local_exec_count;
  END IF;

  -- Gate (d): all 7 politicians nonpartisan (party IS NULL) AND not flagged appointed
  SELECT COUNT(*) INTO v_party_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4014001,-4014002,-4014003,-4014004,-4014005,-4014006,-4014007
  )
  AND party IS NOT NULL;
  IF v_party_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 politicians have a non-NULL party (expected nonpartisan)', v_party_count;
  END IF;

  SELECT COUNT(*) INTO v_appointed_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4014001,-4014002,-4014003,-4014004,-4014005,-4014006,-4014007
  )
  AND is_appointed;
  IF v_appointed_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % of 7 politicians have is_appointed=true, expected 0', v_appointed_count;
  END IF;

  -- Gate (e): exactly 1 office title='Mayor' bound to external_id=-4014001 (Murphy)
  SELECT COUNT(*) INTO v_mayor_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Mayor';
  IF v_mayor_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Mayor, found %', v_mayor_count;
  END IF;

  SELECT p.external_id INTO v_mayor_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Mayor';
  IF v_mayor_extid <> -4014001 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Mayor title is on external_id % — expected -4014001 (Tom Murphy)', v_mayor_extid;
  END IF;

  -- Gate (f): exactly 1 office title='Vice Mayor' bound to external_id=-4014002 (Egbert)
  SELECT COUNT(*) INTO v_vm_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Vice Mayor';
  IF v_vm_count <> 1 THEN
    RAISE EXCEPTION 'Post-verification FAILED: expected exactly 1 office with title=Vice Mayor, found %', v_vm_count;
  END IF;

  SELECT p.external_id INTO v_vm_extid
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND o.title = 'Vice Mayor';
  IF v_vm_extid <> -4014002 THEN
    RAISE EXCEPTION 'Post-verification FAILED: Vice Mayor title is on external_id % — expected -4014002 (Kara Egbert)', v_vm_extid;
  END IF;

  -- Gate (g): section-split — no office reachable via this district under a non-Sahuarita government
  SELECT COUNT(*) INTO v_split_count
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE d.geo_id = '0462140' AND d.mtfcc = 'G4110' AND d.state = 'az'
    AND d.district_type = 'LOCAL'
    AND c.government_id <> (SELECT id FROM essentials.governments
                            WHERE name = 'Town of Sahuarita, Arizona, US');
  IF v_split_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: section-split — % office(s) attached under a non-Sahuarita government', v_split_count;
  END IF;

  -- Gate (h): office_id back-fill — all 7 politicians must have non-null office_id
  SELECT COUNT(*) INTO v_null_count
  FROM essentials.politicians
  WHERE external_id IN (
    -4014001,-4014002,-4014003,-4014004,-4014005,-4014006,-4014007
  )
  AND office_id IS NULL;
  IF v_null_count <> 0 THEN
    RAISE EXCEPTION 'Post-verification FAILED: % politicians still have NULL office_id after back-fill', v_null_count;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: Sahuarita gov=1, offices=7 (all LOCAL, 0 LOCAL_EXEC), party NULL, is_appointed=false, Mayor on -4014001, Vice Mayor on -4014002, section-split=0, office_id back-fill complete';
END $$;

COMMIT;


-- =============================================================================
-- Supabase migration ledger entry (OUTSIDE the transaction)
-- Disk MAX confirmed 1353 on 2026-07-16 (re-verified at author time via `ls` — no drift) → next
-- structural = 1354. Follows the most recent structural migration's (1345 Marana) 1-column form.
-- =============================================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('1354')
ON CONFLICT (version) DO NOTHING;
