-- Migration 1948 — the 2021 Massachusetts Climate Act, re-seated on the instrument ladder.
--
-- 49 serving rows name this Act on climate-change. **42 are written**: every row on Season 1 chairs
-- 1 and 2, whose text is false of the Act. 7 are left alone.
--
--   rows  where they sit                     decision                               written
--   ----  ---------------------------------  -------------------------------------  -------
--     23  Season 1 chair 1                   re-seat to Season 2 chair 1                 23
--     19  Season 1 chair 2                   re-seat to Season 2 chair 1                 19
--      3  Season 1 chair 3                   left alone - their caution is recorded       0
--      4  Season 1 chair 4                   left alone - they voted AGAINST the Act      0
--
-- Every target serves from the closed Season 1, so every write inserts a Season 2 row. Season 1 is
-- untouched and the post-flight block proves it.
-- Full record: data/stance-research/2026-10-26-ma-climate-act-2021/LEDGER.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. THE ACT, READ
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Chapter 8 of the Acts of 2021, "An Act creating a next-generation roadmap for Massachusetts
-- climate policy" - Senate Bill 9 of the 192nd General Court, signed 26 March 2021.
--     section 4(h)  "The interim 2030 statewide greenhouse gas emissions limit shall be at least
--                   50 per cent below the 1990 level"; 2040 at least 75 per cent
--     section 3(b)  a 2050 limit achieving "at least net zero statewide greenhouse gas emissions"
--     section 9     sector sublimits for electric power, transportation, commercial and industrial
--                   heating and cooling, residential heating and cooling, industrial processes and
--                   natural gas distribution
--
-- The Season 1 climate ladder ranks AMBITION:
--     c1 declare a climate emergency and ban all activities that increase carbon emissions
--     c2 rapidly transition to renewable energy and phase out fossil fuels by 2030
--     c3 invest in clean energy while gradually reducing reliance on fossil fuels
-- NO EMERGENCY IS DECLARED, NOTHING IS BANNED, AND NO FOSSIL FUEL IS PHASED OUT BY 2030 - the 2030
-- requirement is a 50 per cent reduction. Chairs 1 and 2 are both false of a member whose evidence
-- is this Act, and 42 people were showing voters one or the other.
--
-- The remedy lands on a different question. Season 1 is closed, so the lever is a Season 2 insert,
-- and by ADR 0006 that row is read against the SEASON 2 ladder, which ranks INSTRUMENTS:
--     c1 Require a shift to clean energy through mandates and firm deadlines.
--     c2 Fund clean energy with major subsidies, tax credits, and public investment.
--     c3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
-- Statutory limits with dates, plus sector sublimits, is chair 1 and nothing else: the Act creates
-- no significant tax credit and appropriates nothing, so chair 2 fails on its own text, and it
-- reforms no permitting, so chair 3 does. **This is the same reading migration 1943 gave the
-- Maryland Climate Solutions Now Act**, on the same ladder, for the same reason.
--
-- 🔴 climate-change v2r3 carries an IDENTITY rung_map {1:1,...,5:5} over this rewrite from ambition
-- to instrument. A rung_map can lie; the rung TEXTS decide, and GUARD 3 asserts all four.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. ⚠ 16 OF THESE ROWS CITE A BILL THAT IS NOT THE ACT
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- They give the 2021 Climate Act as "H.4933". H.4933 of the 192nd General Court is "An Act relative
-- to certain matters concerning municipal governance"; it was reported from the Joint Committee on
-- Municipalities and Regional Government, discharged to House Rules, and died with "no further
-- action taken" on 3 January 2023. The climate law is Senate Bill 9 of the same General Court.
--
-- The claim about what these members did is NOT doubted - the Act passed the House on a recorded
-- vote and the rows describe it correctly in prose. Only the bill number is wrong. This file
-- therefore leaves every citation exactly as it found it and records the error in the row's own
-- notice, because changing evidence is a citation pass's job and not this one's. 16 rows carry the
-- longer notice; 26 carry the plain one, and GUARD 2 checks that each is in the right group.
--
-- ⚠ This is the FOURTH cross-session or wrong-bill citation found in four passes: California "SB
-- 42" merged the Fair Elections Act with the CARE Court Act (migration 1945); the Massachusetts
-- Safe Communities Act was cited at /194/H2288, which is a housing bill (migration 1947); Texas
-- bill numbers recur across four legislatures; and now this. A citation that names a real bill on
-- the right legislature's site passes check-stance-sources, and reasoning that names an act passes
-- audit-chair-evidence. Only opening the page catches it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. THE SEVEN ROWS LEFT ALONE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THREE at chair 3 voted FOR the Act and carry their own recorded caution - "has consistently
-- raised concerns about the pace and cost of energy transition mandates", "mainstream Democratic
-- but tempered by concern about utility rate impacts". Season 1 chair 3, "invest in clean energy
-- while gradually reducing reliance on fossil fuels", is defensible of them, and the rule this pass
-- follows is migration 1944's: fix the rows whose serving text is FALSE of the member, leave the
-- rows whose serving text is defensible. ⚖ That is a departure from migration 1943, which moved a
-- chair 3 row along with its cohort; there, 33 people shared ONE vote and nothing else, so leaving
-- one out would have published two positions from one piece of evidence. Here the three carry
-- member-specific evidence the other 42 do not.
--
-- FOUR at chair 4 voted AGAINST the Act. They are the other direction and are not part of this
-- defect; three of them were citation-repaired by migration 1899, which verified the vote and left
-- the chair standing. ▶ Whether a NO vote can seat chair 4 ("let market forces drive any
-- transition") at all is a live question - migration 1945 ruled that a no vote proves opposition to
-- a bill and never an affirmative alternative - but re-opening a chair another pass affirmed is not
-- this file's business. Recorded in the ledger.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Every one serves from the CLOSED Season 1 (ADR 0005 section 1.6), so every
-- write INSERTs a Season 2 row, which by ADR 0006 is read against the SEASON 2 ladder. That
-- revision is resolved from inform.season_questions and never hard-coded.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1948_ins ON COMMIT DROP AS
SELECT x.politician_id, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AS topic_id, x.op, 1 AS value_after,
       sq.topic_revision_id AS s2_revision,
       pa1.value AS value_before, pa1.topic_revision_id AS s1_revision,
       pa1.updated_at AS s1_updated_at,
       pc1.reasoning AS reasoning_before, pc1.sources AS sources_before
  FROM (VALUES
  ('290ee018-6e9e-4a8c-9561-385cf5ef3d73'::uuid,'ma-climate-chair1'),  -- Adrian C. Madaro: was chair 1
  ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid,'ma-climate-chair1'),  -- Brendan P. Crighton: was chair 1
  ('7cbdb829-4836-49e9-afb2-cb8035afc6bf'::uuid,'ma-climate-chair1'),  -- Christine P. Barber: was chair 1
  ('fd3bf15c-265b-46a9-aa72-c9097749d762'::uuid,'ma-climate-chair1-miscited'),  -- Chynah Tyler: was chair 1
  ('b46a6774-2d85-4750-813a-6d4ef2eefb5b'::uuid,'ma-climate-chair1'),  -- Cynthia S. Creem: was chair 1
  ('5c36a94c-9006-4550-a37e-978a65d2725c'::uuid,'ma-climate-chair1-miscited'),  -- Daniel J. Hunt: was chair 1
  ('f8986c05-2e32-4184-bfb2-9d4c244ffd3a'::uuid,'ma-climate-chair1'),  -- Danillo Sena: was chair 1
  ('8c7d04dc-f567-4759-b99b-0ae8f26d6f32'::uuid,'ma-climate-chair1'),  -- Dylan A. Fernandes: was chair 1
  ('98291d86-d42d-49d0-a5b2-d689a8154b15'::uuid,'ma-climate-chair1'),  -- Erika Uyterhoeven: was chair 1
  ('9ed1b75f-a314-4241-87ff-231de4aba963'::uuid,'ma-climate-chair1'),  -- James B. Eldridge: was chair 1
  ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid,'ma-climate-chair1'),  -- Jason M. Lewis: was chair 1
  ('852e4a21-5750-4ac8-ba06-0376c5a31685'::uuid,'ma-climate-chair1-miscited'),  -- Jay Livingstone: was chair 1
  ('961506eb-3f00-4358-a9a3-1730e7004474'::uuid,'ma-climate-chair1'),  -- Joanne M. Comerford: was chair 1
  ('c4c3ed02-2592-4505-a26c-0195d0b5314e'::uuid,'ma-climate-chair1-miscited'),  -- Judith A. Garcia: was chair 1
  ('bd451748-111f-461d-9752-95e7c243769e'::uuid,'ma-climate-chair1'),  -- Julian A. Cyr: was chair 1
  ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf'::uuid,'ma-climate-chair1'),  -- Karen E. Spilka: was chair 1
  ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid,'ma-climate-chair1'),  -- Liz Miranda: was chair 1
  ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid,'ma-climate-chair1'),  -- Lydia M. Edwards: was chair 1
  ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90'::uuid,'ma-climate-chair1'),  -- Michael J. Barrett: was chair 1
  ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'::uuid,'ma-climate-chair1'),  -- Mike Connolly: was chair 1
  ('d40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid,'ma-climate-chair1'),  -- Patricia D. Jehlen: was chair 1
  ('f530be83-6f1b-4b04-a8c4-3a83dc35099f'::uuid,'ma-climate-chair1'),  -- Paul W. Mark: was chair 1
  ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c'::uuid,'ma-climate-chair1-miscited'),  -- Samantha Montaño: was chair 1
  ('9cf147de-64e0-4116-b461-95933e18c423'::uuid,'ma-climate-chair1-miscited'),  -- Aaron Michlewitz: was chair 2
  ('5c497509-7a9d-492b-ac35-ff37f8fcfb82'::uuid,'ma-climate-chair1-miscited'),  -- Brandy Fluker-Reid: was chair 2
  ('bca54df2-f059-44ce-81c3-f208f1e20752'::uuid,'ma-climate-chair1-miscited'),  -- Christopher J. Worrell: was chair 2
  ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa'::uuid,'ma-climate-chair1-miscited'),  -- Daniel J. Ryan: was chair 2
  ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f'::uuid,'ma-climate-chair1-miscited'),  -- David Biele: was chair 2
  ('ccb7cc4c-2c8f-4590-a3a2-f8e4bfbd64d5'::uuid,'ma-climate-chair1'),  -- Jacob R. Oliveira: was chair 2
  ('c539c9fa-a531-456f-9125-8d30f1fcedfe'::uuid,'ma-climate-chair1-miscited'),  -- Jeffrey R. Turco: was chair 2
  ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb'::uuid,'ma-climate-chair1-miscited'),  -- Jessica A. Giannino: was chair 2
  ('5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid,'ma-climate-chair1'),  -- John F. Keenan: was chair 2
  ('7cc9694b-3bca-44ec-ab75-762c1f6d5136'::uuid,'ma-climate-chair1-miscited'),  -- John F. Moran: was chair 2
  ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4'::uuid,'ma-climate-chair1-miscited'),  -- Kevin G. Honan: was chair 2
  ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid,'ma-climate-chair1'),  -- Mark C. Montigny: was chair 2
  ('67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid,'ma-climate-chair1'),  -- Michael D. Brady: was chair 2
  ('f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid,'ma-climate-chair1'),  -- Michael J. Rodrigues: was chair 2
  ('2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid,'ma-climate-chair1'),  -- Nick Collins: was chair 2
  ('c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid,'ma-climate-chair1'),  -- Paul R. Feeney: was chair 2
  ('e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid,'ma-climate-chair1-miscited'),  -- Russell E. Holmes: was chair 2
  ('194b9b91-6986-423e-89a0-ee9750f275d8'::uuid,'ma-climate-chair1-miscited'),  -- William F. MacGregor: was chair 2
  ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid,'ma-climate-chair1')  -- William N. Brownsberger: was chair 2
  ) AS x(politician_id, op)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target set must be exactly what was read.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1948_ins;
  IF n <> 42 THEN RAISE EXCEPTION 'migration 1948: expected 42 targets, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins WHERE op = 'ma-climate-chair1';
  IF n <> 26 THEN RAISE EXCEPTION 'migration 1948: ma-climate-chair1 expected 26, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins WHERE op = 'ma-climate-chair1-miscited';
  IF n <> 16 THEN RAISE EXCEPTION 'migration 1948: ma-climate-chair1-miscited expected 16, found %', n; END IF;
  SELECT count(DISTINCT politician_id) INTO n FROM mig1948_ins;
  IF n <> 42 THEN RAISE EXCEPTION 'migration 1948: duplicate people; % distinct of 42', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins
   WHERE reasoning_before IS NULL OR btrim(reasoning_before) = '' OR sources_before IS NULL OR cardinality(sources_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % target(s) have no reasoning or citation to keep', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins WHERE reasoning_before LIKE '%migration 1948%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % target(s) already carry a 1948 notice', n; END IF;
END $$;

-- GUARD 2 — every target must still sit where it was read, must name the Act, and the miscited ones
-- must really carry the wrong bill number.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1948_ins WHERE value_before NOT IN (1,2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % row(s) do not sit on chairs 1 or 2', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins
   WHERE reasoning_before !~* '(2021 climate act|next-generation roadmap|climate roadmap)';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % row(s) do not name the 2021 Climate Act', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins i
   WHERE i.op = 'ma-climate-chair1-miscited'
     AND i.reasoning_before !~ 'H\.? ?4933'
     AND NOT EXISTS (SELECT 1 FROM unnest(i.sources_before) u WHERE u LIKE '%/192/H4933%');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % miscited row(s) do not actually cite H.4933', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins i
   WHERE i.op = 'ma-climate-chair1'
     AND (i.reasoning_before ~ 'H\.? ?4933'
          OR EXISTS (SELECT 1 FROM unnest(i.sources_before) u WHERE u LIKE '%/192/H4933%'));
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % correctly-cited row(s) actually cite H.4933', n; END IF;
END $$;

-- GUARD 3 — THE LADDERS. climate-change v2r3 carries an IDENTITY rung_map over a ladder rewritten
-- from AMBITION to INSTRUMENT, so the rung TEXTS decide and are asserted here.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1948: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1948: Season 1 is not closed'; END IF;
  SELECT count(*) INTO n FROM mig1948_ins
   WHERE s1_revision <> 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid OR s2_revision <> '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % row(s) are not on the expected revisions', n; END IF;

  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'ban all activities that increase carbon emissions'
    THEN RAISE EXCEPTION 'migration 1948: Season 1 chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'phase out fossil fuels by 2030'
    THEN RAISE EXCEPTION 'migration 1948: Season 1 chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'mandates and firm deadlines'
    THEN RAISE EXCEPTION 'migration 1948: Season 2 chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'subsidies, tax credits, and public investment'
    THEN RAISE EXCEPTION 'migration 1948: Season 2 chair 2 does not read as recorded: %', t; END IF;
END $$;

-- GUARD 4 — these are inserts, so no target may already hold a Season 2 row; nobody inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1948_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid)
      OR EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % target(s) ALREADY have a Season 2 row', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins i
    JOIN essentials.politicians p ON p.id = i.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % target(s) are on inactive people', n; END IF;
END $$;

-- GUARD 5 — POPULATIONS. Every serving row naming this Act must be a target or deliberately left:
-- 3 rows at chair 3 whose members voted FOR the Act but carry their own recorded caution about the
-- pace and cost of mandates, and 4 rows at chair 4 whose members voted AGAINST it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT ON (pa.politician_id) pa.politician_id, pa.value, pc.reasoning
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
     WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND p.is_active
       AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
     ORDER BY pa.politician_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC) s
   WHERE s.value <> 0 AND s.reasoning ~* '(2021 climate act|next-generation roadmap|climate roadmap)';
  IF n <> 49 THEN RAISE EXCEPTION 'migration 1948: expected 49 serving rows naming the Act, found % — re-read before writing', n; END IF;

  SELECT count(*) INTO n FROM (
    SELECT DISTINCT ON (pa.politician_id) pa.politician_id, pa.value, pc.reasoning
      FROM inform.politician_answers pa
      JOIN inform.politician_context pc
        ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
      JOIN essentials.politicians p ON p.id = pa.politician_id
     WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND p.is_active
       AND pa.season_id <> '7b3a066c-815d-43b2-a6a0-6a3029778075'::uuid
     ORDER BY pa.politician_id, (pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid) DESC) s
   WHERE s.value IN (1,2) AND s.reasoning ~* '(2021 climate act|next-generation roadmap|climate roadmap)'
     AND NOT EXISTS (SELECT 1 FROM mig1948_ins i WHERE i.politician_id = s.politician_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % row(s) on chairs 1-2 naming the Act are not targets', n; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. Notice first, then the ORIGINAL prose verbatim; citations carried across byte for byte.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_after FROM mig1948_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       CASE i.op
         WHEN 'ma-climate-chair1' THEN '[migration 1948, 2026-10-26] Re-seated to Season 2 chair 1. The Act was read, not its name: Chapter 8 of the Acts of 2021, "An Act creating a next-generation roadmap for Massachusetts climate policy" (Senate Bill 9, signed 26 March 2021). Section 4(h): "The interim 2030 statewide greenhouse gas emissions limit shall be at least 50 per cent below the 1990 level", with 2040 at least 75 per cent. Section 3(b) requires a 2050 limit achieving "at least net zero statewide greenhouse gas emissions". Section 9 adds sector sublimits for electric power, transportation, heating and cooling, industrial processes and gas distribution. NO EMERGENCY IS DECLARED, NOTHING IS BANNED, AND NO FOSSIL FUEL IS PHASED OUT BY 2030 - so Season 1 chair 1 ("declare a climate emergency and ban all activities that increase carbon emissions") and chair 2 ("rapidly transition to renewable energy and phase out fossil fuels by 2030") are both false of a member whose evidence is this Act. Season 1 is closed, so the remedy is a Season 2 row, and by ADR 0006 it is read against the SEASON 2 ladder, which ranks instruments rather than ambition: chair 1 "Require a shift to clean energy through mandates and firm deadlines" is the Act''s spine - statutory limits with dates and sector sublimits. Chair 2 ("major subsidies, tax credits, and public investment") fails on the Act itself, which creates no significant tax credit and appropriates nothing; its offshore wind provisions are procurement duties on utilities, not public money. Chair 3 (permitting and the grid) is not its subject. Seated at Season 2 chair 1 - the same reading migration 1943 gave the Maryland Climate Solutions Now Act. The Season 1 answer is untouched and the original reasoning and every citation follow.

'
         WHEN 'ma-climate-chair1-miscited' THEN '[migration 1948, 2026-10-26] Re-seated to Season 2 chair 1. ⚠ AND THIS ROW CITES THE WRONG BILL: it gives the 2021 Climate Act as H.4933, but H.4933 of the 192nd General Court is "An Act relative to certain matters concerning municipal governance", which died in committee. The climate law is Senate Bill 9 of the same General Court, Chapter 8 of the Acts of 2021. The claim about what the member did is not doubted and the citation is left exactly as it was, because changing evidence is not this file''s job; the error is recorded here so it can be repaired by a citation pass. The Act was read, not its name: Chapter 8 of the Acts of 2021, "An Act creating a next-generation roadmap for Massachusetts climate policy" (Senate Bill 9, signed 26 March 2021). Section 4(h): "The interim 2030 statewide greenhouse gas emissions limit shall be at least 50 per cent below the 1990 level", with 2040 at least 75 per cent. Section 3(b) requires a 2050 limit achieving "at least net zero statewide greenhouse gas emissions". Section 9 adds sector sublimits for electric power, transportation, heating and cooling, industrial processes and gas distribution. NO EMERGENCY IS DECLARED, NOTHING IS BANNED, AND NO FOSSIL FUEL IS PHASED OUT BY 2030 - so Season 1 chair 1 ("declare a climate emergency and ban all activities that increase carbon emissions") and chair 2 ("rapidly transition to renewable energy and phase out fossil fuels by 2030") are both false of a member whose evidence is this Act. Season 1 is closed, so the remedy is a Season 2 row, and by ADR 0006 it is read against the SEASON 2 ladder, which ranks instruments rather than ambition: chair 1 "Require a shift to clean energy through mandates and firm deadlines" is the Act''s spine - statutory limits with dates and sector sublimits. Chair 2 ("major subsidies, tax credits, and public investment") fails on the Act itself, which creates no significant tax credit and appropriates nothing; its offshore wind provisions are procurement duties on utilities, not public money. Chair 3 (permitting and the grid) is not its subject. Seated at Season 2 chair 1 - the same reading migration 1943 gave the Maryland Climate Solutions Now Act. The Season 1 answer is untouched and the original reasoning and every citation follow.

'
       END || i.reasoning_before,
       i.sources_before
  FROM mig1948_ins i;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1948_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 1 AND pa.topic_revision_id = i.s2_revision;
  IF n <> 42 THEN RAISE EXCEPTION 'migration 1948: % of 42 inserted answers are at chair 1', n; END IF;

  SELECT count(*) INTO n FROM mig1948_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before OR strpos(pc.reasoning, i.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1948%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % row(s) lost prose, citations or notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED.
  SELECT count(*) INTO n FROM mig1948_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at
      OR pa.topic_revision_id <> i.s1_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % Season 1 answer(s) MOVED', n; END IF;
  SELECT count(*) INTO n FROM mig1948_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1948: % Season 1 context row(s) were rewritten', n; END IF;
END $$;

COMMIT;
