-- =============================================================================
-- Migration 1409: CORRECT Frisco Place 4 — seat winner Jared Elad, retire Ponangi
-- Frisco (4827684, Collin/Denton Co)
-- (Phase 220 Wave-1 checkpoint resolution — operator-approved 2026-07-24)
--
-- REVERSES migration 1404, which seated Gopal Ponangi as Place 4 based on the
-- COLLIN COUNTY-ONLY runoff canvass (Ponangi 3,826 vs Elad 3,274). Frisco spans
-- BOTH Collin and Denton counties; the COMBINED June 7, 2025 runoff result shows
-- JARED ELAD WON 7,162-6,434 (52.68%) — reported by Community Impact, KERA, and
-- Frisco's own official site. Migration 1404 scored a two-county race on one
-- county's partial canvass and seated the loser. This migration restores the
-- correct officeholder and seeds Elad's sourced email.
--
-- Actions (idempotent, skip-if-already-Elad):
--   1. Reactivate Jared Elad (id 5d8acfc7…), point Place 4 office at him,
--      term 2025-06 -> 2028-05 (elected 2025, expires May 2028 per city bio).
--   2. Retire Gopal Ponangi (id d6e0d762…): is_active=false, office_id=NULL,
--      valid_to = runoff date 2025-06-07 (he lost the combined race).
--   3. Seed Elad's sourced email jelad@friscotexas.gov (Cloudflare-decoded from
--      friscotexas.gov/1970/Jared-Elad-Place-4).
--   4. Relink Elad's runoff race_candidate row to his politician_id.
--
-- Sources: communityimpact.com/dallas-fort-worth/frisco/election/2025/06/07/
-- (Elad 7,162 / 52.68% def Ponangi 6,434, combined Collin+Denton); KERA;
-- friscotexas.gov/1970/Jared-Elad-Place-4 (term + email). Same idiom as mig 1404.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_office_id   UUID;
  v_holder_id   UUID;
  v_holder_name TEXT;
  v_elad_id     UUID := '5d8acfc7-5643-418b-a474-3d87898f4e17';
  v_ponangi_id  UUID := 'd6e0d762-f7a2-4566-8718-452e4c33781b';
BEGIN
  SELECT o.id, o.politician_id, p.full_name
    INTO v_office_id, v_holder_id, v_holder_name
  FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1409: Frisco (4827684) Council Member Place 4 office not found — aborting';
  END IF;

  IF v_holder_name = 'Jared Elad' THEN
    RAISE NOTICE 'Migration 1409: Frisco Place 4 already seated to Jared Elad (%) — skipping seat', v_elad_id;
  ELSE
    -- Reactivate the winner (Elad) and point the office at him.
    UPDATE essentials.politicians
       SET is_active = true, is_incumbent = false, is_vacant = false, is_appointed = false,
           office_id = v_office_id,
           valid_from = '2025-06-01', valid_to = '2028-05-01', term_date_precision = 'month',
           data_source = 'communityimpact.com + KERA + friscotexas.gov June-7-2025 runoff COMBINED Collin+Denton (Elad 7162 def Ponangi 6434, 52.68%); corrects mig 1404 Collin-only canvass error'
     WHERE id = v_elad_id;

    UPDATE essentials.offices SET politician_id = v_elad_id WHERE id = v_office_id;

    -- Retire the loser (Ponangi) — mistakenly seated by mig 1404.
    UPDATE essentials.politicians
       SET is_active = false, is_incumbent = false, is_vacant = false,
           office_id = NULL, valid_to = '2025-06-07', term_date_precision = 'day'
     WHERE id = v_ponangi_id;

    RAISE NOTICE 'Migration 1409: seated Jared Elad (%), retired Gopal Ponangi (%)', v_elad_id, v_ponangi_id;
  END IF;

  -- Seed Elad's sourced email (idempotent; his row currently has none).
  UPDATE essentials.politicians
     SET email_addresses = ARRAY['jelad@friscotexas.gov']
   WHERE id = v_elad_id
     AND (email_addresses IS NULL OR NOT ('jelad@friscotexas.gov' = ANY(email_addresses)));

  -- Relink Elad's existing name-only runoff race_candidate row (guarded IS NULL).
  UPDATE essentials.race_candidates rc
     SET politician_id = v_elad_id
   WHERE rc.full_name = 'Jared Elad'
     AND rc.politician_id IS NULL
     AND rc.race_id IN (SELECT r.id FROM essentials.races r WHERE r.office_id = v_office_id);

END $$;

COMMIT;
