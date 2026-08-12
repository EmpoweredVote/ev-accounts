-- 1707_resource_ma_affordable_homes_act.sql
-- Massachusetts Tier A -- re-source the "Affordable Homes Act" rows to the bill and the roll call.
--
-- EVIDENCE: 193rd General Court **H.4977**, "An Act relative to the Affordable Homes Act"
-- (Chapter 150 of the Acts of 2024). **Senate Roll Call #249**, "Question on passing the bill to be
-- enacted" -- an ENACTMENT vote, so the passage-only rule holds. Parse self-checked against the
-- sheet's own declared totals: YEAS 37/37, NAYS 2/2.
--
-- 🔑 MA IDENTITY IS SAFER THAN MD: the sheet prints "Surname, First M.", not a bare surname, so every
-- match here is on surname AND first name. No surname-only match was accepted.
--
-- ⚠ NEAR-UNANIMOUS: 37-2 in a 40-seat Senate. By the same rule that rejected Mary Lehman's 130-1
-- RELIEF Act vote, this cannot establish a DISTINCTIVE position. It is used for the narrower and
-- correct purpose: every row here CLAIMS the member supported the 2024 Affordable Homes Act, and the
-- roll call VERIFIES THAT CLAIM. The citation evidences the sentence, not the chair value.
--
-- ⚠ REASONING LEFT UNCHANGED. Some rows carry softer secondary claims (MBTA Communities compliance,
-- "championed funding") this citation does not support -- but unlike the pass-6d voucher clause,
-- those were never searched for, and NOT SEARCHED IS NOT NOT FOUND. Flagged in the record, not deleted.
--
-- NOT APPLIED (4 of the 21 rows citing this Act): Ronald Mariano and William J. Driscoll are House
-- members; Dylan A. Fernandes was a Representative in the 193rd; **Karen E. Spilka is Senate
-- President** and 37+2=39 of 40 seats, so the presiding officer is the one missing -- UNKNOWN, never
-- guessed, exactly as with the MD Speaker.
--
-- Rollback: backend/data/stance-retirement/2026-08-12-ma-affordable-homes-rollback.json
--
BEGIN
;

CREATE TEMP TABLE ma_aha_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/BPC0']::text[]
WHERE politician_id = '99457307-afa4-4045-aebf-06ee8b39d28f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Brendan P. Crighton — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/BET0']::text[]
WHERE politician_id = 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Bruce E. Tarr — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/jml0']::text[]
WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Jason M. Lewis — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/JBL0']::text[]
WHERE politician_id = '6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Joan B. Lovely — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/JFK0']::text[]
WHERE politician_id = '5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- John F. Keenan — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/JAC0']::text[]
WHERE politician_id = 'bd451748-111f-461d-9752-95e7c243769e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Julian A. Cyr — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/L%20M0']::text[]
WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Liz Miranda — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/LME0']::text[]
WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Lydia M. Edwards — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/MCM0']::text[]
WHERE politician_id = '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Mark C. Montigny — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/MDB0']::text[]
WHERE politician_id = '67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Michael D. Brady — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/MJR0']::text[]
WHERE politician_id = 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Michael J. Rodrigues — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/N_C0']::text[]
WHERE politician_id = '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Nick Collins — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/PDJ0']::text[]
WHERE politician_id = 'd40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Patricia D. Jehlen — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/PMO']::text[]
WHERE politician_id = 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Patrick M. O''Connor — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/PRF0']::text[]
WHERE politician_id = 'c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Paul R. Feeney — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/SND0']::text[]
WHERE politician_id = 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Sal N. DiDomenico — YEA

UPDATE inform.politician_context SET sources = ARRAY['https://malegislature.gov/Bills/193/H4977','https://malegislature.gov/RollCall/193/SenateRollCall249.pdf','https://malegislature.gov/Legislators/Profile/WNB0']::text[]
WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- William N. Brownsberger — YEA

-- Guard 1 (scoped to the touched rows): each must now cite both the bill and the roll call.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
    AND c.politician_id IN ('99457307-afa4-4045-aebf-06ee8b39d28f'::uuid, 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2'::uuid, 'a40f234e-1790-4b52-8670-090b6379eb03'::uuid, '6d8717ca-45f9-42cf-bd28-6786a50d254f'::uuid, '5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'bd451748-111f-461d-9752-95e7c243769e'::uuid, '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'::uuid, '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'::uuid, '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'::uuid, '67ea7814-b7aa-42de-aba8-2230c181d15a'::uuid, 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'::uuid, '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'::uuid, 'd40a0eda-36fc-4032-8382-20c76a36d6a6'::uuid, 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'::uuid, 'c435ab14-5d64-46e4-a59f-bba18ed483c9'::uuid, 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'::uuid, '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'::uuid)
    AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s = 'https://malegislature.gov/Bills/193/H4977')
      OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s = 'https://malegislature.gov/RollCall/193/SenateRollCall249.pdf'));
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % row(s) lack the bill or the roll call', bad;
  END IF;
END
$$;

-- Guard 2: citations only -- nothing created or deleted, measured against the in-transaction snapshot.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM ma_aha_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 2 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 2 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans;
  END IF;
  RAISE NOTICE 'ma-aha ok: context=% (unchanged) answers=% (unchanged) orphans=%', ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
