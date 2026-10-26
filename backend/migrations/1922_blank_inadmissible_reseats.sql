-- Migration 1922 — the remedy for three re-seats migration 1921 should not have made.
--
-- WHAT THIS IS. Migration 1921 re-seated 9 chairs out of the repaired-chairs queue. The
-- chair-evidence gate (`audit-chair-evidence.mjs --check`) is a PRE-commit gate for any migration
-- that sets a chair, and 1921 was applied before it was run. Run afterwards, scoped to Season 2, it
-- failed every chair-setting row. Six of those failures are the gate's documented lexical blindness
-- — "REPEAL ACT" missed on CASE alone, "Measure J" missed because `Measure` requires a decimal,
-- "voted against" missed because the pattern admits only `voted YES/No/Yea/Nay/Aye`. 🔴 THE REGEX
-- WAS NOT WIDENED. Those six name a real act or vote and the remedy there is to cite the identifier.
--
-- 🔴 FOUR NAMED NO INSTRUMENT AT ALL, AND THREE OF THOSE ARE SEATED WHERE THE CODEBOOK DOES NOT
-- ALLOW IT. Under the ruling of 2026-10-06 a record needs a lever, and the person's own words can
-- seat a chair ONLY where `inform.compass_topic_roles.evidence_basis` marks that (topic, level)
-- `own-words`. Checked row by row against that table:
--
--   R32 Harris-Dawson / redistricting  LOCAL  basis own-words  -> ADMISSIBLE, left alone.
--   R04 DeMaio        / same-sex-marriage STATE basis record   -> blanked here.
--   R11 Hernandez     / growth-and-development LOCAL basis record -> blanked here.
--   R12 Hernandez     / housing          LOCAL  basis record   -> RESCUED, chair unmoved.
--
-- ⚖⚖ THE PASS THAT CONVENED TO REFUSE THIS EVIDENCE PRODUCED IT. 1921 exists because a citation
-- repair is forbidden from moving a chair, so a wrongly-seated row came out of the repair passes
-- looking sourced. In three cases 1921 moved a chair onto evidence of exactly the kind it was
-- convened to refuse — a campaign sentence, an endorsement, an announcement. The remedy is the one
-- that queue already used thirteen times: a blank is correct.
--
-- ▶ A BOUNDED RESCUE WAS ATTEMPTED ON ALL THREE FIRST, which is why only two blank. Every page was
-- FETCHED and read; no call here rests on a search summary.
--
-- R12 HERNANDEZ / HOUSING — RESCUED, AND THE CHAIR DOES NOT MOVE. 1921's reasoning said she
-- "pushed the city to build a large-scale SOCIAL HOUSING programme", which names no instrument and
-- reads as advocacy. The instrument was on the cited page the whole time and the row never named
-- it. Read at the primary source — the City Clerk's own file, not a secondary account —
-- COUNCIL FILE 23-0038-S6, "Measure ULA / ACT-LA / Strategic Financing Tools / Permanent
-- Affordability / Resident Governance / Social Housing", introduced 05/28/2024, Mover MARQUEECE
-- HARRIS-DAWSON / EUNISSES HERNANDEZ / NITHYA RAMAN, approved as amended by the Housing and
-- Homelessness Committee 08/07/2024, ADOPTED BY COUNCIL 08/28/2024 by 15-0-0 with
-- "EUNISSES HERNANDEZ 1 YES" in the recorded vote. She is a MOVER and she voted YES on an adopted
-- file. That is her own act, numbered, and its content — build the city's capacity to establish a
-- large-scale social housing programme — is Season 2 rung 2's own distinguishing clause. Rung 1
-- ("make government the main provider ... everyone is guaranteed a home") needs far more than a
-- financing-tools motion. ⚠ A REPAIR MUST NOT MOVE A CHAIR, AND THIS ONE DOES NOT: 2 before, 2
-- after. The council file is ADDED to the row's sources, so the row also stops being generic-only.
--
-- R11 HERNANDEZ / GROWTH-AND-DEVELOPMENT — RESCUE FAILED, AND THE EVIDENCE PARTLY POINTS AWAY.
-- 1921 moved her 2 -> 1 on a campaign sentence: "My plan to fight gentrification is to be the
-- biggest barrier I can to luxury and market-rate development." Rung 1 reads "Hold the pace of
-- growth down — cap major new development, AND LET RESIDENTS VOTE DIRECTLY ON THE LARGEST
-- PROJECTS." Neither limb survives contact with her record on the very page cited:
--   · The resident-vote limb is CONTRADICTED. The page records her support for the discretionary
--     permit system, which gives COUNCIL MEMBERS the veto over land use — the opposite of letting
--     residents vote directly.
--   · The cap limb is CONTRADICTED BY A RECORDED POSITION. FETCHED at LAist: when Raman moved to
--     allow buildings up to 16 units in areas zoned single-family, "Councilmember Eunisses
--     Hernandez echoed Raman's arguments, saying that preserving wealthy single-family
--     neighborhoods represents a continuation of past segregationist policies", and the amendment
--     "failed to move forward" with 10 members against. She backed MORE housing in low-density
--     areas. The same page records her dissenting in 2025 from the council majority that opposed
--     SB 79, a bill to allow dense housing near transit.
-- She is against luxury and market-rate development and for density that is affordable. This
-- ladder is a pure PACE axis and cannot express that, so no rung describes her. Rung 2, where 1921
-- found her, is no better: "infrastructure" and "capacity" appear nowhere. A blank is correct.
--
-- R04 DEMAIO / SAME-SEX-MARRIAGE — RESCUE FAILED FOR WANT OF A RECORD, AND NONE CAN EXIST YET.
-- The whole of the cited page's marriage evidence is one sentence: "He announced his support for
-- same-sex marriage after 2008, has participated in LGBT Pride, and was endorsed by Log Cabin
-- Republicans." FETCHED and searched: the page carries NO Proposition 8, NO Proposition 3, NO
-- ACA 5, no bill number and no vote of any kind on marriage. An announcement is own words and an
-- endorsement is somebody else's; `same-sex-marriage` at STATE level is basis `record`, so neither
-- can seat this chair. ⚠ 1921's own note that "he is himself gay and married" is a fact about the
-- man, not a position he has recorded, and it is not evidence on this ladder.
--   🔑 AND THE ROW RAISES A QUESTION BIGGER THAN ITSELF, LEFT OPEN DELIBERATELY. DeMaio took his
--   Assembly seat in December 2024. California settled the question before he arrived — ACA 5
--   passed in 2023 and Proposition 3 was carried in November 2024 — so there is no state
--   instrument left for him to act on. If no rung at that level has a lever, the 2026-10-06 ruling
--   says the (topic, level) should read `own-words`, not `record`. THAT IS A RULING, NOT A
--   MIGRATION: `compass_topic_roles` is not touched here. Were it re-marked `own-words` later,
--   this row could be re-seated on the announcement — as a separate reliability stratum, which is
--   its own open item.
--
-- 🔑 WHY SEASON 2. Season 1 is closed and is not touched. A blank writes 0, which SUPPRESSES
-- (NULLIF(pa.value, 0)); the row stays and keeps its citations, so coverage still counts the
-- research as having happened. All three rows already serve from Season 2, so all are UPDATEs.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards below fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1922_decisions (
  politician_id uuid NOT NULL,
  topic_id      uuid NOT NULL,
  value_before  int  NOT NULL,
  new_value     int  NOT NULL,
  reasoning     text NOT NULL,
  ledger_no     text NOT NULL
) ON COMMIT DROP;

INSERT INTO mig1922_decisions
  (politician_id, topic_id, value_before, new_value, reasoning, ledger_no)
VALUES
-- R04  Carl DeMaio / same-sex-marriage  2 -> BLANK
('a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,2,0,
 'INTERNAL RECORD - blanked: migration 1921 re-seated this row onto evidence the codebook does not admit at this level, and migration 1922 withdraws it. Shape: NO RECORD AT A RECORD-BASIS LEVEL - the chair rests on the person''s own announcement and on somebody else''s endorsement, while compass_topic_roles marks same-sex-marriage at STATE level evidence_basis ''record''. WHY: the cited page''s entire marriage evidence is one sentence - he announced his support for same-sex marriage after 2008, has participated in LGBT Pride, and was endorsed by Log Cabin Republicans. FETCHED and searched: the page carries no Proposition 8, no Proposition 3, no ACA 5, no bill number and no vote of any kind on marriage. An announcement is own words and an endorsement is somebody else''s; neither can seat a chair where the basis is a record. That he is himself gay and married is a fact about the man, not a position he has recorded. OPEN QUESTION RECORDED, NOT ACTED ON: he took his Assembly seat in December 2024, after California settled the question (ACA 5 in 2023, Proposition 3 carried November 2024), so no state instrument remains for him to act on - which is the 2026-10-06 test for marking a (topic, level) ''own-words''. That is a ruling, and compass_topic_roles is not touched here. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs remedy, migration 1922, ledger row R04.','R04'),
-- R11  Eunisses Hernandez / growth-and-development  1 -> BLANK
('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid,1,0,
 'INTERNAL RECORD - blanked: migration 1921 re-seated this row onto evidence the codebook does not admit at this level, and migration 1922 withdraws it. Shape: RUNG TEXT, AND THE RECORD POINTS AWAY - the seated rung''s own wording describes something the evidence does not show, and her recorded positions cut against it. WHY: 1921 moved her 2 -> 1 on a campaign sentence, "My plan to fight gentrification is to be the biggest barrier I can to luxury and market-rate development." Rung 1 reads "Hold the pace of growth down - cap major new development, and let residents vote directly on the largest projects", and neither limb survives her record on the very page cited. The resident-vote limb is contradicted: the page records her support for the discretionary permit system, which gives COUNCIL MEMBERS the veto over land-use decisions, not residents. The cap limb is contradicted too: FETCHED at LAist, when Nithya Raman moved to allow buildings up to 16 units in areas zoned for single-family housing, "Councilmember Eunisses Hernandez echoed Raman''s arguments, saying that preserving wealthy single-family neighborhoods represents a continuation of past segregationist policies", and the amendment failed with 10 members against - she backed MORE housing in low-density areas. The same page records her dissenting in 2025 from the council majority opposing SB 79, which would allow dense housing near transit. She is against luxury and market-rate development and for density that is affordable; this ladder is a pure PACE axis and cannot express that. Rung 2 is no better - "infrastructure" and "capacity" appear nowhere. Writing this pair blank in Season 2 withdraws the answer from view; it does not assert that the person holds no view, only that this row does not show one. Repaired-chairs remedy, migration 1922, ledger row R11.','R11'),
-- R12  Eunisses Hernandez / housing  2 -> 2  (CITATION REPAIR; the chair does NOT move)
('317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,2,2,
 'Citation repaired 2026-10-21 (migration 1922). THE CHAIR IS UNCHANGED at 2; only the evidence is. Migration 1921 seated this row saying she "pushed the city to build a large-scale social housing programme", which names no instrument and reads as advocacy. THE INSTRUMENT WAS ON THE CITED PAGE THE WHOLE TIME AND THE ROW NEVER NAMED IT, so it is named here from the primary source rather than a secondary account: Los Angeles COUNCIL FILE 23-0038-S6, "Measure ULA / ACT-LA / Strategic Financing Tools / Permanent Affordability / Resident Governance / Social Housing", introduced 28 May 2024, with MARQUEECE HARRIS-DAWSON, EUNISSES HERNANDEZ and NITHYA RAMAN recorded as Mover. The Housing and Homelessness Committee approved it as amended on 7 August 2024 and the Council ADOPTED it on 28 August 2024 by 15-0-0, in which she voted YES. The motion directs the Housing Department to identify strategic financing tools supporting permanent affordability, resident governance and pathways to ownership in social housing, pointing to the Measure ULA fund. WHY THIS MATTERS TO THE CHAIR: she is a mover of the file and voted YES on its adoption, so this is her own act and not a position attributed to her; its content - build the city''s capacity to establish a large-scale social housing sector alongside a private market that stays the norm - is rung 2''s own distinguishing clause. Rung 1, "make government the main provider ... so everyone is guaranteed a home", needs far more than a financing-tools motion, and rung 3 is excluded outright because it requires that no public housing be built. Repaired-chairs remedy, migration 1922, ledger row R12.','R12');

-- GUARD 1 — the decision table arrived whole and says what the ledger says.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1922_decisions;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1922: expected 3 decisions, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT DISTINCT politician_id, topic_id FROM mig1922_decisions) s;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1922: duplicate (politician, topic) pairs; % distinct of 3', n; END IF;
  SELECT count(*) INTO n FROM mig1922_decisions WHERE new_value = 0;
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1922: expected 2 blanks, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1922_decisions WHERE new_value <> 0 AND new_value <> value_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % non-blank row(s) would MOVE a chair - a repair may not', n; END IF;
END $$;

-- GUARD 2 — the picture is current. Every target must still sit exactly where 1921 left it.
-- 🔴 This is what makes a double-apply impossible to do silently.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1922_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_answers pa
      WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
        AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND pa.value = d.value_before);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % target(s) do not sit at the value 1922 expects - re-measure', n; END IF;
END $$;

-- GUARD 3 — every target is one migration 1921 actually wrote. If 1921 were reverted this must fail.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1922_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1921%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % target(s) were not written by migration 1921 - wrong rows', n; END IF;
END $$;

-- GUARD 4 — the evidence basis this migration turns on is what it claims. Read it, do not assume it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.compass_topic_roles r
   WHERE (r.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND r.role_scope = 'state' AND r.evidence_basis = 'record')
      OR (r.topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'::uuid AND r.role_scope = 'local' AND r.evidence_basis = 'record')
      OR (r.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND r.role_scope = 'local' AND r.evidence_basis = 'record');
  IF n <> 3 THEN
    RAISE EXCEPTION 'migration 1922: expected 3 record-basis (topic, level) rows underpinning this pass, found % - the ruling moved', n;
  END IF;
END $$;

-- GUARD 5 — nothing may lose its citations.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1922_decisions d
   WHERE NOT EXISTS (
     SELECT 1 FROM inform.politician_context pc
      WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
        AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
        AND coalesce(cardinality(pc.sources), 0) > 0);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % target(s) have no citations to carry forward', n; END IF;
END $$;

-- The answer. Two blanks write 0; the repaired row is written at its own unchanged value.
UPDATE inform.politician_answers pa
   SET value = d.new_value, updated_at = now()
  FROM mig1922_decisions d
 WHERE pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The record of WHY.
UPDATE inform.politician_context pc
   SET reasoning = d.reasoning, updated_at = now()
  FROM mig1922_decisions d
 WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- R12 only: add the primary source, so the rescued row stops resting on a generic page alone.
-- Idempotent — appends only if the council file is not already cited.
UPDATE inform.politician_context
   SET sources = sources || ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0038-S6'],
       updated_at = now()
 WHERE politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid
   AND topic_id      = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
   AND season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND NOT (sources @> ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0038-S6']);

-- GUARD 6 — verify the RESULT, not the absence of an error.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1922_decisions d
    JOIN inform.politician_answers pa
      ON pa.politician_id = d.politician_id AND pa.topic_id = d.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = d.new_value;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1922: expected 3 rows at their new value, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1922_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % row(s) lost their citations', n; END IF;

  -- A blank must say which kind of nothing it is; the repair must say the chair did not move.
  SELECT count(*) INTO n
    FROM mig1922_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE (d.new_value =  0 AND pc.reasoning NOT LIKE '%Shape:%')
      OR (d.new_value <> 0 AND pc.reasoning NOT LIKE '%THE CHAIR IS UNCHANGED%');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % row(s) do not record what was done to them', n; END IF;

  -- 🔴 No row this pass touched may still carry 1921's re-seat prefix: that is the defect being cleared.
  SELECT count(*) INTO n
    FROM mig1922_decisions d
    JOIN inform.politician_context pc
      ON pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning LIKE 'CHAIR MOVED%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % row(s) still carry the 1921 re-seat prefix', n; END IF;

  -- The rescued row must now cite the council file, and must still sit at 2.
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
   WHERE pc.politician_id = '317698c6-2ae7-4f7f-ab39-bb3811ed50f3'::uuid
     AND pc.topic_id      = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
     AND pc.season_id     = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pa.value = 2
     AND pc.sources @> ARRAY['https://cityclerk.lacity.org/lacityclerkconnect/index.cfm?fa=ccfi.viewrecord&cfnumber=23-0038-S6']
     AND pc.reasoning LIKE '%23-0038-S6%';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1922: the rescued housing row is not at 2 citing council file 23-0038-S6 (found %)', n; END IF;

  -- 🔴 BLAST RADIUS. 1921 made NINE re-seats and this pass rewrites THREE of them — two blanked and
  -- one re-worded as a citation repair — so exactly SIX may still carry the re-seat prefix and a
  -- live chair. ⚠ This gate was written expecting 7 and the dry run refused it: the rescued housing
  -- row stops saying "CHAIR MOVED" even though its chair never moves. Arithmetic, caught by the
  -- gate rather than by the author, which is what a post-verify gate is for.
  SELECT count(*) INTO n
    FROM inform.politician_context pc
    JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id AND pa.season_id = pc.season_id
   WHERE pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND pc.reasoning LIKE 'CHAIR MOVED%migration 1921%'
     AND pa.value > 0;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1922: expected 6 of 1921''s re-seats left standing, found % - wrong blast radius', n; END IF;

  -- Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.seasons s ON s.id = pa.season_id AND s.name = 'Season 1'
    JOIN mig1922_decisions d ON d.politician_id = pa.politician_id AND d.topic_id = pa.topic_id
   WHERE pa.updated_at > now() - interval '5 minutes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1922: % Season 1 answer(s) were modified — Season 1 is closed', n; END IF;
END $$;
