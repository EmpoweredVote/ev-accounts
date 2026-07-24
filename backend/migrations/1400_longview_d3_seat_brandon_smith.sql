-- =============================================================================
-- Migration 1400: Seat Brandon Smith as Longview District 3 (retire hold-over Wray Wade)
-- Longview (4843888, Gregg Co)
-- (Phase 219 follow-up — operator-approved officeholder seating, 2026-07-24)
--
-- Closes the Longview D3 seating gap surfaced (not resolved) by migration 1397:
-- offices.politician_id for Council Member District 3 still reflected hold-over
-- Wray Wade despite Brandon Smith's confirmed June 13, 2026 runoff win (223-204,
-- 52.22%). Per operator decision this migration performs the Phase-218-style
-- seating action that 1397 deliberately deferred: it inserts Brandon Smith as the
-- current officeholder, points the D3 office at him, retires Wade's hold-over
-- record (is_active=false, detached from the office, valid_to = runoff date), and
-- links Smith's existing name-only race_candidate rows (the migration-1397 general
-- race + the migration-187 runoff race) to his new politician_id so his profile /
-- any future headshot carries through the FK.
--
-- Sources: Longview News-Journal "Brandon Smith wins District 3 seat on Longview
-- City Council" (2026-06-13); Ballotpedia Brandon Smith (Longview City Council
-- District 3, Texas, candidate 2026). Term modeled on Longview's 3-year May cycle
-- (D4/Nustad precedent, migration 185: elected 2026 → term expires 2029); Smith
-- seated after the June runoff, so valid_from is June 2026 (month precision).
--
-- Idempotent: if the D3 office already points to a "Brandon Smith" politician the
-- seating is skipped (RAISE NOTICE). The race_candidate link-up is guarded
-- `politician_id IS NULL`, so a re-run affects 0 rows. Wade's retirement UPDATE is
-- guarded on his specific id captured before the office pointer is moved.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_office_id     UUID;
  v_holder_id     UUID;
  v_holder_name   TEXT;
  v_smith_id      UUID;
BEGIN
  -- Resolve the D3 office + its current holder.
  SELECT o.id, o.politician_id, p.full_name
    INTO v_office_id, v_holder_id, v_holder_name
  FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE g.geo_id = '4843888' AND o.title = 'Council Member District 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1400: Longview (4843888) Council Member District 3 office not found — aborting';
  END IF;

  IF v_holder_name = 'Brandon Smith' THEN
    -- Already seated (idempotent re-run). Reuse the existing id for the link-up.
    v_smith_id := v_holder_id;
    RAISE NOTICE 'Migration 1400: Longview D3 already seated to Brandon Smith (%) — skipping seat', v_smith_id;
  ELSE
    -- Insert Brandon Smith as the newly-elected D3 officeholder.
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Brandon', 'Smith', 'Brandon', 'Brandon Smith',
      NULL, NULL,
      true, false, false, false,
      v_office_id, '2026-06-01', '2029-05-01', 'month',
      NULL,
      ARRAY['https://www.longviewtexas.gov/3308/City-Election-Results'],
      'Longview News-Journal (2026-06-13, "Brandon Smith wins District 3 seat on Longview City Council"); Ballotpedia'
    ) RETURNING id INTO v_smith_id;

    -- Point the office at Smith.
    UPDATE essentials.offices SET politician_id = v_smith_id WHERE id = v_office_id;

    -- Retire the hold-over (Wray Wade): mark inactive and detach from the office so
    -- he no longer renders as a current D3 holder. valid_to = runoff date.
    IF v_holder_id IS NOT NULL THEN
      UPDATE essentials.politicians
         SET is_active = false, is_incumbent = false, is_vacant = false,
             office_id = NULL, valid_to = '2026-06-13', term_date_precision = 'day'
       WHERE id = v_holder_id;
      RAISE NOTICE 'Migration 1400: retired Longview D3 hold-over % (Wray Wade)', v_holder_id;
    END IF;

    RAISE NOTICE 'Migration 1400: seated Brandon Smith (Longview D3) — %', v_smith_id;
  END IF;

  -- Link Smith's existing name-only race_candidate rows (general race, migration
  -- 1397; runoff race, migration 187) to his politician_id. Guarded IS NULL so a
  -- re-run is net-zero. Scoped to races on the D3 office.
  UPDATE essentials.race_candidates rc
     SET politician_id = v_smith_id
   WHERE rc.full_name = 'Brandon Smith'
     AND rc.politician_id IS NULL
     AND rc.race_id IN (SELECT r.id FROM essentials.races r WHERE r.office_id = v_office_id);

END $$;

COMMIT;
