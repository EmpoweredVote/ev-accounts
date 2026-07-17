-- Migration 1372: AZ 2026 Statewide Primary election row
-- Phase 199 (AZ 2026 Elections & Discovery), Plan 01.
--
-- Seeds the BARE AZ 2026 Statewide Primary election row. This row is intentionally
-- bare: NO races link to it. ALL 2026 AZ race shells (Plans 02/03) anchor to the
-- pre-existing "AZ 2026 Statewide General" (2026-11-03, e21f5757-071e-4851-9c06-83520d96460e),
-- mirroring the VA Plan-01 lesson. The primary row exists so the discovery date-window
-- (Plan 04) covers both election dates.
--
-- Primary date is 2026-07-21 (HB 2022, signed 2026-02-06) -- the corrected date.
-- It is NOT the old 2026-08-04 date.
--
-- Idempotent: ON CONFLICT (name, election_date, state) DO NOTHING makes re-apply a no-op.

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('AZ 2026 Statewide Primary', '2026-07-21', 'primary', 'state', 'AZ')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- Post-verify: the primary row exists at the corrected date, and the general
-- election FK anchor (the target of all downstream race shells) is present.
DO $$
DECLARE
  v_primary_date date;
  v_general_ct   int;
  v_az_ct        int;
BEGIN
  SELECT election_date INTO v_primary_date
  FROM essentials.elections
  WHERE name = 'AZ 2026 Statewide Primary' AND state = 'AZ';

  IF v_primary_date IS DISTINCT FROM DATE '2026-07-21' THEN
    RAISE EXCEPTION 'Migration 1372: AZ primary row missing or wrong date (got %, expected 2026-07-21)', v_primary_date;
  END IF;

  SELECT COUNT(*) INTO v_general_ct
  FROM essentials.elections
  WHERE name = 'AZ 2026 Statewide General' AND state = 'AZ';

  IF v_general_ct <> 1 THEN
    RAISE EXCEPTION 'Migration 1372: general election FK anchor missing (expected 1, got %)', v_general_ct;
  END IF;

  SELECT COUNT(*) INTO v_az_ct FROM essentials.elections WHERE state = 'AZ';
  IF v_az_ct <> 2 THEN
    RAISE EXCEPTION 'Migration 1372: AZ election count = % (expected 2)', v_az_ct;
  END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1372') ON CONFLICT (version) DO NOTHING;
