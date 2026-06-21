-- 895_santa_clarita_complete.sql
-- Phase 143 / Plan 02 — Santa Clarita roster completion (idempotent).
--
-- RESEAT strategy (user-approved, see 894 header): McLean & Miranda already exist as active
-- politician rows (McLean 9476ec1c / -201394, Miranda 069fc0f2 / -200980). Their old Chamber A
-- offices were deleted in 894. Here we give them NEW offices in the surviving Chamber B
-- (eeabd028, external_id 11243) and back-fill office_id — NO new politician rows, NO duplicate
-- -700181/-700182 people. Districts reuse the existing Chamber B At-Large row bb6bdc6a
-- (flat single geo_id 0669088, D-10 — no new districts/geofences, no LOCAL_EXEC).
--
-- Part C: rotational Mayor flagged on Laurene Weste's (665693) existing seat (D-05) — NO separate
-- Mayor row/chamber/office. Part D: official_count=5.
--
-- chambers.slug is GENERATED — never written. All statements idempotent.

BEGIN;

-- Normalize the two reseated members' flags/source (idempotent — sets same values on re-apply).
UPDATE essentials.politicians
   SET source = 'santaclarita.gov',
       is_active = true, is_incumbent = true, is_appointed = false, is_vacant = false
 WHERE external_id IN (-201394, -200980);

-- Part A — McLean office in Chamber B (guarded; mirrors existing Chamber B office shape).
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city,
   description, seats, normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT '9476ec1c-9e60-4dae-b398-c81c63f6f670',
       'eeabd028-35b3-4aae-97ec-0fba4c829c00',
       'bb6bdc6a-b2a5-4587-aa41-b616c903edd8',
       'Councilmember', 'CA', 'Santa Clarita', '', 0, 'Council Member', '', '',
       false, false, false
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
      AND o.politician_id = '9476ec1c-9e60-4dae-b398-c81c63f6f670');

-- Part B — Miranda office in Chamber B (guarded). Plain Councilmember (his old "Mayor" framing
-- was a past rotational mayor — current rotational Mayor is Weste; D-05).
INSERT INTO essentials.offices
  (politician_id, chamber_id, district_id, title, representing_state, representing_city,
   description, seats, normalized_position_name, partisan_type, salary,
   is_appointed_position, is_vacant, faces_retention_vote)
SELECT '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9',
       'eeabd028-35b3-4aae-97ec-0fba4c829c00',
       'bb6bdc6a-b2a5-4587-aa41-b616c903edd8',
       'Councilmember', 'CA', 'Santa Clarita', '', 0, 'Council Member', '', '',
       false, false, false
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
      AND o.politician_id = '069fc0f2-d1eb-4fac-828a-3d9030d4f2a9');

-- Back-fill politicians.office_id for both reseated members (robust to fresh-insert or re-run).
UPDATE essentials.politicians p
   SET office_id = o.id
  FROM essentials.offices o
 WHERE o.chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND o.politician_id = p.id
   AND p.external_id IN (-201394, -200980)
   AND p.office_id IS DISTINCT FROM o.id;

-- Part C — flag the current rotational Mayor on Weste's (665693) existing council seat (D-05).
UPDATE essentials.offices
   SET title = 'Mayor'
 WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = 665693)
   AND chamber_id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND title <> 'Mayor';

-- Part D — Chamber B official_count = 5.
UPDATE essentials.chambers
   SET official_count = 5
 WHERE id = 'eeabd028-35b3-4aae-97ec-0fba4c829c00'
   AND official_count IS DISTINCT FROM 5;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('895')
ON CONFLICT (version) DO NOTHING;

COMMIT;
