-- CA_0200_utah_countywide_officers_chambers.sql
--
-- Split the row officers out of ten Utah counties' commission / council chambers into a second chamber per
-- county, "Countywide Elected Officials", the shape 28 other counties already use (Dane, Racine, Alameda,
-- Los Angeles, ...). 73 offices move; the 44 commissioners and council members stay where they are.
--
-- WHY
-- ---
-- Each of these ten counties has ONE chamber, named for its legislative body, and every county office sits
-- in it: Utah County's "Utah County Commission" holds the three commissioners AND the Assessor, Auditor,
-- Clerk, County Attorney, Recorder, Sheriff, Surveyor and Treasurer. Consumers that read the chamber as
-- "the body this official belongs to" therefore file the Sheriff under the County Commission:
--   * essentials frontend (src/lib/groupHierarchy.js, main b1e54bf2, the county sub-group fix in essentials
--     PR #157): COUNTY sub-groups key and label on the chamber, so Utah County renders ONE sub-group,
--     "Utah County Commission", holding 11 cards (3 commissioners + 8 row officers). Before #157 it was
--     labelled "Commissioner (Chair)".
--   * essentials body search (essentialsBodiesService, by chamber slug): "Utah County Commission" reports
--     11 members.
-- Measured 2026-09-23: these are the only ten county chambers in the database that mix a legislative body
-- with row officers. (Georgia, Florida and Pennsylvania "Elected Officials" chambers also hold a tax
-- commissioner or property appraiser, but they are officers-only chambers already.)
--
-- WHAT THIS DOES
-- --------------
--   1. One new chamber per county, fixed id, under the SAME government row as the old chamber:
--        name 'Countywide Elected Officials', name_formal '<County> Countywide Elected Officials',
--        slug '<county>-countywide-elected-officials', policy_engagement_level 'full' —
--      exactly the values of the 28 existing chambers of that name (all 'full'; the old Utah chambers are
--      'full' too, so no compass/profile behaviour changes: only 'none' alters a profile).
--   2. Move the non-legislative offices into it, by fixed office id: Assessor, Auditor, Clerk,
--      Clerk/Auditor, Controller, County Attorney, District Attorney, Recorder, Recorder/Surveyor, Sheriff,
--      Surveyor, Treasurer — and the two county EXECUTIVES, Cache County Executive and Salt Lake County
--      Mayor. Executives follow the Dane / Racine precedent (County Executive in "Countywide Elected
--      Officials"); King and Miami-Dade give the executive a chamber of its own, which would also be
--      defensible, and is a one-row follow-up if the operator prefers it.
--
-- WHAT A USER WILL SEE
-- --------------------
--   Utah County browse / address lookup, Local tier, "Utah County":
--     before  Utah County Commission (11)
--     after   Utah County Commission (3), then Utah County Countywide Elected Officials (8)
--   Salt Lake County: Salt Lake County Council (9), then Salt Lake County Countywide Elected Officials (9).
--   (Frontend ordering: a COUNTY sub-group labelled with a legislative word sorts first, other COUNTY
--   groups after — essentials #157.)
--
-- NOT CHANGED
-- -----------
--   No district, geography, government, office title, office_terms, politician or race row. The old
--   chambers keep their id, name and slug. Every backend join from office to chamber goes on to the
--   government (peopleService, electionService, campaignFinance*, fecResearch, locationSearchService), and
--   the new chamber has the same government_id, so each of them resolves to the same county. None of the
--   ten old chambers has a meeting, discovered_source or source_outlet row, and no government_bodies row
--   keys on any of these chamber names (both gated below).
--
-- No migration runner exists; this file records SQL applied by hand. No DELETE.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). First dry run caught that
--   chambers.slug is a GENERATED column (from name_formal) — the INSERT no longer names it; the gates still
--   compare the generated slug to the recorded one. Second dry run: INSERT 10 / UPDATE 73, every gate passed,
--   rollback confirmed reverted (0 new chambers, 73 officers still on the old chambers). Apply: same counts,
--   COMMIT. Re-run inside BEGIN/ROLLBACK after the apply: INSERT 0 / UPDATE 0, every gate passed.
--   Live, grouped with essentials main's groupHierarchy.js:
--     browse 49049  Utah County Commission 11          -> Commission 3 + Countywide Elected Officials 8
--     browse 49035  Salt Lake County Council 3 + 15    -> Council 9 + Countywide Elected Officials 9 (with CA_0199)
--     browse 49005  Cache County Council 15            -> Council 7 + Countywide Elected Officials 8
--     351 W Center St, Provo -> county 49049; Commission 3 + Countywide Elected Officials 8
--   Row counts per browse unchanged. check:reachability OK (UNREACHABLE 24/24, BAD_GEOMETRY 4/4, DEAD 17/17).
--
-- ROLLBACK:
--   UPDATE essentials.offices o SET chamber_id = c.old_chamber_id
--     FROM <ca0200_chamber below> c WHERE o.chamber_id = c.new_chamber_id;
--   DELETE FROM essentials.chambers WHERE id IN (<the ten new_chamber_id values below>);
-- IDEMPOTENT: the chambers insert on fixed ids (ON CONFLICT DO NOTHING, then the post-verify checks every
-- value), and the offices UPDATE is guarded on the old chamber_id. A re-run changes nothing and every gate
-- still passes.

BEGIN;

-- One row per county: the government, the chamber the officers leave, the chamber they join.
CREATE TEMP TABLE ca0200_chamber ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('Box Elder County', '0d82ba05-3fc6-42fe-a09b-3dc25720bc11'::uuid, '1ccbc40d-9b91-42f7-bdad-991efb9c540f'::uuid, '98ee855f-84b6-4b90-948d-318ee249acc5'::uuid, 'Box Elder County Countywide Elected Officials', 'box-elder-county-countywide-elected-officials', 7, 3),
  ('Cache County', '180c587b-2845-438e-988a-6137a0124ce4'::uuid, '0b6d374d-2a13-45cd-9717-1de146e396cf'::uuid, 'db912b30-bdd6-4a66-bb62-3e31a5e4790f'::uuid, 'Cache County Countywide Elected Officials', 'cache-county-countywide-elected-officials', 8, 7),
  ('Davis County', '7b9d8955-3dca-4861-ab1e-2a6569e3dd44'::uuid, 'd98060da-b649-468f-b58f-342de2b59eb2'::uuid, '8adbf990-1b90-4dff-8082-bc833cfd10e8'::uuid, 'Davis County Countywide Elected Officials', 'davis-county-countywide-elected-officials', 8, 3),
  ('Iron County', 'ed101e8d-44a3-4e74-9f65-3f483fdb2108'::uuid, '8e81544c-e8c0-499a-a1b0-40fbf63aedf5'::uuid, '8c898583-4996-47c7-ab25-11cb5e3c3169'::uuid, 'Iron County Countywide Elected Officials', 'iron-county-countywide-elected-officials', 7, 3),
  ('Salt Lake County', '959842a9-4cab-4b50-95cd-51dc031e849b'::uuid, '67872e2f-020d-4bd5-adf5-f70f27635b83'::uuid, '5fb65fde-e39e-4294-aaea-371545cc3a43'::uuid, 'Salt Lake County Countywide Elected Officials', 'salt-lake-county-countywide-elected-officials', 9, 9),
  ('Summit County', 'ad1393cf-7b91-4d83-b28d-cb7cde3d1bf3'::uuid, 'c7b6979f-02f9-4097-b8fb-d6cab709eeb3'::uuid, '7190b57d-4bec-438a-a9f6-cbb6b9b36e27'::uuid, 'Summit County Countywide Elected Officials', 'summit-county-countywide-elected-officials', 7, 5),
  ('Tooele County', '148584d5-9c68-4ce4-8e13-fa8f45480919'::uuid, '5acab0ff-f523-4f3f-a2f5-c8d766705021'::uuid, '2d759397-59e9-47cf-9c8a-13ca3f616124'::uuid, 'Tooele County Countywide Elected Officials', 'tooele-county-countywide-elected-officials', 7, 5),
  ('Utah County', 'dd5697a4-02a1-4514-8db7-8b857859c139'::uuid, '05bd4855-3896-414e-a58a-cd227025d271'::uuid, '7a55d616-b076-4048-ac8b-edbd029ea100'::uuid, 'Utah County Countywide Elected Officials', 'utah-county-countywide-elected-officials', 8, 3),
  ('Washington County', '988b2199-cf8a-4956-848c-26fc0cc0295c'::uuid, '26b476cf-0df3-4a6b-a871-799a35aea14f'::uuid, 'd2eaad5b-0baf-4ea8-852b-bc81319c6c54'::uuid, 'Washington County Countywide Elected Officials', 'washington-county-countywide-elected-officials', 6, 3),
  ('Weber County', '718771f6-ca63-4070-b782-371481c57187'::uuid, '91a89b78-8941-4968-a0e3-5580bda7ec23'::uuid, 'e57e6a7f-3e89-483c-b884-b309cdac83ca'::uuid, 'Weber County Countywide Elected Officials', 'weber-county-countywide-elected-officials', 6, 3)
) AS v(county, government_id, old_chamber_id, new_chamber_id, name_formal, slug, n_move, n_stay);

-- The 73 offices that move, by fixed id, with the title each must still carry.
CREATE TEMP TABLE ca0200_move ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('95ce367d-4387-4642-a94c-70be6640208a'::uuid, 'Box Elder County', 'Assessor'),
  ('302c9156-951e-4a14-b053-bc588f82b5db'::uuid, 'Box Elder County', 'Auditor'),
  ('1d8efc08-2b9f-48dd-b19e-31a7fbe97ed0'::uuid, 'Box Elder County', 'Clerk'),
  ('cf877dbd-6541-4d53-b319-25ac6171508e'::uuid, 'Box Elder County', 'County Attorney'),
  ('a79b3441-3edb-4444-a185-f0d634bede77'::uuid, 'Box Elder County', 'Recorder'),
  ('209c99a1-21b3-4a4f-98c8-997bb7e05fb3'::uuid, 'Box Elder County', 'Sheriff'),
  ('f4f0e289-4086-4f89-8db4-5d601f691836'::uuid, 'Box Elder County', 'Treasurer'),
  ('b256153c-23a5-47b8-8da8-1e36c836a205'::uuid, 'Cache County', 'Assessor'),
  ('7cad9fc9-64fa-40aa-a9e1-207d0f80dbb4'::uuid, 'Cache County', 'Auditor'),
  ('3b8a2997-3424-4341-8c13-eca50b07bf08'::uuid, 'Cache County', 'Clerk'),
  ('f9a33216-6141-41dc-98f5-6a41b5f8982e'::uuid, 'Cache County', 'County Attorney'),
  ('b6626677-a7c7-47c8-80d9-9eed29b69f1f'::uuid, 'Cache County', 'County Executive'),
  ('446b88be-b882-49c3-980a-e68e4b594ab7'::uuid, 'Cache County', 'Recorder'),
  ('a635bf0b-411c-4894-88c8-ed8eabbc8428'::uuid, 'Cache County', 'Sheriff'),
  ('93a375f8-7433-4e38-9e85-dc58a3e17faa'::uuid, 'Cache County', 'Treasurer'),
  ('bebb8470-f50c-427e-b275-bfd5b98405a2'::uuid, 'Davis County', 'Assessor'),
  ('c1730f20-1bc5-4393-8b8b-2e7c51164242'::uuid, 'Davis County', 'Clerk'),
  ('b53e29ed-ddbc-4837-9d8d-2133365b5ea5'::uuid, 'Davis County', 'Controller'),
  ('65878d3c-355f-482b-9965-10f1a1bfaa5b'::uuid, 'Davis County', 'County Attorney'),
  ('1f43fea2-31db-4a41-a6d1-e5b214f46778'::uuid, 'Davis County', 'Recorder'),
  ('5edd69b1-dffd-447a-978c-9bf59f156e8e'::uuid, 'Davis County', 'Sheriff'),
  ('3e0227f7-1451-44c2-a961-3bf5af512b77'::uuid, 'Davis County', 'Surveyor'),
  ('683b08d5-79c5-4b3f-aaa9-d4ad3fb7a625'::uuid, 'Davis County', 'Treasurer'),
  ('7f289d31-3918-4dbb-8638-d2fa0c2a2072'::uuid, 'Iron County', 'Assessor'),
  ('ae671567-66b4-4f33-9b34-c1776bad1dcf'::uuid, 'Iron County', 'Auditor'),
  ('77d81e81-7beb-48b5-badc-5793286b4536'::uuid, 'Iron County', 'Clerk'),
  ('2263259e-67f7-402b-96df-a2b725b911cb'::uuid, 'Iron County', 'County Attorney'),
  ('45b7c7be-def2-4144-b224-c4b1376924a0'::uuid, 'Iron County', 'Recorder'),
  ('814c1669-2c59-46d5-9530-52f1440cddd8'::uuid, 'Iron County', 'Sheriff'),
  ('d1e94d73-6561-4605-bfee-cad32c5bbf1f'::uuid, 'Iron County', 'Treasurer'),
  ('9affe4d3-c37c-4d6e-ad15-0c99b7a89fd9'::uuid, 'Salt Lake County', 'Assessor'),
  ('5f34abc8-c191-4144-b6ea-5226eb576e19'::uuid, 'Salt Lake County', 'Auditor'),
  ('f7fb84f0-f8ca-467f-ac00-a03db836327f'::uuid, 'Salt Lake County', 'Clerk'),
  ('2b6b84ad-f69a-484a-b96e-82976c94ef87'::uuid, 'Salt Lake County', 'District Attorney'),
  ('29c44a74-1686-466f-a73b-e0273cd509d2'::uuid, 'Salt Lake County', 'Mayor'),
  ('24d3f2d6-694e-4e92-b5b8-67df47c25401'::uuid, 'Salt Lake County', 'Recorder'),
  ('d6c89923-a6f2-4eea-bf3e-f40986b4268d'::uuid, 'Salt Lake County', 'Sheriff'),
  ('c1ebaaa1-0213-4a0c-b474-1cc6b76cfec3'::uuid, 'Salt Lake County', 'Surveyor'),
  ('71f6fcea-33b4-4c8e-8163-b614a790b94f'::uuid, 'Salt Lake County', 'Treasurer'),
  ('4155f01e-bd6f-46a0-8ebf-15b13572eb65'::uuid, 'Summit County', 'Assessor'),
  ('ce20e79a-0d62-4310-ac1f-29808c7f5a0c'::uuid, 'Summit County', 'Auditor'),
  ('0ed3c0a4-5c14-471b-bc49-ace11eaa352f'::uuid, 'Summit County', 'Clerk'),
  ('dd7fb8bf-cb18-4e56-8fa3-d45243178e8e'::uuid, 'Summit County', 'County Attorney'),
  ('1d448ada-8669-4312-837e-d743da15e0b7'::uuid, 'Summit County', 'Recorder/Surveyor'),
  ('dd6d5b09-0c64-4641-8ab0-8fabec624987'::uuid, 'Summit County', 'Sheriff'),
  ('01205b58-0c41-4ae7-86cd-5da8a91e9a71'::uuid, 'Summit County', 'Treasurer'),
  ('a4e4df9b-07f0-4cbe-b28d-bf3ab49feece'::uuid, 'Tooele County', 'Assessor'),
  ('27b750bb-7584-472e-a409-3cab4759ce9e'::uuid, 'Tooele County', 'Auditor'),
  ('b55a4953-c99a-4d4a-af21-bcbdbef400a7'::uuid, 'Tooele County', 'Clerk'),
  ('6022ae22-fb51-44b3-aea7-494dc338ba85'::uuid, 'Tooele County', 'County Attorney'),
  ('94a5057f-df4e-48bf-80a6-f3b1bd7221c9'::uuid, 'Tooele County', 'Recorder/Surveyor'),
  ('c3616a3f-2227-48a5-8478-d2f882075e11'::uuid, 'Tooele County', 'Sheriff'),
  ('3cc4e025-ac75-45c4-8604-5c7134439a1a'::uuid, 'Tooele County', 'Treasurer'),
  ('bd7cf4db-00c7-498f-9844-bb56a573f01b'::uuid, 'Utah County', 'Assessor'),
  ('bebaf899-a656-4345-a9c4-cb39b878ca36'::uuid, 'Utah County', 'Auditor'),
  ('f17e0ce8-117d-468c-acc6-46b13116e634'::uuid, 'Utah County', 'Clerk'),
  ('daf1fa50-abdb-4996-82ac-c0a6d55f4257'::uuid, 'Utah County', 'County Attorney'),
  ('94115e79-7a23-4f37-bf17-4c362385ef03'::uuid, 'Utah County', 'Recorder'),
  ('3ac71e23-02a8-4d34-a8c0-85f1110019ab'::uuid, 'Utah County', 'Sheriff'),
  ('deb27807-8cb5-4b2e-9fa4-b73307d39599'::uuid, 'Utah County', 'Surveyor'),
  ('2795dad6-4115-4894-bc25-8c628a358203'::uuid, 'Utah County', 'Treasurer'),
  ('fa4457f9-a474-4531-ba67-e72a9e6b2ab0'::uuid, 'Washington County', 'Assessor'),
  ('9be65f80-dbae-4998-bb72-d2b54f8533fc'::uuid, 'Washington County', 'Clerk/Auditor'),
  ('ee4cb02b-b06e-4fbc-a9eb-e176afb8eefe'::uuid, 'Washington County', 'County Attorney'),
  ('2c90904d-f7b5-43c0-a908-587346bad3bc'::uuid, 'Washington County', 'Recorder/Surveyor'),
  ('a16f7160-59c2-43b0-ba02-c0bd9fc28e0a'::uuid, 'Washington County', 'Sheriff'),
  ('3cc20689-6a86-46d7-b8d2-78f1ae124f27'::uuid, 'Washington County', 'Treasurer'),
  ('ff2726a8-2968-49bf-8e88-86af37099ce2'::uuid, 'Weber County', 'Assessor'),
  ('34128526-6769-411b-bbf0-d8afcef4953b'::uuid, 'Weber County', 'Clerk/Auditor'),
  ('c8df93ab-739b-4227-8e55-40930473b357'::uuid, 'Weber County', 'County Attorney'),
  ('0eaf5455-6dc6-43f8-a329-0b2ff445e838'::uuid, 'Weber County', 'Recorder/Surveyor'),
  ('94e4fa55-b08a-4b02-b061-db4c728b45ab'::uuid, 'Weber County', 'Sheriff'),
  ('a6ed604f-d7ae-4ff7-b0e8-7e322001e5ba'::uuid, 'Weber County', 'Treasurer')
) AS v(office_id, county, title);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight. Refuse to run against a state this file was not written for.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_gov int; n_old int; n_extra_ch int; n_off int; n_off_bad int; n_stay_bad int; n_count_bad int;
  n_id_clash int; n_name_clash int; n_body int; n_refs int; n_not_countywide int;
BEGIN
  -- 0a. The ten governments and their old chambers are the rows the header describes.
  SELECT count(*) INTO n_gov
    FROM ca0200_chamber c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = c.county || ', Utah, US' AND g.type = 'County';
  SELECT count(*) INTO n_old
    FROM ca0200_chamber c
    JOIN essentials.chambers ch ON ch.id = c.old_chamber_id
   WHERE ch.government_id = c.government_id AND ch.name_formal ~ ('^' || c.county || ' (Commission|Council)$');
  IF n_gov <> 10 OR n_old <> 10 THEN
    RAISE EXCEPTION 'governments % / old chambers % match (want 10 / 10)', n_gov, n_old;
  END IF;

  -- 0b. Each government holds only the old chamber (first run) or old + new (re-run).
  SELECT count(*) INTO n_extra_ch
    FROM ca0200_chamber c
    JOIN essentials.chambers ch ON ch.government_id = c.government_id
   WHERE ch.id NOT IN (c.old_chamber_id, c.new_chamber_id);
  IF n_extra_ch > 0 THEN
    RAISE EXCEPTION '% other chamber(s) exist under these ten governments', n_extra_ch;
  END IF;

  -- 0c. Each moving office exists with its recorded title, on its county's old chamber (first run) or new
  --     chamber (re-run), on the county-wide district (geo_id = the county FIPS, COUNTY).
  SELECT count(o.id),
         count(o.id) FILTER (WHERE o.title IS DISTINCT FROM m.title
                               OR o.chamber_id NOT IN (c.old_chamber_id, c.new_chamber_id)),
         count(o.id) FILTER (WHERE d.district_type IS DISTINCT FROM 'COUNTY' OR d.geo_id IS DISTINCT FROM g.geo_id)
    INTO n_off, n_off_bad, n_not_countywide
    FROM ca0200_move m
    JOIN ca0200_chamber c ON c.county = m.county
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.offices o ON o.id = m.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id;
  IF n_off <> 73 OR n_off_bad > 0 OR n_not_countywide > 0 THEN
    RAISE EXCEPTION 'moving offices: % of 73 found, % wrong title/chamber, % not on the county-wide district',
      n_off, n_off_bad, n_not_countywide;
  END IF;

  -- 0d. Everything else on the old chambers is a commissioner / council seat, n_stay of them.
  SELECT count(*) FILTER (WHERE o.title !~* '(commissioner|council)')
    INTO n_stay_bad
    FROM ca0200_chamber c
    JOIN essentials.offices o ON o.chamber_id = c.old_chamber_id
   WHERE o.id NOT IN (SELECT office_id FROM ca0200_move);
  SELECT count(*) INTO n_count_bad
    FROM ca0200_chamber c
   WHERE (SELECT count(*) FROM essentials.offices o
           WHERE o.chamber_id = c.old_chamber_id AND o.id NOT IN (SELECT office_id FROM ca0200_move)) <> c.n_stay;
  IF n_stay_bad > 0 OR n_count_bad > 0 THEN
    RAISE EXCEPTION 'staying offices: % not commissioner/council, % county(ies) with the wrong count', n_stay_bad, n_count_bad;
  END IF;

  -- 0e. A fixed new id is either free or already exactly this file's row (re-run).
  SELECT count(*) INTO n_id_clash
    FROM essentials.chambers ch JOIN ca0200_chamber c ON c.new_chamber_id = ch.id
   WHERE (ch.government_id, ch.name, ch.name_formal, ch.slug, ch.policy_engagement_level)
         IS DISTINCT FROM (c.government_id, 'Countywide Elected Officials', c.name_formal, c.slug, 'full'::essentials.policy_engagement_level);
  IF n_id_clash > 0 THEN
    RAISE EXCEPTION '% new chamber id(s) already exist with different values', n_id_clash;
  END IF;

  -- 0f. No OTHER chamber carries a new slug or name_formal (the slug index is not unique; body search
  --     groups by slug, so a clash would merge two bodies).
  SELECT count(*) INTO n_name_clash
    FROM essentials.chambers ch
   WHERE ch.id NOT IN (SELECT new_chamber_id FROM ca0200_chamber)
     AND (ch.slug IN (SELECT slug FROM ca0200_chamber) OR ch.name_formal IN (SELECT name_formal FROM ca0200_chamber));
  IF n_name_clash > 0 THEN
    RAISE EXCEPTION '% other chamber(s) already use a new slug or name_formal', n_name_clash;
  END IF;

  -- 0g. No government_bodies row keys on the old or new chamber names (one would change the heading /
  --     sub-group label the header describes).
  SELECT count(*) INTO n_body
    FROM essentials.government_bodies gvb
    JOIN ca0200_chamber c ON gvb.body_key IN (c.name_formal, c.county || ' Commission', c.county || ' Council')
   WHERE lower(gvb.state) = 'ut';
  IF n_body > 0 THEN
    RAISE EXCEPTION '% government_bodies row(s) key on these chamber names', n_body;
  END IF;

  -- 0h. Nothing else hangs off the old chambers (the header's claim).
  SELECT (SELECT count(*) FROM meetings.meetings WHERE chamber_id IN (SELECT old_chamber_id FROM ca0200_chamber))
       + (SELECT count(*) FROM essentials.discovered_sources WHERE chamber_id IN (SELECT old_chamber_id FROM ca0200_chamber))
       + (SELECT count(*) FROM essentials.source_outlets WHERE chamber_id IN (SELECT old_chamber_id FROM ca0200_chamber))
    INTO n_refs;
  IF n_refs > 0 THEN
    RAISE EXCEPTION '% meeting / source row(s) reference the old chambers', n_refs;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. The ten chambers.
-- ---------------------------------------------------------------------------
-- chambers.slug is a GENERATED column (from name_formal), so it is not inserted; gates 0e and 3a check that
-- the generated value equals the slug recorded above.
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level)
SELECT new_chamber_id, government_id, 'Countywide Elected Officials', name_formal, 'full'
  FROM ca0200_chamber
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Move the 73 offices. Only those still on their county's old chamber.
-- ---------------------------------------------------------------------------
UPDATE essentials.offices o
   SET chamber_id = c.new_chamber_id
  FROM ca0200_move m
  JOIN ca0200_chamber c ON c.county = m.county
 WHERE o.id = m.office_id
   AND o.chamber_id = c.old_chamber_id;

-- ---------------------------------------------------------------------------
-- 3. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_ch int; n_bad_ch int; r record; n_held int;
BEGIN
  -- 3a. The ten chambers exist with exactly the decided values.
  SELECT count(ch.id),
         count(ch.id) FILTER (WHERE (ch.government_id, ch.name, ch.name_formal, ch.slug, ch.policy_engagement_level)
                                    IS DISTINCT FROM (c.government_id, 'Countywide Elected Officials', c.name_formal, c.slug,
                                                      'full'::essentials.policy_engagement_level))
    INTO n_ch, n_bad_ch
    FROM ca0200_chamber c LEFT JOIN essentials.chambers ch ON ch.id = c.new_chamber_id;
  IF n_ch <> 10 OR n_bad_ch > 0 THEN
    RAISE EXCEPTION 'new chambers: % row(s), % with the wrong values (want 10, 0)', n_ch, n_bad_ch;
  END IF;

  -- 3b. Per county: the new chamber holds exactly its movers, the old one exactly its commissioners /
  --     council members, and nothing is left behind on either side.
  FOR r IN
    SELECT c.county, c.n_move, c.n_stay,
           (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.new_chamber_id) AS got_new,
           (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.new_chamber_id
              AND o.id NOT IN (SELECT office_id FROM ca0200_move m WHERE m.county = c.county)) AS stray_new,
           (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.old_chamber_id) AS got_old,
           (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.old_chamber_id
              AND o.title !~* '(commissioner|council)') AS stray_old
      FROM ca0200_chamber c
  LOOP
    IF r.got_new <> r.n_move OR r.stray_new > 0 OR r.got_old <> r.n_stay OR r.stray_old > 0 THEN
      RAISE EXCEPTION '%: new chamber % (want %, % stray), old chamber % (want %, % non-legislative)',
        r.county, r.got_new, r.n_move, r.stray_new, r.got_old, r.n_stay, r.stray_old;
    END IF;
  END LOOP;

  -- 3c. Occupancy is untouched: every moved office still resolves to a current holder (all 73 were held
  --     on 2026-09-23).
  SELECT count(*) INTO n_held
    FROM ca0200_move m JOIN essentials.office_current_holder och ON och.office_id = m.office_id;
  IF n_held <> 73 THEN
    RAISE EXCEPTION 'moved offices with a current holder: % (want 73)', n_held;
  END IF;

  RAISE NOTICE 'OK: 10 Utah "Countywide Elected Officials" chambers; 73 officers moved; 44 commissioners / council members stay';
END $$;

COMMIT;
