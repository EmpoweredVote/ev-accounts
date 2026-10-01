-- Knight Cities coverage, measured by the method recorded in reference_live_artifacts.
--   officials = local + county seats, jurisdiction resolved by
--               coalesce(chambers.government_id, districts.government_id)
--               -- Wichita's offices have a NULL chamber_id and hang off districts alone
--   excluded  = court chambers (name ~* 'Court' but NOT 'Fiscal Court'), and chamber-less
--               judge offices. An elected prosecutor is not a court.
--   portraits = politicians.photo_custom_url non-empty
--   compass   = an inform.politician_answers row with value <> 0
WITH city(city, st, slice, gov) AS (VALUES
  ('Aberdeen','SD',15,'{ec445d9d-6951-4990-b846-207f1b0cf715,7924c3d3-1eac-4c98-8067-02e8f949bbe4}'::uuid[]),
  ('Akron','OH',8,'{afcb104b-eb62-40e1-a435-ceb598026fb4,ededa623-ebd4-436c-bd50-9a22290a24e3}'::uuid[]),
  ('Biloxi','MS',16,'{b8c2cbd9-ad29-43bd-b0eb-f965c37af25c,9ea25562-c483-43f4-8dd0-131235b828f8}'::uuid[]),
  ('Boulder','CO',9,'{d5a4026b-7218-4337-9a47-291633e554b6,f121a5cb-7109-4361-a1a0-aa2f166118ed}'::uuid[]),
  ('Bradenton','FL',1,'{03a07152-9004-4c2e-a964-176a8a0dd71e,42f89f1b-23b2-405f-8e4d-72e3ce2c0994}'::uuid[]),
  ('Charlotte','NC',10,'{90cd3033-69fc-4abd-b48f-17b6f8f57f73,9a858f93-db6d-49a2-9a2b-518e0b226ab6}'::uuid[]),
  ('Columbia','SC',7,'{e1a3755b-11e3-4bec-b0ab-f7e86b0e0950,3b6cf476-8a87-4278-847d-6f7c02512afd}'::uuid[]),
  ('Columbus','GA',2,'{5fc0dd7d-3ae9-49a4-93a1-ae4a3779fddd}'::uuid[]),
  ('Detroit','MI',11,'{9b13a1e5-5301-4e5b-9baa-a845c35df96b,561f9998-519b-49be-b9b1-3d0106e0e3c1}'::uuid[]),
  ('Duluth','MN',5,'{41be0c66-3a53-46a7-8fcd-26b022363879,c5ac520e-b8fa-4e38-be8c-194222b26298}'::uuid[]),
  ('Fort Wayne','IN',4,'{472f0e46-1a28-40b4-8c12-0d0cfa9be0a0,aa3b7198-695a-4dd9-b9e3-a3dc3e1ec373}'::uuid[]),
  ('Gary','IN',4,'{6699c6a7-a4e1-42f6-af12-e9616fc9ed06,e5d1d991-d1bb-49ed-8ff9-0c4e474b1191}'::uuid[]),
  ('Grand Forks','ND',12,'{2184b4ff-ebef-4c4d-9e01-c0ed94e3f325,af1143a1-dad4-4148-901b-993739d7462e}'::uuid[]),
  ('Lexington','KY',13,'{51799d05-d922-4cf3-99f9-8cf9d92858da}'::uuid[]),
  ('Long Beach','CA',3,'{5e5c3e0b-5479-4759-ac7e-2ea0aecabd38,4236875b-3909-4ae4-ae91-41ae21c07a45}'::uuid[]),
  ('Macon','GA',2,'{cac83614-20ff-4dbf-a341-2fe076054845}'::uuid[]),
  ('Miami','FL',1,'{fc6052a9-bf60-4f11-9a25-a1def6f3245a,d31ea899-f015-4456-8370-b727e3bef271}'::uuid[]),
  ('Milledgeville','GA',2,'{621f55ec-59c5-471f-a75d-5ad008474e12,aa1960a0-d74b-4eb6-8024-a3ca2ac4a49e}'::uuid[]),
  ('Myrtle Beach','SC',7,'{2d22ef58-9bf3-41c4-840d-fa76b40e6b50,0084727b-549a-4463-a394-772d942cf6e6}'::uuid[]),
  ('Palm Beach County','FL',1,'{873b3f10-1b4c-4b14-a62c-56d43fc1ee9f}'::uuid[]),
  ('Philadelphia','PA',6,'{e0617b99-7328-44de-8be7-eda123a47159}'::uuid[]),
  ('San Jose','CA',3,'{47c9ce0a-401e-46d8-ae63-89266584b39a,8f0c9bb1-4b30-46c0-a563-746c423c7b3a}'::uuid[]),
  ('St. Paul','MN',5,'{cd00206f-42c0-42f0-affd-dfef6c688958,853494d6-4c4e-4f99-aa78-0f2401f06a21}'::uuid[]),
  ('State College','PA',6,'{f1620beb-51c4-40a7-91f0-d24e71abfab6,b2bce6ca-1a82-49a0-800e-c4a432a6ab63}'::uuid[]),
  ('Tallahassee','FL',1,'{9b10bf5b-10fb-4e26-9e9a-e7447c0ea79d,d83ad549-77d8-46c2-8aeb-e65af8c46898}'::uuid[]),
  ('Wichita','KS',14,'{45dae0e7-13d6-43f2-b4f2-45f8b5ddc36e,60933db6-ac16-4fe7-8d5a-06379cd080b2}'::uuid[])
),
seat AS (
  SELECT o.id AS office_id,
         coalesce(c.government_id, d.government_id) AS gov_id,
         c.name AS chamber_name,
         o.title
    FROM essentials.offices o
    LEFT JOIN essentials.chambers  c ON c.id = o.chamber_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
),
kept AS (
  SELECT s.* FROM seat s
   WHERE s.gov_id IS NOT NULL
     -- Court chambers out, but a Fiscal Court is a legislative body.
     -- 🔴 coalesce() IS LOAD-BEARING: with a NULL chamber_name, `NULL ~* 'Court'` is NULL,
     -- so `NOT (NULL AND ...)` is NULL and WHERE discards the row. That silently dropped
     -- every chamber-less office -- which is all seven City of Wichita seats, whose offices
     -- carry a NULL chamber_id and hang off districts.government_id alone. The recorded rule
     -- covers the JOIN; the exclusion needs the same NULL-safety or the join's fix is undone.
     AND NOT (coalesce(s.chamber_name,'') ~* 'Court' AND coalesce(s.chamber_name,'') !~* 'Fiscal Court')
     -- chamber-less judge offices out; an elected prosecutor is NOT a court
     AND NOT (s.chamber_name IS NULL AND s.title ~* '(Judge|Justice|Magistrate)')
),
cur AS (
  SELECT DISTINCT ot.office_id, ot.politician_id
    FROM essentials.office_terms ot
   WHERE ot.politician_id IS NOT NULL
     AND (ot.term_start IS NULL OR ot.term_start <= CURRENT_DATE)
     AND (ot.term_end   IS NULL OR ot.term_end   >= CURRENT_DATE)
)
SELECT ci.city, ci.st, ci.slice,
       count(DISTINCT p.id)                                                              AS officials,
       count(DISTINCT p.id) FILTER (WHERE coalesce(btrim(p.photo_custom_url),'') <> '')  AS portraits,
       count(DISTINCT p.id) FILTER (WHERE EXISTS (
         SELECT 1 FROM inform.politician_answers pa
          WHERE pa.politician_id = p.id AND pa.value <> 0))                              AS compass
  FROM city ci
  LEFT JOIN kept k ON k.gov_id = ANY(ci.gov)
  LEFT JOIN cur ON cur.office_id = k.office_id
  LEFT JOIN essentials.politicians p ON p.id = cur.politician_id
 GROUP BY ci.city, ci.st, ci.slice
 ORDER BY ci.city;
