BEGIN;

-- =============================================================================
-- CC_0079: the Senate gun-policy rung 4 — the 49 the ladder could not seat
-- =============================================================================
-- Slot CC_0079 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. 49 gun-policy answers at chair 4 for sitting U.S. Senators who
-- sponsor or cosponsor the Constitutional Concealed Carry Reciprocity Act, plus
-- the 49 context rows that justify them. With CC_0078's 45 and CC_0074's 2, this
-- takes gun-policy from 47 of 98 senators seated to 96.
--
--   47  S. 65   Constitutional Concealed Carry Reciprocity Act of 2025
--    2  S. 214  Constitutional Concealed Carry Reciprocity Act of 2023
--
-- 🔴 DO NOT APPLY THIS UNTIL THE CHAIRS HAVE BEEN REVIEWED BY A HUMAN. 49 rows
-- are 49 published claims about named sitting senators. All 49 pass
-- `verify-reresearch-rows.mjs --tier=federal` — right tier, promoted topic, no
-- prior answer, and every distinctive claim term present in the raw HTML of the
-- cited bill text (26/26 on both bases) — but that gate proves the reasoning is
-- CARRIED BY the source, never that the chair is the right reading of it.
--
-- ── THIS FILE EXISTS BECAUSE THE LADDER MOVED, NOT BECAUSE THE RECORD DID ────
--
-- These 49 senators were the largest absence in CC_0078, and deliberately so.
-- Under Season 2's original rung 4 — "keep current gun laws, adding no new
-- restrictions" — they had no home: that rung is a status-quo position and they
-- are legislating a change, while rung 5 wants major restrictions repealed AND
-- permitless carry, and reciprocity is neither. Seating them at 4 understated and
-- at 5 overstated, so CC_0078 wrote no row and said why.
--
-- CA_0104 reworded rung 4 on 2026-09-08 to "add no new restrictions, and at most
-- loosen rules on carrying, such as honoring permits across state lines" — which
-- is this bill described — and moved the 4-vs-5 line to whether the major federal
-- gun laws stay. That is what makes these rows writable.
--
-- 🔑 THE BILL'S OWN TEXT EVIDENCES THE 4-VS-5 LINE, which is why the reasoning
-- can stop where it does. S. 926D conditions the right on "an individual who is
-- not prohibited by Federal law from possessing... a firearm": the federal
-- prohibitions are the premise the bill builds on, not something it repeals.
--
-- ⚠ SO THESE ROWS DEPEND ON CA_0104 STANDING. Precondition 6 below refuses to
-- apply unless the rung 4 the open season actually SERVES is that wording. If a
-- later revision of version 2 rewrites rung 4 again, these 49 placements have to
-- be re-read against it before they can stand — the evidence would not have
-- changed, but the rung it was measured against would have.
--
-- ── THE PIN SAYS REVISION 2 AND THE VOTER READS REVISION 3 ───────────────────
--
-- ADR 0006 (Option Y): a season is bound to a VERSION and serves the latest
-- published revision of it. CA_0104 was classified CLARIFYING, so it kept version
-- 2 and bumped the revision to 3, and Season 2's pin stayed frozen on revision 2.
-- Answers written here take topic_revision_id from season_questions — revision 2,
-- as CC_0074 and CC_0078 did — and the read path resolves that to revision 3, so
-- the voter sees CA_0104's wording. Both are correct and they are not the same id;
-- do not "fix" the pin to point at revision 3.
--
-- ⚠ THIS RESOLUTION IS EASY TO GET WRONG AND IT WAS. cohort-worksheet.mjs keyed
-- its printed ladder straight off season_questions.topic_revision_id and so handed
-- researchers revision 2's rung 4 — wording the open season does not serve. It was
-- 8 of the 33 federal topics, not just this one, and it is fixed in this branch by
-- copying compassService's `eff` LATERAL rather than re-deriving it.
--
-- ── THE TWO BASES ───────────────────────────────────────────────────────────
--
-- ⚠ THE 2023 BILL'S TEXT IS `pcs`, NOT `is`, AND THE `is` URL IS WORSE THAN A
-- 404. S. 214's only text version is "Placed on Calendar Senate". Requesting
-- BILLS-118s214is 302s to a govinfo landing page that answers HTTP 200 with 44kB
-- of site chrome — a citation that looks alive and carries none of the bill.
-- Hawley and McConnell are the two on the 2023 bill and not the 2025 one, so they
-- are the only rows that need it.
--
-- 🔑 GATED ON THE ROLL, KEYED BY BIOGUIDE ID, as CC_0078 was: each row required
-- the senator's bioguide id in the sponsor/cosponsor roll of the BILLSTATUS
-- record. The verifier does not check that a senator is on a bill, so this is what
-- makes extension by bill safe. S. 65's roll carries 49 ids of which 47 are
-- sitting senators; S. 214's carries 45.
--
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/119/s/BILLSTATUS-119s65.xml
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/118/s/BILLSTATUS-118s214.xml
--
-- ⚠ A SENATOR ON BOTH A RESTRICTION BILL AND RECIPROCITY IS REFUSED, not resolved
-- by precedence. Measured across all 100, the overlap is zero — which is what
-- makes the clusters a clean partition — but the two chairs are two rungs apart
-- and "currently empty" is not a reason to let an if-order decide it later.
--
-- ── WHAT IS STILL ABSENT: FOUR SENATORS ──────────────────────────────────────
--
--   Rand Paul, Lisa Murkowski   on none of the marquee bills; they need an
--                               individual read, not an extension.
--   Susan M. Collins            no gun-policy lead at all in the 2026-09-05 sweep.
--   Alan Armstrong              no lead on ANY of the nine topics, which is the
--                               signature of a bioguide that did not resolve
--                               rather than a senator with no record.
--
-- ── PROVENANCE ───────────────────────────────────────────────────────────────
--
-- 🔴 editor_id IS NULL ON BOTH TABLES, DELIBERATELY, for CC_0074's reason: the
-- prose was drafted in an assisted research session and reviewed before this
-- migration was applied, and there is no EV user account that authored it.
--
-- ⚠ NO ROLE CLAIM, and EDITING THE REASONING WILL BREAK THE GATE. The string
-- names the bill and describes what it does; a shared per-basis string cannot say
-- "sponsor" or "cosponsor" without being wrong for someone, which is the CC_0076
-- error. Every distinctive term is present in the cited text because the string
-- was written against it. Re-run the verifier if you touch it.

-- -----------------------------------------------------------------------------
-- The chair, as one editorial artefact per basis
-- -----------------------------------------------------------------------------
CREATE TEMPORARY TABLE _cc0079_basis (
  basis     text    PRIMARY KEY,
  value     numeric NOT NULL,
  reasoning text    NOT NULL,
  sources   text[]  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0079_basis VALUES
  ('ccc-2025', 4, 'A bill to allow reciprocity for the carrying of certain concealed firearms: an individual who is not prohibited by Federal law from possessing a firearm, and who is carrying a valid license or permit issued pursuant to the law of a State, may carry a concealed handgun in any State other than the State of residence of the individual that allows residents to obtain licenses or permits to carry concealed firearms.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s65is/html/BILLS-119s65is.htm']),
  ('ccc-2023', 4, 'A bill to allow reciprocity for the carrying of certain concealed firearms: an individual who is not prohibited by Federal law from possessing a firearm, and who is carrying a valid license or permit issued pursuant to the law of a State, may carry a concealed handgun in any State other than the State of residence of the individual that allows residents to obtain licenses or permits to carry concealed firearms.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118s214pcs/html/BILLS-118s214pcs.htm']);

-- -----------------------------------------------------------------------------
-- The people
-- -----------------------------------------------------------------------------
-- politician_id, not full_name: full_name is not unique across the roster, and
-- `who` is a cross-check on the row having been assembled correctly.
CREATE TEMPORARY TABLE _cc0079_rows (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  basis         text NOT NULL REFERENCES _cc0079_basis(basis)
) ON COMMIT DROP;

INSERT INTO _cc0079_rows VALUES
  ('108e7bcc-554a-49d7-81f0-c3058f933a07', 'Josh Hawley', 'ccc-2023'),
  ('f8d6555b-faea-4746-b8d8-27c41e08f4c4', 'Mitch McConnell', 'ccc-2023'),
  ('f6c97c43-41e3-45ae-bdaa-c339f2e6ed4d', 'Ashley Moody', 'ccc-2025'),
  ('2249e92f-8064-4c9e-b109-d56c0c5bb1b8', 'Bernie Moreno', 'ccc-2025'),
  ('eff33c8a-38f6-421f-a8de-24518c52d650', 'Bill Cassidy', 'ccc-2025'),
  ('0dd5daa6-87cf-43a7-a1ee-25349ae35e27', 'Bill Hagerty', 'ccc-2025'),
  ('dd5d3f6d-fc82-4774-b510-287ec47cbd84', 'Chuck Grassley', 'ccc-2025'),
  ('4d83f985-9248-4905-a9b6-5742e2df77a8', 'Cindy Hyde-Smith', 'ccc-2025'),
  ('d04b548f-8655-40f6-8d27-9989f473a828', 'Cynthia Lummis', 'ccc-2025'),
  ('a97678bc-8844-4560-87b1-5ef4f8013d96', 'Dan Sullivan', 'ccc-2025'),
  ('4f411143-634b-4e11-ab61-78acaf22ddfb', 'Dave McCormick', 'ccc-2025'),
  ('3149d855-8d85-4080-b0d6-fb83be500533', 'Deb Fischer', 'ccc-2025'),
  ('274c286d-a292-4e3f-b570-6c2d7ae9c209', 'Eric Schmitt', 'ccc-2025'),
  ('2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e', 'James Lankford', 'ccc-2025'),
  ('9a41971c-1e38-41b8-a6ec-bec6055a00b3', 'James Risch', 'ccc-2025'),
  ('2f52b4b6-f167-4452-be9b-d37a5b667e69', 'Jerry Moran', 'ccc-2025'),
  ('023c6644-356e-4afb-925b-e20f9c32209b', 'Jim Banks', 'ccc-2025'),
  ('7e434dbf-80d1-4813-9b43-af30429c8290', 'Jim Justice', 'ccc-2025'),
  ('e4b27d5e-59de-4e71-a8a7-28e7b9a80807', 'John Barrasso', 'ccc-2025'),
  ('3621bbef-a821-45fe-991c-e1744ad05203', 'John Boozman', 'ccc-2025'),
  ('2b022ce1-6272-40db-9332-015a057ec9f8', 'John Cornyn', 'ccc-2025'),
  ('b87583fe-2348-4bf3-aba5-12f5f88d3606', 'John Curtis', 'ccc-2025'),
  ('e6596b34-8d9f-4593-bf0c-4fe7fc17cd26', 'John Hoeven', 'ccc-2025'),
  ('ffe3816f-4923-4e10-b71c-8b2590a8f377', 'John Kennedy', 'ccc-2025'),
  ('661c0499-af4c-4cf9-a34b-eb0c20d5cd4b', 'John Thune', 'ccc-2025'),
  ('d5740b38-9b65-431a-9e33-645d432dec61', 'Jon Husted', 'ccc-2025'),
  ('130591ca-bfd1-4691-916b-3570341b04fb', 'Joni Ernst', 'ccc-2025'),
  ('0ba1cecc-8493-495b-8d58-34d50bbacfba', 'Katie Britt', 'ccc-2025'),
  ('88c06231-8e34-43ff-befb-8868b44383e6', 'Kevin Cramer', 'ccc-2025'),
  ('20aa1064-bbe7-484c-b779-28d99e92e608', 'Lindsey Graham', 'ccc-2025'),
  ('808ab926-365f-4b8a-a42e-628f11ecc48e', 'Marsha Blackburn', 'ccc-2025'),
  ('2971d4f9-1433-4dcd-aaa7-193241ef3c95', 'Mike Crapo', 'ccc-2025'),
  ('4f62ca82-fda1-4386-9a4a-62dd84318f83', 'Mike Lee', 'ccc-2025'),
  ('624e51ff-2f0f-45d0-bd57-1dfa8ad47013', 'Mike Rounds', 'ccc-2025'),
  ('d01ea902-317a-4a66-b346-8b29a91fcd25', 'Pete Ricketts', 'ccc-2025'),
  ('129c2764-370c-4385-ad64-4cb5744c3541', 'Rick Scott', 'ccc-2025'),
  ('9df12eb2-bc9a-4083-8004-1af4167342ea', 'Roger Marshall', 'ccc-2025'),
  ('d53cbad2-d166-4f8d-87a2-f7e5ddc7a237', 'Roger Wicker', 'ccc-2025'),
  ('00abc782-e86b-40f2-be0d-f07fad802688', 'Ron Johnson', 'ccc-2025'),
  ('6ca6aabe-6a7f-46b7-b51d-620a7f5c9913', 'Shelley Moore Capito', 'ccc-2025'),
  ('24109768-01ad-4bab-b833-b7bc1d8f437d', 'Steve Daines', 'ccc-2025'),
  ('401f1fab-c996-4b1a-92f7-2817c5dd4619', 'Ted Budd', 'ccc-2025'),
  ('a8bda21a-a5ca-4c15-9612-10fad5d5c9d6', 'Ted Cruz', 'ccc-2025'),
  ('f1271c9d-fad4-4e1e-9c22-e6e2333a8a3e', 'Thom Tillis', 'ccc-2025'),
  ('675778b0-7e6f-45ef-96b2-7bcb5d7e0af7', 'Tim Scott', 'ccc-2025'),
  ('3bb72269-7f3b-42a5-bf48-4e1963844391', 'Tim Sheehy', 'ccc-2025'),
  ('102b239c-0a3d-44b9-ae32-88d8179197e2', 'Todd Young', 'ccc-2025'),
  ('0942f325-1180-4e1a-b1df-06438f1792a3', 'Tom Cotton', 'ccc-2025'),
  ('7affca4e-db2b-4f7e-b009-9acc6b493139', 'Tommy Tuberville', 'ccc-2025');

-- The corpus size as this transaction found it, so section 4 asserts the DELTA
-- rather than a number typed days earlier. See 4e.
CREATE TEMPORARY TABLE _cc0079_before (answers int NOT NULL, context int NOT NULL) ON COMMIT DROP;

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2    uuid;
  v_n     int;
  v_rung4 text;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  IF v_s2 IS NULL THEN
    RAISE EXCEPTION 'CC_0079: no season is open — every compass write path refuses in that state';
  END IF;
  IF (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0079: the open season is not Season 2 — these chairs were researched against Season 2 ladders';
  END IF;

  -- 2. names match ids
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
    JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE lower(p.full_name) <> lower(r.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  -- 3. every id resolves at all
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = r.politician_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % row(s) name a politician_id that resolves to nobody', v_n;
  END IF;

  -- 4. the topic is one the open season asks — the CC_0066 rule, never is_live
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE topic_key = 'gun-policy') THEN
    RAISE EXCEPTION 'CC_0079: the open season does not ask gun-policy — nothing would serve these answers';
  END IF;

  -- 5. federal tier
  SELECT count(*) INTO v_n
    FROM inform.compass_topics t
   WHERE t.topic_key = 'gun-policy'
     AND EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.id)
     AND NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr
                      WHERE cr.topic_id = t.id AND cr.role_scope = 'federal');
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: gun-policy excludes the federal tier';
  END IF;

  -- 6. 🔴 THE RUNG THESE 49 SENATORS ARE PLACED ON MUST BE THE ONE CA_0104 WROTE.
  --
  -- Resolved the way the read path resolves it: from the season's pin to the
  -- LATEST PUBLISHED REVISION OF ITS VERSION, not from the pinned id. Under the
  -- pre-CA_0104 rung 4 every row in this file is wrong — that wording is a
  -- status-quo position and a reciprocity cosponsor is not in it — so this is a
  -- precondition and not a comment.
  SELECT sr.text INTO v_rung4
    FROM inform.season_questions q
    JOIN inform.compass_topics t ON t.id = q.topic_id AND t.topic_key = 'gun-policy'
    JOIN inform.compass_topic_revisions pin ON pin.id = q.topic_revision_id
    JOIN LATERAL (
      SELECT e.id
        FROM inform.compass_topic_revisions e
       WHERE e.topic_id = pin.topic_id
         AND e.version  = pin.version
         AND e.status IN ('published', 'superseded')
       ORDER BY e.revision DESC
       LIMIT 1
    ) eff ON true
    JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = 4
   WHERE q.season_id = v_s2;

  IF v_rung4 IS NULL THEN
    RAISE EXCEPTION 'CC_0079: could not resolve the rung 4 Season 2 serves for gun-policy';
  END IF;
  -- Matched on the distinctive clause, not the whole string: the corpus is
  -- inconsistent about the leading capital and the read path uppercases it anyway.
  IF lower(v_rung4) NOT LIKE '%honoring permits across state lines%' THEN
    RAISE EXCEPTION 'CC_0079: Season 2 serves rung 4 as "%" — these % rows were placed against CA_0104''s reworded rung 4 and must be re-read before they can stand', v_rung4, 49;
  END IF;

  -- 7. INSERT, not UPDATE
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % pair(s) already hold a Season 2 answer — this file has run, or the rows are stale', v_n;
  END IF;

  -- 8. nobody twice
  SELECT count(*) INTO v_n FROM (
    SELECT politician_id FROM _cc0079_rows GROUP BY politician_id HAVING count(*) > 1) d;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % politician(s) appear more than once', v_n;
  END IF;

  -- 9. discrete chairs only
  SELECT count(*) INTO v_n FROM _cc0079_basis WHERE value <> round(value) OR value < 1 OR value > 5;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % basis row(s) carry a non-discrete or out-of-range chair', v_n;
  END IF;

  IF (SELECT count(*) FROM _cc0079_rows) <> 49 THEN
    RAISE EXCEPTION 'CC_0079: expected exactly 49 rows, found %', (SELECT count(*) FROM _cc0079_rows);
  END IF;

  INSERT INTO _cc0079_before
  SELECT (SELECT count(*) FROM inform.politician_answers WHERE season_id = v_s2),
         (SELECT count(*) FROM inform.politician_context WHERE season_id = v_s2);

  RAISE NOTICE 'CC_0079 preconditions OK: Season 2 open, 49 rows, names match ids, gun-policy promoted and federal, no prior answers.';
  RAISE NOTICE 'CC_0079 rung 4 served reads: %', v_rung4;
  RAISE NOTICE 'CC_0079 baseline: Season 2 holds % answers / % context before this file.',
    (SELECT answers FROM _cc0079_before), (SELECT context FROM _cc0079_before);
END $$;

-- -----------------------------------------------------------------------------
-- 2. The answers
-- -----------------------------------------------------------------------------
-- season_id and topic_revision_id come from season_questions, NEVER hand-typed.
-- That pin is revision 2 and the voter is served revision 3 — see the header.
INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value, write_in_text, editor_id, updated_at)
SELECT r.politician_id,
       t.id,
       sq.season_id,
       sq.topic_revision_id,
       b.value,
       NULL,
       NULL,
       now()
  FROM _cc0079_rows r
  JOIN _cc0079_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'gun-policy'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 3. The context
-- -----------------------------------------------------------------------------
-- CC_0058 §3f enforces the pair: an answer with no context is an unsourced
-- position, which is the one thing this corpus must never publish.
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT r.politician_id,
       t.id,
       sq.season_id,
       sq.topic_revision_id,
       b.reasoning,
       b.sources,
       NULL,
       now()
  FROM _cc0079_rows r
  JOIN _cc0079_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'gun-policy'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 4. Assert the outcome
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2       uuid;
  v_n        int;
  v_answers  int;
  v_context  int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';

  -- 4a. every row landed at the chair its basis names
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
    JOIN _cc0079_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = b.value;
  IF v_n <> 49 THEN
    RAISE EXCEPTION 'CC_0079: % of 49 answers landed at the intended chair', v_n;
  END IF;

  -- 4b. all 49 at chair 4, not merely the right total
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = 4;
  IF v_n <> 49 THEN
    RAISE EXCEPTION 'CC_0079: % answers at chair 4, expected 49', v_n;
  END IF;

  -- 4c. each carries its reasoning and at least one source
  SELECT count(*) INTO v_n
    FROM _cc0079_rows r
    JOIN _cc0079_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_context c
      ON c.politician_id = r.politician_id AND c.topic_id = t.id AND c.season_id = v_s2
   WHERE c.reasoning = b.reasoning
     AND array_length(c.sources, 1) >= 1;
  IF v_n <> 49 THEN
    RAISE EXCEPTION 'CC_0079: % of 49 context rows landed with their reasoning and a source', v_n;
  END IF;

  -- 4d. the season-wide pair invariant still holds. CC_0058 §3f.
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                        AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0079: % non-blank Season 2 answer(s) carry no reasoning', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = v_s2 AND a.value = 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0079: % blanked answer(s) carry Season 2 reasoning', v_n;
  END IF;

  -- 4e. the corpus grew by exactly 49 and 49 — A DELTA, NOT A TOTAL.
  --
  -- 🔴 CC_0078 SHIPPED WITH ABSOLUTE TOTALS AND THEY WENT STALE BEFORE IT WAS
  --    APPLIED: written against 2689/2661, and the Miami-Dade pass moved the
  --    corpus to 2699/2671 two days later, so the assert would have failed on a
  --    file whose own rows were fine. A migration that waits for a human to review
  --    49 published claims cannot know what the whole corpus will hold by then.
  --    The delta is what this file is responsible for and still catches a failed
  --    insert, a duplicate, or a trigger adding more.
  --
  -- ⚠ THE FLOORS ARE RAISED BY HAND, AFTER APPLYING, from what the NOTICE prints.
  SELECT count(*) INTO v_answers FROM inform.politician_answers WHERE season_id = v_s2;
  SELECT count(*) INTO v_context FROM inform.politician_context WHERE season_id = v_s2;
  IF v_answers - (SELECT answers FROM _cc0079_before) <> 49 THEN
    RAISE EXCEPTION 'CC_0079: Season 2 answers grew by %, expected 49', v_answers - (SELECT answers FROM _cc0079_before);
  END IF;
  IF v_context - (SELECT context FROM _cc0079_before) <> 49 THEN
    RAISE EXCEPTION 'CC_0079: Season 2 context rows grew by %, expected 49', v_context - (SELECT context FROM _cc0079_before);
  END IF;

  -- 4f. gun-policy coverage, which is the point of the file
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'gun-policy'
   WHERE a.season_id = v_s2;
  RAISE NOTICE 'CC_0079 OK: 49 answers + 49 context at chair 4. gun-policy now holds % Season 2 answers. Season 2 now % answers / % context — RAISE THE FLOORS TO THESE NUMBERS, in a separate PR, now that the file is applied.',
    v_n, v_answers, v_context;
END $$;

COMMIT;
