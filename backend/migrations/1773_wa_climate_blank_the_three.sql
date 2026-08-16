-- 1773_wa_climate_blank_the_three.sql
-- OPERATOR RULING, 2026-08-15: blank the 3 climate-change chair-3 rows written by migration 1772
-- (Boehnke, Dozier, MacEwen) until the ladder has a chair for "keep the statutory emission targets,
-- but oppose new state-specific mandates". All nine Senate Republicans read in 1772 are now blanks.
--
-- The concern that prompted it, raised when 1772 was reported: seating these three at chair 3 put
-- them on the same rung as the eleven Democrats who wrote the cap-and-invest programme (migration
-- 1763), making the compass read as agreement between the two caucuses. 27 legislators at one chair
-- is the ladder absorbing the whole middle, not a finding about anyone's politics.
--
-- 🔑 WHY THIS IS NOT A REVERSAL OF MIGRATION 1771, which held that CONTRADICTION blanks a chair and
-- INCOMPLETENESS does not. Read the two together or a later session will "fix" one of them:
--   · In 1771, Davis and Nance ADDED co-response work alongside the police hiring they sponsored.
--     Chair 4 described part of their record and nothing in the record cut against it. Incomplete.
--   · Here the same members sponsored SB 5091, which REMOVES the state's principal vehicle
--     decarbonization requirement. Chair 3's second limb — "gradually reducing reliance on fossil
--     fuels" — is not merely unmentioned by that instrument; it is worked against by it. A voter
--     reading chair 3 would take it as a description of the member's climate approach, and the repeal
--     contradicts that description even though the investment half is real and documented.
-- Adding a mechanism leaves the chair true. Removing the mechanism the chair names does not.
--
-- ⚠ THE MECHANISM THIS MIGRATION HAS TO AVOID. Deleting the answer and leaving the context row alone
-- is exactly the pattern that manufactured the orphan-context class (three earlier passes made the
-- same mistake and none of them noticed): the row keeps prose asserting a chair that no longer
-- exists, and it silently joins ORPHAN_CONTEXT. So the reasoning is REWRITTEN into a documented blank
-- in the same transaction, and guard 3 asserts the orphan count is unchanged at 50 rather than 53.
--
-- Nothing about the underlying research is retracted. Each row still names every instrument that was
-- read and still carries its sources; what changes is that the row now records that the ladder could
-- not reach the position, which is the honest state of it.
BEGIN;

CREATE TEMP TABLE cc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke does not hold exactly one climate chair-3 answer (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke does not hold exactly one climate context row (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Perry Dozier does not hold exactly one climate chair-3 answer (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Perry Dozier does not hold exactly one climate context row (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Drew MacEwen does not hold exactly one climate chair-3 answer (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Drew MacEwen does not hold exactly one climate context row (%)', n; END IF;
END $$;

DELETE FROM inform.politician_answers
 WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id IN ('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','5ab349b4-f041-4637-af64-c4e6e4f54c3e');

UPDATE inform.politician_context
   SET reasoning = $r$Unable to place on this ladder. Prime sponsor of SB 6004 (public entities contracting for "renewable resource or nonemitting electric generation"), of SB 5991 (carbon capture, mineralization and sequestration under the clean energy transformation act, reciting the state's net-zero-by-2050 and 100%-nonemitting-by-2045 targets), and of SB 5036 (Chapter law, 2025), which requires annual greenhouse gas inventory reporting to create "accountability for achieving the emission reductions established in RCW 70A.45.020" — and also of SB 5091, which would bar the department of ecology from adopting California's motor vehicle emission standards. Chair 3 ("invest in clean energy while gradually reducing reliance on fossil fuels") describes the investment but not the repeal: SB 5091 would remove the state's principal vehicle decarbonization requirement, so "gradually reducing reliance on fossil fuels" does not describe this record as a whole. Chairs 1 and 2 are refuted for want of an emergency declaration or a phase-out date, chair 5 is refuted by SB 5091's own finding that decarbonizing transportation is "an important objective", and chair 4 requires the transition to be left to market forces, which an act directing ecology to adopt federal-consistent rules does not do. No chair describes supporting the statutory emission targets while opposing state-specific mandates.$r$,
       sources   = ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6004.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5991.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']
 WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec';

UPDATE inform.politician_context
   SET reasoning = $r$Unable to place on this ladder. Co-sponsor of SB 5208 (state loans for electric and hydrogen vehicles and charging infrastructure, solar, wind, geothermal, advanced nuclear, grid modernization and facility decarbonization, funding found "fundamental to helping Washington meet ... the emissions reductions established under RCW 70A.45.020"), of SB 5991, and of SB 5036 (Chapter law, 2025), which creates annual accountability for those statutory reductions — and also of SB 5091, which would bar adoption of California's motor vehicle emission standards. Chair 3 ("invest in clean energy while gradually reducing reliance on fossil fuels") describes the investment but not the repeal: SB 5091 would remove the state's principal vehicle decarbonization requirement, so "gradually reducing reliance on fossil fuels" does not describe this record as a whole. Chairs 1 and 2 are refuted for want of an emergency declaration or a phase-out date, chair 5 is refuted by SB 5091's own finding that decarbonizing transportation is "an important objective", and chair 4 requires the transition to be left to market forces, which an act directing ecology to adopt federal-consistent rules does not do. No chair describes supporting the statutory emission targets while opposing state-specific mandates.$r$,
       sources   = ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5208.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5991.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/Senate/5036.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']
 WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3';

UPDATE inform.politician_context
   SET reasoning = $r$Unable to place on this ladder. Prime sponsor of SB 5208, which would offer state loans for electric and hydrogen vehicles and charging infrastructure, solar, wind, geothermal and hydrogen equipment, advanced nuclear reactors, grid modernization and facility decarbonization, on the finding that the funding is "fundamental to helping Washington meet ... the emissions reductions established under RCW 70A.45.020" — and also of SB 5091, which would bar adoption of California's motor vehicle emission standards. Chair 3 ("invest in clean energy while gradually reducing reliance on fossil fuels") describes the investment but not the repeal: SB 5091 would remove the state's principal vehicle decarbonization requirement, so "gradually reducing reliance on fossil fuels" does not describe this record as a whole. Chairs 1 and 2 are refuted for want of an emergency declaration or a phase-out date, chair 5 is refuted by SB 5091's own finding that decarbonizing transportation is "an important objective", and chair 4 requires the transition to be left to market forces, which an act directing ecology to adopt federal-consistent rules does not do. No chair describes supporting the statutory emission targets while opposing state-specific mandates.$r$,
       sources   = ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5208.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5091.pdf']
 WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id='5ab349b4-f041-4637-af64-c4e6e4f54c3e';

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; nb int; total_blanks int;
BEGIN
  SELECT * INTO s FROM cc_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before - 3 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected -3', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before THEN
    RAISE EXCEPTION 'guard 1: context count changed % -> %, expected no change (rows are UPDATED, not deleted)', s.ctx_before, ctx_after; END IF;

  -- content: each of the three now reads as a documented blank, keeps its sources, and has no answer
  SELECT count(*) INTO nb
    FROM inform.politician_context c
   WHERE c.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND c.politician_id IN ('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','5ab349b4-f041-4637-af64-c4e6e4f54c3e')
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND c.reasoning ~ '70A.45.020'
     AND coalesce(cardinality(c.sources),0) >= 2
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nb <> 3 THEN RAISE EXCEPTION 'guard 2: % rewritten blank(s), expected 3', nb; END IF;

  SELECT count(*) INTO bad FROM inform.politician_answers
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND politician_id IN ('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','5ab349b4-f041-4637-af64-c4e6e4f54c3e');
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % answer row(s) survived the delete', bad; END IF;

  -- the whole SB 5091 cohort is now blank: the six from 1772 plus these three
  SELECT count(*) INTO total_blanks
    FROM inform.politician_context c
   WHERE c.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND c.reasoning ~ '^Unable to place on this ladder'
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF total_blanks <> 9 THEN RAISE EXCEPTION 'guard 2: % documented climate blanks, expected 9', total_blanks; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  -- the load-bearing guard: a delete-the-answer-keep-the-context edit would push this to 53
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50 — the rewritten rows must match the carve-out', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'climate-change: 3 chair-3 rows blanked; 9 documented blanks total; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
