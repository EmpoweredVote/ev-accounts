-- 1763_wa_cohort_rent_and_climate.sql
-- Two instrument cohorts, applied after screening every member individually.
--
-- 34 rows rent-regulation = 2   (EHB 1217, Chapter 209, Laws of 2025)
-- 10 rows climate-change  = 3   (HB 2367, Chapter 37, Laws of 2026)
-- 44 rows total. Fitzgibbon is excluded from both: migration 1762 already seated him on the same
-- two instruments at the same two chairs, and re-inserting would violate the pre-check.
--
-- 🔑 WHY A COHORT IS LEGITIMATE HERE. The corpus rule is that the same instrument cannot seat two
-- co-sponsors in two different chairs, and a co-sponsorship counts as much as authorship. So once the
-- instrument is read, everyone who signed it is seated identically -- or the corpus contradicts
-- itself. The reasoning text differs only in "Prime sponsor" vs "Co-sponsor".
--
-- 🔴 THE COHORT WAS NOT APPLIED BLIND. Every member was screened for an instrument of their OWN that
-- would evidence a DIFFERENT chair on the same ladder, because a blanket write would otherwise bury a
-- stronger record under a shared default.
--
--   RENT: 19 distinct rent-related bills are touched by the 35 sponsors. Eleven members have their own
--   primary-sponsored one. NONE moves the chair -- they are self-storage units (HB 1907, HB 2240),
--   rental cars (HB 1986, HB 1431), aquatic land leases (HB 1758), state park leases (HB 1024),
--   short-term-rental cannabis and pools (HB 2639, HB 2465), rent-payment credit reporting (HB 1927),
--   landlord property-tax treatment (HB 1040, HB 2025), tenant home ownership (HB 2527), mobile-home
--   park sale notice (HB 1358) and extreme-heat habitability (HB 2265). None regulates rent LEVELS or
--   extends rent-cap COVERAGE, which is what chairs 2 through 5 discriminate on.
--   ⚠ The two genuine candidates were read in full rather than screened by title:
--     · HB 1915 "Strengthening tenant protections" (Simmons, Scott, Parshley, Pollet, Hill) amends the
--       just-cause eviction statutes (RCW 59.18.650 and others). Chair 1 requires rent control on ALL
--       rental units PLUS strong protections PLUS just-cause. This satisfies only the just-cause
--       element, and EHB 1217's own section 102 exemptions refute universal coverage for these same
--       members. It does not reach chair 1.
--     · HB 2699 "landlord-tenant relations" (Pollet, with Barkis) actually LOOSENS just-cause in
--       section 1(1)(c). It is still an eviction instrument, and chairs 2-5 are about rent-control
--       scope, so it cannot discriminate among them either.
--
--   CLIMATE: seven of the 11 sponsors have their own primary climate bill. Every one sits inside the
--   cap-and-invest / clean-energy-deployment frame -- CCA auction price containment (HB 1975), CCA
--   compliance obligations (HB 2215), CCA accounts (HB 2251), CCA waste-to-energy treatment (HB 2416),
--   emissions-intensive trade-exposed facilities (HB 2537), low-carbon thermal networks (HB 1514),
--   renewable energy tax policy (HB 1960), hydrofluorocarbons (HB 1462), embodied carbon in buildings
--   (HB 1458, HB 2273), livestock methane (HB 1630). NOT ONE sets a fossil-fuel phase-out date, which
--   is what chair 2 requires ("phase out fossil fuels by 2030"). Chair 3 holds for all 11, and
--   Fitzgibbon's four additional CCA instruments reinforce rather than disturb his 1762 seat.
--
-- 🔑 Identity is by legislature member ID throughout, joined through a linkage verified at 147/147
-- with zero unmatched and zero ambiguous. Surnames are never the key: the DB holds an Elizabeth
-- Fitzgibbon with her own answers, and Emily Alvarado sponsored EHB 1217 from the House but sits in
-- the Senate today, so a name+chamber key would have dropped the bill's PRIME sponsor.
--
-- Operator approved the chair-2 reading of EHB 1217 and the cohort-with-per-member-screen approach
-- on 2026-08-15.
BEGIN;

CREATE TEMP TABLE coh_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

-- Pre-check: none of these (politician, topic) pairs may already hold an answer or a context row.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6341053d-0580-4fbf-85ea-71ddb6b6f838' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Strom Peterson already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: My-Linh Thai already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ab474e84-9ab1-46b1-954b-f49f237498bb' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Darya Farivar already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d97bcc03-4c74-4c9d-9e0f-13ae551ed54c' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lillian Ortiz-Self already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ec9da15f-7d79-42bc-a368-da3ab0855ddf' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Berg already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='da15c353-3744-4dd3-a6ed-c4b6e89752e1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamila Taylor already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Timmons already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0381ded1-ac26-4700-8188-6ff06621d1be' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Tharinger already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Wylie already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0e5af9ca-165c-458c-8c65-a89aaf1a8d3e' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lauren Davis already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c176280e-d886-4b59-b812-e220449ffff1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Debra Lekanoff already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f4f7acdf-1761-4cac-82e6-19bf8f6ea525' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Bergquist already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e3e2c4be-bc12-43c3-9e86-4ba229d44346' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Monica Jurado Stonier already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has an answer on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has an answer on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has an answer on climate-change'; END IF;
END $$;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6341053d-0580-4fbf-85ea-71ddb6b6f838' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Strom Peterson already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: My-Linh Thai already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ab474e84-9ab1-46b1-954b-f49f237498bb' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Darya Farivar already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d97bcc03-4c74-4c9d-9e0f-13ae551ed54c' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lillian Ortiz-Self already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ec9da15f-7d79-42bc-a368-da3ab0855ddf' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Berg already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='da15c353-3744-4dd3-a6ed-c4b6e89752e1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamila Taylor already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Timmons already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0381ded1-ac26-4700-8188-6ff06621d1be' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Tharinger already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Wylie already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0e5af9ca-165c-458c-8c65-a89aaf1a8d3e' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lauren Davis already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c176280e-d886-4b59-b812-e220449ffff1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Debra Lekanoff already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f4f7acdf-1761-4cac-82e6-19bf8f6ea525' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Bergquist already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e3e2c4be-bc12-43c3-9e86-4ba229d44346' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Monica Jurado Stonier already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has a context row on rent-regulation'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has a context row on climate-change'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a context row on climate-change'; END IF;
END $$;

-- Pre-check: both chairs must be defined exactly once on their ladders.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: rent chair 2 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: climate chair 3 not defined exactly once (%)', n; END IF;
END $$;

-- Pre-check: every politician id must still resolve to the name it was screened under.
DO $$
DECLARE t text;
BEGIN
  SELECT full_name INTO t FROM essentials.politicians WHERE id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25';
  IF t <> 'Emily Alvarado' THEN
    RAISE EXCEPTION 'pre-check: 5a36591c-66c5-4cb1-b99d-d7fc7fa93b25 resolves to "%", expected Emily Alvarado', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='22d959a5-ec5f-4b92-98d3-85dc219c2c61';
  IF t <> 'Nicole Macri' THEN
    RAISE EXCEPTION 'pre-check: 22d959a5-ec5f-4b92-98d3-85dc219c2c61 resolves to "%", expected Nicole Macri', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='41ef42e8-fe56-4f82-92e7-eefe85232cd2';
  IF t <> 'Alex Ramel' THEN
    RAISE EXCEPTION 'pre-check: 41ef42e8-fe56-4f82-92e7-eefe85232cd2 resolves to "%", expected Alex Ramel', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='6341053d-0580-4fbf-85ea-71ddb6b6f838';
  IF t <> 'Strom Peterson' THEN
    RAISE EXCEPTION 'pre-check: 6341053d-0580-4fbf-85ea-71ddb6b6f838 resolves to "%", expected Strom Peterson', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='56d6dd6f-4959-4339-be78-e4b1d0083b08';
  IF t <> 'Liz Berry' THEN
    RAISE EXCEPTION 'pre-check: 56d6dd6f-4959-4339-be78-e4b1d0083b08 resolves to "%", expected Liz Berry', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='363fe07c-171e-4044-b6f9-979662962027';
  IF t <> 'Sharlett Mena' THEN
    RAISE EXCEPTION 'pre-check: 363fe07c-171e-4044-b6f9-979662962027 resolves to "%", expected Sharlett Mena', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='1963d6e9-069b-4770-9489-59e36faaa2e1';
  IF t <> 'My-Linh Thai' THEN
    RAISE EXCEPTION 'pre-check: 1963d6e9-069b-4770-9489-59e36faaa2e1 resolves to "%", expected My-Linh Thai', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='67b9aaf1-46eb-471f-8f31-dcf501a92933';
  IF t <> 'Julia Reed' THEN
    RAISE EXCEPTION 'pre-check: 67b9aaf1-46eb-471f-8f31-dcf501a92933 resolves to "%", expected Julia Reed', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='73ad3771-798c-4855-a467-7c6269bca5fc';
  IF t <> 'Edwin Obras' THEN
    RAISE EXCEPTION 'pre-check: 73ad3771-798c-4855-a467-7c6269bca5fc resolves to "%", expected Edwin Obras', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='ab474e84-9ab1-46b1-954b-f49f237498bb';
  IF t <> 'Darya Farivar' THEN
    RAISE EXCEPTION 'pre-check: ab474e84-9ab1-46b1-954b-f49f237498bb resolves to "%", expected Darya Farivar', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='30fdeba0-e9d3-414d-859f-2941140d8e80';
  IF t <> 'Lisa Parshley' THEN
    RAISE EXCEPTION 'pre-check: 30fdeba0-e9d3-414d-859f-2941140d8e80 resolves to "%", expected Lisa Parshley', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='d97bcc03-4c74-4c9d-9e0f-13ae551ed54c';
  IF t <> 'Lillian Ortiz-Self' THEN
    RAISE EXCEPTION 'pre-check: d97bcc03-4c74-4c9d-9e0f-13ae551ed54c resolves to "%", expected Lillian Ortiz-Self', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='805fd55e-2e38-43b1-8b9d-a757af05f8e4';
  IF t <> 'Julio Cortes' THEN
    RAISE EXCEPTION 'pre-check: 805fd55e-2e38-43b1-8b9d-a757af05f8e4 resolves to "%", expected Julio Cortes', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='f3daea18-1a32-486f-b8df-659d7c653c05';
  IF t <> 'Davina Duerr' THEN
    RAISE EXCEPTION 'pre-check: f3daea18-1a32-486f-b8df-659d7c653c05 resolves to "%", expected Davina Duerr', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='7a0da48f-2c29-463e-969a-52d06137cde9';
  IF t <> 'Chipalo Street' THEN
    RAISE EXCEPTION 'pre-check: 7a0da48f-2c29-463e-969a-52d06137cde9 resolves to "%", expected Chipalo Street', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='ec9da15f-7d79-42bc-a368-da3ab0855ddf';
  IF t <> 'April Berg' THEN
    RAISE EXCEPTION 'pre-check: ec9da15f-7d79-42bc-a368-da3ab0855ddf resolves to "%", expected April Berg', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='da15c353-3744-4dd3-a6ed-c4b6e89752e1';
  IF t <> 'Jamila Taylor' THEN
    RAISE EXCEPTION 'pre-check: da15c353-3744-4dd3-a6ed-c4b6e89752e1 resolves to "%", expected Jamila Taylor', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='45737b89-a83b-421f-9d6c-abc829c7eae0';
  IF t <> 'Beth Doglio' THEN
    RAISE EXCEPTION 'pre-check: 45737b89-a83b-421f-9d6c-abc829c7eae0 resolves to "%", expected Beth Doglio', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9';
  IF t <> 'Joe Timmons' THEN
    RAISE EXCEPTION 'pre-check: 7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9 resolves to "%", expected Joe Timmons', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='0381ded1-ac26-4700-8188-6ff06621d1be';
  IF t <> 'Steve Tharinger' THEN
    RAISE EXCEPTION 'pre-check: 0381ded1-ac26-4700-8188-6ff06621d1be resolves to "%", expected Steve Tharinger', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4';
  IF t <> 'Mary Fosse' THEN
    RAISE EXCEPTION 'pre-check: e36107af-ea8f-4fca-a727-0e37ca2f6fd4 resolves to "%", expected Mary Fosse', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='edc48d7e-4f91-4e59-af50-79f34df8b011';
  IF t <> 'Mia Gregerson' THEN
    RAISE EXCEPTION 'pre-check: edc48d7e-4f91-4e59-af50-79f34df8b011 resolves to "%", expected Mia Gregerson', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='370f9462-ed1d-4a83-b244-8bb593038444';
  IF t <> 'Tarra Simmons' THEN
    RAISE EXCEPTION 'pre-check: 370f9462-ed1d-4a83-b244-8bb593038444 resolves to "%", expected Tarra Simmons', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='5617115e-78d5-4480-9534-aa337612a285';
  IF t <> 'Sharon Wylie' THEN
    RAISE EXCEPTION 'pre-check: 5617115e-78d5-4480-9534-aa337612a285 resolves to "%", expected Sharon Wylie', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='fab8170e-a747-41de-ad39-769d8e0dd901';
  IF t <> 'Gerry Pollet' THEN
    RAISE EXCEPTION 'pre-check: fab8170e-a747-41de-ad39-769d8e0dd901 resolves to "%", expected Gerry Pollet', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='b918fb31-108f-49e7-b977-627ce667422d';
  IF t <> 'Shelley Kloba' THEN
    RAISE EXCEPTION 'pre-check: b918fb31-108f-49e7-b977-627ce667422d resolves to "%", expected Shelley Kloba', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='463c9085-ff29-45f4-88b0-fe3be9693a36';
  IF t <> 'Greg Nance' THEN
    RAISE EXCEPTION 'pre-check: 463c9085-ff29-45f4-88b0-fe3be9693a36 resolves to "%", expected Greg Nance', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='0e5af9ca-165c-458c-8c65-a89aaf1a8d3e';
  IF t <> 'Lauren Davis' THEN
    RAISE EXCEPTION 'pre-check: 0e5af9ca-165c-458c-8c65-a89aaf1a8d3e resolves to "%", expected Lauren Davis', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='945d0b44-3329-46b2-a39e-47f5fdddc6ed';
  IF t <> 'Timm Ormsby' THEN
    RAISE EXCEPTION 'pre-check: 945d0b44-3329-46b2-a39e-47f5fdddc6ed resolves to "%", expected Timm Ormsby', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='c176280e-d886-4b59-b812-e220449ffff1';
  IF t <> 'Debra Lekanoff' THEN
    RAISE EXCEPTION 'pre-check: c176280e-d886-4b59-b812-e220449ffff1 resolves to "%", expected Debra Lekanoff', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='f4f7acdf-1761-4cac-82e6-19bf8f6ea525';
  IF t <> 'Steve Bergquist' THEN
    RAISE EXCEPTION 'pre-check: f4f7acdf-1761-4cac-82e6-19bf8f6ea525 resolves to "%", expected Steve Bergquist', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='34ff9b7a-decc-4b21-8f6d-339957ab60bf';
  IF t <> 'Shaun Scott' THEN
    RAISE EXCEPTION 'pre-check: 34ff9b7a-decc-4b21-8f6d-339957ab60bf resolves to "%", expected Shaun Scott', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='e3e2c4be-bc12-43c3-9e86-4ba229d44346';
  IF t <> 'Monica Jurado Stonier' THEN
    RAISE EXCEPTION 'pre-check: e3e2c4be-bc12-43c3-9e86-4ba229d44346 resolves to "%", expected Monica Jurado Stonier', t; END IF;
  SELECT full_name INTO t FROM essentials.politicians WHERE id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6';
  IF t <> 'Natasha Hill' THEN
    RAISE EXCEPTION 'pre-check: 165640fd-99e3-4e1e-bd73-8df36e4ac1d6 resolves to "%", expected Natasha Hill', t; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Prime sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('363fe07c-171e-4044-b6f9-979662962027','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('1963d6e9-069b-4770-9489-59e36faaa2e1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('73ad3771-798c-4855-a467-7c6269bca5fc','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('ab474e84-9ab1-46b1-954b-f49f237498bb','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('30fdeba0-e9d3-414d-859f-2941140d8e80','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('f3daea18-1a32-486f-b8df-659d7c653c05','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('7a0da48f-2c29-463e-969a-52d06137cde9','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('da15c353-3744-4dd3-a6ed-c4b6e89752e1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('45737b89-a83b-421f-9d6c-abc829c7eae0','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('0381ded1-ac26-4700-8188-6ff06621d1be','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('edc48d7e-4f91-4e59-af50-79f34df8b011','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('370f9462-ed1d-4a83-b244-8bb593038444','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('5617115e-78d5-4480-9534-aa337612a285','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('b918fb31-108f-49e7-b977-627ce667422d','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('463c9085-ff29-45f4-88b0-fe3be9693a36','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('c176280e-d886-4b59-b812-e220449ffff1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('f4f7acdf-1761-4cac-82e6-19bf8f6ea525','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('e3e2c4be-bc12-43c3-9e86-4ba229d44346','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
 $r$Co-sponsor of EHB 1217 (Chapter 209, Laws of 2025), which caps annual rent increases at seven percent plus inflation, or 10 percent, whichever is less, and covers both regular rentals and manufactured or mobile home lots. Buildings under 12 years old and publicly owned or subsidised housing are exempt, so the cap is broad but not universal.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf']),
('45737b89-a83b-421f-9d6c-abc829c7eae0','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('363fe07c-171e-4044-b6f9-979662962027','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('30fdeba0-e9d3-414d-859f-2941140d8e80','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('b918fb31-108f-49e7-b977-627ce667422d','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('f3daea18-1a32-486f-b8df-659d7c653c05','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Co-sponsor of HB 2367 (Chapter 37, Laws of 2026), which ends a coal-fired power plant's exemption from Washington's cap-and-invest program and repeals its sales-and-use tax preferences. It reduces reliance on fossil fuels through a declining emissions cap and does not set a phase-out date.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('363fe07c-171e-4044-b6f9-979662962027','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('1963d6e9-069b-4770-9489-59e36faaa2e1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('73ad3771-798c-4855-a467-7c6269bca5fc','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('ab474e84-9ab1-46b1-954b-f49f237498bb','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('30fdeba0-e9d3-414d-859f-2941140d8e80','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('f3daea18-1a32-486f-b8df-659d7c653c05','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('7a0da48f-2c29-463e-969a-52d06137cde9','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('da15c353-3744-4dd3-a6ed-c4b6e89752e1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('45737b89-a83b-421f-9d6c-abc829c7eae0','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('0381ded1-ac26-4700-8188-6ff06621d1be','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('edc48d7e-4f91-4e59-af50-79f34df8b011','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('370f9462-ed1d-4a83-b244-8bb593038444','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('5617115e-78d5-4480-9534-aa337612a285','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('fab8170e-a747-41de-ad39-769d8e0dd901','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('b918fb31-108f-49e7-b977-627ce667422d','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('463c9085-ff29-45f4-88b0-fe3be9693a36','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('c176280e-d886-4b59-b812-e220449ffff1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('f4f7acdf-1761-4cac-82e6-19bf8f6ea525','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('e3e2c4be-bc12-43c3-9e86-4ba229d44346','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2),
('45737b89-a83b-421f-9d6c-abc829c7eae0','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('363fe07c-171e-4044-b6f9-979662962027','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('30fdeba0-e9d3-414d-859f-2941140d8e80','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('b918fb31-108f-49e7-b977-627ce667422d','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('f3daea18-1a32-486f-b8df-659d7c653c05','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3),
('fab8170e-a747-41de-ad39-769d8e0dd901','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3);

-- Guard 1: exactly 44 answers and 44 context rows appear, and nothing else moves.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM coh_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 44 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +44', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 44 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +44', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: every written row sits at the intended chair, carries the clause that REFUTES the
-- neighbouring chair, and cites the session law it was read from. Checked on content.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2'
     AND a.politician_id IN ('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','22d959a5-ec5f-4b92-98d3-85dc219c2c61','41ef42e8-fe56-4f82-92e7-eefe85232cd2','6341053d-0580-4fbf-85ea-71ddb6b6f838','56d6dd6f-4959-4339-be78-e4b1d0083b08','363fe07c-171e-4044-b6f9-979662962027','1963d6e9-069b-4770-9489-59e36faaa2e1','67b9aaf1-46eb-471f-8f31-dcf501a92933','73ad3771-798c-4855-a467-7c6269bca5fc','ab474e84-9ab1-46b1-954b-f49f237498bb','30fdeba0-e9d3-414d-859f-2941140d8e80','d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','805fd55e-2e38-43b1-8b9d-a757af05f8e4','f3daea18-1a32-486f-b8df-659d7c653c05','7a0da48f-2c29-463e-969a-52d06137cde9','ec9da15f-7d79-42bc-a368-da3ab0855ddf','da15c353-3744-4dd3-a6ed-c4b6e89752e1','45737b89-a83b-421f-9d6c-abc829c7eae0','7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9','0381ded1-ac26-4700-8188-6ff06621d1be','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','edc48d7e-4f91-4e59-af50-79f34df8b011','370f9462-ed1d-4a83-b244-8bb593038444','5617115e-78d5-4480-9534-aa337612a285','fab8170e-a747-41de-ad39-769d8e0dd901','b918fb31-108f-49e7-b977-627ce667422d','463c9085-ff29-45f4-88b0-fe3be9693a36','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','945d0b44-3329-46b2-a39e-47f5fdddc6ed','c176280e-d886-4b59-b812-e220449ffff1','f4f7acdf-1761-4cac-82e6-19bf8f6ea525','34ff9b7a-decc-4b21-8f6d-339957ab60bf','e3e2c4be-bc12-43c3-9e86-4ba229d44346','165640fd-99e3-4e1e-bd73-8df36e4ac1d6')
     AND (a.value <> 2
          OR c.reasoning !~ 'broad but not universal'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1217.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % rent row(s) wrong chair, missing scope clause, or missing source', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'
     AND a.politician_id IN ('45737b89-a83b-421f-9d6c-abc829c7eae0','56d6dd6f-4959-4339-be78-e4b1d0083b08','363fe07c-171e-4044-b6f9-979662962027','41ef42e8-fe56-4f82-92e7-eefe85232cd2','30fdeba0-e9d3-414d-859f-2941140d8e80','b918fb31-108f-49e7-b977-627ce667422d','f3daea18-1a32-486f-b8df-659d7c653c05','945d0b44-3329-46b2-a39e-47f5fdddc6ed','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','fab8170e-a747-41de-ad39-769d8e0dd901')
     AND (a.value <> 3
          OR c.reasoning !~ 'does not set a phase-out date'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2367.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % climate row(s) wrong chair, missing refutation clause, or missing source', bad; END IF;
END $$;

-- Guard 3: gate invariants unchanged. The ORPHAN_CONTEXT predicate is copied verbatim from the CI
-- gate -- migration 1735 shipped a guard asserting the OPPOSITE property and passed green.
DO $$
DECLARE orphans int; ans_wo_ctx int; rent_seated int; clim_seated int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  -- the full cohorts, including the Fitzgibbon rows 1762 wrote, must now be complete
  SELECT count(*) INTO rent_seated FROM inform.politician_answers
   WHERE topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND value=2
     AND politician_id IN ('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','22d959a5-ec5f-4b92-98d3-85dc219c2c61','41ef42e8-fe56-4f82-92e7-eefe85232cd2','6341053d-0580-4fbf-85ea-71ddb6b6f838','56d6dd6f-4959-4339-be78-e4b1d0083b08','363fe07c-171e-4044-b6f9-979662962027','1963d6e9-069b-4770-9489-59e36faaa2e1','67b9aaf1-46eb-471f-8f31-dcf501a92933','73ad3771-798c-4855-a467-7c6269bca5fc','ab474e84-9ab1-46b1-954b-f49f237498bb','30fdeba0-e9d3-414d-859f-2941140d8e80','d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','805fd55e-2e38-43b1-8b9d-a757af05f8e4','f3daea18-1a32-486f-b8df-659d7c653c05','7a0da48f-2c29-463e-969a-52d06137cde9','ec9da15f-7d79-42bc-a368-da3ab0855ddf','da15c353-3744-4dd3-a6ed-c4b6e89752e1','45737b89-a83b-421f-9d6c-abc829c7eae0','7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9','0381ded1-ac26-4700-8188-6ff06621d1be','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','edc48d7e-4f91-4e59-af50-79f34df8b011','370f9462-ed1d-4a83-b244-8bb593038444','5617115e-78d5-4480-9534-aa337612a285','fab8170e-a747-41de-ad39-769d8e0dd901','b918fb31-108f-49e7-b977-627ce667422d','463c9085-ff29-45f4-88b0-fe3be9693a36','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','945d0b44-3329-46b2-a39e-47f5fdddc6ed','c176280e-d886-4b59-b812-e220449ffff1','f4f7acdf-1761-4cac-82e6-19bf8f6ea525','34ff9b7a-decc-4b21-8f6d-339957ab60bf','e3e2c4be-bc12-43c3-9e86-4ba229d44346','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','9f914ddb-ba7c-4b30-b756-fe7cd981f919');
  IF rent_seated <> 35 THEN RAISE EXCEPTION 'guard 3: rent cohort is %, expected 35', rent_seated; END IF;

  SELECT count(*) INTO clim_seated FROM inform.politician_answers
   WHERE topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND value=3
     AND politician_id IN ('45737b89-a83b-421f-9d6c-abc829c7eae0','56d6dd6f-4959-4339-be78-e4b1d0083b08','363fe07c-171e-4044-b6f9-979662962027','41ef42e8-fe56-4f82-92e7-eefe85232cd2','30fdeba0-e9d3-414d-859f-2941140d8e80','b918fb31-108f-49e7-b977-627ce667422d','f3daea18-1a32-486f-b8df-659d7c653c05','945d0b44-3329-46b2-a39e-47f5fdddc6ed','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','fab8170e-a747-41de-ad39-769d8e0dd901','9f914ddb-ba7c-4b30-b756-fe7cd981f919');
  IF clim_seated <> 11 THEN RAISE EXCEPTION 'guard 3: climate cohort is %, expected 11', clim_seated; END IF;

  RAISE NOTICE 'cohorts seated: rent-regulation=2 x 35, climate-change=3 x 11; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
