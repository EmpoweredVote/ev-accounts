-- 1647_tarrant_candidate_headshots_and_wrong_person_image_cleanup.sql
--
-- Two things, both from the 2026-08-09 headshot session, both touching essentials.politician_images:
--   (A) import 57 headshots for the Tarrant County 2026 ballot, and
--   (B) remove three WRONG-PERSON images found while auditing how those photos are sourced.
-- Already applied to production by direct MCP execution as `postgres`; this file is the replayable
-- record. Every statement is guarded on END STATE, so re-running is a no-op.
--
-- ── (A) TARRANT COUNTY BALLOT HEADSHOTS ────────────────────────────────────────────────────────
-- 60 candidates on the Nov 3 2026 Tarrant ballot had no image. 57 were sourced, cropped to
-- 600x750 (4:5, q90, face-proportional with eyes near the upper third) and uploaded to
-- storage/politician_photos/<politician_id>-headshot.jpg. Sources:
--   24 Ballotpedia infobox portraits · 17 Tarrant County GOP candidate directory
--    7 campaign websites            ·  4 Tarrant County official .gov pages
--    4 law-firm attorney bios       ·  1 branch.vote aggregator
-- Licences as stored: press_use=52, unknown=5.
-- `unknown` is deliberate and honest: law-firm bios and the aggregator publish no licence terms.
-- Operator reviewed all 57 in a contact sheet and approved on 2026-08-09.
--
-- 3 candidates remain WITHOUT an image on purpose -- Lesa Pamplin (Criminal Court 9), Brian Willett
-- (323rd), Andy Hsu (324th). The only images available are social-media profile photos, which are
-- excluded by policy. Do NOT "fix" these by scraping Facebook.
--
-- ── (B) WRONG-PERSON IMAGES (the reason this migration is not just an import) ───────────────────
-- Auditing the licences above surfaced images of the wrong human being:
--   * Mark Teixeira    (TX-21 candidate)  -- was the NEW YORK YANKEES first baseman, in uniform.
--   * Tommy Hanson     (IL-05 candidate)  -- was the ATLANTA BRAVES pitcher, jersey "HANSON 48".
--     The real candidate is Tom "Tommy" Hanson, an Illinois commercial real-estate broker.
--   * Alex Padilla     (U.S. Senator, CA) -- TWO of its three images were Alex Padilla the
--     INGLEWOOD CITY COUNCILMEMBER (a different man; City of Inglewood seal behind him), and
--     photo_origin_url pointed at cityofinglewood.org. The Senate portrait is kept.
-- Signal worth reusing: a Flickr/Commons licence (cc_by*, cc0) on a LOCAL or low-profile candidate
-- is a smell -- a famous namesake is the usual cause, and the photo is usually a sports/action shot,
-- which no genuine candidate portrait is. Storage objects are intentionally LEFT IN PLACE so each
-- delete is reversible by re-inserting the row.
--
-- ── SCOPE ──────────────────────────────────────────────────────────────────────────────────────
-- Storage-side work is NOT reproducible from SQL and is already applied: the 57 uploads, plus a
-- re-crop of Jillian Gilchrest (CT-01) whose stored file was rotated 90 degrees because the source
-- carried EXIF orientation 6 that the pipeline never applied, plus a swap of Morgan Oyler
-- (LA City Council D5) from Morgan Oyler (WASHINGTON) to Morgan Oyler (CALIFORNIA). Both kept their
-- existing object paths, so the url values below are unchanged and correct either way.
-- Sibling cleanups (duplicate rows, the Richland-Bean Blossom board) are in 1648.

BEGIN;

-- ── A1. image rows ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT v.pid, v.url, 'default', v.lic
  FROM (VALUES
    ('3ad048a3-29b7-4fba-8d1c-811b45b45c25'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3ad048a3-29b7-4fba-8d1c-811b45b45c25-headshot.jpg', 'press_use')  -- Lydia Bean,
    ('46df0e49-5dd6-4abf-84ce-e4d8e18757ea'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/46df0e49-5dd6-4abf-84ce-e4d8e18757ea-headshot.jpg', 'press_use')  -- Mary Louise Nicholson,
    ('4aec65f8-f729-4430-bc24-555b40762a14'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4aec65f8-f729-4430-bc24-555b40762a14-headshot.jpg', 'press_use')  -- Don Pierson,
    ('d6afdea6-0a39-4b43-be7d-d6f73811687b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d6afdea6-0a39-4b43-be7d-d6f73811687b-headshot.jpg', 'press_use')  -- Jennifer Rymell,
    ('196836ce-dc38-49f6-8d4a-62086364b76b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/196836ce-dc38-49f6-8d4a-62086364b76b-headshot.jpg', 'press_use')  -- Mike Hrabal,
    ('ba3e17b7-219a-4700-bb39-01e49998ad80'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ba3e17b7-219a-4700-bb39-01e49998ad80-headshot.jpg', 'press_use')  -- David Cook,
    ('547756b3-9c8a-4bf3-b565-476c1cff7359'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/547756b3-9c8a-4bf3-b565-476c1cff7359-headshot.jpg', 'press_use')  -- Trent Loftin,
    ('81650aae-6a55-4da1-b4e4-8b5df54d1305'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81650aae-6a55-4da1-b4e4-8b5df54d1305-headshot.jpg', 'press_use')  -- Carey Walker,
    ('4a1895f3-112e-4809-8fcc-10bdb213150d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a1895f3-112e-4809-8fcc-10bdb213150d-headshot.jpg', 'press_use')  -- Bob McCoy,
    ('5d186608-0ded-4b70-8ab4-b949235ab308'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d186608-0ded-4b70-8ab4-b949235ab308-headshot.jpg', 'press_use')  -- Deborah Nekhom,
    ('b64b9747-527a-4651-a08d-18344263b14e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b64b9747-527a-4651-a08d-18344263b14e-headshot.jpg', 'press_use')  -- Brad Clark,
    ('c7d0dc6c-89b0-40d5-b3b9-360550d3611b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7d0dc6c-89b0-40d5-b3b9-360550d3611b-headshot.jpg', 'press_use')  -- Julya Billhymer,
    ('30f408b4-676c-4cab-8749-03ae38e14b6a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/30f408b4-676c-4cab-8749-03ae38e14b6a-headshot.jpg', 'press_use')  -- Randi Hartin,
    ('4ae0e032-0c2e-413a-960e-7bf0dd568874'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4ae0e032-0c2e-413a-960e-7bf0dd568874-headshot.jpg', 'press_use')  -- Eric Starnes,
    ('978be8fa-5628-4f1a-b503-b865e16cf8d2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/978be8fa-5628-4f1a-b503-b865e16cf8d2-headshot.jpg', 'press_use')  -- Charles Vanover,
    ('d85d8995-8381-44a5-bc67-a0c2a51ff10d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d85d8995-8381-44a5-bc67-a0c2a51ff10d-headshot.jpg', 'press_use')  -- Brian Bolton,
    ('06c6f1e2-224d-4b68-878e-affcc605b181'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/06c6f1e2-224d-4b68-878e-affcc605b181-headshot.jpg', 'press_use')  -- Cindy Stormer,
    ('0adf4e68-6de3-4b84-a612-0d14c88d57f6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0adf4e68-6de3-4b84-a612-0d14c88d57f6-headshot.jpg', 'press_use')  -- Sherri Wagner,
    ('09c3a5cf-a890-4db1-918d-d866ce519aa8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/09c3a5cf-a890-4db1-918d-d866ce519aa8-headshot.jpg', 'press_use')  -- Douglas A. Allen,
    ('32f713e1-ca36-4cdc-b78d-6873bf0d602a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/32f713e1-ca36-4cdc-b78d-6873bf0d602a-headshot.jpg', 'press_use')  -- Andy Porter,
    ('7f59beb2-7f72-4006-8b56-deca5838748d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f59beb2-7f72-4006-8b56-deca5838748d-headshot.jpg', 'unknown')  -- John Brender,
    ('830a7632-65eb-4a53-8063-e344b59b8077'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/830a7632-65eb-4a53-8063-e344b59b8077-headshot.jpg', 'press_use')  -- Phil Sorrells,
    ('fcc3a9de-2a2e-47f6-a86d-a853e8a4ddf3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fcc3a9de-2a2e-47f6-a86d-a853e8a4ddf3-headshot.jpg', 'press_use')  -- Tiffany Burks,
    ('3fe3e2c2-fdb2-4b09-998b-20b0765fff47'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3fe3e2c2-fdb2-4b09-998b-20b0765fff47-headshot.jpg', 'press_use')  -- Nathan Smith,
    ('2f73b488-ae35-496d-b8d8-2a338cb89c62'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2f73b488-ae35-496d-b8d8-2a338cb89c62-headshot.jpg', 'press_use')  -- Thomas Wilder,
    ('f94a95f7-399d-43ab-96ba-5688d731d564'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f94a95f7-399d-43ab-96ba-5688d731d564-headshot.jpg', 'press_use')  -- Ricky Rodriguez,
    ('6e43a68e-fb2f-4980-a362-9e1febd774da'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6e43a68e-fb2f-4980-a362-9e1febd774da-headshot.jpg', 'press_use')  -- Celina Vasquez,
    ('b4f89c2f-729b-4cef-8a34-d40f77d83a0a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4f89c2f-729b-4cef-8a34-d40f77d83a0a-headshot.jpg', 'press_use')  -- Mary Tom Curnutt,
    ('e566886d-ea5e-443e-893c-d10a8c074ed5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e566886d-ea5e-443e-893c-d10a8c074ed5-headshot.jpg', 'press_use')  -- Bill Brandt,
    ('b3a736df-bef3-42dc-b506-5074ec3947ce'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b3a736df-bef3-42dc-b506-5074ec3947ce-headshot.jpg', 'press_use')  -- Christopher Gregory,
    ('eb6f4565-d93c-4605-9a92-b4fe76f52b57'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb6f4565-d93c-4605-9a92-b4fe76f52b57-headshot.jpg', 'press_use')  -- Rodney Lee,
    ('45980258-a826-4324-b56d-adccfb774df1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/45980258-a826-4324-b56d-adccfb774df1-headshot.jpg', 'press_use')  -- Sergio De Leon,
    ('eb5b2070-e8c5-4546-8b31-7ed9693bbbba'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb5b2070-e8c5-4546-8b31-7ed9693bbbba-headshot.jpg', 'press_use')  -- Jason Charbonnet,
    ('c1d2fd0a-45d6-4d59-aec8-5423d0075f12'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c1d2fd0a-45d6-4d59-aec8-5423d0075f12-headshot.jpg', 'press_use')  -- Kenneth Sanders,
    ('6ea1ac7b-3723-46ba-aae0-88fec3528d10'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6ea1ac7b-3723-46ba-aae0-88fec3528d10-headshot.jpg', 'press_use')  -- Paige Payne-Neal,
    ('2c5b9d6a-ee3e-4ff0-bc7a-7c858db52942'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c5b9d6a-ee3e-4ff0-bc7a-7c858db52942-headshot.jpg', 'press_use')  -- Lisa Woodard,
    ('3692c66b-b294-4911-8b58-79c9e4d5d1c2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3692c66b-b294-4911-8b58-79c9e4d5d1c2-headshot.jpg', 'press_use')  -- Patricia Burns,
    ('e5cc699f-7993-41b1-8dd2-76153af72442'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e5cc699f-7993-41b1-8dd2-76153af72442-headshot.jpg', 'press_use')  -- Brook Bell,
    ('05ed9788-8949-480c-bfaf-e6317fbac42e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/05ed9788-8949-480c-bfaf-e6317fbac42e-headshot.jpg', 'press_use')  -- John P. Chupp,
    ('9eaaa13a-786e-405e-9f99-aaf393a894f5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9eaaa13a-786e-405e-9f99-aaf393a894f5-headshot.jpg', 'press_use')  -- Leslie Barrows,
    ('fae0c1f4-abb0-42ac-9e2e-c45ad62fd79a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fae0c1f4-abb0-42ac-9e2e-c45ad62fd79a-headshot.jpg', 'press_use')  -- Lyndsay Newell,
    ('ce0a90c0-7363-4843-9a69-187ee3d25203'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce0a90c0-7363-4843-9a69-187ee3d25203-headshot.jpg', 'press_use')  -- Kenneth Newell,
    ('3050ed0b-0438-4749-b483-97b06f7f445e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3050ed0b-0438-4749-b483-97b06f7f445e-headshot.jpg', 'press_use')  -- Dusty Fillmore,
    ('df59784c-8952-4cfe-924e-3aa111aa07b1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/df59784c-8952-4cfe-924e-3aa111aa07b1-headshot.jpg', 'unknown')  -- Katherine Kim,
    ('056e183d-4e27-4fb9-8675-78b78f9ee831'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/056e183d-4e27-4fb9-8675-78b78f9ee831-headshot.jpg', 'press_use')  -- Amy Allin,
    ('5db9df0b-c1f0-4d10-9288-37cecaadf280'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5db9df0b-c1f0-4d10-9288-37cecaadf280-headshot.jpg', 'unknown')  -- Fred Howey,
    ('9c82c37b-f9fa-40ff-907b-512ace17398b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c82c37b-f9fa-40ff-907b-512ace17398b-headshot.jpg', 'press_use')  -- James Munford,
    ('490b4db5-664d-4395-b7ca-31196e095ade'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/490b4db5-664d-4395-b7ca-31196e095ade-headshot.jpg', 'press_use')  -- Alex Kim,
    ('f8d6268e-b23b-4b02-93e5-f46f0c49d28a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8d6268e-b23b-4b02-93e5-f46f0c49d28a-headshot.jpg', 'unknown')  -- Crystal Gayden,
    ('e4ed074e-4b01-42b7-a124-ba4a94d1073d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e4ed074e-4b01-42b7-a124-ba4a94d1073d-headshot.jpg', 'press_use')  -- Andy Griffin,
    ('12310f50-df5a-4c07-8e20-a9f3112190c5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/12310f50-df5a-4c07-8e20-a9f3112190c5-headshot.jpg', 'press_use')  -- Cynthia Terry,
    ('5fbc9768-20f9-434f-81c9-639d5b12b226'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5fbc9768-20f9-434f-81c9-639d5b12b226-headshot.jpg', 'press_use')  -- Marq Clayton,
    ('f6d5e2a8-15fa-4fa1-b8ea-360ba6707970'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6d5e2a8-15fa-4fa1-b8ea-360ba6707970-headshot.jpg', 'press_use')  -- Ryan Hill,
    ('53642560-37b6-47b3-b778-a2d5eb23c8ad'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/53642560-37b6-47b3-b778-a2d5eb23c8ad-headshot.jpg', 'press_use')  -- Julie Lugo,
    ('742adcbd-4d6e-4b5a-a4b2-0149e0db7359'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/742adcbd-4d6e-4b5a-a4b2-0149e0db7359-headshot.jpg', 'unknown')  -- Courtney Miller,
    ('eb0934db-f654-457f-940b-4d71751f3d5b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb0934db-f654-457f-940b-4d71751f3d5b-headshot.jpg', 'press_use')  -- Lee Sorrells,
    ('9db8a291-2710-4260-8f2b-364090e72e9e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9db8a291-2710-4260-8f2b-364090e72e9e-headshot.jpg', 'press_use')  -- Steven Jumes
  ) AS v(pid, url, lic)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = v.pid);

-- ── A2. provenance: the page the photo was found on ────────────────────────────────────────────
UPDATE essentials.politicians p
   SET photo_origin_url = v.origin
  FROM (VALUES
    ('3ad048a3-29b7-4fba-8d1c-811b45b45c25'::uuid, 'https://ballotpedia.org/Lydia_Bean')  -- Lydia Bean,
    ('46df0e49-5dd6-4abf-84ce-e4d8e18757ea'::uuid, 'https://tarrantgop.org/directory-candidates/listing/mary-louise-nicholson/')  -- Mary Louise Nicholson,
    ('4aec65f8-f729-4430-bc24-555b40762a14'::uuid, 'https://tarrantgop.org/directory-candidates/listing/don-pierson/')  -- Don Pierson,
    ('d6afdea6-0a39-4b43-be7d-d6f73811687b'::uuid, 'https://tarrantgop.org/directory-candidates/listing/jennifer-rymell/')  -- Jennifer Rymell,
    ('196836ce-dc38-49f6-8d4a-62086364b76b'::uuid, 'https://ballotpedia.org/Mike_Hrabal')  -- Mike Hrabal,
    ('ba3e17b7-219a-4700-bb39-01e49998ad80'::uuid, 'https://tarrantgop.org/directory-candidates/listing/david-cook/')  -- David Cook,
    ('547756b3-9c8a-4bf3-b565-476c1cff7359'::uuid, 'https://tarrantgop.org/directory-candidates/listing/trent-loftin/')  -- Trent Loftin,
    ('81650aae-6a55-4da1-b4e4-8b5df54d1305'::uuid, 'https://tarrantgop.org/directory-candidates/listing/carey-f-walker/')  -- Carey Walker,
    ('4a1895f3-112e-4809-8fcc-10bdb213150d'::uuid, 'https://ballotpedia.org/Bob_McCoy')  -- Bob McCoy,
    ('5d186608-0ded-4b70-8ab4-b949235ab308'::uuid, 'https://tarrantgop.org/directory-candidates/listing/deborah-nekhom/')  -- Deborah Nekhom,
    ('b64b9747-527a-4651-a08d-18344263b14e'::uuid, 'https://ballotpedia.org/Brad_Clark')  -- Brad Clark,
    ('c7d0dc6c-89b0-40d5-b3b9-360550d3611b'::uuid, 'https://ballotpedia.org/Julya_Billhymer')  -- Julya Billhymer,
    ('30f408b4-676c-4cab-8749-03ae38e14b6a'::uuid, 'https://ballotpedia.org/Randi_Hartin')  -- Randi Hartin,
    ('4ae0e032-0c2e-413a-960e-7bf0dd568874'::uuid, 'https://ballotpedia.org/Eric_Starnes')  -- Eric Starnes,
    ('978be8fa-5628-4f1a-b503-b865e16cf8d2'::uuid, 'https://ballotpedia.org/Charles_Vanover')  -- Charles Vanover,
    ('d85d8995-8381-44a5-bc67-a0c2a51ff10d'::uuid, 'https://ballotpedia.org/Brian_Bolton')  -- Brian Bolton,
    ('06c6f1e2-224d-4b68-878e-affcc605b181'::uuid, 'https://ballotpedia.org/Cindy_Stormer')  -- Cindy Stormer,
    ('0adf4e68-6de3-4b84-a612-0d14c88d57f6'::uuid, 'https://ballotpedia.org/Sherri_Wagner')  -- Sherri Wagner,
    ('09c3a5cf-a890-4db1-918d-d866ce519aa8'::uuid, 'https://www.judgedouglasallen.com/')  -- Douglas A. Allen,
    ('32f713e1-ca36-4cdc-b78d-6873bf0d602a'::uuid, 'https://tarrantgop.org/directory-candidates/listing/andy-porter/')  -- Andy Porter,
    ('7f59beb2-7f72-4006-8b56-deca5838748d'::uuid, 'https://www.branch.vote/races/2024-texas-general-election-tx-state-criminal-district-judge-tx-county-tarrant/candidates/john-t-brender')  -- John Brender,
    ('830a7632-65eb-4a53-8063-e344b59b8077'::uuid, 'https://tarrantgop.org/directory-candidates/listing/phil-sorrells/')  -- Phil Sorrells,
    ('fcc3a9de-2a2e-47f6-a86d-a853e8a4ddf3'::uuid, 'https://ballotpedia.org/Tiffany_Burks')  -- Tiffany Burks,
    ('3fe3e2c2-fdb2-4b09-998b-20b0765fff47'::uuid, 'https://ballotpedia.org/Nathan_Smith')  -- Nathan Smith,
    ('2f73b488-ae35-496d-b8d8-2a338cb89c62'::uuid, 'https://www.tarrantcountytx.gov/content/main/en/district-clerk/TarrantCountyDistrictClerk.html')  -- Thomas Wilder,
    ('f94a95f7-399d-43ab-96ba-5688d731d564'::uuid, 'https://www.rickyrodriguez.org/')  -- Ricky Rodriguez,
    ('6e43a68e-fb2f-4980-a362-9e1febd774da'::uuid, 'https://ballotpedia.org/Celina_Vasquez')  -- Celina Vasquez,
    ('b4f89c2f-729b-4cef-8a34-d40f77d83a0a'::uuid, 'https://ballotpedia.org/Mary_Tom_Curnutt')  -- Mary Tom Curnutt,
    ('e566886d-ea5e-443e-893c-d10a8c074ed5'::uuid, 'https://tarrantgop.org/directory-candidates/listing/willam-p-bill-brandt/')  -- Bill Brandt,
    ('b3a736df-bef3-42dc-b506-5074ec3947ce'::uuid, 'https://ballotpedia.org/Christopher_Gregory')  -- Christopher Gregory,
    ('eb6f4565-d93c-4605-9a92-b4fe76f52b57'::uuid, 'https://www.rodneyleeforjop.com/')  -- Rodney Lee,
    ('45980258-a826-4324-b56d-adccfb774df1'::uuid, 'https://www.tarrantcountytx.gov/en/justice-of-the-peace-courts/justice-5/about-us/judge-sergio-l-de-leon.html')  -- Sergio De Leon,
    ('eb5b2070-e8c5-4546-8b31-7ed9693bbbba'::uuid, 'https://tarrantgop.org/directory-candidates/listing/jason-charbonnet/')  -- Jason Charbonnet,
    ('c1d2fd0a-45d6-4d59-aec8-5423d0075f12'::uuid, 'https://ballotpedia.org/Kenneth_Sanders')  -- Kenneth Sanders,
    ('6ea1ac7b-3723-46ba-aae0-88fec3528d10'::uuid, 'https://ballotpedia.org/Paige_Payne-Neal')  -- Paige Payne-Neal,
    ('2c5b9d6a-ee3e-4ff0-bc7a-7c858db52942'::uuid, 'https://www.tarrantcountytx.gov/en/justice-of-the-peace-courts/justice-8.html')  -- Lisa Woodard,
    ('3692c66b-b294-4911-8b58-79c9e4d5d1c2'::uuid, 'https://ballotpedia.org/Patricia_Burns')  -- Patricia Burns,
    ('e5cc699f-7993-41b1-8dd2-76153af72442'::uuid, 'https://www.tarrantcountytx.gov/en/probate-courts/probate-court-2.html')  -- Brook Bell,
    ('05ed9788-8949-480c-bfaf-e6317fbac42e'::uuid, 'https://tarrantgop.org/directory-candidates/listing/john-p-chupp/')  -- John P. Chupp,
    ('9eaaa13a-786e-405e-9f99-aaf393a894f5'::uuid, 'https://ballotpedia.org/Leslie_Barrows')  -- Leslie Barrows,
    ('fae0c1f4-abb0-42ac-9e2e-c45ad62fd79a'::uuid, 'https://www.lyndsaynewellforjudge.com/about-lyndsay-newell')  -- Lyndsay Newell,
    ('ce0a90c0-7363-4843-9a69-187ee3d25203'::uuid, 'https://tarrantgop.org/directory-candidates/listing/kenneth-e-newell/')  -- Kenneth Newell,
    ('3050ed0b-0438-4749-b483-97b06f7f445e'::uuid, 'https://www.fillmoreforjudge.com/')  -- Dusty Fillmore,
    ('df59784c-8952-4cfe-924e-3aa111aa07b1'::uuid, 'https://www.katherinekimlaw.com/about')  -- Katherine Kim,
    ('056e183d-4e27-4fb9-8675-78b78f9ee831'::uuid, 'https://ballotpedia.org/Amy_Allin')  -- Amy Allin,
    ('5db9df0b-c1f0-4d10-9288-37cecaadf280'::uuid, 'https://www.dunhamlaw.com/attorneys/fred-howey-attorney/')  -- Fred Howey,
    ('9c82c37b-f9fa-40ff-907b-512ace17398b'::uuid, 'https://tarrantgop.org/directory-candidates/listing/james-b-munford/')  -- James Munford,
    ('490b4db5-664d-4395-b7ca-31196e095ade'::uuid, 'https://tarrantgop.org/directory-candidates/listing/alex-kim/')  -- Alex Kim,
    ('f8d6268e-b23b-4b02-93e5-f46f0c49d28a'::uuid, 'https://www.gaydenlaw.com/our-mission/')  -- Crystal Gayden,
    ('e4ed074e-4b01-42b7-a124-ba4a94d1073d'::uuid, 'https://ballotpedia.org/Andy_Griffin')  -- Andy Griffin,
    ('12310f50-df5a-4c07-8e20-a9f3112190c5'::uuid, 'https://tarrantgop.org/directory-candidates/listing/cynthia-terry/')  -- Cynthia Terry,
    ('5fbc9768-20f9-434f-81c9-639d5b12b226'::uuid, 'https://ballotpedia.org/Marq_Clayton')  -- Marq Clayton,
    ('f6d5e2a8-15fa-4fa1-b8ea-360ba6707970'::uuid, 'https://ballotpedia.org/Ryan_Hill')  -- Ryan Hill,
    ('53642560-37b6-47b3-b778-a2d5eb23c8ad'::uuid, 'https://tarrantgop.org/directory-candidates/listing/julie-lugo/')  -- Julie Lugo,
    ('742adcbd-4d6e-4b5a-a4b2-0149e0db7359'::uuid, 'https://comallawoffice.com/attorney-profile-2/')  -- Courtney Miller,
    ('eb0934db-f654-457f-940b-4d71751f3d5b'::uuid, 'https://sorrellsforjudge.com/')  -- Lee Sorrells,
    ('9db8a291-2710-4260-8f2b-364090e72e9e'::uuid, 'https://tarrantgop.org/directory-candidates/listing/steve-jumes/')  -- Steven Jumes
  ) AS v(pid, origin)
 WHERE p.id = v.pid AND p.photo_origin_url IS NULL;

-- ── B1. wrong-person images ────────────────────────────────────────────────────────────────────
DELETE FROM essentials.politician_images
 WHERE (politician_id, url) IN (
   -- Mark Teixeira (TX-21): Yankees first baseman
   ('c7699355-885b-475d-834a-1a945618e711'::uuid,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7699355-885b-475d-834a-1a945618e711-headshot.jpg'),
   -- Tommy Hanson (IL-05): Braves pitcher
   ('9d8a2eed-7ff3-46a9-af1b-56cac0418d7b'::uuid,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9d8a2eed-7ff3-46a9-af1b-56cac0418d7b-headshot.jpg'),
   -- Sen. Alex Padilla: two images of the Inglewood councilmember
   ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,
    'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/cities/inglewood/alex-padilla.jpg'),
   ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f-headshot.jpg')
 );

-- Senator's origin pointed at the Inglewood councilmember's city page; the Senate portrait that
-- remains has no established origin, so NULL is the honest value.
UPDATE essentials.politicians
   SET photo_origin_url = NULL
 WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
   AND photo_origin_url ILIKE '%cityofinglewood.org%';

-- ── B2. corrected provenance for the two storage-side repairs ──────────────────────────────────
UPDATE essentials.politicians
   SET photo_origin_url = 'https://commons.wikimedia.org/wiki/File:Jillian_Gilchrest.jpg'
 WHERE id = '0763fb1b-8704-42b6-a52f-5cfcbee46b49'::uuid
   AND photo_origin_url IS DISTINCT FROM 'https://commons.wikimedia.org/wiki/File:Jillian_Gilchrest.jpg';

-- Was the Ballotpedia DISAMBIGUATION page /Morgan_Oyler, which lists a California and a Washington
-- Morgan Oyler. A disambiguation-page origin means the importer never resolved a person.
UPDATE essentials.politicians
   SET photo_origin_url = 'https://ballotpedia.org/Morgan_Oyler_(California)'
 WHERE id = 'c22ed715-4d29-4e03-8885-543bf32b525e'::uuid
   AND photo_origin_url IS DISTINCT FROM 'https://ballotpedia.org/Morgan_Oyler_(California)';

UPDATE essentials.politician_images
   SET photo_license = 'press_use'
 WHERE politician_id = 'c22ed715-4d29-4e03-8885-543bf32b525e'::uuid
   AND photo_license IS DISTINCT FROM 'press_use';

-- ── B3. origin backfill for pre-existing TX U.S. House images ──────────────────────────────────
-- Identified by matching photo_license to the Commons LicenseShortName, then confirming visually.
-- Allred is the 117th Congress portrait (light-blue tie); the 116th and 118th both show a red tie.
UPDATE essentials.politicians p
   SET photo_origin_url = v.origin
  FROM (VALUES
    ('c4695cd1-c251-4c00-ab4e-b84a898b9661'::uuid, 'https://commons.wikimedia.org/wiki/File:Bobby_Pulido_(CROPPED).jpg'),
    ('cb77d554-e526-4282-a1bc-63cc58265cf1'::uuid, 'https://commons.wikimedia.org/wiki/File:Brandon_Herrera_2025.png'),
    ('62e446ff-7398-4d4a-9ab0-3484ff9244da'::uuid, 'https://commons.wikimedia.org/wiki/File:Frederick_Haynes_III_at_Calvary_Baptist_Church.png'),
    ('1154e2d5-41b8-444d-b8f0-d9957999d6e7'::uuid, 'https://commons.wikimedia.org/wiki/File:Colin_Allred,_official_portrait,_117th_Congress.jpg')
  ) AS v(pid, origin)
 WHERE p.id = v.pid AND p.photo_origin_url IS NULL;

-- ── VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_missing integer; v_dupe integer; v_nolic integer; v_bad integer;
BEGIN
  -- Exactly 4 candidates in this election (excluding U.S. Senate) may lack an image, and they are
  -- a KNOWN, NAMED set -- asserted by identity, not by count, so a new gap cannot hide behind the
  -- same number. Three are the documented no-usable-source cases; the fourth is Mark Teixeira,
  -- whose wrong-person image this migration deletes above. Note the cohort spans the whole TX
  -- statewide election, so US House candidates like Teixeira are inside it, not just Tarrant.
  SELECT count(*) INTO v_missing
    FROM (SELECT DISTINCT rc.politician_id
            FROM essentials.race_candidates rc
            JOIN essentials.races r ON r.id = rc.race_id
            JOIN essentials.elections e ON e.id = r.election_id
           WHERE e.name = 'TX 2026 Statewide General'
             AND r.position_name NOT ILIKE '%U.S. Senate%'
             AND rc.candidate_status = 'active') b
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                      WHERE pi.politician_id = b.politician_id)
     AND b.politician_id NOT IN (
           '2ace3238-c700-4ad7-9b0e-de1d19b85eee'::uuid,  -- Lesa Pamplin  (no usable source)
           '5085495e-4ea6-44db-9c98-75385cb15194'::uuid,  -- Brian Willett (no usable source)
           'f8c84458-0731-434f-8c4d-257b2dce705e'::uuid,  -- Andy Hsu      (no usable source)
           'c7699355-885b-475d-834a-1a945618e711'::uuid); -- Mark Teixeira (wrong-person image removed)
  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'Unexpected TX 2026 candidate(s) without an image: % beyond the 4 known cases', v_missing;
  END IF;

  SELECT count(*) INTO v_dupe FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
      JOIN essentials.race_candidates rc ON rc.politician_id = pi.politician_id
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.elections e ON e.id = r.election_id
     WHERE e.name = 'TX 2026 Statewide General'
     GROUP BY pi.politician_id HAVING count(*) > 1) d;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'Tarrant candidates with more than one image row: %', v_dupe;
  END IF;

  -- Scoped to THIS migration's cohort. A corpus-wide check would fail on 4 unrelated pre-existing
  -- rows (Todd Blanche, Markwayne Mullin, Karla Griego, Sherlett Hendy Newbill) that already carry
  -- a NULL photo_license and are outside TX 2026 -- a separate backlog, not this migration's.
  SELECT count(*) INTO v_nolic
    FROM essentials.politician_images pi
   WHERE pi.photo_license IS NULL
     AND pi.politician_id IN (
           SELECT DISTINCT rc.politician_id
             FROM essentials.race_candidates rc
             JOIN essentials.races r ON r.id = rc.race_id
             JOIN essentials.elections e ON e.id = r.election_id
            WHERE e.name = 'TX 2026 Statewide General'
              AND r.position_name NOT ILIKE '%U.S. Senate%'
              AND rc.candidate_status = 'active');
  IF v_nolic <> 0 THEN
    RAISE EXCEPTION '% TX 2026 candidate image rows have a NULL photo_license', v_nolic;
  END IF;

  -- the three wrong-person images must be gone
  SELECT count(*) INTO v_bad FROM essentials.politician_images
   WHERE politician_id IN ('c7699355-885b-475d-834a-1a945618e711'::uuid,
                           '9d8a2eed-7ff3-46a9-af1b-56cac0418d7b'::uuid)
      OR (politician_id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
          AND url ILIKE '%inglewood%');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'A known wrong-person image row still exists (% rows)', v_bad;
  END IF;

  -- the Senator keeps exactly one image
  IF (SELECT count(*) FROM essentials.politician_images
       WHERE politician_id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid) <> 1 THEN
    RAISE EXCEPTION 'Sen. Alex Padilla should have exactly 1 image row';
  END IF;
END $$;

COMMIT;
