-- =============================================================================
-- Migration 1404: Seat Gopal Ponangi as Frisco Place 4 (retire loser Jared Elad)
-- Frisco (4827684, Collin/Denton Co)
-- (Phase 219 follow-up — operator-approved seating correction, 2026-07-24)
--
-- Corrects a data error: the DB seated Jared Elad as Frisco City Council Place 4,
-- but the official Collin County June 7, 2025 runoff canvass (double-verified:
-- all-races xlsx export + official-final summary PDF) shows GOPAL PONANGI WON the
-- runoff 3,826-3,274 (53.89%-46.11%) — Elad LOST. Migration 1403 already seeded
-- the runoff RACE correctly (Ponangi winner, Elad loser). This migration performs
-- the officeholder correction: inserts Ponangi as Place 4's holder, points the
-- office at him, retires Elad (is_active=false, detached, valid_to = runoff date),
-- and links Ponangi's existing name-only race_candidate row (migration 1403 runoff
-- race) to his new politician_id. Same idiom as migration 1400 (Longview D3
-- Smith/Wade). Term modeled on Frisco's 3-year cycle (elected 2025 -> ~2028).
--
-- Sources: collincountytx.gov June-7-2025 Runoff official-final summary PDF +
-- all-races xlsx export. Idempotent: skip-if-already-Ponangi; race link guarded
-- politician_id IS NULL; Elad retirement guarded on his captured id.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_office_id   UUID;
  v_holder_id   UUID;
  v_holder_name TEXT;
  v_ponangi_id  UUID;
BEGIN
  SELECT o.id, o.politician_id, p.full_name
    INTO v_office_id, v_holder_id, v_holder_name
  FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1404: Frisco (4827684) Council Member Place 4 office not found — aborting';
  END IF;

  IF v_holder_name = 'Gopal Ponangi' THEN
    v_ponangi_id := v_holder_id;
    RAISE NOTICE 'Migration 1404: Frisco Place 4 already seated to Gopal Ponangi (%) — skipping seat', v_ponangi_id;
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Gopal', 'Ponangi', 'Gopal', 'Gopal Ponangi',
      NULL, NULL,
      true, false, false, false,
      v_office_id, '2025-06-01', '2028-05-01', 'month',
      NULL,
      ARRAY['https://www.collincountytx.gov/Elections/election-results-archive'],
      'collincountytx.gov June-7-2025 Runoff official-final canvass (Ponangi 3826 def Elad 3274, 53.89%)'
    ) RETURNING id INTO v_ponangi_id;

    UPDATE essentials.offices SET politician_id = v_ponangi_id WHERE id = v_office_id;

    IF v_holder_id IS NOT NULL THEN
      UPDATE essentials.politicians
         SET is_active = false, is_incumbent = false, is_vacant = false,
             office_id = NULL, valid_to = '2025-06-07', term_date_precision = 'day'
       WHERE id = v_holder_id;
      RAISE NOTICE 'Migration 1404: retired Frisco Place 4 loser % (Jared Elad)', v_holder_id;
    END IF;

    RAISE NOTICE 'Migration 1404: seated Gopal Ponangi (Frisco Place 4) — %', v_ponangi_id;
  END IF;

  -- Link Ponangi's existing name-only race_candidate row (migration 1403 runoff
  -- race) to his politician_id. Guarded IS NULL so re-run is net-zero.
  UPDATE essentials.race_candidates rc
     SET politician_id = v_ponangi_id
   WHERE rc.full_name = 'Gopal Ponangi'
     AND rc.politician_id IS NULL
     AND rc.race_id IN (SELECT r.id FROM essentials.races r WHERE r.office_id = v_office_id);

END $$;

COMMIT;
