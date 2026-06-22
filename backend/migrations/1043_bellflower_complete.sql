-- 1043_bellflower_complete.sql
-- Phase 156 Wave 2 (BLFL-01): finalize Bellflower's 5-seat BY-DISTRICT roster.
-- Gov d34bdac8-e928-45c5-aaa8-ca3950ec2d6c; chamber a89b567a-6085-44c0-94ce-2a922ebb1fa6
-- (4 bidirectional by-district offices after mig 1042: D1=Morse, D2=Koops, D4=Sanchez, D5=Dunton;
--  empty D3 district f6369fe9 ready for Santa Ines).
-- STRUCTURAL migration (registers in supabase_migrations.schema_migrations). Idempotent.
-- DB-verified pre-flight 2026-06-22 (156-02 Task 1): NO DRIFT.
--
-- ROTATIONAL MAYOR = TITLE ON A SEAT (West Covina 1011 / Norwalk 1035 model). Bellflower is
-- BY-DISTRICT (5 districts since Ord. 1410, Nov 2021) with a council-selected rotational Mayor.
-- Current rotational state (Dec 8 2025 reorganization, valid through Dec 2026 — confirmed via
-- bellflower.ca.gov, RESEARCH §Roster Verdict HIGH):
--   Mayor          = Sonny R. Santa Ines (District 3) -- the MISSING 5th member, created here
--   Mayor Pro Tem  = Victor A. Sanchez   (District 4, pol 4384a5d8)
-- Name-collision check (Task 1): the only DB rows matching 'Santa Ines' are 4 campaign-finance
--   committee rows (ext_id NULL, is_active=false) — IGNORE (Lancaster rule). No real politician
--   row exists -> clean create.
-- Assumption A1: Dec 2025 reorg still current (next rotation Dec 2026). Re-confirmed this session.
-- CRITICAL: official_count=5 (rotational Mayor IS one of the 5 by-district seats — NOT 4).
-- PITFALL 4: do NOT set Mayor on Dunton (Mayor a prior cycle) or Koops (stale 'mayor' bio URL).
-- NO unlink (all 4 existing current per RESEARCH §Roster Verdict). NO LOCAL_EXEC Mayor office.
-- OUT OF SCOPE (untouched): Bellflower Unified School District gov f85ca154-68c4-4cd5-92c0-adba01d992cc.

BEGIN;

-- Part A: create Santa Ines (-701003) -- Palmdale 919 INSERT pattern, guarded ON CONFLICT (external_id).
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, source,
   is_active, is_appointed, is_incumbent, is_vacant)
VALUES
  (gen_random_uuid(), -701003, 'Sonny R. Santa Ines', 'Sonny', 'Santa Ines', '',
   'bellflower.ca.gov', true, false, true, false)
ON CONFLICT (external_id) DO NOTHING;

-- Part B: seat Santa Ines in a NEW District 3 office (title 'Mayor' -- he IS the current Mayor).
-- Guarded NOT EXISTS on (chamber_id, politician_id). Palmdale 919 office-INSERT column set.
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title,
   representing_state, representing_city, description, seats,
   normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT
  (SELECT id FROM essentials.politicians WHERE external_id = -701003),
  'a89b567a-6085-44c0-94ce-2a922ebb1fa6',
  'f6369fe9-5f53-4fd3-966c-90856294a2c3',  -- District 3 (created in Wave 1)
  'Mayor',
  'CA', 'Bellflower', '', 0,
  'Council Member', '', '',
  false, false, false
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = 'a89b567a-6085-44c0-94ce-2a922ebb1fa6'
      AND o.politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -701003)
 );

-- Part C: back-fill politicians.office_id for Santa Ines (IS DISTINCT FROM guard).
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.chamber_id = 'a89b567a-6085-44c0-94ce-2a922ebb1fa6'
   AND o.politician_id = p.id
   AND p.external_id = -701003
   AND p.office_id IS DISTINCT FROM o.id;

-- Part D: rotational titles on the existing seats (by politician_id — unambiguous; IS DISTINCT FROM).
UPDATE essentials.offices SET title = 'Mayor Pro Tem'
 WHERE politician_id = '4384a5d8-68b2-4e24-81e2-5208f5c61a34'
   AND title IS DISTINCT FROM 'Mayor Pro Tem'; -- Victor A. Sanchez (D4)

UPDATE essentials.offices SET title = 'Councilmember'
 WHERE politician_id IN (
   '31c35458-6cc0-43ad-b431-841846e81875',  -- Ray Dunton (D5; was Mayor a prior cycle)
   'dd2c2cfd-401f-4b35-916f-caba8ca9b722',  -- Dan Koops (D2; stale 'mayor' bio URL — NOT Mayor)
   'd18dcb81-ad41-468f-9b12-a70ed21fd3a7'   -- Wendi Morse (D1)
 )
   AND title IS DISTINCT FROM 'Councilmember';

-- Part E: official_count = 5 (rotational Mayor is one of the 5 by-district seats — NOT 4).
UPDATE essentials.chambers SET official_count = 5
 WHERE id = 'a89b567a-6085-44c0-94ce-2a922ebb1fa6'
   AND official_count IS DISTINCT FROM 5;

-- Part F: exactly-one-Mayor assert (adapted from 1035).
DO $$
DECLARE mayor_ct int;
BEGIN
  SELECT COUNT(*) INTO mayor_ct FROM essentials.offices
    WHERE chamber_id = 'a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND title = 'Mayor';
  IF mayor_ct <> 1 THEN
    RAISE EXCEPTION 'Expected exactly 1 Mayor in chamber a89b567a, found %', mayor_ct;
  END IF;
END $$;

COMMIT;

-- Register structural migration in the ledger (OUTSIDE the transaction block).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('1043', 'bellflower_complete')
ON CONFLICT (version) DO NOTHING;

-- ============================ POST-VERIFICATION =============================
-- 1. Santa Ines created (-701003), seated D3, bidirectional:
--    SELECT p.external_id, p.full_name, o.title, d.label, (p.office_id=o.id) bidir
--      FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id=p.id
--      JOIN essentials.districts d ON d.id=o.district_id WHERE p.external_id=-701003;
-- 2. 5 occupied offices under a89b567a, all bidirectional:
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id
--      WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND p.office_id=o.id;  -> 5
-- 3. titles: Mayor=Santa Ines (-701003), Mayor Pro Tem=Sanchez (-201151), Councilmember=Dunton/Koops/Morse:
--    SELECT p.external_id, p.full_name, o.title, d.label FROM essentials.offices o
--      JOIN essentials.politicians p ON p.id=o.politician_id JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' ORDER BY d.label;
-- 4. exactly one Mayor:
--    SELECT COUNT(*) FROM essentials.offices WHERE chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND title='Mayor';  -> 1
-- 5. Dunton/Koops NOT Mayor:
--    SELECT o.title FROM essentials.offices o JOIN essentials.politicians p ON p.id=o.politician_id WHERE p.external_id IN (-200583,-201149);  -> 'Councilmember'
-- 6. ZERO LOCAL_EXEC offices under this gov:
--    SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
--      WHERE o.chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' AND d.district_type='LOCAL_EXEC';  -> 0
-- 7. official_count=5:
--    SELECT official_count FROM essentials.chambers WHERE id='a89b567a-6085-44c0-94ce-2a922ebb1fa6';  -> 5
-- 8. 5 distinct district labels D1-D5, no shared district_id:
--    SELECT district_id, COUNT(*) FROM essentials.offices WHERE chamber_id='a89b567a-6085-44c0-94ce-2a922ebb1fa6' GROUP BY district_id HAVING COUNT(*)>1;  -> 0 rows
-- 9. ledger MAX includes 1043:
--    SELECT version, name FROM supabase_migrations.schema_migrations WHERE version='1043';
