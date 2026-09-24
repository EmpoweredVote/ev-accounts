-- CA_0208_indiana_per_seat_chambers_shared_name_formal.sql
--
-- Give each per-seat chamber in nine Indiana counties the name of the BODY it belongs to, so the seats of
-- one body group together: the Monroe County pattern, applied to its eight neighbours. 174 chambers get a
-- name_formal; no chamber, office, district or politician row is added, moved or deleted.
--
-- WHY
-- ---
-- These nine counties came in from an early per-seat import: ONE CHAMBER PER SEAT ("Commission - District
-- 1", "Council - At Large", "Assessor", "Indiana Circuit Court Judge - 88th Circuit"), every name_formal
-- empty, and a government_bodies row per seat whose display_name is the seat title. The essentials
-- frontend groups by body, so each seat renders as its own sub-group. Measured 2026-09-24 (live API,
-- grouped with essentials main's groupHierarchy.js):
--   browse 18013 Brown County    17 sub-groups under "Brown County" (Commission - District 1, - District
--                                2, ..., Council - At Large, Council - District 1, ..., Assessor, ...);
--                                the judge under a heading "Indiana Circuit Court Judge - 88th Circuit"
--   browse 18097 Marion County   9 sub-groups (one per row officer); 28 Superior Court judges under a
--                                heading "Superior Court Judge"
--   Greene 13, Owen 17; Jackson / Lawrence / Martin / Morgan the same shape.
-- Monroe County has the same per-seat chambers but already groups correctly: its five council chambers all
-- carry name_formal 'Monroe County Council', its three commission chambers 'Monroe County Board of
-- Commissioners', its court chambers 'Monroe County Circuit Court' (plus grouped government_bodies rows
-- keyed on those names). That is the precedent this file follows.
--
-- WHY RENAME, NOT MERGE
-- ---------------------
-- Merging the seats into one chamber per body would move offices across chambers and collapse
-- policy_engagement_level, which differs by seat INSIDE one body of officers: Assessor, Auditor, Clerk,
-- Coroner, Recorder, Surveyor and Treasurer are 'none' (the profile then reads "This is an administrative
-- office"), Prosecuting Attorney and Sheriff 'full'. A shared name_formal groups them for every reader
-- (essentials sub-groups key and label on chamber_name_formal when there is no body row; the generated
-- chambers.slug follows name_formal, so body search already aggregates same-slug chambers into one body)
-- while every chamber keeps its own engagement level, external_id and offices.
--
-- NAMES (per county; Monroe keeps its three body names, only its officers change)
-- ---------------------------------------------------------------------------------
--   Council - ...                        -> '<County> County Council'
--   Commission - ...                     -> '<County> County Board of Commissioners'
--   Indiana Circuit Court Judge - ...    -> '<County> County Circuit Court'   (Monroe precedent)
--   Superior Court Judge ...             -> '<County> County Superior Court'
--   every COUNTY-typed row office        -> '<County> County Countywide Elected Officials'
--     (the name 38 county chambers already use nationally — Dane, Racine, LA, the ten Utah counties of
--     CA_0200). Monroe's officers change from 'Monroe County Government' to this name too, with its one
--     government_bodies row re-keyed (display_name follows; website_url kept), so Monroe and its
--     neighbours read alike. Monroe's Circuit Court Clerk is JUDICIAL-typed and already sits in
--     'Monroe County Circuit Court'; it is not touched.
--   Measured: none of the 27 new slugs is used by any chamber outside these nine governments.
--
-- WHAT A USER WILL SEE (browse and address, essentials main)
-- ----------------------------------------------------------
--   Brown County: Board of Commissioners (3), County Council (7), Countywide Elected Officials (9) instead
--   of 17 seat-named sub-groups; the judge under "Brown County Circuit Court". Marion: one officers group
--   instead of 9; 28 judges under "Marion County Superior Court". Monroe: "Monroe County Countywide Elected
--   Officials" instead of "Monroe County Officials".
--
-- NOT CHANGED
-- -----------
--   No chamber/office/district/politician/term/race row added, moved or deleted; policy_engagement_level,
--   chambers.name and external_id untouched (gated). governments.geo_id is NULL on all nine county rows —
--   a separate question (it changes which browse step returns these officials), not addressed here.
--   The 131 per-seat government_bodies rows of the eight neighbouring counties (body_key = the seat title,
--   e.g. 'Assessor' at 18013) stop matching: DISTRICT_JOINS keys the join on
--   COALESCE(NULLIF(name_formal,''), name), which is now the body name. They are left in place, not deleted
--   (no behaviour depends on an unmatched row; deleting is a separate cleanup). Without a body row the
--   frontend keys and labels on chamber_name_formal, as CA_0191 chose for the California courts.
--
-- No migration runner exists; this file records SQL applied by hand. No DELETE.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK:
--   UPDATE essentials.chambers ch SET name_formal = t.old_formal
--     FROM <ca0208_chamber below> t WHERE ch.id = t.chamber_id;
--   UPDATE essentials.government_bodies SET body_key = 'Monroe County Government', display_name = 'Monroe County Government'
--    WHERE state = 'IN' AND geo_id = '18105' AND body_key = 'Monroe County Countywide Elected Officials';
-- IDEMPOTENT: both UPDATEs are guarded on the old value; a re-run changes 0 rows and every gate passes.

BEGIN;

-- The 174 chambers this file renames, by fixed id, with what each must still carry.
CREATE TEMP TABLE ca0208_chamber ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('4b2cca48-33ae-4cac-9f0e-49a520731350'::uuid, 'Brown County', 'Commission - District 1', '', 'Brown County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('caf195bd-930d-4b7d-b56c-da592ed06f05'::uuid, 'Brown County', 'Commission - District 2', '', 'Brown County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('a5f0128a-866a-4f52-a7ab-08c15cd09607'::uuid, 'Brown County', 'Commission - District 3', '', 'Brown County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('aed0c86d-8d36-4dd4-a433-b0f7284a6a94'::uuid, 'Brown County', 'Indiana Circuit Court Judge - 88th Circuit', '', 'Brown County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('3c1c88fa-d280-472b-b25f-5495e953e43a'::uuid, 'Brown County', 'Council - At Large', '', 'Brown County Council', 'full'::essentials.policy_engagement_level, 3),
  ('30cc3901-d607-417e-ae58-d9187ecc9bf3'::uuid, 'Brown County', 'Council - District 1', '', 'Brown County Council', 'full'::essentials.policy_engagement_level, 1),
  ('6af2f6f2-9731-4744-a0a9-64952fa2c0e6'::uuid, 'Brown County', 'Council - District 2', '', 'Brown County Council', 'full'::essentials.policy_engagement_level, 1),
  ('2d932726-99ec-4148-b2dc-508cbf8271f3'::uuid, 'Brown County', 'Council - District 3', '', 'Brown County Council', 'full'::essentials.policy_engagement_level, 1),
  ('9280d64d-a5f9-45ca-9597-5be2862513fe'::uuid, 'Brown County', 'Council - District 4', '', 'Brown County Council', 'full'::essentials.policy_engagement_level, 1),
  ('6bee33ba-64a9-4cc7-8ec5-d2d97807c43d'::uuid, 'Brown County', 'Assessor', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('a3b77081-4ae7-4ae6-9bd7-47315ecc0ad2'::uuid, 'Brown County', 'Auditor', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('d54e85bf-4574-4ca8-91dc-0b980016ed97'::uuid, 'Brown County', 'Circuit Court Clerk', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('cf6b046e-0953-4de0-a5ec-e0db3cf066d8'::uuid, 'Brown County', 'Coroner', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('bcb71851-043b-458f-8980-f5fb45adf47f'::uuid, 'Brown County', 'Prosecuting Attorney', '', 'Brown County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('5da6c386-7ddf-4395-a22a-639cc54f854c'::uuid, 'Brown County', 'Recorder', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('49f8d734-c503-410d-a4ee-57c46ce9a94f'::uuid, 'Brown County', 'Sheriff', '', 'Brown County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('7b9e5c03-4777-4899-ad19-7a5d9382bb04'::uuid, 'Brown County', 'Surveyor', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('578fa4fc-302e-4624-90c4-2e8096a17489'::uuid, 'Brown County', 'Treasurer', '', 'Brown County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('c057068d-1064-4962-ba60-933c3cc0db66'::uuid, 'Greene County', 'Commission - District 1', '', 'Greene County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('83d9889a-ba12-4716-926b-baff05064809'::uuid, 'Greene County', 'Commission - District 2', '', 'Greene County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('def6a26c-c382-4160-a495-d39af8d015f0'::uuid, 'Greene County', 'Commission - District 3', '', 'Greene County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('a87fae6a-1761-487a-9e50-4d09a9943b6c'::uuid, 'Greene County', 'Indiana Circuit Court Judge - 63rd Circuit', '', 'Greene County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('4af103c3-bd8c-4ef9-a4dd-ae3a9064b131'::uuid, 'Greene County', 'Council - At Large', '', 'Greene County Council', 'full'::essentials.policy_engagement_level, 3),
  ('3226b7dc-f070-40eb-8615-10922983fc82'::uuid, 'Greene County', 'Council - District 1', '', 'Greene County Council', 'full'::essentials.policy_engagement_level, 1),
  ('99cf0a1b-29f3-4b90-afc4-2c45a5812840'::uuid, 'Greene County', 'Council - District 2', '', 'Greene County Council', 'full'::essentials.policy_engagement_level, 1),
  ('ee1e090d-6b57-4bad-b021-441d4892c871'::uuid, 'Greene County', 'Council - District 3', '', 'Greene County Council', 'full'::essentials.policy_engagement_level, 1),
  ('879f28ba-8a67-43bd-a5bf-2eaa9e060bff'::uuid, 'Greene County', 'Council - District 4', '', 'Greene County Council', 'full'::essentials.policy_engagement_level, 1),
  ('ae337e51-422a-405d-bae6-fae1e2fe21aa'::uuid, 'Greene County', 'Assessor', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('dc2148a5-e21b-4b9b-8b8a-4e1fa42325e0'::uuid, 'Greene County', 'Auditor', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('40fb7bf9-dd1b-4191-a20e-4340b7333278'::uuid, 'Greene County', 'Circuit Court Clerk', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('6a678baa-25f3-409d-a812-1dadc35105d0'::uuid, 'Greene County', 'Coroner', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('b4ad73f5-f62f-48e7-aa62-fb9ebe93ba3d'::uuid, 'Greene County', 'Prosecuting Attorney', '', 'Greene County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('b6af1913-c389-435a-8477-311490aead6a'::uuid, 'Greene County', 'Recorder', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('51a8d569-0f62-4ba4-96a3-6b9566b1363a'::uuid, 'Greene County', 'Sheriff', '', 'Greene County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('4e211686-9d14-4b60-b303-c2f0951ff389'::uuid, 'Greene County', 'Surveyor', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('ca148f88-fb50-44e3-bb0e-39a21a977dc4'::uuid, 'Greene County', 'Treasurer', '', 'Greene County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('20190a46-a85c-4850-8e10-d47eafb29b11'::uuid, 'Greene County', 'Superior Court Judge', '', 'Greene County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('30d961ce-a9a9-47c8-819d-fbf596977994'::uuid, 'Jackson County', 'Commission - District 1', '', 'Jackson County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('047c6506-d600-4acc-9098-f16ef934c09d'::uuid, 'Jackson County', 'Commission - District 2', '', 'Jackson County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('c3af36c3-af89-4a98-8dad-aa5078186425'::uuid, 'Jackson County', 'Commission - District 3', '', 'Jackson County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('ec464121-0804-441d-bad9-98fcaa95156d'::uuid, 'Jackson County', 'Indiana Circuit Court Judge - 40th Circuit', '', 'Jackson County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('34b2115f-f006-4427-ac97-889877b9424d'::uuid, 'Jackson County', 'Council - At Large', '', 'Jackson County Council', 'full'::essentials.policy_engagement_level, 2),
  ('b2f71ad2-d059-4b14-8bf8-8bab113fadee'::uuid, 'Jackson County', 'Council - District 1', '', 'Jackson County Council', 'full'::essentials.policy_engagement_level, 1),
  ('40e34a36-8349-4f54-bd27-7a4b4fa821b3'::uuid, 'Jackson County', 'Assessor', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('7cde8dc0-489c-4347-abc7-61f01a8039f8'::uuid, 'Jackson County', 'Auditor', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('5d9d9314-e71f-4b9b-84ad-51eb204cef69'::uuid, 'Jackson County', 'Circuit Court Clerk', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('96a38e65-498d-4519-bd96-cc73d263089d'::uuid, 'Jackson County', 'Coroner', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('00ed3ed4-e32b-452f-91c2-5e5db43e19d6'::uuid, 'Jackson County', 'Prosecuting Attorney', '', 'Jackson County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('fd9bc2e5-73ac-4477-aa66-784e09832cc8'::uuid, 'Jackson County', 'Recorder', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('072b9780-77f4-4ac3-b28c-32cb8dc4e3e3'::uuid, 'Jackson County', 'Sheriff', '', 'Jackson County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('5f936a93-46ea-4027-a85b-ccc9bbbed4a5'::uuid, 'Jackson County', 'Surveyor', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('edc48b4f-c34d-43ff-bd9a-3c326882cfc2'::uuid, 'Jackson County', 'Treasurer', '', 'Jackson County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('a9c22da2-f308-4aff-ade6-d3b3c4b710d3'::uuid, 'Jackson County', 'Superior Court Judge - Court 1', '', 'Jackson County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('164ed6b8-7e70-4542-a01a-c7b554d0aa5f'::uuid, 'Jackson County', 'Superior Court Judge - Court 2', '', 'Jackson County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('7fab5596-5fa2-4a18-a01e-e3a6e729e571'::uuid, 'Lawrence County', 'Commission - District 1', '', 'Lawrence County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('b3a9aedc-6a5c-4be0-8605-7344998c05f8'::uuid, 'Lawrence County', 'Commission - District 2', '', 'Lawrence County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('e1f12bf5-e60a-419f-b7b6-6548b74b405c'::uuid, 'Lawrence County', 'Commission - District 3', '', 'Lawrence County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('c134caf0-d5e9-4d31-ab9e-c8f17c209748'::uuid, 'Lawrence County', 'Indiana Circuit Court Judge - 81st Circuit', '', 'Lawrence County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('d4aa0d7c-1f32-4398-92dc-d1e850c26a68'::uuid, 'Lawrence County', 'Council - At Large', '', 'Lawrence County Council', 'full'::essentials.policy_engagement_level, 3),
  ('065d3d64-5444-4154-a227-9ccb17eee405'::uuid, 'Lawrence County', 'Council - District 1', '', 'Lawrence County Council', 'full'::essentials.policy_engagement_level, 1),
  ('e658dbbc-da55-49ef-869b-e22a50ed1334'::uuid, 'Lawrence County', 'Council - District 2', '', 'Lawrence County Council', 'full'::essentials.policy_engagement_level, 1),
  ('7fc51397-e003-4645-a1c3-5783fecbf797'::uuid, 'Lawrence County', 'Council - District 3', '', 'Lawrence County Council', 'full'::essentials.policy_engagement_level, 1),
  ('d42ab0f6-152f-49d2-bcce-f27eebeabdad'::uuid, 'Lawrence County', 'Council - District 4', '', 'Lawrence County Council', 'full'::essentials.policy_engagement_level, 1),
  ('2477e431-b2cd-4bea-a936-dbc9c928dc5e'::uuid, 'Lawrence County', 'Assessor', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('0bd4738a-2d75-47c6-a772-bd78f33fc078'::uuid, 'Lawrence County', 'Auditor', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('417c4792-d39c-429f-9270-1764e968b66e'::uuid, 'Lawrence County', 'Circuit Court Clerk', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('6e19e671-5f1b-4fe0-ae88-b4d20365b620'::uuid, 'Lawrence County', 'Coroner', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('176ebf8f-3aa8-4651-9a9b-93b48ac8985f'::uuid, 'Lawrence County', 'Prosecuting Attorney', '', 'Lawrence County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('5442edb7-b5a2-4bd9-a617-e4d6066ab07d'::uuid, 'Lawrence County', 'Recorder', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('c1999f98-a879-4fe1-b504-4c2af1e1e793'::uuid, 'Lawrence County', 'Sheriff', '', 'Lawrence County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('397d0f9f-6fd4-4f28-86df-401d4f843bff'::uuid, 'Lawrence County', 'Surveyor', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('5664c0e6-3370-408d-aa4a-ed7b2de85a8a'::uuid, 'Lawrence County', 'Treasurer', '', 'Lawrence County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('53dde129-aa86-4fce-a780-122635197426'::uuid, 'Lawrence County', 'Superior Court Judge - Court 1', '', 'Lawrence County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('af3ce960-c795-4792-889e-5e4bd7c16e8b'::uuid, 'Lawrence County', 'Superior Court Judge - Court 2', '', 'Lawrence County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('107a66b7-be49-4b58-9f39-a688d89af793'::uuid, 'Marion County', 'Indiana Circuit Court Judge - 19th Circuit', '', 'Marion County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('c24eb0ea-73a4-4dde-9f06-ea4da3a0d6ca'::uuid, 'Marion County', 'Assessor', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('3a867b86-d121-41e1-a24b-d23cffcb88f2'::uuid, 'Marion County', 'Auditor', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('6831f7e8-20a2-4cf4-825d-f569a535f779'::uuid, 'Marion County', 'Circuit Court Clerk', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('da20080e-6bcf-4ff4-bae1-6d0f316c4330'::uuid, 'Marion County', 'Coroner', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('49f04a0f-7220-4b08-a1ce-d83e611caae4'::uuid, 'Marion County', 'Prosecuting Attorney', '', 'Marion County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('f792bdd4-5e15-490b-937a-0f37ccd605a7'::uuid, 'Marion County', 'Recorder', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('1ef7aaaa-f543-4cfb-95e8-07a652ab570c'::uuid, 'Marion County', 'Sheriff', '', 'Marion County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('e9c1c9a4-a78c-42de-aee4-82e4a90c2f24'::uuid, 'Marion County', 'Surveyor', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('5a250e59-aad9-4d8f-b946-1f6ff6c5546e'::uuid, 'Marion County', 'Treasurer', '', 'Marion County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('020ff579-344c-4a8c-a9a3-3321d47ab60f'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('1f90f105-12f6-4db8-85f6-2fcea7330377'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('237af8ef-570d-4ddf-ad57-7addeab8b495'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('23ea144e-c107-456c-83b3-f7ac0db13f67'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('3395ec02-10c8-4653-8fb1-1cc1142b5240'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('385ac3ef-1212-4dfa-bdb3-771f23798f21'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('3dd6165c-694f-4d33-9fb0-dfd750c2770f'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('569d03e7-371a-4a36-afe6-27b1828dfeca'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('6308131d-c9ed-44bf-b443-0e81847f7aee'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('63929e0b-65dd-45cf-bd79-a88991855aee'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('6f87e603-9151-4d37-ab98-6364894b4a61'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('71a17c1d-2ca2-4923-b203-596daf0f8a25'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('71d1f4c7-fe6f-4b53-a219-3575a3908257'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('7dea0f12-d53b-4a55-97d2-fc1e69128ab0'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('8b6309b4-443f-4014-9432-88b7fd992f28'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('91881299-b70c-4119-98de-d69dc7730570'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('929afcb5-f38c-48b7-93c4-8740fa598e87'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('a72d75dc-a117-4b66-b332-673ea76cbf04'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('a937d510-9dc0-4121-bb79-652bfbc3155b'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('b23071c1-cca5-46df-ad01-b1f8c74551b9'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('b9dd58b9-db62-4110-b2db-f2df9f0eaf9a'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('ba809f56-7f4f-451d-8a15-0e383229d9ad'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('c50b5a04-1b3a-402e-8377-479582e63050'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('dda7bac8-533f-42b8-9655-7bfb2927efa9'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('e0ab14b4-ed24-48d4-9c2b-e48192b8b4b4'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('ead42b09-0e24-4c64-a7d0-6e65525769da'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('ef6b2727-beba-4ebe-be85-b260957bb75a'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('f5c2556e-519d-46ee-bf67-b6923f2a41c3'::uuid, 'Marion County', 'Superior Court Judge', '', 'Marion County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('b18e6ca4-82e9-4f6c-b372-467fb05dcc40'::uuid, 'Martin County', 'Commission - District 1', '', 'Martin County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('70b134af-707c-4641-89e8-cf9b0108e5c4'::uuid, 'Martin County', 'Commission - District 2', '', 'Martin County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('22eb266d-6dad-46a8-8bde-899673f76d88'::uuid, 'Martin County', 'Commission - District 3', '', 'Martin County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('92189d12-a6a2-4174-b466-6a6cd4a90a1b'::uuid, 'Martin County', 'Indiana Circuit Court Judge - 90th Circuit', '', 'Martin County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('c8c05657-1c19-4d82-ac58-503d571e3898'::uuid, 'Martin County', 'Council - At Large', '', 'Martin County Council', 'full'::essentials.policy_engagement_level, 3),
  ('bf3a8bb0-7be9-4edf-a300-7e5d71e1740d'::uuid, 'Martin County', 'Council - District 1', '', 'Martin County Council', 'full'::essentials.policy_engagement_level, 1),
  ('1e1893f4-b5ba-4f6d-aff4-2d0ae3d14872'::uuid, 'Martin County', 'Council - District 2', '', 'Martin County Council', 'full'::essentials.policy_engagement_level, 1),
  ('12eba3b9-4935-41cf-b214-b817b15cb7c7'::uuid, 'Martin County', 'Council - District 3', '', 'Martin County Council', 'full'::essentials.policy_engagement_level, 1),
  ('22ce7f53-5c89-4c51-ae9f-b0e80b24998c'::uuid, 'Martin County', 'Council - District 4', '', 'Martin County Council', 'full'::essentials.policy_engagement_level, 1),
  ('15f245c6-7388-47a9-a4c1-c5f3dabfeee3'::uuid, 'Martin County', 'Assessor', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('309cf559-f94a-4369-86fb-03c0bf138f16'::uuid, 'Martin County', 'Auditor', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('7d7a2650-c8f1-4068-8518-51cff0f2afd6'::uuid, 'Martin County', 'Circuit Court Clerk', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('4c5439c4-afe6-4d7e-869a-75e2b9a074f9'::uuid, 'Martin County', 'Coroner', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('1aa3deab-f37c-4455-a359-1f2a0aed2ae5'::uuid, 'Martin County', 'Prosecuting Attorney', '', 'Martin County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('b27b3327-f202-41a5-965b-4a933cc91650'::uuid, 'Martin County', 'Recorder', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('70657c11-7760-4e95-89f8-fcb43ee8be75'::uuid, 'Martin County', 'Sheriff', '', 'Martin County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('8d1aaf49-6b05-4998-8627-d62554c7df6e'::uuid, 'Martin County', 'Surveyor', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('9c106854-eb72-4425-89b1-948efd48b83f'::uuid, 'Martin County', 'Treasurer', '', 'Martin County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('5f246621-b9a9-4c43-aaaf-adbcdb2aa68c'::uuid, 'Monroe County', 'Assessor', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('72fee9c5-b8d8-443f-8def-fafa759ab0bb'::uuid, 'Monroe County', 'Auditor', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('1667d73e-5619-4d00-b836-5d43f80c039e'::uuid, 'Monroe County', 'Coroner', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('30f32555-133e-41cb-9ba5-d6099717bc0e'::uuid, 'Monroe County', 'Prosecuting Attorney', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('d2a55c85-fb36-4e72-ad34-73d8b41d4e70'::uuid, 'Monroe County', 'Recorder', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('c0c4ae0f-0f6a-434c-bc9c-b9231cf1c591'::uuid, 'Monroe County', 'Sheriff', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('8b3bf335-5c5e-47a4-a272-4d322695dae6'::uuid, 'Monroe County', 'Surveyor', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('85210eee-9aba-4581-b539-3a74957d6fb7'::uuid, 'Monroe County', 'Treasurer', 'Monroe County Government', 'Monroe County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('071ba120-b792-408b-bb90-3d83d1a947c1'::uuid, 'Morgan County', 'Commission - District 1', '', 'Morgan County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('15cab2af-1630-4c70-af34-b40f808df9eb'::uuid, 'Morgan County', 'Commission - District 2', '', 'Morgan County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('ca154557-f502-45a0-a139-26e863882e3e'::uuid, 'Morgan County', 'Commission - District 3', '', 'Morgan County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('85ef91c4-8e1a-4b64-8857-5258af2a16bc'::uuid, 'Morgan County', 'Indiana Circuit Court Judge - 15th Circuit', '', 'Morgan County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('917229c6-96a7-4c12-940e-dfc6d3c398b9'::uuid, 'Morgan County', 'Council - At Large', '', 'Morgan County Council', 'full'::essentials.policy_engagement_level, 3),
  ('5b3b5e69-fbb6-48a6-b7ef-bcb6eeae4659'::uuid, 'Morgan County', 'Council - District 4', '', 'Morgan County Council', 'full'::essentials.policy_engagement_level, 1),
  ('c8853bbe-7e36-45b3-8637-1ff6e8b02826'::uuid, 'Morgan County', 'Assessor', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('d1a466db-b99f-485c-9c44-b43ba8ea7d37'::uuid, 'Morgan County', 'Auditor', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('76f2db84-05ed-44ca-bede-76087c7510ac'::uuid, 'Morgan County', 'Circuit Court Clerk', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('00e48917-5072-4bfa-ac3b-6ccaafd01111'::uuid, 'Morgan County', 'Coroner', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('6ada4b43-6567-4773-943c-454527dd5a78'::uuid, 'Morgan County', 'Prosecuting Attorney', '', 'Morgan County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('f978cdf6-f7a1-413f-8977-a2185b4db8da'::uuid, 'Morgan County', 'Recorder', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('715f6f73-217c-4689-876b-bd8286875c90'::uuid, 'Morgan County', 'Sheriff', '', 'Morgan County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('f852fefd-9691-4f95-8c15-91e2e223ebe1'::uuid, 'Morgan County', 'Surveyor', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('095cddda-6564-445c-9b20-ec6047bdbd5a'::uuid, 'Morgan County', 'Treasurer', '', 'Morgan County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('4009c6c4-6500-4fc8-8355-c72565aa5040'::uuid, 'Morgan County', 'Superior Court Judge - Court 2', '', 'Morgan County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('4da13471-a098-486b-b5b5-4692f7e88cc8'::uuid, 'Morgan County', 'Superior Court Judge - Court 3', '', 'Morgan County Superior Court', 'full'::essentials.policy_engagement_level, 1),
  ('ecc9df6c-9df5-483b-9641-370ac62ccf36'::uuid, 'Owen County', 'Commission - District 1', '', 'Owen County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('0709e4bb-428b-4d2f-a69c-1a49fc630a8d'::uuid, 'Owen County', 'Commission - District 2', '', 'Owen County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('adac1f84-f32c-4a9e-ba49-d2040a8c9f25'::uuid, 'Owen County', 'Commission - District 3', '', 'Owen County Board of Commissioners', 'full'::essentials.policy_engagement_level, 1),
  ('dedac1e8-b0ed-45fe-bae4-a7bb04a71b9e'::uuid, 'Owen County', 'Indiana Circuit Court Judge - 78th Circuit, Seat 1', '', 'Owen County Circuit Court', 'full'::essentials.policy_engagement_level, 0),
  ('67783ca7-2a4d-47b9-b2f8-95d1b51fc0be'::uuid, 'Owen County', 'Indiana Circuit Court Judge - 78th Circuit, Seat 2', '', 'Owen County Circuit Court', 'full'::essentials.policy_engagement_level, 1),
  ('2903daa3-63d1-4b88-8428-4700391e2c3c'::uuid, 'Owen County', 'Council - At Large', '', 'Owen County Council', 'full'::essentials.policy_engagement_level, 3),
  ('3cbecdfc-6240-4cff-b274-121bcd06dba7'::uuid, 'Owen County', 'Council - District 1', '', 'Owen County Council', 'full'::essentials.policy_engagement_level, 1),
  ('6eb5ee68-ac3a-4b31-9c87-e2750138519f'::uuid, 'Owen County', 'Council - District 2', '', 'Owen County Council', 'full'::essentials.policy_engagement_level, 1),
  ('b404c4fd-5d91-4960-b488-1abda0be8204'::uuid, 'Owen County', 'Council - District 3', '', 'Owen County Council', 'full'::essentials.policy_engagement_level, 1),
  ('f5ba177a-79e2-4461-a8d1-98b7de17e52a'::uuid, 'Owen County', 'Council - District 4', '', 'Owen County Council', 'full'::essentials.policy_engagement_level, 1),
  ('58ac3d9a-c85b-4a86-b513-7c1eface7cd8'::uuid, 'Owen County', 'Assessor', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('aacc382b-d040-41ef-9cf9-c7f0a1de318f'::uuid, 'Owen County', 'Auditor', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('c543d04c-d315-479b-aa61-13391b2d2b6a'::uuid, 'Owen County', 'Circuit Court Clerk', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('42984141-da5f-4cd6-8f1f-866abeaf3238'::uuid, 'Owen County', 'Coroner', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('5ee9ae6f-1d78-40e7-9d78-d5398135c950'::uuid, 'Owen County', 'Prosecuting Attorney', '', 'Owen County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('db7a1832-fdcb-4721-a6d7-3badb1a7fe32'::uuid, 'Owen County', 'Recorder', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('ba57cbdb-8a65-4b2a-92f2-bb4d9d23982d'::uuid, 'Owen County', 'Sheriff', '', 'Owen County Countywide Elected Officials', 'full'::essentials.policy_engagement_level, 1),
  ('862b7332-d32e-499d-80d0-f39490cdb7f7'::uuid, 'Owen County', 'Surveyor', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1),
  ('6c1f08e8-f3e4-4a89-952a-4b5622e24a83'::uuid, 'Owen County', 'Treasurer', '', 'Owen County Countywide Elected Officials', 'none'::essentials.policy_engagement_level, 1)
) AS v(chamber_id, county, name, old_formal, new_formal, pel, n_offices);

-- Pre-image of every chamber of the nine governments, for the post-verify (everything but name_formal).
CREATE TEMP TABLE ca0208_pre ON COMMIT DROP AS
SELECT ch.id, ch.government_id, ch.name, ch.policy_engagement_level, ch.external_id,
       (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id) AS n_offices
  FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
 WHERE g.name ~ '^(Brown|Greene|Jackson|Lawrence|Martin|Morgan|Owen|Marion|Monroe) County, Indiana, US$';

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_found int; n_bad int; n_gov int; n_other int; n_other_bad int; n_slug int; n_gvb_old int; n_gvb_new int; n_gvb_hit int;
BEGIN
  -- 0a. All 174 exist as recorded: name, engagement level, office count, and a name_formal that is the old
  --     value (first run) or the new one (re-run), under the county government their row names.
  SELECT count(ch.id),
         count(ch.id) FILTER (WHERE ch.name IS DISTINCT FROM t.name
                                OR ch.policy_engagement_level IS DISTINCT FROM t.pel
                                OR COALESCE(ch.name_formal, '') NOT IN (t.old_formal, t.new_formal)
                                OR g.name IS DISTINCT FROM t.county || ', Indiana, US'
                                OR (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id) <> t.n_offices)
    INTO n_found, n_bad
    FROM ca0208_chamber t
    LEFT JOIN essentials.chambers ch ON ch.id = t.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id;
  IF n_found <> 174 OR n_bad > 0 THEN
    RAISE EXCEPTION 'targets: % of 174 found, % not as recorded', n_found, n_bad;
  END IF;

  -- 0b. The nine governments hold 192 chambers: the 174, plus Monroe's 18 that already carry a body name
  --     (council 5, commission 3, circuit court 10 incl. its JUDICIAL-typed clerk). Anything else aborts.
  SELECT count(DISTINCT government_id) INTO n_gov FROM ca0208_pre;
  SELECT count(*),
         count(*) FILTER (WHERE COALESCE(ch.name_formal, '') NOT IN
                          ('Monroe County Council', 'Monroe County Board of Commissioners', 'Monroe County Circuit Court'))
    INTO n_other, n_other_bad
    FROM ca0208_pre p JOIN essentials.chambers ch ON ch.id = p.id
   WHERE p.id NOT IN (SELECT chamber_id FROM ca0208_chamber);
  IF n_gov <> 9 OR n_other <> 18 OR n_other_bad > 0 THEN
    RAISE EXCEPTION 'nine governments: % found, % untouched chamber(s) (want 18), % of them without a Monroe body name',
      n_gov, n_other, n_other_bad;
  END IF;

  -- 0c. No chamber outside the nine governments already has one of the new slugs (body search groups by
  --     slug; a clash would merge two bodies).
  SELECT count(*) INTO n_slug
    FROM essentials.chambers ch
   WHERE ch.id NOT IN (SELECT id FROM ca0208_pre)
     AND ch.slug IN (SELECT DISTINCT btrim(regexp_replace(translate(replace(public.f_unaccent(lower(COALESCE(t.new_formal, ''))), '&', 'and'), '''’.', ''), '[^a-z0-9]+', '-', 'g'), '-') FROM ca0208_chamber t);
  IF n_slug > 0 THEN
    RAISE EXCEPTION '% chamber(s) outside these governments already use a new slug', n_slug;
  END IF;

  -- 0d. Monroe's officers body row: exactly one, old key (first run) or new key (re-run).
  SELECT count(*) FILTER (WHERE body_key = 'Monroe County Government'),
         count(*) FILTER (WHERE body_key = 'Monroe County Countywide Elected Officials')
    INTO n_gvb_old, n_gvb_new
    FROM essentials.government_bodies WHERE state = 'IN' AND geo_id = '18105';
  IF n_gvb_old + n_gvb_new <> 1 THEN
    RAISE EXCEPTION 'Monroe officers body row: % old + % new (want exactly 1)', n_gvb_old, n_gvb_new;
  END IF;

  -- 0e. No body row in the eight neighbouring counties keys on a new name (one would relabel a group).
  SELECT count(*) INTO n_gvb_hit
    FROM essentials.government_bodies gvb
   WHERE gvb.state = 'IN'
     AND gvb.geo_id IN ('18013', '18055', '18071', '18093', '18101', '18109', '18119', '18097')
     AND gvb.body_key IN (SELECT new_formal FROM ca0208_chamber);
  IF n_gvb_hit > 0 THEN
    RAISE EXCEPTION '% government_bodies row(s) already key on a new name', n_gvb_hit;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Name each seat's chamber after its body.
-- ---------------------------------------------------------------------------
UPDATE essentials.chambers ch
   SET name_formal = t.new_formal
  FROM ca0208_chamber t
 WHERE ch.id = t.chamber_id
   AND COALESCE(ch.name_formal, '') = t.old_formal;

-- ---------------------------------------------------------------------------
-- 2. Monroe's officers body row follows its chambers' new name (website_url kept).
-- ---------------------------------------------------------------------------
UPDATE essentials.government_bodies
   SET body_key = 'Monroe County Countywide Elected Officials',
       display_name = 'Monroe County Countywide Elected Officials'
 WHERE state = 'IN' AND geo_id = '18105' AND body_key = 'Monroe County Government';

-- ---------------------------------------------------------------------------
-- 3. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_named int; n_slug_bad int; n_changed int; n_empty int; r record; n_nb_hit int; n_monroe int; n_monroe_hit int; n_url int;
BEGIN
  -- 3a. All 174 carry the new name, and the generated slug is the expected one.
  SELECT count(*) FILTER (WHERE ch.name_formal = t.new_formal),
         count(*) FILTER (WHERE ch.slug IS DISTINCT FROM btrim(regexp_replace(translate(replace(public.f_unaccent(lower(COALESCE(t.new_formal, ''))), '&', 'and'), '''’.', ''), '[^a-z0-9]+', '-', 'g'), '-'))
    INTO n_named, n_slug_bad
    FROM ca0208_chamber t JOIN essentials.chambers ch ON ch.id = t.chamber_id;
  IF n_named <> 174 OR n_slug_bad > 0 THEN
    RAISE EXCEPTION 'renamed: % of 174, % with an unexpected slug', n_named, n_slug_bad;
  END IF;

  -- 3b. Nothing but name_formal changed on any of the 192 chambers (government, name, engagement level,
  --     external_id, office count).
  SELECT count(*) INTO n_changed
    FROM ca0208_pre p JOIN essentials.chambers ch ON ch.id = p.id
   WHERE (ch.government_id, ch.name, ch.policy_engagement_level, ch.external_id,
          (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id))
         IS DISTINCT FROM (p.government_id, p.name, p.policy_engagement_level, p.external_id, p.n_offices);
  IF n_changed > 0 THEN
    RAISE EXCEPTION '% chamber(s) changed beyond name_formal', n_changed;
  END IF;

  -- 3c. The frontend contract: no chamber of the nine governments is left without a body name, and each
  --     county now has exactly its expected set of bodies.
  SELECT count(*) INTO n_empty
    FROM ca0208_pre p JOIN essentials.chambers ch ON ch.id = p.id
   WHERE COALESCE(ch.name_formal, '') = '';
  IF n_empty > 0 THEN
    RAISE EXCEPTION '% chamber(s) still without a name_formal', n_empty;
  END IF;
  FOR r IN
    SELECT g.name AS gov, count(DISTINCT ch.name_formal) AS bodies,
           CASE split_part(g.name, ',', 1)
             WHEN 'Brown County' THEN 4 WHEN 'Martin County' THEN 4 WHEN 'Owen County' THEN 4
             WHEN 'Marion County' THEN 3 WHEN 'Monroe County' THEN 4
             ELSE 5 END AS want
      FROM ca0208_pre p JOIN essentials.chambers ch ON ch.id = p.id
      JOIN essentials.governments g ON g.id = ch.government_id
     GROUP BY g.name
  LOOP
    IF r.bodies <> r.want THEN
      RAISE EXCEPTION '%: % distinct body names (want %)', r.gov, r.bodies, r.want;
    END IF;
  END LOOP;

  -- 3d. The body-row join, exactly as DISTRICT_JOINS runs it, for every office on these chambers:
  --     the eight neighbours match no body row (label from chamber_name_formal); Monroe's offices each
  --     match one of its four grouped rows.
  SELECT count(*) FILTER (WHERE g.name NOT LIKE 'Monroe County,%' AND gvb.id IS NOT NULL),
         count(*) FILTER (WHERE g.name LIKE 'Monroe County,%'),
         count(*) FILTER (WHERE g.name LIKE 'Monroe County,%' AND gvb.id IS NOT NULL)
    INTO n_nb_hit, n_monroe, n_monroe_hit
    FROM ca0208_pre p
    JOIN essentials.chambers ch ON ch.id = p.id
    JOIN essentials.governments g ON g.id = ch.government_id
    JOIN essentials.offices o ON o.chamber_id = ch.id
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state AND gvb.geo_id = d.geo_id
     AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '');
  IF n_nb_hit > 0 OR n_monroe_hit <> n_monroe THEN
    RAISE EXCEPTION 'body-row join: % neighbour office(s) still match a body row (want 0); Monroe % of % match',
      n_nb_hit, n_monroe_hit, n_monroe;
  END IF;

  -- 3e. Monroe's officers row kept its website.
  SELECT count(*) INTO n_url
    FROM essentials.government_bodies
   WHERE state = 'IN' AND geo_id = '18105' AND body_key = 'Monroe County Countywide Elected Officials'
     AND display_name = 'Monroe County Countywide Elected Officials' AND website_url = 'https://www.in.gov/counties/monroe/';
  IF n_url <> 1 THEN
    RAISE EXCEPTION 'Monroe officers body row: % with the new key and the kept website (want 1)', n_url;
  END IF;

  RAISE NOTICE 'OK: 174 Indiana per-seat chambers named after their body (9 counties); Monroe officers row re-keyed; nothing else changed';
END $$;

COMMIT;
