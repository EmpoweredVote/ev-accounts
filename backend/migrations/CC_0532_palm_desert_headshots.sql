-- CC_0532_palm_desert_headshots.sql
-- CC_0532: headshots for the five Palm Desert councilmembers created by CC_0531 (requires it applied first).
--
-- SOURCE. The city's own portraits on palmdesert.gov/government/city-council, read 2026-11-28 with headless Chrome. Each
-- image sits inside that member's own biography panel on the page: Evan Trubee showpublishedimage/360, Joe Pradetto 366,
-- Karina Moreno 368, Gina Nestande 362, Jan Harnik 364 -- all 700x700 PNG studio portraits.
-- Every file was looked at: colour, head and shoulders, no frame or disc. Processing (@napi-rs/canvas, JPEG q90,
-- nothing composited): centre crop 560x700 at (70,0) to 4:5, enlarged x1.07 to 600x750.
-- Uploaded as new objects politician_photos/<politician id>-headshot.jpg; each public copy re-downloaded byte-identical
-- (sha256 prefixes: Trubee 0b513bb2, Pradetto d306043e, Moreno 4f7e6ce3, Nestande d829f9d2, Harnik b2dde6b1).
-- Copies in backend/data/seed-palm-desert-2026/headshots/. John Greenwood (incoming D5, CC_0533) has none yet.
-- ⚠ check-portrait-framing.mjs / check-headshot-faces.py not run (no ffmpeg / Python here); by-eye review only.
-- OVERWRITTEN VALUES: none -- the five people were created by CC_0531 with no image row and NULL photo columns.
BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('27b019ff-125a-473c-9a64-40233ce81968','1fc652aa-4fdd-4ab5-8ab9-cfbaabc21784','be9feaa4-bfeb-404f-b721-14bc4648287a',
                '6b90bb1b-10f0-42ba-a9ff-be8e601585fe','0edc51b8-8c6b-4897-9b5c-a90587aad946');
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0532 precondition: expected the 5 people from CC_0531, found % (apply it first)', n; END IF;
END $$;

CREATE TEMP TABLE cc0532_new ON COMMIT DROP AS
SELECT v.img::uuid AS img_id, v.pid::uuid AS pid, v.name,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/' || v.pid || '-headshot.jpg' AS url
  FROM (VALUES
    ('dbec92e2-0c72-4deb-892e-c6aa74090ba5','27b019ff-125a-473c-9a64-40233ce81968','Evan Trubee'),
    ('73d4e560-438a-412a-aa43-5b8e8bf22916','1fc652aa-4fdd-4ab5-8ab9-cfbaabc21784','Joe Pradetto'),
    ('65412e73-fad7-45dd-bc87-f7312b0a5531','be9feaa4-bfeb-404f-b721-14bc4648287a','Karina Moreno'),
    ('35581c58-4b41-4a51-af7f-072e1201873c','6b90bb1b-10f0-42ba-a9ff-be8e601585fe','Gina Nestande'),
    ('36b7fe5f-b116-4c45-84b3-dc99f8c63ab4','0edc51b8-8c6b-4897-9b5c-a90587aad946','Jan Harnik')
  ) AS v(img, pid, name);

INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT n.img_id, n.pid, n.url, 'default',
       'City of Palm Desert official portrait (palmdesert.gov City Council page, read 2026-11-28); 700x700 original centre-cropped to 4:5 and enlarged x1.07 to 600x750, nothing composited. No rights statement found on the page. (CC_0532)'
  FROM cc0532_new n
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = n.pid);

UPDATE essentials.politicians p
   SET photo_custom_url = n.url, photo_origin_url = 'https://www.palmdesert.gov/government/city-council'
  FROM cc0532_new n
 WHERE p.id = n.pid AND p.photo_custom_url IS NULL AND p.photo_origin_url IS NULL;

DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(coalesce(p.full_name, n.name), ', ') INTO bad
    FROM cc0532_new n LEFT JOIN essentials.politicians p ON p.id = n.pid
   WHERE p.full_name IS DISTINCT FROM n.name
      OR (SELECT count(*) FROM essentials.politician_images i WHERE i.politician_id = n.pid AND i.id = n.img_id AND i.url = n.url) <> 1
      OR p.photo_custom_url IS DISTINCT FROM n.url
      OR p.photo_origin_url IS DISTINCT FROM 'https://www.palmdesert.gov/government/city-council';
  IF bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0532: image wiring wrong for: %', bad; END IF;
  RAISE NOTICE 'CC_0532 OK: 5 Palm Desert headshots wired';
END $$;

COMMIT;
