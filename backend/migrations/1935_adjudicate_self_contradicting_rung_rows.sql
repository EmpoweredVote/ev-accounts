-- Migration 1935 — adjudicate the six rows whose own reasoning names a different rung than the
-- chair they serve.
--
-- WHAT THIS IS. While checking Jenny Wong's class (LEDGER §10), a query found six Season 2 rows in
-- which the stored reasoning explicitly names a rung — "consistent with stance 3", "aligns with new
-- stance 2", "represents a value-3 stance" — while the answer row serves a DIFFERENT number.
-- ⚖ This is the cleanest detector shape in the whole campaign: pure SQL, no lexicon, no
-- calibration, no polarity inference. The row contradicts itself in its own published text.
--
-- 🔴 I PROBED FOR AN INSERTED RUNG BEFORE TREATING ANY OF IT AS A DEFECT. Five of the six are on
-- `housing` and every one is chair = text + 1, and a uniform +1 across a topic is exactly the
-- signature of a rung having been inserted into the ladder — the trap that made migration 1903
-- blank 13 rows wrongly. IT IS NOT ONE HERE. Housing rung 3 TODAY reads "Offer targeted help like
-- subsidies for affordable projects, first-time buyer assistance, and easier building permits",
-- which is precisely the CONTENT the prose describes, and rung 4 reads "Cut regulations and zoning
-- rules so private developers can build more housing". Spellerberg's reasoning even says "not ...
-- full market deregulation" WHILE SEATED ON THE DEREGULATION CHAIR. The prose matches today's
-- numbering, so the chairs are wrong, not the prose. Ma's and Cohen's say "new stance 2" — the
-- author knew the ladder had been renumbered and wrote against the new one.
--
-- ⚖⚖ BUT THE REMEDY IS NOT "MOVE THE CHAIR TO THE NUMBER THE TEXT NAMES." The text naming a rung
-- is the row's own CLAIM, not evidence for it, and a chair still needs evidence describing THAT
-- chair. Read against the ladder, the rung the prose named is itself unevidenced in five of the six
-- cases. 🔑 SO THE MISMATCH IS AN EXCELLENT DETECTOR AND A USELESS REMEDY — the same shape as "a
-- vote proves the SIDE, not the RUNG". Only ONE of the six moves to the number its text named.
--
-- THE SIX, AND WHY EACH LANDS WHERE IT DOES:
--
-- 1. JOEY SPELLERBERG / housing 4 -> 3. RE-SEAT, the only one. ✅ Verified beyond what the row
--    claimed: Nebraska LB 803 was introduced by Senator Hallstrom AT THE TREASURER'S REQUEST,
--    passed 48-1 and was signed 2026-04-16; its First-Time Homebuyer Savings Account Act allows
--    tax-advantaged accounts for down payments and closing costs on a Nebraska primary residence.
--    "First-time buyer assistance" is chair 3's own words, and the initiative is attributable to
--    his office rather than merely administered by it.
--
-- 2. ERICK RUSSELL / housing 4 -> blank. The cited instrument is the CT Baby Bonds programme, which
--    he ADMINISTERS and did not create, and which is a general asset-building vehicle whose
--    permitted uses are home purchase, business investment, education OR retirement. A wealth
--    programme with four uses is not a housing position, and administering it is an office duty.
--    Neither chair 4 nor the chair 3 the text names is evidenced.
--
-- 3. ERICK RUSSELL / same-sex-marriage 2 -> blank. The reasoning seats the chair on WHO HE IS —
--    "the first openly gay Black person elected to Connecticut statewide office and is married to a
--    man" — plus action on gender-affirming care, a different question. 🔴 PERSONAL IDENTITY IS NOT
--    A POLICY POSITION, and this topic is evidence_basis 'record' at state scope, which identity is
--    not even own-words of. Neither chair 2 nor the chair 1 the text names is evidenced.
--
-- 4. FIONA MA / housing 3 -> blank. ⚠ THE CLOSEST CALL HERE, AND IT GOES THE SAME WAY FOR
--    CONSISTENCY. Chairing CDLAC and CTCAC, which allocate housing bonds and Low Income Housing Tax
--    Credits, is an EX OFFICIO STATUTORY DUTY of the California Treasurer — she would chair them
--    whatever she believed — and "oversaw the Dream for All fund" is administration. The remaining
--    item, a campaign listing "affordable housing and homelessness as top priorities", is a
--    SALIENCE claim, not a rung. This is Jenny Wong's OFFICE DUTY shape (migration 1917) and the
--    same ground on which rows 2 and 6 are blanked; sparing this one because the chair happens to
--    fit would be applying the standard unevenly.
--
-- 5. MALIA M. COHEN / housing 3 -> blank. "Supported large-scale affordable housing investment and
--    rental assistance programs during her time as SF supervisor" names NO instrument, NO vote and
--    NO date, and the auditing she does as Controller is an office duty. The sources are an
--    aggregator profile and a voter guide. This is the generic-sourcing defect this whole campaign
--    exists to clear.
--
-- 6. STEVEN JOHNSON / housing 4 -> blank. "The Kansas Treasurer's OFFICE under Johnson administers
--    the Home In The Heartland grant program" — the office administering a programme is not the
--    officeholder's position on it, and the single citation is a bare domain with no path.
--
-- NET: 1 re-seat, 5 blanks, across 5 people.
--
-- ⚖ WHAT A BLANK ASSERTS: that THIS ROW does not show which rung the person occupies. It does not
-- assert they hold no view. Citations are kept and the original reasoning is PRESERVED VERBATIM
-- beneath the notice, so a re-read starts from the record.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1935_targets (
  politician_id uuid NOT NULL,
  topic_id      uuid NOT NULL,
  who           text NOT NULL,
  what          text NOT NULL,
  value_before  numeric NOT NULL,
  value_after   numeric NOT NULL,
  rung_in_text  int  NOT NULL,
  note          text NOT NULL,
  reasoning_before text
);

INSERT INTO mig1935_targets (politician_id, topic_id, who, what, value_before, value_after, rung_in_text, note) VALUES
('dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Joey Spellerberg','housing',4,3,3,
 'RE-SEATED from chair 4 to chair 3 by migration 1935. The row served chair 4, "Cut regulations and zoning rules so private developers can build more housing", while its own reasoning said "consistent with stance 3 - not public housing construction, rent caps, or full market deregulation". It therefore declined the deregulation chair in the same sentence that sat on it. Chair 3 reads "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits". THE EVIDENCE, verified against the record rather than taken from the row: Nebraska LB 803 carried the First-Time Homebuyer Savings Account Act as the lead provision of the Revenue Committee priority package; Senator Bob Hallstrom introduced it AT THE TREASURER''S REQUEST, it passed 48-1 and Governor Pillen signed it on 2026-04-16. It creates tax-advantaged savings accounts usable for down payments and closing costs on a Nebraska primary residence, with accounts opening 2027-01-01. "First-time buyer assistance" is chair 3''s own words, and because the bill was introduced at the Treasurer''s request the initiative is attributable to him rather than merely administered by his office - which is what separates this row from the ones migration 1935 blanked.'),
('674a492b-43f5-45c5-85e8-c302d4a3fd91'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Erick Russell','housing',4,0,3,
 'OFFICE DUTY, AND AN OFF-AXIS INSTRUMENT. The row served chair 4, "Cut regulations and zoning rules", while its reasoning said "consistent with stance 3". Neither is evidenced. The cited instrument is the Connecticut Baby Bonds programme, which the reasoning itself says he ADMINISTERS - it was created before his tenure - and which is a general asset-building vehicle whose permitted uses are home purchase, business investment, education OR retirement. A wealth-building fund with four permitted uses does not establish a position on how housing should be supplied or made affordable, and administering a programme is a duty of the office rather than a view about it.'),
('674a492b-43f5-45c5-85e8-c302d4a3fd91'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'Erick Russell','same-sex-marriage',2,0,1,
 'A CHAIR SEATED ON PERSONAL IDENTITY. The row served chair 2 while its reasoning said "consistent with stance 1", and the evidence offered for either is that he "is the first openly gay Black person elected to Connecticut statewide office and is married to a man", plus action protecting gender-affirming care access. 🔴 WHO A PERSON IS, AND WHOM THEY ARE MARRIED TO, IS NOT A STATEMENT OF WHAT POLICY THEY HOLD - it is an inference about them, and a voter-facing chair is a claim about their position. Gender-affirming care is a different question from marriage recognition. This topic is evidence_basis ''record'' at state scope, and identity is not a record of a position; chair 1 ("require all states to recognize same-sex marriages") and chair 2 ("allow same-sex marriage nationwide while protecting some organizations'' right to decline participation") differ precisely over a religious-exemption question on which nothing here speaks.'),
('41ef8aaa-b604-4725-b46d-dab1656cc198'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Fiona Ma','housing',3,0,2,
 'OFFICE DUTY, PLUS A SALIENCE CLAIM. The row served chair 3 while its reasoning said the evidence was "consistent with new stance 2" - and on reading, neither chair is established. Chairing CDLAC and CTCAC, the bodies that allocate California housing bonds and Low Income Housing Tax Credits, is an EX OFFICIO STATUTORY DUTY of the Treasurer: she holds those chairs by virtue of the office, whatever she believes about housing policy, so performing them shows no preference between the ladder''s options. "Oversaw the Dream for All first-time buyer fund" is likewise administration of a programme created elsewhere. What remains is a campaign listing "affordable housing and homelessness as top priorities", which is a statement of SALIENCE - that the subject matters - and not of which approach she favours. ⚠ This was the closest call in migration 1935: chair 3''s text does describe what her office does. It is blanked for consistency with the two rows beside it, because "the office does X" is not "the officeholder holds X", and sparing this row while blanking Johnson and Russell on the same ground would apply the standard unevenly.'),
('ea85dfe3-1092-468e-a799-cb8054c135db'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Malia M. Cohen','housing',3,0,2,
 'NO INSTRUMENT, AND AGGREGATOR SOURCING. The row served chair 3 while its reasoning said it "aligns with new stance 2". The evidence for either is that she "supported large-scale affordable housing investment and rental assistance programs during her time as SF supervisor and has stated affordable housing is a priority" - which names no bill, no vote, no date and no quotation - together with auditing housing spending as Controller, which is a duty of that office. The citations are an aggregator profile and a voter guide rather than a record. Chair 2 ("rent caps, require new developments to include affordable units, and publicly fund new housing") and chair 3 ("targeted help like subsidies ... first-time buyer assistance ... easier building permits") are distinguished by mechanisms that nothing here names, so the row establishes a direction at most.'),
('6dada0fd-8e21-4899-819d-26ba69a75b37'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Steven Johnson','housing',4,0,3,
 'OFFICE DUTY. The row served chair 4, "Cut regulations and zoning rules", while its reasoning said "This represents a value-3 stance". The whole of the evidence is that "the Kansas Treasurer''s OFFICE under Johnson administers the Home In The Heartland grant program" - the office administering a programme, which is a duty discharged regardless of the officeholder''s view, and the sentence does not attribute the programme to him. The single citation is a bare domain with no path. This is the shape migration 1917 named as OFFICE DUTY when it blanked Berkeley City Auditor Jenny Wong: the cited activity is a duty of the office, not a position on the question.');

-- Attach the text about to be replaced.
UPDATE mig1935_targets t
   SET reasoning_before = pc.reasoning
  FROM inform.politician_context pc
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

CREATE TEMP TABLE mig1935_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

CREATE TEMP TABLE mig1935_season1_before AS
SELECT pa.politician_id, pa.topic_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
  JOIN mig1935_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id;

-- GUARD 1 — the population is exactly the six rows read, each still serving the chair it was read
-- at. 🔴 Staleness gate: if another session has worked these rows, this refuses.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1935_targets;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1935: expected 6 targets, found %', n; END IF;

  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1935_targets) d;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1935: duplicate (politician, topic) pairs'; END IF;

  SELECT count(*) INTO n
    FROM mig1935_targets t
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value IS NULL OR pa.value <> t.value_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) are missing or no longer serve the chair they were read at', n; END IF;

  SELECT count(*) INTO n FROM mig1935_targets WHERE reasoning_before IS NULL OR length(reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) have no reasoning to preserve', n; END IF;
END $$;

-- GUARD 2 — 🔑 THE DEFINING PROPERTY MUST ACTUALLY HOLD. Every target's stored reasoning must name
-- a rung, and that rung must differ from the chair the row serves. This is what selected them, so
-- it is verified rather than trusted.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1935_targets
   WHERE reasoning_before !~* '(stance|value)[- ]?[1-5]';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) name no rung in their reasoning', n; END IF;

  SELECT count(*) INTO n FROM mig1935_targets
   WHERE (regexp_match(reasoning_before, '(?:stance|value)[- ]?([1-5])', 'i'))[1]::int <> rung_in_text;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) do not name the rung this pass recorded', n; END IF;

  SELECT count(*) INTO n FROM mig1935_targets WHERE rung_in_text = value_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) do not actually contradict themselves', n; END IF;
END $$;

-- GUARD 3 — 🔴 NOT AN INSERTED RUNG. The whole reading rests on the housing ladder still saying
-- today what the prose describes. If rung 3 stopped being the targeted-assistance rung, or rung 4
-- stopped being the deregulation rung, the five housing calls would need re-reading, so the
-- migration refuses rather than writing against a ladder that moved.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 3
     AND text ILIKE '%first-time buyer assistance%' AND text ILIKE '%subsidies%';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1935: housing rung 3 is no longer the targeted-assistance rung these rows were read against'; END IF;

  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4
     AND text ILIKE '%Cut regulations%';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1935: housing rung 4 is no longer the deregulation rung these rows were read against'; END IF;

  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1935: the housing ladder has % rungs, not 5 — probe for an inserted rung before writing', n; END IF;
END $$;

-- GUARD 4 — admissibility for the one re-seat. housing/state is evidence_basis 'record', and
-- Spellerberg's chair rests on an enacted act introduced at his office's request.
DO $$
DECLARE basis text; n int;
BEGIN
  SELECT r.evidence_basis INTO basis FROM inform.compass_topic_roles r
   WHERE r.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND r.role_scope = 'state';
  IF basis IS DISTINCT FROM 'record' THEN
    RAISE EXCEPTION 'migration 1935: housing/state evidence_basis is %, not the record basis the re-seat was judged against', coalesce(basis, 'missing');
  END IF;

  SELECT count(*) INTO n FROM mig1935_targets WHERE value_after > 0;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1935: expected exactly 1 re-seat, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1935_targets WHERE value_after > 0 AND note !~* 'LB 803';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: the re-seat does not name its instrument'; END IF;
END $$;

-- GUARD 5 — nothing may lose its citations.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1935_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

UPDATE inform.politician_answers pa
   SET value = t.value_after, updated_at = now()
  FROM mig1935_targets t
 WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY, with the original reasoning PRESERVED VERBATIM beneath it. Sources untouched.
UPDATE inform.politician_context pc
   SET reasoning = CASE WHEN t.value_after > 0
         THEN 'RE-SEATED by migration 1935. '
         ELSE 'INTERNAL RECORD - blanked by migration 1935: the chair does not stand on the evidence this row cites. '
       END
       || 'Shape: THE ROW NAMED A DIFFERENT RUNG THAN IT SERVED - its own text said rung '
       || t.rung_in_text::text || ' while the answer served chair ' || t.value_before::text
       || '. ⚖ A row naming a rung is a CLAIM, not evidence for it, so the mismatch decided nothing by itself; the evidence was read against the ladder and the answer below is what it supports. '
       || t.note
       || ' ⚠ Checked first that this was not a renumbered ladder: housing rung 3 still reads "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits" and rung 4 still reads "Cut regulations and zoning rules", so the prose matches today''s numbering and the chair was the thing out of step. '
       || CASE WHEN t.value_after > 0 THEN ''
          ELSE 'Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show which rung they occupy. THE EVIDENCE IS KEPT AND THIS ROW IS A CANDIDATE FOR RE-SEATING. ' END
       || 'See data/stance-research/2026-10-22-cluster-mappings/LEDGER.md. ---- ORIGINAL REASONING, PRESERVED ---- '
       || t.reasoning_before,
       updated_at = now()
  FROM mig1935_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1935_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> t.value_after;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % row(s) do not hold the adjudicated value', n; END IF;

  SELECT count(*) INTO n
    FROM mig1935_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1935: expected 5 blanked rows, found %', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_answers pa
   WHERE pa.politician_id = 'dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid
     AND pa.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.value = 3;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1935: Spellerberg is not seated at chair 3'; END IF;

  SELECT count(*) INTO n
    FROM mig1935_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % row(s) lost their citations', n; END IF;

  SELECT count(*) INTO n
    FROM mig1935_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1935%'
      OR pc.reasoning NOT LIKE '%Shape:%'
      OR pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ----%'
      OR position(t.reasoning_before in pc.reasoning) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % row(s) lost their original reasoning or their notice', n; END IF;

  -- 🔴 BLAST RADIUS as a delta: 5 rows leave the seated set, the re-seat stays in it.
  SELECT seated_season2 INTO before_seated FROM mig1935_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF before_seated - after_seated <> 5 THEN
    RAISE EXCEPTION 'migration 1935: seated Season 2 rows fell by %, expected exactly 5', before_seated - after_seated;
  END IF;

  -- 🔴 Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM mig1935_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id AND pa.topic_id = b.topic_id
    JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % Season 1 row(s) moved', n; END IF;

  -- 🔑 The defect this pass clears: no Season 2 row may still serve a chair its own text contradicts
  -- among the targets.
  SELECT count(*) INTO n
    FROM mig1935_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value > 0 AND pa.value <> t.rung_in_text;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1935: % target(s) are still seated at a chair their text contradicts', n; END IF;
END $$;

SELECT t.who, t.what, t.value_before AS was, t.value_after AS now, t.rung_in_text AS text_said
  FROM mig1935_targets t ORDER BY t.who, t.what;
