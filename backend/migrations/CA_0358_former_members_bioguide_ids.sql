-- CA_0358_former_members_bioguide_ids.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-04.
--
-- =============================================================================
-- CA_0358: set politicians.bioguide_id on 59 ACTIVE former members of Congress (targeted, not bulk)
-- =============================================================================
-- WHY: federal roll-call votes reach a person only through bioguide id (the federal vote loaders and the Stage 5
-- federal lane, #1287, never match by surname). CA_0339 set ids on SITTING members only, so a former member who is
-- now a governor, cabinet officer, state or local officeholder, or a 2026 candidate has no id and no federal votes.
-- CA_0353 (Jerry Carl) fixed one such person by hand; this does the rest of the active ones in one pass.
--
-- SCOPE: "active" = current holder in essentials.office_current_holder, or a race candidate in an election dated
-- 2026-01-01 or later; no bioguide id on the row or in legislative_politician_id_map. 12,878 such people.
-- SOURCE: unitedstates/congress-legislators legislators-historical.json + legislators-current.json, fetched
-- 2026-11-04 (members whose last term ended 1993 or later).
-- MATCHING: same normalized surname, same first name or nickname, and a shared state (our district/election
-- state vs. any of the member's term states). The 9 federal executive officers (no state on our side) were matched
-- on full name and checked by hand. Party is neither read nor written.
-- EXCLUDED on purpose (8):
--   namesakes - Douglas Owens O000156 (died 2002; ours is UT HD-33), Sam Johnson J000174 (died 2020; ours is Plano
--     ISD), Michael H. Michaud M001149 (ours is Augusta Ward 3 councilor Michael "Shu" Michaud), Robert Garcia
--     G000598 (ours is an Assembly AD-50 candidate), Alex Padilla P000145 (ours is the Inglewood councilmember).
--   duplicates of sitting members - John Rose R000612, Andy Biggs B001302, Dan Sullivan S001198 each have a second
--     record as a candidate. Setting the id there would put one bioguide on two rows, and the loaders skip such ids
--     (the CA_0354 Padilla failure). Those need a merge, not an id.
-- Web-checked 2026-11-04: Rob Bishop (Utah HD-6, seated 2026), John Bryant (TX HD-114 since 2023), Hilda Solis
-- (CA-38 2026 candidate) are the former members.
-- CHECKED read-only 2026-11-04: all 59 rows have an empty bioguide id; none of the 59 ids sits on any politician row
-- or in legislative_politician_id_map.
--
-- WHAT THIS DOES: sets bioguide_id on those 59 rows only, each guarded by id, empty bioguide id and last_name.
-- Writes nothing else; votes are loaded afterwards by federal_votes_legiscan.py (separate, approved runs).
-- Idempotent: a re-run updates 0 rows and the gate still passes.
-- GATE: all 59 pairs set; no id in this list on any other politician row; none in the bioguide map.
--
-- DRY RUN: wrap in BEGIN ... ROLLBACK (replace COMMIT) and confirm afterwards that the 59 rows are still empty.
-- Dry run on prod 2026-11-04 (yes from Chris Andrews): INSERT 59, UPDATE 59, gate OK (59 set, 0 clashes, 0 map
-- conflicts); rolled back; the 59 rows were empty before and still empty after.
-- APPLIED: 2026-11-04 on production, on a second yes from Chris Andrews. INSERT 59, UPDATE 59, gate OK; all 59
-- pairs verified afterwards, and no id in the list sits on more than one row.
-- VOTES (rehearsed first, then on a further yes from Chris Andrews): federal_votes_legiscan.py --congress 117 / 118 /
-- 119 --commit added 16,035 + 15,005 + 1,588 = 32,628 rows, all on 23 of these 59 people (checked row by row;
-- stored count afterwards matches exactly). Rubio and Braun already had their Senate votes through an older
-- LegiScan id link. GAP: LegiScan's 115th/116th datasets carry no bioguide ids, so 16 people whose 2017+ service
-- ended by Jan 2021 still have no federal votes (Collins, Gianforte, DeSantis, Heck, Gabbard, Ellison, Bishop,
-- Rokita, McAdams, Loeffler, Duffy, Lujan Grisham, Walz, Labrador, Garrett, Polis). Needs another source.
-- =============================================================================

BEGIN;

CREATE TEMP TABLE ca0358_pairs (pid uuid PRIMARY KEY, bioguide text UNIQUE NOT NULL, last_name text NOT NULL) ON COMMIT DROP;
INSERT INTO ca0358_pairs (pid, bioguide, last_name) VALUES
  ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, 'S001209', 'Spanberger'), -- Abigail Davis Spanberger, House VA 2019-2025; now: Governor | Virginia Governor
  ('76946887-bbad-4f41-82f0-223e2d0b2545'::uuid, 'G000556', 'Grayson'), -- Alan Grayson, House FL 2009-2017; now: U.S. Representative District 7 | 2026-11-03
  ('60329719-1d5b-4bb4-8295-38ea18f6f378'::uuid, 'B001304', 'Brown'), -- Anthony G. Brown, House MD 2017-2023; now: Attorney General of Maryland | 2026-11-03
  ('ff090074-25d8-4db5-96e8-c60de6893e6d'::uuid, 'D000630', 'Delgado'), -- Antonio Delgado, House NY 2019-2022; now: Lieutenant Governor | New York Lieutenant Governor
  ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, 'M001209', 'McAdams'), -- Ben McAdams, House UT 2019-2021; now: U.S. House District 1 | 2026-06-23
  ('27670793-ddd3-46af-9974-157d6b5c1b86'::uuid, 'G000595', 'Good'), -- Bob Good, House VA 2021-2025; now: U.S. House VA-05 | 2026-11-03
  ('1154e2d5-41b8-444d-b8f0-d9957999d6e7'::uuid, 'A000376', 'Allred'), -- Colin Z. Allred, House TX 2019-2025; now: U.S. Representative District 33 | 2026-11-03
  ('b2f31e4e-eaf2-468b-957c-5a46adf759b0'::uuid, 'B001224', 'Bush'), -- Cori Bush, House MO 2021-2025; now: U.S. Representative District 1 | 2026-11-03
  ('57b3e9b1-1df0-4bc1-b10b-7005eca4593a'::uuid, 'H001064', 'Heck'), -- Denny Heck, House WA 2013-2021; now: Lieutenant Governor | Washington Lieutenant Governor
  ('00d1924e-50d9-485c-8e35-f3856553fdf9'::uuid, 'C001093', 'Collins'), -- Doug Collins, House GA 2013-2021; now: Secretary of Veterans Affairs | United States
  ('2a22bd69-fd7a-4782-9057-4647fdb4e7cb'::uuid, 'L000591', 'Luria'), -- Elaine G. Luria, House VA 2019-2023; now: U.S. House VA-02 | 2026-11-03
  ('c98fd0a3-ea50-4659-967a-209ea5da6087'::uuid, 'S001193', 'Swalwell'), -- Eric Swalwell, House CA 2013-2026; now: CA Governor | 2026-06-02
  ('1021e185-125e-4004-91bb-436a9727e4a9'::uuid, 'G000584', 'Gianforte'), -- Greg Gianforte, House MT 2017-2021; now: Governor | Montana Governor
  ('42b6f850-8370-4800-81ba-c7ad018582b1'::uuid, 'L000604', 'Lopez'), -- Greg Lopez, House CO 2024-2025; now: Colorado Governor | 2026-11-03
  ('f1f3e6ca-5532-4f33-8ec2-64791b08f59b'::uuid, 'S001153', 'Solis'), -- Hilda Solis, House CA 2001-2009; now: U.S. Representative District 38 | 2026-11-03
  ('a809747d-3e53-4e9e-b3a1-6641dac2455c'::uuid, 'V000137', 'Vance'), -- J.D. Vance, Senate OH 2023-2025; now: Vice President | United States
  ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6'::uuid, 'H001063', 'Hahn'), -- Janice Hahn, House CA 2011-2016; now: Supervisor | District 4
  ('ea2ea8af-7b16-48da-a70f-9752b0ca0db8'::uuid, 'P000598', 'Polis'), -- Jared Polis, House CO 2009-2019; now: Governor | Colorado Governor
  ('105ff597-0fa1-4e2f-a257-5ae45724a143'::uuid, 'S001164', 'Schmidt'), -- Jean Schmidt, House OH 2005-2013; now: Representative | State House District 62
  ('8e0122c2-8bcb-4114-87e6-faa72d5d5125'::uuid, 'J000308', 'Jackson'), -- Jeff Jackson, House NC 2023-2024; now: Attorney General | North Carolina Attorney General
  ('c2a6cf9d-deb7-4ec7-9f97-cf300da8da6c'::uuid, 'L000574', 'Landry'), -- Jeffrey M. Landry, House LA 2011-2013; now: Governor | Louisiana Governor
  ('1d10c52b-e94a-40a2-a3bf-5f6ae8169818'::uuid, 'G000582', 'González-Colón'), -- Jenniffer González-Colón, House PR 2017-2025; now: Governor | Puerto Rico Governor
  ('0267f457-cd3f-4790-b0c8-76ec616de3f0'::uuid, 'M001166', 'McNerney'), -- Jerry McNerney, House CA 2007-2023; now: Senator | State Senate District 5
  ('70920806-a146-4dc3-8cc7-4566f9caf903'::uuid, 'B000997', 'Bryant'), -- John Bryant, House TX 1983-1997; now: Representative | TX House District 114
  ('a750bce8-a3ec-45fb-9812-5bb6f726e32f'::uuid, 'F000456', 'Fleming'), -- John Fleming, House LA 2009-2017; now: Treasurer | Louisiana Treasurer
  ('ffb0dcac-385a-4df3-a441-cdbd0e713c1d'::uuid, 'S001078', 'Sununu'), -- John Sununu, House+Senate NH 1997-2009; now: U.S. Senate New Hampshire | 2026-11-03
  ('21c9e711-fb18-4afb-884f-08acd2b598ba'::uuid, 'B001270', 'Bass'), -- Karen Bass, House CA 2011-2023; now: Los Angeles Mayor | 2026-11-03
  ('278d88a7-6ec5-4054-9dec-5209a347571e'::uuid, 'P000618', 'Porter'), -- Katie Porter, House CA 2019-2025; now: CA Governor | 2026-06-02
  ('9b7310b5-d12f-419d-af87-6ad834a1055a'::uuid, 'E000288', 'Ellison'), -- Keith Ellison, House MN 2007-2019; now: Attorney General | Minnesota Attorney General
  ('7544a9ec-53aa-4ed1-86a3-5f5f4d399544'::uuid, 'A000377', 'Armstrong'), -- Kelly Armstrong, House ND 2019-2024; now: Governor | North Dakota Governor
  ('13d45047-8183-46bd-a04a-5f5420b710cc'::uuid, 'A000368', 'Ayotte'), -- Kelly Ayotte, Senate NH 2011-2017; now: Governor | New Hampshire Governor
  ('ba3d9cfd-9c80-45cc-9c25-b66471f0e3b7'::uuid, 'L000594', 'Loeffler'), -- Kelly Loeffler, Senate GA 2020-2021; now: Administrator of the Small Business Administration | United 
  ('9edc0c37-f213-4aae-9212-c9cb4780d854'::uuid, 'R000581', 'Richardson'), -- Laura Richardson, House CA 2007-2013; now: Senator | State Senate District 35
  ('cb3c91b6-df47-479a-8dc7-1207106dbbcc'::uuid, 'Z000017', 'Zeldin'), -- Lee M. Zeldin, House NY 2015-2023; now: EPA Administrator | United States
  ('7c8e4442-e13e-485a-8993-b05ca110410d'::uuid, 'R000595', 'Rubio'), -- Marco Rubio, Senate FL 2011-2025; now: Secretary of State | United States
  ('6fccd939-1a0f-4aca-8114-bcc28ef7f8bb'::uuid, 'M001190', 'Mullin'), -- Markwayne Mullin, House+Senate OK 2013-2026; now: Secretary of Homeland Security | United States
  ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba'::uuid, 'P000619', 'Peltola'), -- Mary Sattler Peltola, House AK 2022-2025; now: U.S. Senate Alaska | 2026-08-18
  ('f410dd08-b72f-416c-bde0-bf83b5af00ed'::uuid, 'B001249', 'Burns'), -- Max Burns, House GA 2003-2005; now: Senator | State Senate District 23
  ('60f2dcfe-1669-4dee-9c32-a285f4756569'::uuid, 'B001253', 'Bean'), -- Melissa Bean, House IL 2005-2011; now: U.S. Representative District 8 | 2026-11-03
  ('9739fb00-209f-4ed0-ad06-b9d97d74ced1'::uuid, 'D000294', 'DeWine'), -- Michael DeWine, House+Senate OH 1983-2007; now: Governor | Ohio Governor
  ('b7dde767-495b-4d62-8e04-9ff27c193ee5'::uuid, 'W000823', 'Waltz'), -- Michael Waltz, House FL 2019-2025; now: Ambassador to the United Nations | United States
  ('d23c3cc7-61e8-4dc3-8a5a-9347546dc0f2'::uuid, 'L000580', 'Lujan Grisham'), -- Michelle Lujan Grisham, House NM 2013-2018; now: Governor | New Mexico Governor
  ('a73e7a2a-48b0-4636-8fa4-5324ede65833'::uuid, 'B001310', 'Braun'), -- Mike Braun, Senate IN 2019-2025; now: Indiana Governor | Indiana Governor
  ('ace0b96d-8ef8-4aca-8928-6848ae430da6'::uuid, 'R000572', 'Rogers'), -- Mike Rogers, House MI 2001-2015; now: U.S. Senate Michigan | 2026-11-03
  ('6609f174-6c1e-4fe9-afe6-2ed20f5f2463'::uuid, 'S001207', 'Sherrill'), -- Mikie Sherrill, House NJ 2019-2025; now: Governor | New Jersey Governor
  ('e0bab0e6-dc32-4d68-a479-0f59a79c0cf4'::uuid, 'L000573', 'Labrador'), -- Raúl R. Labrador, House ID 2011-2019; now: Attorney General | Idaho Attorney General
  ('9c3974cb-355e-49ce-8633-c4450e27e4a8'::uuid, 'B001250', 'Bishop'), -- Rob Bishop, House UT 2003-2021; now: State Representative District 6 | State House District 6
  ('358d0829-8d2b-46ea-9af2-251f48960014'::uuid, 'D000621', 'DeSantis'), -- Ron DeSantis, House FL 2013-2018; now: Governor | Florida Governor
  ('becbb10c-fc9a-4125-9650-caec79be0d46'::uuid, 'D000614', 'Duffy'), -- Sean P. Duffy, House WI 2011-2019; now: Secretary of Transportation | United States
  ('3768a470-ae44-4621-bb46-7596653d2cf4'::uuid, 'C001127', 'Cherfilus-McCormick'), -- Sheila Cherfilus-McCormick, House FL 2022-2026; now: U.S. Representative District 20 | 2026-11-03
  ('2568b40c-a517-4eaa-b0da-eb946f9b6df9'::uuid, 'B001231', 'Berkley'), -- Shelley Berkley, House NV 1999-2013; now: Mayor | City of Las Vegas
  ('56603da5-e7ad-48a9-8c77-259513869ed4'::uuid, 'B000944', 'Brown'), -- Sherrod Brown, House+Senate OH 1993-2025; now: Candidate for U.S. Senate — Ohio | Ohio
  ('e8228875-8fed-4f62-8184-22c5bb0093e1'::uuid, 'G000580', 'Garrett'), -- Thomas A. Garrett, Jr., House VA 2017-2019; now: Delegate | State House District 56
  ('9298415e-b8e5-4ccf-9f2a-b9366dd8ca1a'::uuid, 'G000567', 'Griffin'), -- Tim Griffin, House AR 2011-2015; now: Attorney General | Arkansas Attorney General
  ('d9b4d757-aa43-458d-9ecc-973338bceee4'::uuid, 'W000799', 'Walz'), -- Timothy J. Walz, House MN 2007-2019; now: Governor | Minnesota Governor
  ('ac732037-2172-4899-95c9-ca42ea69c4a0'::uuid, 'R000592', 'Rokita'), -- Todd Rokita, House IN 2011-2019; now: Indiana Attorney General | Indiana Attorney General
  ('9a203de1-f2dc-46d6-86d1-ee40562a79c6'::uuid, 'G000571', 'Gabbard'), -- Tulsi Gabbard, House HI 2013-2021; now: Director of National Intelligence | United States
  ('6b50637f-ed23-4155-9d69-42578bce95a3'::uuid, 'H000615', 'Hilleary'), -- Van Hilleary, House TN 1995-2003; now: U.S. Representative District 6 | 2026-11-03
  ('0f74219c-7d10-4d29-85fe-0f1d834df8a7'::uuid, 'B000287', 'Becerra');  -- Xavier Becerra, House CA 1993-2017; now: CA Governor | 2026-06-02

UPDATE essentials.politicians p
   SET bioguide_id = c.bioguide
  FROM ca0358_pairs c
 WHERE p.id = c.pid
   AND coalesce(p.bioguide_id, '') = ''
   AND p.last_name = c.last_name;

DO $$
DECLARE n_pairs int; n_set int; n_clash int; n_map int;
BEGIN
  SELECT count(*) INTO n_pairs FROM ca0358_pairs;
  SELECT count(*) INTO n_set FROM essentials.politicians p JOIN ca0358_pairs c
    ON c.pid = p.id AND p.bioguide_id = c.bioguide AND p.last_name = c.last_name;
  SELECT count(*) INTO n_clash FROM essentials.politicians p JOIN ca0358_pairs c
    ON p.bioguide_id = c.bioguide AND p.id <> c.pid;
  SELECT count(*) INTO n_map FROM essentials.legislative_politician_id_map m JOIN ca0358_pairs c
    ON m.id_type = 'bioguide' AND m.id_value = c.bioguide AND m.politician_id <> c.pid;
  IF n_pairs <> 59 THEN RAISE EXCEPTION 'CA_0358: expected 59 pairs, found %', n_pairs; END IF;
  IF n_set <> 59 THEN RAISE EXCEPTION 'CA_0358: only % of 59 rows carry their id', n_set; END IF;
  IF n_clash <> 0 THEN RAISE EXCEPTION 'CA_0358: % id(s) also sit on another politician row', n_clash; END IF;
  IF n_map <> 0 THEN RAISE EXCEPTION 'CA_0358: % id(s) point elsewhere in legislative_politician_id_map', n_map; END IF;
  RAISE NOTICE 'CA_0358 gate OK: % set, 0 clashes, 0 map conflicts', n_set;
END $$;

COMMIT;
