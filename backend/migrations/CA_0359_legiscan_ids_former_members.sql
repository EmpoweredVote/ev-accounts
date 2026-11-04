-- CA_0359_legiscan_ids_former_members.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-04.
--
-- =============================================================================
-- CA_0359: LegiScan people ids for 16 former members of Congress, so their 2017-2020 votes can load
-- =============================================================================
-- WHY: CA_0358 gave these 16 active politicians a bioguide id, but they still have no federal votes. Their service
-- from 2017 on ended by January 2021, so they appear only in LegiScan's 115th/116th Congress datasets, and those
-- people files carry no bioguide id (0 of 561 and 0 of 550). federal_votes_legiscan.py links a member by bioguide
-- OR by an id_type 'legiscan' row in legislative_politician_id_map. Every stored 115th/116th federal vote
-- (244,413 + 242,328 rows) is source 'legiscan', so this reuses that loader and row shape rather than a second
-- source for the same Congresses.
--
-- SOURCE: LegiScan US datasets 1435 (115th) and 1658 (116th), both dated 2021-12-31, fetched 2026-11-04; and
-- unitedstates/congress-legislators legislators-historical.json + legislators-current.json, fetched 2026-11-04.
-- MATCHING: by id, not by name. congress-legislators maps each bioguide to a Vote Smart id and an OpenSecrets id;
-- each LegiScan person carries the same two ids. 15 of 16 matched one LegiScan person on BOTH ids. Garrett
-- (G000580) matched on OpenSecrets only (no Vote Smart id on one side); his LegiScan record is "Thomas Garrett",
-- House VA-5, which is his seat. Every match also agrees on name, chamber and state. Party is neither read nor written.
-- CHECKED read-only 2026-11-04: none of the 16 LegiScan ids is in the map; none of the 16 people has any
-- legiscan map row or any stored vote.
--
-- WHAT THIS DOES: inserts 16 rows into legislative_politician_id_map (id_type 'legiscan', source
-- 'legiscan-session-people', the source already used for federal LegiScan links). Each insert is guarded by the
-- politician's id, bioguide id and last name. Writes nothing else; votes are loaded afterwards by
-- federal_votes_legiscan.py (separate, approved run). Idempotent: a re-run inserts 0 rows and the gate still passes.
-- GATE: all 16 links present on the right person; no listed LegiScan id points at anyone else; each of the 16
-- has exactly one legiscan link.
--
-- REHEARSAL 2026-11-04 (links patched in memory, insert rolled back): the loader staged 21,709 votes, all on
-- these 16 people and no one else; each person's count per Congress equals a direct count of the raw LegiScan
-- vote files. Rollback confirmed (stored LegiScan federal total unchanged at 1,596,575).
-- DRY RUN: replace COMMIT with ROLLBACK and confirm afterwards that the 16 links are absent.
-- Dry run on prod 2026-11-04 (dry-run-migration.mjs): INSERT 16, gate OK, rolled back; the 16 links were absent
-- afterwards. Positive control: one last name changed in a copy -> gate failed ("only 15 of 16"), as it should.
-- APPLIED: 2026-11-04 on production, on a yes from Chris Andrews. INSERT 16, gate OK; all 16 links verified.
-- VOTES (on a further yes from Chris Andrews): federal_votes_legiscan.py <115th+116th datasets> --commit added
-- 21,709 rows (2,163 roll calls), all on these 16 people. Stored count per person per Congress equals a direct
-- count of the raw LegiScan vote files, for all 22 (person, Congress) pairs. LegiScan holds bill votes only (no
-- nominations), as for every other member's 115th-119th rows.
-- =============================================================================

BEGIN;

CREATE TEMP TABLE ca0359_links (pid uuid PRIMARY KEY, legiscan_id text UNIQUE NOT NULL, bioguide text UNIQUE NOT NULL,
  last_name text NOT NULL) ON COMMIT DROP;
INSERT INTO ca0359_links (pid, legiscan_id, bioguide, last_name) VALUES
  ('b78f058c-94de-4081-91fb-86ab7badb2fb'::uuid, '20087', 'M001209', 'McAdams'), -- Ben McAdams
  ('57b3e9b1-1df0-4bc1-b10b-7005eca4593a'::uuid, '15223', 'H001064', 'Heck'), -- Denny Heck
  ('00d1924e-50d9-485c-8e35-f3856553fdf9'::uuid, '14083', 'C001093', 'Collins'), -- Doug Collins
  ('1021e185-125e-4004-91bb-436a9727e4a9'::uuid, '19403', 'G000584', 'Gianforte'), -- Greg Gianforte
  ('ea2ea8af-7b16-48da-a70f-9752b0ca0db8'::uuid, '9110', 'P000598', 'Polis'), -- Jared Polis
  ('9b7310b5-d12f-419d-af87-6ad834a1055a'::uuid, '9041', 'E000288', 'Ellison'), -- Keith Ellison
  ('ba3d9cfd-9c80-45cc-9c25-b66471f0e3b7'::uuid, '21467', 'L000594', 'Loeffler'), -- Kelly Loeffler
  ('d23c3cc7-61e8-4dc3-8a5a-9347546dc0f2'::uuid, '15229', 'L000580', 'Lujan Grisham'), -- Michelle Lujan Grisham
  ('e0bab0e6-dc32-4d68-a479-0f59a79c0cf4'::uuid, '11138', 'L000573', 'Labrador'), -- Raul Labrador
  ('9c3974cb-355e-49ce-8633-c4450e27e4a8'::uuid, '9243', 'B001250', 'Bishop'), -- Rob Bishop
  ('358d0829-8d2b-46ea-9af2-251f48960014'::uuid, '14891', 'D000621', 'DeSantis'), -- Ron DeSantis
  ('becbb10c-fc9a-4125-9650-caec79be0d46'::uuid, '11048', 'D000614', 'Duffy'), -- Sean Duffy
  ('e8228875-8fed-4f62-8184-22c5bb0093e1'::uuid, '18307', 'G000580', 'Garrett'), -- Thomas Garrett
  ('d9b4d757-aa43-458d-9ecc-973338bceee4'::uuid, '9143', 'W000799', 'Walz'), -- Timothy Walz
  ('ac732037-2172-4899-95c9-ca42ea69c4a0'::uuid, '11072', 'R000592', 'Rokita'), -- Todd Rokita
  ('9a203de1-f2dc-46d6-86d1-ee40562a79c6'::uuid, '15054', 'G000571', 'Gabbard'); -- Tulsi Gabbard

INSERT INTO essentials.legislative_politician_id_map (politician_id, id_type, id_value, verified_at, source)
SELECT c.pid, 'legiscan', c.legiscan_id, now(), 'legiscan-session-people'
  FROM ca0359_links c
  JOIN essentials.politicians p ON p.id = c.pid AND p.bioguide_id = c.bioguide AND p.last_name = c.last_name
 WHERE NOT EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map m
                    WHERE m.politician_id = c.pid AND m.id_type = 'legiscan' AND m.id_value = c.legiscan_id);

DO $$
DECLARE n_pairs int; n_set int; n_elsewhere int; n_multi int;
BEGIN
  SELECT count(*) INTO n_pairs FROM ca0359_links;
  SELECT count(*) INTO n_set FROM ca0359_links c
    JOIN essentials.politicians p ON p.id = c.pid AND p.bioguide_id = c.bioguide AND p.last_name = c.last_name
    JOIN essentials.legislative_politician_id_map m
      ON m.politician_id = c.pid AND m.id_type = 'legiscan' AND m.id_value = c.legiscan_id;
  SELECT count(*) INTO n_elsewhere FROM essentials.legislative_politician_id_map m JOIN ca0359_links c
    ON m.id_type = 'legiscan' AND m.id_value = c.legiscan_id AND m.politician_id <> c.pid;
  SELECT count(*) INTO n_multi FROM (
    SELECT m.politician_id FROM essentials.legislative_politician_id_map m JOIN ca0359_links c ON c.pid = m.politician_id
     WHERE m.id_type = 'legiscan' GROUP BY 1 HAVING count(*) > 1) x;
  IF n_pairs <> 16 THEN RAISE EXCEPTION 'CA_0359: expected 16 pairs, found %', n_pairs; END IF;
  IF n_set <> 16 THEN RAISE EXCEPTION 'CA_0359: only % of 16 links present on the right person', n_set; END IF;
  IF n_elsewhere <> 0 THEN RAISE EXCEPTION 'CA_0359: % LegiScan id(s) also point at another politician', n_elsewhere; END IF;
  IF n_multi <> 0 THEN RAISE EXCEPTION 'CA_0359: % of the 16 carry more than one legiscan link', n_multi; END IF;
  RAISE NOTICE 'CA_0359 gate OK: % links, 0 elsewhere, 0 multiple', n_set;
END $$;
COMMIT;
