-- Migration 237: OR 2026 Elections — Phase 79 Plan 01
-- Seeds the two OR 2026 election rows that all downstream race rows (Plans 79-02, 79-03, 79-04) reference.
-- D-03: The primary row is bare (no races link to it); all races link to the general election only.
-- Idempotent via ON CONFLICT (name, election_date, state) DO NOTHING.

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('OR 2026 Primary', '2026-05-19', 'primary', 'state', 'OR')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('OR 2026 General', '2026-11-03', 'general', 'state', 'OR')
ON CONFLICT (name, election_date, state) DO NOTHING;
