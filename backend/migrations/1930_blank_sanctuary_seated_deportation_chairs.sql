-- Migration 1930 — withdraw three deportation chairs that a SANCTUARY instrument cannot seat.
--
-- WHAT THIS IS. A re-examination owed by migration 1927
-- (`backend/data/stance-research/2026-10-22-cluster-mappings/LEDGER.md`, open item 2). 1927 blanked
-- three MA rows seated at deportation chair 1 on the Safe Communities Act, on the ground that a
-- bill limiting STATE AND LOCAL COOPERATION with federal immigration enforcement says nothing about
-- WHO SHOULD BE DEPORTED, which is what this ladder asks. That ruling implicates three rows
-- migration 1921 had KEPT at deportation chair 2 on the same kind of instrument:
--
--   Adena Ishii        (Berkeley)  — 1921 ledger row R01
--   Eunisses Hernandez (LA)        — 1921 ledger row R10
--   Hugo Soto-Martinez (LA)        — 1921 ledger row R21
--
-- ⚖ A RULING THAT IMPLICATES EARLIER ROWS IS NOT SELF-EXECUTING. 1927 deliberately did not reach
-- these; they were logged and are read here on their own evidence.
--
-- 🔴 1921'S OWN REASONING STATES THE DEFECT. R01: "Enforcement-sceptical direction; rung 1 (stop
-- deportations entirely) needs more, SO NARROWING LANDS ON 2." R10: "rung 1 needs more." That is
-- the least-extreme-option-on-that-side TIEBREAKER, and the standard names reaching for it as the
-- signal that a row is not evidenced — not as a way to choose a chair.
--
-- THE LADDER AND WHAT THE INSTRUMENTS SAY.
--   chair 1  Stop deportations entirely and protect undocumented residents from removal
--   chair 2  Only deport people convicted of serious violent crimes
-- Ishii's evidence is a unanimous Berkeley council vote reaffirming the city's sanctuary status,
-- plus her own remark that some cities are actively assisting ICE. Hernandez and Soto-Martinez
-- co-introduced the 2023 motion that became Los Angeles's sanctuary ordinance (188441, signed
-- 2024-12-09, adding Chapter 19 to the Administrative Code), which bars City personnel and property
-- from being used for immigration enforcement. All three are about WHAT THE CITY WILL DO WITH ITS
-- OWN RESOURCES. None states a removal threshold, so chair 2's "only ... serious violent crimes" is
-- unevidenced, and chair 1 — which 1921 correctly declined — is further still.
--
-- 🔴 THE ONE REAL ARGUMENT THE OTHER WAY, AND WHY IT DOES NOT CARRY. Press coverage reports that
-- the LA ordinance carries an LAPD carve-out for "serious offenses", which Council President
-- Harris-Dawson described as letting police contact ICE about a migrant convicted of a violent
-- felony who was deported and returned. If the enacted text drew that line, it would be close to
-- chair 2's own words, and this would be a re-seat rather than a blank. IT COULD NOT BE VERIFIED:
-- the amlegal code library refused (HTTP 403), the Clerk's document host did not respond, and the
-- only available description is A REPORTER'S PARAPHRASE PLUS A COUNCILMEMBER'S SPOKEN
-- CHARACTERISATION — the article does not quote the ordinance. The standing rule is to read the
-- enacted text and never seat from a news summary, and the RFMA cluster (migration 1925) was
-- blanked for exactly this shape: A CHAIR DECIDED BY A PARAPHRASE.
-- ⚠ Note also that the carve-out as described is narrower than chair 2 even if accurate: it
-- concerns re-entry after a prior removal, not a general proposition about whom to deport. ▶ If
-- the enacted Chapter 19 text is obtained and does draw chair 2's line, these two LA rows are a
-- re-seat candidate on that text.
--
-- 🔑 THE DECISIVE STRUCTURAL POINT, AND IT IS THE PROJECT'S OWN. There is a separate
-- `local-immigration` ladder, and migration 1921 seated Hernandez at ITS chair 1 on THIS VERY
-- ORDINANCE, writing that "here it is squarely on-axis - it prohibits city resources for federal
-- immigration enforcement, which is rung 1" (ledger row R14). Saying the instrument is squarely
-- on-axis THERE concedes that it is off-axis HERE. Hernandez keeps that row; this migration does
-- not touch it.
-- ⚠ Soto-Martinez and Ishii have NO `local-immigration` row at all, so for them this blank leaves
-- the sanctuary evidence with no on-axis home. That is a gap to seed, not a reason to keep an
-- unevidenced chair. ▶ Logged in the ledger.
--
-- ⚠ ADMISSIBILITY IS NOT SUFFICIENCY. `inform.compass_topic_roles` marks deportation/local as
-- evidence_basis 'own-words' and is_required false, so a person's own words MAY seat this chair.
-- That settles what KIND of evidence is allowed, never whether the evidence describes the chair.
-- Ishii's remark criticises cities that assist ICE; it states no removal threshold.
--
-- ⚖ WHAT A BLANK ASSERTS: that THIS ROW does not show which rung the person occupies. It does not
-- assert they hold no view, and it does not doubt the vote, the motion or the ordinance. The
-- citations are kept and the original reasoning is PRESERVED VERBATIM beneath the notice.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

-- Freeze the target set ONCE, so the update, the counts and the verification all speak about the
-- same rows. 🔴 A predicate re-evaluated after the UPDATE would match nothing and pass vacuously.
CREATE TEMP TABLE mig1930_targets AS
SELECT pc.politician_id,
       pc.topic_id,
       pa.value     AS value_before,
       pc.reasoning AS reasoning_before
  FROM inform.politician_context pc
  JOIN inform.politician_answers pa
    ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
 WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND pc.topic_id  = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
   AND pc.politician_id IN (
         '965de422-660e-4e24-9fe6-717cc0313403'::uuid,  -- Adena Ishii
         '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,  -- Eunisses Hernandez
         '6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid   -- Hugo Soto-Martinez
       );

-- Record the before-picture for a delta check that does not depend on the predicate.
CREATE TEMP TABLE mig1930_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

-- Snapshot Season 1 for these pairs so the closing guard can prove it did not move.
CREATE TEMP TABLE mig1930_season1_before AS
SELECT pa.politician_id, pa.topic_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
  JOIN mig1930_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id;

-- GUARD 1 — the population is exactly the three rows read, each still at chair 2.
-- 🔴 STALENESS GATE: if another session has worked these rows, a value moves and this refuses.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1930_targets;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1930: expected 3 target rows, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1930_targets WHERE value_before <> 2;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % target(s) are no longer seated at chair 2 — re-read before writing', n; END IF;

  SELECT count(*) INTO n FROM mig1930_targets WHERE reasoning_before IS NULL OR length(reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % target(s) have no reasoning to preserve', n; END IF;
END $$;

-- GUARD 2 — every target really is a sanctuary-instrument row. Reading the shape of the stored
-- text rather than trusting the uuid list that selected it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1930_targets WHERE reasoning_before !~* 'sanctuary';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % target(s) do not cite a sanctuary instrument', n; END IF;

  -- None may already have been withdrawn by an earlier pass in this campaign.
  SELECT count(*) INTO n FROM mig1930_targets WHERE reasoning_before LIKE 'INTERNAL RECORD%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % target(s) are already withdrawn rows', n; END IF;
END $$;

-- GUARD 3 — 🔴 THE `local-immigration` ROW THIS PASS RELIES ON MUST ACTUALLY EXIST AND BE SEATED.
-- The argument for blanking is that the same ordinance is on-axis on a different ladder, where
-- migration 1921 seated Hernandez at chair 1. If that row were gone, the reasoning below would be
-- citing something untrue, so it is checked rather than asserted.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.compass_topics t ON t.id = pa.topic_id AND t.topic_key = 'local-immigration'
   WHERE pa.politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.value = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1930: Hernandez/local-immigration is not seated at chair 1; the off-axis argument no longer holds as written'; END IF;
END $$;

-- GUARD 4 — nothing may lose its citations, and every target must already have some.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1930_targets t
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

-- The answer: blank. value 0 suppresses the spoke; the row and its citations remain.
UPDATE inform.politician_answers pa
   SET value = 0, updated_at = now()
  FROM mig1930_targets t
 WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY — 🔑 with the original reasoning PRESERVED VERBATIM beneath it. The votes and
-- the ordinance are real and remain good evidence of an enforcement-sceptical direction; throwing
-- them away would make a re-read start from nothing. Sources are deliberately not touched.
UPDATE inform.politician_context pc
   SET reasoning = 'INTERNAL RECORD - blanked by migration 1930: the chair does not stand on the evidence this row cites. Shape: THE INSTRUMENT DOES NOT LEGISLATE ON THE LADDER''S QUESTION. The evidence is a SANCTUARY instrument - a city declining to put its own personnel, property and data at the service of federal immigration enforcement. This ladder asks WHO SHOULD BE DEPORTED, and a city does not decide that. Chair 2 reads "only deport people convicted of serious violent crimes"; none of these instruments states a removal threshold, so that chair is an unevidenced claim. Chair 1, "stop deportations entirely", is further still, and migration 1921 was right to decline it - but its stated route to chair 2 was that "rung 1 needs more, so narrowing lands on 2", which is the least-extreme-option TIEBREAKER rather than evidence. 🔑 THE PROJECT''S OWN ADJUDICATION SETTLES THE AXIS: migration 1921 seated this same ordinance at chair 1 of the separate LOCAL-IMMIGRATION ladder, writing that there "it is squarely on-axis". Squarely on-axis there means off-axis here. ⚠ Press coverage reports an LAPD carve-out for serious offenses in the Los Angeles ordinance, which if enacted in those terms would be close to chair 2 - but the enacted text could not be retrieved and the only description available is a reporter''s paraphrase, which is not a basis for a voter-facing chair. THE EVIDENCE IS NOT DOUBTED AND IS KEPT: the original reasoning follows verbatim and the sources are unchanged. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show which rung they occupy. THIS ROW IS A CANDIDATE FOR RE-SEATING, NOT A WRITE-OFF. Re-examination owed by migration 1927; see data/stance-research/2026-10-22-cluster-mappings/LEDGER.md. ---- ORIGINAL REASONING, PRESERVED ---- '
                  || t.reasoning_before,
       updated_at = now()
  FROM mig1930_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1930_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1930: expected 3 rows blanked, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1930_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % row(s) lost their citations', n; END IF;

  -- A blank must say which kind of nothing it is, and must keep what it replaced.
  SELECT count(*) INTO n
    FROM mig1930_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE 'INTERNAL RECORD - blanked by migration 1930%'
      OR pc.reasoning NOT LIKE '%Shape:%'
      OR pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ----%'
      OR position(t.reasoning_before in pc.reasoning) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % row(s) lost their original reasoning or their notice', n; END IF;

  -- 🔴 BLAST RADIUS, measured as a delta rather than asserted.
  SELECT seated_season2 INTO before_seated FROM mig1930_before;
  SELECT count(*) INTO after_seated
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF before_seated - after_seated <> 3 THEN
    RAISE EXCEPTION 'migration 1930: seated Season 2 rows fell by %, expected exactly 3', before_seated - after_seated;
  END IF;

  -- The local-immigration row this pass pointed at must survive untouched.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.compass_topics t ON t.id = pa.topic_id AND t.topic_key = 'local-immigration'
   WHERE pa.politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.value = 1;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1930: Hernandez/local-immigration no longer sits at chair 1'; END IF;

  -- 🔴 Season 1 is closed and must not have moved — proved against the snapshot.
  SELECT count(*) INTO n
    FROM mig1930_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id AND pa.topic_id = b.topic_id
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1930: % Season 1 row(s) moved', n; END IF;
END $$;

-- Final shape, for the apply log.
SELECT t.politician_id, t.value_before, pa.value AS value_after
  FROM mig1930_targets t
  JOIN inform.politician_answers pa
    ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
 ORDER BY t.politician_id;
