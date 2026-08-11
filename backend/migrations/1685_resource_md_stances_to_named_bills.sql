-- 1685_resource_md_stances_to_named_bills.sql
-- Maryland single-source queue, pass 4: re-source stances to the bills they already name.
--
-- WHY: every row below cited only a generic mgaleg MEMBER page, which carries ONE session and so
-- cannot support a per-topic position. Each row's reasoning names a specific Maryland Act; that Act
-- was resolved against a local corpus of 73,232 bills (2013RS-2026RS) built from the MGA session
-- indexes, and the legislator's OWN mgaleg slug was then found in that bill's "Sponsored by" list.
--
-- SCOPE: 150 rows across 50 legislators. Citations only -- NO stance value is modified.
-- NOT INCLUDED: 32 surname-only matches (Maryland has same-surname legislators; needs a human),
-- 157 rows with no sponsor link (may still be true via a floor vote -- UNVERIFIED, never false),
-- 569 rows naming no instrument at all.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-bill-resource-rollback.json
--
BEGIN
;

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones01','https://ballotpedia.org/Adrienne_A._Jones']::text[]
WHERE politician_id = '760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Adrienne A. Jones / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]
WHERE politician_id = 'fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Aletheia McCaskill / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]
WHERE politician_id = 'fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Aletheia McCaskill / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1194?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0905?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0624?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/mccaskill01']::text[]
WHERE politician_id = 'fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Aletheia McCaskill / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]
WHERE politician_id = 'b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Andre V. Johnson, Jr. / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]
WHERE politician_id = 'b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Andre V. Johnson, Jr. / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]
WHERE politician_id = 'b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Andre V. Johnson, Jr. / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/johnson02']::text[]
WHERE politician_id = 'b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Andre V. Johnson, Jr. / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid
;  -- Arthur Ellis / Childcare Affordability & Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Arthur Ellis / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Arthur Ellis / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1030?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ellis01']::text[]
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Arthur Ellis / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kramer02','https://ballotpedia.org/Benjamin_Kramer']::text[]
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Benjamin F. Kramer / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/forbes01']::text[]
WHERE politician_id = 'c017b328-4469-45c4-aa8a-7b9035c77e22'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Catherine M. Forbes / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0383?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0445?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]
WHERE politician_id = '92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Caylin Young / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0387?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0197?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/young05']::text[]
WHERE politician_id = '92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Caylin Young / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Cheryl C. Kagan / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kagan01','https://ballotpedia.org/Cheryl_C._Kagan']::text[]
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Cheryl C. Kagan / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Courtney_Watson']::text[]
WHERE politician_id = 'a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Courtney Watson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]
WHERE politician_id = '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Darrell Odom / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0832?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]
WHERE politician_id = '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- Darrell Odom / Deportation Priorities

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1081?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]
WHERE politician_id = '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Darrell Odom / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1477?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/odom01?tab=2026RS-legislation']::text[]
WHERE politician_id = '0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Darrell Odom / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]
WHERE politician_id = 'a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Deni Taveras / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0865?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0445?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/taveras01']::text[]
WHERE politician_id = 'a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid
;  -- Deni Taveras / Medicare / Medicaid

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]
WHERE politician_id = '192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Diana M. Fennell / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0540?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]
WHERE politician_id = '192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Diana M. Fennell / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fennell01']::text[]
WHERE politician_id = '192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Diana M. Fennell / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson03?tab=2026RS-legislation','https://ballotpedia.org/Edith_Patterson']::text[]
WHERE politician_id = 'b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Edith J. Patterson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0629?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]
WHERE politician_id = '03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Elizabeth Embry / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]
WHERE politician_id = '03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Elizabeth Embry / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]
WHERE politician_id = '03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Elizabeth Embry / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0083?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/embry01']::text[]
WHERE politician_id = '03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Elizabeth Embry / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1057?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]
WHERE politician_id = '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid
;  -- Eric Ebersole / Artificial Intelligence Oversight

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]
WHERE politician_id = '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Eric Ebersole / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1222?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1341?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]
WHERE politician_id = '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- Eric Ebersole / Deportation Priorities

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]
WHERE politician_id = '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Eric Ebersole / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1222?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1341?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ebersole01']::text[]
WHERE politician_id = '22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Eric Ebersole / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0779?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/bailey01','https://ballotpedia.org/Jack_Bailey_(Maryland)']::text[]
WHERE politician_id = '0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jack Bailey / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]
WHERE politician_id = '01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Jackie Addison / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0687?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]
WHERE politician_id = '01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Jackie Addison / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0624?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/addison01']::text[]
WHERE politician_id = '01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Jackie Addison / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]
WHERE politician_id = '916afe40-4061-476f-9a54-b271b32778d2'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Jamila J. Woods / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0382?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]
WHERE politician_id = '916afe40-4061-476f-9a54-b271b32778d2'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Jamila J. Woods / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1251?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/woods01?tab=2026RS-legislation']::text[]
WHERE politician_id = '916afe40-4061-476f-9a54-b271b32778d2'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Jamila J. Woods / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0779?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/gallion01','https://ballotpedia.org/Jason_Gallion']::text[]
WHERE politician_id = 'e2ca1bfd-255d-417b-a9d7-424e6c10749d'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jason C. Gallion / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0565?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]
WHERE politician_id = '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Jeffrie E. Long, Jr. / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]
WHERE politician_id = '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jeffrie E. Long, Jr. / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1494?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]
WHERE politician_id = '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Jeffrie E. Long, Jr. / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0556?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]
WHERE politician_id = '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Jeffrie E. Long, Jr. / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0499?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/long02?tab=2026RS-legislation']::text[]
WHERE politician_id = '70f63959-f51d-4411-adc1-f1c429bbc397'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Jeffrie E. Long, Jr. / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01','https://ballotpedia.org/Jen_Terrasa']::text[]
WHERE politician_id = 'f45e2178-2a05-4974-8af8-379662412060'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Jen Terrasa / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0626?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01','https://ballotpedia.org/Jessica_Feldmark']::text[]
WHERE politician_id = 'fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Jessica Feldmark / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosapepe','https://ballotpedia.org/Jim_Rosapepe']::text[]
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Jim Rosapepe / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0166?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid
;  -- Joanne C. Benson / Police Accountability

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0166?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/benson','https://ballotpedia.org/Joanne_Benson']::text[]
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Joanne C. Benson / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0741?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]
WHERE politician_id = '656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Joshua J. Stonko / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1633?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0799?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]
WHERE politician_id = '656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Joshua J. Stonko / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0741?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stonko01']::text[]
WHERE politician_id = '656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Joshua J. Stonko / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Julian Ivey / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1317?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023'::uuid
;  -- Julian Ivey / Artificial Intelligence Oversight

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Julian Ivey / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Julian Ivey / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Julian Ivey / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0987?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ivey01']::text[]
WHERE politician_id = '69bf6043-4546-4804-ae04-311cff54a986'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Julian Ivey / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0894?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]
WHERE politician_id = '5946ad0c-ddf5-4674-840e-6968105042cd'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Karen Simpson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]
WHERE politician_id = '5946ad0c-ddf5-4674-840e-6968105042cd'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Karen Simpson / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1575?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]
WHERE politician_id = '5946ad0c-ddf5-4674-840e-6968105042cd'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- Karen Simpson / Deportation Priorities

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/simpson01']::text[]
WHERE politician_id = '5946ad0c-ddf5-4674-840e-6968105042cd'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Karen Simpson / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Kathy Szeliga / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1258?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Kathy Szeliga / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1624?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0737?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0737?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1027?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Kathy Szeliga / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0201?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Kathy Szeliga / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Kathy Szeliga / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/szeliga']::text[]
WHERE politician_id = '0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Kathy Szeliga / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0894?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]
WHERE politician_id = 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Kenneth Kerr / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0897?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]
WHERE politician_id = 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Kenneth Kerr / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1150?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1109?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]
WHERE politician_id = 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;  -- Kenneth Kerr / Healthcare Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/kerr01']::text[]
WHERE politician_id = 'c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Kenneth Kerr / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1533?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01','https://ballotpedia.org/Kim_Ross']::text[]
WHERE politician_id = '5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Kim Ross / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0935?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0387?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0197?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]
WHERE politician_id = 'dfb9ae21-4605-4c58-94e8-84b1eb1a30c1'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Kris Fair / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0993?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]
WHERE politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Kriselda Valderrama / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation']::text[]
WHERE politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Kriselda Valderrama / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Lauren Arikan / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1258?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Lauren Arikan / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0885?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Lauren Arikan / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0201?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Lauren Arikan / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Lauren Arikan / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/arikan01']::text[]
WHERE politician_id = '6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Lauren Arikan / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01','https://ballotpedia.org/Malcolm_Augustine']::text[]
WHERE politician_id = '9d191d69-084f-4941-bc0a-c59d336f032e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Malcolm Augustine / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/augustine01','https://ballotpedia.org/Malcolm_Augustine']::text[]
WHERE politician_id = '9d191d69-084f-4941-bc0a-c59d336f032e'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Malcolm Augustine / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Mark Edelson / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0836?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0084?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0437?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mark Edelson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0832?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid
;  -- Mark Edelson / Deportation Priorities

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0832?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;  -- Mark Edelson / Immigration and Treatment of Immigrants

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0634?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01']::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Mark Edelson / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mark N. Fisher / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Mark N. Fisher / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1258?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Mark N. Fisher / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1624?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0737?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0737?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1027?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Mark N. Fisher / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0201?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Mark N. Fisher / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Mark N. Fisher / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/fisher?tab=2026RS-legislation']::text[]
WHERE politician_id = '71542618-59c8-4b06-a765-e3df60cca763'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Mark N. Fisher / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01','https://ballotpedia.org/Mary_Washington']::text[]
WHERE politician_id = '38404814-7be0-40e3-b044-062f98b2a5b0'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Mary Washington / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0548?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/schindler01']::text[]
WHERE politician_id = '18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Matthew J. Schindler / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]
WHERE politician_id = '409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Pamela Beidle / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0414?ys=2021RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]
WHERE politician_id = '409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Pamela Beidle / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/boyce01']::text[]
WHERE politician_id = '027a2610-1160-4525-a5c1-469fe85d46e1'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Regina T. Boyce / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0319?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0449?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- Ric Metzgar / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Ric Metzgar / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1472?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0067?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid
;  -- Ric Metzgar / Religious Freedom

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Ric Metzgar / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0741?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Ric Metzgar / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/metzgar01']::text[]
WHERE politician_id = 'ba85b633-32cf-4617-923c-3a325f39894e'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Ric Metzgar / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1073?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]
WHERE politician_id = '9285f590-79b5-48de-a1c0-a022629e6ebb'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;  -- Robbyn Lewis / Affordable Housing

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1396?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1550?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]
WHERE politician_id = '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;  -- Robin L. Grammer, Jr. / Economic Development Incentives

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1258?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]
WHERE politician_id = '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Robin L. Grammer, Jr. / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0201?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]
WHERE politician_id = '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Robin L. Grammer, Jr. / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]
WHERE politician_id = '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Robin L. Grammer, Jr. / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/grammer01']::text[]
WHERE politician_id = '0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Robin L. Grammer, Jr. / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Ron Watson / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Ryan Nawrocki / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1258?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0974?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Ryan Nawrocki / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0737?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1027?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1180?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1039?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;  -- Ryan Nawrocki / School Vouchers & Public Education Funding

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1005?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0201?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Ryan Nawrocki / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0047?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0156?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0063?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid
;  -- Ryan Nawrocki / Transgender Athletes

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/nawrocki01']::text[]
WHERE politician_id = 'f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Ryan Nawrocki / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]
WHERE politician_id = 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Sheila Ruth / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0572?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]
WHERE politician_id = 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Sheila Ruth / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1359?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]
WHERE politician_id = 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Sheila Ruth / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1112?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1109?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0642?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0499?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruth01']::text[]
WHERE politician_id = 'df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Sheila Ruth / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0465?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]
WHERE politician_id = '848ac881-004b-436a-9a17-dfacbd33de5a'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Stephanie Smith / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0084?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]
WHERE politician_id = '848ac881-004b-436a-9a17-dfacbd33de5a'::uuid AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid
;  -- Stephanie Smith / Criminal Justice Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1104?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0800?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/smith03']::text[]
WHERE politician_id = '848ac881-004b-436a-9a17-dfacbd33de5a'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Stephanie Smith / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Terry L. Baker / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- Terry L. Baker / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- Terry L. Baker / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0885?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- Terry L. Baker / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- Terry L. Baker / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0741?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1101?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0690?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Terry L. Baker / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/baker04']::text[]
WHERE politician_id = 'd049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- Terry L. Baker / Voting Rights and Electoral Integrity

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;  -- Veronica Turner / Civil Rights and Social Justice

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0345?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- Veronica Turner / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1479?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation']::text[]
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
;  -- Veronica Turner / Taxation and Public Spending

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
;  -- William Valentine / Climate Change and Environmental Protection

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0673?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;  -- William Valentine / Fossil Fuel Policy

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0475?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid
;  -- William Valentine / Public Safety Approach

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1186?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0885?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;  -- William Valentine / Reproductive Rights and Abortion Access

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
;  -- William Valentine / State Redistricting and Gerrymandering

UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0454?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0964?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/valentine01']::text[]
WHERE politician_id = 'cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;  -- William Valentine / Voting Rights and Electoral Integrity

-- Guard: every touched row must now carry at least one Legislation/Details citation.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('760cd4a7-235c-472f-a0ba-fb07098dfd57'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('fcfa1844-032e-4dba-9ae0-c52b82447fa8'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('b592e432-6411-48b3-bca3-d5596d0d81e9'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid,'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid),
    ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('c017b328-4469-45c4-aa8a-7b9035c77e22'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('92075c9b-6c7e-4763-981f-5a42a8afddf5'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('a92085b6-642a-4cf6-a73e-c985a6fd09fa'::uuid,'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid),
    ('192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('192e8ffb-e576-41f1-915a-dbc0c30d4769'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('03a161cf-1da8-4c34-9c08-d91bbf958987'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('22610d7f-eaca-4802-b486-0e48544e6e7d'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('0abc8345-1fbb-4994-b39c-c3c4f4eefc9f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('01aaf4ba-c8ec-4a50-bd56-8d181d35e903'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('916afe40-4061-476f-9a54-b271b32778d2'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('916afe40-4061-476f-9a54-b271b32778d2'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('916afe40-4061-476f-9a54-b271b32778d2'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('e2ca1bfd-255d-417b-a9d7-424e6c10749d'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('70f63959-f51d-4411-adc1-f1c429bbc397'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),
    ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('656a8bc9-348e-4ffc-819c-2f4611b3ddc8'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'666bf03d-81fc-4138-ab15-69ae734c9023'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('69bf6043-4546-4804-ae04-311cff54a986'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('5946ad0c-ddf5-4674-840e-6968105042cd'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('5946ad0c-ddf5-4674-840e-6968105042cd'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('5946ad0c-ddf5-4674-840e-6968105042cd'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('5946ad0c-ddf5-4674-840e-6968105042cd'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('0945acd2-cb51-49ad-a22f-6043d2e61520'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid,'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),
    ('c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('6a04e5b9-d532-4e80-bbca-6677a35620e5'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid),
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('71542618-59c8-4b06-a765-e3df60cca763'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('38404814-7be0-40e3-b044-062f98b2a5b0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('409ad653-a4fc-41d0-bb61-a933c5bc45c7'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('027a2610-1160-4525-a5c1-469fe85d46e1'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9285f590-79b5-48de-a1c0-a022629e6ebb'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid),
    ('0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid,'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid),
    ('0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('0608cc7a-72ed-4d24-b966-3eee82075bf1'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'d1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),
    ('f5224e0c-0761-4ca7-a889-ed44517e2b91'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('df1a05a1-2a70-4e40-a0c6-5b3f81632c7e'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('848ac881-004b-436a-9a17-dfacbd33de5a'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('848ac881-004b-436a-9a17-dfacbd33de5a'::uuid,'9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),
    ('848ac881-004b-436a-9a17-dfacbd33de5a'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('7a76712a-38cd-41de-b260-cd0127284f16'::uuid,'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid),
    ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%'
  );
  IF missing > 0 THEN
    RAISE EXCEPTION 'guard failed: % row(s) lack a bill citation', missing;
  END IF;
END
$$;

COMMIT
;
