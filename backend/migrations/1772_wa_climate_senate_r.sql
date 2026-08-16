-- 1772_wa_climate_senate_r.sql
-- 3 rows on `climate-change` at chair 3, and 6 DOCUMENTED BLANKS on the same ladder.
-- All nine are Senate Republicans who held no compass row at all; the blanks are the point of this
-- migration as much as the answers are.
--
-- ── how this cohort was chosen, and why it did NOT become a cohort write ─────────────────────────
-- The 11 uncovered Senate Republicans were the largest remaining bucket. Ranked by reach, their
-- shared instruments were: SB 5854 (sexually violent predator placement — a county FAIR SHARE siting
-- bill, on-topic by vocabulary and no chair), SB 5323 (theft of first-responder equipment reclassified
-- as first degree — no findings at all, so judicial-criminal-justice chair 4 "think twice" and chair 5
-- "real consequences" cannot be told apart), SB 6236 (child dependency standards — no ladder), and
-- SB 5850 (initiative petition protections — the `voting-rights` ladder is about voter access and ID,
-- not petitions). Four duds in a row. SB 5091 was the fifth and it does reach the ladder — but not to
-- a single chair for everyone who signed it.
--
-- ── SB 5091 refutes three chairs and evidences NONE ──────────────────────────────────────────────
-- The act repeals RCW 70A.30.010, bars ecology from adopting California's motor vehicle emission
-- standards, and requires rules "consistent with the federal clean air act".
--   · chair 5 ("reject climate change policies and focus on economic growth instead") is REFUTED by
--     the act's own §1: "decarbonizing the transportation sector is achievable and an important
--     objective in Washington state", and it calls for "a more balanced approach ... for Washington's
--     transition to a carbon free transportation sector". 🔑 The lazy read — a Republican bill killing
--     an EV mandate must be chair 5, or at least chair 4 — is refuted by the instrument's own text.
--   · chairs 1 and 2 are refuted: no emergency declaration, no phase-out date.
--   · chair 3 needs INVESTMENT in clean energy. SB 5091 funds nothing; it is a repeal.
--   · chair 4 needs the transition left to MARKET FORCES. SB 5091 substitutes the federal standard for
--     California's and directs ecology to adopt rules — one regulator for another, not deregulation.
-- So the instrument sets no floor. Three members are seated on OTHER instruments of their own; the
-- six whose entire climate record is SB 5091 plus narrow carve-outs are blanked.
--
-- ── chair 3, on the compound-chair pattern of migration 1769 ─────────────────────────────────────
-- Chair 3 is "invest in clean energy while gradually reducing reliance on fossil fuels" — two limbs,
-- and each of the three seated members holds both:
--   · Boehnke — SB 6004 (public entities contracting for renewable and nonemitting generation) and
--     SB 5991 (carbon capture under the clean energy transformation act) supply the investment limb;
--     SB 5036, enacted, supplies the reduction limb by creating annual accountability for the
--     statutory targets in RCW 70A.45.020.
--   · MacEwen — SB 5208 supplies BOTH limbs in one instrument: loans for EVs and charging, solar,
--     wind, geothermal, hydrogen, advanced nuclear and grid modernization, on the express finding that
--     the funding is "fundamental to helping Washington meet ... the emissions reductions established
--     under RCW 70A.45.020".
--   · Dozier — co-sponsor of SB 5208, SB 5991 and SB 5036. Co-sponsorship counts as much as
--     authorship.
-- Chair 2 is refuted for all three: SB 5991 recites a net-zero-by-2050 and 100%-nonemitting-by-2045
-- schedule, which is gradual reduction, not a phase-out by 2030.
--
-- ── the six blanks ───────────────────────────────────────────────────────────────────────────────
-- Gildon, Holy, Muzzall, Schoesler, Short and Harris. Their complete climate records were listed:
-- SB 5091, plus carve-outs from the cap-and-invest program (lubricant emissions, farm fuel payments,
-- waste-to-energy facilities, school district renewable requirements), plus SB 5036 for Short and
-- Harris. A carve-out from a program is not an investment and not a repeal; SB 5036 is the reduction
-- limb without the investment limb. Every chair fails for a stated reason, so the row records that
-- the ladder was tried and could not reach them — not that nobody looked.
-- ⚠ The carve-out bills were identified by title and NOT read in full; nothing here rests on them.
-- The refutations rest on SB 5091 and SB 5036, both read.
--
-- 🔴 FOR THE LADDER OWNER: 27 Washington legislators now sit at climate chair 3 — 11 Democrats from
-- cap-and-invest bills (migration 1763) and 3 Republicans here — while a further 6 Republicans cannot
-- be placed at all. The ladder has no chair for "keep the statutory emission targets, but by federal
-- rather than state-specific mandates, and without new spending", which is the modal minority-party
-- position in this state. Logged in COMPASS-LADDER-TROUBLE-SPOTS.md.
BEGIN;

CREATE TEMP TABLE cc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Perry Dozier already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Perry Dozier already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Drew MacEwen already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Drew MacEwen already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d997402c-ee18-4544-b770-ac13a777b601' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Gildon already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d997402c-ee18-4544-b770-ac13a777b601' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Gildon already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d0350f2f-6463-452e-b97d-c18ea094e2ee' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Holy already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d0350f2f-6463-452e-b97d-c18ea094e2ee' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Holy already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f183194f-814a-43c6-858e-11fc66ad5d41' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Ron Muzzall already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f183194f-814a-43c6-858e-11fc66ad5d41' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Ron Muzzall already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f893ae5d-6659-40cd-a874-e9351efcdb95' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Schoesler already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f893ae5d-6659-40cd-a874-e9351efcdb95' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Schoesler already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a88093ad-c483-49c1-ae1e-9f851cdb53fc' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelly Short already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a88093ad-c483-49c1-ae1e-9f851cdb53fc' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelly Short already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c4e1312c-e746-483e-a3ec-f27bc40b6d26' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Paul Harris already has a climate-change answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c4e1312c-e746-483e-a3ec-f27bc40b6d26' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Paul Harris already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: climate-change chair 3 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND topic_key='climate-change' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: climate-change topic is not live/active'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Prime sponsor of SB 6004, which lets cities, towns and public utility districts contract for the capability of "renewable resource or nonemitting electric generation" projects on the finding that "meeting Washington's clean energy goals will require local governments and other public entities to have greater flexibility for investing in new electric generation"; of SB 5991, which extends carbon capture, mineralization and sequestration under the clean energy transformation act while reciting the state's targets of 95 percent below 1990 levels and net-zero by 2050 and 100 percent nonemitting electricity by 2045; and of SB 5036 (Chapter law, 2025), which requires annual greenhouse gas inventory reporting to create "accountability for achieving the emission reductions established in RCW 70A.45.020". He also sponsored SB 5091, which would bar adoption of California's vehicle emission standards while finding decarbonizing transportation "an important objective" — a gradual reduction rather than a phase-out.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6004.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5991.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of SB 5208, which would offer state loans for electric and hydrogen vehicles and charging infrastructure, solar, wind, geothermal and hydrogen equipment, advanced nuclear reactors, grid modernization and facility decarbonization, on the finding that this funding "is fundamental to helping Washington meet the obligations set forth in the state's environmental policies including ... the emissions reductions established under RCW 70A.45.020"; of SB 5991 (carbon capture and sequestration under the clean energy transformation act); and of SB 5036 (Chapter law, 2025), which creates annual accountability for those same statutory emission reductions. He also sponsored SB 5091, which would bar adoption of California's vehicle emission standards while affirming decarbonization as "an important objective".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5208.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5991.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('5ab349b4-f041-4637-af64-c4e6e4f54c3e','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Prime sponsor of SB 5208, which would offer state loans for electric and hydrogen vehicles and charging infrastructure, solar, wind, geothermal and hydrogen equipment, advanced nuclear reactors, grid modernization and facility decarbonization, on the finding that this funding "is fundamental to helping Washington meet the obligations set forth in the state's environmental policies including ... the emissions reductions established under RCW 70A.45.020". He also sponsored SB 5091, which would bar adoption of California's vehicle emission standards while finding that "decarbonizing the transportation sector is achievable and an important objective" — clean energy investment paired with gradual reduction rather than a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5208.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('d997402c-ee18-4544-b770-ac13a777b601','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('d0350f2f-6463-452e-b97d-c18ea094e2ee','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('f183194f-814a-43c6-858e-11fc66ad5d41','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('f893ae5d-6659-40cd-a874-e9351efcdb95','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']),
('a88093ad-c483-49c1-ae1e-9f851cdb53fc','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position. Also sponsored SB 5036 (Chapter law, 2025), which moves the state to annual greenhouse gas inventory reporting to create "accountability for achieving the emission reductions established in RCW 70A.45.020" — chair 3's reduction half without its investment half.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf']),
('c4e1312c-e746-483e-a3ec-f27bc40b6d26','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Sponsored SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards and instead requires rules consistent with the federal clean air act, while finding that "decarbonizing the transportation sector is achievable and an important objective in Washington state" and that a "more balanced approach" is needed for the state's "transition to a carbon free transportation sector". Those findings refute chair 5, which rejects climate policy outright, and the absence of any emergency declaration or phase-out date refutes chairs 1 and 2. Chair 3 requires investment in clean energy, and this instrument funds nothing. Chair 4 requires the transition to be left to market forces, and this instrument substitutes one regulatory standard for another rather than removing regulation. No chair describes the position. Also sponsored SB 5036 (Chapter law, 2025), which moves the state to annual greenhouse gas inventory reporting to create "accountability for achieving the emission reductions established in RCW 70A.45.020" — chair 3's reduction half without its investment half.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf']);

-- answers for the three seated members only; the six blanks get NO answer row, deliberately
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('5ab349b4-f041-4637-af64-c4e6e4f54c3e','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM cc_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 3 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +3', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 9 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +9', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c3 int; nb int;
BEGIN
  -- seated side: chair 3, the investment limb named, at least two instruments cited
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND a.politician_id IN ('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','5ab349b4-f041-4637-af64-c4e6e4f54c3e')
     AND (a.value <> 3
          OR c.reasoning !~ '70A.45.020'
          OR coalesce(cardinality(c.sources),0) < 2);
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % seated row(s) wrong chair, missing the statutory-target citation, or under-sourced', bad; END IF;

  SELECT count(*) INTO c3 FROM inform.politician_answers
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3 AND politician_id IN ('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','5ab349b4-f041-4637-af64-c4e6e4f54c3e');
  IF c3 <> 3 THEN RAISE EXCEPTION 'guard 2: chair-3 count is %, expected 3', c3; END IF;

  -- blank side: asserted SEPARATELY, because a bug that seated everyone would still satisfy a
  -- total-count guard. Each blank must have a context row, NO answer, the carve-out phrase, and a source.
  SELECT count(*) INTO nb
    FROM inform.politician_context c
   WHERE c.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND c.politician_id IN ('d997402c-ee18-4544-b770-ac13a777b601','d0350f2f-6463-452e-b97d-c18ea094e2ee','f183194f-814a-43c6-858e-11fc66ad5d41','f893ae5d-6659-40cd-a874-e9351efcdb95','a88093ad-c483-49c1-ae1e-9f851cdb53fc','c4e1312c-e746-483e-a3ec-f27bc40b6d26')
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND coalesce(cardinality(c.sources),0) > 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nb <> 6 THEN RAISE EXCEPTION 'guard 2: % documented blank(s), expected 6', nb; END IF;

  SELECT count(*) INTO bad FROM inform.politician_answers
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id IN ('d997402c-ee18-4544-b770-ac13a777b601','d0350f2f-6463-452e-b97d-c18ea094e2ee','f183194f-814a-43c6-858e-11fc66ad5d41','f893ae5d-6659-40cd-a874-e9351efcdb95','a88093ad-c483-49c1-ae1e-9f851cdb53fc','c4e1312c-e746-483e-a3ec-f27bc40b6d26');
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % blank member(s) got an answer row', bad; END IF;
END $$;

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
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50 (the blanks must match the carve-out, not add to it)', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'climate-change: 3 at chair 3, 6 documented blanks; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
