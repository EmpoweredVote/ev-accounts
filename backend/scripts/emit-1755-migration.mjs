// Emits 1755 from the capture file, so the delete list and the rollback record cannot drift apart.
// Deleting by a re-derived predicate would let the two disagree the moment the predicate changed.
import { readFileSync, writeFileSync } from 'node:fs';

const cap = JSON.parse(readFileSync('data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json', 'utf8'));
if (cap.n_rows !== cap.rows.length) throw new Error('capture file is internally inconsistent');

const pairs = cap.rows.map((r) => `  ('${r.politician_id}','${r.topic_id}')`).join(',\n');

// The 40 role-holders and role-candidates migration 1735 protected. Their context rows are NOT orphans
// (they kept their answers), so they are outside this delete by construction -- which is exactly why
// they make a good guard: if the delete ever widened, these are the first rows it would take.
const KEEP = readFileSync('migrations/1735_judicial_topic_scope.sql', 'utf8')
  .split('INSERT INTO js_keep VALUES')[1].split(';')[0]
  .trim().replace(/\n/g, '\n');

const sql = `-- 1755_judicial_orphan_context_delete.sql
-- The context left behind when migration 1735 blanked the role-conduct judicial answers.
--
-- 🔴 THIS IS NOT A NEW DEFECT -- IT IS THE DOCUMENTED RESIDUE OF A CORRECT FIX, AND NOBODY CONNECTED
-- THE TWO. 1735 (2026-08-12) deleted 117 answers on the three ladders that ask about the subject's own
-- conduct in a role they neither hold nor seek, and deliberately kept the context. Guard 2 of that
-- migration ASSERTS the context survived. The next morning ORPHAN_CONTEXT went 50 -> 224 and CI stayed
-- red for 19 runs, because a blanked answer plus a surviving reasoning row IS the orphan shape.
-- 🔑 Generalise: retiring an answer and retiring a stance are not the same operation. Whenever a pass
-- deletes answers, decide what happens to the context in the SAME migration -- the gate will find it
-- either way, just later and with less of the reasoning still in the room.
--
-- 🔑 1735 COULD NOT SEE 2 OF THESE 119, AND THE REASON IS THE ONE THIS WORKSTREAM KEEPS RE-LEARNING.
-- It drove FROM inform.politician_answers, so William Smith and Jeff Waldstreicher -- whose Bail &
-- Pretrial answers had already been blanked by the Maryland pass -- were outside its universe by
-- construction, not missed by a loose predicate. That is the identical FROM-clause blindness that hid
-- this entire class from the gate until 2026-08-07, recurring inside the fix for it. Both are the same
-- category error as the other 117 and are removed with them.
--
-- WHY DELETE AND NOT REWRITE AS A DOCUMENTED BLANK. A blank says "we looked and found nothing". That
-- is not what is true here: the question does not apply to this person at all. Rewriting 119 rows to
-- assert an absence that was never tested would put a false statement in a voter-facing field to make
-- a gate go quiet.
--
-- ⚠ WHAT IS BEING GIVEN UP, STATED PLAINLY. Roughly 80 of these rows carry real, named-instrument
-- evidence -- Warren co-sponsoring the No Money Bail Act, Brownsberger authoring the 2018 CJ reform
-- law, Nazarian's AYE on SB 10, Mitchell's Care First Pretrial Agency motion. That research is good;
-- it is simply attached to a ladder its subject cannot stand on. \`judicial-criminal-justice\` and
-- \`public-safety-approach\` are live and role-UNSCOPED, so a legislator can hold a position on either,
-- and that is where this evidence may belong. Moving it is re-research against a different question,
-- NOT a re-parenting UPDATE: bail-reform evidence supports a bail chair, not automatically a criminal
-- justice chair. Recorded as owed; every row is preserved verbatim in the rollback file below.
--
-- Every deleted pair is listed explicitly, taken from the rollback capture rather than re-derived, so
-- the record and the delete cannot disagree. The capture script re-ran 1735's holds-or-runs test at
-- capture time and refuses to emit if any row qualifies; all 119 returned false.
--
-- Rollback: data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json
--           (reasoning and sources verbatim -- restoring is an INSERT from that file)
BEGIN;

CREATE TEMP TABLE joc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE joc_target (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO joc_target VALUES
${pairs};

-- the 40 role-holders/candidates 1735 protected: their context must be untouched by this
CREATE TEMP TABLE joc_keep (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO joc_keep VALUES
${KEEP};

-- Fail fast if the world moved since capture.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM joc_target;
  IF n <> 119 THEN RAISE EXCEPTION 'pre-check: target is % rows, expected 119', n; END IF;

  -- every target must still exist as context...
  SELECT count(*) INTO n FROM joc_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=t.pid AND c.topic_id=t.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target row(s) no longer exist', n; END IF;

  -- ...and must still be ORPHANS. If someone answered one of these since capture, deleting its
  -- context would create an ANSWER_WITHOUT_CONTEXT violation, which is zero-tolerance.
  SELECT count(*) INTO n FROM joc_target t
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=t.pid AND a.topic_id=t.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target row(s) acquired an answer since capture', n; END IF;

  SELECT count(*) INTO n FROM joc_target t JOIN joc_keep k ON k.pid=t.pid AND k.tid=t.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) are in BOTH lists', n; END IF;
END $$;

DELETE FROM inform.politician_context c USING joc_target t
WHERE c.politician_id = t.pid AND c.topic_id = t.tid;

-- Guard 1: exactly 119 context rows gone, and NOT ONE answer touched.
DO $$
DECLARE ctx_after int; ans_after int; s record;
BEGIN
  SELECT * INTO s FROM joc_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before - 119 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected -119', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers moved % -> %', s.ans_before, ans_after; END IF;
END $$;

-- Guard 2: the 40 protected rows still have BOTH their answer and their context. Checked by explicit
-- id rather than by re-running the delete's predicate -- a guard that re-derives what it is guarding
-- is verification that isn't. (1735's own lesson, kept.)
DO $$
DECLARE lost_ctx int; lost_ans int;
BEGIN
  SELECT count(*) INTO lost_ctx FROM joc_keep k
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=k.pid AND c.topic_id=k.tid);
  IF lost_ctx > 0 THEN RAISE EXCEPTION 'guard 2: % protected row(s) lost context', lost_ctx; END IF;
  SELECT count(*) INTO lost_ans FROM joc_keep k
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=k.pid AND a.topic_id=k.tid);
  IF lost_ans > 0 THEN RAISE EXCEPTION 'guard 2: % protected row(s) lost their answer', lost_ans; END IF;
END $$;

-- Guard 3: no gate-visible orphan remains on any role-scoped judicial ladder, and no answer anywhere
-- lost its context. The second half is the zero-tolerance check the gate runs; asserting it here means
-- a mistake fails inside the transaction instead of in CI.
DO $$
DECLARE left_over int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO left_over
    FROM inform.politician_context pc
    JOIN inform.compass_topics t ON t.id = pc.topic_id AND t.judicial_role IS NOT NULL
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF left_over <> 0 THEN RAISE EXCEPTION 'guard 3: % judicial orphan(s) remain', left_over; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) now have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'judicial orphan context: 119 deleted, 40 protected rows intact, 0 judicial orphans left';
END $$;

COMMIT;
`;

writeFileSync('migrations/1755_judicial_orphan_context_delete.sql', sql);
console.log(`emitted 1755 with ${cap.rows.length} pairs`);
