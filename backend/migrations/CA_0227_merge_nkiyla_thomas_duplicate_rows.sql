-- CA_0227_merge_nkiyla_thomas_duplicate_rows.sql
--
-- Slot CA_0227 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- N'Kiyla Thomas, the 2026 Oklahoma Democratic U.S. Senate nominee, is split across TWO
-- essentials.politicians rows that differ only in the apostrophe of her first name. Found during the
-- CA_0222 sweep (2026-09-24). Same shape as CA_0204 (Barr / Moulton), one level simpler: neither row
-- holds a seat.
--
--   6fc5e090-a7cc-41a8-b7f4-ab7101078487  "N’Kiyla Thomas" (U+2019)   source manual_seed_2026, 2026-06-28
--     holds: the "Candidate for U.S. Senate — Oklahoma" office_terms row (open, 1459 backfill),
--            fec_senate S6OK04163 (confirmed), finance_summary (total_raised 57158.83), a portrait
--   1e8ea8a4-61d5-44f7-84b9-3aa6633a16e6  "N'Kiyla Thomas" (U+0027)   external_id -66000113, 2026-07-10
--     holds: 9 politician_answers (7 Season 1, closed; 2 Season 2, open), 9 politician_context rows,
--            the "U.S. Senate Oklahoma" 2026-08-25 runoff race_candidates row, a portrait
--
-- So today the row voters see as the Senate candidate (the placeholder holder) has no compass answers,
-- and the row with the answers holds nothing and appears on no current ballot.
--
-- Same person: same name up to the apostrophe, same party, same race. FEC S6OK04163 is her 2026 Senate
-- candidacy. The State Election Board prints "N'KIYLA JASMINE THOMAS" (2026-06-16 primary; 2026-08-25
-- runoff, which she won 79,229 / 50,249 — see CA_0222).
--
-- ===========================================================================================
-- SURVIVOR: 1e8ea8a4 (the straight-apostrophe row)
-- ===========================================================================================
-- Not a choice by name. Its 7 Season 1 answers cannot move: Season 1 is closed, and closed-season
-- politician_answers / politician_context rows are BEFORE-trigger immutable. Everything on the other
-- row CAN move. The straight apostrophe also matches the State Election Board's spelling.
--
-- MOVED onto 1e8ea8a4 (checked against every FK into essentials.politicians, 2026-09-24; the curly row
-- is referenced only by the term, the source and its own politician_images row):
--   - office_terms b12cdef4-27ae-47f5-b336-0e4cb75b5b23 (the candidacy placeholder term; still open and
--     correct — she is the nominee). office_terms_no_overlap excludes on (office_id, daterange), not
--     politician_id, so re-pointing it is safe.
--   - politician_sources 0b9601a8-72e3-4ac9-aa0d-fec5c569cf72 (fec_senate S6OK04163, confirmed). The
--     survivor holds no sources, so nothing collides. Contributions follow the link.
--   - finance_summary (the survivor has none). Guarded on the exact total.
--
-- LEFT AS-IS:
--   - politician_images: one row on each, keyed by that row's own id; both rows have photo_origin_url.
--   - The curly row is deactivated (is_active = false; is_incumbent already false) with a note.
--     Nothing is deleted.
--   - is_incumbent on the survivor stays false, stated explicitly: she is a candidate, not a holder.
--   - The Oklahoma general 2026-11-03 roster still lacks her. That is the "rosters after the primaries"
--     change, which depends on this one.
--
-- ROLLBACK (once applied): re-point b12cdef4 and 0b9601a8 back to 6fc5e090; strip the ' | merged onto'
-- suffix from the term's source; set the survivor's finance_summary back to NULL; set 6fc5e090
-- is_active = true and remove its 'CA_0227' note.
--
-- IDEMPOTENT: every step is guarded on its pre-image. Dry run: the body wrapped BEGIN; ... ROLLBACK;
-- against prod, applied twice in one transaction, then the rollback confirmed by re-reading the rows.

BEGIN;

CREATE TEMP TABLE ca0227_pair ON COMMIT DROP AS
SELECT '6fc5e090-a7cc-41a8-b7f4-ab7101078487'::uuid AS loser,
       '1e8ea8a4-61d5-44f7-84b9-3aa6633a16e6'::uuid AS keep,
       'b12cdef4-27ae-47f5-b336-0e4cb75b5b23'::uuid AS term_id,
       '0b9601a8-72e3-4ac9-aa0d-fec5c569cf72'::uuid AS source_id,
       57158.83::numeric                            AS total_raised;

CREATE TEMP TABLE ca0227_before ON COMMIT DROP AS
SELECT (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.essentials_politician_id IN (pr.keep, pr.loser)) AS pair_total
  FROM ca0227_pair pr;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE pr record; n int;
BEGIN
  SELECT * INTO pr FROM ca0227_pair;

  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = pr.keep AND full_name = 'N''Kiyla Thomas'
                   AND external_id = -66000113 AND party = 'Democratic' AND is_active AND NOT is_incumbent) THEN
    RAISE EXCEPTION 'PRE: survivor % is not the active straight-apostrophe N''Kiyla Thomas row', pr.keep;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = pr.loser AND full_name = 'N’Kiyla Thomas'
                   AND party = 'Democratic' AND NOT is_incumbent) THEN
    RAISE EXCEPTION 'PRE: % is not the curly-apostrophe N’Kiyla Thomas row', pr.loser;
  END IF;

  -- The term and the source sit on the loser (first run) or the survivor (re-run), and nothing on
  -- either row escapes this review.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
                  WHERE t.id = pr.term_id AND t.politician_id IN (pr.loser, pr.keep)
                    AND o.title = 'Candidate for U.S. Senate — Oklahoma' AND t.term_end IS NULL) THEN
    RAISE EXCEPTION 'PRE: term % is not the open Oklahoma candidacy term on either row', pr.term_id;
  END IF;
  SELECT count(*) INTO n FROM essentials.office_terms WHERE politician_id IN (pr.loser, pr.keep) AND id <> pr.term_id;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed office_terms row(s) on the pair', n; END IF;

  IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources
                  WHERE id = pr.source_id AND essentials_politician_id IN (pr.loser, pr.keep)
                    AND source_system = 'fec_senate' AND external_id = 'S6OK04163' AND research_status = 'confirmed') THEN
    RAISE EXCEPTION 'PRE: source % is not the confirmed fec_senate S6OK04163 link on either row', pr.source_id;
  END IF;
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (pr.loser, pr.keep) AND id <> pr.source_id;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed politician_sources row(s) on the pair', n; END IF;

  -- The loser carries no answers, context or race rows (they could not follow a Season 1 merge anyway).
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id = pr.loser;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % answers on the loser', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id = pr.loser;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % context rows on the loser', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE politician_id = pr.loser;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % race_candidates rows on the loser', n; END IF;

  RAISE NOTICE 'CA_0227 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. Move the candidacy term and the FEC link.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET politician_id = pr.keep,
       source        = t.source || ' | merged onto ' || pr.keep::text || ' by CA_0227 (2026-09-24): duplicate '
                                || 'N’Kiyla / N''Kiyla Thomas rows'
  FROM ca0227_pair pr
 WHERE t.id = pr.term_id AND t.politician_id = pr.loser;

UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = pr.keep, updated_at = now()
  FROM ca0227_pair pr
 WHERE ps.id = pr.source_id AND ps.essentials_politician_id = pr.loser;

-- ---------------------------------------------------------------------------
-- 2. finance_summary follows the campaign (the survivor has none). Exact value only.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians k
   SET finance_summary = d.finance_summary
  FROM ca0227_pair pr JOIN essentials.politicians d ON d.id = pr.loser
 WHERE k.id = pr.keep AND k.finance_summary IS NULL
   AND (d.finance_summary->>'total_raised')::numeric = pr.total_raised;

-- ---------------------------------------------------------------------------
-- 3. is_incumbent, explicitly (already false on both; guarded no-op), and deactivate the loser.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_incumbent = false
  FROM ca0227_pair pr
 WHERE p.id IN (pr.keep, pr.loser) AND p.is_incumbent IS DISTINCT FROM false;

UPDATE essentials.politicians d
   SET is_active = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0227 (2026-09-24): DUPLICATE of ' || pr.keep::text
               || ' (N''Kiyla Thomas, straight apostrophe), which holds her compass answers. The Oklahoma '
               || 'Senate-candidacy office_terms row, the fec_senate S6OK04163 link and finance_summary moved '
               || 'there. Deactivated, not deleted.')
  FROM ca0227_pair pr
 WHERE d.id = pr.loser AND d.is_active;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE pr record; n int; v_before numeric; v_after numeric;
BEGIN
  SELECT * INTO pr FROM ca0227_pair;

  -- THE POINT: the Oklahoma placeholder resolves to the row with the answers. (Office-rooted lookup.)
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   JOIN essentials.office_terms t ON t.id = pr.term_id AND t.office_id = och.office_id
                  WHERE och.politician_id = pr.keep) THEN
    RAISE EXCEPTION 'POST: the survivor does not hold the Oklahoma candidacy placeholder';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder WHERE politician_id = pr.loser) THEN
    RAISE EXCEPTION 'POST: the loser still resolves as a current holder';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_terms WHERE id = pr.term_id AND politician_id = pr.keep
                   AND term_end IS NULL AND strpos(source, 'merged onto ' || pr.keep::text || ' by CA_0227') > 0) THEN
    RAISE EXCEPTION 'POST: term % not moved and marked, or no longer open', pr.term_id;
  END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources WHERE essentials_politician_id = pr.loser;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % sources still on the loser', n; END IF;
  IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources WHERE id = pr.source_id
                   AND essentials_politician_id = pr.keep AND research_status = 'confirmed') THEN
    RAISE EXCEPTION 'POST: fec_senate link not on the survivor';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = pr.keep AND is_active AND NOT is_incumbent
                   AND (finance_summary->>'total_raised')::numeric = pr.total_raised) THEN
    RAISE EXCEPTION 'POST: survivor not active / not a non-incumbent / finance_summary not copied';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = pr.loser AND NOT is_active AND NOT is_incumbent
                   AND EXISTS (SELECT 1 FROM unnest(notes) x WHERE x LIKE 'CA_0227 (2026-09-24): DUPLICATE of%')) THEN
    RAISE EXCEPTION 'POST: loser not deactivated with the note';
  END IF;
  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE p.id = pr.loser AND (SELECT count(*) FROM unnest(p.notes) x WHERE x LIKE 'CA_0227%') = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'POST: the CA_0227 note is missing or duplicated on the loser'; END IF;

  -- Nothing deleted: the survivor's answers, context and race row are exactly as before.
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id = pr.keep;
  IF n <> 9 THEN RAISE EXCEPTION 'POST: % answers on the survivor, expected 9', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id = pr.keep;
  IF n <> 9 THEN RAISE EXCEPTION 'POST: % context rows on the survivor, expected 9', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE politician_id = pr.keep;
  IF n <> 1 THEN RAISE EXCEPTION 'POST: % race_candidates rows on the survivor, expected 1', n; END IF;

  -- No money created or destroyed: the pair's confirmed total is re-attributed, not changed.
  SELECT pair_total INTO v_before FROM ca0227_before;
  SELECT COALESCE(sum(a.total_amount), 0) INTO v_after FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.essentials_politician_id = pr.keep;
  IF v_before <> v_after THEN
    RAISE EXCEPTION 'POST: pair confirmed total moved from % to %, expected unchanged', v_before, v_after;
  END IF;

  RAISE NOTICE 'CA_0227 applied: N''Kiyla Thomas merged onto % — candidacy term, FEC link, finance_summary '
               'moved; duplicate deactivated', pr.keep;
END $$;

COMMIT;
