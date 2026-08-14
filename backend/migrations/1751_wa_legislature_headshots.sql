-- 1751_wa_legislature_headshots.sql
-- Registers official headshots for all 147 seated WA state legislators.
--
-- Source: https://leg.wa.gov/memberphoto/{wslId}.jpg -- the official legislature
-- portrait, 900x1200. The wslId is the member ID from the official WSL roster,
-- already reconciled to each seat in migration 1743, so no filename was
-- constructed from a name and no name was matched: there is no wrong-person
-- risk from URL construction. The documented legacy paths
-- (/PublishingImages/{lastname}.jpg) are dead; the current pattern was found by
-- observing the site's own network requests.
--
-- The /memberthumbnail/ variant is only 150x200 and was NOT used.
--
-- Processing: cropped to 4:5 FIRST, then resized to 600x750 at q90 (resizing
-- before cropping distorts faces). The crop is biased upward -- a third of the
-- excess off the top, two-thirds off the bottom -- to keep hair intact and eyes
-- nearer the upper third.
--
-- Mirrored into the politician_photos bucket as {politician_id}-headshot.jpg.
-- photo_license=press_use: these are works of a state government.
--
-- All 147 were reviewed on a contact sheet and approved before this ran.
-- Idempotency: NOT EXISTS on politician_images (no unique index on politician_id).

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e3e2c4be-bc12-43c3-9e86-4ba229d44346', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e3e2c4be-bc12-43c3-9e86-4ba229d44346-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'e3e2c4be-bc12-43c3-9e86-4ba229d44346');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5617115e-78d5-4480-9534-aa337612a285', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5617115e-78d5-4480-9534-aa337612a285-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5617115e-78d5-4480-9534-aa337612a285');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'be3c2a24-1576-4636-9374-18fc77a8513f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be3c2a24-1576-4636-9374-18fc77a8513f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'be3c2a24-1576-4636-9374-18fc77a8513f');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4b5055b4-2ed1-4894-acae-0e1465159564', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4b5055b4-2ed1-4894-acae-0e1465159564-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4b5055b4-2ed1-4894-acae-0e1465159564');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd8adabde-90dd-49e7-870c-1f2ae7c5e6d3', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d8adabde-90dd-49e7-870c-1f2ae7c5e6d3-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd8adabde-90dd-49e7-870c-1f2ae7c5e6d3');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '628a26a2-bcb9-4e87-a29f-ac5f6b381a37', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/628a26a2-bcb9-4e87-a29f-ac5f6b381a37-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '628a26a2-bcb9-4e87-a29f-ac5f6b381a37');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ab474e84-9ab1-46b1-954b-f49f237498bb', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab474e84-9ab1-46b1-954b-f49f237498bb-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ab474e84-9ab1-46b1-954b-f49f237498bb');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'fab8170e-a747-41de-ad39-769d8e0dd901', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fab8170e-a747-41de-ad39-769d8e0dd901-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'fab8170e-a747-41de-ad39-769d8e0dd901');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ae61e4af-16a8-44d6-933a-c4826882e103', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae61e4af-16a8-44d6-933a-c4826882e103-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ae61e4af-16a8-44d6-933a-c4826882e103');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'de6d7929-66dd-4166-998a-479cfa264ce5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/de6d7929-66dd-4166-998a-479cfa264ce5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'de6d7929-66dd-4166-998a-479cfa264ce5');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ec9da15f-7d79-42bc-a368-da3ab0855ddf', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ec9da15f-7d79-42bc-a368-da3ab0855ddf-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ec9da15f-7d79-42bc-a368-da3ab0855ddf');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '40ae39e3-8e86-46a5-b660-96b46a3e6c02', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/40ae39e3-8e86-46a5-b660-96b46a3e6c02-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '40ae39e3-8e86-46a5-b660-96b46a3e6c02');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '34ff9b7a-decc-4b21-8f6d-339957ab60bf', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/34ff9b7a-decc-4b21-8f6d-339957ab60bf-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '34ff9b7a-decc-4b21-8f6d-339957ab60bf');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '22d959a5-ec5f-4b92-98d3-85dc219c2c61', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/22d959a5-ec5f-4b92-98d3-85dc219c2c61-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '22d959a5-ec5f-4b92-98d3-85dc219c2c61');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0265efd8-29c9-46b4-b408-7da40b455257', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0265efd8-29c9-46b4-b408-7da40b455257-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0265efd8-29c9-46b4-b408-7da40b455257');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1963d6e9-069b-4770-9489-59e36faaa2e1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1963d6e9-069b-4770-9489-59e36faaa2e1-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1963d6e9-069b-4770-9489-59e36faaa2e1');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a961a076-f7be-436f-881f-155a0e9e687c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a961a076-f7be-436f-881f-155a0e9e687c-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'a961a076-f7be-436f-881f-155a0e9e687c');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '41ef42e8-fe56-4f82-92e7-eefe85232cd2', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41ef42e8-fe56-4f82-92e7-eefe85232cd2-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '41ef42e8-fe56-4f82-92e7-eefe85232cd2');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c176280e-d886-4b59-b812-e220449ffff1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c176280e-d886-4b59-b812-e220449ffff1-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'c176280e-d886-4b59-b812-e220449ffff1');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e1538de2-4e22-44cc-a50f-02fe7e2e9f2e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e1538de2-4e22-44cc-a50f-02fe7e2e9f2e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'e1538de2-4e22-44cc-a50f-02fe7e2e9f2e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bcfed468-6b26-4e3c-a96d-fb39ce46fd13', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bcfed468-6b26-4e3c-a96d-fb39ce46fd13-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'bcfed468-6b26-4e3c-a96d-fb39ce46fd13');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e36107af-ea8f-4fca-a727-0e37ca2f6fd4', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e36107af-ea8f-4fca-a727-0e37ca2f6fd4-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'e36107af-ea8f-4fca-a727-0e37ca2f6fd4');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '805fd55e-2e38-43b1-8b9d-a757af05f8e4', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/805fd55e-2e38-43b1-8b9d-a757af05f8e4-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '805fd55e-2e38-43b1-8b9d-a757af05f8e4');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7a0da48f-2c29-463e-969a-52d06137cde9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a0da48f-2c29-463e-969a-52d06137cde9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7a0da48f-2c29-463e-969a-52d06137cde9');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd5c6e6e4-c474-41fa-ab96-bd237c8ff4de', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5c6e6e4-c474-41fa-ab96-bd237c8ff4de-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd5c6e6e4-c474-41fa-ab96-bd237c8ff4de');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '56d6dd6f-4959-4339-be78-e4b1d0083b08', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/56d6dd6f-4959-4339-be78-e4b1d0083b08-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '56d6dd6f-4959-4339-be78-e4b1d0083b08');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '67b9aaf1-46eb-471f-8f31-dcf501a92933', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/67b9aaf1-46eb-471f-8f31-dcf501a92933-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '67b9aaf1-46eb-471f-8f31-dcf501a92933');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6f2a7dc4-888d-49a0-be12-a7600d976c87', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6f2a7dc4-888d-49a0-be12-a7600d976c87-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '6f2a7dc4-888d-49a0-be12-a7600d976c87');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd2a0229f-8825-4374-819e-29d8e4bc8e44', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d2a0229f-8825-4374-819e-29d8e4bc8e44-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd2a0229f-8825-4374-819e-29d8e4bc8e44');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9f914ddb-ba7c-4b30-b756-fe7cd981f919', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f914ddb-ba7c-4b30-b756-fe7cd981f919-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '9f914ddb-ba7c-4b30-b756-fe7cd981f919');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c88a915a-6613-4940-a12d-18a28b00935c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c88a915a-6613-4940-a12d-18a28b00935c-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'c88a915a-6613-4940-a12d-18a28b00935c');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'edc48d7e-4f91-4e59-af50-79f34df8b011', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/edc48d7e-4f91-4e59-af50-79f34df8b011-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'edc48d7e-4f91-4e59-af50-79f34df8b011');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '73ad3771-798c-4855-a467-7c6269bca5fc', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73ad3771-798c-4855-a467-7c6269bca5fc-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '73ad3771-798c-4855-a467-7c6269bca5fc');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0e5af9ca-165c-458c-8c65-a89aaf1a8d3e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e5af9ca-165c-458c-8c65-a89aaf1a8d3e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0e5af9ca-165c-458c-8c65-a89aaf1a8d3e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '86e6a2bf-5216-4022-900c-621a8480f2e7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86e6a2bf-5216-4022-900c-621a8480f2e7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '86e6a2bf-5216-4022-900c-621a8480f2e7');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9c1035b7-3372-4129-bca3-751b788b0999', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9c1035b7-3372-4129-bca3-751b788b0999-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '9c1035b7-3372-4129-bca3-751b788b0999');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'cf992e89-7b96-46f3-9999-58432c690fe4', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cf992e89-7b96-46f3-9999-58432c690fe4-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'cf992e89-7b96-46f3-9999-58432c690fe4');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'da15c353-3744-4dd3-a6ed-c4b6e89752e1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/da15c353-3744-4dd3-a6ed-c4b6e89752e1-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'da15c353-3744-4dd3-a6ed-c4b6e89752e1');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '363fe07c-171e-4044-b6f9-979662962027', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/363fe07c-171e-4044-b6f9-979662962027-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '363fe07c-171e-4044-b6f9-979662962027');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1a53e3c7-3c47-450b-a04d-a2128288b868', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1a53e3c7-3c47-450b-a04d-a2128288b868-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1a53e3c7-3c47-450b-a04d-a2128288b868');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '55631a34-52aa-4806-9af6-1220fcf65ca5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/55631a34-52aa-4806-9af6-1220fcf65ca5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '55631a34-52aa-4806-9af6-1220fcf65ca5');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7b992556-5e0d-488a-92f7-942ab56660c1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b992556-5e0d-488a-92f7-942ab56660c1-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7b992556-5e0d-488a-92f7-942ab56660c1');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '97b47446-b0ee-4a2c-b4fe-ec8a995356ea', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/97b47446-b0ee-4a2c-b4fe-ec8a995356ea-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '97b47446-b0ee-4a2c-b4fe-ec8a995356ea');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ce184542-9397-469f-ba78-8c735bce20fa', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce184542-9397-469f-ba78-8c735bce20fa-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ce184542-9397-469f-ba78-8c735bce20fa');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7b5839a9-87c9-4789-bd4e-a85e24a90d6d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b5839a9-87c9-4789-bd4e-a85e24a90d6d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7b5839a9-87c9-4789-bd4e-a85e24a90d6d');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5204682b-10ec-452a-bd90-4be46a634258', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5204682b-10ec-452a-bd90-4be46a634258-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5204682b-10ec-452a-bd90-4be46a634258');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '43bb35d8-ef11-49cb-9bc7-f16e65cc6534', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/43bb35d8-ef11-49cb-9bc7-f16e65cc6534-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '43bb35d8-ef11-49cb-9bc7-f16e65cc6534');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0e37790d-e8e6-411d-aecb-3fddb8c53a61', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e37790d-e8e6-411d-aecb-3fddb8c53a61-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0e37790d-e8e6-411d-aecb-3fddb8c53a61');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0381ded1-ac26-4700-8188-6ff06621d1be', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0381ded1-ac26-4700-8188-6ff06621d1be-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0381ded1-ac26-4700-8188-6ff06621d1be');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f68a7024-846d-4383-a34e-a21df06b2314', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f68a7024-846d-4383-a34e-a21df06b2314-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f68a7024-846d-4383-a34e-a21df06b2314');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '463c9085-ff29-45f4-88b0-fe3be9693a36', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/463c9085-ff29-45f4-88b0-fe3be9693a36-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '463c9085-ff29-45f4-88b0-fe3be9693a36');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '370f9462-ed1d-4a83-b244-8bb593038444', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/370f9462-ed1d-4a83-b244-8bb593038444-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '370f9462-ed1d-4a83-b244-8bb593038444');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '30fdeba0-e9d3-414d-859f-2941140d8e80', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/30fdeba0-e9d3-414d-859f-2941140d8e80-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '30fdeba0-e9d3-414d-859f-2941140d8e80');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '45737b89-a83b-421f-9d6c-abc829c7eae0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/45737b89-a83b-421f-9d6c-abc829c7eae0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '45737b89-a83b-421f-9d6c-abc829c7eae0');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd97bcc03-4c74-4c9d-9e0f-13ae551ed54c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d97bcc03-4c74-4c9d-9e0f-13ae551ed54c-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd97bcc03-4c74-4c9d-9e0f-13ae551ed54c');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6341053d-0580-4fbf-85ea-71ddb6b6f838', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6341053d-0580-4fbf-85ea-71ddb6b6f838-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '6341053d-0580-4fbf-85ea-71ddb6b6f838');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '642ee2f7-b15b-47b5-b71b-d86670e85e4e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/642ee2f7-b15b-47b5-b71b-d86670e85e4e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '642ee2f7-b15b-47b5-b71b-d86670e85e4e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'dc5f89f6-be92-4e3d-960e-3959280765ad', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc5f89f6-be92-4e3d-960e-3959280765ad-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'dc5f89f6-be92-4e3d-960e-3959280765ad');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5f02b7a6-a6a3-408f-8e9b-ea678c75b92d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5f02b7a6-a6a3-408f-8e9b-ea678c75b92d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5f02b7a6-a6a3-408f-8e9b-ea678c75b92d');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0f598558-61ab-4010-a0fd-e7c54f688a1a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0f598558-61ab-4010-a0fd-e7c54f688a1a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0f598558-61ab-4010-a0fd-e7c54f688a1a');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7dec5fff-ab9b-45a5-8acf-ab0feccb2771', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7dec5fff-ab9b-45a5-8acf-ab0feccb2771-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7dec5fff-ab9b-45a5-8acf-ab0feccb2771');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7a2907ff-b519-41c0-b9fb-9a664fa15750', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7a2907ff-b519-41c0-b9fb-9a664fa15750-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7a2907ff-b519-41c0-b9fb-9a664fa15750');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ecee999d-6aa9-420c-8da0-249ea31d4078', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ecee999d-6aa9-420c-8da0-249ea31d4078-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ecee999d-6aa9-420c-8da0-249ea31d4078');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a2960d00-9348-4a98-82b9-2cf2320669b6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a2960d00-9348-4a98-82b9-2cf2320669b6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'a2960d00-9348-4a98-82b9-2cf2320669b6');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f6a25fa8-ef58-4179-8660-bdb642336f68', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6a25fa8-ef58-4179-8660-bdb642336f68-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f6a25fa8-ef58-4179-8660-bdb642336f68');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '72f1981b-ff10-48dd-8c92-e6ea2c169902', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/72f1981b-ff10-48dd-8c92-e6ea2c169902-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '72f1981b-ff10-48dd-8c92-e6ea2c169902');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4546a3b3-4544-43bf-bf0f-eb56871fa1a2', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4546a3b3-4544-43bf-bf0f-eb56871fa1a2-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4546a3b3-4544-43bf-bf0f-eb56871fa1a2');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f5c96c19-a962-4881-9520-a741cb0123e5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f5c96c19-a962-4881-9520-a741cb0123e5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f5c96c19-a962-4881-9520-a741cb0123e5');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '81aeef04-3b51-40a1-8a89-013acf2f5ec4', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81aeef04-3b51-40a1-8a89-013acf2f5ec4-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '81aeef04-3b51-40a1-8a89-013acf2f5ec4');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b0ba6ded-89b3-49f4-9aab-8aefea840384', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b0ba6ded-89b3-49f4-9aab-8aefea840384-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'b0ba6ded-89b3-49f4-9aab-8aefea840384');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd4e6e041-dc18-4415-9201-1a9bd18dea8b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d4e6e041-dc18-4415-9201-1a9bd18dea8b-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd4e6e041-dc18-4415-9201-1a9bd18dea8b');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '87a700d7-b217-4475-9366-53a4e04acb19', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/87a700d7-b217-4475-9366-53a4e04acb19-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '87a700d7-b217-4475-9366-53a4e04acb19');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b676423d-10a2-451a-88a8-ac80f5117c6a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b676423d-10a2-451a-88a8-ac80f5117c6a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'b676423d-10a2-451a-88a8-ac80f5117c6a');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f4f7acdf-1761-4cac-82e6-19bf8f6ea525', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f4f7acdf-1761-4cac-82e6-19bf8f6ea525-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f4f7acdf-1761-4cac-82e6-19bf8f6ea525');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '447b684b-e885-42c9-9f32-7e6480cb5b98', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/447b684b-e885-42c9-9f32-7e6480cb5b98-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '447b684b-e885-42c9-9f32-7e6480cb5b98');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '78726dd6-5ce2-40d4-9cf6-10fc6a840756', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/78726dd6-5ce2-40d4-9cf6-10fc6a840756-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '78726dd6-5ce2-40d4-9cf6-10fc6a840756');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '721bf21e-7913-431b-9807-037561f18b82', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/721bf21e-7913-431b-9807-037561f18b82-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '721bf21e-7913-431b-9807-037561f18b82');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '62bd22ba-058e-4cf8-bd24-905ced2f727a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/62bd22ba-058e-4cf8-bd24-905ced2f727a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '62bd22ba-058e-4cf8-bd24-905ced2f727a');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bec74bbe-a581-402d-9de2-4a65354500ff', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bec74bbe-a581-402d-9de2-4a65354500ff-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'bec74bbe-a581-402d-9de2-4a65354500ff');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a327c238-cf63-4a27-83f7-cc85468f8742', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a327c238-cf63-4a27-83f7-cc85468f8742-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'a327c238-cf63-4a27-83f7-cc85468f8742');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '78c2d2cf-5520-490b-a45f-348baad3c59e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/78c2d2cf-5520-490b-a45f-348baad3c59e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '78c2d2cf-5520-490b-a45f-348baad3c59e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ba7f7d85-62ba-440d-abff-70ce9af458e5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ba7f7d85-62ba-440d-abff-70ce9af458e5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'ba7f7d85-62ba-440d-abff-70ce9af458e5');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '20691f72-9abe-40ad-b361-eb804b212e29', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/20691f72-9abe-40ad-b361-eb804b212e29-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '20691f72-9abe-40ad-b361-eb804b212e29');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a9a04d0e-04a6-46c2-b8ce-cebfdd272b19', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a9a04d0e-04a6-46c2-b8ce-cebfdd272b19-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'a9a04d0e-04a6-46c2-b8ce-cebfdd272b19');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2026df33-5726-4d18-8f17-1882e49893fa', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2026df33-5726-4d18-8f17-1882e49893fa-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2026df33-5726-4d18-8f17-1882e49893fa');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3efc8925-9612-4601-aed5-c05234a5e64d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3efc8925-9612-4601-aed5-c05234a5e64d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '3efc8925-9612-4601-aed5-c05234a5e64d');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0401d7b9-9f0d-4b92-beed-02bcf2afc456', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0401d7b9-9f0d-4b92-beed-02bcf2afc456-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0401d7b9-9f0d-4b92-beed-02bcf2afc456');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '945d0b44-3329-46b2-a39e-47f5fdddc6ed', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/945d0b44-3329-46b2-a39e-47f5fdddc6ed-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '945d0b44-3329-46b2-a39e-47f5fdddc6ed');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '165640fd-99e3-4e1e-bd73-8df36e4ac1d6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/165640fd-99e3-4e1e-bd73-8df36e4ac1d6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '165640fd-99e3-4e1e-bd73-8df36e4ac1d6');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7db875e2-7a94-4676-bfef-fd6aec93b7c7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7db875e2-7a94-4676-bfef-fd6aec93b7c7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7db875e2-7a94-4676-bfef-fd6aec93b7c7');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b918fb31-108f-49e7-b977-627ce667422d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b918fb31-108f-49e7-b977-627ce667422d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'b918fb31-108f-49e7-b977-627ce667422d');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f3daea18-1a32-486f-b8df-659d7c653c05', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f3daea18-1a32-486f-b8df-659d7c653c05-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f3daea18-1a32-486f-b8df-659d7c653c05');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '14332488-3986-4e86-abc2-666b7a3f2dd5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/14332488-3986-4e86-abc2-666b7a3f2dd5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '14332488-3986-4e86-abc2-666b7a3f2dd5');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2147a010-bd4e-445c-840a-8d5ad69573ca', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2147a010-bd4e-445c-840a-8d5ad69573ca-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2147a010-bd4e-445c-840a-8d5ad69573ca');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4042de49-5bea-413c-aecd-9abbe742a9a2', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4042de49-5bea-413c-aecd-9abbe742a9a2-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4042de49-5bea-413c-aecd-9abbe742a9a2');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd1e47ce6-4390-47e0-937e-3c710e81abbb', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d1e47ce6-4390-47e0-937e-3c710e81abbb-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd1e47ce6-4390-47e0-937e-3c710e81abbb');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0097aee3-e409-44bc-ba20-121108c11ec7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0097aee3-e409-44bc-ba20-121108c11ec7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0097aee3-e409-44bc-ba20-121108c11ec7');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '47ac1908-3715-4599-82f6-606aaf2d9fe6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47ac1908-3715-4599-82f6-606aaf2d9fe6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '47ac1908-3715-4599-82f6-606aaf2d9fe6');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3ac881c7-2d11-42c1-9bc0-23f54770a64b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3ac881c7-2d11-42c1-9bc0-23f54770a64b-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '3ac881c7-2d11-42c1-9bc0-23f54770a64b');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7902547a-e33b-4fff-8a77-5d4e76163f47', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7902547a-e33b-4fff-8a77-5d4e76163f47-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7902547a-e33b-4fff-8a77-5d4e76163f47');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1ff1e922-601b-45f3-a43d-2ef69220f54b', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1ff1e922-601b-45f3-a43d-2ef69220f54b-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1ff1e922-601b-45f3-a43d-2ef69220f54b');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '207ff383-f26e-462b-a554-72472b52712a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/207ff383-f26e-462b-a554-72472b52712a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '207ff383-f26e-462b-a554-72472b52712a');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3db3f064-dd6e-4bca-9200-3d4395972253', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3db3f064-dd6e-4bca-9200-3d4395972253-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '3db3f064-dd6e-4bca-9200-3d4395972253');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7ac92b63-d489-45d5-a85f-c0deac9d8508', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7ac92b63-d489-45d5-a85f-c0deac9d8508-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7ac92b63-d489-45d5-a85f-c0deac9d8508');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4218b4c2-d642-431e-a279-5aff5100379f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4218b4c2-d642-431e-a279-5aff5100379f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4218b4c2-d642-431e-a279-5aff5100379f');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4991ee01-0a35-454f-bdf6-bb2f34cf1c30', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4991ee01-0a35-454f-bdf6-bb2f34cf1c30-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4991ee01-0a35-454f-bdf6-bb2f34cf1c30');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5ab349b4-f041-4637-af64-c4e6e4f54c3e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5ab349b4-f041-4637-af64-c4e6e4f54c3e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5ab349b4-f041-4637-af64-c4e6e4f54c3e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '5a36591c-66c5-4cb1-b99d-d7fc7fa93b25', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5a36591c-66c5-4cb1-b99d-d7fc7fa93b25-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '5a36591c-66c5-4cb1-b99d-d7fc7fa93b25');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7535e225-d3d0-40ca-ba9c-3890563c40a0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7535e225-d3d0-40ca-ba9c-3890563c40a0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7535e225-d3d0-40ca-ba9c-3890563c40a0');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '15808557-b30b-44cf-bad2-e627fa547e1a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/15808557-b30b-44cf-bad2-e627fa547e1a-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '15808557-b30b-44cf-bad2-e627fa547e1a');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd3fad6d8-8022-4c66-b505-4e7a8fc816d7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3fad6d8-8022-4c66-b505-4e7a8fc816d7-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd3fad6d8-8022-4c66-b505-4e7a8fc816d7');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f6c042e3-b785-4bf2-b385-65a34ff616e8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6c042e3-b785-4bf2-b385-65a34ff616e8-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f6c042e3-b785-4bf2-b385-65a34ff616e8');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '054dd953-bc6b-44de-8173-00efab5a9c04', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/054dd953-bc6b-44de-8173-00efab5a9c04-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '054dd953-bc6b-44de-8173-00efab5a9c04');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '436194e1-479e-4066-8d99-f325fd6bb880', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/436194e1-479e-4066-8d99-f325fd6bb880-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '436194e1-479e-4066-8d99-f325fd6bb880');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c09a622c-ec49-40e9-87db-ead331f5ab9e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c09a622c-ec49-40e9-87db-ead331f5ab9e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'c09a622c-ec49-40e9-87db-ead331f5ab9e');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd997402c-ee18-4544-b770-ac13a777b601', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d997402c-ee18-4544-b770-ac13a777b601-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd997402c-ee18-4544-b770-ac13a777b601');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '65cae041-2bf3-4d9f-a010-02d2f07b949c', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/65cae041-2bf3-4d9f-a010-02d2f07b949c-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '65cae041-2bf3-4d9f-a010-02d2f07b949c');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1e6d175b-1af0-444c-b373-e5d0a279d240', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e6d175b-1af0-444c-b373-e5d0a279d240-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '1e6d175b-1af0-444c-b373-e5d0a279d240');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'eba44d6a-6602-4a90-bef0-44ab12db6109', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eba44d6a-6602-4a90-bef0-44ab12db6109-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'eba44d6a-6602-4a90-bef0-44ab12db6109');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '755f24a5-2330-4546-9679-d5f7fa94aaa9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/755f24a5-2330-4546-9679-d5f7fa94aaa9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '755f24a5-2330-4546-9679-d5f7fa94aaa9');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'aadf55f0-a4b4-4a4a-acf0-bfce06815149', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aadf55f0-a4b4-4a4a-acf0-bfce06815149-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'aadf55f0-a4b4-4a4a-acf0-bfce06815149');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f8feca06-c2bb-4ec8-ad85-0989559912e9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8feca06-c2bb-4ec8-ad85-0989559912e9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f8feca06-c2bb-4ec8-ad85-0989559912e9');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c4e1312c-e746-483e-a3ec-f27bc40b6d26', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c4e1312c-e746-483e-a3ec-f27bc40b6d26-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'c4e1312c-e746-483e-a3ec-f27bc40b6d26');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '624622d4-ce11-4fa3-9f0b-89c47559d1c6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/624622d4-ce11-4fa3-9f0b-89c47559d1c6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '624622d4-ce11-4fa3-9f0b-89c47559d1c6');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'fec68f5f-c9e1-4579-869a-7b4a78f7da90', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fec68f5f-c9e1-4579-869a-7b4a78f7da90-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'fec68f5f-c9e1-4579-869a-7b4a78f7da90');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b316dce9-ed2e-44f6-b974-bf639cacb816', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b316dce9-ed2e-44f6-b974-bf639cacb816-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'b316dce9-ed2e-44f6-b974-bf639cacb816');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f3cd74bb-3bdb-4d55-a07d-5c14bda50926', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f3cd74bb-3bdb-4d55-a07d-5c14bda50926-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f3cd74bb-3bdb-4d55-a07d-5c14bda50926');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '219f7fc7-d02b-46a0-acad-dfc09814ed11', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/219f7fc7-d02b-46a0-acad-dfc09814ed11-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '219f7fc7-d02b-46a0-acad-dfc09814ed11');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f183194f-814a-43c6-858e-11fc66ad5d41', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f183194f-814a-43c6-858e-11fc66ad5d41-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f183194f-814a-43c6-858e-11fc66ad5d41');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f893ae5d-6659-40cd-a874-e9351efcdb95', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f893ae5d-6659-40cd-a874-e9351efcdb95-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'f893ae5d-6659-40cd-a874-e9351efcdb95');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'a88093ad-c483-49c1-ae1e-9f851cdb53fc', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a88093ad-c483-49c1-ae1e-9f851cdb53fc-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'a88093ad-c483-49c1-ae1e-9f851cdb53fc');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd0350f2f-6463-452e-b97d-c18ea094e2ee', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d0350f2f-6463-452e-b97d-c18ea094e2ee-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'd0350f2f-6463-452e-b97d-c18ea094e2ee');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2ffd9e47-b0f1-428f-9164-01025dd34310', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2ffd9e47-b0f1-428f-9164-01025dd34310-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '2ffd9e47-b0f1-428f-9164-01025dd34310');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0e935fed-534e-42b0-a5ad-74f4199ff6df', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0e935fed-534e-42b0-a5ad-74f4199ff6df-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '0e935fed-534e-42b0-a5ad-74f4199ff6df');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c3fccc57-8278-43c8-8e54-dc3c78e50bc9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3fccc57-8278-43c8-8e54-dc3c78e50bc9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = 'c3fccc57-8278-43c8-8e54-dc3c78e50bc9');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6cc4c706-fa7a-486f-ac67-6cbdede4a607', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6cc4c706-fa7a-486f-ac67-6cbdede4a607-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '6cc4c706-fa7a-486f-ac67-6cbdede4a607');
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '78230dff-4e33-4d33-8c46-71f00db01858', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/78230dff-4e33-4d33-8c46-71f00db01858-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = '78230dff-4e33-4d33-8c46-71f00db01858');

UPDATE essentials.politicians
SET photo_origin_url = 'https://leg.wa.gov/legislators/'
WHERE id IN ('e3e2c4be-bc12-43c3-9e86-4ba229d44346','5617115e-78d5-4480-9534-aa337612a285','be3c2a24-1576-4636-9374-18fc77a8513f','4b5055b4-2ed1-4894-acae-0e1465159564','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','628a26a2-bcb9-4e87-a29f-ac5f6b381a37','ab474e84-9ab1-46b1-954b-f49f237498bb','fab8170e-a747-41de-ad39-769d8e0dd901','ae61e4af-16a8-44d6-933a-c4826882e103','de6d7929-66dd-4166-998a-479cfa264ce5','ec9da15f-7d79-42bc-a368-da3ab0855ddf','40ae39e3-8e86-46a5-b660-96b46a3e6c02','34ff9b7a-decc-4b21-8f6d-339957ab60bf','22d959a5-ec5f-4b92-98d3-85dc219c2c61','7ecc31aa-0482-4dcc-86f5-7c5918b7b7f9','0265efd8-29c9-46b4-b408-7da40b455257','1963d6e9-069b-4770-9489-59e36faaa2e1','a961a076-f7be-436f-881f-155a0e9e687c','41ef42e8-fe56-4f82-92e7-eefe85232cd2','c176280e-d886-4b59-b812-e220449ffff1','e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','bcfed468-6b26-4e3c-a96d-fb39ce46fd13','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','805fd55e-2e38-43b1-8b9d-a757af05f8e4','7a0da48f-2c29-463e-969a-52d06137cde9','d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','56d6dd6f-4959-4339-be78-e4b1d0083b08','67b9aaf1-46eb-471f-8f31-dcf501a92933','6f2a7dc4-888d-49a0-be12-a7600d976c87','d2a0229f-8825-4374-819e-29d8e4bc8e44','9f914ddb-ba7c-4b30-b756-fe7cd981f919','c88a915a-6613-4940-a12d-18a28b00935c','edc48d7e-4f91-4e59-af50-79f34df8b011','73ad3771-798c-4855-a467-7c6269bca5fc','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','86e6a2bf-5216-4022-900c-621a8480f2e7','2d50d3e5-aab0-4979-8ae1-5350d9f7a9dd','9c1035b7-3372-4129-bca3-751b788b0999','cf992e89-7b96-46f3-9999-58432c690fe4','da15c353-3744-4dd3-a6ed-c4b6e89752e1','363fe07c-171e-4044-b6f9-979662962027','1a53e3c7-3c47-450b-a04d-a2128288b868','55631a34-52aa-4806-9af6-1220fcf65ca5','7b992556-5e0d-488a-92f7-942ab56660c1','97b47446-b0ee-4a2c-b4fe-ec8a995356ea','ce184542-9397-469f-ba78-8c735bce20fa','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','5204682b-10ec-452a-bd90-4be46a634258','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','0e37790d-e8e6-411d-aecb-3fddb8c53a61','0381ded1-ac26-4700-8188-6ff06621d1be','f68a7024-846d-4383-a34e-a21df06b2314','463c9085-ff29-45f4-88b0-fe3be9693a36','370f9462-ed1d-4a83-b244-8bb593038444','30fdeba0-e9d3-414d-859f-2941140d8e80','45737b89-a83b-421f-9d6c-abc829c7eae0','d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','6341053d-0580-4fbf-85ea-71ddb6b6f838','642ee2f7-b15b-47b5-b71b-d86670e85e4e','dc5f89f6-be92-4e3d-960e-3959280765ad','5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','0f598558-61ab-4010-a0fd-e7c54f688a1a','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','7dec5fff-ab9b-45a5-8acf-ab0feccb2771','7a2907ff-b519-41c0-b9fb-9a664fa15750','ecee999d-6aa9-420c-8da0-249ea31d4078','a2960d00-9348-4a98-82b9-2cf2320669b6','f6a25fa8-ef58-4179-8660-bdb642336f68','72f1981b-ff10-48dd-8c92-e6ea2c169902','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','f5c96c19-a962-4881-9520-a741cb0123e5','81aeef04-3b51-40a1-8a89-013acf2f5ec4','b0ba6ded-89b3-49f4-9aab-8aefea840384','d4e6e041-dc18-4415-9201-1a9bd18dea8b','87a700d7-b217-4475-9366-53a4e04acb19','b676423d-10a2-451a-88a8-ac80f5117c6a','f4f7acdf-1761-4cac-82e6-19bf8f6ea525','447b684b-e885-42c9-9f32-7e6480cb5b98','78726dd6-5ce2-40d4-9cf6-10fc6a840756','721bf21e-7913-431b-9807-037561f18b82','62bd22ba-058e-4cf8-bd24-905ced2f727a','bec74bbe-a581-402d-9de2-4a65354500ff','a327c238-cf63-4a27-83f7-cc85468f8742','78c2d2cf-5520-490b-a45f-348baad3c59e','ba7f7d85-62ba-440d-abff-70ce9af458e5','20691f72-9abe-40ad-b361-eb804b212e29','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','2026df33-5726-4d18-8f17-1882e49893fa','3efc8925-9612-4601-aed5-c05234a5e64d','0401d7b9-9f0d-4b92-beed-02bcf2afc456','945d0b44-3329-46b2-a39e-47f5fdddc6ed','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','7db875e2-7a94-4676-bfef-fd6aec93b7c7','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','b918fb31-108f-49e7-b977-627ce667422d','f3daea18-1a32-486f-b8df-659d7c653c05','14332488-3986-4e86-abc2-666b7a3f2dd5','2147a010-bd4e-445c-840a-8d5ad69573ca','4042de49-5bea-413c-aecd-9abbe742a9a2','d1e47ce6-4390-47e0-937e-3c710e81abbb','0097aee3-e409-44bc-ba20-121108c11ec7','47ac1908-3715-4599-82f6-606aaf2d9fe6','3ac881c7-2d11-42c1-9bc0-23f54770a64b','7902547a-e33b-4fff-8a77-5d4e76163f47','1ff1e922-601b-45f3-a43d-2ef69220f54b','207ff383-f26e-462b-a554-72472b52712a','3db3f064-dd6e-4bca-9200-3d4395972253','7ac92b63-d489-45d5-a85f-c0deac9d8508','4218b4c2-d642-431e-a279-5aff5100379f','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','5ab349b4-f041-4637-af64-c4e6e4f54c3e','5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','7535e225-d3d0-40ca-ba9c-3890563c40a0','15808557-b30b-44cf-bad2-e627fa547e1a','d3fad6d8-8022-4c66-b505-4e7a8fc816d7','f6c042e3-b785-4bf2-b385-65a34ff616e8','054dd953-bc6b-44de-8173-00efab5a9c04','436194e1-479e-4066-8d99-f325fd6bb880','c09a622c-ec49-40e9-87db-ead331f5ab9e','7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe','d997402c-ee18-4544-b770-ac13a777b601','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','65cae041-2bf3-4d9f-a010-02d2f07b949c','1e6d175b-1af0-444c-b373-e5d0a279d240','eba44d6a-6602-4a90-bef0-44ab12db6109','755f24a5-2330-4546-9679-d5f7fa94aaa9','aadf55f0-a4b4-4a4a-acf0-bfce06815149','f8feca06-c2bb-4ec8-ad85-0989559912e9','c4e1312c-e746-483e-a3ec-f27bc40b6d26','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','624622d4-ce11-4fa3-9f0b-89c47559d1c6','fec68f5f-c9e1-4579-869a-7b4a78f7da90','b316dce9-ed2e-44f6-b974-bf639cacb816','f3cd74bb-3bdb-4d55-a07d-5c14bda50926','219f7fc7-d02b-46a0-acad-dfc09814ed11','f183194f-814a-43c6-858e-11fc66ad5d41','f893ae5d-6659-40cd-a874-e9351efcdb95','7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','a88093ad-c483-49c1-ae1e-9f851cdb53fc','d0350f2f-6463-452e-b97d-c18ea094e2ee','2ffd9e47-b0f1-428f-9164-01025dd34310','0e935fed-534e-42b0-a5ad-74f4199ff6df','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','6cc4c706-fa7a-486f-ac67-6cbdede4a607','78230dff-4e33-4d33-8c46-71f00db01858') AND photo_origin_url IS NULL;
