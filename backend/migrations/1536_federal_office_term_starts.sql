-- 1536 — populate office_terms.term_start for sitting federal legislators
--
-- Source: unitedstates/congress-legislators (public domain), legislators-current.json +
-- legislators-historical.json, fetched 2026-08-02. term_start is the first day of the
-- member's CURRENT UNBROKEN run of service in this seat's chamber, so consecutive
-- re-elections collapse into one open-ended tenure, matching ADR 0002's "term_end IS NULL
-- means current" semantics. start_precision is 'day' because the dataset gives exact dates.
--
-- Scope is deliberately narrow. 176 of 705 federal rows are left alone (see
-- the generator for the per-reason tally), and NOTHING non-federal is touched: there is no
-- term-start authority for state and local officeholders, and politicians.valid_from is
-- placeholder-contaminated (2023-01-01 x151, 2025-01-01 x126, 2024-05-01 x79), so migrating
-- it would manufacture day-precision dates that were never published anywhere.
--
-- how_started is left untouched: the dataset says when service began, not whether the member
-- was elected, appointed to a vacancy, or succeeded to the seat.

BEGIN;

-- Guard: every id below must currently have a NULL term_start, or someone has written to
-- these rows since the generator ran and the values may no longer describe them.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE id IN ('e9898584-e3c5-489a-a191-870833259325', '5b32e5f8-50a1-4e9d-9b34-3796c688b234', 'efb602ec-2dd0-4a1f-a562-05bb88960cbe', 'c55dc843-40ef-4be1-b5fa-c196694b75dc', '9549694e-a158-4c37-9d0e-34626f587bf7', '214f3895-aeb4-44a7-acb0-c922806eb6ce', 'b4f2dbce-699b-4649-bc0f-b31d343b27e7', '950a5fff-e9d4-4faa-8a7a-cf1a458f57cf', 'f4da7df3-7936-4e09-9ef3-d7e037fb53bd', '817d50e5-5389-4f90-bc1a-78459b540a92', '575b3b14-cf66-4751-9398-782aa20deac4', 'b8aa1c9b-602c-48b4-97c6-7f68541ddaab', '6bee8265-72b9-4521-b0f4-8446a63f1484', 'b0b1888a-f2ec-455d-afad-e34f1f83924d', '41ee8c81-54e1-4bda-8a57-f9f839281365', '79f82a79-561d-4b7a-9d26-42e88a41170a', 'c90493f7-60d3-41a9-bfae-9bc4d59efb59', 'f77a48fa-6364-4095-bfec-04a46413885b', 'e78044b9-8a60-4642-8ec8-fa6154dfa237', '70d04287-ee20-4f3d-b22d-59c92caa697d', '3ddb43aa-e7f3-4ea4-8f25-692e21a8777a', 'c587d67b-ce9c-4923-b89d-60ad2f957877', 'a4cf695e-61f5-439a-8300-e982972d56bd', 'e6bf19f0-0e04-46c9-b547-e94af9b17621', '6d0710c7-fd42-4242-8f16-d418238c4ead', '41f8c75d-024a-457a-bbe4-f9206b9d463c', '6d1ed881-4ae9-4254-9e4d-15dcfc2f2c11', '874c32e7-e2b0-4446-9217-500deee8ea91', '1edbdc12-1b84-4255-b25d-84c9d7ae5a64', 'd90373cb-b54e-4173-aff1-f744ff8f2b98', '19d1728d-b136-4460-af80-b5b9f4748cab', '9782baa6-6c91-4f3e-9043-e5776914cf67', 'e44746a0-bae5-42aa-bc19-aa25ce116259', 'e64b2ad6-f67d-4729-b13e-bdc527a02493', 'f6dd5786-2c38-4f21-ac6c-d0f24ff5a4ed', 'cc185493-16a0-42ed-982f-fa7e75dbc2f6', '5bd21c43-9f4f-47ee-ad0a-3a832b02dfcd', 'c9f68f43-c0ee-4d10-bd94-75675a98998e', 'ef4a86cc-33d3-4a02-a2ee-aa07a8a01b00', 'fbecff96-e2d3-467d-83e9-dfeee9496d46', '04246315-498f-42d2-806d-00b22b053b75', '98af3fe7-64ba-4175-9ed8-3d70726280ee', 'd37fd057-14d2-43b4-80a5-7a2282e7beb2', 'c054b617-033e-4ab7-ae6a-d3e07e62ae85', '753a6ab6-c705-4835-a694-3471529627fe', 'f25ff3ed-1c31-4cfd-81cd-6ab02e894ecd', '734c41aa-06d6-4814-a11b-108080366ac7', 'f99ac69b-43c2-47b7-9320-58dc73d88495', 'f9b0c61e-60b2-4eff-93fb-8c52c5eadbf9', 'bc15b39e-125f-4d96-96df-54ed30ad5fcb', '58b0c3c0-68eb-4bf4-a9c3-cdca905d8bcf', '5e2f8810-c413-4829-89b7-b7386c238639', 'ba4f77f6-45c4-4537-8531-f3c2a6b2979a', '8879364d-d4b2-4e02-b636-f195b0be9ec6', '48c00557-7efb-451a-b83b-ccee99090154', 'aab12c9f-caf7-4201-84c2-a50738303cd7', '0df678b4-c584-47a1-ad69-901ce106e13e', 'acda0b68-b352-4da9-8062-b3fe0def20bb', '7235c55a-7e73-431d-914e-1ff9bc57235c', 'bdc30aff-7cf6-4d6c-a982-5bfc11d14a03', 'd451e969-bb1e-432d-8ba0-d098721343c0', 'b986fc1b-d8c5-49b8-8fc1-2c1cf926a24c', 'd7a6f747-ce7a-4947-b43e-e300e1ed3e35', '26719271-aa14-4527-9482-bb2de1e5e9da', '31749147-c692-4040-838f-e402b60ffa1e', '1ac8aedb-bb88-465b-8371-ae265c5752e3', '96ffd50e-2b77-43c8-bcf2-e36372afa201', '7714a266-24eb-4ba9-9808-378e29ef3dd3', 'cc2df80b-7b81-40d5-adbd-8bfa583c28c4', 'b9f892a8-e70c-4c00-b293-ea45ab7e52a2', 'f8ddac77-1bb7-40ff-a8ac-9e82b74b76a7', 'cc6eacdb-3c3a-4768-9236-9def335a435a', 'cbf31e17-c411-4e2b-9fdc-0936fb767392', '4a4d8079-0931-4d31-8dac-e3852af155f9', '564075dd-ed41-4e24-b447-85023a874a7f', 'c804e7d5-bd63-48a9-823c-ef3f0c7dcc83', '2a446a3b-6be7-4b81-90b1-531aefcc78bc', 'fd355098-9568-44b8-ab68-047269668307', '4048582e-28f9-4e22-a797-0e93d82be5fb', '468eb0cb-1c1a-4fd6-ad2c-a9e5c0ade8ea', '0fd49452-8282-4de4-9947-e8aff1a9c44d', '3261b105-0728-43e0-976d-7d905c534cae', '4ed53c4a-2ab4-45db-82ab-20594bad849b', '7258b590-3e7a-4330-b829-c9665ebf5208', '08fd6230-0402-4176-a813-f91fc8d695e8', '08313f64-b9e2-4990-864d-89f950e01ca4', 'a0d656dc-e2ab-4bee-bc29-36bedf8215ce', 'faebbb20-0ea5-4619-a448-57d67ee1449c', 'b84d0efd-e258-4856-8aeb-46ebea0ced70', '774fa242-44da-42e7-a192-85654e6fdcbf', '4617370d-ab15-47ca-952d-8876ce643d95', '906a4fc4-4148-4489-9bd9-a1e69d61364e', '7268319f-dad3-4f73-b253-9cafcee46d72', 'e36f39c7-3728-4139-9bea-51a2025c3988', '2fbf8051-baf2-48ef-9814-f2d459e4ce24', 'd37954c6-3c4f-4b93-8165-0eec4fe7200d', 'c34402fe-52c3-421a-850d-bc30b07ba871', '5df17e24-3cbc-4435-8ad2-8e4c84ebd6aa', '6a97ffd9-c1b7-4c4c-9035-270d8df138b6', 'f9e3b85f-be58-42ce-87a7-3c76e37d86ff', '732c4c3e-89cf-4c10-b551-1a0b17398916', '49877611-e41a-4a5d-964d-ed15ce748b6b', '29473826-72ab-442a-ba39-7374ecc180a3', '61baa8d7-54a0-4215-b9be-83b7d6dc3efe', '86b4d695-99b2-4c42-bc94-a7fbbed64534', 'd6bddc1c-382b-4ed0-bc77-e15c5697be70', 'b1c49d8f-a1f8-4840-bd83-15b57dab9221', '7f148a24-e048-4dab-bf6f-763f52810c26', '8ecda4bd-182c-4f93-871a-490d04f1eac9', '78556b10-7960-43ce-b59a-6336623f2a9c', 'e583c777-0ef9-4faf-ad78-9975d28a77ad', '12a5d9ec-1e92-42a9-9bc0-96fa75d81bde', '506c540f-67fa-401f-91d8-428e9f6b75af', '28ab1073-0e74-4853-a6e3-850d10c09569', 'dc48d107-f499-48dd-85ae-e73ff2c5a75d', '802ec670-cc4c-4daa-aa5c-f2f9d75ab7dc', 'cff23a15-4454-4e37-9c36-f7d2313daef1', 'd8a9a0e8-67c0-4955-9650-ddb56dab9f69', '66534f7b-a842-4c4c-a8ac-ecdd43b29e84', '55af15e1-27a8-477f-b45f-a99988e1edf5', 'f28efa1a-25f9-4311-b22d-e99b761ea91a', '181520b6-b803-443b-b61e-eb8eedc28479', 'b7d84ec7-e3f1-478a-9533-22e7b8c98ee0', '82c0dbf9-3c5b-4331-8849-7f328f5fb69e', '3c8ac872-25c7-4c6a-b775-5343ed3049fa', 'cc0e030d-fc27-472b-9653-94550ceef922', 'ef8fa168-e48a-4bba-970e-920206905a5d', 'cc97886e-0a1f-4f61-a2eb-df260722c45b', '9ba7af7e-5919-4e41-bed4-3d41bf2f173b', 'ab222806-9857-4b19-b9ed-1d1a28018061', '0f6f966b-387d-4fa4-9024-55a2e5eb58f0', 'f26350e3-f713-4a01-804e-a0a0a613fc4a', 'a51a0323-560b-463f-9bca-2a2dbf43cc30', '18d8f3d9-9f24-42a5-ad9f-e207c83672fd', 'b0eba786-d54e-4eaa-b513-2bd05438bfac', 'fa1c5268-ac6c-4bc2-b84e-455b1cd69b95', 'e456ba12-cb4b-4f52-a56e-a8fea087d216', 'af945e76-cf8d-4612-a237-0c034568edbc', '1a781d2a-4791-4528-badb-6bbe8c47ad64', '1a638ae7-bd1f-4f95-82f9-b8eb79f24f0c', '6227e743-5d40-4b50-953f-59c82ecb54fd', 'da9dd62c-d52d-4aef-ba9f-1ac0a43c160e', 'be73582c-c1dd-4f04-8e41-fe922bb314c9', '237750a3-c777-45d2-824a-8bcb98f1346a', '6d78c2d2-4d91-4e8b-91ec-3790106f92ab', '2028314e-56a8-4344-9f61-85d97845d63d', 'c02ee742-9c2c-4a30-9414-a5a289719917', '1e13d3f4-ae50-4d61-a3d5-8b8e12d0a1c8', '5fae2e82-9956-4b8a-94e2-53d5a4e59a55', 'c2704144-1d24-4ab3-afba-e6863c7e0712', '43d2c8d7-f6a9-4626-9fe6-e2fa679811c7', '3455e028-5aef-4335-b594-c595a68a1550', '3baeaed2-9e67-4802-a2c4-d9ff0c47de05', 'd26f0bd5-aed4-49e9-ad5d-68186ce97362', 'b06e1b70-55f3-4bd9-94f5-2ac0b1b4e2e7', 'e0281e7c-6edd-4602-9763-493a19047dd8', 'c5334d4e-9609-4c43-9cb5-8edbd4c44e12', 'd3bf1e17-f59c-4057-8cd3-d4bb6892c1f7', '411a0f3a-cb0f-4177-9966-bec211faefd9', '7c310b28-dc7e-4094-be48-4d1f1dd74347', 'dced4f84-54be-44b8-9bdf-c4a0fb8f743b', '319ba9c4-be44-44ad-a6ab-2a459638d4fb', 'd3aa1b4b-ff07-4a8a-850c-14d604ce4d92', '412dabff-f49e-4661-a4d9-f37977fcabb5', '98d51f86-23c9-4e86-bd53-91428749924c', 'e693ca9a-a4fa-48a8-94d4-c3397894526c', 'c2052634-26ed-4054-b56e-38650f9342d2', '3ca17bf0-af00-40db-9f34-d508a86b9b22', 'ab6579df-5446-46bf-9e67-40560c8d4687', '5c7f0e13-92ad-4aee-8f9d-66692029ec6b', '0d28cadb-d38b-4c15-a28d-431df0b1fa60', '8afc8857-6bd6-4a62-aca6-b9d9f81118dd', 'c87d5fe5-37c0-4336-8f8f-da5267cef50c', '4766601c-1672-4578-9588-7d067e333ad3', '1cf44c8d-15da-4716-bdcf-21a1e213df32', '4ebf8ef9-2a9b-44c0-9131-f27cb9c32124', '7cd8e684-bb28-4241-9d59-b7a4b1c4102b', '0251de35-dc30-4901-8afc-b1167914a77f', '4a3ea779-ae31-477b-b8f7-5b5d4afd4ac5', '9366546b-16e8-40f8-9145-ed60638298da', 'b7cc01e9-aee4-48f6-be8f-117f7b1256c7', '724baf2c-a7c6-494c-9530-f7ff7e20e3fd', '9d687807-0a94-4337-93d1-02a8e1c3e6b0', '4a77d835-0150-418f-b0ee-034119a75bed', 'dcf0502c-b059-4bde-b72f-3cc21872add8', 'e2e7fb5a-d172-4cbb-9357-d78758e77e04', '7fd86011-1622-4bda-8bee-cb1128ea756e', '6dfe7358-d7d2-4f97-aadd-6f589ef98a97', '94b189f1-7c8f-4b25-8ebe-648611e5a53c', '4bb4a12e-6fe4-4dfe-8fec-6d50c3bffcf8', '6898ac61-873e-4242-a9c1-c358d45581fb', '51c8eb69-4e2b-43d2-be82-c573a5f69d09', '22ea82af-b232-45fc-8781-d57b172ca25c', '67615c90-8ab2-4ad0-b4e9-46fecc409954', 'd54dce90-d3ef-49df-9da7-198761341b6d', '758afe0a-df47-4855-aa11-547230a328bc', 'e73235d5-806c-4141-a6ec-d5d1fdc91fc2', '9ecdff89-7245-4191-896e-272926f95480', '4b9dbd6b-1927-4a2f-ba8c-52f4ddd371e9', '6b876fdc-4da4-42bd-b6fe-71ecb9f42c76', '1bee1841-6836-47d2-806e-3da4a662ef50', 'eb842055-54d5-43ba-9c11-183fbd3552a9', 'b5faeaf1-1c18-4300-8f36-ab42e7fffe3b', '724dbf54-862a-4994-bcf1-e87a091ab849', '12a7bfed-c9f0-498a-b46f-3ba2a8597c10', '84633187-c4de-46d3-aa14-f220120a4e26', '031b576a-3c38-419d-8edc-9f7a45c82678', 'cc75e22b-ac0b-4215-872d-a4079801b4ba', 'd441d833-4b30-4b80-a924-e7c2f4b0af7d', 'd892a898-75db-4ac2-9c64-03907ee9e6f6', '016f0e65-cf0f-46d4-a3fa-62f36510d213', 'b0abce0c-7c44-4d64-ad37-ec6889244bf6', 'a180d10e-86f1-419e-bc91-a3b82a4d7a80', 'a76e2eab-8c3c-41a2-8ad5-292e62ae14f6', '38a25ac7-f273-49dc-adda-affe38cf88d3', 'a7488ac8-795c-4c31-9e62-79d8be85a3e5', 'e88ed49f-6dce-44b0-b71a-23152fa748d7', '0cb66651-8f9f-4747-8624-2637230d73ab', '90fb4dab-4a30-4183-bc32-630de68c4bd3', 'a24c1c41-140d-460d-a495-6ea1a629ff87', '30719974-35a9-450d-9d3b-6e834bfc85c5', 'fb744540-1fff-4537-81aa-a49be750d40e', '69e6d1d6-75bc-4354-be31-d5d9de4a782d', '4c784013-6307-4900-bd0a-baeae5b573fa', 'e1c91912-eb5a-440e-bac3-b774e2575197', '7465949a-4c6c-4091-bcf2-1913910e4d83', 'a728cbc0-3170-448b-9e5a-2ebb8aae5211', '632da81c-bef6-4ece-a84e-31c27098c933', 'f07d32e3-e0fe-4ecf-9212-38ace392dedf', '9519363f-7b8b-4ee0-84b5-5ba447c24ad6', 'b649164e-31ff-457c-b76c-ebf6c1bfca9b', '39ff0f79-c971-47a6-93c2-2b04ccb603a7', 'a0876ccc-6a95-4645-9b5e-cf598658384f', '7563248c-3189-4d14-88b7-158bc3dfe5b3', '75a70b3d-e33c-4589-8336-e4255e66298b', 'a97ea95a-12ca-4cd9-8b9c-d95c1840e579', '5aa7dbd2-871e-4098-9456-0a7dc388ad58', '17b20bee-4bbd-4647-81f8-53ec5b198a67', '2ec63bb7-1cf1-47c3-9f55-a7f604a234e6', '4e4ad1bf-3762-4047-914f-bc13ffddb03d', 'c74fd12f-ba6c-4acb-ac52-281a6a4052e2', 'cdc7b024-1769-4bd7-8da1-db1410ce2054', '0c230f62-11da-4722-b7ee-2c7f927756ac', 'd40b80e8-3329-466c-bbb4-db7414954fe6', 'a5c8e6e4-cff8-43a8-b111-1ab2ded95131', '0a85315b-03fe-4388-ac95-69bd24b4ffe0', 'e6898d45-aeca-45d7-8022-d1de10e17531', 'ddfce16e-3c74-43bb-a1bc-47eee98d460e', 'ef522aa1-b206-42e4-9451-8f8330c8c617', '0e3c2b9c-006a-4103-8610-ec42dea396ec', '181f045c-008c-4ec3-b552-21a2d3c3dcd8', '8a038165-b508-4e3c-84bf-283b466eaf3f', '99d684e4-e901-465f-9631-3cb443d606b2', '5c60b5fe-91a3-4918-a162-f0f6e6f398e0', '34655655-9b99-4bfb-b6a6-404a70bbacf7', '2f6d528b-aa31-47ce-9f8a-36e604d14200', 'dde3bff3-696f-4af5-9d8a-f6a96940cb89', '5456a878-4fca-4e28-811c-e07f75ebf388', 'dc4597ac-fcc9-420b-a1ab-2afb599de483', '152ff616-d74f-4487-a509-8e2ee73dd815', 'b28a0268-bc22-4979-9243-00379d4d489c', '2ca2b1d9-5225-439b-8c7f-8636f461e964', 'eef3caf1-ebc9-4dbb-b7b2-f897bce4d159', 'd7672999-9c05-4ece-b5ae-825797900d4f', '19ea4b5c-b1e6-4ba8-b236-aea5cdc5a6fc', '34f770af-b89d-470d-9ad5-5bbab1c5c042', '8fc9a02c-2b95-4d1f-a4fe-7259cfcb9212', '05b79c9d-ae4b-42e5-89e2-c030ab03ff01', '52e9c04f-9e09-4361-b20f-3f85da3fad48', 'de667ea2-58bf-4429-90b6-a31fd876ba9c', 'dc130a80-ab62-4649-8088-62fa6f3ac154', 'abe89db7-2460-418a-ae04-56042686c973', 'c137d30b-3318-4e09-a94c-c09ddf6c4991', '1272ec28-7709-4f79-93ea-5a8d88fdca26', '7dee74df-e5d1-4d74-b053-d18d72aa5c82', '73973de6-fe2e-4c18-ad51-ee545ab51fb0', '46fda137-986a-4ffb-8efc-9aa06b4b4f57', '6058e9ec-bb2a-4298-aca1-57a7898606c6', '70921e0f-12ad-4bd8-b466-8bee612fbc7f', 'd5bb8d26-bf02-4846-8635-93b7e0dae81d', '2971b66d-0e96-42db-8ac0-3681653d0a74', 'd3096f6f-8486-4ea9-a588-b01b6328b789', '2ff4abe2-4ead-4c72-bb54-e546cf68e1af', '60949c56-f313-4f75-8cc7-570a0d79aaa2', 'ade2040e-e717-455b-a29f-ef2b686875ef', 'eaffa373-c834-48c0-9de9-47e96ab76572', 'cd11ba8e-f121-4c35-aeff-e397959e3528', 'c27ef575-6c7d-42c4-8989-febf583b43e7', 'f1e1429d-b933-43cd-a13a-b43f924f7f7d', '1129575f-7b38-41f3-9d07-4c869239780d', '3475ecb7-695f-47eb-8c0e-bd6b20bc1e8e', '51696cf1-0555-4a15-893c-23d22df8569f', 'f8d134f8-4651-4b72-99ff-d35b48240a75', 'a642499a-cd27-4178-9a34-ff20e65f0fee', '7cb805d4-6c0c-452d-a3f7-503d63ce6659', 'dac8292a-8bdf-40a4-ad14-94b3acafe20a', '4aad7925-fe0c-4582-a6b5-a159ed512a26', '185863c7-4a7a-442b-b619-3b27d52fc565', '481a37f0-6181-4ebf-a796-c42090a01bc6', 'e326c803-553d-468d-be3e-ae57128a01ee', 'c4cc29f4-4942-4c1b-985a-d860905b3694', 'c2eeb19e-dfd1-4fce-958a-8106e2731a87', 'fa6a0e47-e686-4921-825a-353fa408b8b7', '670e0ef1-35bf-43b4-9c57-7999dfe1df43', 'e233ad2d-b7ef-45cf-89a5-e9cb0d8d53d3', '663051c2-9f46-4459-96cc-9e0163a165ed', '507bcee2-2e69-4397-92c3-b3f35483525e', '8a5e783d-85b5-4104-8e3e-d36f8d72a947', 'd707041b-9815-4f40-8717-752a8c333477', '26a11820-b9b8-4e7f-a12d-a33e191e0809', 'f9758ead-fc2c-4cd2-afdc-4a6f38f35696', 'd5ad282e-1ca7-4dc3-a1ae-f30ebdf306c1', 'af0165f9-b5ed-4c72-95e0-8e016bf882a0', 'cc566465-ab87-4931-a6f2-ca7b7b60b51e', '9c388df4-9f60-4f92-a80c-1c7b0e248ae7', '7a51c7bd-6c07-4b20-a420-d76b3cb02915', '4aacd26c-eefa-4281-a890-29bbaef14b02', '47b57c6b-401c-4831-beff-d3a30d9fc8ba', 'b75a4744-e8df-4232-a97b-fb19314c2586', '029eb3a2-6411-465f-ad89-224b0b4af5b5', '698f8ef0-4d43-4823-89d1-0f935baecf87', '691bc953-9f1a-44dc-ae92-5637e766b210', '10af78ce-4c61-4d6f-b083-999e7588ad8d', '986cfaf9-6ac4-42ee-b8d9-c814d9c1c2b9', '37634bf8-3e45-49b7-a5c1-8db29f974883', 'bf87475e-779d-462f-9d1b-c6569d7c5f00', '0f99b125-67e4-416d-bd23-9f3dde2259c5', '5c8da0d3-a87b-49c0-92c6-bd732fc71597', 'c3a8f684-b756-4eb7-9ff3-a6a72a3cd49c', 'c0edf6bd-cfc6-45e2-b097-41208b6e32dc', 'c31816a2-8a53-44f6-8fe9-e826b71e9627', '9361d585-1a6a-42b0-b6f5-b65b1c774624', 'dcc30533-b50f-414a-a584-ece11cd8c714', 'e3d7120b-3b94-4773-8cb9-1658318fe36c', '78ddccbe-9325-4602-9298-c5d1ede80187', 'bee42cd1-8af7-4325-9a8e-bc5c07980e39', '6a30a54c-106f-487d-b91f-5200d80424da', '06f67880-42d6-4531-879d-0b8e9dde73c5', '009472e6-e959-4a00-b9c8-1871da77a70b', '1d6032c9-94c5-46dd-af15-4da25a1a266d', 'f651270b-ebaf-4805-a40d-ff96d40c0616', '97c0cf5f-0d85-40d0-8a02-9a487377c853', '4b270554-c683-4f4a-80de-a7d680370669', '4848a60c-63ad-4c26-a59e-08bbdae6c70b', 'fba47925-76f4-4019-81d5-ca5632a241f0', 'e091d05a-1d23-4963-8eab-7460d8351c39', '7b6dc753-f81d-4a2f-8b21-da2e9a5e6966', '5bd89b90-679d-4044-a2c4-3193b6c63bed', '49ed4bb0-0156-4a42-9970-9604e19c58d5', '4c9c28e4-a7bd-4f19-a450-26d164e0103c', 'c5605d77-8e3f-4143-b489-f3186377ba17', 'c7f37f3e-0254-451e-9b94-5e23a3b1952f', '8e8c32ed-88ba-4ec5-a91f-5d2063ed6647', '73574320-8208-44df-9696-178c3d1a7356', '9e017ae4-1957-48dc-9031-97bc7ead5417', '3d6d4381-febf-4034-a28f-935aa64a2108', '194c46b7-10d6-478e-83f3-0d97a3d73aed', '015e7e60-934d-4073-ac16-b0a75c941ca9', '943ceb10-3869-41cd-9d5a-b16036d10b71', 'fe297963-716f-4595-9e52-b7d20b81b779', '14e8fdbf-4eed-4633-9344-9ef5a6b02a55', '84be6194-4723-4164-8c94-2865718e1fac', '08a1d115-6433-4b68-9c38-9bc4b7262697', 'f7ff2c98-7f6e-47b3-b147-552225398618', '3d9b0ab0-71f7-4c70-9f6f-485aa680ef6b', '858048f2-cf67-4bd7-9269-1c541b3bf8a1', 'c48ba248-ea2e-427a-bd3f-0b3c418f8879', 'c790de47-0198-4703-b411-5fcecb6e4d9f', '9e55ada2-bb34-4bd8-bf24-b152a86daf5e', 'eaa0f2c6-83e8-424f-8f61-9ce9a210eb0c', '7329da4c-6739-401b-993b-83682e816fd1', '69d09625-8761-4a95-b989-99b85b0685b7', 'b5ab4b17-6204-4f97-9171-4e5c52c063de', 'ea1684dc-accc-4686-9824-b0b2bd68bc5d', '9339d816-129f-4fb2-a450-5e9ec9fe4b77', '160bf099-267b-43d6-87c4-17f1e4ea4de4', '4b0ee9e2-b4af-4c14-a67f-f12fa6982736', 'bc33bf64-2080-4205-bd53-806647cbbf2b', '3c9c90b6-6935-4cfc-8b96-da8b27d7d54c', 'f670748e-b454-4a37-ba3d-db7133e3d3f7', '90cad7ac-552a-45eb-8cf2-89ddcd74917e', 'ce27de82-d56c-4546-b56a-ff95acccc7e5', '914a8d50-893c-4462-8ec6-f1d4a3c3a69a', 'd08e987a-4cb5-46c5-839c-113f62adc657', 'fd2ca9e7-a748-4479-8bf7-fcc32179c3be', '12322083-2606-46a6-8e19-77ddafb024d0', '6dd31184-2320-46c2-9c10-9314fe6aed3e', '087e81f1-aefd-4e99-b8c8-4d3d2732bc3e', 'b8ff0c9b-de94-4a52-a09e-1a523e8af416', '7879d987-365c-4c37-80b4-bbc4783db338', '6ab369bd-e583-4153-8031-83ab9bd98ac1', 'f6882f92-feb3-487f-a16e-c5c337b711dc', '36559900-9525-4e8c-a57b-d497f6e3a6f6', '4f4b6296-d0be-45ba-aa2c-e8d0bb7cd5ea', '63492d00-ab2a-4a08-8959-3225481b0a88', '0c28cfe1-4f6e-42aa-a9d7-05b4417fa79e', '603d7570-5e8b-4538-8aab-c82ae5e9136e', 'aba9eae4-eade-46aa-9c51-c22a65a4dceb', '59c93403-ebb2-42e8-b7ac-9ab9cc0d8933', '1e06b362-ec13-4e70-9ac8-2b1a93430596', '4ed29dba-2f5e-411e-b96e-4330fa811f30', 'aed847b4-1ac1-4935-9a99-36693cf9d6e8', 'f81793c0-5766-4022-9116-2a4cdc3c0b21', '083c4edf-4ea7-46e8-98a3-8ade1f45ae59', '0948f86b-0813-422c-9211-1f41c5f3f224', 'b82279ff-d2fd-46b5-b53a-9dd90d8cf480', 'c4ab522b-7374-4644-afe8-b1f59f8aa010', '0e1a7b9a-d92a-44ea-9119-deb9f3da64b9', '1ce61e8d-5626-4e9b-86ea-632544698fde', '71cb177f-5b08-4bb0-a8e3-0a390bebf5d1', '061d871e-b38c-4aab-8395-742ab699affe', 'f07766e6-c8d2-4d94-ba3c-6c8ec6d3432d', '8cc4c555-813a-4bb8-b5c5-4e4584aa646c', '20176e18-02c9-42e3-a518-b4df4f3caf99', 'd9a0f809-48d8-42fb-8d46-fcb6e462e4cd', '360324cc-6ada-47a7-b5ce-97eecdb8e62e', 'bc3eeab3-4f26-40df-a984-8abfd74b0fab', '23e30dd3-5271-44e0-9e81-bdebdd30e0b1', '1d2b0d7a-f5df-4e39-a075-d2bcd3bfc296', '63306f82-bdec-4234-b151-0ab0a7c38786', '776ad9e3-a483-49b1-9e59-29aa309f5e40', '4bae42c8-0ef7-4d87-8070-2ecfb7a0b01c', '3d87d2fb-8003-4748-97fc-24abcba2d8b7', 'cffdbe97-a8be-4c8a-9b88-21c21fa2c60c', '97d28e0c-4e9c-4891-988b-7d5920b0e17a', 'd78109d1-6aa8-4917-92d4-3ec475472e42', 'f4227802-a53b-435d-96b4-857c3e18beab', 'c983edee-ef31-4646-9b17-87518233cb7e', 'a166ac3e-af84-4dcf-8ec2-0f24dd9dc473', '0f678d70-6f14-47cb-b2f9-088cdb974275', '85713323-f678-4ab5-bc3a-98559e93effa', '169b0ed5-cb80-453b-8934-e6d8aa8d5718', 'f039a2d8-2d9f-4a94-8705-599c112f2712', 'c1e748d1-b15f-4075-a843-516724c966d1', '3e91b218-434b-48d5-9c9a-d38a9e9e231c', '6c1b53b3-e34e-496c-952e-079eaeaf060a', 'c0b2236d-5e0f-4b3a-b2ac-027719887927', '404877d4-ee0a-410a-9876-dc942e25c0dd', '217402c2-bca8-4243-8565-18674c249989', '010c8583-4f4f-4f90-bebc-a2eab020b35e', 'b33ddfdf-16fb-42e8-abe0-88a0800bc426', 'b1f6a337-013a-473d-9cea-b37a8f9b67f6', '1bd2faec-913f-4a40-a763-4dadbdd6eb88', '82972530-4c51-43ae-98ad-6ecc79b8d017', 'a7c7c87a-c8a9-4d4b-82ae-c7242e503dcc', '7c8fe235-1320-4860-a1d7-d62a1fefcea6', '7053dfaa-4d15-42d8-b9c8-d048a0ecab61', '67181152-aa68-4826-8532-d8f5874465e4', '141a60f1-ee58-4772-9b9a-8347ee9d3998', '6b40c892-4e79-46b3-8a63-c0190ae274f0', '2a17451e-f941-4c79-bfac-78bb3fd84c79', '9c0bb663-f78d-49f2-8618-f3179bfa04e2', '3bd7bca7-251a-4ced-b8a1-58e2ec28fbec', '744f20e7-7413-497e-bc45-139583bee0fd', '8539a964-6361-464e-bfd3-9455ca21af53', 'aaccaa14-2af8-410c-b108-7d464eaec060', '9597f87f-d1a7-4821-809a-6ec030f33134', '739da429-249f-4ec2-923c-8bebf5a9be0b', '4cd111e7-44ee-4ee7-ae05-7e5c4e1a1f36', 'abafd08b-dac6-41cf-92ca-d68d42a8ecaf', '48bfd22e-06b7-49ff-9ef0-5fdf33eb1d4d', '2688c70e-a478-44df-a328-565b78524ec1', '78e2c18e-199e-43cb-bb58-cf8ee34fd669', 'b9052130-b627-487b-8006-866e7880659c', 'b4d45dbc-d7f2-4abd-8ea3-5e1398671fb8', '044f9c80-151a-4d62-b90f-5775ad85c1f1', '2b40147e-1d27-4cb8-b7ad-5499a5078097', 'ae4cd1e6-a254-419d-bd74-398b36690a1c', 'af56dbac-961b-470c-a742-373fbec6f2c2', 'def3cd93-1e3f-49bc-8748-727ac0ec28bc', '42cdd3a2-ebc7-4e7d-8700-81a4432affe8', 'ca31c469-14e8-4f16-94a5-38962a8a80cc', '113b475c-474a-4f56-b804-60a5a771ac41', '0bc3e569-b9ea-4cd5-8d7f-63cddc59089c', '4d5f4bc8-2bb4-43b9-a4ea-8855db383fa4', 'de147f55-dea8-4183-9863-b55e61b6dbaa', '89b16149-9014-4c1b-97d6-82ff66e972e8', '5f949433-f38c-484b-a417-6d8d955d0871', '19c8b3fa-2861-416c-8d4c-a00145584000', '4f8baf31-db82-4708-9781-81224c3b95e5', 'c4b467c2-ad6e-45b1-9257-750e5f096d7e', '7d840afb-0fd6-4d36-a048-f821708d49ab', 'edb16724-3bb7-4203-9d04-c1b233290407', '85120813-d49c-4c26-8e57-1321050ba466', 'cce5c07b-ed30-4ef3-8abd-d49d180082ef', '69bc1905-e204-434d-9630-af3cb723febd', 'fef4de38-a8c1-424b-8c6f-7f1e7bba7732', '7b604276-4c08-4dd6-8716-712303706f11', 'ef4e92d7-8a8e-4a8e-b3d7-5289270edc28', '63634356-ee87-4fef-ab39-e9d6ca0db11a', 'acfb7305-60bb-493f-80fd-f983627da86a', 'a23dd3ba-8a31-4816-b718-08762ba1dcd8', 'dd10eba9-858a-4d07-8fbe-e46f85490bca', '1fa0aa5b-cc9d-468b-859c-0ee37485a061', '324af3f5-ba6d-4590-9307-d9840be9dc4d', '24727e6d-8179-4d6e-bb1e-5d18f40a3424', 'a9c7d4a3-8d5d-438c-8eef-f21d284f5367', '11f52e5a-e987-4fe2-bceb-c3f4e68db79a', 'cc921357-978c-4ef8-86c2-c2fa046c6f71', '5fca51f9-42df-46ef-9a46-4a61cfd13c47', '8e1e69b3-0dac-4419-b40b-70f6b6660975', 'c8c72767-f00f-464d-ac0e-8216803354d6', 'f8813aca-7650-48ab-b11b-caf624a7d62d', '3c52ccc7-54b8-48a9-9abf-e20df5184497', '5635f128-2e91-46d1-b846-44b74eb344c3', '210c95be-abf0-4e0e-99e9-78e9d226a259', '8c10dabd-b85b-4c58-87e2-c54ca639546f', '4f87b590-b99f-40aa-b43e-ec22490804c3', 'efba2637-961b-42e9-ae53-293602fc0cdd', '10942f4a-d5c1-435e-8cd7-c90ce90a125a', '2ae92334-91f8-4a0f-b735-13592ec7a9d9', '2651b172-6c0e-4fd5-8d06-0f2217262967', '0b27bd85-a7ed-4f3a-9fd4-98e11f7702e5', '401404b7-dd29-4552-b4eb-071b00800975', '68ba6a08-155f-45d5-ae20-aa4496b78a0b', '1969e542-a651-4cfc-85c8-b9b5849107e4', '96e604bf-4205-4141-b6f0-fc1f9590a388', 'c6024c7e-633e-4ae2-8919-445d01083a91', 'bed2d0de-385b-41e7-8794-b0a7794ac826', '6921f14b-e059-4ec5-b10c-a16f3fc70c6f', 'dc9e2c1e-72e1-40bd-b0ba-c4b01f531d48', 'e44bc4ea-add9-4819-9b24-7e0c1e6d719c', 'd83da1d8-cb9d-4064-8513-2c3b2372206b', 'b30e27e0-b3d5-4d6e-9745-b7bab550facc', '36fea65a-93c0-4114-ba2a-7b16b0b6ba3f', '4bb13242-6350-4e79-a320-f305927cd431', '0cb19192-eaf2-462a-bf3b-dca0bb42647c', '22ee1b11-825b-4465-bccb-f98cc022c578', '7d23a099-f7d3-42e5-8d26-67003f2ee8ae')
     AND term_start IS NOT NULL;
  IF n > 0 THEN
    RAISE EXCEPTION '1536: % of the targeted office_terms rows already have a term_start; aborting', n;
  END IF;
END $$;

-- André Carson (IN) U.S. House of Representatives - Indiana 7th Congressional District · bioguide C001072 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2008-03-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001072); migration 1536'
 WHERE id = 'e9898584-e3c5-489a-a191-870833259325';
-- Erin Houchin (IN) U.S. House of Representatives - Indiana 9th Congressional District · bioguide H001093 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001093); migration 1536'
 WHERE id = '5b32e5f8-50a1-4e9d-9b34-3796c688b234';
-- Jim Baird (IN) U.S. House of Representatives - Indiana 4th Congressional District · bioguide B001307 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001307); migration 1536'
 WHERE id = 'efb602ec-2dd0-4a1f-a562-05bb88960cbe';
-- Mark Messmer (IN) U.S. House of Representatives - Indiana 8th Congressional District · bioguide M001233 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001233); migration 1536'
 WHERE id = 'c55dc843-40ef-4be1-b5fa-c196694b75dc';
-- Todd Young (IN) U.S. Senate - Indiana · bioguide Y000064 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide Y000064); migration 1536'
 WHERE id = '9549694e-a158-4c37-9d0e-34626f587bf7';
-- Jim Banks (IN) U.S. Senate - Indiana · bioguide B001299 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001299); migration 1536'
 WHERE id = '214f3895-aeb4-44a7-acb0-c922806eb6ce';
-- Alex Padilla (CA) U.S. Senate - California · bioguide P000145 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-20', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide P000145); migration 1536'
 WHERE id = 'b4f2dbce-699b-4649-bc0f-b31d343b27e7';
-- Adam B. Schiff (CA) U.S. Senate - California · bioguide S001150 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2024-12-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001150); migration 1536'
 WHERE id = '950a5fff-e9d4-4faa-8a7a-cf1a458f57cf';
-- Elizabeth Warren (MA) U.S. Senate - Massachusetts · bioguide W000817 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000817); migration 1536'
 WHERE id = 'f4da7df3-7936-4e09-9ef3-d7e037fb53bd';
-- Lisa Murkowski (AK) Senator · bioguide M001153 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001153); migration 1536'
 WHERE id = '817d50e5-5389-4f90-bc1a-78459b540a92';
-- Dan Sullivan (AK) Senator · bioguide S001198 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001198); migration 1536'
 WHERE id = '575b3b14-cf66-4751-9398-782aa20deac4';
-- Tommy Tuberville (AL) Senator · bioguide T000278 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide T000278); migration 1536'
 WHERE id = 'b8aa1c9b-602c-48b4-97c6-7f68541ddaab';
-- Katie Britt (AL) Senator · bioguide B001319 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001319); migration 1536'
 WHERE id = '6bee8265-72b9-4521-b0f4-8446a63f1484';
-- John Boozman (AR) Senator · bioguide B001236 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001236); migration 1536'
 WHERE id = 'b0b1888a-f2ec-455d-afad-e34f1f83924d';
-- Tom Cotton (AR) Senator · bioguide C001095 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001095); migration 1536'
 WHERE id = '41ee8c81-54e1-4bda-8a57-f9f839281365';
-- Mark Kelly (AZ) Senator · bioguide K000377 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2020-12-02', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000377); migration 1536'
 WHERE id = '79f82a79-561d-4b7a-9d26-42e88a41170a';
-- Ruben Gallego (AZ) Senator · bioguide G000574 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide G000574); migration 1536'
 WHERE id = 'c90493f7-60d3-41a9-bfae-9bc4d59efb59';
-- Michael Bennet (CO) Senator · bioguide B001267 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-22', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001267); migration 1536'
 WHERE id = 'f77a48fa-6364-4095-bfec-04a46413885b';
-- John Hickenlooper (CO) Senator · bioguide H000273 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H000273); migration 1536'
 WHERE id = 'e78044b9-8a60-4642-8ec8-fa6154dfa237';
-- Richard Blumenthal (CT) Senator · bioguide B001277 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001277); migration 1536'
 WHERE id = '70d04287-ee20-4f3d-b22d-59c92caa697d';
-- Christopher Murphy (CT) Senator · bioguide M001169 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001169); migration 1536'
 WHERE id = '3ddb43aa-e7f3-4ea4-8f25-692e21a8777a';
-- Chris Coons (DE) Senator · bioguide C001088 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2010-11-15', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001088); migration 1536'
 WHERE id = 'c587d67b-ce9c-4923-b89d-60ad2f957877';
-- Lisa Blunt Rochester (DE) Senator · bioguide B001303 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001303); migration 1536'
 WHERE id = 'a4cf695e-61f5-439a-8300-e982972d56bd';
-- Rick Scott (FL) Senator · bioguide S001217 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-08', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001217); migration 1536'
 WHERE id = 'e6bf19f0-0e04-46c9-b547-e94af9b17621';
-- Ashley Moody (FL) Senator · bioguide M001244 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-21', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001244); migration 1536'
 WHERE id = '6d0710c7-fd42-4242-8f16-d418238c4ead';
-- Jon Ossoff (GA) Senator · bioguide O000174 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-20', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide O000174); migration 1536'
 WHERE id = '41f8c75d-024a-457a-bbe4-f9206b9d463c';
-- Raphael Warnock (GA) Senator · bioguide W000790 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-20', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000790); migration 1536'
 WHERE id = '6d1ed881-4ae9-4254-9e4d-15dcfc2f2c11';
-- Brian Schatz (HI) Senator · bioguide S001194 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2012-12-27', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001194); migration 1536'
 WHERE id = '874c32e7-e2b0-4446-9217-500deee8ea91';
-- Mazie Hirono (HI) Senator · bioguide H001042 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001042); migration 1536'
 WHERE id = '1edbdc12-1b84-4255-b25d-84c9d7ae5a64';
-- Chuck Grassley (IA) Senator · bioguide G000386 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1981-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide G000386); migration 1536'
 WHERE id = 'd90373cb-b54e-4173-aff1-f744ff8f2b98';
-- Joni Ernst (IA) Senator · bioguide E000295 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide E000295); migration 1536'
 WHERE id = '19d1728d-b136-4460-af80-b5b9f4748cab';
-- Mike Crapo (ID) Senator · bioguide C000880 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C000880); migration 1536'
 WHERE id = '9782baa6-6c91-4f3e-9043-e5776914cf67';
-- James Risch (ID) Senator · bioguide R000584 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide R000584); migration 1536'
 WHERE id = 'e44746a0-bae5-42aa-bc19-aa25ce116259';
-- Richard Durbin (IL) Senator · bioguide D000563 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide D000563); migration 1536'
 WHERE id = 'e64b2ad6-f67d-4729-b13e-bdc527a02493';
-- Tammy Duckworth (IL) Senator · bioguide D000622 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide D000622); migration 1536'
 WHERE id = 'f6dd5786-2c38-4f21-ac6c-d0f24ff5a4ed';
-- Jerry Moran (KS) Senator · bioguide M000934 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M000934); migration 1536'
 WHERE id = 'cc185493-16a0-42ed-982f-fa7e75dbc2f6';
-- Roger Marshall (KS) Senator · bioguide M001198 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001198); migration 1536'
 WHERE id = '5bd21c43-9f4f-47ee-ad0a-3a832b02dfcd';
-- Mitch McConnell (KY) Senator · bioguide M000355 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1985-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M000355); migration 1536'
 WHERE id = 'c9f68f43-c0ee-4d10-bd94-75675a98998e';
-- Rand Paul (KY) Senator · bioguide P000603 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide P000603); migration 1536'
 WHERE id = 'ef4a86cc-33d3-4a02-a2ee-aa07a8a01b00';
-- Bill Cassidy (LA) Senator · bioguide C001075 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001075); migration 1536'
 WHERE id = 'fbecff96-e2d3-467d-83e9-dfeee9496d46';
-- John Kennedy (LA) Senator · bioguide K000393 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000393); migration 1536'
 WHERE id = '04246315-498f-42d2-806d-00b22b053b75';
-- Chris Van Hollen (MD) Senator · bioguide V000128 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide V000128); migration 1536'
 WHERE id = '98af3fe7-64ba-4175-9ed8-3d70726280ee';
-- Angela Alsobrooks (MD) Senator · bioguide A000382 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide A000382); migration 1536'
 WHERE id = 'd37fd057-14d2-43b4-80a5-7a2282e7beb2';
-- Gary Peters (MI) Senator · bioguide P000595 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide P000595); migration 1536'
 WHERE id = 'c054b617-033e-4ab7-ae6a-d3e07e62ae85';
-- Elissa Slotkin (MI) Senator · bioguide S001208 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001208); migration 1536'
 WHERE id = '753a6ab6-c705-4835-a694-3471529627fe';
-- Amy Klobuchar (MN) Senator · bioguide K000367 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000367); migration 1536'
 WHERE id = 'f25ff3ed-1c31-4cfd-81cd-6ab02e894ecd';
-- Tina Smith (MN) Senator · bioguide S001203 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001203); migration 1536'
 WHERE id = '734c41aa-06d6-4814-a11b-108080366ac7';
-- Josh Hawley (MO) Senator · bioguide H001089 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001089); migration 1536'
 WHERE id = 'f99ac69b-43c2-47b7-9320-58dc73d88495';
-- Eric Schmitt (MO) Senator · bioguide S001227 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001227); migration 1536'
 WHERE id = 'f9b0c61e-60b2-4eff-93fb-8c52c5eadbf9';
-- Roger Wicker (MS) Senator · bioguide W000437 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-12-31', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000437); migration 1536'
 WHERE id = 'bc15b39e-125f-4d96-96df-54ed30ad5fcb';
-- Cindy Hyde-Smith (MS) Senator · bioguide H001079 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-04-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001079); migration 1536'
 WHERE id = '58b0c3c0-68eb-4bf4-a9c3-cdca905d8bcf';
-- Steve Daines (MT) Senator · bioguide D000618 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide D000618); migration 1536'
 WHERE id = '5e2f8810-c413-4829-89b7-b7386c238639';
-- Tim Sheehy (MT) Senator · bioguide S001232 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001232); migration 1536'
 WHERE id = 'ba4f77f6-45c4-4537-8531-f3c2a6b2979a';
-- Thom Tillis (NC) Senator · bioguide T000476 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide T000476); migration 1536'
 WHERE id = '8879364d-d4b2-4e02-b636-f195b0be9ec6';
-- Ted Budd (NC) Senator · bioguide B001305 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001305); migration 1536'
 WHERE id = '48c00557-7efb-451a-b83b-ccee99090154';
-- John Hoeven (ND) Senator · bioguide H001061 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001061); migration 1536'
 WHERE id = 'aab12c9f-caf7-4201-84c2-a50738303cd7';
-- Kevin Cramer (ND) Senator · bioguide C001096 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001096); migration 1536'
 WHERE id = '0df678b4-c584-47a1-ad69-901ce106e13e';
-- Deb Fischer (NE) Senator · bioguide F000463 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide F000463); migration 1536'
 WHERE id = 'acda0b68-b352-4da9-8062-b3fe0def20bb';
-- Pete Ricketts (NE) Senator · bioguide R000618 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-23', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide R000618); migration 1536'
 WHERE id = '7235c55a-7e73-431d-914e-1ff9bc57235c';
-- Jeanne Shaheen (NH) Senator · bioguide S001181 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001181); migration 1536'
 WHERE id = 'bdc30aff-7cf6-4d6c-a982-5bfc11d14a03';
-- Maggie Hassan (NH) Senator · bioguide H001076 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001076); migration 1536'
 WHERE id = 'd451e969-bb1e-432d-8ba0-d098721343c0';
-- Cory Booker (NJ) Senator · bioguide B001288 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-10-31', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001288); migration 1536'
 WHERE id = 'b986fc1b-d8c5-49b8-8fc1-2c1cf926a24c';
-- Andy Kim (NJ) Senator · bioguide K000394 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-12-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000394); migration 1536'
 WHERE id = 'd7a6f747-ce7a-4947-b43e-e300e1ed3e35';
-- Martin Heinrich (NM) Senator · bioguide H001046 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001046); migration 1536'
 WHERE id = '26719271-aa14-4527-9482-bb2de1e5e9da';
-- Ben Ray Luján (NM) Senator · bioguide L000570 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide L000570); migration 1536'
 WHERE id = '31749147-c692-4040-838f-e402b60ffa1e';
-- Catherine Cortez Masto (NV) Senator · bioguide C001113 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001113); migration 1536'
 WHERE id = '1ac8aedb-bb88-465b-8371-ae265c5752e3';
-- Jacky Rosen (NV) Senator · bioguide R000608 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide R000608); migration 1536'
 WHERE id = '96ffd50e-2b77-43c8-bcf2-e36372afa201';
-- Chuck Schumer (NY) Senator · bioguide S000148 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S000148); migration 1536'
 WHERE id = '7714a266-24eb-4ba9-9808-378e29ef3dd3';
-- Kirsten Gillibrand (NY) Senator · bioguide G000555 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-27', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide G000555); migration 1536'
 WHERE id = 'cc2df80b-7b81-40d5-adbd-8bfa583c28c4';
-- Jon Husted (OH) Senator · bioguide H001104 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-21', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H001104); migration 1536'
 WHERE id = 'b9f892a8-e70c-4c00-b293-ea45ab7e52a2';
-- Bernie Moreno (OH) Senator · bioguide M001242 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001242); migration 1536'
 WHERE id = 'f8ddac77-1bb7-40ff-a8ac-9e82b74b76a7';
-- James Lankford (OK) Senator · bioguide L000575 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide L000575); migration 1536'
 WHERE id = 'cc6eacdb-3c3a-4768-9236-9def335a435a';
-- Alan Armstrong (OK) Senator · bioguide A000383 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2026-03-24', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide A000383); migration 1536'
 WHERE id = 'cbf31e17-c411-4e2b-9fdc-0936fb767392';
-- Ron Wyden (OR) U.S. Senate - Oregon · bioguide W000779 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1996-02-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000779); migration 1536'
 WHERE id = '4a4d8079-0931-4d31-8dac-e3852af155f9';
-- Jeff Merkley (OR) U.S. Senate - Oregon · bioguide M001176 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001176); migration 1536'
 WHERE id = '564075dd-ed41-4e24-b447-85023a874a7f';
-- John Fetterman (PA) Senator · bioguide F000479 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide F000479); migration 1536'
 WHERE id = 'c804e7d5-bd63-48a9-823c-ef3f0c7dcc83';
-- Dave McCormick (PA) Senator · bioguide M001243 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001243); migration 1536'
 WHERE id = '2a446a3b-6be7-4b81-90b1-531aefcc78bc';
-- Jack Reed (RI) Senator · bioguide R000122 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide R000122); migration 1536'
 WHERE id = 'fd355098-9568-44b8-ab68-047269668307';
-- Sheldon Whitehouse (RI) Senator · bioguide W000802 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000802); migration 1536'
 WHERE id = '4048582e-28f9-4e22-a797-0e93d82be5fb';
-- Tim Scott (SC) Senator · bioguide S001184 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S001184); migration 1536'
 WHERE id = '468eb0cb-1c1a-4fd6-ad2c-a9e5c0ade8ea';
-- John Thune (SD) Senator · bioguide T000250 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide T000250); migration 1536'
 WHERE id = '0fd49452-8282-4de4-9947-e8aff1a9c44d';
-- Mike Rounds (SD) Senator · bioguide R000605 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide R000605); migration 1536'
 WHERE id = '3261b105-0728-43e0-976d-7d905c534cae';
-- Marsha Blackburn (TN) Senator · bioguide B001243 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001243); migration 1536'
 WHERE id = '4ed53c4a-2ab4-45db-82ab-20594bad849b';
-- Bill Hagerty (TN) Senator · bioguide H000601 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide H000601); migration 1536'
 WHERE id = '7258b590-3e7a-4330-b829-c9665ebf5208';
-- Mike Lee (UT) U.S. Senate - Utah · bioguide L000577 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide L000577); migration 1536'
 WHERE id = '08fd6230-0402-4176-a813-f91fc8d695e8';
-- John Curtis (UT) U.S. Senate - Utah · bioguide C001114 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001114); migration 1536'
 WHERE id = '08313f64-b9e2-4990-864d-89f950e01ca4';
-- Tim Kaine (VA) Senator · bioguide K000384 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000384); migration 1536'
 WHERE id = 'a0d656dc-e2ab-4bee-bc29-36bedf8215ce';
-- Mark Warner (VA) Senator · bioguide W000805 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000805); migration 1536'
 WHERE id = 'faebbb20-0ea5-4619-a448-57d67ee1449c';
-- Bernie Sanders (VT) Senator · bioguide S000033 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide S000033); migration 1536'
 WHERE id = 'b84d0efd-e258-4856-8aeb-46ebea0ced70';
-- Peter Welch (VT) Senator · bioguide W000800 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide W000800); migration 1536'
 WHERE id = '774fa242-44da-42e7-a192-85654e6fdcbf';
-- Patty Murray (WA) Senator · bioguide M001111 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M001111); migration 1536'
 WHERE id = '4617370d-ab15-47ca-952d-8876ce643d95';
-- Maria Cantwell (WA) Senator · bioguide C000127 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C000127); migration 1536'
 WHERE id = '906a4fc4-4148-4489-9bd9-a1e69d61364e';
-- Tammy Baldwin (WI) Senator · bioguide B001230 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001230); migration 1536'
 WHERE id = '7268319f-dad3-4f73-b253-9cafcee46d72';
-- Ron Johnson (WI) Senator · bioguide J000293 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide J000293); migration 1536'
 WHERE id = 'e36f39c7-3728-4139-9bea-51a2025c3988';
-- Shelley Moore Capito (WV) Senator · bioguide C001047 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001047); migration 1536'
 WHERE id = '2fbf8051-baf2-48ef-9814-f2d459e4ce24';
-- Jim Justice (WV) Senator · bioguide J000312 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide J000312); migration 1536'
 WHERE id = 'd37954c6-3c4f-4b93-8165-0eec4fe7200d';
-- John Barrasso (WY) Senator · bioguide B001261 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-06-25', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide B001261); migration 1536'
 WHERE id = 'c34402fe-52c3-421a-850d-bc30b07ba871';
-- Cynthia Lummis (WY) Senator · bioguide L000571 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide L000571); migration 1536'
 WHERE id = '5df17e24-3cbc-4435-8ad2-8e4c84ebd6aa';
-- Ted Cruz (TX) U.S. Senate - Texas · bioguide C001098 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001098); migration 1536'
 WHERE id = '6a97ffd9-c1b7-4c4c-9035-270d8df138b6';
-- John Cornyn (TX) U.S. Senate - Texas · bioguide C001056 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2002-11-30', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001056); migration 1536'
 WHERE id = 'f9e3b85f-be58-42ce-87a7-3c76e37d86ff';
-- Susan M. Collins (ME) U.S. Senate - Maine · bioguide C001035 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide C001035); migration 1536'
 WHERE id = '732c4c3e-89cf-4c10-b551-1a0b17398916';
-- Angus S. King, Jr. (ME) U.S. Senate - Maine · bioguide K000383 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide K000383); migration 1536'
 WHERE id = '49877611-e41a-4a5d-964d-ed15ce748b6b';
-- Edward J. Markey (MA) U.S. Senate - Massachusetts · bioguide M000133 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-07-16', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken sen service (bioguide M000133); migration 1536'
 WHERE id = '29473826-72ab-442a-ba39-7374ecc180a3';
-- Jay Obernolte (CA) Representative · bioguide O000019 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000019); migration 1536'
 WHERE id = '61baa8d7-54a0-4215-b9be-83b7d6dc3efe';
-- Julia Brownley (CA) Representative · bioguide B001285 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001285); migration 1536'
 WHERE id = '86b4d695-99b2-4c42-bc94-a7fbbed64534';
-- George Whitesides (CA) Representative · bioguide W000830 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000830); migration 1536'
 WHERE id = 'd6bddc1c-382b-4ed0-bc77-e15c5697be70';
-- Judy Chu (CA) Representative · bioguide C001080 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2009-07-16', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001080); migration 1536'
 WHERE id = 'b1c49d8f-a1f8-4840-bd83-15b57dab9221';
-- Luz Maria Rivas (CA) Representative · bioguide R000620 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000620); migration 1536'
 WHERE id = '7f148a24-e048-4dab-bf6f-763f52810c26';
-- Laura Friedman (CA) Representative · bioguide F000483 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000483); migration 1536'
 WHERE id = '8ecda4bd-182c-4f93-871a-490d04f1eac9';
-- Gil Cisneros (CA) Representative · bioguide C001123 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001123); migration 1536'
 WHERE id = '78556b10-7960-43ce-b59a-6336623f2a9c';
-- Brad Sherman (CA) Representative · bioguide S000344 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000344); migration 1536'
 WHERE id = 'e583c777-0ef9-4faf-ad78-9975d28a77ad';
-- Jimmy Gomez (CA) Representative · bioguide G000585 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2017-07-11', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000585); migration 1536'
 WHERE id = '12a5d9ec-1e92-42a9-9bc0-96fa75d81bde';
-- Norma Torres (CA) Representative · bioguide T000474 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000474); migration 1536'
 WHERE id = '506c540f-67fa-401f-91d8-428e9f6b75af';
-- Ted W. Lieu (CA) Representative · bioguide L000582 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000582); migration 1536'
 WHERE id = '28ab1073-0e74-4853-a6e3-850d10c09569';
-- Sydney Kamlager-Dove (CA) Representative · bioguide K000400 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000400); migration 1536'
 WHERE id = 'dc48d107-f499-48dd-85ae-e73ff2c5a75d';
-- Linda T. Sanchez (CA) Representative · bioguide S001156 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001156); migration 1536'
 WHERE id = '802ec670-cc4c-4daa-aa5c-f2f9d75ab7dc';
-- Robert Garcia (CA) Representative · bioguide G000598 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000598); migration 1536'
 WHERE id = 'cff23a15-4454-4e37-9c36-f7d2313daef1';
-- Maxine Waters (CA) Representative · bioguide W000187 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '1991-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000187); migration 1536'
 WHERE id = 'd8a9a0e8-67c0-4955-9650-ddb56dab9f69';
-- Derek Tran (CA) Representative · bioguide T000491 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000491); migration 1536'
 WHERE id = '66534f7b-a842-4c4c-a8ac-ecdd43b29e84';
-- Pete Aguilar (CA) Representative · bioguide A000371 · matched by bioguide
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000371); migration 1536'
 WHERE id = '55af15e1-27a8-477f-b45f-a99988e1edf5';
-- Gilbert Cisneros (CA) U.S. Representative · bioguide C001123 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001123); migration 1536'
 WHERE id = 'f28efa1a-25f9-4311-b22d-e99b761ea91a';
-- Raul Ruiz (CA) U.S. Representative · bioguide R000599 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000599); migration 1536'
 WHERE id = '181520b6-b803-443b-b61e-eb8eedc28479';
-- Nathaniel Moran (TX) Representative · bioguide M001224 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001224); migration 1536'
 WHERE id = 'b7d84ec7-e3f1-478a-9533-22e7b8c98ee0';
-- Dan Crenshaw (TX) Representative · bioguide C001120 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001120); migration 1536'
 WHERE id = '82c0dbf9-3c5b-4331-8849-7f328f5fb69e';
-- Keith Self (TX) Representative · bioguide S001224 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001224); migration 1536'
 WHERE id = '3c8ac872-25c7-4c6a-b775-5343ed3049fa';
-- Pat Fallon (TX) Representative · bioguide F000246 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000246); migration 1536'
 WHERE id = 'cc0e030d-fc27-472b-9653-94550ceef922';
-- Lance Gooden (TX) Representative · bioguide G000589 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000589); migration 1536'
 WHERE id = 'ef8fa168-e48a-4bba-970e-920206905a5d';
-- Jake Ellzey (TX) Representative · bioguide E000071 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-07-30', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000071); migration 1536'
 WHERE id = 'cc97886e-0a1f-4f61-a2eb-df260722c45b';
-- Lizzie Fletcher (TX) Representative · bioguide F000468 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000468); migration 1536'
 WHERE id = '9ba7af7e-5919-4e41-bed4-3d41bf2f173b';
-- Morgan Luttrell (TX) Representative · bioguide L000603 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000603); migration 1536'
 WHERE id = 'ab222806-9857-4b19-b9ed-1d1a28018061';
-- Al Green (TX) Representative · bioguide G000553 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000553); migration 1536'
 WHERE id = '0f6f966b-387d-4fa4-9024-55a2e5eb58f0';
-- Michael McCaul (TX) Representative · bioguide M001157 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001157); migration 1536'
 WHERE id = 'f26350e3-f713-4a01-804e-a0a0a613fc4a';
-- August Pfluger (TX) Representative · bioguide P000048 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000048); migration 1536'
 WHERE id = 'a51a0323-560b-463f-9bca-2a2dbf43cc30';
-- Craig Goldman (TX) Representative · bioguide G000601 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000601); migration 1536'
 WHERE id = '18d8f3d9-9f24-42a5-ad9f-e207c83672fd';
-- Ronny Jackson (TX) Representative · bioguide J000304 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000304); migration 1536'
 WHERE id = 'b0eba786-d54e-4eaa-b513-2bd05438bfac';
-- Randy Weber (TX) Representative · bioguide W000814 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000814); migration 1536'
 WHERE id = 'fa1c5268-ac6c-4bc2-b84e-455b1cd69b95';
-- Monica De La Cruz (TX) Representative · bioguide D000594 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000594); migration 1536'
 WHERE id = 'e456ba12-cb4b-4f52-a56e-a8fea087d216';
-- Veronica Escobar (TX) Representative · bioguide E000299 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000299); migration 1536'
 WHERE id = 'af945e76-cf8d-4612-a237-0c034568edbc';
-- Pete Sessions (TX) Representative · bioguide S000250 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000250); migration 1536'
 WHERE id = '1a781d2a-4791-4528-badb-6bbe8c47ad64';
-- Christian Menefee (TX) Representative · bioguide M001245 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2026-02-02', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001245); migration 1536'
 WHERE id = '1a638ae7-bd1f-4f95-82f9-b8eb79f24f0c';
-- Jodey Arrington (TX) Representative · bioguide A000375 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000375); migration 1536'
 WHERE id = '6227e743-5d40-4b50-953f-59c82ecb54fd';
-- Joaquin Castro (TX) Representative · bioguide C001091 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001091); migration 1536'
 WHERE id = 'da9dd62c-d52d-4aef-ba9f-1ac0a43c160e';
-- Chip Roy (TX) Representative · bioguide R000614 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000614); migration 1536'
 WHERE id = 'be73582c-c1dd-4f04-8e41-fe922bb314c9';
-- Troy Nehls (TX) Representative · bioguide N000026 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000026); migration 1536'
 WHERE id = '237750a3-c777-45d2-824a-8bcb98f1346a';
-- Beth Van Duyne (TX) Representative · bioguide V000134 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000134); migration 1536'
 WHERE id = '6d78c2d2-4d91-4e8b-91ec-3790106f92ab';
-- Roger Williams (TX) Representative · bioguide W000816 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000816); migration 1536'
 WHERE id = '2028314e-56a8-4344-9f61-85d97845d63d';
-- Brandon Gill (TX) Representative · bioguide G000603 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000603); migration 1536'
 WHERE id = 'c02ee742-9c2c-4a30-9414-a5a289719917';
-- Michael Cloud (TX) Representative · bioguide C001115 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-07-10', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001115); migration 1536'
 WHERE id = '1e13d3f4-ae50-4d61-a3d5-8b8e12d0a1c8';
-- Henry Cuellar (TX) Representative · bioguide C001063 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001063); migration 1536'
 WHERE id = '5fae2e82-9956-4b8a-94e2-53d5a4e59a55';
-- Sylvia Garcia (TX) Representative · bioguide G000587 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000587); migration 1536'
 WHERE id = 'c2704144-1d24-4ab3-afba-e6863c7e0712';
-- Jasmine Crockett (TX) Representative · bioguide C001130 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001130); migration 1536'
 WHERE id = '43d2c8d7-f6a9-4626-9fe6-e2fa679811c7';
-- John Carter (TX) Representative · bioguide C001051 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001051); migration 1536'
 WHERE id = '3455e028-5aef-4335-b594-c595a68a1550';
-- Julie Johnson (TX) Representative · bioguide J000310 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000310); migration 1536'
 WHERE id = '3baeaed2-9e67-4802-a2c4-d9ff0c47de05';
-- Marc Veasey (TX) Representative · bioguide V000131 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000131); migration 1536'
 WHERE id = 'd26f0bd5-aed4-49e9-ad5d-68186ce97362';
-- Vicente Gonzalez (TX) Representative · bioguide G000581 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000581); migration 1536'
 WHERE id = 'b06e1b70-55f3-4bd9-94f5-2ac0b1b4e2e7';
-- Greg Casar (TX) Representative · bioguide C001131 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001131); migration 1536'
 WHERE id = 'e0281e7c-6edd-4602-9763-493a19047dd8';
-- Brian Babin (TX) Representative · bioguide B001291 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001291); migration 1536'
 WHERE id = 'c5334d4e-9609-4c43-9cb5-8edbd4c44e12';
-- Lloyd Doggett (TX) Representative · bioguide D000399 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1995-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000399); migration 1536'
 WHERE id = 'd3bf1e17-f59c-4057-8cd3-d4bb6892c1f7';
-- Wesley Hunt (TX) Representative · bioguide H001095 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001095); migration 1536'
 WHERE id = '411a0f3a-cb0f-4177-9966-bec211faefd9';
-- Richard Neal (MA) Representative · bioguide N000015 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1989-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000015); migration 1536'
 WHERE id = '7c310b28-dc7e-4094-be48-4d1f1dd74347';
-- Jim McGovern (MA) Representative · bioguide M000312 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M000312); migration 1536'
 WHERE id = 'dced4f84-54be-44b8-9bdf-c4a0fb8f743b';
-- Lori Trahan (MA) Representative · bioguide T000482 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000482); migration 1536'
 WHERE id = '319ba9c4-be44-44ad-a6ab-2a459638d4fb';
-- Jake Auchincloss (MA) Representative · bioguide A000148 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000148); migration 1536'
 WHERE id = 'd3aa1b4b-ff07-4a8a-850c-14d604ce4d92';
-- Katherine Clark (MA) Representative · bioguide C001101 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-12-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001101); migration 1536'
 WHERE id = '412dabff-f49e-4661-a4d9-f37977fcabb5';
-- Seth Moulton (MA) Representative · bioguide M001196 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001196); migration 1536'
 WHERE id = '98d51f86-23c9-4e86-bd53-91428749924c';
-- Ayanna Pressley (MA) Representative · bioguide P000617 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000617); migration 1536'
 WHERE id = 'e693ca9a-a4fa-48a8-94d4-c3397894526c';
-- Stephen Lynch (MA) Representative · bioguide L000562 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-10-23', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000562); migration 1536'
 WHERE id = 'c2052634-26ed-4054-b56e-38650f9342d2';
-- Chellie Pingree (ME) Representative · bioguide P000597 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000597); migration 1536'
 WHERE id = '3ca17bf0-af00-40db-9f34-d508a86b9b22';
-- Jared Golden (ME) Representative · bioguide G000592 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000592); migration 1536'
 WHERE id = 'ab6579df-5446-46bf-9e67-40560c8d4687';
-- Jared Huffman (CA) U.S. Representative · bioguide H001068 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001068); migration 1536'
 WHERE id = '5c7f0e13-92ad-4aee-8f9d-66692029ec6b';
-- Kevin Kiley (CA) U.S. Representative · bioguide K000401 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000401); migration 1536'
 WHERE id = '0d28cadb-d38b-4c15-a28d-431df0b1fa60';
-- Mike Thompson (CA) U.S. Representative · bioguide T000460 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000460); migration 1536'
 WHERE id = '8afc8857-6bd6-4a62-aca6-b9d9f81118dd';
-- Tom McClintock (CA) U.S. Representative · bioguide M001177 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001177); migration 1536'
 WHERE id = 'c87d5fe5-37c0-4336-8f8f-da5267cef50c';
-- Ami Bera (CA) U.S. Representative · bioguide B001287 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001287); migration 1536'
 WHERE id = '4766601c-1672-4578-9588-7d067e333ad3';
-- Doris Matsui (CA) U.S. Representative · bioguide M001163 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-03-10', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001163); migration 1536'
 WHERE id = '1cf44c8d-15da-4716-bdcf-21a1e213df32';
-- John Garamendi (CA) U.S. Representative · bioguide G000559 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-11-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000559); migration 1536'
 WHERE id = '4ebf8ef9-2a9b-44c0-9131-f27cb9c32124';
-- Josh Harder (CA) U.S. Representative · bioguide H001090 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001090); migration 1536'
 WHERE id = '7cd8e684-bb28-4241-9d59-b7a4b1c4102b';
-- Mark DeSaulnier (CA) U.S. Representative · bioguide D000623 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000623); migration 1536'
 WHERE id = '0251de35-dc30-4901-8afc-b1167914a77f';
-- Nancy Pelosi (CA) U.S. Representative · bioguide P000197 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1987-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000197); migration 1536'
 WHERE id = '4a3ea779-ae31-477b-b8f7-5b5d4afd4ac5';
-- Lateefah Simon (CA) U.S. Representative · bioguide S001231 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001231); migration 1536'
 WHERE id = '9366546b-16e8-40f8-9145-ed60638298da';
-- Adam Gray (CA) U.S. Representative · bioguide G000605 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000605); migration 1536'
 WHERE id = 'b7cc01e9-aee4-48f6-be8f-117f7b1256c7';
-- Kevin Mullin (CA) U.S. Representative · bioguide M001225 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001225); migration 1536'
 WHERE id = '724baf2c-a7c6-494c-9530-f7ff7e20e3fd';
-- Sam Liccardo (CA) U.S. Representative · bioguide L000607 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000607); migration 1536'
 WHERE id = '9d687807-0a94-4337-93d1-02a8e1c3e6b0';
-- Ro Khanna (CA) U.S. Representative · bioguide K000389 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000389); migration 1536'
 WHERE id = '4a77d835-0150-418f-b0ee-034119a75bed';
-- Zoe Lofgren (CA) U.S. Representative · bioguide L000397 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1995-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000397); migration 1536'
 WHERE id = 'dcf0502c-b059-4bde-b72f-3cc21872add8';
-- Jimmy Panetta (CA) U.S. Representative · bioguide P000613 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000613); migration 1536'
 WHERE id = 'e2e7fb5a-d172-4cbb-9357-d78758e77e04';
-- Vince Fong (CA) U.S. Representative · bioguide F000480 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-06-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000480); migration 1536'
 WHERE id = '7fd86011-1622-4bda-8bee-cb1128ea756e';
-- Jim Costa (CA) U.S. Representative · bioguide C001059 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001059); migration 1536'
 WHERE id = '6dfe7358-d7d2-4f97-aadd-6f589ef98a97';
-- David Valadao (CA) U.S. Representative · bioguide V000129 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000129); migration 1536'
 WHERE id = '94b189f1-7c8f-4b25-8ebe-648611e5a53c';
-- Salud Carbajal (CA) U.S. Representative · bioguide C001112 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001112); migration 1536'
 WHERE id = '4bb4a12e-6fe4-4dfe-8fec-6d50c3bffcf8';
-- Raul Ruiz (CA) U.S. Representative · bioguide R000599 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000599); migration 1536'
 WHERE id = '6898ac61-873e-4242-a9c1-c358d45581fb';
-- Mark Takano (CA) U.S. Representative · bioguide T000472 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000472); migration 1536'
 WHERE id = '51c8eb69-4e2b-43d2-be82-c573a5f69d09';
-- Young Kim (CA) U.S. Representative · bioguide K000397 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000397); migration 1536'
 WHERE id = '22ea82af-b232-45fc-8781-d57b172ca25c';
-- Ken Calvert (CA) U.S. Representative · bioguide C000059 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C000059); migration 1536'
 WHERE id = '67615c90-8ab2-4ad0-b4e9-46fecc409954';
-- Dave Min (CA) U.S. Representative · bioguide M001241 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001241); migration 1536'
 WHERE id = 'd54dce90-d3ef-49df-9da7-198761341b6d';
-- Darrell Issa (CA) U.S. Representative · bioguide I000056 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide I000056); migration 1536'
 WHERE id = '758afe0a-df47-4855-aa11-547230a328bc';
-- Mike Levin (CA) U.S. Representative · bioguide L000593 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000593); migration 1536'
 WHERE id = 'e73235d5-806c-4141-a6ec-d5d1fdc91fc2';
-- Scott Peters (CA) U.S. Representative · bioguide P000608 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000608); migration 1536'
 WHERE id = '9ecdff89-7245-4191-896e-272926f95480';
-- Sara Jacobs (CA) U.S. Representative · bioguide J000305 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000305); migration 1536'
 WHERE id = '4b9dbd6b-1927-4a2f-ba8c-52f4ddd371e9';
-- Juan Vargas (CA) U.S. Representative · bioguide V000130 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000130); migration 1536'
 WHERE id = '6b876fdc-4da4-42bd-b6fe-71ecb9f42c76';
-- James Gallagher (CA) U.S. Representative · bioguide G000607 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2026-06-10', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000607); migration 1536'
 WHERE id = '1bee1841-6836-47d2-806e-3da4a662ef50';
-- Blake Moore (UT) Representative · bioguide M001213 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001213); migration 1536'
 WHERE id = 'eb842055-54d5-43ba-9c11-183fbd3552a9';
-- Celeste Maloy (UT) Representative · bioguide M001228 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-11-21', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001228); migration 1536'
 WHERE id = 'b5faeaf1-1c18-4300-8f36-ab42e7fffe3b';
-- Mike Kennedy (UT) Representative · bioguide K000403 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000403); migration 1536'
 WHERE id = '724dbf54-862a-4994-bcf1-e87a091ab849';
-- Burgess Owens (UT) Representative · bioguide O000086 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000086); migration 1536'
 WHERE id = '12a7bfed-c9f0-498a-b46f-3ba2a8597c10';
-- Suzanne Bonamici (OR) Representative · bioguide B001278 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2012-02-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001278); migration 1536'
 WHERE id = '84633187-c4de-46d3-aa14-f220120a4e26';
-- Cliff Bentz (OR) Representative · bioguide B000668 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B000668); migration 1536'
 WHERE id = '031b576a-3c38-419d-8edc-9f7a45c82678';
-- Maxine Dexter (OR) Representative · bioguide D000635 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000635); migration 1536'
 WHERE id = 'cc75e22b-ac0b-4215-872d-a4079801b4ba';
-- Val Hoyle (OR) Representative · bioguide H001094 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001094); migration 1536'
 WHERE id = 'd441d833-4b30-4b80-a924-e7c2f4b0af7d';
-- Janelle Bynum (OR) Representative · bioguide B001326 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001326); migration 1536'
 WHERE id = 'd892a898-75db-4ac2-9c64-03907ee9e6f6';
-- Andrea Salinas (OR) Representative · bioguide S001226 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001226); migration 1536'
 WHERE id = '016f0e65-cf0f-46d4-a3fa-62f36510d213';
-- Andy Harris (MD) U.S. Representative · bioguide H001052 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001052); migration 1536'
 WHERE id = 'b0abce0c-7c44-4d64-ad37-ec6889244bf6';
-- Johnny Olszewski (MD) U.S. Representative · bioguide O000176 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000176); migration 1536'
 WHERE id = 'a180d10e-86f1-419e-bc91-a3b82a4d7a80';
-- Sarah Elfreth (MD) U.S. Representative · bioguide E000301 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000301); migration 1536'
 WHERE id = 'a76e2eab-8c3c-41a2-8ad5-292e62ae14f6';
-- Glenn Ivey (MD) U.S. Representative · bioguide I000058 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide I000058); migration 1536'
 WHERE id = '38a25ac7-f273-49dc-adda-affe38cf88d3';
-- Steny Hoyer (MD) U.S. Representative · bioguide H000874 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1981-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H000874); migration 1536'
 WHERE id = 'a7488ac8-795c-4c31-9e62-79d8be85a3e5';
-- April McClain Delaney (MD) U.S. Representative · bioguide M001232 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001232); migration 1536'
 WHERE id = 'e88ed49f-6dce-44b0-b71a-23152fa748d7';
-- Kweisi Mfume (MD) U.S. Representative · bioguide M000687 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2020-05-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M000687); migration 1536'
 WHERE id = '0cb66651-8f9f-4747-8624-2637230d73ab';
-- Jamie Raskin (MD) U.S. Representative · bioguide R000606 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000606); migration 1536'
 WHERE id = '90fb4dab-4a30-4183-bc32-630de68c4bd3';
-- Rob Wittman (VA) U.S. Representative · bioguide W000804 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-12-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000804); migration 1536'
 WHERE id = 'a24c1c41-140d-460d-a495-6ea1a629ff87';
-- Jen Kiggans (VA) U.S. Representative · bioguide K000399 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000399); migration 1536'
 WHERE id = '30719974-35a9-450d-9d3b-6e834bfc85c5';
-- Bobby Scott (VA) U.S. Representative · bioguide S000185 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000185); migration 1536'
 WHERE id = 'fb744540-1fff-4537-81aa-a49be750d40e';
-- Jennifer McClellan (VA) U.S. Representative · bioguide M001227 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-03-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001227); migration 1536'
 WHERE id = '69e6d1d6-75bc-4354-be31-d5d9de4a782d';
-- Eugene Vindman (VA) U.S. Representative · bioguide V000138 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000138); migration 1536'
 WHERE id = '4c784013-6307-4900-bd0a-baeae5b573fa';
-- Don Beyer (VA) U.S. Representative · bioguide B001292 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001292); migration 1536'
 WHERE id = 'e1c91912-eb5a-440e-bac3-b774e2575197';
-- Suhas Subramanyam (VA) U.S. Representative · bioguide S001230 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001230); migration 1536'
 WHERE id = '7465949a-4c6c-4091-bcf2-1913910e4d83';
-- James Walkinshaw (VA) U.S. Representative · bioguide W000831 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-09-10', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000831); migration 1536'
 WHERE id = 'a728cbc0-3170-448b-9e5a-2ebb8aae5211';
-- Barry Moore (AL) U.S. Representative · bioguide M001212 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001212); migration 1536'
 WHERE id = '632da81c-bef6-4ece-a84e-31c27098c933';
-- Shomari Figures (AL) U.S. Representative · bioguide F000481 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000481); migration 1536'
 WHERE id = 'f07d32e3-e0fe-4ecf-9212-38ace392dedf';
-- Mike Rogers (AL) U.S. Representative · bioguide R000575 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000575); migration 1536'
 WHERE id = '9519363f-7b8b-4ee0-84b5-5ba447c24ad6';
-- Robert B. Aderholt (AL) U.S. Representative · bioguide A000055 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000055); migration 1536'
 WHERE id = 'b649164e-31ff-457c-b76c-ebf6c1bfca9b';
-- Dale W. Strong (AL) U.S. Representative · bioguide S001220 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001220); migration 1536'
 WHERE id = '39ff0f79-c971-47a6-93c2-2b04ccb603a7';
-- Gary J. Palmer (AL) U.S. Representative · bioguide P000609 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000609); migration 1536'
 WHERE id = 'a0876ccc-6a95-4645-9b5e-cf598658384f';
-- Terri A. Sewell (AL) U.S. Representative · bioguide S001185 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001185); migration 1536'
 WHERE id = '7563248c-3189-4d14-88b7-158bc3dfe5b3';
-- Nicholas J. Begich III (AK) U.S. Representative · bioguide B001323 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001323); migration 1536'
 WHERE id = '75a70b3d-e33c-4589-8336-e4255e66298b';
-- David Schweikert (AZ) U.S. Representative · bioguide S001183 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001183); migration 1536'
 WHERE id = 'a97ea95a-12ca-4cd9-8b9c-d95c1840e579';
-- Elijah Crane (AZ) U.S. Representative · bioguide C001132 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001132); migration 1536'
 WHERE id = '5aa7dbd2-871e-4098-9456-0a7dc388ad58';
-- Yassamin Ansari (AZ) U.S. Representative · bioguide A000381 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000381); migration 1536'
 WHERE id = '17b20bee-4bbd-4647-81f8-53ec5b198a67';
-- Greg Stanton (AZ) U.S. Representative · bioguide S001211 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001211); migration 1536'
 WHERE id = '2ec63bb7-1cf1-47c3-9f55-a7f604a234e6';
-- Andy Biggs (AZ) U.S. Representative · bioguide B001302 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001302); migration 1536'
 WHERE id = '4e4ad1bf-3762-4047-914f-bc13ffddb03d';
-- Juan Ciscomani (AZ) U.S. Representative · bioguide C001133 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001133); migration 1536'
 WHERE id = 'c74fd12f-ba6c-4acb-ac52-281a6a4052e2';
-- Adelita S. Grijalva (AZ) U.S. Representative · bioguide G000606 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-11-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000606); migration 1536'
 WHERE id = 'cdc7b024-1769-4bd7-8da1-db1410ce2054';
-- Abraham J. Hamadeh (AZ) U.S. Representative · bioguide H001098 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001098); migration 1536'
 WHERE id = '0c230f62-11da-4722-b7ee-2c7f927756ac';
-- Paul A. Gosar (AZ) U.S. Representative · bioguide G000565 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000565); migration 1536'
 WHERE id = 'd40b80e8-3329-466c-bbb4-db7414954fe6';
-- Eric A. "Rick" Crawford (AR) U.S. Representative · bioguide C001087 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001087); migration 1536'
 WHERE id = 'a5c8e6e4-cff8-43a8-b111-1ab2ded95131';
-- J. French Hill (AR) U.S. Representative · bioguide H001072 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001072); migration 1536'
 WHERE id = '0a85315b-03fe-4388-ac95-69bd24b4ffe0';
-- Steve Womack (AR) U.S. Representative · bioguide W000809 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000809); migration 1536'
 WHERE id = 'e6898d45-aeca-45d7-8022-d1de10e17531';
-- Bruce Westerman (AR) U.S. Representative · bioguide W000821 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000821); migration 1536'
 WHERE id = 'ddfce16e-3c74-43bb-a1bc-47eee98d460e';
-- Diana DeGette (CO) U.S. Representative · bioguide D000197 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000197); migration 1536'
 WHERE id = 'ef522aa1-b206-42e4-9451-8f8330c8c617';
-- Joe Neguse (CO) U.S. Representative · bioguide N000191 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000191); migration 1536'
 WHERE id = '0e3c2b9c-006a-4103-8610-ec42dea396ec';
-- Jeff Hurd (CO) U.S. Representative · bioguide H001100 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001100); migration 1536'
 WHERE id = '181f045c-008c-4ec3-b552-21a2d3c3dcd8';
-- Lauren Boebert (CO) U.S. Representative · bioguide B000825 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B000825); migration 1536'
 WHERE id = '8a038165-b508-4e3c-84bf-283b466eaf3f';
-- Jeff Crank (CO) U.S. Representative · bioguide C001137 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001137); migration 1536'
 WHERE id = '99d684e4-e901-465f-9631-3cb443d606b2';
-- Jason Crow (CO) U.S. Representative · bioguide C001121 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001121); migration 1536'
 WHERE id = '5c60b5fe-91a3-4918-a162-f0f6e6f398e0';
-- Brittany Pettersen (CO) U.S. Representative · bioguide P000620 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000620); migration 1536'
 WHERE id = '34655655-9b99-4bfb-b6a6-404a70bbacf7';
-- Gabe Evans (CO) U.S. Representative · bioguide E000300 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000300); migration 1536'
 WHERE id = '2f6d528b-aa31-47ce-9f8a-36e604d14200';
-- John B. Larson (CT) U.S. Representative · bioguide L000557 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000557); migration 1536'
 WHERE id = 'dde3bff3-696f-4af5-9d8a-f6a96940cb89';
-- Joe Courtney (CT) U.S. Representative · bioguide C001069 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001069); migration 1536'
 WHERE id = '5456a878-4fca-4e28-811c-e07f75ebf388';
-- Rosa L. DeLauro (CT) U.S. Representative · bioguide D000216 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1991-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000216); migration 1536'
 WHERE id = 'dc4597ac-fcc9-420b-a1ab-2afb599de483';
-- James A. Himes (CT) U.S. Representative · bioguide H001047 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001047); migration 1536'
 WHERE id = '152ff616-d74f-4487-a509-8e2ee73dd815';
-- Jahana Hayes (CT) U.S. Representative · bioguide H001081 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001081); migration 1536'
 WHERE id = 'b28a0268-bc22-4979-9243-00379d4d489c';
-- Sarah McBride (DE) U.S. Representative · bioguide M001238 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001238); migration 1536'
 WHERE id = '2ca2b1d9-5225-439b-8c7f-8636f461e964';
-- Jimmy Patronis (FL) U.S. Representative · bioguide P000622 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-04-02', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000622); migration 1536'
 WHERE id = 'eef3caf1-ebc9-4dbb-b7b2-f897bce4d159';
-- Neal P. Dunn (FL) U.S. Representative · bioguide D000628 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000628); migration 1536'
 WHERE id = 'd7672999-9c05-4ece-b5ae-825797900d4f';
-- Kat Cammack (FL) U.S. Representative · bioguide C001039 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001039); migration 1536'
 WHERE id = '19ea4b5c-b1e6-4ba8-b236-aea5cdc5a6fc';
-- Aaron Bean (FL) U.S. Representative · bioguide B001314 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001314); migration 1536'
 WHERE id = '34f770af-b89d-470d-9ad5-5bbab1c5c042';
-- John H. Rutherford (FL) U.S. Representative · bioguide R000609 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000609); migration 1536'
 WHERE id = '8fc9a02c-2b95-4d1f-a4fe-7259cfcb9212';
-- Randy Fine (FL) U.S. Representative · bioguide F000484 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-04-02', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000484); migration 1536'
 WHERE id = '05b79c9d-ae4b-42e5-89e2-c030ab03ff01';
-- Cory Mills (FL) U.S. Representative · bioguide M001216 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001216); migration 1536'
 WHERE id = '52e9c04f-9e09-4361-b20f-3f85da3fad48';
-- Mike Haridopolos (FL) U.S. Representative · bioguide H001099 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001099); migration 1536'
 WHERE id = 'de667ea2-58bf-4429-90b6-a31fd876ba9c';
-- Darren Soto (FL) U.S. Representative · bioguide S001200 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001200); migration 1536'
 WHERE id = 'dc130a80-ab62-4649-8088-62fa6f3ac154';
-- Maxwell Frost (FL) U.S. Representative · bioguide F000476 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000476); migration 1536'
 WHERE id = 'abe89db7-2460-418a-ae04-56042686c973';
-- Daniel Webster (FL) U.S. Representative · bioguide W000806 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000806); migration 1536'
 WHERE id = 'c137d30b-3318-4e09-a94c-c09ddf6c4991';
-- Gus M. Bilirakis (FL) U.S. Representative · bioguide B001257 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001257); migration 1536'
 WHERE id = '1272ec28-7709-4f79-93ea-5a8d88fdca26';
-- Anna Paulina Luna (FL) U.S. Representative · bioguide L000596 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000596); migration 1536'
 WHERE id = '7dee74df-e5d1-4d74-b053-d18d72aa5c82';
-- Kathy Castor (FL) U.S. Representative · bioguide C001066 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001066); migration 1536'
 WHERE id = '73973de6-fe2e-4c18-ad51-ee545ab51fb0';
-- Laurel M. Lee (FL) U.S. Representative · bioguide L000597 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000597); migration 1536'
 WHERE id = '46fda137-986a-4ffb-8efc-9aa06b4b4f57';
-- Vern Buchanan (FL) U.S. Representative · bioguide B001260 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001260); migration 1536'
 WHERE id = '6058e9ec-bb2a-4298-aca1-57a7898606c6';
-- W. Gregory Steube (FL) U.S. Representative · bioguide S001214 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001214); migration 1536'
 WHERE id = '70921e0f-12ad-4bd8-b466-8bee612fbc7f';
-- Scott Franklin (FL) U.S. Representative · bioguide F000472 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000472); migration 1536'
 WHERE id = 'd5bb8d26-bf02-4846-8635-93b7e0dae81d';
-- Byron Donalds (FL) U.S. Representative · bioguide D000032 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000032); migration 1536'
 WHERE id = '2971b66d-0e96-42db-8ac0-3681653d0a74';
-- Brian J. Mast (FL) U.S. Representative · bioguide M001199 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001199); migration 1536'
 WHERE id = 'd3096f6f-8486-4ea9-a588-b01b6328b789';
-- Lois Frankel (FL) U.S. Representative · bioguide F000462 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000462); migration 1536'
 WHERE id = '2ff4abe2-4ead-4c72-bb54-e546cf68e1af';
-- Jared Moskowitz (FL) U.S. Representative · bioguide M001217 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001217); migration 1536'
 WHERE id = '60949c56-f313-4f75-8cc7-570a0d79aaa2';
-- Frederica S. Wilson (FL) U.S. Representative · bioguide W000808 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000808); migration 1536'
 WHERE id = 'ade2040e-e717-455b-a29f-ef2b686875ef';
-- Debbie Wasserman Schultz (FL) U.S. Representative · bioguide W000797 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000797); migration 1536'
 WHERE id = 'eaffa373-c834-48c0-9de9-47e96ab76572';
-- Mario Diaz-Balart (FL) U.S. Representative · bioguide D000600 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000600); migration 1536'
 WHERE id = 'cd11ba8e-f121-4c35-aeff-e397959e3528';
-- Maria Elvira Salazar (FL) U.S. Representative · bioguide S000168 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000168); migration 1536'
 WHERE id = 'c27ef575-6c7d-42c4-8989-febf583b43e7';
-- Carlos A. Gimenez (FL) U.S. Representative · bioguide G000593 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000593); migration 1536'
 WHERE id = 'f1e1429d-b933-43cd-a13a-b43f924f7f7d';
-- Earl L. "Buddy" Carter (GA) U.S. Representative · bioguide C001103 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001103); migration 1536'
 WHERE id = '1129575f-7b38-41f3-9d07-4c869239780d';
-- Sanford D. Bishop, Jr. (GA) U.S. Representative · bioguide B000490 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B000490); migration 1536'
 WHERE id = '3475ecb7-695f-47eb-8c0e-bd6b20bc1e8e';
-- Brian Jack (GA) U.S. Representative · bioguide J000311 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000311); migration 1536'
 WHERE id = '51696cf1-0555-4a15-893c-23d22df8569f';
-- Henry C. "Hank" Johnson, Jr. (GA) U.S. Representative · bioguide J000288 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000288); migration 1536'
 WHERE id = 'f8d134f8-4651-4b72-99ff-d35b48240a75';
-- Nikema Williams (GA) U.S. Representative · bioguide W000788 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000788); migration 1536'
 WHERE id = 'a642499a-cd27-4178-9a34-ff20e65f0fee';
-- Lucy McBath (GA) U.S. Representative · bioguide M001208 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001208); migration 1536'
 WHERE id = '7cb805d4-6c0c-452d-a3f7-503d63ce6659';
-- Richard McCormick (GA) U.S. Representative · bioguide M001218 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001218); migration 1536'
 WHERE id = 'dac8292a-8bdf-40a4-ad14-94b3acafe20a';
-- Austin Scott (GA) U.S. Representative · bioguide S001189 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001189); migration 1536'
 WHERE id = '4aad7925-fe0c-4582-a6b5-a159ed512a26';
-- Andrew S. Clyde (GA) U.S. Representative · bioguide C001116 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001116); migration 1536'
 WHERE id = '185863c7-4a7a-442b-b619-3b27d52fc565';
-- Mike Collins (GA) U.S. Representative · bioguide C001129 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001129); migration 1536'
 WHERE id = '481a37f0-6181-4ebf-a796-c42090a01bc6';
-- Barry Loudermilk (GA) U.S. Representative · bioguide L000583 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000583); migration 1536'
 WHERE id = 'e326c803-553d-468d-be3e-ae57128a01ee';
-- Rick W. Allen (GA) U.S. Representative · bioguide A000372 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000372); migration 1536'
 WHERE id = 'c4cc29f4-4942-4c1b-985a-d860905b3694';
-- Clay Fuller (GA) U.S. Representative · bioguide F000485 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2026-04-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000485); migration 1536'
 WHERE id = 'c2eeb19e-dfd1-4fce-958a-8106e2731a87';
-- Ed Case (HI) U.S. Representative · bioguide C001055 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001055); migration 1536'
 WHERE id = 'fa6a0e47-e686-4921-825a-353fa408b8b7';
-- Jill N. Tokuda (HI) U.S. Representative · bioguide T000487 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000487); migration 1536'
 WHERE id = '670e0ef1-35bf-43b4-9c57-7999dfe1df43';
-- Russ Fulcher (ID) U.S. Representative · bioguide F000469 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000469); migration 1536'
 WHERE id = 'e233ad2d-b7ef-45cf-89a5-e9cb0d8d53d3';
-- Michael K. Simpson (ID) U.S. Representative · bioguide S001148 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001148); migration 1536'
 WHERE id = '663051c2-9f46-4459-96cc-9e0163a165ed';
-- Jonathan L. Jackson (IL) U.S. Representative · bioguide J000309 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000309); migration 1536'
 WHERE id = '507bcee2-2e69-4397-92c3-b3f35483525e';
-- Robin L. Kelly (IL) U.S. Representative · bioguide K000385 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-04-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000385); migration 1536'
 WHERE id = '8a5e783d-85b5-4104-8e3e-d36f8d72a947';
-- Delia C. Ramirez (IL) U.S. Representative · bioguide R000617 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000617); migration 1536'
 WHERE id = 'd707041b-9815-4f40-8717-752a8c333477';
-- Jesús G. "Chuy" García (IL) U.S. Representative · bioguide G000586 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000586); migration 1536'
 WHERE id = '26a11820-b9b8-4e7f-a12d-a33e191e0809';
-- Mike Quigley (IL) U.S. Representative · bioguide Q000023 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-04-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide Q000023); migration 1536'
 WHERE id = 'f9758ead-fc2c-4cd2-afdc-4a6f38f35696';
-- Sean Casten (IL) U.S. Representative · bioguide C001117 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001117); migration 1536'
 WHERE id = 'd5ad282e-1ca7-4dc3-a1ae-f30ebdf306c1';
-- Danny K. Davis (IL) U.S. Representative · bioguide D000096 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000096); migration 1536'
 WHERE id = 'af0165f9-b5ed-4c72-95e0-8e016bf882a0';
-- Raja Krishnamoorthi (IL) U.S. Representative · bioguide K000391 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000391); migration 1536'
 WHERE id = 'cc566465-ab87-4931-a6f2-ca7b7b60b51e';
-- Janice D. Schakowsky (IL) U.S. Representative · bioguide S001145 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1999-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001145); migration 1536'
 WHERE id = '9c388df4-9f60-4f92-a80c-1c7b0e248ae7';
-- Bradley Scott Schneider (IL) U.S. Representative · bioguide S001190 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001190); migration 1536'
 WHERE id = '7a51c7bd-6c07-4b20-a420-d76b3cb02915';
-- Bill Foster (IL) U.S. Representative · bioguide F000454 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000454); migration 1536'
 WHERE id = '4aacd26c-eefa-4281-a890-29bbaef14b02';
-- Mike Bost (IL) U.S. Representative · bioguide B001295 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001295); migration 1536'
 WHERE id = '47b57c6b-401c-4831-beff-d3a30d9fc8ba';
-- Nikki Budzinski (IL) U.S. Representative · bioguide B001315 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001315); migration 1536'
 WHERE id = 'b75a4744-e8df-4232-a97b-fb19314c2586';
-- Lauren Underwood (IL) U.S. Representative · bioguide U000040 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide U000040); migration 1536'
 WHERE id = '029eb3a2-6411-465f-ad89-224b0b4af5b5';
-- Mary E. Miller (IL) U.S. Representative · bioguide M001211 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001211); migration 1536'
 WHERE id = '698f8ef0-4d43-4823-89d1-0f935baecf87';
-- Darin LaHood (IL) U.S. Representative · bioguide L000585 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-09-17', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000585); migration 1536'
 WHERE id = '691bc953-9f1a-44dc-ae92-5637e766b210';
-- Eric Sorensen (IL) U.S. Representative · bioguide S001225 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001225); migration 1536'
 WHERE id = '10af78ce-4c61-4d6f-b083-999e7588ad8d';
-- Frank J. Mrvan (IN) U.S. Representative · bioguide M001214 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001214); migration 1536'
 WHERE id = '986cfaf9-6ac4-42ee-b8d9-c814d9c1c2b9';
-- Rudy Yakym III (IN) U.S. Representative · bioguide Y000067 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2022-11-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide Y000067); migration 1536'
 WHERE id = '37634bf8-3e45-49b7-a5c1-8db29f974883';
-- Marlin A. Stutzman (IN) U.S. Representative · bioguide S001188 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001188); migration 1536'
 WHERE id = 'bf87475e-779d-462f-9d1b-c6569d7c5f00';
-- Victoria Spartz (IN) U.S. Representative · bioguide S000929 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000929); migration 1536'
 WHERE id = '0f99b125-67e4-416d-bd23-9f3dde2259c5';
-- Jefferson Shreve (IN) U.S. Representative · bioguide S001229 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001229); migration 1536'
 WHERE id = '5c8da0d3-a87b-49c0-92c6-bd732fc71597';
-- Mariannette Miller-Meeks (IA) U.S. Representative · bioguide M001215 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001215); migration 1536'
 WHERE id = 'c3a8f684-b756-4eb7-9ff3-a6a72a3cd49c';
-- Ashley Hinson (IA) U.S. Representative · bioguide H001091 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001091); migration 1536'
 WHERE id = 'c0edf6bd-cfc6-45e2-b097-41208b6e32dc';
-- Zachary Nunn (IA) U.S. Representative · bioguide N000193 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000193); migration 1536'
 WHERE id = 'c31816a2-8a53-44f6-8fe9-e826b71e9627';
-- Randy Feenstra (IA) U.S. Representative · bioguide F000446 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000446); migration 1536'
 WHERE id = '9361d585-1a6a-42b0-b6f5-b65b1c774624';
-- Tracey Mann (KS) U.S. Representative · bioguide M000871 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M000871); migration 1536'
 WHERE id = 'dcc30533-b50f-414a-a584-ece11cd8c714';
-- Derek Schmidt (KS) U.S. Representative · bioguide S001228 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001228); migration 1536'
 WHERE id = 'e3d7120b-3b94-4773-8cb9-1658318fe36c';
-- Sharice Davids (KS) U.S. Representative · bioguide D000629 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000629); migration 1536'
 WHERE id = '78ddccbe-9325-4602-9298-c5d1ede80187';
-- Ron Estes (KS) U.S. Representative · bioguide E000298 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-04-25', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000298); migration 1536'
 WHERE id = 'bee42cd1-8af7-4325-9a8e-bc5c07980e39';
-- James Comer (KY) U.S. Representative · bioguide C001108 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2016-11-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001108); migration 1536'
 WHERE id = '6a30a54c-106f-487d-b91f-5200d80424da';
-- Brett Guthrie (KY) U.S. Representative · bioguide G000558 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000558); migration 1536'
 WHERE id = '06f67880-42d6-4531-879d-0b8e9dde73c5';
-- Morgan McGarvey (KY) U.S. Representative · bioguide M001220 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001220); migration 1536'
 WHERE id = '009472e6-e959-4a00-b9c8-1871da77a70b';
-- Thomas Massie (KY) U.S. Representative · bioguide M001184 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2012-11-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001184); migration 1536'
 WHERE id = '1d6032c9-94c5-46dd-af15-4da25a1a266d';
-- Harold Rogers (KY) U.S. Representative · bioguide R000395 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1981-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000395); migration 1536'
 WHERE id = 'f651270b-ebaf-4805-a40d-ff96d40c0616';
-- Andy Barr (KY) U.S. Representative · bioguide B001282 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001282); migration 1536'
 WHERE id = '97c0cf5f-0d85-40d0-8a02-9a487377c853';
-- Steve Scalise (LA) U.S. Representative · bioguide S001176 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2008-05-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001176); migration 1536'
 WHERE id = '4b270554-c683-4f4a-80de-a7d680370669';
-- Troy A. Carter (LA) U.S. Representative · bioguide C001125 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-05-11', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001125); migration 1536'
 WHERE id = '4848a60c-63ad-4c26-a59e-08bbdae6c70b';
-- Clay Higgins (LA) U.S. Representative · bioguide H001077 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001077); migration 1536'
 WHERE id = 'fba47925-76f4-4019-81d5-ca5632a241f0';
-- Mike Johnson (LA) U.S. Representative · bioguide J000299 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000299); migration 1536'
 WHERE id = 'e091d05a-1d23-4963-8eab-7460d8351c39';
-- Julia Letlow (LA) U.S. Representative · bioguide L000595 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-04-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000595); migration 1536'
 WHERE id = '7b6dc753-f81d-4a2f-8b21-da2e9a5e6966';
-- Cleo Fields (LA) U.S. Representative · bioguide F000110 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000110); migration 1536'
 WHERE id = '5bd89b90-679d-4044-a2c4-3193b6c63bed';
-- Jack Bergman (MI) U.S. Representative · bioguide B001301 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001301); migration 1536'
 WHERE id = '49ed4bb0-0156-4a42-9970-9604e19c58d5';
-- John R. Moolenaar (MI) U.S. Representative · bioguide M001194 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001194); migration 1536'
 WHERE id = '4c9c28e4-a7bd-4f19-a450-26d164e0103c';
-- Hillary J. Scholten (MI) U.S. Representative · bioguide S001221 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001221); migration 1536'
 WHERE id = 'c5605d77-8e3f-4143-b489-f3186377ba17';
-- Bill Huizenga (MI) U.S. Representative · bioguide H001058 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001058); migration 1536'
 WHERE id = 'c7f37f3e-0254-451e-9b94-5e23a3b1952f';
-- Tim Walberg (MI) U.S. Representative · bioguide W000798 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000798); migration 1536'
 WHERE id = '8e8c32ed-88ba-4ec5-a91f-5d2063ed6647';
-- Debbie Dingell (MI) U.S. Representative · bioguide D000624 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000624); migration 1536'
 WHERE id = '73574320-8208-44df-9696-178c3d1a7356';
-- Tom Barrett (MI) U.S. Representative · bioguide B001321 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001321); migration 1536'
 WHERE id = '9e017ae4-1957-48dc-9031-97bc7ead5417';
-- Kristen McDonald Rivet (MI) U.S. Representative · bioguide M001237 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001237); migration 1536'
 WHERE id = '3d6d4381-febf-4034-a28f-935aa64a2108';
-- Lisa C. McClain (MI) U.S. Representative · bioguide M001136 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001136); migration 1536'
 WHERE id = '194c46b7-10d6-478e-83f3-0d97a3d73aed';
-- John James (MI) U.S. Representative · bioguide J000307 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000307); migration 1536'
 WHERE id = '015e7e60-934d-4073-ac16-b0a75c941ca9';
-- Haley M. Stevens (MI) U.S. Representative · bioguide S001215 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001215); migration 1536'
 WHERE id = '943ceb10-3869-41cd-9d5a-b16036d10b71';
-- Rashida Tlaib (MI) U.S. Representative · bioguide T000481 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000481); migration 1536'
 WHERE id = 'fe297963-716f-4595-9e52-b7d20b81b779';
-- Shri Thanedar (MI) U.S. Representative · bioguide T000488 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000488); migration 1536'
 WHERE id = '14e8fdbf-4eed-4633-9344-9ef5a6b02a55';
-- Brad Finstad (MN) U.S. Representative · bioguide F000475 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2022-08-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000475); migration 1536'
 WHERE id = '84be6194-4723-4164-8c94-2865718e1fac';
-- Angie Craig (MN) U.S. Representative · bioguide C001119 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001119); migration 1536'
 WHERE id = '08a1d115-6433-4b68-9c38-9bc4b7262697';
-- Kelly Morrison (MN) U.S. Representative · bioguide M001234 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001234); migration 1536'
 WHERE id = 'f7ff2c98-7f6e-47b3-b147-552225398618';
-- Betty McCollum (MN) U.S. Representative · bioguide M001143 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001143); migration 1536'
 WHERE id = '3d9b0ab0-71f7-4c70-9f6f-485aa680ef6b';
-- Ilhan Omar (MN) U.S. Representative · bioguide O000173 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000173); migration 1536'
 WHERE id = '858048f2-cf67-4bd7-9269-1c541b3bf8a1';
-- Tom Emmer (MN) U.S. Representative · bioguide E000294 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000294); migration 1536'
 WHERE id = 'c48ba248-ea2e-427a-bd3f-0b3c418f8879';
-- Michelle Fischbach (MN) U.S. Representative · bioguide F000470 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000470); migration 1536'
 WHERE id = 'c790de47-0198-4703-b411-5fcecb6e4d9f';
-- Pete Stauber (MN) U.S. Representative · bioguide S001212 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001212); migration 1536'
 WHERE id = '9e55ada2-bb34-4bd8-bf24-b152a86daf5e';
-- Trent Kelly (MS) U.S. Representative · bioguide K000388 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-06-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000388); migration 1536'
 WHERE id = 'eaa0f2c6-83e8-424f-8f61-9ce9a210eb0c';
-- Bennie G. Thompson (MS) U.S. Representative · bioguide T000193 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-04-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000193); migration 1536'
 WHERE id = '7329da4c-6739-401b-993b-83682e816fd1';
-- Michael Guest (MS) U.S. Representative · bioguide G000591 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000591); migration 1536'
 WHERE id = '69d09625-8761-4a95-b989-99b85b0685b7';
-- Mike Ezell (MS) U.S. Representative · bioguide E000235 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000235); migration 1536'
 WHERE id = 'b5ab4b17-6204-4f97-9171-4e5c52c063de';
-- Wesley Bell (MO) U.S. Representative · bioguide B001324 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001324); migration 1536'
 WHERE id = 'ea1684dc-accc-4686-9824-b0b2bd68bc5d';
-- Ann Wagner (MO) U.S. Representative · bioguide W000812 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000812); migration 1536'
 WHERE id = '9339d816-129f-4fb2-a450-5e9ec9fe4b77';
-- Robert F. Onder, Jr. (MO) U.S. Representative · bioguide O000177 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000177); migration 1536'
 WHERE id = '160bf099-267b-43d6-87c4-17f1e4ea4de4';
-- Mark Alford (MO) U.S. Representative · bioguide A000379 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000379); migration 1536'
 WHERE id = '4b0ee9e2-b4af-4c14-a67f-f12fa6982736';
-- Emanuel Cleaver (MO) U.S. Representative · bioguide C001061 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001061); migration 1536'
 WHERE id = 'bc33bf64-2080-4205-bd53-806647cbbf2b';
-- Sam Graves (MO) U.S. Representative · bioguide G000546 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000546); migration 1536'
 WHERE id = '3c9c90b6-6935-4cfc-8b96-da8b27d7d54c';
-- Eric Burlison (MO) U.S. Representative · bioguide B001316 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001316); migration 1536'
 WHERE id = 'f670748e-b454-4a37-ba3d-db7133e3d3f7';
-- Jason Smith (MO) U.S. Representative · bioguide S001195 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-06-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001195); migration 1536'
 WHERE id = '90cad7ac-552a-45eb-8cf2-89ddcd74917e';
-- Ryan K. Zinke (MT) U.S. Representative · bioguide Z000018 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide Z000018); migration 1536'
 WHERE id = 'ce27de82-d56c-4546-b56a-ff95acccc7e5';
-- Troy Downing (MT) U.S. Representative · bioguide D000634 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000634); migration 1536'
 WHERE id = '914a8d50-893c-4462-8ec6-f1d4a3c3a69a';
-- Mike Flood (NE) U.S. Representative · bioguide F000474 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2022-07-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000474); migration 1536'
 WHERE id = 'd08e987a-4cb5-46c5-839c-113f62adc657';
-- Don Bacon (NE) U.S. Representative · bioguide B001298 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001298); migration 1536'
 WHERE id = 'fd2ca9e7-a748-4479-8bf7-fcc32179c3be';
-- Adrian Smith (NE) U.S. Representative · bioguide S001172 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001172); migration 1536'
 WHERE id = '12322083-2606-46a6-8e19-77ddafb024d0';
-- Dina Titus (NV) U.S. Representative · bioguide T000468 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000468); migration 1536'
 WHERE id = '6dd31184-2320-46c2-9c10-9314fe6aed3e';
-- Mark E. Amodei (NV) U.S. Representative · bioguide A000369 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-09-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000369); migration 1536'
 WHERE id = '087e81f1-aefd-4e99-b8c8-4d3d2732bc3e';
-- Susie Lee (NV) U.S. Representative · bioguide L000590 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000590); migration 1536'
 WHERE id = 'b8ff0c9b-de94-4a52-a09e-1a523e8af416';
-- Steven Horsford (NV) U.S. Representative · bioguide H001066 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001066); migration 1536'
 WHERE id = '7879d987-365c-4c37-80b4-bbc4783db338';
-- Chris Pappas (NH) U.S. Representative · bioguide P000614 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000614); migration 1536'
 WHERE id = '6ab369bd-e583-4153-8031-83ab9bd98ac1';
-- Maggie Goodlander (NH) U.S. Representative · bioguide G000604 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000604); migration 1536'
 WHERE id = 'f6882f92-feb3-487f-a16e-c5c337b711dc';
-- Donald Norcross (NJ) U.S. Representative · bioguide N000188 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2014-11-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000188); migration 1536'
 WHERE id = '36559900-9525-4e8c-a57b-d497f6e3a6f6';
-- Jefferson Van Drew (NJ) U.S. Representative · bioguide V000133 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000133); migration 1536'
 WHERE id = '4f4b6296-d0be-45ba-aa2c-e8d0bb7cd5ea';
-- Herbert C. Conaway, Jr. (NJ) U.S. Representative · bioguide C001136 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001136); migration 1536'
 WHERE id = '63492d00-ab2a-4a08-8959-3225481b0a88';
-- Christopher H. Smith (NJ) U.S. Representative · bioguide S000522 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1981-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000522); migration 1536'
 WHERE id = '0c28cfe1-4f6e-42aa-a9d7-05b4417fa79e';
-- Josh Gottheimer (NJ) U.S. Representative · bioguide G000583 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000583); migration 1536'
 WHERE id = '603d7570-5e8b-4538-8aab-c82ae5e9136e';
-- Frank Pallone, Jr. (NJ) U.S. Representative · bioguide P000034 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1987-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000034); migration 1536'
 WHERE id = 'aba9eae4-eade-46aa-9c51-c22a65a4dceb';
-- Thomas H. Kean, Jr. (NJ) U.S. Representative · bioguide K000398 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000398); migration 1536'
 WHERE id = '59c93403-ebb2-42e8-b7ac-9ab9cc0d8933';
-- Robert Menendez (NJ) U.S. Representative · bioguide M001226 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001226); migration 1536'
 WHERE id = '1e06b362-ec13-4e70-9ac8-2b1a93430596';
-- Nellie Pou (NJ) U.S. Representative · bioguide P000621 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000621); migration 1536'
 WHERE id = '4ed29dba-2f5e-411e-b96e-4330fa811f30';
-- LaMonica McIver (NJ) U.S. Representative · bioguide M001229 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-09-18', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001229); migration 1536'
 WHERE id = 'aed847b4-1ac1-4935-9a99-36693cf9d6e8';
-- Analilia Mejia (NJ) U.S. Representative · bioguide M001246 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2026-04-20', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001246); migration 1536'
 WHERE id = 'f81793c0-5766-4022-9116-2a4cdc3c0b21';
-- Bonnie Watson Coleman (NJ) U.S. Representative · bioguide W000822 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000822); migration 1536'
 WHERE id = '083c4edf-4ea7-46e8-98a3-8ade1f45ae59';
-- Melanie A. Stansbury (NM) U.S. Representative · bioguide S001218 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-06-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001218); migration 1536'
 WHERE id = '0948f86b-0813-422c-9211-1f41c5f3f224';
-- Gabe Vasquez (NM) U.S. Representative · bioguide V000136 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000136); migration 1536'
 WHERE id = 'b82279ff-d2fd-46b5-b53a-9dd90d8cf480';
-- Teresa Leger Fernandez (NM) U.S. Representative · bioguide L000273 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000273); migration 1536'
 WHERE id = 'c4ab522b-7374-4644-afe8-b1f59f8aa010';
-- Nick LaLota (NY) U.S. Representative · bioguide L000598 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000598); migration 1536'
 WHERE id = '0e1a7b9a-d92a-44ea-9119-deb9f3da64b9';
-- Andrew R. Garbarino (NY) U.S. Representative · bioguide G000597 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000597); migration 1536'
 WHERE id = '1ce61e8d-5626-4e9b-86ea-632544698fde';
-- Thomas R. Suozzi (NY) U.S. Representative · bioguide S001201 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-02-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001201); migration 1536'
 WHERE id = '71cb177f-5b08-4bb0-a8e3-0a390bebf5d1';
-- Laura Gillen (NY) U.S. Representative · bioguide G000602 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000602); migration 1536'
 WHERE id = '061d871e-b38c-4aab-8395-742ab699affe';
-- Gregory W. Meeks (NY) U.S. Representative · bioguide M001137 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001137); migration 1536'
 WHERE id = 'f07766e6-c8d2-4d94-ba3c-6c8ec6d3432d';
-- Grace Meng (NY) U.S. Representative · bioguide M001188 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001188); migration 1536'
 WHERE id = '8cc4c555-813a-4bb8-b5c5-4e4584aa646c';
-- Nydia M. Velázquez (NY) U.S. Representative · bioguide V000081 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000081); migration 1536'
 WHERE id = '20176e18-02c9-42e3-a518-b4df4f3caf99';
-- Hakeem S. Jeffries (NY) U.S. Representative · bioguide J000294 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000294); migration 1536'
 WHERE id = 'd9a0f809-48d8-42fb-8d46-fcb6e462e4cd';
-- Yvette D. Clarke (NY) U.S. Representative · bioguide C001067 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001067); migration 1536'
 WHERE id = '360324cc-6ada-47a7-b5ce-97eecdb8e62e';
-- Daniel S. Goldman (NY) U.S. Representative · bioguide G000599 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000599); migration 1536'
 WHERE id = 'bc3eeab3-4f26-40df-a984-8abfd74b0fab';
-- Nicole Malliotakis (NY) U.S. Representative · bioguide M000317 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M000317); migration 1536'
 WHERE id = '23e30dd3-5271-44e0-9e81-bdebdd30e0b1';
-- Jerrold Nadler (NY) U.S. Representative · bioguide N000002 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1992-11-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000002); migration 1536'
 WHERE id = '1d2b0d7a-f5df-4e39-a075-d2bcd3bfc296';
-- Adriano Espaillat (NY) U.S. Representative · bioguide E000297 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000297); migration 1536'
 WHERE id = '63306f82-bdec-4234-b151-0ab0a7c38786';
-- Alexandria Ocasio-Cortez (NY) U.S. Representative · bioguide O000172 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000172); migration 1536'
 WHERE id = '776ad9e3-a483-49b1-9e59-29aa309f5e40';
-- Ritchie Torres (NY) U.S. Representative · bioguide T000486 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000486); migration 1536'
 WHERE id = '4bae42c8-0ef7-4d87-8070-2ecfb7a0b01c';
-- George Latimer (NY) U.S. Representative · bioguide L000606 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000606); migration 1536'
 WHERE id = '3d87d2fb-8003-4748-97fc-24abcba2d8b7';
-- Michael Lawler (NY) U.S. Representative · bioguide L000599 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000599); migration 1536'
 WHERE id = 'cffdbe97-a8be-4c8a-9b88-21c21fa2c60c';
-- Patrick Ryan (NY) U.S. Representative · bioguide R000579 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2022-09-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000579); migration 1536'
 WHERE id = '97d28e0c-4e9c-4891-988b-7d5920b0e17a';
-- Josh Riley (NY) U.S. Representative · bioguide R000622 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000622); migration 1536'
 WHERE id = 'd78109d1-6aa8-4917-92d4-3ec475472e42';
-- Paul Tonko (NY) U.S. Representative · bioguide T000469 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000469); migration 1536'
 WHERE id = 'f4227802-a53b-435d-96b4-857c3e18beab';
-- Elise M. Stefanik (NY) U.S. Representative · bioguide S001196 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001196); migration 1536'
 WHERE id = 'c983edee-ef31-4646-9b17-87518233cb7e';
-- John W. Mannion (NY) U.S. Representative · bioguide M001231 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001231); migration 1536'
 WHERE id = 'a166ac3e-af84-4dcf-8ec2-0f24dd9dc473';
-- Nicholas A. Langworthy (NY) U.S. Representative · bioguide L000600 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000600); migration 1536'
 WHERE id = '0f678d70-6f14-47cb-b2f9-088cdb974275';
-- Claudia Tenney (NY) U.S. Representative · bioguide T000478 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-02-11', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000478); migration 1536'
 WHERE id = '85713323-f678-4ab5-bc3a-98559e93effa';
-- Joseph D. Morelle (NY) U.S. Representative · bioguide M001206 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-11-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001206); migration 1536'
 WHERE id = '169b0ed5-cb80-453b-8934-e6d8aa8d5718';
-- Timothy M. Kennedy (NY) U.S. Representative · bioguide K000402 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-05-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000402); migration 1536'
 WHERE id = 'f039a2d8-2d9f-4a94-8705-599c112f2712';
-- Donald G. Davis (NC) U.S. Representative · bioguide D000230 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000230); migration 1536'
 WHERE id = 'c1e748d1-b15f-4075-a843-516724c966d1';
-- Deborah K. Ross (NC) U.S. Representative · bioguide R000305 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000305); migration 1536'
 WHERE id = '3e91b218-434b-48d5-9c9a-d38a9e9e231c';
-- Gregory F. Murphy (NC) U.S. Representative · bioguide M001210 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-09-17', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001210); migration 1536'
 WHERE id = '6c1b53b3-e34e-496c-952e-079eaeaf060a';
-- Valerie P. Foushee (NC) U.S. Representative · bioguide F000477 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000477); migration 1536'
 WHERE id = 'c0b2236d-5e0f-4b3a-b2ac-027719887927';
-- Virginia Foxx (NC) U.S. Representative · bioguide F000450 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000450); migration 1536'
 WHERE id = '404877d4-ee0a-410a-9876-dc942e25c0dd';
-- Addison P. McDowell (NC) U.S. Representative · bioguide M001240 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001240); migration 1536'
 WHERE id = '217402c2-bca8-4243-8565-18674c249989';
-- David Rouzer (NC) U.S. Representative · bioguide R000603 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000603); migration 1536'
 WHERE id = '010c8583-4f4f-4f90-bebc-a2eab020b35e';
-- Mark Harris (NC) U.S. Representative · bioguide H001102 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001102); migration 1536'
 WHERE id = 'b33ddfdf-16fb-42e8-abe0-88a0800bc426';
-- Richard Hudson (NC) U.S. Representative · bioguide H001067 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001067); migration 1536'
 WHERE id = 'b1f6a337-013a-473d-9cea-b37a8f9b67f6';
-- Pat Harrigan (NC) U.S. Representative · bioguide H001101 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001101); migration 1536'
 WHERE id = '1bd2faec-913f-4a40-a763-4dadbdd6eb88';
-- Chuck Edwards (NC) U.S. Representative · bioguide E000246 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000246); migration 1536'
 WHERE id = '82972530-4c51-43ae-98ad-6ecc79b8d017';
-- Alma S. Adams (NC) U.S. Representative · bioguide A000370 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2014-11-12', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000370); migration 1536'
 WHERE id = 'a7c7c87a-c8a9-4d4b-82ae-c7242e503dcc';
-- Brad Knott (NC) U.S. Representative · bioguide K000405 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000405); migration 1536'
 WHERE id = '7c8fe235-1320-4860-a1d7-d62a1fefcea6';
-- Tim Moore (NC) U.S. Representative · bioguide M001236 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001236); migration 1536'
 WHERE id = '7053dfaa-4d15-42d8-b9c8-d048a0ecab61';
-- Julie Fedorchak (ND) U.S. Representative · bioguide F000482 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000482); migration 1536'
 WHERE id = '67181152-aa68-4826-8532-d8f5874465e4';
-- Greg Landsman (OH) U.S. Representative · bioguide L000601 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000601); migration 1536'
 WHERE id = '141a60f1-ee58-4772-9b9a-8347ee9d3998';
-- David J. Taylor (OH) U.S. Representative · bioguide T000490 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000490); migration 1536'
 WHERE id = '6b40c892-4e79-46b3-8a63-c0190ae274f0';
-- Joyce Beatty (OH) U.S. Representative · bioguide B001281 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001281); migration 1536'
 WHERE id = '2a17451e-f941-4c79-bfac-78bb3fd84c79';
-- Jim Jordan (OH) U.S. Representative · bioguide J000289 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000289); migration 1536'
 WHERE id = '9c0bb663-f78d-49f2-8618-f3179bfa04e2';
-- Robert E. Latta (OH) U.S. Representative · bioguide L000566 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-12-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000566); migration 1536'
 WHERE id = '3bd7bca7-251a-4ced-b8a1-58e2ec28fbec';
-- Michael A. Rulli (OH) U.S. Representative · bioguide R000619 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-06-11', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000619); migration 1536'
 WHERE id = '744f20e7-7413-497e-bc45-139583bee0fd';
-- Max L. Miller (OH) U.S. Representative · bioguide M001222 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001222); migration 1536'
 WHERE id = '8539a964-6361-464e-bfd3-9455ca21af53';
-- Warren Davidson (OH) U.S. Representative · bioguide D000626 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2016-06-09', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000626); migration 1536'
 WHERE id = 'aaccaa14-2af8-410c-b108-7d464eaec060';
-- Marcy Kaptur (OH) U.S. Representative · bioguide K000009 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1983-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000009); migration 1536'
 WHERE id = '9597f87f-d1a7-4821-809a-6ec030f33134';
-- Michael R. Turner (OH) U.S. Representative · bioguide T000463 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000463); migration 1536'
 WHERE id = '739da429-249f-4ec2-923c-8bebf5a9be0b';
-- Shontel M. Brown (OH) U.S. Representative · bioguide B001313 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-11-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001313); migration 1536'
 WHERE id = '4cd111e7-44ee-4ee7-ae05-7e5c4e1a1f36';
-- Troy Balderson (OH) U.S. Representative · bioguide B001306 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-09-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001306); migration 1536'
 WHERE id = 'abafd08b-dac6-41cf-92ca-d68d42a8ecaf';
-- Emilia Strong Sykes (OH) U.S. Representative · bioguide S001223 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001223); migration 1536'
 WHERE id = '48bfd22e-06b7-49ff-9ef0-5fdf33eb1d4d';
-- David P. Joyce (OH) U.S. Representative · bioguide J000295 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000295); migration 1536'
 WHERE id = '2688c70e-a478-44df-a328-565b78524ec1';
-- Mike Carey (OH) U.S. Representative · bioguide C001126 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-11-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001126); migration 1536'
 WHERE id = '78e2c18e-199e-43cb-bb58-cf8ee34fd669';
-- Kevin Hern (OK) U.S. Representative · bioguide H001082 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-11-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001082); migration 1536'
 WHERE id = 'b9052130-b627-487b-8006-866e7880659c';
-- Josh Brecheen (OK) U.S. Representative · bioguide B001317 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001317); migration 1536'
 WHERE id = 'b4d45dbc-d7f2-4abd-8ea3-5e1398671fb8';
-- Frank D. Lucas (OK) U.S. Representative · bioguide L000491 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-05-10', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000491); migration 1536'
 WHERE id = '044f9c80-151a-4d62-b90f-5775ad85c1f1';
-- Tom Cole (OK) U.S. Representative · bioguide C001053 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2003-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001053); migration 1536'
 WHERE id = '2b40147e-1d27-4cb8-b7ad-5499a5078097';
-- Stephanie I. Bice (OK) U.S. Representative · bioguide B000740 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B000740); migration 1536'
 WHERE id = 'ae4cd1e6-a254-419d-bd74-398b36690a1c';
-- Brian K. Fitzpatrick (PA) U.S. Representative · bioguide F000466 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000466); migration 1536'
 WHERE id = 'af56dbac-961b-470c-a742-373fbec6f2c2';
-- Brendan F. Boyle (PA) U.S. Representative · bioguide B001296 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001296); migration 1536'
 WHERE id = 'def3cd93-1e3f-49bc-8748-727ac0ec28bc';
-- Dwight Evans (PA) U.S. Representative · bioguide E000296 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2016-11-14', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide E000296); migration 1536'
 WHERE id = '42cdd3a2-ebc7-4e7d-8700-81a4432affe8';
-- Madeleine Dean (PA) U.S. Representative · bioguide D000631 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000631); migration 1536'
 WHERE id = 'ca31c469-14e8-4f16-94a5-38962a8a80cc';
-- Mary Gay Scanlon (PA) U.S. Representative · bioguide S001205 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2018-11-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001205); migration 1536'
 WHERE id = '113b475c-474a-4f56-b804-60a5a771ac41';
-- Chrissy Houlahan (PA) U.S. Representative · bioguide H001085 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001085); migration 1536'
 WHERE id = '0bc3e569-b9ea-4cd5-8d7f-63cddc59089c';
-- Ryan Mackenzie (PA) U.S. Representative · bioguide M001230 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001230); migration 1536'
 WHERE id = '4d5f4bc8-2bb4-43b9-a4ea-8855db383fa4';
-- Robert P. Bresnahan, Jr. (PA) U.S. Representative · bioguide B001327 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001327); migration 1536'
 WHERE id = 'de147f55-dea8-4183-9863-b55e61b6dbaa';
-- Daniel Meuser (PA) U.S. Representative · bioguide M001204 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001204); migration 1536'
 WHERE id = '89b16149-9014-4c1b-97d6-82ff66e972e8';
-- Scott Perry (PA) U.S. Representative · bioguide P000605 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000605); migration 1536'
 WHERE id = '5f949433-f38c-484b-a417-6d8d955d0871';
-- Lloyd Smucker (PA) U.S. Representative · bioguide S001199 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001199); migration 1536'
 WHERE id = '19c8b3fa-2861-416c-8d4c-a00145584000';
-- Summer L. Lee (PA) U.S. Representative · bioguide L000602 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000602); migration 1536'
 WHERE id = '4f8baf31-db82-4708-9781-81224c3b95e5';
-- John Joyce (PA) U.S. Representative · bioguide J000302 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000302); migration 1536'
 WHERE id = 'c4b467c2-ad6e-45b1-9257-750e5f096d7e';
-- Guy Reschenthaler (PA) U.S. Representative · bioguide R000610 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000610); migration 1536'
 WHERE id = '7d840afb-0fd6-4d36-a048-f821708d49ab';
-- Glenn Thompson (PA) U.S. Representative · bioguide T000467 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2009-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000467); migration 1536'
 WHERE id = 'edb16724-3bb7-4203-9d04-c1b233290407';
-- Mike Kelly (PA) U.S. Representative · bioguide K000376 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000376); migration 1536'
 WHERE id = '85120813-d49c-4c26-8e57-1321050ba466';
-- Christopher R. Deluzio (PA) U.S. Representative · bioguide D000530 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000530); migration 1536'
 WHERE id = 'cce5c07b-ed30-4ef3-8abd-d49d180082ef';
-- Gabe Amo (RI) U.S. Representative · bioguide A000380 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-11-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide A000380); migration 1536'
 WHERE id = '69bc1905-e204-434d-9630-af3cb723febd';
-- Seth Magaziner (RI) U.S. Representative · bioguide M001223 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001223); migration 1536'
 WHERE id = 'fef4de38-a8c1-424b-8c6f-7f1e7bba7732';
-- Nancy Mace (SC) U.S. Representative · bioguide M000194 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M000194); migration 1536'
 WHERE id = '7b604276-4c08-4dd6-8716-712303706f11';
-- Joe Wilson (SC) U.S. Representative · bioguide W000795 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-12-18', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000795); migration 1536'
 WHERE id = 'ef4e92d7-8a8e-4a8e-b3d7-5289270edc28';
-- Sheri Biggs (SC) U.S. Representative · bioguide B001325 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001325); migration 1536'
 WHERE id = '63634356-ee87-4fef-ab39-e9d6ca0db11a';
-- William R. Timmons IV (SC) U.S. Representative · bioguide T000480 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000480); migration 1536'
 WHERE id = 'acfb7305-60bb-493f-80fd-f983627da86a';
-- Ralph Norman (SC) U.S. Representative · bioguide N000190 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-06-26', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000190); migration 1536'
 WHERE id = 'a23dd3ba-8a31-4816-b718-08762ba1dcd8';
-- James E. Clyburn (SC) U.S. Representative · bioguide C000537 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1993-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C000537); migration 1536'
 WHERE id = 'dd10eba9-858a-4d07-8fbe-e46f85490bca';
-- Russell Fry (SC) U.S. Representative · bioguide F000478 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000478); migration 1536'
 WHERE id = '1fa0aa5b-cc9d-468b-859c-0ee37485a061';
-- Dusty Johnson (SD) U.S. Representative · bioguide J000301 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000301); migration 1536'
 WHERE id = '324af3f5-ba6d-4590-9307-d9840be9dc4d';
-- Diana Harshbarger (TN) U.S. Representative · bioguide H001086 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001086); migration 1536'
 WHERE id = '24727e6d-8179-4d6e-bb1e-5d18f40a3424';
-- Tim Burchett (TN) U.S. Representative · bioguide B001309 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001309); migration 1536'
 WHERE id = 'a9c7d4a3-8d5d-438c-8eef-f21d284f5367';
-- Charles J. "Chuck" Fleischmann (TN) U.S. Representative · bioguide F000459 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000459); migration 1536'
 WHERE id = '11f52e5a-e987-4fe2-bceb-c3f4e68db79a';
-- Scott DesJarlais (TN) U.S. Representative · bioguide D000616 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000616); migration 1536'
 WHERE id = 'cc921357-978c-4ef8-86c2-c2fa046c6f71';
-- Andrew Ogles (TN) U.S. Representative · bioguide O000175 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide O000175); migration 1536'
 WHERE id = '5fca51f9-42df-46ef-9a46-4a61cfd13c47';
-- John W. Rose (TN) U.S. Representative · bioguide R000612 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000612); migration 1536'
 WHERE id = '8e1e69b3-0dac-4419-b40b-70f6b6660975';
-- Matt Van Epps (TN) U.S. Representative · bioguide V000139 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-12-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000139); migration 1536'
 WHERE id = 'c8c72767-f00f-464d-ac0e-8216803354d6';
-- David Kustoff (TN) U.S. Representative · bioguide K000392 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide K000392); migration 1536'
 WHERE id = 'f8813aca-7650-48ab-b11b-caf624a7d62d';
-- Steve Cohen (TN) U.S. Representative · bioguide C001068 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2007-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001068); migration 1536'
 WHERE id = '3c52ccc7-54b8-48a9-9abf-e20df5184497';
-- Becca Balint (VT) U.S. Representative · bioguide B001318 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001318); migration 1536'
 WHERE id = '5635f128-2e91-46d1-b846-44b74eb344c3';
-- Suzan K. DelBene (WA) U.S. Representative · bioguide D000617 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2012-11-13', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide D000617); migration 1536'
 WHERE id = '210c95be-abf0-4e0e-99e9-78e9d226a259';
-- Rick Larsen (WA) U.S. Representative · bioguide L000560 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2001-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide L000560); migration 1536'
 WHERE id = '8c10dabd-b85b-4c58-87e2-c54ca639546f';
-- Marie Gluesenkamp Perez (WA) U.S. Representative · bioguide G000600 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000600); migration 1536'
 WHERE id = '4f87b590-b99f-40aa-b43e-ec22490804c3';
-- Dan Newhouse (WA) U.S. Representative · bioguide N000189 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide N000189); migration 1536'
 WHERE id = 'efba2637-961b-42e9-ae53-293602fc0cdd';
-- Michael Baumgartner (WA) U.S. Representative · bioguide B001322 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide B001322); migration 1536'
 WHERE id = '10942f4a-d5c1-435e-8cd7-c90ce90a125a';
-- Emily Randall (WA) U.S. Representative · bioguide R000621 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide R000621); migration 1536'
 WHERE id = '2ae92334-91f8-4a0f-b735-13592ec7a9d9';
-- Pramila Jayapal (WA) U.S. Representative · bioguide J000298 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2017-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide J000298); migration 1536'
 WHERE id = '2651b172-6c0e-4fd5-8d06-0f2217262967';
-- Kim Schrier (WA) U.S. Representative · bioguide S001216 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001216); migration 1536'
 WHERE id = '0b27bd85-a7ed-4f3a-9fd4-98e11f7702e5';
-- Adam Smith (WA) U.S. Representative · bioguide S000510 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '1997-01-07', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S000510); migration 1536'
 WHERE id = '401404b7-dd29-4552-b4eb-071b00800975';
-- Marilyn Strickland (WA) U.S. Representative · bioguide S001159 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001159); migration 1536'
 WHERE id = '68ba6a08-155f-45d5-ae20-aa4496b78a0b';
-- Carol D. Miller (WV) U.S. Representative · bioguide M001205 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001205); migration 1536'
 WHERE id = '1969e542-a651-4cfc-85c8-b9b5849107e4';
-- Riley M. Moore (WV) U.S. Representative · bioguide M001235 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001235); migration 1536'
 WHERE id = '96e604bf-4205-4141-b6f0-fc1f9590a388';
-- Bryan Steil (WI) U.S. Representative · bioguide S001213 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide S001213); migration 1536'
 WHERE id = 'c6024c7e-633e-4ae2-8919-445d01083a91';
-- Mark Pocan (WI) U.S. Representative · bioguide P000607 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2013-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide P000607); migration 1536'
 WHERE id = 'bed2d0de-385b-41e7-8794-b0a7794ac826';
-- Derrick Van Orden (WI) U.S. Representative · bioguide V000135 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide V000135); migration 1536'
 WHERE id = '6921f14b-e059-4ec5-b10c-a16f3fc70c6f';
-- Gwen Moore (WI) U.S. Representative · bioguide M001160 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2005-01-04', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001160); migration 1536'
 WHERE id = 'dc9e2c1e-72e1-40bd-b0ba-c4b01f531d48';
-- Scott Fitzgerald (WI) U.S. Representative · bioguide F000471 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2021-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide F000471); migration 1536'
 WHERE id = 'e44bc4ea-add9-4819-9b24-7e0c1e6d719c';
-- Glenn Grothman (WI) U.S. Representative · bioguide G000576 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2015-01-06', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000576); migration 1536'
 WHERE id = 'd83da1d8-cb9d-4064-8513-2c3b2372206b';
-- Thomas P. Tiffany (WI) U.S. Representative · bioguide T000165 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2020-05-19', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide T000165); migration 1536'
 WHERE id = 'b30e27e0-b3d5-4d6e-9745-b7bab550facc';
-- Tony Wied (WI) U.S. Representative · bioguide W000829 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2024-11-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide W000829); migration 1536'
 WHERE id = '36fea65a-93c0-4114-ba2a-7b16b0b6ba3f';
-- Harriet M. Hageman (WY) U.S. Representative · bioguide H001096 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2023-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide H001096); migration 1536'
 WHERE id = '4bb13242-6350-4e79-a320-f305927cd431';
-- John McGuire (VA) U.S. Representative · bioguide M001239 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2025-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide M001239); migration 1536'
 WHERE id = '0cb19192-eaf2-462a-bf3b-dca0bb42647c';
-- Ben Cline (VA) U.S. Representative · bioguide C001118 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2019-01-03', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide C001118); migration 1536'
 WHERE id = '22ee1b11-825b-4465-bccb-f98cc022c578';
-- Morgan Griffith (VA) U.S. Representative · bioguide G000568 · matched by name+state
UPDATE essentials.office_terms SET term_start = DATE '2011-01-05', start_precision = 'day',
  source = 'unitedstates/congress-legislators, fetched 2026-08-02 — start of current unbroken rep service (bioguide G000568); migration 1536'
 WHERE id = '7d23a099-f7d3-42e5-8d26-67003f2ee8ae';

-- Verification: expected exactly 529 populated federal rows after this runs.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE id IN ('e9898584-e3c5-489a-a191-870833259325', '5b32e5f8-50a1-4e9d-9b34-3796c688b234', 'efb602ec-2dd0-4a1f-a562-05bb88960cbe', 'c55dc843-40ef-4be1-b5fa-c196694b75dc', '9549694e-a158-4c37-9d0e-34626f587bf7', '214f3895-aeb4-44a7-acb0-c922806eb6ce', 'b4f2dbce-699b-4649-bc0f-b31d343b27e7', '950a5fff-e9d4-4faa-8a7a-cf1a458f57cf', 'f4da7df3-7936-4e09-9ef3-d7e037fb53bd', '817d50e5-5389-4f90-bc1a-78459b540a92', '575b3b14-cf66-4751-9398-782aa20deac4', 'b8aa1c9b-602c-48b4-97c6-7f68541ddaab', '6bee8265-72b9-4521-b0f4-8446a63f1484', 'b0b1888a-f2ec-455d-afad-e34f1f83924d', '41ee8c81-54e1-4bda-8a57-f9f839281365', '79f82a79-561d-4b7a-9d26-42e88a41170a', 'c90493f7-60d3-41a9-bfae-9bc4d59efb59', 'f77a48fa-6364-4095-bfec-04a46413885b', 'e78044b9-8a60-4642-8ec8-fa6154dfa237', '70d04287-ee20-4f3d-b22d-59c92caa697d', '3ddb43aa-e7f3-4ea4-8f25-692e21a8777a', 'c587d67b-ce9c-4923-b89d-60ad2f957877', 'a4cf695e-61f5-439a-8300-e982972d56bd', 'e6bf19f0-0e04-46c9-b547-e94af9b17621', '6d0710c7-fd42-4242-8f16-d418238c4ead', '41f8c75d-024a-457a-bbe4-f9206b9d463c', '6d1ed881-4ae9-4254-9e4d-15dcfc2f2c11', '874c32e7-e2b0-4446-9217-500deee8ea91', '1edbdc12-1b84-4255-b25d-84c9d7ae5a64', 'd90373cb-b54e-4173-aff1-f744ff8f2b98', '19d1728d-b136-4460-af80-b5b9f4748cab', '9782baa6-6c91-4f3e-9043-e5776914cf67', 'e44746a0-bae5-42aa-bc19-aa25ce116259', 'e64b2ad6-f67d-4729-b13e-bdc527a02493', 'f6dd5786-2c38-4f21-ac6c-d0f24ff5a4ed', 'cc185493-16a0-42ed-982f-fa7e75dbc2f6', '5bd21c43-9f4f-47ee-ad0a-3a832b02dfcd', 'c9f68f43-c0ee-4d10-bd94-75675a98998e', 'ef4a86cc-33d3-4a02-a2ee-aa07a8a01b00', 'fbecff96-e2d3-467d-83e9-dfeee9496d46', '04246315-498f-42d2-806d-00b22b053b75', '98af3fe7-64ba-4175-9ed8-3d70726280ee', 'd37fd057-14d2-43b4-80a5-7a2282e7beb2', 'c054b617-033e-4ab7-ae6a-d3e07e62ae85', '753a6ab6-c705-4835-a694-3471529627fe', 'f25ff3ed-1c31-4cfd-81cd-6ab02e894ecd', '734c41aa-06d6-4814-a11b-108080366ac7', 'f99ac69b-43c2-47b7-9320-58dc73d88495', 'f9b0c61e-60b2-4eff-93fb-8c52c5eadbf9', 'bc15b39e-125f-4d96-96df-54ed30ad5fcb', '58b0c3c0-68eb-4bf4-a9c3-cdca905d8bcf', '5e2f8810-c413-4829-89b7-b7386c238639', 'ba4f77f6-45c4-4537-8531-f3c2a6b2979a', '8879364d-d4b2-4e02-b636-f195b0be9ec6', '48c00557-7efb-451a-b83b-ccee99090154', 'aab12c9f-caf7-4201-84c2-a50738303cd7', '0df678b4-c584-47a1-ad69-901ce106e13e', 'acda0b68-b352-4da9-8062-b3fe0def20bb', '7235c55a-7e73-431d-914e-1ff9bc57235c', 'bdc30aff-7cf6-4d6c-a982-5bfc11d14a03', 'd451e969-bb1e-432d-8ba0-d098721343c0', 'b986fc1b-d8c5-49b8-8fc1-2c1cf926a24c', 'd7a6f747-ce7a-4947-b43e-e300e1ed3e35', '26719271-aa14-4527-9482-bb2de1e5e9da', '31749147-c692-4040-838f-e402b60ffa1e', '1ac8aedb-bb88-465b-8371-ae265c5752e3', '96ffd50e-2b77-43c8-bcf2-e36372afa201', '7714a266-24eb-4ba9-9808-378e29ef3dd3', 'cc2df80b-7b81-40d5-adbd-8bfa583c28c4', 'b9f892a8-e70c-4c00-b293-ea45ab7e52a2', 'f8ddac77-1bb7-40ff-a8ac-9e82b74b76a7', 'cc6eacdb-3c3a-4768-9236-9def335a435a', 'cbf31e17-c411-4e2b-9fdc-0936fb767392', '4a4d8079-0931-4d31-8dac-e3852af155f9', '564075dd-ed41-4e24-b447-85023a874a7f', 'c804e7d5-bd63-48a9-823c-ef3f0c7dcc83', '2a446a3b-6be7-4b81-90b1-531aefcc78bc', 'fd355098-9568-44b8-ab68-047269668307', '4048582e-28f9-4e22-a797-0e93d82be5fb', '468eb0cb-1c1a-4fd6-ad2c-a9e5c0ade8ea', '0fd49452-8282-4de4-9947-e8aff1a9c44d', '3261b105-0728-43e0-976d-7d905c534cae', '4ed53c4a-2ab4-45db-82ab-20594bad849b', '7258b590-3e7a-4330-b829-c9665ebf5208', '08fd6230-0402-4176-a813-f91fc8d695e8', '08313f64-b9e2-4990-864d-89f950e01ca4', 'a0d656dc-e2ab-4bee-bc29-36bedf8215ce', 'faebbb20-0ea5-4619-a448-57d67ee1449c', 'b84d0efd-e258-4856-8aeb-46ebea0ced70', '774fa242-44da-42e7-a192-85654e6fdcbf', '4617370d-ab15-47ca-952d-8876ce643d95', '906a4fc4-4148-4489-9bd9-a1e69d61364e', '7268319f-dad3-4f73-b253-9cafcee46d72', 'e36f39c7-3728-4139-9bea-51a2025c3988', '2fbf8051-baf2-48ef-9814-f2d459e4ce24', 'd37954c6-3c4f-4b93-8165-0eec4fe7200d', 'c34402fe-52c3-421a-850d-bc30b07ba871', '5df17e24-3cbc-4435-8ad2-8e4c84ebd6aa', '6a97ffd9-c1b7-4c4c-9035-270d8df138b6', 'f9e3b85f-be58-42ce-87a7-3c76e37d86ff', '732c4c3e-89cf-4c10-b551-1a0b17398916', '49877611-e41a-4a5d-964d-ed15ce748b6b', '29473826-72ab-442a-ba39-7374ecc180a3', '61baa8d7-54a0-4215-b9be-83b7d6dc3efe', '86b4d695-99b2-4c42-bc94-a7fbbed64534', 'd6bddc1c-382b-4ed0-bc77-e15c5697be70', 'b1c49d8f-a1f8-4840-bd83-15b57dab9221', '7f148a24-e048-4dab-bf6f-763f52810c26', '8ecda4bd-182c-4f93-871a-490d04f1eac9', '78556b10-7960-43ce-b59a-6336623f2a9c', 'e583c777-0ef9-4faf-ad78-9975d28a77ad', '12a5d9ec-1e92-42a9-9bc0-96fa75d81bde', '506c540f-67fa-401f-91d8-428e9f6b75af', '28ab1073-0e74-4853-a6e3-850d10c09569', 'dc48d107-f499-48dd-85ae-e73ff2c5a75d', '802ec670-cc4c-4daa-aa5c-f2f9d75ab7dc', 'cff23a15-4454-4e37-9c36-f7d2313daef1', 'd8a9a0e8-67c0-4955-9650-ddb56dab9f69', '66534f7b-a842-4c4c-a8ac-ecdd43b29e84', '55af15e1-27a8-477f-b45f-a99988e1edf5', 'f28efa1a-25f9-4311-b22d-e99b761ea91a', '181520b6-b803-443b-b61e-eb8eedc28479', 'b7d84ec7-e3f1-478a-9533-22e7b8c98ee0', '82c0dbf9-3c5b-4331-8849-7f328f5fb69e', '3c8ac872-25c7-4c6a-b775-5343ed3049fa', 'cc0e030d-fc27-472b-9653-94550ceef922', 'ef8fa168-e48a-4bba-970e-920206905a5d', 'cc97886e-0a1f-4f61-a2eb-df260722c45b', '9ba7af7e-5919-4e41-bed4-3d41bf2f173b', 'ab222806-9857-4b19-b9ed-1d1a28018061', '0f6f966b-387d-4fa4-9024-55a2e5eb58f0', 'f26350e3-f713-4a01-804e-a0a0a613fc4a', 'a51a0323-560b-463f-9bca-2a2dbf43cc30', '18d8f3d9-9f24-42a5-ad9f-e207c83672fd', 'b0eba786-d54e-4eaa-b513-2bd05438bfac', 'fa1c5268-ac6c-4bc2-b84e-455b1cd69b95', 'e456ba12-cb4b-4f52-a56e-a8fea087d216', 'af945e76-cf8d-4612-a237-0c034568edbc', '1a781d2a-4791-4528-badb-6bbe8c47ad64', '1a638ae7-bd1f-4f95-82f9-b8eb79f24f0c', '6227e743-5d40-4b50-953f-59c82ecb54fd', 'da9dd62c-d52d-4aef-ba9f-1ac0a43c160e', 'be73582c-c1dd-4f04-8e41-fe922bb314c9', '237750a3-c777-45d2-824a-8bcb98f1346a', '6d78c2d2-4d91-4e8b-91ec-3790106f92ab', '2028314e-56a8-4344-9f61-85d97845d63d', 'c02ee742-9c2c-4a30-9414-a5a289719917', '1e13d3f4-ae50-4d61-a3d5-8b8e12d0a1c8', '5fae2e82-9956-4b8a-94e2-53d5a4e59a55', 'c2704144-1d24-4ab3-afba-e6863c7e0712', '43d2c8d7-f6a9-4626-9fe6-e2fa679811c7', '3455e028-5aef-4335-b594-c595a68a1550', '3baeaed2-9e67-4802-a2c4-d9ff0c47de05', 'd26f0bd5-aed4-49e9-ad5d-68186ce97362', 'b06e1b70-55f3-4bd9-94f5-2ac0b1b4e2e7', 'e0281e7c-6edd-4602-9763-493a19047dd8', 'c5334d4e-9609-4c43-9cb5-8edbd4c44e12', 'd3bf1e17-f59c-4057-8cd3-d4bb6892c1f7', '411a0f3a-cb0f-4177-9966-bec211faefd9', '7c310b28-dc7e-4094-be48-4d1f1dd74347', 'dced4f84-54be-44b8-9bdf-c4a0fb8f743b', '319ba9c4-be44-44ad-a6ab-2a459638d4fb', 'd3aa1b4b-ff07-4a8a-850c-14d604ce4d92', '412dabff-f49e-4661-a4d9-f37977fcabb5', '98d51f86-23c9-4e86-bd53-91428749924c', 'e693ca9a-a4fa-48a8-94d4-c3397894526c', 'c2052634-26ed-4054-b56e-38650f9342d2', '3ca17bf0-af00-40db-9f34-d508a86b9b22', 'ab6579df-5446-46bf-9e67-40560c8d4687', '5c7f0e13-92ad-4aee-8f9d-66692029ec6b', '0d28cadb-d38b-4c15-a28d-431df0b1fa60', '8afc8857-6bd6-4a62-aca6-b9d9f81118dd', 'c87d5fe5-37c0-4336-8f8f-da5267cef50c', '4766601c-1672-4578-9588-7d067e333ad3', '1cf44c8d-15da-4716-bdcf-21a1e213df32', '4ebf8ef9-2a9b-44c0-9131-f27cb9c32124', '7cd8e684-bb28-4241-9d59-b7a4b1c4102b', '0251de35-dc30-4901-8afc-b1167914a77f', '4a3ea779-ae31-477b-b8f7-5b5d4afd4ac5', '9366546b-16e8-40f8-9145-ed60638298da', 'b7cc01e9-aee4-48f6-be8f-117f7b1256c7', '724baf2c-a7c6-494c-9530-f7ff7e20e3fd', '9d687807-0a94-4337-93d1-02a8e1c3e6b0', '4a77d835-0150-418f-b0ee-034119a75bed', 'dcf0502c-b059-4bde-b72f-3cc21872add8', 'e2e7fb5a-d172-4cbb-9357-d78758e77e04', '7fd86011-1622-4bda-8bee-cb1128ea756e', '6dfe7358-d7d2-4f97-aadd-6f589ef98a97', '94b189f1-7c8f-4b25-8ebe-648611e5a53c', '4bb4a12e-6fe4-4dfe-8fec-6d50c3bffcf8', '6898ac61-873e-4242-a9c1-c358d45581fb', '51c8eb69-4e2b-43d2-be82-c573a5f69d09', '22ea82af-b232-45fc-8781-d57b172ca25c', '67615c90-8ab2-4ad0-b4e9-46fecc409954', 'd54dce90-d3ef-49df-9da7-198761341b6d', '758afe0a-df47-4855-aa11-547230a328bc', 'e73235d5-806c-4141-a6ec-d5d1fdc91fc2', '9ecdff89-7245-4191-896e-272926f95480', '4b9dbd6b-1927-4a2f-ba8c-52f4ddd371e9', '6b876fdc-4da4-42bd-b6fe-71ecb9f42c76', '1bee1841-6836-47d2-806e-3da4a662ef50', 'eb842055-54d5-43ba-9c11-183fbd3552a9', 'b5faeaf1-1c18-4300-8f36-ab42e7fffe3b', '724dbf54-862a-4994-bcf1-e87a091ab849', '12a7bfed-c9f0-498a-b46f-3ba2a8597c10', '84633187-c4de-46d3-aa14-f220120a4e26', '031b576a-3c38-419d-8edc-9f7a45c82678', 'cc75e22b-ac0b-4215-872d-a4079801b4ba', 'd441d833-4b30-4b80-a924-e7c2f4b0af7d', 'd892a898-75db-4ac2-9c64-03907ee9e6f6', '016f0e65-cf0f-46d4-a3fa-62f36510d213', 'b0abce0c-7c44-4d64-ad37-ec6889244bf6', 'a180d10e-86f1-419e-bc91-a3b82a4d7a80', 'a76e2eab-8c3c-41a2-8ad5-292e62ae14f6', '38a25ac7-f273-49dc-adda-affe38cf88d3', 'a7488ac8-795c-4c31-9e62-79d8be85a3e5', 'e88ed49f-6dce-44b0-b71a-23152fa748d7', '0cb66651-8f9f-4747-8624-2637230d73ab', '90fb4dab-4a30-4183-bc32-630de68c4bd3', 'a24c1c41-140d-460d-a495-6ea1a629ff87', '30719974-35a9-450d-9d3b-6e834bfc85c5', 'fb744540-1fff-4537-81aa-a49be750d40e', '69e6d1d6-75bc-4354-be31-d5d9de4a782d', '4c784013-6307-4900-bd0a-baeae5b573fa', 'e1c91912-eb5a-440e-bac3-b774e2575197', '7465949a-4c6c-4091-bcf2-1913910e4d83', 'a728cbc0-3170-448b-9e5a-2ebb8aae5211', '632da81c-bef6-4ece-a84e-31c27098c933', 'f07d32e3-e0fe-4ecf-9212-38ace392dedf', '9519363f-7b8b-4ee0-84b5-5ba447c24ad6', 'b649164e-31ff-457c-b76c-ebf6c1bfca9b', '39ff0f79-c971-47a6-93c2-2b04ccb603a7', 'a0876ccc-6a95-4645-9b5e-cf598658384f', '7563248c-3189-4d14-88b7-158bc3dfe5b3', '75a70b3d-e33c-4589-8336-e4255e66298b', 'a97ea95a-12ca-4cd9-8b9c-d95c1840e579', '5aa7dbd2-871e-4098-9456-0a7dc388ad58', '17b20bee-4bbd-4647-81f8-53ec5b198a67', '2ec63bb7-1cf1-47c3-9f55-a7f604a234e6', '4e4ad1bf-3762-4047-914f-bc13ffddb03d', 'c74fd12f-ba6c-4acb-ac52-281a6a4052e2', 'cdc7b024-1769-4bd7-8da1-db1410ce2054', '0c230f62-11da-4722-b7ee-2c7f927756ac', 'd40b80e8-3329-466c-bbb4-db7414954fe6', 'a5c8e6e4-cff8-43a8-b111-1ab2ded95131', '0a85315b-03fe-4388-ac95-69bd24b4ffe0', 'e6898d45-aeca-45d7-8022-d1de10e17531', 'ddfce16e-3c74-43bb-a1bc-47eee98d460e', 'ef522aa1-b206-42e4-9451-8f8330c8c617', '0e3c2b9c-006a-4103-8610-ec42dea396ec', '181f045c-008c-4ec3-b552-21a2d3c3dcd8', '8a038165-b508-4e3c-84bf-283b466eaf3f', '99d684e4-e901-465f-9631-3cb443d606b2', '5c60b5fe-91a3-4918-a162-f0f6e6f398e0', '34655655-9b99-4bfb-b6a6-404a70bbacf7', '2f6d528b-aa31-47ce-9f8a-36e604d14200', 'dde3bff3-696f-4af5-9d8a-f6a96940cb89', '5456a878-4fca-4e28-811c-e07f75ebf388', 'dc4597ac-fcc9-420b-a1ab-2afb599de483', '152ff616-d74f-4487-a509-8e2ee73dd815', 'b28a0268-bc22-4979-9243-00379d4d489c', '2ca2b1d9-5225-439b-8c7f-8636f461e964', 'eef3caf1-ebc9-4dbb-b7b2-f897bce4d159', 'd7672999-9c05-4ece-b5ae-825797900d4f', '19ea4b5c-b1e6-4ba8-b236-aea5cdc5a6fc', '34f770af-b89d-470d-9ad5-5bbab1c5c042', '8fc9a02c-2b95-4d1f-a4fe-7259cfcb9212', '05b79c9d-ae4b-42e5-89e2-c030ab03ff01', '52e9c04f-9e09-4361-b20f-3f85da3fad48', 'de667ea2-58bf-4429-90b6-a31fd876ba9c', 'dc130a80-ab62-4649-8088-62fa6f3ac154', 'abe89db7-2460-418a-ae04-56042686c973', 'c137d30b-3318-4e09-a94c-c09ddf6c4991', '1272ec28-7709-4f79-93ea-5a8d88fdca26', '7dee74df-e5d1-4d74-b053-d18d72aa5c82', '73973de6-fe2e-4c18-ad51-ee545ab51fb0', '46fda137-986a-4ffb-8efc-9aa06b4b4f57', '6058e9ec-bb2a-4298-aca1-57a7898606c6', '70921e0f-12ad-4bd8-b466-8bee612fbc7f', 'd5bb8d26-bf02-4846-8635-93b7e0dae81d', '2971b66d-0e96-42db-8ac0-3681653d0a74', 'd3096f6f-8486-4ea9-a588-b01b6328b789', '2ff4abe2-4ead-4c72-bb54-e546cf68e1af', '60949c56-f313-4f75-8cc7-570a0d79aaa2', 'ade2040e-e717-455b-a29f-ef2b686875ef', 'eaffa373-c834-48c0-9de9-47e96ab76572', 'cd11ba8e-f121-4c35-aeff-e397959e3528', 'c27ef575-6c7d-42c4-8989-febf583b43e7', 'f1e1429d-b933-43cd-a13a-b43f924f7f7d', '1129575f-7b38-41f3-9d07-4c869239780d', '3475ecb7-695f-47eb-8c0e-bd6b20bc1e8e', '51696cf1-0555-4a15-893c-23d22df8569f', 'f8d134f8-4651-4b72-99ff-d35b48240a75', 'a642499a-cd27-4178-9a34-ff20e65f0fee', '7cb805d4-6c0c-452d-a3f7-503d63ce6659', 'dac8292a-8bdf-40a4-ad14-94b3acafe20a', '4aad7925-fe0c-4582-a6b5-a159ed512a26', '185863c7-4a7a-442b-b619-3b27d52fc565', '481a37f0-6181-4ebf-a796-c42090a01bc6', 'e326c803-553d-468d-be3e-ae57128a01ee', 'c4cc29f4-4942-4c1b-985a-d860905b3694', 'c2eeb19e-dfd1-4fce-958a-8106e2731a87', 'fa6a0e47-e686-4921-825a-353fa408b8b7', '670e0ef1-35bf-43b4-9c57-7999dfe1df43', 'e233ad2d-b7ef-45cf-89a5-e9cb0d8d53d3', '663051c2-9f46-4459-96cc-9e0163a165ed', '507bcee2-2e69-4397-92c3-b3f35483525e', '8a5e783d-85b5-4104-8e3e-d36f8d72a947', 'd707041b-9815-4f40-8717-752a8c333477', '26a11820-b9b8-4e7f-a12d-a33e191e0809', 'f9758ead-fc2c-4cd2-afdc-4a6f38f35696', 'd5ad282e-1ca7-4dc3-a1ae-f30ebdf306c1', 'af0165f9-b5ed-4c72-95e0-8e016bf882a0', 'cc566465-ab87-4931-a6f2-ca7b7b60b51e', '9c388df4-9f60-4f92-a80c-1c7b0e248ae7', '7a51c7bd-6c07-4b20-a420-d76b3cb02915', '4aacd26c-eefa-4281-a890-29bbaef14b02', '47b57c6b-401c-4831-beff-d3a30d9fc8ba', 'b75a4744-e8df-4232-a97b-fb19314c2586', '029eb3a2-6411-465f-ad89-224b0b4af5b5', '698f8ef0-4d43-4823-89d1-0f935baecf87', '691bc953-9f1a-44dc-ae92-5637e766b210', '10af78ce-4c61-4d6f-b083-999e7588ad8d', '986cfaf9-6ac4-42ee-b8d9-c814d9c1c2b9', '37634bf8-3e45-49b7-a5c1-8db29f974883', 'bf87475e-779d-462f-9d1b-c6569d7c5f00', '0f99b125-67e4-416d-bd23-9f3dde2259c5', '5c8da0d3-a87b-49c0-92c6-bd732fc71597', 'c3a8f684-b756-4eb7-9ff3-a6a72a3cd49c', 'c0edf6bd-cfc6-45e2-b097-41208b6e32dc', 'c31816a2-8a53-44f6-8fe9-e826b71e9627', '9361d585-1a6a-42b0-b6f5-b65b1c774624', 'dcc30533-b50f-414a-a584-ece11cd8c714', 'e3d7120b-3b94-4773-8cb9-1658318fe36c', '78ddccbe-9325-4602-9298-c5d1ede80187', 'bee42cd1-8af7-4325-9a8e-bc5c07980e39', '6a30a54c-106f-487d-b91f-5200d80424da', '06f67880-42d6-4531-879d-0b8e9dde73c5', '009472e6-e959-4a00-b9c8-1871da77a70b', '1d6032c9-94c5-46dd-af15-4da25a1a266d', 'f651270b-ebaf-4805-a40d-ff96d40c0616', '97c0cf5f-0d85-40d0-8a02-9a487377c853', '4b270554-c683-4f4a-80de-a7d680370669', '4848a60c-63ad-4c26-a59e-08bbdae6c70b', 'fba47925-76f4-4019-81d5-ca5632a241f0', 'e091d05a-1d23-4963-8eab-7460d8351c39', '7b6dc753-f81d-4a2f-8b21-da2e9a5e6966', '5bd89b90-679d-4044-a2c4-3193b6c63bed', '49ed4bb0-0156-4a42-9970-9604e19c58d5', '4c9c28e4-a7bd-4f19-a450-26d164e0103c', 'c5605d77-8e3f-4143-b489-f3186377ba17', 'c7f37f3e-0254-451e-9b94-5e23a3b1952f', '8e8c32ed-88ba-4ec5-a91f-5d2063ed6647', '73574320-8208-44df-9696-178c3d1a7356', '9e017ae4-1957-48dc-9031-97bc7ead5417', '3d6d4381-febf-4034-a28f-935aa64a2108', '194c46b7-10d6-478e-83f3-0d97a3d73aed', '015e7e60-934d-4073-ac16-b0a75c941ca9', '943ceb10-3869-41cd-9d5a-b16036d10b71', 'fe297963-716f-4595-9e52-b7d20b81b779', '14e8fdbf-4eed-4633-9344-9ef5a6b02a55', '84be6194-4723-4164-8c94-2865718e1fac', '08a1d115-6433-4b68-9c38-9bc4b7262697', 'f7ff2c98-7f6e-47b3-b147-552225398618', '3d9b0ab0-71f7-4c70-9f6f-485aa680ef6b', '858048f2-cf67-4bd7-9269-1c541b3bf8a1', 'c48ba248-ea2e-427a-bd3f-0b3c418f8879', 'c790de47-0198-4703-b411-5fcecb6e4d9f', '9e55ada2-bb34-4bd8-bf24-b152a86daf5e', 'eaa0f2c6-83e8-424f-8f61-9ce9a210eb0c', '7329da4c-6739-401b-993b-83682e816fd1', '69d09625-8761-4a95-b989-99b85b0685b7', 'b5ab4b17-6204-4f97-9171-4e5c52c063de', 'ea1684dc-accc-4686-9824-b0b2bd68bc5d', '9339d816-129f-4fb2-a450-5e9ec9fe4b77', '160bf099-267b-43d6-87c4-17f1e4ea4de4', '4b0ee9e2-b4af-4c14-a67f-f12fa6982736', 'bc33bf64-2080-4205-bd53-806647cbbf2b', '3c9c90b6-6935-4cfc-8b96-da8b27d7d54c', 'f670748e-b454-4a37-ba3d-db7133e3d3f7', '90cad7ac-552a-45eb-8cf2-89ddcd74917e', 'ce27de82-d56c-4546-b56a-ff95acccc7e5', '914a8d50-893c-4462-8ec6-f1d4a3c3a69a', 'd08e987a-4cb5-46c5-839c-113f62adc657', 'fd2ca9e7-a748-4479-8bf7-fcc32179c3be', '12322083-2606-46a6-8e19-77ddafb024d0', '6dd31184-2320-46c2-9c10-9314fe6aed3e', '087e81f1-aefd-4e99-b8c8-4d3d2732bc3e', 'b8ff0c9b-de94-4a52-a09e-1a523e8af416', '7879d987-365c-4c37-80b4-bbc4783db338', '6ab369bd-e583-4153-8031-83ab9bd98ac1', 'f6882f92-feb3-487f-a16e-c5c337b711dc', '36559900-9525-4e8c-a57b-d497f6e3a6f6', '4f4b6296-d0be-45ba-aa2c-e8d0bb7cd5ea', '63492d00-ab2a-4a08-8959-3225481b0a88', '0c28cfe1-4f6e-42aa-a9d7-05b4417fa79e', '603d7570-5e8b-4538-8aab-c82ae5e9136e', 'aba9eae4-eade-46aa-9c51-c22a65a4dceb', '59c93403-ebb2-42e8-b7ac-9ab9cc0d8933', '1e06b362-ec13-4e70-9ac8-2b1a93430596', '4ed29dba-2f5e-411e-b96e-4330fa811f30', 'aed847b4-1ac1-4935-9a99-36693cf9d6e8', 'f81793c0-5766-4022-9116-2a4cdc3c0b21', '083c4edf-4ea7-46e8-98a3-8ade1f45ae59', '0948f86b-0813-422c-9211-1f41c5f3f224', 'b82279ff-d2fd-46b5-b53a-9dd90d8cf480', 'c4ab522b-7374-4644-afe8-b1f59f8aa010', '0e1a7b9a-d92a-44ea-9119-deb9f3da64b9', '1ce61e8d-5626-4e9b-86ea-632544698fde', '71cb177f-5b08-4bb0-a8e3-0a390bebf5d1', '061d871e-b38c-4aab-8395-742ab699affe', 'f07766e6-c8d2-4d94-ba3c-6c8ec6d3432d', '8cc4c555-813a-4bb8-b5c5-4e4584aa646c', '20176e18-02c9-42e3-a518-b4df4f3caf99', 'd9a0f809-48d8-42fb-8d46-fcb6e462e4cd', '360324cc-6ada-47a7-b5ce-97eecdb8e62e', 'bc3eeab3-4f26-40df-a984-8abfd74b0fab', '23e30dd3-5271-44e0-9e81-bdebdd30e0b1', '1d2b0d7a-f5df-4e39-a075-d2bcd3bfc296', '63306f82-bdec-4234-b151-0ab0a7c38786', '776ad9e3-a483-49b1-9e59-29aa309f5e40', '4bae42c8-0ef7-4d87-8070-2ecfb7a0b01c', '3d87d2fb-8003-4748-97fc-24abcba2d8b7', 'cffdbe97-a8be-4c8a-9b88-21c21fa2c60c', '97d28e0c-4e9c-4891-988b-7d5920b0e17a', 'd78109d1-6aa8-4917-92d4-3ec475472e42', 'f4227802-a53b-435d-96b4-857c3e18beab', 'c983edee-ef31-4646-9b17-87518233cb7e', 'a166ac3e-af84-4dcf-8ec2-0f24dd9dc473', '0f678d70-6f14-47cb-b2f9-088cdb974275', '85713323-f678-4ab5-bc3a-98559e93effa', '169b0ed5-cb80-453b-8934-e6d8aa8d5718', 'f039a2d8-2d9f-4a94-8705-599c112f2712', 'c1e748d1-b15f-4075-a843-516724c966d1', '3e91b218-434b-48d5-9c9a-d38a9e9e231c', '6c1b53b3-e34e-496c-952e-079eaeaf060a', 'c0b2236d-5e0f-4b3a-b2ac-027719887927', '404877d4-ee0a-410a-9876-dc942e25c0dd', '217402c2-bca8-4243-8565-18674c249989', '010c8583-4f4f-4f90-bebc-a2eab020b35e', 'b33ddfdf-16fb-42e8-abe0-88a0800bc426', 'b1f6a337-013a-473d-9cea-b37a8f9b67f6', '1bd2faec-913f-4a40-a763-4dadbdd6eb88', '82972530-4c51-43ae-98ad-6ecc79b8d017', 'a7c7c87a-c8a9-4d4b-82ae-c7242e503dcc', '7c8fe235-1320-4860-a1d7-d62a1fefcea6', '7053dfaa-4d15-42d8-b9c8-d048a0ecab61', '67181152-aa68-4826-8532-d8f5874465e4', '141a60f1-ee58-4772-9b9a-8347ee9d3998', '6b40c892-4e79-46b3-8a63-c0190ae274f0', '2a17451e-f941-4c79-bfac-78bb3fd84c79', '9c0bb663-f78d-49f2-8618-f3179bfa04e2', '3bd7bca7-251a-4ced-b8a1-58e2ec28fbec', '744f20e7-7413-497e-bc45-139583bee0fd', '8539a964-6361-464e-bfd3-9455ca21af53', 'aaccaa14-2af8-410c-b108-7d464eaec060', '9597f87f-d1a7-4821-809a-6ec030f33134', '739da429-249f-4ec2-923c-8bebf5a9be0b', '4cd111e7-44ee-4ee7-ae05-7e5c4e1a1f36', 'abafd08b-dac6-41cf-92ca-d68d42a8ecaf', '48bfd22e-06b7-49ff-9ef0-5fdf33eb1d4d', '2688c70e-a478-44df-a328-565b78524ec1', '78e2c18e-199e-43cb-bb58-cf8ee34fd669', 'b9052130-b627-487b-8006-866e7880659c', 'b4d45dbc-d7f2-4abd-8ea3-5e1398671fb8', '044f9c80-151a-4d62-b90f-5775ad85c1f1', '2b40147e-1d27-4cb8-b7ad-5499a5078097', 'ae4cd1e6-a254-419d-bd74-398b36690a1c', 'af56dbac-961b-470c-a742-373fbec6f2c2', 'def3cd93-1e3f-49bc-8748-727ac0ec28bc', '42cdd3a2-ebc7-4e7d-8700-81a4432affe8', 'ca31c469-14e8-4f16-94a5-38962a8a80cc', '113b475c-474a-4f56-b804-60a5a771ac41', '0bc3e569-b9ea-4cd5-8d7f-63cddc59089c', '4d5f4bc8-2bb4-43b9-a4ea-8855db383fa4', 'de147f55-dea8-4183-9863-b55e61b6dbaa', '89b16149-9014-4c1b-97d6-82ff66e972e8', '5f949433-f38c-484b-a417-6d8d955d0871', '19c8b3fa-2861-416c-8d4c-a00145584000', '4f8baf31-db82-4708-9781-81224c3b95e5', 'c4b467c2-ad6e-45b1-9257-750e5f096d7e', '7d840afb-0fd6-4d36-a048-f821708d49ab', 'edb16724-3bb7-4203-9d04-c1b233290407', '85120813-d49c-4c26-8e57-1321050ba466', 'cce5c07b-ed30-4ef3-8abd-d49d180082ef', '69bc1905-e204-434d-9630-af3cb723febd', 'fef4de38-a8c1-424b-8c6f-7f1e7bba7732', '7b604276-4c08-4dd6-8716-712303706f11', 'ef4e92d7-8a8e-4a8e-b3d7-5289270edc28', '63634356-ee87-4fef-ab39-e9d6ca0db11a', 'acfb7305-60bb-493f-80fd-f983627da86a', 'a23dd3ba-8a31-4816-b718-08762ba1dcd8', 'dd10eba9-858a-4d07-8fbe-e46f85490bca', '1fa0aa5b-cc9d-468b-859c-0ee37485a061', '324af3f5-ba6d-4590-9307-d9840be9dc4d', '24727e6d-8179-4d6e-bb1e-5d18f40a3424', 'a9c7d4a3-8d5d-438c-8eef-f21d284f5367', '11f52e5a-e987-4fe2-bceb-c3f4e68db79a', 'cc921357-978c-4ef8-86c2-c2fa046c6f71', '5fca51f9-42df-46ef-9a46-4a61cfd13c47', '8e1e69b3-0dac-4419-b40b-70f6b6660975', 'c8c72767-f00f-464d-ac0e-8216803354d6', 'f8813aca-7650-48ab-b11b-caf624a7d62d', '3c52ccc7-54b8-48a9-9abf-e20df5184497', '5635f128-2e91-46d1-b846-44b74eb344c3', '210c95be-abf0-4e0e-99e9-78e9d226a259', '8c10dabd-b85b-4c58-87e2-c54ca639546f', '4f87b590-b99f-40aa-b43e-ec22490804c3', 'efba2637-961b-42e9-ae53-293602fc0cdd', '10942f4a-d5c1-435e-8cd7-c90ce90a125a', '2ae92334-91f8-4a0f-b735-13592ec7a9d9', '2651b172-6c0e-4fd5-8d06-0f2217262967', '0b27bd85-a7ed-4f3a-9fd4-98e11f7702e5', '401404b7-dd29-4552-b4eb-071b00800975', '68ba6a08-155f-45d5-ae20-aa4496b78a0b', '1969e542-a651-4cfc-85c8-b9b5849107e4', '96e604bf-4205-4141-b6f0-fc1f9590a388', 'c6024c7e-633e-4ae2-8919-445d01083a91', 'bed2d0de-385b-41e7-8794-b0a7794ac826', '6921f14b-e059-4ec5-b10c-a16f3fc70c6f', 'dc9e2c1e-72e1-40bd-b0ba-c4b01f531d48', 'e44bc4ea-add9-4819-9b24-7e0c1e6d719c', 'd83da1d8-cb9d-4064-8513-2c3b2372206b', 'b30e27e0-b3d5-4d6e-9745-b7bab550facc', '36fea65a-93c0-4114-ba2a-7b16b0b6ba3f', '4bb13242-6350-4e79-a320-f305927cd431', '0cb19192-eaf2-462a-bf3b-dca0bb42647c', '22ee1b11-825b-4465-bccb-f98cc022c578', '7d23a099-f7d3-42e5-8d26-67003f2ee8ae') AND term_start IS NOT NULL;
  IF n <> 529 THEN
    RAISE EXCEPTION '1536: expected 529 populated rows, found %', n;
  END IF;
END $$;

COMMIT;
