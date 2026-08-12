-- 1706_utah_local_headshots.sql
--
-- Portraits for 76 of Utah's 166 seated county, municipal and school-board officials (46%).
-- All 166 are real officeholders — Utah has ZERO candidate contamination, confirmed against
-- essentials.politician_occupancy_evidence (migration 1702), unlike Indiana where 83% of the
-- listed backlog was campaign-finance discovery records.
--
-- By government: Provo School District 7, Summit County 7, Tooele School District 7, Weber School District 7, Cache School District 6, Cedar Hills 6, Eagle Mountain 6, Lindon 5, Park City School District 5, Box Elder County 4, Taylorsville 4, Davis County 3, Washington County 3, Weber County 3, Iron County 2, Springville 1.
--
-- METHOD, and why the number moved. Raw-HTML scraping plateaued at 39. The limiter was not the
-- sites having no photos — it was reading them wrong:
--   * Cache School District serves its board through 13 scripts with NO names in the markup.
--   * Several roster path guesses 404'd (Pleasant Grove /city-council among them).
--   * Most roster cards ship <img src="council-2.jpg"> with the name in an adjacent heading,
--     so filename/alt matching alone never sees it.
-- Rendering each page in a real browser, scrolling to trigger lazy-load, and pulling every
-- <img> together with ITS OWN CARD TEXT from the DOM took it from 39 to 72. Cedar Hills, Eagle
-- Mountain, Tooele School, Weber School and Park City went from zero to complete on that pass
-- alone. A further 4 came from Taylorsville, which 403s python-requests but answers Node's
-- fetch — a client-fingerprint difference, not a broken image, and those four are the best
-- sources in the wave at 900x1125.
--
-- Every match required BOTH surname and given name (nicknames allowed) inside the same roster
-- card, then a contact-sheet review. That review rejected 3 that had matched cleanly and passed
-- every size and aspect check: a signpost ICON (Salt Lake City), a GROUP PHOTO of the whole
-- council (Springville), and a "vote.utah.gov register online" GRAPHIC (Washington County).
-- Nothing but looking catches those.
--
-- Resolution was tested rather than assumed: 14 rows need a 4x or greater upscale, and the
-- larger originals do not exist. Iron County's Next.js /_next/image?w=256 and Park City's
-- Finalsite f_auto,q_auto both serve identical pixels when fetched raw — 217x163 and 143x215
-- ARE the published files.
--
-- Sets BOTH photo_custom_url and photo_origin_url: the read path is
-- COALESCE(photo_custom_url, photo_origin_url, ''), so writing only the origin — a source page,
-- not an image — renders the portrait broken (the defect mig 1475 Part B repaired).
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _ut_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _ut_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('092f3e8a-30a1-4ca8-8229-8bee0fa67e8c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/092f3e8a-30a1-4ca8-8229-8bee0fa67e8c-headshot.jpg', 'https://www.boxeldercountyut.gov/m/directory', 'press_use'),
  ('027e3d43-6e71-41d6-be87-a36f1f31740f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/027e3d43-6e71-41d6-be87-a36f1f31740f-headshot.jpg', 'https://www.boxeldercountyut.gov/m/directory', 'press_use'),
  ('b6084ce1-39d3-4147-bbbd-7c556bb7ab9b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6084ce1-39d3-4147-bbbd-7c556bb7ab9b-headshot.jpg', 'https://www.boxeldercountyut.gov/m/directory', 'press_use'),
  ('39b47b77-0040-42fe-bf7e-e0ca0e23b14f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/39b47b77-0040-42fe-bf7e-e0ca0e23b14f-headshot.jpg', 'https://www.boxeldercountyut.gov/m/directory', 'press_use'),
  ('f2c520a2-b4df-4ba9-8803-a2ee1e4ff367'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f2c520a2-b4df-4ba9-8803-a2ee1e4ff367-headshot.jpg', 'https://lindon.gov/m/directory', 'press_use'),
  ('bf0d8f88-09bd-470b-9afc-710616365f1c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bf0d8f88-09bd-470b-9afc-710616365f1c-headshot.jpg', 'https://lindon.gov/m/directory', 'press_use'),
  ('2aee4484-1fbc-4a10-b49a-acd0fbb5c753'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2aee4484-1fbc-4a10-b49a-acd0fbb5c753-headshot.jpg', 'https://lindon.gov/m/directory', 'press_use'),
  ('96f36f38-a65d-435b-a7df-fa4e40128ffb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/96f36f38-a65d-435b-a7df-fa4e40128ffb-headshot.jpg', 'https://lindon.gov/m/directory', 'press_use'),
  ('2e62cf4d-7cf3-4ccc-a7e2-1ddee71e7e92'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2e62cf4d-7cf3-4ccc-a7e2-1ddee71e7e92-headshot.jpg', 'https://lindon.gov/m/directory', 'press_use'),
  ('c094510c-c61a-48d0-8ecf-75507452939e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c094510c-c61a-48d0-8ecf-75507452939e-headshot.jpg', 'https://provo.edu/category/news/pcsd-school-board/', 'press_use'),
  ('cf3373d3-3694-4993-a3fb-723bb3402893'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cf3373d3-3694-4993-a3fb-723bb3402893-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('7c457a73-3e59-43cf-a88f-42cd6e104060'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c457a73-3e59-43cf-a88f-42cd6e104060-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('79b453e3-6a30-44e0-9309-ac0e17cb4a2f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/79b453e3-6a30-44e0-9309-ac0e17cb4a2f-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('cc5d770d-c298-43f3-992c-c66ec773cfcf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cc5d770d-c298-43f3-992c-c66ec773cfcf-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('df45ee8f-267b-4e97-9102-022c62d4311a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df45ee8f-267b-4e97-9102-022c62d4311a-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('7e25bb14-7369-469e-8e70-9efc9c8ff0da'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7e25bb14-7369-469e-8e70-9efc9c8ff0da-headshot.jpg', 'https://provo.edu/board-of-education/facility/', 'press_use'),
  ('e38caffd-005d-4988-a2b5-8c576e0d5a30'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e38caffd-005d-4988-a2b5-8c576e0d5a30-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('77a2f7d5-0eae-44e1-a97b-7f311dce68b1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/77a2f7d5-0eae-44e1-a97b-7f311dce68b1-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('44005127-887c-446b-ad0e-a9acc9808df1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/44005127-887c-446b-ad0e-a9acc9808df1-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('1c56208a-59f6-4760-ad76-013064a04aaf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c56208a-59f6-4760-ad76-013064a04aaf-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('b349e5d5-959b-4a42-8515-a00441bbf1f2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b349e5d5-959b-4a42-8515-a00441bbf1f2-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('39db406d-e044-43d3-ae4f-f2b0bceb8258'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/39db406d-e044-43d3-ae4f-f2b0bceb8258-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('b93271d9-bf9f-4016-a8f4-7b4a9904b087'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b93271d9-bf9f-4016-a8f4-7b4a9904b087-headshot.jpg', 'https://www.summitcountyutah.gov/m/directory', 'press_use'),
  ('1e099a11-9f5e-44e4-806f-d9b81204cfa1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e099a11-9f5e-44e4-806f-d9b81204cfa1-headshot.jpg', 'https://www.daviscountyutah.gov/commission/portfolio', 'press_use'),
  ('e0f84fbf-342d-48e9-be4f-d992635b5811'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e0f84fbf-342d-48e9-be4f-d992635b5811-headshot.jpg', 'https://www.daviscountyutah.gov/commission/portfolio', 'press_use'),
  ('c38af2d7-bc52-4f72-9cf6-2d5eb130335c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c38af2d7-bc52-4f72-9cf6-2d5eb130335c-headshot.jpg', 'https://www.daviscountyutah.gov/commission/portfolio', 'press_use'),
  ('a6b7b4e9-fda4-4993-9e6b-15d93ec8e179'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a6b7b4e9-fda4-4993-9e6b-15d93ec8e179-headshot.jpg', 'https://www.washco.utah.gov/departments/commission/', 'press_use'),
  ('b2646c87-5fb6-4a7f-b594-1bab05f7ea3a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b2646c87-5fb6-4a7f-b594-1bab05f7ea3a-headshot.jpg', 'https://www.washco.utah.gov/departments/commission/', 'press_use'),
  ('389cde57-2175-4f97-9285-5398dbe37e72'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/389cde57-2175-4f97-9285-5398dbe37e72-headshot.jpg', 'https://www.washco.utah.gov/departments/commission/', 'press_use'),
  ('f9e9df90-5234-4c23-8f70-39d6e812c14a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f9e9df90-5234-4c23-8f70-39d6e812c14a-headshot.jpg', 'https://www.webercountyutah.gov/County_Commission/', 'press_use'),
  ('4dc660bf-bdf7-402b-a79d-6e733ec87ffd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4dc660bf-bdf7-402b-a79d-6e733ec87ffd-headshot.jpg', 'https://www.webercountyutah.gov/County_Commission/', 'press_use'),
  ('855978c9-8966-4075-9570-39c34567c34a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/855978c9-8966-4075-9570-39c34567c34a-headshot.jpg', 'https://www.webercountyutah.gov/County_Commission/', 'press_use'),
  ('2ff775d1-91b3-411a-8eee-6b9f99f97e26'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2ff775d1-91b3-411a-8eee-6b9f99f97e26-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('7f7afe25-cb1f-4802-99f8-c8c3d655525d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f7afe25-cb1f-4802-99f8-c8c3d655525d-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('1049958f-c834-4215-b67f-0678f8c4c00a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1049958f-c834-4215-b67f-0678f8c4c00a-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('875fa306-b508-4248-8d43-c9c6db0d7898'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/875fa306-b508-4248-8d43-c9c6db0d7898-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('2131ad38-f988-4c0c-a860-74c9ab8b21b2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2131ad38-f988-4c0c-a860-74c9ab8b21b2-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('a2d3ea66-71fe-42db-bdd8-65c53e7efb29'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a2d3ea66-71fe-42db-bdd8-65c53e7efb29-headshot.jpg', 'https://www.ccsdut.org/board-of-education/board-members', 'press_use'),
  ('d1ef59fc-3597-4201-a614-a3d9a1acb312'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d1ef59fc-3597-4201-a614-a3d9a1acb312-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('d72908b7-8859-4303-8de8-bbed641e65a8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d72908b7-8859-4303-8de8-bbed641e65a8-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('ca729597-b121-4f6a-ac33-7d55632f92ca'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ca729597-b121-4f6a-ac33-7d55632f92ca-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('9503cd35-3d1a-4282-9139-df0b4a89efa7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9503cd35-3d1a-4282-9139-df0b4a89efa7-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('dfcf5f86-b056-4732-9f48-6e259f56919f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dfcf5f86-b056-4732-9f48-6e259f56919f-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('e96d79ea-0f4f-4a17-9a94-8fbefed6e5d5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e96d79ea-0f4f-4a17-9a94-8fbefed6e5d5-headshot.jpg', 'https://www.cedarhills.org/page/mayor-and-city-council', 'press_use'),
  ('0ced2c3b-ebe8-4717-bf0a-38e8d7da9032'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ced2c3b-ebe8-4717-bf0a-38e8d7da9032-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('a25acef2-46dc-4cac-a453-8c411c5a8be7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a25acef2-46dc-4cac-a453-8c411c5a8be7-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('9fa1e9f2-92a6-4d35-9ff7-7be86d41db0e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9fa1e9f2-92a6-4d35-9ff7-7be86d41db0e-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('fc5c7094-67d9-47f2-abcb-19d40470128d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc5c7094-67d9-47f2-abcb-19d40470128d-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('2c812d48-3f74-4ae6-bd7e-d51d63c63d1a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c812d48-3f74-4ae6-bd7e-d51d63c63d1a-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('e4ae63aa-3b66-4097-9bec-eb684725f6ee'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e4ae63aa-3b66-4097-9bec-eb684725f6ee-headshot.jpg', 'https://eaglemountain.gov/government/mayor-city-council/', 'press_use'),
  ('dbca5cc5-6b7d-4f91-9b74-3df94d8c6a34'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbca5cc5-6b7d-4f91-9b74-3df94d8c6a34-headshot.jpg', 'https://www.springvilleutah.gov/mayors-message/', 'press_use'),
  ('edd0e830-bc03-436e-a4e0-3052cab31090'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/edd0e830-bc03-436e-a4e0-3052cab31090-headshot.jpg', 'https://ironcountyut.gov/commission', 'press_use'),
  ('d8c40eb5-91a7-4a40-8f4c-dcfbe8f04c59'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d8c40eb5-91a7-4a40-8f4c-dcfbe8f04c59-headshot.jpg', 'https://ironcountyut.gov/commission', 'press_use'),
  ('06517f20-cdf8-4c43-b29a-8a450381ecf1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/06517f20-cdf8-4c43-b29a-8a450381ecf1-headshot.jpg', 'https://www.pcschools.us/board-of-education', 'press_use'),
  ('6e55d227-e400-4cdf-9675-ef23dcdeac2b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6e55d227-e400-4cdf-9675-ef23dcdeac2b-headshot.jpg', 'https://www.pcschools.us/board-of-education', 'press_use'),
  ('8a7f60cb-a44b-4795-9a66-d8f4d28bc629'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8a7f60cb-a44b-4795-9a66-d8f4d28bc629-headshot.jpg', 'https://www.pcschools.us/board-of-education', 'press_use'),
  ('36cacddf-aea6-4c2d-8aa1-57fb607c562a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/36cacddf-aea6-4c2d-8aa1-57fb607c562a-headshot.jpg', 'https://www.pcschools.us/board-of-education', 'press_use'),
  ('121b2453-2967-4e16-a7f4-b809a23dc33c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/121b2453-2967-4e16-a7f4-b809a23dc33c-headshot.jpg', 'https://www.pcschools.us/board-of-education', 'press_use'),
  ('898df74a-9917-4953-8d3e-dbce781033c0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/898df74a-9917-4953-8d3e-dbce781033c0-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('53d9032b-5093-4a1d-8961-6588945973c3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/53d9032b-5093-4a1d-8961-6588945973c3-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('85ef73fe-a511-409d-9e31-4553fd46e35e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/85ef73fe-a511-409d-9e31-4553fd46e35e-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('ef9042d2-3a7a-4422-8dfc-cdd71e8b07ff'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ef9042d2-3a7a-4422-8dfc-cdd71e8b07ff-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('be01836c-9c6b-4f69-9d9b-478e7edc7cb8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be01836c-9c6b-4f69-9d9b-478e7edc7cb8-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('d8f2a920-4b35-4b12-83ab-cc0d133d5b24'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d8f2a920-4b35-4b12-83ab-cc0d133d5b24-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('38a1b146-7ccd-4719-a4ee-4e4821632f74'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/38a1b146-7ccd-4719-a4ee-4e4821632f74-headshot.jpg', 'https://www.tooeleschools.org/board-of-education', 'press_use'),
  ('af65e96b-5ada-4d2f-84bd-65f5e027e659'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af65e96b-5ada-4d2f-84bd-65f5e027e659-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('f1a7a02b-0a73-44f2-bd60-4e2850e091e5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f1a7a02b-0a73-44f2-bd60-4e2850e091e5-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('9548e9ae-4762-4651-a864-2cae9f359ad2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9548e9ae-4762-4651-a864-2cae9f359ad2-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('64270b6a-8163-4a3e-9d7c-37d69c43e74e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/64270b6a-8163-4a3e-9d7c-37d69c43e74e-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('b93b1087-e304-4bbf-a57c-d2000682ef34'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b93b1087-e304-4bbf-a57c-d2000682ef34-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('9399f6ca-53a0-41ce-875f-0a9c19c8437c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9399f6ca-53a0-41ce-875f-0a9c19c8437c-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('ecb989f4-4d1a-46ae-a574-092be1740bfa'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ecb989f4-4d1a-46ae-a574-092be1740bfa-headshot.jpg', 'https://www.wsd.net/page/board-members', 'press_use'),
  ('97ed7300-768f-4a53-a77b-c32f9dac1a83'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/97ed7300-768f-4a53-a77b-c32f9dac1a83-headshot.jpg', 'https://www.taylorsvilleut.gov/government/elected-officials/council', 'press_use'),
  ('af7c2adf-cdd4-429b-baf6-9db30377f80c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af7c2adf-cdd4-429b-baf6-9db30377f80c-headshot.jpg', 'https://www.taylorsvilleut.gov/government/elected-officials/council', 'press_use'),
  ('b36eeeff-57c9-4cc7-9569-f899df9035b4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b36eeeff-57c9-4cc7-9569-f899df9035b4-headshot.jpg', 'https://www.taylorsvilleut.gov/government/elected-officials/council', 'press_use'),
  ('ddcefcb7-651c-45bc-b439-d0d34abe3a35'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ddcefcb7-651c-45bc-b439-d0d34abe3a35-headshot.jpg', 'https://www.taylorsvilleut.gov/government/elected-officials/council', 'press_use');

DO $$
DECLARE n_missing int; n_override int; n_placeholder int;
BEGIN
  SELECT count(*) INTO n_missing FROM _ut_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % target politicians no longer exist', n_missing;
  END IF;

  -- mig 192 / D-08: a hand-picked portrait outranks anything a sweep produces
  SELECT count(*) INTO n_override FROM _ut_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;

  -- never put a face on a discovered candidate
  SELECT count(DISTINCT t.politician_id) INTO n_placeholder
  FROM _ut_headshots t
  JOIN essentials.politician_occupancy_evidence e ON e.politician_id = t.politician_id
  WHERE e.is_placeholder_occupancy;
  IF n_placeholder <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are placeholder occupancies, not officeholders',
      n_placeholder;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _ut_headshots t
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _ut_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

DO $$
DECLARE n_img int; n_custom int; n_render int;
BEGIN
  SELECT count(*) INTO n_img FROM _ut_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 76 THEN RAISE EXCEPTION 'expected 76 image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _ut_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 76 THEN
    RAISE EXCEPTION 'expected 76 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts verbatim
  SELECT count(*) INTO n_render FROM _ut_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render < 76 THEN
    RAISE EXCEPTION 'only % of 76 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render;
  END IF;

  RAISE NOTICE 'ok: 76 Utah officials renderable';
END $$;

COMMIT;
