-- Migration 1091: Seed Nov 3 2026 CA US House general-election candidates (race_candidates only)
--
-- Phase 149-01 (v2.20 2026 US House Candidate Coverage). Wires the full Nov-3 general
-- field onto the 52 pre-existing CA US House races in the "CA 2026 Statewide General"
-- election (728d0074-8a8d-49e3-a68c-78ccdd15434f). CA is turnkey: elections + the 52
-- NATIONAL_LOWER races already exist with 0 race_candidates; this migration only inserts
-- race_candidates (+38 new politician records for genuinely-new challengers + Ruiz dedup).
--
-- Field source: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md
-- (per-district Wikipedia 2026_United_States_House_of_Representatives_elections_in_California
-- URLs, cited per row in race_candidates.source). Reconciliation (live reuse-vs-new decision
-- per candidate): backend/data/seed-ca-2026-house/149-01-reconciliation.csv (104 rows: 38 NEW
-- + 66 REUSE, all REUSE pids live-confirmed active 2026-06-29).
--
-- ANTIPARTISAN INVARIANT (D-03): party is NOT stored on race_candidates. Party in the field
-- table parens is read only to determine the race field; it lives on races.primary_party.
--
-- Record reuse (D-02): renominated/redistricted/previously-seeded figures REUSE their existing
-- politician_id (NEVER a new row for a sitting/previously-seeded rep — the v2.4 two-Andy-Barrs /
-- mig-1074 failure vector). Only the 38 genuinely-new names get new rows. Redistricted runners
-- reuse their existing pid with is_incumbent=false in the NEW district: Ami Bera (CA-6 -> CA-3),
-- Kevin Kiley (CA-3 -> CA-6 as Independent), Ken Calvert (CA-41 -> CA-40). Incumbent name
-- aliases reuse home pid as incumbent: Luz Rivas (Luz Maria Rivas), Ted Lieu (Ted W. Lieu),
-- Nanette Barragan (Nanette Diaz Baragan).
--
-- Raul Ruiz CA-25 dedup (D-02): KEEP canonical 5238b298-6004-4bcc-94c2-ee43a9c2999e (ext
-- -6000325, wired as CA-25 incumbent); RETIRE active duplicate 05349fa0-8529-4738-8556-f386965e4cc8
-- (ext NULL; had 1 office, 0 race_candidates/stances/images) via is_active=false; NEVER hard-DELETE.
-- (eb9448bd-... "RUIZ FOR PERRIS CITY COUNCIL 2018" already is_active=false.)
--
-- New external_id scheme: -(6010000 + cd*100 + seq); the -6010000..-6015999 band verified
-- empty/collision-free before authoring (2026-06-29).
--
-- Idempotent: NOT EXISTS guards on (external_id) for politicians and (race_id, full_name) for
-- race_candidates (there is NO DB unique constraint on either — application-enforced). A re-run
-- inserts 0 rows. Scoped to the 52 NATIONAL_LOWER House races; the 53rd (Governor) race is
-- NEVER touched.

BEGIN;

-- 1. Retire the active Raul Ruiz duplicate (CA-25 wired to the canonical record below).
UPDATE essentials.politicians
   SET is_active = false
 WHERE id = '05349fa0-8529-4738-8556-f386965e4cc8' AND is_active = true;

-- 2. Insert the 38 genuinely-new CA House candidates (no offices row -- feed resolves via
--    race_candidates.politician_id; an office row would pollute the reps feed / geofence search).
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
  (-6010201, 'Robin Littau', 'Robin', 'Littau'),
  (-6010301, 'Robb Tucker', 'Robb', 'Tucker'),
  (-6010401, 'Eric Jones', 'Eric', 'Jones'),
  (-6010501, 'Michael Masuda', 'Michael', 'Masuda'),
  (-6010601, 'Richard Pan', 'Richard', 'Pan'),
  (-6010801, 'Rudy Recile', 'Rudy', 'Recile'),
  (-6010901, 'John McBride', 'John', 'McBride'),
  (-6011001, 'Jeff Frese', 'Jeff', 'Frese'),
  (-6011201, 'Jamie Joyce', 'Jamie', 'Joyce'),
  (-6011301, 'Kevin Lincoln', 'Kevin', 'Lincoln'),
  (-6011401, 'Melissa Hernandez', 'Melissa', 'Hernandez'),
  (-6011501, 'Charles Hoelter', 'Charles', 'Hoelter'),
  (-6011601, 'Peter Sundin Soulé', 'Peter', 'Sundin Soulé'),
  (-6011701, 'Ritesh Tandon', 'Ritesh', 'Tandon'),
  (-6011801, 'Shane Lewis', 'Shane', 'Lewis'),
  (-6011901, 'Peter Verbica', 'Peter', 'Verbica'),
  (-6012001, 'Sandra Van Scotter', 'Sandra', 'Van Scotter'),
  (-6012101, 'Kyle Kirkland', 'Kyle', 'Kirkland'),
  (-6012201, 'Randy Villegas', 'Randy', 'Villegas'),
  (-6012301, 'Tessa Lynn Hodge', 'Tessa', 'Lynn Hodge'),
  (-6012401, 'Bob Smith', 'Bob', 'Smith'),
  (-6012601, 'Sam Gallucci', 'Sam', 'Gallucci'),
  (-6012901, 'Angélica María Dueñas', 'Angélica', 'María Dueñas'),
  (-6013801, 'Hilda Solis', 'Hilda', 'Solis'),
  (-6013802, 'Pedro Antonio Casas', 'Pedro', 'Antonio Casas'),
  (-6013901, 'Steve Manos', 'Steve', 'Manos'),
  (-6014101, 'Linda Sánchez', 'Linda', 'Sánchez'),
  (-6014102, 'Mitch Clemmons', 'Mitch', 'Clemmons'),
  (-6014201, 'Brian Burley', 'Brian', 'Burley'),
  (-6014301, 'Cristian Morales', 'Cristian', 'Morales'),
  (-6014401, 'Genevieve Angel', 'Genevieve', 'Angel'),
  (-6014501, 'Chuong Vo', 'Chuong', 'Vo'),
  (-6014601, 'David Pan', 'David', 'Pan'),
  (-6014701, 'Jenny Le Roux', 'Jenny', 'Le Roux'),
  (-6014801, 'Jim Desmond', 'Jim', 'Desmond'),
  (-6014901, 'Armen Kurdian', 'Armen', 'Kurdian'),
  (-6015101, 'Richardo Cabrera', 'Richardo', 'Cabrera'),
  (-6015201, 'Jeff Belle', 'Jeff', 'Belle')
) AS v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext
);

-- 3. Insert the 104 race_candidates onto the 52 existing CA House races.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT v.race_id, v.politician_id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  ('74a5b509-8904-430a-9630-e48d2889db62'::uuid, '0a283c28-344c-40c9-ae48-bb2dcf1c7c4d'::uuid, 'James Gallagher', 'James', 'Gallagher', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_1'),
  ('74a5b509-8904-430a-9630-e48d2889db62'::uuid, '974bfe8b-afb8-424c-bfd2-7805f033b1a0'::uuid, 'Mike McGuire', 'Mike', 'McGuire', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_1'),
  ('00a7bf9a-96b5-4818-9ff3-3de3a4048068'::uuid, '960e5acd-c847-4c8b-9a00-980483647849'::uuid, 'Jared Huffman', 'Jared', 'Huffman', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_2'),
  ('00a7bf9a-96b5-4818-9ff3-3de3a4048068'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010201), 'Robin Littau', 'Robin', 'Littau', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_2'),
  ('873ea4ce-52ed-475f-bd4c-006946eeeb99'::uuid, '0d635e23-f206-44fc-bac1-e309b932a081'::uuid, 'Ami Bera', 'Ami', 'Bera', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_3'),
  ('873ea4ce-52ed-475f-bd4c-006946eeeb99'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010301), 'Robb Tucker', 'Robb', 'Tucker', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_3'),
  ('eabbb909-51bc-4498-ab4f-10b0f1d83ad3'::uuid, '4466bd8c-8dba-4f2e-9471-c06d8429a779'::uuid, 'Mike Thompson', 'Mike', 'Thompson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_4'),
  ('eabbb909-51bc-4498-ab4f-10b0f1d83ad3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010401), 'Eric Jones', 'Eric', 'Jones', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_4'),
  ('9889c3b7-f1f5-427b-bef5-90331856451f'::uuid, 'f7704cd1-eec4-40d8-b44f-429b4f9c8611'::uuid, 'Tom McClintock', 'Tom', 'McClintock', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_5'),
  ('9889c3b7-f1f5-427b-bef5-90331856451f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010501), 'Michael Masuda', 'Michael', 'Masuda', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_5'),
  ('17eaf24e-1ab0-4457-a786-787fbcd39157'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010601), 'Richard Pan', 'Richard', 'Pan', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_6'),
  ('17eaf24e-1ab0-4457-a786-787fbcd39157'::uuid, '645a79be-ad06-461f-b2d6-3f811a0c48ee'::uuid, 'Kevin Kiley', 'Kevin', 'Kiley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_6'),
  ('143ffa3e-701f-46dc-ba19-f67c557b58eb'::uuid, '5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef'::uuid, 'Doris Matsui', 'Doris', 'Matsui', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_7'),
  ('143ffa3e-701f-46dc-ba19-f67c557b58eb'::uuid, 'ff0dc6f0-f5c8-4266-b70a-3fcc183da5c7'::uuid, 'Mai Vang', 'Mai', 'Vang', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_7'),
  ('3714f671-f75b-4f3f-981c-53df319f886c'::uuid, '28eeeb86-5ec1-48dd-86a7-9cf6d7771949'::uuid, 'John Garamendi', 'John', 'Garamendi', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_8'),
  ('3714f671-f75b-4f3f-981c-53df319f886c'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010801), 'Rudy Recile', 'Rudy', 'Recile', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_8'),
  ('f1f491b1-14b9-494b-b2fc-9955e9ee81c6'::uuid, '3ab13c27-f66e-486f-b3d4-87ddb927c35f'::uuid, 'Josh Harder', 'Josh', 'Harder', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_9'),
  ('f1f491b1-14b9-494b-b2fc-9955e9ee81c6'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6010901), 'John McBride', 'John', 'McBride', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_9'),
  ('63afb822-dc57-4d03-b616-e77ebc2b6080'::uuid, 'bc29096f-63ce-41f7-8d51-c4e6cfa87f8c'::uuid, 'Mark DeSaulnier', 'Mark', 'DeSaulnier', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_10'),
  ('63afb822-dc57-4d03-b616-e77ebc2b6080'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011001), 'Jeff Frese', 'Jeff', 'Frese', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_10'),
  ('586d8394-217f-4321-ad9e-4da4634202d4'::uuid, 'f3f21e38-d8e6-41d2-9d74-0360a5f679b9'::uuid, 'Connie Chan', 'Connie', 'Chan', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_11'),
  ('586d8394-217f-4321-ad9e-4da4634202d4'::uuid, 'eb8b6aa3-a9d2-4792-8175-a105304da87f'::uuid, 'Scott Wiener', 'Scott', 'Wiener', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_11'),
  ('0f99903c-9862-4ef9-b607-d760e8a87cf1'::uuid, '39db6eee-ccf5-4901-90a0-1c2580731b0e'::uuid, 'Lateefah Simon', 'Lateefah', 'Simon', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_12'),
  ('0f99903c-9862-4ef9-b607-d760e8a87cf1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011201), 'Jamie Joyce', 'Jamie', 'Joyce', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_12'),
  ('3bff8b9f-03d4-4431-afb1-ec56a0f1c4d3'::uuid, '1b473093-b86b-4b39-990b-19859d163080'::uuid, 'Adam Gray', 'Adam', 'Gray', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_13'),
  ('3bff8b9f-03d4-4431-afb1-ec56a0f1c4d3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011301), 'Kevin Lincoln', 'Kevin', 'Lincoln', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_13'),
  ('f6579e2c-0012-4e01-be52-f202e3aa25c2'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011401), 'Melissa Hernandez', 'Melissa', 'Hernandez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_14'),
  ('f6579e2c-0012-4e01-be52-f202e3aa25c2'::uuid, 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70'::uuid, 'Aisha Wahab', 'Aisha', 'Wahab', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_14'),
  ('21a3ca1e-00a9-47c2-b756-889cd55a84cd'::uuid, '9c880377-7e1f-4994-91b3-82d9cb15bbb4'::uuid, 'Kevin Mullin', 'Kevin', 'Mullin', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_15'),
  ('21a3ca1e-00a9-47c2-b756-889cd55a84cd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011501), 'Charles Hoelter', 'Charles', 'Hoelter', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_15'),
  ('429ad566-e2c3-43f5-bab6-bfbab56bfb18'::uuid, '7ceb0371-baba-4d05-9204-2852cc91dee0'::uuid, 'Sam Liccardo', 'Sam', 'Liccardo', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_16'),
  ('429ad566-e2c3-43f5-bab6-bfbab56bfb18'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011601), 'Peter Sundin Soulé', 'Peter', 'Sundin Soulé', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_16'),
  ('d306c5b6-5203-4955-9657-edcc886320a3'::uuid, '07255876-bbe6-4f6a-8c68-75939d9b5128'::uuid, 'Ro Khanna', 'Ro', 'Khanna', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_17'),
  ('d306c5b6-5203-4955-9657-edcc886320a3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011701), 'Ritesh Tandon', 'Ritesh', 'Tandon', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_17'),
  ('ff4b7da5-25fa-4496-a5f0-decb024d0c2a'::uuid, '956281d7-e27e-43cc-84e9-244879ed5ecf'::uuid, 'Zoe Lofgren', 'Zoe', 'Lofgren', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_18'),
  ('ff4b7da5-25fa-4496-a5f0-decb024d0c2a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011801), 'Shane Lewis', 'Shane', 'Lewis', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_18'),
  ('e98beacf-6a5b-4039-b977-eb1c30d53c8d'::uuid, '29a4c8f8-67a4-45a1-b4e8-ea708523cf3f'::uuid, 'Jimmy Panetta', 'Jimmy', 'Panetta', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_19'),
  ('e98beacf-6a5b-4039-b977-eb1c30d53c8d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6011901), 'Peter Verbica', 'Peter', 'Verbica', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_19'),
  ('8f40ae37-39c3-42cd-9bf8-851d6a967bac'::uuid, 'e228243c-4d7c-4a61-87c9-2e3f7a9d6afd'::uuid, 'Vince Fong', 'Vince', 'Fong', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_20'),
  ('8f40ae37-39c3-42cd-9bf8-851d6a967bac'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012001), 'Sandra Van Scotter', 'Sandra', 'Van Scotter', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_20'),
  ('1cbd9d96-519c-45e0-a0c2-3cab2b5894fe'::uuid, '196e8502-0aab-49a8-a6a0-6626bf121f34'::uuid, 'Jim Costa', 'Jim', 'Costa', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_21'),
  ('1cbd9d96-519c-45e0-a0c2-3cab2b5894fe'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012101), 'Kyle Kirkland', 'Kyle', 'Kirkland', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_21'),
  ('43105b49-ecdf-41ce-9309-38a0aef1b81d'::uuid, '42bff283-c977-43f1-9d54-a06131dc5eac'::uuid, 'David Valadao', 'David', 'Valadao', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_22'),
  ('43105b49-ecdf-41ce-9309-38a0aef1b81d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012201), 'Randy Villegas', 'Randy', 'Villegas', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_22'),
  ('7740b4c3-587b-4823-a530-8c229e20debd'::uuid, '18db5d61-6bce-4f55-ad45-bed01f329548'::uuid, 'Jay Obernolte', 'Jay', 'Obernolte', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_23'),
  ('7740b4c3-587b-4823-a530-8c229e20debd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012301), 'Tessa Lynn Hodge', 'Tessa', 'Lynn Hodge', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_23'),
  ('a7de60d2-605c-4db1-88cf-97b12eccf582'::uuid, '565438e0-04f1-4d2d-87cf-44df42ac1173'::uuid, 'Salud Carbajal', 'Salud', 'Carbajal', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_24'),
  ('a7de60d2-605c-4db1-88cf-97b12eccf582'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012401), 'Bob Smith', 'Bob', 'Smith', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_24'),
  ('295705e5-3254-4d75-bdb3-bf19f46ba099'::uuid, '5238b298-6004-4bcc-94c2-ee43a9c2999e'::uuid, 'Raul Ruiz', 'Raul', 'Ruiz', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_25'),
  ('295705e5-3254-4d75-bdb3-bf19f46ba099'::uuid, 'b6e6ecef-e4c6-4d2a-a0fc-f777706f7138'::uuid, 'Joe Males', 'Joe', 'Males', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_25'),
  ('c116e2e6-9512-4462-8633-d2a1373161cb'::uuid, '97285c92-b664-4687-a1e4-6d88cf9c7fe4'::uuid, 'Jacqui Irwin', 'Jacqui', 'Irwin', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_26'),
  ('c116e2e6-9512-4462-8633-d2a1373161cb'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012601), 'Sam Gallucci', 'Sam', 'Gallucci', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_26'),
  ('368aba08-e456-4b87-bd65-6d90e09a6d08'::uuid, 'c2f8656e-f73a-42ec-996e-87fceedf0389'::uuid, 'George Whitesides', 'George', 'Whitesides', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_27'),
  ('368aba08-e456-4b87-bd65-6d90e09a6d08'::uuid, '434cd9b0-ce80-42fd-b71d-f221349e33f5'::uuid, 'Jason Gibbs', 'Jason', 'Gibbs', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_27'),
  ('61682c04-9730-4528-a50b-7ffed0044016'::uuid, 'd75dfa60-351b-4f0d-880a-45acf013c82a'::uuid, 'Judy Chu', 'Judy', 'Chu', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_28'),
  ('61682c04-9730-4528-a50b-7ffed0044016'::uuid, '4d92b952-9cec-445e-8f09-239b82f16a88'::uuid, 'April Verlato', 'April', 'Verlato', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_28'),
  ('40190b91-ec57-4da9-9955-1cb3b8b06486'::uuid, 'a1fc524b-7c90-43c0-83a7-c76664293913'::uuid, 'Luz Rivas', 'Luz', 'Rivas', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_29'),
  ('40190b91-ec57-4da9-9955-1cb3b8b06486'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6012901), 'Angélica María Dueñas', 'Angélica', 'María Dueñas', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_29'),
  ('fc8ac036-1ab5-4012-aa67-16b334137509'::uuid, 'e099da71-f9d9-445d-96d9-179952bd539c'::uuid, 'Laura Friedman', 'Laura', 'Friedman', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_30'),
  ('fc8ac036-1ab5-4012-aa67-16b334137509'::uuid, '4bacdb84-7d0d-461b-a3b7-06709526ad03'::uuid, 'Scott Meyers', 'Scott', 'Meyers', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_30'),
  ('19a88b8b-5260-4c7b-b9a5-5217fc306b67'::uuid, 'be2943b7-f634-42f4-8ab8-15db8138169f'::uuid, 'Gil Cisneros', 'Gil', 'Cisneros', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_31'),
  ('19a88b8b-5260-4c7b-b9a5-5217fc306b67'::uuid, '340c4a0a-e6cb-4e32-9a56-f5cbf951cbc4'::uuid, 'Eric Ching', 'Eric', 'Ching', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_31'),
  ('dd326b64-5a46-4d71-b404-a9d9469cfbc5'::uuid, '96c77e2b-df35-4d56-a573-8bc0c15a142d'::uuid, 'Brad Sherman', 'Brad', 'Sherman', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_32'),
  ('dd326b64-5a46-4d71-b404-a9d9469cfbc5'::uuid, '9d425434-b3b5-4825-afa3-01d508b41ae4'::uuid, 'Larry Thompson', 'Larry', 'Thompson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_32'),
  ('b88178d8-23ac-4ab9-a73c-0687534da38a'::uuid, '822966a7-5f09-4151-ba43-630afbd676c2'::uuid, 'Pete Aguilar', 'Pete', 'Aguilar', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_33'),
  ('b88178d8-23ac-4ab9-a73c-0687534da38a'::uuid, '7e65a839-45ea-49d5-a4db-3edc1e411a07'::uuid, 'Stephanie Vargas', 'Stephanie', 'Vargas', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_33'),
  ('bed3e589-1f6d-4693-93af-5b05c9abc842'::uuid, '99d93781-7c5f-492c-b959-ee502ca05c29'::uuid, 'Jimmy Gomez', 'Jimmy', 'Gomez', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_34'),
  ('bed3e589-1f6d-4693-93af-5b05c9abc842'::uuid, '7b99c301-222a-4ebf-8427-c7290685e245'::uuid, 'Angela Gonzales-Torres', 'Angela', 'Gonzales-Torres', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_34'),
  ('ed452e1f-56aa-4a44-99a1-20fcf6bde43e'::uuid, 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, 'Norma Torres', 'Norma', 'Torres', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_35'),
  ('ed452e1f-56aa-4a44-99a1-20fcf6bde43e'::uuid, '67cf09dd-89d7-48a2-9ae6-85a045e616c0'::uuid, 'Mike Cargile', 'Mike', 'Cargile', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_35'),
  ('40e4571a-7492-4012-b244-70e2b185d15b'::uuid, '3a39c313-b994-447b-b3fd-592e4994769b'::uuid, 'Ted Lieu', 'Ted', 'Lieu', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_36'),
  ('40e4571a-7492-4012-b244-70e2b185d15b'::uuid, 'b7c00468-c2b4-4e48-876b-d218f3b53eac'::uuid, 'Houston Brignano', 'Houston', 'Brignano', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_36'),
  ('232fac06-8757-45c6-9c1b-6b492ec79657'::uuid, 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'::uuid, 'Sydney Kamlager-Dove', 'Sydney', 'Kamlager-Dove', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_37'),
  ('232fac06-8757-45c6-9c1b-6b492ec79657'::uuid, 'a3f12544-4d18-41da-a69e-9585219985d5'::uuid, 'Samantha Mota', 'Samantha', 'Mota', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_37'),
  ('2910e7f6-11f2-4496-a651-056991895606'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6013801), 'Hilda Solis', 'Hilda', 'Solis', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_38'),
  ('2910e7f6-11f2-4496-a651-056991895606'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6013802), 'Pedro Antonio Casas', 'Pedro', 'Antonio Casas', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_38'),
  ('83f9b284-404b-4869-bb33-a61a27f073ba'::uuid, '0af35a49-9908-474a-a3b6-f0f0ad1e85a0'::uuid, 'Mark Takano', 'Mark', 'Takano', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_39'),
  ('83f9b284-404b-4869-bb33-a61a27f073ba'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6013901), 'Steve Manos', 'Steve', 'Manos', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_39'),
  ('ce3d2c4f-42b2-40bc-9e40-4f96ca1446bb'::uuid, '97b8516d-37a6-46e5-8030-60ac927ced4f'::uuid, 'Ken Calvert', 'Ken', 'Calvert', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_40'),
  ('ce3d2c4f-42b2-40bc-9e40-4f96ca1446bb'::uuid, '504a0b06-6729-4fc5-93cd-7c43b1e153fe'::uuid, 'Young Kim', 'Young', 'Kim', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_40'),
  ('7ade7f08-0d2e-42e3-b7e4-ac2b5b8c58dd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014101), 'Linda Sánchez', 'Linda', 'Sánchez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_41'),
  ('7ade7f08-0d2e-42e3-b7e4-ac2b5b8c58dd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014102), 'Mitch Clemmons', 'Mitch', 'Clemmons', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_41'),
  ('6113b008-3a56-49e1-8d22-9236af5e7a6d'::uuid, '28a5f098-7f90-4fa9-af7e-c034d49cb538'::uuid, 'Robert Garcia', 'Robert', 'Garcia', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_42'),
  ('6113b008-3a56-49e1-8d22-9236af5e7a6d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014201), 'Brian Burley', 'Brian', 'Burley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_42'),
  ('740e83a7-aba3-4c2c-8137-33502453503e'::uuid, '203ab943-324d-4478-9093-d827d5d9c7da'::uuid, 'Maxine Waters', 'Maxine', 'Waters', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_43'),
  ('740e83a7-aba3-4c2c-8137-33502453503e'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014301), 'Cristian Morales', 'Cristian', 'Morales', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_43'),
  ('81365b4a-d1c9-4a4a-ad85-49d9e2640987'::uuid, '5bd54ac0-c8b9-486c-844c-ecc4313e5de7'::uuid, 'Nanette Barragán', 'Nanette', 'Barragán', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_44'),
  ('81365b4a-d1c9-4a4a-ad85-49d9e2640987'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014401), 'Genevieve Angel', 'Genevieve', 'Angel', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_44'),
  ('69d64aab-bcdb-497f-9392-4e939efe7d95'::uuid, 'b7612f49-c914-4ea7-a6da-559d71f313c2'::uuid, 'Derek Tran', 'Derek', 'Tran', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_45'),
  ('69d64aab-bcdb-497f-9392-4e939efe7d95'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014501), 'Chuong Vo', 'Chuong', 'Vo', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_45'),
  ('27130e86-b66f-4c50-9aa1-1a6e5b1887ec'::uuid, 'c06165d2-008c-4fe3-93cd-e31fbd6e377f'::uuid, 'Lou Correa', 'Lou', 'Correa', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_46'),
  ('27130e86-b66f-4c50-9aa1-1a6e5b1887ec'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014601), 'David Pan', 'David', 'Pan', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_46'),
  ('ccdca7a6-eb1c-4c20-8651-0c1ba6c30d6c'::uuid, '59b9f70a-b67d-4ff9-a99a-829442300178'::uuid, 'Dave Min', 'Dave', 'Min', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_47'),
  ('ccdca7a6-eb1c-4c20-8651-0c1ba6c30d6c'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014701), 'Jenny Le Roux', 'Jenny', 'Le Roux', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_47'),
  ('9770ac95-8777-41a2-9006-937ba5e14ba3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014801), 'Jim Desmond', 'Jim', 'Desmond', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_48'),
  ('9770ac95-8777-41a2-9006-937ba5e14ba3'::uuid, 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'::uuid, 'Marni von Wilpert', 'Marni', 'von Wilpert', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_48'),
  ('92e327ec-a49e-4e85-8516-6778e6712efb'::uuid, '821be1ee-ba55-4f47-9e5f-7a39f8514271'::uuid, 'Mike Levin', 'Mike', 'Levin', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_49'),
  ('92e327ec-a49e-4e85-8516-6778e6712efb'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6014901), 'Armen Kurdian', 'Armen', 'Kurdian', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_49'),
  ('613e48d5-86f9-4a82-811b-f9d1c3b091bd'::uuid, '3a9072fc-cb5c-4435-ad77-86562481830f'::uuid, 'Scott Peters', 'Scott', 'Peters', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_50'),
  ('613e48d5-86f9-4a82-811b-f9d1c3b091bd'::uuid, '7b2966fb-0b21-4db1-a3ad-f7f2cc69a4bb'::uuid, 'Steve Cohen', 'Steve', 'Cohen', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_50'),
  ('70c0bbe6-ae6e-462e-bfbf-741c34810fe0'::uuid, '51e4c723-299f-46a6-b1b2-f75386ee64f0'::uuid, 'Sara Jacobs', 'Sara', 'Jacobs', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_51'),
  ('70c0bbe6-ae6e-462e-bfbf-741c34810fe0'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6015101), 'Richardo Cabrera', 'Richardo', 'Cabrera', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_51'),
  ('959c4e27-ef9b-4dea-be87-a5ff8d42bb8f'::uuid, 'afa3cab9-4caf-4df3-a9ce-f739cc12b89d'::uuid, 'Juan Vargas', 'Juan', 'Vargas', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_52'),
  ('959c4e27-ef9b-4dea-be87-a5ff8d42bb8f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-6015201), 'Jeff Belle', 'Jeff', 'Belle', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_52')
) AS v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id AND rc.full_name = v.full_name
);

COMMIT;
