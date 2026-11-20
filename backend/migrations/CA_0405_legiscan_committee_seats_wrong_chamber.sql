-- CA_0405 — LegiScan committees: seats in the wrong chamber, and Assembly committees stored as joint.
--
-- Why. 47 committee seats sat in the other chamber: 41 LegiScan Senate committee seats on 19 California
-- Assembly members, and 6 in Indiana (3 Senate seats on House members, 3 House seats on senators). The
-- LegiScan importer did not write them (LegiScan has no committee rosters). The retired EV-Backend script
-- scripts/import_state_committees.py did, on 2026-03-05, from Open States (California) and the Indiana
-- General Assembly API, in two ways:
--   (a) It matched each roster committee to a stored committee by NAME ONLY, ignoring chamber. California
--       has a Senate and an Assembly "Health", "Insurance", "Education", "Emergency Management"; Indiana a
--       House and a Senate "Local Government", "Judiciary", "Natural Resources". One name key won, so the
--       other chamber's members landed on it.
--   (b) It found people through `openstates-committees` id rows that put 8 senators' Open States ids on
--       Assembly members (deleted by CA_0402; their Open States-committee seats are moved by CA_0404). The
--       same run wrote those senators' LegiScan-committee seats onto the Assembly members too.
-- Separately, the importer's committeeChamber() read LegiScan's Assembly code 'A' as 'joint', so every
-- California, Nevada and Wisconsin Assembly committee was stored as joint. The importer is fixed in the
-- same PR ('A' -> house; unknown -> null; no memberships from LegiScan people records).
--
-- 1. Relabels 85 LegiScan committees from 'joint' to 'house' (california 35, nevada 10, wisconsin 40).
--    Each one's code is 'A' in every LegiScan dataset we hold (California 2009-2026 and Wisconsin datasets in
--    .planning/research/legiscan-cache; Nevada 2023 and 2025 archives). Old value of every row: 'joint'.
--      fa35bae7-599e-494b-bae5-09d41c4e5e17  california    447  Accountability and Administrative Review
--      6b3f8a9e-1b4c-4479-bdfd-3208b5c8cd04  california    446  Aging And Long-Term Care
--      15458dc9-2876-4729-8b96-84ead5e88672  california    448  Agriculture
--      42fddbd1-09d4-418b-9b94-090bd42b86be  california    449  Appropriations
--      a061c959-e2b3-44a7-8dc3-0e181ee016c9  california   4780  Arts, Entertainment, Sports, and Tourism
--      50f2be7e-0ab1-4f73-a732-e1466ad0b1e8  california    450  Banking and Finance
--      eea0cba7-f430-4c7e-b130-7b74662fe415  california    452  Budget
--      c13838c7-8186-449b-90fd-8aaae2b17015  california    451  Business and Professions
--      a1e48c53-20a1-4749-b092-87be16bf5a0b  california   3669  Communications and Conveyance
--      5ea6f309-86b9-4d66-b9b0-ccb359d4460d  california   5218  Economic Development, Growth, and Household Impact
--      921726dc-870a-4ccd-9841-e68fce45d1be  california    455  Education
--      688c8f66-48b5-4418-8b42-5ccd4022c75c  california   4331  Elections
--      3780124b-e3a4-4cdf-bd31-d32b71292166  california   4330  Emergency Management
--      feea3755-d25e-4a8e-81e3-dc36e6135dc6  california    454  Environmental Safety and Toxic Materials
--      3d6791dd-91e6-49d5-9740-d6164bb00490  california    456  Governmental Organization
--      968548ae-d6ef-4b97-ba3c-479e52a975f1  california    457  Health
--      d89f0cdb-ecb4-4b63-8214-e393b3f6d952  california    458  Higher Education
--      51ce8039-0136-4d45-ab0c-2284a0bddafb  california    459  Housing and Community Development
--      7b42b072-c039-451e-9915-f052ba5c96ea  california    460  Human Services
--      ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67  california    461  Insurance
--      372620b9-7da3-4910-9fac-601f35f9c3e7  california    462  Jobs, Economic Development, and the Economy
--      7529a4bb-7ce5-427d-8299-ace980a914fc  california    463  Judiciary
--      f55fc15e-a5f8-43df-8819-878205292686  california    464  Labor and Employment
--      0675ebf0-f2b0-485d-9d71-a81e0161e0ca  california    465  Local Government
--      e6462bb3-25c3-4ffb-8e27-12a957a8d51f  california   4469  Military and Veterans Affairs
--      2de9948c-c75f-4726-b32e-623434c08fa7  california    466  Natural Resources
--      413a49d4-3ba2-4a27-979b-968e693ef7aa  california   4967  Petroleum And Gasoline Supply
--      ebfc518d-ed12-4838-9913-d5941f6481c9  california   3626  Privacy and Consumer Protection
--      bb203294-24db-4d55-ad8c-764619432ced  california   3914  Public Employment and Retirement
--      b4f31120-b604-4dc9-9e2a-abe1ddfd1919  california    468  Public Safety
--      42d650e9-b5d4-445f-bc88-f5442e63b0bd  california    469  Revenue and Taxation
--      d8373e16-3133-4f3a-a28b-5c7fbbf31efb  california    470  Rules
--      80702140-88a2-466b-96ff-1129b9cf2d34  california    471  Transportation
--      f32d986d-fe34-461d-bec3-a2502147faac  california   3620  Utilities and Energy
--      6e374fab-cf2f-43d2-8c7b-a5526b3fc755  california    474  Water, Parks and Wildlife
--      569510ff-1637-458b-8fee-54737eed2106  nevada       1570  Commerce and Labor
--      c744f48c-77cd-41ca-af4a-4ba4d632f59f  nevada       1573  Education
--      d3119231-7e18-4eed-9c93-4beb8703437b  nevada       1575  Government Affairs
--      81800925-c19e-4308-93fe-8806491881de  nevada       3775  Growth and Infrastructure
--      16f67b0e-2c73-42d9-9a19-09129ed58a13  nevada       1576  Health and Human Services
--      72e2070b-6639-4e34-a601-807669e7355f  nevada       1577  Judiciary
--      b54960e3-8637-4a49-89e8-9714f8fab76d  nevada       2103  Legislative Operations and Elections
--      2a101e5b-b453-48f0-828f-a268e0863026  nevada       4288  Natural Resources
--      8a46f3ea-b718-4b4f-99c7-4f17d7d99000  nevada       4287  Revenue
--      c2b955b4-ceff-4c26-a17b-3c505bde0bd9  nevada       1581  Ways and Means
--      6582bd43-90c7-4fdf-bc66-026da54bae70  wisconsin    1019  Agriculture
--      0e16bbe4-04c1-42e3-a8a3-5d7a74f0bdcc  wisconsin    2990  Campaigns and Elections
--      86fd6d81-afb1-4987-960e-ae3c1bfab7aa  wisconsin    1022  Children and Families
--      b6af1198-23b4-470f-8656-e1dbe15af182  wisconsin    1024  Colleges and Universities
--      339e45b9-165c-47b9-be70-7812c1e059fd  wisconsin    5214  Commerce
--      14b86928-5d7e-4a28-adaa-0deff9bdf087  wisconsin    1025  Consumer Protection
--      b4941396-326c-47fd-af9a-6cbe11c81f5f  wisconsin    2998  Corrections
--      acfc0a54-da85-4159-997d-0824b87902ab  wisconsin    3254  Criminal Justice and Public Safety
--      ab5225be-cd02-4983-8d2c-d41abb6cd838  wisconsin    1028  Education
--      eaebfb1d-c45d-4cb7-9ab6-9423ebb7450d  wisconsin    1032  Energy and Utilities
--      84b9e916-1901-446f-a906-6ab8ec9250fc  wisconsin    4122  Environment
--      89c8c2fb-eede-44f1-868f-7f994ad43364  wisconsin    3012  Family Law
--      8671ec3f-39f8-4e40-a1aa-2864309aeb2c  wisconsin    1035  Financial Institutions
--      37929e12-7e1f-420f-9cf5-4a2df20ce198  wisconsin    4038  Forestry, Parks and Outdoor Recreation
--      640172a0-e482-4502-9c37-f47a3332ccf0  wisconsin    3625  Government Accountability and Oversight
--      e8b87ad8-ac1c-40c2-98af-29d29afd10df  wisconsin    5217  Government Operations, Accountability, and Transparency
--      03a3dcec-03bd-4bda-8abb-be56bcc54b42  wisconsin    4790  Health, Aging and Long-Term Care
--      a867cb9f-24ef-4728-b083-857d0074ca74  wisconsin    3033  Housing and Real Estate
--      e732f420-44b6-4fa1-a8f1-04e0bf8d3457  wisconsin    1040  Insurance
--      ad02c7ad-d4e6-45c9-9790-09d26b8e96a7  wisconsin    3256  Jobs and Economy
--      84b8a87d-e49b-46ba-bc3b-5ffd12e842ad  wisconsin    4891  Jobs, Economy and Small Business Development
--      3368ec3f-14b0-4001-ab5c-ca7ff70b62c9  wisconsin    2989  Judiciary
--      1a534481-ef24-4643-bdc9-542c1f5037e3  wisconsin    4056  Labor and Integrated Employment
--      82e7c203-b821-4f7f-bbac-8325870511f1  wisconsin    3574  Local Government
--      41ea972c-1b00-430c-9911-329d1b0031a7  wisconsin    4890  Mental Health and Substance Abuse Prevention
--      7733720d-196e-408f-b28f-bd050e417f45  wisconsin    1020  Organization
--      3820050d-07ff-4072-8ccb-c7d4a198861a  wisconsin    3386  Public Benefit Reform
--      8db09648-19ff-477f-8e37-f3adf3e17bf2  wisconsin    3577  Regulatory Licensing Reform
--      5a452b4c-fc6b-45ca-b854-410c961ab720  wisconsin    1049  Rules
--      b4c1e71e-1593-4f72-bdf1-583b2bc41916  wisconsin    4159  Rural Development
--      08f4a237-ea1b-453d-9eeb-6f8a825146f7  wisconsin    5100  Science, Technology, and AI
--      bc150ffd-325d-4581-a389-9a0cf1a9d50a  wisconsin    3993  Sporting Heritage
--      4aac84e1-fa94-4534-9a1e-b75eda1921cc  wisconsin    3000  State Affairs
--      5d2e68eb-e998-4eaa-8ddc-69f7dc6ab847  wisconsin    5209  State and Federal Relations
--      92e75166-1c5a-4032-ac98-7ee300ffed39  wisconsin    2991  Tourism
--      aefe9c3d-983e-47a3-91dc-f5259997acdf  wisconsin    1054  Transportation
--      d71af1b3-e315-4e2a-9b81-76d1c802068f  wisconsin    1056  Veterans and Military Affairs
--      fb0202bd-2684-4d13-bdcf-8095cc1fd092  wisconsin    1057  Ways and Means
--      9a1be834-ee2d-4b44-bde4-4c36954527f6  wisconsin    4871  Workforce Development and Economic Opportunities
--      2d84614f-a943-4ed3-8b4b-c8ae42e0833c  wisconsin    5166  Workforce Development, Labor, and Integrated Employment
--    Left as joint (1): their code is 'J' (a real joint committee) or not in any dataset we hold.
--      ee4502eb-b8e4-47a4-9094-94a7eb80f492  wisconsin    1083  Finance  code=['J']
--
-- 2. The 47 seats. Each was checked on 2026-11-20 against the public Open States committee files
--    (github.com/openstates/people, data/{ca,in}/committees/*.yml, commit of 2026-11-18), by Open States person id.
--    Every row keeps congress_number 0, is_current true and its session_id. Old values below.
--    2a. 17 seats move to the same-named LegiScan committee in the member's OWN chamber (Open States lists
--        the member there, with the role shown). membership id | member | old committee (chamber ext_id) -> new | old role -> new
--      03267334-0ad1-423d-bd76-55d1009f74a7  CA Catherine Stefani      Health (senate 480) -> ext 457  member -> member
--      b306cefb-c509-4c1a-bdaf-9c6259fc36bb  CA Celeste Rodriguez      Health (senate 480) -> ext 457  member -> member
--      65db3074-8f4e-45a4-ada2-bfe30384d235  CA Jeff Gonzalez          Health (senate 480) -> ext 457  member -> member
--      6536aae4-8aa8-44a9-8981-ebd31876ee4e  CA Jessica M. Caloza      Health (senate 480) -> ext 457  member -> member
--      65702341-5267-4fcd-a067-e34f0b0086f7  CA John Harabedian        Insurance (senate 2449) -> ext 461  member -> member
--      b5926280-0e47-4525-b865-44188f51552d  CA Josh Lowenthal         Education (senate 477) -> ext 455  member -> member
--      54b854b8-e201-4d0f-9890-dcb1a492ef45  CA Juan Carrillo          Health (senate 480) -> ext 457  member -> member
--      f3f65a62-cdcd-43ee-a370-797acd5f21e9  CA Lisa Calderon          Emergency Management (senate 5261) -> ext 4330  member -> member
--      14029fd8-1b24-4d8e-9386-365e5534f0cd  CA Lisa Calderon          Insurance (senate 2449) -> ext 461  chair -> chair
--      55f1a127-9d76-4224-a6bc-fea2bb10c6fb  CA Liz Ortega             Insurance (senate 2449) -> ext 461  member -> member
--      1ba76124-e71e-4a32-a80b-85906d5fd2c9  CA Michelle Rodriguez     Insurance (senate 2449) -> ext 461  member -> member
--      c3433ba8-4379-4ff4-9cbf-08e34443dfdd  CA Mike Gipson            Insurance (senate 2449) -> ext 461  member -> member
--      b1eec75a-7bbf-4ff1-905c-5d91c643b8f3  CA Pilar Schiavo          Health (senate 480) -> ext 457  member -> member
--      8b22f8a7-c96e-4432-b36c-49edfac80380  CA Rick Zbur              Education (senate 477) -> ext 455  member -> member
--      ceea3f57-c4e3-4ab8-8a15-84a33ed77a58  IN Chris May              Local Government (senate 1327) -> ext 1298  chair -> chair
--      261e0471-c5a0-4c30-a59e-37b45524b5c6  IN Justin Moed            Local Government (senate 1327) -> ext 1298  member -> member
--      69be6ca7-1d2f-4990-b133-e70c46d7eeab  IN Vanessa Summers        Local Government (senate 1327) -> ext 1298  member -> member
--    2b. 26 seats move to the SENATOR whose Open States id the Assembly member wrongly held (Open States lists
--        the senator on this Senate committee). membership id | old politician -> new | committee | old role -> new
--      8c448a83-d752-44cb-8a64-56ffa4e8e4da  Alexandra M. Macedo    8566674a-3a3b-4c88-bba0-c9f42e4ff810 -> Lena Gonzalez 1cede4d2-3075-4860-b133-1ab34cdacff5  Education (senate 477)  member -> member
--      9d561fc1-0453-4e57-96db-db1c56babf0e  Alexandra M. Macedo    8566674a-3a3b-4c88-bba0-c9f42e4ff810 -> Lena Gonzalez 1cede4d2-3075-4860-b133-1ab34cdacff5  Energy, Utilities and Communications (senate 495)  member -> member
--      f14bd0a9-2048-4493-b10b-f3460575e592  Alexandra M. Macedo    8566674a-3a3b-4c88-bba0-c9f42e4ff810 -> Lena Gonzalez 1cede4d2-3075-4860-b133-1ab34cdacff5  Environmental Quality (senate 478)  member -> member
--      3b7ccd38-ea16-4723-9059-93e8500135c7  Alexandra M. Macedo    8566674a-3a3b-4c88-bba0-c9f42e4ff810 -> Lena Gonzalez 1cede4d2-3075-4860-b133-1ab34cdacff5  Health (senate 480)  member -> member
--      c0ea6be8-3ca7-4182-bab6-2b37ab555912  Alexandra M. Macedo    8566674a-3a3b-4c88-bba0-c9f42e4ff810 -> Lena Gonzalez 1cede4d2-3075-4860-b133-1ab34cdacff5  Housing (senate 3949)  member -> member
--      c5a2a401-0643-4564-af42-f3e9370711ba  Catherine Stefani      0649630c-bd6d-40fe-8f66-e026e6f6c83e -> Susan Rubio b3937fff-ebcf-48d9-b20d-bdf98196e119  Emergency Management (senate 5261)  member -> member
--      9c2b9ca0-a168-4a5d-9dec-aaca98243b47  Catherine Stefani      0649630c-bd6d-40fe-8f66-e026e6f6c83e -> Susan Rubio b3937fff-ebcf-48d9-b20d-bdf98196e119  Energy, Utilities and Communications (senate 495)  member -> member
--      9e5937fe-96c0-488a-8780-a3f13a3d7d05  Catherine Stefani      0649630c-bd6d-40fe-8f66-e026e6f6c83e -> Susan Rubio b3937fff-ebcf-48d9-b20d-bdf98196e119  Insurance (senate 2449)  member -> member
--      d575776e-2e97-4dcb-b69e-ce52ea9009ed  Gregg Hart             21940b7c-2424-47e9-a649-077b0f827c2c -> Henry Stern f3671de4-514f-441c-8ad4-4a9ab7c65ae6  Emergency Management (senate 5261)  chair -> chair
--      aace0185-5982-40ef-92bb-fe901056d92a  Gregg Hart             21940b7c-2424-47e9-a649-077b0f827c2c -> Henry Stern f3671de4-514f-441c-8ad4-4a9ab7c65ae6  Energy, Utilities and Communications (senate 495)  member -> member
--      54e155e0-d775-447e-9e67-23f3f3b39c08  Jeff Gonzalez          5ad32852-789e-4013-995b-6f0aa6a5a5d4 -> Lola Smallwood-Cuevas cb9b6b95-ace4-4ae3-a7e6-ae2349abd741  Budget and Fiscal Review (senate 476)  member -> member
--      d75593a3-e5b0-4c4e-bb8a-4eebbad875bb  Jeff Gonzalez          5ad32852-789e-4013-995b-6f0aa6a5a5d4 -> Lola Smallwood-Cuevas cb9b6b95-ace4-4ae3-a7e6-ae2349abd741  Business, Professions and Economic Development (senate 493)  member -> member
--      e5ed2b6b-72d7-4dfd-b609-2bfe1ea1dfec  Jeff Gonzalez          5ad32852-789e-4013-995b-6f0aa6a5a5d4 -> Lola Smallwood-Cuevas cb9b6b95-ace4-4ae3-a7e6-ae2349abd741  Labor, Public Employment and Retirement (senate 3973)  chair -> chair
--      2df89ace-89b7-493f-9428-c64f1d9af65d  Liz Ortega             6730d01a-e87e-4177-9a2b-876b9c494774 -> Laura Richardson 9edc0c37-f213-4aae-9212-c9cb4780d854  Appropriations (senate 475)  member -> member
--      d97c94c1-4de5-419d-8042-270c61f43c75  Liz Ortega             6730d01a-e87e-4177-9a2b-876b9c494774 -> Laura Richardson 9edc0c37-f213-4aae-9212-c9cb4780d854  Banking and Financial Institutions (senate 3675)  member -> member
--      a4c19e86-71de-4fa6-8c00-a5140352fb4f  Liz Ortega             6730d01a-e87e-4177-9a2b-876b9c494774 -> Laura Richardson 9edc0c37-f213-4aae-9212-c9cb4780d854  Budget and Fiscal Review (senate 476)  member -> member
--      c93f8970-abdc-4fc8-83a5-c3eb90946ad0  Liz Ortega             6730d01a-e87e-4177-9a2b-876b9c494774 -> Laura Richardson 9edc0c37-f213-4aae-9212-c9cb4780d854  Energy, Utilities and Communications (senate 495)  member -> member
--      c8c036fc-7eea-49e8-98bc-56ce02f05e2d  Patrick J. Ahrens      bd4dc076-4bdd-4e10-be2c-80d998b17c50 -> Benjamin Allen 4486f856-118b-475c-83f0-078581a7b268  Elections and Constitutional Amendments (senate 1796)  member -> member
--      35778a31-bdf1-41fd-b13d-ed1dd5cde9f4  Patrick J. Ahrens      bd4dc076-4bdd-4e10-be2c-80d998b17c50 -> Benjamin Allen 4486f856-118b-475c-83f0-078581a7b268  Emergency Management (senate 5261)  member -> member
--      40dba79e-03e2-41d4-b514-b9a4aa817282  Patrick J. Ahrens      bd4dc076-4bdd-4e10-be2c-80d998b17c50 -> Benjamin Allen 4486f856-118b-475c-83f0-078581a7b268  Energy, Utilities and Communications (senate 495)  chair -> chair
--      64734187-48f0-4d8b-ad06-31f85d7895ff  Patrick J. Ahrens      bd4dc076-4bdd-4e10-be2c-80d998b17c50 -> Benjamin Allen 4486f856-118b-475c-83f0-078581a7b268  Environmental Quality (senate 478)  member -> member
--      54e19287-2f4a-4cd1-98b8-5822190154f6  Phillip Chen           ed32efa5-b455-4323-a12f-5fe79bc4ffd6 -> Bob Archuleta 29e15a5d-d98f-4536-ad62-05b2612f30ca  Budget and Fiscal Review (senate 476)  member -> member
--      e7bd635e-bd91-41f8-8566-d664b5b7cd59  Phillip Chen           ed32efa5-b455-4323-a12f-5fe79bc4ffd6 -> Bob Archuleta 29e15a5d-d98f-4536-ad62-05b2612f30ca  Business, Professions and Economic Development (senate 493)  member -> member
--      1d10eec5-cc4f-4137-a427-3d6a86ec49c2  Phillip Chen           ed32efa5-b455-4323-a12f-5fe79bc4ffd6 -> Bob Archuleta 29e15a5d-d98f-4536-ad62-05b2612f30ca  Energy, Utilities and Communications (senate 495)  member -> member
--      dbae0af9-23f3-4d92-9e28-a6f1c1ee3a0d  Steve Bennett          8c61cd23-68fb-4f1c-8a3c-60da74c86a64 -> Suzette Martinez Valladares 7f3b03b0-b481-4ccf-a33e-1261daabc6e8  Environmental Quality (senate 478)  vice_chair -> vice_chair
--      45a91618-a14c-4dff-8f26-a7cf740a7e07  Steve Bennett          8c61cd23-68fb-4f1c-8a3c-60da74c86a64 -> Suzette Martinez Valladares 7f3b03b0-b481-4ccf-a33e-1261daabc6e8  Health (senate 480)  vice_chair -> vice_chair
--    2c. 4 seats are deleted: Open States today lists the member on neither this committee nor its twin in
--        their own chamber. Full old rows (id, committee_id, politician_id, role):
--      3788bb26-34bc-419b-8bf4-35b1218ff59e  48b1cc88-a132-44c1-bde6-aa28c14363e7  ea803096-927f-41fe-98e1-deab56291810  chair           CA Al Muratsuchi — Education (senate 477)
--      f5fff6e7-3438-4258-8254-077643960b77  51f4ecf1-c28e-4728-9b11-93f3b70d28bd  8f1088b4-48b5-40ed-95e6-16d8dabd2d33  ranking_member  IN Eric Koch — Judiciary (house 1296)
--      cdef0ba8-d7e6-4a97-9976-396c9509b2fb  51f4ecf1-c28e-4728-9b11-93f3b70d28bd  6b6368a1-354d-4f28-9232-a6ec70198ab8  member          IN Greg Taylor — Judiciary (house 1296)
--      d8b4f1ae-b4d1-4742-bba8-43ee0c0ee18f  f4150a10-581a-41e9-b841-61ee1faa7584  5aa536e1-faaa-485c-b6d8-0e4d99d16361  ranking_member  IN Shelli Yoder — Natural Resources (house 1299)
--
-- Not touched: the 24 Open States-committee seats CA_0404 moves, and any seat in the member's own chamber.
-- To undo: 1. set chamber back to 'joint' for the ids in part 1; 2a/2b. set committee_id / politician_id / role
-- back to the old values above; 2c. re-insert the rows above (congress_number 0, is_current true).
--
-- STATUS: NOT APPLIED.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- 1. Assembly committees: joint -> house.
  UPDATE essentials.legislative_committees
     SET chamber = 'house'
   WHERE source = 'legiscan' AND chamber = 'joint'
     AND id IN (
       'fa35bae7-599e-494b-bae5-09d41c4e5e17',
       '6b3f8a9e-1b4c-4479-bdfd-3208b5c8cd04',
       '15458dc9-2876-4729-8b96-84ead5e88672',
       '42fddbd1-09d4-418b-9b94-090bd42b86be',
       'a061c959-e2b3-44a7-8dc3-0e181ee016c9',
       '50f2be7e-0ab1-4f73-a732-e1466ad0b1e8',
       'eea0cba7-f430-4c7e-b130-7b74662fe415',
       'c13838c7-8186-449b-90fd-8aaae2b17015',
       'a1e48c53-20a1-4749-b092-87be16bf5a0b',
       '5ea6f309-86b9-4d66-b9b0-ccb359d4460d',
       '921726dc-870a-4ccd-9841-e68fce45d1be',
       '688c8f66-48b5-4418-8b42-5ccd4022c75c',
       '3780124b-e3a4-4cdf-bd31-d32b71292166',
       'feea3755-d25e-4a8e-81e3-dc36e6135dc6',
       '3d6791dd-91e6-49d5-9740-d6164bb00490',
       '968548ae-d6ef-4b97-ba3c-479e52a975f1',
       'd89f0cdb-ecb4-4b63-8214-e393b3f6d952',
       '51ce8039-0136-4d45-ab0c-2284a0bddafb',
       '7b42b072-c039-451e-9915-f052ba5c96ea',
       'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67',
       '372620b9-7da3-4910-9fac-601f35f9c3e7',
       '7529a4bb-7ce5-427d-8299-ace980a914fc',
       'f55fc15e-a5f8-43df-8819-878205292686',
       '0675ebf0-f2b0-485d-9d71-a81e0161e0ca',
       'e6462bb3-25c3-4ffb-8e27-12a957a8d51f',
       '2de9948c-c75f-4726-b32e-623434c08fa7',
       '413a49d4-3ba2-4a27-979b-968e693ef7aa',
       'ebfc518d-ed12-4838-9913-d5941f6481c9',
       'bb203294-24db-4d55-ad8c-764619432ced',
       'b4f31120-b604-4dc9-9e2a-abe1ddfd1919',
       '42d650e9-b5d4-445f-bc88-f5442e63b0bd',
       'd8373e16-3133-4f3a-a28b-5c7fbbf31efb',
       '80702140-88a2-466b-96ff-1129b9cf2d34',
       'f32d986d-fe34-461d-bec3-a2502147faac',
       '6e374fab-cf2f-43d2-8c7b-a5526b3fc755',
       '569510ff-1637-458b-8fee-54737eed2106',
       'c744f48c-77cd-41ca-af4a-4ba4d632f59f',
       'd3119231-7e18-4eed-9c93-4beb8703437b',
       '81800925-c19e-4308-93fe-8806491881de',
       '16f67b0e-2c73-42d9-9a19-09129ed58a13',
       '72e2070b-6639-4e34-a601-807669e7355f',
       'b54960e3-8637-4a49-89e8-9714f8fab76d',
       '2a101e5b-b453-48f0-828f-a268e0863026',
       '8a46f3ea-b718-4b4f-99c7-4f17d7d99000',
       'c2b955b4-ceff-4c26-a17b-3c505bde0bd9',
       '6582bd43-90c7-4fdf-bc66-026da54bae70',
       '0e16bbe4-04c1-42e3-a8a3-5d7a74f0bdcc',
       '86fd6d81-afb1-4987-960e-ae3c1bfab7aa',
       'b6af1198-23b4-470f-8656-e1dbe15af182',
       '339e45b9-165c-47b9-be70-7812c1e059fd',
       '14b86928-5d7e-4a28-adaa-0deff9bdf087',
       'b4941396-326c-47fd-af9a-6cbe11c81f5f',
       'acfc0a54-da85-4159-997d-0824b87902ab',
       'ab5225be-cd02-4983-8d2c-d41abb6cd838',
       'eaebfb1d-c45d-4cb7-9ab6-9423ebb7450d',
       '84b9e916-1901-446f-a906-6ab8ec9250fc',
       '89c8c2fb-eede-44f1-868f-7f994ad43364',
       '8671ec3f-39f8-4e40-a1aa-2864309aeb2c',
       '37929e12-7e1f-420f-9cf5-4a2df20ce198',
       '640172a0-e482-4502-9c37-f47a3332ccf0',
       'e8b87ad8-ac1c-40c2-98af-29d29afd10df',
       '03a3dcec-03bd-4bda-8abb-be56bcc54b42',
       'a867cb9f-24ef-4728-b083-857d0074ca74',
       'e732f420-44b6-4fa1-a8f1-04e0bf8d3457',
       'ad02c7ad-d4e6-45c9-9790-09d26b8e96a7',
       '84b8a87d-e49b-46ba-bc3b-5ffd12e842ad',
       '3368ec3f-14b0-4001-ab5c-ca7ff70b62c9',
       '1a534481-ef24-4643-bdc9-542c1f5037e3',
       '82e7c203-b821-4f7f-bbac-8325870511f1',
       '41ea972c-1b00-430c-9911-329d1b0031a7',
       '7733720d-196e-408f-b28f-bd050e417f45',
       '3820050d-07ff-4072-8ccb-c7d4a198861a',
       '8db09648-19ff-477f-8e37-f3adf3e17bf2',
       '5a452b4c-fc6b-45ca-b854-410c961ab720',
       'b4c1e71e-1593-4f72-bdf1-583b2bc41916',
       '08f4a237-ea1b-453d-9eeb-6f8a825146f7',
       'bc150ffd-325d-4581-a389-9a0cf1a9d50a',
       '4aac84e1-fa94-4534-9a1e-b75eda1921cc',
       '5d2e68eb-e998-4eaa-8ddc-69f7dc6ab847',
       '92e75166-1c5a-4032-ac98-7ee300ffed39',
       'aefe9c3d-983e-47a3-91dc-f5259997acdf',
       'd71af1b3-e315-4e2a-9b81-76d1c802068f',
       'fb0202bd-2684-4d13-bdcf-8095cc1fd092',
       '9a1be834-ee2d-4b44-bde4-4c36954527f6',
       '2d84614f-a943-4ed3-8b4b-c8ae42e0833c');
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 85 THEN RAISE EXCEPTION 'CA_0405: expected to relabel 85 Assembly committees, relabelled %', n; END IF;

  -- 2a. Same-named committee in the member's own chamber.
  UPDATE essentials.legislative_committee_memberships m
     SET committee_id = v.to_cid::uuid, role = v.new_role
    FROM (VALUES
      ('03267334-0ad1-423d-bd76-55d1009f74a7', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('b306cefb-c509-4c1a-bdaf-9c6259fc36bb', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('65db3074-8f4e-45a4-ada2-bfe30384d235', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('6536aae4-8aa8-44a9-8981-ebd31876ee4e', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('65702341-5267-4fcd-a067-e34f0b0086f7', '2ad2bb99-8cbb-4444-91d4-ee2bded7e973', 'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67', 'member'),
      ('b5926280-0e47-4525-b865-44188f51552d', '48b1cc88-a132-44c1-bde6-aa28c14363e7', '921726dc-870a-4ccd-9841-e68fce45d1be', 'member'),
      ('54b854b8-e201-4d0f-9890-dcb1a492ef45', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('f3f65a62-cdcd-43ee-a370-797acd5f21e9', 'b22da114-c8a0-4bd8-a749-1765a04b9d48', '3780124b-e3a4-4cdf-bd31-d32b71292166', 'member'),
      ('14029fd8-1b24-4d8e-9386-365e5534f0cd', '2ad2bb99-8cbb-4444-91d4-ee2bded7e973', 'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67', 'chair'),
      ('55f1a127-9d76-4224-a6bc-fea2bb10c6fb', '2ad2bb99-8cbb-4444-91d4-ee2bded7e973', 'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67', 'member'),
      ('1ba76124-e71e-4a32-a80b-85906d5fd2c9', '2ad2bb99-8cbb-4444-91d4-ee2bded7e973', 'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67', 'member'),
      ('c3433ba8-4379-4ff4-9cbf-08e34443dfdd', '2ad2bb99-8cbb-4444-91d4-ee2bded7e973', 'ed52a96d-3eb5-4fa3-bd39-a88d7bac4f67', 'member'),
      ('b1eec75a-7bbf-4ff1-905c-5d91c643b8f3', 'c9cf9fd3-7588-48a1-bbfd-cae442b01c53', '968548ae-d6ef-4b97-ba3c-479e52a975f1', 'member'),
      ('8b22f8a7-c96e-4432-b36c-49edfac80380', '48b1cc88-a132-44c1-bde6-aa28c14363e7', '921726dc-870a-4ccd-9841-e68fce45d1be', 'member'),
      ('ceea3f57-c4e3-4ab8-8a15-84a33ed77a58', '1accea7a-035d-4c01-8abc-02224fb01f15', '5c51fa13-ab01-4ccd-9a96-6041df3c2f54', 'chair'),
      ('261e0471-c5a0-4c30-a59e-37b45524b5c6', '1accea7a-035d-4c01-8abc-02224fb01f15', '5c51fa13-ab01-4ccd-9a96-6041df3c2f54', 'member'),
      ('69be6ca7-1d2f-4990-b133-e70c46d7eeab', '1accea7a-035d-4c01-8abc-02224fb01f15', '5c51fa13-ab01-4ccd-9a96-6041df3c2f54', 'member')
    ) AS v(membership_id, from_cid, to_cid, new_role)
   WHERE m.id = v.membership_id::uuid AND m.committee_id = v.from_cid::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.legislative_committee_memberships t
                      WHERE t.committee_id = v.to_cid::uuid AND t.politician_id = m.politician_id
                        AND t.congress_number = m.congress_number);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 17 THEN RAISE EXCEPTION 'CA_0405: expected to move 17 seats to the own-chamber committee, moved %', n; END IF;

  -- 2b. Senators' seats written onto the Assembly member who held the senator's Open States id.
  UPDATE essentials.legislative_committee_memberships m
     SET politician_id = v.to_pid::uuid, role = v.new_role
    FROM (VALUES
      ('8c448a83-d752-44cb-8a64-56ffa4e8e4da', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5', 'member'),
      ('9d561fc1-0453-4e57-96db-db1c56babf0e', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5', 'member'),
      ('f14bd0a9-2048-4493-b10b-f3460575e592', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5', 'member'),
      ('3b7ccd38-ea16-4723-9059-93e8500135c7', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5', 'member'),
      ('c0ea6be8-3ca7-4182-bab6-2b37ab555912', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5', 'member'),
      ('c5a2a401-0643-4564-af42-f3e9370711ba', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119', 'member'),
      ('9c2b9ca0-a168-4a5d-9dec-aaca98243b47', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119', 'member'),
      ('9e5937fe-96c0-488a-8780-a3f13a3d7d05', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119', 'member'),
      ('d575776e-2e97-4dcb-b69e-ce52ea9009ed', '21940b7c-2424-47e9-a649-077b0f827c2c', 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'chair'),
      ('aace0185-5982-40ef-92bb-fe901056d92a', '21940b7c-2424-47e9-a649-077b0f827c2c', 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6', 'member'),
      ('54e155e0-d775-447e-9e67-23f3f3b39c08', '5ad32852-789e-4013-995b-6f0aa6a5a5d4', 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'member'),
      ('d75593a3-e5b0-4c4e-bb8a-4eebbad875bb', '5ad32852-789e-4013-995b-6f0aa6a5a5d4', 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'member'),
      ('e5ed2b6b-72d7-4dfd-b609-2bfe1ea1dfec', '5ad32852-789e-4013-995b-6f0aa6a5a5d4', 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741', 'chair'),
      ('2df89ace-89b7-493f-9428-c64f1d9af65d', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854', 'member'),
      ('d97c94c1-4de5-419d-8042-270c61f43c75', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854', 'member'),
      ('a4c19e86-71de-4fa6-8c00-a5140352fb4f', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854', 'member'),
      ('c93f8970-abdc-4fc8-83a5-c3eb90946ad0', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854', 'member'),
      ('c8c036fc-7eea-49e8-98bc-56ce02f05e2d', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268', 'member'),
      ('35778a31-bdf1-41fd-b13d-ed1dd5cde9f4', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268', 'member'),
      ('40dba79e-03e2-41d4-b514-b9a4aa817282', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268', 'chair'),
      ('64734187-48f0-4d8b-ad06-31f85d7895ff', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268', 'member'),
      ('54e19287-2f4a-4cd1-98b8-5822190154f6', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca', 'member'),
      ('e7bd635e-bd91-41f8-8566-d664b5b7cd59', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca', 'member'),
      ('1d10eec5-cc4f-4137-a427-3d6a86ec49c2', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca', 'member'),
      ('dbae0af9-23f3-4d92-9e28-a6f1c1ee3a0d', '8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '7f3b03b0-b481-4ccf-a33e-1261daabc6e8', 'vice_chair'),
      ('45a91618-a14c-4dff-8f26-a7cf740a7e07', '8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '7f3b03b0-b481-4ccf-a33e-1261daabc6e8', 'vice_chair')
    ) AS v(membership_id, from_pid, to_pid, new_role)
   WHERE m.id = v.membership_id::uuid AND m.politician_id = v.from_pid::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.legislative_committee_memberships t
                      WHERE t.committee_id = m.committee_id AND t.politician_id = v.to_pid::uuid
                        AND t.congress_number = m.congress_number);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 26 THEN RAISE EXCEPTION 'CA_0405: expected to move 26 seats to the senator, moved %', n; END IF;

  -- 2c. Seats no roster supports.
  DELETE FROM essentials.legislative_committee_memberships m
   USING (VALUES
      ('3788bb26-34bc-419b-8bf4-35b1218ff59e', '48b1cc88-a132-44c1-bde6-aa28c14363e7', 'ea803096-927f-41fe-98e1-deab56291810'),
      ('f5fff6e7-3438-4258-8254-077643960b77', '51f4ecf1-c28e-4728-9b11-93f3b70d28bd', '8f1088b4-48b5-40ed-95e6-16d8dabd2d33'),
      ('cdef0ba8-d7e6-4a97-9976-396c9509b2fb', '51f4ecf1-c28e-4728-9b11-93f3b70d28bd', '6b6368a1-354d-4f28-9232-a6ec70198ab8'),
      ('d8b4f1ae-b4d1-4742-bba8-43ee0c0ee18f', 'f4150a10-581a-41e9-b841-61ee1faa7584', '5aa536e1-faaa-485c-b6d8-0e4d99d16361')
   ) AS v(membership_id, committee_id, politician_id)
   WHERE m.id = v.membership_id::uuid AND m.committee_id = v.committee_id::uuid AND m.politician_id = v.politician_id::uuid;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 4 THEN RAISE EXCEPTION 'CA_0405: expected to delete 4 seats, deleted %', n; END IF;

  -- Post-guard: no LegiScan committee seat left in the other chamber (California and Indiana).
  SELECT count(*) INTO n
    FROM essentials.legislative_committee_memberships m
    JOIN essentials.legislative_committees c ON c.id = m.committee_id
    JOIN essentials.office_terms ot ON ot.politician_id = m.politician_id AND ot.term_end IS NULL
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.source = 'legiscan'
     AND ((d.district_type = 'STATE_LOWER' AND c.chamber = 'senate')
       OR (d.district_type = 'STATE_UPPER' AND c.chamber = 'house'));
  IF n <> 0 THEN RAISE EXCEPTION 'CA_0405: % LegiScan committee seats still in the other chamber', n; END IF;
END $$;

COMMIT;
