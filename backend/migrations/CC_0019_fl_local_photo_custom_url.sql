-- CC_0019_fl_local_photo_custom_url.sql
-- Make FL-7's 71 Florida local and county officials render the headshots we already host.
--
-- THE DEFECT. FL-7 mirrored these 72 people into our bucket and correctly set
-- photo_origin_url to the SOURCE PAGE (provenance). It never set photo_custom_url. The
-- address-search path builds its photo from
--     COALESCE(p.photo_custom_url, p.photo_origin_url, '')
-- (backend/src/lib/districtQueries.ts, DISTRICT_SELECT_FIELDS) and NEVER READS
-- essentials.politician_images. So with photo_custom_url empty these rows handed an HTML
-- PAGE URL to an <img src>. Checked 2026-08-30: those URLs return text/html, one returns
-- 403. 54 of 55 COUNTY and 17 of 17 LOCAL were in this state; the 1 COUNTY row that
-- already had photo_custom_url set is untouched by the guard below.
--
-- This is the same defect CC_0018 fixed for the 155 state legislators, in the cohort that
-- introduced it. The importer itself was fixed in the same pass so new waves cannot repeat
-- it (scripts/import-headshot-candidates.py now writes photo_custom_url).
--
-- Every one of the 71 CDN URLs was byte-checked before this was written: all 71 return a
-- real JPEG/PNG magic number, not an HTTP status and not a file extension.
--
-- photo_origin_url is DELIBERATELY NOT TOUCHED. It already holds the correct provenance
-- page. Only the render field is missing.
--
-- Guarded on photo_custom_url still being empty, so a re-run is a no-op and a row someone
-- has since set by hand is left alone.

BEGIN;

CREATE TEMP TABLE _fl_local_photos (pid uuid, cdn_url text) ON COMMIT DROP;

INSERT INTO _fl_local_photos (pid, cdn_url) VALUES
    ('c5ca3774-67db-4674-9b9f-9002591af297'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c5ca3774-67db-4674-9b9f-9002591af297-headshot.jpg'),  -- Akin Akinyemi
    ('4a6b8323-b563-4349-8090-9cb794dc40d1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a6b8323-b563-4349-8090-9cb794dc40d1-headshot.jpg'),  -- Alina Garcia
    ('9a5ba4af-b368-45a3-aaa2-ccdc66197034'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9a5ba4af-b368-45a3-aaa2-ccdc66197034-headshot.jpg'),  -- Amanda Ballard
    ('760efd50-9c39-4d3b-aca3-03ef26e92c8a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/760efd50-9c39-4d3b-aca3-03ef26e92c8a-headshot.jpg'),  -- Angelina "Angel" Colonneso
    ('419df08c-63fc-4245-b584-2613f9d53139'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/419df08c-63fc-4245-b584-2613f9d53139-headshot.jpg'),  -- Anne M. Gannon
    ('d1404db5-02c6-4880-a8f5-3fe2c7d4d2d0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d1404db5-02c6-4880-a8f5-3fe2c7d4d2d0-headshot.jpg'),  -- Anthony Rodriguez
    ('1711a389-bf8a-4cd5-b993-0513f256f947'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1711a389-bf8a-4cd5-b993-0513f256f947-headshot.jpg'),  -- Bill Proctor
    ('ee01e78f-38c1-4c83-8f4e-e2c12a8b1bcf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ee01e78f-38c1-4c83-8f4e-e2c12a8b1bcf-headshot.jpg'),  -- Bobby Powell Jr.
    ('3a6030d7-049d-475d-b48c-cabf21720b57'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3a6030d7-049d-475d-b48c-cabf21720b57-headshot.jpg'),  -- Brian Welch
    ('c7d6c1bc-9349-4ba0-9987-d1693b29a49c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7d6c1bc-9349-4ba0-9987-d1693b29a49c-headshot.jpg'),  -- Carolyn D. Cummings
    ('9647fef1-fd13-4406-9104-6619a2d4868c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9647fef1-fd13-4406-9104-6619a2d4868c-headshot.jpg'),  -- Charles E. Hackney
    ('9325fe3a-63e0-42f3-b7ca-cc23d05ecdc4'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9325fe3a-63e0-42f3-b7ca-cc23d05ecdc4-headshot.jpg'),  -- Charles R. "Rick" Wells
    ('2610e93d-dadf-4ae5-9254-52c1bd96437d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2610e93d-dadf-4ae5-9254-52c1bd96437d-headshot.jpg'),  -- Christian Caban
    ('11f50757-0cfa-459b-a6cf-57af9e7eb50a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/11f50757-0cfa-459b-a6cf-57af9e7eb50a-headshot.jpg'),  -- Christine King
    ('5b9af6ce-da40-4171-b13c-4c45d2c6ec02'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5b9af6ce-da40-4171-b13c-4c45d2c6ec02-headshot.jpg'),  -- Curtis Richardson
    ('fbb0d440-8838-4965-ad03-ca6cd7d61ef5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fbb0d440-8838-4965-ad03-ca6cd7d61ef5-headshot.jpg'),  -- Damian Pardo
    ('e83d4e27-df48-445b-bd2d-5f371ecfed9a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e83d4e27-df48-445b-bd2d-5f371ecfed9a-headshot.jpg'),  -- Daniella Levine Cava
    ('0d13108c-a1ad-4747-b8b4-5db47c0e6941'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0d13108c-a1ad-4747-b8b4-5db47c0e6941-headshot.jpg'),  -- Danielle Cohen Higgins
    ('f8d82d6b-91f1-4fc3-80ad-7e51ab96ea13'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8d82d6b-91f1-4fc3-80ad-7e51ab96ea13-headshot.jpg'),  -- Dariel Fernandez
    ('c2d842e7-c5d5-4d3a-843b-14d6ae36da30'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2d842e7-c5d5-4d3a-843b-14d6ae36da30-headshot.jpg'),  -- David O'Keefe
    ('b66b8326-2578-4ae5-8240-c6768588df99'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b66b8326-2578-4ae5-8240-c6768588df99-headshot.jpg'),  -- Dianne Williams-Cox
    ('8177cd69-f53e-4e3c-8137-d021065c4978'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8177cd69-f53e-4e3c-8137-d021065c4978-headshot.jpg'),  -- Doris Maloy
    ('abda71bd-6c1d-4b18-9190-96cc192afb3a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/abda71bd-6c1d-4b18-9190-96cc192afb3a-headshot.jpg'),  -- Dorothy Jacks
    ('8f1b66d0-68ef-4e21-9f66-45fced3d0b90'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f1b66d0-68ef-4e21-9f66-45fced3d0b90-headshot.jpg'),  -- Dr. Bob McCann
    ('341a5784-4dde-4a4b-a84a-ec51d765cf55'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/341a5784-4dde-4a4b-a84a-ec51d765cf55-headshot.jpg'),  -- Eileen Higgins
    ('4a075943-d0df-46a2-beab-36675a5cd9e6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4a075943-d0df-46a2-beab-36675a5cd9e6-headshot.jpg'),  -- Gene Brown
    ('e831875e-c406-4b9e-9180-f420446622bf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e831875e-c406-4b9e-9180-f420446622bf-headshot.jpg'),  -- George Kruse
    ('84b4e65b-ee92-44d7-86f3-b09c61c7e702'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/84b4e65b-ee92-44d7-86f3-b09c61c7e702-headshot.jpg'),  -- Gregg K. Weiss
    ('7f45cc7e-5404-411e-b685-51d28ae6d63b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f45cc7e-5404-411e-b685-51d28ae6d63b-headshot.jpg'),  -- Gwen Marshall
    ('34521ee7-a88d-4030-afb7-d098574b174f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/34521ee7-a88d-4030-afb7-d098574b174f-headshot.jpg'),  -- Jacqueline "Jack" Porter
    ('472543fd-e529-421e-9270-b0316358410a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/472543fd-e529-421e-9270-b0316358410a-headshot.jpg'),  -- Jason Bearden
    ('6a4f5751-a66f-4997-9678-0b3f1738fc90'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6a4f5751-a66f-4997-9678-0b3f1738fc90-headshot.jpg'),  -- Jayne Kocher
    ('cfb2cfd1-8e68-4166-ae97-d27ac192f417'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cfb2cfd1-8e68-4166-ae97-d27ac192f417-headshot.jpg'),  -- Jeremy Matlow
    ('2978bb25-4dfd-46b2-85ff-017d8610f7b7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2978bb25-4dfd-46b2-85ff-017d8610f7b7-headshot.jpg'),  -- Joel G. Flores
    ('be040f10-f5a4-4661-835f-8e4604b89860'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/be040f10-f5a4-4661-835f-8e4604b89860-headshot.jpg'),  -- John Dailey
    ('a4dd3e61-d742-40c2-a180-f781f4137cf1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a4dd3e61-d742-40c2-a180-f781f4137cf1-headshot.jpg'),  -- Juan Carlos "JC" Bermudez
    ('3f0e8be4-0a63-47b3-a924-e750a16c48b6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3f0e8be4-0a63-47b3-a924-e750a16c48b6-headshot.jpg'),  -- Juan Fernandez-Barquin
    ('a4e632ee-88fd-443a-bf8d-9d75221835dd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a4e632ee-88fd-443a-bf8d-9d75221835dd-headshot.jpg'),  -- Kemp Schuessler
    ('01463105-eae5-4037-b5e7-a86e3ec9ced9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01463105-eae5-4037-b5e7-a86e3ec9ced9-headshot.jpg'),  -- Ken Burton, Jr.
    ('5f074ffb-314c-4395-a2df-cdd37a7eb34f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5f074ffb-314c-4395-a2df-cdd37a7eb34f-headshot.jpg'),  -- Keon Hardemon
    ('189fb6bd-55ed-4a4d-992a-ba86f8df1ead'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/189fb6bd-55ed-4a4d-992a-ba86f8df1ead-headshot.jpg'),  -- Kionne L. McGhee
    ('5bf953c6-d159-42f9-9bf2-f5451a96809f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5bf953c6-d159-42f9-9bf2-f5451a96809f-headshot.jpg'),  -- Lisa Gonzalez Moore
    ('67bf315c-4775-40c1-ab5c-4fa115e9c974'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/67bf315c-4775-40c1-ab5c-4fa115e9c974-headshot.jpg'),  -- Marci Woodward
    ('a9f3a6d4-6d1a-4687-b797-6dee01fed72d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a9f3a6d4-6d1a-4687-b797-6dee01fed72d-headshot.jpg'),  -- Maria G. Marino
    ('f48fe0d8-468e-4941-8a09-e140f37a0322'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f48fe0d8-468e-4941-8a09-e140f37a0322-headshot.jpg'),  -- Maria Sachs
    ('d3be3b8b-df3f-4878-9c13-af097d7d032b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3be3b8b-df3f-4878-9c13-af097d7d032b-headshot.jpg'),  -- Marianne Barnebey
    ('518df864-1375-4de9-a068-fb9f4205f627'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/518df864-1375-4de9-a068-fb9f4205f627-headshot.jpg'),  -- Mark S. Earley
    ('23950def-95e8-4282-b3b5-5d0a86e29b36'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/23950def-95e8-4282-b3b5-5d0a86e29b36-headshot.jpg'),  -- Marleine Bastien
    ('237fe767-ea76-45d3-8ded-95e623dbce8f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/237fe767-ea76-45d3-8ded-95e623dbce8f-headshot.jpg'),  -- Micky Steinberg
    ('36771b52-7e86-4199-a3d7-ebc63489dedd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/36771b52-7e86-4199-a3d7-ebc63489dedd-headshot.jpg'),  -- Miguel Angel Gabela
    ('ce28e398-7169-4a53-ad01-dd2afd00fce7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ce28e398-7169-4a53-ad01-dd2afd00fce7-headshot.jpg'),  -- Mike Rahn
    ('8f68ac99-9e0b-4b08-9bf4-4bd59e3297a8'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f68ac99-9e0b-4b08-9bf4-4bd59e3297a8-headshot.jpg'),  -- Natalie Milian Orbis
    ('dbc2f9d8-a7ce-4874-a4b7-10f053409046'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbc2f9d8-a7ce-4874-a4b7-10f053409046-headshot.jpg'),  -- Nick Maddox
    ('e9e16972-9298-4ea8-afaa-f5e191c96c83'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9e16972-9298-4ea8-afaa-f5e191c96c83-headshot.jpg'),  -- Pam Coachman
    ('989996df-6af2-4fb3-95b8-99caea16bee5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/989996df-6af2-4fb3-95b8-99caea16bee5-headshot.jpg'),  -- Ralph "Rafael" Rosado
    ('ab1cf05e-cb5e-461a-8723-7ee87adac518'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ab1cf05e-cb5e-461a-8723-7ee87adac518-headshot.jpg'),  -- Raquel A. Regalado
    ('385f0162-a7ac-445a-9522-abe0491b65dd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/385f0162-a7ac-445a-9522-abe0491b65dd-headshot.jpg'),  -- René Garcia
    ('2bc57f81-1bea-4602-8e36-40a915f021f9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2bc57f81-1bea-4602-8e36-40a915f021f9-headshot.jpg'),  -- Ric L. Bradshaw
    ('dc74d16c-1bac-464f-9fbd-1d7e2e6f7bbb'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc74d16c-1bac-464f-9fbd-1d7e2e6f7bbb-headshot.jpg'),  -- Rick Minor
    ('3e24904c-c172-40d3-ad27-fd65927927a2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3e24904c-c172-40d3-ad27-fd65927927a2-headshot.jpg'),  -- Roberto J. Gonzalez
    ('2a4901c9-5491-4582-b893-e7ea78459cd6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2a4901c9-5491-4582-b893-e7ea78459cd6-headshot.jpg'),  -- Rocky Hanna
    ('e1385747-e3fb-4d30-aa7c-359faddadc0c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e1385747-e3fb-4d30-aa7c-359faddadc0c-headshot.jpg'),  -- Rolando Escalona
    ('5f19081b-e438-4654-b715-ba792f0b28cf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5f19081b-e438-4654-b715-ba792f0b28cf-headshot.jpg'),  -- Rosanna "Rosie" Cordero-Stutz
    ('47217f23-4c31-430a-b794-ccecf24c8542'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47217f23-4c31-430a-b794-ccecf24c8542-headshot.jpg'),  -- Sara Baxter
    ('b6c533c4-66f1-4bff-bc02-ec4136f96538'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6c533c4-66f1-4bff-bc02-ec4136f96538-headshot.jpg'),  -- Scott Farrington
    ('158b062f-8fee-4f04-b18a-289eb0c7e059'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/158b062f-8fee-4f04-b18a-289eb0c7e059-headshot.jpg'),  -- Shannon Ramsey-Chessman
    ('232cf97b-09a9-4cf6-8913-e767b9d09a11'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/232cf97b-09a9-4cf6-8913-e767b9d09a11-headshot.jpg'),  -- Tal Siddique
    ('68b2866a-f427-4cad-8f2b-cf5a431b5f07'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/68b2866a-f427-4cad-8f2b-cf5a431b5f07-headshot.jpg'),  -- Tomas Regalado
    ('7bb3b4b3-20fa-44df-b4cc-fdef4b587c46'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7bb3b4b3-20fa-44df-b4cc-fdef4b587c46-headshot.jpg'),  -- Vicki L. Lopez
    ('e19a23bd-f300-4c9b-87c7-db5ab9e1370c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e19a23bd-f300-4c9b-87c7-db5ab9e1370c-headshot.jpg'),  -- Walt McNeil
    ('7c536709-cec2-4409-aff8-ccc0fb469d3d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c536709-cec2-4409-aff8-ccc0fb469d3d-headshot.jpg')  -- Wendy Sartory Link
;

UPDATE essentials.politicians p
   SET photo_custom_url = f.cdn_url
  FROM _fl_local_photos f
 WHERE p.id = f.pid
   AND btrim(COALESCE(p.photo_custom_url, '')) = '';

DO $$
DECLARE
  n_total      int;
  n_no_render  int;
  n_non_image  int;
  n_lost_prov  int;
BEGIN
  SELECT count(*) INTO n_total FROM _fl_local_photos;
  IF n_total <> 71 THEN
    RAISE EXCEPTION 'expected 71 Florida local/county officials, got %', n_total;
  END IF;

  -- What the address-search path will now render must be our own bucket.
  SELECT count(*) INTO n_no_render
    FROM _fl_local_photos f JOIN essentials.politicians p ON p.id = f.pid
   WHERE COALESCE(NULLIF(btrim(p.photo_custom_url), ''), p.photo_origin_url, '')
         NOT LIKE '%storage.supabase.co%';
  IF n_no_render <> 0 THEN
    RAISE EXCEPTION '% official(s) would still render from a third-party host', n_no_render;
  END IF;

  -- And it must be an image, not a page. This is the bug being fixed; assert it is gone.
  SELECT count(*) INTO n_non_image
    FROM _fl_local_photos f JOIN essentials.politicians p ON p.id = f.pid
   WHERE COALESCE(NULLIF(btrim(p.photo_custom_url), ''), p.photo_origin_url, '')
         !~* '\.(jpg|jpeg|png|webp)(\?|$)';
  IF n_non_image <> 0 THEN
    RAISE EXCEPTION '% official(s) would still render a non-image URL', n_non_image;
  END IF;

  -- Provenance must survive untouched: every one still points at a source PAGE.
  SELECT count(*) INTO n_lost_prov
    FROM _fl_local_photos f JOIN essentials.politicians p ON p.id = f.pid
   WHERE p.photo_origin_url IS NULL
      OR p.photo_origin_url ~* '\.(jpg|jpeg|png|webp)(\?|$)';
  IF n_lost_prov <> 0 THEN
    RAISE EXCEPTION '% row(s) lost their source-page provenance', n_lost_prov;
  END IF;

  RAISE NOTICE 'OK: 71 Florida local/county officials now render from our bucket';
END $$;

COMMIT;
