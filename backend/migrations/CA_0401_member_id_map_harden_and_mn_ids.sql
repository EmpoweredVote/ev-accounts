-- CA_0401_member_id_map_harden_and_mn_ids.sql
-- Give each sitting Minnesota legislator their own member ids, and make the id map safe to trust.
--
-- Created 2026-11-19 with Chris Andrews. Steward slot CA_0401. Approved 2026-11-19 ("Yes, build MN") after the
-- survey and design in side-session notes legislator-member-ids-survey-and-design.md.
--
-- WHY. The research verifier matches a Minnesota bill author by name. A family name on COMMON_LAST_NAMES (Lee,
-- Johnson, Anderson) needs a title the Revisor never prints, so 15 true sponsorships in gun-policy mn-01 failed.
-- The stopgap (#1549) follows each author link to the LRL record and compares names exactly. With the LRL id
-- stored on the person, the verifier compares ids instead, and a namesake (former Sen. Paul T. Anderson vs
-- Rep. Paul H. Anderson) can never be accepted by name.
--
-- WHAT THIS CHANGES on essentials.legislative_politician_id_map (4,306 rows before):
--   id_type, id_value       NOT NULL (0 nulls on 2026-11-19)
--   politician_id           FOREIGN KEY -> essentials.politicians(id) (0 orphans). A merge must move these rows;
--                           dedup-essentials-politicians.ts now does, and the merge migrations already did.
--   (id_type, id_value)     UNIQUE: one id names one person (0 collisions). A person may still hold two ids of one
--                           type: 6 California legislators hold two LegiScan ids each.
--   id_type                 CHECK: legiscan, bioguide, openstates, onboard, legistar, mn-lrl, mn-senate-mem.
--   match_method            NEW, NOT NULL, default 'name'. seat | id_crosswalk | name | manual.
--                           Backfill: 'legiscan-session-people' (matched by Vote Smart / OpenSecrets ids, CA_0359)
--                           -> id_crosswalk. Every other existing row stays 'name': the LegiScan state importer
--                           matches by name, and no other writer records how it matched.
-- Then 467 Minnesota rows, built by scripts/member-ids/mn-member-ids.ts (read 2026-11-20 UTC):
--   mn-lrl         200  LRL legislator id, matched on chamber + district to lrl.mn.gov/legdb/current (seat).
--                       Cross-checks: family name agrees on all 200; the House photo URL's profile number equals
--                       the LRL id on all 133 House members.
--   mn-senate-mem   67  the Senate's own mem_id from senate.mn/api/members, matched on district (seat); family
--                       name agrees; equals the mem_id in the Senate photo URL wherever one is stored.
--   openstates     200  Open States person id, by id (id_crosswalk): the Open States record's link carries the same
--                       LRL id (House) or mem_id (Senate), and its district equals the seat.
--
-- Overwrites no stored value (match_method is new; every other change adds a rule or a row).
--
-- LOCKS. ALTER TABLE takes a brief ACCESS EXCLUSIVE lock on a 4k-row table; lock_timeout 3s fails fast.
--
-- ROLLBACK:
--   delete from essentials.legislative_politician_id_map where id_type in ('mn-lrl','mn-senate-mem')
--     or (id_type = 'openstates' and source like 'https://data.openstates.org/people/current/mn.csv%');
--   alter table essentials.legislative_politician_id_map
--     drop constraint leg_id_map_politician_fk, drop constraint leg_id_map_id_type_chk,
--     drop constraint leg_id_map_match_method_chk, drop column match_method,
--     alter column id_type drop not null, alter column id_value drop not null;
--   drop index essentials.uq_leg_id_map_type_value;
--
-- STATUS: APPLIED to prod 2026-11-19 via apply-migration-file.mjs (operator approval: Chris Andrews, "Yes, apply it");
--   21 rows updated, 467 inserted, every guard passed. Before that: dry run OK twice; a tamper (LRL 15301 moved off
--   Paul Anderson) was stopped by the post-guard. After: 200 mn-lrl / 67 mn-senate-mem (seat), 200 openstates
--   (id_crosswalk); the FK, both CHECKs and uq_leg_id_map_type_value exist; mn-member-ids.ts re-run finds 0 new rows;
--   loadMemberIds returns { 'mn-lrl': ['15301'] } for Paul Anderson.

BEGIN;
set local lock_timeout = '3s';

-- Pre-guards: the rules below must hold for the rows already there.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map WHERE id_type IS NULL OR id_value IS NULL) THEN
    RAISE EXCEPTION 'CA_0401: null id_type or id_value present';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map m
              WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = m.politician_id)) THEN
    RAISE EXCEPTION 'CA_0401: orphan rows present';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map GROUP BY id_type, id_value
              HAVING count(DISTINCT politician_id) > 1) THEN
    RAISE EXCEPTION 'CA_0401: an id is held by two people';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map WHERE id_type IN ('mn-lrl', 'mn-senate-mem')) THEN
    RAISE EXCEPTION 'CA_0401: Minnesota member ids already present (already applied?)';
  END IF;
END $$;

ALTER TABLE essentials.legislative_politician_id_map
  ALTER COLUMN id_type SET NOT NULL,
  ALTER COLUMN id_value SET NOT NULL,
  ADD COLUMN match_method text NOT NULL DEFAULT 'name',
  ADD CONSTRAINT leg_id_map_match_method_chk CHECK (match_method IN ('seat', 'id_crosswalk', 'name', 'manual')),
  ADD CONSTRAINT leg_id_map_id_type_chk CHECK (id_type IN
    ('legiscan', 'bioguide', 'openstates', 'onboard', 'legistar', 'mn-lrl', 'mn-senate-mem')),
  ADD CONSTRAINT leg_id_map_politician_fk FOREIGN KEY (politician_id) REFERENCES essentials.politicians(id);

CREATE UNIQUE INDEX uq_leg_id_map_type_value ON essentials.legislative_politician_id_map (id_type, id_value);

COMMENT ON COLUMN essentials.legislative_politician_id_map.match_method IS
  'How the row was made: seat (issuer''s current-member list, chamber + district), id_crosswalk (another trusted id), '
  'name (a name match; not proof of identity), manual. Research tools that must not trust names skip ''name''.';

UPDATE essentials.legislative_politician_id_map SET match_method = 'id_crosswalk'
 WHERE source = 'legiscan-session-people';

INSERT INTO essentials.legislative_politician_id_map (politician_id, id_type, id_value, match_method, source, verified_at)
SELECT v.pid, v.t, v.val, v.m, v.src, now() FROM (VALUES
  -- Jim Abeler
  ('6162018b-568b-4739-8130-cde253fbb31b'::uuid, 'mn-lrl', '10002', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Gregory Davids
  ('89f1c6e1-4cb6-4aa4-99d7-2260729fee28'::uuid, 'mn-lrl', '10123', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- D. Scott Dibble
  ('22d35adf-72f2-4b26-b151-579f53c8f2c8'::uuid, 'mn-lrl', '10142', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Warren Limmer
  ('7f870a88-85e4-4021-969b-c417709f01f0'::uuid, 'mn-lrl', '10376', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- John Marty
  ('2744a53f-1558-41c3-8c3c-c6e71c70b682'::uuid, 'mn-lrl', '10403', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Sandra Pappas
  ('df44f106-1cb2-4c27-b792-af147ae3aa4d'::uuid, 'mn-lrl', '10503', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ann Rest
  ('3295d8e3-953f-4312-b660-a08b5ba8d862'::uuid, 'mn-lrl', '10558', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Torrey Westrom
  ('545069b3-7f84-4480-a36b-761f5c6cc415'::uuid, 'mn-lrl', '10709', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ronald Latz
  ('1ab9c3b6-63b4-4afe-bd4a-aa1f7b057646'::uuid, 'mn-lrl', '10772', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Carla Nelson
  ('15788263-ad8f-4233-ac48-c9de61d2b55e'::uuid, 'mn-lrl', '10778', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Tina Liebling
  ('73b22a9e-e9f8-4419-8f64-7c0ed9806da3'::uuid, 'mn-lrl', '12268', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Leon Lillie
  ('31699ccd-426b-4708-9a1d-bdaced1a56dc'::uuid, 'mn-lrl', '12269', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Rick Hansen
  ('007efefd-7680-44b7-9f07-813340f52366'::uuid, 'mn-lrl', '12282', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jim Carlson
  ('bfde1ba1-0aab-416e-884d-708bb14ee500'::uuid, 'mn-lrl', '15245', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Erin Murphy
  ('f9f2c3e6-ae73-4844-91c2-c472d74c3aa9'::uuid, 'mn-lrl', '15284', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steve Drazkowski
  ('b697907e-c2ac-40d5-805d-c6a06d88943b'::uuid, 'mn-lrl', '15286', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Paul Anderson
  ('8d46d88e-ad1e-4a88-81c2-782da83d77f1'::uuid, 'mn-lrl', '15301', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Paul Torkelson
  ('df16a6e7-95e5-4c40-b81e-690dfc7d3aeb'::uuid, 'mn-lrl', '15304', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Peggy Scott
  ('15843ab1-33c5-480d-b4b4-c98935e9d880'::uuid, 'mn-lrl', '15314', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bobby Joe Champion
  ('24e523eb-c8b0-4b30-915b-6982c1d1a3cb'::uuid, 'mn-lrl', '15317', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Gary Dahms
  ('47534fbb-c532-4d3d-8e03-46695ca83f01'::uuid, 'mn-lrl', '15326', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jeremy Miller
  ('d78d2570-7fca-4a5d-86c1-5f0996e3fdd4'::uuid, 'mn-lrl', '15335', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mary Franson
  ('b96b430e-5ba7-42cc-825f-38e2dbceb466'::uuid, 'mn-lrl', '15347', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Glenn Gruenhagen
  ('9c835ab1-0d18-463f-a6ad-5991e1281523'::uuid, 'mn-lrl', '15350', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Joe McDonald
  ('50ce958b-8215-41c2-afa0-cb993d31d2fd'::uuid, 'mn-lrl', '15360', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Tim O'Driscoll
  ('a146f476-d15d-40e5-948a-40724c920ca4'::uuid, 'mn-lrl', '15364', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Duane Quam
  ('8f781313-476b-48a0-b80c-c57a683b7db8'::uuid, 'mn-lrl', '15366', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Chris Swedzinski
  ('394260b2-ddfe-4c6d-91dc-544d7fef9fe8'::uuid, 'mn-lrl', '15369', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Foung Hawj
  ('3e6dbcc6-a36c-46a5-a045-c55e294aa3f1'::uuid, 'mn-lrl', '15380', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- John Hoffman
  ('66a77b36-2947-47c1-8801-13a4f2f6e078'::uuid, 'mn-lrl', '15381', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Karin Housley
  ('302feb80-0c30-4b42-b107-dae60b15fb4f'::uuid, 'mn-lrl', '15382', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Eric Pratt
  ('fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid, 'mn-lrl', '15386', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bill Weber
  ('476f550b-5c67-4d65-b7d6-d834360503d7'::uuid, 'mn-lrl', '15388', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Melissa Wiklund
  ('9e2e19df-eca0-4b74-8d0b-6ef205f5431c'::uuid, 'mn-lrl', '15389', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steve Green
  ('4aba3726-4227-4e5b-8498-8a05ff6119b0'::uuid, 'mn-lrl', '15395', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Peter Fischer
  ('e6333290-8189-415a-af13-7cfc594ca86b'::uuid, 'mn-lrl', '15396', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mike Freiberg
  ('ace1dba6-9927-4224-9e45-6aef5b6b75d6'::uuid, 'mn-lrl', '15398', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jeff Howe
  ('f3440eb0-e3cc-4968-8ef5-2b670d88aadc'::uuid, 'mn-lrl', '15401', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ron Kresha
  ('edc6c327-bd08-4993-af0b-98397d232e6d'::uuid, 'mn-lrl', '15404', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Marion Rarick
  ('aecee77e-b104-43a1-a907-fc44287dfd06'::uuid, 'mn-lrl', '15409', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jeff Backer
  ('7beab3d6-e4f9-401d-9859-de2ced5089f2'::uuid, 'mn-lrl', '15428', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Dave Baker
  ('70ad1a5d-f216-415e-a307-f31c83785abb'::uuid, 'mn-lrl', '15429', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Peggy Bennett
  ('e86085c5-e044-49f1-a862-01d35da5f7f9'::uuid, 'mn-lrl', '15430', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Joshua Heintzeman
  ('0bfc2626-fbf0-44cc-bd0d-ffcd10b12d44'::uuid, 'mn-lrl', '15435', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jon Koznick
  ('ad0a254b-0082-41da-8eef-3567066d2bbf'::uuid, 'mn-lrl', '15436', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Eric Lucero
  ('830820d7-c5a5-4dec-ba83-f8a785a2fb41'::uuid, 'mn-lrl', '15438', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jim Nash
  ('c9ea7750-8bd5-4db0-8ea9-40076eec7646'::uuid, 'mn-lrl', '15441', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Dave Pinto
  ('8ae767e1-a3bc-406d-a191-5fb5133ec190'::uuid, 'mn-lrl', '15444', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jason Rarick
  ('e9e8dab5-3add-4eb0-874f-7c7652fad785'::uuid, 'mn-lrl', '15445', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Cheryl Youakim
  ('7d365578-3cfd-444b-80fa-bd6927b3b72c'::uuid, 'mn-lrl', '15450', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Calvin Bahr
  ('aa1104a3-2bf0-4fa5-81e4-00b3c95f649f'::uuid, 'mn-lrl', '15455', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Matt Bliss
  ('fb704747-1d31-4a6d-9ce5-c1f7185fb018'::uuid, 'mn-lrl', '15458', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Erin Koegel
  ('3b0dc78e-e73a-47e7-b45a-73b880a1ab7c'::uuid, 'mn-lrl', '15465', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mary Kunesh
  ('bb07b87a-b92b-426d-af32-9d505ff3bb7a'::uuid, 'mn-lrl', '15466', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Fue Lee
  ('556de586-e176-4e68-90de-1eabb24a5b4d'::uuid, 'mn-lrl', '15468', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Erin Maye Quade
  ('a9f089f1-c5a5-4cf6-908b-b9898a078fe7'::uuid, 'mn-lrl', '15473', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Nolan West
  ('c9c55e16-d9fa-4c5a-b95e-b0e53cada2a5'::uuid, 'mn-lrl', '15476', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steve Cwodzinski
  ('7845f8df-cc58-49fa-a87c-6483d6cdcf47'::uuid, 'mn-lrl', '15478', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Rich Draheim
  ('a41019c1-8548-4465-bbd6-f23688ed38dd'::uuid, 'mn-lrl', '15479', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Nick Frentz
  ('c2d7c018-141c-4c34-a605-e8b1f53acdee'::uuid, 'mn-lrl', '15481', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- John Jasinski
  ('959d8534-6a9a-41e7-af1c-b3d9e2e0499c'::uuid, 'mn-lrl', '15483', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mark Johnson
  ('521f60ba-6749-4022-b9dc-1474fa63c890'::uuid, 'mn-lrl', '15485', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Matt Klein
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a'::uuid, 'mn-lrl', '15486', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mark Koran
  ('7f7ac8a6-a126-4eb6-bf68-b10aa124de60'::uuid, 'mn-lrl', '15487', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Andrew Lang
  ('98eef5a7-e6f2-48da-a2c7-288fa694476f'::uuid, 'mn-lrl', '15489', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Andrew Mathews
  ('99080178-3c14-40f0-be57-c922f870bef9'::uuid, 'mn-lrl', '15491', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Paul Utke
  ('63a54046-caa9-4a19-a824-590c9305de0d'::uuid, 'mn-lrl', '15493', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Lisa Demuth
  ('e49ed577-d00e-402f-bf80-5546baae414f'::uuid, 'mn-lrl', '15498', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Dan Wolgamott
  ('bef03b5f-8da7-46b6-b609-433ffb993f10'::uuid, 'mn-lrl', '15499', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Shane Mekeland
  ('463cdab3-b3bd-4aa9-b834-bf573f4f34bf'::uuid, 'mn-lrl', '15500', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kristin Robbins
  ('0a48874e-3d5a-4160-9481-a67cb23cfafc'::uuid, 'mn-lrl', '15504', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kristin Bahner
  ('4269e293-60c0-4348-adca-7a2dbc98dd18'::uuid, 'mn-lrl', '15505', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Zack Stephenson
  ('a04547cf-8928-4638-9fe4-bef286cfba0f'::uuid, 'mn-lrl', '15507', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Samantha Vang
  ('ba34c6bc-b9cf-4097-aa83-fdc191a3622c'::uuid, 'mn-lrl', '15510', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kelly Moller
  ('ac902e73-18b8-48dd-9409-657e8bb85af0'::uuid, 'mn-lrl', '15511', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ginny Klevorn
  ('34b532b9-de36-4647-82f1-6bc17ed0d627'::uuid, 'mn-lrl', '15512', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Patty Acomb
  ('f1f2ffaf-c9fb-4555-adf8-6c9c8114d9f3'::uuid, 'mn-lrl', '15513', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Carlie Kotyza-Witthuhn
  ('e3311ba8-aeed-497c-b61c-4487f7a22383'::uuid, 'mn-lrl', '15515', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steve Elkins
  ('7c525707-de26-453c-9d7b-166ab5dcf9e5'::uuid, 'mn-lrl', '15517', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Michael Howard
  ('e6082f4d-56fd-4fc7-b29a-2da8ad703979'::uuid, 'mn-lrl', '15518', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Tou Xiong
  ('c5aac466-971e-4b44-ac6e-91c4cbfa39d7'::uuid, 'mn-lrl', '15520', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Brad Tabke
  ('cdcc38fe-555e-456f-9511-85f4cf7283e3'::uuid, 'mn-lrl', '15523', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Alice Mann
  ('6fb577f3-ac0b-4faa-9685-d4a0485e4860'::uuid, 'mn-lrl', '15525', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Robert Bierman
  ('32422c01-9158-4264-b2b9-b021e3438cce'::uuid, 'mn-lrl', '15526', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- John Huot
  ('ff1fbc23-7d83-4b4e-93ca-22a58b60e481'::uuid, 'mn-lrl', '15527', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mohamud Noor
  ('afd02cc7-9c13-4345-b3b4-7a507c062414'::uuid, 'mn-lrl', '15528', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jamie Long
  ('9e9ae384-03ef-4f76-831b-3ccc266509a4'::uuid, 'mn-lrl', '15529', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Aisha Gomez
  ('81033847-4e48-4080-a0c5-8daf154a4761'::uuid, 'mn-lrl', '15531', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jay Xiong
  ('36ac7eb0-5bb1-4fa6-b0e9-bc984a73fdb8'::uuid, 'mn-lrl', '15533', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Nathan Nelson
  ('bd04bd63-5a7b-44ba-a34f-a293b51de5b9'::uuid, 'mn-lrl', '15534', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Sydney Jordan
  ('1b23f52f-50da-48bf-877b-e1182a1e7679'::uuid, 'mn-lrl', '15535', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Paul Novotny
  ('fbbc53e2-d3c8-4fbc-9df5-28cec3be9f41'::uuid, 'mn-lrl', '15536', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jennifer McEwen
  ('a3656b66-f796-4b26-a29e-2b9d7c1c064e'::uuid, 'mn-lrl', '15537', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- John Burkel
  ('d6ec0d2d-21d1-4eda-933c-c7eb593389dc'::uuid, 'mn-lrl', '15538', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Heather Keeler
  ('4d08487a-cfb1-47d9-b61a-8fb20968b662'::uuid, 'mn-lrl', '15539', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Spencer Igo
  ('144b7c0e-354b-4d1f-be2f-73b04e8a0072'::uuid, 'mn-lrl', '15540', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jordan Rasmusson
  ('906a4784-59a9-4882-8a2e-a390f3032b72'::uuid, 'mn-lrl', '15541', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Luke Frederick
  ('58f8cad2-0a73-43ac-83d6-fcc21a047b51'::uuid, 'mn-lrl', '15542', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bjorn Olson
  ('65c57cac-84ad-4ac1-9b4b-db5db92f1dfc'::uuid, 'mn-lrl', '15544', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Liz Boldon
  ('738daece-ad27-449f-8fad-8d614e296f63'::uuid, 'mn-lrl', '15545', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Sandra Feist
  ('641bf895-0822-4ed2-9423-24b1a3fada2a'::uuid, 'mn-lrl', '15547', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Cedrick Frazier
  ('7f7c4959-18a0-4dd3-901e-8d59aece0337'::uuid, 'mn-lrl', '15548', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Liz Reyer
  ('6af8f82e-dbee-4ad2-b3ff-7b9e694b849c'::uuid, 'mn-lrl', '15549', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kaela Berg
  ('a89ba4b9-a684-40a6-b5ec-db0876a65b8d'::uuid, 'mn-lrl', '15550', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Esther Agbaje
  ('285c226e-a195-4d7e-993b-d54b6712e65b'::uuid, 'mn-lrl', '15551', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Emma Greenman
  ('a9303183-ae2a-4c1b-9777-587bb356f488'::uuid, 'mn-lrl', '15552', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Athena Hollins
  ('27d3b46b-befc-4169-9bf0-f87e09d47d8b'::uuid, 'mn-lrl', '15553', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ann Johnson Stewart
  ('56c6c6c9-2bf8-4841-aa25-9244586e88eb'::uuid, 'mn-lrl', '15555', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Julia Coleman
  ('b1f2628a-6264-4849-a14f-0f708fef5394'::uuid, 'mn-lrl', '15556', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Lindsey Port
  ('08a8570b-9a9a-4cf7-bfd2-2d55a24136cb'::uuid, 'mn-lrl', '15557', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Zach Duckworth
  ('099c5cb6-2221-4228-a3a8-0f5955d89112'::uuid, 'mn-lrl', '15558', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Omar Fateh
  ('777c5284-663b-40b3-a86c-a557c8653339'::uuid, 'mn-lrl', '15559', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Gene Dornink
  ('e62ff25c-2d0a-4fc3-b235-ff33eacf43d4'::uuid, 'mn-lrl', '15560', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Patricia Mueller
  ('c93d7f91-5e6d-4e41-a0ac-303c019c4b99'::uuid, 'mn-lrl', '15561', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jessica Hanson
  ('79ee7fa2-44fb-4681-a7ed-450e74388425'::uuid, 'mn-lrl', '15563', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Aric Putnam
  ('842fbe6e-2018-4250-b024-5ce57aa278b7'::uuid, 'mn-lrl', '15564', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Nathan Coulter
  ('3386966b-b6fe-4ffb-8796-e755be9b44ab'::uuid, 'mn-lrl', '15567', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mary Frances Clardy
  ('7c84dfd1-eb0b-47fa-9fd4-373591ce662d'::uuid, 'mn-lrl', '15568', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ben Bakeberg
  ('562d1707-a74e-4ede-b8c7-8deaf9a90c0c'::uuid, 'mn-lrl', '15569', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jeff Witte
  ('78a28a3b-98d0-46a6-bdf2-1d8b961fa6ed'::uuid, 'mn-lrl', '15570', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kristi Pursell
  ('56a81dd0-5e0e-446f-8835-65d643520b72'::uuid, 'mn-lrl', '15571', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Samantha Sencer-Mura
  ('05c8fc85-08b2-4f30-a6a3-65169ca9675d'::uuid, 'mn-lrl', '15572', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Samakab Hussein
  ('940b9e75-ae5d-458e-a888-6d7096e7df54'::uuid, 'mn-lrl', '15573', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- María Isa Pérez-Vega
  ('2b1b89f8-5692-4acf-b437-e8f1ae677b13'::uuid, 'mn-lrl', '15574', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Leigh Finke
  ('1c30fb24-6bda-46ca-94fe-df0579d7ca4d'::uuid, 'mn-lrl', '15575', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Liz Lee
  ('d5e54444-041b-4eeb-8043-b691d3a3edfb'::uuid, 'mn-lrl', '15576', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Grant Hauschild
  ('acbe5b83-4bc5-49c0-8f9a-40716b912d3a'::uuid, 'mn-lrl', '15577', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Robert Kupec
  ('a855b6e4-1ce3-44f1-ade3-de2bf2b95c9c'::uuid, 'mn-lrl', '15578', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Robert Farnsworth
  ('a571aa51-078a-4fd7-b54a-360249d443ac'::uuid, 'mn-lrl', '15579', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Nathan Wesenberg
  ('a3618859-16e1-4bd8-9fc8-cbad342443b4'::uuid, 'mn-lrl', '15580', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Michael Kreun
  ('f05556a2-a3e8-4f98-9b62-9d169dec312d'::uuid, 'mn-lrl', '15581', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Heather Gustafson
  ('4ea59d05-8372-4646-8780-3b388b9bc98a'::uuid, 'mn-lrl', '15582', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Susan Pha
  ('feb4315d-60f4-49c5-a57b-0a65432a2868'::uuid, 'mn-lrl', '15583', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Judy Seeberger
  ('c35bd7ef-eafe-47be-b21b-928f579fbf73'::uuid, 'mn-lrl', '15584', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bonnie Westlin
  ('51a9e676-8adb-4682-b121-aed21a58e66f'::uuid, 'mn-lrl', '15585', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bill Lieske
  ('bbdde0a7-f79e-4b77-8e96-92d77beb603b'::uuid, 'mn-lrl', '15587', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Zaynab Mohamed
  ('8ace4090-cdf6-4a6f-bcee-7aac68c51890'::uuid, 'mn-lrl', '15588', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Clare Oumou Verbeten
  ('f5763e3f-da57-4213-a7b9-1f07267ab35b'::uuid, 'mn-lrl', '15589', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jim Joy
  ('ae296dbc-36aa-444f-89e3-1b1c6b734447'::uuid, 'mn-lrl', '15591', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Krista Knudsen
  ('d0ed90a5-39e0-479b-b450-b57edda4e539'::uuid, 'mn-lrl', '15592', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Mike Wiener
  ('eb65cea1-51ae-487f-840f-b70b2c1126f9'::uuid, 'mn-lrl', '15593', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ben Davis
  ('32a1f6b7-ced6-4417-8074-cb37faca7659'::uuid, 'mn-lrl', '15594', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Liish Kozlowski
  ('b6759469-327d-46fe-9064-0c1ec40bec63'::uuid, 'mn-lrl', '15595', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Tom Murphy
  ('ca967473-dabb-4bfa-9019-63cc6b1bd2e5'::uuid, 'mn-lrl', '15596', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Isaac Schultz
  ('a6159eb9-ec8c-42a4-951a-b27e41a936bd'::uuid, 'mn-lrl', '15597', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Jeff Dotseth
  ('28b95309-d367-4c50-988b-38c851950cbc'::uuid, 'mn-lrl', '15598', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bernie Perryman
  ('d12d13ea-dbb8-4871-b35e-f37e2385db9a'::uuid, 'mn-lrl', '15599', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Dawn Gillman
  ('96bbf0ae-f4b0-4a93-836a-c1ae576de868'::uuid, 'mn-lrl', '15600', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bobbie Harder
  ('8d5c67e1-1443-477c-bfbf-317dbababa2f'::uuid, 'mn-lrl', '15601', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Pam Altendorf
  ('7a84bd40-30d3-4a27-9d54-b8262783f1da'::uuid, 'mn-lrl', '15602', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steven Jacob
  ('c1baaa36-8965-4775-a453-d3e39089aa16'::uuid, 'mn-lrl', '15603', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Marj Fogelman
  ('338af9c7-7d7f-4450-830f-1a098a8cb080'::uuid, 'mn-lrl', '15604', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kimberly Hicks
  ('c63adb8a-5321-4ef1-be53-c915f81308aa'::uuid, 'mn-lrl', '15605', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Andrew Smith
  ('3757d377-1cc0-45f0-8b6f-e1f988c6fea2'::uuid, 'mn-lrl', '15606', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Walter Hudson
  ('37a6b346-470d-4f30-843f-7b5e9a20edaa'::uuid, 'mn-lrl', '15607', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Harry Niska
  ('a653e944-5dbf-4a40-bf03-02868ee902e7'::uuid, 'mn-lrl', '15608', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Matt Norris
  ('e19f88ea-5ebe-4333-810e-d8d5d9ccaf9a'::uuid, 'mn-lrl', '15609', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Patricia Anderson
  ('3da2f389-a20f-4b21-a20c-dbe6880f074b'::uuid, 'mn-lrl', '15610', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Josiah Hill
  ('393a864c-e1a1-4940-810c-e26322c5679e'::uuid, 'mn-lrl', '15611', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Danny Nadeau
  ('4d2fbac3-d8d9-4bb4-96a9-bbaf0b864206'::uuid, 'mn-lrl', '15612', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Elliott Engen
  ('171be6a9-0b10-4156-a2ce-e92da70f3b7f'::uuid, 'mn-lrl', '15613', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Brion Curran
  ('131b330a-cbc2-477e-a94b-3eeec70418a5'::uuid, 'mn-lrl', '15614', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ned Carroll
  ('4f779833-0eb9-4b14-b2a9-1e541f548849'::uuid, 'mn-lrl', '15617', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Andrew Myers
  ('4a810646-c2f7-4702-a2ed-263fc3d0f4ed'::uuid, 'mn-lrl', '15618', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Larry Kraft
  ('461ec505-bdae-4b92-af7d-7d2cabf65b20'::uuid, 'mn-lrl', '15619', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Amanda Hemmingsen-Jaeger
  ('bd87858e-f045-4b4d-aa3c-cbcfe3613066'::uuid, 'mn-lrl', '15620', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Ethan Cha
  ('376e49a2-a73e-4748-b7c4-9195cbfa2ec5'::uuid, 'mn-lrl', '15621', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Lucille Rehm
  ('f409650c-fed4-467a-9ecd-000de3c99487'::uuid, 'mn-lrl', '15622', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Roger Skraba
  ('63dd49ad-2466-4256-a71c-ad2477dfbe6d'::uuid, 'mn-lrl', '15623', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Natalie Zeleznikar
  ('95a65bb4-a540-4f52-8104-11a5bd7abb68'::uuid, 'mn-lrl', '15624', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bianca Virnig
  ('01a09876-9713-4c34-b4a4-03b57c8b1535'::uuid, 'mn-lrl', '15625', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bryan Lawrence
  ('2c007652-490b-4f11-9c16-e8b31de632bb'::uuid, 'mn-lrl', '15626', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Keith Allen
  ('a592683c-1ced-48a0-8a91-a2ad0a63aa39'::uuid, 'mn-lrl', '15627', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Tom Dippel
  ('fd5b1256-82d8-4553-86e5-eed68f85a2e4'::uuid, 'mn-lrl', '15628', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Bidal Duran
  ('b94e5477-4c6c-48d4-8232-60631494cc27'::uuid, 'mn-lrl', '15629', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Alexander Falconer
  ('71bbd8ad-1ea0-4755-8d14-81739e898a70'::uuid, 'mn-lrl', '15630', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Steve Gander
  ('688aed9e-1232-44c8-a321-d4e79e312789'::uuid, 'mn-lrl', '15631', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- James Gordon
  ('e0a3294a-692e-434d-b54b-c44b957b669d'::uuid, 'mn-lrl', '15632', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Julie Greene
  ('df29702a-88ca-45a4-b3b9-1a5eb4509ac7'::uuid, 'mn-lrl', '15633', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Huldah Momanyi-Hiltsley
  ('5c71d118-2442-4b4b-9504-7fb042541efb'::uuid, 'mn-lrl', '15634', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Peter Johnson
  ('51834ca0-6073-4d6c-863e-adf4264bdede'::uuid, 'mn-lrl', '15636', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Wayne Johnson
  ('512c4ad3-271c-4108-bad5-e59a724fbc2a'::uuid, 'mn-lrl', '15637', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Katie Jones
  ('14b8fcd1-1981-4bbf-b766-287c664133f5'::uuid, 'mn-lrl', '15638', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Anquam Mahamoud
  ('f1b6bd58-d35f-4fff-be59-6130af3e3bc7'::uuid, 'mn-lrl', '15639', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Kari Rehrauer
  ('9918a503-86e6-403c-9c9b-0f2cd5ee0408'::uuid, 'mn-lrl', '15640', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Aaron Repinski
  ('0318e417-787a-49d0-9bdf-1b8a27b00998'::uuid, 'mn-lrl', '15641', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Drew Roach
  ('9faaf97e-a076-4914-aefd-574e5cc48944'::uuid, 'mn-lrl', '15642', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Max Rymer
  ('b7093e4c-c73f-4acc-af87-274ff68c8431'::uuid, 'mn-lrl', '15643', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Erica Schwartz
  ('b4a9f522-73e5-4816-8206-973ebfb897c0'::uuid, 'mn-lrl', '15644', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Thomas Sexton
  ('c0e174a4-b9c8-42d7-9bd3-937f642ae1d3'::uuid, 'mn-lrl', '15645', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Terry Stier
  ('961a4084-a4a5-4a8e-ae85-3d647870689b'::uuid, 'mn-lrl', '15646', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Scott Van Binsbergen
  ('9b75b466-a210-4ac7-9997-da2a77b0b9b7'::uuid, 'mn-lrl', '15647', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Cal Warwas
  ('a40d131f-8e2e-4185-a52f-0d8cdfd03fe9'::uuid, 'mn-lrl', '15648', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Doron Clark
  ('3a7411c9-55d4-4eb6-bae0-5f5f6206c517'::uuid, 'mn-lrl', '15649', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- David Gottfried
  ('9ce10008-2f7b-42e0-b480-468bc4f1e182'::uuid, 'mn-lrl', '15650', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Keri Heintzeman
  ('fe0742ae-e32f-4900-ad95-0c7d3cc796ea'::uuid, 'mn-lrl', '15651', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Xp Lee
  ('82898b0f-ca2b-4b4e-8ca7-c60bbd2ea47f'::uuid, 'mn-lrl', '15652', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Michael Holmstrom
  ('927f1587-2180-4d0f-9238-2360dac34959'::uuid, 'mn-lrl', '15653', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Meg Luger-Nikolai
  ('4e973b77-a492-4033-8067-7c38ceefa22c'::uuid, 'mn-lrl', '15654', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- Shelley Buck
  ('8a0c78b2-fdf2-4906-8245-a3d8d303879e'::uuid, 'mn-lrl', '15655', 'seat', 'https://www.lrl.mn.gov/legdb/current (read 2026-11-20)'),
  -- D. Scott Dibble
  ('22d35adf-72f2-4b26-b151-579f53c8f2c8'::uuid, 'mn-senate-mem', '1010', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Warren Limmer
  ('7f870a88-85e4-4021-969b-c417709f01f0'::uuid, 'mn-senate-mem', '1032', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- John Marty
  ('2744a53f-1558-41c3-8c3c-c6e71c70b682'::uuid, 'mn-senate-mem', '1035', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Sandra L. Pappas
  ('df44f106-1cb2-4c27-b792-af147ae3aa4d'::uuid, 'mn-senate-mem', '1046', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Ann H. Rest
  ('3295d8e3-953f-4312-b660-a08b5ba8d862'::uuid, 'mn-senate-mem', '1051', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Ron Latz
  ('1ab9c3b6-63b4-4afe-bd4a-aa1f7b057646'::uuid, 'mn-senate-mem', '1102', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jim Carlson
  ('bfde1ba1-0aab-416e-884d-708bb14ee500'::uuid, 'mn-senate-mem', '1140', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Gary H. Dahms
  ('47534fbb-c532-4d3d-8e03-46695ca83f01'::uuid, 'mn-senate-mem', '1174', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Carla J. Nelson
  ('15788263-ad8f-4233-ac48-c9de61d2b55e'::uuid, 'mn-senate-mem', '1178', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jeremy R. Miller
  ('d78d2570-7fca-4a5d-86c1-5f0996e3fdd4'::uuid, 'mn-senate-mem', '1179', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Torrey N. Westrom
  ('545069b3-7f84-4480-a36b-761f5c6cc415'::uuid, 'mn-senate-mem', '1197', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Bill Weber
  ('476f550b-5c67-4d65-b7d6-d834360503d7'::uuid, 'mn-senate-mem', '1199', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- John A. Hoffman
  ('66a77b36-2947-47c1-8801-13a4f2f6e078'::uuid, 'mn-senate-mem', '1205', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Melissa H. Wiklund
  ('9e2e19df-eca0-4b74-8d0b-6ef205f5431c'::uuid, 'mn-senate-mem', '1209', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Eric R. Pratt
  ('fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid, 'mn-senate-mem', '1210', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Bobby Joe Champion
  ('24e523eb-c8b0-4b30-915b-6982c1d1a3cb'::uuid, 'mn-senate-mem', '1212', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Foung Hawj
  ('3e6dbcc6-a36c-46a5-a045-c55e294aa3f1'::uuid, 'mn-senate-mem', '1213', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Karin Housley
  ('302feb80-0c30-4b42-b107-dae60b15fb4f'::uuid, 'mn-senate-mem', '1214', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jim Abeler
  ('6162018b-568b-4739-8130-cde253fbb31b'::uuid, 'mn-senate-mem', '1216', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Mark T. Johnson
  ('521f60ba-6749-4022-b9dc-1474fa63c890'::uuid, 'mn-senate-mem', '1217', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Paul J. Utke
  ('63a54046-caa9-4a19-a824-590c9305de0d'::uuid, 'mn-senate-mem', '1218', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Andrew Mathews
  ('99080178-3c14-40f0-be57-c922f870bef9'::uuid, 'mn-senate-mem', '1222', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Andrew R. Lang
  ('98eef5a7-e6f2-48da-a2c7-288fa694476f'::uuid, 'mn-senate-mem', '1223', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Nick A. Frentz
  ('c2d7c018-141c-4c34-a605-e8b1f53acdee'::uuid, 'mn-senate-mem', '1224', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Rich Draheim
  ('a41019c1-8548-4465-bbd6-f23688ed38dd'::uuid, 'mn-senate-mem', '1225', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- John R. Jasinski
  ('959d8534-6a9a-41e7-af1c-b3d9e2e0499c'::uuid, 'mn-senate-mem', '1227', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Mark W. Koran
  ('7f7ac8a6-a126-4eb6-bf68-b10aa124de60'::uuid, 'mn-senate-mem', '1228', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Steve A. Cwodzinski
  ('7845f8df-cc58-49fa-a87c-6483d6cdcf47'::uuid, 'mn-senate-mem', '1234', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Matt D. Klein
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a'::uuid, 'mn-senate-mem', '1235', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jeff R. Howe
  ('f3440eb0-e3cc-4968-8ef5-2b670d88aadc'::uuid, 'mn-senate-mem', '1239', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jason Rarick
  ('e9e8dab5-3add-4eb0-874f-7c7652fad785'::uuid, 'mn-senate-mem', '1240', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jennifer A. McEwen
  ('a3656b66-f796-4b26-a29e-2b9d7c1c064e'::uuid, 'mn-senate-mem', '1241', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Mary K. Kunesh
  ('bb07b87a-b92b-426d-af32-9d505ff3bb7a'::uuid, 'mn-senate-mem', '1242', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Ann M. Johnson Stewart
  ('56c6c6c9-2bf8-4841-aa25-9244586e88eb'::uuid, 'mn-senate-mem', '1243', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Julia E. Coleman
  ('b1f2628a-6264-4849-a14f-0f708fef5394'::uuid, 'mn-senate-mem', '1244', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Lindsey Port
  ('08a8570b-9a9a-4cf7-bfd2-2d55a24136cb'::uuid, 'mn-senate-mem', '1245', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Zach Duckworth
  ('099c5cb6-2221-4228-a3a8-0f5955d89112'::uuid, 'mn-senate-mem', '1246', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Omar Fateh
  ('777c5284-663b-40b3-a86c-a557c8653339'::uuid, 'mn-senate-mem', '1247', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Erin P. Murphy
  ('f9f2c3e6-ae73-4844-91c2-c472d74c3aa9'::uuid, 'mn-senate-mem', '1248', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Aric Putnam
  ('842fbe6e-2018-4250-b024-5ce57aa278b7'::uuid, 'mn-senate-mem', '1249', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Gene Dornink
  ('e62ff25c-2d0a-4fc3-b235-ff33eacf43d4'::uuid, 'mn-senate-mem', '1250', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Steve Green
  ('4aba3726-4227-4e5b-8498-8a05ff6119b0'::uuid, 'mn-senate-mem', '1251', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Grant Hauschild
  ('acbe5b83-4bc5-49c0-8f9a-40716b912d3a'::uuid, 'mn-senate-mem', '1252', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Robert J. Kupec
  ('a855b6e4-1ce3-44f1-ade3-de2bf2b95c9c'::uuid, 'mn-senate-mem', '1253', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Robert D. Farnsworth
  ('a571aa51-078a-4fd7-b54a-360249d443ac'::uuid, 'mn-senate-mem', '1254', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Jordan Rasmusson
  ('906a4784-59a9-4882-8a2e-a390f3032b72'::uuid, 'mn-senate-mem', '1255', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Nathan Wesenberg
  ('a3618859-16e1-4bd8-9fc8-cbad342443b4'::uuid, 'mn-senate-mem', '1256', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Glenn H. Gruenhagen
  ('9c835ab1-0d18-463f-a6ad-5991e1281523'::uuid, 'mn-senate-mem', '1257', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Steve Drazkowski
  ('b697907e-c2ac-40d5-805d-c6a06d88943b'::uuid, 'mn-senate-mem', '1258', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Liz Boldon
  ('738daece-ad27-449f-8fad-8d614e296f63'::uuid, 'mn-senate-mem', '1259', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Eric Lucero
  ('830820d7-c5a5-4dec-ba83-f8a785a2fb41'::uuid, 'mn-senate-mem', '1260', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Calvin K. Bahr
  ('aa1104a3-2bf0-4fa5-81e4-00b3c95f649f'::uuid, 'mn-senate-mem', '1261', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Michael E. Kreun
  ('f05556a2-a3e8-4f98-9b62-9d169dec312d'::uuid, 'mn-senate-mem', '1262', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Heather Gustafson
  ('4ea59d05-8372-4646-8780-3b388b9bc98a'::uuid, 'mn-senate-mem', '1263', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Susan Pha
  ('feb4315d-60f4-49c5-a57b-0a65432a2868'::uuid, 'mn-senate-mem', '1264', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Judy Seeberger
  ('c35bd7ef-eafe-47be-b21b-928f579fbf73'::uuid, 'mn-senate-mem', '1265', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Bonnie S. Westlin
  ('51a9e676-8adb-4682-b121-aed21a58e66f'::uuid, 'mn-senate-mem', '1266', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Tou Xiong
  ('c5aac466-971e-4b44-ac6e-91c4cbfa39d7'::uuid, 'mn-senate-mem', '1267', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Alice Mann
  ('6fb577f3-ac0b-4faa-9685-d4a0485e4860'::uuid, 'mn-senate-mem', '1270', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Erin K. Maye Quade
  ('a9f089f1-c5a5-4cf6-908b-b9898a078fe7'::uuid, 'mn-senate-mem', '1271', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Bill Lieske
  ('bbdde0a7-f79e-4b77-8e96-92d77beb603b'::uuid, 'mn-senate-mem', '1272', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Zaynab Mohamed
  ('8ace4090-cdf6-4a6f-bcee-7aac68c51890'::uuid, 'mn-senate-mem', '1273', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Clare Oumou Verbeten
  ('f5763e3f-da57-4213-a7b9-1f07267ab35b'::uuid, 'mn-senate-mem', '1274', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Doron Clark
  ('3a7411c9-55d4-4eb6-bae0-5f5f6206c517'::uuid, 'mn-senate-mem', '1275', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Keri Heintzeman
  ('fe0742ae-e32f-4900-ad95-0c7d3cc796ea'::uuid, 'mn-senate-mem', '1276', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Michael W. Holmstrom
  ('927f1587-2180-4d0f-9238-2360dac34959'::uuid, 'mn-senate-mem', '1277', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Amanda H. Hemmingsen-Jaeger
  ('bd87858e-f045-4b4d-aa3c-cbcfe3613066'::uuid, 'mn-senate-mem', '1278', 'seat', 'https://www.senate.mn/api/members (read 2026-11-20)'),
  -- Sandy Pappas
  ('df44f106-1cb2-4c27-b792-af147ae3aa4d'::uuid, 'openstates', 'ocd-person/0b83a916-567b-4d36-843f-17d8f5e13b8d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Shelley Buck
  ('8a0c78b2-fdf2-4906-8245-a3d8d303879e'::uuid, 'openstates', 'ocd-person/0b860ed2-515a-4212-81ab-cc27b5e16223', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Walter Hudson
  ('37a6b346-470d-4f30-843f-7b5e9a20edaa'::uuid, 'openstates', 'ocd-person/0b721953-c642-4b33-b203-5eb3f3da210b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Erin Koegel
  ('3b0dc78e-e73a-47e7-b45a-73b880a1ab7c'::uuid, 'openstates', 'ocd-person/0d6f7edf-eae0-441d-8089-84472ce1f36f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- David Gottfried
  ('9ce10008-2f7b-42e0-b480-468bc4f1e182'::uuid, 'openstates', 'ocd-person/0d187b4d-c15c-487e-9602-541bd7dd948a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Cal Warwas
  ('a40d131f-8e2e-4185-a52f-0d8cdfd03fe9'::uuid, 'openstates', 'ocd-person/0fcdf023-48a4-4f62-92d0-0be6715bf229', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Alex Falconer
  ('71bbd8ad-1ea0-4755-8d14-81739e898a70'::uuid, 'openstates', 'ocd-person/1a50d8e6-64c4-4c8f-87ee-dedde17c1c2c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mary Clardy
  ('7c84dfd1-eb0b-47fa-9fd4-373591ce662d'::uuid, 'openstates', 'ocd-person/1acddc90-d32a-4495-a769-27f8b57193b7', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Natalie Zeleznikar
  ('95a65bb4-a540-4f52-8104-11a5bd7abb68'::uuid, 'openstates', 'ocd-person/1b1055a8-959c-452c-a2a8-106a4ccef20d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mary Franson
  ('b96b430e-5ba7-42cc-825f-38e2dbceb466'::uuid, 'openstates', 'ocd-person/1b284763-8577-49ab-b641-f4f079196646', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Torrey Westrom
  ('545069b3-7f84-4480-a36b-761f5c6cc415'::uuid, 'openstates', 'ocd-person/1c19414e-994b-46d4-8971-432ed482ca39', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Samakab Hussein
  ('940b9e75-ae5d-458e-a888-6d7096e7df54'::uuid, 'openstates', 'ocd-person/1ff5f689-18c9-4d74-970f-c289f915dc6a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Doron Clark
  ('3a7411c9-55d4-4eb6-bae0-5f5f6206c517'::uuid, 'openstates', 'ocd-person/2c27d592-c50b-45ae-b62a-ff657c828a5c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ginny Klevorn
  ('34b532b9-de36-4647-82f1-6bc17ed0d627'::uuid, 'openstates', 'ocd-person/2cb0f6d7-006d-4f7a-a1a3-218eff6016aa', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Spencer Igo
  ('144b7c0e-354b-4d1f-be2f-73b04e8a0072'::uuid, 'openstates', 'ocd-person/2e342c55-f56d-4895-9dd2-ef1271f784c0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Michael Kreun
  ('f05556a2-a3e8-4f98-9b62-9d169dec312d'::uuid, 'openstates', 'ocd-person/3a76623e-d295-4c58-be60-fd37a285a39b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Heather Keeler
  ('4d08487a-cfb1-47d9-b61a-8fb20968b662'::uuid, 'openstates', 'ocd-person/3ace0851-830e-42a1-8390-27c1142f2367', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Jacob
  ('c1baaa36-8965-4775-a453-d3e39089aa16'::uuid, 'openstates', 'ocd-person/3c90edec-1bce-4197-8e1c-cc840102c7a9', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Paul Novotny
  ('fbbc53e2-d3c8-4fbc-9df5-28cec3be9f41'::uuid, 'openstates', 'ocd-person/3e0eb8aa-b66c-4b30-9a0e-f1326c6f0589', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Andrew Lang
  ('98eef5a7-e6f2-48da-a2c7-288fa694476f'::uuid, 'openstates', 'ocd-person/3e1cd4f3-2c37-4531-b2cb-ca875c82d773', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kelly Moller
  ('ac902e73-18b8-48dd-9409-657e8bb85af0'::uuid, 'openstates', 'ocd-person/3eb5eb9d-cd17-4a48-ac4c-4f7a7b8e133e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Samantha Vang
  ('ba34c6bc-b9cf-4097-aa83-fdc191a3622c'::uuid, 'openstates', 'ocd-person/3f73ba2f-f038-47ff-b721-27118592b691', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- John Marty
  ('2744a53f-1558-41c3-8c3c-c6e71c70b682'::uuid, 'openstates', 'ocd-person/4acf27d9-edd4-4f04-97c7-164390a5664b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Patti Anderson
  ('3da2f389-a20f-4b21-a20c-dbe6880f074b'::uuid, 'openstates', 'ocd-person/4bab18ef-55dc-44bf-adfe-8dbdf9488a09', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mike Wiener
  ('eb65cea1-51ae-487f-840f-b70b2c1126f9'::uuid, 'openstates', 'ocd-person/4c34f3d9-8890-4145-8a96-92ab23f046c0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jordan Rasmusson
  ('906a4784-59a9-4882-8a2e-a390f3032b72'::uuid, 'openstates', 'ocd-person/4c3116e2-98db-4367-b543-a12220c9b12f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Judy Seeberger
  ('c35bd7ef-eafe-47be-b21b-928f579fbf73'::uuid, 'openstates', 'ocd-person/4ca681ca-58ab-4d75-b7ef-8d255f858d62', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Keri Heintzeman
  ('fe0742ae-e32f-4900-ad95-0c7d3cc796ea'::uuid, 'openstates', 'ocd-person/4d922135-f178-4e50-8439-ebbf47cf025c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Scott Dibble
  ('22d35adf-72f2-4b26-b151-579f53c8f2c8'::uuid, 'openstates', 'ocd-person/4dc8ff31-159a-457a-9551-a897d222f87e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Omar Fateh
  ('777c5284-663b-40b3-a86c-a557c8653339'::uuid, 'openstates', 'ocd-person/04eeaa61-ee3c-4e36-88f2-b415660175eb', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Greg Davids
  ('89f1c6e1-4cb6-4aa4-99d7-2260729fee28'::uuid, 'openstates', 'ocd-person/5bf21441-27fe-4f78-8fc1-83ca3ee5700d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- John Huot
  ('ff1fbc23-7d83-4b4e-93ca-22a58b60e481'::uuid, 'openstates', 'ocd-person/5d8ac115-4a2b-4f0f-b70a-c1df26184891', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tou Xiong
  ('c5aac466-971e-4b44-ac6e-91c4cbfa39d7'::uuid, 'openstates', 'ocd-person/5d9e1da5-ecf9-45d9-b104-7d1238032aff', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tom Dippel
  ('fd5b1256-82d8-4553-86e5-eed68f85a2e4'::uuid, 'openstates', 'ocd-person/05de7bba-70ee-4848-b0ec-d67354b6073a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Brad Tabke
  ('cdcc38fe-555e-456f-9511-85f4cf7283e3'::uuid, 'openstates', 'ocd-person/05f634e6-f8d3-4983-9604-dfc8dddc574e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bill Lieske
  ('bbdde0a7-f79e-4b77-8e96-92d77beb603b'::uuid, 'openstates', 'ocd-person/05fb3c26-0704-49c8-8eb6-8c624b752434', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Grant Hauschild
  ('acbe5b83-4bc5-49c0-8f9a-40716b912d3a'::uuid, 'openstates', 'ocd-person/6a13cdd4-3646-4fe9-a2a3-5f1399c2c146', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Glenn Gruenhagen
  ('9c835ab1-0d18-463f-a6ad-5991e1281523'::uuid, 'openstates', 'ocd-person/7a52595e-fa21-4e21-88d6-b03e4d9f1f77', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Lisa Demuth
  ('e49ed577-d00e-402f-bf80-5546baae414f'::uuid, 'openstates', 'ocd-person/7b7b8d46-05d4-4285-b728-abcad1a430d5', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Nathan Wesenberg
  ('a3618859-16e1-4bd8-9fc8-cbad342443b4'::uuid, 'openstates', 'ocd-person/7eaf40ec-f926-4992-8962-65b90846ef80', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Drew Roach
  ('9faaf97e-a076-4914-aefd-574e5cc48944'::uuid, 'openstates', 'ocd-person/7eb10c5c-1b6e-4ee2-9dac-589e3db32f49', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bidal Duran
  ('b94e5477-4c6c-48d4-8232-60631494cc27'::uuid, 'openstates', 'ocd-person/8a84172a-6b96-4b28-a9ab-bf11625528a3', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jon Koznick
  ('ad0a254b-0082-41da-8eef-3567066d2bbf'::uuid, 'openstates', 'ocd-person/8c4ed90f-f243-43f1-b205-0edd374777d8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Anquam Mahamoud
  ('f1b6bd58-d35f-4fff-be59-6130af3e3bc7'::uuid, 'openstates', 'ocd-person/8c85da58-235b-4769-be5f-dcf5b7c66c75', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jen McEwen
  ('a3656b66-f796-4b26-a29e-2b9d7c1c064e'::uuid, 'openstates', 'ocd-person/8d0a69ec-1301-4df5-9676-86720555ea7c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Clare Oumou Verbeten
  ('f5763e3f-da57-4213-a7b9-1f07267ab35b'::uuid, 'openstates', 'ocd-person/9afffc3e-2fd8-404c-beeb-5bf3e17397ce', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Rob Farnsworth
  ('a571aa51-078a-4fd7-b54a-360249d443ac'::uuid, 'openstates', 'ocd-person/9cdb9977-9923-4124-ae93-c45e28f1f51c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Green
  ('4aba3726-4227-4e5b-8498-8a05ff6119b0'::uuid, 'openstates', 'ocd-person/9d8b9b67-e74b-4e7f-92d5-52e3c0907f1d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Terry Stier
  ('961a4084-a4a5-4a8e-ae85-3d647870689b'::uuid, 'openstates', 'ocd-person/9e7eca64-ff97-48f2-8887-916e50d917cd', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Athena Hollins
  ('27d3b46b-befc-4169-9bf0-f87e09d47d8b'::uuid, 'openstates', 'ocd-person/9f56bc31-f522-4e29-af62-cdc616babc88', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tim O'Driscoll
  ('a146f476-d15d-40e5-948a-40724c920ca4'::uuid, 'openstates', 'ocd-person/015d0cf4-9742-4050-8084-a62be4107f2e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Julie Greene
  ('df29702a-88ca-45a4-b3b9-1a5eb4509ac7'::uuid, 'openstates', 'ocd-person/15f0a29b-674a-4146-8a93-019c9a3f305e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Peggy Bennett
  ('e86085c5-e044-49f1-a862-01d35da5f7f9'::uuid, 'openstates', 'ocd-person/16c8390c-93c6-403e-83d4-5ff1a81fe4aa', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Scott Van Binsbergen
  ('9b75b466-a210-4ac7-9997-da2a77b0b9b7'::uuid, 'openstates', 'ocd-person/18e1e0aa-a224-4772-b4d1-11c7a9ed510f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Aric Putnam
  ('842fbe6e-2018-4250-b024-5ce57aa278b7'::uuid, 'openstates', 'ocd-person/20c89480-8cde-4106-8b3d-54183371960a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Gander
  ('688aed9e-1232-44c8-a321-d4e79e312789'::uuid, 'openstates', 'ocd-person/23bda6c1-1fa1-4d42-9b6c-8c76d1d91227', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Pam Altendorf
  ('7a84bd40-30d3-4a27-9d54-b8262783f1da'::uuid, 'openstates', 'ocd-person/26c19220-1368-4453-81c9-3b0c395e3949', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Liz Boldon
  ('738daece-ad27-449f-8fad-8d614e296f63'::uuid, 'openstates', 'ocd-person/26ed75ae-3230-4e92-82a3-486bd76e1893', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Cedrick Frazier
  ('7f7c4959-18a0-4dd3-901e-8d59aece0337'::uuid, 'openstates', 'ocd-person/31bf14e3-fcde-4b2f-b2c4-1dd47b9a260b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Andy Smith
  ('3757d377-1cc0-45f0-8b6f-e1f988c6fea2'::uuid, 'openstates', 'ocd-person/41cf59c9-a2c3-442d-85f1-7d6ec8de1a97', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Nick Frentz
  ('c2d7c018-141c-4c34-a605-e8b1f53acdee'::uuid, 'openstates', 'ocd-person/55a02119-b43d-4b39-a19b-07411c5ec7c9', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Cal Bahr
  ('aa1104a3-2bf0-4fa5-81e4-00b3c95f649f'::uuid, 'openstates', 'ocd-person/57b9021d-f5b7-4f80-a82d-a93ca9a123d0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Julia Coleman
  ('b1f2628a-6264-4849-a14f-0f708fef5394'::uuid, 'openstates', 'ocd-person/62a79a93-6117-4f36-87ef-f4058c34142a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Nathan Coulter
  ('3386966b-b6fe-4ffb-8796-e755be9b44ab'::uuid, 'openstates', 'ocd-person/63b26a4d-ae7c-4267-89ab-dfa4a1f341ad', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Carla Nelson
  ('15788263-ad8f-4233-ac48-c9de61d2b55e'::uuid, 'openstates', 'ocd-person/69ac712d-4de2-448a-8b84-ef07b4c4e423', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Patty Mueller
  ('c93d7f91-5e6d-4e41-a0ac-303c019c4b99'::uuid, 'openstates', 'ocd-person/71df2690-6a54-4452-960a-54a5b6540bc7', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jeff Witte
  ('78a28a3b-98d0-46a6-bdf2-1d8b961fa6ed'::uuid, 'openstates', 'ocd-person/72c6929c-a329-4613-99a0-5e339f5a045f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Samantha Sencer-Mura
  ('05c8fc85-08b2-4f30-a6a3-65169ca9675d'::uuid, 'openstates', 'ocd-person/74dec7df-a9b9-48aa-9fae-bbe45990f4f5', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Lucy Rehm
  ('f409650c-fed4-467a-9ecd-000de3c99487'::uuid, 'openstates', 'ocd-person/75e19dbb-1f4b-4ace-b87e-201e445d25b4', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Peggy Scott
  ('15843ab1-33c5-480d-b4b4-c98935e9d880'::uuid, 'openstates', 'ocd-person/75f1b339-bd9f-4f7c-820b-75812553bde0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Sandra Feist
  ('641bf895-0822-4ed2-9423-24b1a3fada2a'::uuid, 'openstates', 'ocd-person/94c52434-9616-43bd-863b-9481943dedb1', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Nathan Nelson
  ('bd04bd63-5a7b-44ba-a34f-a293b51de5b9'::uuid, 'openstates', 'ocd-person/172cb289-beec-4bc1-8627-f027f2cd3769', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Shane Mekeland
  ('463cdab3-b3bd-4aa9-b834-bf573f4f34bf'::uuid, 'openstates', 'ocd-person/204ac87d-7f04-4b49-adc4-658faec7d413', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Zaynab Mohamed
  ('8ace4090-cdf6-4a6f-bcee-7aac68c51890'::uuid, 'openstates', 'ocd-person/332e30b5-dc8d-4074-9c16-6e2a6255d135', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bernie Perryman
  ('d12d13ea-dbb8-4871-b35e-f37e2385db9a'::uuid, 'openstates', 'ocd-person/354e366b-b9b5-46b4-b9ce-f3d96f508ceb', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Harry Niska
  ('a653e944-5dbf-4a40-bf03-02868ee902e7'::uuid, 'openstates', 'ocd-person/371f41ef-a432-4880-950b-f3ac4b17d02f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Brion Curran
  ('131b330a-cbc2-477e-a94b-3eeec70418a5'::uuid, 'openstates', 'ocd-person/372ff500-488c-4bf6-9557-6b5824c6e193', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mike Holmstrom
  ('927f1587-2180-4d0f-9238-2360dac34959'::uuid, 'openstates', 'ocd-person/564bbace-b157-416d-ae59-81cd8a1fbaf8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mohamud Noor
  ('afd02cc7-9c13-4345-b3b4-7a507c062414'::uuid, 'openstates', 'ocd-person/591ea10b-1362-434e-90be-2db0877a0e9c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Xp Lee
  ('82898b0f-ca2b-4b4e-8ca7-c60bbd2ea47f'::uuid, 'openstates', 'ocd-person/622e5358-869c-4d25-b6ed-e5425ca56caa', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Matt Norris
  ('e19f88ea-5ebe-4333-810e-d8d5d9ccaf9a'::uuid, 'openstates', 'ocd-person/662f07d4-7dd5-4549-bded-c8b5a200e054', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Marion Rarick
  ('aecee77e-b104-43a1-a907-fc44287dfd06'::uuid, 'openstates', 'ocd-person/0682bc6b-e4f2-427a-917b-96fbc49bb741', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ned Carroll
  ('4f779833-0eb9-4b14-b2a9-1e541f548849'::uuid, 'openstates', 'ocd-person/764db471-e56d-4ef0-9df8-4e7a164c3b7e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ron Latz
  ('1ab9c3b6-63b4-4afe-bd4a-aa1f7b057646'::uuid, 'openstates', 'ocd-person/834a2c10-beb0-454e-8e08-619309d8a08a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jim Joy
  ('ae296dbc-36aa-444f-89e3-1b1c6b734447'::uuid, 'openstates', 'ocd-person/0897d40e-d8b4-4b1e-b0cf-e0ae4e9685f2', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Peter Fischer
  ('e6333290-8189-415a-af13-7cfc594ca86b'::uuid, 'openstates', 'ocd-person/929dc6f7-63f4-4a9d-ba24-6ab8c5964acf', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Keith Allen
  ('a592683c-1ced-48a0-8a91-a2ad0a63aa39'::uuid, 'openstates', 'ocd-person/939c0bab-e76d-443f-b46b-7f98d05036e2', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jeff Howe
  ('f3440eb0-e3cc-4968-8ef5-2b670d88aadc'::uuid, 'openstates', 'ocd-person/971dbd16-363f-4151-a75c-306746aec18e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kaela Berg
  ('a89ba4b9-a684-40a6-b5ec-db0876a65b8d'::uuid, 'openstates', 'ocd-person/1912cdc1-267c-4d36-acec-08896502658e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mary Kunesh
  ('bb07b87a-b92b-426d-af32-9d505ff3bb7a'::uuid, 'openstates', 'ocd-person/2795e0ed-3a02-4afc-8836-f5c3c067139c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ron Kresha
  ('edc6c327-bd08-4993-af0b-98397d232e6d'::uuid, 'openstates', 'ocd-person/3059daef-810c-4917-b6fa-c059312f97bf', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Danny Nadeau
  ('4d2fbac3-d8d9-4bb4-96a9-bbaf0b864206'::uuid, 'openstates', 'ocd-person/04242ba4-8fb4-4306-98d2-cae358d8e532', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Josiah Hill
  ('393a864c-e1a1-4940-810c-e26322c5679e'::uuid, 'openstates', 'ocd-person/4558fb30-435a-4fde-acdd-bdcc82c7da45', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ann Johnson Stewart
  ('56c6c6c9-2bf8-4841-aa25-9244586e88eb'::uuid, 'openstates', 'ocd-person/4749e0fb-4f41-46e3-a8b4-19fdbbbde113', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jess Hanson
  ('79ee7fa2-44fb-4681-a7ed-450e74388425'::uuid, 'openstates', 'ocd-person/5099a61c-2d2a-41d0-a03d-ccbbb0edbf15', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Erin Maye Quade
  ('a9f089f1-c5a5-4cf6-908b-b9898a078fe7'::uuid, 'openstates', 'ocd-person/5233b98b-0b6d-47c9-9fc0-9218a592f8d8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Liish Kozlowski
  ('b6759469-327d-46fe-9064-0c1ec40bec63'::uuid, 'openstates', 'ocd-person/5604b347-d9b5-40b6-844d-8bc5246283d3', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Foung Hawj
  ('3e6dbcc6-a36c-46a5-a045-c55e294aa3f1'::uuid, 'openstates', 'ocd-person/5644f3f8-6394-4ab6-9619-7ab6702b37ea', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Huldah Hiltsley
  ('5c71d118-2442-4b4b-9504-7fb042541efb'::uuid, 'openstates', 'ocd-person/05831ea3-3480-4a57-a5ea-a1844a554301', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Duane Quam
  ('8f781313-476b-48a0-b80c-c57a683b7db8'::uuid, 'openstates', 'ocd-person/6652aa40-32c5-4430-bbf6-707a0b8a1f56', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kim Hicks
  ('c63adb8a-5321-4ef1-be53-c915f81308aa'::uuid, 'openstates', 'ocd-person/6902f219-7571-4bf1-a0af-ffa9eae2c23f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bonnie Westlin
  ('51a9e676-8adb-4682-b121-aed21a58e66f'::uuid, 'openstates', 'ocd-person/7536b66f-54fe-436e-ba03-83291c3c8d12', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Amanda Hemmingsen-Jaeger
  ('bd87858e-f045-4b4d-aa3c-cbcfe3613066'::uuid, 'openstates', 'ocd-person/8300aa36-f818-4ae8-ad31-f9373e396e08', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jay Xiong
  ('36ac7eb0-5bb1-4fa6-b0e9-bc984a73fdb8'::uuid, 'openstates', 'ocd-person/8892bfba-9b17-4378-8c85-f2d73d2b88ac', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mike Howard
  ('e6082f4d-56fd-4fc7-b29a-2da8ad703979'::uuid, 'openstates', 'ocd-person/8910b3db-698e-4019-b976-0ee19ecb8ca0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Heather Gustafson
  ('4ea59d05-8372-4646-8780-3b388b9bc98a'::uuid, 'openstates', 'ocd-person/9411a121-c47d-431a-b407-88ff5c891c5f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Aisha Gomez
  ('81033847-4e48-4080-a0c5-8daf154a4761'::uuid, 'openstates', 'ocd-person/09493dc0-a224-4cf6-a859-1384ffeda8a0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Katie Jones
  ('14b8fcd1-1981-4bbf-b766-287c664133f5'::uuid, 'openstates', 'ocd-person/12252e69-5ffb-459b-a84e-333af1219f94', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Josh Heintzeman
  ('0bfc2626-fbf0-44cc-bd0d-ffcd10b12d44'::uuid, 'openstates', 'ocd-person/18549c8f-0d80-4c2f-bdcc-f3762c3acb19', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Nolan West
  ('c9c55e16-d9fa-4c5a-b95e-b0e53cada2a5'::uuid, 'openstates', 'ocd-person/171224fc-8a8d-4516-aa87-a2f5bcf1ea46', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Leon Lillie
  ('31699ccd-426b-4708-9a1d-bdaced1a56dc'::uuid, 'openstates', 'ocd-person/00240593-7a31-4725-8c31-c723115732bb', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Paul Torkelson
  ('df16a6e7-95e5-4c40-b81e-690dfc7d3aeb'::uuid, 'openstates', 'ocd-person/380875c6-dc4c-4062-8c2d-f5b80dd64c4c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Wayne Johnson
  ('512c4ad3-271c-4108-bad5-e59a724fbc2a'::uuid, 'openstates', 'ocd-person/0926949b-8d9e-4fc0-b860-7662f46afdc6', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bianca Virnig
  ('01a09876-9713-4c34-b4a4-03b57c8b1535'::uuid, 'openstates', 'ocd-person/971431ad-1fdb-49e5-9cf0-57cfff1645a8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tom Sexton
  ('c0e174a4-b9c8-42d7-9bd3-937f642ae1d3'::uuid, 'openstates', 'ocd-person/2989633c-a60b-4337-972d-49941a4db1b6', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mike Freiberg
  ('ace1dba6-9927-4224-9e45-6aef5b6b75d6'::uuid, 'openstates', 'ocd-person/4815983e-d0b9-4ebc-855f-bb9eac8aa5ae', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Joe McDonald
  ('50ce958b-8215-41c2-afa0-cb993d31d2fd'::uuid, 'openstates', 'ocd-person/6292245e-1db4-4a8e-ba2a-a036e7b68044', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Meg Luger-Nikolai
  ('4e973b77-a492-4033-8067-7c38ceefa22c'::uuid, 'openstates', 'ocd-person/8164812a-be9a-44e0-bf42-741cb4a01e2c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Marj Fogelman
  ('338af9c7-7d7f-4450-830f-1a098a8cb080'::uuid, 'openstates', 'ocd-person/9837607c-b08b-4742-ad5f-3e8f72f8b7b4', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Lindsey Port
  ('08a8570b-9a9a-4cf7-bfd2-2d55a24136cb'::uuid, 'openstates', 'ocd-person/39814623-d268-47a1-8dcd-78e3ae1a33cf', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Dan Wolgamott
  ('bef03b5f-8da7-46b6-b609-433ffb993f10'::uuid, 'openstates', 'ocd-person/57755948-5912-49c5-b8b7-65c110ae44d9', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Erin Murphy
  ('f9f2c3e6-ae73-4844-91c2-c472d74c3aa9'::uuid, 'openstates', 'ocd-person/81828030-d1b8-4641-8692-8148fca58b28', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jimmy Gordon
  ('e0a3294a-692e-434d-b54b-c44b957b669d'::uuid, 'openstates', 'ocd-person/a2fed609-2172-4740-b9f3-f00a6da4716d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Matt Klein
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a'::uuid, 'openstates', 'ocd-person/a4b21c2d-d3fe-41dc-9614-0ff80878850c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Dave Pinto
  ('8ae767e1-a3bc-406d-a191-5fb5133ec190'::uuid, 'openstates', 'ocd-person/a8c6c773-371b-4df9-a57a-5d2565c7b876', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tom Murphy
  ('ca967473-dabb-4bfa-9019-63cc6b1bd2e5'::uuid, 'openstates', 'ocd-person/a798a6be-e28f-447c-b9ce-ffd7bf9a0ed4', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Isaac Schultz
  ('a6159eb9-ec8c-42a4-951a-b27e41a936bd'::uuid, 'openstates', 'ocd-person/a916d408-21ae-4eee-a2d7-c8019478f521', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Drazkowski
  ('b697907e-c2ac-40d5-805d-c6a06d88943b'::uuid, 'openstates', 'ocd-person/a947d529-ab68-4ae8-b1e8-7ff012dde193', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Eric Lucero
  ('830820d7-c5a5-4dec-ba83-f8a785a2fb41'::uuid, 'openstates', 'ocd-person/a9040c8f-56d4-4ad9-83f5-e6f1216e7a5e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Larry Kraft
  ('461ec505-bdae-4b92-af7d-7d2cabf65b20'::uuid, 'openstates', 'ocd-person/a4451923-cc1b-4d5d-9c14-5c50062335a2', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Andrew Mathews
  ('99080178-3c14-40f0-be57-c922f870bef9'::uuid, 'openstates', 'ocd-person/aabdca28-85ec-41e4-be90-726acaaa0cff', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Paul Anderson
  ('8d46d88e-ad1e-4a88-81c2-782da83d77f1'::uuid, 'openstates', 'ocd-person/ab35dde5-226a-4427-9344-c74d8291a75f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jim Carlson
  ('bfde1ba1-0aab-416e-884d-708bb14ee500'::uuid, 'openstates', 'ocd-person/ac087885-bab6-4fbf-b88a-daf71262c8b6', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Zach Duckworth
  ('099c5cb6-2221-4228-a3a8-0f5955d89112'::uuid, 'openstates', 'ocd-person/acacede0-a09a-45b9-8990-646dfa5bd59a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kristin Bahner
  ('4269e293-60c0-4348-adca-7a2dbc98dd18'::uuid, 'openstates', 'ocd-person/ad111cf3-f5f9-4e94-a087-dc39ce1fb136', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bjorn Olson
  ('65c57cac-84ad-4ac1-9b4b-db5db92f1dfc'::uuid, 'openstates', 'ocd-person/ad3245d1-b310-4d50-8290-e642d078f661', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Max Rymer
  ('b7093e4c-c73f-4acc-af87-274ff68c8431'::uuid, 'openstates', 'ocd-person/afca05de-e5ff-4b1c-b38c-444f37b92687', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Leigh Finke
  ('1c30fb24-6bda-46ca-94fe-df0579d7ca4d'::uuid, 'openstates', 'ocd-person/afff2a0a-1b2d-480e-a90d-8609842f0927', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Luke Frederick
  ('58f8cad2-0a73-43ac-83d6-fcc21a047b51'::uuid, 'openstates', 'ocd-person/b0d93fc5-2efc-4908-aceb-7b2fc208b34d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jamie Long
  ('9e9ae384-03ef-4f76-831b-3ccc266509a4'::uuid, 'openstates', 'ocd-person/b6ea5e13-3aad-438c-bed0-749a9bff80c3', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Rob Kupec
  ('a855b6e4-1ce3-44f1-ade3-de2bf2b95c9c'::uuid, 'openstates', 'ocd-person/b8c303a5-0a73-4a26-8071-be5a9dcf113a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- John Hoffman
  ('66a77b36-2947-47c1-8801-13a4f2f6e078'::uuid, 'openstates', 'ocd-person/b31cb55a-94ea-4f44-a4b9-8003b32c749a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bryan Lawrence
  ('2c007652-490b-4f11-9c16-e8b31de632bb'::uuid, 'openstates', 'ocd-person/b135d3fd-c3cd-4bb5-a0b8-eefef669aada', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Esther Agbaje
  ('285c226e-a195-4d7e-993b-d54b6712e65b'::uuid, 'openstates', 'ocd-person/b140f0d2-f803-4118-9c6c-72aa322ec3bb', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Patty Acomb
  ('f1f2ffaf-c9fb-4555-adf8-6c9c8114d9f3'::uuid, 'openstates', 'ocd-person/b393cb61-cb71-4cd0-8132-6e21c2a7202d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Elkins
  ('7c525707-de26-453c-9d7b-166ab5dcf9e5'::uuid, 'openstates', 'ocd-person/b867618c-7a49-4cb3-94ac-b5836ae8dedf', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Andrew Myers
  ('4a810646-c2f7-4702-a2ed-263fc3d0f4ed'::uuid, 'openstates', 'ocd-person/bba68b5b-90ac-4465-bdd2-fdf23c33b87a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Susan Pha
  ('feb4315d-60f4-49c5-a57b-0a65432a2868'::uuid, 'openstates', 'ocd-person/bd086574-4116-4b0a-ad6b-7c0352293f06', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Carlie Kotyza-Witthuhn
  ('e3311ba8-aeed-497c-b61c-4487f7a22383'::uuid, 'openstates', 'ocd-person/bfa93ce5-99ed-4840-9d49-c3531a6e7742', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Alice Mann
  ('6fb577f3-ac0b-4faa-9685-d4a0485e4860'::uuid, 'openstates', 'ocd-person/c5f2a744-0a3e-481f-9224-e4d5a58b9c9d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- John Burkel
  ('d6ec0d2d-21d1-4eda-933c-c7eb593389dc'::uuid, 'openstates', 'ocd-person/c86f501e-0b47-4e57-8f5a-d7d0be2392af', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Dave Baker
  ('70ad1a5d-f216-415e-a307-f31c83785abb'::uuid, 'openstates', 'ocd-person/c0275aeb-e2ff-44c7-b4ab-cae4bf495d84', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bobby Joe Champion
  ('24e523eb-c8b0-4b30-915b-6982c1d1a3cb'::uuid, 'openstates', 'ocd-person/c7436be4-472a-4d5e-82f5-f46359395d3a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Rick Hansen
  ('007efefd-7680-44b7-9f07-813340f52366'::uuid, 'openstates', 'ocd-person/c41944c1-d89b-4c3f-a76f-d5c58d0a507f', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Matt Bliss
  ('fb704747-1d31-4a6d-9ce5-c1f7185fb018'::uuid, 'openstates', 'ocd-person/cbab855f-4a47-4afd-b74a-468a4545b82b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ethan Cha
  ('376e49a2-a73e-4748-b7c4-9195cbfa2ec5'::uuid, 'openstates', 'ocd-person/d0e94ca0-b600-4567-88ee-34a861ca38aa', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Gary Dahms
  ('47534fbb-c532-4d3d-8e03-46695ca83f01'::uuid, 'openstates', 'ocd-person/d1b377a1-8caa-4e37-999b-83ef8a1bf92c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- María Isa Pérez-Vega
  ('2b1b89f8-5692-4acf-b437-e8f1ae677b13'::uuid, 'openstates', 'ocd-person/d1c094c0-6184-49e4-a18a-d5b900caca1b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Melissa Wiklund
  ('9e2e19df-eca0-4b74-8d0b-6ef205f5431c'::uuid, 'openstates', 'ocd-person/d2fb6801-379e-481c-9313-2ac099d3a775', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Fue Lee
  ('556de586-e176-4e68-90de-1eabb24a5b4d'::uuid, 'openstates', 'ocd-person/d8da71a7-c99b-4510-8abc-2d8e78db3fff', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Chris Swedzinski
  ('394260b2-ddfe-4c6d-91dc-544d7fef9fe8'::uuid, 'openstates', 'ocd-person/d9abe93e-6eba-4658-a0cd-68610585606b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Krista Knudsen
  ('d0ed90a5-39e0-479b-b450-b57edda4e539'::uuid, 'openstates', 'ocd-person/d9b75b0d-6065-4efc-81e2-03084dee070a', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kristin Robbins
  ('0a48874e-3d5a-4160-9481-a67cb23cfafc'::uuid, 'openstates', 'ocd-person/d32d0b31-20af-4068-a5bd-42fd0a072ded', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Gene Dornink
  ('e62ff25c-2d0a-4fc3-b235-ff33eacf43d4'::uuid, 'openstates', 'ocd-person/d3857eb4-0ec5-4406-840a-e338aad6a238', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jim Nash
  ('c9ea7750-8bd5-4db0-8ea9-40076eec7646'::uuid, 'openstates', 'ocd-person/d7012c12-e223-4409-823b-ba3e55be6677', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Warren Limmer
  ('7f870a88-85e4-4021-969b-c417709f01f0'::uuid, 'openstates', 'ocd-person/dc676c57-0779-4d0e-9ba4-a07d7034dfa1', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Karin Housley
  ('302feb80-0c30-4b42-b107-dae60b15fb4f'::uuid, 'openstates', 'ocd-person/dde8cf7d-52c2-48e5-bf65-f0fe2477713c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mark Johnson
  ('521f60ba-6749-4022-b9dc-1474fa63c890'::uuid, 'openstates', 'ocd-person/de9b28f6-a2a8-4edd-98cb-2b3ff2e6382c', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Roger Skraba
  ('63dd49ad-2466-4256-a71c-ad2477dfbe6d'::uuid, 'openstates', 'ocd-person/e7b3aed7-aa50-4c4b-bd53-eacc60e53ba8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Sydney Jordan
  ('1b23f52f-50da-48bf-877b-e1182a1e7679'::uuid, 'openstates', 'ocd-person/e60bb3ff-5164-4d6d-9029-d2e3d2ac69a0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Erica Schwartz
  ('b4a9f522-73e5-4816-8206-973ebfb897c0'::uuid, 'openstates', 'ocd-person/e62d342c-ae38-4607-88d7-3a7f3f7e248b', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Liz Reyer
  ('6af8f82e-dbee-4ad2-b3ff-7b9e694b849c'::uuid, 'openstates', 'ocd-person/e57307af-8e06-4c44-997d-a2cad2cdb231', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Steve Cwodzinski
  ('7845f8df-cc58-49fa-a87c-6483d6cdcf47'::uuid, 'openstates', 'ocd-person/e67843ce-752d-4cc0-abb9-4a45b8b8fdca', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ripper Repinski
  ('0318e417-787a-49d0-9bdf-1b8a27b00998'::uuid, 'openstates', 'ocd-person/e783687f-ea0d-480a-a1ff-3072f491fb44', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Cheryl Youakim
  ('7d365578-3cfd-444b-80fa-bd6927b3b72c'::uuid, 'openstates', 'ocd-person/ec1171fd-3b90-4137-b01d-041f905c642d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ann Rest
  ('3295d8e3-953f-4312-b660-a08b5ba8d862'::uuid, 'openstates', 'ocd-person/ec588921-873b-4335-8fa1-2e3485008d3e', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kari Rehrauer
  ('9918a503-86e6-403c-9c9b-0f2cd5ee0408'::uuid, 'openstates', 'ocd-person/ecea4720-d4e0-4c21-a4dd-76cdb54023d2', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Zack Stephenson
  ('a04547cf-8928-4638-9fe4-bef286cfba0f'::uuid, 'openstates', 'ocd-person/ed5f1cc0-ff12-461e-9016-0ef27f180430', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Tina Liebling
  ('73b22a9e-e9f8-4419-8f64-7c0ed9806da3'::uuid, 'openstates', 'ocd-person/ed6e8851-f7a8-41af-b2b6-570bd2004587', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Kristi Pursell
  ('56a81dd0-5e0e-446f-8835-65d643520b72'::uuid, 'openstates', 'ocd-person/ed73b309-bb2f-4805-a33b-a3fb760e6664', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jeff Backer
  ('7beab3d6-e4f9-401d-9859-de2ced5089f2'::uuid, 'openstates', 'ocd-person/edcf7ea6-b735-46b3-9d50-fa189cda6e8d', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Robert Bierman
  ('32422c01-9158-4264-b2b9-b021e3438cce'::uuid, 'openstates', 'ocd-person/f2b7f80c-abb4-4204-839f-eb9a4de6dbab', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jeff Dotseth
  ('28b95309-d367-4c50-988b-38c851950cbc'::uuid, 'openstates', 'ocd-person/f6aa30f5-2e66-44ae-8de0-352c64ddafe8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- John Jasinski
  ('959d8534-6a9a-41e7-af1c-b3d9e2e0499c'::uuid, 'openstates', 'ocd-person/f6b649e0-5359-4d22-8ff0-6ca017bc5e23', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ben Bakeberg
  ('562d1707-a74e-4ede-b8c7-8deaf9a90c0c'::uuid, 'openstates', 'ocd-person/f8d52f8b-1b8c-454d-87be-42edd3100511', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Liz Lee
  ('d5e54444-041b-4eeb-8043-b691d3a3edfb'::uuid, 'openstates', 'ocd-person/f9dbe591-5c2d-4a25-836a-ae05863b40ff', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Rich Draheim
  ('a41019c1-8548-4465-bbd6-f23688ed38dd'::uuid, 'openstates', 'ocd-person/f9fb7c65-e0ab-484c-8517-b20267cc3f07', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jason Rarick
  ('e9e8dab5-3add-4eb0-874f-7c7652fad785'::uuid, 'openstates', 'ocd-person/f15c0d42-4380-4f9b-b66d-14ffe61e1a40', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Mark Koran
  ('7f7ac8a6-a126-4eb6-bf68-b10aa124de60'::uuid, 'openstates', 'ocd-person/f20a4255-6c65-4091-a0f5-aea70f133cdb', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Elliott Engen
  ('171be6a9-0b10-4156-a2ce-e92da70f3b7f'::uuid, 'openstates', 'ocd-person/f27e2742-5c0f-4dba-a37f-76592f91f6f0', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Emma Greenman
  ('a9303183-ae2a-4c1b-9777-587bb356f488'::uuid, 'openstates', 'ocd-person/f38e8115-610c-4e22-b9cb-80bd96311410', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jeremy Miller
  ('d78d2570-7fca-4a5d-86c1-5f0996e3fdd4'::uuid, 'openstates', 'ocd-person/f0824aef-4692-46c8-bafa-f19a01a9d716', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bill Weber
  ('476f550b-5c67-4d65-b7d6-d834360503d7'::uuid, 'openstates', 'ocd-person/f839da78-1e9c-4e4b-b1d7-d203970ec6b2', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Dawn Gillman
  ('96bbf0ae-f4b0-4a93-836a-c1ae576de868'::uuid, 'openstates', 'ocd-person/f4047f6d-971d-41be-bbce-e15dac5829ae', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Eric Pratt
  ('fa8d5cfb-5feb-4112-b68b-f1c2de963dc3'::uuid, 'openstates', 'ocd-person/f520232e-1086-4353-b904-9ff7a89ba5e8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Ben Davis
  ('32a1f6b7-ced6-4417-8074-cb37faca7659'::uuid, 'openstates', 'ocd-person/f5597924-50c0-4bfc-bd63-3d3b814274f8', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Pete Johnson
  ('51834ca0-6073-4d6c-863e-adf4264bdede'::uuid, 'openstates', 'ocd-person/fb643600-2577-4561-a902-6f158a5c40e4', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Jim Abeler
  ('6162018b-568b-4739-8130-cde253fbb31b'::uuid, 'openstates', 'ocd-person/fc189dd9-b597-4744-86d3-ac315b93a3f3', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Paul Utke
  ('63a54046-caa9-4a19-a824-590c9305de0d'::uuid, 'openstates', 'ocd-person/fde08265-b73e-4a4b-ba87-d90d71319640', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)'),
  -- Bobbie Harder
  ('8d5c67e1-1443-477c-bfbf-317dbababa2f'::uuid, 'openstates', 'ocd-person/fe6a11bc-199d-467e-9447-3999c8250490', 'id_crosswalk', 'https://data.openstates.org/people/current/mn.csv (read 2026-11-20)')
) AS v(pid, t, val, m, src);

-- Post-guards: every sitting Minnesota legislator has exactly one LRL id; senators one Senate id; all one Open States id.
DO $$
DECLARE
  n_hold int; n_sen int; bad int;
BEGIN
  WITH h AS (
    SELECT DISTINCT och.politician_id pid, d.district_type
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND upper(d.state) = 'MN' AND och.politician_id IS NOT NULL)
  SELECT count(*), count(*) FILTER (WHERE district_type = 'STATE_UPPER'),
         count(*) FILTER (WHERE
           (SELECT count(*) FROM essentials.legislative_politician_id_map m WHERE m.politician_id = h.pid AND m.id_type = 'mn-lrl') <> 1
        OR (SELECT count(*) FROM essentials.legislative_politician_id_map m WHERE m.politician_id = h.pid AND m.id_type = 'openstates'
              AND m.source LIKE 'https://data.openstates.org/people/current/mn.csv%') <> 1
        OR (district_type = 'STATE_UPPER') <> ((SELECT count(*) FROM essentials.legislative_politician_id_map m
              WHERE m.politician_id = h.pid AND m.id_type = 'mn-senate-mem') = 1))
    INTO n_hold, n_sen, bad FROM h;
  IF n_hold <> 200 OR n_sen <> 67 OR bad <> 0 THEN
    RAISE EXCEPTION 'CA_0401: holders % (want 200), senators % (want 67), people with a wrong id count %', n_hold, n_sen, bad;
  END IF;
  IF (SELECT count(*) FROM essentials.legislative_politician_id_map WHERE id_type IN ('mn-lrl','mn-senate-mem')) <> 267 THEN
    RAISE EXCEPTION 'CA_0401: expected 267 Minnesota member-id rows';
  END IF;
  -- The worked case: Rep. Paul H. Anderson (12A) is LRL 15301.
  IF NOT EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map m JOIN essentials.politicians p ON p.id = m.politician_id
                  WHERE m.id_type = 'mn-lrl' AND m.id_value = '15301' AND p.full_name = 'Paul Anderson') THEN
    RAISE EXCEPTION 'CA_0401: LRL 15301 is not on Paul Anderson';
  END IF;
END $$;

COMMIT;
