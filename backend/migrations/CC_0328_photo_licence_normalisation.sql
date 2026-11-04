-- CC_0328_photo_licence_normalisation.sql
--
-- Normalise the Creative Commons spellings in essentials.politician_images.photo_license.
-- 201 rows. SPELLING ONLY: not one row changes which licence it claims.
--
-- WHY THIS IS NOT COSMETIC
--   CC BY-SA 4.0 was stored three ways, 3.0 and 2.0 two ways each, and the family prefix itself
--   two ways. Any predicate on this column therefore returns a fraction of what it names.
--   `CC_0326` relied on `photo_license ILIKE 'cc%'` to find attribution-owing rows and was
--   correct only because that pattern happens to be loose enough to catch every spelling.
--
-- 🔴 THE VALUES THIS OVERWRITES, IN FULL
--   There is no history table for this column, so the overwritten value exists nowhere once this
--   commits -- and the mapping is NOT invertible from the end state, because two old spellings
--   merge into a third that 36 rows already used. The `lic_fix` table below therefore carries
--   every row's own old value. THIS FILE IS THE BEFORE-IMAGE; reverting is replaying it backwards.
--
--   184  cc_by_sa -> cc_by-sa
--    13  cc_by_sa_4.0 -> cc_by-sa_4.0
--     2  cc-by-sa-4.0 -> cc_by-sa_4.0
--     1  cc_by_sa_2.0 -> cc_by-sa_2.0
--     1  cc_by_sa_3.0 -> cc_by-sa_3.0
--
-- THE CANONICAL SCHEME, AND THE WHOLE OF IT
--   lowercase; parts joined with '_'; a licence ELEMENT keeps its own hyphen ('by-sa'); the
--   version is appended with '_'.  ->  cc0 · cc_by_2.0 · cc_by_3.0 · cc_by_4.0 · cc_by-sa · cc_by-sa_2.0 · cc_by-sa_3.0 · cc_by-sa_4.0
--   This is already the repo majority at every version that had more than one spelling
--   (36 vs 13 vs 2 at 4.0; 16 vs 1 at 3.0; 12 vs 1 at 2.0), so it is the smallest change that
--   makes the column uniform.
--
-- ⚠ 'cc_by-sa' CARRIES NO VERSION, AND THIS MIGRATION DOES NOT GIVE IT ONE.
--   184 of the 201 rows are the unversioned value. CC BY-SA 2.0, 3.0 and 4.0 are different
--   licences with different terms, so inventing a version to make the column tidy would be
--   asserting a legal claim nobody checked. They are re-spelled and left unversioned, which is
--   what the record actually supports. After this they are findable in one query:
--   `photo_license = 'cc_by-sa'`. See the PR for where they came from.
--
-- WHAT IS DELIBERATELY OUT OF SCOPE
--   The free-text provenance paragraphs in this column (some 250 words long) are untouched. A few
--   mention CC in passing; the token regex is anchored at the start of the value so a sentence
--   about a licence is never mistaken for one.
--
-- Production state read 2026-11-02 (CC-token values only):
--   184  cc_by_sa
--    36  cc_by-sa_4.0
--    23  cc_by_4.0
--    22  cc_by_2.0
--    16  cc_by-sa_3.0
--    13  cc_by_sa_4.0
--    13  cc0
--    13  cc_by_3.0
--    12  cc_by-sa_2.0
--     2  cc-by-sa-4.0
--     1  cc_by_sa_3.0
--     1  cc_by_sa_2.0

BEGIN;

-- Every licence value's count as it stands right now. The post-verify uses this to prove that
-- nothing OUTSIDE the normalised set moved -- a delta captured inside this transaction, not a
-- total another session can shift while the file is being written.
CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images
   GROUP BY 1;

CREATE TEMP TABLE lic_fix (
  image_id    uuid PRIMARY KEY,
  old_licence text NOT NULL,
  new_licence text NOT NULL
) ON COMMIT DROP;

INSERT INTO lic_fix (image_id, old_licence, new_licence) VALUES
  ('019e48ca-7a95-4f24-9b8a-c6e05544b6a3'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('02558142-421b-4db3-a853-f28d2b378120'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('045e6225-f19b-4961-971c-e10d4c72eeeb'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0591342d-303a-4d11-bc03-e8cdba4c9fb2'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('05d6350e-4c48-42eb-bbaf-6eb00e813b8f'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('089ad4f9-4b98-454a-867c-386ca808e546'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0b18776f-7512-4a24-b7f6-8c9d37604dfe'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0c1660f9-fbb8-48a6-87ab-13c8fc77cf95'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0cc81f5d-78bf-4668-ad08-7f2d62ebf42c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0f1372e6-6887-4ee8-ac14-2b96e86b1cff'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('0fcc828d-1a28-4d5b-9a02-384c221d1cea'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('10135389-1335-4bdf-a1fa-4d1cfb85416a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('13505fa0-cd69-4559-85df-292e9cb3790b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('1351156f-5dce-4fac-8440-1d9f9bd396d1'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('16bfc0bb-383b-4957-ae24-069885b07610'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('179562d5-fe65-4550-8f06-e18e84c3db7b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('17b388e5-cdd4-4bf5-995a-9825bfb243e6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('17c7559e-ebfd-4414-bf1b-521b456ff6c5'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('1907b290-7f03-4650-9a8e-f420bab0ac5b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('1a773e22-c1c1-404d-afc9-f2f383304fc3'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('1ea3d6a1-a53f-4571-90c5-fab6c8df991b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('2193697f-f109-4097-b59d-4ca2024d7c59'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('225cbcdd-f447-4230-bd5e-47e36628b9dc'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('27546165-1806-4fa2-bb0f-5bd0aad7ef87'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('28b9e10e-4c19-40af-b629-531aa922579b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('29188bdc-04e6-4363-afe0-815ff1d9416b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('29a81c73-8a15-45bc-b29f-b4dfd04044d6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('29b699f8-e9c4-41f3-8416-531db34a8033'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('29e1dc54-9f79-41d1-add8-a32e7f99ecf6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('29fbb792-1b37-465f-938b-b5c6342775a5'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('2bbf7ab3-5231-4575-9dce-59b2537e86be'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('2c34ba52-cb42-4d51-abc5-55136d78446e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('2f0118f5-a878-4787-8403-c22890432650'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('2fc8f193-1080-4904-af4c-2cd886546f8b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('32c8bf92-9c70-4406-8829-602e25b119ef'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('33da35c1-0d73-4e7d-9f7e-9c36b20095c7'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3480ebb6-3c29-4334-9099-fd3e666cfd50'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('38e9a63c-df7d-4545-9078-b46990590e0a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('390b65ce-64e7-4018-82ae-b9d1006ef4bc'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('399a481f-3372-4278-bd09-3e5be8b0b9fa'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3a5ea9fc-02fd-45ef-b761-f3eb46db6314'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3a655b25-0ea3-4236-8ae1-824f0d25f04b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3c16f67e-88d6-4028-9384-0013dcfb4143'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3d7a57cf-c6b7-4084-8800-cd8114e6d6a0'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3f0e4541-3b75-4867-b6e5-acfc95e3d3a9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('3f93fd5e-6c3a-4e8d-9de5-9645faef20f2'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('41213208-2c83-45d1-b681-6c3d3de6512c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('41e01327-8596-4085-baec-adaf6756f288'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('428aee29-1b51-46b9-a98b-35de48d776dc'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('45091d10-4279-4bec-bd12-71ab66d3e08a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('469ecc3a-b933-4516-ac42-1c5f996b9319'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('47eaa4cf-1ad6-4d42-9b41-757b67c5fb73'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('4827d81b-a353-4e33-81df-4b868fab5b25'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('4a52bc68-0716-44cd-9ca1-c0d8c9768420'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('4d8cea62-e908-44b7-b6f8-67a834d0d751'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('4dc704d9-01ef-47e0-805b-58eb71c56df5'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('50f036dc-df0a-42c8-8c09-d3f0254ddc3a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('514c6088-fb1e-4aff-b464-14d8fc1fb8e6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('51b5ab4c-0cc9-4a9c-a220-a851736e78d4'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('53f74ad4-17ed-45f1-a488-3e8983c5788e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('56b06e1d-aec2-400b-9799-2ad78b232126'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('56b4425c-451b-4d5b-99b8-f14d458efa8e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('57668715-ed3a-40be-b677-8cbb1869bdd7'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('577c5279-53af-4d0e-9a10-e94a432343e0'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('59bd2e72-56db-43a6-948e-9ebae431130d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('59d07b41-f0b6-467d-8971-14b3f3a0ddda'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('5d4bd91d-7e8d-47fc-ab24-b0eee1ce917d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('5f9d95f0-61d4-4104-8d03-768419430739'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('60b6b84e-e2c3-4315-b7c3-2560c9b190d8'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('613fddd0-e27f-4ca9-a16e-0921020aec42'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('62be5aac-d4f4-4b59-bcbc-f3f96ac983ff'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('64f9d0c6-505a-431b-a99d-8ab0967d7dae'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('684e0fb6-324f-41a6-95bc-d5137361524e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('68acfeda-ae7c-457a-b58e-54b01ac0819d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('6d8459f6-e4b8-48c7-92eb-6634e5571c8e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('6db67ee9-5840-4a83-ba8b-c9823b9f547a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('6e78361e-6bcc-4b39-aec3-7197fdb85f35'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('6f8ced23-c876-495e-b9d5-3e1cce7d09bb'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('7042174f-ff57-4731-aecb-97922f02f440'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('72151e3c-f33f-4705-b71a-045560e4a333'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('73745b66-0e3f-4946-a262-f1743b5ec57e'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('73b202c5-6071-4580-8366-340e9ec047f0'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('765d4d3e-838e-4fdb-95cb-716bb98dd9fa'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('77201958-3a77-48dc-8407-4a703dd3e498'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('7742d27e-3047-40d3-bbad-cffc2cb9886a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('7c219a86-fd6c-4f4a-8ca8-d0513d5b18f9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('7fc05f2c-548f-4df0-88b9-7b656805e1f4'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8110a77d-f866-49a2-b73a-742356012426'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('81638169-68a7-4d75-82b7-8d9e383d6ab5'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('81b75637-8bf3-4fae-854c-0aab8a25b817'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('82bc978f-c639-4a45-8dc3-a21657b06968'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('83fcdd68-3de3-4969-b6bc-1848fd1f47f8'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('85bc5a78-1ff9-4d3e-9677-f2963c475e99'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('86025dcf-ef88-4e32-9200-0c615ff6c514'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('861f5ee3-22f6-4a14-8aef-167e0a84a63d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('86c06a07-ab6c-426c-a3fa-d9000b811d52'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('877bcbd3-3431-4366-aa7f-c8630ae40752'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('89abc29d-a029-4fbd-affd-619c4307bd1d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8a6b77ad-e390-4255-a807-5a80483229b6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8aee51d5-6b87-4e5a-a6b0-e942fba7734d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8c0a0422-d660-42b8-99a9-9e844590ab04'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8f2b4cb9-2bd1-49b3-8dac-007135d8816c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('8fb16929-e56d-4bc6-9cf9-1bdeaf1ad169'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('93225665-09f4-43a2-8afc-faa24df1762c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('933e77cc-3283-48c3-827f-da464c9daba2'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('94081ef3-b989-4093-aadc-c8e7bdec335d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('94a6cf9f-a661-4403-9069-3a0955bdc997'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('95489350-7dce-4a5f-9a70-d58e040a052b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9647dd35-6a81-4f10-96ce-361598e4a811'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('97004044-5421-4899-bf08-a871fb119d4c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('97cc5a83-3a15-4b71-a2e8-324fd34688c0'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9a926500-84b7-4727-b132-be46ce0f5d84'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9abea4fd-893d-4ef7-9684-95cd1bdf1f73'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9b952f60-4ed7-4d91-a8af-a5ca36401c69'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9bd5ddde-40e6-44a8-bb52-b5fc77683717'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9ccfea19-d2f8-4d62-8529-6fe6083d4231'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('9fb8199b-de10-4624-a61e-ee5a5b47f800'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a078d470-7b27-4664-8e8b-32d556b034a5'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a1abc1b8-20a0-44ce-910d-e38edff10264'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a4cffcbd-74f3-4d15-9a2e-7671faaa270d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a51d695c-13c0-491f-8425-a7c5d8fffaf0'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a52dd27a-8802-4813-8c25-3d68736ed55c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('a5bcaf31-2013-4abc-bea1-a1781daa6ed2'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('aa91e116-9416-49c6-a3d5-03a28f9cc6e1'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('aabf00f7-b6cc-4401-8f1e-ac564e9f91dc'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('aac22646-b8ad-445d-ac49-4366ca7b2ac4'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ab74dde0-913d-4b81-a478-cba8774d910b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ad1daed9-74c8-441a-a5a2-3202222edba7'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('aece92cd-5899-4622-abfc-896285d95d76'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('aed85eb3-f194-4b90-93a9-fec5feb3d201'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('afcc2d08-2f2a-4146-a708-2063beef7c30'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b0d23f24-f2af-41eb-8a3e-0119f36e3351'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b2a3cdc6-1d98-49eb-9390-dad0bf56bb38'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b2ca3fcd-65c8-40cb-b0f9-32a34312026a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b2e4e7fd-225d-4883-ac68-efc4c47e4bf9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b64465d3-2e92-411a-91bb-e7d19fd56cb3'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('baba2271-fe52-433a-be9a-27a492fd5507'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('badf82c3-2a69-4f0b-ae7d-89b89df15b56'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('bafc11f0-e1de-4d3c-8a38-ce96f0a0f4a7'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('bb2af711-2ea1-4984-b22b-70f511493a31'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('bbbba77b-137b-4a77-a4b6-d653852ee6a1'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('bbe8b311-4ea6-4129-b5b8-00da2ed235bd'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('bda3e292-67c3-4b11-979d-45fee9531caf'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('c0e50f21-f277-4a82-ac86-614d70897315'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('c899d196-d56d-4dbe-918c-ad28be812826'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('cc6d2382-893b-4c52-a9db-7657fbaf1cc9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('cce24911-2793-45c4-b98e-8a189abff255'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ceabbf83-4293-4554-8362-8d6dccf25121'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('cfd4e7a8-876f-4240-9f5c-7d3223cd12a6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d132f7cb-9104-4af7-985d-2040e172799a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d313da4e-fa5e-4b80-9e76-11102ef7ee6f'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d545317b-1782-4bc6-8848-ddf6dfcbc4dc'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d54ccf68-fe1f-4d3a-8c29-8bdbc17f8925'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d57b6819-c70b-4209-9add-ebc8894a2ed9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d70b947d-56fe-47d8-81e5-0a1c071d4af1'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d75f1abf-3e31-449e-8c7b-4982d6fa97fb'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d7c92dba-1585-45ad-aaa3-b1029e29cbf9'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d7d7ccb5-3c72-45b1-b887-b7ddee1b875b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('d96cc27d-d1cd-48ae-8c19-0acd6f4ea17c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('dab532fc-40d3-4ae9-a776-a7a8cdc8396d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('dcb19e6e-1c0f-474c-bfc0-5b46ca3ecbaa'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('dd89e8fa-3f00-46e5-8f96-e4f791520663'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('e240b46e-9e28-4aa2-959b-4568c2bd0b99'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('e5194bbf-1a15-46a1-b642-ae16c8099e48'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('e8514fb1-6ba6-4366-b7d8-c5a6524e4313'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('e876dcd8-ca3b-42a3-adc0-7d9cbf8f5f9f'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('e92277d7-890d-4b2e-a93e-f412aae9c7ce'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('eaf31446-2e8f-42a9-abbc-157f9f699dca'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ebc20067-e888-41c3-b7fa-03e5df93555c'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ec7a0f9e-f517-4430-87ba-9559bce17578'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('edbb1778-68f8-4b71-a450-8f4bdc936bb3'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('eeaba0e7-7d70-4e07-bc64-9de8bcdefc21'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f167840d-90a8-4cec-a590-f8b543c0b63d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f23e37a8-899e-4b6c-8fc7-b7cb68abbd24'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f251b677-6733-4b47-a28d-149f5ae335d6'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f3729a22-1f96-48ab-b135-2bd519bc207b'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f526b6a7-1318-4151-b2bd-17a95b9fb8ed'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f8236503-7cdc-45dd-afb3-53b05b545aee'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('f9beeef7-a0bb-48b3-876b-92234006f0a2'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('fb74bd5d-5493-4a70-bb51-f8d77c05049d'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('fba7fb48-e4ed-4abe-b04a-06ff651ffe7a'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('fe5466bb-5e07-4281-b0e2-b88ec6378409'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('feb37ade-e2d8-4e04-b672-bccacb2dd841'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('ff337edd-ab4e-427a-8c79-78acaea12819'::uuid, 'cc_by_sa', 'cc_by-sa'),
  ('b52acf14-a266-462d-ad95-0e8bafca26b8'::uuid, 'cc_by_sa_2.0', 'cc_by-sa_2.0'),
  ('47c747b2-6db9-4a8a-b120-5214bf27cb8f'::uuid, 'cc_by_sa_3.0', 'cc_by-sa_3.0'),
  ('10f4d657-a9aa-4f92-ad24-507317354374'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('11398568-3162-454c-b302-ead7a36fdf6f'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('41516abd-4952-4b53-9b3b-00a582ed054f'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('4cf3237f-e724-4b52-b746-a769160765f8'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('7184e697-5a57-4f21-8ed8-fd37d9b0cf46'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('73b3a83b-84e0-4729-9267-e602b148747a'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('7c60e1f2-e162-4830-bb18-3c98b20efb1b'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('80ad091e-ad56-486b-a1b8-263f614c7f0a'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('89ad7dc6-a65b-4c4a-8e07-74d848d172c9'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('96441b95-6bde-4525-beca-8788d3021199'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('988ad452-d57d-4fc1-9221-ece0d1706249'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('c12788f5-08df-47b5-8d38-62979eb68bd9'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('f852cfaf-a4d5-4645-a303-1310dd31ef2e'::uuid, 'cc_by_sa_4.0', 'cc_by-sa_4.0'),
  ('4fe68622-1551-4716-ae52-3f383132962b'::uuid, 'cc-by-sa-4.0', 'cc_by-sa_4.0'),
  ('5451bea8-b4c9-442b-90b4-faae0ebca154'::uuid, 'cc-by-sa-4.0', 'cc_by-sa_4.0');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM lic_fix;
  IF n <> 201 THEN RAISE EXCEPTION 'pre-flight: expected 201 staged rows, found %', n; END IF;

  SELECT count(*) INTO n
    FROM lic_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id;
  IF n <> 201 THEN RAISE EXCEPTION 'pre-flight: % of 201 staged images exist', n; END IF;

  -- 🔴 Every staged row must STILL carry the value this file records for it. If one does not,
  --    somebody changed it after the file was generated and the before-image is already a lie.
  SELECT count(*) INTO n
    FROM lic_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license IS DISTINCT FROM f.old_licence;
  IF n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged image(s) no longer carry their recorded old licence', n;
  END IF;

  -- 🔴🔴 THE GATE THAT MAKES "SPELLING ONLY" TESTABLE RATHER THAN ASSERTED.
  --     Strip every hyphen, underscore and space from both sides and they must be the same
  --     licence. A relabelling -- 2.0 written over 4.0, by written over by-sa -- cannot survive
  --     this, however well-formed it looks.
  SELECT count(*) INTO n FROM lic_fix f
   WHERE regexp_replace(lower(f.old_licence), '[-_[:space:]]', '', 'g')
      <> regexp_replace(lower(f.new_licence), '[-_[:space:]]', '', 'g');
  IF n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % row(s) would change the LICENCE, not just its spelling', n;
  END IF;

  SELECT count(*) INTO n FROM lic_fix f WHERE f.new_licence NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0');
  IF n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % row(s) target a value outside the canonical vocabulary', n;
  END IF;

  -- 🔴 The staged set must be the WHOLE problem. A non-canonical CC row left out of it would
  --    survive the migration and quietly keep the column non-uniform.
  SELECT count(*) INTO n FROM essentials.politician_images pi
   WHERE pi.photo_license ~* '^\s*cc[-_ ]?(0|by|zero)'
     AND pi.photo_license NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0')
     AND NOT EXISTS (SELECT 1 FROM lic_fix f WHERE f.image_id = pi.id);
  IF n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % non-canonical CC row(s) are not staged', n;
  END IF;

  -- The generator's own arithmetic, checked LAST and deliberately so. These counts move for any
  -- edit at all, so in front of the gates above they would shadow every one of them and a tamper
  -- aimed at the spelling check would go red here instead -- a control that proves nothing about
  -- the thing it was pointed at.
  SELECT count(*) INTO n FROM lic_fix WHERE old_licence = 'cc_by_sa' AND new_licence = 'cc_by-sa';
  IF n <> 184 THEN RAISE EXCEPTION 'pre-flight: expected 184 rows cc_by_sa -> cc_by-sa, found %', n; END IF;

  SELECT count(*) INTO n FROM lic_fix WHERE old_licence = 'cc_by_sa_4.0' AND new_licence = 'cc_by-sa_4.0';
  IF n <> 13 THEN RAISE EXCEPTION 'pre-flight: expected 13 rows cc_by_sa_4.0 -> cc_by-sa_4.0, found %', n; END IF;

  SELECT count(*) INTO n FROM lic_fix WHERE old_licence = 'cc-by-sa-4.0' AND new_licence = 'cc_by-sa_4.0';
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected 2 rows cc-by-sa-4.0 -> cc_by-sa_4.0, found %', n; END IF;

  SELECT count(*) INTO n FROM lic_fix WHERE old_licence = 'cc_by_sa_2.0' AND new_licence = 'cc_by-sa_2.0';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 rows cc_by_sa_2.0 -> cc_by-sa_2.0, found %', n; END IF;

  SELECT count(*) INTO n FROM lic_fix WHERE old_licence = 'cc_by_sa_3.0' AND new_licence = 'cc_by-sa_3.0';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 rows cc_by_sa_3.0 -> cc_by-sa_3.0, found %', n; END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = f.new_licence
  FROM lic_fix f
 WHERE pi.id = f.image_id
   AND pi.photo_license = f.old_licence;

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM lic_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license = f.new_licence;
  IF n <> 201 THEN RAISE EXCEPTION 'post-verify: % of 201 carry their normalised value', n; END IF;

  -- The invariant this migration exists to establish.
  SELECT count(*) INTO n FROM essentials.politician_images pi
   WHERE pi.photo_license ~* '^\s*cc[-_ ]?(0|by|zero)' AND pi.photo_license NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0');
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: % non-canonical CC spelling(s) remain', n; END IF;

  -- 🔴 NOTHING OUTSIDE THE NORMALISED SET MOVED. Compared against this transaction's own
  --    starting census, so it measures what THIS migration did and not what the week did.
  SELECT count(*) INTO n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) NOT IN ('cc_by_sa', 'cc_by_sa_4.0', 'cc-by-sa-4.0', 'cc_by_sa_3.0', 'cc_by_sa_2.0', 'cc_by-sa', 'cc_by-sa_4.0', 'cc_by-sa_3.0', 'cc_by-sa_2.0');
  IF n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the normalised set changed count', n;
  END IF;

  -- 🔴 And the unversioned rows are still unversioned. If this number moved, the migration
  --    invented a version for somebody.
  SELECT count(*) INTO n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF n <> 184 THEN RAISE EXCEPTION 'post-verify: expected 184 unversioned cc_by-sa rows, found %', n; END IF;
END $$;

COMMIT;
