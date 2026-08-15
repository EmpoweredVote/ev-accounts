-- 1755_judicial_orphan_context_delete.sql
-- The context left behind when migration 1735 blanked the role-conduct judicial answers.
--
-- 🔴 THIS IS NOT A NEW DEFECT -- IT IS THE DOCUMENTED RESIDUE OF A CORRECT FIX, AND NOBODY CONNECTED
-- THE TWO. 1735 (2026-08-12) deleted 117 answers on the three ladders that ask about the subject's own
-- conduct in a role they neither hold nor seek, and deliberately kept the context. Guard 2 of that
-- migration ASSERTS the context survived. The next morning ORPHAN_CONTEXT went 50 -> 224 and CI stayed
-- red for 19 runs, because a blanked answer plus a surviving reasoning row IS the orphan shape.
-- 🔑 Generalise: retiring an answer and retiring a stance are not the same operation. Whenever a pass
-- deletes answers, decide what happens to the context in the SAME migration -- the gate will find it
-- either way, just later and with less of the reasoning still in the room.
--
-- 🔑 1735 COULD NOT SEE 2 OF THESE 119, AND THE REASON IS THE ONE THIS WORKSTREAM KEEPS RE-LEARNING.
-- It drove FROM inform.politician_answers, so William Smith and Jeff Waldstreicher -- whose Bail &
-- Pretrial answers had already been blanked by the Maryland pass -- were outside its universe by
-- construction, not missed by a loose predicate. That is the identical FROM-clause blindness that hid
-- this entire class from the gate until 2026-08-07, recurring inside the fix for it. Both are the same
-- category error as the other 117 and are removed with them.
--
-- WHY DELETE AND NOT REWRITE AS A DOCUMENTED BLANK. A blank says "we looked and found nothing". That
-- is not what is true here: the question does not apply to this person at all. Rewriting 119 rows to
-- assert an absence that was never tested would put a false statement in a voter-facing field to make
-- a gate go quiet.
--
-- ⚠ WHAT IS BEING GIVEN UP, STATED PLAINLY. Roughly 80 of these rows carry real, named-instrument
-- evidence -- Warren co-sponsoring the No Money Bail Act, Brownsberger authoring the 2018 CJ reform
-- law, Nazarian's AYE on SB 10, Mitchell's Care First Pretrial Agency motion. That research is good;
-- it is simply attached to a ladder its subject cannot stand on. `judicial-criminal-justice` and
-- `public-safety-approach` are live and role-UNSCOPED, so a legislator can hold a position on either,
-- and that is where this evidence may belong. Moving it is re-research against a different question,
-- NOT a re-parenting UPDATE: bail-reform evidence supports a bail chair, not automatically a criminal
-- justice chair. Recorded as owed; every row is preserved verbatim in the rollback file below.
--
-- Every deleted pair is listed explicitly, taken from the rollback capture rather than re-derived, so
-- the record and the delete cannot disagree. The capture script re-ran 1735's holds-or-runs test at
-- capture time and refuses to emit if any row qualifies; all 119 returned false.
--
-- Rollback: data/stance-retirement/2026-08-14-judicial-orphan-context-1755-rollback.json
--           (reasoning and sources verbatim -- restoring is an INSERT from that file)
BEGIN;

CREATE TEMP TABLE joc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

CREATE TEMP TABLE joc_target (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO joc_target VALUES
  ('41945b74-325e-4fa2-9cc9-edd11ead9ed3','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('602f147a-90bc-4083-aeab-1d0becf088e9','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('7bf73fb2-1b31-412e-913d-835bfd3e326d','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('77256186-0ce8-4069-9d06-1d2fd5b4b622','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('04e1a744-acf5-4453-9172-7135b6bfce96','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('81dfcf88-c739-4461-9d16-931f8d51a8c5','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('d40a0eda-36fc-4032-8382-20c76a36d6a6','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('969f1ca4-4766-44fd-8638-ef813b1835e7','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('e30ddde5-a722-477b-837b-056fdc7e2d6b','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('a0cb697c-3158-4680-8e70-c154c3a15cc4','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('8c34f0b8-4201-49b4-95a2-d043e99a3eef','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('6b16270a-c6c7-46be-9b9c-7def323dc4ef','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('b96758c6-2ea0-4698-8886-d574d34e366d','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('da75c207-bb23-477e-b3c0-7c462394b570','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('916afe40-4061-476f-9a54-b271b32778d2','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
  ('e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('7cd80dd2-bbc6-4ae0-8445-b8688bf19c47','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('41945b74-325e-4fa2-9cc9-edd11ead9ed3','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('4a7dc8a6-2138-4472-8197-8b878034f029','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('13ebfaf6-3fc1-4448-a034-8b6bb6eade65','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('9c5e1ac7-8a39-4c6e-8b20-0788a92f8607','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('cf190bac-9369-4175-bd4b-8ba776697d9c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('7bf73fb2-1b31-412e-913d-835bfd3e326d','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('98d6a17e-59dc-4d11-a342-869603862f10','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('b47b26a2-ef64-42d2-b3e8-d076d4ecd1df','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('1ff55ff7-c617-42cf-864e-a0d788815c43','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('dc3d8a98-07ce-4797-bc84-957a72fd854f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('6e3c30f5-52be-48b0-b5b4-383e5d745c57','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('b80a680a-9f79-4d56-994b-00ce24ec7ef3','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('9e3f9d94-ec56-4d9e-811f-8b4672494362','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('05c9b5b9-cb2b-4387-ab6b-350b69553fac','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('81dfcf88-c739-4461-9d16-931f8d51a8c5','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('a7d28222-72e6-4fb5-befd-74b6ef664cd0','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('560d30c0-6904-4a3e-a4c5-4294d5ff87dd','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('d40a0eda-36fc-4032-8382-20c76a36d6a6','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('8cffe7a0-b56c-42fe-adbf-f57d63589973','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('bc703231-6af8-48c6-8ae6-4a93fc60b18f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('fc67428c-f769-47ca-9004-0f68bc917409','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('e76d0654-b0c6-43dc-9159-e929e480d070','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('fc23b939-0dfd-4968-ab19-fc1e7745e997','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('21975878-739e-452b-8bf7-95919680462a','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('a9882d8b-b20d-4b0c-b509-c2883b4352e0','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('5587e9e4-0bfe-40d7-97a0-5a736fd7b5b7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('6cd02c2b-6bca-4b74-9703-0917872bf3f7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('b89b09f0-6a9f-46e5-9193-8a9de99867b0','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('590fd6ec-3194-43af-97fc-25490490c565','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('ee52f7fe-8923-4ac7-85b4-7bd9ea68389c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('8abee534-5db0-4950-a2b9-d0d1e8088cc7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('96876928-53f8-4ed5-b2de-deab3a456d83','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('e30ddde5-a722-477b-837b-056fdc7e2d6b','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('a0cb697c-3158-4680-8e70-c154c3a15cc4','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('0e238dbf-5b4e-4e95-8a94-e02d97a136f5','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('70d58d4b-4203-4fc2-b36f-32e6231c4339','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('26e2d1ad-130f-4794-83e9-82b341644cc9','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('27033804-17b9-4aed-9d27-e6b31d2ada80','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('8c34f0b8-4201-49b4-95a2-d043e99a3eef','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('c0bf0c64-6254-40a7-b810-8717977759dd','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('6c795b3b-d59d-4667-b79e-8a2e27e0c283','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('203a0228-7a63-4a6a-b26d-fa45ba139472','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('ac558ee8-ecae-47b6-a25e-46307521b4af','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('b96758c6-2ea0-4698-8886-d574d34e366d','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('7a76712a-38cd-41de-b260-cd0127284f16','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('6c14655c-5643-4f0e-8950-a53f60394bf7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('458a60ba-a235-4b36-80bb-8b537375a4ff','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('da75c207-bb23-477e-b3c0-7c462394b570','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('85d27350-e1b6-45b8-aee3-509ca88c5af4','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('cf68a5cd-f375-4296-8a87-1828d903baea','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('3342ae40-cc86-43e5-8581-3237b6aa8f08','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('36171e41-704b-4bf9-b300-755afe4ee06f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
  ('85f785f3-08c3-4d80-ba9a-96b81be758c0','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('41945b74-325e-4fa2-9cc9-edd11ead9ed3','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('122f1897-2dae-4f21-bee0-1c02c95e9e3a','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('7bf73fb2-1b31-412e-913d-835bfd3e326d','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('c7e94dda-1862-40fe-bda5-5fa2fe68f536','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('184ffdfb-7026-4d65-8916-3bc31bf14d2a','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('317698c6-2ae7-4f7f-ab39-bb3811ed50f3','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('81dfcf88-c739-4461-9d16-931f8d51a8c5','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('d40a0eda-36fc-4032-8382-20c76a36d6a6','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('ee4081d5-fc3e-4a8c-b39e-481ae20135d5','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('e30ddde5-a722-477b-837b-056fdc7e2d6b','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('a0cb697c-3158-4680-8e70-c154c3a15cc4','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('6c795b3b-d59d-4667-b79e-8a2e27e0c283','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('b96758c6-2ea0-4698-8886-d574d34e366d','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('c7ee1c03-63d7-4107-b076-72b1f059b0f7','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
  ('dd08c9de-076d-40ee-ab27-9298bbb72d1a','abb99d95-cbb1-4617-8f8b-f220ef6028ca');

-- the 40 role-holders/candidates 1735 protected: their context must be untouched by this
CREATE TEMP TABLE joc_keep (pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO joc_keep VALUES
('d06e70b3-b63a-477e-8b3d-8fb7e656f30e','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('7f32a8a4-fac8-44d3-af71-01f40895f5ba','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('b5e19b59-9085-48e6-8f14-864b9c94699d','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('53fd1ed7-b8f2-4c0b-a973-3592e4457472','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('839199d0-669b-45bc-aa8e-2ba63d960b7b','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('47627948-d590-47a4-9c7f-dd135043035f','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
('0f6484bd-2fc1-4071-9648-d7b8a950d29c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('602f147a-90bc-4083-aeab-1d0becf088e9','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('969f1ca4-4766-44fd-8638-ef813b1835e7','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('769374f9-6f4a-428f-ac54-6e1f996ee487','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('0d81c306-514e-455c-988e-b0d04f7e0897','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('3f90952e-7d1b-413d-a0e1-e319fb23fa05','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('eef42ac4-5573-47c7-8b41-f2f1e0769aec','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('6b16270a-c6c7-46be-9b9c-7def323dc4ef','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('6cd2e87b-7366-429a-a049-990751bd647f','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('974cd2b6-8dd2-4794-aded-88c6ebc38a30','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('7157dd95-0f1b-4e05-bd4f-39317345b47c','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('83474f06-c501-416d-a870-65d75f0cec9d','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('068393be-9502-44e6-a36f-2fa99cb9a3e8','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('77256186-0ce8-4069-9d06-1d2fd5b4b622','7bad33eb-e93e-4d94-8822-97212d49bde5'),
('0f6484bd-2fc1-4071-9648-d7b8a950d29c','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('602f147a-90bc-4083-aeab-1d0becf088e9','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('00bcdb0e-8bf2-4997-9642-ed3d14a2a5f8','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('969f1ca4-4766-44fd-8638-ef813b1835e7','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('0157dc45-31ae-4fc0-855d-0ac56b299fb2','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('86c12b33-cb76-41da-bdf0-6b58a0cbbed6','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('2c36a446-6766-483c-b043-73bb5244eabb','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('0d81c306-514e-455c-988e-b0d04f7e0897','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('3f90952e-7d1b-413d-a0e1-e319fb23fa05','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('a8a4a392-37c8-470a-a389-889f4f41911e','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('eef42ac4-5573-47c7-8b41-f2f1e0769aec','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('6b16270a-c6c7-46be-9b9c-7def323dc4ef','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('6cd2e87b-7366-429a-a049-990751bd647f','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('7157dd95-0f1b-4e05-bd4f-39317345b47c','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('83474f06-c501-416d-a870-65d75f0cec9d','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('068393be-9502-44e6-a36f-2fa99cb9a3e8','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
('77256186-0ce8-4069-9d06-1d2fd5b4b622','abb99d95-cbb1-4617-8f8b-f220ef6028ca');

-- Fail fast if the world moved since capture.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM joc_target;
  IF n <> 119 THEN RAISE EXCEPTION 'pre-check: target is % rows, expected 119', n; END IF;

  -- every target must still exist as context...
  SELECT count(*) INTO n FROM joc_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=t.pid AND c.topic_id=t.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target row(s) no longer exist', n; END IF;

  -- ...and must still be ORPHANS. If someone answered one of these since capture, deleting its
  -- context would create an ANSWER_WITHOUT_CONTEXT violation, which is zero-tolerance.
  SELECT count(*) INTO n FROM joc_target t
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id=t.pid AND a.topic_id=t.tid);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target row(s) acquired an answer since capture', n; END IF;

  SELECT count(*) INTO n FROM joc_target t JOIN joc_keep k ON k.pid=t.pid AND k.tid=t.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % row(s) are in BOTH lists', n; END IF;
END $$;

DELETE FROM inform.politician_context c USING joc_target t
WHERE c.politician_id = t.pid AND c.topic_id = t.tid;

-- Guard 1: exactly 119 context rows gone, and NOT ONE answer touched.
DO $$
DECLARE ctx_after int; ans_after int; s record;
BEGIN
  SELECT * INTO s FROM joc_snap;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> s.ctx_before - 119 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected -119', s.ctx_before, ctx_after; END IF;
  IF ans_after <> s.ans_before THEN
    RAISE EXCEPTION 'guard 1: answers moved % -> %', s.ans_before, ans_after; END IF;
END $$;

-- Guard 2: the 40 protected rows still have BOTH their answer and their context. Checked by explicit
-- id rather than by re-running the delete's predicate -- a guard that re-derives what it is guarding
-- is verification that isn't. (1735's own lesson, kept.)
DO $$
DECLARE lost_ctx int; lost_ans int;
BEGIN
  SELECT count(*) INTO lost_ctx FROM joc_keep k
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=k.pid AND c.topic_id=k.tid);
  IF lost_ctx > 0 THEN RAISE EXCEPTION 'guard 2: % protected row(s) lost context', lost_ctx; END IF;
  SELECT count(*) INTO lost_ans FROM joc_keep k
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=k.pid AND a.topic_id=k.tid);
  IF lost_ans > 0 THEN RAISE EXCEPTION 'guard 2: % protected row(s) lost their answer', lost_ans; END IF;
END $$;

-- Guard 3: no gate-visible orphan remains on any role-scoped judicial ladder, and no answer anywhere
-- lost its context. The second half is the zero-tolerance check the gate runs; asserting it here means
-- a mistake fails inside the transaction instead of in CI.
DO $$
DECLARE left_over int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO left_over
    FROM inform.politician_context pc
    JOIN inform.compass_topics t ON t.id = pc.topic_id AND t.judicial_role IS NOT NULL
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF left_over <> 0 THEN RAISE EXCEPTION 'guard 3: % judicial orphan(s) remain', left_over; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) now have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'judicial orphan context: 119 deleted, 40 protected rows intact, 0 judicial orphans left';
END $$;

COMMIT;
