-- 1699_tx_legislature_headshots.sql
--
-- Portraits for the 158 seated Texas legislators who had researched stances on a live
-- Essentials profile but no renderable image — the largest single jurisdiction block in
-- backend/data/headshot-backlog-2026-08-11.csv (135 TX House + 23 TX Senate, 1,432 stances).
--
-- Source: the official chamber rosters, keyed by DISTRICT and cross-checked on last and
-- first name (house.texas.gov/members/<n>, senate.texas.gov/member.php?d=<n>). Two rows are
-- Ballotpedia instead, because the official file was unusable and a contact-sheet review
-- caught it — neither is detectable from the filename or the alt text:
--   HD-111 Yvonne Davis — house.texas.gov serves a literal "No Photo Available" graphic.
--   HD-71  Stan Lambert — the official file has a black ellipse stroked across the photo.
-- Both were re-verified against district and tenure before substitution.
--
-- EXCLUDED: SD-22 Brian Birdwell. He resigned 2026-05-26 (Assistant Secretary of War for
-- Sustainment) and the Senate directory now shows that district as "Constituent Services",
-- but essentials still has him on an open term. That is an occupancy defect, not a missing
-- portrait, and it is deliberately NOT fixed here.
--
-- Images are already mirrored to storage as politician_photos/<pid>-headshot.jpg (600x750,
-- 4:5, top-anchored) and every one was read back through the public CDN before this ran.
--
-- Sets BOTH photo_custom_url and photo_origin_url on purpose. The read path is
-- COALESCE(photo_custom_url, photo_origin_url, '') — writing only the origin (a source PAGE,
-- not an image) makes the portrait render broken. That is the defect migration 1475 Part B
-- had to repair for 48 Wisconsin profiles.
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _tx_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _tx_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('0f8b9952-c966-415a-bb5a-35a95430e80b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0f8b9952-c966-415a-bb5a-35a95430e80b-headshot.jpg', 'https://house.texas.gov/members/1', 'press_use'),
  ('015a74ba-4e2b-4c79-b9bd-271ea9b7230c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/015a74ba-4e2b-4c79-b9bd-271ea9b7230c-headshot.jpg', 'https://house.texas.gov/members/3', 'press_use'),
  ('b5f2f8c9-13ab-4e15-82dd-dbecb6466084'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b5f2f8c9-13ab-4e15-82dd-dbecb6466084-headshot.jpg', 'https://house.texas.gov/members/4', 'press_use'),
  ('cb331eaa-fe08-4692-b92c-c3d303a426aa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cb331eaa-fe08-4692-b92c-c3d303a426aa-headshot.jpg', 'https://house.texas.gov/members/5', 'press_use'),
  ('687ba2dd-c179-4ac6-abb2-3a5ac7ed43bb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/687ba2dd-c179-4ac6-abb2-3a5ac7ed43bb-headshot.jpg', 'https://house.texas.gov/members/6', 'press_use'),
  ('b10ab09a-0945-4ee7-a78c-a25288a6f136'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b10ab09a-0945-4ee7-a78c-a25288a6f136-headshot.jpg', 'https://house.texas.gov/members/7', 'press_use'),
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c6dcdb47-9bbd-4c9b-9169-77e6082f17b1-headshot.jpg', 'https://house.texas.gov/members/8', 'press_use'),
  ('754cf14b-7282-46cb-a2d8-5aee3639f003'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/754cf14b-7282-46cb-a2d8-5aee3639f003-headshot.jpg', 'https://house.texas.gov/members/9', 'press_use'),
  ('1df6d2a2-8b75-43a9-9a05-b8caa9a65894'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1df6d2a2-8b75-43a9-9a05-b8caa9a65894-headshot.jpg', 'https://house.texas.gov/members/10', 'press_use'),
  ('e1b7592e-6f9a-411a-96c3-19f1ccc23435'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e1b7592e-6f9a-411a-96c3-19f1ccc23435-headshot.jpg', 'https://house.texas.gov/members/11', 'press_use'),
  ('81932e53-b3f3-436a-90bb-61df43447953'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81932e53-b3f3-436a-90bb-61df43447953-headshot.jpg', 'https://house.texas.gov/members/12', 'press_use'),
  ('9ced80ef-935e-47a3-ab6c-92f31e31e5e8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9ced80ef-935e-47a3-ab6c-92f31e31e5e8-headshot.jpg', 'https://house.texas.gov/members/13', 'press_use'),
  ('933d4df6-d2ac-4d2c-82b9-a7676bf2c269'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/933d4df6-d2ac-4d2c-82b9-a7676bf2c269-headshot.jpg', 'https://house.texas.gov/members/14', 'press_use'),
  ('9ce81b97-6e02-4bdb-b9dc-e2592d4ce87c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9ce81b97-6e02-4bdb-b9dc-e2592d4ce87c-headshot.jpg', 'https://house.texas.gov/members/16', 'press_use'),
  ('002f4446-75be-4860-935e-3cb65ce296fb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/002f4446-75be-4860-935e-3cb65ce296fb-headshot.jpg', 'https://house.texas.gov/members/17', 'press_use'),
  ('b36348f0-135f-4ea4-983d-70775f71e03e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b36348f0-135f-4ea4-983d-70775f71e03e-headshot.jpg', 'https://house.texas.gov/members/18', 'press_use'),
  ('c27708ad-8718-4b73-99c4-c3161c130462'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c27708ad-8718-4b73-99c4-c3161c130462-headshot.jpg', 'https://house.texas.gov/members/19', 'press_use'),
  ('56b91150-194f-4699-ba31-e944443eacae'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/56b91150-194f-4699-ba31-e944443eacae-headshot.jpg', 'https://house.texas.gov/members/20', 'press_use'),
  ('9974fbb8-10d1-452c-ae8e-a853dd3f7d37'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9974fbb8-10d1-452c-ae8e-a853dd3f7d37-headshot.jpg', 'https://house.texas.gov/members/21', 'press_use'),
  ('6d13d033-f970-4356-8cce-73d81f342dc8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d13d033-f970-4356-8cce-73d81f342dc8-headshot.jpg', 'https://house.texas.gov/members/22', 'press_use'),
  ('edbedc04-f48d-48b9-b229-1f10db22b4f6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/edbedc04-f48d-48b9-b229-1f10db22b4f6-headshot.jpg', 'https://house.texas.gov/members/23', 'press_use'),
  ('afdc1bdd-8975-4d9f-9071-ab5065450ea9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/afdc1bdd-8975-4d9f-9071-ab5065450ea9-headshot.jpg', 'https://house.texas.gov/members/24', 'press_use'),
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f3450e1-7b1c-4ca0-ae62-581bbc2cf606-headshot.jpg', 'https://house.texas.gov/members/25', 'press_use'),
  ('c0019789-2464-47bf-81a5-73fc2867a6c7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c0019789-2464-47bf-81a5-73fc2867a6c7-headshot.jpg', 'https://house.texas.gov/members/26', 'press_use'),
  ('2f16bdad-8486-48c7-94f2-cbe7ea6853c9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f16bdad-8486-48c7-94f2-cbe7ea6853c9-headshot.jpg', 'https://house.texas.gov/members/27', 'press_use'),
  ('1769fdb6-9c60-4c99-b08d-55cbe95bcedd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1769fdb6-9c60-4c99-b08d-55cbe95bcedd-headshot.jpg', 'https://house.texas.gov/members/28', 'press_use'),
  ('f6e50487-d839-479d-8efd-9937a09f9ab4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6e50487-d839-479d-8efd-9937a09f9ab4-headshot.jpg', 'https://house.texas.gov/members/29', 'press_use'),
  ('3c083452-8494-4c47-b6e8-327dc24584c7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c083452-8494-4c47-b6e8-327dc24584c7-headshot.jpg', 'https://house.texas.gov/members/30', 'press_use'),
  ('b6ea3b73-5664-462f-bc99-6c377418c34f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6ea3b73-5664-462f-bc99-6c377418c34f-headshot.jpg', 'https://house.texas.gov/members/31', 'press_use'),
  ('d66fb5fd-7b56-47a5-9762-e29b7403bb39'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d66fb5fd-7b56-47a5-9762-e29b7403bb39-headshot.jpg', 'https://house.texas.gov/members/32', 'press_use'),
  ('1d0242ba-f594-4764-b071-22cc86a7cc30'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d0242ba-f594-4764-b071-22cc86a7cc30-headshot.jpg', 'https://house.texas.gov/members/34', 'press_use'),
  ('2d3e3416-fb12-455b-9010-4185010fb3aa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2d3e3416-fb12-455b-9010-4185010fb3aa-headshot.jpg', 'https://house.texas.gov/members/35', 'press_use'),
  ('65bdba41-859d-41ba-bb25-65e8ba50f5ad'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/65bdba41-859d-41ba-bb25-65e8ba50f5ad-headshot.jpg', 'https://house.texas.gov/members/36', 'press_use'),
  ('df2b0dba-63d7-4f18-b713-7cc0594ec61d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df2b0dba-63d7-4f18-b713-7cc0594ec61d-headshot.jpg', 'https://house.texas.gov/members/37', 'press_use'),
  ('112dd21d-c4ea-4299-91a4-46508b74fdca'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/112dd21d-c4ea-4299-91a4-46508b74fdca-headshot.jpg', 'https://house.texas.gov/members/38', 'press_use'),
  ('d9486e4a-490a-4d87-a495-655cce9700e2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9486e4a-490a-4d87-a495-655cce9700e2-headshot.jpg', 'https://house.texas.gov/members/39', 'press_use'),
  ('02691090-c16c-4216-ac3b-1caa89a618a8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02691090-c16c-4216-ac3b-1caa89a618a8-headshot.jpg', 'https://house.texas.gov/members/40', 'press_use'),
  ('6577418b-49cc-4a03-a194-97020e0e8c9a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6577418b-49cc-4a03-a194-97020e0e8c9a-headshot.jpg', 'https://house.texas.gov/members/41', 'press_use'),
  ('76fb2373-43c5-4f18-9e0f-18da31e0f863'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76fb2373-43c5-4f18-9e0f-18da31e0f863-headshot.jpg', 'https://house.texas.gov/members/42', 'press_use'),
  ('e0a0c582-de13-4999-88fd-859a4dfba6c2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0a0c582-de13-4999-88fd-859a4dfba6c2-headshot.jpg', 'https://house.texas.gov/members/43', 'press_use'),
  ('c4e1ab3e-27b2-4531-987e-11958d0c23c4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c4e1ab3e-27b2-4531-987e-11958d0c23c4-headshot.jpg', 'https://house.texas.gov/members/44', 'press_use'),
  ('17648ed7-5a6a-4ac1-b49e-0d3eaf08417e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/17648ed7-5a6a-4ac1-b49e-0d3eaf08417e-headshot.jpg', 'https://house.texas.gov/members/45', 'press_use'),
  ('712486e7-0730-4c6c-866e-2b8ce458d1bb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/712486e7-0730-4c6c-866e-2b8ce458d1bb-headshot.jpg', 'https://house.texas.gov/members/46', 'press_use'),
  ('f39b0865-c923-428a-b940-09138c09e4e8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f39b0865-c923-428a-b940-09138c09e4e8-headshot.jpg', 'https://house.texas.gov/members/47', 'press_use'),
  ('92dbc7a4-34e5-4da3-8d75-133752cb7268'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/92dbc7a4-34e5-4da3-8d75-133752cb7268-headshot.jpg', 'https://house.texas.gov/members/48', 'press_use'),
  ('bc67255e-e79d-4328-9775-a7ac7cd1efce'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bc67255e-e79d-4328-9775-a7ac7cd1efce-headshot.jpg', 'https://house.texas.gov/members/49', 'press_use'),
  ('6af34442-997a-4b8d-8c19-3ae65519fa38'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6af34442-997a-4b8d-8c19-3ae65519fa38-headshot.jpg', 'https://house.texas.gov/members/51', 'press_use'),
  ('9c6b89e7-f71a-4bf7-9a32-d611afe28cb8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c6b89e7-f71a-4bf7-9a32-d611afe28cb8-headshot.jpg', 'https://house.texas.gov/members/52', 'press_use'),
  ('8925add1-8c61-4d2d-92e8-4314df644187'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8925add1-8c61-4d2d-92e8-4314df644187-headshot.jpg', 'https://house.texas.gov/members/53', 'press_use'),
  ('d701afd5-c15c-48c4-8f16-54aa142a6769'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d701afd5-c15c-48c4-8f16-54aa142a6769-headshot.jpg', 'https://house.texas.gov/members/54', 'press_use'),
  ('82968d14-f39b-401d-821c-89825a9811ac'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/82968d14-f39b-401d-821c-89825a9811ac-headshot.jpg', 'https://house.texas.gov/members/55', 'press_use'),
  ('0fa291b4-7f6b-4004-8bb9-19a11b75ab26'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0fa291b4-7f6b-4004-8bb9-19a11b75ab26-headshot.jpg', 'https://house.texas.gov/members/56', 'press_use'),
  ('099c7880-e909-4874-a257-cc8ca54ca7bd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/099c7880-e909-4874-a257-cc8ca54ca7bd-headshot.jpg', 'https://house.texas.gov/members/57', 'press_use'),
  ('d9dbb8f1-c49a-4a95-8a53-8aaf34809ffe'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9dbb8f1-c49a-4a95-8a53-8aaf34809ffe-headshot.jpg', 'https://house.texas.gov/members/58', 'press_use'),
  ('ac161830-6b8a-479d-8ef4-c0eb3d93df83'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ac161830-6b8a-479d-8ef4-c0eb3d93df83-headshot.jpg', 'https://house.texas.gov/members/59', 'press_use'),
  ('ecf2b5c5-8686-4160-8f7d-a0090e5c4a47'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ecf2b5c5-8686-4160-8f7d-a0090e5c4a47-headshot.jpg', 'https://house.texas.gov/members/60', 'press_use'),
  ('586b4b4d-26f1-449c-90ba-55d4aec48066'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/586b4b4d-26f1-449c-90ba-55d4aec48066-headshot.jpg', 'https://house.texas.gov/members/63', 'press_use'),
  ('b266c38d-9763-48d4-bcba-7b44adf79ab9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b266c38d-9763-48d4-bcba-7b44adf79ab9-headshot.jpg', 'https://house.texas.gov/members/64', 'press_use'),
  ('2c5de636-b661-4b8f-8863-f10aa25e54ce'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c5de636-b661-4b8f-8863-f10aa25e54ce-headshot.jpg', 'https://house.texas.gov/members/68', 'press_use'),
  ('3b3da471-8c67-4ea5-bb5f-fa1b2c0ce095'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3b3da471-8c67-4ea5-bb5f-fa1b2c0ce095-headshot.jpg', 'https://house.texas.gov/members/69', 'press_use'),
  ('47cdb7af-9fff-487a-a6d1-23c66d21a414'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47cdb7af-9fff-487a-a6d1-23c66d21a414-headshot.jpg', 'https://ballotpedia.org/Stan_Lambert', 'press_use'),
  ('b01f30e9-0c17-4d59-af5f-a90c176b133d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b01f30e9-0c17-4d59-af5f-a90c176b133d-headshot.jpg', 'https://house.texas.gov/members/72', 'press_use'),
  ('42370d1a-2ffd-480b-a24f-b2a39405c929'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42370d1a-2ffd-480b-a24f-b2a39405c929-headshot.jpg', 'https://house.texas.gov/members/73', 'press_use'),
  ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/155a62d8-9e8e-4231-94dc-823b9f15b30b-headshot.jpg', 'https://house.texas.gov/members/74', 'press_use'),
  ('619ad301-d993-40b3-94fe-0eb956932dae'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/619ad301-d993-40b3-94fe-0eb956932dae-headshot.jpg', 'https://house.texas.gov/members/75', 'press_use'),
  ('96a7a21f-87c1-4a3c-b7ee-4caa30d8ff09'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/96a7a21f-87c1-4a3c-b7ee-4caa30d8ff09-headshot.jpg', 'https://house.texas.gov/members/76', 'press_use'),
  ('6bdea3fd-5a3f-4d43-a0cc-9f4c7373c269'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6bdea3fd-5a3f-4d43-a0cc-9f4c7373c269-headshot.jpg', 'https://house.texas.gov/members/77', 'press_use'),
  ('819c3c06-c958-4e98-bc60-da91e3fb5c24'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/819c3c06-c958-4e98-bc60-da91e3fb5c24-headshot.jpg', 'https://house.texas.gov/members/78', 'press_use'),
  ('d45bbf56-7e43-4932-b536-fd73173eb295'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d45bbf56-7e43-4932-b536-fd73173eb295-headshot.jpg', 'https://house.texas.gov/members/79', 'press_use'),
  ('481d7dae-0a6f-4e54-917c-72a2c6be6731'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/481d7dae-0a6f-4e54-917c-72a2c6be6731-headshot.jpg', 'https://house.texas.gov/members/80', 'press_use'),
  ('90d94c32-12a1-433a-8ab4-418cd2f05c01'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/90d94c32-12a1-433a-8ab4-418cd2f05c01-headshot.jpg', 'https://house.texas.gov/members/81', 'press_use'),
  ('44d86767-7041-4ce9-9d03-ce23dd663c95'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/44d86767-7041-4ce9-9d03-ce23dd663c95-headshot.jpg', 'https://house.texas.gov/members/82', 'press_use'),
  ('30063951-196d-4eea-a8da-4ac1702bd867'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/30063951-196d-4eea-a8da-4ac1702bd867-headshot.jpg', 'https://house.texas.gov/members/83', 'press_use'),
  ('21d1e18c-f192-4a1a-9dc0-36bd873a3daa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21d1e18c-f192-4a1a-9dc0-36bd873a3daa-headshot.jpg', 'https://house.texas.gov/members/84', 'press_use'),
  ('c41d17c7-ca70-4c7c-85d4-8e85e4288742'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c41d17c7-ca70-4c7c-85d4-8e85e4288742-headshot.jpg', 'https://house.texas.gov/members/85', 'press_use'),
  ('edad1d9c-b40b-407c-bdcc-af34e3f37413'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/edad1d9c-b40b-407c-bdcc-af34e3f37413-headshot.jpg', 'https://house.texas.gov/members/86', 'press_use'),
  ('0dc7e2da-505d-42b6-af05-a2105ce81379'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0dc7e2da-505d-42b6-af05-a2105ce81379-headshot.jpg', 'https://house.texas.gov/members/87', 'press_use'),
  ('7ee40e9b-00d6-45ca-870f-d7a1e4f5dc9e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7ee40e9b-00d6-45ca-870f-d7a1e4f5dc9e-headshot.jpg', 'https://house.texas.gov/members/88', 'press_use'),
  ('ff0ce995-51b0-42fd-ae1a-458062b0ce1f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff0ce995-51b0-42fd-ae1a-458062b0ce1f-headshot.jpg', 'https://house.texas.gov/members/90', 'press_use'),
  ('382d9814-389e-4205-b48c-67f3b9f7b332'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/382d9814-389e-4205-b48c-67f3b9f7b332-headshot.jpg', 'https://house.texas.gov/members/91', 'press_use'),
  ('32cd74d7-cd2a-4420-8e96-7f34c253dba6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/32cd74d7-cd2a-4420-8e96-7f34c253dba6-headshot.jpg', 'https://house.texas.gov/members/92', 'press_use'),
  ('14694bb4-489f-4223-9961-d899b51146a7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14694bb4-489f-4223-9961-d899b51146a7-headshot.jpg', 'https://house.texas.gov/members/93', 'press_use'),
  ('41e2f865-d56b-4999-9232-57473dea13ee'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41e2f865-d56b-4999-9232-57473dea13ee-headshot.jpg', 'https://house.texas.gov/members/95', 'press_use'),
  ('5249613b-40df-4458-830d-cdbb121961dc'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5249613b-40df-4458-830d-cdbb121961dc-headshot.jpg', 'https://house.texas.gov/members/96', 'press_use'),
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f920022b-4aa0-47ae-a5ae-c2edf3e17044-headshot.jpg', 'https://house.texas.gov/members/97', 'press_use'),
  ('b652c0bb-1dc5-4043-8a2e-9e12ea034dc8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b652c0bb-1dc5-4043-8a2e-9e12ea034dc8-headshot.jpg', 'https://house.texas.gov/members/98', 'press_use'),
  ('01d02684-5189-4b52-9d38-e7827b4d6b42'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01d02684-5189-4b52-9d38-e7827b4d6b42-headshot.jpg', 'https://house.texas.gov/members/99', 'press_use'),
  ('e8058f2b-c68a-474b-b9fe-df4d2d22545b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e8058f2b-c68a-474b-b9fe-df4d2d22545b-headshot.jpg', 'https://house.texas.gov/members/100', 'press_use'),
  ('625ec7a8-10b3-446d-a935-a8bee51e72fd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/625ec7a8-10b3-446d-a935-a8bee51e72fd-headshot.jpg', 'https://house.texas.gov/members/101', 'press_use'),
  ('bd563960-3aa8-4d4d-94cb-62b6c2ae0656'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd563960-3aa8-4d4d-94cb-62b6c2ae0656-headshot.jpg', 'https://house.texas.gov/members/102', 'press_use'),
  ('217dbd01-bbb3-45ef-afc3-a1a94a937583'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/217dbd01-bbb3-45ef-afc3-a1a94a937583-headshot.jpg', 'https://house.texas.gov/members/103', 'press_use'),
  ('e36f4bc1-4896-48cb-8ae7-39e1f742ace3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e36f4bc1-4896-48cb-8ae7-39e1f742ace3-headshot.jpg', 'https://house.texas.gov/members/104', 'press_use'),
  ('b9cb31c9-15e0-405d-a8a0-d64850bf0955'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9cb31c9-15e0-405d-a8a0-d64850bf0955-headshot.jpg', 'https://house.texas.gov/members/105', 'press_use'),
  ('08e96b22-0cdc-48bb-b94a-ef4c54491f98'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/08e96b22-0cdc-48bb-b94a-ef4c54491f98-headshot.jpg', 'https://house.texas.gov/members/107', 'press_use'),
  ('1c90dfec-8203-4c1c-9158-48b775862109'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c90dfec-8203-4c1c-9158-48b775862109-headshot.jpg', 'https://house.texas.gov/members/108', 'press_use'),
  ('37be7b0c-64a5-426d-be36-3272ffc9675b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/37be7b0c-64a5-426d-be36-3272ffc9675b-headshot.jpg', 'https://house.texas.gov/members/109', 'press_use'),
  ('43567dd1-db59-40af-928e-03708237eb98'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/43567dd1-db59-40af-928e-03708237eb98-headshot.jpg', 'https://house.texas.gov/members/110', 'press_use'),
  ('9634d62c-f6b1-45da-918e-33c9969cf6c9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9634d62c-f6b1-45da-918e-33c9969cf6c9-headshot.jpg', 'https://ballotpedia.org/Yvonne_Davis', 'press_use'),
  ('f4286f1f-dda7-4fe4-9473-455772f40fae'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f4286f1f-dda7-4fe4-9473-455772f40fae-headshot.jpg', 'https://house.texas.gov/members/113', 'press_use'),
  ('70920806-a146-4dc3-8cc7-4566f9caf903'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/70920806-a146-4dc3-8cc7-4566f9caf903-headshot.jpg', 'https://house.texas.gov/members/114', 'press_use'),
  ('d4eb0cfb-f7e4-4d07-b44b-a046e06108e5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d4eb0cfb-f7e4-4d07-b44b-a046e06108e5-headshot.jpg', 'https://house.texas.gov/members/116', 'press_use'),
  ('fd716f6e-aa75-4829-ae39-43e31516b3a5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd716f6e-aa75-4829-ae39-43e31516b3a5-headshot.jpg', 'https://house.texas.gov/members/117', 'press_use'),
  ('4001a833-a971-45ec-a625-cdb206d3c2ed'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4001a833-a971-45ec-a625-cdb206d3c2ed-headshot.jpg', 'https://house.texas.gov/members/118', 'press_use'),
  ('c1914284-9aee-44f4-8b7f-a833d8f392e7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1914284-9aee-44f4-8b7f-a833d8f392e7-headshot.jpg', 'https://house.texas.gov/members/119', 'press_use'),
  ('1a94bee0-7418-4b75-ba17-f3cf97d888aa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1a94bee0-7418-4b75-ba17-f3cf97d888aa-headshot.jpg', 'https://house.texas.gov/members/120', 'press_use'),
  ('786ac925-59d3-40e3-a9ce-b63a54f4caf4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/786ac925-59d3-40e3-a9ce-b63a54f4caf4-headshot.jpg', 'https://house.texas.gov/members/121', 'press_use'),
  ('207cb8e4-14f2-49e1-8786-9533dc9b9d31'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/207cb8e4-14f2-49e1-8786-9533dc9b9d31-headshot.jpg', 'https://house.texas.gov/members/122', 'press_use'),
  ('3a310d29-093f-417b-a23f-885aa3658b12'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3a310d29-093f-417b-a23f-885aa3658b12-headshot.jpg', 'https://house.texas.gov/members/123', 'press_use'),
  ('2824037c-8574-41f6-9fc9-a1342d32250b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2824037c-8574-41f6-9fc9-a1342d32250b-headshot.jpg', 'https://house.texas.gov/members/124', 'press_use'),
  ('a436b52d-8801-4588-b676-bd101bb2bdeb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a436b52d-8801-4588-b676-bd101bb2bdeb-headshot.jpg', 'https://house.texas.gov/members/125', 'press_use'),
  ('47101bc2-46a8-4412-b2b6-2347697ba2fe'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47101bc2-46a8-4412-b2b6-2347697ba2fe-headshot.jpg', 'https://house.texas.gov/members/126', 'press_use'),
  ('032bb339-c63b-4510-93e5-25e72c4f9632'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/032bb339-c63b-4510-93e5-25e72c4f9632-headshot.jpg', 'https://house.texas.gov/members/127', 'press_use'),
  ('9d6eae75-9400-46bf-a2f1-34de55db3d49'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9d6eae75-9400-46bf-a2f1-34de55db3d49-headshot.jpg', 'https://house.texas.gov/members/128', 'press_use'),
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a80b2deb-e005-4115-b5c0-2a050fa6a1ec-headshot.jpg', 'https://house.texas.gov/members/129', 'press_use'),
  ('8d339a48-dabd-424c-ac3c-e1e128b68bf8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8d339a48-dabd-424c-ac3c-e1e128b68bf8-headshot.jpg', 'https://house.texas.gov/members/130', 'press_use'),
  ('4750d905-2ccc-4eaf-9a69-f5f20ef8b18f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4750d905-2ccc-4eaf-9a69-f5f20ef8b18f-headshot.jpg', 'https://house.texas.gov/members/131', 'press_use'),
  ('83004c0d-69f2-4b8f-9089-1c5d1fd296cd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/83004c0d-69f2-4b8f-9089-1c5d1fd296cd-headshot.jpg', 'https://house.texas.gov/members/132', 'press_use'),
  ('6121f45c-3508-43a7-a36e-871901303d73'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6121f45c-3508-43a7-a36e-871901303d73-headshot.jpg', 'https://house.texas.gov/members/133', 'press_use'),
  ('136fc01b-f061-4e30-9aa7-d5735e0a4659'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/136fc01b-f061-4e30-9aa7-d5735e0a4659-headshot.jpg', 'https://house.texas.gov/members/134', 'press_use'),
  ('f5f63005-94a6-4170-b120-a421ea5a8f3b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f5f63005-94a6-4170-b120-a421ea5a8f3b-headshot.jpg', 'https://house.texas.gov/members/135', 'press_use'),
  ('2be64a58-ae2c-4eee-b80d-6e673ef774bd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2be64a58-ae2c-4eee-b80d-6e673ef774bd-headshot.jpg', 'https://house.texas.gov/members/136', 'press_use'),
  ('5b64f3b4-1ec1-4247-9ff3-9e7043be21d6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5b64f3b4-1ec1-4247-9ff3-9e7043be21d6-headshot.jpg', 'https://house.texas.gov/members/137', 'press_use'),
  ('02288122-6afb-46c4-ae9f-a712152b1a73'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02288122-6afb-46c4-ae9f-a712152b1a73-headshot.jpg', 'https://house.texas.gov/members/138', 'press_use'),
  ('60e2bada-4104-47af-b4d7-93662e401543'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/60e2bada-4104-47af-b4d7-93662e401543-headshot.jpg', 'https://house.texas.gov/members/139', 'press_use'),
  ('c456d802-e836-4208-8d18-33402c807429'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c456d802-e836-4208-8d18-33402c807429-headshot.jpg', 'https://house.texas.gov/members/140', 'press_use'),
  ('c783e709-2cef-460e-af1e-8b4f8e8339b0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c783e709-2cef-460e-af1e-8b4f8e8339b0-headshot.jpg', 'https://house.texas.gov/members/141', 'press_use'),
  ('9c972a56-0084-483d-a4f2-8b42a823e58a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c972a56-0084-483d-a4f2-8b42a823e58a-headshot.jpg', 'https://house.texas.gov/members/142', 'press_use'),
  ('f6570c10-effb-41e1-b559-ef9ca41a2bf1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6570c10-effb-41e1-b559-ef9ca41a2bf1-headshot.jpg', 'https://house.texas.gov/members/143', 'press_use'),
  ('50d759c2-05cc-4769-a1d9-69b282745d0d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/50d759c2-05cc-4769-a1d9-69b282745d0d-headshot.jpg', 'https://house.texas.gov/members/144', 'press_use'),
  ('b5e9a6f8-e768-402e-aff5-77dc22e68115'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b5e9a6f8-e768-402e-aff5-77dc22e68115-headshot.jpg', 'https://house.texas.gov/members/145', 'press_use'),
  ('d62f0017-3d27-43f0-8908-781f3c9e5050'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d62f0017-3d27-43f0-8908-781f3c9e5050-headshot.jpg', 'https://house.texas.gov/members/146', 'press_use'),
  ('67a194b0-2584-48c6-a431-7abb70c96288'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/67a194b0-2584-48c6-a431-7abb70c96288-headshot.jpg', 'https://house.texas.gov/members/147', 'press_use'),
  ('81d931a9-5906-4ff4-9ac8-15b49c4ae38a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81d931a9-5906-4ff4-9ac8-15b49c4ae38a-headshot.jpg', 'https://house.texas.gov/members/148', 'press_use'),
  ('25183d7a-9300-4065-8d42-941ae826ca91'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/25183d7a-9300-4065-8d42-941ae826ca91-headshot.jpg', 'https://house.texas.gov/members/149', 'press_use'),
  ('7c2c52a2-4047-4090-bc88-e543aaaeba50'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c2c52a2-4047-4090-bc88-e543aaaeba50-headshot.jpg', 'https://house.texas.gov/members/150', 'press_use'),
  ('1ea8b603-7f4d-40e5-b8c7-0ba19af17717'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ea8b603-7f4d-40e5-b8c7-0ba19af17717-headshot.jpg', 'https://senate.texas.gov/member.php?d=3', 'press_use'),
  ('ea7694f7-b2bb-4b53-8248-bae698545f24'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea7694f7-b2bb-4b53-8248-bae698545f24-headshot.jpg', 'https://senate.texas.gov/member.php?d=5', 'press_use'),
  ('6ed2b57e-4930-4099-8567-d5a6bf7b999f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ed2b57e-4930-4099-8567-d5a6bf7b999f-headshot.jpg', 'https://senate.texas.gov/member.php?d=6', 'press_use'),
  ('f7f56e38-194a-4cc5-8883-cba2a61a2a62'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f7f56e38-194a-4cc5-8883-cba2a61a2a62-headshot.jpg', 'https://senate.texas.gov/member.php?d=7', 'press_use'),
  ('490693bc-abac-4bcb-ab2d-5127c08952af'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/490693bc-abac-4bcb-ab2d-5127c08952af-headshot.jpg', 'https://senate.texas.gov/member.php?d=9', 'press_use'),
  ('457620ac-d32b-434f-ad00-d860a5615e6d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/457620ac-d32b-434f-ad00-d860a5615e6d-headshot.jpg', 'https://senate.texas.gov/member.php?d=10', 'press_use'),
  ('92169386-c7ca-4edb-8446-56b565ad8c02'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/92169386-c7ca-4edb-8446-56b565ad8c02-headshot.jpg', 'https://senate.texas.gov/member.php?d=11', 'press_use'),
  ('67a35228-1353-4044-90b2-cd8fcf48de7b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/67a35228-1353-4044-90b2-cd8fcf48de7b-headshot.jpg', 'https://senate.texas.gov/member.php?d=13', 'press_use'),
  ('2775a1c4-d7e5-45ce-9633-f1ad137c546a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2775a1c4-d7e5-45ce-9633-f1ad137c546a-headshot.jpg', 'https://senate.texas.gov/member.php?d=14', 'press_use'),
  ('e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9ae7dbc-e266-4d10-ad47-4cd63efc5d0d-headshot.jpg', 'https://senate.texas.gov/member.php?d=15', 'press_use'),
  ('0ad0ceaa-2aa7-477b-bafb-03e927fe81ff'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ad0ceaa-2aa7-477b-bafb-03e927fe81ff-headshot.jpg', 'https://senate.texas.gov/member.php?d=17', 'press_use'),
  ('2db78ab9-242e-46cd-ba95-5c504a2c8892'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2db78ab9-242e-46cd-ba95-5c504a2c8892-headshot.jpg', 'https://senate.texas.gov/member.php?d=18', 'press_use'),
  ('3aee54f8-89eb-425d-b850-19fff9f2c8ea'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3aee54f8-89eb-425d-b850-19fff9f2c8ea-headshot.jpg', 'https://senate.texas.gov/member.php?d=19', 'press_use'),
  ('6153ca04-6c12-4a04-b58b-5a6db1e92861'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6153ca04-6c12-4a04-b58b-5a6db1e92861-headshot.jpg', 'https://senate.texas.gov/member.php?d=20', 'press_use'),
  ('1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d0b1e50-5bd7-46f6-b9a9-6ca7cdfcebe6-headshot.jpg', 'https://senate.texas.gov/member.php?d=21', 'press_use'),
  ('1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ff93be4-a2d0-432b-af59-ef6ace1eb77b-headshot.jpg', 'https://senate.texas.gov/member.php?d=23', 'press_use'),
  ('29fcdf7e-e3e2-4463-b461-ffd7a34a8754'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/29fcdf7e-e3e2-4463-b461-ffd7a34a8754-headshot.jpg', 'https://senate.texas.gov/member.php?d=24', 'press_use'),
  ('02e74087-5a81-474b-9771-62451239007a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02e74087-5a81-474b-9771-62451239007a-headshot.jpg', 'https://senate.texas.gov/member.php?d=25', 'press_use'),
  ('ada67d5b-b7d5-4ab9-a751-59355715c3e1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ada67d5b-b7d5-4ab9-a751-59355715c3e1-headshot.jpg', 'https://senate.texas.gov/member.php?d=26', 'press_use'),
  ('0c6c482a-feba-45bc-821b-02769a810063'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0c6c482a-feba-45bc-821b-02769a810063-headshot.jpg', 'https://senate.texas.gov/member.php?d=27', 'press_use'),
  ('eb7ef2a7-d0bb-475e-b2de-d96e6931932c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb7ef2a7-d0bb-475e-b2de-d96e6931932c-headshot.jpg', 'https://senate.texas.gov/member.php?d=28', 'press_use'),
  ('32608fd7-5038-4474-bfa9-7392b5e0eb80'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/32608fd7-5038-4474-bfa9-7392b5e0eb80-headshot.jpg', 'https://senate.texas.gov/member.php?d=29', 'press_use'),
  ('183d6ca3-be06-4d4f-a727-103687f80e69'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/183d6ca3-be06-4d4f-a727-103687f80e69-headshot.jpg', 'https://senate.texas.gov/member.php?d=31', 'press_use');

-- Refuse to run against a shifted roster rather than seating a face on the wrong person.
DO $$
DECLARE n_missing int; n_override int;
BEGIN
  SELECT count(*) INTO n_missing
  FROM _tx_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % of 158 target politicians no longer exist', n_missing;
  END IF;

  -- mig 192 / D-08: a hand-picked portrait outranks anything a sweep produces.
  SELECT count(*) INTO n_override
  FROM _tx_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _tx_headshots t
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url
);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _tx_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

-- Post-verify: every target must end up renderable by the app's own predicate.
DO $$
DECLARE n_img int; n_custom int; n_renderable int; n_bad_origin int;
BEGIN
  SELECT count(*) INTO n_img
  FROM _tx_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 158 THEN
    RAISE EXCEPTION 'expected 158 politician_images rows, found %', n_img;
  END IF;

  SELECT count(*) INTO n_custom
  FROM _tx_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 158 THEN
    RAISE EXCEPTION 'expected 158 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts so this
  -- migration cannot disagree with the platform's own coverage numbers.
  SELECT count(*) INTO n_renderable
  FROM _tx_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_renderable < 158 THEN
    RAISE EXCEPTION 'only % of 158 satisfy HAS_RENDERABLE_PHOTO_SQL', n_renderable;
  END IF;

  -- photo_origin_url is a research scratchpad elsewhere in this table (mig 1688 cleaned
  -- 148 breadcrumbs out of it). Every value this migration writes must be a real URL.
  SELECT count(*) INTO n_bad_origin
  FROM _tx_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_origin_url NOT LIKE 'http%';
  IF n_bad_origin <> 0 THEN
    RAISE EXCEPTION '% origin url(s) are not http', n_bad_origin;
  END IF;

  RAISE NOTICE 'ok: 158 TX legislators renderable (% images, % custom urls)', n_img, n_custom;
END $$;

COMMIT;
