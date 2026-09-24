-- CA_0210_indiana_county_geo_mtfcc_body_rows.sql
--
-- Three follow-ups to CA_0208 for the nine legacy Indiana county governments (Brown, Greene, Jackson,
-- Lawrence, Martin, Morgan, Owen, Marion, Monroe):
--   1. governments.geo_id  NULL -> the county FIPS, on the nine county government rows.
--   2. districts.mtfcc     'G5220' / '' -> 'G4020', on the 139 county-wide COUNTY and JUDICIAL districts of
--                          seven of them (every such district in the database outside G4020).
--   3. government_bodies   delete the 130 per-seat rows CA_0208 left unmatched (full pre-image below).
--
-- 1. governments.geo_id — WHY
-- ---------------------------
-- Three readers key on governments.geo_id, and all three miss these counties today (measured 2026-09-24):
--   * location search (locationSearchService, curated CTE): COALESCE(g.geo_id, <a G4110/G4020 district of
--     the government>) — the fallback finds nothing for the seven counties whose districts carry G5220 or ''
--     (step 2), so "Greene County" and "Marion County" return an Indiana candidate with geo_id null and no
--     usable link. Brown and Monroe resolve only through the fallback.
--   * browse by government list (essentialsBrowseService, government step: WHERE g.geo_id = ANY($1)): the
--     county's own officials reach the page only through the geofence-overlap step, so an official whose
--     district has no geofence is missing. A read-only replay of the government step with the FIPS set adds
--     exactly 10 seated council members who are not on the page today: Greene Council Districts 1-4,
--     Lawrence 1-4, Jackson 1, Morgan 4 (their districts 18055000N / 18093000N / 1807100001 / 1810900004
--     have no geofence). Everyone else it returns is already on the page. With skip_overlap (the county
--     deep-link form) the page holds only the 52 statewide officials today and no county official at all.
--   * elections by government list (electionService fetchGovernmentRaceRows): county-government races.
--     None are seeded for these offices today, so nothing changes there yet.
--   No other government row carries any of the nine FIPS (checked). Four of them collide with a state
--   house geo_id (18055 / 18071 / 18093 / 18097 are also IN House Districts 55 / 71 / 93 / 97, layer
--   G5220); the location search orders its geofence join by mtfcc and takes G4020, the county.
--   Known cost: in browse, the government step's row wins over the overlap step's row for the same person
--   and carries no government_bodies website, so Monroe's headings lose their in.gov links in browse (the
--   address page keeps them). Labels do not change: after CA_0208 Monroe's body rows and its chambers'
--   name_formal read the same.
--
-- 2. districts.mtfcc — WHY
-- ------------------------
-- 96 COUNTY + 43 JUDICIAL districts carry a county FIPS geo_id with mtfcc 'G5220' (Greene, Jackson,
-- Lawrence, Marion) or '' (Martin, Morgan, Owen); every one has a G4020 geofence, and these are the only
-- county-wide districts in the database not on G4020. Address matching keys on the GEOFENCE's mtfcc, so
-- it is unaffected, but two readers use the district's own:
--   * electionService (address elections): the geofence lateral takes the first boundary with
--     `gbo.mtfcc = d.mtfcc` — for a G5220 district on 18055 that is INDIANA HOUSE DISTRICT 55's polygon,
--     so a Greene County race would be shown to House District 55 and hidden from the rest of the county.
--     Latent: no race is on these offices today.
--   * locationSearchService fallback (above) accepts only G4110 / G4020 districts.
--
-- 3. government_bodies — WHY
-- --------------------------
-- CA_0208 gave the per-seat chambers of the eight neighbours a shared name_formal, so their 131 per-seat
-- body rows (body_key = the seat title, e.g. 'Assessor' at 18013) stopped matching. 130 of them now match
-- no office anywhere (DISTRICT_JOINS keys on state + geo_id + COALESCE(NULLIF(name_formal,''), name)).
-- The 131st, 'City Mayor' at 18097, still matches: the Mayor of Indianapolis (City of Indianapolis
-- government, district 18097 typed COUNTY under Unigov) — it is KEPT. All 130 have an empty website_url.
--
-- NOT CHANGED: no chamber, office, politician, term or race row; no geofence. The City of Indianapolis
-- government (geo_id NULL, 5 of the 25 City-County Council seats, "/Marion City/County Council - District
-- N" chambers) is a separate follow-up.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK:
--   UPDATE essentials.governments SET geo_id = NULL WHERE id IN (SELECT government_id FROM <ca0210_gov>);
--   UPDATE essentials.districts d SET mtfcc = t.old_mtfcc FROM <ca0210_district> t WHERE d.id = t.district_id;
--   INSERT INTO essentials.government_bodies (id, state, geo_id, body_key, display_name, website_url)
--   SELECT * FROM <ca0210_body> ON CONFLICT DO NOTHING;
-- IDEMPOTENT: each step is guarded on the old value; a re-run changes 0 rows and every gate passes.

BEGIN;

CREATE TEMP TABLE ca0210_gov ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('d53aa383-577d-4783-ac57-f94670fc17dc'::uuid, 'Brown County, Indiana, US', '18013'),
  ('b7c8587b-2f10-4979-8df3-ec10d0a69f37'::uuid, 'Greene County, Indiana, US', '18055'),
  ('28d0d034-b742-4660-9a57-406f3950d075'::uuid, 'Jackson County, Indiana, US', '18071'),
  ('f8e1780b-1934-4728-84df-3aea85bb9196'::uuid, 'Lawrence County, Indiana, US', '18093'),
  ('10dc8fce-2722-4301-a896-3bcad3d5e01e'::uuid, 'Marion County, Indiana, US', '18097'),
  ('fff58b9c-cb02-4c96-863b-3e40da464d2b'::uuid, 'Martin County, Indiana, US', '18101'),
  ('6c3875d3-524f-4083-8130-d8caff409956'::uuid, 'Monroe County, Indiana, US', '18105'),
  ('9fc0a81a-ae72-43f1-94c2-d1c2de4cdc91'::uuid, 'Morgan County, Indiana, US', '18109'),
  ('4806e8f0-3ba9-4706-a5a1-f62d3917f0db'::uuid, 'Owen County, Indiana, US', '18119')
) AS v(government_id, name, fips);

CREATE TEMP TABLE ca0210_district ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('3c25021b-271c-47db-850b-a96237ba589b'::uuid, '18055', 'COUNTY', 'G5220', 'At-Large'),
  ('e19d4db5-3d20-4b51-9276-8a89c9a63c3f'::uuid, '18055', 'COUNTY', 'G5220', 'District 1'),
  ('b534dc08-9b47-4c3f-8062-4959b5e113d3'::uuid, '18055', 'COUNTY', 'G5220', 'District 2'),
  ('74be92ff-48e2-4323-ad44-fef6fe84e058'::uuid, '18055', 'COUNTY', 'G5220', 'District 3'),
  ('2a062efc-e033-4b6c-a3a1-186f6b3c61e8'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Assessor'),
  ('7a8a1b5e-f69a-4fbe-bcc4-844946529973'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Auditor'),
  ('36b2ec30-0419-4006-b497-c2c9044e0051'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Circuit Court Clerk'),
  ('e99084a2-47de-43af-b76b-e1089ab6ea2a'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Coroner'),
  ('c730dccf-25b3-4e9a-b8ed-e5461b3baff6'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Prosecuting Attorney'),
  ('25d7f30c-ef80-4c29-96f9-db24ed887048'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Recorder'),
  ('4f7891a5-68b2-4251-82f5-4ca6ebc5e1bd'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Sheriff'),
  ('be92f4ab-d916-4cfb-bb96-6659c0febc72'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Surveyor'),
  ('50c483c1-807b-4f3e-ba26-e07d5069999d'::uuid, '18055', 'COUNTY', 'G5220', 'Greene County Treasurer'),
  ('7636b089-cf87-4104-9e71-dd320ceeffb3'::uuid, '18055', 'JUDICIAL', 'G5220', 'Greene County Superior Court Judge'),
  ('a716e1e6-b1f2-43f4-abd3-5793b72a4209'::uuid, '18055', 'JUDICIAL', 'G5220', 'Indiana Circuit Court Judge - 63rd Circuit (Greene County)'),
  ('3e2b3ab7-f5ad-4614-ac0d-cdcbf5e343ee'::uuid, '18071', 'COUNTY', 'G5220', 'At-Large'),
  ('99b067ff-da67-4b63-bfb4-1112b4dfa1e9'::uuid, '18071', 'COUNTY', 'G5220', 'District 1'),
  ('177daa1b-4a10-40d8-80e3-0064f4362b31'::uuid, '18071', 'COUNTY', 'G5220', 'District 2'),
  ('a7ed8bb9-80d8-4d5b-a06a-53956957b233'::uuid, '18071', 'COUNTY', 'G5220', 'District 3'),
  ('f15bda0f-d0ad-4af2-aec0-add136c1cc10'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Assessor'),
  ('3d93b482-a46c-4842-a8ef-c9f78e286a87'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Auditor'),
  ('f8817d6c-49b3-4bd0-a32f-8952a11fad5e'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Circuit Court Clerk'),
  ('2bac7e5d-44d1-4e9f-9f35-2499f05d2d24'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Coroner'),
  ('3de89150-ef90-40f2-8ef1-a8dd323c6d71'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Prosecuting Attorney'),
  ('9c834868-c949-4a0e-b4b5-8a91aea0403c'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Recorder'),
  ('fae64fbf-f19d-4d56-a6a7-79b128e1261d'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Sheriff'),
  ('4f751458-91df-4665-a785-30d3231fbba8'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Surveyor'),
  ('525e8f9a-96df-40ae-96af-835e130c643f'::uuid, '18071', 'COUNTY', 'G5220', 'Jackson County Treasurer'),
  ('2c6e2bf4-476e-4824-acd2-7b7d0e2552df'::uuid, '18071', 'JUDICIAL', 'G5220', 'Indiana Circuit Court Judge - 40th Circuit (Jackson County)'),
  ('4c54f4a1-624e-4aa6-ba15-6b1e28ce29fa'::uuid, '18071', 'JUDICIAL', 'G5220', 'Jackson County Superior Court Judge - Court 1'),
  ('f3b2e01f-8502-4b57-bc88-20453e02e7df'::uuid, '18071', 'JUDICIAL', 'G5220', 'Jackson County Superior Court Judge - Court 2'),
  ('ac92e145-0b94-4c00-974a-f538b69c52b4'::uuid, '18093', 'COUNTY', 'G5220', 'At-Large'),
  ('f417dd5b-d158-4d86-adcd-89ee461a6544'::uuid, '18093', 'COUNTY', 'G5220', 'District 1'),
  ('689c8dc9-f4dd-4260-8f87-5c5097de4795'::uuid, '18093', 'COUNTY', 'G5220', 'District 2'),
  ('cc294613-91a4-485b-8a6c-eb84a50d0b15'::uuid, '18093', 'COUNTY', 'G5220', 'District 3'),
  ('fe415c6c-54d7-47fb-9564-da4abf8415dc'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Assessor'),
  ('1d035668-60bf-4f0a-bdc8-98b511e3f0ae'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Auditor'),
  ('96c01dda-f041-42ef-a809-4fc3c579ab97'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Circuit Court Clerk'),
  ('08a6dea9-2aba-4ff8-81df-532eb7aa6b3c'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Coroner'),
  ('89427f84-82ad-4359-b0c9-f4e61f9e22aa'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Prosecuting Attorney'),
  ('5651406b-7b8e-42a9-a421-0c0c8caea967'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Recorder'),
  ('e8cabfc1-7c7c-49b8-a29c-d8b80f107c57'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Sheriff'),
  ('aa808599-3cdd-4245-8b49-8eed7f1a6414'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Surveyor'),
  ('e9f1d958-19b2-4d94-8b71-70d7b770325d'::uuid, '18093', 'COUNTY', 'G5220', 'Lawrence County Treasurer'),
  ('2662b070-046d-43c9-9379-dba065098be9'::uuid, '18093', 'JUDICIAL', 'G5220', 'Indiana Circuit Court Judge - 81st Circuit (Lawrence County)'),
  ('19f28026-545f-44c8-9423-45c172342e47'::uuid, '18093', 'JUDICIAL', 'G5220', 'Lawrence County Superior Court Judge - Court 1'),
  ('27b7fa60-00d1-4a7f-9eeb-e27672e24124'::uuid, '18093', 'JUDICIAL', 'G5220', 'Lawrence County Superior Court Judge - Court 2'),
  ('5a836a96-a66e-4d10-ab14-a58a89bcb91d'::uuid, '18097', 'COUNTY', 'G5220', 'Indianapolis City Mayor'),
  ('1bb1a290-7517-47fc-a5a8-b90da10fd745'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Assessor'),
  ('965decf1-5948-4b16-908e-3827d35bebff'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Auditor'),
  ('fc156a86-c8d9-4e4d-bcab-122a09810394'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Circuit Court Clerk'),
  ('bd5c29db-fd9e-49ca-8b01-3426cec2e405'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Coroner'),
  ('080edcec-b3e3-4700-a700-8167430a6c3f'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Prosecuting Attorney'),
  ('2883dcd8-4ab9-48d3-9d05-8844723a1477'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Recorder'),
  ('be8c5772-9017-495b-96b4-ee5de0ea9a40'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Sheriff'),
  ('f3742de9-c642-411e-b919-1e63b4799e2d'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Surveyor'),
  ('c93c8722-d5eb-4f93-98c8-1d57d1ee9d7b'::uuid, '18097', 'COUNTY', 'G5220', 'Marion County Treasurer'),
  ('d2d40ed6-cacf-4bcb-9273-c02a5b2f11ee'::uuid, '18097', 'JUDICIAL', 'G5220', 'Indiana Circuit Court Judge - 19th Circuit (Marion County)'),
  ('e3fce3e3-a4ae-4844-bd4e-a36e1ff1b0cb'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Ayers?)'),
  ('4247a214-471f-4d16-a00b-1ad95b6b662f'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Brown?)'),
  ('7cee5375-9cf2-40c5-8b14-e7f4b71f4079'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Certo?)'),
  ('b0e9338d-c2de-47bd-a6f0-acd3eb3e5d8b'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Charles Miller?)'),
  ('6ddbd2ab-7b1a-441f-b778-7d603253cf2a'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Chavis?)'),
  ('54718529-1de7-4104-8b4c-6e2efbf9477c'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Creason?)'),
  ('0089b7bc-f9ce-404f-afa9-90a24d3c05dd'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Davis?)'),
  ('12122b09-be59-4aaf-b425-691cd42742e9'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Dietrick?)'),
  ('6c0f0fb1-2cd3-4ef8-9cd9-9789b60c8f95'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Eisgruber?)'),
  ('77cfb032-85a0-4e52-8a67-4cdcb20bd3ec'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Garner?)'),
  ('50efa4de-ee0c-492d-853a-1bc5daf11fa5'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Gary Miller?)'),
  ('73a8aa18-9ae2-43e8-83bc-862e70eef942'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Gaughan?)'),
  ('79a4e6b2-f383-495a-ac20-30d56589589b'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Gooden?)'),
  ('cc4de992-1eee-4822-bcf0-9fb06ed4838e'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Graham?)'),
  ('3961fe18-4e88-413e-840b-12551b93d1ad'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Harrison?)'),
  ('c33e9741-1ffa-46d0-bd75-2598849edf48'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Helen W. Marchal?)'),
  ('f3ddeee5-d8a0-4905-a5ca-104806865dff'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Jones?)'),
  ('aad2c86a-d085-4a1f-aa5d-9b4b3c2d2cf5'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Joven?)'),
  ('631e5c98-252f-4809-a76b-eb6b74b623f5'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Kern?)'),
  ('5ebab72e-dbef-4c76-b9cf-003d90be977d'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Klineman?)'),
  ('68634b78-926a-4a28-bcf9-c6f4161f9673'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Marchal?)'),
  ('ca2a05d3-c78b-4975-815a-3d7548ff04f5'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Nelson?)'),
  ('bc4cda58-b214-453a-b0b2-bf7af8a69489'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Oakes?)'),
  ('1536bd5d-26e0-421b-bd56-92a88493fcea'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Oetjen?)'),
  ('0bd4a4ef-b9d7-4dd9-957a-131ef66905cf'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Osborn?)'),
  ('a8396685-cac1-4487-acd9-3ced6822b771'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Rogers?)'),
  ('8b9c2483-d018-4d02-bc1e-a8d6a9f0577d'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Rothenberg?)'),
  ('b80ff06e-5a5b-494f-a1e7-fc970a67fbe5'::uuid, '18097', 'JUDICIAL', 'G5220', 'Marion County Superior Court Judge (Retain Salinas?)'),
  ('10ff5240-2e73-4b4e-b404-2f292e5c997a'::uuid, '18101', 'COUNTY', '', 'At-Large'),
  ('13423554-2a20-43ed-8b97-394e03855c8b'::uuid, '18101', 'COUNTY', '', 'District 1'),
  ('aa9db313-8c5d-40bf-9da9-bc1b248cc648'::uuid, '18101', 'COUNTY', '', 'District 1'),
  ('6ea62b56-a218-4544-8022-751a233a6e43'::uuid, '18101', 'COUNTY', '', 'District 2'),
  ('bc23a324-97c9-48df-bcf4-7e11d7d23c59'::uuid, '18101', 'COUNTY', '', 'District 2'),
  ('8616da39-cbf0-48eb-b1db-6b8dfced47df'::uuid, '18101', 'COUNTY', '', 'District 3'),
  ('a18647c9-ffaa-4930-aa14-5e6f8a65e3ce'::uuid, '18101', 'COUNTY', '', 'District 3'),
  ('b50dab37-0c39-4937-b0b8-0557f6eb4dac'::uuid, '18101', 'COUNTY', '', 'District 4'),
  ('e7bacb58-51d7-432d-9a6e-0de354f70bc4'::uuid, '18101', 'COUNTY', '', 'Martin County Assessor'),
  ('2d07ce1c-6620-405e-9e80-0a8ec68fc8d2'::uuid, '18101', 'COUNTY', '', 'Martin County Auditor'),
  ('3a9d589f-11ea-490d-acb0-5c900f1655a6'::uuid, '18101', 'COUNTY', '', 'Martin County Circuit Court Clerk'),
  ('ff8a0048-60fb-4ed0-8fdb-35936dafb689'::uuid, '18101', 'COUNTY', '', 'Martin County Coroner'),
  ('35bcc685-0095-4427-90f4-e8f35b538b11'::uuid, '18101', 'COUNTY', '', 'Martin County Prosecuting Attorney'),
  ('31d8bc2f-7056-4b81-a1c4-2a631dd8fbcd'::uuid, '18101', 'COUNTY', '', 'Martin County Recorder'),
  ('4f9d7b21-a129-41be-aa46-91cd1e584d5b'::uuid, '18101', 'COUNTY', '', 'Martin County Sheriff'),
  ('54e7afde-6f72-460a-ba4a-bca33bb97360'::uuid, '18101', 'COUNTY', '', 'Martin County Surveyor'),
  ('c34cc1c7-6153-4bda-98db-1de44f0badba'::uuid, '18101', 'COUNTY', '', 'Martin County Treasurer'),
  ('58d3ab75-e109-4807-a210-fa7f9edf1daf'::uuid, '18101', 'JUDICIAL', '', 'Indiana Circuit Court Judge - 90th Circuit (Martin County)'),
  ('e206a1a0-417e-4ac9-9fcf-bb349c5c62f4'::uuid, '18109', 'COUNTY', '', 'At-Large'),
  ('3b9ef2b0-9467-4b3d-8a0b-2b354b9de77c'::uuid, '18109', 'COUNTY', '', 'District 1'),
  ('b3f841c8-95e6-47fd-a29c-7d6f25eb15e8'::uuid, '18109', 'COUNTY', '', 'District 2'),
  ('5a72f4f8-0ea6-48fb-b772-ede8b471a825'::uuid, '18109', 'COUNTY', '', 'District 3'),
  ('0a7f1afe-5601-4cec-87b7-a5f6150abd9d'::uuid, '18109', 'COUNTY', '', 'Morgan County Assessor'),
  ('d881d00d-4bb7-4af0-a485-c5630e48d932'::uuid, '18109', 'COUNTY', '', 'Morgan County Auditor'),
  ('353d04eb-4d9b-4d25-95e2-5578921d7cf2'::uuid, '18109', 'COUNTY', '', 'Morgan County Circuit Court Clerk'),
  ('22854d4a-79f8-45f2-a411-45cbfb1551b9'::uuid, '18109', 'COUNTY', '', 'Morgan County Coroner'),
  ('983efc89-ad30-4286-bfb1-b3f4a54b83de'::uuid, '18109', 'COUNTY', '', 'Morgan County Prosecuting Attorney'),
  ('61115a27-6345-4d3a-a0db-4f30ac0a4671'::uuid, '18109', 'COUNTY', '', 'Morgan County Recorder'),
  ('4657d4e1-f962-41e2-867f-2762ae14988e'::uuid, '18109', 'COUNTY', '', 'Morgan County Sheriff'),
  ('d5000a66-f3c1-4621-a3c6-a4cba8fc0f3b'::uuid, '18109', 'COUNTY', '', 'Morgan County Surveyor'),
  ('0da49a9a-18a9-4a71-a8a3-7b612491946b'::uuid, '18109', 'COUNTY', '', 'Morgan County Treasurer'),
  ('47cc576a-cd0f-4919-93ff-8990ea131f8a'::uuid, '18109', 'JUDICIAL', '', 'Indiana Circuit Court Judge - 15th Circuit (Morgan County)'),
  ('e2c67faf-0f3d-4334-9cc1-0a9fd7f9afd6'::uuid, '18109', 'JUDICIAL', '', 'Morgan County Superior Court Judge - Court 2'),
  ('cd083882-dd96-4f04-bd39-a311809f30a2'::uuid, '18109', 'JUDICIAL', '', 'Morgan County Superior Court Judge - Court 3'),
  ('260178e0-33e7-468e-8f69-403b6dcf9df8'::uuid, '18119', 'COUNTY', '', 'At-Large'),
  ('556e3c98-2da0-42b9-8232-ef82180b44f2'::uuid, '18119', 'COUNTY', '', 'District 1'),
  ('9616862d-32b3-4ea1-b58e-e1c1f74a4d62'::uuid, '18119', 'COUNTY', '', 'District 1'),
  ('19096c22-9b16-49a9-aa78-152f0abbc73f'::uuid, '18119', 'COUNTY', '', 'District 2'),
  ('e2019356-36d7-45b1-994d-f4960f936f68'::uuid, '18119', 'COUNTY', '', 'District 2'),
  ('0feb7c0e-3d7c-4c18-a9a3-623d499b60b3'::uuid, '18119', 'COUNTY', '', 'District 3'),
  ('731d7fc7-bb71-4896-ae64-b0c4a6a2ea7f'::uuid, '18119', 'COUNTY', '', 'District 3'),
  ('e2e613f2-4098-4f5d-9b8c-0fa00f5ca3b0'::uuid, '18119', 'COUNTY', '', 'District 4'),
  ('6e6ede96-73a0-42b1-8afa-af61da2371f9'::uuid, '18119', 'COUNTY', '', 'Owen County Assessor'),
  ('cf92b575-de61-4997-9a47-a9ee7f6f346a'::uuid, '18119', 'COUNTY', '', 'Owen County Auditor'),
  ('dd639372-17b7-4a1a-a14b-3b529ad5b20f'::uuid, '18119', 'COUNTY', '', 'Owen County Circuit Court Clerk'),
  ('3b6e2e42-ff30-4ea4-86e9-b34b2c5e0508'::uuid, '18119', 'COUNTY', '', 'Owen County Coroner'),
  ('b647ad31-9612-4987-942d-8e282199e2a7'::uuid, '18119', 'COUNTY', '', 'Owen County Prosecuting Attorney'),
  ('fb459c80-d5e8-4045-8642-5c204c748c98'::uuid, '18119', 'COUNTY', '', 'Owen County Recorder'),
  ('ee445208-2473-4fe0-98c4-eb2ce75b9a0a'::uuid, '18119', 'COUNTY', '', 'Owen County Sheriff'),
  ('de6fd0a7-67dc-4536-91a2-95ef3d15d82b'::uuid, '18119', 'COUNTY', '', 'Owen County Surveyor'),
  ('f324e84a-edf2-48f0-8c6f-d7f9413db758'::uuid, '18119', 'COUNTY', '', 'Owen County Treasurer'),
  ('051ad42b-ea13-42d0-b08d-2f1ad0956038'::uuid, '18119', 'JUDICIAL', '', 'Indiana Circuit Court Judge - 78th Circuit (Owen County), Seat 1'),
  ('fb6ccdd0-0380-4f57-a847-3cd6f382031c'::uuid, '18119', 'JUDICIAL', '', 'Indiana Circuit Court Judge - 78th Circuit (Owen County), Seat 2')
) AS v(district_id, geo_id, district_type, old_mtfcc, label);

-- Full pre-image of the body rows this file deletes (the rollback re-inserts these).
CREATE TEMP TABLE ca0210_body ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('e704387a-e183-4ec7-9f3a-280343856d17'::uuid, 'IN', '18013', 'Assessor', 'Assessor', ''),
  ('7ec75d15-871f-4906-8557-9691e6516bc6'::uuid, 'IN', '18013', 'Auditor', 'Auditor', ''),
  ('1cb3cc7c-9010-4290-9bd1-e5e187e07bcd'::uuid, 'IN', '18013', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('0fc1b9c5-3feb-4317-90a3-397f13c18333'::uuid, 'IN', '18013', 'Commission - District 1', 'Commission - District 1', ''),
  ('ee4d5f8e-ca67-4461-a4aa-52f24e510676'::uuid, 'IN', '18013', 'Commission - District 2', 'Commission - District 2', ''),
  ('7db3799d-33ae-4aaa-8fe9-eab46dd24516'::uuid, 'IN', '18013', 'Commission - District 3', 'Commission - District 3', ''),
  ('bae7b97a-ad91-46bf-bd50-4bc63c1ca868'::uuid, 'IN', '18013', 'Coroner', 'Coroner', ''),
  ('5e4fcce1-08b2-4bbe-b83e-aa58dc108cf2'::uuid, 'IN', '18013', 'Council - At Large', 'Council - At Large', ''),
  ('c7287d87-08fc-4932-8be7-34d161af9a30'::uuid, 'IN', '18013', 'Council - District 1', 'Council - District 1', ''),
  ('836395a4-14bc-45bd-9942-a1837df5bb2c'::uuid, 'IN', '18013', 'Council - District 2', 'Council - District 2', ''),
  ('4eac0305-91fe-4a54-a0b6-9be454c2e2e1'::uuid, 'IN', '18013', 'Council - District 3', 'Council - District 3', ''),
  ('b2e20566-5547-4bde-b8c4-106bc25bacfa'::uuid, 'IN', '18013', 'Council - District 4', 'Council - District 4', ''),
  ('7edcafdf-3904-4d13-a3a8-047a6a7c6ecc'::uuid, 'IN', '18013', 'Indiana Circuit Court Judge - 88th Circuit', 'Indiana Circuit Court Judge - 88th Circuit', ''),
  ('adb1a9a3-823d-4a55-a4e1-d02f49f10d02'::uuid, 'IN', '18013', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('1ad5db0e-abad-4ba6-84b1-137e63c8c5d0'::uuid, 'IN', '18013', 'Recorder', 'Recorder', ''),
  ('c590d9ff-28da-4be3-b965-a53703aee93d'::uuid, 'IN', '18013', 'Sheriff', 'Sheriff', ''),
  ('a829b03d-803d-41a2-912c-1ed923c5746b'::uuid, 'IN', '18013', 'Surveyor', 'Surveyor', ''),
  ('ebe79c2c-9492-4a2b-924a-3df083ccc7aa'::uuid, 'IN', '18013', 'Treasurer', 'Treasurer', ''),
  ('04e0c6f0-3ed5-4baf-87ba-ccc4462d822f'::uuid, 'IN', '18055', 'Assessor', 'Assessor', ''),
  ('2a529adb-fa6c-487a-a14d-d7454ba05dc0'::uuid, 'IN', '18055', 'Auditor', 'Auditor', ''),
  ('ddeca68f-be71-4735-9461-b21a897150f6'::uuid, 'IN', '18055', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('5a0c97f8-38fd-4c9a-bbe1-ad8853e40e44'::uuid, 'IN', '18055', 'Commission - District 1', 'Commission - District 1', ''),
  ('26a798df-5110-4c91-9d3d-40b1fc62d8b2'::uuid, 'IN', '18055', 'Commission - District 2', 'Commission - District 2', ''),
  ('45f93121-fd81-430e-a39b-9bba1d2e0cbc'::uuid, 'IN', '18055', 'Commission - District 3', 'Commission - District 3', ''),
  ('67a62e42-234f-4ae9-9545-1ecf898cfc93'::uuid, 'IN', '18055', 'Coroner', 'Coroner', ''),
  ('eb93c4e7-8d50-4741-9b86-b2fcd66cf10b'::uuid, 'IN', '18055', 'Council - At Large', 'Council - At Large', ''),
  ('2c1dd3e8-6faf-46c2-842f-b9a29aa61a3f'::uuid, 'IN', '18055', 'Indiana Circuit Court Judge - 63rd Circuit', 'Indiana Circuit Court Judge - 63rd Circuit', ''),
  ('5ecaf9d5-3481-448c-85ef-c3bcf6c2db5d'::uuid, 'IN', '18055', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('9b4abfe0-489d-40ec-b23a-262770e795fa'::uuid, 'IN', '18055', 'Recorder', 'Recorder', ''),
  ('77caa1cc-dc7d-426a-b9aa-3f7de680201b'::uuid, 'IN', '18055', 'Sheriff', 'Sheriff', ''),
  ('be3237e4-9107-452f-880f-7bfaa67d340f'::uuid, 'IN', '18055', 'Superior Court Judge', 'Superior Court Judge', ''),
  ('6b824629-2d92-4797-8a77-69aab1566e2c'::uuid, 'IN', '18055', 'Surveyor', 'Surveyor', ''),
  ('a9667a5f-bcc9-4f73-a702-dccd3a886d3e'::uuid, 'IN', '18055', 'Treasurer', 'Treasurer', ''),
  ('abdfcd28-34c0-4a47-9053-045ac9a37064'::uuid, 'IN', '18071', 'Assessor', 'Assessor', ''),
  ('89bf0ddc-9421-483f-9638-1a95a032854a'::uuid, 'IN', '18071', 'Auditor', 'Auditor', ''),
  ('375295ba-1a5b-44e4-9123-6193e005cd64'::uuid, 'IN', '18071', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('1ceed6de-86f4-4047-83da-6852992c5397'::uuid, 'IN', '18071', 'Commission - District 1', 'Commission - District 1', ''),
  ('a9a7781e-9045-41dd-b823-4d7363d9023e'::uuid, 'IN', '18071', 'Commission - District 2', 'Commission - District 2', ''),
  ('8bec4b0f-e80d-4310-84ed-6e1ef5fdd5e4'::uuid, 'IN', '18071', 'Commission - District 3', 'Commission - District 3', ''),
  ('6118aa03-4351-481b-9b3c-e573f17e7117'::uuid, 'IN', '18071', 'Coroner', 'Coroner', ''),
  ('ed17da27-b679-4c40-a00a-66a8203bf536'::uuid, 'IN', '18071', 'Council - At Large', 'Council - At Large', ''),
  ('6f8a5457-b973-4e09-9dd2-1f4396b55552'::uuid, 'IN', '18071', 'Indiana Circuit Court Judge - 40th Circuit', 'Indiana Circuit Court Judge - 40th Circuit', ''),
  ('0848f64b-1ebc-420d-a4e8-7d1ceba5cefe'::uuid, 'IN', '18071', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('fe528f8d-dd08-434e-8781-78c872be9b62'::uuid, 'IN', '18071', 'Recorder', 'Recorder', ''),
  ('eb298706-63d2-4d39-916f-284f11341ffb'::uuid, 'IN', '18071', 'Sheriff', 'Sheriff', ''),
  ('1a0d75a9-9cfb-4c41-8417-84f92e36650d'::uuid, 'IN', '18071', 'Superior Court Judge - Court 1', 'Superior Court Judge - Court 1', ''),
  ('701fd3bb-de3c-41bd-b4e5-84b1b02d311d'::uuid, 'IN', '18071', 'Superior Court Judge - Court 2', 'Superior Court Judge - Court 2', ''),
  ('310bc387-858a-411b-a803-b585678ef673'::uuid, 'IN', '18071', 'Surveyor', 'Surveyor', ''),
  ('8a4b0f87-694d-487b-899a-b6cfa70cf1f1'::uuid, 'IN', '18071', 'Treasurer', 'Treasurer', ''),
  ('f9261dc9-82ae-427b-a56c-84af337f2031'::uuid, 'IN', '18093', 'Assessor', 'Assessor', ''),
  ('862cfbac-6a28-4378-bdf6-68890ee8a821'::uuid, 'IN', '18093', 'Auditor', 'Auditor', ''),
  ('6988df7c-3184-42ef-943d-09ae51b8e737'::uuid, 'IN', '18093', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('ea35de47-55e6-4d10-8607-b44ec0deb242'::uuid, 'IN', '18093', 'Commission - District 1', 'Commission - District 1', ''),
  ('a95e2feb-4c9e-4d6e-8fd0-b7ddd3977d8e'::uuid, 'IN', '18093', 'Commission - District 2', 'Commission - District 2', ''),
  ('dfe0cfa2-9167-4492-91c8-8e4bd6c69289'::uuid, 'IN', '18093', 'Commission - District 3', 'Commission - District 3', ''),
  ('77baeb7f-1324-4aaa-9b29-572da50f4f8f'::uuid, 'IN', '18093', 'Coroner', 'Coroner', ''),
  ('af36129a-480a-4a53-a59e-3ed21e52d65a'::uuid, 'IN', '18093', 'Council - At Large', 'Council - At Large', ''),
  ('a72218ff-2fc6-47d1-b10d-e5fbd98b0804'::uuid, 'IN', '18093', 'Indiana Circuit Court Judge - 81st Circuit', 'Indiana Circuit Court Judge - 81st Circuit', ''),
  ('75a0a8cc-00c1-450a-8709-7d78fb728b82'::uuid, 'IN', '18093', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('cfead2d9-757d-49f5-adac-1bd49c6b0bb8'::uuid, 'IN', '18093', 'Recorder', 'Recorder', ''),
  ('67b8e1a8-3865-46b2-a169-ca63872089e5'::uuid, 'IN', '18093', 'Sheriff', 'Sheriff', ''),
  ('53250492-2fce-49e3-a534-99d33fc9ea59'::uuid, 'IN', '18093', 'Superior Court Judge - Court 1', 'Superior Court Judge - Court 1', ''),
  ('6df29afd-24d2-4964-8b2e-e12165dafa18'::uuid, 'IN', '18093', 'Superior Court Judge - Court 2', 'Superior Court Judge - Court 2', ''),
  ('39e1f36c-96d5-4f1c-8874-f779b73ad24b'::uuid, 'IN', '18093', 'Surveyor', 'Surveyor', ''),
  ('c5bd974c-f819-4c5f-8e62-c7053262a798'::uuid, 'IN', '18093', 'Treasurer', 'Treasurer', ''),
  ('12ae1104-3a74-4671-8353-8e4c19579b4f'::uuid, 'IN', '18097', 'Assessor', 'Assessor', ''),
  ('ea63a000-b603-4eb9-80c5-a033ed5f6350'::uuid, 'IN', '18097', 'Auditor', 'Auditor', ''),
  ('6f79eed2-f686-4807-9144-c9e71f577598'::uuid, 'IN', '18097', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('cd376466-12ab-4706-a16a-ddecf0c80244'::uuid, 'IN', '18097', 'Coroner', 'Coroner', ''),
  ('9ba22441-447e-482b-8c4c-1801e7ee837c'::uuid, 'IN', '18097', 'Indiana Circuit Court Judge - 19th Circuit', 'Indiana Circuit Court Judge - 19th Circuit', ''),
  ('fc80d667-70e4-4850-b589-f118c10d4ccf'::uuid, 'IN', '18097', 'Indiana House of Representatives - District 97', 'Indiana House of Representatives - District 97', ''),
  ('d212f037-c653-48b2-9e8e-daa1bb931834'::uuid, 'IN', '18097', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('c6fb4d78-ed88-4cf9-896a-3db0bd0bffb4'::uuid, 'IN', '18097', 'Recorder', 'Recorder', ''),
  ('a6f5195f-7b40-4381-a50f-ee4c2d1aa0e0'::uuid, 'IN', '18097', 'Sheriff', 'Sheriff', ''),
  ('8ebe2c67-e177-4aed-8b20-773100b644e7'::uuid, 'IN', '18097', 'Superior Court Judge', 'Superior Court Judge', ''),
  ('2cd23c51-1d15-4d06-8e57-40cf02fb4fa3'::uuid, 'IN', '18097', 'Surveyor', 'Surveyor', ''),
  ('602a5111-87ed-4157-a423-4aa3835f9bf5'::uuid, 'IN', '18097', 'Treasurer', 'Treasurer', ''),
  ('c2fda4c4-af11-430a-a70f-933547e10c00'::uuid, 'IN', '18101', 'Assessor', 'Assessor', ''),
  ('f2967a0b-63c1-460e-9db5-541dfe3c1727'::uuid, 'IN', '18101', 'Auditor', 'Auditor', ''),
  ('bfa641c4-2d43-460f-a6ec-21add12e99b9'::uuid, 'IN', '18101', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('ba0e5054-b395-410b-a26f-49f7e716074d'::uuid, 'IN', '18101', 'Commission - District 1', 'Commission - District 1', ''),
  ('1dcde1b7-a87e-453d-8fab-1c23c47a8e04'::uuid, 'IN', '18101', 'Commission - District 2', 'Commission - District 2', ''),
  ('a5c10033-68a7-435d-b5fc-8b8826b7a815'::uuid, 'IN', '18101', 'Commission - District 3', 'Commission - District 3', ''),
  ('1800742a-595f-49fd-bdcb-ccb6eb7e6418'::uuid, 'IN', '18101', 'Coroner', 'Coroner', ''),
  ('f819d9b7-3ba2-42f0-acf0-3de0f15bf685'::uuid, 'IN', '18101', 'Council - At Large', 'Council - At Large', ''),
  ('f3321596-f603-4bd4-9cf0-682fd3fede61'::uuid, 'IN', '18101', 'Council - District 1', 'Council - District 1', ''),
  ('a8f723e7-ce9a-449f-8528-99ce6aa7f9ea'::uuid, 'IN', '18101', 'Council - District 2', 'Council - District 2', ''),
  ('01c4b822-817e-4181-b0c2-5cdb0fb3e1b2'::uuid, 'IN', '18101', 'Council - District 3', 'Council - District 3', ''),
  ('bb887848-41b3-470f-b583-7733a647a19e'::uuid, 'IN', '18101', 'Council - District 4', 'Council - District 4', ''),
  ('44119443-54ba-48a3-987f-3b7dc93b229a'::uuid, 'IN', '18101', 'Indiana Circuit Court Judge - 90th Circuit', 'Indiana Circuit Court Judge - 90th Circuit', ''),
  ('7a9f9ff2-bc23-421e-93ae-e1adccb512f4'::uuid, 'IN', '18101', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('9b206a68-dcb6-4901-b26c-986eb56ec61e'::uuid, 'IN', '18101', 'Recorder', 'Recorder', ''),
  ('095c9b3e-c64e-4da2-81d9-f1794817b64a'::uuid, 'IN', '18101', 'Sheriff', 'Sheriff', ''),
  ('0c39a7a6-7edd-48b0-bd6d-a92110e505ae'::uuid, 'IN', '18101', 'Surveyor', 'Surveyor', ''),
  ('34529ab7-3775-4205-85b3-9cdf27ebeabe'::uuid, 'IN', '18101', 'Treasurer', 'Treasurer', ''),
  ('40b3c570-b2af-4356-bbbd-a0eebc9b1ad0'::uuid, 'IN', '18109', 'Assessor', 'Assessor', ''),
  ('766d739a-1a86-476c-8074-e86a9433d1ed'::uuid, 'IN', '18109', 'Auditor', 'Auditor', ''),
  ('3c87b18a-505a-445c-aca2-fa0b151a7ff9'::uuid, 'IN', '18109', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('8e6028f2-9bd8-4e2b-8444-4151dcc41000'::uuid, 'IN', '18109', 'Commission - District 1', 'Commission - District 1', ''),
  ('184dd924-2668-45b1-ad54-53f9cae0569b'::uuid, 'IN', '18109', 'Commission - District 2', 'Commission - District 2', ''),
  ('95a9b5e5-8328-4c94-8950-ffcb6498b0a9'::uuid, 'IN', '18109', 'Commission - District 3', 'Commission - District 3', ''),
  ('24be030b-c036-4e35-944f-b3b52e1685eb'::uuid, 'IN', '18109', 'Coroner', 'Coroner', ''),
  ('e750a25e-a9f4-4131-a2ed-93045650cc65'::uuid, 'IN', '18109', 'Council - At Large', 'Council - At Large', ''),
  ('71ff4eb6-82ee-43ff-9513-a7a0459c103c'::uuid, 'IN', '18109', 'Indiana Circuit Court Judge - 15th Circuit', 'Indiana Circuit Court Judge - 15th Circuit', ''),
  ('57cfa000-4337-4ff5-84be-55a589e23890'::uuid, 'IN', '18109', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('354294be-4958-4894-b683-6db9ee7c60e1'::uuid, 'IN', '18109', 'Recorder', 'Recorder', ''),
  ('42a7c1e3-8d92-4dbe-a5ab-86d0bb82f6b1'::uuid, 'IN', '18109', 'Sheriff', 'Sheriff', ''),
  ('d682d1b3-d5d1-496e-8011-11daa623aad3'::uuid, 'IN', '18109', 'Superior Court Judge - Court 2', 'Superior Court Judge - Court 2', ''),
  ('092acae7-4ea6-4a7e-88db-26a3f0cb70ba'::uuid, 'IN', '18109', 'Superior Court Judge - Court 3', 'Superior Court Judge - Court 3', ''),
  ('0fc60d8f-787d-49f2-a0b1-dbfaa9e8bf38'::uuid, 'IN', '18109', 'Surveyor', 'Surveyor', ''),
  ('9e379eba-ce53-4b67-bbd6-61ca13b8ade2'::uuid, 'IN', '18109', 'Treasurer', 'Treasurer', ''),
  ('810d4d20-938e-47b1-9dcd-51c531eb957f'::uuid, 'IN', '18119', 'Assessor', 'Assessor', ''),
  ('8211b196-d0e9-4318-860a-a64152b0e89f'::uuid, 'IN', '18119', 'Auditor', 'Auditor', ''),
  ('753266af-3770-4e56-8a3a-80df955f415c'::uuid, 'IN', '18119', 'Circuit Court Clerk', 'Circuit Court Clerk', ''),
  ('37830d13-b93f-409e-a287-5b0115c0955e'::uuid, 'IN', '18119', 'Commission - District 1', 'Commission - District 1', ''),
  ('b3002f2e-4f21-43a9-8821-51fd839f9c64'::uuid, 'IN', '18119', 'Commission - District 2', 'Commission - District 2', ''),
  ('2c6f065e-5dcf-426f-a119-5daf274260c0'::uuid, 'IN', '18119', 'Commission - District 3', 'Commission - District 3', ''),
  ('35308409-ba01-4705-9882-08571dd150d4'::uuid, 'IN', '18119', 'Coroner', 'Coroner', ''),
  ('c837fe6b-4c01-400a-ad18-3c05d3ecedf2'::uuid, 'IN', '18119', 'Council - At Large', 'Council - At Large', ''),
  ('be8a54f3-3d13-4a30-96a6-a1205c15cb99'::uuid, 'IN', '18119', 'Council - District 1', 'Council - District 1', ''),
  ('5c63e6d8-7961-4467-9713-32cf376f7228'::uuid, 'IN', '18119', 'Council - District 2', 'Council - District 2', ''),
  ('df1818cc-c028-4eb7-856e-7bd3ce0749a3'::uuid, 'IN', '18119', 'Council - District 3', 'Council - District 3', ''),
  ('a79c165a-e66f-476b-8e41-306673c6f63b'::uuid, 'IN', '18119', 'Council - District 4', 'Council - District 4', ''),
  ('bc4e1ec8-f709-4357-8a2e-8931147128a2'::uuid, 'IN', '18119', 'Indiana Circuit Court Judge - 78th Circuit, Seat 1', 'Indiana Circuit Court Judge - 78th Circuit, Seat 1', ''),
  ('b8169a51-3fdc-4bd4-91de-dbd4252850cd'::uuid, 'IN', '18119', 'Indiana Circuit Court Judge - 78th Circuit, Seat 2', 'Indiana Circuit Court Judge - 78th Circuit, Seat 2', ''),
  ('e87caa69-5b5a-4ed9-b234-0052715dfc2c'::uuid, 'IN', '18119', 'Prosecuting Attorney', 'Prosecuting Attorney', ''),
  ('c53a5b88-ea83-4a32-90b4-324a40ab87fd'::uuid, 'IN', '18119', 'Recorder', 'Recorder', ''),
  ('9ef4582e-a36c-4452-9af4-c67d295dbd98'::uuid, 'IN', '18119', 'Sheriff', 'Sheriff', ''),
  ('ca11f961-4a86-4d12-97aa-987ab4e547ed'::uuid, 'IN', '18119', 'Surveyor', 'Surveyor', ''),
  ('dacd01ec-c3bd-4569-a086-021e564c5a9e'::uuid, 'IN', '18119', 'Treasurer', 'Treasurer', '')
) AS v(id, state, geo_id, body_key, display_name, website_url);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_gov int; n_gov_bad int; n_geo_taken int; n_d int; n_d_bad int; n_d_fence int; n_b int; n_b_bad int; n_b_matched int; n_mayor int;
BEGIN
  -- 0a. The nine county governments, geo_id NULL (first run) or their FIPS (re-run).
  SELECT count(g.id), count(g.id) FILTER (WHERE g.name IS DISTINCT FROM t.name OR g.type IS DISTINCT FROM 'County'
                                            OR (g.geo_id IS NOT NULL AND g.geo_id IS DISTINCT FROM t.fips))
    INTO n_gov, n_gov_bad
    FROM ca0210_gov t LEFT JOIN essentials.governments g ON g.id = t.government_id;
  SELECT count(*) INTO n_geo_taken
    FROM essentials.governments g
   WHERE g.geo_id IN (SELECT fips FROM ca0210_gov) AND g.id NOT IN (SELECT government_id FROM ca0210_gov);
  IF n_gov <> 9 OR n_gov_bad > 0 OR n_geo_taken > 0 THEN
    RAISE EXCEPTION 'governments: % of 9, % not as recorded, % other government(s) already on these FIPS', n_gov, n_gov_bad, n_geo_taken;
  END IF;

  -- 0b. The 139 districts: as recorded, mtfcc old (first run) or G4020 (re-run), each with a G4020 geofence.
  SELECT count(d.id),
         count(d.id) FILTER (WHERE d.geo_id IS DISTINCT FROM t.geo_id OR d.district_type IS DISTINCT FROM t.district_type
                               OR d.label IS DISTINCT FROM t.label OR COALESCE(d.mtfcc, '') NOT IN (t.old_mtfcc, 'G4020')),
         count(d.id) FILTER (WHERE NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id AND gb.mtfcc = 'G4020'))
    INTO n_d, n_d_bad, n_d_fence
    FROM ca0210_district t LEFT JOIN essentials.districts d ON d.id = t.district_id;
  IF n_d <> 139 OR n_d_bad > 0 OR n_d_fence > 0 THEN
    RAISE EXCEPTION 'districts: % of 139, % not as recorded, % without a G4020 geofence', n_d, n_d_bad, n_d_fence;
  END IF;

  -- 0c. The 130 body rows: present exactly as recorded (first run) or gone (re-run), and none of them matches
  --     an office through DISTRICT_JOINS' body join.
  SELECT count(gvb.id),
         count(gvb.id) FILTER (WHERE (gvb.state, gvb.geo_id, gvb.body_key, gvb.display_name, gvb.website_url)
                                     IS DISTINCT FROM (t.state, t.geo_id, t.body_key, t.display_name, t.website_url))
    INTO n_b, n_b_bad
    FROM ca0210_body t LEFT JOIN essentials.government_bodies gvb ON gvb.id = t.id;
  SELECT count(*) INTO n_b_matched
    FROM ca0210_body t
    JOIN essentials.districts d ON d.state = t.state AND d.geo_id = t.geo_id
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE t.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '');
  IF n_b NOT IN (0, 130) OR n_b_bad > 0 OR n_b_matched > 0 THEN
    RAISE EXCEPTION 'body rows: % present (want 130, or 0 on a re-run), % not as recorded, % still matched by an office', n_b, n_b_bad, n_b_matched;
  END IF;

  -- 0d. The Indianapolis Mayor's body row is not in the list and still matches his office.
  SELECT count(*) INTO n_mayor
    FROM essentials.government_bodies gvb
    JOIN essentials.districts d ON d.state = gvb.state AND d.geo_id = gvb.geo_id
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE gvb.state = 'IN' AND gvb.geo_id = '18097' AND gvb.body_key = 'City Mayor'
     AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
     AND gvb.id NOT IN (SELECT id FROM ca0210_body);
  IF n_mayor <> 1 THEN
    RAISE EXCEPTION 'Indianapolis City Mayor body row: % matching (want 1)', n_mayor;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. governments.geo_id.
-- ---------------------------------------------------------------------------
UPDATE essentials.governments g
   SET geo_id = t.fips
  FROM ca0210_gov t
 WHERE g.id = t.government_id AND g.geo_id IS NULL;

-- ---------------------------------------------------------------------------
-- 2. districts.mtfcc.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts d
   SET mtfcc = 'G4020'
  FROM ca0210_district t
 WHERE d.id = t.district_id AND COALESCE(d.mtfcc, '') = t.old_mtfcc;

-- ---------------------------------------------------------------------------
-- 3. government_bodies: the 130 unmatched per-seat rows.
-- ---------------------------------------------------------------------------
DELETE FROM essentials.government_bodies gvb
 USING ca0210_body t
 WHERE gvb.id = t.id
   AND (gvb.state, gvb.geo_id, gvb.body_key, gvb.display_name, gvb.website_url)
       IS NOT DISTINCT FROM (t.state, t.geo_id, t.body_key, t.display_name, t.website_url);

-- ---------------------------------------------------------------------------
-- 4. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_geo int; n_off_wide int; n_left int; n_mayor int; n_monroe int; n_monroe_hit int; n_nb_hit int;
BEGIN
  -- 4a. All nine carry their FIPS.
  SELECT count(*) INTO n_geo
    FROM ca0210_gov t JOIN essentials.governments g ON g.id = t.government_id WHERE g.geo_id = t.fips;
  IF n_geo <> 9 THEN
    RAISE EXCEPTION 'governments with their FIPS: % of 9', n_geo;
  END IF;

  -- 4b. No county-wide COUNTY / JUDICIAL district anywhere is off G4020 any more.
  SELECT count(*) INTO n_off_wide
    FROM essentials.districts d
   WHERE d.geo_id ~ '^\d{5}$' AND d.district_type IN ('COUNTY', 'JUDICIAL') AND COALESCE(d.mtfcc, '') <> 'G4020';
  IF n_off_wide > 0 THEN
    RAISE EXCEPTION '% county-wide district(s) still off G4020', n_off_wide;
  END IF;

  -- 4c. The 130 rows are gone; the Indianapolis Mayor's row remains.
  SELECT count(*) INTO n_left FROM essentials.government_bodies WHERE id IN (SELECT id FROM ca0210_body);
  SELECT count(*) INTO n_mayor FROM essentials.government_bodies WHERE state = 'IN' AND geo_id = '18097' AND body_key = 'City Mayor';
  IF n_left > 0 OR n_mayor <> 1 THEN
    RAISE EXCEPTION 'body rows: % of the 130 left (want 0), Indianapolis City Mayor rows % (want 1)', n_left, n_mayor;
  END IF;

  -- 4d. The body join for the nine counties' offices is unchanged from CA_0208: the eight neighbours match
  --     no body row, every Monroe office matches one.
  SELECT count(*) FILTER (WHERE g.name NOT LIKE 'Monroe County,%' AND gvb.id IS NOT NULL),
         count(*) FILTER (WHERE g.name LIKE 'Monroe County,%'),
         count(*) FILTER (WHERE g.name LIKE 'Monroe County,%' AND gvb.id IS NOT NULL)
    INTO n_nb_hit, n_monroe, n_monroe_hit
    FROM ca0210_gov t
    JOIN essentials.governments g ON g.id = t.government_id
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state AND gvb.geo_id = d.geo_id
     AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '');
  IF n_nb_hit > 0 OR n_monroe_hit <> n_monroe THEN
    RAISE EXCEPTION 'body join: % neighbour office(s) match a body row (want 0); Monroe % of %', n_nb_hit, n_monroe_hit, n_monroe;
  END IF;

  RAISE NOTICE 'OK: 9 Indiana county governments on their FIPS; 0 county-wide districts off G4020; 130 unmatched per-seat body rows removed, Indianapolis Mayor row kept';
END $$;

COMMIT;
