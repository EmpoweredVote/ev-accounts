-- 1546_merge_duplicate_rick_richard_bennett.sql
-- Merge the two politician rows for Maine state senator Rick (Richard) Bennett, the
-- independent candidate for Governor of Maine 2026.
-- Idempotent (once the loser row holds no references and is inactive, every statement no-ops).
--
-- RENUMBERED 1537 -> 1546. Authored, applied to prod and verified as 1537 on 2026-08-03; at
--   commit time origin/master turned out to already carry a different 1537
--   (1537_retire_pretenure_vote_assertions.sql) and to run up to 1544, so
--   scripts/check-migration-numbers.mjs put the next free prefix at 1545. The renumber is a
--   filename change only — nothing in prod was re-run.
--   DELIBERATELY NOT REWRITTEN: the provenance strings this migration wrote into
--   essentials.politicians.notes and essentials.quotes.editor_note read "migration 1537",
--   because that is what is actually recorded in prod. If you are reading those strings and
--   looking for a 1537 that merges Bennett, it is this file.
--
-- WHY: This pair is invisible to the duplicate scan behind 1534. That scan keys on
--   lower(first_name) || ' ' || lower(last_name), which requires an EXACT first-name match, so
--   nickname variants (Dan/Daniel, Rick/Richard, Mike/Michael) never collide under it. A
--   separate nickname-map scan found 34 such pairs; on individual verification all but this one
--   turned out to be either genuinely distinct people or pure hygiene with no quotes at stake.
--
--   Read & Rank reaches quotes ONLY via race_candidates.politician_id = quotes.politician_id
--   (backend/src/lib/readrankService.ts, main query ~:325 and the rankable_topic_count
--   subquery ~:310). Here the race edge and the quotes landed on DIFFERENT rows, so 7
--   readrank_selected quotes are permanently invisible on the Maine Governor race page.
--
--   person            keep (external_id)                     drop (external_id)
--   ---------------   ------------------------------------   ----------------------------
--   Rick Bennett      -231018  Senator, Maine · 7 quotes     (none)  holds the race edge
--
-- IDENTITY VERIFIED (2026-08-03) — name similarity is NOT evidence, so this pair was
--   confirmed four independent ways before writing anything:
--     1. All 7 selected quotes on the keep row are sourced from bennettforgovernor.com/vision
--        — a MAINE GUBERNATORIAL campaign platform.
--     2. The race edge on the drop row cites mainepublic.org/politics/2026-06-04 "independent
--        qualifies for ballot, setting up 3-way race for Maine governor".
--     3. Ballotpedia files him as "Richard Bennett (Maine)"; Wikipedia as "Rick Bennett (Maine
--        politician)". Both describe one person: the Oxford state senator (District 18, since
--        2022-12-06, former Senate President) who left the Republican Party on 2025-06-24 to
--        run for governor as an independent.
--     4. The keep row's office (Senator, ME) is exactly the office that person holds.
--
--   COUNTEREXAMPLES from the same scan, recorded so nobody "completes" this migration by
--   sweeping in the rest of the nickname pairs:
--     Dan Sullivan (-400002, sitting AK senator) vs Daniel J. Sullivan Jr. (-66000068) are TWO
--       DIFFERENT PEOPLE who are both legitimately 'filed' in the SAME 2026 U.S. Senate Alaska
--       race. The second is a Petersburg retiree who SUED and won a court ruling to stay on the
--       primary ballot. Identical race + identical status + identical party is not evidence.
--       Merging them would erase a real candidate.
--     Steve Johnson (MD Delegate) vs Steven Johnson (KS Treasurer); Chris Campbell (TN-01) vs
--       Christopher Campbell (KY U.S. Senate); Mike McGuire (CA-01) vs Michael McGuire (NJ-03);
--       Mike Thompson (CA-04) vs Michael Thompson (FL-22) vs Michael Thompson (Indiana);
--       Dan Ryan (Portland OR councilor) vs Daniel J. Ryan (MA 2nd Suffolk); Joe LaCava (San
--       Diego) vs Joseph LaCava (MA Ward 5). All distinct people. Do not merge.
--
-- KEEP RULE: same as 1450 and 1534 — keep the row holding a real external_id, the office and
--   the office_terms record; re-point the candidacy onto it. Note the direction is the OPPOSITE
--   of what "the row with the race edge is the real one" would suggest: race edges are cheap to
--   move (race_candidates has a real FK), whereas the external_id, office, office_term, 7
--   quotes and 9 Compass answers are not.
--
-- REFERENCE AUDIT (all 22 FK-referencing tables plus the four UNCONSTRAINED soft references
--   scanned for both UUIDs on 2026-08-03). essentials.quotes, meetings.speakers,
--   essentials.legislative_votes and meetings.la_council_votes carry NO foreign key to
--   politicians — verified via information_schema; those are the hazard, because a DELETE would
--   silently orphan them rather than error. Non-empty for this pair:
--       essentials.quotes              keep 7   drop 1
--       essentials.race_candidates     keep 0   drop 1   <-- this is the bug
--       essentials.politician_images   keep 1   drop 1
--       essentials.office_terms        keep 1   drop 0
--       inform.politician_answers      keep 9   drop 8
--       inform.politician_context      keep 9   drop 8
--   Empty on BOTH rows: politician_contacts, addresses, degrees, experiences, identifiers,
--   politician_committees, politician_name_aliases, quest_verified_facts,
--   politician_context_evidence, stance_research_review, topic_rewrite_stance_proposals,
--   meetings.speakers, meetings.la_council_votes, essentials.legislative_votes,
--   public.politician_id_bridge, empower.empowered_profiles.
--   essentials.current_office_holders and essentials.office_current_holder are VIEWS over
--   office_terms — nothing to update there.
--
-- THREE CONSTRAINTS THIS MIGRATION HAS TO RESPECT THAT 1534 DID NOT HIT:
--
--   (1) A UNIQUE INDEX BLOCKS THE NAIVE REPOINT.
--       essentials.quotes carries
--           quotes_one_selected_per_stance UNIQUE (politician_id, lower(topic_key))
--                                          WHERE readrank_selected
--       and BOTH rows hold a readrank_selected 'campaign-finance' quote. A plain
--       UPDATE ... SET politician_id = keep_id therefore ABORTS. Step 1 below de-selects the
--       drop row's colliding quote FIRST. Chris chose (2026-08-03) to keep the campaign-platform
--       quote live and demote the 2022 Sun Journal one to a draft: it is 4 years older and
--       narrower (foreign spending on referendums specifically), and keeping the platform set
--       intact means all 7 topics compare like-for-like against opponents' current platforms.
--       The demoted quote is PRESERVED, not deleted, so it can be promoted by hand later.
--
--   (2) DEACTIVATING IS NOT ENOUGH TO HIDE THE DROP ROW.
--       The speaker-link picker (on-the-record gui/politicians.py:256, PR #146) filters on
--           WHERE (p.is_active = true
--                  OR p.id IN (SELECT politician_id FROM essentials.race_candidates
--                              WHERE COALESCE(candidate_status,'active') <> 'withdrawn'))
--       so an inactive row that still shows a non-withdrawn candidacy STAYS VISIBLE. The drop
--       row must therefore end with zero race edges, which step 2 guarantees and the VERIFY
--       block asserts. (gui/politicians.py is shipped and reviewed; this migration adapts to
--       it and does not require any code change.)
--
--   (3) office_terms MUST BE MOVED, NOT DELETED, WHEN THE KEEP ROW LACKS ONE.
--       1534 could DELETE the loser's office_terms because its keep rows always held one. That
--       is not safe in general: essentials.office_current_holder derives the office holder FROM
--       office_terms, so deleting the only row blanks the person's office in both the picker and
--       the public "who represents me" feed. Here the keep row already holds the term and the
--       drop row holds none, so step 5 is a no-op today — but it is written move-if-keep-lacks
--       (mirroring the images rule) so it stays correct under drift and for reuse.
--
-- DISPLAY NAME (deliberate, and the one user-visible change here).
--   readrankService.ts:588 renders essentials.politicians.full_name — NOT the denormalized
--   race_candidates.full_name. Keeping the merge purely mechanical would therefore relabel him
--   "Richard A. Bennett" on the live Maine Governor race page, beside "Hannah Pingree" and
--   "Bobby Charles" — a name matching neither the ballot, the campaign, nor any press coverage.
--   Step 6 sets the keep row's full_name to 'Rick Bennett' and records 'Richard A. Bennett' in
--   alternate_names, matching the precedent set by 1483_fix_wi_ad55_gustafson_name.sql.
--
--   Be clear about what that alias does and does not do. It is a RECORD OF THE FORMAL NAME, not
--   a functional search alias: no application code in either repo reads alternate_names
--   (verified by grep across ev-accounts backend/src and on-the-record). The picker searches
--   only _NAME_FIELDS = (full_name, preferred_name, first_name, last_name)
--   (gui/politicians.py:36). What actually keeps "Richard Bennett" resolving after this merge is
--   that first_name stays 'Richard' — deliberately NOT rewritten here. Verified post-apply: all
--   of "Bennett", "Rick Bennett", "Richard Bennett" and "Richard A. Bennett" return exactly one
--   row. If alternate_names is ever added to _NAME_FIELDS the alias starts earning its keep;
--   until then, do not rely on it for recall.
--
-- MEASURED EFFECT (before -> after, race deafeeb8 "Governor of Maine"):
--   Bennett's reachable readrank_selected quotes  1 -> 7
--   Race rankable_topic_count                     3 -> 4   ('taxes' becomes rankable: Bennett
--                                                            + Bobby Charles)
--   'climate-change' and 'healthcare' go from 2-way to 3-way comparisons.
--   All 7 topics are live inform.compass_topics and all 7 quotes have deidentified_text, both
--   of which readrankService additionally requires — verified, not assumed.
--
-- COORDINATION: does not touch the rows in the concurrent stranded-quotes repair (Priest, Hong,
--   Rose, Nguyen, Fetty Anderson, Marshall) nor in the concurrent officeholder-reactivation
--   migration (Daniel Webster, Patrice Lattimore — authored as 1536, also awaiting a renumber).
--   Disjoint. Checked against origin/master's 1536-1544 as well: those are citations, outlet and
--   office-term work and touch none of the Bennett rows.

BEGIN;

-- ---------------------------------------------------------------------------
-- Pair table. 1534 resolved by external_id because both its rows had one; here the DROP row
-- has external_id IS NULL (that is part of why it is the impostor), so there is no stable
-- business key for it and it is addressed by UUID. The assertions below make a wrong UUID fail
-- loudly instead of merging the wrong person.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE merge_pairs ON COMMIT DROP AS
SELECT 'Rick Bennett'::text AS person,
       k.id                 AS keep_id,
       d.id                 AS lose_id
FROM essentials.politicians k
CROSS JOIN essentials.politicians d
WHERE k.external_id = -231018::bigint
  AND d.id = 'f64c1364-65a7-4958-a9f2-999383f0729d'::uuid;

DO $$
DECLARE n int; k_name text; d_name text; d_ext bigint;
BEGIN
  SELECT count(*) INTO n FROM merge_pairs;
  IF n <> 1 THEN
    RAISE EXCEPTION 'expected 1 merge pair, resolved % — external_id -231018 or the drop UUID is missing/changed', n;
  END IF;

  SELECT p.full_name INTO k_name FROM essentials.politicians p JOIN merge_pairs m ON m.keep_id = p.id;
  SELECT p.full_name, p.external_id INTO d_name, d_ext
    FROM essentials.politicians p JOIN merge_pairs m ON m.lose_id = p.id;

  -- Keep row: 'Richard A. Bennett' on first run, 'Rick Bennett' after step 6 has run once.
  IF k_name NOT IN ('Richard A. Bennett', 'Rick Bennett') THEN
    RAISE EXCEPTION 'keep row (-231018) is "%", expected Richard A. Bennett or Rick Bennett — wrong person', k_name;
  END IF;
  IF d_name <> 'Rick Bennett' THEN
    RAISE EXCEPTION 'drop row f64c1364 is "%", expected Rick Bennett — wrong person, ABORTING', d_name;
  END IF;
  IF d_ext IS NOT NULL THEN
    RAISE EXCEPTION 'drop row f64c1364 has external_id % — the impostor should have none; refusing to merge', d_ext;
  END IF;
  IF (SELECT keep_id FROM merge_pairs) = (SELECT lose_id FROM merge_pairs) THEN
    RAISE EXCEPTION 'keep and drop resolved to the same row';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Resolve the quotes_one_selected_per_stance collision BEFORE re-pointing.
--    De-select any quote on the drop row whose topic the keep row already has selected.
--    Today: exactly one row, 'campaign-finance' (2022 Sun Journal). Guarded on
--    readrank_selected, so a re-run no-ops and the editor_note is appended only once.
-- ---------------------------------------------------------------------------
UPDATE essentials.quotes q
   SET readrank_selected = false,
       editor_note = CASE
         WHEN COALESCE(q.editor_note, '') = '' THEN
           'De-selected by migration 1537 on 2026-08-03: this row was merged into the '
           'office-holder record, which already had a selected campaign-finance quote from '
           'the 2026 gubernatorial platform. Preserved as a draft — promote by hand if '
           'preferred over the platform line.'
         ELSE q.editor_note || E'\n\n'
           || 'De-selected by migration 1537 on 2026-08-03 (campaign-finance collision on merge).'
       END
  FROM merge_pairs m
 WHERE q.politician_id = m.lose_id
   AND q.readrank_selected
   AND EXISTS (
     SELECT 1 FROM essentials.quotes k
      WHERE k.politician_id = m.keep_id
        AND k.readrank_selected
        AND lower(k.topic_key) = lower(q.topic_key)
   );

UPDATE essentials.quotes q
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE q.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 2. The candidacy. This is the whole point: it moves onto the row that holds the quotes.
--    race_candidates.full_name stays 'Rick Bennett' (correct — it is the ballot name, and
--    step 6 makes the politician row agree with it).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE rc.politician_id = m.lose_id
   AND NOT EXISTS (
     SELECT 1 FROM essentials.race_candidates k
      WHERE k.politician_id = m.keep_id AND k.race_id = rc.race_id
   );
-- Any edge left behind would be a duplicate candidacy for one person in one race.
DELETE FROM essentials.race_candidates rc
 USING merge_pairs m WHERE rc.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 3. Compass answers/context. PK is (politician_id, topic_id), so move only topics the keep
--    row LACKS; the office-holder row's answer wins on collision. This is the rule agreed
--    when 1534 deliberately excluded every colliding pair.
--    Measured for this pair: 4 topics move (Economic Development Incentives, Fossil Fuel
--    Policy, Immigration and Treatment of Immigrants, Medicare/Medicaid), 1 collides in
--    agreement (Campaign Finance Reform, both 2.0), and 3 collide in DISAGREEMENT where the
--    keep row wins by rule: Healthcare Access 2.0 over 3.0, Taxation 3.0 over 4.0,
--    Transgender Athletes 1.0 over 2.0.
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

-- Empty on both rows today; present so a re-run after drift stays correct. ON DELETE CASCADE
-- from politicians, so a stray row here would vanish silently on any later hard delete.
UPDATE inform.politician_context_evidence e
   SET politician_id = m.keep_id
  FROM merge_pairs m WHERE e.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 4. Portrait: one person, one portrait. Keep row's wins; move the drop row's only if the
--    keep row has none. politician_images HAS a FK, so a stray row would block a later
--    hard-delete cleanup.
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
-- 5. office_terms: move-if-keep-lacks, NOT the unconditional DELETE 1534 used. See constraint
--    (3) in the header. No-op today (keep 1, drop 0).
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET politician_id = m.keep_id
  FROM merge_pairs m
 WHERE t.politician_id = m.lose_id
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms k
                    WHERE k.politician_id = m.keep_id);
DELETE FROM essentials.office_terms t
 USING merge_pairs m WHERE t.politician_id = m.lose_id;

-- ---------------------------------------------------------------------------
-- 6. Ballot display name, plus a record of the formal name in alternate_names (which nothing
--    reads today — see "DISPLAY NAME" in the header). The guard fires when
--    EITHER the name or the alias is not yet in place, so a re-run no-ops but a half-applied
--    state still self-heals. The append is ARRAY[...] rather than || 'literal': against a
--    text[] an untyped literal is parsed as an array literal and fails with
--    "malformed array literal" (caught by the pre-apply dry run).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET full_name = 'Rick Bennett',
       full_name_manual_override = true,
       alternate_names = CASE
         WHEN 'Richard A. Bennett' = ANY(COALESCE(p.alternate_names, '{}'::text[]))
           THEN COALESCE(p.alternate_names, '{}'::text[])
         ELSE COALESCE(p.alternate_names, '{}'::text[]) || ARRAY['Richard A. Bennett']::text[]
       END
  FROM merge_pairs m
 WHERE p.id = m.keep_id
   AND (p.full_name <> 'Rick Bennett'
        OR NOT ('Richard A. Bennett' = ANY(COALESCE(p.alternate_names, '{}'::text[]))));

-- ---------------------------------------------------------------------------
-- 7. Deactivate the impostor. Guarded on is_active so a re-run does not append the note twice.
--    DEACTIVATE, NOT DELETE: meetings.speakers, essentials.quotes and
--    essentials.legislative_votes have no FK to politicians, so a delete cannot be trusted to
--    error on a missed soft reference. This pair holds no speaker rows today, but the rule is
--    uniform across 1534 and this migration.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_active = false,
       notes = COALESCE(p.notes, '{}'::text[])
               || ('merged into politician ' || m.keep_id::text
                   || ' by migration 1537 on 2026-08-03 (nickname-variant duplicate of '
                   || 'Richard A. Bennett, external_id -231018, Maine state senator and 2026 '
                   || 'independent candidate for Governor; the Governor of Maine race edge was '
                   || 're-pointed onto the office-holder row, making 7 readrank_selected quotes '
                   || 'reachable in Read & Rank)')
  FROM merge_pairs m
 WHERE p.id = m.lose_id
   AND p.is_active;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  m           record;
  n_bad       int;
  n_reachable int;
  n_rankable  int;
  race        uuid;
BEGIN
  SELECT * INTO m FROM merge_pairs;

  -- The impostor must be inactive and hold no references at all.
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = m.lose_id AND is_active) THEN
    RAISE EXCEPTION 'impostor row % is still active', m.lose_id;
  END IF;

  SELECT (SELECT count(*) FROM essentials.quotes                  WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM essentials.race_candidates         WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM essentials.politician_images       WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM essentials.office_terms            WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM inform.politician_answers          WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM inform.politician_context          WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM meetings.speakers                  WHERE politician_id = m.lose_id)
       + (SELECT count(*) FROM essentials.legislative_votes       WHERE politician_id = m.lose_id)
    INTO n_bad;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% references still attached to impostor row %', n_bad, m.lose_id;
  END IF;

  -- Constraint (2): with no race edge left, the picker's is_active OR candidacy filter now
  -- excludes the impostor. Asserted directly in the picker's own shape.
  IF EXISTS (
    SELECT 1 FROM essentials.politicians p
     WHERE p.id = m.lose_id
       AND (p.is_active = true
            OR p.id IN (SELECT politician_id FROM essentials.race_candidates
                         WHERE COALESCE(candidate_status,'active') <> 'withdrawn'))
  ) THEN
    RAISE EXCEPTION 'impostor row % is still visible to the GUI picker filter', m.lose_id;
  END IF;

  -- The keep row must be active, hold the candidacy, exactly one portrait, and the ballot name.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = m.keep_id AND is_active) THEN
    RAISE EXCEPTION 'kept row % is not active', m.keep_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE politician_id = m.keep_id) THEN
    RAISE EXCEPTION 'candidacy did not follow the merge onto %', m.keep_id;
  END IF;
  SELECT count(*) INTO n_bad FROM essentials.politician_images WHERE politician_id = m.keep_id;
  IF n_bad <> 1 THEN
    RAISE EXCEPTION 'kept row should hold exactly 1 portrait, holds %', n_bad;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                  WHERE id = m.keep_id AND full_name = 'Rick Bennett'
                    AND 'Richard A. Bennett' = ANY(COALESCE(alternate_names, '{}'::text[]))) THEN
    RAISE EXCEPTION 'kept row is missing the ballot name or the Richard A. Bennett search alias';
  END IF;

  -- No duplicate candidacy in one race.
  SELECT count(*) INTO n_bad FROM (
    SELECT race_id FROM essentials.race_candidates
     WHERE politician_id = m.keep_id GROUP BY race_id HAVING count(*) > 1
  ) x;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% duplicate race edges created by the merge', n_bad;
  END IF;

  -- The unique index must hold: at most one selected quote per topic.
  SELECT count(*) INTO n_bad FROM (
    SELECT lower(topic_key) FROM essentials.quotes
     WHERE politician_id = m.keep_id AND readrank_selected
     GROUP BY lower(topic_key) HAVING count(*) > 1
  ) x;
  IF n_bad <> 0 THEN
    RAISE EXCEPTION '% topics have more than one selected quote after the merge', n_bad;
  END IF;

  -- THE POINT OF THE MIGRATION, through the exact join Read & Rank uses — including the
  -- deidentified_text and compass_topics.is_live predicates readrankService also applies.
  SELECT count(*) INTO n_reachable
    FROM essentials.race_candidates rc
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
    JOIN inform.compass_topics ct
      ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
   WHERE rc.politician_id = m.keep_id
     AND COALESCE(rc.candidate_status, 'active') <> 'withdrawn';
  IF n_reachable <> 7 THEN
    RAISE EXCEPTION 'expected 7 selected quotes reachable after merge, found %', n_reachable;
  END IF;

  -- And the race gains a rankable topic ('taxes': Bennett + Bobby Charles). Recomputed with
  -- readrankService's rankable_topic_count subquery verbatim.
  SELECT rc.race_id INTO race FROM essentials.race_candidates rc WHERE rc.politician_id = m.keep_id LIMIT 1;
  SELECT count(*) INTO n_rankable FROM (
    SELECT lower(q2.topic_key) AS tk
      FROM essentials.race_candidates rc2
      JOIN essentials.quotes q2
        ON q2.politician_id = rc2.politician_id
       AND q2.deidentified_text IS NOT NULL AND q2.readrank_selected = true
      JOIN inform.compass_topics ct2
        ON ct2.topic_key = lower(q2.topic_key) AND ct2.is_live = true
     WHERE rc2.race_id = race
       AND COALESCE(rc2.candidate_status, 'active') <> 'withdrawn'
     GROUP BY lower(q2.topic_key)
     HAVING COUNT(DISTINCT rc2.politician_id) >= 2
  ) rankable;
  IF n_rankable < 4 THEN
    RAISE EXCEPTION 'expected >= 4 rankable topics on the Maine Governor race, found %', n_rankable;
  END IF;

  RAISE NOTICE 'Bennett merge PASSED: impostor % deactivated and de-referenced, candidacy re-pointed onto %, % selected quotes now reachable, % rankable topics on the race.',
    m.lose_id, m.keep_id, n_reachable, n_rankable;
END $$;

COMMIT;
