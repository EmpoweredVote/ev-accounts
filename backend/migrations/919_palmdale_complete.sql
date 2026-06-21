-- 919_palmdale_complete.sql
-- Phase 146 (Palmdale deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations)
-- Pre-flight confirmed 2026-06-20: Bishop -201331 office_id NULL; -700657 free;
-- no real active Laura Bettencourt official; District 3 row 21d57fc7 present (Plan 01);
-- Loa 692504 active; current Mayor = Eric Ohlsen (D4, selected 12/2/2025, effective 1/1/2026).
--
-- Part A: REPAIR Bishop's (-201331) back-pointer (politicians.office_id was NULL — desync).
--         Normalize his office title 'Council Member' → 'Councilmember'.
-- Part B: CREATE Laura Bettencourt (-700657) + INSERT a NEW District 3 office in survivor
--         chamber 000d672d; sync BOTH offices.politician_id AND politicians.office_id.
-- Part C: FLAG Mayor on Ohlsen's existing D4 seat a67a975e (Glendale rotational-mayor model —
--         NO separate Mayor office / chamber / LOCAL_EXEC district).
--         Set survivor chamber official_count=5.
-- Idempotent throughout (ON CONFLICT / NOT EXISTS / IS DISTINCT FROM guards).

BEGIN;

-- ============================================================
-- Part A: Repair Bishop's bidirectional link + normalize title
-- ============================================================

-- Repair back-pointer: set politicians.office_id → Bishop's office 198661de
UPDATE essentials.politicians
   SET office_id = '198661de-2850-46a1-954e-ef502122a40c'
 WHERE external_id = -201331
   AND office_id IS DISTINCT FROM '198661de-2850-46a1-954e-ef502122a40c';

-- Normalize Bishop's office title: 'Council Member' → 'Councilmember'
UPDATE essentials.offices
   SET title = 'Councilmember'
 WHERE id = '198661de-2850-46a1-954e-ef502122a40c'
   AND title <> 'Councilmember';

-- ============================================================
-- Part B: Create Laura Bettencourt (-700657) + seat in District 3 office
-- ============================================================

-- Insert Bettencourt politician row (guarded; ext_id unique)
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source,
   is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -700657, 'Laura Bettencourt', 'Laura', 'Bettencourt', '',
   'cityofpalmdaleca.gov', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- Insert NEW District 3 office in survivor chamber 000d672d (guarded NOT EXISTS on chamber+politician)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title,
   representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT
  (SELECT id FROM essentials.politicians WHERE external_id = -700657),
  '000d672d-97f1-4f1f-af61-9eb6f008c4fd',
  '21d57fc7-7c70-44ad-acd6-760842c72324',
  'Councilmember',
  'CA', 'Palmdale', '', 0,
  'Council Member', '', '',
  false, false, false
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
      AND o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700657)
 );

-- Back-fill politicians.office_id for Bettencourt (robust to re-run via IS DISTINCT FROM)
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.chamber_id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
   AND o.politician_id = p.id
   AND p.external_id = -700657
   AND p.office_id IS DISTINCT FROM o.id;

-- ============================================================
-- Part C: Flag Mayor on Ohlsen's existing D4 seat (Glendale model)
--         + set official_count=5 on survivor chamber
-- ============================================================

-- Set title='Mayor' on Ohlsen's D4 council seat (office a67a975e) — NO new Mayor office/chamber
UPDATE essentials.offices
   SET title = 'Mayor'
 WHERE id = 'a67a975e-9743-435b-a44c-1badb47866c3'
   AND title <> 'Mayor';

-- Survivor chamber: official_count=5
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
   AND official_count IS DISTINCT FROM 5;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('919')
ON CONFLICT (version) DO NOTHING;

COMMIT;

-- ============================================================
-- Addendum (orchestrator deviation, Phase 146): remove the stale LOCAL_EXEC
-- 'Palmdale Mayor' district left over from the original wrong "separately-tracked
-- at-large mayor" seed. D-08 establishes Palmdale has NO separate Mayor LOCAL_EXEC
-- structure (rotational mayor flagged via title='Mayor' on the D4 council seat), so
-- this orphan contradicts the corrected form of government. Guarded: only deletes
-- when 0 offices reference it (idempotent — re-run is a no-op once gone).
-- ============================================================
BEGIN;
DELETE FROM essentials.districts d
 WHERE d.id = 'a2732964-32e5-4419-96a0-5ddc56ad45c3'
   AND d.district_type = 'LOCAL_EXEC'
   AND d.label = 'Palmdale Mayor'
   AND d.geo_id = '0655156'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);
COMMIT;

-- ============================================================
-- Post-verification roster query (run after COMMIT to confirm):
-- ============================================================
-- SELECT p.external_id, p.first_name, p.last_name, p.is_active,
--        o.id as office_id, o.title, d.label as district,
--        (p.office_id = o.id) as pol_ptr_ok,
--        (o.politician_id = p.id) as off_ptr_ok
-- FROM essentials.offices o
-- JOIN essentials.politicians p ON p.id = o.politician_id
-- JOIN essentials.districts d ON d.id = o.district_id
-- WHERE o.chamber_id = '000d672d-97f1-4f1f-af61-9eb6f008c4fd'
-- ORDER BY d.label;
