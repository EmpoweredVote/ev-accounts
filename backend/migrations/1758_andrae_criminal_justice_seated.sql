-- 1758_andrae_criminal_justice_seated.sql
-- The entire relocatable yield of the 119 judicial rows deleted by 1755: ONE row.
--
-- 🔴 THE PREMISE OF THE RELOCATION DID NOT SURVIVE CONTACT WITH THE LADDERS. 1755's header recorded
-- that ~80 of the deleted rows carried real named-instrument evidence and suggested it might belong on
-- `judicial-criminal-justice` or `public-safety-approach`, both live and role-unscoped. That was a
-- statement about EVIDENCE QUALITY, and evidence quality is not what binds. Three things do, and each
-- was measured (scripts/judicial-relocation-survey.mjs):
--
--   1. THE DESTINATION IS ALREADY OCCUPIED. 96 of the 119 politicians already hold an answer or a
--      context row on judicial-criminal-justice, and 102 on public-safety-approach. Only 23 and 17
--      slots respectively are free. There is nothing to relocate INTO for the rest, and overwriting
--      would destroy research that was done properly.
--
--   2. THE LADDERS ASK DIFFERENT QUESTIONS THAN THE EVIDENCE ANSWERS.
--      · `public-safety-approach` asks "How should your community FUND AND OPERATE public safety
--        services?" and every chair is about the police BUDGET and staffing. The 70 Police
--        Accountability rows are about officer MISCONDUCT -- qualified immunity, the Justice in
--        Policing Act, misconduct investigation. Both mention police; they answer different
--        questions. On-topic by VOCABULARY, not by RATIONALE -- the same test that blanked Taplin in
--        migration 1738.
--      · `judicial-criminal-justice` asks "When someone breaks the law, what matters most?", a
--        rehabilitation-to-punishment axis about the purpose of the sanction. The 26 Bail and Pretrial
--        rows are about detention BEFORE adjudication, of people who have not been convicted of
--        anything. The ladder does not reach them.
--      · Only Prosecution Priorities -- diversion versus prosecution -- maps onto that axis at all.
--
--   3. `public-safety-approach` SAYS "YOUR COMMUNITY", AND 69 OF THE 119 ARE FEDERAL OR STATE
--      OFFICEHOLDERS. A US Senator has no community police budget. Moving those rows there would
--      re-commit the exact category error 1755 removed, wearing a friendlier topic name. Mark Warner
--      was among the rows whose public-safety slot was free.
--
-- Intersecting all three leaves THREE candidates, and reading them leaves one:
--   · Antonio Hayes / Bail -> Criminal Justice — REJECTED twice over. Pretrial detention is not what
--     the ladder asks about, and the row's only sources are a bare mgaleg member page (which shows a
--     single session) and a Ballotpedia bio. No named instrument.
--   · Michael Verveer / Prosecution -> Criminal Justice — REJECTED. Authoring Madison's cannabis
--     decriminalisation ordinance says what should not be a crime, not what matters most once someone
--     breaks the law. It proves DIRECTION and cannot discriminate a chair.
--   · Richelle Andrae / Prosecution -> Criminal Justice — SEATED at chair 2 below.
--
-- ✅ ANDRAE, VERIFIED AGAINST THE LIVE PAGE BEFORE SEATING, NOT AFTER. richelle4danecounty.org/issues
-- read via scripts/read-site.mjs (raw=6,640c, body=6,167c): the sentence "provide the necessary
-- resource for evidence-based diversion programs that repair harm" and the commitment to "implement
-- Community Court" are both present verbatim.
-- 🔑 Chair 2 is "giving the person a fair chance to make things right — through treatment, community
-- service, or restitution". Repairing harm through a community court IS that mechanism. This follows
-- the precedent set in migration 1734, which seated Alonzo Washington at this same chair on
-- restorative-practices bills because "making things right" is chair 2's own idea. Seating Andrae
-- differently would make the corpus inconsistent with itself.
-- ⚠ The same paragraph also says the reforms "balance public safety while ultimately reducing our
-- reliance on incarceration". "Balance" gestures at chair 3 and "root causes" at chair 1, so this was
-- not a clean single reading -- but neither of those is a MECHANISM, and chair 2's mechanism is named
-- outright. Recorded here so the next reader sees the competing sentences rather than rediscovering
-- them.
-- ⚠ Andrae's Public Safety Approach row is ALREADY seated at chair 2 from this same page. That is why
-- only the criminal-justice slot is written here.
--
-- This migration only INSERTs, so the answer-delete context guard does not apply -- but the property
-- it protects is asserted anyway: the new answer gets its context in the same statement pair, and
-- guard 3 proves ORPHAN_CONTEXT did not move.
--
-- Survey data: data/stance-retirement/2026-08-14-judicial-relocation-survey.json
-- Deleted rows, verbatim: data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json
BEGIN;

CREATE TEMP TABLE ajc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

-- Fail fast rather than silently updating: if either row already exists, someone has researched this
-- pair since the survey and their work must not be overwritten by a paste from a stale worklist.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='85f785f3-08c3-4d80-ba9a-96b81be758c0'
     AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrae already has a criminal-justice answer'; END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='85f785f3-08c3-4d80-ba9a-96b81be758c0'
     AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrae already has a criminal-justice context row'; END IF;

  -- The chair must exist on this ladder. A value of 2 that no stance row defines would render blank.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: chair 2 is not defined exactly once on this ladder'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('85f785f3-08c3-4d80-ba9a-96b81be758c0','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Issues page calls for implementing Community Court and providing "the necessary resource for evidence-based diversion programs that repair harm", within reforms aimed at "reducing our reliance on incarceration".$r$,
 ARRAY['https://www.richelle4danecounty.org/issues']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('85f785f3-08c3-4d80-ba9a-96b81be758c0','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 2);

-- Guard 1: exactly one answer and one context appear, and nothing else moves.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM ajc_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 1 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +1', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 1 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +1', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: the row says what it is supposed to say, cites the page it was verified against, and sits
-- at the chair that was read -- checked on CONTENT, not on the fact that an INSERT ran.
DO $$
DECLARE v numeric; r text; srcs text[];
BEGIN
  SELECT a.value, c.reasoning, c.sources INTO v, r, srcs
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE a.politician_id='85f785f3-08c3-4d80-ba9a-96b81be758c0'
     AND a.topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';

  IF v <> 2 THEN RAISE EXCEPTION 'guard 2: chair is %, expected 2', v; END IF;
  IF r !~ 'diversion programs that repair harm' THEN
    RAISE EXCEPTION 'guard 2: reasoning does not carry the verified quotation'; END IF;
  IF NOT ('https://www.richelle4danecounty.org/issues' = ANY(srcs)) THEN
    RAISE EXCEPTION 'guard 2: the page the claim was verified against is not cited'; END IF;
  IF cardinality(srcs) = 0 THEN RAISE EXCEPTION 'guard 2: no sources'; END IF;
END $$;

-- Guard 3: the two gate invariants this workstream exists to protect are unchanged. Writing an answer
-- is precisely the operation that publishes reasoning, so ORPHAN_CONTEXT is asserted here rather than
-- left for CI.
DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'Andrae seated at judicial-criminal-justice chair 2; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
