-- Migration 1946 — contradiction check, ROUND FIVE: a small write and three findings that are
-- larger than it.
--
-- Rounds two to four worked the queue's big mapping-shaped groups. What is left at the top is
-- mostly NOT defective, and the two groups read in full here show both outcomes:
--
--   rows  instrument                      ladder          decision                      written
--   ----  ------------------------------  --------------  ----------------------------  -------
--     13  California AB 2655 (2023-24)    misinformation  withdraw 11, leave 2                11
--     14  Texas HB 44 (89R)               abortion        NOT DEFECTIVE; one row goes          1
--
-- 12 rows written, all withdrawals. Both targets serve from the CLOSED Season 1, so both writes
-- insert a Season 2 row; Season 1 is untouched and the post-flight block proves it.
--
-- ⚠ NO CHAIR IS SEATED BY THIS FILE, so audit-chair-evidence has nothing to judge. Running it would
-- print "OK: all 0 valued row(s)" - the vacuous pass its own header warns about. It was not run,
-- and that is recorded rather than dressed up as a passing gate.
--
-- Full record: data/stance-research/2026-10-26-contradiction-check-round-five/LEDGER.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. CALIFORNIA AB 2655 -> misinformation, 13 rows: 11 withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- The ladder was rewritten between seasons at chairs 1 and 2, and the rewrite is what makes this
-- group look resolvable and then turns out not to:
--     S1 c2  mandate fact-checking and transparency in how algorithms promote content
--     S2 c2  require platforms to label false content, RATHER THAN remove it
--     S2 c1  legally require platforms to remove false information
--     S2 c3  encourage voluntary standards for combating misinformation online
-- Every row describes AB 2655 as a LABELLING mandate, which lands on Season 2 chair 2 almost word
-- for word. Reading the Act reverses that. Its Legislative Counsel's Digest:
--     "would require a large online platform ... to BLOCK the posting of materially deceptive
--      content related to elections in California, during specified periods before and after an
--      election. The bill would require a large online platform to LABEL certain additional content
--      inauthentic, fake, or false during specified periods before and after an election"
-- The Act carries BOTH limbs. Chair 2 says "rather than remove it" and the blocking mandate
-- contradicts it; chair 1 says "remove false information" and the Act is confined to election
-- content, defined windows and large platforms; chair 3 says "voluntary" and a mandate is not.
-- A vote on a package holding two chairs' content proves the SIDE and not the RUNG - migration
-- 1925's rule, and the reason the title was not trusted.
--
-- ⚖ THE TWO ROWS LEFT ALONE voted NO on the Act and sit at chair 4, "protect free speech online and
-- prevent government censorship". One gives its reason in the row - opposing government-mandated
-- content restrictions "citing free speech" - and a no vote on a mandate is consistent with that
-- chair without having to assert anything further. They are not part of this defect.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. TEXAS HB 44 (89R) -> abortion, 14 rows: NOT DEFECTIVE, 1 row withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔑 A 2/4 SPLIT THAT IS THE LADDER WORKING. HB 44, the Life of the Mother Act, adds
-- medical-judgment exceptions to Texas's existing near-total ban and drew 61 co-authors from BOTH
-- parties. Co-sponsoring a narrow exceptions bill means opposite things depending on the rest of
-- the record, and these rows show it:
--   chair 2  Democrats seated on wider records - a former House Minority Leader who opposed SB 8,
--            HB 1280 and the trigger ban; a 50-year women's rights record.
--   chair 4  Republicans seated on recorded floor votes FOR the ban itself - one row cites the
--            House Journal by record number for Yea on SB 8 (83-64) and Yea on HB 1280 (81-61) -
--            and one on the member's own candidate questionnaire: "Abortion should not be allowed".
-- These are good rows and the group needs no write.
--
-- ONE ROW IS WITHDRAWN. It seats chair 2 on a bill the member is not recorded as having joined:
--     "Did not appear on HB44 co-author list specifically, but consistent Democratic caucus
--      position."
-- plus the district's geography. An absence of sponsorship and a caucus prior are not a position.
-- ⚠ It is the SAME MEMBER and the SAME SHAPE that migration 1944 withdrew from school-vouchers,
-- where the row read "Did not co-author HB3 ... As a Rio Grande Valley Democrat". A shape that
-- recurs for one member is worth looking for across that member's other rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. THREE FINDINGS LARGER THAN THIS FILE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 1. `immigration` EXISTS IN SEASON 1 ONLY, AND 1,666 VALUED ANSWERS ARE STRANDED THERE.
-- It has no season_questions row in Season 2 and none in the Season 3 draft. Every repair technique
-- these passes use is an INSERT of a Season 2 row, and for this topic there is nothing to insert
-- against. The Texas SB 8 (89R) group was read in this pass and is off-axis - the Act makes county
-- sheriffs enter ICE 287(g) agreements, while every chair on the ladder is about LEGAL IMMIGRATION
-- LEVELS and PUBLIC SERVICE ELIGIBILITY - and three of its five rows rest on nothing but "consistent
-- with conservative Republican immigration enforcement position". It cannot be written. Recorded.
--
-- 🔴 2. AN OLDER PROGRAMME HAS ALREADY BLANKED 1,021 ROWS FOR THESE SHAPES, under a named
-- vocabulary this file has been re-deriving in its own words: OFF AXIS, DIRECTION ONLY, OMISSION
-- FOR COMMITMENT, EMPLOYER, AFFILIATION, OFFICE DUTY, BARE SCORE, ABSENCE MOVES THE SEAT, NO RECORD
-- AT A RECORD, THE ROW INFERS THE CHAIR INSTEAD OF SHOWING IT. 603 people, 36 topics, written
-- between 2026-10-09 and 2026-10-25, in the format "INTERNAL RECORD - blanked by migration NNNN ...
-- Shape: X". The contradiction-check migrations use a different notice format for the same act.
-- Worth reconciling; not by rewriting a hundred rows today.
--
-- 🔴 3. THE SHAPES HAVE A LONG TAIL STILL IN THE CORPUS. A regex sweep for rows that seat a chair
-- while declaring the evidence absent - "did not appear", "no record of", "insufficient", "no
-- strong public stance was identified", a party or caucus baseline, NVR - returns 563 serving rows
-- out of 31,362. ⚠ THAT IS A SEARCH RESULT, NOT A DEFECT COUNT: a sample of 8 contained 3 rows
-- that name real instruments and merely use a trigger word. The real number is smaller and only
-- reading settles it.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Every one of them serves from the CLOSED Season 1 with nothing shadowing
-- it, so every write is an INSERT of a Season 2 row (ADR 0005 section 1.6). By ADR 0006 that row
-- is read against the SEASON 2 ladder, which is resolved from inform.season_questions and never
-- hard-coded. The Season 1 value, reasoning, sources and updated_at are carried along so the
-- guards and the post-flight block can prove nothing in the closed season moved.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1946_ins ON COMMIT DROP AS
SELECT x.politician_id, x.topic_id, x.op, x.value_after,
       sq.topic_revision_id  AS s2_revision,
       pa1.value             AS value_before,
       pa1.topic_revision_id AS s1_revision,
       pa1.updated_at        AS s1_updated_at,
       pc1.reasoning         AS reasoning_before,
       pc1.sources           AS sources_before
  FROM (VALUES
  ('ea803096-927f-41fe-98e1-deab56291810'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Al Muratsuchi: was chair 2
  ('51d15b77-71bb-475e-b86e-c6e1b37b869d'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Blanca E. Rubio: was chair 2
  ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Blanca Pacheco: was chair 2
  ('f9cbe210-a840-4924-b4aa-a5de0dc143ba'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Celeste Rodriguez: was chair 2
  ('ab26d178-4f69-4ffc-9485-ac03f87643e2'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Damon Connolly: was chair 2
  ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Gavin Newsom: was chair 2
  ('97285c92-b664-4687-a1e4-6d88cf9c7fe4'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Jacqui Irwin: was chair 2
  ('e099da71-f9d9-445d-96d9-179952bd539c'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Laura Friedman: was chair 2
  ('a1fc524b-7c90-43c0-83a7-c76664293913'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Luz Maria Rivas: was chair 2
  ('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Rob Bonta: was chair 2
  ('29e15a5d-d98f-4536-ad62-05b2612f30ca'::uuid,'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'ab2655-blank',0),  -- Bob Archuleta: was chair 3
  ('65bdba41-859d-41ba-bb25-65e8ba50f5ad'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,'hb44-caucus-blank',0)  -- Sergio Munoz: was chair 2
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = x.topic_id
   AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = x.topic_id
   AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = x.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target set must be exactly what was read, and every row must have something to keep.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1946_ins;
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1946: expected 12 targets, found % — a Season 1 answer or context row is missing', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'ab2655-blank';
  IF n <> 11 THEN RAISE EXCEPTION 'migration 1946: ab2655-blank expected 11, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'hb44-caucus-blank';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1946: hb44-caucus-blank expected 1, found %', n; END IF;
  SELECT count(DISTINCT (politician_id, topic_id)) INTO n FROM mig1946_ins;
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1946: duplicate (person, topic) pairs; % distinct of 12', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins
   WHERE reasoning_before IS NULL OR btrim(reasoning_before) = ''
      OR sources_before IS NULL OR cardinality(sources_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) have no reasoning or no citation to keep', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE reasoning_before LIKE '%migration 1946%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) already carry a 1946 notice — this file has run', n; END IF;
END $$;

-- GUARD 2 — every target must TODAY still sit on the chair the queue measured it at. If anything
-- re-researched these rows since 2026-10-26 the adjudication is stale and must not be applied.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'ab2655-blank' AND value_before NOT IN (2,3);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % ab2655-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'hb44-caucus-blank' AND value_before NOT IN (2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % hb44-caucus-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE value_before = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) are already blank', n; END IF;
END $$;

-- GUARD 3 — the reasoning must really name the thing the adjudication turned on. Without this the
-- file is a list of uuids and a clerical slip is undetectable.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'ab2655-blank' AND reasoning_before !~ 'AB ?2655|Deepfake Deception';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % ab2655-blank row(s) do not name AB 2655', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE op = 'hb44-caucus-blank' AND reasoning_before !~ 'HB ?44';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % hb44-caucus-blank row(s) do not name HB 44', n; END IF;
END $$;

-- GUARD 4 — THE LADDERS. A rung NUMBER means nothing outside one revision, and a rung_map can lie
-- (climate-change v2r3 and school-vouchers v2r3 both claim IDENTITY over rewritten rungs), so the
-- rung TEXTS are asserted here — including, for school-vouchers chair 4, the clause the Season 2
-- rewrite DELETED, which is the whole reason the Texas HB 3 dissenter moves.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1946: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1946: Season 1 is not closed'; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i WHERE i.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid
     AND (i.s1_revision <> '6fa8a338-153a-430d-bc44-e985b44a357c'::uuid OR i.s2_revision <> 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % misinformation row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i WHERE i.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
     AND (i.s1_revision <> 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid OR i.s2_revision <> 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % abortion row(s) are not on the expected revisions', n; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '6fa8a338-153a-430d-bc44-e985b44a357c'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'how algorithms promote content' THEN RAISE EXCEPTION 'migration 1946: Season 1 misinformation chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'remove false information' THEN RAISE EXCEPTION 'migration 1946: Season 2 misinformation chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'rather than remove it' THEN RAISE EXCEPTION 'migration 1946: Season 2 misinformation chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'voluntary standards' THEN RAISE EXCEPTION 'migration 1946: Season 2 misinformation chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'bd313c07-02a5-4344-8cc3-0e4b4c3b78a1'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'prevent government censorship' THEN RAISE EXCEPTION 'migration 1946: Season 2 misinformation chair 4 does not read as recorded: %', t; END IF;

  -- 🔑 THE TWO LADDERS DIFFER IN KIND, AND THAT IS THE POINT OF THIS FILE.
  -- abortion pins ONE revision across both seasons, so the HB 44 reasoning is read against the very
  -- ladder it was researched against. misinformation does NOT: chairs 1 and 2 were rewritten, and
  -- it is the rewrite that makes AB 2655 look like a clean chair 2 ("label ... rather than remove
  -- it") until the Act is read and found to require blocking as well.
  SELECT count(*) INTO n FROM inform.season_questions a
    JOIN inform.season_questions b ON b.topic_id = a.topic_id
   WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND b.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND a.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid AND a.topic_revision_id = b.topic_revision_id;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1946: abortion no longer pins one revision across both seasons'; END IF;
  SELECT count(*) INTO n FROM inform.season_questions a
    JOIN inform.season_questions b ON b.topic_id = a.topic_id
   WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND b.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND a.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND a.topic_revision_id = b.topic_revision_id;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: misinformation now shares a revision across seasons — the rewrite this file turns on is gone'; END IF;

  -- every chair this file writes must EXIST on the revision it is written against
  SELECT count(*) INTO n FROM mig1946_ins i
   WHERE i.value_after <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions cs
                      WHERE cs.topic_revision_id = i.s2_revision AND cs.value = i.value_after);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % row(s) would be seated on a chair that does not exist', n; END IF;
END $$;

-- GUARD 5 — these are inserts, so no target may already hold a Season 2 row; and nobody here may
-- be inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1946_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
                    AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) ALREADY have a Season 2 answer — somebody answered since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
                    AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) ALREADY have a Season 2 context row', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN essentials.politicians p ON p.id = i.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) are on inactive people', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins
   WHERE topic_id NOT IN ('ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % target(s) are on an unexpected topic', n; END IF;
END $$;

-- GUARD 6 — POPULATIONS, NOT JUST TARGETS, and the rows left alone on purpose.
DO $$
DECLARE n int;
BEGIN
  -- every serving row naming AB 2655 on this ladder, measured 2026-10-26: 11 on the FOR side at
  -- chairs 2 and 3, plus 2 no-vote rows at chair 4 which this file deliberately keeps.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~* 'AB ?2655|Deepfake Deception';
  IF n <> 13 THEN RAISE EXCEPTION 'migration 1946: expected 13 AB 2655 rows, found % — re-read before writing', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value IN (2,3) AND p.is_active AND pc.reasoning ~* 'AB ?2655|Deepfake Deception'
     AND NOT EXISTS (SELECT 1 FROM mig1946_ins i
                      WHERE i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % AB 2655 row(s) on the for side are not targets', n; END IF;

  -- the two no-vote rows at chair 4 must still be there, and must NOT be written
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
   WHERE pa.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 4 AND pc.reasoning ~* 'AB ?2655|Deepfake Deception';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1946: expected 2 kept chair 4 rows on AB 2655, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE value_after <> 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: this file seats no chair; % row(s) would seat one', n; END IF;

  -- 🔑 THE HB 44 GROUP IS NOT DEFECTIVE AND MUST SURVIVE INTACT. Exactly one row is written.
  -- ⚠ THE CHECK GROUPED 14 ROWS; 69 Texas abortion rows actually cite HB 44, because the Act drew
  -- 61 co-authors and the keyer resolves a direction for only some of them. The 14 were read in
  -- full and are sound. The other 55 are UNREAD and recorded as owed in the ledger - this guard
  -- pins the real population so the gap cannot widen unnoticed.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'HB ?44([^0-9]|$)'
     AND EXISTS (SELECT 1 FROM unnest(pc.sources) src WHERE src LIKE '%capitol.texas.gov%');
  IF n <> 69 THEN RAISE EXCEPTION 'migration 1946: expected 69 Texas abortion rows citing HB 44, found % — re-measure', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins WHERE topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1946: exactly one HB 44 row may be written, found %', n; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. Two inserts. The Season 2 reasoning is the migration's notice followed by the ORIGINAL
-- prose, kept verbatim — a reader must be able to see what the row used to claim and why it moved.
-- Sources are carried across byte for byte; this file re-reads evidence, it never re-cites it.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_after
  FROM mig1946_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       CASE i.op
         WHEN 'ab2655-blank' THEN '[migration 1946, 2026-10-26] Withdrawn. This row rests on California AB 2655, the Defending Democracy from Deepfake Deception Act of 2024. The Act was read, not its title: it "would require a large online platform ... to BLOCK the posting of materially deceptive content related to elections in California, during specified periods before and after an election" AND "require a large online platform to LABEL certain additional content inauthentic, fake, or false". It carries BOTH limbs. Season 2 chair 2 reads "require platforms to label false content, RATHER THAN remove it", which the blocking mandate contradicts; Season 2 chair 1 is "legally require platforms to remove false information", which overstates an Act confined to election content, defined windows and large platforms; and chair 3 is "encourage VOLUNTARY standards", which a mandate is not. A vote on a package holding two chairs'' content proves the side and not the rung - the rule migration 1925 set for the Respect for Marriage Act. ⚖ WHERE THIS ROW CARRIES MORE THAN THE ACT it was read too and does not change the outcome: signing four AI-disclosure measures, a cybersecurity background, a stated wish for "much greater accountability by social media companies", or letters from an Attorney General demanding platform action all establish the SIDE more firmly without choosing between removing false content and labelling it instead. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'hb44-caucus-blank' THEN '[migration 1946, 2026-10-26] Withdrawn. The row seats a chair on a bill the member is not recorded as having joined: it states "Did not appear on HB44 co-author list specifically, but consistent Democratic caucus position", and the rest of its support is the district''s geography. An absence of sponsorship plus a caucus prior is not a position. ⚖ THE GROUP AROUND THIS ROW IS NOT DEFECTIVE and is deliberately left alone: Texas HB 44 (89R), the Life of the Mother Act, adds medical-judgment exceptions to an existing near-total ban and drew co-authors from both parties, so its 2/4 split is the ladder working - Democrats seated on their wider records, Republicans on recorded floor votes FOR the ban itself. This is the same member and the same shape withdrawn from school-vouchers by migration 1944. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
       END || i.reasoning_before,
       i.sources_before
  FROM mig1946_ins i;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT. Everything below runs inside the same transaction, so a failure here rolls the
-- whole file back.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = i.value_after AND pa.topic_revision_id = i.s2_revision;
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1946: % of 12 inserted answers are at their chair and revision', n; END IF;

  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: expected 0 seated rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1946: expected 12 withdrawn rows, found %', n; END IF;

  -- the kept prose and the untouched citations
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % row(s) had their citations altered', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE strpos(pc.reasoning, i.reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % row(s) lost their original reasoning', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1946%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % row(s) carry no notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED. Not one value, not one word of reasoning, not one updated_at may move.
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at
      OR pa.topic_revision_id <> i.s1_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % Season 1 answer(s) MOVED — the closed season was written to', n; END IF;
  SELECT count(*) INTO n FROM mig1946_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1946: % Season 1 context row(s) were rewritten', n; END IF;

  -- the rows this file promised not to touch are still where they were
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
   WHERE pa.topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 4 AND pc.reasoning ~* 'AB ?2655|Deepfake Deception';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1946: the 2 kept chair 4 rows moved; found %', n; END IF;
END $$;

COMMIT;
