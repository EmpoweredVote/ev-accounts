BEGIN;

-- =============================================================================
-- CC_0080: the Senate israel-military-aid batch - 47 answers off three measures
-- =============================================================================
-- Slot CC_0080 reserved via `steward slot CC` before this file existed.
--
-- WHAT THIS IS. 47 israel-military-aid answers for sitting U.S. Senators, plus the
-- 47 context rows that justify them. Second topic of the federal research pass;
-- gun-policy reached 96 of 100 across CC_0074 / CC_0078 / CC_0079.
--
--   43  chair 1  measures that compel or demand continued delivery of aid
--    4  chair 3  the arms-sale disapproval that prohibits a named offensive sale
--
-- 🔴 DO NOT APPLY THIS UNTIL THE CHAIRS HAVE BEEN REVIEWED BY A HUMAN. 47 rows are
-- 47 published claims about named sitting senators. All 47 pass
-- `verify-reresearch-rows.mjs --tier=federal` - right tier, promoted topic, no prior
-- answer, and every distinctive claim term present in the raw HTML of the cited text
-- - but that gate proves the reasoning is CARRIED BY the source, never that the chair
-- is the right reading of it.
--
-- -- THE THREE BASES, AND WHY EACH SEATS ITS CHAIR ----------------------------
--
-- CHAIR 1 is "continue full military aid to Israel with no new conditions".
--
--   S.Res. 682 (42 senators) says it almost verbatim: it condemns any decision to
--     halt the shipment of United States made ammunition and weapons, and DEMANDS
--     that the Administration "continue to fulfill the military aid requests from the
--     State of Israel". Neither clause imposes the compliance requirement chair 2
--     asks for; both refuse conditions outright.
--
--   H.R. 8369 (1 senator) - "to provide for the expeditious delivery of defense
--     articles and defense services for Israel". ⚠ THE HOUSE COMPANION IS HERE
--     BECAUSE ONE SENATOR NEEDS IT. Jim Banks served in the House until 2025, so his
--     cosponsorship of this Act is on H.R. 8369 and not S. 4337; a Senate-only
--     pattern silently dropped his row until the count came up one short. Same shape
--     as gun-policy's H.R. 698.
--
-- CHAIR 3 is "block offensive weapons sales while continuing defensive support such
-- as missile defense".
--
--   S.J.Res. 138 (4 senators) prohibits a NAMED sale: twelve thousand BLU-110A/B
--     general purpose, 1,000-pound bomb bodies, Transmittal No. 26-32 under section
--     36(b)(1) of the Arms Export Control Act. That is offensive ordnance, not
--     missile defense, so the rung's first clause is evidenced by the transmittal
--     itself rather than by inference. Chair 4 - "sharply cut aid as a step toward
--     ending it" - is a stronger claim a targeted disapproval does not support.
--
--   🔑 ITS ROLL IS EXACTLY THESE FOUR SENATORS: Sanders (sponsor), Van Hollen,
--   Merkley, Welch. The basis and the batch coincide, which is the cleanest form this
--   gate takes.
--
--   ⚠ SANDERS AND WELCH ALSO SIGN THE 502B HUMAN-RIGHTS REQUEST, which is chair 2's
--   instrument - a privileged resolution under the Foreign Assistance Act, and the
--   recognised way of forcing a vote on conditioning arms to an ally. Both chairs are
--   evidenced, and BLOCKING WAS TAKEN TO OUTRANK CONDITIONING: a senator who would
--   prohibit the sale is not merely asking for conditions on it. Same precedence
--   CC_0074 set when it ruled chair 3 understates a signatory of an assault weapons
--   ban. Sanders sponsors 24 such disapprovals and Welch cosponsors 12, so the
--   blocking half is not a marginal signal for either.
--
-- -- WHAT IS ABSENT, AND WHY --------------------------------------------------
--
-- 🔴 BRIAN SCHATZ IS REFUSED, DELIBERATELY, AND THE BASIS AGREES. He holds exactly
-- one on-axis lead - S.J.Res. 111, cosponsored 2024-09-25 - and is otherwise a
-- mainstream pro-aid Democrat. One cosponsorship two years old is too thin to publish
-- a rung on, the same call made for Murkowski on gun-policy. He is also the only
-- settleable senator absent from every basis in this file, so the refusal falls out of
-- the gate rather than needing an exclusion list.
--
-- 26 senators hold ONLY commemorative leads and 24 only off-axis ones. The largest
-- lead on this topic is a solidarity resolution 84 of 100 senators cosponsored: it
-- appropriates nothing, conditions nothing and blocks nothing, so it cannot separate
-- chair 1 from chair 5. See the triage under data/federal-pass/.
--
-- ⚠ FOUR MEASURES WERE TREATED AS ON-AXIS UNTIL SOMEBODY READ THEM, and one would
-- have carried 40 rows into this file. "Stand with Israel Act" (S. 1521) prohibits US
-- CONTRIBUTIONS TO THE UNITED NATIONS related to discrimination against Israel - not
-- US military aid in any sense. Also removed: a war-reserves stockpile authority
-- extension, a DoD munitions ASSESSMENT, and KC-46 TRAINING for Israeli personnel.
-- Fixed in lead-axis.mjs, which now requires an entry to quote the bill's stated
-- purpose. This file's 47 rows postdate that correction.
--
-- -- PROVENANCE --------------------------------------------------------------
--
-- 🔴 editor_id IS NULL ON BOTH TABLES, DELIBERATELY, for CC_0074's reason: the prose
-- was drafted in an assisted research session and reviewed before this migration was
-- applied, and there is no EV user account that authored it.
--
-- ⚠ NO ROLE CLAIM, AND EDITING THE REASONING WILL BREAK THE GATE. Each string
-- describes what the MEASURE does in that measure's own vocabulary, so sponsor and
-- cosponsor sit on identical words - the CC_0076 error cannot recur. Every distinctive
-- term is present in the cited text because the string was written against it.

-- -----------------------------------------------------------------------------
-- The chairs, one artefact per basis
-- -----------------------------------------------------------------------------
-- Reasoning is per BASIS, not per person and not per chair: the two chair-1 bases
-- cite different texts and so carry different words.
CREATE TEMPORARY TABLE _cc0080_basis (
  basis     text    PRIMARY KEY,
  value     numeric NOT NULL,
  reasoning text    NOT NULL,
  sources   text[]  NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0080_basis VALUES

  ('deliver-sres682', 1, 'A resolution that condemns any decision to halt the shipment of United States made ammunition and weapons to the State of Israel, and demands that the Administration continue to fulfill the military aid requests from the State of Israel.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118sres682is/html/BILLS-118sres682is.htm']),
  ('deliver-hr8369', 1, 'A bill to provide for the expeditious delivery of defense articles and defense services for Israel.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-118hr8369ih/html/BILLS-118hr8369ih.htm']),
  ('block-sjres138', 3, 'A joint resolution providing that the proposed foreign military sale to the Government of Israel described in Transmittal No. 26-32 is prohibited: twelve thousand BLU-110A/B general purpose, 1,000-pound bomb bodies, submitted pursuant to section 36(b)(1) of the Arms Export Control Act.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119sjres138is/html/BILLS-119sjres138is.htm']);

-- -----------------------------------------------------------------------------
-- The people
-- -----------------------------------------------------------------------------
CREATE TEMPORARY TABLE _cc0080_rows (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  basis         text NOT NULL REFERENCES _cc0080_basis(basis)
) ON COMMIT DROP;

INSERT INTO _cc0080_rows VALUES

  ('3cc5cece-cec0-4490-8faa-37a6b66231c7', 'Bernie Sanders', 'block-sjres138'),
  ('61a601c2-7faa-4889-abf2-bbb0066ce448', 'Chris Van Hollen', 'block-sjres138'),
  ('0eabc969-c1a1-47b7-8d34-6113b723a170', 'Jeff Merkley', 'block-sjres138'),
  ('9a9874ab-159f-4ffb-b88e-f058df02d5fa', 'Peter Welch', 'block-sjres138'),
  ('023c6644-356e-4afb-925b-e20f9c32209b', 'Jim Banks', 'deliver-hr8369'),
  ('eff33c8a-38f6-421f-a8de-24518c52d650', 'Bill Cassidy', 'deliver-sres682'),
  ('0dd5daa6-87cf-43a7-a1ee-25349ae35e27', 'Bill Hagerty', 'deliver-sres682'),
  ('dd5d3f6d-fc82-4774-b510-287ec47cbd84', 'Chuck Grassley', 'deliver-sres682'),
  ('4d83f985-9248-4905-a9b6-5742e2df77a8', 'Cindy Hyde-Smith', 'deliver-sres682'),
  ('d04b548f-8655-40f6-8d27-9989f473a828', 'Cynthia Lummis', 'deliver-sres682'),
  ('a97678bc-8844-4560-87b1-5ef4f8013d96', 'Dan Sullivan', 'deliver-sres682'),
  ('3149d855-8d85-4080-b0d6-fb83be500533', 'Deb Fischer', 'deliver-sres682'),
  ('274c286d-a292-4e3f-b570-6c2d7ae9c209', 'Eric Schmitt', 'deliver-sres682'),
  ('2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e', 'James Lankford', 'deliver-sres682'),
  ('9a41971c-1e38-41b8-a6ec-bec6055a00b3', 'James Risch', 'deliver-sres682'),
  ('2f52b4b6-f167-4452-be9b-d37a5b667e69', 'Jerry Moran', 'deliver-sres682'),
  ('e4b27d5e-59de-4e71-a8a7-28e7b9a80807', 'John Barrasso', 'deliver-sres682'),
  ('3621bbef-a821-45fe-991c-e1744ad05203', 'John Boozman', 'deliver-sres682'),
  ('2b022ce1-6272-40db-9332-015a057ec9f8', 'John Cornyn', 'deliver-sres682'),
  ('e6596b34-8d9f-4593-bf0c-4fe7fc17cd26', 'John Hoeven', 'deliver-sres682'),
  ('ffe3816f-4923-4e10-b71c-8b2590a8f377', 'John Kennedy', 'deliver-sres682'),
  ('661c0499-af4c-4cf9-a34b-eb0c20d5cd4b', 'John Thune', 'deliver-sres682'),
  ('130591ca-bfd1-4691-916b-3570341b04fb', 'Joni Ernst', 'deliver-sres682'),
  ('108e7bcc-554a-49d7-81f0-c3058f933a07', 'Josh Hawley', 'deliver-sres682'),
  ('0ba1cecc-8493-495b-8d58-34d50bbacfba', 'Katie Britt', 'deliver-sres682'),
  ('88c06231-8e34-43ff-befb-8868b44383e6', 'Kevin Cramer', 'deliver-sres682'),
  ('cc873a93-cb47-405a-93b0-bb2848fdd57e', 'Lisa Murkowski', 'deliver-sres682'),
  ('808ab926-365f-4b8a-a42e-628f11ecc48e', 'Marsha Blackburn', 'deliver-sres682'),
  ('2971d4f9-1433-4dcd-aaa7-193241ef3c95', 'Mike Crapo', 'deliver-sres682'),
  ('4f62ca82-fda1-4386-9a4a-62dd84318f83', 'Mike Lee', 'deliver-sres682'),
  ('624e51ff-2f0f-45d0-bd57-1dfa8ad47013', 'Mike Rounds', 'deliver-sres682'),
  ('f8d6555b-faea-4746-b8d8-27c41e08f4c4', 'Mitch McConnell', 'deliver-sres682'),
  ('d01ea902-317a-4a66-b346-8b29a91fcd25', 'Pete Ricketts', 'deliver-sres682'),
  ('129c2764-370c-4385-ad64-4cb5744c3541', 'Rick Scott', 'deliver-sres682'),
  ('9df12eb2-bc9a-4083-8004-1af4167342ea', 'Roger Marshall', 'deliver-sres682'),
  ('d53cbad2-d166-4f8d-87a2-f7e5ddc7a237', 'Roger Wicker', 'deliver-sres682'),
  ('00abc782-e86b-40f2-be0d-f07fad802688', 'Ron Johnson', 'deliver-sres682'),
  ('6ca6aabe-6a7f-46b7-b51d-620a7f5c9913', 'Shelley Moore Capito', 'deliver-sres682'),
  ('24109768-01ad-4bab-b833-b7bc1d8f437d', 'Steve Daines', 'deliver-sres682'),
  ('6b817122-f196-4b72-b0b4-2d9763c4be47', 'Susan M. Collins', 'deliver-sres682'),
  ('401f1fab-c996-4b1a-92f7-2817c5dd4619', 'Ted Budd', 'deliver-sres682'),
  ('a8bda21a-a5ca-4c15-9612-10fad5d5c9d6', 'Ted Cruz', 'deliver-sres682'),
  ('f1271c9d-fad4-4e1e-9c22-e6e2333a8a3e', 'Thom Tillis', 'deliver-sres682'),
  ('675778b0-7e6f-45ef-96b2-7bcb5d7e0af7', 'Tim Scott', 'deliver-sres682'),
  ('102b239c-0a3d-44b9-ae32-88d8179197e2', 'Todd Young', 'deliver-sres682'),
  ('0942f325-1180-4e1a-b1df-06438f1792a3', 'Tom Cotton', 'deliver-sres682'),
  ('7affca4e-db2b-4f7e-b009-9acc6b493139', 'Tommy Tuberville', 'deliver-sres682');

CREATE TEMPORARY TABLE _cc0080_before (answers int NOT NULL, context int NOT NULL) ON COMMIT DROP;

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2 uuid;
  v_n  int;
  v_r1 text;
  v_r3 text;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  IF v_s2 IS NULL THEN
    RAISE EXCEPTION 'CC_0080: no season is open - every compass write path refuses in that state';
  END IF;
  IF (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0080: the open season is not Season 2';
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0080_rows r JOIN essentials.politicians p ON p.id = r.politician_id
   WHERE lower(p.full_name) <> lower(r.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM _cc0080_rows r
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = r.politician_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % row(s) name a politician_id that resolves to nobody', v_n;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics_promoted WHERE topic_key = 'israel-military-aid') THEN
    RAISE EXCEPTION 'CC_0080: the open season does not ask israel-military-aid';
  END IF;

  SELECT count(*) INTO v_n FROM inform.compass_topics t
   WHERE t.topic_key = 'israel-military-aid'
     AND EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.id)
     AND NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr
                      WHERE cr.topic_id = t.id AND cr.role_scope = 'federal');
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: israel-military-aid excludes the federal tier';
  END IF;

  -- 🔴 THE RUNGS THESE ROWS SIT ON MUST STILL READ AS RESEARCHED.
  --
  -- Resolved the way the READ PATH resolves wording - from the season's pin to the
  -- LATEST PUBLISHED REVISION OF ITS VERSION, not from the pinned id. That distinction
  -- is not pedantry: cohort-worksheet.mjs printed the pinned revision and so showed
  -- stale rungs on 8 of 33 federal topics, and on gun-policy the stale text would have
  -- refused 49 rows the ladder had a seat for. israel-military-aid does not drift
  -- today; this precondition is what notices if it starts to.
  SELECT max(CASE WHEN sr.value = 1 THEN sr.text END),
         max(CASE WHEN sr.value = 3 THEN sr.text END)
    INTO v_r1, v_r3
    FROM inform.season_questions q
    JOIN inform.compass_topics t ON t.id = q.topic_id AND t.topic_key = 'israel-military-aid'
    JOIN inform.compass_topic_revisions pin ON pin.id = q.topic_revision_id
    JOIN LATERAL (
      SELECT e.id FROM inform.compass_topic_revisions e
       WHERE e.topic_id = pin.topic_id AND e.version = pin.version
         AND e.status IN ('published', 'superseded')
       ORDER BY e.revision DESC LIMIT 1
    ) eff ON true
    JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id
   WHERE q.season_id = v_s2;

  IF v_r1 IS NULL OR v_r3 IS NULL THEN
    RAISE EXCEPTION 'CC_0080: could not resolve the rung 1 and rung 3 texts Season 2 serves';
  END IF;
  IF lower(v_r1) NOT LIKE '%no new conditions%' THEN
    RAISE EXCEPTION 'CC_0080: served rung 1 reads "%" - the 43 chair-1 rows were placed against "continue full military aid with no new conditions" and must be re-read', v_r1;
  END IF;
  IF lower(v_r3) NOT LIKE '%offensive weapons%' THEN
    RAISE EXCEPTION 'CC_0080: served rung 3 reads "%" - the 4 chair-3 rows were placed against "block offensive weapons sales" and must be re-read', v_r3;
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0080_rows r
    JOIN inform.compass_topics t ON t.topic_key = 'israel-military-aid'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % pair(s) already hold a Season 2 answer - this file has run, or the rows are stale', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM (
    SELECT politician_id FROM _cc0080_rows GROUP BY politician_id HAVING count(*) > 1) d;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % politician(s) appear more than once', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM _cc0080_basis WHERE value <> round(value) OR value < 1 OR value > 5;
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % basis row(s) carry a non-discrete or out-of-range chair', v_n;
  END IF;

  IF (SELECT count(*) FROM _cc0080_rows) <> 47 THEN
    RAISE EXCEPTION 'CC_0080: expected exactly 47 rows, found %', (SELECT count(*) FROM _cc0080_rows);
  END IF;

  INSERT INTO _cc0080_before
  SELECT (SELECT count(*) FROM inform.politician_answers WHERE season_id = v_s2),
         (SELECT count(*) FROM inform.politician_context WHERE season_id = v_s2);

  RAISE NOTICE 'CC_0080 preconditions OK: Season 2 open, 47 rows, names match ids, topic promoted and federal, no prior answers.';
  RAISE NOTICE 'CC_0080 served rung 1: %', v_r1;
  RAISE NOTICE 'CC_0080 served rung 3: %', v_r3;
  RAISE NOTICE 'CC_0080 baseline: Season 2 holds % answers / % context before this file.',
    (SELECT answers FROM _cc0080_before), (SELECT context FROM _cc0080_before);
END $$;

-- -----------------------------------------------------------------------------
-- 2. The answers
-- -----------------------------------------------------------------------------
INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value, write_in_text, editor_id, updated_at)
SELECT r.politician_id, t.id, sq.season_id, sq.topic_revision_id, b.value, NULL, NULL, now()
  FROM _cc0080_rows r
  JOIN _cc0080_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'israel-military-aid'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 3. The context
-- -----------------------------------------------------------------------------
INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT r.politician_id, t.id, sq.season_id, sq.topic_revision_id, b.reasoning, b.sources, NULL, now()
  FROM _cc0080_rows r
  JOIN _cc0080_basis b            ON b.basis = r.basis
  JOIN inform.compass_topics t    ON t.topic_key = 'israel-military-aid'
  JOIN inform.seasons s           ON s.status = 'open'
  JOIN inform.season_questions sq ON sq.season_id = s.id AND sq.topic_id = t.id;

-- -----------------------------------------------------------------------------
-- 4. Assert the outcome
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2 uuid; v_n int; v_answers int; v_context int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';

  SELECT count(*) INTO v_n
    FROM _cc0080_rows r
    JOIN _cc0080_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'israel-military-aid'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = b.value;
  IF v_n <> 47 THEN
    RAISE EXCEPTION 'CC_0080: % of 47 answers landed at the intended chair', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0080_rows r
    JOIN inform.compass_topics t ON t.topic_key = 'israel-military-aid'
    JOIN inform.politician_answers a
      ON a.politician_id = r.politician_id AND a.topic_id = t.id AND a.season_id = v_s2
   WHERE a.value = 1;
  IF v_n <> 43 THEN
    RAISE EXCEPTION 'CC_0080: % answers at chair 1, expected 43', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0080_rows r
    JOIN _cc0080_basis b ON b.basis = r.basis
    JOIN inform.compass_topics t ON t.topic_key = 'israel-military-aid'
    JOIN inform.politician_context c
      ON c.politician_id = r.politician_id AND c.topic_id = t.id AND c.season_id = v_s2
   WHERE c.reasoning = b.reasoning AND array_length(c.sources, 1) >= 1;
  IF v_n <> 47 THEN
    RAISE EXCEPTION 'CC_0080: % of 47 context rows landed with their reasoning and a source', v_n;
  END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                        AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0080: % non-blank Season 2 answer(s) carry no reasoning', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id
   WHERE a.season_id = v_s2 AND a.value = 0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0080: % blanked answer(s) carry Season 2 reasoning', v_n;
  END IF;

  -- the corpus grew by exactly 47 and 47 - A DELTA, NOT A TOTAL. CC_0078 shipped
  -- absolute totals and they went stale before a human finished reviewing its chairs.
  SELECT count(*) INTO v_answers FROM inform.politician_answers WHERE season_id = v_s2;
  SELECT count(*) INTO v_context FROM inform.politician_context WHERE season_id = v_s2;
  IF v_answers - (SELECT answers FROM _cc0080_before) <> 47 THEN
    RAISE EXCEPTION 'CC_0080: Season 2 answers grew by %, expected 47', v_answers - (SELECT answers FROM _cc0080_before);
  END IF;
  IF v_context - (SELECT context FROM _cc0080_before) <> 47 THEN
    RAISE EXCEPTION 'CC_0080: Season 2 context rows grew by %, expected 47', v_context - (SELECT context FROM _cc0080_before);
  END IF;

  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'israel-military-aid'
   WHERE a.season_id = v_s2;
  RAISE NOTICE 'CC_0080 OK: 47 answers + 47 context (43 at chair 1, 4 at chair 3). israel-military-aid now holds % Season 2 answers. Season 2 now % answers / % context - RAISE THE FLOORS TO THESE NUMBERS, in a separate PR, now that the file is applied.',
    v_n, v_answers, v_context;
END $$;

COMMIT;
