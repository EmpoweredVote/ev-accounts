-- Migration 1111: Seed Nov 3 2026 NY US House general-election candidates (race_candidates + new politicians)
--
-- Phase 150-04 (v2.20). Wires the full Nov-3 general field onto the 26 NY US House races authored
-- in migration 1109 (NY 2026 Statewide General, 80a2b03d-...). 33 genuinely-new candidates get new
-- politician records (band -(3610000 + cd*100 + seq), -3610000..-3619999 verified empty 2026-06-29);
-- the 21 renominated incumbents REUSE their existing politician_id (148-incumbent-map.csv).
--
-- Field source: 148-FIELD-TABLE.md (per-district Wikipedia/Axios 2026_..._New_York URLs, cited per
-- row in race_candidates.source). Reconciliation: backend/data/seed-ny-2026-house/150-04-ny-reconciliation.csv
-- (54 rows = 33 NEW + 21 REUSE; all 33 new names live-confirmed 0-match 2026-06-29).
--
-- ANTIPARTISAN INVARIANT (D-05): party is NOT stored on race_candidates; races.primary_party NULL.
--
-- D-05 lost-primary (incumbent gets NO active row; primary WINNER is active):
--   NY-10 Goldman (c7f357ce, lost) -> Brad Lander (NEW) active; NY-13 Espaillat (26636234, lost) ->
--   Darializa Avila Chevalier (NEW) active. Retired: NY-7 Velazquez -> Valdez/Rivera; NY-12 Nadler ->
--   Lasher/Shinkle; NY-21 Stefanik -> Constantino/Gendebien/Smullen.
-- D-02 fusion minor lines SEEDED (party-agnostic): NY-13 Bob Cohen (Working Families), NY-21 Robert
--   Smullen (Conservative). NY-13 + NY-21 are 3-candidate races.
--
-- Idempotent: NOT EXISTS on (external_id) for politicians and (race_id, full_name) for race_candidates.
-- Scoped to the 26 NATIONAL_LOWER NY House races; never touches races rows; never office_id NULL;
-- never an essentials.offices row for a challenger.

BEGIN;

-- 1. Insert the 33 genuinely-new NY House candidates.
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
(-3610101, 'Chris Gallant', 'Chris', 'Gallant'),
  (-3610201, 'Patrick Halpin', 'Patrick', 'Halpin'),
  (-3610301, 'Mike LiPetri', 'Mike', 'LiPetri'),
  (-3610401, 'Jeanine Driscoll', 'Jeanine', 'Driscoll'),
  (-3610501, 'George Marsh', 'George', 'Marsh'),
  (-3610601, 'Joseph Chou', 'Joseph', 'Chou'),
  (-3610701, 'Claire Valdez', 'Claire', 'Valdez'),
  (-3610702, 'Melvin Rivera', 'Melvin', 'Rivera'),
  (-3610801, 'Lewis Mizrahi', 'Lewis', 'Mizrahi'),
  (-3610901, 'Joel Anabilah-Azumah', 'Joel', 'Anabilah-Azumah'),
  (-3611001, 'Brad Lander', 'Brad', 'Lander'),
  (-3611002, 'Jennifer Moore', 'Jennifer', 'Moore'),
  (-3611101, 'Michael DeCillis', 'Michael', 'DeCillis'),
  (-3611201, 'Micah Lasher', 'Micah', 'Lasher'),
  (-3611202, 'Caroline Shinkle', 'Caroline', 'Shinkle'),
  (-3611301, 'Darializa Avila Chevalier', 'Darializa', 'Avila Chevalier'),
  (-3611302, 'Jomo M. Williams', 'Jomo', 'M. Williams'),
  (-3611303, 'Bob Cohen', 'Bob', 'Cohen'),
  (-3611401, 'Diamant Hysenaj', 'Diamant', 'Hysenaj'),
  (-3611501, 'Stylo Sapaskis', 'Stylo', 'Sapaskis'),
  (-3611601, 'Joseph Cinquemani', 'Joseph', 'Cinquemani'),
  (-3611701, 'Cait Conley', 'Cait', 'Conley'),
  (-3611801, 'Jacqueline Auringer', 'Jacqueline', 'Auringer'),
  (-3611901, 'Peter Oberacker', 'Peter', 'Oberacker'),
  (-3612001, 'Ralph Ambrosio', 'Ralph', 'Ambrosio'),
  (-3612101, 'Anthony Constantino', 'Anthony', 'Constantino'),
  (-3612102, 'Blake Gendebien', 'Blake', 'Gendebien'),
  (-3612103, 'Robert Smullen', 'Robert', 'Smullen'),
  (-3612201, 'Kailee Buller', 'Kailee', 'Buller'),
  (-3612301, 'Aaron Gies', 'Aaron', 'Gies'),
  (-3612401, 'Alissa Ellman', 'Alissa', 'Ellman'),
  (-3612501, 'Virginia McIntyre', 'Virginia', 'McIntyre'),
  (-3612601, 'Dennis Hannon', 'Dennis', 'Hannon')
) v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2. Insert the 54 race_candidates (33 new + 21 reuse) onto the 26 NY races.
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id, v.politician_id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  ('f1415ce1-250b-49d5-afc1-b0f0f624b044'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36001), 'Nick LaLota', 'Nick', 'LaLota', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_1'),
  ('f1415ce1-250b-49d5-afc1-b0f0f624b044'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610101), 'Chris Gallant', 'Chris', 'Gallant', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_1'),
  ('05d23321-9f87-412e-9b21-34c812b16c4d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36002), 'Andrew R. Garbarino', 'Andrew', 'R. Garbarino', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_2'),
  ('05d23321-9f87-412e-9b21-34c812b16c4d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610201), 'Patrick Halpin', 'Patrick', 'Halpin', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_2'),
  ('e091d25a-1c46-45c0-8835-f0d84ae06173'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36003), 'Thomas R. Suozzi', 'Thomas', 'R. Suozzi', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_3'),
  ('e091d25a-1c46-45c0-8835-f0d84ae06173'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610301), 'Mike LiPetri', 'Mike', 'LiPetri', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_3'),
  ('e03c23bc-1676-49e6-8e3c-f4c00dde548d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36004), 'Laura Gillen', 'Laura', 'Gillen', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_4'),
  ('e03c23bc-1676-49e6-8e3c-f4c00dde548d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610401), 'Jeanine Driscoll', 'Jeanine', 'Driscoll', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_4'),
  ('87d3ba4f-2a14-4af0-aea9-b3430b136155'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36005), 'Gregory W. Meeks', 'Gregory', 'W. Meeks', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_5'),
  ('87d3ba4f-2a14-4af0-aea9-b3430b136155'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610501), 'George Marsh', 'George', 'Marsh', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_5'),
  ('7061d405-60ca-49df-b23d-f0dee8ec7345'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36006), 'Grace Meng', 'Grace', 'Meng', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_6'),
  ('7061d405-60ca-49df-b23d-f0dee8ec7345'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610601), 'Joseph Chou', 'Joseph', 'Chou', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_6'),
  ('221c4481-3039-44a2-8455-928fa2cba87e'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610701), 'Claire Valdez', 'Claire', 'Valdez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_7'),
  ('221c4481-3039-44a2-8455-928fa2cba87e'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610702), 'Melvin Rivera', 'Melvin', 'Rivera', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_7'),
  ('ed0a4ce0-ff59-40b4-8a81-501f72a197c6'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36008), 'Hakeem S. Jeffries', 'Hakeem', 'S. Jeffries', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_8'),
  ('ed0a4ce0-ff59-40b4-8a81-501f72a197c6'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610801), 'Lewis Mizrahi', 'Lewis', 'Mizrahi', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_8'),
  ('b56f4f54-8945-4d6e-8e55-b6812a7c79d3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36009), 'Yvette D. Clarke', 'Yvette', 'D. Clarke', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_9'),
  ('b56f4f54-8945-4d6e-8e55-b6812a7c79d3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3610901), 'Joel Anabilah-Azumah', 'Joel', 'Anabilah-Azumah', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_9'),
  ('a11fd498-9cf0-4319-8742-e73ef941c738'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611001), 'Brad Lander', 'Brad', 'Lander', false, 'https://www.axios.com/2026/06/24/dan-goldman-brad-lander-mamdani-new-york-primary'),
  ('a11fd498-9cf0-4319-8742-e73ef941c738'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611002), 'Jennifer Moore', 'Jennifer', 'Moore', false, 'https://www.axios.com/2026/06/24/dan-goldman-brad-lander-mamdani-new-york-primary'),
  ('ac2e8d2e-186b-4570-86a5-a02a1bad3f67'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36011), 'Nicole Malliotakis', 'Nicole', 'Malliotakis', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_11'),
  ('ac2e8d2e-186b-4570-86a5-a02a1bad3f67'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611101), 'Michael DeCillis', 'Michael', 'DeCillis', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_11'),
  ('2e48b131-f593-4d6e-91dc-4b8c42e59bc1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611201), 'Micah Lasher', 'Micah', 'Lasher', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_12'),
  ('2e48b131-f593-4d6e-91dc-4b8c42e59bc1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611202), 'Caroline Shinkle', 'Caroline', 'Shinkle', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_12'),
  ('08b0a874-5fc5-4d02-ac61-986ebc2238bb'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611301), 'Darializa Avila Chevalier', 'Darializa', 'Avila Chevalier', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_13'),
  ('08b0a874-5fc5-4d02-ac61-986ebc2238bb'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611302), 'Jomo M. Williams', 'Jomo', 'M. Williams', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_13'),
  ('08b0a874-5fc5-4d02-ac61-986ebc2238bb'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611303), 'Bob Cohen', 'Bob', 'Cohen', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_13'),
  ('7f0ae969-0667-4ab1-8ae1-3e6508bc9477'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36014), 'Alexandria Ocasio-Cortez', 'Alexandria', 'Ocasio-Cortez', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_14'),
  ('7f0ae969-0667-4ab1-8ae1-3e6508bc9477'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611401), 'Diamant Hysenaj', 'Diamant', 'Hysenaj', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_14'),
  ('32d39b1d-30e4-470e-8ef4-64c1192acccc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36015), 'Ritchie Torres', 'Ritchie', 'Torres', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_15'),
  ('32d39b1d-30e4-470e-8ef4-64c1192acccc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611501), 'Stylo Sapaskis', 'Stylo', 'Sapaskis', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_15'),
  ('fcb869e9-2fee-4551-8920-ae5fc161769a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36016), 'George Latimer', 'George', 'Latimer', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_16'),
  ('fcb869e9-2fee-4551-8920-ae5fc161769a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611601), 'Joseph Cinquemani', 'Joseph', 'Cinquemani', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_16'),
  ('82d021d3-f4e9-4465-a5e9-d2ef8358df34'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36017), 'Michael Lawler', 'Michael', 'Lawler', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_17'),
  ('82d021d3-f4e9-4465-a5e9-d2ef8358df34'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611701), 'Cait Conley', 'Cait', 'Conley', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_17'),
  ('1a49995f-8de3-434f-968b-ac9ef8168752'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36018), 'Patrick Ryan', 'Patrick', 'Ryan', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_18'),
  ('1a49995f-8de3-434f-968b-ac9ef8168752'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611801), 'Jacqueline Auringer', 'Jacqueline', 'Auringer', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_18'),
  ('9f71abe0-0049-4010-a43f-0adbe6d8a4b3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36019), 'Josh Riley', 'Josh', 'Riley', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_19'),
  ('9f71abe0-0049-4010-a43f-0adbe6d8a4b3'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3611901), 'Peter Oberacker', 'Peter', 'Oberacker', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_19'),
  ('ad4f7917-d49e-47e3-b60b-e0f73e95d3b1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36020), 'Paul Tonko', 'Paul', 'Tonko', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_20'),
  ('ad4f7917-d49e-47e3-b60b-e0f73e95d3b1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612001), 'Ralph Ambrosio', 'Ralph', 'Ambrosio', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_20'),
  ('6cd0af96-9d2f-4990-9a78-036d60fc2f40'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612101), 'Anthony Constantino', 'Anthony', 'Constantino', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_21'),
  ('6cd0af96-9d2f-4990-9a78-036d60fc2f40'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612102), 'Blake Gendebien', 'Blake', 'Gendebien', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_21'),
  ('6cd0af96-9d2f-4990-9a78-036d60fc2f40'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612103), 'Robert Smullen', 'Robert', 'Smullen', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_21'),
  ('92365231-af4e-49c4-969a-e24f2005ab01'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36022), 'John W. Mannion', 'John', 'W. Mannion', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_22'),
  ('92365231-af4e-49c4-969a-e24f2005ab01'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612201), 'Kailee Buller', 'Kailee', 'Buller', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_22'),
  ('920d5128-79d8-4446-9d0d-b39e3482e6b4'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36023), 'Nicholas A. Langworthy', 'Nicholas', 'A. Langworthy', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_23'),
  ('920d5128-79d8-4446-9d0d-b39e3482e6b4'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612301), 'Aaron Gies', 'Aaron', 'Gies', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_23'),
  ('8f8dbd3b-f01e-4096-b6c5-5aff7f960321'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36024), 'Claudia Tenney', 'Claudia', 'Tenney', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_24'),
  ('8f8dbd3b-f01e-4096-b6c5-5aff7f960321'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612401), 'Alissa Ellman', 'Alissa', 'Ellman', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_24'),
  ('c7a0aafc-63b3-475e-bf52-ba1111470024'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36025), 'Joseph D. Morelle', 'Joseph', 'D. Morelle', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_25'),
  ('c7a0aafc-63b3-475e-bf52-ba1111470024'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612501), 'Virginia McIntyre', 'Virginia', 'McIntyre', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_25'),
  ('5cbfc002-fbe7-44cb-a295-4498f1681b4f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-36026), 'Timothy M. Kennedy', 'Timothy', 'M. Kennedy', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_26'),
  ('5cbfc002-fbe7-44cb-a295-4498f1681b4f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-3612601), 'Dennis Hannon', 'Dennis', 'Hannon', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_26')
) v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id AND rc.full_name = v.full_name
);

-- 3. Post-write assertions (NY NATIONAL_LOWER geo '36' within NY 2026 Statewide General).
DO $$
DECLARE
  v_races int; v_nullpid int; v_dup int; v_lost int; v_active int;
  v_lander int; v_cohen int; v_smullen int; ny_eid uuid;
BEGIN
  SELECT id INTO ny_eid FROM essentials.elections WHERE name='NY 2026 Statewide General';
  SELECT count(DISTINCT r.id),
         count(*) FILTER (WHERE rc.candidate_status='active' AND rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.candidate_status='active')
    INTO v_races, v_nullpid, v_active
  FROM essentials.races r
  JOIN essentials.offices o ON o.id=r.office_id
  JOIN essentials.districts d ON d.id=o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id=r.id
  WHERE r.election_id=ny_eid AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='36';
  IF v_races<>26 THEN RAISE EXCEPTION 'FAIL: expected 26 NY races, got %', v_races; END IF;
  IF v_nullpid<>0 THEN RAISE EXCEPTION 'FAIL: % active NY rows with NULL politician_id', v_nullpid; END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT lower(rc.full_name) FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
    WHERE r.election_id=ny_eid AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='36'
      AND rc.candidate_status='active'
    GROUP BY lower(rc.full_name) HAVING count(*)>1) q;
  IF v_dup<>0 THEN RAISE EXCEPTION 'FAIL: % duplicate full_name within NY', v_dup; END IF;

  SELECT count(*) INTO v_lost FROM essentials.race_candidates rc
  WHERE rc.candidate_status='active'
    AND rc.politician_id IN ('c7f357ce-2fa0-4760-921b-905ff6a63944','26636234-c292-4a02-8205-6b84f6864f82');
  IF v_lost<>0 THEN RAISE EXCEPTION 'FAIL: Goldman/Espaillat have % active rows', v_lost; END IF;

  SELECT count(*) INTO v_lander FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id WHERE r.election_id=ny_eid AND d.geo_id='3610' AND rc.candidate_status='active' AND lower(rc.full_name)='brad lander';
  SELECT count(*) INTO v_cohen FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id WHERE r.election_id=ny_eid AND d.geo_id='3613' AND rc.candidate_status='active' AND lower(rc.full_name)='bob cohen';
  SELECT count(*) INTO v_smullen FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id WHERE r.election_id=ny_eid AND d.geo_id='3621' AND rc.candidate_status='active' AND lower(rc.full_name)='robert smullen';
  IF v_lander<>1 OR v_cohen<>1 OR v_smullen<>1 THEN RAISE EXCEPTION 'FAIL: winner/minor missing (Lander=%, Cohen=%, Smullen=%)', v_lander, v_cohen, v_smullen; END IF;

  RAISE NOTICE 'OK: 26 NY races, % active candidates, 0 null pid, 0 dup, Goldman/Espaillat absent, Lander/Cohen/Smullen active', v_active;
END $$;

COMMIT;
