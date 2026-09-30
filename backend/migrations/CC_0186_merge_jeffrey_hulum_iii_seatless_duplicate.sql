-- CC_0186_merge_jeffrey_hulum_iii_seatless_duplicate.sql
-- Merge the seatless DUPLICATE row of Jeffrey Hulum III into his SEATED row, and deactivate the duplicate.
-- Same pattern as CA_0227 / CA_0261: the SEATED row is the person; what hangs on the duplicate moves to it;
-- nothing is deleted.
--
-- Slot CC_0186 reserved via `npm run steward --prefix backend -- slot CC` (author: Chris Cantrell).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
--
-- WHY NOW: `npm run check:duplicate-people` has failed on EVERY master run since 2026-09-29 18:33Z —
--   six consecutive red runs — on exactly one new pair. The job is master-only, so no PR ever showed it.
--     NEW  NAME_STATE  ms  Jeffrey Hulum III [seated, 0 answers]
--                        ~  Jeffrey Hulum III [no seat, 6 answers, fec_house:H6MS04242]
--
-- THE PAIR (duplicate -> seated twin):
--   6ff3ff30-00b9-4077-8cde-700cf687d106 "Jeffrey Hulum III" (created 2026-07-07, external_id -280401;
--     no seat, no term, is_incumbent false; 6 Season-1 answers + 6 context rows, 3 quotes, 1 image,
--     1 race row, 1 FEC source) -> 3e9b6f7f-1cb8-49e9-b645-086390226f75 "Jeffrey Hulum III"
--     (created 2026-09-28 by the MS-2 wave, external_id -2766230; holds Mississippi House District 119,
--     office 70fc4f67-1ef4-4620-86f2-397969d18720, is_incumbent true; nothing else attached).
--
-- ONE PERSON — three independent sources agree, and none disagrees:
--   * Open States `ms.csv` (read 2026-09-30) gives MS House District 119 = Jeffrey Hulum, Democratic,
--     jhulum@house.ms.gov, and lists ballotpedia.org/Jeffrey_Hulum_III and en.wikipedia.org/wiki/Jeffrey_Hulum_III
--     among that person's own sources.
--   * FEC candidate H6MS04242 (api.open.fec.gov, read 2026-09-30) = "HULUM, JEFFREY III", DEMOCRATIC PARTY,
--     House, MS, district 04, election year 2026, Challenger, address GULFPORT MS.
--   * Wikipedia (read 2026-09-30): "Jeffrey Hulum III ... currently serving in the Mississippi House of
--     Representatives from Mississippi's 119th House of Representatives district, a district based in the city
--     of Gulfport in Harrison County. He was elected in a 2022 special election. He is a member of the
--     Democratic Party. Hulum is the Democratic nominee for Mississippi's 4th congressional district in 2026."
--   HD-119 (Gulfport, Harrison County) sits inside MS-04. The suffix "III" is carried by both rows and by all
--   three sources. A sitting state representative running for Congress is the ordinary shape here, not a clash.
--   ⚠ The name alone was NOT the evidence. The duplicate-name guard keys on (first_name, last_name), and a hit
--   has two opposite right answers; this one was read, and it is the same man.
--
-- WHAT MOVES (every column in the database named politician_id / essentials_politician_id was counted for the
-- duplicate on 2026-09-30 — 55 of them; these seven are the only ones that are non-zero, and the twin holds a
-- row in NONE of them, so no key can collide):
--   inform.politician_answers                        6  (Season 1)
--   inform.politician_context                        6  (Season 1, one per answer — the pair moves together)
--   essentials.quotes                                3
--   essentials.politician_images                     1  (photo_license cc_by_2.0)
--   essentials.race_candidates                       1  (U.S. Representative District 4, MS 2026 Statewide
--                                                        General, 2026-11-03)
--   transparent_motivations.politician_sources       1  (fec_house / candidate_committee / H6MS04242, confirmed)
--   essentials.politicians.photo_custom_url          -  copied to the twin, cleared on the duplicate
--
-- NOT A TABLE: essentials.politician_occupancy_evidence is a VIEW. Both rows appear in it because it is computed;
--   it needs no write and gets none. Checked rather than assumed.
--
-- 🔴 THIS MIGRATION SETS `inform.allow_closed_season_write` AND MUST SAY WHY.
--   All 12 answer and context rows sit in Season 1, which is CLOSED, and
--   inform.closed_season_is_immutable() refuses INSERT, UPDATE and DELETE there. Its own message names this
--   escape hatch for the case that "really must edit history".
--   This is that case, and it is NOT a content edit: value, topic_id, season_id, reasoning and every source stay
--   byte-identical. The ONLY column that changes is politician_id, and it changes from a duplicate row of a man
--   to the canonical row of THE SAME MAN. The historical record is not altered; the key pointing at it is corrected.
--   ▶ The trigger's normal advice — "write a row in the OPEN season, it shadows the old one on read" — is WRONG
--   here and would do real damage: it would fabricate Season-2 answers no researcher produced, against ladders
--   they were never evidenced for, while leaving Season 1 attributing his positions to a row no address reaches.
--
-- 🟢 PREDICTED, NOT ASSUMED: essentials.race_candidate_mirror_data fires on the politician_id UPDATE and writes
--   NOTHING — race row 319397d7 carries photo_url NULL and website_url NULL, and mirror_candidate_data_to_politician
--   returns early for both. The twin's photo therefore comes from the explicit copy below, not from the trigger.
--
-- NOT CHANGED: the twin's office_term (still term_start NULL / start_precision 'unknown' from MS-2 — dating it is a
--   separate question and inventing a date is worse than leaving it); the twin's is_incumbent (already true); the
--   duplicate's is_incumbent (already false); any answer VALUE; any season.
--
-- ROLLBACK: re-point all seven sets back to 6ff3ff30-00b9-4077-8cde-700cf687d106 (with the same SET LOCAL, for the
--   two inform tables), restore that row's photo_custom_url, clear the twin's, set is_active back to true and drop
--   the CC_0186 note from notes.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

-- The closed-season hatch. SET LOCAL, so it dies with this transaction and cannot leak into another session.
SET LOCAL inform.allow_closed_season_write = 'on';

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the twin is active, the incumbent, and holds MS House District 119
  SELECT count(*) INTO v_n
    FROM essentials.politicians k
    JOIN essentials.office_current_holder och ON och.politician_id = k.id
   WHERE k.id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
     AND k.full_name = 'Jeffrey Hulum III' AND k.is_active AND k.is_incumbent
     AND och.office_id = '70fc4f67-1ef4-4620-86f2-397969d18720';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin is not the active holder of MS House District 119'; END IF;

  -- the duplicate is the same name, active, and holds no term
  SELECT count(*) INTO v_n
    FROM essentials.politicians d
   WHERE d.id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
     AND d.full_name = 'Jeffrey Hulum III' AND d.is_active AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate missing, renamed, inactive, incumbent, or holding a term'; END IF;

  -- exactly the reviewed rows hang on the duplicate, and NOTHING of these kinds hangs on the twin
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % answers on the duplicate, expected 6', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % context rows on the duplicate, expected 6', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % quotes on the duplicate, expected 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % images on the duplicate, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '319397d7-28e8-4706-8e3f-77ac3f0ea809' AND politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
     AND photo_url IS NULL AND website_url IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the MS-04 race row is not in its reviewed state (id, owner, null photo/site)'; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
     AND source_system = 'fec_house' AND external_id = 'H6MS04242';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the FEC source row is missing or changed'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: twin already carries % answers — a primary key would collide', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: twin already carries % context rows — a primary key would collide', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: twin already carries % image row(s)', v_n; END IF;

  -- every answer on the duplicate really is Season 1 and really is closed — the hatch above is aimed at these
  SELECT count(*) INTO v_n
    FROM inform.politician_answers pa JOIN inform.seasons s ON s.id = pa.season_id
   WHERE pa.politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106' AND s.status = 'closed';
  IF v_n <> 6 THEN RAISE EXCEPTION 'PRE: % of 6 answers are in a closed season — re-read before using the hatch', v_n; END IF;
END $$;

-- ─── Move everything that hangs on the duplicate ─────────────────────────────────────────────────
UPDATE inform.politician_answers
   SET politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

UPDATE inform.politician_context
   SET politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

UPDATE essentials.quotes
   SET politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

UPDATE essentials.politician_images
   SET politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

UPDATE essentials.race_candidates
   SET politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE id = '319397d7-28e8-4706-8e3f-77ac3f0ea809'
   AND politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

UPDATE transparent_motivations.politician_sources
   SET essentials_politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
 WHERE essentials_politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106';

-- photo_custom_url is what actually renders; a politician_images row alone changes nothing a voter sees.
UPDATE essentials.politicians
   SET photo_custom_url = (SELECT photo_custom_url FROM essentials.politicians
                            WHERE id = '6ff3ff30-00b9-4077-8cde-700cf687d106')
 WHERE id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
   AND coalesce(photo_custom_url, '') = '';

UPDATE essentials.politicians
   SET photo_custom_url = NULL
 WHERE id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
   AND photo_custom_url IS NOT NULL;

-- ─── Deactivate the duplicate, naming its twin ───────────────────────────────────────────────────
UPDATE essentials.politicians
   SET is_active = false,
       notes = coalesce(notes, '{}'::text[]) || ARRAY[
         'CC_0186 (2026-09-30): duplicate of 3e9b6f7f-1cb8-49e9-b645-086390226f75, the same man''s seated row '
         '(Mississippi House District 119). Everything that hung here — 6 Season-1 answers and their 6 context '
         'rows, 3 quotes, 1 image, the MS-04 2026 race row and the fec_house H6MS04242 source — was moved there. '
         'Kept inactive rather than deleted.']
 WHERE id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
   AND is_active;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_photo text;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: twin holds % answers, expected 6', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: twin holds % context rows, expected 6', v_n; END IF;

  -- every answer keeps its season and its value: nothing was rewritten, only re-pointed
  SELECT count(*) INTO v_n
    FROM inform.politician_answers pa JOIN inform.seasons s ON s.id = pa.season_id
   WHERE pa.politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75' AND s.name = 'Season 1'
     AND pa.value IN (2, 3);
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % of 6 answers are not the reviewed Season-1 values', v_n; END IF;

  -- answer and context still pair one-to-one, which is the whole point of moving them together
  SELECT count(*) INTO v_n
    FROM inform.politician_answers pa
   WHERE pa.politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75'
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
                        AND pc.season_id = pa.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % answers on the twin have no matching context row', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.quotes WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: twin holds % quotes, expected 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin holds % images, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin holds % race rows, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin holds % source rows, expected 1', v_n; END IF;

  -- the twin renders a face; photo_custom_url is the column that decides that
  SELECT photo_custom_url INTO v_photo FROM essentials.politicians WHERE id = '3e9b6f7f-1cb8-49e9-b645-086390226f75';
  IF coalesce(v_photo, '') = '' THEN RAISE EXCEPTION 'POST: twin has no photo_custom_url, so it still renders initials'; END IF;

  -- the duplicate is empty and inactive, and still exists
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '6ff3ff30-00b9-4077-8cde-700cf687d106' AND NOT is_active AND photo_custom_url IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate is missing, still active, or still carries a photo'; END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT 1 FROM inform.politician_answers WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
    UNION ALL SELECT 1 FROM inform.politician_context WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
    UNION ALL SELECT 1 FROM essentials.quotes WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
    UNION ALL SELECT 1 FROM essentials.politician_images WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
    UNION ALL SELECT 1 FROM essentials.race_candidates WHERE politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
    UNION ALL SELECT 1 FROM transparent_motivations.politician_sources
                     WHERE essentials_politician_id = '6ff3ff30-00b9-4077-8cde-700cf687d106'
  ) leftovers;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % row(s) still hang on the duplicate', v_n; END IF;

  -- exactly one active Jeffrey Hulum III remains, and it is the seated one
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE lower(last_name) LIKE 'hulum%' AND is_active;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active Hulum rows remain, expected 1', v_n; END IF;
END $$;

COMMIT;
