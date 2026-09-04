BEGIN;

-- =============================================================================
-- CA_0098: AI Oversight (ai-regulation) — re-audit chairs 3/4/5 against v2 wording
-- =============================================================================
-- Created 2026-09-01 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
-- WHY: CA_0065 approved+pinned the v2 triple de-barrel (chairs 3/4/5) to Season 2 and
--   deferred the row re-audit. This applies it. The v2 rework removed the "ban a high-risk
--   use" position from the ladder entirely (it lived only in chairs 4 and 5) and split
--   "disclose risks" from "held responsible" (chair 3 kept liability only). Every reworded-
--   chair row (462) was read against the actual instrument it cites.
-- DISPOSITION (Chris Andrews rulings, 2026-09-01):
--   carry chair 3 (liability-for-harm instrument): 40
--   move  chair 3 -> 4 (safety-testing / impact-assessment instrument): 41
--   carry chair 4 (safety-testing instrument): 46
--   carry chair 5 (universal pre-approval — Krzyzanowski): 1
--   BLANK 334 = 248 dropped-barrel (85 Maine LD 2162 chatbot bans, 31 WA HB 2225,
--         deepfake/facial-recognition/rent-algorithm bans, pure disclosure) + 80 thin
--         (no concrete instrument) + 6 chair-5 (targeted bans / vague-maximum).
--   Distribution 19/123/269/186/7 -> 19/123/40/87/1 (334 blanked, 41 moved 3->4).
--   Applied to the shared answer set (Season 1 open; no Season 2 answers exist yet) per the
--   CA_0056 / CA_0045 model. A dropped-barrel or thin seat is under-evidenced under v1's
--   double-barrel wording too, so the correction belongs on the live rows.
-- Idempotent: DELETE no-ops on re-run; value UPDATEs are stable; context UPDATEs are stable.
-- @context-decision: rewritten-as-blank — the AI Oversight topic applies to each blanked
--   official and each record was read in the re-audit; every blanked pair keeps a documented
--   blank ("Researched 2026-09-01 …") naming the prior basis and why it fails the v2 wording,
--   with sources emptied. No answer row remains for them. CI answer-delete guard matches only
--   ^(\d+)_ names so it skips CA_ files; the ORPHAN_CONTEXT guard below is pasted from
--   backend/migrations/_templates/answer_delete_context_guard.sql; check-stance-sources.mjs
--   and audit-chair-evidence.mjs are run by hand after apply.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id='666bf03d-81fc-4138-ab15-69ae734c9023' AND topic_key='ai-regulation') THEN
    RAISE EXCEPTION 'CA_0098: ai-regulation topic id mismatch';
  END IF;
END $$;

CREATE TEMP TABLE air_blank(pid uuid) ON COMMIT DROP;
INSERT INTO air_blank(pid) VALUES
  ('0ef9c1e3-8381-42e3-bafc-d7632119c37f'),
  ('0aa1c59d-f8fe-4569-94ea-484599d49b73'),
  ('74579547-1454-475e-ab35-12cf88a998b9'),
  ('96eff205-63aa-4999-890c-c83bcad391dd'),
  ('64783a11-a7ae-4ab7-a6d2-593ae06796f8'),
  ('8e804443-d7ac-4103-943f-546a76c4c8bf'),
  ('0265efd8-29c9-46b4-b408-7da40b455257'),
  ('52d3e817-03bf-4dd5-8a16-67b44acf23ac'),
  ('e7c985f0-7804-485e-8ad7-8e71c0129a00'),
  ('4f4b2bff-0054-475f-8687-e83f68085f15'),
  ('238222f5-e5e0-4331-8540-ee904bbacb8a'),
  ('da087947-83af-4ca2-91c8-1f9e0bf887a9'),
  ('066de417-a463-4574-8cee-c2eac3700d8b'),
  ('a1467b58-9cc8-4611-a03e-07defc1679bf'),
  ('27d57833-842f-427c-bedd-aa1695fe550f'),
  ('f3e749b6-24f5-47b4-8f31-94bc23421b86'),
  ('e9e79f56-f4c8-4694-b161-2858722dcbc0'),
  ('96c77e2b-df35-4d56-a573-8bc0c15a142d'),
  ('424eb63b-9976-4059-8049-365c09719cc6'),
  ('48b16473-9fcb-4957-a836-8de0b8609946'),
  ('100de02f-b44d-4587-9b90-19aa5081708c'),
  ('c88a915a-6613-4940-a12d-18a28b00935c'),
  ('e6788516-795b-4963-8762-4d1cd617ac35'),
  ('ceace463-1299-4c49-b5aa-e73af2534e0a'),
  ('99198363-2ac9-4b56-9d80-7abfe7b2a01a'),
  ('1d2d647a-16e0-4d17-af5b-acd83762c359'),
  ('6ed2b57e-4930-4099-8567-d5a6bf7b999f'),
  ('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e'),
  ('91f87a53-13bc-4d35-b3c8-49227ae80faa'),
  ('32608fd7-5038-4474-bfa9-7392b5e0eb80'),
  ('7a0da48f-2c29-463e-969a-52d06137cde9'),
  ('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3'),
  ('61a601c2-7faa-4889-abf2-bbb0066ce448'),
  ('ea85c891-d6c0-4d45-a92c-f565794b1729'),
  ('dd5d3f6d-fc82-4774-b510-287ec47cbd84'),
  ('af01a7ec-9318-4862-ba78-553e5908182c'),
  ('86e6a2bf-5216-4022-900c-621a8480f2e7'),
  ('fc23b939-0dfd-4968-ab19-fc1e7745e997'),
  ('721bf21e-7913-431b-9807-037561f18b82'),
  ('872f60a5-7ded-473b-87a8-a904d6ca4d6e'),
  ('065c6e87-8778-43ee-ab44-b9982a677aa7'),
  ('9974fbb8-10d1-452c-ae8e-a853dd3f7d37'),
  ('216790b9-1ee5-4198-b6ca-e8650017bf59'),
  ('70226cbc-2707-4962-835e-175a2864d3d4'),
  ('c0373c9a-54ed-406e-9ff6-400a43dae429'),
  ('78726dd6-5ce2-40d4-9cf6-10fc6a840756'),
  ('c1a8e812-2851-4c1b-b5c5-cf2997ee2ed2'),
  ('cc79161f-2a1b-491f-9c4f-b0cf161196a8'),
  ('ae7e8d67-e8a4-49a7-bb5c-715c99168374'),
  ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6'),
  ('f3daea18-1a32-486f-b8df-659d7c653c05'),
  ('91d28127-8183-4b67-a1fb-dc8a150f6199'),
  ('f72689da-fe02-4bdd-977f-bb7760a42fb2'),
  ('85fdd516-d5cc-48d8-8fec-e425d90f03db'),
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec'),
  ('1844a5e3-8ea5-4ee5-9377-066378b25b49'),
  ('a6f10769-ec53-456f-afbd-2a89d3ac84b2'),
  ('01eac4cc-d6f2-4b33-ab5f-c3d4d2b93dc0'),
  ('30063951-196d-4eea-a8da-4ac1702bd867'),
  ('70b5e5a8-2ae4-454e-b75e-adb200b7b91d'),
  ('e2751db9-30ac-41fc-9db3-5dab859f0126'),
  ('77ceaab2-846e-4bc8-b09d-faff40ddbc60'),
  ('332de859-029c-43ff-baa7-0113ad436d0f'),
  ('f26309c8-2525-49b2-bdaf-62980cbb1853'),
  ('e091da26-dbcf-4d12-87c3-4e2e023d00a1'),
  ('fab8170e-a747-41de-ad39-769d8e0dd901'),
  ('a4a239ad-98ab-4fa9-9d56-7781f46821a4'),
  ('ac09c6dc-d7db-4bdb-9829-0e746c8ca665'),
  ('3bc348ae-0363-4dca-b235-30bc5c073fad'),
  ('afd8d31b-9f88-4eb9-8a88-46e5ef914267'),
  ('02f88a57-ccf5-4fe1-a693-7fc949321fb1'),
  ('3f6ef889-ca07-4cd9-bbb5-300667099d92'),
  ('2e0915c5-45d7-48de-ae59-04bcd6bda1f7'),
  ('a961a076-f7be-436f-881f-155a0e9e687c'),
  ('f2d4231d-ac81-4e9c-82df-b8548f357142'),
  ('e987cfff-23ae-4b24-a64d-4cde8582f520'),
  ('b1baf884-5fd5-4618-b380-f2790fa47ee5'),
  ('1d877e4d-8aaf-4db8-be5b-2a3de0a98783'),
  ('0eabc969-c1a1-47b7-8d34-6113b723a170'),
  ('4b7fb0a4-5d8c-49a1-8266-74a73421bf6e'),
  ('03ed0d1f-e210-464b-8bf4-8f7dffae90d0'),
  ('a74e04c6-46c8-4fdf-b08c-8930c1bb1ffa'),
  ('d36fc2e8-f76a-4f52-bc82-1ea16dacfd83'),
  ('d8daeb9d-2437-4864-9efd-6031291fed86'),
  ('2a6693c7-9149-4e71-85fe-003746f7d23d'),
  ('e6596b34-8d9f-4593-bf0c-4fe7fc17cd26'),
  ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d'),
  ('6160a29a-d896-4061-801a-e5c3d9f06c99'),
  ('b25b77e1-f502-418a-974d-c084801b53d3'),
  ('68254709-e00d-4d3c-9d10-b3daac0c2f37'),
  ('64eda290-d172-48de-8827-6ebca668cf5a'),
  ('108e7bcc-554a-49d7-81f0-c3058f933a07'),
  ('c566a41d-28e7-45cb-9eea-c9501878f2a7'),
  ('1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6'),
  ('67b9aaf1-46eb-471f-8f31-dcf501a92933'),
  ('805fd55e-2e38-43b1-8b9d-a757af05f8e4'),
  ('21c9e711-fb18-4afb-884f-08acd2b598ba'),
  ('0ba1cecc-8493-495b-8d58-34d50bbacfba'),
  ('e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4'),
  ('fd26d6ce-979e-4485-9e35-7d4c179c3c4c'),
  ('283b1fdd-3d89-4f82-a065-098324f2f967'),
  ('e976e2c2-52c1-48c9-a5a6-4337d6740f71'),
  ('a7e29796-a928-49cc-b795-973a4f69fafe'),
  ('463f8a89-e12c-4b92-8df1-0fed43dc4441'),
  ('cf992e89-7b96-46f3-9999-58432c690fe4'),
  ('c4c71706-e2fb-42ac-be4b-0e913d83e06a'),
  ('39db6eee-ccf5-4901-90a0-1c2580731b0e'),
  ('406dd9be-a751-4685-a946-44806bd01548'),
  ('bb73793e-ad67-431a-bb03-663b765204d8'),
  ('81dfcf88-c739-4461-9d16-931f8d51a8c5'),
  ('f9abc9e1-e1d5-4cd9-9983-a403dc94a5fc'),
  ('e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb'),
  ('cc873a93-cb47-405a-93b0-bb2848fdd57e'),
  ('30fdeba0-e9d3-414d-859f-2941140d8e80'),
  ('56d6dd6f-4959-4339-be78-e4b1d0083b08'),
  ('b96758c6-2ea0-4698-8886-d574d34e366d'),
  ('c924abea-3bdf-49af-98cc-7d117cb54ad1'),
  ('a1fc524b-7c90-43c0-83a7-c76664293913'),
  ('7b992556-5e0d-488a-92f7-942ab56660c1'),
  ('bc29096f-63ce-41f7-8d51-c4e6cfa87f8c'),
  ('7e1e1044-a98b-4c69-910e-73de8e818c48'),
  ('6a2d6591-432c-48cc-920a-085a51a01d74'),
  ('85d27350-e1b6-45b8-aee3-509ca88c5af4'),
  ('c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'),
  ('4fa06009-8f67-40f6-a8b3-d2d62712240d'),
  ('e36107af-ea8f-4fca-a727-0e37ca2f6fd4'),
  ('72dd5219-490f-48bb-986e-183a6098d602'),
  ('387d0557-3a5d-42f0-861b-6de2e5ea8af7'),
  ('dc92c805-4734-4d4b-8ceb-597e59b0e268'),
  ('fc52e8ba-c234-42cd-b2a2-5abddaa9c3b1'),
  ('60f2dcfe-1669-4dee-9c32-a285f4756569'),
  ('edc48d7e-4f91-4e59-af50-79f34df8b011'),
  ('535591bf-7151-48ba-81b4-e8d9983def72'),
  ('21b282b2-24bf-49b2-b0b7-109eb98083f8'),
  ('9739fb00-209f-4ed0-ad06-b9d97d74ced1'),
  ('1963d6e9-069b-4770-9489-59e36faaa2e1'),
  ('165640fd-99e3-4e1e-bd73-8df36e4ac1d6'),
  ('e31e6ebf-91ea-478f-b4dc-6974888bdffa'),
  ('22d959a5-ec5f-4b92-98d3-85dc219c2c61'),
  ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'),
  ('4b5055b4-2ed1-4894-acae-0e1465159564'),
  ('0f06ced9-84c7-4020-98fd-82ac25d49027'),
  ('822966a7-5f09-4151-ba43-630afbd676c2'),
  ('9a9874ab-159f-4ffb-b88e-f058df02d5fa'),
  ('60d485a8-17c9-4092-a666-b06c011d66e8'),
  ('ee1a8680-16cf-40ee-bbee-09670cb296cc'),
  ('5fe0fed0-05b0-49e4-b7e2-99d2c8463a0d'),
  ('bab3379b-d64e-423b-b62e-4efa04cee750'),
  ('bd630c8f-14da-4149-b95c-6da7eddaab8f'),
  ('2c3372a7-dadc-4622-944c-1783abe57b56'),
  ('a0cb697c-3158-4680-8e70-c154c3a15cc4'),
  ('07255876-bbe6-4f6a-8c68-75939d9b5128'),
  ('de6d7929-66dd-4166-998a-479cfa264ce5'),
  ('85eb733f-615f-4709-99ca-d524e793588d'),
  ('1f7429f7-1ecd-4f44-abce-03c72d5cf664'),
  ('0fd03798-714d-4976-a9b6-448aa22d8a68'),
  ('7e588ebb-d17c-43c6-9eef-558871b55330'),
  ('870437b0-1498-4def-835f-966ad989e9e1'),
  ('611c17c5-3c5f-4685-8c22-3b3fe75482ba'),
  ('5ccb1f15-f285-470c-b86a-97f9e6b22dff'),
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0'),
  ('eab7b830-c831-45f9-bca8-11b079f42680'),
  ('363fe07c-171e-4044-b6f9-979662962027'),
  ('5617115e-78d5-4480-9534-aa337612a285'),
  ('34ff9b7a-decc-4b21-8f6d-339957ab60bf'),
  ('c19c488e-ae48-4ed2-ba7c-3092b847c192'),
  ('b918fb31-108f-49e7-b977-627ce667422d'),
  ('8cc1c412-fe14-4bc6-b1e2-02d95997fd47'),
  ('32d35023-d9b4-4035-a73f-63433dbc9910'),
  ('b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6'),
  ('522d03a0-6fe8-4f48-b68a-cc4e12eba21b'),
  ('24109768-01ad-4bab-b833-b7bc1d8f437d'),
  ('98b05c70-2a30-48ea-81f3-b3216ffb0ca0'),
  ('6b817122-f196-4b72-b0b4-2d9763c4be47'),
  ('459c4ee8-d027-4215-ab8c-d28476cd9010'),
  ('ac7faadb-52c2-4e13-9073-3a607a4f8e57'),
  ('059dab9f-a79a-4664-b4cf-26b0655c596f'),
  ('370f9462-ed1d-4a83-b244-8bb593038444'),
  ('04f5d126-665b-49c8-9468-72d5b744d130'),
  ('8f5b07af-7932-49d4-9164-6277781a541e'),
  ('945d0b44-3329-46b2-a39e-47f5fdddc6ed'),
  ('a8017fcc-f4c0-4b7d-a0fa-9d76ea3d56f6'),
  ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c'),
  ('d2d9d65d-138a-4b40-a4de-88642f35ec15'),
  ('efad217f-13a7-449b-b484-cabda59ce14e'),
  ('134c2bfa-eb1f-4e67-beb6-505624707a2f'),
  ('db66036a-2a1f-4bcf-980e-2f29a336dc5f'),
  ('956281d7-e27e-43cc-84e9-244879ed5ecf'),
  ('4bbdb54e-664a-437e-9c2d-2c6939bf44c5'),
  ('ec0cfeae-a512-4ce2-a8f2-a25b00112b9b'),
  ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032'),
  ('5200d94b-cca2-4927-89bf-48c2c4f527fd'),
  ('352876f0-02b4-4eba-b979-c99079ab368a'),
  ('bec15428-f2c6-45a2-9bf0-ae91e6fabe70'),
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'),
  ('ba4f0f86-7159-4097-a6a6-ad45fbcf003c'),
  ('ee2ff8c8-d9b6-46a3-a13e-d97b9fdc8cab'),
  ('d886838f-6e64-43d7-ab84-5a8f300055df'),
  ('3d51cca6-7206-413b-ab8d-3199a58a6767'),
  ('403fb454-25fd-4c9f-9657-975715511b57'),
  ('74eb8c85-b789-4767-bdd1-206009b7cd11'),
  ('0bd82de2-6f06-4775-a716-cfa6568671ef'),
  ('0593d23d-88b2-4aa8-81e4-f974a7d9c793'),
  ('ec48f5a7-1efd-4942-8e13-65584102df0d'),
  ('1453d66e-9374-402b-8230-b89e0b5a3c49'),
  ('179a1762-3343-4dd6-aef2-f8c9e2442b4e'),
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'),
  ('3cc5cece-cec0-4490-8faa-37a6b66231c7'),
  ('a6d9db8e-b113-4638-b455-1a589ba2b920'),
  ('b71ec1b6-7d9e-406b-a30a-8c0710278d5e'),
  ('92bb2ff8-0967-41c3-a68a-efc7a072ead1'),
  ('6910a92c-af56-4676-804c-048e007e9b5b'),
  ('ad28f54e-0639-4005-ade9-3be3b90c3d39'),
  ('b5cc94df-2ba3-4057-8abd-5760383b286b'),
  ('d7ad5924-0e8a-4d11-93e3-56e1db5dd019'),
  ('e63791e7-3d09-4da1-a28c-b3e221491c15'),
  ('d2c740be-74fc-4ab6-bca7-af9d6e7c7463'),
  ('1507e55f-fdce-4c66-8629-327444850fe7'),
  ('bb7a224e-a0af-4bd8-a2a9-d70c35e1eefc'),
  ('f3f21e38-d8e6-41d2-9d74-0360a5f679b9'),
  ('90342c06-b82a-4e86-8d89-152ab07a4c66'),
  ('bf3d8a5d-f5a6-4bfa-b144-513898d12ed5'),
  ('fb5600ed-e81a-4e9d-b3e2-9d57237349ad'),
  ('6ca52345-ae36-4d19-8058-334f66076ee4'),
  ('18b11787-c861-4996-aba5-3b863ea33b1d'),
  ('5abdd7d2-32f2-455d-bfbb-95a75b0c7d3e'),
  ('2e737f21-8570-4ad2-8d68-9b0678ac2c3f'),
  ('b0686023-8930-43ad-af62-a4e9ebe5aef9'),
  ('f7303b7d-0e06-4037-b9a4-9c7d12f37d6e'),
  ('6f39ef78-1967-4a41-bc6f-f2ed372f10c3'),
  ('34a3fabb-809d-4d11-866d-d270b4922f7e'),
  ('dd08c9de-076d-40ee-ab27-9298bbb72d1a'),
  ('21f45688-4e19-42bb-b1c0-e17b5dba2d3a'),
  ('047962c6-216a-4ff6-b63e-04c900fb8af9'),
  ('b652c0bb-1dc5-4043-8a2e-9e12ea034dc8'),
  ('6794d63a-05d5-4bcc-99fc-f4f860529d16'),
  ('1f171f1f-14e4-47ef-b715-0d676e815568'),
  ('0199d6a7-271e-40b1-aad0-2cf262c7046b'),
  ('78c8864e-8ba1-40bf-b6ce-9f4b5b6df8c1'),
  ('5cdd28b7-f8be-4968-bc1a-0e7928786980'),
  ('b1ebe22c-a9f5-45c2-8ae0-3636e1e9be4c'),
  ('580f3720-7990-4a2b-a417-78d90012db93'),
  ('95c63dde-ea43-4ef5-9691-a61ed7233b30'),
  ('8e0122c2-8bcb-4114-87e6-faa72d5d5125'),
  ('0763fb1b-8704-42b6-a52f-5cfcbee46b49'),
  ('023c6644-356e-4afb-925b-e20f9c32209b'),
  ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5'),
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e'),
  ('99d93781-7c5f-492c-b959-ee502ca05c29'),
  ('04000e04-4103-4334-ac0e-6aefb23af1cf'),
  ('3f7ce0c5-7674-4b3b-87aa-61e0190b402c'),
  ('479e7920-d431-44b9-a048-8c3913c2498e'),
  ('66da3b64-3dab-4f79-950a-475acc006dc8'),
  ('0e4492df-b9b8-429c-8a1e-1ab909042d7d'),
  ('40373be4-5a51-48d7-8afc-e6be734653ce'),
  ('43d8dd56-6b83-4fb3-91c8-a6018de164ff'),
  ('54600569-46e8-4830-88c1-c86cabed4488'),
  ('90369b67-99c3-4e29-9f6c-8529350cf1eb'),
  ('811bd5cb-8c0f-41a5-b78b-18d76151b994'),
  ('3079710f-a2bc-4e9d-a72a-69ba41722966'),
  ('5d1feb93-3532-4e63-a175-5502fbcddae1'),
  ('8b0fe853-b289-40ad-95ba-dc1ea25e1c34'),
  ('496cc607-2296-4a7c-b2a0-0d56210805fd'),
  ('7ebe7923-3a6a-464e-9646-4e688459f614'),
  ('e099da71-f9d9-445d-96d9-179952bd539c'),
  ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'),
  ('185b5de5-50a4-4a5b-9cef-f64f0ab1cb4c'),
  ('b3737c12-af18-4419-b2f1-27ab6a599457'),
  ('a44d3934-0db6-4fe4-9ba1-316098279e38'),
  ('04a1f435-1a5c-42db-9efd-410e65652f40'),
  ('6465949e-7832-40cb-962f-839ebecf32ce'),
  ('c0a1a251-feb5-4ec7-bbbf-7cf7d3da31a6'),
  ('307081dc-33cc-4bd2-9343-06fa90d29f03'),
  ('453e9798-bbe1-45f3-9898-4cd13d91fc61'),
  ('26fa2e76-137e-4ace-b40a-fc49105c2a05'),
  ('0705d7cf-7e28-4543-9852-298bcafe4e66'),
  ('e9ed38b1-5e71-482f-96b8-331c63a3f083'),
  ('6e1fd819-cbf6-4f93-9917-220ad3294902'),
  ('203ab943-324d-4478-9093-d827d5d9c7da'),
  ('9f8eebbe-19e1-4986-9f5f-563887a94462'),
  ('aec413c6-2bb2-4997-a9d4-d066b8836d2f'),
  ('fbc9df01-ec6f-4e8c-b1fe-884425a34047'),
  ('8b1dca67-2cfa-456f-81b0-27cab1690388'),
  ('1e8bac4b-6d4d-4425-8628-bdfdddf46058'),
  ('ee8f52bc-ad53-4abf-b136-3898ead3e41b'),
  ('d3f89474-72f0-4a7a-a803-c32a865cec3a'),
  ('ace0b96d-8ef8-4aca-8928-6848ae430da6'),
  ('03a6f459-7163-4030-9fdb-bf1ef4a45ea0'),
  ('835e9c91-f373-4c9d-af75-6a5dd68539ec'),
  ('ebd1c39c-73cc-4346-a7f3-55a4274045a3'),
  ('1037ec72-4bfe-4d5c-87b8-4eb2fa7d998b'),
  ('0cf86dbe-b7be-4cf1-977b-97a98fc60fa9'),
  ('05582f3f-8963-4fdf-806a-da150bf3e966'),
  ('a793b036-460a-4752-961f-53d460f8130a'),
  ('a82316c1-dc9f-4ed7-9f3c-3866ed4ebe6f'),
  ('6b44e402-7ea5-4dad-b3dd-6066fab6c6f6'),
  ('36fad2d6-fdd9-4ac9-a85f-e5447f7f68cd'),
  ('4025a524-5e29-4c04-9026-009ba23878e5'),
  ('7a0017bb-cd74-43bb-9719-842aaa1bd383'),
  ('6ca03396-08d7-43ff-a101-f5a1aec11e3e'),
  ('5b45bee6-4cdd-4800-83db-66e4e5b74c1d'),
  ('8d45a199-5054-417f-b9a9-3874e113c5f4'),
  ('9664affa-96b6-461f-976e-6cdf077cbf11'),
  ('dc3d8a98-07ce-4797-bc84-957a72fd854f'),
  ('7937e94e-c1bc-4ff9-8e89-e906b559e996'),
  ('7e3b308c-05e2-4109-91c0-cae55bba4534'),
  ('24e1ccb6-7ac1-4d98-a35f-d73c347dd906'),
  ('a21435a5-d6d0-4053-a016-94ca5bade4cd'),
  ('022405cb-cab1-4ccb-867b-c5b5c56313da'),
  ('2640d53c-bcdc-4335-a4a8-04442babe033'),
  ('a5c70691-3834-48f8-aeca-79b95c131884'),
  ('d921e2be-d1e4-456a-915c-a4b3780dd633'),
  ('a2c6adc7-7689-49b9-964f-8f2aeb243a83'),
  ('0c1b5005-e1e5-4ba1-9e85-ce858371cd6e'),
  ('f1271c9d-fad4-4e1e-9c22-e6e2333a8a3e'),
  ('0bbbb18d-1f67-4bd1-89d6-505a175d063c'),
  ('09346353-22be-41e9-b382-59be94ebfa33'),
  ('6793f0eb-ddaa-4c72-ac99-70876295279a'),
  ('248c67f9-b8bf-4627-b358-a0f49b47abe7'),
  ('73f801b5-b71b-4f01-9043-9dc2638049ff'),
  ('e7f224d2-659a-41fd-887c-e2c714956bf8'),
  ('1e4353eb-d05f-4b84-994e-32e1f43295fa'),
  ('a54704f7-023d-4351-80b5-9cfb397dfcf6'),
  ('2d5859a0-18ba-42d2-b272-fb9acd9890a1'),
  ('6a008bbb-a2dd-4128-87cf-f2fe0278738b'),
  ('6ad1021e-5f98-4215-a879-a9b76a57b9e3'),
  ('a80b01d7-0c4c-49c0-9914-fd296b4fb134'),
  ('8a68b1f1-52d6-442d-ba75-77885f30de58'),
  ('21abfb53-adcd-4aaa-8f5b-37ef03af9d13'),
  ('86533db6-cfb8-49bf-a265-74a3b3845575'),
  ('eaab41f8-71c8-47db-bd0b-62da46b5607b'),
  ('792ad281-ed7c-418d-b0c5-9fcdd9e1b097'),
  ('8b493601-de91-44f8-8ce9-0b73ddf532f0'),
  ('b0a1af0e-0aeb-486d-85e6-9dff704aa870');

-- Remove the 334 unevidenced / dropped-barrel seatings (blank = absence of an answer row).
DELETE FROM inform.politician_answers a USING air_blank b
 WHERE a.politician_id=b.pid AND a.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';

-- Documented-blank contexts for the 334 blanked pairs (sources emptied).
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adam Dunigan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0ef9c1e3-8381-42e3-bafc-d7632119c37f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adam Murphy. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0aa1c59d-f8fe-4569-94ea-484599d49b73' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Addison P. McDowell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='74579547-1454-475e-ab35-12cf88a998b9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adonis Hooslyn. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='96eff205-63aa-4999-890c-c83bcad391dd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Al Lemmo. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='64783a11-a7ae-4ab7-a6d2-593ae06796f8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Alex Joers. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8e804443-d7ac-4103-943f-546a76c4c8bf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Alicia Rule. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0265efd8-29c9-46b4-b408-7da40b455257' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Anamarie Avila Farias. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='52d3e817-03bf-4dd5-8a16-67b44acf23ac' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Andy Kim. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e7c985f0-7804-485e-8ad7-8e71c0129a00' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Angus S. King, Jr.. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4f4b2bff-0054-475f-8687-e83f68085f15' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Annie Andrews. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='238222f5-e5e0-4331-8540-ee904bbacb8a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — April McClain Delaney. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='da087947-83af-4ca2-91c8-1f9e0bf887a9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ashtyn Kennedy. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='066de417-a463-4574-8cee-c2eac3700d8b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Avelino Valencia. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a1467b58-9cc8-4611-a03e-07defc1679bf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ben Ray Luján. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='27d57833-842f-427c-bedd-aa1695fe550f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Blake Gendebien. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f3e749b6-24f5-47b4-8f31-94bc23421b86' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Bob Harvie. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e9e79f56-f4c8-4694-b161-2858722dcbc0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brad Sherman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='96c77e2b-df35-4d56-a573-8bc0c15a142d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brent Blackaby. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='424eb63b-9976-4059-8049-365c09719cc6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brent Hennrich. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='48b16473-9fcb-4957-a836-8de0b8609946' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brian Schatz. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='100de02f-b44d-4587-9b90-19aa5081708c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brianna Thomas. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c88a915a-6613-4940-a12d-18a28b00935c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Caitlin Rourk. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e6788516-795b-4963-8762-4d1cd617ac35' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cameron D. Reny. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ceace463-1299-4c49-b5aa-e73af2534e0a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Candice B. Pierucci. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='99198363-2ac9-4b56-9d80-7abfe7b2a01a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Carleigh Beriont. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1d2d647a-16e0-4d17-af5b-acd83762c359' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Carol Alvarado. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6ed2b57e-4930-4099-8567-d5a6bf7b999f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Carolyn Eslick. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e1538de2-4e22-44cc-a50f-02fe7e2e9f2e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Catherine Cortez Masto. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='91f87a53-13bc-4d35-b3c8-49227ae80faa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — César Blanco. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='32608fd7-5038-4474-bfa9-7392b5e0eb80' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chipalo Street. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chris Stearns. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chris Van Hollen. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='61a601c2-7faa-4889-abf2-bbb0066ce448' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Christina Bertrand Hines. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ea85c891-d6c0-4d45-a92c-f565794b1729' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chuck Grassley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='dd5d3f6d-fc82-4774-b510-287ec47cbd84' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chuck Schumer. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='af01a7ec-9318-4862-ba78-553e5908182c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cindy Ryu. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='86e6a2bf-5216-4022-900c-621a8480f2e7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Clarence K. Lam. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fc23b939-0dfd-4968-ab19-fc1e7745e997' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Clyde Shavers. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='721bf21e-7913-431b-9807-037561f18b82' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cory Booker. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='872f60a5-7ded-473b-87a8-a904d6ca4d6e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cottie Petrie-Norris. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='065c6e87-8778-43ee-ab44-b9982a677aa7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dade Phelan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9974fbb8-10d1-452c-ae8e-a853dd3f7d37' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Damon Anderson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='216790b9-1ee5-4198-b6ca-e8650017bf59' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dan Schwartz. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='70226cbc-2707-4962-835e-175a2864d3d4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Danielle Sterbinsky. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c0373c9a-54ed-406e-9ff6-400a43dae429' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dave Paul. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='78726dd6-5ce2-40d4-9cf6-10fc6a840756' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dave Sunday. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c1a8e812-2851-4c1b-b5c5-cf2997ee2ed2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — David Alan Bradstock. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='cc79161f-2a1b-491f-9c4f-b0cf161196a8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — David Brock Smith. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ae7e8d67-e8a4-49a7-bb5c-715c99168374' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — David Chiu. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='86c12b33-cb76-41da-bdf0-6b58a0cbbed6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Davina Duerr. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Debbie Dingell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='91d28127-8183-4b67-a1fb-dc8a150f6199' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Deidre M. Henderson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f72689da-fe02-4bdd-977f-bb7760a42fb2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Denise Powell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='85fdd516-d5cc-48d8-8fec-e425d90f03db' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dennis Paul. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a80b2deb-e005-4115-b5c0-2a050fa6a1ec' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Derek Brown. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1844a5e3-8ea5-4ee5-9377-066378b25b49' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Don Tracy. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a6f10769-ec53-456f-afbd-2a89d3ac84b2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Doug Fiefia. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='01eac4cc-d6f2-4b33-ab5f-c3d4d2b93dc0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dustin Burrows. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='30063951-196d-4eea-a8da-4ac1702bd867' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Emily Buss. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='70b5e5a8-2ae4-454e-b75e-adb200b7b91d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Eric Chung. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e2751db9-30ac-41fc-9db3-5dab859f0126' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Francisco E. Paulino. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='77ceaab2-846e-4bc8-b09d-faff40ddbc60' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Frank Pallone, Jr.. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='332de859-029c-43ff-baa7-0113ad436d0f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Gavin Newsom. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f26309c8-2525-49b2-bdaf-62980cbb1853' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — George Austin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e091da26-dbcf-4d12-87c3-4e2e023d00a1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Gerry Pollet. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Gretchen Whitmer. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a4a239ad-98ab-4fa9-9d56-7781f46821a4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Hannah Pingree. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ac09c6dc-d7db-4bdb-9829-0e746c8ca665' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Heather Smiley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3bc348ae-0363-4dca-b235-30bc5c073fad' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jack Reed. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='afd8d31b-9f88-4eb9-8a88-46e5ef914267' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jackie Fielder. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='02f88a57-ccf5-4fe1-a693-7fc949321fb1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jamee Decio. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3f6ef889-ca07-4cd9-bbb5-300667099d92' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — James Uthmeier. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2e0915c5-45d7-48de-ae59-04bcd6bda1f7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Janice Zahn. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a961a076-f7be-436f-881f-155a0e9e687c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jason Hart. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f2d4231d-ac81-4e9c-82df-b8548f357142' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jason Pearce. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e987cfff-23ae-4b24-a64d-4cde8582f520' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jay J Bowman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b1baf884-5fd5-4618-b380-f2790fa47ee5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jeanne Shaheen. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1d877e4d-8aaf-4db8-be5b-2a3de0a98783' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jeff Merkley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0eabc969-c1a1-47b7-8d34-6113b723a170' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jeromie Whalen. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4b7fb0a4-5d8c-49a1-8266-74a73421bf6e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jerrad Christian. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='03ed0d1f-e210-464b-8bf4-8f7dffae90d0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jimmy Skovgard. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a74e04c6-46c8-4fdf-b08c-8930c1bb1ffa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John Croisant. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d36fc2e8-f76a-4f52-bc82-1ea16dacfd83' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John D. Johnson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d8daeb9d-2437-4864-9efd-6031291fed86' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John Hickenlooper. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2a6693c7-9149-4e71-85fe-003746f7d23d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John Hoeven. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e6596b34-8d9f-4593-bf0c-4fe7fc17cd26' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John Sununu. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ffb0dcac-385a-4df3-a441-cdbd0e713c1d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jon Ossoff. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6160a29a-d896-4061-801a-e5c3d9f06c99' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jonathan Treble. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b25b77e1-f502-418a-974d-c084801b53d3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Joseph Perez-Caputo. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='68254709-e00d-4d3c-9d10-b3daac0c2f37' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Josh Becker. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='64eda290-d172-48de-8827-6ebca668cf5a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Josh Hawley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='108e7bcc-554a-49d7-81f0-c3058f933a07' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Josh Thomas. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c566a41d-28e7-45cb-9eea-c9501878f2a7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Judith Zaffirini. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Julia Reed. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Julio Cortes. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Karen Ruth Bass. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='21c9e711-fb18-4afb-884f-08acd2b598ba' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Katie Britt. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0ba1cecc-8493-495b-8d58-34d50bbacfba' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Katy Hall. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kay Ivey. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fd26d6ce-979e-4485-9e35-7d4c179c3c4c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Keil Roark. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='283b1fdd-3d89-4f82-a065-098324f2f967' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kelly Thompson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e976e2c2-52c1-48c9-a5a6-4337d6740f71' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kent Udell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a7e29796-a928-49cc-b795-973a4f69fafe' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kirsten Gillibrand. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='463f8a89-e12c-4b92-8df1-0fed43dc4441' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kristine Reeves. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kyle Blomquist. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c4c71706-e2fb-42ac-be4b-0e913d83e06a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lateefah Simon. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='39db6eee-ccf5-4901-90a0-1c2580731b0e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Letitia James. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='406dd9be-a751-4685-a946-44806bd01548' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Linda T. Sanchez. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bb73793e-ad67-431a-bb03-663b765204d8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lindsey P. Horvath. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='81dfcf88-c739-4461-9d16-931f8d51a8c5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lisa Blunt Rochester. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f9abc9e1-e1d5-4cd9-9983-a403dc94a5fc' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lisa Callan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lisa Murkowski. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='cc873a93-cb47-405a-93b0-bb2848fdd57e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lisa Parshley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Liz Berry. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lori Trahan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b96758c6-2ea0-4698-8886-d574d34e366d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Luke Bronin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c924abea-3bdf-49af-98cc-7d117cb54ad1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Luz Maria Rivas. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a1fc524b-7c90-43c0-83a7-c76664293913' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mari Leavitt. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7b992556-5e0d-488a-92f7-942ab56660c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark DeSaulnier. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bc29096f-63ce-41f7-8d51-c4e6cfa87f8c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark Kelly. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7e1e1044-a98b-4c69-910e-73de8e818c48' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark Nair. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6a2d6591-432c-48cc-920a-085a51a01d74' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark Warner. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='85d27350-e1b6-45b8-aee3-509ca88c5af4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Marni von Wilpert. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c3f1fad4-46cd-4f2f-8723-d7a3f99dca65' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Martin Heinrich. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4fa06009-8f67-40f6-a8b3-d2d62712240d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mary Fosse. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Matt Pierce. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='72dd5219-490f-48bb-986e-183a6098d602' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Matthew "Bronco" Williams. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='387d0557-3a5d-42f0-861b-6de2e5ea8af7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mazie Hirono. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='dc92c805-4734-4d4b-8ceb-597e59b0e268' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mel Tull. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fc52e8ba-c234-42cd-b2a2-5abddaa9c3b1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Melissa Bean. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='60f2dcfe-1669-4dee-9c32-a285f4756569' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mia Gregerson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michael Bennet. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='535591bf-7151-48ba-81b4-e8d9983def72' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michael Bridgford. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='21b282b2-24bf-49b2-b0b7-109eb98083f8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mike DeWine. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9739fb00-209f-4ed0-ad06-b9d97d74ced1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — My-Linh Thai. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Natasha Hill. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Nick Schultz. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e31e6ebf-91ea-478f-b4dc-6974888bdffa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Nicole Macri. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Norma Torres. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e4d5cd69-0a54-48d6-9d8c-11da8f091cb6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Osman Salahuddin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Patty Murray. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0f06ced9-84c7-4020-98fd-82ac25d49027' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Pete Aguilar. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='822966a7-5f09-4151-ba43-630afbd676c2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Peter Welch. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9a9874ab-159f-4ffb-b88e-f058df02d5fa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Rachel Fetty Anderson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='60d485a8-17c9-4092-a666-b06c011d66e8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Raja Krishnamoorthi. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ee1a8680-16cf-40ee-bbee-09670cb296cc' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Raphael Warnock. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5fe0fed0-05b0-49e4-b7e2-99d2c8463a0d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ricardo Lara. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bab3379b-d64e-423b-b62e-4efa04cee750' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Richard Blumenthal. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bd630c8f-14da-4149-b95c-6da7eddaab8f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Richard Durbin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2c3372a7-dadc-4622-944c-1783abe57b56' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Richard Neal. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a0cb697c-3158-4680-8e70-c154c3a15cc4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ro Khanna. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='07255876-bbe6-4f6a-8c68-75939d9b5128' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Roger Goodman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Rosalba Dominguez. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='85eb733f-615f-4709-99ca-d524e793588d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Roy Cooper. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1f7429f7-1ecd-4f44-abce-03c72d5cf664' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ruben Gallego. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0fd03798-714d-4976-a9b6-448aa22d8a68' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sabrina Cervantes. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7e588ebb-d17c-43c6-9eef-558871b55330' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sarah Zabel. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='870437b0-1498-4def-835f-966ad989e9e1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sasha Renée Pérez. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='611c17c5-3c5f-4685-8c22-3b3fe75482ba' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Seth Moulton. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5ccb1f15-f285-470c-b86a-97f9e6b22dff' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Seth Moulton. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='77f162cd-6ca0-4073-84e1-1c8ab87eb1e0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shamann Walton. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='eab7b830-c831-45f9-bca8-11b079f42680' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sharlett Mena. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sharon Wylie. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shaun Scott. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sheldon Whitehouse. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c19c488e-ae48-4ed2-ba7c-3092b847c192' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shelley Kloba. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shoshana O'Keefe. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8cc1c412-fe14-4bc6-b1e2-02d95997fd47' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shri Thanedar. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='32d35023-d9b4-4035-a73f-63433dbc9910' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Spencer J. Cox. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Stella G. Pekarsky. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='522d03a0-6fe8-4f48-b68a-cc4e12eba21b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Steve Daines. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='24109768-01ad-4bab-b833-b7bc1d8f437d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Suhas Subramanyam. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='98b05c70-2a30-48ea-81f3-b3216ffb0ca0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Susan M. Collins. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6b817122-f196-4b72-b0b4-2d9763c4be47' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Suzie Byrd. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='459c4ee8-d027-4215-ab8c-d28476cd9010' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tammy Baldwin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ac7faadb-52c2-4e13-9073-3a607a4f8e57' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tammy Duckworth. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='059dab9f-a79a-4664-b4cf-26b0655c596f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tarra Simmons. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Taylor Burks. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='04f5d126-665b-49c8-9468-72d5b744d130' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Thomas DiNapoli. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8f5b07af-7932-49d4-9164-6277781a541e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Timm Ormsby. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on co-sponsorship of Washington HB 2225, an AI companion-chatbot notification-and-safeguard mandate with a consumer-protection penalty. v2 chair 3 covers only holding developers legally responsible when their systems cause harm; a disclosure-and-safeguard mandate is not liability for harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tina Smith. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a targeted AI use-restriction. The v2 ladder no longer offers a use-ban position and v2 chair 3 covers only legal liability for harm, which no instrument on record establishes. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a8017fcc-f4c0-4b7d-a0fa-9d76ea3d56f6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tony Cardenas. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tracy Miller. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d2d9d65d-138a-4b40-a4de-88642f35ec15' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Vanessa Enoch. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='efad217f-13a7-449b-b484-cabda59ce14e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — William Tong. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='134c2bfa-eb1f-4e67-beb6-505624707a2f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Zach Wahls. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of holding developers legally responsible when their systems cause harm. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='db66036a-2a1f-4bcf-980e-2f29a336dc5f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Zoe Lofgren. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-3 seat rested on a disclosure or transparency measure. The v2 rework dropped the disclosure barrel; v2 chair 3 now covers only holding developers legally responsible when their systems cause harm, and no liability-for-harm instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='956281d7-e27e-43cc-84e9-244879ed5ecf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Abden Simmons. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4bbdb54e-664a-437e-9c2d-2c6939bf44c5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Abdul El-Sayed. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ec0cfeae-a512-4ce2-a8f2-a25b00112b9b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adam B. Schiff. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adam Lee. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5200d94b-cca2-4927-89bf-48c2c4f527fd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adrian Fontes. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='352876f0-02b4-4eba-b979-c99079ab368a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Aisha Wahab. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bec15428-f2c6-45a2-9bf0-ae91e6fabe70' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Alex Padilla. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Allison Hepler. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ba4f0f86-7159-4097-a6a6-ad45fbcf003c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Amanda Collamore. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ee2ff8c8-d9b6-46a3-a13e-d97b9fdc8cab' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Amy Arata. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d886838f-6e64-43d7-ab84-5a8f300055df' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Amy Klobuchar. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3d51cca6-7206-413b-ab8d-3199a58a6767' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Amy Kuhn. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='403fb454-25fd-4c9f-9657-975715511b57' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Amy Roeder. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='74eb8c85-b789-4767-bdd1-206009b7cd11' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ann Matlack. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0bd82de2-6f06-4775-a716-cfa6568671ef' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Anne Graham. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0593d23d-88b2-4aa8-81e4-f974a7d9c793' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Anne-Marie Mastraccio. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ec48f5a7-1efd-4942-8e13-65584102df0d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Arthur Bell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1453d66e-9374-402b-8230-b89e0b5a3c49' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Aswar Rahman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='179a1762-3343-4dd6-aef2-f8c9e2442b4e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ayanna Pressley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c61baf45-dc2a-4d78-b4b7-21b1e9d79464' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Bernie Sanders. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3cc5cece-cec0-4490-8faa-37a6b66231c7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Braeden Curwick. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a6d9db8e-b113-4638-b455-1a589ba2b920' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Brent Bowles. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b71ec1b6-7d9e-406b-a30a-8c0710278d5e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Caldwell Jackson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='92bb2ff8-0967-41c3-a68a-efc7a072ead1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Callie Barr. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6910a92c-af56-4676-804c-048e007e9b5b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cassie Julia. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ad28f54e-0639-4005-ade9-3be3b90c3d39' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Charles Booker. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b5cc94df-2ba3-4057-8abd-5760383b286b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Charles Skold. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d7ad5924-0e8a-4d11-93e3-56e1db5dd019' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Chelsey Hockett. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e63791e7-3d09-4da1-a28c-b3e221491c15' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cheryl Golek. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d2c740be-74fc-4ab6-bca7-af9d6e7c7463' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Christina Mitchell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1507e55f-fdce-4c66-8629-327444850fe7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Christopher Kessler. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bb7a224e-a0af-4bd8-a2a9-d70c35e1eefc' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Connie Chan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f3f21e38-d8e6-41d2-9d74-0360a5f679b9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Cynthia Wirth. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='90342c06-b82a-4e86-8d89-152ab07a4c66' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — D. Michael Ray. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='bf3d8a5d-f5a6-4bfa-b144-513898d12ed5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Daniel Ankeles. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fb5600ed-e81a-4e9d-b3e2-9d57237349ad' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Daniel McCay. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6ca52345-ae36-4d19-8058-334f66076ee4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Daniel Sayre. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='18b11787-c861-4996-aba5-3b863ea33b1d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — David Rollins. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5abdd7d2-32f2-455d-bfbb-95a75b0c7d3e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Deqa Dhalac. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2e737f21-8570-4ad2-8d68-9b0678ac2c3f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Douglas Crockett. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b0686023-8930-43ad-af62-a4e9ebe5aef9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Drew Gattine. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f7303b7d-0e06-4037-b9a4-9c7d12f37d6e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Dylan Pugh. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6f39ef78-1967-4a41-bc6f-f2ed372f10c3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Eleanor Sato. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='34a3fabb-809d-4d11-866d-d270b4922f7e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Elizabeth Warren. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='dd08c9de-076d-40ee-ab27-9298bbb72d1a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Flavia DeBrito. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='21f45688-4e19-42bb-b1c0-e17b5dba2d3a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Gary Friedmann. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='047962c6-216a-4ff6-b63e-04c900fb8af9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Giovanni Capriglione. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b652c0bb-1dc5-4043-8a2e-9e12ea034dc8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Grayson Lookner. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6794d63a-05d5-4bcc-99fc-f4f860529d16' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Holly Eaton. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1f171f1f-14e4-47ef-b715-0d676e815568' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Holly Sargent. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0199d6a7-271e-40b1-aad0-2cf262c7046b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Holly Stover. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='78c8864e-8ba1-40bf-b6ce-9f4b5b6df8c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Isaac G. Bryan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5cdd28b7-f8be-4968-bc1a-0e7928786980' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — James Sceniak. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b1ebe22c-a9f5-45c2-8ae0-3636e1e9be4c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jamie Joyce. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='580f3720-7990-4a2b-a417-78d90012db93' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Janice Dodge. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='95c63dde-ea43-4ef5-9691-a61ed7233b30' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jeff Jackson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8e0122c2-8bcb-4114-87e6-faa72d5d5125' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jillian Gilchrest. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0763fb1b-8704-42b6-a52f-5cfcbee46b49' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jim Banks. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='023c6644-356e-4afb-925b-e20f9c32209b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jim McGovern. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ee4081d5-fc3e-4a8c-b39e-481ae20135d5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jim Rosapepe. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9c400214-f007-4a8d-92fe-5f5d23b3838e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jimmy Gomez. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='99d93781-7c5f-492c-b959-ee502ca05c29' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Joel Anabilah-Azumah. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='04000e04-4103-4334-ac0e-6aefb23af1cf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John "Drew" Williams. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3f7ce0c5-7674-4b3b-87aa-61e0190b402c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — John Paul Torres. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='479e7920-d431-44b9-a048-8c3913c2498e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Jonathan L. Jackson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='66da3b64-3dab-4f79-950a-475acc006dc8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Julia McCabe. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0e4492df-b9b8-429c-8a1e-1ab909042d7d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Juliana Stratton. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='40373be4-5a51-48d7-8afc-e6be734653ce' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Justin Early. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='43d8dd56-6b83-4fb3-91c8-a6018de164ff' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Karen Montell. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='54600569-46e8-4830-88c1-c86cabed4488' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kathy Hochul. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='90369b67-99c3-4e29-9f6c-8529350cf1eb' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kathy Jennings. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='811bd5cb-8c0f-41a5-b78b-18d76151b994' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kelda Roys. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='3079710f-a2bc-4e9d-a72a-69ba41722966' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kelly Murphy. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5d1feb93-3532-4e63-a175-5502fbcddae1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kilton Webb. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8b0fe853-b289-40ad-95ba-dc1ea25e1c34' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kimberly Pomerleau. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='496cc607-2296-4a7c-b2a0-0d56210805fd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Kristi Mathieson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7ebe7923-3a6a-464e-9646-4e688459f614' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Laura Friedman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e099da71-f9d9-445d-96d9-179952bd539c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lindsay Sabadosa. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='853f0b26-a2b5-48b6-8dd6-f40ca48c87fd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lori Gramlich. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='185b5de5-50a4-4a5b-9cef-f64f0ab1cb4c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lydia Crafts. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b3737c12-af18-4419-b2f1-27ab6a599457' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Lynn Copeland. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a44d3934-0db6-4fe4-9ba1-316098279e38' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mana Abdi. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='04a1f435-1a5c-42db-9efd-410e65652f40' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Marc Malon. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6465949e-7832-40cb-962f-839ebecf32ce' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark Blier. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='c0a1a251-feb5-4ec7-bbbf-7cf7d3da31a6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mark Cooper. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='307081dc-33cc-4bd2-9343-06fa90d29f03' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Marshall Archer. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='453e9798-bbe1-45f3-9898-4cd13d91fc61' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Marygrace Cimino. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='26fa2e76-137e-4ace-b40a-fc49105c2a05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Matt Moonen. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0705d7cf-7e28-4543-9852-298bcafe4e66' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Matthew Arndt. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e9ed38b1-5e71-482f-96b8-331c63a3f083' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Matthew Beck. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6e1fd819-cbf6-4f93-9917-220ad3294902' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Maxine Waters. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='203ab943-324d-4478-9093-d827d5d9c7da' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Melanie Sachs. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9f8eebbe-19e1-4986-9f5f-563887a94462' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Micah Lasher. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='aec413c6-2bb2-4997-a9d4-d066b8836d2f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michael Brennan. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='fbc9df01-ec6f-4e8c-b1fe-884425a34047' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michael Lemelin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8b1dca67-2cfa-456f-81b0-27cab1690388' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michel Lajoie. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1e8bac4b-6d4d-4425-8628-bdfdddf46058' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michele Meyer. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ee8f52bc-ad53-4abf-b136-3898ead3e41b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Michelle Boyer. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d3f89474-72f0-4a7a-a803-c32a865cec3a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mike Rogers. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ace0b96d-8ef8-4aca-8928-6848ae430da6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Mikel Wein. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='03a6f459-7163-4030-9fdb-bf1ef4a45ea0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Morgan Rielly. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='835e9c91-f373-4c9d-af75-6a5dd68539ec' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Nathan Carlow. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='ebd1c39c-73cc-4346-a7f3-55a4274045a3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Nina Milliken. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1037ec72-4bfe-4d5c-87b8-4eb2fa7d998b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Parnell Terry. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0cf86dbe-b7be-4cf1-977b-97a98fc60fa9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Patrick Mosolf. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='05582f3f-8963-4fdf-806a-da150bf3e966' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Paul Flynn. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a793b036-460a-4752-961f-53d460f8130a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Poppy Arford. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a82316c1-dc9f-4ed7-9f3c-3866ed4ebe6f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Rachel Fetty Anderson. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6b44e402-7ea5-4dad-b3dd-6066fab6c6f6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Randy Villegas. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='36fad2d6-fdd9-4ac9-a85f-e5447f7f68cd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Robert Foley. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='4025a524-5e29-4c04-9026-009ba23878e5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Robert Nutting. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7a0017bb-cd74-43bb-9719-842aaa1bd383' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Russell White. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6ca03396-08d7-43ff-a101-f5a1aec11e3e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ryan Fecteau. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='5b45bee6-4cdd-4800-83db-66e4e5b74c1d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Samuel Zager. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8d45a199-5054-417f-b9a9-3874e113c5f4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Scott Harriman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='9664affa-96b6-461f-976e-6cdf077cbf11' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sean Elo-Rivera. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='dc3d8a98-07ce-4797-bc84-957a72fd854f' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Shannon W. Bray. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7937e94e-c1bc-4ff9-8e89-e906b559e996' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sharon Frost. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='7e3b308c-05e2-4109-91c0-cae55bba4534' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sophia Warren. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='24e1ccb6-7ac1-4d98-a35f-d73c347dd906' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Stefany Shaheen. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a21435a5-d6d0-4053-a016-94ca5bade4cd' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Stephan Bunker. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='022405cb-cab1-4ccb-867b-c5b5c56313da' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Stephen Wood. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2640d53c-bcdc-4335-a4a8-04442babe033' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Steven Bishop. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a5c70691-3834-48f8-aeca-79b95c131884' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Suzanne Salisbury. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='d921e2be-d1e4-456a-915c-a4b3780dd633' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sydney Kamlager-Dove. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a2c6adc7-7689-49b9-964f-8f2aeb243a83' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tavis Hasenfus. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0c1b5005-e1e5-4ba1-9e85-ce858371cd6e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Thom Tillis. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='f1271c9d-fad4-4e1e-9c22-e6e2333a8a3e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tiffany Roberts. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='0bbbb18d-1f67-4bd1-89d6-505a175d063c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Tim Cywinski. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on a targeted AI use-ban or restriction, not safety testing. v2 chair 4 covers only pre-deployment safety testing, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='09346353-22be-41e9-b382-59be94ebfa33' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Traci Gere. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6793f0eb-ddaa-4c72-ac99-70876295279a' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Valerie P. Foushee. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on no chair-specific instrument — only a general or direction-only statement about regulating AI. Under the v2 wording this does not evidence the specific position of requiring safety testing before AI is used in high-stakes areas. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='248c67f9-b8bf-4627-b358-a0f49b47abe7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Valli Geiger. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='73f801b5-b71b-4f01-9043-9dc2638049ff' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Victoria Doudera. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='e7f224d2-659a-41fd-887c-e2c714956bf8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — W. Edward Crockett. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='1e4353eb-d05f-4b84-994e-32e1f43295fa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Walter Runte. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a54704f7-023d-4351-80b5-9cfb397dfcf6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Wayne Farrin. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='2d5859a0-18ba-42d2-b272-fb9acd9890a1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Wayne Parry. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6a008bbb-a2dd-4128-87cf-f2fe0278738b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — William Bridgeo. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='6ad1021e-5f98-4215-a879-a9b76a57b9e3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — William Pluecker. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='a80b01d7-0c4c-49c0-9914-fd296b4fb134' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Yusuf Yusuf. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-4 seat rested on the vote for Maine LD 2162, a targeted restriction on minors' access to AI companion chatbots. v2 chair 4 covers only pre-deployment safety testing in high-stakes areas, and the v2 ladder no longer offers a position for banning a high-risk use; no safety-testing instrument is on record. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8a68b1f1-52d6-442d-ba75-77885f30de58' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Adam D. Austill. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on a general call for 'firm restrictions on every aspect of AI', with no government pre-approval mechanism. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='21abfb53-adcd-4aaa-8f5b-37ef03af9d13' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Alexandria Ocasio-Cortez. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on the AI Data Center Moratorium Act, a targeted construction moratorium. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='86533db6-cfb8-49bf-a265-74a3b3845575' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Ben Bartlett. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on a municipal ban of AI rent-pricing algorithms, a targeted use-ban. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='eaab41f8-71c8-47db-bd0b-62da46b5607b' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Hunter Gordon. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on a general call for strict AI regulation and punishing executives, with no government pre-approval mechanism. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='792ad281-ed7c-418d-b0c5-9fcdd9e1b097' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Moshe Landman. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on a general call to tightly regulate new robotics, with no government pre-approval mechanism. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='8b493601-de91-44f8-8ce9-0b73ddf532f0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(), sources='{}'::text[],
  reasoning=$r$Researched 2026-09-01 — Sam Forstag. Re-audit of the ai-regulation ("AI Oversight") ladder against the approved v2 (Season 2) wording: the prior chair-5 seat rested on a general call for strict federal oversight of existential-risk AI, not a universal pre-approval regime. v2 chair 5 covers only a universal government pre-approval regime for every AI system, and the v2 ladder no longer offers a position for banning a specific AI system. Left blank rather than assert an unevidenced chair.$r$
 WHERE politician_id='b0a1af0e-0aeb-486d-85e6-9dff704aa870' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';

-- Move 3 -> 4 (evidence is pre-deployment safety testing / impact assessment = chair 4 under v2).
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Abigail Spanberger
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Spanberger co-sponsored the AI Accountability Act (H.R. 4278, 2023) in the House, which required federal agencies to publish AI impact assessments and transparency reports. She also supported the DEEPFAKES Accountability Act to require disclosure of synthetic media. Her overall posture favors proactive regulatory guardrails on AI while allowing continued innovation. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='46c6ebb0-137a-46aa-b6fa-17af31aa4ef1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='e5470008-3c0d-4970-a485-053621d8f0a6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Akilah Weber Pierson
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Weber Pierson authored SB-503 (2025) requiring developers of AI systems used in healthcare clinical decision-making to conduct annual independent audits, submit compliance reports to the state Department of Public Health starting 2027, and publish audit summaries publicly. AB-1791 (2023) required social media platforms to preserve and disclose digital content provenance data to ensure content authenticity. This pattern reflects mandating basic safety testing and auditing before AI systems are deployed in sensitive domains, consistent with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='e5470008-3c0d-4970-a485-053621d8f0a6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='29e15a5d-d98f-4536-ad62-05b2612f30ca' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Bob Archuleta
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Archuleta voted Aye on SB 1047 (2024) the Safe and Secure Innovation for Frontier Artificial Intelligence Models Act which passed the Senate 30-9 and would have required basic safety testing before deploying frontier AI models. He serves on the Energy Utilities and Communications Committee giving him jurisdiction over AI energy infrastructure. Voting record supports requiring basic safety testing before AI deployment consistent with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='29e15a5d-d98f-4536-ad62-05b2612f30ca' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='5821d0a9-672e-44c0-bac7-1a802a2e8368' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Buffy Wicks
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on SB-1047 (AI safety bill 2024) and authored AB-3211 (digital content provenance standards 2024) and AB-853 (CA AI Transparency Act 2025 signed) requiring basic safety testing and disclosure before AI systems are released without imposing heavy regulatory bans. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='5821d0a9-672e-44c0-bac7-1a802a2e8368' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='fad61dc3-a3ad-4056-b2f2-1f5d32fb886d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Catherine S. Blakespear
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Blakespear voted Aye on SB 1047 (2024, AI safety requiring large model testing), SB 53 (2025, AI safety framework, passed 37-0), SB 813 (2026, AI oversight regulation), and AB 2013 (2024, AI training data transparency). Her votes support requiring basic safety testing before AI companies release new systems, without authoring expansive government-approval mandates. This pattern aligns with value 3 â basic safety testing required before public deployment. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='fad61dc3-a3ad-4056-b2f2-1f5d32fb886d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='1ee95c1d-6127-494b-9f68-e8b3c975adee' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Christopher M. Ward
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on SB-1047 (AI safety for frontier models, Assembly floor 8/28/24, 48-16) and is listed as coauthor of AB-1018 (Automated Decisions Safety Act, 2025-26), requiring safety evaluations and disclosures before AI systems affecting employment/housing/criminal justice are deployed. Supports requiring basic safety testing before release -- aligns with stance 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='1ee95c1d-6127-494b-9f68-e8b3c975adee' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='d1a320a9-39e9-4152-85a0-11cab602fdc9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Danny Sauter
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Sauter supported Senator Scott Wiener's SB 1047 AI safety bill in 2024, stating it would place 'reasonable safeguards' alongside new technology development. This reflects a moderate pro-regulation stance — supportive of basic safety testing and oversight frameworks but not opposed to AI development. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='d1a320a9-39e9-4152-85a0-11cab602fdc9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='e0dc83f8-f72d-4869-8d79-532002408028' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Dave Cortese
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Cortese voted Aye on SB-1047 (2024, AI safety testing requirements before deployment) and Aye on SB-53 (2024, AI safety incident reporting). He has not authored AI-specific bills, placing him in the mainstream California position of requiring basic safety testing before companies release new AI systems, consistent with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='e0dc83f8-f72d-4869-8d79-532002408028' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='fb44c938-26fd-40ca-9333-e842693a1ad4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Diane Papan
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted AYE on SB-1047 (AI safety 2024) and AB-1018 (automated decision systems accountability 2025) -- supports basic safety testing requirements before AI deployment without heavy government approval mandates. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='fb44c938-26fd-40ca-9333-e842693a1ad4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='9a927fae-60bf-41f9-8ec0-433cc98997fa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Dr. Darshana R. Patel
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted AYE on AB 1018 (automated decision systems safety requirements, 6/2/25) and AYE on AB 853 (AI Transparency Act requiring provenance disclosure for AI-generated content, 9/12/25). Supports requiring basic safety testing and transparency before AI deployment but has not sponsored heavier regulatory bills. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='9a927fae-60bf-41f9-8ec0-433cc98997fa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='9edab965-ac61-4227-a8d6-601c07821f53' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Dr. Joaquin Arambula
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted Aye on SB-1047 (AI safety regulation Assembly floor 8/28/24) requiring safety testing before deployment of frontier AI models. Voted Aye on AB-1018 (automated decision systems Assembly floor 6/2/25). Supports requiring basic safety testing and government oversight before AI systems are released to the public. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='9edab965-ac61-4227-a8d6-601c07821f53' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Dr. LaShae Sharp-Collins
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted AYE on AB 1018 (automated decision systems regulation, 6/2/25 Assembly floor, 50-16) and AYE on AB 853 (California AI Transparency Act, 9/12/25, 60-4). Supports requiring basic safety testing and transparency for AI systems before deployment without seeking outright bans. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='2326fe1b-923d-4e2f-9598-0c8a23528df8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Esmeralda Z. Soria
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted AYE on SB 1047 (AI safety bill 8/28/24) but NVR on AB 1018 (automated decision systems 6/2/25). The SB 1047 AYE indicates support for basic safety testing requirements before AI deployment, consistent with stance 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='2326fe1b-923d-4e2f-9598-0c8a23528df8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='190c3584-0826-4a5f-a2ad-104ff70ff259' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Gail Pellerin
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted AYE on SB-1047 (8/28/24) and AYE on AB-1018 automated decision systems (6/2/25), supporting government safety testing requirements before AI systems are released to the public. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='190c3584-0826-4a5f-a2ad-104ff70ff259' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='e31c865b-e378-4c02-b6d5-3f3fc1393791' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- James Talarico
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$His AI/tech platform calls for requiring platforms to conduct 'regular impact assessments examining algorithms for bias, fairness, privacy, and security'; shielding workers from 'invasive AI surveillance'; and ensuring transparency and 'human review' in employment decisions. He wants liability reforms and to rein in broad tech immunity. This is a disclosure-and-accountability framework — he does not call for banning AI in specific high-stakes sectors or mandatory pre-deployment government approval, placing him at value 3: require AI developers to disclose risks and be held responsible when their systems cause harm. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='e31c865b-e378-4c02-b6d5-3f3fc1393791' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='ea2ea8af-7b16-48da-a70f-9752b0ca0db8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Jared Polis
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Polis signed SB24-205 (May 17, 2024) requiring developers and deployers of high-risk AI systems to disclose when consumers interact with AI, provide impact assessments, notify consumers of consequential algorithmic decisions, and offer appeal processes. He also vetoed a social media child safety bill (April 2025) resisting heavy-handed content regulation. His signed AI law aligns with requiring risk disclosure and accountability without a broad ban. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='ea2ea8af-7b16-48da-a70f-9752b0ca0db8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='eeeaf1be-3372-4cf9-b3b6-d5d1dff42615' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Jesse Arreguín
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Arreguín voted YES on SB 53 (2025, AI-generated deepfakes), YES on SB 813 (2025, CA AI Standards and Safety Commission), and YES on SB 243 (2025, companion chatbots regulation). As Chair of the Public Safety Committee he oversees AI safety legislation. This pattern supports requiring basic safety testing before AI systems are deployed, consistent with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='eeeaf1be-3372-4cf9-b3b6-d5d1dff42615' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='9edc0c37-f213-4aae-9212-c9cb4780d854' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Laura Richardson
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Richardson voted YES on SB 53 (2025, AI incident reporting and oversight), SB 813 (AI Standards and Safety Commission), and SB 719 (inventory of high-risk automated decision systems in government). This pattern — supporting safety testing and safety commissions — aligns with requiring basic safety testing before deployment rather than heavy pre-approval requirements or a laissez-faire approach. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='9edc0c37-f213-4aae-9212-c9cb4780d854' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='fc8374d8-7186-4be8-9c36-f37df2e9c0d8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Lori D. Wilson
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on AB 2930 (2024) requiring impact assessments for automated decision systems and YES on AB 2013 (2024) mandating AI training data transparency disclosures; supports basic safety testing and transparency requirements without heavy regulatory bans. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='fc8374d8-7186-4be8-9c36-f37df2e9c0d8' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='ec0aeea4-afb2-46b1-be2c-c226188cfbaa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Maggie Hassan
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Hassan co-sponsored the Preserving American Dominance in AI Act (December 2024 with Romney Reed Moran King) which establishes an AI Safety Review Office requiring pre-deployment safety testing for frontier models but includes a presumption-of-approval mechanism after 90 days. This reflects requiring basic safety testing before release without heavy government control. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='ec0aeea4-afb2-46b1-be2c-c226188cfbaa' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='750717e7-1f22-42a7-86fd-e065caf343de' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Maria Cantwell
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$As Senate Commerce Committee Ranking Member (formerly Chair), Cantwell released the MAIN AI Act (May 2024) requiring basic safety testing before AI systems are released but stopping well short of heavy government approval requirements. Her approach emphasizes innovation while establishing baseline accountability standards. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='750717e7-1f22-42a7-86fd-e065caf343de' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='c7dc9c50-84c6-4bde-af06-e7f9d5167e93' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Maria Elena Durazo
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Durazo voted YES on SB 1047 (2024, AI safety requirements, 32-1), SB 243 (2025, AI safety, 33-3), SB 813 (2026, AI regulation, 31-7), and SB 719 (2026, AI inventory, 39-0). She also voted YES in the Labor Committee on SB 366 (2025, employment AI protections). Her pattern reflects consistent support for basic safety testing and oversight before AI systems are released, without authoring the most aggressive oversight packages, aligning with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='c7dc9c50-84c6-4bde-af06-e7f9d5167e93' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='c1215ce9-430e-411d-869c-353c93fe1cac' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Megan Dahle
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$As a 2025-2026 State Senator, Dahle voted YES (37-0) on SB 53 (May 2025), requiring basic AI safety testing and incident reporting before deploying advanced AI systems, and YES (39-0) on SB 719 (Jan 2026), establishing government AI accountability frameworks. These bipartisan votes suggest she supports baseline safety testing requirements without opposing AI development broadly, consistent with value 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='c1215ce9-430e-411d-869c-353c93fe1cac' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Melissa Hurtado
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted Aye on SB 1047 (AI safety 2024) and Aye on SB 813 (AI safety 2026). Aye on SB 53 concurrence (2024). NVR on SB 243 (companion chatbots 2025). Her legislative priorities page emphasizes holding the powerful accountable through algorithmic price-manipulation oversight, suggesting support for basic safety testing before AI deployment rather than heavy pre-approval requirements. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='0d70edc9-535c-4191-a222-fe57ebde4467' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Mia Bonta
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on SB-1047 (AI safety bill requiring frontier model safety testing 2024) on the 48-16 Assembly floor vote supporting basic government oversight before AI deployment without imposing heavy regulatory bans. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='0d70edc9-535c-4191-a222-fe57ebde4467' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='cacdb3e3-f716-4914-9e32-a95cc632af42' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Mike Fong
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Authored AB-2392 (2026) requiring CA community colleges and CSU to establish procurement standards and safety testing protocols before deploying generative AI systems — including risk assessments, student data protections, sycophancy avoidance standards, and vendor labor/privacy screening. This is basic safety-testing-before-deployment regulation aligned with stance 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='cacdb3e3-f716-4914-9e32-a95cc632af42' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='974bfe8b-afb8-424c-bfd2-7805f033b1a0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Mike McGuire
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$McGuire voted Aye on SB 1047 (2023-24 Wiener AI safety bill requiring safety testing for frontier models) on 08/29/24 and Aye on SB 53 (2025-26 AI large developers) on 09/13/25 and Aye on SB 243 (2025 companion chatbots regulation). His votes reflect support for basic safety testing before AI release rather than heavy pre-approval regulation or a laissez-faire stance. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='974bfe8b-afb8-424c-bfd2-7805f033b1a0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='c7a56941-597a-456b-8fd8-e4bd840014c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Monique Limón
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Limón voted Aye on SB 1047 (Safe and Secure Innovation for Frontier AI, May 2024) and Aye on SB 53 (AI large developers regulation, Sep 2025). She supports safety testing requirements before AI systems are deployed publicly, aligning with value 3, but has not authored primary AI legislation. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='c7a56941-597a-456b-8fd8-e4bd840014c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='6f5db776-afcb-40c3-87a5-83e9408d3044' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Nanette Barragan
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Cosponsored the Algorithmic Accountability Act of 2023 requiring impact assessments when automated systems cause harm, and introduced the bipartisan AI Public Awareness and Education Campaign Act (H.R. 7151, Jan 2026) and HEAL AI Act (Nov 2025) focused on disclosure and literacy. Her pattern is transparency and accountability for harms rather than pre-approval requirements or bans, placing her at new scale 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='6f5db776-afcb-40c3-87a5-83e9408d3044' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='d64c969e-f458-4387-98b5-1e7af8cb42f0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Pilar Schiavo
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Schiavo voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions with worker protections) and YES on SB-1047 (Safe and Secure Innovation for Frontier AI Models Act — required safety testing and risk disclosure for large AI models). Her YES votes on both bills requiring AI risk disclosure and employer accountability reflect support for holding AI developers responsible when systems cause harm. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm). — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='d64c969e-f458-4387-98b5-1e7af8cb42f0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='ff77225c-51f9-4628-acc3-020d40382d05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Rick Chavez Zbur
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Zbur voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions with worker protections) and YES on SB-1047 (Safe and Secure Innovation for Frontier AI Models Act — required safety testing and risk disclosure for large AI models). His YES votes on both bills requiring AI risk disclosure and AI safety requirements reflect support for mandatory accountability. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm). — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='ff77225c-51f9-4628-acc3-020d40382d05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='5a75d4fb-e4fe-441a-8658-e6eb57574fd4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Robert Rivas
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on SB 1047 (Safe and Secure AI Act requiring safety testing, 8/28/24) and YES on AB 1018 (automated decision systems oversight, 6/2/25). Supports requiring basic safety testing before AI companies release new systems. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='5a75d4fb-e4fe-441a-8658-e6eb57574fd4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='2147281e-e1b1-4416-a5d9-dae9d4f31be0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Ron Wyden
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Wyden introduced the Algorithmic Accountability Act (2019) granting the FTC power to study algorithmic bias and the Mind Your Own Business Act (FTC penalties up to 4% of annual revenue for privacy violations). He supports basic safety testing but strongly opposes heavy government control that would stifle innovation, consistent with his record co-authoring Section 230. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='2147281e-e1b1-4416-a5d9-dae9d4f31be0' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='3c2bfe51-9a53-4992-801b-138a1a8ce9ed' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Sade Elhawary
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Elhawary voted YES on SB-7 (Employment: automated decision systems — required employers to disclose and regulate AI use in employment decisions and establish worker protections against automated decision systems). As a Democrat representing an Assembly district in Los Angeles, her YES vote on a bill requiring AI accountability in employment contexts reflects support for holding AI systems accountable when they affect workers. This aligns with value 3 (require AI developers to disclose risks and be held responsible when their systems cause harm). — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='3c2bfe51-9a53-4992-801b-138a1a8ce9ed' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='3a462896-e249-4c79-94b7-175bd2efcf73' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Steve Padilla
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Voted YES on SB 1047 (2024, Safe and Secure Innovation for Frontier Artificial Intelligence Models Act), supporting pre-deployment safety standards for advanced AI. Also authored SB 867 (2025-26) imposing a 4-year moratorium on AI chatbot toys for children under 18, indicating support for targeted safety regulation rather than comprehensive oversight. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='3a462896-e249-4c79-94b7-175bd2efcf73' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='b3937fff-ebcf-48d9-b20d-bdf98196e119' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Susan Rubio
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Rubio voted YES on SB 1047 (2024, AI safety regulation requiring safety evaluations before deployment) and YES on SB 942 (2023, California AI Transparency Act). While she supported both bills, she has not authored AI regulation legislation herself, suggesting she supports safety-testing requirements while following, not leading, on the issue. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='b3937fff-ebcf-48d9-b20d-bdf98196e119' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='401f1fab-c996-4b1a-92f7-2817c5dd4619' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Ted Budd
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Budd introduced bipartisan bills requiring HHS to develop strategies addressing AI biosecurity threats and mandating risk assessments for catastrophic AI-enabled risks; he also co-sponsored the Kids Off Social Media Act restricting algorithmic targeting of minors, supporting basic safety testing in high-risk AI contexts. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='401f1fab-c996-4b1a-92f7-2817c5dd4619' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='712be98b-a05d-4605-9603-cd5d86abfad1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Thomas Umberg
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$As Senate Judiciary Committee chair, Umberg voted YES on SB 1047 (2024, AI safety regulation) at committee and floor stages, YES on SB 942 (AI Transparency Act), and YES on AB 1018 (2025-26, automated decision systems) in Judiciary. He authored SB 574 (2025-26, AI use by attorneys and arbitrators in courts). His pattern supports basic safety testing and disclosure requirements. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='712be98b-a05d-4605-9603-cd5d86abfad1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='9ce81b97-6e02-4bdb-b9dc-e2592d4ce87c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Will Metcalf
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Co-authored HB149 (89R, 04/23/2025), which establishes consumer protection requirements for AI systems including mandatory disclosure, right to appeal AI decisions affecting health/welfare, prohibition on AI systems encouraging self-harm, and a regulatory sandbox for testing. This balanced approach requiring basic safety testing before AI deployment aligns with stance 3. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='9ce81b97-6e02-4bdb-b9dc-e2592d4ce87c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='0f74219c-7d10-4d29-85fe-0f1d834df8a7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Xavier Becerra
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Becerra's AI platform calls for "firm guardrails around real harms," transparency in automated decision-making, human review, and mandatory independent audits of AI systems deployed by state agencies — developed "with industry at the table." It does not require government pre-approval before releasing AI systems. This disclosure-, accountability-, and audit-based approach maps to stance 3 (require developers to disclose risks and be held responsible) rather than a strict pre-approval regime. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='0f74219c-7d10-4d29-85fe-0f1d834df8a7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
UPDATE inform.politician_answers SET value=4, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now() WHERE politician_id='efa0cb88-6ae0-47dc-abe1-b1388983addf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'; -- Yvette D. Clarke
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Introduced the Deepfakes Accountability Act (2019, updated 2023) requiring disclosure and accountability for AI-generated synthetic media; co-sponsored the Algorithmic Accountability Act (2019) requiring audits and liability when AI systems cause harm. Serves on the Energy and Commerce Subcommittee on Commerce, Manufacturing, and Trade. Positions match requiring disclosure and accountability rather than full prior-approval requirements. — Re-sorted 2026-09-01 from chair 3 to chair 4 in the ai-regulation v2 re-audit: this evidence is support for pre-deployment safety testing / impact assessment, which is chair 4's position under the v2 wording (v2 chair 3 covers only legal liability when systems cause harm). This supersedes any chair-3 characterization above.$r$
 WHERE politician_id='efa0cb88-6ae0-47dc-abe1-b1388983addf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';

-- GUARD: ORPHAN_CONTEXT predicate (character-identical to check-stance-sources.mjs) on blanked pairs.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM air_blank t
    JOIN inform.politician_context pc ON pc.politician_id=t.pid AND pc.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023'
   WHERE coalesce(cardinality(pc.sources),0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0098 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int; v_blank_ans int; v_blank_ctx int; v_moved int;
BEGIN
  SELECT count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2), count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4), count(*) FILTER (WHERE value=5)
    INTO v_c1,v_c2,v_c3,v_c4,v_c5 FROM inform.politician_answers WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (19,123,40,87,1) THEN
    RAISE EXCEPTION 'CA_0098: distribution %/%/%/%/% (expected 19/123/40/87/1)', v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;
  SELECT count(*) INTO v_blank_ans FROM inform.politician_answers a JOIN air_blank b ON a.politician_id=b.pid AND a.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF v_blank_ans <> 0 THEN RAISE EXCEPTION 'CA_0098: % answer rows survived for blanked pairs', v_blank_ans; END IF;
  SELECT count(*) INTO v_blank_ctx FROM inform.politician_context c JOIN air_blank b ON c.politician_id=b.pid AND c.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' WHERE c.reasoning ~* '^researched 2026-09-01';
  IF v_blank_ctx <> 334 THEN RAISE EXCEPTION 'CA_0098: expected 334 documented-blank contexts, got %', v_blank_ctx; END IF;
  SELECT count(*) INTO v_moved FROM inform.politician_answers WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND value=4 AND updated_at::date='2026-09-01';
  RAISE NOTICE 'CA_0098 OK — dist now %/%/%/%/% (334 blanked, 41 moved 3->4)', v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
