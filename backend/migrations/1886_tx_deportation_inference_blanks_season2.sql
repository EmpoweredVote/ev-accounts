-- 1886_tx_deportation_inference_blanks_season2.sql
-- Blank 11 Texas Deportation Priorities chairs in Season 2. They are seated in Season 1 on inference
-- rather than evidence. 11 context rows + 11 answer rows (value 0) INSERTED. Nothing updated,
-- nothing deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHAT IS WRONG WITH THEM. Each cites no bill, no vote, no quote and no dated statement. The chair
-- is argued from some mixture of:
--   (a) NOT having co-authored someone else's immigration bill,
--   (b) party or caucus membership ("standard progressive Democrat posture", "Freedom Caucus",
--       "ranked 3rd most conservative"),
--   (c) the demographics of the district represented.
-- 🔴 **The absence of a signature is not a position**, and a district's composition is a fact about
-- voters, not about their representative. Christina Morales's Immigration row states the method
-- outright -- *"She did not co-author immigration enforcement bills. Score 2 reflects standard
-- progressive Democrat posture"* -- and cites, as its source, the bill page of a bill she did not sign.
--
-- 🔴🔴 THE DEFECT RUNS IN BOTH DIRECTIONS, WHICH IS WHY THIS IS NOT A PARTISAN EDIT. 9 of the 11 are
-- Democrats inferred toward the protective end from caucus and district; 2 are Republicans inferred
-- toward the enforcement end from party and an ideology ranking (Terry Wilson: "no authored
-- immigration enforcement or ICE cooperation bill found. His general conservative record aligns with
-- the standard Texas Republican enforcement approach"; Steve Toth, seated at chair 5 on being
-- "ranked 3rd most conservative"). Party is never DISPLAYED by this product, and it must not be the
-- thing positions are DERIVED from either.
--
-- ⚖ A BLANK, NOT A REVERSAL. value 0 says the question has not been answered on this person. It does
-- NOT assert the opposite chair, and every one of these is re-researchable: several of these members
-- very likely do hold the position they were seated at. What is missing is evidence, not plausibility.
--
-- 🔑 WHY BLANK AND NOT DELETE. Deleting a Season 2 row does not blank anyone -- with seasons the read
-- falls back to Season 1 (CC_0057's header says so), so the inferred chair would stay visible. A
-- blank is value 0, which CC_0057 made expressible and PR #350/#354 made safe to read.
-- ⚠ This supersedes the note in the Season 3 agenda that "a blank mechanic would have to be proven
-- first" -- CC_0057 landed 2026-09-03 and migration 1882 used value-0 blanks on 2026-09-20.
--
-- 🔑 THE LADDER REVISION DIFFERS BETWEEN SEASONS AND IT DOES NOT MATTER HERE. Deportation Priorities
-- pins 673c3758 in Season 1 and 55c3167e in Season 2. A blank asserts no rung, so nothing is being
-- carried across a re-scale; the Season 2 pin is used only because the FK requires the season's own.
--
-- ⚠ READ INDIVIDUALLY, NOT TAKEN FROM A DETECTOR. A first cut flagged 31 rows; all 31 were read and
-- **12 were kept** because they rest on the member's own conduct -- Ramon Romero Jr. fasted for three
-- days in 2017 against SB 4; Armando Walle led floor opposition as Deputy Floor Leader; Eddie Morales
-- and Briscoe Cain carry directly quoted positions. Blanking a correct stance is worse than leaving a
-- weak one, so the queue was read down to the 11 here.
--
-- ⚠ NOT IN THIS MIGRATION: the 10 sibling rows on **Immigration and Treatment of Immigrants**, which
-- has the same defect and includes the two rows seated on NOT co-authoring HB 17 (Jon Rosenthal,
-- Linda Garcia). That topic is **Season 1 only** -- it is the corpus's largest orphan (1,678 stances,
-- not pinned in Season 2 or 3), so no Season 2 row can exist for it and voters cannot reach any of
-- it today. It is fixed by the Season 3 return/retire/merge decision, not by a blank.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('6af34442-997a-4b8d-8c19-3ae65519fa38','e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d','2d3e3416-fb12-455b-9010-4185010fb3aa','81d931a9-5906-4ff4-9ac8-15b49c4ae38a','a436b52d-8801-4588-b676-bd101bb2bdeb','f4286f1f-dda7-4fe4-9473-455772f40fae','1ff93be4-a2d0-432b-af59-ef6ace1eb77b','579a5a6f-c12e-4f01-af74-ec30f6bfbafe','02691090-c16c-4216-ac3b-1caa89a618a8','56b91150-194f-4699-ba31-e944443eacae','43567dd1-db59-40af-928e-03708237eb98');
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1886: expected 11 Season 1 chairs for this cohort, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('6af34442-997a-4b8d-8c19-3ae65519fa38','e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d','2d3e3416-fb12-455b-9010-4185010fb3aa','81d931a9-5906-4ff4-9ac8-15b49c4ae38a','a436b52d-8801-4588-b676-bd101bb2bdeb','f4286f1f-dda7-4fe4-9473-455772f40fae','1ff93be4-a2d0-432b-af59-ef6ace1eb77b','579a5a6f-c12e-4f01-af74-ec30f6bfbafe','02691090-c16c-4216-ac3b-1caa89a618a8','56b91150-194f-4699-ba31-e944443eacae','43567dd1-db59-40af-928e-03708237eb98');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1886: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND topic_revision_id='55c3167e-3ad8-425d-a699-b2e91552d912';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1886: Season 2 does not pin revision 55c3167e-3ad8-425d-a699-b2e91552d912 for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, v.reasoning, ARRAY[]::text[]
FROM (VALUES
  -- Lulu Flores (S1 chair 2)
  ('6af34442-997a-4b8d-8c19-3ae65519fa38',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Lulu Flores at chair 2 on inference rather than on anything Flores did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Molly Cook (S1 chair 2)
  ('e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Molly Cook at chair 2 on inference rather than on anything Cook did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Oscar Longoria (S1 chair 2)
  ('2d3e3416-fb12-455b-9010-4185010fb3aa',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Oscar Longoria at chair 2 on inference rather than on anything Longoria did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Penny Morales Shaw (S1 chair 2)
  ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Penny Morales Shaw at chair 2 on inference rather than on anything Shaw did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Ray Lopez (S1 chair 2)
  ('a436b52d-8801-4588-b676-bd101bb2bdeb',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Ray Lopez at chair 2 on inference rather than on anything Lopez did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Rhetta Bowers (S1 chair 2)
  ('f4286f1f-dda7-4fe4-9473-455772f40fae',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Rhetta Bowers at chair 2 on inference rather than on anything Bowers did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Royce West (S1 chair 2)
  ('1ff93be4-a2d0-432b-af59-ef6ace1eb77b',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Royce West at chair 2 on inference rather than on anything West did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Steve Toth (S1 chair 5)
  ('579a5a6f-c12e-4f01-af74-ec30f6bfbafe',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Steve Toth at chair 5 on inference rather than on anything Toth did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Terry Canales (S1 chair 2)
  ('02691090-c16c-4216-ac3b-1caa89a618a8',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Terry Canales at chair 2 on inference rather than on anything Canales did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Terry Wilson (S1 chair 4)
  ('56b91150-194f-4699-ba31-e944443eacae',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Terry Wilson at chair 4 on inference rather than on anything Wilson did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$),
  -- Toni Rose (S1 chair 2)
  ('43567dd1-db59-40af-928e-03708237eb98',$r$Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats Toni Rose at chair 2 on inference rather than on anything Rose did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$)
) AS v(pid, reasoning);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, 0
FROM (VALUES
  -- Lulu Flores (S1 chair 2 -> blank)
  ('6af34442-997a-4b8d-8c19-3ae65519fa38'),
  -- Molly Cook (S1 chair 2 -> blank)
  ('e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d'),
  -- Oscar Longoria (S1 chair 2 -> blank)
  ('2d3e3416-fb12-455b-9010-4185010fb3aa'),
  -- Penny Morales Shaw (S1 chair 2 -> blank)
  ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'),
  -- Ray Lopez (S1 chair 2 -> blank)
  ('a436b52d-8801-4588-b676-bd101bb2bdeb'),
  -- Rhetta Bowers (S1 chair 2 -> blank)
  ('f4286f1f-dda7-4fe4-9473-455772f40fae'),
  -- Royce West (S1 chair 2 -> blank)
  ('1ff93be4-a2d0-432b-af59-ef6ace1eb77b'),
  -- Steve Toth (S1 chair 5 -> blank)
  ('579a5a6f-c12e-4f01-af74-ec30f6bfbafe'),
  -- Terry Canales (S1 chair 2 -> blank)
  ('02691090-c16c-4216-ac3b-1caa89a618a8'),
  -- Terry Wilson (S1 chair 4 -> blank)
  ('56b91150-194f-4699-ba31-e944443eacae'),
  -- Toni Rose (S1 chair 2 -> blank)
  ('43567dd1-db59-40af-928e-03708237eb98')
) AS v(pid);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=0
     AND politician_id IN ('6af34442-997a-4b8d-8c19-3ae65519fa38','e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d','2d3e3416-fb12-455b-9010-4185010fb3aa','81d931a9-5906-4ff4-9ac8-15b49c4ae38a','a436b52d-8801-4588-b676-bd101bb2bdeb','f4286f1f-dda7-4fe4-9473-455772f40fae','1ff93be4-a2d0-432b-af59-ef6ace1eb77b','579a5a6f-c12e-4f01-af74-ec30f6bfbafe','02691090-c16c-4216-ac3b-1caa89a618a8','56b91150-194f-4699-ba31-e944443eacae','43567dd1-db59-40af-928e-03708237eb98');
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1886: expected 11 Season 2 blanks, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND a.value=0 AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1886: % blank(s) carry no context row explaining the blank', n;
  END IF;

  -- 🔴 Season 1 must be untouched: same count, and no Season 1 chair turned into a blank
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('6af34442-997a-4b8d-8c19-3ae65519fa38','e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d','2d3e3416-fb12-455b-9010-4185010fb3aa','81d931a9-5906-4ff4-9ac8-15b49c4ae38a','a436b52d-8801-4588-b676-bd101bb2bdeb','f4286f1f-dda7-4fe4-9473-455772f40fae','1ff93be4-a2d0-432b-af59-ef6ace1eb77b','579a5a6f-c12e-4f01-af74-ec30f6bfbafe','02691090-c16c-4216-ac3b-1caa89a618a8','56b91150-194f-4699-ba31-e944443eacae','43567dd1-db59-40af-928e-03708237eb98') AND value <> 0;
  IF n <> 11 THEN
    RAISE EXCEPTION 'migration 1886: Season 1 chairs changed -- % still non-blank, expected 11', n;
  END IF;
END $$;

COMMIT;
