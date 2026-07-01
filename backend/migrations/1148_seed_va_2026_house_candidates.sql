-- 1148_seed_va_2026_house_candidates.sql
-- Phase 159-03: 46 new VA politicians + 58 active race_candidates onto the
--   11 EXISTING VA U.S. House races (2026 Virginia General Election; races NOT created here).
-- Field: Wikipedia 2026 VA US House (raw) + Ballotpedia Aug-4 primary pages, cross-checked
--   vademocrats/VPAP/politics1. Withdrawn candidates excluded; declared indep/3rd-party seeded
--   PROVISIONAL (VA filing deadline 2026-08-04) -> reconciled in Phase 159-05.
-- ANTIPARTISAN: party never stored on race_candidates; races.primary_party untouched.
-- INCUMBENT REUSE (all 11), incl. Walkinshaw -5102011 (single record, NOT duplicated). NOTE: the
--   VA-5/6/9 incumbent records carry rotated external_ids vs district (pre-existing DB office-link
--   bug) — we wire the TRUE incumbent per district: VA-5 McGuire(-5102009), VA-6 Cline(-5102005),
--   VA-9 Griffith(-5102006). Office-link rotation flagged as a separate carry-forward.
BEGIN;

-- Add PROVISIONAL marker to the 11 existing VA races (description-only; office_id/election_id untouched)
UPDATE essentials.races r
SET description = 'PROVISIONAL: pre-primary qualified field, cull >= 2026-08-05'
WHERE r.id IN ('65dd3477-4828-43de-adb5-9b621d08b43e'::uuid,'73a46730-61f8-4e35-90d7-20c11016865e'::uuid,'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid,'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid,'6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid,'807d0f7c-6bb7-4810-b120-ec241eadef42'::uuid,'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid,'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid,'da51cdee-de79-4186-baab-033308f251fe'::uuid,'3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid,'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid)
  AND (r.description IS NULL OR r.description NOT LIKE 'PROVISIONAL:%');

-- 46 new challenger/indep records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510101, 'Salaam Bhatti', 'Salaam', 'Bhatti', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510102, 'Elizabeth Beggs', 'Elizabeth', 'Beggs', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510103, 'Tim Cywinski', 'Tim', 'Cywinski', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510104, 'Jason Knapp', 'Jason', 'Knapp', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510104);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510105, 'Ericka Kopp', 'Ericka', 'Kopp', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510105);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510106, 'Shannon Taylor', 'Shannon', 'Taylor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510106);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510107, 'Mel Tull', 'Mel', 'Tull', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510107);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510201, 'Elaine Luria', 'Elaine', 'Luria', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510201);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510202, 'Nila Devanath', 'Nila', 'Devanath', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510202);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510203, 'Bill Fleming', 'Bill', 'Fleming', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510203);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510204, 'Patrick Mosolf', 'Patrick', 'Mosolf', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510204);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510205, 'Makiba Gaines', 'Makiba', 'Gaines', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510205);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510206, 'Bishop Staten', 'Bishop', 'Staten', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510206);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510301, 'Edwin Rivera', 'Edwin', 'Rivera', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510302, 'James "Zeb" Taylor', 'James', '"Zeb" Taylor', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510302);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510401, 'Andre Kersey', 'Andre', 'Kersey', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510402, 'Jason Brown II', 'Jason', 'Brown II', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510501, 'Tom Perriello', 'Tom', 'Perriello', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510502, 'Suzanne Krzyzanowski', 'Suzanne', 'Krzyzanowski', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510503, 'Robert Tracinski', 'Robert', 'Tracinski', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510503);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510504, 'Melanie Lucero', 'Melanie', 'Lucero', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510504);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510505, 'Bob Good', 'Bob', 'Good', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510505);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510506, 'Chris Register', 'Chris', 'Register', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510506);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510601, 'Beth Macy', 'Beth', 'Macy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510701, 'Philip Harding', 'Philip', 'Harding', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510701);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510702, 'Doug Ollivant', 'Doug', 'Ollivant', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510702);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510703, 'Ricky Smithers', 'Ricky', 'Smithers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510703);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510704, 'Randall Terry', 'Randall', 'Terry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510704);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510801, 'Lorena Bruner', 'Lorena', 'Bruner', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510802, 'Michael Duffin', 'Michael', 'Duffin', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510803, 'Adam Dunigan', 'Adam', 'Dunigan', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510803);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510804, 'Mo Seifeldein', 'Mo', 'Seifeldein', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510804);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510805, 'Tony Sabio', 'Tony', 'Sabio', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510805);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510901, 'Douglas Crockett', 'Douglas', 'Crockett', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510901);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510902, 'Brandi Hall', 'Brandi', 'Hall', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510902);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510903, 'Adam Murphy', 'Adam', 'Murphy', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510903);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510904, 'Joy Powers', 'Joy', 'Powers', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510904);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510905, 'Brandon Cook', 'Brandon', 'Cook', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510905);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -510906, 'Michael Jackson', 'Michael', 'Jackson', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -510906);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511001, 'Dave Beckwith', 'Dave', 'Beckwith', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511001);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511002, 'Julie Perry', 'Julie', 'Perry', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511002);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511003, 'Anthony Suttles', 'Anthony', 'Suttles', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511003);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511101, 'Bree Fram', 'Bree', 'Fram', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511102, 'Amy Roma', 'Amy', 'Roma', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511103, 'Nathan Headrick', 'Nathan', 'Headrick', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511103);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -511104, 'Michael Van Meter', 'Michael', 'Van Meter', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -511104);

-- 58 active race_candidates onto existing VA races (11 incumbents reused + 46 new)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Rob Wittman', 'Rob', 'Wittman', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102001
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Rob Wittman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Salaam Bhatti', 'Salaam', 'Bhatti', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Salaam Bhatti'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Elizabeth Beggs', 'Elizabeth', 'Beggs', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510102
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Elizabeth Beggs'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Tim Cywinski', 'Tim', 'Cywinski', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510103
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Tim Cywinski'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Jason Knapp', 'Jason', 'Knapp', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510104
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Jason Knapp'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Ericka Kopp', 'Ericka', 'Kopp', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510105
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Ericka Kopp'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Shannon Taylor', 'Shannon', 'Taylor', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510106
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Shannon Taylor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid, p.id, 'Mel Tull', 'Mel', 'Tull', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510107
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '65dd3477-4828-43de-adb5-9b621d08b43e'::uuid AND lower(rc.full_name) = lower('Mel Tull'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Jen Kiggans', 'Jen', 'Kiggans', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102002
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Jen Kiggans'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Elaine Luria', 'Elaine', 'Luria', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510201
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Elaine Luria'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Nila Devanath', 'Nila', 'Devanath', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510202
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Nila Devanath'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Bill Fleming', 'Bill', 'Fleming', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510203
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Bill Fleming'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Patrick Mosolf', 'Patrick', 'Mosolf', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510204
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Patrick Mosolf'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Makiba Gaines', 'Makiba', 'Gaines', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510205
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Makiba Gaines'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '73a46730-61f8-4e35-90d7-20c11016865e'::uuid, p.id, 'Bishop Staten', 'Bishop', 'Staten', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510206
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '73a46730-61f8-4e35-90d7-20c11016865e'::uuid AND lower(rc.full_name) = lower('Bishop Staten'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid, p.id, 'Bobby Scott', 'Bobby', 'Scott', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102003
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid AND lower(rc.full_name) = lower('Bobby Scott'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid, p.id, 'Edwin Rivera', 'Edwin', 'Rivera', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510301
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid AND lower(rc.full_name) = lower('Edwin Rivera'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid, p.id, 'James "Zeb" Taylor', 'James', '"Zeb" Taylor', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510302
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'ae5bfa0e-f5da-4fd1-bf69-d07db17a48ee'::uuid AND lower(rc.full_name) = lower('James "Zeb" Taylor'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid, p.id, 'Jennifer McClellan', 'Jennifer', 'McClellan', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102004
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid AND lower(rc.full_name) = lower('Jennifer McClellan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid, p.id, 'Andre Kersey', 'Andre', 'Kersey', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510401
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid AND lower(rc.full_name) = lower('Andre Kersey'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid, p.id, 'Jason Brown II', 'Jason', 'Brown II', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510402
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'a48dfb93-6c36-40b0-8f92-c28c6159c9f9'::uuid AND lower(rc.full_name) = lower('Jason Brown II'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'John McGuire', 'John', 'McGuire', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102009
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('John McGuire'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Tom Perriello', 'Tom', 'Perriello', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510501
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Tom Perriello'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Suzanne Krzyzanowski', 'Suzanne', 'Krzyzanowski', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510502
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Suzanne Krzyzanowski'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Robert Tracinski', 'Robert', 'Tracinski', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510503
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Robert Tracinski'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Melanie Lucero', 'Melanie', 'Lucero', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510504
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Melanie Lucero'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Bob Good', 'Bob', 'Good', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510505
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Bob Good'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid, p.id, 'Chris Register', 'Chris', 'Register', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510506
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '6a1bf3a1-3fc7-4997-9e67-7d9736e03ffe'::uuid AND lower(rc.full_name) = lower('Chris Register'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '807d0f7c-6bb7-4810-b120-ec241eadef42'::uuid, p.id, 'Ben Cline', 'Ben', 'Cline', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102005
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '807d0f7c-6bb7-4810-b120-ec241eadef42'::uuid AND lower(rc.full_name) = lower('Ben Cline'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '807d0f7c-6bb7-4810-b120-ec241eadef42'::uuid, p.id, 'Beth Macy', 'Beth', 'Macy', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510601
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '807d0f7c-6bb7-4810-b120-ec241eadef42'::uuid AND lower(rc.full_name) = lower('Beth Macy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid, p.id, 'Eugene Vindman', 'Eugene', 'Vindman', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102007
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid AND lower(rc.full_name) = lower('Eugene Vindman'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid, p.id, 'Philip Harding', 'Philip', 'Harding', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510701
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid AND lower(rc.full_name) = lower('Philip Harding'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid, p.id, 'Doug Ollivant', 'Doug', 'Ollivant', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510702
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid AND lower(rc.full_name) = lower('Doug Ollivant'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid, p.id, 'Ricky Smithers', 'Ricky', 'Smithers', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510703
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid AND lower(rc.full_name) = lower('Ricky Smithers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid, p.id, 'Randall Terry', 'Randall', 'Terry', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510704
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'b9e08170-8918-4bf6-a57c-f0ba5f4dabde'::uuid AND lower(rc.full_name) = lower('Randall Terry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Don Beyer', 'Don', 'Beyer', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102008
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Don Beyer'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Lorena Bruner', 'Lorena', 'Bruner', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510801
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Lorena Bruner'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Michael Duffin', 'Michael', 'Duffin', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510802
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Michael Duffin'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Adam Dunigan', 'Adam', 'Dunigan', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510803
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Adam Dunigan'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Mo Seifeldein', 'Mo', 'Seifeldein', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510804
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Mo Seifeldein'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid, p.id, 'Tony Sabio', 'Tony', 'Sabio', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510805
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df4895e9-81e6-4392-ab40-18105ddacf7c'::uuid AND lower(rc.full_name) = lower('Tony Sabio'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Morgan Griffith', 'Morgan', 'Griffith', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102006
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Morgan Griffith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Douglas Crockett', 'Douglas', 'Crockett', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510901
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Douglas Crockett'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Brandi Hall', 'Brandi', 'Hall', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510902
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Brandi Hall'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Adam Murphy', 'Adam', 'Murphy', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510903
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Adam Murphy'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Joy Powers', 'Joy', 'Powers', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510904
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Joy Powers'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Brandon Cook', 'Brandon', 'Cook', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -510905
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Brandon Cook'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'da51cdee-de79-4186-baab-033308f251fe'::uuid, p.id, 'Michael Jackson', 'Michael', 'Jackson', false, 'active', 'Declared indep/3rd-party (Wikipedia/politics1); provisional — VA filing deadline 2026-08-04'
FROM essentials.politicians p
WHERE p.external_id = -510906
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'da51cdee-de79-4186-baab-033308f251fe'::uuid AND lower(rc.full_name) = lower('Michael Jackson'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid, p.id, 'Suhas Subramanyam', 'Suhas', 'Subramanyam', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102010
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid AND lower(rc.full_name) = lower('Suhas Subramanyam'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid, p.id, 'Dave Beckwith', 'Dave', 'Beckwith', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511001
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid AND lower(rc.full_name) = lower('Dave Beckwith'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid, p.id, 'Julie Perry', 'Julie', 'Perry', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511002
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid AND lower(rc.full_name) = lower('Julie Perry'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid, p.id, 'Anthony Suttles', 'Anthony', 'Suttles', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511003
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3fccc125-a310-4624-aff6-05f8b54bf7cd'::uuid AND lower(rc.full_name) = lower('Anthony Suttles'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'James Walkinshaw', 'James', 'Walkinshaw', true, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5102011
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('James Walkinshaw'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'Bree Fram', 'Bree', 'Fram', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('Bree Fram'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'Stella Pekarsky', 'Stella', 'Pekarsky', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -5110036
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('Stella Pekarsky'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'Amy Roma', 'Amy', 'Roma', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511102
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('Amy Roma'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'Nathan Headrick', 'Nathan', 'Headrick', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511103
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('Nathan Headrick'));
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid, p.id, 'Michael Van Meter', 'Michael', 'Van Meter', false, 'active', 'Wikipedia 2026 VA US House + Ballotpedia (Aug-4 primary), cross-checked vademocrats/VPAP'
FROM essentials.politicians p
WHERE p.external_id = -511104
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e'::uuid AND lower(rc.full_name) = lower('Michael Van Meter'));

COMMIT;
