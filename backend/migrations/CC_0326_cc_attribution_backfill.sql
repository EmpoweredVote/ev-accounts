-- CC_0326_cc_attribution_backfill.sql
--
-- Record the attribution source for 78 CC-licensed portraits that carried none.
--
-- THE PROBLEM. Every Creative Commons licence except CC0 requires attribution. These 78 rows hold a
-- CC licence in essentials.politician_images.photo_license and a MIRRORED url on our own CDN, with
-- politicians.photo_origin_url NULL or empty. politician_images has no author, credit or source
-- column, so for these rows the credit the licence requires was recorded NOWHERE.
--
-- WHAT IS WRITTEN. politicians.photo_origin_url = the Wikimedia Commons FILE DESCRIPTION page.
-- 🔴 NOT the upload.wikimedia.org file URL that the original migrations recorded in comments. That
-- URL is the raw bytes: it names no author and states no terms, so storing it would satisfy the
-- column and not the obligation. The description page carries both.
--
-- HOW EACH PAGE WAS ESTABLISHED. Asked for, never constructed. Deriving the page from the upload
-- path is a guess that usually works and, when it does not, yields a 404 or a DIFFERENT file of the
-- same name. Every title here was confirmed through the Commons API (prop=imageinfo,
-- iiprop=extmetadata), which also returned the artist and the licence:
--   * 78 of 78 confirmed, 0 missing;
--   * 78 of 78 carry a named artist;
--   * 78 of 78 state a licence that AGREES with the one already in photo_license -- so this
--     migration corrects no licence and asserts no new one. It fills in the credit for licences
--     that were already right.
-- A sample of pages was then fetched and each was confirmed to render its artist's name, against a
-- control: a fabricated title returns 404, so a 200 means the page is real.
--
-- WHAT IS DELIBERATELY NOT HERE.
--   * 43 further CC rows whose origin this repository does not record anywhere. They stay blank --
--     a blank is findable by the query that looks for missing attribution; an invented or
--     self-referential URL is not. 🔴 3 of those 43 are the trap: the LA County audit records their
--     origin as the literal string "(existing stored photo)" with src_img pointing at OUR OWN
--     bucket. A CDN self-reference is not provenance, and writing it would launder a gap into a fix.
--   * Eric Pratt and Kaela Berg. Their origin IS recorded, but their licence is OVER-CLAIMED:
--     production says cc_by_2.0 and cc_by-sa_4.0 while the Minnesota seed manifests say "press_use"
--     and "Minnesota House of Representatives (used by permission, 2026-09-17)". Writing an origin
--     while the licence still tells the public they may reuse a by-permission portrait would be
--     half a fix, and the wrong half. They need a licence decision first.
--   * Licence-string normalisation. CC BY-SA 4.0 is spelled three ways in production
--     (cc_by_sa_4.0, cc_by-sa_4.0, cc-by-sa-4.0), 3.0 and 2.0 two ways each, and one row records
--     cc_by_sa with no version at all. Any filter on photo_license is therefore already wrong.
--     Fixing it means auditing every reader first; it is not folded in here.
--
-- OVERWRITES NOTHING. The UPDATE is guarded on photo_origin_url being blank, so no existing value
-- is replaced and there is nothing to record a previous value for.
--
-- Run: node backend/scripts/apply-migration-file.mjs backend/migrations/CC_0326_cc_attribution_backfill.sql

BEGIN;

CREATE TEMP TABLE cc_attr (
  politician_id uuid PRIMARY KEY,
  object        text NOT NULL,
  commons_page  text NOT NULL,
  licence       text NOT NULL,
  artist        text NOT NULL,
  name_in_title boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO cc_attr (politician_id, object, commons_page, licence, artist, name_in_title) VALUES
  ('352876f0-02b4-4eba-b979-c99079ab368a'::uuid, '352876f0-02b4-4eba-b979-c99079ab368a-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Adrian_Fontes_2025.jpg', 'cc_by-sa_2.0', 'Gage Skidmore from Surprise, AZ, United States of America', true),
  ('65df6ce5-a824-4b24-a0a9-d031e3631272'::uuid, '65df6ce5-a824-4b24-a0a9-d031e3631272-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Alexi_Giannoulias_2.jpg', 'cc_by-sa_2.0', 'Bart Heird from Chicago', true),
  ('fc75d0fc-a205-43e2-ab13-80a1caecdff5'::uuid, 'fc75d0fc-a205-43e2-ab13-80a1caecdff5-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:AustinDavis.jpg', 'cc_by_2.0', 'Governor Tom Wolf from Harrisburg, PA', true),
  ('3b4ba5e3-226c-4b36-9613-81865f982437'::uuid, '3b4ba5e3-226c-4b36-9613-81865f982437-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Austin_Knudsen.jpg', 'cc_by_4.0', 'Putitonamap98', true),
  ('f5b283b7-8415-47cd-9bbe-e909760a67a3'::uuid, 'f5b283b7-8415-47cd-9bbe-e909760a67a3-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Hob_Nob_on_the_State_Line_with_Tennessee_Governor_Bill_Lee%2C_Bristol_(cropped).2.jpg', 'cc_by_4.0', 'Virginia Office of the Governor', true),
  ('b9854782-7b24-4b4a-ba90-22e9ecf9a3ca'::uuid, 'b9854782-7b24-4b4a-ba90-22e9ecf9a3ca-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Bob_Evnen_1.jpg', 'cc_by_2.0', 'Matt Johnson from Omaha, Nebraska, United States', true),
  ('b8427e5d-f570-45bd-945f-c192e78b4d12'::uuid, 'b8427e5d-f570-45bd-945f-c192e78b4d12-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Bob_Ferguson_at_his_2023_Shrimp_Feed_02_(cropped).jpg', 'cc_by-sa_4.0', 'Joe Mabel', true),
  ('d36ab4ef-dbf4-4b60-9f8b-db497dfb5de4'::uuid, 'd36ab4ef-dbf4-4b60-9f8b-db497dfb5de4-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Brad_Little_official_photo.jpg', 'cc_by-sa_4.0', 'Phil White/Office of the Governor of Idaho.', true),
  ('b5c0a945-8e4f-4617-895d-a75be0e3b48c'::uuid, 'b5c0a945-8e4f-4617-895d-a75be0e3b48c-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Brad_Raffensperger_2022.jpg', 'cc_by-sa_2.0', 'Knight Foundation', true),
  ('1b52da57-06f3-4841-aa1d-8bbbb82f96ea'::uuid, '1b52da57-06f3-4841-aa1d-8bbbb82f96ea-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Brenna_Bird_by_Gage_Skidmore_2.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('d76a1a8b-5316-4e84-b64b-e66843c4763b'::uuid, 'd76a1a8b-5316-4e84-b64b-e66843c4763b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Brian_Kemp_2025_(cropped).jpg', 'cc_by_4.0', 'Governo do Estado de São Paulo', true),
  ('14acb49e-85a6-4367-87fa-0a087d085912'::uuid, '14acb49e-85a6-4367-87fa-0a087d085912-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Burt_Jones_-_Turning_Point_USA_tour_at_University_of_Georgia%2C_April_14%2C_2026_(cropped).jpg', 'cc_by-sa_4.0', 'Gage Skidmore', true),
  ('7b2dfaca-3f6e-4d71-893f-28a278049eda'::uuid, '7b2dfaca-3f6e-4d71-893f-28a278049eda-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Charity_Clark.jpg', 'cc_by_3.0', 'Town Meeting TV', true),
  ('d90f754e-c3c6-44f9-890d-a8f2a9a00d22'::uuid, 'd90f754e-c3c6-44f9-890d-a8f2a9a00d22-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Christopher_M._Carr_by_Gage_Skidmore_(cropped).jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('b503b679-773a-4eee-9c16-e73bff1a723f'::uuid, 'b503b679-773a-4eee-9c16-e73bff1a723f-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Chuck_Gray_in_2025_(cropped).jpg', 'cc_by-sa_2.0', 'Gage Skidmore', true),
  ('0a0736c2-3e12-4296-9abe-d2b7a793c8b8'::uuid, '0a0736c2-3e12-4296-9abe-d2b7a793c8b8-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Cutris_Loftis_(cropped).jpg', 'cc_by-sa_3.0', 'Allen Anderson', true),
  ('125d1783-6548-496c-9499-fbd79a0e4a4e'::uuid, '125d1783-6548-496c-9499-fbd79a0e4a4e-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:RI_Governor_Daniel_McKee.jpg', 'cc_by_4.0', 'Kenneth C. Zirkel', true),
  ('1ce5f060-da97-4d82-8441-e09994095c76'::uuid, '1ce5f060-da97-4d82-8441-e09994095c76-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Dana_Nessel_Michigan_Is_Preparing_for_''Every_Scenario''_on_Election_Day_THE_CIRCUS_SHOWTIME_0-25_screenshot_(cropped).jpg', 'cc_by_3.0', 'SHOWTIME', true),
  ('8868cae5-a50a-483b-be2e-b581894c1b6b'::uuid, '8868cae5-a50a-483b-be2e-b581894c1b6b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Dave_Young_(Colorado_politician)_2022_(cropped).JPG', 'cc_by_4.0', 'Jeffrey Beall', true),
  ('14d42486-4ffc-4305-a998-b5d4d47aaace'::uuid, '14d42486-4ffc-4305-a998-b5d4d47aaace-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:David_Toland_official_photo.jpg', 'cc_by-sa_4.0', 'Office of the Governor of Kansas', true),
  ('1b1a74c3-a6af-4de5-a026-b9564ac7ed41'::uuid, '1b1a74c3-a6af-4de5-a026-b9564ac7ed41-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Dianne_Primavera_2022.jpg', 'cc_by_2.0', 'US Department of Labor', true),
  ('e7f351cf-d668-4d09-b8ff-0f8dbd85b33a'::uuid, 'e7f351cf-d668-4d09-b8ff-0f8dbd85b33a-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Elaine_Marshall_IACA_2018.jpg', 'cc_by-sa_2.0', 'Joe Ross', true),
  ('79276956-dfa1-4bca-9820-ab7c78dd57c8'::uuid, '79276956-dfa1-4bca-9820-ab7c78dd57c8-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Frank_LaRose_by_Gage_Skidmore.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('312e77d1-8fc7-4a75-8731-2f252d72e2a4'::uuid, '312e77d1-8fc7-4a75-8731-2f252d72e2a4-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Garlin_Gilchrist_in_Grand_Rapids.jpg', 'cc_by-sa_4.0', 'Cjh1452000', true),
  ('1021e185-125e-4004-91bb-436a9727e4a9'::uuid, '1021e185-125e-4004-91bb-436a9727e4a9-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Greg_Gianforte_in_2025_(cropped).jpg', 'cc_by-sa_4.0', 'Gage Skidmore', true),
  ('8df7ff47-c5f1-4ba1-82dc-1e8f6abdc753'::uuid, '8df7ff47-c5f1-4ba1-82dc-1e8f6abdc753-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Rhode_Island_Secretary_Of_State_Gregg_M._Amore.jpg', 'cc_by-sa_4.0', 'Kenneth C. Zirkel', true),
  ('3043a446-7107-4532-bd90-9f1a5a2f58a1'::uuid, '3043a446-7107-4532-bd90-9f1a5a2f58a1-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Henry_McMaster_in_2026_(cropped).jpg', 'cc_by-sa_4.0', 'Gage Skidmore', true),
  ('f6456243-9b0e-4c5c-87b2-3740bf833b4b'::uuid, 'f6456243-9b0e-4c5c-87b2-3740bf833b4b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Lt._Governor_Presiding_in_the_Senate_(cropped).jpg', 'cc_by-sa_4.0', 'Scribe of Grant County', false),
  ('95ee890b-81c3-4376-972c-ac474e5a95fe'::uuid, '95ee890b-81c3-4376-972c-ac474e5a95fe-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:James_Diossa%2C_Rhode_Island_General_Treasurer.jpg', 'cc_by-sa_4.0', 'Kenneth C. Zirkel', true),
  ('a9c5e442-1358-43e6-87d2-a4673a811bda'::uuid, 'a9c5e442-1358-43e6-87d2-a4673a811bda-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:John_McCuskey_by_Gage_Skidmore.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('5751ccd5-8b7a-4ce4-9247-e308c703a809'::uuid, '5751ccd5-8b7a-4ce4-9247-e308c703a809-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Jim_Pillen_SelectUSA_(55251574792).jpg', 'cc_by_4.0', 'Maryland GovPics', true),
  ('8638e7a7-ee89-4687-8e93-b31a73872086'::uuid, '8638e7a7-ee89-4687-8e93-b31a73872086-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Jim_Tressel_2025_portrait_(cropped).jpg', 'cc_by-sa_4.0', 'Jesse Lung, Producer, OGT/The Ohio Channel', true),
  ('5d59648a-be0a-4a19-bb3d-344754a559ef'::uuid, '5d59648a-be0a-4a19-bb3d-344754a559ef-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:SOS_Jocelyn_Benson_web.jpg', 'cc_by_4.0', 'JFM Photo 73', true),
  ('f8e66045-33cc-4f0e-ae31-58f58e148f94'::uuid, 'f8e66045-33cc-4f0e-ae31-58f58e148f94-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Joe_Lombardo_by_Gage_Skidmore.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('aa4040bf-4468-460e-8cb4-5a1e2a53c34f'::uuid, 'aa4040bf-4468-460e-8cb4-5a1e2a53c34f-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:JohnRodgers.png', 'cc_by-sa_4.0', 'Lukepblue', true),
  ('76307cf7-47dd-4b0a-ac4b-ed218095bf47'::uuid, '76307cf7-47dd-4b0a-ac4b-ed218095bf47-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Josh_Green_Official_Photo_2022_(cropped)_1cropped).jpg', 'cc_by-sa_4.0', 'Aloha102', true),
  ('9dc798c5-09b7-4d9d-bf8f-e79b0f8c0f74'::uuid, '9dc798c5-09b7-4d9d-bf8f-e79b0f8c0f74-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Josh_Kaul-13_-_44610449305_(3x4b).jpg', 'cc_by_2.0', 'SLR Images', true),
  ('c3956e15-01f6-46cf-95bd-edd43f0ae8f3'::uuid, 'c3956e15-01f6-46cf-95bd-edd43f0ae8f3-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Josh_Shapiro_December_2025.jpg', 'cc_by_4.0', 'Maryland GovPics', true),
  ('05889a4f-f4e5-4fb3-87a4-984bc9c23131'::uuid, '05889a4f-f4e5-4fb3-87a4-984bc9c23131-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Josh_Stein_SelectUSA_(55252715239).jpg', 'cc_by_4.0', 'Maryland GovPics', true),
  ('90369b67-99c3-4e29-9f6c-8529350cf1eb'::uuid, '90369b67-99c3-4e29-9f6c-8529350cf1eb-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Governor_Kathy_Hochul_Press_Conference_(cropped).jpg', 'cc_by_4.0', 'Maryland GovPics', true),
  ('ca092ddd-8ce5-4521-bbbe-38f453650b04'::uuid, 'ca092ddd-8ce5-4521-bbbe-38f453650b04-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Katie_Hobbs_2026.jpg', 'cc_by-sa_4.0', 'Gage Skidmore from Surprise, AZ, United States of America', true),
  ('7044cbb7-0669-4ecc-80a5-058a52472e4b'::uuid, '7044cbb7-0669-4ecc-80a5-058a52472e4b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kevin_Stitt_(55103789989)_(cropped).jpg', 'cc_by_4.0', 'Maryland GovPics', true),
  ('108874f4-314b-44fc-83df-31eea167064b'::uuid, '108874f4-314b-44fc-83df-31eea167064b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kim_Reynolds_by_Gage_Skidmore_2.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('ad8c25f3-538c-48f3-b8db-1d72d7d6d4ca'::uuid, 'ad8c25f3-538c-48f3-b8db-1d72d7d6d4ca-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kimberly_Yee_by_Gage_Skidmore_3.jpg', 'cc_by-sa_3.0', 'Gage Skidmore', true),
  ('e947c3c1-41f5-48d8-b105-5a0c39aa21ae'::uuid, 'e947c3c1-41f5-48d8-b105-5a0c39aa21ae-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kris_Mayes_(52365525231)_(cropped).jpg', 'cc_by-sa_2.0', 'Gage Skidmore from Surprise, AZ, United States of America, Please attribute to Gage Skidmore if used elsewhere.', true),
  ('cd97be85-d6cf-4d08-ab0b-415a06d69d8c'::uuid, 'cd97be85-d6cf-4d08-ab0b-415a06d69d8c-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kristen_Juras.jpg', 'cc_by_4.0', 'Putitonamap98', true),
  ('dcf335bf-ca4f-4878-8ef6-616380ff19db'::uuid, 'dcf335bf-ca4f-4878-8ef6-616380ff19db-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Kwame_Raoul_RFCG.jpg', 'cc_by_2.0', 'Erin Klee from Illinois, United States', true),
  ('0a283b10-918c-4251-899b-5385c9174b6d'::uuid, '0a283b10-918c-4251-899b-5385c9174b6d-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Larry_Rhoden_2025_(cropped).jpg', 'cc_by_2.0', 'U.S. Embassy Jerusalem', true),
  ('d01a39ea-94bf-4064-b3dd-56d3878aab6b'::uuid, 'd01a39ea-94bf-4064-b3dd-56d3878aab6b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Laura_Kelly_official_photo.jpg', 'cc_by-sa_4.0', 'Chris Mullins – Office of the Governor of Kansas', true),
  ('9d8e3a1a-dd68-433e-8f5c-6056317845d5'::uuid, '9d8e3a1a-dd68-433e-8f5c-6056317845d5-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Laura_Montoya_54596229497_(cropped).jpg', 'cc_by_2.0', 'Comptroller of Maryland Brooke Lierman', true),
  ('e8d0cb0c-a145-4483-860e-4e6af68f0a8b'::uuid, 'e8d0cb0c-a145-4483-860e-4e6af68f0a8b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Leslie_Rutledge_(25475720912)_(1).jpg', 'cc_by-sa_2.0', 'Gage Skidmore from Peoria, AZ, United States of America', true),
  ('406dd9be-a751-4685-a946-44806bd01548'::uuid, '406dd9be-a751-4685-a946-44806bd01548-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Letitia_James_Interview_Feb_2020.png', 'cc_by_3.0', 'WBLS', true),
  ('6b1f2035-1e85-4fca-a5e8-b34e0600a473'::uuid, '6b1f2035-1e85-4fca-a5e8-b34e0600a473-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Maggie_Toulouse_Oliver.jpg', 'cc_by_3.0', 'NewMexicoMercury', true),
  ('a5752370-3b1b-4eaa-aced-91e786379b2f'::uuid, 'a5752370-3b1b-4eaa-aced-91e786379b2f-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Mark_Metcalf.jpg', 'cc_by_2.0', 'Manuel Bartual from Madrid, España', true),
  ('e4f4c7bc-9f03-42dc-bac1-bf137ece3d35'::uuid, 'e4f4c7bc-9f03-42dc-bac1-bf137ece3d35-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Michael_Adams.jpg', 'cc_by_3.0', 'UK College of Agriculture, Food and Environment', true),
  ('ee6be9e8-0441-4be8-a71f-f01f7032bcb0'::uuid, 'ee6be9e8-0441-4be8-a71f-f01f7032bcb0-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Michelle_Strinden.jpg', 'cc_by_4.0', 'Putitonamap98', true),
  ('9739fb00-209f-4ed0-ad06-b9d97d74ced1'::uuid, '9739fb00-209f-4ed0-ad06-b9d97d74ced1-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Gov-Mike-DeWine.jpg', 'cc_by-sa_4.0', 'Vivien McClain Photography', true),
  ('33a51039-958f-40c2-974f-e04ea064b419'::uuid, '33a51039-958f-40c2-974f-e04ea064b419-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Governor_Mike_J._Dunleavy_-_Official_Portrait.jpg', 'cc_by-sa_4.0', 'State of Alaska, Office of the Governor', true),
  ('84f33004-e145-4ea7-8c73-c68e2a1048c2'::uuid, '84f33004-e145-4ea7-8c73-c68e2a1048c2-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Frerichs_at_Conflict_of_Interest_Rule_Discussion_with_Sec_Perez_in_Chicago_June_30_2016.jpg', 'cc_by_2.0', 'By US Department of Labor: Scott M. Allen (L-16-06-30-A_0165) [CC BY 2.0 (https://creativecommons.org/licenses/by/2.0)], via Wikimedia Commons', true),
  ('e32910d5-50f2-4ab9-afc0-a5dd605c429b'::uuid, 'e32910d5-50f2-4ab9-afc0-a5dd605c429b-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Mike_Hilgers.jpg', 'cc_by_2.0', 'Matt Johnson from Omaha, Nebraska, United States', true),
  ('cb4548a9-9d24-4696-8f88-8cc140ae88ac'::uuid, 'cb4548a9-9d24-4696-8f88-8cc140ae88ac-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Washington_State_Treasurer_Mike_Pellicciotti_portrait.jpg', 'cc_by-sa_4.0', 'Melissa Ponder of Mel Ponder Photography', true),
  ('20bcd3a8-ccef-4fe3-8897-9333d7e79eb8'::uuid, '20bcd3a8-ccef-4fe3-8897-9333d7e79eb8-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Mike_Pieciak_on_All_Things_LGBTQ_(cropped).jpg', 'cc_by_3.0', 'ORCA Media', true),
  ('eca2c4af-c882-42f6-bcb9-e656e1264758'::uuid, 'eca2c4af-c882-42f6-bcb9-e656e1264758-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Governor_Ned_Lamont_of_Connecticut%2C_official_portrait.jpg', 'cc_by-sa_4.0', 'The Office of Governor Ned Lamont', true),
  ('99762b4d-d69f-4b43-a7fc-3984babb1942'::uuid, '99762b4d-d69f-4b43-a7fc-3984babb1942-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Official_portrait_of_Rt_Hon_Nicholas_Brown_MP_crop_2.jpg', 'cc_by_3.0', 'Richard Townshend', true),
  ('c788d228-1757-4069-bca4-6a9586819dc8'::uuid, 'c788d228-1757-4069-bca4-6a9586819dc8-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:2026PeggyFlanagan.jpg', 'cc_by-sa_4.0', 'Travellers &amp; Tinkers', true),
  ('8dfb13d5-f590-4afb-a00d-58c477f39b94'::uuid, '8dfb13d5-f590-4afb-a00d-58c477f39b94-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Rhode_Island_Lieutenant_governor_Sabina_Matos.jpg', 'cc_by-sa_4.0', 'Kenneth C. Zirkel', true),
  ('fc2b0e86-3e94-4e0b-9812-a154065b5bad'::uuid, 'fc2b0e86-3e94-4e0b-9812-a154065b5bad-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Sarah_Copeland-Hanzas_at_Secretary_of_State_Democratic_Party_Primary_Forum_(cropped).jpg', 'cc_by_3.0', 'Town Meeting TV', true),
  ('9547b530-f40b-4802-b621-fb64571670e4'::uuid, '9547b530-f40b-4802-b621-fb64571670e4-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Sarah_Godlewski_Photo.jpg', 'cc_by-sa_4.0', 'Lisacheese', true),
  ('8cb018dc-a962-47b1-813c-6d1322b36037'::uuid, '8cb018dc-a962-47b1-813c-6d1322b36037-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Scott_Bedke_in_2022_(cropped).jpg', 'cc_by-sa_4.0', 'Darren Damon', true),
  ('e752a957-c776-4942-9aae-63ebf23174ac'::uuid, 'e752a957-c776-4942-9aae-63ebf23174ac-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Scott_Schwab_official_photo_(cropped).jpg', 'cc_by-sa_4.0', 'Kansas Secretary of State', true),
  ('066f7bc5-6e3d-4d17-9878-73d896a2369e'::uuid, '066f7bc5-6e3d-4d17-9878-73d896a2369e-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Stacy_Garrity%2C_2024.jpg', 'cc_by_3.0', 'WOLF-TV', true),
  ('d33b1fb5-bac7-48b9-9628-8169e28f4e16'::uuid, 'd33b1fb5-bac7-48b9-9628-8169e28f4e16-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Steve_Marshall_(41773693585).jpg', 'cc_by-sa_2.0', 'repmobrooks', true),
  ('d95b4426-cd5e-4970-a46e-ae9b7ee16012'::uuid, 'd95b4426-cd5e-4970-a46e-ae9b7ee16012-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:2026SteveSimon.jpg', 'cc_by-sa_4.0', 'Travellers &amp; Tinkers', true),
  ('f22b744c-6857-4c75-bce0-3b58d592259c'::uuid, 'f22b744c-6857-4c75-bce0-3b58d592259c-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Bysiewicz_Sworn_In_(cropped).jpg', 'cc_by-sa_2.0', 'Liam Enea', true),
  ('8f5b07af-7932-49d4-9164-6277781a541e'::uuid, '8f5b07af-7932-49d4-9164-6277781a541e-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:TPD''s_Headshot_(cropped).jpg', 'cc_by-sa_4.0', 'Office of NYS Comptroller', false),
  ('0ef0cb58-09c9-4c21-b81e-5b676cae23f8'::uuid, '0ef0cb58-09c9-4c21-b81e-5b676cae23f8-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Tony_Evers_-_2022_(a).jpg', 'cc_by_2.0', 'Tony Evers', true),
  ('7a0a5ed5-2a17-4fa8-8197-a589a4f5e2ab'::uuid, '7a0a5ed5-2a17-4fa8-8197-a589a4f5e2ab-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Young_Boozer_2023.jpg', 'cc_by-sa_4.0', 'GlendaAU', true),
  ('0e1c737b-223a-4008-8389-1307c00567e9'::uuid, '0e1c737b-223a-4008-8389-1307c00567e9-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Zach_Conine%2C_Nevada_State_Treasurer%2C_USA_-_cropped.jpg', 'cc_by_2.0', 'Horasis', true);

-- ---------------------------------------------------------------------------------------------
-- Pre-flight. Each assertion is a different way this could be wrong.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM cc_attr;
  IF n <> 78 THEN RAISE EXCEPTION 'pre-flight: expected 78 rows staged, found %', n; END IF;

  -- Every target must exist.
  SELECT count(*) INTO n FROM cc_attr a
    JOIN essentials.politicians p ON p.id = a.politician_id;
  IF n <> 78 THEN RAISE EXCEPTION 'pre-flight: expected 78 politicians to exist, found %', n; END IF;

  -- None may already carry an origin. If one does, something wrote it since this was measured and
  -- this migration must not silently disagree with it.
  SELECT count(*) INTO n FROM cc_attr a
    JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE coalesce(p.photo_origin_url, '') <> '';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % target(s) already carry photo_origin_url', n; END IF;

  -- 🔴 BIND TO THE PHOTOGRAPH, NOT JUST THE PERSON. The credit belongs to one image. If the
  -- default image has been replaced since this was measured, the recorded artist describes a
  -- picture that is no longer there, and attributing it would be a false statement about the
  -- photograph on screen.
  SELECT count(*) INTO n FROM cc_attr a
    JOIN essentials.politician_images pi ON pi.politician_id = a.politician_id AND pi.type = 'default'
   WHERE regexp_replace(substring(pi.url from 'politician_photos/(.*)$'), '\?.*$', '') = a.object
     AND lower(pi.photo_license) = lower(a.licence);
  IF n <> 78 THEN
    RAISE EXCEPTION 'pre-flight: expected 78 default images matching both object and licence, found %', n;
  END IF;

  -- 🔴 DOES THE CREDIT LAND ON THE RIGHT FACE? The object key says which row; it does not say that
  -- the Commons page depicts this person. The filename is an independent signal, and 76 of 78
  -- contain the surname. Exactly 2 do not, and both were confirmed by READING the page -- each is
  -- named in its description and in its categories:
  --   Howie Morales    File:Lt._Governor_Presiding_in_the_Senate_(cropped).jpg
  --   Thomas DiNapoli  File:TPD's_Headshot_(cropped).jpg
  -- If this count moves, the generator has paired a page with someone it was not confirmed against.
  -- Recomputed HERE, from essentials.politicians.full_name, NOT from the staged name_in_title
  -- column. 🔴 THAT COLUMN IS DERIVED BY THE SAME GENERATOR THAT DID THE PAIRING, so on its own it
  -- moves with the defect it is supposed to catch: swap two rows' pages after generation and the
  -- flags still say true. This check reads the database's own name and the page URL, so a swapped
  -- or mispaired page shows up as a surname that is not in its own title.
  SELECT count(*) INTO n
    FROM cc_attr a
    JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE position(
           lower(regexp_replace(split_part(replace(p.full_name, '.', ' '), ' ',
                 array_length(string_to_array(trim(replace(p.full_name, '.', ' ')), ' '), 1)),
                 '[^A-Za-z]', '', 'g'))
           IN lower(regexp_replace(a.commons_page, '[^A-Za-z]', '', 'g'))
         ) = 0;
  IF n <> 2 THEN
    RAISE EXCEPTION 'pre-flight: expected exactly 2 rows whose surname is absent from their Commons page, found %', n;
  END IF;

  SELECT count(*) INTO n FROM cc_attr WHERE NOT name_in_title;
  IF n <> 2 THEN
    RAISE EXCEPTION 'pre-flight: expected exactly 2 confirmed name exceptions, found %', n;
  END IF;
  SELECT count(*) INTO n FROM cc_attr
   WHERE NOT name_in_title
     AND politician_id NOT IN ('f6456243-9b0e-4c5c-87b2-3740bf833b4b'::uuid,
                               '8f5b07af-7932-49d4-9164-6277781a541e'::uuid);
  IF n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % unbound row(s) are not the two confirmed exceptions', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET photo_origin_url = a.commons_page
  FROM cc_attr a
 WHERE p.id = a.politician_id
   AND coalesce(p.photo_origin_url, '') = '';

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int; blanks int;
BEGIN
  SELECT count(*) INTO n FROM cc_attr a
    JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE p.photo_origin_url = a.commons_page;
  IF n <> 78 THEN RAISE EXCEPTION 'post-verify: expected 78 rows to carry their Commons page, found %', n; END IF;

  SELECT count(*) INTO n FROM cc_attr a
    JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE p.photo_origin_url NOT LIKE 'https://commons.wikimedia.org/wiki/File:%';
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: % row(s) do not point at a Commons file page', n; END IF;

  -- The 45 this migration deliberately does not touch must STAY blank: 43 with no recorded origin
  -- (3 of them CDN self-references) plus Pratt and Berg, who need a licence decision first. If this
  -- number moves, someone has filled one in from a source nobody audited.
  SELECT count(*) INTO blanks
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.type = 'default'
     AND pi.photo_license ILIKE 'cc%'
     AND lower(pi.photo_license) <> 'cc0'
     AND coalesce(p.photo_origin_url, '') = '';
  IF blanks <> 45 THEN
    RAISE EXCEPTION 'post-verify: expected the other 45 attribution-owing rows to stay blank, found % blank', blanks;
  END IF;
END $$;

COMMIT;
