-- Migration 1927 — adjudicate five defective (instrument, topic, rung) clusters as MAPPINGS.
--
-- WHAT THIS IS. The 2026-10-21 sample of the 396 citation-repaired rows that sit outside the
-- generic-sourcing block found that THE CLUSTER, NOT THE ROW, IS THE UNIT OF DEFECT: 231 of
-- those rows fingerprint to a named instrument, and when one member's rung mapping is wrong it
-- is wrong for every member citing that instrument. Eight clusters were read and found
-- defective, covering 62 rows. Measurement:
-- `backend/data/stance-research/2026-10-21-repaired-rest-sample/MEASUREMENT.md`.
--
-- ⚖ EACH CLUSTER HERE IS ONE DECISION APPLIED N TIMES, NOT N READINGS. That is the whole point
-- of working the queue this way, and it is also the discipline it demands: the decision must be
-- about what the INSTRUMENT establishes, since that is the only thing every row in the cluster
-- shares.
--
-- SCOPE: 39 rows / 28 people across 5 clusters — 14 re-seated, 25 blanked.
-- 🔑 THE OTHER THREE of the eight defective clusters (TX Medicaid-expansion → healthcare r2,
-- TX SB13 → fossil-fuels r4, TX SB13 → climate-change r5; 23 rows) were already blanked by
-- MIGRATION 1926, which swept every row carrying the migration-1903 "does not by itself separate
-- the rungs" disclaimer. Verified: none of the 39 rows below carries that sentence, so this
-- pass and 1926 are disjoint. Guard 4 enforces it rather than asserting it.
--
-- 🔴 WHERE THIS PASS DEPARTS FROM THE SAMPLE'S OWN READS, AND WHY. The sample re-seated the
-- jail-capacity and deportation clusters to chair 2. This migration BLANKS them instead. In both
-- cases chair 2's distinguishing content — pretrial diversion / bail reform / treatment
-- alternatives, and a "serious violent crimes" removal threshold — is absent from the cited
-- instrument, so moving the row there would seat it on the least-extreme-option-on-that-side
-- TIEBREAKER rather than on evidence. The standard names that move as the signal that a row is
-- not evidenced, so the honest answer is a blank spoke. See the per-cluster notes below.
--
-- ⚖ WHAT A BLANK ASSERTS: that THIS ROW does not show which rung the member occupies. It does
-- not assert the member holds no view, and it does not doubt the vote or the cosponsorship.
-- Every citation is kept and the original reasoning is PRESERVED VERBATIM beneath the notice, so
-- a re-read starts from the record rather than from nothing. These rows are candidates for
-- re-seating.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

-- C1 — MA ROE Act H.5179 → abortion rung 1 (14 rows): RE-SEAT to rung 2. ROE-ACT YEA, OVER-SEATED.
--      Daniel J. Hunt, Daniel M. Donahue, David A. LeBoeuf, James J. O'Day, Chynah Tyler, Karen E. Spilka, Mary S. Keefe, Jonathan D. Zlotnik, John J. Mahoney, Adrian C. Madaro, Brian W. Murray, Natalie Higgins, David Biele, Jay Livingstone
-- C3 — MA police reform act S.2963 → public-safety-approach rung 2 (11 rows): BLANK. OFF-AXIS INSTRUMENT.
--      Christine P. Barber, Marjorie C. Decker, James J. O'Day, John J. Mahoney, Mary S. Keefe, Mike Connolly, Jonathan D. Zlotnik, Natalie Higgins, Brian W. Murray, Daniel M. Donahue, David A. LeBoeuf
-- C4 — MA ROE Act H.5179 → abortion rung 4 (7 rows): BLANK. DIRECTION ONLY - A NAY CANNOT CHOOSE AMONG THE RUNGS IT OPPOSES.
--      David K. Muradian, Hannah E. Kane, Paul K. Frost, Joseph D. McKenna, Michael J. Soter, Donald R. Berthiaume, Kimberly N. Ferguson
-- C7 — MA jail/prison construction moratorium → jail-capacity rung 1 (4 rows): BLANK. MECHANISM UNEVIDENCED ON BOTH CANDIDATE RUNGS.
--      Samantha Montaño, Adrian C. Madaro, Russell E. Holmes, Chynah Tyler
-- C8 — MA Safe Communities Act → deportation rung 1 (3 rows): BLANK. THE INSTRUMENT DOES NOT LEGISLATE ON THE LADDERS QUESTION.
--      Judith A. Garcia, Adrian C. Madaro, Lydia M. Edwards

-- Freeze the target set ONCE, so the update, the counts and the verification all speak about the
-- same rows. 🔴 A predicate re-evaluated after the UPDATE would match nothing and pass vacuously.
CREATE TEMP TABLE mig1927_targets (
  cluster      text    NOT NULL,
  politician_id uuid   NOT NULL,
  topic_id     uuid    NOT NULL,
  value_before numeric NOT NULL,
  value_after  numeric NOT NULL,
  reasoning_before text
);

INSERT INTO mig1927_targets (cluster, politician_id, topic_id, value_before, value_after) VALUES
  ('C1', '5c36a94c-9006-4550-a37e-978a65d2725c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', 'fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '869ba820-3138-473c-b70d-383e67f5797d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', 'c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C1', '852e4a21-5750-4ac8-ba06-0376c5a31685'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1, 2),
  ('C3', '7cbdb829-4836-49e9-afb2-cb8035afc6bf'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '2b1a645a-72ce-4c0f-80ec-17565a2d6d10'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '50838d91-2ce4-4aa6-8950-b87579860a4b'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', 'a6eb79f8-c7e7-41b0-8a1c-baf85e7cd22c'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '869ba820-3138-473c-b70d-383e67f5797d'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', 'c14b3502-f142-4c1f-bfa9-a8fa52351a8e'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '4702bc3c-0820-42f4-a0ae-5bc244c44159'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C3', '3ca6c1b2-eec3-4e28-991d-fce8b6b67354'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2, 0),
  ('C4', '891030da-39e2-496f-8a20-72aeb27093ba'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', 'd54b9791-0668-4397-b488-160d06f7c420'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', '799c1cea-4020-4c50-b7d1-1e9aac867529'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', '2fadc37b-4d33-46b4-a3cc-a2ca5ebeb39a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', '51e50b38-dbb2-4131-91bb-23c24bf6d741'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', '329212d4-14ef-4685-9d95-cc7473aad949'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C4', '62aee074-7ed1-45e8-94fc-3b5b5007f85d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4, 0),
  ('C7', '28a703f8-8316-4d3c-bfc0-3dcd77eab96c'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1, 0),
  ('C7', '290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1, 0),
  ('C7', 'e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1, 0),
  ('C7', 'fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid, 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid, 1, 0),
  ('C8', 'c4c3ed02-2592-4505-a26c-0195d0b5314e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1, 0),
  ('C8', '290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1, 0),
  ('C8', '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 1, 0);

-- Attach the text we are about to replace, and the value actually serving right now.
UPDATE mig1927_targets t
   SET reasoning_before = pc.reasoning
  FROM inform.politician_context pc
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- Record the before-picture for a delta check that does not depend on the predicate.
CREATE TEMP TABLE mig1927_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

-- GUARD 1 — the population is exactly what was measured, and every row is still serving the rung
-- the cluster was read at. 🔴 THIS IS THE STALENESS GATE: if another session has worked these
-- rows, a value_before moves and this migration refuses rather than overwriting their work.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1927_targets;
  IF n <> 39 THEN RAISE EXCEPTION 'migration 1927: expected 39 target rows, found %', n; END IF;

  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1927_targets) s;
  IF n <> 39 THEN RAISE EXCEPTION 'migration 1927: duplicate (politician, topic) pairs; % distinct of 39', n; END IF;

  SELECT count(DISTINCT politician_id) INTO n FROM mig1927_targets;
  IF n <> 28 THEN RAISE EXCEPTION 'migration 1927: expected 28 people, found %', n; END IF;

  -- Every target must exist in Season 2 and be seated at the rung the cluster recorded.
  SELECT count(*) INTO n
    FROM mig1927_targets t
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value IS NULL OR pa.value <> t.value_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % target(s) are missing or no longer seated at the rung the cluster was read at — re-measure', n; END IF;

  -- Every target must have stored reasoning to preserve.
  SELECT count(*) INTO n FROM mig1927_targets WHERE reasoning_before IS NULL OR length(reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % target(s) have no Season 2 reasoning row', n; END IF;
END $$;

-- GUARD 2 — per-cluster sizes, so a cluster cannot silently shrink or borrow rows from another.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C1';
  IF n <> 14 THEN RAISE EXCEPTION 'migration 1927: cluster C1 expected 14 rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C1' AND topic_id <> 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: cluster C1 has % row(s) on the wrong topic', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C3';
  IF n <> 11 THEN RAISE EXCEPTION 'migration 1927: cluster C3 expected 11 rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C3' AND topic_id <> 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: cluster C3 has % row(s) on the wrong topic', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C4';
  IF n <> 7 THEN RAISE EXCEPTION 'migration 1927: cluster C4 expected 7 rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C4' AND topic_id <> 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: cluster C4 has % row(s) on the wrong topic', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C7';
  IF n <> 4 THEN RAISE EXCEPTION 'migration 1927: cluster C7 expected 4 rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C7' AND topic_id <> 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: cluster C7 has % row(s) on the wrong topic', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C8';
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1927: cluster C8 expected 3 rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1927_targets WHERE cluster = 'C8' AND topic_id <> '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: cluster C8 has % row(s) on the wrong topic', n; END IF;
END $$;

-- GUARD 3 — 🔴 SEASON 1 IS CLOSED. Every write below is keyed to the Season 2 uuid explicitly;
-- this records what Season 1 holds for these pairs so the closing guard can prove it did not move.
CREATE TEMP TABLE mig1927_season1_before AS
SELECT pa.politician_id, pa.topic_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
  JOIN mig1927_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id;

-- GUARD 4 — disjoint from migration 1926. No target may carry the migration-1903 marker sentence
-- that 1926 swept, or the two passes would be arguing about the same rows.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1927_targets
   WHERE reasoning_before LIKE '%does not by itself separate the rungs%'
      OR reasoning_before LIKE '%blanked by migration 1926%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % target(s) overlap migration 1926', n; END IF;

  -- Nor may a target already have been withdrawn by an earlier pass in this campaign.
  SELECT count(*) INTO n FROM mig1927_targets WHERE reasoning_before LIKE 'INTERNAL RECORD%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % target(s) are already withdrawn rows', n; END IF;
END $$;

-- GUARD 5 — nothing may lose its citations, and every target must already have some.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1927_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- GUARD 6 — the one re-seat must be admissible for the chair it moves to.
-- 🔴 inform.compass_topic_roles.evidence_basis decides what may seat a chair: where it says
-- 'record', a person's own words cannot. abortion/state is 'record', and every row in C1 rests on
-- a recorded roll-call vote on a named act, so the re-seat is admissible. This guard refuses if
-- that ever stops being true.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.compass_topic_roles r
   WHERE r.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid AND r.role_scope = 'state' AND r.evidence_basis = 'record';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1927: abortion/state evidence_basis is not the record basis this re-seat was judged against'; END IF;

  -- Each re-seated row must actually name the instrument it is being re-seated on.
  SELECT count(*) INTO n FROM mig1927_targets
   WHERE value_after > 0 AND reasoning_before !~* '(ROE Act|H\.?5179)';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % re-seat target(s) do not name the ROE Act', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

-- The answer. A blank writes 0, which suppresses the spoke (the reader applies NULLIF(value, 0));
-- the row and its citations remain. A re-seat writes the corrected rung.
UPDATE inform.politician_answers pa
   SET value = t.value_after, updated_at = now()
  FROM mig1927_targets t
 WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY, per cluster — and 🔑 THE ORIGINAL REASONING IS PRESERVED VERBATIM BENEATH IT.
-- The votes and cosponsorships are real and are good evidence of the side; discarding them would
-- make any re-read start from nothing. Sources are deliberately not touched.

-- C1: MA ROE Act H.5179 → abortion rung 1 (14 rows)
UPDATE inform.politician_context pc
   SET reasoning = 'RE-SEATED by migration 1927 (chair 1 → chair 2): Shape: ROE-ACT YEA, OVER-SEATED. RE-SEATED from chair 1 to chair 2 by migration 1927. The instrument is the Massachusetts ROE Act (H.5179, enacted 2020 over the Governor veto; House override 107-46, Senate 32-8), and this member voted for it. WHAT THE ACT ACTUALLY DOES: it is viability-structured. It protects abortion through 24 weeks, and after 24 weeks only on a specific ground - a fatal fetal anomaly, or where a physician judges it necessary to preserve the patients physical or mental health. WHY CHAIR 2: chair 2 reads "keep abortion legal and accessible through the second trimester with rare exceptions afterward", which is the Acts own structure. WHY NOT CHAIR 1: chair 1 reads "legal, accessible, and publicly funded at all stages of pregnancy". The Act is not at all stages - the post-24-week grounds are narrow and enumerated - and it carries no public-funding mandate. A Yea on this Act therefore cannot reach chair 1. THE INSTRUMENT DEFINES THE CHAIR: the chair must describe what the member voted for, not the direction the vote points. This is a MAPPING correction applied to every row citing this Act at chair 1; the vote is not doubted and the citation is unchanged. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1927_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND t.cluster = 'C1';

-- C3: MA police reform act S.2963 → public-safety-approach rung 2 (11 rows)
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1927: Shape: OFF-AXIS INSTRUMENT. BLANKED by migration 1927. Shape: OFF-AXIS - the cited instrument is about a different question than the one this ladder asks. The instrument is the 2020 Massachusetts police reform act (S.2963), which is an OFFICER-ACCOUNTABILITY statute: POST certification and decertification, limits on qualified immunity, a chokehold ban, duty-to-intervene rules. THIS LADDER ASKS SOMETHING ELSE: it asks about police STAFFING, BUDGET and WHO ANSWERS NON-VIOLENT CALLS. Chair 2 reads "maintain current police staffing but shift non-violent calls to unarmed mental health co-responders" - and the co-responder clause, which is the whole of what distinguishes chair 2 from its neighbours, appears nowhere in the act. An accountability vote does not establish a staffing-and-dispatch position in either direction, so no chair on this ladder is evidenced by it. NOTE ALSO: this topic carries only a LOCAL role scope in inform.compass_topic_roles, and these are state legislators. THE CITATION IS SOUND AND IS KEPT - migration 1900 repaired it correctly, catching that the row had cited an unrelated municipal bill and finding the real enacted vehicle. What fails is the mapping from that act to this ladder, not the research. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1927_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND t.cluster = 'C3';

-- C4: MA ROE Act H.5179 → abortion rung 4 (7 rows)
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1927: Shape: DIRECTION ONLY - A NAY CANNOT CHOOSE AMONG THE RUNGS IT OPPOSES. BLANKED by migration 1927. Shape: DIRECTION ONLY. This member voted Nay on the Massachusetts ROE Act (H.5179) override. That vote is real and is good evidence of the SIDE: it places the member among those opposing an expansion of abortion access. IT CANNOT CHOOSE THE RUNG. Chairs 3, 4 and 5 all oppose the Act, and they differ from one another only by their EXCEPTION FRAMEWORK - chair 3 allows the first trimester plus rape, incest and maternal health; chair 4 restricts to rape, incest and serious threats to the mothers life; chair 5 bans with no exceptions and adds criminal penalties. A single Nay on an expansion bill is consistent with all three and distinguishes none of them, so chair 4 is an unevidenced claim. ⚠ The converse-of-a-lopsided-vote reasoning in the row below is sound as far as it goes - dissent from a large majority is distinctive - but it establishes DISSENT, not an exception framework. THE VOTE IS NOT DOUBTED AND THE EVIDENCE IS KEPT: this row is a candidate for re-seating once a record naming an exception framework is found, not a write-off. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1927_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND t.cluster = 'C4';

-- C7: MA jail/prison construction moratorium → jail-capacity rung 1 (4 rows)
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1927: Shape: MECHANISM UNEVIDENCED ON BOTH CANDIDATE RUNGS. BLANKED by migration 1927. Shape: THE EVIDENCE NAMES NO MECHANISM THIS LADDER ASKS ABOUT. The instrument is the Massachusetts jail and prison construction moratorium (S.2030, 192nd General Court, filed - it did not become law), and this member is a verified cosponsor. WHAT IT DOES: it freezes construction, expansion, conversion and renovation of correctional facilities for five years, while allowing routine maintenance. That is all it does. WHY NOT CHAIR 1: chair 1 requires REDIRECTING incarceration funding into community-based mental health, addiction, housing and restorative justice programmes. A construction freeze redirects nothing; it is a spending prohibition, not a reallocation. WHY NOT CHAIR 2 EITHER, AND THIS IS THE POINT: chair 2 reads "reducing the incarcerated population through pretrial diversion, bail reform, and treatment alternatives rather than building new capacity". The moratorium is ONLY the trailing clause. Its three named mechanisms - pretrial diversion, bail reform, treatment alternatives - appear nowhere in the bill. ⚠ MOVING THE ROW TO CHAIR 2 BECAUSE CHAIR 1 IS TOO STRONG WOULD BE THE TIEBREAKER, NOT EVIDENCE: picking the least extreme option on the members own side is precisely the move the standard forbids, and reaching for it is the signal that the row is not yet evidenced. THE COSPONSORSHIP IS NOT DOUBTED AND IS KEPT: it is strong evidence of a decarceral direction, and this row is a candidate for re-seating against a record that names a mechanism. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1927_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND t.cluster = 'C7';

-- C8: MA Safe Communities Act → deportation rung 1 (3 rows)
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1927: Shape: THE INSTRUMENT DOES NOT LEGISLATE ON THE LADDERS QUESTION. BLANKED by migration 1927. Shape: THE INSTRUMENT DOES NOT SPEAK TO THIS LADDER. The instrument is the Massachusetts Safe Communities Act (filed repeatedly, never enacted), and this member is a verified cosponsor. WHAT IT DOES: it limits STATE AND LOCAL cooperation with federal immigration enforcement - barring 287(g) agreements, barring police from holding a person solely on an ICE detainer, and restricting release notifications to ICE. WHAT THIS LADDER ASKS: WHO SHOULD BE DEPORTED. Those are different questions, and a state legislature does not set removal priorities. WHY NOT CHAIR 1: chair 1 reads "stop deportations entirely and protect undocumented residents from removal". A non-cooperation bill cannot stop federal removals and does not purport to. WHY NOT CHAIR 2: chair 2 reads "only deport people convicted of serious violent crimes". The Act names no such threshold. Its nearest clause - still permitting notification to ICE when a person is released after serving a criminal sentence - governs NOTIFICATION, not which convictions warrant removal, and "served a sentence" is not "serious violent crime". ⚠ DEPARTS FROM A PRECEDENT, DELIBERATELY: migration 1921 kept two members at chair 2 on sanctuary instruments. That reading reached chair 2 the same way, and those rows should be re-examined rather than treated as licence. THE COSPONSORSHIP IS NOT DOUBTED AND IS KEPT. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1927_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND t.cluster = 'C8';

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  -- Every row now serves exactly the value this pass decided.
  SELECT count(*) INTO n
    FROM mig1927_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> t.value_after;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % row(s) do not hold the adjudicated value', n; END IF;

  SELECT count(*) INTO n FROM mig1927_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 25 THEN RAISE EXCEPTION 'migration 1927: expected 25 blanked rows, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1927_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 2 AND t.cluster = 'C1';
  IF n <> 14 THEN RAISE EXCEPTION 'migration 1927: expected 14 rows re-seated to chair 2, found %', n; END IF;

  -- No row lost its citations.
  SELECT count(*) INTO n FROM mig1927_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % row(s) lost their citations', n; END IF;

  -- Every row says what was done to it, and 🔑 kept its original reasoning.
  SELECT count(*) INTO n FROM mig1927_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1927%'
      OR pc.reasoning NOT LIKE '%Shape:%'
      OR pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ----%'
      OR position(t.reasoning_before in pc.reasoning) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % row(s) lost their original reasoning or their notice', n; END IF;

  -- 🔴 BLAST RADIUS, measured as a delta rather than asserted. 25 rows left the seated set and
  -- 14 stayed in it (a re-seat is still seated), so the net fall must be exactly 25.
  SELECT seated_season2 INTO before_seated FROM mig1927_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF before_seated - after_seated <> 25 THEN
    RAISE EXCEPTION 'migration 1927: seated Season 2 rows fell by %, expected exactly 25', before_seated - after_seated;
  END IF;

  -- 🔴 Season 1 is closed and must not have moved — proved against the snapshot, not assumed.
  SELECT count(*) INTO n
    FROM mig1927_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id AND pa.topic_id = b.topic_id
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1927: % Season 1 row(s) moved', n; END IF;
END $$;

-- Final shape, for the apply log.
SELECT t.cluster,
       count(*) AS rows,
       min(t.value_before) AS was,
       min(t.value_after)  AS now
  FROM mig1927_targets t
 GROUP BY t.cluster
 ORDER BY t.cluster;
