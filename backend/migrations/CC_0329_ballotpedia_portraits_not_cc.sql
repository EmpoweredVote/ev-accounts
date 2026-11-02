-- CC_0329_ballotpedia_portraits_not_cc.sql
--
-- 89 portrait rows claim Creative Commons BY-SA. Ballotpedia licenses none of them, and the claim
-- is not merely unverified -- it is unsupportable. They become 'candidate_submitted'.
--
-- 🔴 THE VALUE THIS OVERWRITES: every one of the 89 currently reads exactly 'cc_by-sa' (the
--    unversioned value, normalised by CC_0328). No row here carries a version, so nothing more
--    specific is being discarded. Each row's politician and origin URL are enumerated below, and
--    photo_origin_url is NOT touched -- the Ballotpedia profile remains the record of where the
--    file came from.
--
-- WHY THE OLD VALUE CANNOT BE RIGHT, measured 2026-11-02
--   Ballotpedia's person photographs are NOT MediaWiki files. They are served from a separate
--   asset store (s3.amazonaws.com/ballotpedia-api4/files/thumbs/...) which has no file
--   description page and carries no licence metadata of any kind -- probed across a sample, 0 of
--   8 stated a licence, and the absence is structural rather than a sampling result.
--   Ballotpedia's own documentation says these come from the candidate directly, or from the
--   candidate's campaign site or public accounts. Either way the copyright sits with the
--   candidate's side and was never Ballotpedia's to license. Its ARTICLE TEXT is GFDL, which is
--   not CC BY-SA either, and does not reach the photographs regardless.
--
-- ⚠ WHAT 'candidate_submitted' CLAIMS, AND WHAT IT DOES NOT
--   It records the route -- the photograph reached us from the candidate's own side via
--   Ballotpedia -- and asserts NO reuse terms. It is deliberately not a grant. Rights remain
--   unestablished, and these rows stay findable as one group for whenever that is pursued.
--   🔴 It is NOT a licence. Do not read it as permission to redistribute.
--
-- Operator ruling 2026-11-02: use this token rather than blanking the rows, so the provenance we do
-- have is kept instead of being thrown away with the false claim.

BEGIN;

CREATE TEMP TABLE lic_before ON COMMIT DROP AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
    FROM essentials.politician_images GROUP BY 1;

CREATE TEMP TABLE bp_fix (
  image_id uuid PRIMARY KEY,
  who      text NOT NULL,
  origin   text NOT NULL
) ON COMMIT DROP;

INSERT INTO bp_fix (image_id, who, origin) VALUES
  ('9b952f60-4ed7-4d91-a8af-a5ca36401c69'::uuid, 'Abdur Rahman Sikder', 'https://ballotpedia.org/Abdur_Rahman_Sikder'),
  ('f9beeef7-a0bb-48b3-876b-92234006f0a2'::uuid, 'Adrienne Konigar-Macklin', 'https://ballotpedia.org/Adrienne_D._Konigar-Macklin'),
  ('10135389-1335-4bdf-a1fa-4d1cfb85416a'::uuid, 'Ainye Long', 'https://ballotpedia.org/Ainye_Long'),
  ('b64465d3-2e92-411a-91bb-e7d19fd56cb3'::uuid, 'Al Muratsuchi', 'https://ballotpedia.org/Al_Muratsuchi'),
  ('0591342d-303a-4d11-bc03-e8cdba4c9fb2'::uuid, 'Alice Stek', 'https://ballotpedia.org/Alice_Stek'),
  ('9fb8199b-de10-4624-a61e-ee5a5b47f800'::uuid, 'Alma Taylor-Pleasant', 'https://ballotpedia.org/Alma_Taylor-Pleasant'),
  ('e92277d7-890d-4b2e-a93e-f412aae9c7ce'::uuid, 'Ana Maria Quintana', 'https://ballotpedia.org/Ana_Maria_Quintana'),
  ('51b5ab4c-0cc9-4a9c-a220-a851736e78d4'::uuid, 'Andy Manske', 'https://ballotpedia.org/Andrew_Manske'),
  ('41213208-2c83-45d1-b681-6c3d3de6512c'::uuid, 'Anthony Bryson', 'https://ballotpedia.org/Anthony_Bryson'),
  ('97cc5a83-3a15-4b71-a2e8-324fd34688c0'::uuid, 'Anthony Rendon', 'https://ballotpedia.org/Anthony_Rendon'),
  ('e240b46e-9e28-4aa2-959b-4568c2bd0b99'::uuid, 'Antonio Villaraigosa', 'https://ballotpedia.org/Antonio_Villaraigosa'),
  ('1351156f-5dce-4fac-8440-1d9f9bd396d1'::uuid, 'Armond Aghakhanian', 'https://ballotpedia.org/Armond_Aghakhanian'),
  ('aac22646-b8ad-445d-ac49-4366ca7b2ac4'::uuid, 'Ava Flanell', 'https://ballotpedia.org/Ava_Flanell'),
  ('29a81c73-8a15-45bc-b29f-b4dfd04044d6'::uuid, 'Blanca E. Rubio', 'https://ballotpedia.org/Blanca_Rubio'),
  ('feb37ade-e2d8-4e04-b672-bccacb2dd841'::uuid, 'Blanca Pacheco', 'https://ballotpedia.org/Blanca_Pacheco'),
  ('3c16f67e-88d6-4028-9384-0013dcfb4143'::uuid, 'Bradley Meyer', 'https://ballotpedia.org/Brad_Meyer'),
  ('3a5ea9fc-02fd-45ef-b761-f3eb46db6314'::uuid, 'Carlos Barron', 'https://ballotpedia.org/Carlos_Barron'),
  ('bafc11f0-e1de-4d3c-8a38-ce96f0a0f4a7'::uuid, 'Carrie Buck', 'https://ballotpedia.org/Carrie_Buck_(Nevada)'),
  ('86025dcf-ef88-4e32-9200-0c615ff6c514'::uuid, 'Chad Clifford', 'https://ballotpedia.org/Chad_Clifford'),
  ('2fc8f193-1080-4904-af4c-2cd886546f8b'::uuid, 'Chris Richardson', 'https://ballotpedia.org/Chris_Richardson_(Colorado)'),
  ('861f5ee3-22f6-4a14-8aef-167e0a84a63d'::uuid, 'Cody Whipple', 'https://ballotpedia.org/Cody_Whipple'),
  ('a078d470-7b27-4664-8e8b-32d556b034a5'::uuid, 'Cristina Lucero', 'https://ballotpedia.org/Christina_Lucero'),
  ('38e9a63c-df7d-4545-9078-b46990590e0a'::uuid, 'David Collenberg', 'https://ballotpedia.org/David_Collenberg'),
  ('7742d27e-3047-40d3-bbad-cffc2cb9886a'::uuid, 'David Fennell', 'https://ballotpedia.org/David_Fennell'),
  ('f526b6a7-1318-4151-b2bd-17a95b9fb8ed'::uuid, 'David Flippo', 'https://ballotpedia.org/David_Flippo'),
  ('d54ccf68-fe1f-4d3a-8c29-8bdbc17f8925'::uuid, 'David Varnam', 'https://ballotpedia.org/David_Varnam'),
  ('0b18776f-7512-4a24-b7f6-8c9d37604dfe'::uuid, 'David W. Paulson', 'https://ballotpedia.org/David_W._Paulson'),
  ('d132f7cb-9104-4af7-985d-2040e172799a'::uuid, 'Delaine Eastin', 'https://ballotpedia.org/Delaine_Eastin'),
  ('8fb16929-e56d-4bc6-9cf9-1bdeaf1ad169'::uuid, 'Dennis Trujillo', 'https://ballotpedia.org/Dennis_Trujillo'),
  ('019e48ca-7a95-4f24-9b8a-c6e05544b6a3'::uuid, 'Diana Craighead', 'https://ballotpedia.org/Diana_Craighead'),
  ('b2a3cdc6-1d98-49eb-9390-dad0bf56bb38'::uuid, 'Don J. Grundmann', 'https://ballotpedia.org/Don_Grundmann'),
  ('29b699f8-e9c4-41f3-8416-531db34a8033'::uuid, 'Donald P. Wagner', 'https://ballotpedia.org/Donald_P._Wagner'),
  ('d75f1abf-3e31-449e-8c7b-4982d6fa97fb'::uuid, 'Drew Johnson', 'https://ballotpedia.org/Drew_Johnson_(Nevada)'),
  ('3f93fd5e-6c3a-4e8d-9de5-9645faef20f2'::uuid, 'Ebie Lynch', 'https://ballotpedia.org/Ebie_Lynch'),
  ('577c5279-53af-4d0e-9a10-e94a432343e0'::uuid, 'Eleni Kounalakis', 'https://ballotpedia.org/Eleni_Kounalakis'),
  ('02558142-421b-4db3-a853-f28d2b378120'::uuid, 'Eugene A. Gasiorkiewicz', 'https://ballotpedia.org/Eugene_Gasiorkiewicz'),
  ('93225665-09f4-43a2-8afc-faa24df1762c'::uuid, 'Francesca Hong', 'https://ballotpedia.org/Francesca_Hong'),
  ('cfd4e7a8-876f-4240-9f5c-7d3223cd12a6'::uuid, 'Frank Lara', 'https://ballotpedia.org/Frank_Lara_(California)'),
  ('1907b290-7f03-4650-9a8e-f420bab0ac5b'::uuid, 'Gary N. Blenner', 'https://ballotpedia.org/Gary_Blenner'),
  ('27546165-1806-4fa2-bb0f-5bd0aad7ef87'::uuid, 'Gus Mattammal', 'https://ballotpedia.org/Gus_Mattammal'),
  ('eeaba0e7-7d70-4e07-bc64-9de8bcdefc21'::uuid, 'Isaac G. Bryan', 'https://ballotpedia.org/Isaac_Bryan'),
  ('17b388e5-cdd4-4bf5-995a-9825bfb243e6'::uuid, 'Jackie Goldberg', 'https://ballotpedia.org/Jackie_Goldberg'),
  ('47eaa4cf-1ad6-4d42-9b41-757b67c5fb73'::uuid, 'Jacque Phillips', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/jacque_phillips.jpg'),
  ('6f8ced23-c876-495e-b9d5-3e1cce7d09bb'::uuid, 'James Graham', 'https://ballotpedia.org/James_Graham_(Indiana)'),
  ('edbb1778-68f8-4b71-a450-8f4bdc936bb3'::uuid, 'James Hanink', 'https://ballotpedia.org/James_Hanink'),
  ('5d4bd91d-7e8d-47fc-ab24-b0eee1ce917d'::uuid, 'James Williamson', 'https://ballotpedia.org/James_Williamson_(California)'),
  ('5f9d95f0-61d4-4104-8d03-768419430739'::uuid, 'Jamie Jackson', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Jamie_Jackson_Colorado_House.jpg'),
  ('6d8459f6-e4b8-48c7-92eb-6634e5571c8e'::uuid, 'Jamie Jo Carothers', 'https://ballotpedia.org/Jamie_Jo_Carothers'),
  ('1a773e22-c1c1-404d-afc9-f2f383304fc3'::uuid, 'Janelle Kellman', 'https://ballotpedia.org/Janelle_Kellman'),
  ('8110a77d-f866-49a2-b73a-742356012426'::uuid, 'Janice Rich', 'https://ballotpedia.org/Janice_Rich'),
  ('2bbf7ab3-5231-4575-9dce-59b2537e86be'::uuid, 'Jeyson Lopez', 'https://ballotpedia.org/Jeyson_Lopez'),
  ('0fcc828d-1a28-4d5b-9a02-384c221d1cea'::uuid, 'Jim Marchant', 'https://ballotpedia.org/Jim_Marchant'),
  ('aa91e116-9416-49c6-a3d5-03a28f9cc6e1'::uuid, 'Joel Brennan', 'https://ballotpedia.org/Joel_Brennan'),
  ('baba2271-fe52-433a-be9a-27a492fd5507'::uuid, 'Joel E. Jacob', 'https://ballotpedia.org/Joel_Jacob'),
  ('6db67ee9-5840-4a83-ba8b-c9823b9f547a'::uuid, 'John Carson', 'https://ballotpedia.org/John_Carson_(Colorado)'),
  ('13505fa0-cd69-4559-85df-292e9cb3790b'::uuid, 'Jorge Hernandez Rosas', 'https://ballotpedia.org/Jorge_Hernandez_Rosas'),
  ('32c8bf92-9c70-4406-8829-602e25b119ef'::uuid, 'Josh Fryday', 'https://ballotpedia.org/Josh_Fryday'),
  ('fb74bd5d-5493-4a70-bb51-f8d77c05049d'::uuid, 'Josh Newman', 'https://ballotpedia.org/Josh_Newman'),
  ('d545317b-1782-4bc6-8848-ddf6dfcbc4dc'::uuid, 'Katie Wallace', 'https://ballotpedia.org/Katie_Wallace'),
  ('3f0e4541-3b75-4867-b6e5-acfc95e3d3a9'::uuid, 'Keil Roark', 'https://ballotpedia.org/Keil_Roark'),
  ('aed85eb3-f194-4b90-93a9-fec5feb3d201'::uuid, 'Kelda Roys', 'https://ballotpedia.org/Kelda_Roys'),
  ('badf82c3-2a69-4f0b-ae7d-89b89df15b56'::uuid, 'Kenny Nguyen', 'https://ballotpedia.org/Kenny_Nguyen'),
  ('81638169-68a7-4d75-82b7-8d9e383d6ab5'::uuid, 'Larry Don Suckla', 'https://ballotpedia.org/Larry_Don_Suckla'),
  ('3a655b25-0ea3-4236-8ae1-824f0d25f04b'::uuid, 'Larry Liston', 'https://ballotpedia.org/Larry_Liston'),
  ('57668715-ed3a-40be-b677-8cbb1869bdd7'::uuid, 'Lilliana Young', 'https://ballotpedia.org/Lilliana_Young'),
  ('089ad4f9-4b98-454a-867c-386ca808e546'::uuid, 'Lori Goldstein', 'https://ballotpedia.org/Lori_Goldstein'),
  ('ebc20067-e888-41c3-b7fa-03e5df93555c'::uuid, 'Lynda Zamora Wilson', 'https://ballotpedia.org/Lynda_Zamora_Wilson'),
  ('56b4425c-451b-4d5b-99b8-f14d458efa8e'::uuid, 'Mandela Barnes', 'https://ballotpedia.org/Mandela_Barnes'),
  ('89abc29d-a029-4fbd-affd-619c4307bd1d'::uuid, 'Marty O''Donnell', 'https://ballotpedia.org/Marty_O%27Donnell_(Nevada)'),
  ('7042174f-ff57-4731-aecb-97922f02f440'::uuid, 'Matt Soper', 'https://ballotpedia.org/Matt_Soper'),
  ('aabf00f7-b6cc-4401-8f1e-ac564e9f91dc'::uuid, 'Michael Allen', 'https://ballotpedia.org/Michael_Allen_(Colorado)'),
  ('045e6225-f19b-4961-971c-e10d4c72eeeb'::uuid, 'Michael E. Gates', 'https://ballotpedia.org/Michael_Gates_(California)'),
  ('83fcdd68-3de3-4969-b6bc-1848fd1f47f8'::uuid, 'Michael Feinstein', 'https://ballotpedia.org/Michael_Feinstein_(California)'),
  ('a4cffcbd-74f3-4d15-9a2e-7671faaa270d'::uuid, 'Michael MacDougall', 'https://ballotpedia.org/Michael_MacDougall'),
  ('4dc704d9-01ef-47e0-805b-58eb71c56df5'::uuid, 'Michael Tubbs', 'https://ballotpedia.org/Michael_Tubbs'),
  ('a52dd27a-8802-4813-8c25-3d68736ed55c'::uuid, 'Nichelle M. Henderson', 'https://ballotpedia.org/Nichelle_Henderson'),
  ('225cbcdd-f447-4230-bd5e-47e36628b9dc'::uuid, 'Oliver Ma', 'https://ballotpedia.org/Oliver_Ma'),
  ('95489350-7dce-4a5f-9a70-d58e040a052b'::uuid, 'Ronald Sampson', 'https://ballotpedia.org/Ronald_Sampson'),
  ('a5bcaf31-2013-4abc-bea1-a1781daa6ed2'::uuid, 'Ryan Gonzalez', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/ryangonzalez.jpeg'),
  ('bda3e292-67c3-4b11-979d-45fee9531caf'::uuid, 'Scott Slaugh', 'https://ballotpedia.org/Scott_Slaugh'),
  ('59d07b41-f0b6-467d-8971-14b3f3a0ddda'::uuid, 'Sean Collinson', 'https://ballotpedia.org/Sean_Collinson_(California)'),
  ('60b6b84e-e2c3-4315-b7c3-2560c9b190d8'::uuid, 'Teresa Benitez-Thompson', 'https://ballotpedia.org/Teresa_Benitez-Thompson'),
  ('514c6088-fb1e-4aff-b464-14d8fc1fb8e6'::uuid, 'Thunder Parley', 'https://ballotpedia.org/Thunder_Parley'),
  ('ff337edd-ab4e-427a-8c79-78acaea12819'::uuid, 'Tim Myers', 'https://ballotpedia.org/Tim_Myers_(California)'),
  ('97004044-5421-4899-bf08-a871fb119d4c'::uuid, 'Timothy Peck', 'https://ballotpedia.org/Timothy_Peck'),
  ('ceabbf83-4293-4554-8362-8d6dccf25121'::uuid, 'Tom Steyer', 'https://ballotpedia.org/Thomas_Steyer'),
  ('ad1daed9-74c8-441a-a5a2-3202222edba7'::uuid, 'Tya Mathis-Coleman', 'https://ballotpedia.org/Tya_Mathis-Coleman'),
  ('469ecc3a-b933-4516-ac42-1c5f996b9319'::uuid, 'Will Martin', 'https://ballotpedia.org/Will_Martin_(Wisconsin)'),
  ('a1abc1b8-20a0-44ce-910d-e38edff10264'::uuid, 'Yemi Mobolade', 'https://ballotpedia.org/Yemi_Mobolade');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM bp_fix;
  IF v_n <> 89 THEN RAISE EXCEPTION 'pre-flight: expected 89 staged rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM bp_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id;
  IF v_n <> 89 THEN RAISE EXCEPTION 'pre-flight: % of 89 staged images exist', v_n; END IF;

  SELECT count(*) INTO v_n FROM bp_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license IS DISTINCT FROM 'cc_by-sa';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) no longer carry the unversioned cc_by-sa', v_n;
  END IF;

  -- 🔴🔴 THE BALLOTPEDIA-NESS IS RECOMPUTED FROM THE DATABASE'S OWN photo_origin_url, NOT from
  --     the origin column staged above. A check derived from the same data that did the
  --     selection moves with the defect: swap two rows in the generator and a staged-column
  --     check still agrees with itself. This one cannot.
  SELECT count(*) INTO v_n
    FROM bp_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE coalesce(p.photo_origin_url, '') !~ '(ballotpedia\.org|ballotpedia-api4)';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % staged row(s) do not actually have a Ballotpedia origin', v_n;
  END IF;

  -- 🔴 The staged set must be EVERY unversioned row with a Ballotpedia origin. One left behind
  --    keeps an unsupportable CC claim in production and out of the group that records it.
  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.photo_license = 'cc_by-sa' AND pi.type = 'default'
     AND coalesce(p.photo_origin_url, '') ~ '(ballotpedia\.org|ballotpedia-api4)'
     AND NOT EXISTS (SELECT 1 FROM bp_fix f WHERE f.image_id = pi.id);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'pre-flight: % Ballotpedia cc_by-sa row(s) are not staged', v_n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = 'candidate_submitted'
  FROM bp_fix f
 WHERE pi.id = f.image_id
   AND pi.photo_license = 'cc_by-sa';

-- ---------------------------------------------------------------------------------------------
-- Post-verify.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE v_n int; v_before int;
BEGIN
  SELECT count(*) INTO v_n FROM bp_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license = 'candidate_submitted';
  IF v_n <> 89 THEN RAISE EXCEPTION 'post-verify: % of 89 carry candidate_submitted', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.photo_license = 'cc_by-sa' AND coalesce(p.photo_origin_url, '') ~ '(ballotpedia\.org|ballotpedia-api4)';
  IF v_n <> 0 THEN RAISE EXCEPTION 'post-verify: % Ballotpedia row(s) still claim CC BY-SA', v_n; END IF;

  -- 🔴 A DELTA, not a total: the unversioned population must fall by exactly 89, whatever another
  --    session did to it while this file was being written.
  SELECT coalesce((SELECT n FROM lic_before WHERE lic = 'cc_by-sa'), 0) INTO v_before;
  SELECT count(*) INTO v_n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa';
  IF v_before - v_n <> 89 THEN
    RAISE EXCEPTION 'post-verify: unversioned cc_by-sa fell by %, expected 89', v_before - v_n;
  END IF;

  -- Nothing outside the two values this migration moves may have changed count.
  SELECT count(*) INTO v_n FROM (
    SELECT coalesce(photo_license, '<null>') AS lic, count(*)::int AS n
      FROM essentials.politician_images GROUP BY 1
  ) a
  FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) NOT IN ('cc_by-sa', 'candidate_submitted');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the relabelled set changed count', v_n;
  END IF;
END $$;

COMMIT;
