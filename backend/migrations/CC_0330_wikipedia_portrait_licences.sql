-- CC_0330_wikipedia_portrait_licences.sql
--
-- 26 portrait rows claimed an unversioned 'cc_by-sa' that had been inferred from the host. Their
-- real licence is read off the Commons file description page and written here, and the origin
-- moves from the Wikipedia ARTICLE page to that file page -- the only page that names an author
-- and states terms.
--
-- 🔴 21 OF THE 26 ARE NOT CREATIVE COMMONS AT ALL. They are public domain, mostly official
--    congressional portraits. The old value was not a wrong version; it was a wrong kind.
--      21  public_domain
--       3  cc_by-sa_4.0
--       1  cc_by-sa_3.0
--       1  cc_by_4.0
--
-- 🔴 THE VALUES THIS OVERWRITES are enumerated per row below: every row's old licence was
--    exactly 'cc_by-sa', and its old photo_origin_url is carried in the staged table. Nothing
--    else records them once this commits.
--
-- 🔴🔴 EVERY ROW CARRIES ITS OWN PROOF THAT THE COMMONS FILE IS OUR PHOTOGRAPH.
--    An article replaces its lead image over time, so "the page's photo is CC BY-SA 3.0" says
--    nothing about the file WE stored. Each row was checked by downloading both images and
--    measuring the mean absolute difference after downscaling to a common size. The staged 'mad'
--    column is that measurement and the migration gates on it.
--      accepted matches     : 0.0 - 5.5
--      rejected as different: 14.8 and above
--      negative controls    : 46 - 106   (our file against ANOTHER person's lead image)
--    61 of the 87 rows in this cohort were REFUSED on exactly this test and are left untouched.
--    ⚠ Several refusals sit in a grey band (7.6, 11.2, 14.4) where a recrop of the same shoot is
--      plausible. They are deliberately NOT auto-written; they belong to the research tail.
--
-- Read 2026-11-02 from the live Commons API; titles were asked for, never built from an upload path.

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE wk_fix (
  image_id      uuid PRIMARY KEY,
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  new_licence   text NOT NULL,
  old_origin    text NOT NULL,
  new_origin    text NOT NULL,
  artist        text NOT NULL,
  mad           numeric NOT NULL
) ON COMMIT DROP;

INSERT INTO wk_fix (image_id, politician_id, who, new_licence, old_origin, new_origin, artist, mad) VALUES
  ('0c1660f9-fbb8-48a6-87ab-13c8fc77cf95'::uuid, '449ad20f-7190-4c59-9809-0805e5a0edd8'::uuid, 'Al Green', 'public_domain',
   'https://en.wikipedia.org/wiki/Al_Green_(politician)', 'https://commons.wikimedia.org/wiki/File:Al_Green_-_119th_Congress_Full_Headshot.jpg', 'United States Congress', 0.79),
  ('9abea4fd-893d-4ef7-9684-95cd1bdf1f73'::uuid, '7dff1af1-993e-4d8f-8901-e4f96b93f11d'::uuid, 'Andrew Gruel', 'cc_by-sa_3.0',
   'https://en.wikipedia.org/wiki/Andrew_Gruel', 'https://commons.wikimedia.org/wiki/File:Andrew_Gruel_2016_(cropped).jpg', 'Lauren Gruel', 0.00),
  ('eaf31446-2e8f-42a9-abbc-157f9f699dca'::uuid, '4f4b2bff-0054-475f-8687-e83f68085f15'::uuid, 'Angus S. King, Jr.', 'public_domain',
   'https://en.wikipedia.org/wiki/Angus_King', 'https://commons.wikimedia.org/wiki/File:Angus_King,_official_portrait,_113th_Congress.jpg', 'United States Senate', 0.65),
  ('68acfeda-ae7c-457a-b58e-54b01ac0819d'::uuid, '4b04c042-bae9-456a-8ebc-e84e11397b23'::uuid, 'August Pfluger', 'public_domain',
   'https://en.wikipedia.org/wiki/August_Pfluger', 'https://commons.wikimedia.org/wiki/File:August_Pfluger_official_photo.jpg', 'United States Congress', 0.82),
  ('2f0118f5-a878-4787-8403-c22890432650'::uuid, '4b7c5474-9a09-4e12-8f74-17d5748909b3'::uuid, 'Brandon Gill', 'public_domain',
   'https://en.wikipedia.org/wiki/Brandon_Gill', 'https://commons.wikimedia.org/wiki/File:Brandon_Gill,_official_portrait,_119th_Congress.jpg', 'Nate Payne', 1.37),
  ('765d4d3e-838e-4fdb-95cb-716bb98dd9fa'::uuid, 'deae1b6d-3aa5-43fe-aff3-df73052cc434'::uuid, 'Dan Crenshaw', 'public_domain',
   'https://en.wikipedia.org/wiki/Dan_Crenshaw', 'https://commons.wikimedia.org/wiki/File:Rep._Dan_Crenshaw,_official_portrait,_118th_Congress.jpg', 'House Creative Services', 0.66),
  ('6e78361e-6bcc-4b39-aec3-7197fdb85f35'::uuid, '17ff1698-366e-4c56-a221-9d65fddd88ab'::uuid, 'Glenn Hegar', 'cc_by_4.0',
   'https://en.wikipedia.org/wiki/Glenn_Hegar', 'https://commons.wikimedia.org/wiki/File:Hegar_Glenn_0015-Cropped.jpg', 'Txams1948', 0.58),
  ('e8514fb1-6ba6-4366-b7d8-c5a6524e4313'::uuid, 'e31c865b-e378-4c02-b6d5-3f3fc1393791'::uuid, 'James Talarico', 'cc_by-sa_4.0',
   'https://en.wikipedia.org/wiki/James_Talarico', 'https://commons.wikimedia.org/wiki/File:James_Talarico_Press_Conference_(cropped).jpg', 'Antonioaesparza', 4.71),
  ('2c34ba52-cb42-4d51-abc5-55136d78446e'::uuid, 'a40f234e-1790-4b52-8670-090b6379eb03'::uuid, 'Jason M. Lewis', 'public_domain',
   'https://en.wikipedia.org/wiki/Jason_Lewis_(Massachusetts_politician)', 'https://commons.wikimedia.org/wiki/File:Jason_M._Lewis.jpg', 'Massachusetts General Court', 0.80),
  ('4a52bc68-0716-44cd-9ca1-c0d8c9768420'::uuid, '7c7b5942-8ad8-4e15-bd62-f16be22d676e'::uuid, 'Joaquin Castro', 'public_domain',
   'https://en.wikipedia.org/wiki/Joaquin_Castro', 'https://commons.wikimedia.org/wiki/File:Joaquin_Castro,_official_portrait,_118th_Congress.jpg', 'Nate Payne', 0.68),
  ('56b06e1d-aec2-400b-9799-2ad78b232126'::uuid, '2b022ce1-6272-40db-9332-015a057ec9f8'::uuid, 'John Cornyn', 'public_domain',
   'https://en.wikipedia.org/wiki/John_Cornyn', 'https://commons.wikimedia.org/wiki/File:John_Cornyn.jpg', 'United States Senate Photography Office', 0.78),
  ('a51d695c-13c0-491f-8425-a7c5d8fffaf0'::uuid, '5cd1c798-31dc-4e53-b578-7e2d81378478'::uuid, 'John F. Keenan', 'public_domain',
   'https://en.wikipedia.org/wiki/John_F._Keenan_(politician)', 'https://commons.wikimedia.org/wiki/File:John_Keenan.jpg', 'Massachusetts General Court', 5.48),
  ('45091d10-4279-4bec-bd12-71ab66d3e08a'::uuid, 'db2251fb-8188-4d17-917f-ade709e5e498'::uuid, 'Julie Johnson', 'public_domain',
   'https://en.wikipedia.org/wiki/Julie_Johnson_(politician)', 'https://commons.wikimedia.org/wiki/File:Rep._Julie_Johnson_Official_Portrait.jpg', 'Ike Hayman, House Creative Services', 0.89),
  ('ec7a0f9e-f517-4430-87ba-9559bce17578'::uuid, '90d1ac0b-efa6-42fc-abb2-34767380d607'::uuid, 'Katie Wilson', 'cc_by-sa_4.0',
   'https://en.wikipedia.org/wiki/Katie_Wilson', 'https://commons.wikimedia.org/wiki/File:Katie_Wilson_Seattle_mayoral_candidate_(cropped).jpg', 'Wilson for Seattle Campaign', 0.92),
  ('8f2b4cb9-2bd1-49b3-8dac-007135d8816c'::uuid, '65013b5e-faf5-458a-abc7-24cd61e32bdb'::uuid, 'Keith Self', 'public_domain',
   'https://en.wikipedia.org/wiki/Keith_Self', 'https://commons.wikimedia.org/wiki/File:Rep._Keith_Self_official_photo,_118th_Congress.jpg', 'United States Congress', 0.98),
  ('33da35c1-0d73-4e7d-9f7e-9c36b20095c7'::uuid, 'd141e4b7-f9a7-4ab0-927a-ba08348eab13'::uuid, 'Lance Gooden', 'public_domain',
   'https://en.wikipedia.org/wiki/Lance_Gooden', 'https://commons.wikimedia.org/wiki/File:Lance_Gooden,_official_portrait,_116th_Congress.jpg', 'United States Congress', 0.70),
  ('428aee29-1b51-46b9-a98b-35de48d776dc'::uuid, 'd429897d-efa9-4cf4-863b-900325cb7190'::uuid, 'Maebe Pudlo', 'public_domain',
   'https://en.wikipedia.org/wiki/Maebe_A._Girl', 'https://commons.wikimedia.org/wiki/File:Maebe_(crop).jpg', 'Silver Lake Neighborhood Council', 0.00),
  ('b2e4e7fd-225d-4883-ac68-efc4c47e4bf9'::uuid, '1139cf4b-c7be-464f-b343-69c4b0f8ace6'::uuid, 'Michael McCaul', 'public_domain',
   'https://en.wikipedia.org/wiki/Michael_McCaul', 'https://commons.wikimedia.org/wiki/File:Rep._Michael_McCaul,_official_portrait,_118th_Congress.jpg', 'U.S. House Office of Photography', 3.89),
  ('29e1dc54-9f79-41d1-add8-a32e7f99ecf6'::uuid, 'c3cb5289-17af-4952-9894-dbddfcd50484'::uuid, 'Monica De La Cruz', 'cc_by-sa_4.0',
   'https://en.wikipedia.org/wiki/Monica_De_La_Cruz', 'https://commons.wikimedia.org/wiki/File:MDLC_Official_Portrait_2025.jpg', 'Nicktilson', 0.82),
  ('dab532fc-40d3-4ae9-a776-a7a8cdc8396d'::uuid, 'e9236454-c687-4721-8193-e37e018c6905'::uuid, 'Nathaniel Moran', 'public_domain',
   'https://en.wikipedia.org/wiki/Nathaniel_Moran', 'https://commons.wikimedia.org/wiki/File:Rep._Nathaniel_Moran_official_photo,_118th_Congress.jpg', 'United States Congress', 1.01),
  ('62be5aac-d4f4-4b59-bcbc-f3f96ac983ff'::uuid, 'c6187c67-fa60-4fa2-917f-543cd7fc441f'::uuid, 'Pat Fallon', 'public_domain',
   'https://en.wikipedia.org/wiki/Pat_Fallon', 'https://commons.wikimedia.org/wiki/File:PatFallon118th.jpg', 'House Creative Services', 0.92),
  ('d313da4e-fa5e-4b80-9e76-11102ef7ee6f'::uuid, '62b453da-3dea-4177-82ba-9e4b78eb7691'::uuid, 'Stephen Lynch', 'public_domain',
   'https://en.wikipedia.org/wiki/Stephen_Lynch_(politician)', 'https://commons.wikimedia.org/wiki/File:Stephen_Lynch_2019.jpg', 'US House of Representatives', 0.72),
  ('d70b947d-56fe-47d8-81e5-0a1c071d4af1'::uuid, 'b956345e-e9fb-4e4f-97b3-ed2213f5da1e'::uuid, 'Sylvia Garcia', 'public_domain',
   'https://en.wikipedia.org/wiki/Sylvia_Garcia', 'https://commons.wikimedia.org/wiki/File:Sylvia_Garcia,_official_portrait,_116th_Congress.jpg', 'United States Congress', 0.81),
  ('877bcbd3-3431-4366-aa7f-c8630ae40752'::uuid, 'a0bc977b-71c6-4973-9082-3cc009445a02'::uuid, 'Troy Nehls', 'public_domain',
   'https://en.wikipedia.org/wiki/Troy_Nehls', 'https://commons.wikimedia.org/wiki/File:Troy_Nehls_117th_U.S_Congress.jpg', 'House Creative Committee', 0.85),
  ('9ccfea19-d2f8-4d62-8529-6fe6083d4231'::uuid, '6a18fa31-ad05-481a-bf5e-ecaa5cd193d1'::uuid, 'Vicente Gonzalez', 'public_domain',
   'https://en.wikipedia.org/wiki/Vicente_Gonzalez_(American_politician)', 'https://commons.wikimedia.org/wiki/File:Rep._Vicente_Gonzalez,_118th_Congress.jpg', 'U.S. House of Representatives', 1.28),
  ('73b202c5-6071-4580-8366-340e9ec047f0'::uuid, '0248c3ba-caea-4421-9be3-ceaa6e0df69e'::uuid, 'Wesley Hunt', 'public_domain',
   'https://en.wikipedia.org/wiki/Wesley_Hunt', 'https://commons.wikimedia.org/wiki/File:Rep._Wesley_Hunt_official_photo.jpg', 'United States Congress', 1.08);

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM wk_fix;
  IF v_n <> 26 THEN RAISE EXCEPTION 'pre-flight: expected 26 staged rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id;
  IF v_n <> 26 THEN RAISE EXCEPTION 'pre-flight: % of 26 staged images exist', v_n; END IF;

  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license IS DISTINCT FROM 'cc_by-sa';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry the unversioned cc_by-sa', v_n;
  END IF;

  -- The image must belong to the politician whose origin we are about to overwrite.
  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.politician_id IS DISTINCT FROM f.politician_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged image(s) belong to another politician', v_n; END IF;

  -- 🔴 The recorded old origin must still be what the database holds, or the before-image is
  --    already stale and the overwrite would destroy a value this file does not record.
  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE coalesce(p.photo_origin_url, '') IS DISTINCT FROM f.old_origin;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry their recorded old origin', v_n;
  END IF;

  -- 🔴 Recomputed from the database, not from the staged column: every old origin really is a
  --    Wikipedia article page, so no other cohort can be swept in here.
  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE coalesce(p.photo_origin_url, '') !~* '^https://en\.wikipedia\.org/wiki/';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % staged row(s) are not Wikipedia-sourced', v_n; END IF;

  SELECT count(*) INTO v_n FROM wk_fix
   WHERE new_origin !~ '^https://commons\.wikimedia\.org/wiki/File:';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % new origin(s) are not a Commons file page', v_n; END IF;

  SELECT count(*) INTO v_n FROM wk_fix WHERE new_licence NOT IN ('cc0', 'cc_by_2.0', 'cc_by_3.0', 'cc_by_4.0', 'cc_by-sa', 'cc_by-sa_2.0', 'cc_by-sa_3.0', 'cc_by-sa_4.0', 'public_domain');
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % row(s) target a non-canonical licence', v_n; END IF;

  -- 🔴 EVERY CC ROW MUST NAME AN AUTHOR. A CC licence other than CC0 requires attribution, so
  --    recording one with nobody to credit would create the very gap CC_0326 closed.
  SELECT count(*) INTO v_n FROM wk_fix
   WHERE new_licence LIKE 'cc\_%' AND new_licence <> 'cc0' AND btrim(artist) = '';
  IF v_n <> 0 THEN RAISE EXCEPTION 'pre-flight: % CC row(s) name no author', v_n; END IF;

  -- 🔴 THE SAME-PHOTOGRAPH PROOF. Anything at or above the match ceiling is a different picture.
  SELECT count(*) INTO v_n FROM wk_fix WHERE mad >= 6.0;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) did not match their Commons file', v_n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = f.new_licence
  FROM wk_fix f
 WHERE pi.id = f.image_id
   AND pi.photo_license = 'cc_by-sa';

UPDATE essentials.politicians p
   SET photo_origin_url = f.new_origin
  FROM wk_fix f
 WHERE p.id = f.politician_id
   AND coalesce(p.photo_origin_url, '') = f.old_origin;

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license = f.new_licence;
  IF v_n <> 26 THEN RAISE EXCEPTION 'post-verify: % of 26 carry their corrected licence', v_n; END IF;

  SELECT count(*) INTO v_n FROM wk_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE p.photo_origin_url = f.new_origin;
  IF v_n <> 26 THEN RAISE EXCEPTION 'post-verify: % of 26 point at their Commons file page', v_n; END IF;

  -- 🔴 Delta, not a total.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_before - v_n <> 26 THEN
    RAISE EXCEPTION 'post-verify: unversioned cc_by-sa fell by %, expected 26', v_before - v_n;
  END IF;

  -- Nothing outside cc_by-sa and the licences written here may have changed count.
  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) <> 'cc_by-sa'
     AND coalesce(a.lic, b.lic) NOT IN (SELECT DISTINCT new_licence FROM wk_fix);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the corrected set changed count', v_n;
  END IF;
END $$;

COMMIT;
