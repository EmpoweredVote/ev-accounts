-- CA_0184_merge_duplicate_rows_carrying_compass_answers.sql
-- Identity merge of 9 duplicate person rows whose compass answers sit only (or partly) on the DUPLICATE, while the
-- seat sits on the twin. Moves the answers the twin lacks -- with their context rows, context evidence and stance
-- review rows -- onto the seated twin, fixes one misspelled name, and deactivates the duplicates.
-- Part of the "active incumbent with no office_terms row" clean-up (CA_0180 - CA_0183).
--
-- THE PAIRS (duplicate -> seated twin):
--   Salt Lake County Council: Aimee Winder Newton (District 3), Carlos A. Moreno (District 2), Dea Theodore
--     (District 6), Jiro Johnson (District 1), Ross Romero (District 4), Sheldon Stewart (District 5). Same full name;
--     the twin holds the seat and has NO answers; the duplicate has all of them.
--   Victoria Petro -> Victoria Petro-Eschler (Salt Lake City Council District 1). Twin has no answers.
--   Nanette Barragan -> the CA-44 row, whose name is misspelled "Nanette Diaz Baragán". The duplicate (from the inform
--     migration) has 23 answers; the twin has 17: 12 the same, 4 CONFLICTING, 7 only on the duplicate.
--   Tony Strickland: the cicero duplicate CA_0180 deactivated. It alone answers School Vouchers (Season 1).
--
-- 🔴 THIS FILE EDITS A CLOSED SEASON, WITH THE OVERRIDE THE TRIGGER ASKS FOR. inform.closed_season_is_immutable()
-- blocks every write to a Season 1 answer or context row unless the migration sets
-- inform.allow_closed_season_write = 'on' and says why. Why: this is an IDENTITY correction, not a position change.
-- No value, season, topic or topic_revision pin changes; each answer moves from one row of a person to the other row
-- of the SAME person, where the read paths look for it. Left alone, deactivating the duplicates would hide 70 Season 1
-- and 8 Season 2 answers from the people's own profiles. The override is set with SET LOCAL, so it ends with this
-- transaction.
--
-- WHAT MOVES, per (topic, season) the twin does NOT answer: the answer, its politician_context row, that context's
-- politician_context_evidence rows (5, Jiro Johnson), and the duplicate's stance_research_review rows (6, Jiro
-- Johnson). Also moved: Barragán's 2 name aliases and her politician_id_bridge row (inform id 6f5db776), so the old
-- inform id resolves to the seated row.
-- NOT MOVED: where both rows answer the same (topic, season). Same value -> the twin already has it. Different value ->
-- 4 for Barragán and 4 for Strickland stay on the deactivated duplicate as a stance-review lead; this file does not
-- choose between them.
-- Context move mechanics: politician_context_evidence references its context row by (politician_id, topic_id,
-- season_id) with no ON UPDATE rule, so each context row is COPIED to the twin, its evidence re-pointed, and the
-- duplicate's copy removed -- a move, not a deletion of content. No answer is deleted.
--
-- NAME FIX: the CA-44 twin "Nanette Diaz Baragán" (last_name "Baragán") becomes "Nanette Diaz Barragán"
-- ("Barragán"), the spelling her own alias rows and house.gov use.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews, which covered the closed-season override below).
--   Dry run x2 repeated right before the apply; verified after: 8 active duplicates inactive, the override is off again,
--   8 conflicting answers (Barragan 4, Strickland 4) left on the duplicates for stance review.
--
-- ROLLBACK: every moved row is listed by key in _ans / _srr / _alias below; re-point them to the duplicate (with the
-- same override), restore the Barragán name, and set the duplicates back to active / incumbent.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run moves nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (dup uuid PRIMARY KEY, keep uuid, dup_name text, keep_office uuid) ON COMMIT DROP;
INSERT INTO _pair
SELECT x.dup, x.keep, x.dup_name, och.office_id
  FROM (VALUES
    ('13752a3e-8159-4569-ac16-3736c16c96be'::uuid, 'b89b1a2b-03b1-4cc7-add1-6dbb7f986976'::uuid, 'Aimee Winder Newton'),
    ('d077198d-0013-420d-9603-81cf6f2e7316', 'd7169049-314d-4545-ad82-e7d2817bbab2', 'Carlos A. Moreno'),
    ('dd90ac18-7613-4a2f-bfc1-2eddfebb4daf', '87715601-731d-4aaf-bd26-3cd3e2377179', 'Dea Theodore'),
    ('261b4428-3b92-4d3f-a013-00c4b10a7925', 'd1bd8ce5-1323-4476-8663-be3295998e36', 'Jiro Johnson'),
    ('2ec55690-4c8a-4e9e-934b-f0f945947721', 'a0333140-ee4d-4b76-b7ab-7b6eb688e6a8', 'Ross Romero'),
    ('bc7cdf2d-2ee7-404f-b6be-286bf4252dc5', 'b004af3b-577d-4564-aec4-144be999d57a', 'Sheldon Stewart'),
    ('7fa1fd18-c121-49e1-912a-67889f574f13', 'cbd6c67a-27dc-4b07-87de-4e06811443a1', 'Victoria Petro'),
    ('6f5db776-afcb-40c3-87a5-83e9408d3044', '5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Barragan'),
    ('b156be63-59f0-4caa-98d9-44ae7afccf79', '863ef272-ea35-482b-aee2-447c06bd469d', 'Tony Strickland')
  ) AS x(dup, keep, dup_name)
  JOIN essentials.office_current_holder och ON och.politician_id = x.keep;

-- the answers to move: on the duplicate, for a (topic, season) the twin does not answer. On a re-run these are found
-- on the twin with the duplicate's recorded marker instead (see the note on each moved context row below).
CREATE TEMP TABLE _ans (dup uuid, keep uuid, topic_id uuid, season_id uuid, PRIMARY KEY (dup, topic_id, season_id)) ON COMMIT DROP;
INSERT INTO _ans
SELECT pr.dup, pr.keep, a.topic_id, a.season_id
  FROM _pair pr JOIN inform.politician_answers a ON a.politician_id = pr.dup
 WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers k
                    WHERE k.politician_id = pr.keep AND k.topic_id = a.topic_id AND k.season_id = a.season_id);

CREATE TEMP TABLE _srr ON COMMIT DROP AS
SELECT r.id, pr.dup, pr.keep FROM inform.stance_research_review r JOIN _pair pr ON pr.dup = r.politician_id;
CREATE TEMP TABLE _alias ON COMMIT DROP AS
SELECT a.id, pr.dup, pr.keep FROM essentials.politician_name_aliases a JOIN _pair pr ON pr.dup = a.politician_id;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _pair;
  IF v_n <> 9 THEN RAISE EXCEPTION 'PRE: % of 9 twins hold a seat', v_n; END IF;

  -- first run: 70 closed + 8 open answers to move; a re-run finds 0 (they are already on the twins)
  SELECT count(*) INTO v_n FROM _ans;
  IF v_n NOT IN (78, 0) THEN RAISE EXCEPTION 'PRE: % answers to move, expected 78 (or 0 on a re-run)', v_n; END IF;

  -- every answer to move has its context row, and the twin has no context row for that (topic, season)
  SELECT count(*) INTO v_n FROM _ans x
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = x.dup AND c.topic_id = x.topic_id AND c.season_id = x.season_id)
      OR EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = x.keep AND c.topic_id = x.topic_id AND c.season_id = x.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % answer(s) to move lack a context row or collide with one on the twin', v_n; END IF;

  -- the duplicates carry nothing else this file does not handle
  SELECT count(*) INTO v_n FROM _pair pr
   WHERE EXISTS (SELECT 1 FROM essentials.race_candidates x WHERE x.politician_id = pr.dup)
      OR EXISTS (SELECT 1 FROM transparent_motivations.politician_sources x WHERE x.essentials_politician_id = pr.dup AND pr.dup_name <> 'Tony Strickland')
      OR EXISTS (SELECT 1 FROM essentials.office_terms x WHERE x.politician_id = pr.dup)
      OR EXISTS (SELECT 1 FROM inform.evidence_items x WHERE x.politician_id = pr.dup)
      OR EXISTS (SELECT 1 FROM inform.topic_rewrite_stance_proposals x WHERE x.politician_id = pr.dup);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % duplicate(s) carry rows this file does not move', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' AND NOT full_name_manual_override
     AND full_name IN ('Nanette Diaz Baragán', 'Nanette Diaz Barragán');
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the CA-44 row is not in its reviewed state'; END IF;
END $$;

-- ─── 1. Move answers, context, evidence (closed-season override, identity fix only) ───────────
SET LOCAL inform.allow_closed_season_write = 'on';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id, editor_id, created_at, updated_at)
SELECT x.keep, c.topic_id, c.reasoning, c.sources, c.season_id, c.topic_revision_id, c.editor_id, c.created_at, c.updated_at
  FROM _ans x JOIN inform.politician_context c ON c.politician_id = x.dup AND c.topic_id = x.topic_id AND c.season_id = x.season_id;

UPDATE inform.politician_context_evidence e SET politician_id = x.keep
  FROM _ans x WHERE e.politician_id = x.dup AND e.topic_id = x.topic_id AND e.season_id = x.season_id;

DELETE FROM inform.politician_context c
 USING _ans x WHERE c.politician_id = x.dup AND c.topic_id = x.topic_id AND c.season_id = x.season_id;

UPDATE inform.politician_answers a SET politician_id = x.keep
  FROM _ans x WHERE a.politician_id = x.dup AND a.topic_id = x.topic_id AND a.season_id = x.season_id;

RESET inform.allow_closed_season_write;

UPDATE inform.stance_research_review r SET politician_id = x.keep FROM _srr x WHERE r.id = x.id AND r.politician_id = x.dup;
UPDATE essentials.politician_name_aliases a SET politician_id = x.keep FROM _alias x WHERE a.id = x.id AND a.politician_id = x.dup;
UPDATE politician_id_bridge b SET essentials_id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7'
 WHERE b.essentials_id = '6f5db776-afcb-40c3-87a5-83e9408d3044' AND b.inform_id = '6f5db776-afcb-40c3-87a5-83e9408d3044';

-- ─── 2. Barragán spelling, and deactivate the duplicates ───────────────────────────────────────
UPDATE essentials.politicians
   SET full_name = 'Nanette Diaz Barragán', last_name = 'Barragán',
       notes = COALESCE(notes, ARRAY[]::text[]) || 'CA_0184 (2026-09-23): name was misspelled "Nanette Diaz Baragán"; corrected to the spelling of her alias rows and house.gov.'::text
 WHERE id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' AND full_name = 'Nanette Diaz Baragán';

UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0184 (2026-09-23): DUPLICATE of ' || pr.keep::text
               || ', the row that holds the seat. Compass answers the seated row lacked moved there (closed-season '
               || 'override, identity fix); answers both rows gave with DIFFERENT values stay here as a stance-review lead.')::text
  FROM _pair pr
 WHERE d.id = pr.dup AND (d.is_active OR d.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the duplicates keep only the answers that CONFLICT with the twin (4 Barragán + 4 Strickland) and any the twin
  -- also gives with the same value; nothing the twin lacks is left behind
  SELECT count(*) INTO v_n FROM _pair pr JOIN inform.politician_answers a ON a.politician_id = pr.dup
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers k WHERE k.politician_id = pr.keep AND k.topic_id = a.topic_id AND k.season_id = a.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % answer(s) the twin lacks are still on a duplicate', v_n; END IF;
  SELECT count(*) INTO v_n FROM _pair pr JOIN inform.politician_answers a ON a.politician_id = pr.dup
    JOIN inform.politician_answers k ON k.politician_id = pr.keep AND k.topic_id = a.topic_id AND k.season_id = a.season_id AND k.value <> a.value;
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: % conflicting answers left on the duplicates, expected 8 (4 Barragán + 4 Strickland)', v_n; END IF;

  -- every answer on the twins has its context row (the move carried the pairs together)
  SELECT count(*) INTO v_n FROM _pair pr JOIN inform.politician_answers a ON a.politician_id = pr.keep
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = pr.keep AND c.topic_id = a.topic_id AND c.season_id = a.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % answer(s) on the twins without a context row', v_n; END IF;
  SELECT count(*) INTO v_n FROM _pair pr JOIN inform.politician_context c ON c.politician_id = pr.dup
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = pr.dup AND a.topic_id = c.topic_id AND a.season_id = c.season_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % orphan context row(s) left on the duplicates', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.stance_research_review WHERE politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % stance review row(s) still on the duplicates', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context_evidence WHERE politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % context evidence row(s) still on the duplicates', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians d JOIN _pair pr ON pr.dup = d.id WHERE NOT d.is_active AND NOT d.is_incumbent;
  IF v_n <> 9 THEN RAISE EXCEPTION 'POST: % of 9 duplicates inactive', v_n; END IF;
  SELECT count(*) INTO v_n FROM _pair pr JOIN essentials.office_current_holder och ON och.politician_id = pr.keep AND och.office_id = pr.keep_office;
  IF v_n <> 9 THEN RAISE EXCEPTION 'POST: % of 9 twins still on their seat', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' AND full_name = 'Nanette Diaz Barragán';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: the CA-44 name is not corrected'; END IF;

  RAISE NOTICE 'CA_0184 applied: 9 duplicates merged; dup-only answers moved with context; 8 conflicts left for review';
END $$;

COMMIT;
