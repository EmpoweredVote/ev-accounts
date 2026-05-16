-- Migration 155: MA US Senators (Warren + Markey, NATIONAL_UPPER)
--
-- Both senators link to:
-- - Shared chamber: 7cbe07bc-84b8-433b-952b-540e7de18a92 (U.S. Senate — already exists)
-- - Shared district: NATIONAL_UPPER + state='MA' (created by Plan 40-01, migration 154)
--
-- external_ids:
-- - Elizabeth Warren: -200101
-- - Edward J. Markey: -200102
--
-- Office uniqueness key: (district_id, politician_id) — district is shared but
-- politician_id makes each office row unique.
--
-- Idempotent: ON CONFLICT (external_id) DO NOTHING on politicians,
-- NOT EXISTS guard on offices.

BEGIN;

-- ----- Elizabeth Warren (-200101) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Elizabeth Warren', 'Elizabeth', 'Warren', 'Democrat',
          true, false, false, true, -200101)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ----- Edward J. Markey (-200102) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Edward J. Markey', 'Edward', 'Markey', 'Democrat',
          true, false, false, true, -200102)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'MA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'MA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- ===== office_id back-fill =====
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -200110 AND -200101
  AND p.office_id IS NULL;

COMMIT;
