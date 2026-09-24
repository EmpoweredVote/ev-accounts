-- CA_0229_merge_fetty_anderson_seatless_duplicate.sql
-- Merge the seatless DUPLICATE row of Rachel Fetty Anderson (2026 Democratic candidate for U.S. Senate, West
-- Virginia) into her seated twin, and deactivate the duplicate. Same pattern as CA_0182 and CA_0184: the SEATED row
-- is the person; what hangs on the duplicate moves to it where the twin lacks it; nothing is deleted.
--
-- THE PAIR (duplicate -> seated twin):
--   60d485a8-17c9-4092-a666-b06c011d66e8 (created 2026-07-10 by the Ballotpedia Senate-candidate seed,
--     external_id -66000015; no seat) -> 6b44e402-7ea5-4dad-b3dd-6066fab6c6f6 (created 2026-05-22; holds the
--     "Candidate for U.S. Senate — West Virginia" placeholder seat; FEC S6WV00188 confirmed).
--   Found 2026-09-24 while checking the compound-surname fix (#712): the FEC queue reads seats, so the duplicate
--   was invisible to it, while her race row -- and every Read & Rank quote -- sat on the duplicate.
--
-- WHAT MOVES: 1 race_candidates row (WV 2026 Statewide General, race d5767db7) and 11 essentials.quotes (8
-- readrank_selected; the twin has no quotes, so the one-selected-per-question indexes cannot collide). The race row
-- carries no photo or website, so the race_candidate_mirror_data trigger writes nothing.
-- NOT MOVED: the duplicate's 10 Season 1 compass answers and 11 context rows. The twin already answers all 10 of
--   those topics in Season 1 -- 4 with the same value, 6 with a DIFFERENT one (Abortion, AI Oversight, Climate
--   Change, Healthcare, Medicare/aid, Misinformation). As in CA_0184, they stay on the deactivated duplicate as a
--   stance-review lead; this file does not choose between them. So no closed-season write, and no override.
--   The duplicate's politician_images row also stays (the twin has its own).
--
-- THEN: the duplicate is deactivated (is_active = false, is_incumbent stays false) with a note naming its twin.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE. No office_terms change.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval and apply: Chris Andrews). Dry run (BEGIN ... ROLLBACK) passed and
--   was confirmed reverted before the apply; verified after: duplicate inactive, race row + 11 quotes (8 selected) on
--   the seated row, which keeps its seat and its confirmed FEC link S6WV00188.
--
-- ROLLBACK: re-point race_candidates 8250bf5c-d4bb-4828-a3c4-eb1962c6dde6 and the 11 quote ids in _quote back to
-- 60d485a8-17c9-4092-a666-b06c011d66e8, and set that row's is_active back to true, removing its CA_0229 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _quote (id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO _quote
SELECT q.id FROM essentials.quotes q
 WHERE q.politician_id IN ('60d485a8-17c9-4092-a666-b06c011d66e8', '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the twin is active, not the incumbent, and holds the WV Senate placeholder seat
  SELECT count(*) INTO v_n FROM essentials.politicians k
    JOIN essentials.office_current_holder och ON och.politician_id = k.id
    JOIN essentials.offices o ON o.id = och.office_id
   WHERE k.id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6' AND k.full_name = 'Rachel Fetty Anderson' AND k.is_active
     AND o.title = 'Candidate for U.S. Senate — West Virginia';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin is not active on the WV Senate placeholder seat'; END IF;

  -- the duplicate is the same name and holds no term
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '60d485a8-17c9-4092-a666-b06c011d66e8' AND d.full_name = 'Rachel Fetty Anderson'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate missing, renamed, or holding a term'; END IF;

  -- exactly the reviewed race row, on the duplicate or already on the twin; the twin has no other race row
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id IN ('60d485a8-17c9-4092-a666-b06c011d66e8', '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % race rows across the pair, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '8250bf5c-d4bb-4828-a3c4-eb1962c6dde6' AND race_id = 'd5767db7-ba5b-40d8-87aa-000feaec1f54';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the reviewed race row is not in its reviewed state'; END IF;

  SELECT count(*) INTO v_n FROM _quote;
  IF v_n <> 11 THEN RAISE EXCEPTION 'PRE: % quotes across the pair, expected 11', v_n; END IF;

  -- nothing else hangs on the duplicate that this file has not reviewed
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % committee/FEC link(s) on the duplicate; this file moves none', v_n; END IF;

  -- every duplicate answer is a (topic, season) the twin already answers -- so nothing needs to move
  SELECT count(*) INTO v_n FROM inform.politician_answers d
   WHERE d.politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8'
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers k
                      WHERE k.politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6'
                        AND k.topic_id = d.topic_id AND k.season_id IS NOT DISTINCT FROM d.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % duplicate answer(s) the twin lacks; this file moves none', v_n; END IF;
END $$;

-- ─── 1. Move the race row and the quotes to the twin ───────────────────────────────────────────
UPDATE essentials.race_candidates SET politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6', updated_at = now()
 WHERE id = '8250bf5c-d4bb-4828-a3c4-eb1962c6dde6' AND politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8';

UPDATE essentials.quotes q SET politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6', updated_at = now()
 WHERE q.id IN (SELECT id FROM _quote) AND q.politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8';

-- ─── 2. Deactivate the duplicate ─────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0229 (2026-09-24): DUPLICATE of 6b44e402-7ea5-4dad-b3dd-6066fab6c6f6 '
               || '(Rachel Fetty Anderson), the row that holds the WV Senate candidate seat. Race row and 11 quotes moved '
               || 'there; 6 Season 1 answers that CONFLICT with the twin stay here as a stance-review lead; '
               || 'deactivated, not deleted.')::text
 WHERE d.id = '60d485a8-17c9-4092-a666-b06c011d66e8' AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = '60d485a8-17c9-4092-a666-b06c011d66e8' AND NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0229 (2026-09-24): DUPLICATE of%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate not deactivated with the note'; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '8250bf5c-d4bb-4828-a3c4-eb1962c6dde6' AND politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: race row not on the twin'; END IF;

  SELECT count(*) INTO v_n FROM essentials.quotes WHERE politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6';
  IF v_n <> 11 THEN RAISE EXCEPTION 'POST: % of 11 quotes on the twin', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes
   WHERE politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6' AND readrank_selected;
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: % of 8 selected quotes on the twin', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % race rows still on the duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes WHERE politician_id = '60d485a8-17c9-4092-a666-b06c011d66e8';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % quotes still on the duplicate', v_n; END IF;

  -- the twin still holds its seat, and its FEC link is untouched
  SELECT count(*) INTO v_n FROM essentials.office_current_holder WHERE politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin holds % seats, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '6b44e402-7ea5-4dad-b3dd-6066fab6c6f6' AND external_id = 'S6WV00188' AND research_status = 'confirmed';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin lost its confirmed FEC link'; END IF;

  -- only one active Rachel Fetty Anderson remains
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE is_active AND lower(full_name) = 'rachel fetty anderson';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active Rachel Fetty Anderson rows', v_n; END IF;

  RAISE NOTICE 'CA_0229 applied: duplicate deactivated; 1 race row and 11 quotes (8 selected) on the seated twin';
END $$;

COMMIT;
