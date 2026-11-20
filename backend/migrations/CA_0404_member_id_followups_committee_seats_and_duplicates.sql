-- CA_0404 — member id follow-ups: committee seats written through wrong Open States ids, and the ids and
-- committee seats of two duplicate person rows.
--
-- 1. Moves 24 essentials.legislative_committee_memberships rows (Open States committees, California) from an
--    Assembly member to the senator Open States lists on that committee. They were written through the 8 wrong
--    `openstates-committees` id rows CA_0402 deleted: each put a senator's Open States id on an Assembly member,
--    so the senator's committee seats landed on the Assembly member. Checked 2026-11-20 against the public
--    Open States committee files (github.com/openstates/people, data/ca/committees/*.yml, `members[].person_id`):
--    every row below names the senator's id and not the Assembly member's. Moved rows (membership id, from -> to):
--      02a6fa18-6566-4646-a27d-11e4736120f8  Alexandra M. Macedo  -> Lena Gonzalez                senate International Sporting Events: Olympics and World Cup Soccer Special
--      27c9cb69-d421-4aa2-ba30-fb7012c0cc01  Catherine Stefani    -> Susan Rubio                  joint  Arts
--      78cbae4d-b1d4-4a95-b561-c969172a086e  Catherine Stefani    -> Susan Rubio                  senate International Sporting Events: Olympics and World Cup Soccer Special
--      bb9b3bc9-1041-43bf-8863-41dcee0b2ef6  Catherine Stefani    -> Susan Rubio                  joint  Legislative Emergency Management
--      8feda15f-4881-4534-8c73-a6f37664e8cb  Catherine Stefani    -> Susan Rubio                  senate Minority Economic Development Select
--      152b6d79-99f9-4710-b59c-b6c4f5e4bd0a  Gregg Hart           -> Henry Stern                  joint  Climate Change Policies Legislative
--      711171fd-367b-45f0-bf79-6cadcc673735  Gregg Hart           -> Henry Stern                  joint  Legislative Emergency Management
--      7df8ac74-8948-4e48-b2e6-24d3606f7171  Jeff Gonzalez        -> Lola Smallwood-Cuevas        senate Hydrogen Energy Select
--      beaf3025-e39e-4d9f-b9c0-e6d95746dde7  Jeff Gonzalez        -> Lola Smallwood-Cuevas        senate International Sporting Events: Olympics and World Cup Soccer Special
--      dadad80d-bed3-40cc-a0df-fd8b2a1f50a0  Liz Ortega           -> Laura Richardson             joint  Arts
--      d8e793a5-3bd3-44d3-9f00-f2151d6984a1  Liz Ortega           -> Laura Richardson             senate Green Economic Development Select
--      91516d32-bfa8-4931-8110-1cb670a1abd1  Liz Ortega           -> Laura Richardson             senate International Sporting Events: Olympics and World Cup Soccer Special
--      66831c36-68a1-4372-884e-d59c0b379775  Patrick J. Ahrens    -> Benjamin Allen               joint  Arts
--      f103f0ac-b7f0-43a2-bee8-d16f0a99d975  Patrick J. Ahrens    -> Benjamin Allen               senate California-Mexico Cooperation and Dialogue Select
--      668168da-9853-4525-b699-2091ed16cb56  Patrick J. Ahrens    -> Benjamin Allen               senate Economic Development and Technological Innovation Select
--      46a42994-b9d4-4fa0-9079-da66fad9f721  Patrick J. Ahrens    -> Benjamin Allen               senate Hydrogen Energy Select
--      67795d9e-e40d-4ab4-b091-e3ed5d6f0b84  Patrick J. Ahrens    -> Benjamin Allen               senate International Sporting Events: Olympics and World Cup Soccer Special
--      e07d3488-1386-4929-9c69-2260eb116b0d  Patrick J. Ahrens    -> Benjamin Allen               joint  Legislative Emergency Management
--      270e7925-a219-4f39-a5ec-f26c2cdf6dc5  Phillip Chen         -> Bob Archuleta                senate Community College: The Hub of the Community Select
--      b9a52d94-0ac5-4858-8ede-0194832f2ff3  Phillip Chen         -> Bob Archuleta                senate Hydrogen Energy Select
--      b0f630f6-b59d-48e3-8f6b-5c3a62392b2f  Phillip Chen         -> Bob Archuleta                senate International Sporting Events: Olympics and World Cup Soccer Special
--      babfb7e3-f49e-4cf7-bd1a-37fdf0fb2053  Steve Bennett        -> Suzette Martinez Valladares  senate Hydrogen Energy Select
--      fe173e34-7d97-4c44-bcf1-5f559571c420  Steve Bennett        -> Suzette Martinez Valladares  senate International Sporting Events: Olympics and World Cup Soccer Special
--      34107bb2-a0fd-40d6-a3c4-a24a03b987ab  Steve Bennett        -> Suzette Martinez Valladares  senate Minority Economic Development Select
--    To undo: set politician_id back to the "from" person of each row above.
--    NOT touched: 41 LegiScan-sourced Senate committee seats on 19 California Assembly members (and 6 cross-chamber
--    seats in Indiana). Those did not come through a wrong id (Macedo, Ahrens and Bennett never held a senator's
--    LegiScan id), so their owner is not known; it looks like an importer fault, a separate follow-up.
--
-- 2. Duplicate person rows. Tony Strickland and Caroline Menjivar each have an INACTIVE older row (b156be63…,
--    27a358cd…; source 'cicero') that held their Open States id and committee seats, while the ACTIVE row
--    (863ef272…, 4baa73c2…) holds the Senate seat. Moves the Open States id row (the seat match of 2026-11-19
--    confirms it: match_method 'seat') and every committee seat to the active row. Their LegiScan ids, votes and
--    bills move with scripts/member-ids/repair-legiscan-person.ts, not here. The inactive rows keep their older
--    compass answers and are not deleted.
--
-- STATUS: NOT APPLIED.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  UPDATE essentials.legislative_committee_memberships m
     SET politician_id = v.to_pid::uuid
    FROM (VALUES
      ('02a6fa18-6566-4646-a27d-11e4736120f8', '8566674a-3a3b-4c88-bba0-c9f42e4ff810', '1cede4d2-3075-4860-b133-1ab34cdacff5'),
      ('27c9cb69-d421-4aa2-ba30-fb7012c0cc01', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119'),
      ('78cbae4d-b1d4-4a95-b561-c969172a086e', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119'),
      ('bb9b3bc9-1041-43bf-8863-41dcee0b2ef6', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119'),
      ('8feda15f-4881-4534-8c73-a6f37664e8cb', '0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'b3937fff-ebcf-48d9-b20d-bdf98196e119'),
      ('152b6d79-99f9-4710-b59c-b6c4f5e4bd0a', '21940b7c-2424-47e9-a649-077b0f827c2c', 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'),
      ('711171fd-367b-45f0-bf79-6cadcc673735', '21940b7c-2424-47e9-a649-077b0f827c2c', 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'),
      ('7df8ac74-8948-4e48-b2e6-24d3606f7171', '5ad32852-789e-4013-995b-6f0aa6a5a5d4', 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'),
      ('beaf3025-e39e-4d9f-b9c0-e6d95746dde7', '5ad32852-789e-4013-995b-6f0aa6a5a5d4', 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'),
      ('dadad80d-bed3-40cc-a0df-fd8b2a1f50a0', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854'),
      ('d8e793a5-3bd3-44d3-9f00-f2151d6984a1', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854'),
      ('91516d32-bfa8-4931-8110-1cb670a1abd1', '6730d01a-e87e-4177-9a2b-876b9c494774', '9edc0c37-f213-4aae-9212-c9cb4780d854'),
      ('66831c36-68a1-4372-884e-d59c0b379775', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('f103f0ac-b7f0-43a2-bee8-d16f0a99d975', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('668168da-9853-4525-b699-2091ed16cb56', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('46a42994-b9d4-4fa0-9079-da66fad9f721', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('67795d9e-e40d-4ab4-b091-e3ed5d6f0b84', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('e07d3488-1386-4929-9c69-2260eb116b0d', 'bd4dc076-4bdd-4e10-be2c-80d998b17c50', '4486f856-118b-475c-83f0-078581a7b268'),
      ('270e7925-a219-4f39-a5ec-f26c2cdf6dc5', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca'),
      ('b9a52d94-0ac5-4858-8ede-0194832f2ff3', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca'),
      ('b0f630f6-b59d-48e3-8f6b-5c3a62392b2f', 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '29e15a5d-d98f-4536-ad62-05b2612f30ca'),
      ('babfb7e3-f49e-4cf7-bd1a-37fdf0fb2053', '8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '7f3b03b0-b481-4ccf-a33e-1261daabc6e8'),
      ('fe173e34-7d97-4c44-bcf1-5f559571c420', '8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '7f3b03b0-b481-4ccf-a33e-1261daabc6e8'),
      ('34107bb2-a0fd-40d6-a3c4-a24a03b987ab', '8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '7f3b03b0-b481-4ccf-a33e-1261daabc6e8')
    ) AS v(membership_id, from_pid, to_pid)
   WHERE m.id = v.membership_id::uuid AND m.politician_id = v.from_pid::uuid
     AND NOT EXISTS (SELECT 1 FROM essentials.legislative_committee_memberships t
                      WHERE t.committee_id = m.committee_id AND t.politician_id = v.to_pid::uuid
                        AND t.congress_number = m.congress_number);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 24 THEN RAISE EXCEPTION 'CA_0404: expected to move 24 Open States committee seats, moved %', n; END IF;

  -- 2. Duplicate rows: the Open States id and committee seats go to the active row.
  UPDATE essentials.legislative_politician_id_map
     SET politician_id = CASE politician_id
           WHEN 'b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid THEN '863ef272-ea35-482b-aee2-447c06bd469d'::uuid
           ELSE '4baa73c2-d38b-4d07-894f-1577d5ba43a3'::uuid END,
         match_method = 'seat', verified_at = now(),
         source = source || '; moved from an inactive duplicate row by CA_0404 (seat match 2026-11-19)'
   WHERE id_type = 'openstates'
     AND (politician_id, id_value) IN (
       ('b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid, 'ocd-person/3dae8bef-7fb2-40a0-afee-78d79212521b'),
       ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39'::uuid, 'ocd-person/b19c0361-ca41-4cba-bcf4-b7342a67f28b'));
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 2 THEN RAISE EXCEPTION 'CA_0404: expected to move 2 Open States ids off duplicate rows, moved %', n; END IF;

  UPDATE essentials.legislative_committee_memberships m
     SET politician_id = CASE m.politician_id
           WHEN 'b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid THEN '863ef272-ea35-482b-aee2-447c06bd469d'::uuid
           ELSE '4baa73c2-d38b-4d07-894f-1577d5ba43a3'::uuid END
   WHERE m.politician_id IN ('b156be63-59f0-4caa-98d9-44ae7afccf79', '27a358cd-d4d8-47d6-b2f1-6d984cb46b39')
     AND NOT EXISTS (SELECT 1 FROM essentials.legislative_committee_memberships t
                      WHERE t.committee_id = m.committee_id AND t.congress_number = m.congress_number
                        AND t.politician_id = CASE m.politician_id
                              WHEN 'b156be63-59f0-4caa-98d9-44ae7afccf79'::uuid THEN '863ef272-ea35-482b-aee2-447c06bd469d'::uuid
                              ELSE '4baa73c2-d38b-4d07-894f-1577d5ba43a3'::uuid END);
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 12 THEN RAISE EXCEPTION 'CA_0404: expected to move 12 committee seats off duplicate rows (4 + 8), moved %', n; END IF;

  -- Post-guards.
  IF EXISTS (SELECT 1 FROM essentials.legislative_committee_memberships
              WHERE politician_id IN ('b156be63-59f0-4caa-98d9-44ae7afccf79', '27a358cd-d4d8-47d6-b2f1-6d984cb46b39')) THEN
    RAISE EXCEPTION 'CA_0404: a duplicate row still holds a committee seat';
  END IF;
END $$;

COMMIT;
