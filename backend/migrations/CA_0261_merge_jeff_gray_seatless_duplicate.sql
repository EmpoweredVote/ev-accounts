-- CA_0261_merge_jeff_gray_seatless_duplicate.sql
-- Merge the seatless DUPLICATE row of Jeff Gray (Utah County Attorney, 2026 Republican nominee) into his seated twin,
-- and deactivate the duplicate. Same pattern as CA_0229 / CA_0234: the SEATED row is the person; what hangs on the
-- duplicate moves to it; nothing is deleted.
--
-- Slot CA_0261 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- ✅ APPLIED to prod 2026-09-24 (approval Chris Andrews): UPDATE 1 / 1, both gates green. Re-read: primary row on 6b16270a,
--   duplicate inactive, twin holds the seat with 2 race rows and 1 image.
--
-- THE PAIR (duplicate -> seated twin):
--   35faf7b8-4d1e-4363-b4db-3531ea3fad5e "Jeff Gray" (created 2026-06-18, data_source sos_filing; no seat, no term,
--     no answers) -> 6b16270a-c6c7-46be-9b9c-7def323dc4ef "Jeffrey S. Gray" (created 2026-05-22, ut-county-utah
--     external_id -307479; holds the Utah County Attorney seat daf1fa50; 8 compass answers + 8 context rows).
--   One person: the same office; the twin's own portrait comes from utahcounty.gov/imgs/electedOfficials/JeffGray.webp;
--   and the 2026 filings list and certified ballot print "JEFF GRAY" for that seat. Found 2026-09-24 by CA_0253 (PR #751), which already seated the November race
--   row on the twin; this file moves the one row CA_0253 left on the duplicate.
--
-- WHAT MOVES: 1 race_candidates row — the 2026-06-23 primary row 8c244f50 (Utah County Attorney, result 'won',
--   recorded by CA_0240). It keeps its own full_name "Jeff Gray" (the name he filed under) and its photo_url.
--   The race_candidate_mirror_data trigger fires on the politician_id change and writes nothing: the twin already
--   has a politician_images row and a photo_custom_url, and the race row carries no website_url.
-- NOT MOVED: the duplicate's politician_images row (the twin has its own), as in CA_0229.
-- Every other table that references a politician (all 24 FKs, plus every column named like politician_id) was
--   counted for the duplicate on 2026-09-24: race_candidates 1, politician_images 1, everything else 0. The
--   pre-flight re-checks the ones that matter.
--
-- THEN: the duplicate is deactivated (is_active = false, is_incumbent stays false) with a note naming its twin.
--
-- NOT CHANGED: the twin's last_name, which reads "S. Gray" (middle initial inside the surname). 81 active rows share
--   that defect, so it is a separate sweep, not a one-off fix here. office_terms; answers; is_incumbent of the twin.
--
-- ROLLBACK: re-point race_candidates 8c244f50-38e4-4b4e-8888-e03d4e3cfe4d back to 35faf7b8-4d1e-4363-b4db-3531ea3fad5e and set
-- that row's is_active back to true, removing its CA_0261 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the twin is active, the incumbent, and holds the Utah County Attorney seat
  SELECT count(*) INTO v_n FROM essentials.politicians k
    JOIN essentials.office_current_holder och ON och.politician_id = k.id
   WHERE k.id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef' AND k.full_name = 'Jeffrey S. Gray' AND k.is_active
     AND k.is_incumbent AND och.office_id = 'daf1fa50-abdb-4996-82ac-c0a6d55f4257';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin is not the active holder of the Utah County Attorney seat'; END IF;

  -- the duplicate is the same person's name and holds no term
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e' AND d.full_name = 'Jeff Gray' AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate missing, renamed, incumbent, or holding a term'; END IF;

  -- exactly the reviewed race rows: the primary row (on the duplicate, or already moved) and CA_0253's general row
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id IN ('35faf7b8-4d1e-4363-b4db-3531ea3fad5e', '6b16270a-c6c7-46be-9b9c-7def323dc4ef');
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % race rows across the pair, expected 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '8c244f50-38e4-4b4e-8888-e03d4e3cfe4d' AND race_id = (
           SELECT id FROM essentials.races WHERE election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
              AND position_name = 'Utah County Attorney')
     AND result = 'won';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the primary race row is not in its reviewed state'; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '8c99c328-f04c-4820-9620-bb2d5aeecfdc' AND politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: CA_0253''s general row is not on the twin'; END IF;

  -- nothing else hangs on the duplicate that this file has not reviewed
  SELECT count(*) INTO v_n FROM inform.politician_answers  WHERE politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answers on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context  WHERE politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % context rows on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes           WHERE politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % quotes on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_contacts WHERE politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % contacts on the duplicate; this file moves none', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % committee/FEC link(s) on the duplicate; this file moves none', v_n; END IF;

  -- the trigger will write nothing to the twin: it already has an image and a photo
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef'
     AND photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/307479.webp';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin''s photo_custom_url is not the reviewed value'; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin has % images, expected 1', v_n; END IF;

  RAISE NOTICE 'CA_0261 pre-flight OK';
END $$;

-- ─── 1. Move the primary race row to the twin ─────────────────────────────────────────────────────
UPDATE essentials.race_candidates SET politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef', updated_at = now()
 WHERE id = '8c244f50-38e4-4b4e-8888-e03d4e3cfe4d' AND politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';

-- ─── 2. Deactivate the duplicate ─────────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0261 (2026-09-24): DUPLICATE of 6b16270a-c6c7-46be-9b9c-7def323dc4ef '
               || '(Jeffrey S. Gray), the row that holds the Utah County Attorney seat. Its 2026 primary race row moved '
               || 'there; deactivated, not deleted.')::text
 WHERE d.id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e' AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e' AND NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0261 (2026-09-24): DUPLICATE of%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate not deactivated with the note'; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = '35faf7b8-4d1e-4363-b4db-3531ea3fad5e';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % race rows still on the duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef'
     AND id IN ('8c244f50-38e4-4b4e-8888-e03d4e3cfe4d', '8c99c328-f04c-4820-9620-bb2d5aeecfdc');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 race rows on the twin', v_n; END IF;

  -- the twin keeps its seat, answers, photo and single image (the trigger wrote nothing)
  SELECT count(*) INTO v_n FROM essentials.office_current_holder
   WHERE politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef' AND office_id = 'daf1fa50-abdb-4996-82ac-c0a6d55f4257';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin no longer holds the Utah County Attorney seat'; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef';
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: twin has % answers, expected 8', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin has % images, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '6b16270a-c6c7-46be-9b9c-7def323dc4ef' AND is_active AND is_incumbent
     AND photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/307479.webp';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin''s flags or photo changed'; END IF;

  -- only one active Jeff Gray remains in Utah County's data
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE is_active AND first_name ILIKE 'Jeff%' AND (last_name = 'Gray' OR last_name LIKE '% Gray')
     AND id IN ('35faf7b8-4d1e-4363-b4db-3531ea3fad5e', '6b16270a-c6c7-46be-9b9c-7def323dc4ef');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active Jeff Gray rows in the pair', v_n; END IF;

  RAISE NOTICE 'CA_0261 applied: duplicate deactivated; primary race row on the seated twin';
END $$;

COMMIT;
