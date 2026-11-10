-- CC_0384 — eleven published headshots were not photographs of a person, or not only one.
--
-- check-portrait-framing.mjs, run over all 9,481 published headshots on 2026-11-09, found 11
-- frames with a MANUFACTURED SURROUND: a disc or oval on a matte, a photograph letterboxed
-- inside a flat frame, or a mask burnt into the file. Every one of them had passed the face
-- gate, and two of them are STATE SEALS - the Great Seal of North Carolina and the State Seal
-- of Washington - which contain a portrait, so a face detector clears them honestly.
--
-- 🔴 ONE WAS ALREADY HALF-FIXED, AND THE HALF THAT WAS MISSING IS THE ONE THE GATE READS.
-- Steve Hobbs got a real portrait on 2026-10-19: it went into politician_images as
-- <id>-headshot-v2.jpg and photo_custom_url was never moved off <id>-headshot.jpg, the seal.
-- So the profile grid, which reads images[], showed the portrait, while the gate and the
-- backend scalar still had the seal. Three photo columns, and they can disagree pairwise.
--
-- 🔴 THE VALUES THIS MIGRATION OVERWRITES, recorded here because nothing else records them:
--
--   Bryn Heather Johnson  (7fc14acd-5763-4eef-9ff6-26c098469c06)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382968.png
--     photo_origin_url  https://www.draperutah.gov/media/ym3jbcdo/bryn-heather-johnson.png
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382968.png   licence sourced
--   Fred Lowry  (4d96a7dd-573d-4499-8ea5-be0738403b0a)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382970.png
--     photo_origin_url  https://www.draperutah.gov/media/yynjwdvj/fred-lowry.png
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382970.png   licence sourced
--   Jacquelynn Scheuman  (e78a1793-b0c0-4531-8f4e-90890199cf2d)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e78a1793-b0c0-4531-8f4e-90890199cf2d-headshot.jpg
--     photo_origin_url  https://www.allencounty.in.gov/directory.aspx
--     images[default]   https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e78a1793-b0c0-4531-8f4e-90890199cf2d-headshot.jpg   licence Allen directory
--   Jeff Jackson  (8e0122c2-8bcb-4114-87e6-faa72d5d5125)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg
--     photo_origin_url  NULL
--     images[default]   https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg   licence public_domain
--   Liz Feitl  (b3830ff1-3b9b-463a-bb7d-311bf1bf0168)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Liz-Feitl.png
--     photo_origin_url  NULL
--     images[default]   (no row)
--   Matt Holton  (42687b5a-95d2-4344-a471-2e71f23f56ef)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/389556.png
--     photo_origin_url  NULL
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/389556.png   licence sourced
--   Michael Green  (dc503cfa-4d0f-4412-8fee-5e6b715a2cd1)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382967.png
--     photo_origin_url  https://www.draperutah.gov/media/me5nesxr/mike-green.png
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382967.png   licence sourced
--   Mike Klein  (1cc730ef-cd4c-4633-a66b-3cb12e6d638d)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1cc730ef-cd4c-4633-a66b-3cb12e6d638d-headshot.jpg
--     photo_origin_url  https://ballotpedia.org/Florida%27s_3rd_Congressional_District_election,_2026
--     images[default]   https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1cc730ef-cd4c-4633-a66b-3cb12e6d638d-headshot.jpg   licence press_use
--   Patricia Cortez  (736fc53b-1778-4751-8002-5b42c2671ef1)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ddbc251f-fcd1-4790-aa56-d074c758b4b3/default.jpeg
--     photo_origin_url  NULL
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ddbc251f-fcd1-4790-aa56-d074c758b4b3/default.jpeg   licence scraped_no_license
--   Sarah Blackwell  (52f2ed4d-72dd-42e4-869d-886c925cd05e)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/370486.jpg
--     photo_origin_url  https://www.alpineut.gov/ImageRepository/Document?documentID=1351
--     images[default]   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/370486.jpg   licence sourced
--   Steve Hobbs  (87f17e16-15dc-47d7-889a-40ee329f17b7)
--     photo_custom_url  https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87f17e16-15dc-47d7-889a-40ee329f17b7-headshot.jpg
--     photo_origin_url  https://www.sos.wa.gov/secretary-state-steve-hobbs
--     images[default]   https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87f17e16-15dc-47d7-889a-40ee329f17b7-headshot-v2.jpg   licence press_use
--
-- 🔴 EVERY REPLACEMENT URL CARRIES ?v=20261110, AND THAT IS NOT DECORATION. x-upsert at the
-- same object path returns 200 while the public CDN goes on serving the OLD bytes with
-- cf-cache-status HIT; a request-side Cache-Control: no-cache does not shift it. A replacement
-- needs a new cache key. Each URL below was re-fetched after upload and its sha256 compared to
-- the local file: all eight matched, cf-cache-status MISS.
--
-- WHAT WAS DONE TO EACH, and why:
--   Jeff Jackson - the GREAT SEAL OF NORTH CAROLINA. Re-sourced.
--   Michael Green - an oval crop on black. Re-sourced.
--   Bryn Heather Johnson - an oval crop on black. Re-sourced.
--   Fred Lowry - an oval crop on black. Re-sourced.
--   Sarah Blackwell - pillarboxed — cream bands down both sides. Cropped.
--   Matt Holton - pillarboxed — white bands down both sides. Cropped.
--   Jacquelynn Scheuman - letterboxed inside a white frame on all four sides. Cropped.
--   Patricia Cortez - letterboxed inside a dark maroon frame. Cropped.
--   Steve Hobbs - the state seal. REPOINTED to the portrait already in the bucket; no upload.
--   Liz Feitl - a circular crop on white. BLANKED. Monroe County publishes every councillor as
--     a circle. Measured: the mask is a circle of radius 498 in a 1000x1000 frame and her crown
--     is at y=75, so a 4:5 window that stays inside it, clears her hair and keeps her face near
--     the middle is 279x349 - a 2.15x enlargement of a frame her face would overflow. A blank
--     beats a matte-cornered frame, and it puts her back in the needs-a-headshot queue.
--   Mike Klein - a black arched mask, burnt into a file already cropped to 600x750, so there is
--     nothing to crop back to. BLANKED, and his politician_images row DELETED rather than
--     blanked, because the grid reads images[] first and a row holding a bad URL is worse than
--     no row. His origin was a Ballotpedia election page recorded press_use - a claim
--     Ballotpedia cannot grant. He lost FL-3 on 2026-11-03 and holds no office.
--
-- The nine replacements were all measured off a grid labelled in original pixels, drawn back
-- onto the photograph, looked at, and then run through check-portrait-framing.mjs with its five
-- fixtures green: FRAMED none.
-- ⚠ NO FACE DETECTOR RAN. check-headshot-faces.py needs Python and there is none on the machine
-- that prepared this. Every frame was looked at; that is the only check behind them.

BEGIN;

-- Jeff Jackson — the GREAT SEAL OF NORTH CAROLINA
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://commons.wikimedia.org/wiki/File:Rep._Jeff_Jackson_-_118th_Congress.jpg'
 WHERE id = '8e0122c2-8bcb-4114-87e6-faa72d5d5125';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg?v=20261110', photo_license = 'public_domain'
 WHERE id = 'fd38c7dc-1679-4233-9f52-9e9c2e7988b3';

-- Michael Green — an oval crop on black
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc503cfa-4d0f-4412-8fee-5e6b715a2cd1-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://www.draperutah.gov/city-government/mayor-and-council/'
 WHERE id = 'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc503cfa-4d0f-4412-8fee-5e6b715a2cd1-headshot.jpg?v=20261110', photo_license = 'press_use'
 WHERE id = 'c2a53d7b-0a31-48f9-965d-97c02a7772be';

-- Bryn Heather Johnson — an oval crop on black
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7fc14acd-5763-4eef-9ff6-26c098469c06-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://www.draperutah.gov/city-government/mayor-and-council/'
 WHERE id = '7fc14acd-5763-4eef-9ff6-26c098469c06';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7fc14acd-5763-4eef-9ff6-26c098469c06-headshot.jpg?v=20261110', photo_license = 'press_use'
 WHERE id = 'fed79fdf-a062-4700-89c8-035b9734e594';

-- Fred Lowry — an oval crop on black
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4d96a7dd-573d-4499-8ea5-be0738403b0a-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://www.draperutah.gov/city-government/mayor-and-council/'
 WHERE id = '4d96a7dd-573d-4499-8ea5-be0738403b0a';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4d96a7dd-573d-4499-8ea5-be0738403b0a-headshot.jpg?v=20261110', photo_license = 'press_use'
 WHERE id = '382b507e-62ee-4d91-94a8-70bef7b1d187';

-- Sarah Blackwell — pillarboxed — cream bands down both sides
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/52f2ed4d-72dd-42e4-869d-886c925cd05e-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://www.alpineut.gov/ImageRepository/Document?documentID=1351'
 WHERE id = '52f2ed4d-72dd-42e4-869d-886c925cd05e';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/52f2ed4d-72dd-42e4-869d-886c925cd05e-headshot.jpg?v=20261110'
 WHERE id = '30b0a042-dc1c-4d4b-8927-730ad45475cc';

-- Matt Holton — pillarboxed — white bands down both sides
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42687b5a-95d2-4344-a471-2e71f23f56ef-headshot.jpg?v=20261110'
     , photo_origin_url = NULL
 WHERE id = '42687b5a-95d2-4344-a471-2e71f23f56ef';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/42687b5a-95d2-4344-a471-2e71f23f56ef-headshot.jpg?v=20261110'
 WHERE id = '3cf87cb0-627d-438e-b1ec-86a7969e1d9e';

-- Jacquelynn Scheuman — letterboxed inside a white frame on all four sides
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e78a1793-b0c0-4531-8f4e-90890199cf2d-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://www.allencounty.in.gov/m/directory'
 WHERE id = 'e78a1793-b0c0-4531-8f4e-90890199cf2d';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e78a1793-b0c0-4531-8f4e-90890199cf2d-headshot.jpg?v=20261110'
 WHERE id = 'e2882329-e4c5-4f08-9baa-46d83b31f3c7';

-- Patricia Cortez — letterboxed inside a dark maroon frame
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/736fc53b-1778-4751-8002-5b42c2671ef1-headshot.jpg?v=20261110'
     , photo_origin_url = 'https://covinaca.gov/our-city/government/city-council/'
 WHERE id = '736fc53b-1778-4751-8002-5b42c2671ef1';
UPDATE essentials.politician_images SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/736fc53b-1778-4751-8002-5b42c2671ef1-headshot.jpg?v=20261110'
 WHERE id = '0ef8ab07-97df-4c0b-98c7-6efbbc6ccaa4';

-- Steve Hobbs — the scalar still pointed at the seal while images[] already held the portrait.
UPDATE essentials.politicians SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87f17e16-15dc-47d7-889a-40ee329f17b7-headshot-v2.jpg'
 WHERE id = '87f17e16-15dc-47d7-889a-40ee329f17b7';

-- Liz Feitl — blanked. She has no politician_images row at all, only the scalar.
UPDATE essentials.politicians SET photo_custom_url = NULL, photo_origin_url = NULL
 WHERE id = 'b3830ff1-3b9b-463a-bb7d-311bf1bf0168';

-- Mike Klein — blanked, and the image ROW removed, not emptied.
DELETE FROM essentials.politician_images WHERE politician_id = '1cc730ef-cd4c-4633-a66b-3cb12e6d638d';
UPDATE essentials.politicians SET photo_custom_url = NULL, photo_origin_url = NULL
 WHERE id = '1cc730ef-cd4c-4633-a66b-3cb12e6d638d';

DO $$
DECLARE
  seated int; blanked int; stale int; orphan int; ballot int;
BEGIN
  -- 1. the nine that keep a picture: scalar and images[] agree, and both carry the new key.
  SELECT count(*) INTO seated
    FROM essentials.politicians p
    JOIN essentials.politician_images pi
      ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.id = ANY(ARRAY[
           '8e0122c2-8bcb-4114-87e6-faa72d5d5125',
           'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1',
           '7fc14acd-5763-4eef-9ff6-26c098469c06',
           '4d96a7dd-573d-4499-8ea5-be0738403b0a',
           '52f2ed4d-72dd-42e4-869d-886c925cd05e',
           '42687b5a-95d2-4344-a471-2e71f23f56ef',
           'e78a1793-b0c0-4531-8f4e-90890199cf2d',
           '736fc53b-1778-4751-8002-5b42c2671ef1',
           '87f17e16-15dc-47d7-889a-40ee329f17b7'
         ]::uuid[])
     AND p.photo_custom_url IS NOT NULL
     AND pi.url = p.photo_custom_url;
  IF seated <> 9 THEN
    RAISE EXCEPTION 'expected 9 rows with the scalar and images[] agreeing, found %', seated;
  END IF;

  -- 2. the two blanks really are blank, on BOTH surfaces.
  SELECT count(*) INTO blanked
    FROM essentials.politicians p
   WHERE p.id = ANY(ARRAY['b3830ff1-3b9b-463a-bb7d-311bf1bf0168','1cc730ef-cd4c-4633-a66b-3cb12e6d638d']::uuid[])
     AND p.photo_custom_url IS NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);
  IF blanked <> 2 THEN
    RAISE EXCEPTION 'expected 2 fully blanked rows, found %', blanked;
  END IF;

  -- 3. 🔴 NOT ONE OF THE ELEVEN STILL SERVES A FILE THIS MIGRATION REPLACED. Gating on the
  --    new value alone would pass while an old URL sat in the other column; this asks the
  --    opposite question, which is the one that was wrong for Hobbs for three weeks.
  SELECT count(*) INTO stale FROM (
    SELECT p.photo_custom_url AS u FROM essentials.politicians p WHERE p.id = ANY(ARRAY[
           '8e0122c2-8bcb-4114-87e6-faa72d5d5125',
           'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1',
           '7fc14acd-5763-4eef-9ff6-26c098469c06',
           '4d96a7dd-573d-4499-8ea5-be0738403b0a',
           '52f2ed4d-72dd-42e4-869d-886c925cd05e',
           '42687b5a-95d2-4344-a471-2e71f23f56ef',
           'e78a1793-b0c0-4531-8f4e-90890199cf2d',
           '736fc53b-1778-4751-8002-5b42c2671ef1',
           '87f17e16-15dc-47d7-889a-40ee329f17b7',
           'b3830ff1-3b9b-463a-bb7d-311bf1bf0168',
           '1cc730ef-cd4c-4633-a66b-3cb12e6d638d'
         ]::uuid[])
    UNION ALL
    SELECT pi.url FROM essentials.politician_images pi WHERE pi.politician_id = ANY(ARRAY[
           '8e0122c2-8bcb-4114-87e6-faa72d5d5125',
           'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1',
           '7fc14acd-5763-4eef-9ff6-26c098469c06',
           '4d96a7dd-573d-4499-8ea5-be0738403b0a',
           '52f2ed4d-72dd-42e4-869d-886c925cd05e',
           '42687b5a-95d2-4344-a471-2e71f23f56ef',
           'e78a1793-b0c0-4531-8f4e-90890199cf2d',
           '736fc53b-1778-4751-8002-5b42c2671ef1',
           '87f17e16-15dc-47d7-889a-40ee329f17b7',
           'b3830ff1-3b9b-463a-bb7d-311bf1bf0168',
           '1cc730ef-cd4c-4633-a66b-3cb12e6d638d'
         ]::uuid[])
  ) t WHERE t.u = ANY(ARRAY[
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382968.png',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382970.png',
           'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e78a1793-b0c0-4531-8f4e-90890199cf2d-headshot.jpg',
           'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e0122c2-8bcb-4114-87e6-faa72d5d5125-headshot.jpg',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/monroe_council/Liz-Feitl.png',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/389556.png',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/382967.png',
           'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1cc730ef-cd4c-4633-a66b-3cb12e6d638d-headshot.jpg',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ddbc251f-fcd1-4790-aa56-d074c758b4b3/default.jpeg',
           'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/ut/370486.jpg',
           'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87f17e16-15dc-47d7-889a-40ee329f17b7-headshot.jpg'
         ]);
  IF stale <> 0 THEN
    RAISE EXCEPTION '% column(s) still serve a file this migration replaced', stale;
  END IF;

  -- 4. nobody among the eleven is left with an images[] row and no scalar, or the reverse.
  SELECT count(*) INTO orphan
    FROM essentials.politicians p
   WHERE p.id = ANY(ARRAY[
           '8e0122c2-8bcb-4114-87e6-faa72d5d5125',
           'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1',
           '7fc14acd-5763-4eef-9ff6-26c098469c06',
           '4d96a7dd-573d-4499-8ea5-be0738403b0a',
           '52f2ed4d-72dd-42e4-869d-886c925cd05e',
           '42687b5a-95d2-4344-a471-2e71f23f56ef',
           'e78a1793-b0c0-4531-8f4e-90890199cf2d',
           '736fc53b-1778-4751-8002-5b42c2671ef1',
           '87f17e16-15dc-47d7-889a-40ee329f17b7',
           'b3830ff1-3b9b-463a-bb7d-311bf1bf0168',
           '1cc730ef-cd4c-4633-a66b-3cb12e6d638d'
         ]::uuid[])
     AND (p.photo_custom_url IS NOT NULL)
         <> EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id AND pi.type = 'default');
  IF orphan <> 0 THEN
    RAISE EXCEPTION '% of the eleven disagree between the scalar and images[]', orphan;
  END IF;

  -- 5. ⚠ THE THIRD COLUMN. race_candidates.photo_url outranks both of the above on every
  --    ballot page and nothing above would notice it. It is NULL for all eleven today; this
  --    fails loudly if that ever stops being true.
  SELECT count(*) INTO ballot
    FROM essentials.race_candidates rc
   WHERE rc.politician_id = ANY(ARRAY[
           '8e0122c2-8bcb-4114-87e6-faa72d5d5125',
           'dc503cfa-4d0f-4412-8fee-5e6b715a2cd1',
           '7fc14acd-5763-4eef-9ff6-26c098469c06',
           '4d96a7dd-573d-4499-8ea5-be0738403b0a',
           '52f2ed4d-72dd-42e4-869d-886c925cd05e',
           '42687b5a-95d2-4344-a471-2e71f23f56ef',
           'e78a1793-b0c0-4531-8f4e-90890199cf2d',
           '736fc53b-1778-4751-8002-5b42c2671ef1',
           '87f17e16-15dc-47d7-889a-40ee329f17b7',
           'b3830ff1-3b9b-463a-bb7d-311bf1bf0168',
           '1cc730ef-cd4c-4633-a66b-3cb12e6d638d'
         ]::uuid[])
     AND nullif(rc.photo_url, '') IS NOT NULL;
  IF ballot <> 0 THEN
    RAISE EXCEPTION '% ballot row(s) carry their own photo_url and would outrank this fix', ballot;
  END IF;

  RAISE NOTICE 'CC_0384 ok: 9 seated, 2 blanked, 0 stale urls, 0 column disagreements, 0 ballot overrides';
END $$;

COMMIT;
