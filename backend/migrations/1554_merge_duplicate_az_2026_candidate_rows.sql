-- 1545_merge_duplicate_az_2026_candidate_rows.sql
-- Merge 4 pairs of duplicate politician records created by the 2026-07-25 AZ hand-add session.
-- Idempotent (naturally: once the loser rows hold no references and are inactive, every
-- statement no-ops).
--
-- RENUMBERED 1534 -> 1545. Authored, applied to prod and verified as 1534 on 2026-08-03, then
--   left uncommitted; by commit time origin/master already carried a different 1534
--   (1534_clean_tracked_actonmass_archive_url.sql) and ran up to 1544, so
--   scripts/check-migration-numbers.mjs put the next free prefix at 1545. Filename change only —
--   nothing in prod was re-run.
--   DELIBERATELY NOT REWRITTEN: the provenance strings this migration wrote into
--   essentials.politicians.notes read "migration 1534", because that is what is recorded in
--   prod. If you are reading those strings and looking for a 1534 that merges the AZ rows, it is
--   this file. The companion Bennett merge is 1546 (authored as 1537); it follows the same
--   keep-rule and cites this file as its precedent.
--
-- WHY: On 2026-07-25 a hand-add session minted NEW politician rows in the synthetic -66000xxx
--   band for four people who ALREADY existed in essentials with real external_ids. The
--   essentials.race_candidates edge landed on the new (impostor) row while the curated
--   essentials.quotes stayed on the pre-existing row.
--
--   Read & Rank reaches quotes ONLY via race_candidates.politician_id = quotes.politician_id
--   (backend/src/lib/readrankService.ts, main query ~:325 and the rankable_topic_count
--   subquery ~:310). A quote on a row with no race edge is therefore permanently invisible on
--   the race page. This migration makes 9 quotes (7 readrank_selected) reachable again.
--
-- KEEP RULE, applied uniformly (same rule as 1450_racine_merge_duplicate_politicians):
--   keep the record that already holds an office and a real external_id; the hand-added
--   -66000xxx stub is the impostor. In all four pairs the keep row also holds the quotes,
--   the portrait, the office_terms row and the Compass answers.
--
--   person              keep (external_id)                    drop (external_id)
--   -----------------   -----------------------------------   ------------------------------
--   Kris Mayes          -400092   AZ Attorney General          -66000122  AG candidate stub
--   Kimberly Yee        -400094   AZ Treasurer                 -66000136  Superintendent stub
--   Alexander Kolodin   -4006005  AZ State Representative      -66000133  Sec. of State stub
--   David Schweikert    -4001     U.S. Representative (AZ)     -66000128  Governor stub
--
-- REFERENCE AUDIT (done before writing this — the reason it is safe):
--   essentials.politicians is referenced by 21 FOREIGN KEY constraints but by 42 columns
--   across 10 schemas once soft (un-constrained) references are counted. essentials.quotes,
--   essentials.politician_stances, meetings.speakers, essentials.legislative_votes and
--   essentials.office_current_holder carry NO foreign key — those are the hazard, because a
--   DELETE would silently orphan them rather than error. That is why this migration
--   DEACTIVATES rather than deletes (see below).
--
--   All 42 columns were scanned for the 8 UUIDs in these pairs. Only these carry rows:
--       essentials.quotes              9  (all on keep rows)
--       essentials.race_candidates     4  (all on DROP rows — this is the bug)
--       essentials.politician_images   4  (all on keep rows)
--       essentials.office_terms        4  (all on keep rows)
--       essentials.politician_answers 35  (all on keep rows)
--       essentials.politician_context 35  (all on keep rows)
--       meetings.speakers              3  (all on DROP rows: Kolodin, Schweikert, Yee)
--   Everything else is empty for these 8 people, including politician_contacts, degrees,
--   experiences, identifiers, endorsements, legislative_votes, zip_politicians,
--   empower.empowered_profiles and public.politician_id_bridge.
--
--   Verified NO Compass collisions: inform.politician_answers and inform.politician_context
--   are keyed on (politician_id, topic_id), so a merge can violate the PK. For these four
--   pairs the drop rows hold ZERO answers, so zero topics collide. (Other duplicate pairs in
--   the DB DO collide — Rachel Fetty Anderson 11, Steve Marshall 6, Tram Nguyen 4 — which is
--   why they are deliberately NOT in this migration.)
--
--   Verified NO same-race clash: no keep/drop pair shares a race_id, so re-pointing the edge
--   cannot create two candidacies for one person in one race.
--
-- WHY DEACTIVATE, NOT DELETE: 1450 deleted its losers safely because nothing downstream had
--   attached to them. Here the drop rows carry meetings.speakers rows, and speakers has no FK
--   to politicians — a delete would silently orphan meeting speaker attribution. Deactivating
--   preserves the audit trail and keeps every soft reference resolvable. A follow-up migration
--   can delete them once the speaker rows are confirmed re-pointed and settled.
--
-- NOTE ON PROVENANCE: none of -66000122/-66000128/-66000133/-66000136 appear in ANY migration
--   file in this repo — they were written directly to prod by the 2026-07-25 session. This
--   migration is therefore also the first record of their existence.

BEGIN;

-- ---------------------------------------------------------------------------
-- Pair table, resolved by external_id (stable; UUIDs are environment-specific)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE merge_pairs ON COMMIT DROP AS
SELECT
  v.person,
  k.id AS keep_id,
  d.id AS lose_id
FROM (VALUES
  ('Kris Mayes',        -400092::bigint,  -66000122::bigint),
  ('Kimberly Yee',      -400094,          -66000136),
  ('Alexander Kolodin', -4006005,         -66000133),
  ('David Schweikert',  -4001,            -66000128)
) AS v(person, keep_ext, lose_ext)
JOIN essentials.politicians k ON k.external_id = v.keep_ext
JOIN essentials.politicians d ON d.external_id = v.lose_ext;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM merge_pairs;
  IF n <> 4 THEN
    RAISE EXCEPTION 'expected 4 merge pairs, resolved % — external_ids missing or changed', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Re-point references from the impostor row onto the real row.
--    Quotes/contacts are listed for completeness; they are empty on the drop
--    rows today, and the statements no-op if that stays true.
-- ---------------------------------------------------------------------------
UPDATE essentials.quotes q
   SET politician_id = m.keep_id
  FROM merge_pairs m WHERE q.politician_id = m.lose_id;

UPDATE essentials.race_candidates rc
   SET politician_id = m.keep_id
  FROM merge_pairs m WHERE rc.politician_id = m.lose_id;

UPDATE meetings.speakers s
   SET politician_id = m.keep_id
  FROM merge_pairs m WHERE s.politician_id = m.lose_id;

UPDATE essentials.politician_contacts c
   SET politician_id = m.keep_id
  FROM merge_pairs m WHERE c.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 2. Compass answers/context. PK is (politician_id, topic_id), so move only
--    topics the keep row lacks; the keep (office-holder) row's answer wins.
--    Zero rows today — present so a re-run after any drift stays correct.
-- ---------------------------------------------------------------------------
UPDATE inform.politician_answers a
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE a.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM inform.politician_answers k
                    WHERE k.politician_id = m.keep_id AND k.topic_id = a.topic_id);
DELETE FROM inform.politician_answers a
 USING merge_pairs m WHERE a.politician_id = m.lose_id;

UPDATE inform.politician_context c
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE c.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM inform.politician_context k
                    WHERE k.politician_id = m.keep_id AND k.topic_id = c.topic_id);
DELETE FROM inform.politician_context c
 USING merge_pairs m WHERE c.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 3. Portraits: keep the real row's image. Move the stub's only if the keep
--    row has none (it never does today), else drop it so one person keeps one
--    portrait. essentials.politician_images HAS a FK, so a stray row here would
--    block deactivation cleanup later.
-- ---------------------------------------------------------------------------
UPDATE essentials.politician_images i
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE i.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images k
                    WHERE k.politician_id = m.keep_id);
DELETE FROM essentials.politician_images i
 USING merge_pairs m WHERE i.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 4. office_terms: the stubs hold none; the real rows hold the true term.
--    (essentials.current_office_holders and essentials.office_current_holder
--    are VIEWS, verified via pg_class.relkind = 'v' — nothing to update.)
-- ---------------------------------------------------------------------------
DELETE FROM essentials.office_terms t
 USING merge_pairs m WHERE t.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 5. Deactivate the impostor. Guarded on is_active so a re-run does not
--    append the provenance note twice.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_active = false,
       notes = COALESCE(p.notes, '{}'::text[])
               || ('merged into politician ' || m.keep_id::text
                   || ' by migration 1534 on 2026-08-03 (duplicate row from the 2026-07-25 '
                   || 'AZ hand-add session; race edge re-pointed to the office-holder record)')
  FROM merge_pairs m
 WHERE p.id = m.lose_id
   AND p.is_active;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  n_bad int;
  n_visible int;
BEGIN
  -- Every impostor must be inactive and hold no references at all.
  FOR r IN SELECT * FROM merge_pairs LOOP
    IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.lose_id AND is_active) THEN
      RAISE EXCEPTION '% : impostor row % is still active', r.person, r.lose_id;
    END IF;

    SELECT (SELECT count(*) FROM essentials.quotes            WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM essentials.race_candidates   WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM meetings.speakers            WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM essentials.politician_images WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM essentials.office_terms      WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM inform.politician_answers    WHERE politician_id = r.lose_id)
         + (SELECT count(*) FROM inform.politician_context    WHERE politician_id = r.lose_id)
      INTO n_bad;
    IF n_bad <> 0 THEN
      RAISE EXCEPTION '% : % references still attached to impostor row %',
        r.person, n_bad, r.lose_id;
    END IF;

    -- The kept row must now hold the candidacy.
    IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE politician_id = r.keep_id) THEN
      RAISE EXCEPTION '% : candidacy did not follow the merge onto %', r.person, r.keep_id;
    END IF;

    -- The kept row must still be the live one.
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.keep_id AND is_active) THEN
      RAISE EXCEPTION '% : kept row % is not active', r.person, r.keep_id;
    END IF;
  END LOOP;

  -- One portrait per merged person, not two.
  SELECT count(*) INTO n_bad FROM (
    SELECT m.keep_id FROM merge_pairs m
      JOIN essentials.politician_images i ON i.politician_id = m.keep_id
     GROUP BY m.keep_id HAVING count(*) > 1
  ) x;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% merged people ended up with more than one portrait', n_bad;
  END IF;

  -- No merged person may hold two candidacies in one race.
  SELECT count(*) INTO n_bad FROM (
    SELECT rc.politician_id, rc.race_id
      FROM essentials.race_candidates rc
      JOIN merge_pairs m ON m.keep_id = rc.politician_id
     GROUP BY rc.politician_id, rc.race_id HAVING count(*) > 1
  ) x;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% duplicate race edges created by the merge', n_bad;
  END IF;

  -- THE POINT OF THE MIGRATION: selected quotes now reachable through the exact
  -- join Read & Rank uses. Expect 7 (Mayes 5, Kolodin 1, Schweikert 1; Yee has a
  -- quote but none selected).
  SELECT count(*) INTO n_visible
    FROM essentials.race_candidates rc
    JOIN essentials.quotes q ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL AND q.readrank_selected = true
    JOIN merge_pairs m ON m.keep_id = rc.politician_id
   WHERE COALESCE(rc.candidate_status, 'active') <> 'withdrawn';
  IF n_visible < 7 THEN
    RAISE EXCEPTION 'expected >= 7 selected quotes reachable after merge, found %', n_visible;
  END IF;

  RAISE NOTICE 'AZ duplicate merge PASSED: 4 impostor rows deactivated, 4 candidacies and 3 meeting-speaker rows re-pointed, % selected quotes now reachable.', n_visible;
END $$;

COMMIT;
