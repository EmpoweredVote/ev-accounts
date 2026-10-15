-- CA_0309_merge_atoosa_reaser_duplicate_row.sql
-- Merge the DUPLICATE row of Atoosa Reaser (VA House of Delegates, District 27) into her seated row, and deactivate the
-- duplicate. Same pattern as CA_0261: the SEATED row is the person and holds the Season 1 answers; what hangs on the
-- duplicate moves to it; nothing is deleted and no answer row is touched.
--
-- Slot CA_0309 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- ✅ APPLIED to prod 2026-10-14 (approval Chris Andrews): both gates green; duplicate inactive, term on the seated row.
--
-- THE PAIR (duplicate -> seated twin):
--   8e42053a-a353-5dae-9a43-f2afc09eb1ec "Atoosa Reaser" (created 2026-10-14 by CA_0308's school-board sweep; no answers,
--     no images, no race rows; one ended Loudoun County School Board term) ->
--   b8856cc7-d711-436d-96b3-f0cbd352350a "Atoosa R. Reaser" (external_id -5120027; holds the Delegate seat, State House
--     District 27; 3 answers + 3 context rows + 1 image).
--   One person: Wikipedia and Ballotpedia both give her Loudoun County School Board service (Algonkian District, 2020 to
--   2023-12-31) followed by the Virginia House of Delegates, 27th District, from 2024-01-10. CA_0308's own term note says
--   "left Dec 31 2023 (elected to VA House of Delegates)".
--
-- WHAT MOVES: the one office_terms row 865552cb (School Board Member, Algonkian District, 2020-01-01 to 2023-12-31).
-- NOT CHANGED: the twin's first_name "Atoosa R." (middle initial in the given name; a separate sweep), her seat, answers,
--   context, image, is_incumbent.
-- THEN: the duplicate is deactivated (is_active = false, is_incumbent stays false) with a note naming its twin.
--
-- ROLLBACK: set office_terms 865552cb back to politician_id 8e42053a-a353-5dae-9a43-f2afc09eb1ec and re-activate that
-- politician row, removing its CA_0309 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians k
    JOIN essentials.office_current_holder och ON och.politician_id = k.id
   WHERE k.id = 'b8856cc7-d711-436d-96b3-f0cbd352350a' AND k.full_name = 'Atoosa R. Reaser' AND k.is_active
     AND k.is_incumbent AND och.office_id = 'bff77f13-9638-4f9c-8857-b87f918beee8';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin is not the active holder of the District 27 Delegate seat'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec' AND d.full_name = 'Atoosa Reaser' AND NOT d.is_incumbent;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate missing, renamed, or incumbent'; END IF;

  -- the duplicate holds exactly the one reviewed term (on it, or already moved), and nothing else this file ignores
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE id = '865552cb-db3a-4c88-bbe2-d70d87dbfc8a' AND office_id = '6895c14e-b7c5-5ca0-a730-28c8cc636724'
     AND politician_id IN ('8e42053a-a353-5dae-9a43-f2afc09eb1ec', 'b8856cc7-d711-436d-96b3-f0cbd352350a');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the school-board term is not in its reviewed state'; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec'
     AND id <> '865552cb-db3a-4c88-bbe2-d70d87dbfc8a';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other terms on the duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers  WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answers on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context  WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % context rows on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race rows on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % images on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % source link(s) on the duplicate; this file moves none', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = 'b8856cc7-d711-436d-96b3-f0cbd352350a';
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: twin has % answers, expected 3', v_n; END IF;

  RAISE NOTICE 'CA_0309 pre-flight OK';
END $$;

-- ─── 1. Move the ended school-board term to the seated twin ──────────────────────────────────────
UPDATE essentials.office_terms SET politician_id = 'b8856cc7-d711-436d-96b3-f0cbd352350a'
 WHERE id = '865552cb-db3a-4c88-bbe2-d70d87dbfc8a' AND politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';

-- ─── 2. Deactivate the duplicate ─────────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0309 (2026-10-14): DUPLICATE of b8856cc7-d711-436d-96b3-f0cbd352350a '
               || '(Atoosa R. Reaser), the row that holds the District 27 Delegate seat. Its ended Loudoun school-board term '
               || 'moved there; deactivated, not deleted.')::text
 WHERE d.id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec' AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec' AND NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0309 (2026-10-14): DUPLICATE of%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate not deactivated with the note'; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id = '8e42053a-a353-5dae-9a43-f2afc09eb1ec';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % terms still on the duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE politician_id = 'b8856cc7-d711-436d-96b3-f0cbd352350a'
     AND id IN ('865552cb-db3a-4c88-bbe2-d70d87dbfc8a', 'df3d47df-56c2-49f5-b6cf-641213a9eb1b');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 terms on the twin', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.office_current_holder
   WHERE politician_id = 'b8856cc7-d711-436d-96b3-f0cbd352350a' AND office_id = 'bff77f13-9638-4f9c-8857-b87f918beee8';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin no longer holds the District 27 seat'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = 'b8856cc7-d711-436d-96b3-f0cbd352350a';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: twin has % answers, expected 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = 'b8856cc7-d711-436d-96b3-f0cbd352350a' AND is_active AND is_incumbent;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin flags changed'; END IF;

  RAISE NOTICE 'CA_0309 applied: duplicate deactivated; school-board term on the seated twin';
END $$;

COMMIT;
