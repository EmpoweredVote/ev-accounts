-- 947_pasadena_complete.sql
-- Phase 149 Wave 2 (PASA-01): Pasadena roster link-repair.
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- Runs after 946 (single 'City Council' chamber 2e7f01d0, 8 offices, districts D1-D7 + Mayor).
-- DB-verified pre-flight 2026-06-20 (149-02 Task 1): Gordo (-200901) + Hampton (-201094) had NULL
-- politicians.office_id after the Plan 01 chamber move; the other 6 links were already consistent;
-- ext_id 657577 already reads 'Rick Cole' (no name correction needed); official_count pre-state = 8.
-- RESEARCH §2: all 8 members current (June 2026 incumbents Jones/Rivas/Lyon held; no departures).
-- NO creations, NO retirements. Mayor is directly elected (Lancaster/Pomona LOCAL_EXEC, already modeled).

BEGIN;

-- Part A: repair bidirectional back-pointers (politicians.office_id). offices.politician_id already set.
-- Gordo + Hampton were NULL after the Plan 01 move; the rest guarded as idempotent no-ops.
UPDATE essentials.politicians SET office_id='fc5e372a-5a42-4e0f-aebe-2e8f10db190b'
 WHERE external_id=-200901 AND office_id IS DISTINCT FROM 'fc5e372a-5a42-4e0f-aebe-2e8f10db190b'; -- Gordo Mayor
UPDATE essentials.politicians SET office_id='0c357b48-7f12-42ec-a9c6-c9d5b06b154f'
 WHERE external_id=-201094 AND office_id IS DISTINCT FROM '0c357b48-7f12-42ec-a9c6-c9d5b06b154f'; -- Hampton D1
UPDATE essentials.politicians SET office_id='7ab2730c-01b3-4cd6-881f-98a1ce550b7f'
 WHERE external_id=657577 AND office_id IS DISTINCT FROM '7ab2730c-01b3-4cd6-881f-98a1ce550b7f';  -- Cole D2
UPDATE essentials.politicians SET office_id='e3617ff5-4a83-4bbb-8fe8-eaff01d877b1'
 WHERE external_id=657578 AND office_id IS DISTINCT FROM 'e3617ff5-4a83-4bbb-8fe8-eaff01d877b1';  -- Jones D3
UPDATE essentials.politicians SET office_id='0bc62efd-0d23-467f-93bc-17c05136dc91'
 WHERE external_id=657579 AND office_id IS DISTINCT FROM '0bc62efd-0d23-467f-93bc-17c05136dc91';  -- Masuda D4
UPDATE essentials.politicians SET office_id='7bdb4f77-18c6-472a-bb68-704a7d1d0b3a'
 WHERE external_id=-700150 AND office_id IS DISTINCT FROM '7bdb4f77-18c6-472a-bb68-704a7d1d0b3a'; -- Rivas D5
UPDATE essentials.politicians SET office_id='f2cb13dd-1842-4e5a-933a-7366717c97b8'
 WHERE external_id=657581 AND office_id IS DISTINCT FROM 'f2cb13dd-1842-4e5a-933a-7366717c97b8';  -- Madison D6
UPDATE essentials.politicians SET office_id='0cd97f4e-ce8c-4280-b8cd-24800e047d17'
 WHERE external_id=657582 AND office_id IS DISTINCT FROM '0cd97f4e-ce8c-4280-b8cd-24800e047d17';  -- Lyon D7

-- Part B: correct Cole name IF it had been the stale 'Felicia Williams' (Pitfall 2). Pre-flight found it
-- already reads 'Rick Cole' -> this is a guarded 0-row no-op, kept for idempotency/self-documentation.
UPDATE essentials.politicians SET first_name='Rick', last_name='Cole'
 WHERE external_id=657577 AND last_name ILIKE '%Williams%';

-- Part C: council official_count = 7 (Pitfall 6 -- 7 council seats; Mayor is LOCAL_EXEC, not counted).
UPDATE essentials.chambers SET official_count=7
 WHERE id='2e7f01d0-69dd-4301-b24c-58d83eb19f47' AND official_count IS DISTINCT FROM 7;

COMMIT;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('947', 'pasadena_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 8 active members with CONSISTENT bidirectional links in 2e7f01d0:
--   SELECT p.external_id, p.last_name, d.label FROM essentials.politicians p
--     JOIN essentials.offices o ON o.id=p.office_id AND o.politician_id=p.id
--     JOIN essentials.districts d ON d.id=o.district_id
--    WHERE o.chamber_id='2e7f01d0-69dd-4301-b24c-58d83eb19f47' AND p.is_active ORDER BY d.district_type,d.label;
-- official_count=7 ; Cole reads 'Rick Cole' ; split-section check 0 rows for Pasadena.
