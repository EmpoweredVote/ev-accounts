-- 1119_seed_il_2026_house_candidates.sql
-- Phase 155 Wave 2 (155-04): seed the certified Nov-3 field onto the 17 IL House races (155-01 scaffold,
-- mig 1117). Inserts 28 NEW essentials.politicians + 40 race_candidates (12 sitting incumbents
-- REUSED is_incumbent=true via 154 incumbent_pid + 28 new challengers/open-seat nominees).
--
-- FIELD SOURCE: 154-FIELD-TABLE.md IL section + per-district Wikipedia URLs, RE-CONFIRMED live 2026-06-30
-- (Ballotpedia + Wikipedia general-election tables). D-03 certified-general re-confirm RESOLVED the IL-4
-- suspicion: the 7-candidate IL-4 field IS the genuine certified general — Illinois lets independents/new-party
-- candidates PETITION DIRECTLY onto the general ballot (they skip the March primary), so an open Chicago seat
-- legitimately drew a 7-way general (Patty Garcia D primary winner + Lupe Castillo R + Ed Hershey Working Class
-- Party + 4 independents). IL-2 = Donna Miller D / Mike Noack R / Ashley Banks Ind. Open seats IL-7/8/9 D
-- nominees: La Shawn Ford / Melissa Bean / Daniel Biss.
--
-- DEDUP (D-03, live-verified 2026-06-30): all 28 new IL names returned 0 prior records (incl. Melissa
-- Bean, Daniel Biss, La Shawn Ford, Byron Sigcho-Lopez, Donna Miller — none pre-existed) -> all genuinely NEW.
-- Mary E. Miller (IL-15 R incumbent, reused) is a DIFFERENT person from Donna Miller (IL-2 new).
--
-- ANTIPARTISAN (D-06): party NOT stored on the card; no essentials.offices rows for challengers; never office_id NULL.
-- Idempotent: politicians guarded by NOT EXISTS(external_id); race_candidates by NOT EXISTS(race_id, lower(full_name)).

BEGIN;

-- 1) 28 new IL candidate politicians (negative external_id band -(17*10000+cd*100+seq)).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-170101, 'Christian Maxwell', 'Christian', 'Maxwell'),
    (-170201, 'Donna Miller', 'Donna', 'Miller'),
    (-170202, 'Mike Noack', 'Mike', 'Noack'),
    (-170203, 'Ashley Banks', 'Ashley', 'Banks'),
    (-170301, 'Angel Oakley', 'Angel', 'Oakley'),
    (-170401, 'Patty Garcia', 'Patty', 'Garcia'),
    (-170402, 'Lupe Castillo', 'Lupe', 'Castillo'),
    (-170403, 'Ed Hershey', 'Ed', 'Hershey'),
    (-170404, 'Lindsay Church', 'Lindsay', 'Church'),
    (-170405, 'Chris Getty', 'Chris', 'Getty'),
    (-170406, 'Mayra Macías', 'Mayra', 'Macías'),
    (-170407, 'Byron Sigcho-Lopez', 'Byron', 'Sigcho-Lopez'),
    (-170501, 'Tommy Hanson', 'Tommy', 'Hanson'),
    (-170601, 'Niki Conforti', 'Niki', 'Conforti'),
    (-170701, 'La Shawn Ford', 'La', 'Shawn Ford'),
    (-170702, 'Chad Koppie', 'Chad', 'Koppie'),
    (-170801, 'Melissa Bean', 'Melissa', 'Bean'),
    (-170802, 'Jennifer Davis', 'Jennifer', 'Davis'),
    (-170901, 'Daniel Biss', 'Daniel', 'Biss'),
    (-170902, 'John Elleson', 'John', 'Elleson'),
    (-171001, 'Carl Lambrecht', 'Carl', 'Lambrecht'),
    (-171101, 'Jeff Walter', 'Jeff', 'Walter'),
    (-171201, 'Julie Fortier', 'Julie', 'Fortier'),
    (-171301, 'Jeff Wilson', 'Jeff', 'Wilson'),
    (-171401, 'James Marter', 'James', 'Marter'),
    (-171501, 'Jennifer Todd', 'Jennifer', 'Todd'),
    (-171601, 'Paul Nolley', 'Paul', 'Nolley'),
    (-171701, 'Dillan Vancil', 'Dillan', 'Vancil')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2) 40 race_candidates onto the 17 IL races. politician_id = reuse uuid (incumbent) OR resolved
--    by external_id (new). candidate_status='active'. Guard: NOT EXISTS (race_id, lower(full_name)).
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id::uuid, COALESCE(v.pid_uuid::uuid, np.id), v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.src
FROM (VALUES
    ('c89b6491-8092-43cd-b70d-4097b8600b50', '66da3b64-3dab-4f79-950a-475acc006dc8', NULL, 'Jonathan L. Jackson', 'Jonathan', 'L. Jackson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_1'),
    ('c89b6491-8092-43cd-b70d-4097b8600b50', NULL, -170101, 'Christian Maxwell', 'Christian', 'Maxwell', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_1'),
    ('8a01f2aa-3cc7-4a2c-90dc-fdd6499c1783', NULL, -170201, 'Donna Miller', 'Donna', 'Miller', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_2'),
    ('8a01f2aa-3cc7-4a2c-90dc-fdd6499c1783', NULL, -170202, 'Mike Noack', 'Mike', 'Noack', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_2'),
    ('8a01f2aa-3cc7-4a2c-90dc-fdd6499c1783', NULL, -170203, 'Ashley Banks', 'Ashley', 'Banks', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_2'),
    ('74db93b8-c844-4775-a9e6-ad7caced9f6f', 'f74970a7-a63c-43e2-8033-d04b7f2bd64d', NULL, 'Delia C. Ramirez', 'Delia', 'C. Ramirez', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_3'),
    ('74db93b8-c844-4775-a9e6-ad7caced9f6f', NULL, -170301, 'Angel Oakley', 'Angel', 'Oakley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_3'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170401, 'Patty Garcia', 'Patty', 'Garcia', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170402, 'Lupe Castillo', 'Lupe', 'Castillo', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170403, 'Ed Hershey', 'Ed', 'Hershey', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170404, 'Lindsay Church', 'Lindsay', 'Church', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170405, 'Chris Getty', 'Chris', 'Getty', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170406, 'Mayra Macías', 'Mayra', 'Macías', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('43d78ceb-9a9a-4ce4-ab53-4ea599f0e888', NULL, -170407, 'Byron Sigcho-Lopez', 'Byron', 'Sigcho-Lopez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_4'),
    ('a2bad632-ae35-43db-a37f-2bb2ef282f4a', '05e88b53-b6f4-4c5d-bcd2-f6b7b20f98d6', NULL, 'Mike Quigley', 'Mike', 'Quigley', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_5'),
    ('a2bad632-ae35-43db-a37f-2bb2ef282f4a', NULL, -170501, 'Tommy Hanson', 'Tommy', 'Hanson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_5'),
    ('e124e9a1-5aa5-4cfa-9ef2-cc09544cff18', '05cf439f-3932-4398-b97b-4fd9a7506934', NULL, 'Sean Casten', 'Sean', 'Casten', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_6'),
    ('e124e9a1-5aa5-4cfa-9ef2-cc09544cff18', NULL, -170601, 'Niki Conforti', 'Niki', 'Conforti', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_6'),
    ('92259b93-2cb6-4078-bc2a-6f0d6cf8e8bf', NULL, -170701, 'La Shawn Ford', 'La', 'Shawn Ford', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_7'),
    ('92259b93-2cb6-4078-bc2a-6f0d6cf8e8bf', NULL, -170702, 'Chad Koppie', 'Chad', 'Koppie', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_7'),
    ('cd0eb9a3-08f0-455a-b4d4-640148a95321', NULL, -170801, 'Melissa Bean', 'Melissa', 'Bean', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_8'),
    ('cd0eb9a3-08f0-455a-b4d4-640148a95321', NULL, -170802, 'Jennifer Davis', 'Jennifer', 'Davis', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_8'),
    ('54f56737-8faf-4276-bb7d-8f8cc98bdb1b', NULL, -170901, 'Daniel Biss', 'Daniel', 'Biss', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_9'),
    ('54f56737-8faf-4276-bb7d-8f8cc98bdb1b', NULL, -170902, 'John Elleson', 'John', 'Elleson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_9'),
    ('ffef2601-403f-42fb-a257-2a9303d5d737', 'ecdb6fda-81cd-48bd-9403-a03a82f3ebad', NULL, 'Bradley Scott Schneider', 'Bradley', 'Scott Schneider', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_10'),
    ('ffef2601-403f-42fb-a257-2a9303d5d737', NULL, -171001, 'Carl Lambrecht', 'Carl', 'Lambrecht', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_10'),
    ('6931062e-5e90-42ae-a076-db6c36550b72', 'f45dfff4-2279-4d59-b682-160bb402b37b', NULL, 'Bill Foster', 'Bill', 'Foster', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_11'),
    ('6931062e-5e90-42ae-a076-db6c36550b72', NULL, -171101, 'Jeff Walter', 'Jeff', 'Walter', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_11'),
    ('672a3ae9-3a65-440f-b9b2-79b7aae43995', '01c4093a-db5a-4f92-9caa-b54c1e44c63a', NULL, 'Mike Bost', 'Mike', 'Bost', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_12'),
    ('672a3ae9-3a65-440f-b9b2-79b7aae43995', NULL, -171201, 'Julie Fortier', 'Julie', 'Fortier', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_12'),
    ('9969d601-7597-4930-bcb9-1c0b8bde61c7', '6192aa12-077f-42a8-a4cc-fcdf5d56355f', NULL, 'Nikki Budzinski', 'Nikki', 'Budzinski', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_13'),
    ('9969d601-7597-4930-bcb9-1c0b8bde61c7', NULL, -171301, 'Jeff Wilson', 'Jeff', 'Wilson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_13'),
    ('59fca96e-1863-4052-802a-059da25acec3', '4774c04d-23cd-4e0f-91d2-e294864f0dbb', NULL, 'Lauren Underwood', 'Lauren', 'Underwood', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_14'),
    ('59fca96e-1863-4052-802a-059da25acec3', NULL, -171401, 'James Marter', 'James', 'Marter', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_14'),
    ('57d0565f-4793-4e42-90d5-e9c1d69bb5a8', '73816ba4-4235-400c-a0a1-00c67b762687', NULL, 'Mary E. Miller', 'Mary', 'E. Miller', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_15'),
    ('57d0565f-4793-4e42-90d5-e9c1d69bb5a8', NULL, -171501, 'Jennifer Todd', 'Jennifer', 'Todd', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_15'),
    ('534a50e7-22f1-43a8-bb38-394800f88caa', 'f0d27c86-02f3-4014-9162-e4e940f2afdd', NULL, 'Darin LaHood', 'Darin', 'LaHood', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_16'),
    ('534a50e7-22f1-43a8-bb38-394800f88caa', NULL, -171601, 'Paul Nolley', 'Paul', 'Nolley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_16'),
    ('6b3e2352-4344-4398-8505-2c43e3a701d4', 'a87adee0-ca19-4e02-b734-e6a91ca34245', NULL, 'Eric Sorensen', 'Eric', 'Sorensen', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_17'),
    ('6b3e2352-4344-4398-8505-2c43e3a701d4', NULL, -171701, 'Dillan Vancil', 'Dillan', 'Vancil', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Illinois#District_17')
) AS v(race_id, pid_uuid, pid_ext, full_name, first_name, last_name, is_incumbent, src)
LEFT JOIN essentials.politicians np ON np.external_id = v.pid_ext::int
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND lower(rc.full_name) = lower(v.full_name)
);

COMMIT;
