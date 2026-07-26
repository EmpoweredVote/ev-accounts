-- Migration 1472: Racine County officeholder enrichment (headshots + emails)
--
-- Source: racinecounty.gov (Akamai-walled; reachable with a browser User-Agent AND
--   Accept-Encoding present -- curl needs --compressed, or it returns HTTP 403).
-- Headshots: 384x384 circular-cutout portraits from per-official pages, selected by
--   matching the img alt attribute to the officeholder (each page also carries a
--   portrait-shaped district MAP and a sitewide County Executive promo image, both decoys).
--   Processed to 4:5 -> 600x750 Lanczos JPEG q90 and mirrored to the politician_photos bucket.
-- D3 (Osterman) and D17 (Weatherston) portraits occupy image slots whose alt text still
--   named the previous occupant (tom rutkowski / gary kolb). Both were re-uploaded by the
--   county in the post-April-2026 batch; identity corroborated against a Racine County Eye
--   photo (Osterman) and the 2015 legislature portrait (Weatherston). Flagged in photo_license.
-- Emails: 21 supervisors publish personal First.Last@racinecounty.gov (middle names dropped,
--   so NOT derivable from full_name). The countywide officers publish only DEPARTMENTAL
--   inboxes -- stored deliberately, as they are the official published contact route.
-- Not covered (no source exists): D14 Hoffman + D18 McReynolds (county shows an explicit
--   "no picture" placeholder), County Clerk / Treasurer / Register of Deeds portraits,
--   and all 10 circuit judges (the court-officials page lists names only).
-- Idempotent: every statement guards on current state.

BEGIN;
-- 1) Headshot rows ---------------------------------------------------------
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1c3fa486-3719-402e-b4d5-65680870eabe', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c3fa486-3719-402e-b4d5-65680870eabe-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='1c3fa486-3719-402e-b4d5-65680870eabe');  -- D1 Valena Lena Coleman
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6c040b24-d9cc-48ad-8271-3cfead5a6c5d', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6c040b24-d9cc-48ad-8271-3cfead5a6c5d-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6c040b24-d9cc-48ad-8271-3cfead5a6c5d');  -- D2 Renee Kelly
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3130fabe-aaa0-42c6-aa28-04e9c2ab612a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3130fabe-aaa0-42c6-aa28-04e9c2ab612a-headshot.jpg', 'default', 'press_use — racinecounty.gov official portrait; alt text on the image slot still named the prior occupant (see migration note)'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='3130fabe-aaa0-42c6-aa28-04e9c2ab612a');  -- D3 Monte Osterman
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '33cdad7e-ada6-4da9-9e99-64bc510fbb6e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/33cdad7e-ada6-4da9-9e99-64bc510fbb6e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='33cdad7e-ada6-4da9-9e99-64bc510fbb6e');  -- D4 Melissa Kaprelian
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'fdba65d2-19ae-4cb5-a69e-bd6ca60aeecf', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fdba65d2-19ae-4cb5-a69e-bd6ca60aeecf-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='fdba65d2-19ae-4cb5-a69e-bd6ca60aeecf');  -- D5 Jody Spencer
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1375a361-0ef9-4ef6-9d33-8f4bc6c79a4e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1375a361-0ef9-4ef6-9d33-8f4bc6c79a4e-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='1375a361-0ef9-4ef6-9d33-8f4bc6c79a4e');  -- D6 Q.A. Shakoor, II
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '7dd312fb-8b5c-418b-8e5e-92a585b7cf51', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7dd312fb-8b5c-418b-8e5e-92a585b7cf51-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='7dd312fb-8b5c-418b-8e5e-92a585b7cf51');  -- D7 Ernie Rossi
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0446822f-3443-4cfd-8f8b-8793edd0c5b6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0446822f-3443-4cfd-8f8b-8793edd0c5b6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='0446822f-3443-4cfd-8f8b-8793edd0c5b6');  -- D8 Brett A. Nielsen
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e2b79962-0f11-4aa1-8fcf-987275790eb6', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e2b79962-0f11-4aa1-8fcf-987275790eb6-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='e2b79962-0f11-4aa1-8fcf-987275790eb6');  -- D9 Eric Hopkins
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b23cda29-b228-4900-ba38-fad82140e184', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b23cda29-b228-4900-ba38-fad82140e184-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='b23cda29-b228-4900-ba38-fad82140e184');  -- D10 Tony Veranth
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '6b95b80c-22bd-4176-8346-4c5459b5a090', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b95b80c-22bd-4176-8346-4c5459b5a090-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6b95b80c-22bd-4176-8346-4c5459b5a090');  -- D11 Robert N. Miller
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3b6ddd4c-1cb7-4468-aeab-fd4e54e8b03f', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3b6ddd4c-1cb7-4468-aeab-fd4e54e8b03f-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='3b6ddd4c-1cb7-4468-aeab-fd4e54e8b03f');  -- D12 Don Trottier
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'bd6fa242-e96a-4bb1-8c87-1d4abcd100de', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bd6fa242-e96a-4bb1-8c87-1d4abcd100de-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='bd6fa242-e96a-4bb1-8c87-1d4abcd100de');  -- D13 Tom Kramer
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '2d0e85a2-ab25-4a0a-9f94-b8dc2c78a946', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2d0e85a2-ab25-4a0a-9f94-b8dc2c78a946-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='2d0e85a2-ab25-4a0a-9f94-b8dc2c78a946');  -- D15 John Wisch
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'ecf42f21-d452-4039-b24d-8480e8d858e5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ecf42f21-d452-4039-b24d-8480e8d858e5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='ecf42f21-d452-4039-b24d-8480e8d858e5');  -- D16 Scott Meier
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b249285b-0d3f-45ea-8d6d-5ce965a6c79e', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b249285b-0d3f-45ea-8d6d-5ce965a6c79e-headshot.jpg', 'default', 'press_use — racinecounty.gov official portrait; alt text on the image slot still named the prior occupant (see migration note)'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='b249285b-0d3f-45ea-8d6d-5ce965a6c79e');  -- D17 Thomas Weatherston
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'd5d3fcd5-0ece-454a-8f17-dd3549a67812', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d5d3fcd5-0ece-454a-8f17-dd3549a67812-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='d5d3fcd5-0ece-454a-8f17-dd3549a67812');  -- D19 Greg Horeth
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'f64a25b4-cc2f-48fa-8910-dec51d8bcce9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f64a25b4-cc2f-48fa-8910-dec51d8bcce9-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='f64a25b4-cc2f-48fa-8910-dec51d8bcce9');  -- D20 Tom Preusker
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '57e48782-606a-4793-aca7-5fd13dc5e4f0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/57e48782-606a-4793-aca7-5fd13dc5e4f0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='57e48782-606a-4793-aca7-5fd13dc5e4f0');  -- D21 Taylor Wishau
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0a695784-7fe4-4545-bf90-9e1770db5709', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a695784-7fe4-4545-bf90-9e1770db5709-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='0a695784-7fe4-4545-bf90-9e1770db5709');  -- Ralph Malicki
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'b5485814-7374-44bc-a8da-f2e7188c01fe', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b5485814-7374-44bc-a8da-f2e7188c01fe-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='b5485814-7374-44bc-a8da-f2e7188c01fe');  -- Christopher Schmaling
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1349f478-b02b-427a-9837-8822673133c5', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1349f478-b02b-427a-9837-8822673133c5-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='1349f478-b02b-427a-9837-8822673133c5');  -- Amy Vanderhoef
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'e444877d-286c-4bc8-93c8-c48fe5f6dbf2', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e444877d-286c-4bc8-93c8-c48fe5f6dbf2-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='e444877d-286c-4bc8-93c8-c48fe5f6dbf2');  -- Patricia J. Hanson

-- 2) photo_origin_url -----------------------------------------------------
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/nick-demske' WHERE id='1c3fa486-3719-402e-b4d5-65680870eabe' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/fabi-maldonado' WHERE id='6c040b24-d9cc-48ad-8271-3cfead5a6c5d' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/steve-smetana' WHERE id='3130fabe-aaa0-42c6-aa28-04e9c2ab612a' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/melissa-kaprelian' WHERE id='33cdad7e-ada6-4da9-9e99-64bc510fbb6e' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/jody-spencer' WHERE id='fdba65d2-19ae-4cb5-a69e-bd6ca60aeecf' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/q-a-shakoor-ii' WHERE id='1375a361-0ef9-4ef6-9d33-8f4bc6c79a4e' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-supervisors/ernie-rossi-district-7' WHERE id='7dd312fb-8b5c-418b-8e5e-92a585b7cf51' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/brett-a-nielsen' WHERE id='0446822f-3443-4cfd-8f8b-8793edd0c5b6' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/eric-hopkins' WHERE id='e2b79962-0f11-4aa1-8fcf-987275790eb6' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/kelly-kruse' WHERE id='b23cda29-b228-4900-ba38-fad82140e184' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/robert-n-miller' WHERE id='6b95b80c-22bd-4176-8346-4c5459b5a090' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/don-trottier' WHERE id='3b6ddd4c-1cb7-4468-aeab-fd4e54e8b03f' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/tom-kramer' WHERE id='bd6fa242-e96a-4bb1-8c87-1d4abcd100de' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/john-wisch' WHERE id='2d0e85a2-ab25-4a0a-9f94-b8dc2c78a946' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/scott-maier' WHERE id='ecf42f21-d452-4039-b24d-8480e8d858e5' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/robert-d-grove' WHERE id='b249285b-0d3f-45ea-8d6d-5ce965a6c79e' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/tom-hincz' WHERE id='d5d3fcd5-0ece-454a-8f17-dd3549a67812' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/thomas-pringle' WHERE id='f64a25b4-cc2f-48fa-8910-dec51d8bcce9' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-board/county-board-of-supervisors/mike-dawson' WHERE id='57e48782-606a-4793-aca7-5fd13dc5e4f0' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/county-executive' WHERE id='0a695784-7fe4-4545-bf90-9e1770db5709' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/sheriff-s-office' WHERE id='b5485814-7374-44bc-a8da-f2e7188c01fe' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/clerk-of-circuit-court-5279' WHERE id='1349f478-b02b-427a-9837-8822673133c5' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.racinecounty.gov/departments/district-attorney' WHERE id='e444877d-286c-4bc8-93c8-c48fe5f6dbf2' AND photo_origin_url IS NULL;

-- 3) Emails ---------------------------------------------------------------
UPDATE essentials.politicians SET email_addresses=ARRAY['Valena.Coleman@racinecounty.gov'] WHERE id='1c3fa486-3719-402e-b4d5-65680870eabe' AND NOT ('Valena.Coleman@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D1 Valena Lena Coleman
UPDATE essentials.politicians SET email_addresses=ARRAY['Renee.Kelly@racinecounty.gov'] WHERE id='6c040b24-d9cc-48ad-8271-3cfead5a6c5d' AND NOT ('Renee.Kelly@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D2 Renee Kelly
UPDATE essentials.politicians SET email_addresses=ARRAY['Monte.Osterman@racinecounty.gov'] WHERE id='3130fabe-aaa0-42c6-aa28-04e9c2ab612a' AND NOT ('Monte.Osterman@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D3 Monte Osterman
UPDATE essentials.politicians SET email_addresses=ARRAY['mkb@racinecounty.gov'] WHERE id='33cdad7e-ada6-4da9-9e99-64bc510fbb6e' AND NOT ('mkb@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D4 Melissa Kaprelian
UPDATE essentials.politicians SET email_addresses=ARRAY['Jody.Spencer@racinecounty.gov'] WHERE id='fdba65d2-19ae-4cb5-a69e-bd6ca60aeecf' AND NOT ('Jody.Spencer@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D5 Jody Spencer
UPDATE essentials.politicians SET email_addresses=ARRAY['QA.Shakoor@racinecounty.gov'] WHERE id='1375a361-0ef9-4ef6-9d33-8f4bc6c79a4e' AND NOT ('QA.Shakoor@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D6 Q.A. Shakoor, II
UPDATE essentials.politicians SET email_addresses=ARRAY['Ernie.Rossi@racinecounty.gov'] WHERE id='7dd312fb-8b5c-418b-8e5e-92a585b7cf51' AND NOT ('Ernie.Rossi@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D7 Ernie Rossi
UPDATE essentials.politicians SET email_addresses=ARRAY['Brett.Nielsen@racinecounty.gov'] WHERE id='0446822f-3443-4cfd-8f8b-8793edd0c5b6' AND NOT ('Brett.Nielsen@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D8 Brett A. Nielsen
UPDATE essentials.politicians SET email_addresses=ARRAY['Eric.Hopkins@racinecounty.gov'] WHERE id='e2b79962-0f11-4aa1-8fcf-987275790eb6' AND NOT ('Eric.Hopkins@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D9 Eric Hopkins
UPDATE essentials.politicians SET email_addresses=ARRAY['Tony.Veranth@racinecounty.gov'] WHERE id='b23cda29-b228-4900-ba38-fad82140e184' AND NOT ('Tony.Veranth@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D10 Tony Veranth
UPDATE essentials.politicians SET email_addresses=ARRAY['Robert.Miller@racinecounty.gov'] WHERE id='6b95b80c-22bd-4176-8346-4c5459b5a090' AND NOT ('Robert.Miller@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D11 Robert N. Miller
UPDATE essentials.politicians SET email_addresses=ARRAY['Don.Trottier@racinecounty.gov'] WHERE id='3b6ddd4c-1cb7-4468-aeab-fd4e54e8b03f' AND NOT ('Don.Trottier@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D12 Don Trottier
UPDATE essentials.politicians SET email_addresses=ARRAY['Tom.Kramer@racinecounty.gov'] WHERE id='bd6fa242-e96a-4bb1-8c87-1d4abcd100de' AND NOT ('Tom.Kramer@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D13 Tom Kramer
UPDATE essentials.politicians SET email_addresses=ARRAY['James.Hoffman@racinecounty.gov'] WHERE id='4478ea39-a6a6-495b-93aa-7193bb620675' AND NOT ('James.Hoffman@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D14 James M. Hoffman
UPDATE essentials.politicians SET email_addresses=ARRAY['John.Wisch@racinecounty.gov'] WHERE id='2d0e85a2-ab25-4a0a-9f94-b8dc2c78a946' AND NOT ('John.Wisch@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D15 John Wisch
UPDATE essentials.politicians SET email_addresses=ARRAY['Scott.Maier@racinecounty.gov'] WHERE id='ecf42f21-d452-4039-b24d-8480e8d858e5' AND NOT ('Scott.Maier@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D16 Scott Meier
UPDATE essentials.politicians SET email_addresses=ARRAY['Thomas.Weatherston@racinecounty.gov'] WHERE id='b249285b-0d3f-45ea-8d6d-5ce965a6c79e' AND NOT ('Thomas.Weatherston@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D17 Thomas Weatherston
UPDATE essentials.politicians SET email_addresses=ARRAY['Troy.McReynolds@racinecounty.gov'] WHERE id='19b1b32b-7561-410e-bffd-8b62ba7a1344' AND NOT ('Troy.McReynolds@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D18 Troy McReynolds
UPDATE essentials.politicians SET email_addresses=ARRAY['Greg.Horeth@racinecounty.gov'] WHERE id='d5d3fcd5-0ece-454a-8f17-dd3549a67812' AND NOT ('Greg.Horeth@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D19 Greg Horeth
UPDATE essentials.politicians SET email_addresses=ARRAY['Tom.Preusker@racinecounty.gov'] WHERE id='f64a25b4-cc2f-48fa-8910-dec51d8bcce9' AND NOT ('Tom.Preusker@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D20 Tom Preusker
UPDATE essentials.politicians SET email_addresses=ARRAY['Taylor.Wishau@racinecounty.gov'] WHERE id='57e48782-606a-4793-aca7-5fd13dc5e4f0' AND NOT ('Taylor.Wishau@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- D21 Taylor Wishau
UPDATE essentials.politicians SET email_addresses=ARRAY['RCExecutive@racinecounty.gov'] WHERE id='0a695784-7fe4-4545-bf90-9e1770db5709' AND NOT ('RCExecutive@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- departmental inbox
UPDATE essentials.politicians SET email_addresses=ARRAY['RCClerk@racinecounty.gov'] WHERE id='106bd9ff-a2bd-4d78-bac9-eb10fae5f52c' AND NOT ('RCClerk@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- departmental inbox
UPDATE essentials.politicians SET email_addresses=ARRAY['rod@racinecounty.gov'] WHERE id='b2c0c382-3787-49e1-86ff-d77331479d1d' AND NOT ('rod@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- departmental inbox
UPDATE essentials.politicians SET email_addresses=ARRAY['RCSheriff@racinecounty.gov'] WHERE id='b5485814-7374-44bc-a8da-f2e7188c01fe' AND NOT ('RCSheriff@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- departmental inbox
UPDATE essentials.politicians SET email_addresses=ARRAY['rcclerkofcourts@racinecounty.gov'] WHERE id='1349f478-b02b-427a-9837-8822673133c5' AND NOT ('rcclerkofcourts@racinecounty.gov' = ANY(coalesce(email_addresses,'{}')));  -- departmental inbox

-- 4) District 16 name correction ------------------------------------------
-- The ALL-CAPS roster listing reads MEIER, but his own detail page title and his
-- county email both read Maier. Detail page + email treated as authoritative.
UPDATE essentials.politicians SET full_name='Scott Maier', last_name='Maier'
WHERE id='ecf42f21-d452-4039-b24d-8480e8d858e5' AND full_name='Scott Meier';

INSERT INTO essentials.politician_name_aliases (politician_id, alias, source)
SELECT 'ecf42f21-d452-4039-b24d-8480e8d858e5', 'Scott Meier', 'migration 1472 (racinecounty.gov county board roster listing)'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_name_aliases
                  WHERE politician_id='ecf42f21-d452-4039-b24d-8480e8d858e5' AND alias='Scott Meier');

COMMIT;
