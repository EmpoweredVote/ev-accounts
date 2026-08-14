-- 1742_wa_legislature_structure.sql
-- Washington State Legislature: 2 chambers + 147 offices.
--
-- Seattle deep seed, Task 2. Depends on the WA TIGER load (Task 1), which
-- ALREADY created all 98 essentials.districts rows (writeDistrictRow=true for
-- sldu/sldl). This migration therefore creates CHAMBERS and OFFICES ONLY —
-- it must not insert districts.
--
-- Confirmed facts (verified against the database 2026-08-13):
--   * MTFCC orientation is INVERTED vs a plain TIGER reading:
--       STATE_UPPER (Senate) = G5210,  STATE_LOWER (House) = G5220.
--     Verified by loader config AND independently by the boundary names
--     ("Legislative (Senate) District 34" carries mtfcc G5210).
--   * geo_id is NOT unique across MTFCCs: '53001' is Adams County (G4020),
--     LD 1 Senate (G5210) and LD 1 House (G5220) simultaneously. Every join
--     below keys on (district_type, mtfcc, state) — never geo_id alone.
--   * districts.state = 'wa' (LOWERCASE).
--
-- WA is MULTI-MEMBER: 49 legislative districts, each electing ONE senator and
-- TWO representatives over the SAME boundary. 49 + 98 = 147 offices.
-- The two House seats are distinguished as Position 1 and Position 2 with
-- SEPARATE ballot lines (unlike AZ, where both seats run at-large within the
-- district and correctly share an identical title).
--
-- Idempotency: essentials.offices has NO unique index beyond the pkey, so all
-- inserts use NOT EXISTS, never ON CONFLICT. The House guard keys on
-- (district_id, title) — keying on (district_id, chamber_id) would make
-- Position 2 a silent no-op and land 49 offices instead of 98 (the Maryland
-- multi-member trap).
--
-- Existing WA chambers all carry NULL external_id, so chamber idempotency keys
-- on (government_id, name) to match that convention.
--
-- chambers.slug is a GENERATED column derived from name_formal — it cannot be
-- inserted directly. The name_formal values below generate the intended slugs.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────
-- Short-form names matching this government's existing convention ('Governor',
-- not 'Washington Governor') and matching AZ, WA's structural twin.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id,
       'State Senate',
       'Washington State Senate',   -- slug is GENERATED from name_formal => washington-state-senate
       49,
       4,      -- 4-year terms
       true,   -- STAGGERED: only ~half the 49 seats appear on any even-year ballot
       'full'
FROM essentials.governments g
WHERE g.state = 'WA' AND g.geo_id = '53'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'State Senate'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id,
       'House of Representatives',
       'Washington House of Representatives',  -- slug GENERATED => washington-house-of-representatives
       98,
       2,      -- 2-year terms; ALL 98 seats up every even year
       false,
       'full'
FROM essentials.governments g
WHERE g.state = 'WA' AND g.geo_id = '53'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'House of Representatives'
  );

-- ─── Senate offices: 49, one per STATE_UPPER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position)
SELECT c.id, d.id, 'State Senator', 'WA', false
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'WA' AND g.geo_id = '53' AND ch.name = 'State Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND d.state ILIKE 'wa'
  AND d.mtfcc = 'G5210'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'State Senator'
  );

-- ─── House offices: 98 = 49 districts x 2 positions ──────────────────────────
-- The NOT EXISTS guard keys on (district_id, title). Keying it on
-- (district_id, chamber_id) instead is the Maryland trap: Position 2 becomes a
-- silent no-op in every district and the migration lands 49 rows, not 98.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position)
SELECT c.id, d.id, 'State Representative (Position ' || p.pos || ')', 'WA', false
FROM essentials.districts d
CROSS JOIN (SELECT 1 AS pos UNION ALL SELECT 2) p
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'WA' AND g.geo_id = '53' AND ch.name = 'House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND d.state ILIKE 'wa'
  AND d.mtfcc = 'G5220'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.title = 'State Representative (Position ' || p.pos || ')'
  );

COMMIT;
