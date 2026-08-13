-- 1735_judicial_topic_scope.sql
-- The judicial ladders were being answered by people who do not hold the role they speak as.
--
-- 🔴 THE MEASUREMENT. The corpus holds **287 politicians in judge-titled offices. NOT ONE of them
-- answers either judge-scoped topic.** Every answer on those ladders belonged to someone else.
-- `offices.role_canonical` cannot detect this: it is set on only 230 offices and its values are
-- executive (governor, attorney_general, MAYOR, …) — there is no judge or DA value at all. Role has
-- to be read from the office TITLE, and from the race a candidate is running in.
--
-- 🔑 THE DISTINCTION THAT DECIDES EACH TOPIC IS ITS OWN QUESTION TEXT.
-- Three of the four ask about the office-holder's CONDUCT IN THAT ROLE, and nobody else can hold a
-- position on them:
--   · Bail and Pretrial Decisions — "Should A JUDGE trust what prosecutors say, or watch them
--     closely?" Chair 5 is "judges shouldn't second-guess that judgment".
--   · Police Accountability — "When government employees do wrong, does THE OFFICE defend them or
--     hold them accountable?" Chair 5 is "The client is the government".
--   · Prosecution Priorities — "Does THE OFFICE try to put people away, or find better solutions?"
-- A state senator cannot hold a position on how *their office* charges cases. That is a category
-- error, not a sourcing gap, and it is what this migration removes.
--
-- ⚠ **Judicial Interpretation is NOT in that set and its answers are NOT touched.** Its question —
-- "Does the law change with the times, or does it mean what it said when it was written?" — is
-- general jurisprudence, and chairs 1-4 are stated impersonally ("Courts should reconsider old
-- rulings…"). A legislator can hold that view; they vote on judicial nominees on exactly this axis.
-- There the TAG is the defect, so `judicial_role` is cleared and its 71 answers stand. Deleting
-- them would have destroyed legitimate data — the reason this migration is not uniform.
--
-- 🔑 QUALIFYING IS "HOLDS **OR IS RUNNING FOR**" THE ROLE. Checking office_terms alone would have
-- blanked 15 legitimate rows: six candidates for **LA Superior Court** answering Bail and Pretrial,
-- and nine candidates for City Attorney / District Attorney answering the two prosecutor ladders.
-- They have no office term because they do not hold office YET. ⚠ Their races carry the office only
-- as free-text `position_name` ("LA Superior Court Office 14") with a NULL office_id, so the race
-- title must be read too.
-- 🔴 That same widening caught one row the office-term test would have KEPT by accident:
-- **Faizah Malik is running for Los Angeles City Council District 11**, not for City Attorney, so
-- her Police Accountability answer is blanked with the rest.
--
-- ── 117 BLANKED (answer deleted, context kept) ────────────────────────────────────────────────
--   Police Accountability 70 · Bail and Pretrial Decisions 24 · Prosecution Priorities 23
-- ── 40 KEPT — 25 role-holders (AGs, DAs, City Attorneys) + 15 role-candidates ─────────────────
-- The guard checks those 40 SURVIVED by explicit id. A guard that re-ran the delete's own predicate
-- would be verification that isn't.
--
-- ⚠ NOT FIXED HERE: nothing PREVENTS this recurring. There is no reliable role flag to enforce
-- against — `role_canonical` has no judicial values — so a scope constraint needs that column
-- populated first. Recorded as owed.
--
-- Rollback: data/stance-retirement/2026-08-12-judicial-scope-1735-rollback.json
BEGIN;

CREATE TEMP TABLE js_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers)  AS ans_before,
       (SELECT count(*) FROM inform.politician_context)  AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers a
          JOIN inform.compass_topics t ON t.id=a.topic_id
         WHERE t.title='Judicial Interpretation')        AS ji_answers_before;

-- who qualifies: holds the office, or is running for it
CREATE TEMP TABLE js_target ON COMMIT DROP AS
WITH holds AS (
  SELECT ot.politician_id,
         bool_or(o.title ILIKE '%judge%' OR o.title ILIKE '%justice%') AS is_judge,
         bool_or(o.title ILIKE '%district attorney%' OR o.title ILIKE '%state''s attorney%'
              OR o.title ILIKE '%city attorney%' OR o.title ILIKE '%county attorney%'
              OR o.title ILIKE '%prosecut%' OR o.title ILIKE '%solicitor%'
              OR o.title ILIKE '%attorney general%' OR o.title ILIKE '%corporation counsel%') AS is_da
    FROM essentials.office_terms ot JOIN essentials.offices o ON o.id = ot.office_id
   GROUP BY ot.politician_id),
runs AS (
  SELECT rc.politician_id,
         bool_or(COALESCE(o2.title,'') ILIKE '%judge%' OR COALESCE(o2.title,'') ILIKE '%justice%'
              OR r.position_name ILIKE '%court%' OR r.position_name ILIKE '%judge%'
              OR r.position_name ILIKE '%justice%') AS runs_judge,
         bool_or(COALESCE(o2.title,'') ILIKE '%attorney%' OR COALESCE(o2.title,'') ILIKE '%prosecut%'
              OR r.position_name ILIKE '%attorney%' OR r.position_name ILIKE '%prosecut%'
              OR r.position_name ILIKE '%solicitor%') AS runs_da
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
    LEFT JOIN essentials.offices o2 ON o2.id = r.office_id
   GROUP BY rc.politician_id)
SELECT a.politician_id AS pid, a.topic_id AS tid
  FROM inform.politician_answers a
  JOIN inform.compass_topics t ON t.id = a.topic_id AND t.judicial_role IS NOT NULL
                              AND t.title <> 'Judicial Interpretation'
  LEFT JOIN holds h ON h.politician_id = a.politician_id
  LEFT JOIN runs  rn ON rn.politician_id = a.politician_id
 WHERE NOT (CASE WHEN t.judicial_role='judge'
                 THEN COALESCE(h.is_judge,false) OR COALESCE(rn.runs_judge,false)
                 ELSE COALESCE(h.is_da,false)    OR COALESCE(rn.runs_da,false) END);

-- the 40 that must SURVIVE, listed explicitly rather than re-derived
CREATE TEMP TABLE js_keep (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO js_keep VALUES
('d06e70b3-b63a-477e-8b3d-8fb7e656f30e','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('7f32a8a4-fac8-44d3-af71-01f40895f5ba','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('b5e19b59-9085-48e6-8f14-864b9c94699d','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('53fd1ed7-b8f2-4c0b-a973-3592e4457472','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('839199d0-669b-45bc-aa8e-2ba63d960b7b','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('47627948-d590-47a4-9c7f-dd135043035f','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('0f6484bd-2fc1-4071-9648-d7b8a950d29c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('602f147a-90bc-4083-aeab-1d0becf088e9','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('969f1ca4-4766-44fd-8638-ef813b1835e7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('769374f9-6f4a-428f-ac54-6e1f996ee487','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('0d81c306-514e-455c-988e-b0d04f7e0897','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('3f90952e-7d1b-413d-a0e1-e319fb23fa05','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('eef42ac4-5573-47c7-8b41-f2f1e0769aec','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('6b16270a-c6c7-46be-9b9c-7def323dc4ef','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('6cd2e87b-7366-429a-a049-990751bd647f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('974cd2b6-8dd2-4794-aded-88c6ebc38a30','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('7157dd95-0f1b-4e05-bd4f-39317345b47c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('83474f06-c501-416d-a870-65d75f0cec9d','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('068393be-9502-44e6-a36f-2fa99cb9a3e8','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('77256186-0ce8-4069-9d06-1d2fd5b4b622','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('0f6484bd-2fc1-4071-9648-d7b8a950d29c','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('602f147a-90bc-4083-aeab-1d0becf088e9','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('969f1ca4-4766-44fd-8638-ef813b1835e7','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('0157dc45-31ae-4fc0-855d-0ac56b299fb2','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('2c36a446-6766-483c-b043-73bb5244eabb','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('0d81c306-514e-455c-988e-b0d04f7e0897','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('3f90952e-7d1b-413d-a0e1-e319fb23fa05','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('a8a4a392-37c8-470a-a389-889f4f41911e','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('eef42ac4-5573-47c7-8b41-f2f1e0769aec','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('6b16270a-c6c7-46be-9b9c-7def323dc4ef','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('6cd2e87b-7366-429a-a049-990751bd647f','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('7157dd95-0f1b-4e05-bd4f-39317345b47c','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('83474f06-c501-416d-a870-65d75f0cec9d','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('068393be-9502-44e6-a36f-2fa99cb9a3e8','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('77256186-0ce8-4069-9d06-1d2fd5b4b622','abb99d95-cbb1-4617-8f8b-f220ef6028ca');

-- fail fast if the world moved since the rollback was captured
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM js_target;
  IF n <> 117 THEN RAISE EXCEPTION 'pre-check failed: target is % rows, expected 117', n; END IF;
  SELECT count(*) INTO n FROM js_keep;
  IF n <> 40 THEN RAISE EXCEPTION 'pre-check failed: keep list is % rows, expected 40', n; END IF;
  SELECT count(*) INTO n FROM js_target t JOIN js_keep k ON k.pid=t.pid AND k.tid=t.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check failed: % row(s) are in BOTH lists', n; END IF;
END $$;

DELETE FROM inform.politician_answers a USING js_target t
WHERE a.politician_id = t.pid AND a.topic_id = t.tid;

-- Judicial Interpretation is a general topic, not a role-conduct one: drop the tag, keep the data.
UPDATE inform.compass_topics SET judicial_role = NULL WHERE id = '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee';

-- Guard 1: exactly 117 answers gone; context untouched; no orphans.
DO $$
DECLARE ans_after int; ctx_after int; orphans int; s record;
BEGIN
  SELECT * INTO s FROM js_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before - 117 THEN
    RAISE EXCEPTION 'guard 1 failed: answers % -> %, expected -117', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1 failed: context moved % -> %', s.ctx_before, ctx_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 1 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 2: the blanked rows kept their context, and the 40 role-holders/candidates SURVIVED.
DO $$
DECLARE lost_ctx int; killed int;
BEGIN
  SELECT count(*) INTO lost_ctx FROM js_target t
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=t.pid AND c.topic_id=t.tid);
  IF lost_ctx > 0 THEN RAISE EXCEPTION 'guard 2 failed: % blanked row(s) lost context', lost_ctx; END IF;
  SELECT count(*) INTO killed FROM js_keep k
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id=k.pid AND a.topic_id=k.tid);
  IF killed > 0 THEN RAISE EXCEPTION 'guard 2 failed: % role-holder/candidate row(s) were deleted', killed; END IF;
END $$;

-- Guard 3: Judicial Interpretation lost its tag and NOT ONE of its answers.
DO $$
DECLARE ji_after int; still_tagged int; s record;
BEGIN
  SELECT * INTO s FROM js_snap;
  SELECT count(*) INTO ji_after FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id=a.topic_id WHERE t.title='Judicial Interpretation';
  IF ji_after <> s.ji_answers_before THEN
    RAISE EXCEPTION 'guard 3 failed: Judicial Interpretation answers % -> %', s.ji_answers_before, ji_after; END IF;
  SELECT count(*) INTO still_tagged FROM inform.compass_topics
   WHERE title='Judicial Interpretation' AND judicial_role IS NOT NULL;
  IF still_tagged > 0 THEN RAISE EXCEPTION 'guard 3 failed: tag not cleared'; END IF;
  RAISE NOTICE 'judicial scope: 117 blanked, 40 kept, Judicial Interpretation re-tagged';
END $$;

COMMIT;
