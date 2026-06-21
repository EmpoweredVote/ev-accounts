-- 1011_west_covina_complete.sql
-- Phase 152 Wave 2 (WCOV-01): finalize West Covina's 5-seat by-district roster.
-- Gov 1982a9fa; survivor council chamber 12c9360a (5 bidirectional offices after mig 1010).
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-21 (152-02 Task 1): all 5 current, active, bidirectional; official_count=5.
--
-- ROTATIONAL MAYOR = TITLE ON A SEAT (Palmdale 146 / Glendale 144 model — NOT El Monte/Lancaster
-- directly-elected LOCAL_EXEC). The title rotates annually; current (2026, westcovina.gov/172+/177):
--   Mayor = Lopez-Viado (D2), Mayor Pro Tem = Cantos (D4). NO separate Mayor office / LOCAL_EXEC.
--
-- Part A — Mayor + Mayor Pro Tem titles + normalize council titles ('Council Member' -> 'Councilmember').
-- Part B — official_count=5 (all 5 are council seats; no separate mayor to exclude).
-- No new politician; no unlink (all 5 current per RESEARCH §D-02/§D-03).

BEGIN;

-- Part A: Mayor / Mayor Pro Tem titles (rotational, title-on-seat), normalize the rest.
UPDATE essentials.offices SET title = 'Mayor'
 WHERE id = '4a8f2fd6-755b-448c-8824-bb42ad170a33' AND title IS DISTINCT FROM 'Mayor'; -- Lopez-Viado D2
UPDATE essentials.offices SET title = 'Mayor Pro Tem'
 WHERE id = '50471af9-bc27-4c68-aff4-49a97c313a1e' AND title IS DISTINCT FROM 'Mayor Pro Tem'; -- Cantos D4
UPDATE essentials.offices SET title = 'Councilmember'
 WHERE id IN ('0f3cce5f-9509-4268-a3fe-2ce972ead493',  -- Gutierrez D1
              'abd27abb-42c6-4734-b683-5fac4d978174',  -- Diaz D3
              '65bf4e71-cd21-4394-802d-8630bcd9f48e')  -- Wu D5
   AND title IS DISTINCT FROM 'Councilmember';

-- Part B: official_count (idempotent guard; already 5).
UPDATE essentials.chambers SET official_count = 5
 WHERE id = '12c9360a-60ac-476f-b2ac-055a26e891a0' AND official_count IS DISTINCT FROM 5;

COMMIT;

INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1011', 'west_covina_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. 5 occupied offices under 12c9360a, all bidirectional
-- 2. title 'Mayor' on 4a8f2fd6 (Lopez-Viado), 'Mayor Pro Tem' on 50471af9 (Cantos), 'Councilmember' on other 3
-- 3. ZERO LOCAL_EXEC rows for geo_id 0684200; no separate Mayor office; no new politician
-- 4. official_count=5; district labels D1-D5
-- 5. feedback_section_split_check -> 0 rows for West Covina
-- 6. migration 1011 registered
