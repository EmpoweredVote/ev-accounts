-- 1694_resource_md_rollcall_verified.sql
--
-- Maryland pass 5: ROLL-CALL evidence for rows a sponsor list could never settle.
--
-- These rows claim the member "supported" / "backed" / "voted for" something. Mig 1685 deliberately left
-- them alone because they are not sponsorship claims. Maryland publishes each floor vote as a PDF, so each
-- row below now cites the bill page AND the vote sheet carrying the member's own name.
--
-- METHOD, and the guards that make it trustworthy:
--   * TENURE FIRST. A member who was not serving is simply absent from the sheet, so absence would read as
--     "did not support" when it means "was not there". Only in-tenure bills were read.
--   * PASSAGE VOTES ONLY. Most recorded votes are floor amendments; a Nay on a hostile amendment is not
--     opposition to the bill. Only "Third Reading(s) Passed", "Concurs" and "Overridden" were read.
--   * CHAMBER RESOLVED PER SESSION. Surnames collide across chambers (Alonzo Washington in the House and
--     Mary Washington in the Senate, same session), so the member's chamber for that year is derived from
--     their service history and a bare surname is never matched across chambers.
--   * THE PDF's OWN TALLIES ARE THE PARSE CHECK. Each sheet declares "95 Yeas 42 Nays 4 Absent"; a parse
--     that does not reproduce every count exactly is discarded, not guessed at.
--   * IDENTITY. A bare surname counts only when no disambiguated form ("Jones, D." / "Jones, R.") of that
--     surname appears in the same vote; otherwise the member's initial must select exactly one.
--   * DIRECTION. The polarity is read from the clause GOVERNING the instrument and must agree with the
--     recorded vote.
--
-- SCOPE: 91 rows. Citations only -- NO stance value modified.
--
-- NOT INCLUDED:
--   Brian M. Crosby / Climate Change -- a GENUINE CONTRADICTION: the stance says he "has supported the
--     Climate Solutions Now Act" and he voted NAY on 2022RS SB0528 (Third Reading Passed). Held for an
--     operator decision; this needs a reasoning correction or retirement, not a citation.
--   32 rows where no passage vote exists to read (the named bill died in committee -- SB0644/SB1000/
--     SB0915 have ZERO recorded votes), plus 1 ABSENT and 1 NOT_VOTING.
--   2 rows for the Speaker (Adrienne A. Jones): the presiding officer is listed as "Speaker", not by name,
--     so her own vote is not attributable by surname. UNKNOWN, never guessed.
--   29 PRE-TENURE rows: the named instrument predates the member's service entirely.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-rollcall-1694-rollback.json
--
BEGIN
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hayes02','https://ballotpedia.org/Antonio_Hayes']::text[]
WHERE politician_id = '04e1a744-acf5-4453-9172-7135b6bfce96'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Antonio Hayes / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/senate/0977.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Benjamin F. Kramer / Public Safety Approach — YEA on 2021RS SB0071 (Maryland Police Accountability Act of 2021 - Body-Worn Cameras, Employee Programs, and U

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Benjamin F. Kramer / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Benjamin F. Kramer / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Benjamin F. Kramer / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chisholm01','https://ballotpedia.org/Brian_Chisholm']::text[]
WHERE politician_id = 'cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Brian Chisholm / Climate Change and Environmental Protection — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/crosby01?tab=2026RS-legislation','https://ballotpedia.org/Brian_Crosby']::text[]
WHERE politician_id = '898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Brian M. Crosby / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire','https://ballotpedia.org/Bryan_Simonaire']::text[]
WHERE politician_id = '4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Bryan W. Simonaire / Climate Change and Environmental Protection — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — Senate 3/14/2022 3/02/2022 Third Reading Passed (32

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simonaire','https://ballotpedia.org/Bryan_Simonaire']::text[]
WHERE politician_id = '4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Bryan W. Simonaire / Taxation and Public Spending — NAY on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- C. T. Wilson / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- C. T. Wilson / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wilson','https://ballotpedia.org/C.T._Wilson']::text[]
WHERE politician_id = '69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- C. T. Wilson / Reproductive Rights and Abortion Access — YEA on 2022RS HB0937 (Abortion Care Access Act) — House 3/11/2022 3/05/2022 Third Reading Passed (89-47) 26 Cl

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0656?ys=2026RS','https://mgaleg.maryland.gov/2026RS/votes/house/1167.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01','https://ballotpedia.org/Chao_Wu']::text[]
WHERE politician_id = '7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Chao Wu / Civil Rights and Social Justice — YEA on 2026RS SB0656 (Public Health - Cosmetic Products - Enforcement and Penalties for Prohibited Ingredients

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Cheryl C. Kagan / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Cheryl C. Kagan / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Cheryl C. Kagan / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0656?ys=2026RS','https://mgaleg.maryland.gov/2026RS/votes/house/1167.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01','https://ballotpedia.org/Cheryl_Pasteur']::text[]
WHERE politician_id = 'b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Cheryl E. Pasteur / Civil Rights and Social Justice — YEA on 2026RS SB0656 (Public Health - Cosmetic Products - Enforcement and Penalties for Prohibited Ingredients

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/west02','https://ballotpedia.org/Chris_West_(Maryland)']::text[]
WHERE politician_id = 'fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Chris West / Climate Change and Environmental Protection — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — Senate 3/14/2022 3/02/2022 Third Reading Passed (32

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Cory V. McCray / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — Senate 3/14/2022 3/02/2022 Third Reading Passed (32

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Cory V. McCray / Fossil Fuel Policy — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — Senate 3/14/2022 3/02/2022 Third Reading Passed (32

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccray02','https://ballotpedia.org/Cory_McCray']::text[]
WHERE politician_id = '54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Cory V. McCray / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0656?ys=2026RS','https://mgaleg.maryland.gov/2026RS/votes/house/1167.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Courtney Watson / Civil Rights and Social Justice — YEA on 2026RS SB0656 (Public Health - Cosmetic Products - Enforcement and Penalties for Prohibited Ingredients

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Courtney Watson / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/attar02','https://ballotpedia.org/Dalya_Attar']::text[]
WHERE politician_id = 'fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dalya Attar / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Dana_Jones']::text[]
WHERE politician_id = 'd8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Dana Jones / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Dana Stein / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]
WHERE politician_id = 'e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Dana Stein / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/davis02','https://ballotpedia.org/Debra_Davis']::text[]
WHERE politician_id = '1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Debra Davis / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Edith J. Patterson / Reproductive Rights and Abortion Access — YEA on 2022RS HB0937 (Abortion Care Access Act) — House 3/11/2022 3/05/2022 Third Reading Passed (89-47) 26 Cl

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0656?ys=2026RS','https://mgaleg.maryland.gov/2026RS/votes/house/1167.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01','https://ballotpedia.org/Harry_Bhandari']::text[]
WHERE politician_id = '6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Harry Bhandari / Civil Rights and Social Justice — YEA on 2026RS SB0656 (Public Health - Cosmetic Products - Enforcement and Penalties for Prohibited Ingredients

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01','https://ballotpedia.org/Harry_Bhandari']::text[]
WHERE politician_id = '6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Harry Bhandari / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01','https://ballotpedia.org/Harry_Bhandari']::text[]
WHERE politician_id = '6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Harry Bhandari / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bhandari01','https://ballotpedia.org/Harry_Bhandari']::text[]
WHERE politician_id = '6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Harry Bhandari / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Heather Bagnall / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Heather Bagnall / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Heather Bagnall / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bagnall01','https://ballotpedia.org/Heather_Bagnall']::text[]
WHERE politician_id = '41749b94-11b8-4047-8421-95db0900d4b2'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Heather Bagnall / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01','https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]
WHERE politician_id = '0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jack Bailey / Taxation and Public Spending — NAY on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01','https://ballotpedia.org/Jen_Terrasa']::text[]
WHERE politician_id = 'f45e2178-2a05-4974-8af8-379662412060'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jen Terrasa / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01','https://ballotpedia.org/Jen_Terrasa']::text[]
WHERE politician_id = 'f45e2178-2a05-4974-8af8-379662412060'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Jen Terrasa / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01','https://ballotpedia.org/Jen_Terrasa']::text[]
WHERE politician_id = 'f45e2178-2a05-4974-8af8-379662412060'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jen Terrasa / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01','https://ballotpedia.org/Jessica_Feldmark']::text[]
WHERE politician_id = 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jessica Feldmark / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01','https://ballotpedia.org/Jessica_Feldmark']::text[]
WHERE politician_id = 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Jessica Feldmark / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01','https://ballotpedia.org/Jessica_Feldmark']::text[]
WHERE politician_id = 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jessica Feldmark / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Jim Rosapepe / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Jim Rosapepe / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Jim Rosapepe / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jim Rosapepe / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Joanne C. Benson / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0405.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Joanne C. Benson / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — Senate 3/14/2022 3/02/2022 Third Reading Passed (32

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Joanne C. Benson / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Joanne C. Benson / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Joanne C. Benson / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01','https://ballotpedia.org/Jon_Cardin']::text[]
WHERE politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jon S. Cardin / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01','https://ballotpedia.org/Jon_Cardin']::text[]
WHERE politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Jon S. Cardin / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01','https://ballotpedia.org/Jon_Cardin']::text[]
WHERE politician_id = '631dac5c-fb86-41f5-a82d-5963164a9142'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jon S. Cardin / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01','https://ballotpedia.org/Malcolm_Augustine']::text[]
WHERE politician_id = '9d191d69-084f-4941-bc0a-c59d336f032e'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Malcolm Augustine / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01','https://ballotpedia.org/Malcolm_Augustine']::text[]
WHERE politician_id = '9d191d69-084f-4941-bc0a-c59d336f032e'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Malcolm Augustine / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation','https://ballotpedia.org/Mark_Chang']::text[]
WHERE politician_id = '4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Mark S. Chang / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation','https://ballotpedia.org/Mark_Chang']::text[]
WHERE politician_id = '4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mark S. Chang / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation','https://ballotpedia.org/Mark_Chang']::text[]
WHERE politician_id = '4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Mark S. Chang / Reproductive Rights and Abortion Access — YEA on 2022RS HB0937 (Abortion Care Access Act) — House 3/11/2022 3/05/2022 Third Reading Passed (89-47) 26 Cl

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation','https://ballotpedia.org/Mark_Chang']::text[]
WHERE politician_id = '4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Mark S. Chang / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/carozza02','https://ballotpedia.org/Mary_Beth_Carozza']::text[]
WHERE politician_id = '9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Mary Beth Carozza / Reproductive Rights and Abortion Access — NAY on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Matthew Morgan / Climate Change and Environmental Protection — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Matthew Morgan / Fossil Fuel Policy — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/morgan02','https://ballotpedia.org/Matthew_Morgan_(Maryland)']::text[]
WHERE politician_id = 'c4e4d811-1e14-45fe-9335-7521f1603856'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Matthew Morgan / Reproductive Rights and Abortion Access — NAY on 2022RS HB0937 (Abortion Care Access Act) — House 3/11/2022 3/05/2022 Third Reading Passed (89-47) 26 Cl

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]
WHERE politician_id = '81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Nancy J. King / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0656?ys=2026RS','https://mgaleg.maryland.gov/2026RS/votes/house/1167.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ziegler01','https://ballotpedia.org/Natalie_Ziegler']::text[]
WHERE politician_id = '38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Natalie Ziegler / Civil Rights and Social Justice — YEA on 2026RS SB0656 (Public Health - Cosmetic Products - Enforcement and Penalties for Prohibited Ingredients

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Nick Charles / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Nick Charles / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/house/1047.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- Nick Charles / Police Accountability — YEA on 2021RS SB0071 (Maryland Police Accountability Act of 2021 - Body-Worn Cameras, Employee Programs, and U

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Nick Charles / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/charles02','https://ballotpedia.org/Nick_Charles']::text[]
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Nick Charles / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]
WHERE politician_id = '409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Pamela Beidle / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0890?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/senate/0738.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]
WHERE politician_id = '409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Pamela Beidle / Reproductive Rights and Abortion Access — YEA on 2022RS SB0890 (Abortion Care Access Act) — Senate 3/28/2022 3/15/2022 Third Reading Passed (30-14) 55 C

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/senate/0866.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]
WHERE politician_id = '409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Pamela Beidle / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — Senate 3/16/2020 3/12/2020 Third Rea

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Ron Watson / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Ron Watson / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Ron Watson / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Seth A. Howard / Climate Change and Environmental Protection — NAY on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/howard01','https://ballotpedia.org/Seth_Howard']::text[]
WHERE politician_id = '2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Seth A. Howard / Reproductive Rights and Abortion Access — NAY on 2022RS HB0937 (Abortion Care Access Act) — House 3/11/2022 3/05/2022 Third Reading Passed (89-47) 26 Cl

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Shaneka Henson / Childcare Affordability & Access — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Shaneka Henson / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2021RS','https://mgaleg.maryland.gov/2021RS/votes/house/1047.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- Shaneka Henson / Police Accountability — YEA on 2021RS SB0071 (Maryland Police Accountability Act of 2021 - Body-Worn Cameras, Employee Programs, and U

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Shaneka Henson / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/henson02','https://ballotpedia.org/Shaneka_Henson']::text[]
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Shaneka Henson / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/2022RS/votes/house/0795.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Terri L. Hill / Climate Change and Environmental Protection — YEA on 2022RS SB0528 (Climate Solutions Now Act of 2022) — House 3/29/2022 3/21/2022 Third Reading Passed with

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Terri L. Hill / School Vouchers & Public Education Funding — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1300?ys=2020RS','https://mgaleg.maryland.gov/2020RS/votes/house/0397.pdf','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]
WHERE politician_id = 'f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Terri L. Hill / Taxation and Public Spending — YEA on 2020RS HB1300 (Blueprint for Maryland''s Future - Implementation) — House 3/06/2020 3/06/2020 Third Read

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]
WHERE politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- Kriselda Valderrama / Deportation Priorities — sponsor of 2026 HB0444 "Public Safety - Immigration Enforcement Agreements - Prohibition" (the bare number had

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]
WHERE politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Kriselda Valderrama / Immigration and Treatment of Immigrants — sponsor of 2026 HB0444 "Public Safety - Immigration Enforcement Agreements - Prohibition" (the bare number had

DO $$
DECLARE bad int;
BEGIN
  -- every touched row must now cite a Legislation/Details page
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid)
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) lack a bill citation', bad; END IF;

  -- no duplicates introduced, nobody emptied
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('cfc704da-dd6c-40b0-97fa-0c5ece8d3976'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('898845f9-cb93-4162-b0ed-6842eacda5d6'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4aa50ee7-aeed-48ae-96e7-142bd9ac731b'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('69870c10-cea2-43c2-8cf9-bfcaf0b82265'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('7ced90a8-39dc-447e-ba33-e3af4cd47473'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('fc06c2bb-db76-43fa-8e2e-91a4c34e57ae'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('9b2fe9e6-21bf-4aee-b351-a841f3f382b9'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('c4e4d811-1e14-45fe-9335-7521f1603856'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('2fe3f655-c28e-40c3-a2f9-48ea9eb8b498'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid)
  ) AND (c.sources IS NULL OR cardinality(c.sources) = 0
         OR cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s));
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) empty or duplicated', bad; END IF;
END
$$;

COMMIT
;
