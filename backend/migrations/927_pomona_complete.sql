-- 927_pomona_complete.sql
-- Phase 147 (Pomona deep-seed) Wave 2 — STRUCTURAL (registers in schema_migrations)
-- Pre-flight confirmed 2026-06-20: Garcia -201350 / Lustro -201352 / Sandoval -200916 office_id all NULL;
-- -700658 free; only campaign-committee Ontiveros rows exist (NULL ext, NULL first_name — NOT officials);
-- District 4 row 7adbe57d present (Plan 01); Martin/Canales/Lustro active (A1/A2/A3).
--
-- Part A: REPAIR 3 broken bidirectional links (set politicians.office_id; offices.politician_id already set).
-- Part B: CREATE Elizabeth Ontiveros-Cole (-700658) + seat into a NEW District 4 office in survivor
--         chamber ddabfccc; sync BOTH offices.politician_id AND politicians.office_id.
-- Part C: set survivor chamber official_count=7 (Pomona = directly-elected Mayor + 6 council = 7).
-- Lancaster (directly-elected) Mayor model: 'Pomona Mayor' LOCAL_EXEC 3ec78ed9 + Sandoval office 657cb0b2
-- (title 'Mayor') reused — NO new Mayor office/district, NO rotational title flag (Pitfall 3).
-- Idempotent throughout (ON CONFLICT / NOT EXISTS / IS DISTINCT FROM guards).

BEGIN;

-- ============================================================
-- Part A: Repair 3 broken back-pointers (Garcia / Lustro / Sandoval)
-- ============================================================
UPDATE essentials.politicians SET office_id = '315a0a8a-a950-4bac-984d-7b60a192c176'
 WHERE external_id = -201350 AND office_id IS DISTINCT FROM '315a0a8a-a950-4bac-984d-7b60a192c176';  -- Garcia
UPDATE essentials.politicians SET office_id = '8570f2ad-a8e4-476f-a437-4083da315095'
 WHERE external_id = -201352 AND office_id IS DISTINCT FROM '8570f2ad-a8e4-476f-a437-4083da315095';  -- Lustro
UPDATE essentials.politicians SET office_id = '657cb0b2-f607-4a8d-898c-5a15a49451fb'
 WHERE external_id = -200916 AND office_id IS DISTINCT FROM '657cb0b2-f607-4a8d-898c-5a15a49451fb';  -- Sandoval (Mayor)

-- ============================================================
-- Part B: Create Elizabeth Ontiveros-Cole (-700658) + seat in a new District 4 office
-- ============================================================
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source,
   is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -700658, 'Elizabeth Ontiveros-Cole', 'Elizabeth', 'Ontiveros-Cole', '',
   'pomonaca.gov', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- New District 4 office in survivor chamber ddabfccc (guarded NOT EXISTS on chamber+politician)
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title,
   representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT
  (SELECT id FROM essentials.politicians WHERE external_id = -700658),
  'ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d',
  '7adbe57d-515a-4848-9320-ccbf3feeeeb2',
  'Council Member',
  'CA', 'Pomona', '', 0,
  'Council Member', '', '',
  false, false, false
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = 'ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d'
      AND o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -700658)
 );

-- Sync politicians.office_id for Ontiveros-Cole (robust to re-run via IS DISTINCT FROM)
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.chamber_id = 'ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d'
   AND o.politician_id = p.id
   AND p.external_id = -700658
   AND p.office_id IS DISTINCT FROM o.id;

-- ============================================================
-- Part C: official_count = 7 on survivor chamber (Mayor + 6 council)
-- ============================================================
UPDATE essentials.chambers SET official_count = 7
 WHERE id = 'ddabfccc-820f-4b10-bc0f-a7ba47d9bb0d' AND official_count IS DISTINCT FROM 7;

-- Register this structural migration
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('927', 'pomona_complete')
ON CONFLICT (version) DO NOTHING;

COMMIT;
