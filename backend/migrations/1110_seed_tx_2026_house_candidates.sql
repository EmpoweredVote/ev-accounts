-- Migration 1110: Seed Nov 3 2026 TX US House general-election candidates (race_candidates + new politicians)
--
-- Phase 150-03 (v2.20). Wires the full Nov-3 general field onto the 38 TX US House races authored
-- in migration 1109 (TX 2026 Statewide General, 783b7506-...). 48 genuinely-new candidates get new
-- politician records (external_id band -(4810000 + cd*100 + seq), band -4810000..-4819999 verified
-- empty 2026-06-29); every incumbent / previously-seeded figure REUSES its existing politician_id.
--
-- Field source: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md
-- (per-district Wikipedia 2026_..._Texas URLs, cited per row in race_candidates.source).
-- Reconciliation (live reuse-vs-new per candidate): backend/data/seed-tx-2026-house/150-03-tx-reconciliation.csv
-- (76 rows = 48 NEW + 28 REUSE; all REUSE targets live-confirmed active 2026-06-29).
--
-- ANTIPARTISAN INVARIANT (D-05): party is NOT stored on race_candidates; it lives on races.primary_party
-- (NULL here). Party in the reconciliation/field is read only to determine the ballot field.
--
-- D-03 reuse (live-confirmed, NOT inferred):
--   Greg Casar (TX-35 incumbent -100335) is the active TX-37 candidate (is_incumbent=false); TX-35's
--     own field (Johnny Garcia / Carlos De La Cruz) is all-new and Casar has NO active row in TX-35.
--   Steve Toth (-100515, existing TX state-rep record) is the active TX-2 candidate (Crenshaw lost primary,
--     gets no active row).
--   Dan Barrios (e8c863a7-..., existing Richardson TX city-council record) IS the TX-32 Democratic nominee
--     (same person — Richardson councilmember; confirmed via Ballotpedia/news 2026-06-29). REUSE, not a new dup.
--   Colin Allred is genuinely NEW (live DB returned 0 matching records — the CONTEXT "2024 Senate record"
--     guess was FALSE; confirms the D-03 mandate). "Trever Nehls" in the field is a typo for renominated
--     incumbent Troy Nehls (-100322) -> REUSE.
--
-- Lost/retired/redistricted-away TX incumbents get NO active row in their old seat: TX-2 Crenshaw (lost),
--   TX-8/10/19/21/37/38 (retired), TX-9 Green / TX-30 Crockett / TX-32 Johnson / TX-33 Veasey
--   (redistricted-away; absent from every 2026 TX field), TX-35 Casar (runs TX-37). TX-23 open-seat
--   vacancy: both candidates new.
--
-- Idempotent: NOT EXISTS guards on (external_id) for politicians and (race_id, full_name) for
-- race_candidates (no DB unique constraint -- application-enforced). A re-run inserts 0 rows.
-- Scoped to the 38 NATIONAL_LOWER TX House races; never touches races rows; never office_id NULL;
-- never creates an essentials.offices row for a challenger (feed resolves via race_candidates.politician_id).

BEGIN;

-- 1. Insert the 48 genuinely-new TX House candidates.
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
SELECT gen_random_uuid(), v.ext, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
(-4810101, 'Yolanda Prince', 'Yolanda', 'Prince'),
  (-4810201, 'Shaun Finnie', 'Shaun', 'Finnie'),
  (-4810301, 'Evan Hunt', 'Evan', 'Hunt'),
  (-4810401, 'Jason Pearce', 'Jason', 'Pearce'),
  (-4810501, 'Chelsey Hockett', 'Chelsey', 'Hockett'),
  (-4810601, 'Danny Minton', 'Danny', 'Minton'),
  (-4810701, 'Alexander Hale', 'Alexander', 'Hale'),
  (-4810801, 'Jessica Steinmann', 'Jessica', 'Steinmann'),
  (-4810802, 'Laura Jones', 'Laura', 'Jones'),
  (-4810901, 'Leticia Gutierrez', 'Leticia', 'Gutierrez'),
  (-4810902, 'Alex Mealer', 'Alex', 'Mealer'),
  (-4811001, 'Chris Gober', 'Chris', 'Gober'),
  (-4811002, 'Caitlin Rourk', 'Caitlin', 'Rourk'),
  (-4811101, 'Claire Reynolds', 'Claire', 'Reynolds'),
  (-4811201, 'Angela Rodriguez Prilliman', 'Angela', 'Rodriguez Prilliman'),
  (-4811301, 'Mark Nair', 'Mark', 'Nair'),
  (-4811401, 'Thurman Bartie', 'Thurman', 'Bartie'),
  (-4811501, 'Bobby Pulido', 'Bobby', 'Pulido'),
  (-4811601, 'Adam Bauman', 'Adam', 'Bauman'),
  (-4811701, 'Casey Shepard', 'Casey', 'Shepard'),
  (-4811801, 'Ronald Whitfield', 'Ronald', 'Whitfield'),
  (-4811901, 'Tom Sell', 'Tom', 'Sell'),
  (-4811902, 'Kyle Rable', 'Kyle', 'Rable'),
  (-4812001, 'Edgardo Baez', 'Edgardo', 'Baez'),
  (-4812101, 'Mark Teixeira', 'Mark', 'Teixeira'),
  (-4812102, 'Kristin Hook', 'Kristin', 'Hook'),
  (-4812201, 'Marquette Greene-Scott', 'Marquette', 'Greene-Scott'),
  (-4812301, 'Brandon Herrera', 'Brandon', 'Herrera'),
  (-4812302, 'Katy Padilla Stout', 'Katy', 'Padilla Stout'),
  (-4812401, 'Kevin Burge', 'Kevin', 'Burge'),
  (-4812501, 'Dione Sims', 'Dione', 'Sims'),
  (-4812601, 'Steven Shook', 'Steven', 'Shook'),
  (-4812701, 'Tanya Lloyd', 'Tanya', 'Lloyd'),
  (-4812801, 'Tano Tijerina', 'Tano', 'Tijerina'),
  (-4812901, 'Martha Fierro', 'Martha', 'Fierro'),
  (-4813001, 'Frederick Haynes III', 'Frederick', 'Haynes III'),
  (-4813002, 'Everett Jackson', 'Everett', 'Jackson'),
  (-4813101, 'Justin Early', 'Justin', 'Early'),
  (-4813201, 'Jace Yarbrough', 'Jace', 'Yarbrough'),
  (-4813301, 'Colin Allred', 'Colin', 'Allred'),
  (-4813302, 'Patrick Gillespie', 'Patrick', 'Gillespie'),
  (-4813401, 'Eric Flores', 'Eric', 'Flores'),
  (-4813501, 'Johnny Garcia', 'Johnny', 'Garcia'),
  (-4813502, 'Carlos De La Cruz', 'Carlos', 'De La Cruz'),
  (-4813601, 'Rhonda Hart', 'Rhonda', 'Hart'),
  (-4813701, 'Lauren Peña', 'Lauren', 'Peña'),
  (-4813801, 'Jon Bonck', 'Jon', 'Bonck'),
  (-4813802, 'Melissa McDonough', 'Melissa', 'McDonough')
) v(ext, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

-- 2. Insert the 76 race_candidates (48 new + 28 reuse) onto the 38 TX races.
INSERT INTO essentials.race_candidates (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT gen_random_uuid(), v.race_id, v.politician_id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  ('a282204e-d645-4496-9ecc-c1d7a5e1a842'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100301), 'Nathaniel Moran', 'Nathaniel', 'Moran', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_1'),
  ('a282204e-d645-4496-9ecc-c1d7a5e1a842'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810101), 'Yolanda Prince', 'Yolanda', 'Prince', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_1'),
  ('52aba312-6c76-4591-a27c-c569da854ab5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100515), 'Steve Toth', 'Steve', 'Toth', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_2'),
  ('52aba312-6c76-4591-a27c-c569da854ab5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810201), 'Shaun Finnie', 'Shaun', 'Finnie', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_2'),
  ('516d9125-674f-472e-8f41-dcbca7d74d16'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100303), 'Keith Self', 'Keith', 'Self', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_3'),
  ('516d9125-674f-472e-8f41-dcbca7d74d16'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810301), 'Evan Hunt', 'Evan', 'Hunt', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_3'),
  ('dd49e721-3905-409d-92e5-18505beacf39'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100304), 'Pat Fallon', 'Pat', 'Fallon', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_4'),
  ('dd49e721-3905-409d-92e5-18505beacf39'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810401), 'Jason Pearce', 'Jason', 'Pearce', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_4'),
  ('c09ed536-07e5-4dca-a77d-e3b636a724c4'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100305), 'Lance Gooden', 'Lance', 'Gooden', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_5'),
  ('c09ed536-07e5-4dca-a77d-e3b636a724c4'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810501), 'Chelsey Hockett', 'Chelsey', 'Hockett', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_5'),
  ('1ae3afe8-a646-4dcd-8c4c-304b8446ae8f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100306), 'Jake Ellzey', 'Jake', 'Ellzey', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_6'),
  ('1ae3afe8-a646-4dcd-8c4c-304b8446ae8f'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810601), 'Danny Minton', 'Danny', 'Minton', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_6'),
  ('4547a4e0-bed6-4be0-a866-0f6b56259cfc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100307), 'Lizzie Fletcher', 'Lizzie', 'Fletcher', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_7'),
  ('4547a4e0-bed6-4be0-a866-0f6b56259cfc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810701), 'Alexander Hale', 'Alexander', 'Hale', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_7'),
  ('857ff454-abb5-4a03-873b-4f0ada1e5477'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810801), 'Jessica Steinmann', 'Jessica', 'Steinmann', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_8'),
  ('857ff454-abb5-4a03-873b-4f0ada1e5477'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810802), 'Laura Jones', 'Laura', 'Jones', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_8'),
  ('95e43ee0-6b5f-4374-86b0-2bfc9c1e7476'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810901), 'Leticia Gutierrez', 'Leticia', 'Gutierrez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_9'),
  ('95e43ee0-6b5f-4374-86b0-2bfc9c1e7476'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4810902), 'Alex Mealer', 'Alex', 'Mealer', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_9'),
  ('350d53d9-2b4f-46e6-8aea-0e4d011f704d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811001), 'Chris Gober', 'Chris', 'Gober', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_10'),
  ('350d53d9-2b4f-46e6-8aea-0e4d011f704d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811002), 'Caitlin Rourk', 'Caitlin', 'Rourk', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_10'),
  ('820f6a52-f5d0-4a62-9838-a2d776a4e9d7'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100311), 'August Pfluger', 'August', 'Pfluger', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_11'),
  ('820f6a52-f5d0-4a62-9838-a2d776a4e9d7'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811101), 'Claire Reynolds', 'Claire', 'Reynolds', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_11'),
  ('ff027afa-9b90-40a1-b420-60f0eca83a64'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100312), 'Craig Goldman', 'Craig', 'Goldman', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_12'),
  ('ff027afa-9b90-40a1-b420-60f0eca83a64'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811201), 'Angela Rodriguez Prilliman', 'Angela', 'Rodriguez Prilliman', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_12'),
  ('a2492843-6c86-4209-9278-a235f5bbf533'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100313), 'Ronny Jackson', 'Ronny', 'Jackson', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_13'),
  ('a2492843-6c86-4209-9278-a235f5bbf533'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811301), 'Mark Nair', 'Mark', 'Nair', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_13'),
  ('5b04befe-6ecf-4483-ac2a-564778cecf22'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100314), 'Randy Weber', 'Randy', 'Weber', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_14'),
  ('5b04befe-6ecf-4483-ac2a-564778cecf22'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811401), 'Thurman Bartie', 'Thurman', 'Bartie', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_14'),
  ('7f41e478-86b6-489c-bf7d-9b4d655b8100'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100315), 'Monica De La Cruz', 'Monica', 'De La Cruz', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_15'),
  ('7f41e478-86b6-489c-bf7d-9b4d655b8100'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811501), 'Bobby Pulido', 'Bobby', 'Pulido', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_15'),
  ('8124ea17-ccb4-4b76-a4dd-3c31a493f35a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100316), 'Veronica Escobar', 'Veronica', 'Escobar', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_16'),
  ('8124ea17-ccb4-4b76-a4dd-3c31a493f35a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811601), 'Adam Bauman', 'Adam', 'Bauman', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_16'),
  ('b6c2e0bd-e4c5-459c-b505-6d60a55bc8a1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100317), 'Pete Sessions', 'Pete', 'Sessions', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_17'),
  ('b6c2e0bd-e4c5-459c-b505-6d60a55bc8a1'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811701), 'Casey Shepard', 'Casey', 'Shepard', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_17'),
  ('85a70c63-1305-45b5-9824-4f65c8b79f6a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100318), 'Christian Menefee', 'Christian', 'Menefee', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_18'),
  ('85a70c63-1305-45b5-9824-4f65c8b79f6a'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811801), 'Ronald Whitfield', 'Ronald', 'Whitfield', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_18'),
  ('aad5f023-705d-4432-9185-07d8ea0268f0'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811901), 'Tom Sell', 'Tom', 'Sell', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_19'),
  ('aad5f023-705d-4432-9185-07d8ea0268f0'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4811902), 'Kyle Rable', 'Kyle', 'Rable', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_19'),
  ('f1a24132-f288-4716-8995-08896825674d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100320), 'Joaquin Castro', 'Joaquin', 'Castro', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_20'),
  ('f1a24132-f288-4716-8995-08896825674d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812001), 'Edgardo Baez', 'Edgardo', 'Baez', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_20'),
  ('71e280a7-0ec9-4d19-80cc-7798b305a36b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812101), 'Mark Teixeira', 'Mark', 'Teixeira', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_21'),
  ('71e280a7-0ec9-4d19-80cc-7798b305a36b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812102), 'Kristin Hook', 'Kristin', 'Hook', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_21'),
  ('ef2f9063-233b-4a2a-8ded-fea5094cdc98'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100322), 'Troy Nehls', 'Troy', 'Nehls', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_22'),
  ('ef2f9063-233b-4a2a-8ded-fea5094cdc98'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812201), 'Marquette Greene-Scott', 'Marquette', 'Greene-Scott', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_22'),
  ('78fd8f9d-9ca6-473a-be0b-07d6cce916ec'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812301), 'Brandon Herrera', 'Brandon', 'Herrera', false, 'https://www.cbsnews.com/news/tony-gonzales-drops-out-of-house-runoff-race-after-admitting-affair-with-aide/'),
  ('78fd8f9d-9ca6-473a-be0b-07d6cce916ec'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812302), 'Katy Padilla Stout', 'Katy', 'Padilla Stout', false, 'https://www.cbsnews.com/news/tony-gonzales-drops-out-of-house-runoff-race-after-admitting-affair-with-aide/'),
  ('f506ed58-7ea3-4284-b891-5ee5bbaeb9dd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100324), 'Beth Van Duyne', 'Beth', 'Van Duyne', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_24'),
  ('f506ed58-7ea3-4284-b891-5ee5bbaeb9dd'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812401), 'Kevin Burge', 'Kevin', 'Burge', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_24'),
  ('d438d09a-321b-42a0-b92d-31925704a5fc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100325), 'Roger Williams', 'Roger', 'Williams', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_25'),
  ('d438d09a-321b-42a0-b92d-31925704a5fc'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812501), 'Dione Sims', 'Dione', 'Sims', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_25'),
  ('7124e03f-9f72-424b-8312-aa23564e7ef8'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100326), 'Brandon Gill', 'Brandon', 'Gill', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_26'),
  ('7124e03f-9f72-424b-8312-aa23564e7ef8'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812601), 'Steven Shook', 'Steven', 'Shook', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_26'),
  ('b56bcde8-0686-4970-a05b-4234477f32b8'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100327), 'Michael Cloud', 'Michael', 'Cloud', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_27'),
  ('b56bcde8-0686-4970-a05b-4234477f32b8'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812701), 'Tanya Lloyd', 'Tanya', 'Lloyd', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_27'),
  ('bfaf1f49-e9a6-46df-b6af-9b632f43da66'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100328), 'Henry Cuellar', 'Henry', 'Cuellar', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_28'),
  ('bfaf1f49-e9a6-46df-b6af-9b632f43da66'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812801), 'Tano Tijerina', 'Tano', 'Tijerina', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_28'),
  ('7e2bfe3b-81c9-4114-b751-b81449df488d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100329), 'Sylvia Garcia', 'Sylvia', 'Garcia', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_29'),
  ('7e2bfe3b-81c9-4114-b751-b81449df488d'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4812901), 'Martha Fierro', 'Martha', 'Fierro', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_29'),
  ('c7bc3023-6936-42da-a618-3f683f4c8a3b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813001), 'Frederick Haynes III', 'Frederick', 'Haynes III', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_30'),
  ('c7bc3023-6936-42da-a618-3f683f4c8a3b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813002), 'Everett Jackson', 'Everett', 'Jackson', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_30'),
  ('06d2ed59-b6bc-4907-91f7-a85a91e6b27b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100331), 'John Carter', 'John', 'Carter', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_31'),
  ('06d2ed59-b6bc-4907-91f7-a85a91e6b27b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813101), 'Justin Early', 'Justin', 'Early', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_31'),
  ('2f07eaa0-2f9e-4386-906a-7c40dc2c25c4'::uuid, 'e8c863a7-d116-480e-a81f-47d26f45e264'::uuid, 'Dan Barrios', 'Dan', 'Barrios', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_32'),
  ('2f07eaa0-2f9e-4386-906a-7c40dc2c25c4'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813201), 'Jace Yarbrough', 'Jace', 'Yarbrough', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_32'),
  ('38114e7e-e713-4ad8-a402-2688b2a2f33b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813301), 'Colin Allred', 'Colin', 'Allred', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_33'),
  ('38114e7e-e713-4ad8-a402-2688b2a2f33b'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813302), 'Patrick Gillespie', 'Patrick', 'Gillespie', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_33'),
  ('402a28dd-b59b-420a-b9e9-8e0a4b5fcced'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100334), 'Vicente Gonzalez', 'Vicente', 'Gonzalez', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_34'),
  ('402a28dd-b59b-420a-b9e9-8e0a4b5fcced'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813401), 'Eric Flores', 'Eric', 'Flores', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_34'),
  ('77f914d0-4143-42ae-ac11-e2f6f8f3dd86'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813501), 'Johnny Garcia', 'Johnny', 'Garcia', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_35'),
  ('77f914d0-4143-42ae-ac11-e2f6f8f3dd86'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813502), 'Carlos De La Cruz', 'Carlos', 'De La Cruz', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_35'),
  ('75502a2a-dc2b-4fa6-93c4-e4afb498b7ab'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100336), 'Brian Babin', 'Brian', 'Babin', true, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_36'),
  ('75502a2a-dc2b-4fa6-93c4-e4afb498b7ab'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813601), 'Rhonda Hart', 'Rhonda', 'Hart', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_36'),
  ('7a69ab9f-2b15-48cf-b407-9b7b1de207a5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-100335), 'Greg Casar', 'Greg', 'Casar', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_37'),
  ('7a69ab9f-2b15-48cf-b407-9b7b1de207a5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813701), 'Lauren Peña', 'Lauren', 'Peña', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_37'),
  ('7ff2347a-c959-4da8-bfd1-af816ad2e5d5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813801), 'Jon Bonck', 'Jon', 'Bonck', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_38'),
  ('7ff2347a-c959-4da8-bfd1-af816ad2e5d5'::uuid, (SELECT id FROM essentials.politicians WHERE external_id=-4813802), 'Melissa McDonough', 'Melissa', 'McDonough', false, 'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_38')
) v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id AND rc.full_name = v.full_name
);

-- 3. Post-write assertions (TX NATIONAL_LOWER geo '48' within TX 2026 Statewide General).
DO $$
DECLARE
  v_races int; v_nullpid int; v_dup int; v_casar int; v_crenshaw int; v_active int;
  tx_eid uuid;
BEGIN
  SELECT id INTO tx_eid FROM essentials.elections WHERE name='TX 2026 Statewide General';
  SELECT count(DISTINCT r.id),
         count(*) FILTER (WHERE rc.candidate_status='active' AND rc.politician_id IS NULL),
         count(*) FILTER (WHERE rc.candidate_status='active')
    INTO v_races, v_nullpid, v_active
  FROM essentials.races r
  JOIN essentials.offices o ON o.id=r.office_id
  JOIN essentials.districts d ON d.id=o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id=r.id
  WHERE r.election_id=tx_eid AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='48';
  IF v_races<>38 THEN RAISE EXCEPTION 'FAIL: expected 38 TX races, got %', v_races; END IF;
  IF v_nullpid<>0 THEN RAISE EXCEPTION 'FAIL: % active TX rows with NULL politician_id', v_nullpid; END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT lower(rc.full_name) FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
    WHERE r.election_id=tx_eid AND d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2)='48'
      AND rc.candidate_status='active'
    GROUP BY lower(rc.full_name) HAVING count(*)>1) q;
  IF v_dup<>0 THEN RAISE EXCEPTION 'FAIL: % duplicate full_name within TX', v_dup; END IF;

  SELECT count(*) INTO v_casar FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id=rc.race_id
  JOIN essentials.offices o ON o.id=r.office_id
  JOIN essentials.districts d ON d.id=o.district_id
  WHERE r.election_id=tx_eid AND d.geo_id='4837' AND rc.candidate_status='active'
    AND rc.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100335);
  IF v_casar<>1 THEN RAISE EXCEPTION 'FAIL: Greg Casar not active in TX-37 (got %)', v_casar; END IF;

  SELECT count(*) INTO v_crenshaw FROM essentials.race_candidates rc
  WHERE rc.candidate_status='active'
    AND rc.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-100302);
  IF v_crenshaw<>0 THEN RAISE EXCEPTION 'FAIL: Crenshaw (lost) has % active rows', v_crenshaw; END IF;

  RAISE NOTICE 'OK: 38 TX races, % active candidates, 0 null pid, 0 dup, Casar active TX-37, Crenshaw absent', v_active;
END $$;

COMMIT;
