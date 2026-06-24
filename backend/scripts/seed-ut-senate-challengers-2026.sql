-- Seed politician records for 2026 Utah State Senate challengers
-- and link them to existing race_candidates rows.
--
-- These are candidates with no current office who filed for the
-- June 23, 2026 primary. Creating a politician record per person
-- allows compass stances to attach via inform.politician_answers.
--
-- Idempotent: INSERT … ON CONFLICT (full_name, office_id) skipped;
-- UPDATE race_candidates is safe to re-run.

BEGIN;

-- ── Step 1: Insert politician records for challengers ─────────────────────
-- We use a CTE to emit a deterministic UUID per person so re-runs are stable.

INSERT INTO essentials.politicians (
  id, full_name, first_name, last_name,
  is_incumbent, is_active, data_source, created_at
)
VALUES
  -- District 9
  (gen_random_uuid(), 'Thaddeus A. Evans',  'Thaddeus', 'Evans',   false, true, 'sos_filing', now()),
  -- District 11
  (gen_random_uuid(), 'Brooks Benson',      'Brooks',   'Benson',  false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'MacKenzie Miller',   'MacKenzie','Miller',  false, true, 'sos_filing', now()),
  -- District 12
  (gen_random_uuid(), 'Deidre Tyler',       'Deidre',   'Tyler',   false, true, 'sos_filing', now()),
  -- District 13
  (gen_random_uuid(), 'Evan Done',          'Evan',     'Done',    false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'Ryan L. Mahoney',    'Ryan',     'Mahoney', false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'Silvia Catten',      'Silvia',   'Catten',  false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'Taylor J. Paden',    'Taylor',   'Paden',   false, true, 'sos_filing', now()),
  -- District 14
  (gen_random_uuid(), 'Tayler Khater',      'Tayler',   'Khater',  false, true, 'sos_filing', now()),
  -- District 18
  (gen_random_uuid(), 'A. Dane Anderson',   'Dane',     'Anderson',false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'Doug Fiefia',        'Doug',     'Fiefia',  false, true, 'sos_filing', now()),
  -- District 19
  (gen_random_uuid(), 'Shana Anderson',     'Shana',    'Anderson',false, true, 'sos_filing', now()),
  -- District 21
  (gen_random_uuid(), 'Kandee Myers',       'Kandee',   'Myers',   false, true, 'sos_filing', now()),
  (gen_random_uuid(), 'Kelly Smith',        'Kelly',    'Smith',   false, true, 'sos_filing', now()),
  -- District 23
  (gen_random_uuid(), 'Tucker Smith',       'Tucker',   'Smith',   false, true, 'sos_filing', now())
ON CONFLICT DO NOTHING;

-- ── Step 2: Link race_candidates → new politician records ─────────────────
-- Each UPDATE resolves the politician_id by name so it survives re-runs
-- (gen_random_uuid() above means UUIDs differ on re-run, but ON CONFLICT
--  DO NOTHING means the first-run rows win and the name lookup stays stable).

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'bd093c55-289a-4a0e-8631-1337bf4cf54a'  -- Thaddeus A. Evans, D9
  AND p.full_name = 'Thaddeus A. Evans'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'fbd312e1-fd19-414c-bacd-b4e221e7eacf'  -- Brooks Benson, D11
  AND p.full_name = 'Brooks Benson'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'f0305322-56c7-4f7c-a65f-e270dbdd13e3'  -- MacKenzie Miller, D11
  AND p.full_name = 'MacKenzie Miller'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '6be6baa3-758e-480a-9c9b-a0deeaaff94b'  -- Deidre Tyler, D12
  AND p.full_name = 'Deidre Tyler'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '5826d198-5408-4893-84fb-2f793c2eadef'  -- Evan Done, D13
  AND p.full_name = 'Evan Done'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'c5e9a5bc-914a-47a7-88ea-9cd8433ca2b5'  -- Ryan L. Mahoney, D13
  AND p.full_name = 'Ryan L. Mahoney'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'e059c6a4-c26f-4145-bd60-83474e09cd49'  -- Silvia Catten, D13
  AND p.full_name = 'Silvia Catten'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'a94dc189-8c69-4747-bbc7-a17172e9e191'  -- Taylor J. Paden, D13
  AND p.full_name = 'Taylor J. Paden'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'b2c821dc-d587-4057-a091-45a2c3f46f4e'  -- Tayler Khater, D14
  AND p.full_name = 'Tayler Khater'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '53fffcc2-ef34-489a-93c3-03ee721a8f83'  -- A. Dane Anderson, D18
  AND p.full_name = 'A. Dane Anderson'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '61d64fe3-0153-4d65-96dc-7577e75cb04f'  -- Doug Fiefia, D18
  AND p.full_name = 'Doug Fiefia'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = 'f68d56f9-d26d-4805-a860-2c483d676148'  -- Shana Anderson, D19
  AND p.full_name = 'Shana Anderson'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '4820a0ca-1466-4557-bb1e-985191720e2d'  -- Kandee Myers, D21
  AND p.full_name = 'Kandee Myers'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '7bb08b5f-4ec6-4a5c-9553-75bd7918eb55'  -- Kelly Smith, D21
  AND p.full_name = 'Kelly Smith'
  AND rc.politician_id IS NULL;

UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.id = '3b72c539-686f-4cf0-82c4-98aaac54b883'  -- Tucker Smith, D23
  AND p.full_name = 'Tucker Smith'
  AND rc.politician_id IS NULL;

-- ── Verification ─────────────────────────────────────────────────────────
-- SELECT rc.id, rc.full_name, rc.politician_id, rc.is_incumbent
-- FROM essentials.race_candidates rc
-- JOIN essentials.races r ON r.id = rc.race_id
-- JOIN essentials.elections e ON e.id = r.election_id
-- WHERE e.name = '2026 Utah Primary'
--   AND r.position_name ILIKE '%State Senate%'
-- ORDER BY r.position_name, rc.full_name;

COMMIT;
