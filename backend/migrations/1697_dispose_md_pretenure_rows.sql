-- 1697_dispose_md_pretenure_rows.sql
--
-- The 29 PRE-TENURE Maryland rows. Operator instruction 2026-08-11.
--
-- Every row rests on an instrument that PREDATES the member's service, so the claim as written is
-- impossible, not merely unsourced. The Guzzone standard (migs 1690 vs 1692) decides the rest: search for
-- in-tenure evidence, re-source where the member's own record carries the chair, retire where it does not.
--
--   9 RE-SOURCED with corrected reasoning -- their own in-tenure bills carry the position
--  20 RETIRED -- no honest substitute
--
-- 🔑 ON-TOPIC BY VOCABULARY IS NOT ON-TOPIC BY RATIONALE, and this is where most of the work was. The
-- automated in-tenure search found a sponsorship for 21 of 29 rows; READING them showed 12 were vocabulary
-- collisions that cannot support the chair, so those rows count as having nothing:
--   "Nonpublic Schools - Corporal Punishment", "Student Elopement - Notice",
--   "Public and Nonpublic Schools - Bronchodilator Availability"    -> a SCHOOL VOUCHERS chair
--   "Income Tax Credit - Venison Donation", "Theatrical Production Tax Credit",
--   "Subtraction Modification for Classroom Supplies"               -> a PROGRESSIVE TAXATION chair
--   "Criminal Law - Fraud - Assisted Reproductive Treatment"        -> an ABORTION ACCESS chair
--   "Sales and Use Tax - Distribution of Cannabis Revenue"          -> a TAXATION chair
-- A narrow targeted credit does not pin "tax the wealthy", and fertility fraud is not abortion access.
--
-- 🔴 Retire = delete the ANSWER and the CONTEXT row; context alone leaves an orphan answer and trips
--    ANSWER_WITHOUT_CONTEXT (must be 0). NOBODY is emptied (asserted below).
-- Rollback -- the only surviving copy of the retired reasoning, sources and values, plus the list of
-- rejected vocabulary matches: backend/data/stance-retirement/2026-08-11-md-pretenure-1697-rollback.json
--
BEGIN
;

CREATE TEMP TABLE _1697_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total
;

-- ---------- 9 rows RE-SOURCED to the member's own in-tenure record ----------

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0155?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01','https://ballotpedia.org/Cheryl_Pasteur']::text[], reasoning = 'Sponsored HB0155 (2026) prohibiting face coverings for law enforcement officers; favors police accountability and transparency over enforcement-first approaches.'
WHERE politician_id = 'b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- RE-SOURCED Cheryl E. Pasteur / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[], reasoning = 'Co-sponsored HB0350 (2026), the Voting Rights Act of 2026 for counties and municipal corporations; supports expanding voting protections and local ballot access.'
WHERE politician_id = '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- RE-SOURCED Darrell Odom / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0350?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0280?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01','https://ballotpedia.org/Dawn_Gile']::text[], reasoning = 'Sponsored SB0350 (2023) altering the Child Care Scholarship Program and SB0280 (2023) on child care provider registration and licensing; backs expanded childcare access and subsidy programs.'
WHERE politician_id = 'ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- RE-SOURCED Dawn Gile / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0447?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0563?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/gile01','https://ballotpedia.org/Dawn_Gile']::text[], reasoning = 'Sponsored SB0447 (2025) on hospital procedures for emergency pregnancy-related medical conditions and SB0563 (2026) on confidentiality of medical records at crisis pregnancy clinics; supports reproductive healthcare access.'
WHERE politician_id = 'ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- RE-SOURCED Dawn Gile / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01','https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[], reasoning = 'Sponsored HB0572 (2026), the Climate Crimes Accountability Act, creating Attorney General authority and a climate accountability fund; favors aggressive climate action.'
WHERE politician_id = 'c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- RE-SOURCED Gabriel M. Moreno / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1341?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01','https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[], reasoning = 'Sponsored HB0444 (2026) prohibiting immigration enforcement agreements and HB1341 (2026) expanding sensitive locations and notification requirements for immigration enforcement; opposes state and local cooperation with federal immigration enforcement.'
WHERE politician_id = 'c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- RE-SOURCED Gabriel M. Moreno / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0664?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0402?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03','https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[], reasoning = 'Sponsored SB0664 (2026) prioritising child care providers in the Child Care Scholarship Program and SB0402 (2026) on residential child care programs; backs childcare subsidy expansion.'
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- RE-SOURCED Kevin M. Harris / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0930?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01','https://ballotpedia.org/Kim_Ross']::text[], reasoning = 'Sponsored HB0930 (2025) establishing the Public Health Abortion Grant Program; supports public funding for abortion access.'
WHERE politician_id = '5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- RE-SOURCED Kim Ross / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0641?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stinnett01']::text[], reasoning = 'Sponsored HB0350 (2026), the Voting Rights Act of 2026 for counties and municipal corporations, and HB0641 (2026) establishing a curbside voting pilot program; supports expanding ballot access.'
WHERE politician_id = '012af8f7-693a-4ddc-b0bc-953dae8d2bc2'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- RE-SOURCED Sean A. Stinnett / Voting Rights and Electoral Integrity

-- ---------- 20 rows RETIRED: claim impossible, no honest substitute ----------

DELETE FROM inform.politician_answers WHERE (politician_id, topic_id) IN (
  ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
)
;

DELETE FROM inform.politician_context WHERE (politician_id, topic_id) IN (
  ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
  ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
  ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
)
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _1697_before;
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - 20 THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -20'; END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - 20 THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -20'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_context WHERE (politician_id, topic_id) IN (
    ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % retired context row(s) survive', bad; END IF;

  -- no orphan answers anywhere
  SELECT count(*) INTO bad FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s) corpus-wide', bad; END IF;

  -- nobody emptied
  SELECT count(*) INTO bad FROM (VALUES ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid),('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid),('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid),('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid),('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid),('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid),('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid),('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid),('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid),('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid),('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid),('012af8f7-693a-4ddc-b0bc-953dae8d2bc2'::uuid)) AS v(pid)
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = v.pid);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) emptied', bad; END IF;

  -- every re-sourced row must carry a bill citation
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('012af8f7-693a-4ddc-b0bc-953dae8d2bc2'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % re-sourced row(s) lack a bill citation', bad; END IF;
END
$$;

COMMIT
;
