-- Migration 322: VA 2026 Elections — Phase 105 Plan 01
-- Seeds the two VA 2026 election rows that all downstream race rows (Plans 105-02, 105-03) reference.
-- NOTE: The primary row is bare (no races link to it); all races link to the general election only.
-- Both dates verified from ROADMAP and STATE.md: primary 2026-08-04, general 2026-11-03.
-- Idempotent via ON CONFLICT (name, election_date, state) DO NOTHING.

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Virginia State Primary', '2026-08-04', 'primary', 'state', 'VA')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Virginia General Election', '2026-11-03', 'general', 'state', 'VA')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('322')
ON CONFLICT (version) DO NOTHING;
