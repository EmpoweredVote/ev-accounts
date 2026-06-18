-- Migration 777: Beverly Hills rotational-Mayor title correction (Friedman -> Corman)
-- BH uses a rotational mayor; Craig Corman has been Mayor since Apr 14, 2026 (succeeding Nazarian,
-- who succeeded Friedman). The v7.0 seed froze Friedman in the "Mayor" office. Swap the two
-- occupants so the title reflects reality: Corman -> Mayor office, Friedman -> Council Member office.
-- Stances are keyed by politician_id and are unaffected. Reversible.
-- (Full BH reorg — Mirisch's seat turns over after the June-2-2026 election installs ~July 7 —
--  remains a separate pending follow-up.)
--
-- Mayor office (LOCAL_EXEC):    f7938b2e-a8db-41ef-83f6-c68dbe824b0b  (was Friedman 4f69ba91)
-- Corman's Council Member seat: 931b03bb-dcae-4869-b70c-e19031edd68d  (was Corman 1221c215)

BEGIN;

-- Corman -> Mayor office
UPDATE essentials.offices SET politician_id = '1221c215-2b80-46f7-b980-c04f25c5866f'
WHERE id = 'f7938b2e-a8db-41ef-83f6-c68dbe824b0b';

-- Friedman -> the (now-vacated) Council Member office
UPDATE essentials.offices SET politician_id = '4f69ba91-d6f4-400e-aa46-10f1706d2f3c'
WHERE id = '931b03bb-dcae-4869-b70c-e19031edd68d';

-- Maintain politicians.office_id backlinks
UPDATE essentials.politicians SET office_id = 'f7938b2e-a8db-41ef-83f6-c68dbe824b0b'
WHERE id = '1221c215-2b80-46f7-b980-c04f25c5866f';  -- Corman -> Mayor office
UPDATE essentials.politicians SET office_id = '931b03bb-dcae-4869-b70c-e19031edd68d'
WHERE id = '4f69ba91-d6f4-400e-aa46-10f1706d2f3c';  -- Friedman -> Council Member office

COMMIT;
