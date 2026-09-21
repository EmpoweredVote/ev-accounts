-- 1860_merge_jim_priest_retire_mace_unsourceable_quote.sql
--
-- Slot 1860 reserved via `npm run steward --prefix backend -- slot shared`. An earlier draft of
-- this file was numbered 1856 by reading max(num) by hand; the allocator returned 1860, because
-- 1856-1859 were already claimed by sessions that had not pushed. CLAUDE.md is right that counting
-- is the bug, not a fallback.
--
-- Two unrelated repairs found by the same 2026-09-12 pass over quotes that Read & Rank cannot
-- reach. Both are small. Neither makes a new topic rankable — that is stated up front so nobody
-- reads a visibility win into this file.
--
-- No migration runner exists; this file records SQL applied by hand.
--
-- ===========================================================================================
-- PART A — Merge the two Jim Priest rows (OK U.S. Senate 2026)
-- ===========================================================================================
-- Jim Priest exists twice. Both rows carry 5 quotes cited to the SAME page,
-- jimpriest.com/newfairdeal, so three of them are near-duplicates of each other.
--
--   KEEP  91dcb66a  ext -66000114  5 quotes (ALL readrank_selected) · 1 race edge · 1 image · 6 answers
--   DROP  0bba9f72  ext NULL       5 quotes (2 selected)            · 0 race edges · 1 image · 6 answers
--                                  · 1 office_term "Candidate for U.S. Senate - Oklahoma"
--
-- 🔴 THE KEEP RULE IS INVERTED HERE, ON PURPOSE. Migration 1554 (AZ) and 1555 (Bennett) keep the
--   row that holds the real office. Neither Priest row holds a real office: he is a challenger,
--   and 0bba9f72's only office_term is a "Candidate for ..." placeholder of the kind migration 196
--   created for Talarico and Paxton. So the tie is broken on content instead. 91dcb66a wins because
--   it holds the race edge, all five selections, and the fuller wording — for example
--   "Jim will end reckless tariffs, restore Congress's authority, and rebuild the trust that makes
--   America a beacon of democracy again." against the other row's bare "End reckless tariffs".
--   The placeholder office_term MOVES to the kept row rather than being deleted, because the kept
--   row has none and it is Priest's only office record.
--
-- 🔴 A NAIVE REPOINT WOULD VIOLATE A UNIQUE INDEX. quotes_one_selected_per_legacy_stance is
--   UNIQUE (politician_id, lower(topic_key)) WHERE readrank_selected AND question_id IS NULL.
--   BOTH rows hold a SELECTED quote on school-vouchers AND on tariffs. Moving them would put two
--   selected quotes on one topic for one person and abort. The rule used below avoids the index
--   entirely: move a quote only when the kept row has no quote on that topic; delete the rest as
--   duplicates. Nothing selected is discarded — every deleted row's topic is already represented
--   on the kept row by an equal or fuller quote.
--
--     topic             DROP row                         KEEP row                        action
--     ---------------   ------------------------------   -----------------------------   --------------
--     campaign-finance  "Banning congressional stock      (none)                          MOVE
--                        trading" (draft)
--     climate-change    "Protect natural resources        (none)                          MOVE
--                        responsibly" (draft)
--     childcare         "Expand affordable childcare"     "Expand affordable childcare."  DELETE (dup)
--                        (draft)                          (selected)
--     school-vouchers   "...raise teacher pay"            "...raise teacher pay."         DELETE (dup)
--                        (SELECTED)                       (selected)
--     tariffs           "End reckless tariffs"            "Jim will end reckless          DELETE (dup)
--                        (SELECTED)                        tariffs, ..." (selected)
--
--   Net: the kept row goes from 5 quotes to 7. Selected count stays 5. No topic changes meaning.
--
-- NO RANKABLE GAIN — VERIFIED, NOT ASSUMED. Priest sits on the 2026 Oklahoma Primary Runoff
--   (race 19cb9ec1), NOT the OK 2026 Statewide General. His only opponent there is N'Kiyla Thomas.
--   Their selected topics already overlap on childcare and healthcare, so that race has 2 rankable
--   topics today and still has 2 afterwards. The two quotes this migration moves are drafts on
--   campaign-finance and climate-change, and Thomas holds neither. Read & Rank needs >= 2
--   candidates per topic (readrankService.ts:414 and :453).
--
-- 🔴 COMPASS ANSWERS ARE LEFT WHERE THEY ARE, AND THAT IS A DECISION, NOT AN OVERSIGHT.
--   The dropped row holds 6 answers, ALL in Season 1, which is CLOSED. The kept row holds 5 in
--   Season 1 and 1 in Season 2 (open). Two topics exist only on the dropped row:
--   campaign-finance (2.0) and climate-change (3.0), both Season 1.
--
--   inform.closed_season_is_immutable() (CC_0044, ADR 0005 s1.6 step 5) blocks any write against a
--   closed season. A first draft of this migration tried to move them and was correctly refused.
--   Three ways forward existed:
--     (a) leave them            — chosen here
--     (b) copy into open Season 2 — REJECTED: it would manufacture a current-season datapoint out
--                                  of Season 1 research, asserting a present position nobody verified
--     (c) SET LOCAL inform.allow_closed_season_write = 'on' and move them inside Season 1
--
--   (a) is chosen because a closed season records what was true at the time, and at the time the
--   record genuinely was split across two rows. Rewriting it would make history assert a unified
--   record that never existed. Nothing user-facing reads these two draft answers: the row holding
--   them is deactivated by this migration, and neither topic is selected on any quote.
--   If full unification is later wanted, (c) is the sanctioned route and needs its own migration
--   saying why. Migration 1572 moved answers between duplicate rows freely, but it predates CC_0044.
--
-- ===========================================================================================
-- PART B — Retire one unsourceable Nancy Mace quote
-- ===========================================================================================
--   c8be0517  Mace / taxes  "Every government dollar would be better spent by taxpayers."
--             cited to https://www.atr.org/legislators/nancy-mace/
--
-- The sentence is NOT on the cited page. That page records only that she signed the Americans for
-- Tax Reform Taxpayer Protection Pledge; it carries no quotation from her. An open-web search for
-- the exact sentence returns no instance of it anywhere. Her real positions on this subject are
-- well documented (a Penny Plan, an income-tax elimination proposal) — this particular sentence
-- is not. It reads as a rewritten pledge summary, the same failure mode migration 1809 recorded
-- for Becerra / deportation.
--
-- 🔴 THIS ONE IS LIVE, WHICH 1809 REFUSED TO DO. Migration 1809 hard-deleted six unsourceable
--   quotes but aborted if any was selected, on the grounds that a live quote needs a human. This
--   row IS readrank_selected = true. It is deleted anyway, for a reason that did not apply there:
--   Nancy Mace holds NO race_candidates edge, so the quote is unreachable through Read & Rank and
--   cannot be on a live card. Nothing is being pulled out from under a voter. It also has zero
--   references in readrank_questions, inform.compass_verdicts, public.source_verifications and
--   compass_deprecated.quote_verdicts — all four checked.
--
--   Mace is ALSO not a 2026 SC-01 candidate. She entered the South Carolina governor's race on
--   2025-08-04 and does not appear on the SC-01 primary ballot. The SC-01 roster correctly holds
--   no incumbent. Do not "fix" her missing race edge by attaching her to SC-01.
--
-- The full trace is in on-the-record docs/audits/2026-09-12-mace-atr-quote-trace.md.

BEGIN;

-- -------------------------------------------------------------------------------------------
-- PART A
-- -------------------------------------------------------------------------------------------
CREATE TEMP TABLE priest(keep_id uuid, lose_id uuid) ON COMMIT DROP;
INSERT INTO priest VALUES
  ('91dcb66a-9e36-4e95-9be6-13c07503a4ea', '0bba9f72-0b24-4956-9c91-590fbd3a36a6');

DO $$
DECLARE k int; l int; kr int; lr int;
BEGIN
  SELECT count(*) INTO k FROM essentials.politicians p JOIN priest m ON p.id = m.keep_id
   WHERE lower(p.full_name) = 'jim priest';
  SELECT count(*) INTO l FROM essentials.politicians p JOIN priest m ON p.id = m.lose_id
   WHERE lower(p.full_name) = 'jim priest';
  IF k <> 1 OR l <> 1 THEN
    RAISE EXCEPTION 'Priest rows not found as expected (keep=%, lose=%)', k, l;
  END IF;

  SELECT count(*) INTO kr FROM essentials.race_candidates rc JOIN priest m ON rc.politician_id = m.keep_id;
  SELECT count(*) INTO lr FROM essentials.race_candidates rc JOIN priest m ON rc.politician_id = m.lose_id;
  IF kr < 1 THEN RAISE EXCEPTION 'kept Priest row holds no race edge — keep/lose may be inverted'; END IF;
  IF lr <> 0 THEN RAISE EXCEPTION 'dropped Priest row unexpectedly holds % race edge(s)', lr; END IF;
END $$;

-- Quotes: move only topics the kept row lacks; delete the duplicates.
UPDATE essentials.quotes q
   SET politician_id = m.keep_id
  FROM priest m
 WHERE q.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM essentials.quotes k
                    WHERE k.politician_id = m.keep_id
                      AND lower(k.topic_key) = lower(q.topic_key));
DELETE FROM essentials.quotes q USING priest m WHERE q.politician_id = m.lose_id;

-- Compass answers / context: DELIBERATELY NOT TOUCHED. See the header note on Season 1.
-- Office term: the placeholder is his only office record; move it to the kept row.
UPDATE essentials.office_terms t SET politician_id = m.keep_id
  FROM priest m WHERE t.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms k WHERE k.politician_id = m.keep_id);
DELETE FROM essentials.office_terms t USING priest m WHERE t.politician_id = m.lose_id;

-- Portrait: one person, one portrait.
UPDATE essentials.politician_images i SET politician_id = m.keep_id
  FROM priest m WHERE i.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images k WHERE k.politician_id = m.keep_id);
DELETE FROM essentials.politician_images i USING priest m WHERE i.politician_id = m.lose_id;

-- Anything else that could still point at the dropped row.
UPDATE essentials.race_candidates rc SET politician_id = m.keep_id FROM priest m WHERE rc.politician_id = m.lose_id;
UPDATE meetings.speakers s          SET politician_id = m.keep_id FROM priest m WHERE s.politician_id = m.lose_id;
UPDATE essentials.politician_contacts c SET politician_id = m.keep_id FROM priest m WHERE c.politician_id = m.lose_id;

UPDATE essentials.politicians p
   SET is_active = false,
       notes = COALESCE(p.notes, '{}'::text[])
               || ('merged into politician ' || m.keep_id::text
                   || ' by migration 1860 on 2026-09-12 (duplicate Jim Priest row; kept row holds '
                   || 'the race edge and the fuller quotes)')
  FROM priest m
 WHERE p.id = m.lose_id AND p.is_active;

-- -------------------------------------------------------------------------------------------
-- PART B
-- -------------------------------------------------------------------------------------------
DO $$
DECLARE n int; refs int;
BEGIN
  -- Idempotent: 1 on first run, 0 on any re-run once retired. Anything else is a surprise.
  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a';
  IF n > 1 THEN RAISE EXCEPTION 'expected at most 1 Mace quote to retire, found %', n; END IF;

  IF n = 1 THEN
  SELECT (SELECT count(*) FROM essentials.readrank_questions WHERE origin_quote_id = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a')
       + (SELECT count(*) FROM inform.compass_verdicts        WHERE quote_id        = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a')
       + (SELECT count(*) FROM public.source_verifications    WHERE quote_id        = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a')
       + (SELECT count(*) FROM compass_deprecated.quote_verdicts WHERE quote_id     = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a')
    INTO refs;
  IF refs <> 0 THEN RAISE EXCEPTION 'Mace quote is referenced by % row(s); resolve before deleting', refs; END IF;

  -- The quote is live. That is allowed here ONLY because she holds no race edge.
  IF EXISTS (SELECT 1 FROM essentials.race_candidates rc
              JOIN essentials.politicians p ON p.id = rc.politician_id
             WHERE p.external_id = -45001) THEN
    RAISE EXCEPTION 'Nancy Mace now holds a race edge — a live quote would be on a card. Stop and review.';
  END IF;
  END IF;
END $$;

DELETE FROM essentials.quotes WHERE id = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a';

-- -------------------------------------------------------------------------------------------
-- VERIFY
-- -------------------------------------------------------------------------------------------
DO $$
DECLARE r record; n int; sel int; rankable int;
BEGIN
  SELECT * INTO r FROM priest LIMIT 1;

  -- dropped row must be inert
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.lose_id AND is_active) THEN
    RAISE EXCEPTION 'dropped Priest row is still active';
  END IF;
  -- Compass answers/context are excluded on purpose (closed Season 1 — see header).
  SELECT (SELECT count(*) FROM essentials.quotes            WHERE politician_id = r.lose_id)
       + (SELECT count(*) FROM essentials.race_candidates   WHERE politician_id = r.lose_id)
       + (SELECT count(*) FROM essentials.politician_images WHERE politician_id = r.lose_id)
       + (SELECT count(*) FROM essentials.office_terms      WHERE politician_id = r.lose_id)
       + (SELECT count(*) FROM meetings.speakers            WHERE politician_id = r.lose_id)
    INTO n;
  IF n <> 0 THEN RAISE EXCEPTION '% non-compass references still attached to the dropped Priest row', n; END IF;

  -- and the Season 1 answers must be exactly as they were: untouched, not moved, not deleted.
  SELECT count(*) INTO n FROM inform.politician_answers WHERE politician_id = r.lose_id;
  IF n <> 6 THEN RAISE EXCEPTION 'dropped row Season 1 answers = %, expected 6 untouched', n; END IF;

  -- kept row: 7 quotes, still exactly 5 selected, race edge intact
  SELECT count(*) INTO n   FROM essentials.quotes WHERE politician_id = r.keep_id;
  SELECT count(*) INTO sel FROM essentials.quotes WHERE politician_id = r.keep_id AND readrank_selected;
  IF n <> 7   THEN RAISE EXCEPTION 'kept Priest row has % quotes, expected 7', n; END IF;
  IF sel <> 5 THEN RAISE EXCEPTION 'kept Priest row has % selected quotes, expected 5', sel; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE politician_id = r.keep_id) THEN
    RAISE EXCEPTION 'kept Priest row lost its race edge';
  END IF;

  -- no two selected quotes on one topic (the index this migration was written to avoid)
  SELECT count(*) INTO n FROM (
    SELECT lower(topic_key) FROM essentials.quotes
     WHERE politician_id = r.keep_id AND readrank_selected AND question_id IS NULL
     GROUP BY 1 HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION '% topics carry two selected quotes on the kept row', n; END IF;

  -- the runoff race must still have exactly the 2 rankable topics it had before
  SELECT count(*) INTO rankable FROM (
    SELECT lower(q.topic_key)
      FROM essentials.race_candidates rc
      JOIN essentials.quotes q ON q.politician_id = rc.politician_id
       AND q.readrank_selected AND q.deidentified_text IS NOT NULL
      JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live
     WHERE rc.race_id = '19cb9ec1-e0cf-4dea-9b6a-d2d6bf4f2ce6'
       AND COALESCE(rc.candidate_status,'active') <> 'withdrawn'
     GROUP BY 1 HAVING count(DISTINCT rc.politician_id) >= 2) x;
  IF rankable <> 2 THEN
    RAISE EXCEPTION 'OK runoff rankable topics = %, expected 2 (childcare, healthcare)', rankable;
  END IF;

  -- Mace quote gone
  IF EXISTS (SELECT 1 FROM essentials.quotes WHERE id = 'c8be0517-26e2-4e0a-9b4c-0cf7a67d8c4a') THEN
    RAISE EXCEPTION 'Mace quote still present';
  END IF;

  RAISE NOTICE 'PASSED: Priest merged (kept row 7 quotes / 5 selected / race edge intact; 6 closed-season answers deliberately left on the deactivated row), OK runoff still 2 rankable topics, 1 unsourceable Mace quote retired.';
END $$;

COMMIT;
