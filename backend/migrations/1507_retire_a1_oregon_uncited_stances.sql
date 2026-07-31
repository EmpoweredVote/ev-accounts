-- 1507_retire_a1_oregon_uncited_stances.sql
--
-- Retire 86 published stance answers across 53 Oregon officeholders whose CITED SOURCE
-- demonstrably does not contain the claim. Cohort A1 of the stance re-sourcing backlog.
--   Evidence:        data/stance-retirement/2026-07-30-a1-oregon-citation-audit.json
--   Rollback record: data/stance-retirement/2026-07-29-suspect-stance-backlog.csv carries
--                    politician_id, topic_id, value, write_in_text, reasoning and sources for
--                    every row deleted here, so this is fully reversible from the repo.
--
-- WHAT WAS TESTED. All 94 cited Ballotpedia pages were fetched and searched for the bills named in
-- each row's OWN reasoning. This judges the CITATION, not the claim: a row deleted here may still
-- be true, it simply is not sourced by the thing it cites. Two classes:
--    83  named >=1 specific bill, NONE of which appears anywhere on the cited page
--     3  the cited page is a 404 — the source does not exist at all
--
-- Worked example: Dan Rayfield's rows cite HB 2002, SB 1547, HB 3115 and HB 2929. His page carries
-- none of them, no "Medicaid", no "voucher", no "transgender", and states he did not complete
-- Ballotpedia's candidate survey. Only 29 distinct bills are cited across all 94 politicians.
--
-- WHAT IS DELIBERATELY LEFT ALONE — 144 of the cohort's 230 rows. 140 name no bill at all, so there
-- is nothing mechanical to test and they need claim-level review; 4 name a measure that DOES appear
-- on the page and still need the "does it support THIS chair" test. An earlier pass over-counted
-- these as failures by applying a politician-level verdict to every one of that politician's rows.
-- Deleting an untested row is the same error as publishing an unsourced one, pointed the other way.
--
-- 🔴 METHOD NOTE for whoever runs cohorts A2-A6: Ballotpedia rate-limits SILENTLY. Parallel fetches
-- return HTTP 202 with an EMPTY BODY, and r.ok is TRUE for 202, so a naive probe scores "bill not
-- found" for a page it never read and the false negative is indistinguishable from evidence. The
-- first sweep here was invalid for exactly that reason. Fetch serially with ~1.3s delay and treat
-- status <> 200 OR chars < 3000 as UNKNOWN, never as a miss.
--
-- Idempotent: the target set is an explicit (politician_id, topic_id) list, so a re-run deletes
-- nothing. Structure follows migration 1494.

BEGIN;

CREATE TEMP TABLE _retire_1507 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1507 (politician_id, topic_id) VALUES
  ('402a00be-71c3-4584-b29f-bf493365bffb'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Christine Drazan · Public Safety Approach
  ('402a00be-71c3-4584-b29f-bf493365bffb'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Christine Drazan · Reproductive Rights and Abortion Access
  ('402a00be-71c3-4584-b29f-bf493365bffb'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Christine Drazan · Taxation and Public Spending
  ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Bruce Starr · Public Safety Approach
  ('35d2729c-b754-4fad-b124-10ee437a116f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Alek Skarlatos · Climate Change and Environmental Protection
  ('f3fb09eb-adb0-4543-b6a2-32f90003569b'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Darin Harbick · Climate Change and Environmental Protection
  ('50eab431-7b51-4a56-acaa-61af3509c298'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Diane Linthicum · Taxation and Public Spending
  ('2a116530-8d06-41b5-b965-50d943eae8c2'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Sarah Finger McDonald · Civil Rights and Social Justice [404 source]
  ('2a116530-8d06-41b5-b965-50d943eae8c2'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Sarah Finger McDonald · Healthcare Access [404 source]
  ('86d23630-36ff-48a7-b2ac-6071a0cabd64'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Todd Nash · Taxation and Public Spending
  ('eab1011b-0cf3-4538-8842-292e7ab22291'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Darcey Edwards · Climate Change and Environmental Protection
  ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Dwayne Yunker · Climate Change and Environmental Protection
  ('ce386a55-7cc5-4006-89db-97e06e0e0279'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Matt Bunch · Climate Change and Environmental Protection
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Dan Rayfield · Civil Rights and Social Justice
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Dan Rayfield · Climate Change and Environmental Protection
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),  -- Dan Rayfield · Criminal Justice Approach
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Dan Rayfield · Criminalization of Homelessness
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid),  -- Dan Rayfield · Healthcare Access
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),  -- Dan Rayfield · Police Accountability
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Dan Rayfield · Reproductive Rights and Abortion Access
  ('15dbbf1b-da3d-4fb9-8fc5-67b734e7979e'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Dan Rayfield · Transgender Athletes
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Elizabeth Steiner · Criminalization of Homelessness
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Elizabeth Steiner · Reproductive Rights and Abortion Access
  ('c712d9cb-6a42-4fc6-b025-67cd5064605f'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Elizabeth Steiner · Transgender Athletes
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),  -- Maxine Dexter · Affordable Housing
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Maxine Dexter · Civil Rights and Social Justice
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Maxine Dexter · Climate Change and Environmental Protection
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Maxine Dexter · Reproductive Rights and Abortion Access
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Maxine Dexter · Taxation and Public Spending
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Maxine Dexter · Transgender Athletes
  ('13dcf1a8-c0bf-4e2f-92aa-46637182b42a'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),  -- Maxine Dexter · Transportation Priorities
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Christina Stephenson · Reproductive Rights and Abortion Access
  ('8548989d-ff40-4b25-bb42-e1a7cbb03c88'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid),  -- Christina Stephenson · Transgender Athletes
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),  -- Janelle Bynum · Affordable Housing
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Janelle Bynum · Civil Rights and Social Justice
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Janelle Bynum · Public Safety Approach
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Janelle Bynum · Reproductive Rights and Abortion Access
  ('7aad2a83-2f05-4570-aa7a-eb7a8c602ebd'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),  -- Janelle Bynum · Transportation Priorities
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid),  -- Tina Kotek · Campaign Finance Reform
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid),  -- Tina Kotek · Misinformation and the Role of Algorithms in Democracy
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Tina Kotek · Reproductive Rights and Abortion Access
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'ba59337e-30e2-4aba-a39a-426b3366eb27'::uuid),  -- Tina Kotek · Transportation Priorities
  ('66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid),  -- Tina Kotek · Voting Rights and Electoral Integrity
  ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd'::uuid, '7bad33eb-e93e-4d94-8822-97212d49bde5'::uuid),  -- Lew Frederick · Police Accountability
  ('1ca1abf1-9523-499c-b644-0b32c61257c6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Sara Gelser Blouin · Civil Rights and Social Justice
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid),  -- Andrea Salinas · Affordable Housing
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Andrea Salinas · Civil Rights and Social Justice
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Andrea Salinas · Criminalization of Homelessness
  ('24398310-8e0c-487e-a11c-253e3060f77c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid),  -- Julie Fahey · Criminalization of Homelessness
  ('24398310-8e0c-487e-a11c-253e3060f77c'::uuid, '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),  -- Julie Fahey · Immigration and Treatment of Immigrants
  ('94105ea6-e6f7-4629-b30c-a8fe713e1cad'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Tobias Read · Reproductive Rights and Abortion Access
  ('6b107b84-afbe-4141-8951-bafb65543dda'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Fred Girod · Public Safety Approach
  ('6b107b84-afbe-4141-8951-bafb65543dda'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Fred Girod · Taxation and Public Spending
  ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Kate Lieber · Civil Rights and Social Justice
  ('252a2adf-68a5-4b5a-9024-d5635e2fbd88'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Mike McLane · Public Safety Approach
  ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Cedric Hayden · Taxation and Public Spending
  ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Courtney Neron Misslin · Civil Rights and Social Justice
  ('b6f5cd9e-a9d2-44ff-9027-0d931765f378'::uuid, '9db07b16-1076-4b7d-ad89-ebe7b51f4336'::uuid),  -- Floyd Prozanski · Criminal Justice Approach
  ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Janeen Sollman · Civil Rights and Social Justice
  ('2edbb7a5-a798-4088-8939-7b44b51e682c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Kevin Mannix · Climate Change and Environmental Protection
  ('2edbb7a5-a798-4088-8939-7b44b51e682c'::uuid, 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid),  -- Kevin Mannix · Public Safety Approach
  ('36db8c55-4b20-408c-bd99-b8488d0ef344'::uuid, 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),  -- Mark Gamba · Fossil Fuel Policy
  ('22a1e980-4f15-435d-a0c4-1a08202d6bb5'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Chris Gorsek · Civil Rights and Social Justice
  ('0e3b9216-cfb9-411f-b80e-684ccaae593f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Court Boice · Climate Change and Environmental Protection
  ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Dick Anderson · Taxation and Public Spending
  ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Jeff Golden · Civil Rights and Social Justice
  ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Jeff Golden · Climate Change and Environmental Protection
  ('3778353d-cbc9-43cf-866a-a7c01397503a'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Kim Wallan · Climate Change and Environmental Protection
  ('be46ed6d-363e-46f4-89d4-c95d9af67db1'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Mark Meek · Civil Rights and Social Justice
  ('03af5908-a069-4ab7-91db-2f388a885bf9'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid),  -- Pam Marsh · Civil Rights and Social Justice
  ('d34df5c8-9534-4472-814d-971adff16f50'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid),  -- Suzanne Weber · Taxation and Public Spending
  ('0cd6ccff-e02d-4cbe-a1df-381226292840'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Anna Scharf · Climate Change and Environmental Protection
  ('05152597-fd40-49bb-bcd3-9e21945ae8b0'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Bobby Levy · Climate Change and Environmental Protection
  ('d5386673-4244-44ca-8e54-e1af61803f6e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Boomer Wright · Climate Change and Environmental Protection
  ('3c7c9b46-a054-41a7-8752-f0d8706f754d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- E. Werner Reschke · Climate Change and Environmental Protection
  ('ea9746ba-9fd2-4622-b781-b3ed35d18d17'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Ed Diehl · Climate Change and Environmental Protection
  ('9f9b60c1-483c-4a8e-8221-145098204ced'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Emily McIntire · Climate Change and Environmental Protection
  ('81cda574-d820-4ac3-b7fe-0ac3d2638c28'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Gregory Smith · Climate Change and Environmental Protection
  ('c854f51f-0ab0-4b46-9397-596501e3ee67'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Jami Cate · Climate Change and Environmental Protection
  ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Jeff Helfrich · Climate Change and Environmental Protection [404 source]
  ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Lucetta Elmer · Climate Change and Environmental Protection
  ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Mark Owens · Climate Change and Environmental Protection
  ('aa57168d-58b8-4f70-a937-09fdaf18b325'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Rick Lewis · Climate Change and Environmental Protection
  ('4919fd6a-c250-47b2-a37d-37b1eec8c63d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Shelly Boshart Davis · Climate Change and Environmental Protection
  ('7f460988-c9a6-4452-a872-441e7c4ac071'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),  -- Vikki Breese-Iverson · Climate Change and Environmental Protection
  ('558e9c8c-5e52-4685-9e24-1367810f8030'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid);  -- Virgle Osborne · Climate Change and Environmental Protection

-- Politicians left with no answers at all, computed BEFORE the delete so the count is honest.
CREATE TEMP TABLE _emptied_1507 ON COMMIT DROP AS
SELECT a.politician_id FROM inform.politician_answers a
 GROUP BY a.politician_id
HAVING count(*) = count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM _retire_1507 r
          WHERE r.politician_id = a.politician_id AND r.topic_id = a.topic_id));

DELETE FROM inform.politician_context c USING _retire_1507 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1507 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- A timestamp with zero answers would assert research that no longer exists.
UPDATE essentials.politicians p SET last_stances_researched_at = NULL
  FROM _emptied_1507 e
 WHERE p.id = e.politician_id AND p.last_stances_researched_at IS NOT NULL;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1507 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left;
  END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1507 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN
    RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx;
  END IF;
END $$;

COMMIT;
