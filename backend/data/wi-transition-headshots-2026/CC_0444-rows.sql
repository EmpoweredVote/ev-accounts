  -- JoCasta Zamarripa — Secretary of State
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '4892ed26-cdcc-4c88-82a4-b673f0b43bc9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4892ed26-cdcc-4c88-82a4-b673f0b43bc9-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '4892ed26-cdcc-4c88-82a4-b673f0b43bc9' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4892ed26-cdcc-4c88-82a4-b673f0b43bc9-headshot.jpg', photo_origin_url = 'https://www.votejocasta.com/'
   WHERE id = '4892ed26-cdcc-4c88-82a4-b673f0b43bc9' AND photo_custom_url IS NULL;

  -- Daniel J. Bukiewicz — Assembly District 21
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'c8205f59-7eb8-444f-80e5-85911b9b99e7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c8205f59-7eb8-444f-80e5-85911b9b99e7-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'c8205f59-7eb8-444f-80e5-85911b9b99e7' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c8205f59-7eb8-444f-80e5-85911b9b99e7-headshot.jpg', photo_origin_url = 'https://www.danbukiewicz.com'
   WHERE id = 'c8205f59-7eb8-444f-80e5-85911b9b99e7' AND photo_custom_url IS NULL;

  -- Kevin Knoke — Assembly District 30
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbdf66f1-2673-4cd2-94cf-d92e45e616b1-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbdf66f1-2673-4cd2-94cf-d92e45e616b1-headshot.jpg', photo_origin_url = 'https://www.kevinknoke.com/'
   WHERE id = 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1' AND photo_custom_url IS NULL;

  -- Bill Oemichen — Assembly District 50
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '011bee3f-2a87-4590-893d-c6be616fa45a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/011bee3f-2a87-4590-893d-c6be616fa45a-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '011bee3f-2a87-4590-893d-c6be616fa45a' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/011bee3f-2a87-4590-893d-c6be616fa45a-headshot.jpg', photo_origin_url = 'https://www.billforwisconsinassembly.com'
   WHERE id = '011bee3f-2a87-4590-893d-c6be616fa45a' AND photo_custom_url IS NULL;

  -- Ben Gruber — Assembly District 51
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f383f2fd-77aa-4bad-a924-a0a14a5d0bff-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f383f2fd-77aa-4bad-a924-a0a14a5d0bff-headshot.jpg', photo_origin_url = 'https://www.ben-gruber.com/'
   WHERE id = 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff' AND photo_custom_url IS NULL;

  -- Becky Nichols — Assembly District 53
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'f42d0120-f51e-451c-b79e-2a7db2aec953', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f42d0120-f51e-451c-b79e-2a7db2aec953-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'f42d0120-f51e-451c-b79e-2a7db2aec953' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f42d0120-f51e-451c-b79e-2a7db2aec953-headshot.jpg', photo_origin_url = 'https://www.beckynicholsforassembly.com/'
   WHERE id = 'f42d0120-f51e-451c-b79e-2a7db2aec953' AND photo_custom_url IS NULL;

  -- Kevin Krentz — Assembly District 57
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '5241dedb-30c9-49cf-8d0c-f0daafc103f3', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5241dedb-30c9-49cf-8d0c-f0daafc103f3-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '5241dedb-30c9-49cf-8d0c-f0daafc103f3' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5241dedb-30c9-49cf-8d0c-f0daafc103f3-headshot.jpg', photo_origin_url = 'https://www.krentzforassembly.com/'
   WHERE id = '5241dedb-30c9-49cf-8d0c-f0daafc103f3' AND photo_custom_url IS NULL;

  -- Bernie Newman — Assembly District 58
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'b01540ed-5638-4f61-b066-17b27232f4e8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b01540ed-5638-4f61-b066-17b27232f4e8-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'b01540ed-5638-4f61-b066-17b27232f4e8' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b01540ed-5638-4f61-b066-17b27232f4e8-headshot.jpg', photo_origin_url = 'https://bernienewmanforwi.com/'
   WHERE id = 'b01540ed-5638-4f61-b066-17b27232f4e8' AND photo_custom_url IS NULL;

  -- Bryson Reyes — Assembly District 82
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'db04f75c-76a9-40dd-a742-e71071117f27', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db04f75c-76a9-40dd-a742-e71071117f27-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'db04f75c-76a9-40dd-a742-e71071117f27' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db04f75c-76a9-40dd-a742-e71071117f27-headshot.jpg', photo_origin_url = 'https://www.brysonforwisconsin.com/'
   WHERE id = 'db04f75c-76a9-40dd-a742-e71071117f27' AND photo_custom_url IS NULL;

  -- Brandy Tollefson — Assembly District 88
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'beb7d2dc-1db8-4025-9aa4-032214a71817', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/beb7d2dc-1db8-4025-9aa4-032214a71817-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'beb7d2dc-1db8-4025-9aa4-032214a71817' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/beb7d2dc-1db8-4025-9aa4-032214a71817-headshot.jpg', photo_origin_url = 'https://www.brandyforwisconsin.com/'
   WHERE id = 'beb7d2dc-1db8-4025-9aa4-032214a71817' AND photo_custom_url IS NULL;

  -- Jeremiah Fredrickson — Assembly District 92
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'c3b22f21-fdef-46a9-bb32-680f08459d91', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3b22f21-fdef-46a9-bb32-680f08459d91-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'c3b22f21-fdef-46a9-bb32-680f08459d91' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3b22f21-fdef-46a9-bb32-680f08459d91-headshot.jpg', photo_origin_url = 'https://www.jeremiahfredricksonforstateassembly.com/'
   WHERE id = 'c3b22f21-fdef-46a9-bb32-680f08459d91' AND photo_custom_url IS NULL;

