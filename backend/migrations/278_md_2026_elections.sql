-- Migration 278: MD 2026 Elections — Phase 96 Plan 01
-- Seeds the two MD 2026 election rows that all downstream race rows (Plans 96-02, 96-03) reference.
-- D-02: The primary row is bare (no races link to it); all races link to the general election only.
-- NOTE: MD primary date verified at elections.maryland.gov as 2026-06-23 (correcting July 14 from CONTEXT.md).
-- Idempotent via ON CONFLICT (name, election_date, state) DO NOTHING.

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Maryland State Primary', '2026-06-23', 'primary', 'state', 'MD')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Maryland General Election', '2026-11-03', 'general', 'state', 'MD')
ON CONFLICT (name, election_date, state) DO NOTHING;
