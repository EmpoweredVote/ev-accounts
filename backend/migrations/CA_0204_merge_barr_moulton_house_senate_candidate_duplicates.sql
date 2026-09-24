-- CA_0204_merge_barr_moulton_house_senate_candidate_duplicates.sql
-- Merge two sitting U.S. Representatives who are each split across two essentials.politicians rows: a seated
-- House row and a separate "Candidate for U.S. Senate" row. Found 2026-09-23 while auditing federal duplicates
-- (same shape as CA_0180's Menjivar/Strickland Senate duplicates, one level up).
--
--   Andy Barr    seated  164fb70e-b8c1-48cd-a6ef-12d80165c67d  U.S. Representative [KY], is_incumbent true
--                candidate d6d297f5-5319-4be1-b938-6bcce63368e7  Candidate for U.S. Senate — Kentucky, is_incumbent false
--   Seth Moulton seated  77f162cd-6ca0-4073-84e1-1c8ab87eb1e0  Representative [MA], is_incumbent true
--                candidate 5ccb1f15-f285-470c-b86a-97f9e6b22dff  Candidate for U.S. Senate — Massachusetts, is_incumbent false
--
-- Evidence they are the same person, not a Mike-Rogers-style coincidence (three real, distinct "Mike Rogers"
-- rows exist in this table and are NOT touched here):
--   - Same full_name, first_name, last_name, party on both rows of each pair.
--   - FEC candidate IDs follow the same person-pair shape as the NINE correctly-modeled Representatives running
--     for Senate (Angie Craig H6MN02131/S6MN00499, Chris Pappas H8NH01210/S6NH00141, etc. — one politician row
--     holding both a fec_house and a fec_senate politician_sources row): Barr holds fec_house H0KY06104 (seated)
--     and fec_senate S6KY00286 (candidate); Moulton holds fec_house H4MA06090 (seated) and fec_senate S6MA00296
--     (candidate).
--   - Both rows of each pair carry a headshot (photo_origin_url) and independent stance research (compass
--     answers), not an empty scrape stub — this is not the CA_0180 shape (a real row vs. an inert Cicero dup);
--     it is two independently-populated rows for the same officeholder.
--   - Season 2 (open) answers that exist on both rows of a pair agree exactly on every shared topic (Barr:
--     Same-Sex Marriage 5/5; Moulton: Affordable Housing 3/3, Same-Sex Marriage 2/2) — zero conflicts.
--   - A sweep for the same shape (`essentials.politicians` sharing a full_name where one row holds a federal
--     seat via essentials.office_current_holder and another holds an essentials.office_terms row on an office
--     titled 'Candidate for%') returns exactly these two pairs plus the known Mike Rogers false positive
--     (dafa64fd.../ace0b96d... — Rep. Mike Rogers of Alabama vs. former Rep. Mike Rogers of Michigan, different
--     people, different party incumbency shape; left untouched).
--
-- Survivor is the seated House row in both cases (it holds the office_current_holder-visible seat and the
-- larger House campaign's confirmed money). Moved onto it:
--   - The Senate candidacy's essentials.office_terms row (politician_id repointed — the row itself is untouched,
--     an open-ended term with unknown start; essentials.office_terms's exclusion constraint is keyed on
--     office_id + daterange, not politician_id, so repointing this existing row cannot create an overlap).
--   - The Senate fec_senate transparent_motivations.politician_sources row (essentials_politician_id repointed;
--     no collision with the seated row's fec_house row — different source_system/external_id. Contribution
--     aggregates key off politician_source_id, so they follow the id unchanged; confirmed totals combine to
--     29,421,425.95 (Barr) and 17,124,218.85 (Moulton), verified below).
--   - Barr's essentials.race_candidates row for the KY Senate race (politician_id repointed; the candidate row
--     is the only one of the two that carries it). Moulton's Senate race_candidates row already points at the
--     seated row — nothing to move there.
--   - finance_summary (jsonb column on essentials.politicians): the candidate row's version overwrites the
--     seated row's, per the finance-summary job's own tie-break rule ("sought seat's committee wins", PR #676)
--     — the survivor is now itself the sought-seat candidate. Barr's seated row had none (NULL); Moulton's
--     seated row already carried a partial, stale copy of the same committee's numbers (identical top_donors,
--     missing total_raised) — this replaces it with the fuller version from the candidate row.
--
-- NOT moved: inform.politician_answers / inform.politician_context. Season 1 is CLOSED and both tables are
-- BEFORE INSERT/UPDATE/DELETE-guarded immutable for closed-season rows (inform.closed_season_is_immutable) —
-- a merge cannot touch those rows even if it wanted to. Season 2 rows (1-2 per row) have zero conflicts (see
-- above) but are left in place rather than partially merged, matching the CA_0180 precedent of leaving compass
-- answers on the deactivated row untouched. Unlike Strickland's small conflict set, these two pairs disagree on
-- a meaningful share of their closed-season answers — Barr on 5 of 14 shared Season-1 topics (Civil Rights,
-- Fossil Fuel Policy, Religious Freedom, Reproductive Rights, Taxation and Public Spending), Moulton on 8 of 22
-- (Deportation Priorities, Fossil Fuel Policy, Immigration, Jail Capacity, Reproductive Rights, School Vouchers
-- — a 5-vs-1 swing, the largest — Social Security, Tariff Policy). This is a stance-review lead for a future
-- pass, not something this migration resolves: the seated row's answers stay visible under the seated row,
-- the candidate row's (different) answers stay on the now-deactivated candidate row, invisible to voters.
--
-- Also NOT moved (all zero for both loser rows, checked against every table with a politician_id FK into
-- essentials.politicians): empower.empowered_profiles, inform.evidence_items, essentials.addresses,
-- essentials.politician_committees, essentials.politician_contacts, essentials.degrees, essentials.experiences,
-- essentials.identifiers, meetings.la_council_votes, politician_id_bridge, essentials.politician_name_aliases,
-- essentials.quest_verified_facts, inform.stance_research_review, inform.topic_rewrite_stance_proposals.
-- essentials.politician_images (1 row per politician, keyed by that row's own id in its storage path) is left
-- on each row as-is: both seated rows already carry their own photo_origin_url, so there is nothing to backfill
-- (the CA_0180 "copy if empty" step does not apply here).
--
-- Then each candidate row is deactivated (is_active = false, is_incumbent was already false) with a note.
-- Nothing is deleted.
--
-- STATUS: NOT YET APPLIED. Dry-run only (BEGIN ... ROLLBACK), pending operator go-ahead.
--
-- ROLLBACK (in this order, once applied):
--   1. Re-point the moved office_terms / politician_sources / race_candidates rows back to their candidate row
--      (ids are listed below); strip the ' | merged onto <seated id> by CA_0204 (2026-09-23)' suffix from the
--      office_terms.source this file appended.
--   2. Restore each seated row's prior finance_summary (Barr: NULL; Moulton: the partial jsonb without
--      total_raised — see the header for its shape) and set is_active = true on both candidate rows; strip the
--      'CA_0204 (2026-09-23): DUPLICATE of' notes entry from each.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (loser uuid PRIMARY KEY, keep uuid, who text) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('d6d297f5-5319-4be1-b938-6bcce63368e7', '164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr'),
  ('5ccb1f15-f285-470c-b86a-97f9e6b22dff', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton');

-- the Senate-candidacy office_terms row on each loser (measured 2026-09-23: exactly 1 each)
CREATE TEMP TABLE _term (id uuid PRIMARY KEY, loser uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _term VALUES
  ('c3bc0db8-68b7-45fc-9388-e1efe98aa8a6', 'd6d297f5-5319-4be1-b938-6bcce63368e7', '164fb70e-b8c1-48cd-a6ef-12d80165c67d'),
  ('201d7962-f1a8-4366-a57d-54d963856d15', '5ccb1f15-f285-470c-b86a-97f9e6b22dff', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0');

-- the fec_senate politician_sources row on each loser (1 each; neither collides with the seated row's fec_house row)
CREATE TEMP TABLE _src (id uuid PRIMARY KEY, loser uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _src VALUES
  ('5bd22e6a-4b4e-4568-80dc-69b1d56d5dc3', 'd6d297f5-5319-4be1-b938-6bcce63368e7', '164fb70e-b8c1-48cd-a6ef-12d80165c67d'),
  ('f73913f1-296a-44e5-a0d6-0a4a3aa3be08', '5ccb1f15-f285-470c-b86a-97f9e6b22dff', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0');

-- only Barr's Senate race_candidates row needs to move; Moulton's is already on the seated row
CREATE TEMP TABLE _race (id uuid PRIMARY KEY, loser uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _race VALUES
  ('3394da15-8552-402b-b346-ec48edccbecd', 'd6d297f5-5319-4be1-b938-6bcce63368e7', '164fb70e-b8c1-48cd-a6ef-12d80165c67d');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT pr.keep,
       (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.essentials_politician_id IN (pr.keep, pr.loser)) AS pair_total
FROM _pair pr;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each pair: same full_name, keep is active+incumbent holding a federal seat, loser is not-incumbent (its
  -- is_active is left alone by this check since deactivating it is this migration's own outcome — true before
  -- a first run, false after)
  -- EXISTS, not a JOIN, against office_current_holder: that view is one row per OFFICE, and after this
  -- migration runs once the seated row holds two current offices (House + the moved Senate candidacy), so a
  -- politician_id-rooted JOIN would fan out to 2 rows per pair on a re-run (the exact office_current_holder
  -- trap this repo's CLAUDE.md warns about) and miscount idempotency checks below.
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep AND k.full_name = pr.who AND k.is_active AND k.is_incumbent
    JOIN essentials.politicians d ON d.id = pr.loser AND d.full_name = pr.who AND NOT d.is_incumbent
   WHERE EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = pr.keep);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 pairs match (seated federal incumbent holding a seat, same-named non-incumbent loser)', v_n; END IF;

  -- the loser's only office_terms row is the one we are about to move (or it has already been moved by a prior run)
  SELECT count(*) INTO v_n FROM _term t
   WHERE EXISTS (SELECT 1 FROM essentials.office_terms x WHERE x.id = t.id AND x.politician_id IN (t.loser, t.keep));
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 term rows are on their loser or seated row', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id IN (SELECT loser FROM _pair) AND id NOT IN (SELECT id FROM _term);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % extra office_terms row(s) on a loser were not reviewed', v_n; END IF;

  SELECT count(*) INTO v_n FROM _src s
   WHERE EXISTS (SELECT 1 FROM transparent_motivations.politician_sources x WHERE x.id = s.id AND x.essentials_politician_id IN (s.loser, s.keep));
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 source rows are on their loser or seated row', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id IN (SELECT loser FROM _pair) AND id NOT IN (SELECT id FROM _src);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % extra politician_sources row(s) on a loser were not reviewed', v_n; END IF;
  -- no collision: the seated row must not already hold a source with the same (source_system, external_id)
  SELECT count(*) INTO v_n FROM _src x JOIN transparent_motivations.politician_sources a ON a.id = x.id
    JOIN transparent_motivations.politician_sources b ON b.essentials_politician_id = x.keep AND b.id <> a.id
         AND b.source_system = a.source_system AND b.external_id = a.external_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % source link(s) would collide on the seated row', v_n; END IF;

  SELECT count(*) INTO v_n FROM _race r
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.id = r.id AND x.politician_id IN (r.loser, r.keep));
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Barr''s race_candidates row is not on the candidate or seated row (id changed unexpectedly)'; END IF;

  RAISE NOTICE 'CA_0204 pre-flight OK';
END $$;

-- ─── Move the Senate-candidacy term, FEC source link, and (Barr only) race_candidates row ───────
UPDATE essentials.office_terms t
   SET politician_id = x.keep,
       source = t.source || ' | merged onto ' || x.keep::text || ' by CA_0204 (2026-09-23)'
  FROM _term x
 WHERE t.id = x.id AND t.politician_id = x.loser;

UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = x.keep, updated_at = now()
  FROM _src x WHERE ps.id = x.id AND ps.essentials_politician_id = x.loser;

UPDATE essentials.race_candidates rc
   SET politician_id = x.keep
  FROM _race x WHERE rc.id = x.id AND rc.politician_id = x.loser;

-- finance_summary: the candidate row's (the sought seat) wins, per the single-writer job's own rule
UPDATE essentials.politicians k
   SET finance_summary = d.finance_summary
  FROM _pair pr JOIN essentials.politicians d ON d.id = pr.loser
 WHERE k.id = pr.keep AND d.finance_summary IS NOT NULL AND d.finance_summary IS DISTINCT FROM k.finance_summary;

-- deactivate the candidate rows; nothing deleted
UPDATE essentials.politicians d
   SET is_active = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0204 (2026-09-23): DUPLICATE of ' || pr.keep::text
               || ', the seated House row for the same Representative. Senate-candidacy office_terms row, FEC '
               || 'fec_senate link' || (CASE WHEN pr.loser = 'd6d297f5-5319-4be1-b938-6bcce63368e7'
                                             THEN ' and race_candidates row' ELSE '' END)
               || ' moved there. Compass answers left here (Season 1 is closed and immutable either way; some '
               || 'disagree with the seated row''s answers on the same topics — a stance-review lead). '
               || 'Deactivated, not deleted.')
  FROM _pair pr
 WHERE d.id = pr.loser AND d.is_active;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric; v_before numeric;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % office_terms row(s) still on a loser', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_terms t JOIN _term x ON x.id = t.id
   WHERE t.politician_id = x.keep AND strpos(t.source, 'merged onto ' || x.keep::text || ' by CA_0204') > 0;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 term rows moved and marked', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % politician_sources row(s) still on a loser', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT keep FROM _pair);
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % politician_sources rows on the seated rows, expected 4 (2 fec_house + 2 fec_senate)', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id = 'd6d297f5-5319-4be1-b938-6bcce63368e7';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: Barr''s race_candidates row is still on the candidate row'; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE politician_id IN ('164fb70e-b8c1-48cd-a6ef-12d80165c67d','77f162cd-6ca0-4073-84e1-1c8ab87eb1e0');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 seated rows hold their Senate race_candidates row', v_n; END IF;

  PERFORM 1 FROM essentials.politicians WHERE id = '164fb70e-b8c1-48cd-a6ef-12d80165c67d' AND (finance_summary->>'total_raised')::numeric = 9981055.48;
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Barr seated row finance_summary was not copied from the candidate row'; END IF;
  PERFORM 1 FROM essentials.politicians WHERE id = '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND (finance_summary->>'total_raised')::numeric = 5651172.00;
  IF NOT FOUND THEN RAISE EXCEPTION 'POST: Moulton seated row finance_summary was not copied from the candidate row'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians WHERE id IN ('d6d297f5-5319-4be1-b938-6bcce63368e7','5ccb1f15-f285-470c-b86a-97f9e6b22dff')
    AND NOT is_active AND NOT is_incumbent AND EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0204 (2026-09-23): DUPLICATE of%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 candidate rows deactivated with the note', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE id IN ('164fb70e-b8c1-48cd-a6ef-12d80165c67d','77f162cd-6ca0-4073-84e1-1c8ab87eb1e0') AND is_active AND is_incumbent;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 seated rows still active incumbents', v_n; END IF;

  -- both federal seats are still (now more clearly) held by the seated rows
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och JOIN _pair pr ON pr.keep = och.politician_id
   JOIN essentials.offices o ON o.id = och.office_id JOIN essentials.chambers ch ON ch.id = o.chamber_id
  WHERE ch.name = 'U.S. House of Representatives';
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 House seats still held by the seated rows', v_n; END IF;

  -- nothing deleted: the candidate rows' compass answers/context are exactly as they were (17+18 / 34+25 total)
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 43 THEN RAISE EXCEPTION 'POST: % answers on the candidate rows, expected 43 (18 Barr + 25 Moulton, untouched)', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE politician_id IN (SELECT loser FROM _pair);
  IF v_n <> 46 THEN RAISE EXCEPTION 'POST: % context rows on the candidate rows, expected 46 (21 Barr + 25 Moulton, untouched)', v_n; END IF;

  -- no money created or destroyed: the pair's combined confirmed total is unchanged, just re-attributed
  FOR v_before, v_amt IN
    SELECT b.pair_total, (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                            JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                           WHERE ps.essentials_politician_id = b.keep)
    FROM _before b
  LOOP
    IF v_before <> v_amt THEN RAISE EXCEPTION 'POST: pair confirmed total moved from % to %, expected unchanged', v_before, v_amt; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0204 applied: 2 duplicate pairs merged (Andy Barr, Seth Moulton) — office_terms, FEC source link, finance_summary and (Barr) race_candidates moved onto the seated House row; candidate rows deactivated';
END $$;

COMMIT;
