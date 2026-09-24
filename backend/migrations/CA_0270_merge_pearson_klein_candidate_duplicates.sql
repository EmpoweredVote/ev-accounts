-- CA_0270_merge_pearson_klein_candidate_duplicates.sql
-- Identity merge of two sitting state legislators who are each split across two essentials.politicians rows: a
-- 2026 U.S. House candidate row (holding the compass answers, quotes, FEC link and race row) and a separate
-- state-legislature row (holding only the seat). The SEAT moves to the candidate row; nothing else moves.
-- Same survivor rule as CA_0227 (N'Kiyla Thomas): keep the row whose Season 1 answers would otherwise have to move.
--
-- Slot CA_0270 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- ✅ APPLIED to prod 2026-09-24 (approval: Chris Andrews). UPDATE 2/2/2/2/2/2/1, both gates green. Dry run x2 (BEGIN ...
--   ROLLBACK) passed and was confirmed reverted before the apply. Re-read after: 5d56470c and 5e86fb53 are the active
--   incumbents holding TN House 86 / MN Senate 53 with 4 / 6 answers, 1 / 5 quotes, 1 race row each and external_id
--   -4720086 / -2732185; de50a88b and 4966792b are inactive and hold nothing.
--
-- 🟢 SEASON 1 IS NOT TOUCHED. Ruling 2026-09-24 (Chris Andrews): do not edit the closed season for a merge. The first
-- draft of this file moved the 10 Season 1 answers with inform.allow_closed_season_write (the CA_0184 / CA_0234
-- pattern); this version keeps them where they are and moves the seat instead. No inform.* row is written.
--
-- Found 2026-09-24 by CA_0267 (PR #764): once a leading middle initial moved out of last_name, first_name + surname
-- matched three pairs. Two are merged here. The third is already done.
--
-- THE PAIRS (seat row -> survivor):
--   1. JUSTIN J. PEARSON
--      de50a88b-1366-4088-bb0a-baeb16e19e2d (external_id -4720086, TN General Assembly seed 1855; created 2026-09-11;
--        holds State House District 86 via office_terms 0f19fb40; nothing else references it)
--        -> 5d56470c-fb82-42f7-82e3-d28bf74ace47 (external_id -470907, from 1197; the TN-9 candidate: 4 Season 1
--           answers + context, 1 quote, fec_house H6TN09449, race row 5273ca75, portrait).
--      ONE PERSON: the Tennessee General Assembly page for District 86 names "Representative Justin J. Pearson,
--      Democrat, Memphis" (capitol.tn.gov/house/members/h86.html). FEC H6TN09449 is "PEARSON, JUSTIN J.", Memphis
--      TN, TN-09, committee C00922633 "The Committee to Elect Justin J. Pearson". NBC News, 2025-10, reports the
--      "Tennessee Three legislator Justin Pearson" launching the TN-9 primary challenge to Rep. Steve Cohen, and the
--      TN SOS 2026-08-06 Democratic primary totals name "Justin J. Pearson" the District 9 winner (CA_0266). The
--      candidate row's own Season 1 context already reads "As a TN state representative Pearson ..." and cites his
--      state bill HB1393.
--   2. MATT D. KLEIN
--      4966792b-a05c-41df-8f4b-9b81deebb166 "Matt D. Klein" (external_id -2732185, MN legislature seed CC_0108; created
--        2026-09-14; holds State Senate District 53 via office_terms 8d5162d7, plus its own politician_images row)
--        -> 5e86fb53-a6eb-4b35-82de-79706a66dc1a "Matthew D. Klein" (external_id -270204, from 1211; the MN-2
--           candidate: 6 Season 1 answers + context, 5 quotes, fec_house H6MN02248, race row 13bdc18a, portrait).
--      ONE PERSON: the Minnesota Senate member page names "Senator Matt D. Klein (53, DFL)" (senate.mn, mem_id 1235).
--      FEC H6MN02248 is "KLEIN, MATTHEW DAVID", West St. Paul MN, MN-02, committee C00904292 "Matt Klein for
--      Congress", whose site (kleinforcongress.com) says he has served in the state Senate since 2017 and represents
--      Senate District 53. The candidate row's own Season 1 context cites his MN Senate committee work.
--   3. RICHARD A. HYER — NO CHANGE. 05624287 was already merged into 11c6810e (Ogden City Council District 2) and
--      deactivated by CA_0182 (applied 2026-09-23). Only its own politician_images row remains on it, as that
--      precedent leaves it. The pre-flight asserts this is still so. ogdencity.gov/164/Richard-Hyer: "District 2,
--      Term: January 2012 - December 2027".
--
-- WHAT CHANGES, per pair:
--   a. The seat's office_terms row is re-pointed to the survivor (term dates untouched; office_terms_no_overlap
--      excludes on (office_id, daterange), not politician_id). Its source gains ' | merged onto <id> by CA_0270'.
--   b. external_id is SWAPPED: the survivor takes the legislature seed's id, the seat row takes the candidate seed's.
--      Why: both legislature generators find people by external_id (1855's TN term insert joins
--      p.external_id = prefix - district; CC_0108's MN term insert and its NOT EXISTS person guard use external_id).
--      Without the swap, a re-run of either would find the DEACTIVATED seat row and try to seat it again. The
--      candidate ids (-470907, -270204) are referenced nowhere else in the repo (git grep, 2026-09-24).
--   c. The survivor is set is_incumbent = true explicitly (it now holds the seat; CLAUDE.md). Where the survivor's
--      source / data_source is NULL it takes the seat row's legislature citation. A CA_0270 note is appended; the
--      older CA_0181 note ("holds no seat") stays as history.
--   d. Klein only: the survivor takes the name the Senate and his campaign use — first_name 'Matt', full_name
--      'Matt D. Klein' — and keeps 'Matthew D. Klein' (his FEC name) in alternate_names with 'Matt Klein'.
--      last_name 'Klein' and middle_initial 'D.' are already right (CA_0267). His race row keeps "Matthew D. Klein",
--      the name he filed under. Pearson's names are already identical on both rows.
--   e. The seat row is deactivated (is_active = false, is_incumbent = false) with a note naming the survivor.
--
-- NOT CHANGED: every inform.* row (answers, context, evidence, review) — nothing there references the seat rows;
--   race_candidates, quotes, politician_sources (already on the survivor); photos (each survivor keeps its own
--   portrait; Klein's seat row keeps its own senate.mn image row, as CA_0229 / CA_0261 leave images).
--   finance_summary is NULL on all four rows. FOLLOW-UP after apply: run the federal finance-summary writer for both
--   survivors (backend/scripts/run-fec-finance-summary.ts --politician <id>).
-- check:stance-sources: the survivors' state bucket was their race state (tn, mn) and becomes their seat state (tn,
--   mn) — the same bucket, so the baseline does not move. check:duplicate-people (PR #773) lists both pairs as
--   same_person; after apply they are resolved.
-- ⚠ CA_0267's pre-flight matches Klein's candidate row by full_name 'Matthew D. Klein'. CA_0267 is applied and nothing
--   replays migrations, but a re-run of CA_0267 after this file would stop at its pre-flight.
--
-- ROLLBACK (once applied), per pair: re-point the office_terms row back to the seat row and strip its ' | merged onto'
--   suffix; swap external_id back (via NULL); set the survivor is_incumbent = false and remove its CA_0270 note (and,
--   for Klein, restore first_name 'Matthew', full_name 'Matthew D. Klein', alternate_names '{}'; clear the copied
--   source / data_source); set the seat row is_active = true, is_incumbent = true and remove its CA_0270 note.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (keep uuid PRIMARY KEY, seat uuid UNIQUE, term_id uuid, office_id uuid,
                         keep_ext bigint, seat_ext bigint, n_ans int, n_quotes int, who text) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('5d56470c-fb82-42f7-82e3-d28bf74ace47', 'de50a88b-1366-4088-bb0a-baeb16e19e2d', '0f19fb40-b1fc-4ff1-886f-f3007739764c',
   '03bf94b9-7c03-466d-99c6-594128709cfd', -470907, -4720086, 4, 1, 'Justin J. Pearson'),
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a', '4966792b-a05c-41df-8f4b-9b81deebb166', '8d5162d7-66d7-4520-a00f-206cec3e2311',
   '2eecc490-1173-46d0-a520-11a6ada9b2a7', -270204, -2732185, 6, 5, 'Matt D. Klein');

-- a fingerprint of everything on the survivors this file must NOT change
CREATE TEMP TABLE _inform_before ON COMMIT DROP AS
SELECT 'a' AS t, md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id)) AS h
  FROM inform.politician_answers a WHERE a.politician_id IN (SELECT keep FROM _pair)
UNION ALL
SELECT 'c', md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
  FROM inform.politician_context c WHERE c.politician_id IN (SELECT keep FROM _pair);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each seat term is on the seat row (first run) or already on the survivor (re-run), and it is the only term
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_terms t ON t.id = pr.term_id
   WHERE t.office_id = pr.office_id AND t.politician_id IN (pr.seat, pr.keep) AND t.term_end IS NULL;
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 reviewed seat terms in place', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms
   WHERE politician_id IN (SELECT seat FROM _pair UNION ALL SELECT keep FROM _pair);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % office_terms rows across the pairs, expected 2', v_n; END IF;
  -- the term is the office's current holder, so the survivor will show as seated
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_current_holder och ON och.office_id = pr.office_id
   WHERE och.politician_id IN (pr.seat, pr.keep);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 seats resolve to the pair as current holder', v_n; END IF;

  -- external_ids are in their pre-image or already swapped
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep JOIN essentials.politicians s ON s.id = pr.seat
   WHERE (k.external_id = pr.keep_ext AND s.external_id = pr.seat_ext)
      OR (k.external_id = pr.seat_ext AND s.external_id = pr.keep_ext);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 pairs have their reviewed external_ids', v_n; END IF;

  -- survivors: active, same surname, holding everything else of the person
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.is_active AND k.last_name IN ('Pearson', 'Klein') AND k.middle_initial IN ('J.', 'D.')
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM inform.politician_context c WHERE c.politician_id = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM essentials.quotes q WHERE q.politician_id = pr.keep) = pr.n_quotes
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = pr.keep) = 1
     AND (SELECT count(*) FROM transparent_motivations.politician_sources ps
           WHERE ps.essentials_politician_id = pr.keep AND ps.source_system = 'fec_house'
             AND ps.research_status = 'confirmed') = 1;
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 survivors hold their reviewed answers, quotes, race row and FEC link', v_n; END IF;

  -- seat rows: nothing but the term (and Klein's own image)
  SELECT (SELECT count(*) FROM inform.politician_answers        WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.politician_context        WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.stance_research_review    WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM inform.evidence_items            WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.race_candidates       WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.quotes                WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.politician_contacts   WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM essentials.politician_name_aliases WHERE politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT seat FROM _pair))
       + (SELECT count(*) FROM politician_id_bridge             WHERE essentials_id IN (SELECT seat FROM _pair))
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on a seat row that this file does not move', v_n; END IF;

  -- pair 3 (Hyer) needs nothing: CA_0182 left only the duplicate's own image row on it
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '05624287-c90f-40be-bada-12a883040d60' AND NOT is_active AND NOT is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0182 (2026-09-23): DUPLICATE of 11c6810e%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Hyer duplicate is no longer the inactive CA_0182 row'; END IF;
  SELECT (SELECT count(*) FROM essentials.race_candidates WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.office_terms WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM inform.politician_answers WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.quotes WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
       + (SELECT count(*) FROM essentials.politician_contacts WHERE politician_id = '05624287-c90f-40be-bada-12a883040d60')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows hang on the Hyer duplicate again; re-review', v_n; END IF;

  RAISE NOTICE 'CA_0270 pre-flight OK';
END $$;

-- ─── 1. Move the seat ────────────────────────────────────────────────────────────────────────────
UPDATE essentials.office_terms t
   SET politician_id = pr.keep,
       source = t.source || ' | merged onto ' || pr.keep::text || ' by CA_0270 (2026-09-24)'
  FROM _pair pr
 WHERE t.id = pr.term_id AND t.politician_id = pr.seat;

-- ─── 2. Swap external_id (unique, so through NULL) ───────────────────────────────────────────────
UPDATE essentials.politicians s SET external_id = NULL
  FROM _pair pr WHERE s.id = pr.seat AND s.external_id = pr.seat_ext
   AND EXISTS (SELECT 1 FROM essentials.politicians k WHERE k.id = pr.keep AND k.external_id = pr.keep_ext);
UPDATE essentials.politicians k SET external_id = pr.seat_ext
  FROM _pair pr WHERE k.id = pr.keep AND k.external_id = pr.keep_ext
   AND EXISTS (SELECT 1 FROM essentials.politicians s WHERE s.id = pr.seat AND s.external_id IS NULL);
UPDATE essentials.politicians s SET external_id = pr.keep_ext
  FROM _pair pr WHERE s.id = pr.seat AND s.external_id IS NULL;

-- ─── 3. Deactivate the seat rows (before any rename, so no two ACTIVE rows share a name) ────────
UPDATE essentials.politicians s
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(s.notes, ARRAY[]::text[]) || ('CA_0270 (2026-09-24): DUPLICATE of ' || pr.keep::text
               || ', the row that holds this person''s compass answers, quotes, FEC link and 2026 U.S. House race row. '
               || 'Its state-legislature seat (office_terms ' || pr.term_id::text || ') and its external_id moved '
               || 'there; deactivated, not deleted.')::text
  FROM _pair pr
 WHERE s.id = pr.seat AND (s.is_active OR s.is_incumbent);

-- ─── 4. The survivor now holds the seat ──────────────────────────────────────────────────────────
UPDATE essentials.politicians k
   SET is_incumbent = true,
       source       = COALESCE(k.source, s.source),
       data_source  = COALESCE(k.data_source, s.data_source),
       notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CA_0270 (2026-09-24): holds the state-legislature seat '
               || '(office_terms ' || pr.term_id::text || ') and external_id of ' || pr.seat::text
               || ', a duplicate row of the same person, now deactivated. Season 1 was not touched.')::text
  FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
 WHERE k.id = pr.keep
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0270 (2026-09-24): holds%');

UPDATE essentials.politicians
   SET first_name = 'Matt', full_name = 'Matt D. Klein', alternate_names = ARRAY['Matt Klein', 'Matthew D. Klein']
 WHERE id = '5e86fb53-a6eb-4b35-82de-79706a66dc1a' AND full_name = 'Matthew D. Klein' AND NOT full_name_manual_override;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each survivor is the active, seated incumbent, with the legislature's external_id
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.is_active AND k.is_incumbent AND k.external_id = pr.seat_ext AND k.full_name = pr.who
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = pr.office_id AND och.politician_id = pr.keep)
     AND EXISTS (SELECT 1 FROM essentials.office_terms t
                  WHERE t.id = pr.term_id AND t.politician_id = pr.keep
                    AND strpos(t.source, 'merged onto ' || pr.keep::text || ' by CA_0270') > 0)
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0270 (2026-09-24): holds%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 survivors are the seated incumbent with the swapped id and note', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '5e86fb53-a6eb-4b35-82de-79706a66dc1a' AND first_name = 'Matt' AND last_name = 'Klein'
     AND middle_initial = 'D.' AND alternate_names @> ARRAY['Matt Klein', 'Matthew D. Klein'];
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Klein''s survivor does not carry the reviewed names'; END IF;
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.source IS NOT NULL OR k.data_source IS NOT NULL;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 survivors carry a legislature citation', v_n; END IF;

  -- each seat row is inactive, holds nothing, and has the candidate's old external_id
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians s ON s.id = pr.seat
   WHERE NOT s.is_active AND NOT s.is_incumbent AND s.external_id = pr.keep_ext
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = s.id)
     AND EXISTS (SELECT 1 FROM unnest(s.notes) n WHERE n LIKE 'CA_0270 (2026-09-24): DUPLICATE of ' || pr.keep::text || '%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 seat rows deactivated, emptied and noted', v_n; END IF;

  -- 🟢 Season 1 untouched: the survivors' answers and context are byte-identical, and still complete
  SELECT count(*) INTO v_n FROM _inform_before b
   WHERE b.h IS DISTINCT FROM (
     CASE b.t
       WHEN 'a' THEN (SELECT md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id))
                        FROM inform.politician_answers a WHERE a.politician_id IN (SELECT keep FROM _pair))
       ELSE          (SELECT md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
                        FROM inform.politician_context c WHERE c.politician_id IN (SELECT keep FROM _pair))
     END);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: survivors'' answers or context changed; this file must not write inform.*'; END IF;
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = pr.keep) = pr.n_ans;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: survivors no longer hold 4 and 6 answers'; END IF;

  -- one active row per person
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE is_active AND ((first_name = 'Justin' AND last_name = 'Pearson')
                     OR (first_name IN ('Matt', 'Matthew') AND last_name = 'Klein'));
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % active Justin Pearson / Matt Klein rows, expected 2', v_n; END IF;

  RAISE NOTICE 'CA_0270 applied: seats moved onto the Pearson and Klein rows that hold their answers; duplicates deactivated; Season 1 untouched';
END $$;

COMMIT;
