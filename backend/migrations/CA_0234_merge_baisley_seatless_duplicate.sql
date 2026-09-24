-- CA_0234_merge_baisley_seatless_duplicate.sql
-- Identity merge of the seatless DUPLICATE row of Mark Baisley into his seated twin, and deactivate the duplicate.
-- Same pattern as CA_0184 (answers only on the duplicate) and CA_0229 (race row + quotes): the SEATED row is the
-- person; what hangs on the duplicate moves to it; nothing is deleted.
--
-- THE PAIR (duplicate -> seated twin):
--   a9e23e62-7572-4d78-860c-c8950df6e141 (external_id -66000020, from 1296_senate_2026_deep_seed; created 2026-07-10;
--     no seat) -> 3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab (external_id -810004, from 1844_co_legislature_incumbents;
--     created 2026-08-21; holds Colorado State Senate District 4 since 2023-01-09).
--   ONE PERSON: the Republican state senator who left the governor's race in January 2026 to run for U.S. Senate, and
--   the unopposed Republican nominee against John Hickenlooper (CA_0222 records the certified CO primary ballot naming
--   only Baisley). Both rows: Republican, Colorado. Found 2026-09-24 in the same-name sweep of the 2026-07-10 batch
--   after CA_0229.
--
-- 🔴 THIS FILE EDITS A CLOSED SEASON, WITH THE OVERRIDE THE TRIGGER ASKS FOR. inform.closed_season_is_immutable()
-- blocks every write to a Season 1 answer or context row unless inform.allow_closed_season_write = 'on'. Why: this is
-- an IDENTITY correction, not a position change. No value, season, topic or topic_revision pin changes; each answer
-- moves from one row of the person to the other row of the SAME person, where the read paths look for it. Left alone,
-- deactivating the duplicate would hide his 10 Season 1 answers from his own profile. The seated twin answers NO topic,
-- so nothing collides and nothing is chosen between. The override is SET LOCAL and RESET straight after, so it covers
-- the two UPDATEs only. Operator approval for this override: Chris Andrews, 2026-09-24.
--
-- WHAT MOVES: 1 race_candidates row (CO 2026 Statewide General, U.S. Senate Colorado), 1 essentials.quotes row (not
-- readrank_selected), 10 Season 1 inform.politician_answers rows and their 10 inform.politician_context rows. No
-- politician_context_evidence or stance_research_review rows exist for the duplicate, so the context rows can be
-- UPDATEd in place (CA_0184 had to copy-then-delete because of evidence rows; here there are none, and the pre-flight
-- refuses to run if that changes). The race row carries no photo or website, so race_candidate_mirror_data writes
-- nothing. The duplicate's politician_images row stays (the twin has its own).
-- NOTE FOR STANCE REVIEW, not acted on here: all 10 answers are rung 4 and every one names an instrument, vote or
-- pledge, but Fossil Fuels ("no specific drilling-permit bill") and Taxes (campaign pledge only) evidence direction
-- more clearly than rung.
--
-- THEN: the duplicate is deactivated (is_active = false, is_incumbent stays false) with a note naming its twin.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE. No office_terms change.
-- STATUS: NOT YET APPLIED.
--
-- ROLLBACK: with the same override, re-point race_candidates 08f933cc-fc44-4066-b512-654025f6cccc, quote
-- b9be256a-2dc1-40da-b728-1227234cd642 and the 10 (topic, season) keys in _ans back to
-- a9e23e62-7572-4d78-860c-c8950df6e141, and set that row's is_active back to true, removing its CA_0234 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run moves nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _ans (topic_id uuid, season_id uuid, PRIMARY KEY (topic_id, season_id)) ON COMMIT DROP;
INSERT INTO _ans
SELECT a.topic_id, a.season_id FROM inform.politician_answers a
 WHERE a.politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the twin is active, the incumbent, and holds the CO State Senate seat
  SELECT count(*) INTO v_n FROM essentials.politicians k
    JOIN essentials.office_current_holder och ON och.politician_id = k.id
    JOIN essentials.offices o ON o.id = och.office_id
   WHERE k.id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab' AND k.full_name = 'Mark Baisley' AND k.is_active AND k.is_incumbent
     AND k.party = 'Republican' AND o.title = 'State Senator' AND o.representing_state = 'CO';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: twin is not the active CO State Senator'; END IF;

  -- the duplicate is the same name and party and holds no term
  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = 'a9e23e62-7572-4d78-860c-c8950df6e141' AND d.full_name = 'Mark Baisley' AND d.party = 'Republican'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = d.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: duplicate missing, renamed, re-partied, or holding a term'; END IF;

  -- exactly the reviewed race row and quote, on the duplicate or already on the twin
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % race rows across the pair, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE id = '08f933cc-fc44-4066-b512-654025f6cccc';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the reviewed race row is missing'; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes
   WHERE politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % quotes across the pair, expected 1', v_n; END IF;

  -- 10 answers, all in the same (closed) season, each with its context row; none on both rows
  SELECT count(*) INTO v_n FROM _ans;
  IF v_n <> 10 THEN RAISE EXCEPTION 'PRE: % answers across the pair, expected 10', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab');
  IF v_n <> 10 THEN RAISE EXCEPTION 'PRE: % context rows across the pair, expected 10', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c
   WHERE c.politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab')
     AND NOT EXISTS (SELECT 1 FROM _ans x WHERE x.topic_id = c.topic_id AND x.season_id = c.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % context rows with no matching answer', v_n; END IF;

  -- nothing references a context row by key, so an in-place UPDATE is safe
  SELECT count(*) INTO v_n FROM inform.politician_context_evidence
   WHERE politician_id IN ('a9e23e62-7572-4d78-860c-c8950df6e141', '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % context evidence rows; this file cannot move them in place', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.stance_research_review
   WHERE politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % stance_research_review rows on the duplicate; this file moves none', v_n; END IF;

  -- no finance links on either row to keep track of
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % finance link(s) on the duplicate; this file moves none', v_n; END IF;
END $$;

-- ─── 1. Move the race row and the quote to the twin ────────────────────────────────────────────
UPDATE essentials.race_candidates SET politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab', updated_at = now()
 WHERE id = '08f933cc-fc44-4066-b512-654025f6cccc' AND politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141';

UPDATE essentials.quotes SET politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab', updated_at = now()
 WHERE id = 'b9be256a-2dc1-40da-b728-1227234cd642' AND politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141';

-- ─── 2. Move the Season 1 answers and their context (closed season: identity correction) ───────
SET LOCAL inform.allow_closed_season_write = 'on';

UPDATE inform.politician_context c SET politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab'
  FROM _ans x
 WHERE c.politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141' AND c.topic_id = x.topic_id AND c.season_id = x.season_id;

UPDATE inform.politician_answers a SET politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab'
  FROM _ans x
 WHERE a.politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141' AND a.topic_id = x.topic_id AND a.season_id = x.season_id;

RESET inform.allow_closed_season_write;

-- ─── 3. Deactivate the duplicate ─────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0234 (2026-09-24): DUPLICATE of 3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab '
               || '(Mark Baisley), the row that holds his Colorado State Senate seat. Race row, quote, and 10 Season 1 '
               || 'answers with their context moved there; deactivated, not deleted.')::text
 WHERE d.id = 'a9e23e62-7572-4d78-860c-c8950df6e141' AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  IF COALESCE(NULLIF(current_setting('inform.allow_closed_season_write', true), ''), 'off') <> 'off' THEN
    RAISE EXCEPTION 'POST: the closed-season override is still on';
  END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = 'a9e23e62-7572-4d78-860c-c8950df6e141' AND NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0234 (2026-09-24): DUPLICATE of%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: duplicate not deactivated with the note'; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = '08f933cc-fc44-4066-b512-654025f6cccc' AND politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: race row not on the twin'; END IF;
  SELECT count(*) INTO v_n FROM essentials.quotes
   WHERE id = 'b9be256a-2dc1-40da-b728-1227234cd642' AND politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: quote not on the twin'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a JOIN _ans x USING (topic_id, season_id)
   WHERE a.politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab';
  IF v_n <> 10 THEN RAISE EXCEPTION 'POST: % of 10 answers on the twin', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context c JOIN _ans x USING (topic_id, season_id)
   WHERE c.politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab';
  IF v_n <> 10 THEN RAISE EXCEPTION 'POST: % of 10 context rows on the twin', v_n; END IF;

  -- nothing left on the duplicate but its image
  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141')
       + (SELECT count(*) FROM essentials.quotes WHERE politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141')
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141')
       + (SELECT count(*) FROM inform.politician_context WHERE politician_id = 'a9e23e62-7572-4d78-860c-c8950df6e141')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows still on the duplicate', v_n; END IF;

  -- the twin still holds its seat, and is the only active Mark Baisley
  SELECT count(*) INTO v_n FROM essentials.office_current_holder WHERE politician_id = '3b8ff5f8-582a-4044-9a19-dc63b6d6a7ab';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: twin holds % seats, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE is_active AND lower(full_name) = 'mark baisley';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active Mark Baisley rows', v_n; END IF;

  RAISE NOTICE 'CA_0234 applied: duplicate deactivated; race row, quote, 10 answers and 10 context rows on the seated twin';
END $$;

COMMIT;
