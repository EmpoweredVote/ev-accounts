-- CA_0373_merge_romaine_quinn_candidate_duplicate.sql
-- Identity merge: Wisconsin State Senator Romaine Quinn is split across two essentials.politicians rows. The SITTING row
-- (State Senate District 25, LegiScan people id 16423, votes, Season 1 answer, portrait) and a CANDIDATE row created by
-- the 2026 roster load, "Romaine Robert Quinn", which holds his two State Senate District 23 race rows (2026-08-11
-- primary, 2026-11-03 general, both 'won') and the gun-policy Season 3 research written on 2026-11-10 (PR #1370).
-- The candidacy and that research move to the sitting row.
--
-- Slot CA_0373 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand. Pure DML.
-- ✅ APPLIED to prod 2026-11-10 (approval: Chris Andrews). Both gates green. Before the apply: dry run passed, a
--   double-apply changed 0 rows on the second pass, and two planted faults each failed the post-gate — evidence not
--   re-pointed ("3 of 7 rows on the survivor"; the context delete cascades it away) and the answer's value altered in
--   the move ("1 fingerprint(s) changed"). Read back after: 2dbf3032 active, seated in District 25, 2 race rows,
--   2 answers (S1 + S3), 4 evidence rows; a0ea7354 inactive and empty. check:duplicate-people dropped the pair.
--
-- WHICH ROW SURVIVES, AND WHY IT IS THE SITTING ONE. Ruling 2026-09-24 (Chris Andrews, CA_0270): a merge never edits
-- the closed Season 1. Here BOTH rows hold answers:
--   2dbf3032 (sitting)   civil-rights, Season 1 (CLOSED)  — the closed-season trigger forbids moving it.
--   a0ea7354 (candidate) gun-policy,   Season 3 (DRAFT)   — writable; moving it edits no closed season.
-- So the only merge that leaves Season 1 untouched is onto 2dbf3032. That row also carries everything a loader keys
-- on: LegiScan id 16423 (legislative_politician_id_map 7636312f — the hand-off note said the map pointed at a0ea7354;
-- measured 2026-11-10, it points at 2dbf3032), 562 legislative_votes, 531 cosponsor rows, the portrait, and
-- external_id -5505025. Survivor = 2dbf3032-65b1-4898-813b-0f62dac0192e "Romaine Quinn".
--
-- Every uuid/text column named like *politician*, *essentials_id*, *person_id* or subject_id in every schema (69
-- columns) was scanned for both ids on 2026-11-10. The candidate row holds exactly the rows listed in _move below and
-- nothing else (no office_terms, images, aliases, contacts, quotes, speakers, id-map, votes, FEC or bridge rows).
-- Neither row has a deprecated politicians.office_id (both NULL), so there is no snapshot to repoint.
--
-- THE SEAT. The sitting row's term 2a655273 on office df48ef3d (State Senator, State Senate District 25; term_start
-- NULL, start_precision 'unknown', open-ended) is NOT TOUCHED and is fingerprinted. He won District 23 on 2026-11-03;
-- that seat is NOT seated here. Wisconsin senators take office in January 2027, so seating District 23 (and closing
-- District 25) is a separate post-election seating pass. The post-gate asserts he holds no District 23 term.
--
-- VALUES THIS FILE OVERWRITES (pre-image, measured 2026-11-10):
--   essentials.race_candidates  18ff147c-578f-488f-b08d-8cf40227b7a5  politician_id a0ea7354-d1ff-49d2-a6c4-44a0a8099222
--   essentials.race_candidates  4bce4d9c-d3e2-4e01-a03f-7ef5e2196c8c  politician_id a0ea7354-d1ff-49d2-a6c4-44a0a8099222
--   inform.politician_answers   (a0ea7354, topic 56125933 gun-policy, season 7b3a066c)  politician_id a0ea7354…  value 5.0
--   inform.politician_context   (a0ea7354, 56125933, 7b3a066c)  re-keyed: copied verbatim to 2dbf3032, then the
--                                a0ea7354 copy deleted (the evidence FK has no ON UPDATE CASCADE, so it cannot be UPDATEd)
--   inform.politician_context_evidence  342dd575, 70f645fd, 3f345fa3, 58e5aab4  politician_id a0ea7354…
--   inform.stance_research_review       44fbce6b-36fc-43ec-aaca-39cf6cdb4c37   politician_id a0ea7354…
--   inform.topic_research_outcomes      (a0ea7354, 56125933, 7b3a066c)          politician_id a0ea7354…  outcome 'seated'
--   essentials.politicians a0ea7354  is_active true -> false (is_incumbent already false; full_name, external_id
--                                    -5507153 and its one existing note are left as they are)
-- ADDED: alias 'Romaine Robert Quinn' on 2dbf3032 (it had no aliases); one CA_0373 note on each row.
-- NOT CHANGED: every Season 1 row (fingerprinted); office_terms; names; external_ids; portraits; race_candidates.full_name
--   (left as printed on the ballot). Both race rows have NULL photo_url and website_url, so the
--   race_candidate_mirror_data trigger copies nothing onto the survivor.
--
-- ROLLBACK (once applied): re-point the rows in _move back to a0ea7354 (for the context row: copy back, re-point the
--   four evidence rows, delete the 2dbf3032 copy), delete the alias with source 'CA_0373', set a0ea7354 is_active = true,
--   and remove both CA_0373 notes.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _p (keep uuid, dup uuid, topic uuid, season uuid, sd25_office uuid, sd25_term uuid) ON COMMIT DROP;
INSERT INTO _p VALUES ('2dbf3032-65b1-4898-813b-0f62dac0192e', 'a0ea7354-d1ff-49d2-a6c4-44a0a8099222',
                       '56125933-b82a-46c5-847b-b2e9a146b89f', '7b3a066c-815d-43b2-a6a0-6a3029778075',
                       'df48ef3d-9728-4125-9aaa-4921ace0c193', '2a655273-75d4-4609-b7f2-3a2f7b69aa1c');

CREATE TEMP TABLE _move (tbl text, id uuid, PRIMARY KEY (tbl, id)) ON COMMIT DROP;
INSERT INTO _move VALUES
  ('race_candidates', '18ff147c-578f-488f-b08d-8cf40227b7a5'),
  ('race_candidates', '4bce4d9c-d3e2-4e01-a03f-7ef5e2196c8c'),
  ('evidence',        '342dd575-548d-4d9b-9934-36f0af8680f6'),
  ('evidence',        '70f645fd-926f-4482-a4bc-d994e5046bf5'),
  ('evidence',        '3f345fa3-e972-4793-9a01-f87a789bac79'),
  ('evidence',        '58e5aab4-9dba-432f-8159-24c4fecdc682'),
  ('review',          '44fbce6b-36fc-43ec-aaca-39cf6cdb4c37');

-- Fingerprints, taken before any write:
--   s1   every closed-season answer/context row of either id — must not change at all
--   s3   the moving Season 3 rows WITHOUT politician_id — content must survive the move byte for byte
--   term the District 25 term row — must not change
CREATE TEMP TABLE _fp ON COMMIT DROP AS
SELECT 's1' AS k, md5(coalesce((SELECT string_agg(to_jsonb(a)::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id)
                                  FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
                                 WHERE s.status = 'closed' AND a.politician_id IN (SELECT keep FROM _p UNION ALL SELECT dup FROM _p)), '')
                 || '#' ||
                 coalesce((SELECT string_agg(to_jsonb(c)::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id)
                             FROM inform.politician_context c JOIN inform.seasons s ON s.id = c.season_id
                            WHERE s.status = 'closed' AND c.politician_id IN (SELECT keep FROM _p UNION ALL SELECT dup FROM _p)), '')) AS h
UNION ALL
SELECT 's3', md5(
    coalesce((SELECT string_agg((to_jsonb(a) - 'politician_id')::text, '|') FROM inform.politician_answers a, _p
               WHERE a.politician_id IN (_p.keep, _p.dup) AND a.topic_id = _p.topic AND a.season_id = _p.season), '') || '#' ||
    coalesce((SELECT string_agg((to_jsonb(c) - 'politician_id')::text, '|') FROM inform.politician_context c, _p
               WHERE c.politician_id IN (_p.keep, _p.dup) AND c.topic_id = _p.topic AND c.season_id = _p.season), '') || '#' ||
    coalesce((SELECT string_agg((to_jsonb(e) - 'politician_id')::text, '|' ORDER BY e.id) FROM inform.politician_context_evidence e
               WHERE e.id IN (SELECT id FROM _move WHERE tbl = 'evidence')), '') || '#' ||
    coalesce((SELECT string_agg((to_jsonb(r) - 'politician_id')::text, '|') FROM inform.stance_research_review r
               WHERE r.id IN (SELECT id FROM _move WHERE tbl = 'review')), '') || '#' ||
    coalesce((SELECT string_agg((to_jsonb(tro) - 'politician_id')::text, '|') FROM inform.topic_research_outcomes tro, _p
               WHERE tro.politician_id IN (_p.keep, _p.dup) AND tro.topic_id = _p.topic AND tro.season_id = _p.season), ''))
UNION ALL
SELECT 'term', md5(to_jsonb(t)::text) FROM essentials.office_terms t, _p WHERE t.id = _p.sd25_term;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; p record;
BEGIN
  SELECT * INTO p FROM _p;

  -- the two reviewed rows, by name
  SELECT count(*) INTO v_n FROM essentials.politicians k, essentials.politicians d
   WHERE k.id = p.keep AND d.id = p.dup
     AND k.full_name = 'Romaine Quinn' AND d.full_name = 'Romaine Robert Quinn'
     AND k.first_name = d.first_name AND k.last_name = d.last_name
     AND k.is_active AND k.is_incumbent AND NOT d.is_incumbent;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the two Quinn rows no longer match their reviewed names and flags'; END IF;

  -- the survivor holds District 25 now, through the reviewed term (office-rooted join: one row per office)
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
   WHERE och.office_id = p.sd25_office AND och.politician_id = p.keep;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: 2dbf3032 is not the current holder of State Senate District 25'; END IF;

  -- LegiScan 16423 points at the survivor
  SELECT count(*) INTO v_n FROM essentials.legislative_politician_id_map
   WHERE id_type = 'legiscan' AND id_value = '16423' AND politician_id = p.keep;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: LegiScan 16423 does not map to 2dbf3032'; END IF;

  -- the Season 3 rows sit in a season that is not closed (the move must not need the closed-season override)
  SELECT count(*) INTO v_n FROM inform.seasons WHERE id = p.season AND status <> 'closed';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: season 7b3a066c is closed or missing; this file must not write it'; END IF;

  -- the survivor has no gun-policy row of its own in that season, so the move cannot collide
  SELECT (SELECT count(*) FROM inform.politician_answers      WHERE politician_id = p.keep AND topic_id = p.topic AND season_id = p.season)
       + (SELECT count(*) FROM inform.topic_research_outcomes WHERE politician_id = p.keep AND topic_id = p.topic AND season_id = p.season)
    INTO v_n;
  -- 0 on the first run; 2 on a re-run (answer + outcome already moved)
  IF v_n NOT IN (0, 2) THEN RAISE EXCEPTION 'PRE: survivor already holds % unexpected gun-policy Season 3 row(s)', v_n; END IF;

  -- each listed row is on the candidate row (first run) or the survivor (re-run)
  SELECT count(*) INTO v_n FROM _move m
   WHERE (m.tbl = 'race_candidates' AND EXISTS (SELECT 1 FROM essentials.race_candidates x        WHERE x.id = m.id AND x.politician_id IN (p.dup, p.keep)))
      OR (m.tbl = 'evidence'        AND EXISTS (SELECT 1 FROM inform.politician_context_evidence x WHERE x.id = m.id AND x.politician_id IN (p.dup, p.keep)))
      OR (m.tbl = 'review'          AND EXISTS (SELECT 1 FROM inform.stance_research_review x      WHERE x.id = m.id AND x.politician_id IN (p.dup, p.keep)));
  IF v_n <> 7 THEN RAISE EXCEPTION 'PRE: % of 7 reviewed rows in place', v_n; END IF;

  -- the candidate row holds nothing this file does not handle
  SELECT (SELECT count(*) FROM essentials.race_candidates           WHERE politician_id = p.dup AND id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM inform.politician_context_evidence   WHERE politician_id = p.dup AND id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM inform.stance_research_review        WHERE politician_id = p.dup AND id NOT IN (SELECT id FROM _move))
       + (SELECT count(*) FROM inform.politician_answers            WHERE politician_id = p.dup AND NOT (topic_id = p.topic AND season_id = p.season))
       + (SELECT count(*) FROM inform.politician_context            WHERE politician_id = p.dup AND NOT (topic_id = p.topic AND season_id = p.season))
       + (SELECT count(*) FROM inform.topic_research_outcomes       WHERE politician_id = p.dup AND NOT (topic_id = p.topic AND season_id = p.season))
       + (SELECT count(*) FROM inform.own_words_passages            WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.evidence_items                WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.office_terms              WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.politician_images         WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.politician_contacts       WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.politician_name_aliases   WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.quotes                    WHERE politician_id = p.dup)
       + (SELECT count(*) FROM meetings.speakers                    WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.legislative_politician_id_map WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.legislative_votes         WHERE politician_id = p.dup)
       + (SELECT count(*) FROM essentials.legislative_bill_cosponsors WHERE politician_id = p.dup)
       + (SELECT count(*) FROM transparent_motivations.politician_sources WHERE essentials_politician_id = p.dup)
       + (SELECT count(*) FROM politician_id_bridge                 WHERE essentials_id = p.dup)
       + (SELECT count(*) FROM essentials.politicians WHERE office_id IS NOT NULL AND id IN (p.dup, p.keep))
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows on the candidate row (or an office_id snapshot) that this file does not handle', v_n; END IF;

  -- the race rows carry no photo or website, so the mirror trigger copies nothing onto the survivor
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id IN (SELECT id FROM _move WHERE tbl = 'race_candidates')
     AND (COALESCE(photo_url, '') <> '' OR COALESCE(website_url, '') <> '');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % race row(s) now carry a photo or website; re-review', v_n; END IF;

  RAISE NOTICE 'CA_0373 pre-flight OK';
END $$;

-- ─── 1. The candidacy ────────────────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates x SET politician_id = p.keep, updated_at = now()
  FROM _p p
 WHERE x.id IN (SELECT id FROM _move WHERE tbl = 'race_candidates') AND x.politician_id = p.dup;

-- ─── 2. The gun-policy Season 3 research ─────────────────────────────────────────────────────────
UPDATE inform.politician_answers a SET politician_id = p.keep
  FROM _p p
 WHERE a.politician_id = p.dup AND a.topic_id = p.topic AND a.season_id = p.season;

-- context: copy verbatim under the survivor, re-point the evidence, then drop the old key
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id,
                                       editor_id, created_at, updated_at, evidence_tier)
SELECT p.keep, c.topic_id, c.reasoning, c.sources, c.season_id, c.topic_revision_id,
       c.editor_id, c.created_at, c.updated_at, c.evidence_tier
  FROM inform.politician_context c, _p p
 WHERE c.politician_id = p.dup AND c.topic_id = p.topic AND c.season_id = p.season
   AND NOT EXISTS (SELECT 1 FROM inform.politician_context k
                    WHERE k.politician_id = p.keep AND k.topic_id = p.topic AND k.season_id = p.season);

UPDATE inform.politician_context_evidence e SET politician_id = p.keep
  FROM _p p
 WHERE e.id IN (SELECT id FROM _move WHERE tbl = 'evidence') AND e.politician_id = p.dup;

DELETE FROM inform.politician_context c
 USING _p p
 WHERE c.politician_id = p.dup AND c.topic_id = p.topic AND c.season_id = p.season
   AND EXISTS (SELECT 1 FROM inform.politician_context k
                WHERE k.politician_id = p.keep AND k.topic_id = p.topic AND k.season_id = p.season);

UPDATE inform.stance_research_review r SET politician_id = p.keep
  FROM _p p
 WHERE r.id IN (SELECT id FROM _move WHERE tbl = 'review') AND r.politician_id = p.dup;

UPDATE inform.topic_research_outcomes tro SET politician_id = p.keep
  FROM _p p
 WHERE tro.politician_id = p.dup AND tro.topic_id = p.topic AND tro.season_id = p.season;

-- ─── 3. The ballot name as an alias ──────────────────────────────────────────────────────────────
INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT p.keep, 'Romaine Robert Quinn', 'CA_0373' FROM _p p
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_name_aliases
                    WHERE politician_id = p.keep AND lower(alias) = 'romaine robert quinn');

-- ─── 4. Deactivate the candidate row; note both ──────────────────────────────────────────────────
UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0373 (2026-11-10): DUPLICATE of ' || p.keep::text
               || ' (sitting State Senator, LegiScan 16423). Its two 2026 State Senate District 23 race rows and its '
               || 'gun-policy Season 3 research moved there; deactivated, not deleted.')::text
  FROM _p p
 WHERE d.id = p.dup AND d.is_active;

UPDATE essentials.politicians k
   SET notes = COALESCE(k.notes, ARRAY[]::text[]) || ('CA_0373 (2026-11-10): holds the 2026 State Senate District 23 '
               || 'candidacy and gun-policy Season 3 research of ' || p.dup::text || ', a duplicate row of the same '
               || 'person, now deactivated. Season 1 was not touched. District 23 is not seated yet (term starts January 2027).')::text
  FROM _p p
 WHERE k.id = p.keep
   AND NOT EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0373 (2026-11-10): holds%');

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; p record;
BEGIN
  SELECT * INTO p FROM _p;

  -- every listed row is on the survivor
  SELECT count(*) INTO v_n FROM _move m
   WHERE (m.tbl = 'race_candidates' AND EXISTS (SELECT 1 FROM essentials.race_candidates x        WHERE x.id = m.id AND x.politician_id = p.keep))
      OR (m.tbl = 'evidence'        AND EXISTS (SELECT 1 FROM inform.politician_context_evidence x WHERE x.id = m.id AND x.politician_id = p.keep))
      OR (m.tbl = 'review'          AND EXISTS (SELECT 1 FROM inform.stance_research_review x      WHERE x.id = m.id AND x.politician_id = p.keep));
  IF v_n <> 7 THEN RAISE EXCEPTION 'POST: % of 7 rows on the survivor', v_n; END IF;

  -- the survivor holds the answer, context and outcome for gun-policy in Season 3
  SELECT (SELECT count(*) FROM inform.politician_answers      WHERE politician_id = p.keep AND topic_id = p.topic AND season_id = p.season)
       + (SELECT count(*) FROM inform.politician_context      WHERE politician_id = p.keep AND topic_id = p.topic AND season_id = p.season)
       + (SELECT count(*) FROM inform.topic_research_outcomes WHERE politician_id = p.keep AND topic_id = p.topic AND season_id = p.season)
    INTO v_n;
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 gun-policy Season 3 rows on the survivor', v_n; END IF;

  -- the candidate row is empty, inactive and noted
  SELECT (SELECT count(*) FROM essentials.race_candidates         WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.politician_answers          WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.politician_context          WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.politician_context_evidence WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.stance_research_review      WHERE politician_id = p.dup)
       + (SELECT count(*) FROM inform.topic_research_outcomes     WHERE politician_id = p.dup)
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows still on the candidate row', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d
   WHERE d.id = p.dup AND NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0373 (2026-11-10): DUPLICATE of ' || p.keep::text || '%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: candidate row not deactivated and noted'; END IF;

  -- the survivor: active, incumbent, still District 25's holder, both race rows, alias, note
  SELECT count(*) INTO v_n FROM essentials.politicians k
   WHERE k.id = p.keep AND k.is_active AND k.is_incumbent
     AND EXISTS (SELECT 1 FROM essentials.office_current_holder och WHERE och.office_id = p.sd25_office AND och.politician_id = p.keep)
     AND (SELECT count(*) FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
           WHERE rc.politician_id = p.keep AND r.position_name = 'State Senate District 23') = 2
     AND EXISTS (SELECT 1 FROM essentials.politician_name_aliases a WHERE a.politician_id = p.keep AND lower(a.alias) = 'romaine robert quinn')
     AND EXISTS (SELECT 1 FROM unnest(k.notes) n WHERE n LIKE 'CA_0373 (2026-11-10): holds%');
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: survivor not in its target state'; END IF;

  -- District 23 is NOT seated by this file: the survivor holds exactly one term, and it is the District 25 one
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE politician_id = p.keep;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: survivor holds % office_terms rows; expected only the District 25 term', v_n; END IF;

  -- LegiScan 16423 resolves to exactly one politician, the survivor
  SELECT count(DISTINCT politician_id) INTO v_n FROM essentials.legislative_politician_id_map
   WHERE id_type = 'legiscan' AND id_value = '16423' AND politician_id = p.keep;
  IF v_n <> 1 OR EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map
                          WHERE id_type = 'legiscan' AND id_value = '16423' AND politician_id <> p.keep)
  THEN RAISE EXCEPTION 'POST: LegiScan 16423 does not resolve to the survivor alone'; END IF;

  -- exactly one active row for the person
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE is_active AND id IN (p.keep, p.dup);
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % active Quinn rows; expected 1', v_n; END IF;

  -- 🟢 Season 1 untouched, the moved content unchanged, the District 25 term unchanged
  SELECT count(*) INTO v_n FROM _fp f
   WHERE f.h IS DISTINCT FROM (CASE f.k
     WHEN 's1' THEN md5(coalesce((SELECT string_agg(to_jsonb(a)::text, '|' ORDER BY a.politician_id, a.topic_id, a.season_id)
                                    FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
                                   WHERE s.status = 'closed' AND a.politician_id IN (p.keep, p.dup)), '')
                        || '#' ||
                        coalesce((SELECT string_agg(to_jsonb(c)::text, '|' ORDER BY c.politician_id, c.topic_id, c.season_id)
                                    FROM inform.politician_context c JOIN inform.seasons s ON s.id = c.season_id
                                   WHERE s.status = 'closed' AND c.politician_id IN (p.keep, p.dup)), ''))
     WHEN 's3' THEN md5(
         coalesce((SELECT string_agg((to_jsonb(a) - 'politician_id')::text, '|') FROM inform.politician_answers a
                    WHERE a.politician_id IN (p.keep, p.dup) AND a.topic_id = p.topic AND a.season_id = p.season), '') || '#' ||
         coalesce((SELECT string_agg((to_jsonb(c) - 'politician_id')::text, '|') FROM inform.politician_context c
                    WHERE c.politician_id IN (p.keep, p.dup) AND c.topic_id = p.topic AND c.season_id = p.season), '') || '#' ||
         coalesce((SELECT string_agg((to_jsonb(e) - 'politician_id')::text, '|' ORDER BY e.id) FROM inform.politician_context_evidence e
                    WHERE e.id IN (SELECT id FROM _move WHERE tbl = 'evidence')), '') || '#' ||
         coalesce((SELECT string_agg((to_jsonb(r) - 'politician_id')::text, '|') FROM inform.stance_research_review r
                    WHERE r.id IN (SELECT id FROM _move WHERE tbl = 'review')), '') || '#' ||
         coalesce((SELECT string_agg((to_jsonb(tro) - 'politician_id')::text, '|') FROM inform.topic_research_outcomes tro
                    WHERE tro.politician_id IN (p.keep, p.dup) AND tro.topic_id = p.topic AND tro.season_id = p.season), ''))
     ELSE (SELECT md5(to_jsonb(t)::text) FROM essentials.office_terms t WHERE t.id = p.sd25_term)
   END);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % fingerprint(s) changed (Season 1, moved Season 3 content, or the District 25 term)', v_n; END IF;

  -- the fingerprints were not taken over nothing
  IF (SELECT count(*) FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id
       WHERE s.status = 'closed' AND a.politician_id = p.keep) <> 1
  THEN RAISE EXCEPTION 'POST: the survivor''s Season 1 answer is not where the fingerprint expects it'; END IF;

  RAISE NOTICE 'CA_0373 applied: Romaine Quinn is one record (2dbf3032) holding the District 25 seat, the District 23 race and the gun-policy research; Season 1 untouched';
END $$;

COMMIT;
