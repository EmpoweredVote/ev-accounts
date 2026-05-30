-- Migration 103: Texas statewide and federal officials
-- Adds Ted Cruz & John Cornyn (US Senators) + TX executive branch so they appear
-- when browsing any Texas government-list area (e.g. Collin County).
--
-- Verify current officeholders at texas.gov before re-running.
-- Negative external_ids are synthetic placeholders pending VoteSmart linkage.

BEGIN;

-- ── US Senate – Texas ──────────────────────────────────────────────────────────
-- Uses shared "U.S. Senate" chamber (7cbe07bc) under United States Federal Government (0a6b51aa)

WITH
  ins_district AS (
    INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
    VALUES (gen_random_uuid(), 'NATIONAL_UPPER', 'TX', '48', 'Texas', 'Texas', '')
    RETURNING id
  ),
  ins_cruz AS (
    INSERT INTO essentials.politicians
      (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
    VALUES (gen_random_uuid(), 'Ted Cruz', 'Ted', 'Cruz', 'Republican', true, false, false, true, -100200)
    RETURNING id
  ),
  ins_cornyn AS (
    INSERT INTO essentials.politicians
      (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
    VALUES (gen_random_uuid(), 'John Cornyn', 'John', 'Cornyn', 'Republican', true, false, false, true, -100201)
    RETURNING id
  )
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT gen_random_uuid(), d.id, '7cbe07bc-84b8-433b-952b-540e7de18a92', p.id, 'Senator', 'TX', false, false
FROM ins_district d, ins_cruz p
UNION ALL
SELECT gen_random_uuid(), d.id, '7cbe07bc-84b8-433b-952b-540e7de18a92', p.id, 'Senator', 'TX', false, false
FROM ins_district d, ins_cornyn p;

-- ── Texas Executive Branch ─────────────────────────────────────────────────────
-- government_id 8aea8ed7 = State of Texas

WITH
  ins_chambers AS (
    INSERT INTO essentials.chambers (id, name, name_formal, government_id)
    VALUES
      (gen_random_uuid(), 'Texas Governor',                 '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'),
      (gen_random_uuid(), 'Texas Lieutenant Governor',      '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'),
      (gen_random_uuid(), 'Texas Attorney General',         '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'),
      (gen_random_uuid(), 'Texas Comptroller',              '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'),
      (gen_random_uuid(), 'Texas Land Commissioner',        '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'),
      (gen_random_uuid(), 'Texas Agriculture Commissioner', '', '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9')
    RETURNING id, name
  ),
  ins_districts AS (
    INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
    VALUES
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Governor',                 '', ''),
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Lieutenant Governor',      '', ''),
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Attorney General',         '', ''),
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Comptroller',              '', ''),
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Land Commissioner',        '', ''),
      (gen_random_uuid(), 'STATE_EXEC', 'TX', '48', 'Texas Agriculture Commissioner', '', '')
    RETURNING id, label
  ),
  ins_politicians AS (
    INSERT INTO essentials.politicians
      (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
    VALUES
      (gen_random_uuid(), 'Greg Abbott',       'Greg',  'Abbott',     'Republican', true, false, false, true, -100202),
      (gen_random_uuid(), 'Dan Patrick',       'Dan',   'Patrick',    'Republican', true, false, false, true, -100203),
      (gen_random_uuid(), 'Ken Paxton',        'Ken',   'Paxton',     'Republican', true, false, false, true, -100204),
      (gen_random_uuid(), 'Glenn Hegar',       'Glenn', 'Hegar',      'Republican', true, false, false, true, -100205),
      (gen_random_uuid(), 'Dawn Buckingham',   'Dawn',  'Buckingham', 'Republican', true, false, false, true, -100206),
      (gen_random_uuid(), 'Sid Miller',        'Sid',   'Miller',     'Republican', true, false, false, true, -100207)
    RETURNING id, full_name
  )
INSERT INTO essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state, is_appointed_position, is_vacant)
SELECT
  gen_random_uuid(),
  dist.id,
  ch.id,
  pol.id,
  ch.name,
  'TX',
  false,
  false
FROM (VALUES
  ('Greg Abbott',       'Texas Governor'),
  ('Dan Patrick',       'Texas Lieutenant Governor'),
  ('Ken Paxton',        'Texas Attorney General'),
  ('Glenn Hegar',       'Texas Comptroller'),
  ('Dawn Buckingham',   'Texas Land Commissioner'),
  ('Sid Miller',        'Texas Agriculture Commissioner')
) AS mapping(pol_name, office_name)
JOIN ins_politicians pol  ON pol.full_name  = mapping.pol_name
JOIN ins_districts   dist ON dist.label     = mapping.office_name
JOIN ins_chambers    ch   ON ch.name        = mapping.office_name;

COMMIT;
