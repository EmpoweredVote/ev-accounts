-- CA_0360_merge_rose_biggs_governor_candidate_duplicates.sql
-- Identity merge of two sitting members of the U.S. House who are each split across two essentials.politicians rows:
-- the SITTING row (bioguide id, House seat, federal votes, compass answers) and a second row created when they ran
-- for governor in 2026 (the race row, quotes and meeting-speaker links only). The candidacy moves to the sitting row.
--
-- Slot CA_0360 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE.
-- ✅ APPLIED to prod 2026-11-04 (approval: Chris Andrews). Both gates green. Dry run passed three times before the
--   apply (single, double-apply with 0 rows changed on the second pass, and repeated just before the apply), and a
--   planted fault (speaker links not moved) failed the post-gate as "6 of 14 rows on the survivor". Re-read after:
--   both survivors active, seated, carrying their bioguide id, votes, answers and governor race row; both second rows
--   inactive and empty. check:duplicate-people dropped both pairs from the baseline.
--
-- Found by CA_0358 (PR #1297), which gave bioguide ids to active former members and left these two out: copying the
-- bioguide id onto the second row would put one bioguide on two rows, and both federal vote loaders skip such an id
-- silently (the CA_0354 Padilla failure). Until this merge a voter looking at either governor race saw a record with
-- no voting history and no compass answers.
--
-- 🟢 SEASON 1 IS NOT TOUCHED. Ruling 2026-09-24 (Chris Andrews): a merge never edits the closed season. Here the
-- survivor already holds every answer and the second rows hold none, so no inform.* row is written; the post-gate
-- fingerprints all four rows.
--
-- THE TWO (second row -> sitting survivor), each checked 2026-11-04:
--   1. JOHN ROSE   7a43967d "John Rose" (no external_id, source manual:pipeline-2026) -> ed095ae9 "John W. Rose"
--      (R000612, ext -47006, U.S. Representative TN-6 since 2019-01-03, 16 answers / 17 context, 3,700 votes).
--      The second row holds race_candidates d5fc10c4 (Governor of Tennessee, 2026-08-06 Republican primary, result
--      'lost'), 4 quotes (wvlt.tv 2026-07-24, nashvillebanner.com 2026-07-28, wkrn.com x2 — all name him as the
--      congressman running for governor), and 7 meetings.speakers rows. Same first + last name, same state.
--   2. ANDY BIGGS  868b219c "Andy Biggs" (ext -66000127) -> 8118811a "Andy Biggs" (B001302, ext -4005,
--      U.S. Representative AZ-5 since 2017-01-03, 21 answers / 22 context, 4,836 votes). The second row holds
--      race_candidates 895a426d (Governor, Arizona, 2026-11-03, result 'advanced') and 1 meetings.speakers row
--      (fa660310). Identical full_name, same state. The repo's
--      source-store findings file for 868b219c (3 Arizona Legislature roll calls, 2005-2011, voting-rights Season 3) is
--      folded into 8118811a.json in the same PR.
--   Every uuid/text column named like *politician* or essentials_id in every schema (66 columns) was scanned for the
--   second rows: they hold nothing else — no office_terms, answers, context, evidence, review rows, images, FEC links,
--   aliases, bridge rows, votes, cosponsors or id-map rows.
--
-- NOT A DUPLICATE, NOT TOUCHED: Dan Sullivan (a97678bc, S001198) vs "Daniel J. Sullivan Jr." (f0a46feb). Different
--   people: separate FEC ids (S4AK00214 vs S6AK00326), both separately on the 2026 Alaska primary and general ballots,
--   both 'advanced' (CA_0231). Recorded as different_people in duplicate-people-baseline.json.
--
-- WHAT CHANGES, per pair:
--   a. race_candidates, quotes and meetings.speakers rows on the second row are re-pointed to the survivor.
--      race_candidates.full_name is left as printed on the ballot. Both race rows have NULL photo_url and website_url,
--      so the race_candidate_mirror_data trigger copies nothing onto the survivor.
--   b. Rose: alias 'John Rose' is added to the survivor (its full_name is 'John W. Rose').
--   c. The second row is deactivated (is_active = false, is_incumbent stays false) with a note naming the survivor.
--      external_ids stay where they are: the survivors keep the ids their loaders key on (1536 federal seed), and
--      Biggs' -66000127 is referenced by no file in the repo.
--   d. The survivor gets a CA_0360 note.
-- NOT CHANGED: every inform.* row; office_terms; names; party; portraits.
--
-- ROLLBACK (once applied): re-point the listed race_candidates / quotes / speakers rows back to the second rows (ids are
--   in this header and in the _move table below), delete the 'John Rose' alias row with source 'CA_0360', set the
--   second rows is_active = true, and remove both CA_0360 notes.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (who text PRIMARY KEY, keep uuid UNIQUE, dup uuid UNIQUE, bioguide text,
                         keep_name text, dup_name text, n_ans int, n_ctx int) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('John Rose',  'ed095ae9-1864-47e1-9d5d-36b65f0314fe', '7a43967d-ffde-405f-be63-6ce39278d812', 'R000612',
   'John W. Rose', 'John Rose', 16, 17),
  ('Andy Biggs', '8118811a-aadd-4eb9-9208-de0f5d3b29ad', '868b219c-a10a-4dc2-a632-9022c7f835d1', 'B001302',
   'Andy Biggs', 'Andy Biggs', 21, 22);

-- every row that moves, by id
CREATE TEMP TABLE _move (tbl text, id uuid, who text, PRIMARY KEY (tbl, id)) ON COMMIT DROP;
INSERT INTO _move VALUES
  ('race_candidates', 'd5fc10c4-52c2-401d-8de8-6b017aabdb78', 'John Rose'),
  ('race_candidates', '895a426d-6c65-49fe-adc9-65bad6afab67', 'Andy Biggs'),
  ('quotes',   'd29d9032-0566-4a68-99de-f0c24d5e0cb6', 'John Rose'),
  ('quotes',   '5da17c8d-1598-4f7b-a734-d81a8c3f9ab8', 'John Rose'),
  ('quotes',   '8e8928c8-5144-4ff1-a2ad-efffb02d86b1', 'John Rose'),
  ('quotes',   'f53f338a-d6ee-483a-a312-f179ef53b7dc', 'John Rose'),
  ('speakers', '0a853acf-cd4f-4135-a559-d33ac532cf2f', 'John Rose'),
  ('speakers', '0fc1f9dd-3b61-454d-8704-284d12e40d65', 'John Rose'),
  ('speakers', 'c99b9b98-84d2-4433-9aa2-75188a38aa52', 'John Rose'),
  ('speakers', '46602216-3bcb-4d7f-9dd8-7390c583575e', 'John Rose'),
  ('speakers', '9d365efa-bcec-4730-8673-65f198794e84', 'John Rose'),
  ('speakers', '8ca46c1e-bd55-4604-aab5-c96e356a128f', 'John Rose'),
  ('speakers', 'b0a065c4-008c-4df4-a8f9-0fb317fe2ffe', 'John Rose'),
  ('speakers', 'fa660310-d53d-40b6-9484-59053b570d2a', 'Andy Biggs');

-- a fingerprint of all four rows' answers and context, which this file must not change
CREATE TEMP TABLE _inform_before ON COMMIT DROP AS
SELECT 'a' AS t, md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id)) AS h
  FROM inform.politician_answers a
 WHERE a.politician_id IN (SELECT keep FROM _pair UNION ALL SELECT dup FROM _pair)
UNION ALL
SELECT 'c', md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
  FROM inform.politician_context c
 WHERE c.politician_id IN (SELECT keep FROM _pair UNION ALL SELECT dup FROM _pair);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the reviewed rows, by name; survivor carries the bioguide and the answers
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep JOIN essentials.politicians d ON d.id = pr.dup
   WHERE k.full_name = pr.keep_name AND d.full_name = pr.dup_name
     AND lower(k.first_name) = lower(d.first_name) AND lower(k.last_name) = lower(d.last_name)
     AND k.is_active AND k.is_incumbent AND k.bioguide_id = pr.bioguide AND d.bioguide_id IS NULL
     AND (SELECT count(*) FROM inform.politician_answers a WHERE a.politician_id = pr.keep) = pr.n_ans
     AND (SELECT count(*) FROM inform.politician_context c WHERE c.politician_id = pr.keep) = pr.n_ctx;
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 pairs match their reviewed names, bioguide and answers', v_n; END IF;

  -- survivor still holds its House seat (EXISTS: a politician-rooted join on the view can fan out)
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = pr.keep);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 survivors hold a current seat', v_n; END IF;

  -- each listed row is on the second row (first run) or on the survivor (re-run)
  SELECT count(*) INTO v_n FROM _move m JOIN _pair pr ON pr.who = m.who
   WHERE (m.tbl = 'race_candidates' AND EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.id = m.id AND x.politician_id IN (pr.dup, pr.keep)))
      OR (m.tbl = 'quotes'          AND EXISTS (SELECT 1 FROM essentials.quotes x          WHERE x.id = m.id AND x.politician_id IN (pr.dup, pr.keep)))
      OR (m.tbl = 'speakers'        AND EXISTS (SELECT 1 FROM meetings.speakers x          WHERE x.id = m.id AND x.politician_id IN (pr.dup, pr.keep)));
  IF v_n <> 14 THEN RAISE EXCEPTION 'PRE: % of 14 reviewed rows in place', v_n; END IF;

  -- the second rows hold nothing this file does not handle
  SELECT (SELECT count(*) FROM essentials.race_candidates x WHERE x.politician_id IN (SELECT dup FROM _pair) AND x.id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM essentials.quotes x          WHERE x.politician_id IN (SELECT dup FROM _pair) AND x.id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM meetings.speakers x          WHERE x.politician_id IN (SELECT dup FROM _pair) AND x.id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM essentials.office_terms               WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.politician_answers             WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.politician_context             WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.politician_context_evidence    WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.stance_research_review         WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.evidence_items                 WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM inform.own_words_passages             WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_images          WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_contacts        WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.politician_name_aliases    WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.legislative_politician_id_map WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM essentials.legislative_votes          WHERE politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT dup FROM _pair))
       + (SELECT count(*) FROM politician_id_bridge                  WHERE essentials_id IN (SELECT dup FROM _pair))
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on a second row that this file does not handle', v_n; END IF;

  -- both race rows carry no photo or website, so the mirror trigger copies nothing onto the survivor
  SELECT count(*) INTO v_n FROM essentials.race_candidates x
   WHERE x.id IN (SELECT id FROM _move WHERE tbl = 'race_candidates')
     AND (COALESCE(x.photo_url, '') <> '' OR COALESCE(x.website_url, '') <> '');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race row(s) now carry a photo or website; re-review', v_n; END IF;

  RAISE NOTICE 'CA_0360 pre-flight OK';
END $$;

-- ─── 1. Move the candidacy ───────────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates x SET politician_id = pr.keep, updated_at = now()
  FROM _move m JOIN _pair pr ON pr.who = m.who
 WHERE m.tbl = 'race_candidates' AND x.id = m.id AND x.politician_id = pr.dup;

UPDATE essentials.quotes x SET politician_id = pr.keep
  FROM _move m JOIN _pair pr ON pr.who = m.who
 WHERE m.tbl = 'quotes' AND x.id = m.id AND x.politician_id = pr.dup;

UPDATE meetings.speakers x SET politician_id = pr.keep
  FROM _move m JOIN _pair pr ON pr.who = m.who
 WHERE m.tbl = 'speakers' AND x.id = m.id AND x.politician_id = pr.dup;

-- ─── 2. Rose's ballot name as an alias ───────────────────────────────────────────────────────────
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT 'ed095ae9-1864-47e1-9d5d-36b65f0314fe', 'John Rose', 'CA_0360'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_name_aliases
                    WHERE politician_id = 'ed095ae9-1864-47e1-9d5d-36b65f0314fe' AND lower(alias) = 'john rose');

-- ─── 3. Deactivate the second rows ───────────────────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0360 (2026-11-04): DUPLICATE of ' || pr.keep::text
               || ' (bioguide ' || pr.bioguide || '), the sitting member''s row. Its 2026 governor race row, quotes and '
               || 'meeting-speaker links moved there; deactivated, not deleted.')::text
  FROM _pair pr
 WHERE d.id = pr.dup AND d.is_active;

-- ─── 4. Note on the survivor ─────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians k
   SET notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CA_0360 (2026-11-04): holds the 2026 governor candidacy, quotes '
               || 'and meeting-speaker links of ' || pr.dup::text || ', a duplicate row of the same person, now '
               || 'deactivated. Season 1 was not touched.')::text
  FROM _pair pr
 WHERE k.id = pr.keep
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0360 (2026-11-04): holds%');

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- every listed row is on the survivor
  SELECT count(*) INTO v_n FROM _move m JOIN _pair pr ON pr.who = m.who
   WHERE (m.tbl = 'race_candidates' AND EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.id = m.id AND x.politician_id = pr.keep))
      OR (m.tbl = 'quotes'          AND EXISTS (SELECT 1 FROM essentials.quotes x          WHERE x.id = m.id AND x.politician_id = pr.keep))
      OR (m.tbl = 'speakers'        AND EXISTS (SELECT 1 FROM meetings.speakers x          WHERE x.id = m.id AND x.politician_id = pr.keep));
  IF v_n <> 14 THEN RAISE EXCEPTION 'POST: % of 14 rows on the survivor', v_n; END IF;

  -- survivors: active, incumbent, still seated, bioguide, a governor race row, the note
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians k ON k.id = pr.keep
   WHERE k.is_active AND k.is_incumbent AND k.bioguide_id = pr.bioguide
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.politician_id = pr.keep)
     AND EXISTS (SELECT 1 FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
                  WHERE rc.politician_id = pr.keep AND r.position_name ILIKE 'Governor%')
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0360 (2026-11-04): holds%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 survivors in their target state', v_n; END IF;

  -- second rows: inactive, empty of race rows / quotes / speakers, noted
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.politicians d ON d.id = pr.dup
   WHERE NOT d.is_active AND NOT d.is_incumbent
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.politician_id = d.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.quotes x          WHERE x.politician_id = d.id)
     AND NOT EXISTS (SELECT 1 FROM meetings.speakers x          WHERE x.politician_id = d.id)
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0360 (2026-11-04): DUPLICATE of ' || pr.keep::text || '%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 second rows deactivated, emptied and noted', v_n; END IF;

  -- Rose's alias
  SELECT count(*) INTO v_n FROM essentials.politician_name_aliases
   WHERE politician_id = 'ed095ae9-1864-47e1-9d5d-36b65f0314fe' AND lower(alias) = 'john rose';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Rose''s alias is missing'; END IF;

  -- each bioguide resolves to exactly one politician, across the column and the id map (CA_0354)
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(DISTINCT pid) FROM (
            SELECT p.id AS pid FROM essentials.politicians p WHERE p.bioguide_id = pr.bioguide
            UNION SELECT m.politician_id FROM essentials.legislative_politician_id_map m
                   WHERE m.id_type = 'bioguide' AND m.id_value = pr.bioguide) s) = 1;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 bioguide ids resolve to exactly one politician', v_n; END IF;

  -- one active row per person (by first + last name, within the pair)
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE (SELECT count(*) FROM essentials.politicians p WHERE p.is_active AND p.id IN (pr.keep, pr.dup)) = 1;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 people have exactly one active row', v_n; END IF;

  -- 🟢 Season 1 untouched
  SELECT count(*) INTO v_n FROM _inform_before b
   WHERE b.h IS DISTINCT FROM (
     CASE b.t
       WHEN 'a' THEN (SELECT md5(string_agg(a::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id))
                        FROM inform.politician_answers a
                       WHERE a.politician_id IN (SELECT keep FROM _pair UNION ALL SELECT dup FROM _pair))
       ELSE          (SELECT md5(string_agg(c::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id))
                        FROM inform.politician_context c
                       WHERE c.politician_id IN (SELECT keep FROM _pair UNION ALL SELECT dup FROM _pair))
     END);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: answers or context changed; this file must not write inform.*'; END IF;

  RAISE NOTICE 'CA_0360 applied: Rose and Biggs governor candidacies moved onto their sitting rows; Season 1 untouched';
END $$;

COMMIT;
