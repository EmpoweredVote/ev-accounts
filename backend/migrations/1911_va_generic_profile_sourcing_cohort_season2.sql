-- 1911_va_generic_profile_sourcing_cohort_season2.sql
-- The Virginia generic-profile-sourcing cohort: every voter-visible stance row of a Virginia
-- officeholder whose EVERY cited source is a generic page about the PERSON -- a Wikipedia or
-- Ballotpedia biography, or a General Assembly MEMBER page.
--
-- Measured fresh: 118 keys / 41 officeholders.
-- 110 rows written: 49 CITATION REPAIRS (chair unchanged) and 61 BLANKS.
-- 3 rows HELD for the operator. 5 rows BLOCKED on `immigration`.
--
-- ⚠ THE INHERITED FIGURE WAS 85, AND BOTH NUMBERS ARE RIGHT. The national detector counts only
-- biography pages; 85 is exactly the bio-only count here. Adding the General Assembly member
-- page to the generic list -- which is what the Maryland and Texas passes established it should
-- be -- adds 33 rows. This is a DEFINITION difference, not drift.
--
-- ══ 🔑 THE MARYLAND RULE TRANSFERS TO VIRGINIA, AND CALIFORNIA'S DID NOT ══════════════════════
-- A VA LIS member page lists the member's own legislation with titles -- "Legislation as Chief
-- Patron: SB 451 Income tax, corporate; SB 457 Driving Decarbonization Program and Fund..." --
-- exactly like a Maryland roster page. So for those rows the page already cited IS the evidence
-- and the fix is a citation repair. California had no roster pages at all and ran at 26%.
-- Virginia repairs 49 of 113 writable rows, 43%.
-- ⚠ A VA member page shows ONE SESSION, the one in its URL (241 = 2024, 251 = 2025). A member
-- page cited for 2024 cannot support a claim about a 2023 bill.
-- ⚠ AND IT RETURNS HTTP 200 WHEN THE MEMBER DID NOT SERVE THAT SESSION. The signal is zero
-- bills on the page, NOT the response code and NOT the <title>, which never carries the name.
--
-- ══ 🔴 TWO FALSE-POSITIVE GENERATORS THAT DOMINATE THIS COHORT ════════════════════════════════
-- BIO_BOX (17 rows, the largest single class). The Ballotpedia infobox -- "Compensation Base
-- salary $18,000 Per diem $237/day Elections and appointments Last election ... Education
-- Bachelor's" -- is the same box on every page. "Elections and appointments" makes every page
-- look like it discusses VOTING RIGHTS; "Education Bachelor's" makes it look like SCHOOL
-- VOUCHERS; "assumed office ... term ends" makes it look like HOUSING. Nine voting-rights rows
-- in this cohort scored 95-178 keyword hits and every one of them was the box.
-- SCORECARD_LEGEND (7 rows). Ballotpedia prints a legend explaining what each rating group
-- measures -- "REPRO Rising Virginia: Legislators are scored on their stances on policies
-- related to reproductive health issues". The legend names the topic and says nothing whatever
-- about how this legislator scored, let alone what they believe.
--
-- ══ THE BLANKS, each recording WHICH KIND of nothing ══════════════════════════════════════════
--   BIO_BOX 17 · OFF_TOPIC 13 · ENDORSEMENT_LIST 8 · BILL_LIST_OFF_TOPIC 8 ·
--   SCORECARD_LEGEND 7 · BLOCKED 5 · SILENT 4 · COMMITTEE_LIST 2 · SURVEY_NOT_COMPLETED 1 ·
--   OWN_LIFE_STORY 1
-- 🔴 OWN_LIFE_STORY is worth naming: a deportation chair had been read from the member's own
-- account of immigrating as a four-year-old. A life story is not a policy position.
-- ⚠ BILL_LIST_OFF_TOPIC is the Maryland rule's limit: the member page does list this member's
-- own bills, and none of them is about this topic. A roster of 38 bills proves nothing about a
-- subject none of them touches.
--
-- ══ ⚖ THE CARRY GATE: 3 ROWS HELD ═════════════════════════════════════════════════════════════
-- Of 52 candidate repairs, 38 rungs are identical, 5 were already in Season 2 (no carry
-- question), and 9 changed and were read by hand. Six carry as rewordings or because Season 2
-- asks less. Three do not:
--   Amy J. Laufer / climate-change and David W. Marsden / climate-change -- Season 1 rung 3 was
--     "invest in clean energy while gradually reducing reliance on fossil fuels"; Season 2 rung
--     3 is "Speed up clean energy by cutting permitting red tape and upgrading the grid". Their
--     evidence is investment and a decarbonisation fund, not deregulation.
--   Saddam Azlan Salim / voting-rights -- 🔴 THE RUNG CHANGED AXIS, from "expand early voting
--     and no-excuse mail voting" to "Accept non-photo identification, such as a utility bill".
--
-- ══ 🔴 5 ROWS CANNOT BE WRITTEN ═══════════════════════════════════════════════════════════════
-- All five are `immigration`, which has no Season 2 pin. One of them, William M. Stanley Jr.'s,
-- has good first-person evidence on the page and would otherwise have been repaired.
--
-- ⚖ Virginia shows NO wrong-person contamination. The three California detectors -- house of
-- origin (an SB is lead-patroned by a senator), the borrowed district site, and the row that
-- describes the wrong office -- were run here and returned one row, which reading cleared:
-- Jennifer D. Carroll Foy's civil-rights row says she led the ERA ratification "as a delegate",
-- which is accurate, as she served in the House of Delegates before the Senate.
--
-- Season 1 is CLOSED and IMMUTABLE: every write here is forward, into Season 2.
-- No migration runner exists; this file records SQL applied by hand.


DO $pre$
DECLARE n integer;
BEGIN
  -- all 110 rows this file writes must still sit at the chair they were read at
  WITH eff AS (
    SELECT DISTINCT ON (pa.politician_id, pa.topic_id) pa.politician_id, pa.topic_id, pa.value
      FROM inform.politician_answers pa
      JOIN inform.seasons s ON s.id = pa.season_id
     WHERE s.number IN (1,2)
     ORDER BY pa.politician_id, pa.topic_id, s.number DESC
  ), k(pid, tid, expected) AS (VALUES
    ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid, 3),
    ('9e843c9d-bd2e-431f-969f-63372d0274ca'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2),
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 1),
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('612b8663-46c6-4f34-887d-0dadd06dd194'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 4),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 1),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 3),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 1),
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4),
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 3),
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('e2542ec1-213a-403b-bcda-e956a9384dcb'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 5),
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('95cdc29b-18d1-45e1-84c3-ba601f5bec40'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('c490eece-71f4-4051-975d-8fa5ed5f652b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 5),
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 5),
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4),
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 3),
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 1),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 5),
    ('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('d918e6be-5933-4b24-aada-84cbc461c207'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 1),
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('70d45f9c-aef9-4cd7-be4c-5ae568e94f94'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, 4),
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 4),
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 5),
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 4),
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5)
  )
  SELECT count(*) INTO n FROM k JOIN eff e ON e.politician_id = k.pid AND e.topic_id = k.tid
   WHERE e.value = k.expected;
  IF n <> 110 THEN
    RAISE EXCEPTION 'migration 1911: expected 110 rows at their recorded chairs, found %', n;
  END IF;
END
$pre$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Abigail Spanberger / data-centers  (BLANK SILENT)
    ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48a03d6-b972-4f27-9a8a-d41b07f4a929'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Abigail_Spanberger']::text[]),
  -- Amy J. Laufer / abortion  (BLANK ENDORSEMENT_LIST)
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Amy_Laufer']::text[]),
  -- Amy J. Laufer / healthcare  (REPAIR, chair 2 held)
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she described rural healthcare access as the problem -- ''many of our people live far away from the doctors or specialists they require'' -- and pointed to telemedicine as the opportunity. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Amy_Laufer#Campaign_themes']::text[]),
  -- Bonita G. Anthony / abortion  (BLANK ENDORSEMENT_LIST)
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Bonita_Anthony']::text[]),
  -- Bonita G. Anthony / healthcare  (BLANK SURVEY_NOT_COMPLETED)
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page''s only position-bearing section is its Candidate Connection survey, and the page states in terms that this person DID NOT COMPLETE it. The source affirmatively records that there is nothing to cite. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Bonita_Anthony']::text[]),
  -- Briana D. Sewell / childcare  (BLANK SILENT)
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Briana_Sewell']::text[]),
  -- Briana D. Sewell / healthcare  (REPAIR, chair 2 held)
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that she advocates for paid parental leave, paid sick leave, and affordable healthcare. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Briana_Sewell']::text[]),
  -- Danica A. Roem / trans-athletes  (REPAIR, chair 1 held)
    ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that she is the first openly transgender person elected to either house of the Virginia General Assembly, and covers her opposition to HB 1612, the bathroom bill that died in committee. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Danica_Roem', 'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S126']::text[]),
  -- David R. Suetterlein / abortion  (REPAIR, chair 4 held)
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states under ''Protecting Innocent Life'' that he is pro-life, that as Senator he ''will strongly oppose taxpayer funding of abortion and support the Virginia Pain-Capable Unborn Child Protection Act'', and that he is endorsed by the Virginia Society for Human Life. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/David_Suetterlein#Campaign_themes']::text[]),
  -- David R. Suetterlein / healthcare  (REPAIR, chair 4 held)
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states that he opposes proposals to expand Obamacare in Virginia, arguing the law forced Virginians to give up insurance plans and cost full-time jobs. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/David_Suetterlein#Campaign_themes']::text[]),
  -- David W. Marsden / taxes  (REPAIR, chair 2 held)
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own legislation as chief patron, including SB 451, directing corporate income tax revenues to state parks, and SB 453 on emissions inspection fees. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S80C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S80C']::text[]),
  -- Elizabeth B. Bennett-Parker / abortion  (BLANK ENDORSEMENT_LIST)
    ('612b8663-46c6-4f34-887d-0dadd06dd194'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Elizabeth_Bennett-Parker', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H334C']::text[]),
  -- Elizabeth R. Guzman / civil-rights  (BLANK SILENT)
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Elizabeth_Guzman']::text[]),
  -- Elizabeth R. Guzman / healthcare  (REPAIR, chair 2 held)
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that she worked for collective bargaining and to provide paid sick leave to home health care workers. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Elizabeth_Guzman']::text[]),
  -- Ghazala Hashmi / campaign-finance  (BLANK BIO_BOX)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / childcare  (REPAIR, chair 1 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she writes, ''We must expand access to quality childcare and make it affordable, ensure that families are supported with home healthcare and elder care.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / deportation  (BLANK OWN_LIFE_STORY)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The only matches are the member''s own biography -- where they were born, how they came to the country, what happened to their family. A life story is not a policy position, and reading one as a chair puts words in the member''s mouth. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / economic-development  (REPAIR, chair 2 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she commits to ''quality public education that prepares them for well-paying jobs or higher education'' and to continued investment in schools, students, educators and support staff. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / healthcare  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / judicial-criminal-justice  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / medicare/aid  (REPAIR, chair 1 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she writes, ''I have introduced bills to protect Medicaid, establish environmental justice, provide healthcare coverage for all children.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / public-safety-approach  (BLANK SILENT)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited page does not mention this subject at all. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / religious-freedom  (BLANK SCORECARD_LEGEND)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / taxes  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Ghazala Hashmi / voting-rights  (BLANK BIO_BOX)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Ghazala_Hashmi']::text[]),
  -- Glen H. Sturtevant, Jr. / healthcare  (REPAIR, chair 4 held)
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states, ''I oppose the expansion of Medicaid and Obamacare in Virginia... Medicaid is already growing at an unsustainable rate.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Glen_Sturtevant#Campaign_themes']::text[]),
  -- Glen H. Sturtevant, Jr. / taxes  (REPAIR, chair 4 held)
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states, ''I''ll be a vote for lower taxes and free market, pro-growth economic policies,'' and commits to opposing ''job-killing regulations''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Glen_Sturtevant#Campaign_themes']::text[]),
  -- Israel D. O'Quinn / climate-change  (REPAIR, chair 4 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own HB 1074, on the renewable energy portfolio standard and the eligibility of hydrogen and nuclear resources, and HB 1363 convening a work group on critical infrastructure sectors. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H242C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H242C']::text[]),
  -- Israel D. O'Quinn / fossil-fuels  (REPAIR, chair 3 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own HB 1783 on natural gas utilities and retail supply choice, and HB 2026 on renewable energy from biomass-fired facilities. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H242C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+H242C']::text[]),
  -- Israel D. O'Quinn / taxes  (BLANK BILL_LIST_OFF_TOPIC)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H242S', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+H242S']::text[]),
  -- Israel D. O'Quinn / voting-rights  (REPAIR, chair 4 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own HB 46, requiring voter identification containing a photograph. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+H242S']::text[]),
  -- James W. Morefield / fossil-fuels  (REPAIR, chair 3 held)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own HB 2334, extending the retail sales and use tax exemption for oil and gas drilling equipment, and HB 2401, on the Coal and Gas Road Improvement Fund. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H224C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?211+mbr+H224C']::text[]),
  -- James W. Morefield / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H224C']::text[]),
  -- James W. Morefield / taxes  (BLANK BILL_LIST_OFF_TOPIC)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+H224S']::text[]),
  -- Jennifer B. Boysko / campaign-finance  (REPAIR, chair 2 held)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists her own SB 377, on campaign finance -- prohibited personal use of campaign funds, complaints, hearings and civil penalty. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C']::text[]),
  -- Jennifer B. Boysko / healthcare  (REPAIR, chair 2 held)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists her own SB 376, limiting cost-sharing payments for prescription drugs under certain plans, alongside her bill on licensing certified midwives. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S106C']::text[]),
  -- Jennifer B. Boysko / voting-rights  (BLANK BIO_BOX)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Jennifer_Boysko', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S106C']::text[]),
  -- Jennifer D. Carroll Foy / abortion  (REPAIR, chair 2 held)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she writes, ''I''ll fight for reproductive freedom, which means protecting and expanding access to abortion and contraception, ensuring Virginians have healthy pregnancies.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Jennifer_Carroll_Foy', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C']::text[]),
  -- Jennifer D. Carroll Foy / civil-rights  (BLANK OFF_TOPIC)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Jennifer_Carroll_Foy', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C']::text[]),
  -- Jennifer D. Carroll Foy / healthcare  (BLANK OFF_TOPIC)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Jennifer_Carroll_Foy', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C']::text[]),
  -- Jennifer D. Carroll Foy / voting-rights  (BLANK BIO_BOX)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Jennifer_Carroll_Foy', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S117C']::text[]),
  -- Joshua G. Cole / taxes  (REPAIR, chair 2 held)
    ('e2542ec1-213a-403b-bcda-e956a9384dcb'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page carries his own statement that the minimum wage in Virginia ''remains stagnant at $7.25'' and that ''hardworking, taxpaying residents across the Commonwealth should not be forced to toil with two or three minimum wage jobs at 80 hours a week''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Joshua_Cole_(Virginia)']::text[]),
  -- Kathy KL Tran / abortion  (REPAIR, chair 2 held)
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page quotes her own campaign warning that her opponent would ''threaten funding for Planned Parenthood'' and restrict access to affordable health care -- ''this is what is at stake in our election''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Kathy_Tran']::text[]),
  -- Kathy KL Tran / civil-rights  (REPAIR, chair 2 held)
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page records that she carried the bill making military members and their families a protected class, banning discrimination in housing and employment on the basis of military status, and that in 2024, 2025 and 2026 she introduced a bill to repeal the ban on public sector collective bargaining. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Kathy_Tran']::text[]),
  -- Katrina E. Callsen / abortion  (BLANK ENDORSEMENT_LIST)
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Katrina_Callsen#Campaign_themes']::text[]),
  -- Katrina E. Callsen / school-vouchers  (BLANK BIO_BOX)
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Katrina_Callsen']::text[]),
  -- L. Louise Lucas / abortion  (REPAIR, chair 1 held)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists her own SJ 1, the constitutional amendment establishing a fundamental right to reproductive freedom (first reference). ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19S', 'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19']::text[]),
  -- L. Louise Lucas / redistricting  (BLANK OFF_TOPIC)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Louise_Lucas', 'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19']::text[]),
  -- L. Louise Lucas / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+S19C', 'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19']::text[]),
  -- Lamont Bagby / civil-rights  (BLANK SCORECARD_LEGEND)
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Lamont_Bagby', 'https://ballotpedia.org/Lamont_Bagby']::text[]),
  -- Lamont Bagby / voting-rights  (BLANK BIO_BOX)
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Lamont_Bagby', 'https://ballotpedia.org/Lamont_Bagby']::text[]),
  -- Lashrecse D. Aird / abortion  (BLANK ENDORSEMENT_LIST)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Lashrecse_Aird#Campaign_themes']::text[]),
  -- Lashrecse D. Aird / civil-rights  (BLANK SCORECARD_LEGEND)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Lashrecse_Aird']::text[]),
  -- Lashrecse D. Aird / voting-rights  (BLANK BIO_BOX)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Lashrecse_Aird']::text[]),
  -- M. Keith Hodges / healthcare  (REPAIR, chair 4 held)
    ('95cdc29b-18d1-45e1-84c3-ba601f5bec40'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site lists as an issue: ''Oppose big government healthcare mandates and always work to preserve the doctor-patient relationship and patient choice.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Keith_Hodges#Campaign_themes']::text[]),
  -- Marcus B. Simon / redistricting  (REPAIR, chair 2 held)
    ('c490eece-71f4-4051-975d-8fa5ed5f652b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page records that he was one of the eight legislators appointed to the 2021 Virginia Redistricting Commission, which sat alongside eight citizen members. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Marcus_B._Simon']::text[]),
  -- Mark D. Obenshain / abortion  (BLANK OFF_TOPIC)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Mark_Obenshain', 'https://en.wikipedia.org/wiki/Mark_Obenshain']::text[]),
  -- Mark D. Obenshain / fossil-fuels  (REPAIR, chair 4 held)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material records his support for ''Virginia''s efforts to tap the significant oil deposits along Virginia''s outer continental shelf in an environmentally sensitive manner''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Mark_Obenshain#Campaign_themes']::text[]),
  -- Mark D. Obenshain / religious-freedom  (BLANK BIO_BOX)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 5 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Mark_Obenshain#Campaign_themes']::text[]),
  -- Mark D. Obenshain / taxes  (REPAIR, chair 4 held)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site lists ''Holding the Line on Taxes'': ''Our families already pay too much in taxes -- on average, more than they spend on food, clothing, and shelter combined.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Mark_Obenshain#Campaign_themes']::text[]),
  -- Mark J. Peake / abortion  (BLANK SCORECARD_LEGEND)
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Mark_Peake#Campaign_themes']::text[]),
  -- Mark J. Peake / taxes  (REPAIR, chair 4 held)
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material states that he ''believes that Virginia has a spending problem, not a revenue problem, and will work to cut back wasteful government expenditures'', under the heading ''Keeping Taxes Low''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Mark_Peake#Campaign_themes']::text[]),
  -- May Nivar / abortion  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she writes, ''I will fight for the right to make personal healthcare decisions, including access to abortion, contraception, and IVF,'' and that she will ensure providers can offer those services without fear. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/May_Nivar#Campaign_themes']::text[]),
  -- May Nivar / healthcare  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she commits to ''lower the cost of living -- making housing, healthcare, and everyday necessities more affordable''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/May_Nivar#Campaign_themes']::text[]),
  -- May Nivar / medicare/aid  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: In her own campaign statement she writes, ''Over 600,000 Virginians have gained coverage through Medicaid expansion, and as your Delegate, I will fight to protect these families from losing healthcare if this progress is reversed.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/May_Nivar#Campaign_themes']::text[]),
  -- May Nivar / school-vouchers  (BLANK OFF_TOPIC)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/May_Nivar']::text[]),
  -- Michael J. Jones / civil-rights  (BLANK OFF_TOPIC)
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Michael_Jones_(Virginia_politician)', 'https://ballotpedia.org/Michael_Jones_(Virginia_state_senator)']::text[]),
  -- Michael J. Jones / climate-change  (BLANK BILL_LIST_OFF_TOPIC)
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Michael_Jones_(Virginia_politician)']::text[]),
  -- Phillip A. Scott / taxes  (REPAIR, chair 4 held)
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page records that he sponsored a bill allowing localities to lower vehicle tax rates in response to rising used-car prices, and that it was signed into law by Governor Youngkin. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Phillip_Scott_(Virginia_politician)']::text[]),
  -- Phillip A. Scott / voting-rights  (BLANK COMMITTEE_LIST)
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a committee is not a position on its subject. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Phillip_Scott_(Virginia_politician)']::text[]),
  -- R. Creigh Deeds / abortion  (BLANK ENDORSEMENT_LIST)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Creigh_Deeds', 'https://en.wikipedia.org/wiki/Creigh_Deeds']::text[]),
  -- R. Creigh Deeds / healthcare  (BLANK OFF_TOPIC)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Creigh_Deeds', 'https://ballotpedia.org/Creigh_Deeds']::text[]),
  -- R. Creigh Deeds / taxes  (REPAIR, chair 2 held)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page carries a ''Political positions > Taxes'' section recording that in January 2009 he proposed up to a $10,000 tax credit for businesses making job-creating investments and supported a sales tax exemption. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://en.wikipedia.org/wiki/Creigh_Deeds', 'https://ballotpedia.org/Creigh_Deeds']::text[]),
  -- Saddam Azlan Salim / healthcare  (REPAIR, chair 2 held)
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own SB 335, requiring health insurance coverage for fertility preservation treatments. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S127C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S127C']::text[]),
  -- Sam Rasoul / abortion  (BLANK ENDORSEMENT_LIST)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Sam_Rasoul']::text[]),
  -- Sam Rasoul / civil-rights  (REPAIR, chair 2 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material argues the Commonwealth has ''the opportunity and obligation to address this growing inequity'', weighing the impact of COVID-19 on ''moms, especially moms of color''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Sam_Rasoul']::text[]),
  -- Sam Rasoul / climate-change  (REPAIR, chair 1 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material commits him to ''Enact a Green New Deal'' and frames it as ''not just about climate justice -- it''s also about the intersection of economic justice, racial justice, health care justice and worker justice.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Sam_Rasoul#Campaign_themes']::text[]),
  -- Sam Rasoul / fossil-fuels  (REPAIR, chair 1 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material commits him to ''100% clean energy by 2036'', to ''Establish a moratorium on new fossil fuel projects'' -- ''the future of Virginia''s economy is clean energy, not more pipelines'' -- and to a just transition for fossil fuel workers. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Sam_Rasoul#Campaign_themes']::text[]),
  -- Sam Rasoul / healthcare  (BLANK COMMITTEE_LIST)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are committee assignments. Sitting on a committee is not a position on its subject. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Sam_Rasoul#Campaign_themes']::text[]),
  -- Sam Rasoul / voting-rights  (BLANK BIO_BOX)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Sam_Rasoul']::text[]),
  -- Schuyler T. VanValkenburg / redistricting  (BLANK BIO_BOX)
    ('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Schuyler_VanValkenburg', 'https://ballotpedia.org/Schuyler_VanValkenburg']::text[]),
  -- Scott A. Surovell / campaign-finance  (BLANK BILL_LIST_OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+S100C']::text[]),
  -- Scott A. Surovell / healthcare  (BLANK BILL_LIST_OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+mbr+S100C']::text[]),
  -- Scott A. Surovell / redistricting  (BLANK OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Scott_Surovell', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C']::text[]),
  -- Scott A. Surovell / voting-rights  (BLANK BIO_BOX)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Scott_Surovell', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S100C']::text[]),
  -- Scott A. Wyatt / healthcare  (BLANK OFF_TOPIC)
    ('d918e6be-5933-4b24-aada-84cbc461c207'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://en.wikipedia.org/wiki/Scott_Wyatt_(politician)', 'https://ballotpedia.org/Scott_Wyatt_(Virginia)']::text[]),
  -- Shelly A. Simonds / abortion  (BLANK ENDORSEMENT_LIST)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The only matches are names in a list of endorsing organisations. An endorsement is somebody else''s judgement of the person, not a position the person has stated. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Shelly_Simonds#Campaign_themes']::text[]),
  -- Shelly A. Simonds / school-vouchers  (BLANK BIO_BOX)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 1 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Shelly_Simonds#Campaign_themes']::text[]),
  -- Shelly A. Simonds / voting-rights  (BLANK BIO_BOX)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 2 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Shelly_Simonds#Campaign_themes']::text[]),
  -- Tara A. Durant / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('70d45f9c-aef9-4cd7-be4c-5ae568e94f94'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. The cited LIS member page does list this member''s own bills, but none of them is about this topic. A roster of 38 bills proves nothing about a subject none of them touches. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S120C', 'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S120']::text[]),
  -- Terry L. Austin / abortion  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material states that he ''is proudly pro-life and will support additional efforts to protect the unborn''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Terry_Austin#Campaign_themes']::text[]),
  -- Terry L. Austin / religious-freedom  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material states that he ''supports laws that protect every Virginian''s right to openly proclaim and practice their faith'', alongside his support for ''traditional Virginia faith-based values''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Terry_Austin#Campaign_themes']::text[]),
  -- Terry L. Austin / taxes  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material states under ''Keeping Taxes Low'' that he ''knows how important it is for the General Assembly to hold down taxes, especially when so many families and businesses are struggling''. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Terry_Austin#Campaign_themes']::text[]),
  -- Todd E. Pillion / fossil-fuels  (REPAIR, chair 5 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states under ''Coal'': ''I will fight to stop job-killing regulations and taxes. I believe that coal is not only critical to our economy, but is also an important part of our culture and way of life.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Todd_Pillion#Campaign_themes']::text[]),
  -- Todd E. Pillion / healthcare  (REPAIR, chair 4 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site states, ''I am opposed to expanding Obamacare in Virginia. Obamacare has been a disaster since day 1.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Todd_Pillion#Campaign_themes']::text[]),
  -- Todd E. Pillion / religious-freedom  (BLANK SCORECARD_LEGEND)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/Todd_Pillion#Campaign_themes']::text[]),
  -- Todd E. Pillion / taxes  (REPAIR, chair 4 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign site, under ''Coal'', commits him to fighting ''job-killing regulations and taxes'' on the coal industry. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/Todd_Pillion#Campaign_themes']::text[]),
  -- William M. Stanley, Jr. / abortion  (BLANK SCORECARD_LEGEND)
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 1 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', ARRAY['https://ballotpedia.org/William_Stanley#Campaign_themes']::text[]),
  -- William M. Stanley, Jr. / taxes  (REPAIR, chair 5 held)
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own 2011 campaign site states, ''I will never vote to raise your taxes or user fees at any time,'' and ''I will fight to reduce taxes and the crushing government regulations on small businesses.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', ARRAY['https://ballotpedia.org/William_Stanley#Campaign_themes']::text[]);


INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Abigail Spanberger / data-centers  (BLANK SILENT)
    ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c48a03d6-b972-4f27-9a8a-d41b07f4a929'::uuid, 0),
  -- Amy J. Laufer / abortion  (BLANK ENDORSEMENT_LIST)
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Amy J. Laufer / healthcare  (REPAIR, chair 2 held)
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Bonita G. Anthony / abortion  (BLANK ENDORSEMENT_LIST)
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Bonita G. Anthony / healthcare  (BLANK SURVEY_NOT_COMPLETED)
    ('fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Briana D. Sewell / childcare  (BLANK SILENT)
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 0),
  -- Briana D. Sewell / healthcare  (REPAIR, chair 2 held)
    ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Danica A. Roem / trans-athletes  (REPAIR, chair 1 held)
    ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af2c6427-daf8-4819-93ba-42db212bae68'::uuid, 1),
  -- David R. Suetterlein / abortion  (REPAIR, chair 4 held)
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 4),
  -- David R. Suetterlein / healthcare  (REPAIR, chair 4 held)
    ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 4),
  -- David W. Marsden / taxes  (REPAIR, chair 2 held)
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Elizabeth B. Bennett-Parker / abortion  (BLANK ENDORSEMENT_LIST)
    ('612b8663-46c6-4f34-887d-0dadd06dd194'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Elizabeth R. Guzman / civil-rights  (BLANK SILENT)
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Elizabeth R. Guzman / healthcare  (REPAIR, chair 2 held)
    ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Ghazala Hashmi / campaign-finance  (BLANK BIO_BOX)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Ghazala Hashmi / childcare  (REPAIR, chair 1 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e9fe0f2-cfab-4553-99cd-c3195d08e236'::uuid, 1),
  -- Ghazala Hashmi / deportation  (BLANK OWN_LIFE_STORY)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, 0),
  -- Ghazala Hashmi / economic-development  (REPAIR, chair 2 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- Ghazala Hashmi / healthcare  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Ghazala Hashmi / judicial-criminal-justice  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c334f475-05bd-48ba-9d25-f4de593a3f15'::uuid, 0),
  -- Ghazala Hashmi / medicare/aid  (REPAIR, chair 1 held)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 1),
  -- Ghazala Hashmi / public-safety-approach  (BLANK SILENT)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'b9c1c07f-f80e-493a-9bb0-015e46c9bc71'::uuid, 0),
  -- Ghazala Hashmi / religious-freedom  (BLANK SCORECARD_LEGEND)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Ghazala Hashmi / taxes  (BLANK OFF_TOPIC)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Ghazala Hashmi / voting-rights  (BLANK BIO_BOX)
    ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Glen H. Sturtevant, Jr. / healthcare  (REPAIR, chair 4 held)
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 4),
  -- Glen H. Sturtevant, Jr. / taxes  (REPAIR, chair 4 held)
    ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Israel D. O'Quinn / climate-change  (REPAIR, chair 4 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 4),
  -- Israel D. O'Quinn / fossil-fuels  (REPAIR, chair 3 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 3),
  -- Israel D. O'Quinn / taxes  (BLANK BILL_LIST_OFF_TOPIC)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Israel D. O'Quinn / voting-rights  (REPAIR, chair 4 held)
    ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 4),
  -- James W. Morefield / fossil-fuels  (REPAIR, chair 3 held)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 3),
  -- James W. Morefield / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- James W. Morefield / taxes  (BLANK BILL_LIST_OFF_TOPIC)
    ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 0),
  -- Jennifer B. Boysko / campaign-finance  (REPAIR, chair 2 held)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 2),
  -- Jennifer B. Boysko / healthcare  (REPAIR, chair 2 held)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Jennifer B. Boysko / voting-rights  (BLANK BIO_BOX)
    ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Jennifer D. Carroll Foy / abortion  (REPAIR, chair 2 held)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 2),
  -- Jennifer D. Carroll Foy / civil-rights  (BLANK OFF_TOPIC)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Jennifer D. Carroll Foy / healthcare  (BLANK OFF_TOPIC)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Jennifer D. Carroll Foy / voting-rights  (BLANK BIO_BOX)
    ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Joshua G. Cole / taxes  (REPAIR, chair 2 held)
    ('e2542ec1-213a-403b-bcda-e956a9384dcb'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Kathy KL Tran / abortion  (REPAIR, chair 2 held)
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 2),
  -- Kathy KL Tran / civil-rights  (REPAIR, chair 2 held)
    ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 2),
  -- Katrina E. Callsen / abortion  (BLANK ENDORSEMENT_LIST)
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Katrina E. Callsen / school-vouchers  (BLANK BIO_BOX)
    ('13a9c6b7-d781-415b-b44f-3f8ca06aa763'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- L. Louise Lucas / abortion  (REPAIR, chair 1 held)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 1),
  -- L. Louise Lucas / redistricting  (BLANK OFF_TOPIC)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- L. Louise Lucas / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Lamont Bagby / civil-rights  (BLANK SCORECARD_LEGEND)
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Lamont Bagby / voting-rights  (BLANK BIO_BOX)
    ('52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Lashrecse D. Aird / abortion  (BLANK ENDORSEMENT_LIST)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Lashrecse D. Aird / civil-rights  (BLANK SCORECARD_LEGEND)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Lashrecse D. Aird / voting-rights  (BLANK BIO_BOX)
    ('731049dd-0a5b-44fb-a778-b637dded0a5b'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- M. Keith Hodges / healthcare  (REPAIR, chair 4 held)
    ('95cdc29b-18d1-45e1-84c3-ba601f5bec40'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 4),
  -- Marcus B. Simon / redistricting  (REPAIR, chair 2 held)
    ('c490eece-71f4-4051-975d-8fa5ed5f652b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 2),
  -- Mark D. Obenshain / abortion  (BLANK OFF_TOPIC)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Mark D. Obenshain / fossil-fuels  (REPAIR, chair 4 held)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 4),
  -- Mark D. Obenshain / religious-freedom  (BLANK BIO_BOX)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Mark D. Obenshain / taxes  (REPAIR, chair 4 held)
    ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Mark J. Peake / abortion  (BLANK SCORECARD_LEGEND)
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Mark J. Peake / taxes  (REPAIR, chair 4 held)
    ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- May Nivar / abortion  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 2),
  -- May Nivar / healthcare  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- May Nivar / medicare/aid  (REPAIR, chair 2 held)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '38bab357-9790-4cb3-a6d2-c43cbdca615b'::uuid, 2),
  -- May Nivar / school-vouchers  (BLANK OFF_TOPIC)
    ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Michael J. Jones / civil-rights  (BLANK OFF_TOPIC)
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 0),
  -- Michael J. Jones / climate-change  (BLANK BILL_LIST_OFF_TOPIC)
    ('e529eee5-ecec-4719-8b50-47ab9d31bc4d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 0),
  -- Phillip A. Scott / taxes  (REPAIR, chair 4 held)
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Phillip A. Scott / voting-rights  (BLANK COMMITTEE_LIST)
    ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- R. Creigh Deeds / abortion  (BLANK ENDORSEMENT_LIST)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- R. Creigh Deeds / healthcare  (BLANK OFF_TOPIC)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- R. Creigh Deeds / taxes  (REPAIR, chair 2 held)
    ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 2),
  -- Saddam Azlan Salim / healthcare  (REPAIR, chair 2 held)
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 2),
  -- Sam Rasoul / abortion  (BLANK ENDORSEMENT_LIST)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Sam Rasoul / civil-rights  (REPAIR, chair 2 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2010cab0-1968-4f24-b74d-ca47c2f90165'::uuid, 2),
  -- Sam Rasoul / climate-change  (REPAIR, chair 1 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 1),
  -- Sam Rasoul / fossil-fuels  (REPAIR, chair 1 held)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 1),
  -- Sam Rasoul / healthcare  (BLANK COMMITTEE_LIST)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Sam Rasoul / voting-rights  (BLANK BIO_BOX)
    ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Schuyler T. VanValkenburg / redistricting  (BLANK BIO_BOX)
    ('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Scott A. Surovell / campaign-finance  (BLANK BILL_LIST_OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid, 0),
  -- Scott A. Surovell / healthcare  (BLANK BILL_LIST_OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Scott A. Surovell / redistricting  (BLANK OFF_TOPIC)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid, 0),
  -- Scott A. Surovell / voting-rights  (BLANK BIO_BOX)
    ('f3ffde61-ca65-4028-8552-2d4e9a9c6055'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Scott A. Wyatt / healthcare  (BLANK OFF_TOPIC)
    ('d918e6be-5933-4b24-aada-84cbc461c207'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 0),
  -- Shelly A. Simonds / abortion  (BLANK ENDORSEMENT_LIST)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- Shelly A. Simonds / school-vouchers  (BLANK BIO_BOX)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Shelly A. Simonds / voting-rights  (BLANK BIO_BOX)
    ('c25726d9-566e-4283-b35c-c608b921599f'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Tara A. Durant / school-vouchers  (BLANK BILL_LIST_OFF_TOPIC)
    ('70d45f9c-aef9-4cd7-be4c-5ae568e94f94'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid, 0),
  -- Terry L. Austin / abortion  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 4),
  -- Terry L. Austin / religious-freedom  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 4),
  -- Terry L. Austin / taxes  (REPAIR, chair 4 held)
    ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- Todd E. Pillion / fossil-fuels  (REPAIR, chair 5 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid, 5),
  -- Todd E. Pillion / healthcare  (REPAIR, chair 4 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'afc91aa2-4d48-4db6-aebd-f4c9788e6ad7'::uuid, 4),
  -- Todd E. Pillion / religious-freedom  (BLANK SCORECARD_LEGEND)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid, 0),
  -- Todd E. Pillion / taxes  (REPAIR, chair 4 held)
    ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 4),
  -- William M. Stanley, Jr. / abortion  (BLANK SCORECARD_LEGEND)
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'dab46e5c-628a-4360-ad1d-3aaba61768f0'::uuid, 0),
  -- William M. Stanley, Jr. / taxes  (REPAIR, chair 5 held)
    ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '87f8c011-5c70-4f39-a1ea-5cc53c010c60'::uuid, 5);


  -- Alex Q. Askew / housing  (BLANK BIO_BOX)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9e843c9d-bd2e-431f-969f-63372d0274ca'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9e843c9d-bd2e-431f-969f-63372d0274ca'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Bonita G. Anthony / housing  (BLANK BIO_BOX)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'fe47cdc4-c16b-446c-b674-82fdc074370d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Danica A. Roem / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: Her page carries an ''LGBTQ rights'' section recording that she introduced, as first sponsor, House Bill 2132 to amend the Virginia Constitution on marriage. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- David W. Marsden / housing  (BLANK BIO_BOX)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Ghazala Hashmi / housing  (BLANK BIO_BOX)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 3 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are the Ballotpedia INFOBOX -- base salary, per diem, ''Elections and appointments'', ''Last election'', education, profession. It is the same box on every page and it describes the office, not a position. This is the single largest false-positive generator in this cohort. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Lamont Bagby / housing  (BLANK OFF_TOPIC)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 4 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. The page speaks about something nearby, but not about this topic. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '52daeb4d-205d-426a-80a4-40e00b7ee9c0'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Mark J. Peake / same-sex-marriage  (BLANK SCORECARD_LEGEND)
UPDATE inform.politician_context SET reasoning = 'Blanked 2026-10-08 (migration 1911). The chair of 5 was read from Season 2 and rested on a generic page about the person rather than on evidence of this position. 🔴 The matches are Ballotpedia''s LEGEND explaining what each rating organisation measures -- ''Legislators are scored on their votes on bills impacting...''. The legend names the topic; it says nothing about how this legislator scored or what they believe. The sources examined are kept below so the next reader does not derive this again from scratch. This is a blank, not a deletion, and not a judgement that the member has no position -- re-research from their own record is owed.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 0, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = 'ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- R. Creigh Deeds / same-sex-marriage  (REPAIR, chair 3 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page carries an ''LGBTQ'' section recording that in 2006 he was part of the unanimous Democratic coalition that voted to oppose the amendment to the Virginia Constitution banning same-sex marriage. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 3, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Saddam Azlan Salim / housing  (REPAIR, chair 4 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: The LIS member page already cited lists his own SB 304, on zoning for the development and use of accessory dwelling units. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 4, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
  -- Sam Rasoul / same-sex-marriage  (REPAIR, chair 2 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His own campaign material, under ''Fighting for Women, LGBTQ, Minority, & Religious Rights'', states that ''All Virginians should have the right to know they won''t be discriminated against based on who they love or how they worship.'' ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
UPDATE inform.politician_answers SET value = 2, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  -- Schuyler T. VanValkenburg / housing  (REPAIR, chair 5 held)
UPDATE inform.politician_context SET reasoning = 'Citation repaired 2026-10-08 (migration 1911). The chair is UNCHANGED; only the evidence is. THE EVIDENCE, FROM THE PAGE ALREADY CITED: His page carries a ''Housing'' section recording that in 2026 he sponsored a ''housing near jobs'' bill allowing by-right zoning for apartment buildings, townhomes and mixed-use development in commercial areas. ⚠ WHAT WAS WRONG BEFORE: the row cited the page and said nothing about what is on it, which is why the national detector read it as profile-sourced. The page is a legitimate source for this position; the citation now says so.', updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;
UPDATE inform.politician_answers SET value = 5, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND politician_id = '38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid;


DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1911)%';
  IF n <> 110 THEN
    RAISE EXCEPTION 'migration 1911: wrote % reasoning rows, expected 110', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id = c.politician_id
     AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE 'Citation repaired%(migration 1911)%' AND a.value > 0;
  IF n <> 49 THEN
    RAISE EXCEPTION 'migration 1911: % repairs hold a live chair, expected 49', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id = c.politician_id
     AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE 'Blanked 2026-10-08 (migration 1911)%' AND a.value = 0;
  IF n <> 61 THEN
    RAISE EXCEPTION 'migration 1911: % blanks at 0, expected 61', n;
  END IF;


  -- ⚖ NO REPAIR MAY HAVE MOVED A CHAIR -- asserted against the EFFECTIVE chair each row was
  -- read at, never against Season 1. A row whose chair came from Season 2 legitimately differs
  -- from its Season 1 value wherever Season 2 renumbered the ladder.
  WITH expected(pid, tid, val) AS (VALUES
      ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('77ce6e63-7379-4c8a-9038-5c708510d6cc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('2d726661-e210-42f3-8454-3cf2d3ecf811'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 1),
      ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
      ('8ed24df0-2a89-45d2-a236-1fe339b2a11c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
      ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
      ('cea4db8b-acb5-4ebb-be09-e731d4412249'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 1),
      ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
      ('9e3f9d94-ec56-4d9e-811f-8b4672494362'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 1),
      ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
      ('405de162-8de9-4aef-af9a-c323c04da698'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 4),
      ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
      ('36673ec0-1045-4a98-8074-12d6deed5cc8'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 4),
      ('df51bc00-8a69-4bd0-9418-e61a3cfe248b'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 3),
      ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid, 2),
      ('b4f19462-f23f-4061-831d-ec4544b5678f'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('b3c03be3-ae7a-4393-a99b-80b63fea74d0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
      ('e2542ec1-213a-403b-bcda-e956a9384dcb'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
      ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
      ('f224a300-8b54-4b57-b988-5c340667f99b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
      ('0efec835-12f2-472b-b7a0-7a166ed937a1'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 1),
      ('95cdc29b-18d1-45e1-84c3-ba601f5bec40'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
      ('c490eece-71f4-4051-975d-8fa5ed5f652b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 2),
      ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 4),
      ('b7e9d159-b766-445c-b95f-9797b57247d9'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('ed60a0c7-252c-443f-98ff-5926bf9a58a3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 2),
      ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('191ee4e1-1514-4567-8fd4-8308e3b88bb0'::uuid, 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid, 2),
      ('597a4057-4ccc-43f6-bf97-bcc701d7e637'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 3),
      ('66fe0d73-731e-45b9-8db4-21e3ce9eb9fd'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 2),
      ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2),
      ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 4),
      ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2),
      ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 1),
      ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 1),
      ('307597bd-3a05-41ad-a991-a7325ece5b5f'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 2),
      ('38b9461f-2f5b-45d8-ae99-626c75ae305d'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 5),
      ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid, 4),
      ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid, 4),
      ('3049ed75-9743-42f4-8c9e-037a41f9bdc3'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid, 5),
      ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 4),
      ('eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 4),
      ('1722c95b-7aed-430e-81a3-488cdf610afc'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid, 5)
  )
  SELECT count(*) INTO n FROM expected x
    JOIN inform.politician_answers a ON a.politician_id = x.pid AND a.topic_id = x.tid
     AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   WHERE a.value <> x.val;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1911: % repaired rows are not at the chair they were read at', n;
  END IF;

  -- Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND reasoning LIKE '%migration 1911%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1911: % Season 1 rows altered, expected 0', n;
  END IF;

  -- the three HELD rows must not have been written
  SELECT count(*) INTO n FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1911)%'
     AND (p.full_name, t.topic_key) IN (('Amy J. Laufer','climate-change'),
          ('David W. Marsden','climate-change'),('Saddam Azlan Salim','voting-rights'));
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1911: % held rows were written, expected 0', n;
  END IF;

  -- California's work must be untouched
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning LIKE '%(migration 1908)%' OR reasoning LIKE '%(migration 1909)%');
  IF n <> 166 THEN
    RAISE EXCEPTION 'migration 1911: CA migrations 1908+1909 now show % rows, expected 166', n;
  END IF;
END
$post$;
