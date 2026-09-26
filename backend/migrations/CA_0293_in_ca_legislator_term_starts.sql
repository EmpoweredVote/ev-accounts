BEGIN;

-- =============================================================================
-- CA_0293: office_terms.term_start for seated Indiana and California state legislators
--          (term-date roster pilot, 2026-09-25)
-- =============================================================================
-- Before: every seated member of the IN Senate (50), IN House (100), CA Senate (40) and CA Assembly
-- (79) had an open-ended office_terms row with term_start NULL, start_precision 'unknown' (the ADR 0002
-- phase-2 backfill). The codebook CONFIRM step needs the tenure start to check pre-seating and the
-- statement cycle, so every row from these seats failed with `dates-imprecise`.
--
-- Method (backend/scripts/term-dates-openstates.ts + scripts/lib/termStartRules.ts):
--   1. Candidate = start of the member's unbroken tenure in THIS seat (same chamber + district) from the
--      OpenStates `people` dataset (github.com/openstates/people @ bf4caf1, 2026-09-24). A role in
--      another district (redistricting) is a different seat, so e.g. Durazo SD26 starts 2022-12-05.
--   2. Legal rule: the date must equal the day the state's own law fixes for a term to begin —
--      IN: the day after the general election (IN Const. art. 4 §3);
--      CA: the first Monday in December (CA Const. art. IV §2(a)).
--      Match → start_precision 'day'. No match (a vacancy fill: IN caucus selection, CA special
--      election) → the YEAR only, start_precision 'year' ("Don't invent dates", CLAUDE.md).
--   3. Identity: our seat holder's surname must equal the OpenStates holder AND the chamber's official
--      roster read on 2026-09-25 (senate.ca.gov/senators, assembly.ca.gov/assemblymembers,
--      iga.in.gov/legislative/2026/legislators). Saved in backend/data/term-dates/official/.
--   Proposal files: backend/data/term-dates/2026-09-25-{IN,CA}-proposal.json.
--
-- Writes 267 rows: 219 at 'day' precision, 48 at 'year' precision (the 'year' rows are vacancy fills a
-- person may later refine to the exact day from the official record). Only rows still NULL/'unknown'
-- are touched, by term id AND (office, politician) — idempotent, and a seat that changed hands since the
-- proposal is skipped by the post-verify count, not overwritten.
--
-- Held back (left 'unknown'; each needs a person):
--   IN Indiana State Senate district 41: Greg Walker — no-current-role-start
--   CA California State Senate district 10: Aisha Wahab — openstates-holders-0; official-roster-absent
--   ⚠ CA SD10 (Aisha Wahab) is on no official roster and has no current OpenStates holder: our seat
--     is probably stale. NOT touched here.
--
-- Narrowing an open-ended range (NULL start → a date) can only remove overlap, never add it, so the
-- office_terms_no_overlap exclusion constraint cannot fail on this UPDATE.
-- The source note deliberately does NOT contain "| unverified" (office_holders_as_of skips those).
-- =============================================================================

CREATE TEMP TABLE ca0293_terms (term_id uuid, office_id uuid, politician_id uuid, term_start date,
  start_precision text, state text, full_name text, district text, openstates_start date) ON COMMIT DROP;
INSERT INTO ca0293_terms VALUES
  ('11592fda-56c5-4f9e-8b08-b0d9a3880ec1'::uuid, '13d4f894-0117-404f-b9e0-b6759ab3366b'::uuid, '8c12dbdc-8afa-409a-8681-928c2e23e93e'::uuid, DATE '2020-01-01', 'year', 'IN', 'Robert B Johnson', '100', DATE '2020-06-27'),
  ('c2bb5281-71a7-4894-82f0-772fa3e0cf23'::uuid, '30451f34-837d-4474-96b2-b75dfc37f7ad'::uuid, '6882686d-8db8-445c-9a5c-8f85f0c1ad5e'::uuid, DATE '2014-11-05', 'day', 'IN', 'Bruce Borders', '45', DATE '2014-11-05'),
  ('5da192a1-7753-4ab7-a0b4-c0ae4b840db5'::uuid, '445584b2-cff8-4040-941f-9c6df1e53037'::uuid, '77261f08-6172-4a58-a5d6-446c2b84a50e'::uuid, DATE '2010-01-01', 'year', 'IN', 'Bob Heaton', '46', DATE '2010-11-16'),
  ('f06644ad-fdf8-46a3-a910-e0627f6e6c63'::uuid, '4e827459-027f-4998-b86d-c01355c44ed8'::uuid, 'f84421ea-eb49-44c3-a6a7-a3cfaf5dc745'::uuid, DATE '2012-11-07', 'day', 'IN', 'Peggy Mayfield', '60', DATE '2012-11-07'),
  ('63ce3d19-c75c-40db-9628-ced2c6d97438'::uuid, '7b3f68ef-bd9b-4316-9e39-89091b6e9aa1'::uuid, '72dd5219-490f-48bb-986e-183a6098d602'::uuid, DATE '2002-01-01', 'year', 'IN', 'Matt Pierce', '61', DATE '2002-01-09'),
  ('25d4feef-8fef-46ba-b6d3-90b28717cddc'::uuid, '847135b4-5bd6-46e2-87e4-41bd792097bd'::uuid, 'e971c7f2-3ab2-483d-97a4-7fe919365f98'::uuid, DATE '2022-11-09', 'day', 'IN', 'Dave Hall', '62', DATE '2022-11-09'),
  ('d912ea42-37a9-4fbc-9f36-0cd41ecebdbd'::uuid, '705ce366-6fb8-45f1-8424-a37725c1d704'::uuid, 'c2f7b661-b9cc-4fc4-929e-6d5c776d0f17'::uuid, DATE '2017-01-01', 'year', 'IN', 'Shane M Lindauer', '63', DATE '2017-11-16'),
  ('87713090-cbd3-4292-a6fc-819a95ac02c6'::uuid, 'a12f17df-3933-420d-9c5c-11b7793c4599'::uuid, '8e050c00-d5d8-447a-8a50-3af1688c7aea'::uuid, DATE '2016-11-09', 'day', 'IN', 'Chris D May', '65', DATE '2016-11-09'),
  ('43f90a3d-bced-4b2b-af51-80a46fe58478'::uuid, 'ac2f22a0-3a86-4508-b76f-34a806c9a652'::uuid, '4357b09a-6018-4e61-9147-23a0a184fa67'::uuid, DATE '1992-11-04', 'day', 'IN', 'Gregory W Porter', '96', DATE '1992-11-04'),
  ('1abc79b3-9a30-4bd6-9e0b-3974f9e8ab5c'::uuid, '1932e535-0be6-44d6-a9d7-40c4124fe38e'::uuid, '3b8cd30f-9602-4669-b93a-f8bc582aa4cd'::uuid, DATE '2012-11-07', 'day', 'IN', 'Justin Moed', '97', DATE '2012-11-07'),
  ('b205ae1a-b016-4671-a937-b2587158ba72'::uuid, '242e6a92-b4cd-4e4f-b61e-1b18990d5195'::uuid, 'be502033-c0b7-42b7-be14-5e41bdd4532f'::uuid, DATE '2012-11-07', 'day', 'IN', 'Robin Shackleford', '98', DATE '2012-11-07'),
  ('e545ff6b-0661-42e4-82a6-851d241e5426'::uuid, 'c172a8a8-d8e6-4493-a519-ae9fd5b33810'::uuid, '7427f323-978d-4f43-9c00-6cd976647f9b'::uuid, DATE '1991-01-01', 'year', 'IN', 'Vanessa J Summers', '99', DATE '1991-06-07'),
  ('f34cb351-9cd4-49eb-9773-602ef02627b7'::uuid, '1d513f84-c4c6-4ca0-9da4-fe746635faf4'::uuid, '9ec5d907-b5d8-4f16-8379-703f748b58e0'::uuid, DATE '2018-11-07', 'day', 'IN', 'Carolyn Jackson', '1', DATE '2018-11-07'),
  ('b98591ca-ba3e-42b4-968c-8e364b5d1aa2'::uuid, '6a40aa09-e0dc-4260-a5f9-dee035cf1e9b'::uuid, 'bda78cce-1711-433e-bdc3-83aa364c1fd2'::uuid, DATE '2008-11-05', 'day', 'IN', 'Chuck Moseley', '10', DATE '2008-11-05'),
  ('120fc2a7-2505-459e-8bdb-68b524d20a0e'::uuid, '75504657-4a6b-454b-a043-e746b9b2cf71'::uuid, '36b039a6-2224-4b73-90b4-2de142d16183'::uuid, DATE '2014-11-05', 'day', 'IN', 'Mike Aylesworth', '11', DATE '2014-11-05'),
  ('b0a81cea-efba-4d78-8dec-4168dd91b7cd'::uuid, '515351ae-3574-453f-8431-5ad90c7fcdeb'::uuid, '4a12bdcb-e722-426e-b2e7-338acac23f40'::uuid, DATE '2020-11-04', 'day', 'IN', 'Mike Andrade', '12', DATE '2020-11-04'),
  ('4cd71b6a-3bfb-4add-88de-2bff1e923770'::uuid, '40fd1fe1-8e53-4868-905c-4f8182751323'::uuid, 'e469d4ca-dcc0-4e2a-8cd2-d8e7bed54a3b'::uuid, DATE '2024-11-06', 'day', 'IN', 'Matt Commons', '13', DATE '2024-11-06'),
  ('156b559b-c4a6-4cf4-87bd-d6618fb79e86'::uuid, 'a1326c5d-561e-48ee-a882-402c75e56370'::uuid, '6c52f78a-51c2-4b1f-b91d-a0c9451f5cc2'::uuid, DATE '1990-01-01', 'year', 'IN', 'Vernon Smith', '14', DATE '1990-02-11'),
  ('87163cad-6a40-4857-b14c-d634cabff958'::uuid, 'a3a5df9a-81e0-4e63-9b23-0b1868bd0709'::uuid, '98255886-e292-47e7-bfd1-8bfe760bb460'::uuid, DATE '2020-11-04', 'day', 'IN', 'Harold Slager', '15', DATE '2020-11-04'),
  ('a14900c5-39cb-4e1b-aedb-755a605d8cd3'::uuid, '7cc3d0be-029c-4eb0-8e24-0696a5d9891e'::uuid, '634d4e4c-57e4-454d-9e40-94e6a0e46f04'::uuid, DATE '2022-11-09', 'day', 'IN', 'Kendell Culp', '16', DATE '2022-11-09'),
  ('fffcdf51-1f22-4887-a212-b96ac4262928'::uuid, '5ed89170-badd-44f1-ad7e-bbe9cefbcf65'::uuid, '45e48053-6db5-4e63-a5d7-2ad613340bd9'::uuid, DATE '2016-11-09', 'day', 'IN', 'Jack Jordan', '17', DATE '2016-11-09'),
  ('4809c38a-6dcc-47b6-9ac7-79075ee82b18'::uuid, 'f55fa8f4-d50c-4821-8a12-79f10bb169da'::uuid, '1e239b16-89e0-4a93-9724-0df547e079f3'::uuid, DATE '2022-11-09', 'day', 'IN', 'David Abbott', '18', DATE '2022-11-09'),
  ('f7ca4ba6-9c49-4e4f-b2b2-1013bc740d44'::uuid, 'd59ccbcd-abf2-4d11-89dd-c3ea056046d7'::uuid, 'befd0035-e611-4d14-9da9-227156bb2c10'::uuid, DATE '2020-11-04', 'day', 'IN', 'Julie Olthoff', '19', DATE '2020-11-04'),
  ('992b64ad-a9fb-4dfc-a730-dbfab0726fdf'::uuid, '6a758c5e-5e73-4bcd-91be-814a786c1861'::uuid, '7c19c055-65b3-4ab0-b93e-f10e06036974'::uuid, DATE '2016-11-09', 'day', 'IN', 'Earl Harris', '2', DATE '2016-11-09'),
  ('c3fdef3f-5fcb-4bc1-8ef2-76e01c3efbb2'::uuid, 'aecf921e-3e4b-41d0-afbf-53f913a8e4ed'::uuid, '9e2a7aa6-bc33-4c2d-91bb-71f766d49a2e'::uuid, DATE '2016-11-09', 'day', 'IN', 'Jim Pressel', '20', DATE '2016-11-09'),
  ('8630338d-ee0e-4b56-8ab6-157d39a3b7f3'::uuid, '92903b72-38f5-4b52-8566-f03eda881b9c'::uuid, '48f99b45-486d-4d6d-8f48-ed21a793778f'::uuid, DATE '2010-11-03', 'day', 'IN', 'Timothy Wesco', '21', DATE '2010-11-03'),
  ('8547048a-f61b-4661-9dae-d2688813a977'::uuid, 'b31e5a27-3cd0-4c1c-a635-65f330f35652'::uuid, '4c3f4c61-882e-487b-a1dc-2fafce2539de'::uuid, DATE '2022-11-09', 'day', 'IN', 'Craig Snow', '22', DATE '2022-11-09'),
  ('48eea754-379c-48ee-ace9-18e8a79b5de4'::uuid, '23035d2a-72ab-4fca-aba2-5dcb2c7aa940'::uuid, '65534e3a-7ea3-4e85-98f8-57c6c3082ad2'::uuid, DATE '2018-11-07', 'day', 'IN', 'Ethan Manning', '23', DATE '2018-11-07'),
  ('f859c7b3-f8a8-4ae3-82bd-50bd25ead9d5'::uuid, '973e4fed-bfdb-44a1-82b0-415e3c8057df'::uuid, '452300b4-c6da-4866-be08-7462421673f1'::uuid, DATE '2024-11-06', 'day', 'IN', 'Hunter Smith', '24', DATE '2024-11-06'),
  ('3e521500-3349-4d75-a1f5-e21b40373ce3'::uuid, '441a4e01-78a9-479c-a215-8ce67033a772'::uuid, '445af4b4-7d6f-4d11-8e7c-a629113604b7'::uuid, DATE '2022-11-09', 'day', 'IN', 'Becky Cash', '25', DATE '2022-11-09'),
  ('e98eebd4-2e8f-4a23-9903-7ff5d37a5d4b'::uuid, 'bcb5f62a-4c1b-4159-bb6b-d53f96daadf5'::uuid, '1c1d4016-93b8-4a97-9166-077921868027'::uuid, DATE '2018-11-07', 'day', 'IN', 'Chris Campbell', '26', DATE '2018-11-07'),
  ('6f69ec59-a880-4f57-9915-49c900a5b60c'::uuid, '179cb4e1-98e0-4858-8b21-895a337e25ea'::uuid, '4b0d1306-5004-482c-b5e4-44a6c1d542eb'::uuid, DATE '1982-01-01', 'year', 'IN', 'Sheila Klinker', '27', DATE '1982-01-05'),
  ('d078e373-9113-4870-9a4a-5f8cf560c88c'::uuid, '219c260d-1781-43a6-a04d-7567f113db2b'::uuid, '3688a87d-4b4c-400c-ab5a-52c90896ef2f'::uuid, DATE '1998-11-04', 'day', 'IN', 'Jeffrey Thompson', '28', DATE '1998-11-04'),
  ('0d9d5346-0019-4be9-aa3c-e4665502c3d0'::uuid, '743aa064-44e8-46a3-8837-a590577f4dde'::uuid, 'e0244003-7c41-48ba-863c-12cff608642b'::uuid, DATE '2024-11-06', 'day', 'IN', 'Alaina Shonkwiler', '29', DATE '2024-11-06'),
  ('a9f4d156-92e3-4159-80eb-eeefcb358f80'::uuid, '56929398-faca-44eb-920d-0bac8b3e29aa'::uuid, 'cf1be32b-b0f4-47b7-9a46-1394f65987e6'::uuid, DATE '2018-11-07', 'day', 'IN', 'Ragen Hatcher', '3', DATE '2018-11-07'),
  ('920477ce-3e87-4726-b252-6d27e3532949'::uuid, '6941c0bb-eb53-4312-b370-2d17df4fd3b7'::uuid, '9c4aa310-5706-42e8-b3f1-b5dee9b6f6fa'::uuid, DATE '2010-01-01', 'year', 'IN', 'Michael Karickhoff', '30', DATE '2010-11-02'),
  ('0447fbf0-72ad-4d1a-8777-ed066da96e44'::uuid, '8963396a-6555-4b23-9f91-88e0fdf6d213'::uuid, '1e3c9273-2989-4511-9763-a431394792de'::uuid, DATE '2023-01-01', 'year', 'IN', 'Lori Goss-reaves', '31', DATE '2023-06-01'),
  ('43ab9fcb-4ff7-4105-a5c9-9439a9bff9ee'::uuid, '02cc5466-5971-4738-b395-c914c173788a'::uuid, '7c2a4bfe-f6e1-406f-ac8c-dfc849036a83'::uuid, DATE '2022-11-09', 'day', 'IN', 'Victoria Garcia Wilburn', '32', DATE '2022-11-09'),
  ('202884b3-c283-4fcc-a5f3-55bc3e5d6993'::uuid, 'defea4d9-df33-48b2-b208-a065217ec784'::uuid, 'a2bb7489-51a4-4498-be87-ef040eae4ccf'::uuid, DATE '2018-11-07', 'day', 'IN', 'J.D. Prescott', '33', DATE '2018-11-07'),
  ('63fa2e17-e66d-4cf8-ad60-627af2833966'::uuid, 'e2318196-2db7-40d6-b8e3-142e52475926'::uuid, '627467eb-e823-4bf1-b97d-026a36d55f43'::uuid, DATE '2012-11-07', 'day', 'IN', 'Sue Errington', '34', DATE '2012-11-07'),
  ('41be7fa6-95f9-4836-b555-7f27a7282d95'::uuid, '373a204c-323f-4243-9912-1b42a67c338c'::uuid, 'd9ca3eac-f51d-4d1a-b7ae-df5249459d24'::uuid, DATE '2020-11-04', 'day', 'IN', 'Elizabeth Rowray', '35', DATE '2020-11-04'),
  ('b7900167-cb34-461d-9674-433eb367026a'::uuid, '4aec3e97-8522-40a6-8e81-588908fc20e6'::uuid, 'aa2ee278-9763-4a30-90a9-9231331ac129'::uuid, DATE '2022-11-09', 'day', 'IN', 'Kyle Pierce', '36', DATE '2022-11-09'),
  ('adca573e-3221-45b2-914d-89cc5e85175b'::uuid, 'c662f892-d685-4c9b-9461-2ca0d26e60a3'::uuid, 'd2b8e2ab-dc6b-42a9-9aea-b6b661e0476e'::uuid, DATE '2012-11-07', 'day', 'IN', 'Todd Huston', '37', DATE '2012-11-07'),
  ('42259ca9-4706-43a6-a1f0-2918bd952caf'::uuid, 'f56dead1-876c-428a-98c3-8e88e6672cfa'::uuid, '89648ec2-7768-41b2-8dfd-4e8297f3d3b2'::uuid, DATE '2010-11-03', 'day', 'IN', 'Heath VanNatter', '38', DATE '2010-11-03'),
  ('90383821-0141-4bcc-aab0-7d32aac3b99a'::uuid, 'acab121f-1cfa-44b4-bb4b-d0d6f8c06413'::uuid, 'fed420a8-8d89-48d2-bccc-62ba0a330237'::uuid, DATE '2024-11-06', 'day', 'IN', 'Danny Lopez', '39', DATE '2024-11-06'),
  ('104dc15d-8178-4c20-a424-2a7cffdb20d5'::uuid, '5f584301-def4-4b05-bba8-e017dc2273e0'::uuid, '79bb9e5a-a74a-44ef-a1c4-5b956ad36e5e'::uuid, DATE '2006-11-08', 'day', 'IN', 'Edmond Soliday', '4', DATE '2006-11-08'),
  ('824af2b5-208a-439b-9516-cb5666dcbe76'::uuid, '88ca1f76-e2b8-4f75-ad29-1e36cefa6cee'::uuid, '946f7bc2-48ed-447e-a9a5-cb99aae00b31'::uuid, DATE '2007-01-01', 'year', 'IN', 'Gregory Steuerwald', '40', DATE '2007-08-19'),
  ('31a46d06-c00a-46c6-9ab0-08e28814e271'::uuid, '6964502c-32ff-4a2e-96ca-9453cf954dda'::uuid, '6a200c04-7360-455e-b43d-f0ab2591a3cc'::uuid, DATE '2022-11-09', 'day', 'IN', 'Mark Genda', '41', DATE '2022-11-09'),
  ('d73cda6f-ecd0-41f1-95f2-ee1dc801bd25'::uuid, 'c3fc17e8-50da-4fcc-b382-717c3006cb8e'::uuid, 'd64c6b22-8a5a-41d2-b53b-c75fb57d1425'::uuid, DATE '2025-01-01', 'year', 'IN', 'Tim Yocum', '42', DATE '2025-01-16'),
  ('274c4c54-a948-4f9f-af96-39e09a74a83e'::uuid, '27e037df-c2f1-4101-8be4-a24b7290ea88'::uuid, '40200c4e-48b7-41b2-9c58-c8f2ab890ca4'::uuid, DATE '2018-11-07', 'day', 'IN', 'Tonya Pfaff', '43', DATE '2018-11-07'),
  ('03a1fa8f-f122-4eb0-bd7a-e78ccc802fcf'::uuid, '8860e485-151d-4e30-8a27-e835987407e5'::uuid, '60dec8ad-4ae4-4ff8-bf99-a4d5df5aeb7b'::uuid, DATE '2018-11-07', 'day', 'IN', 'Beau Baird', '44', DATE '2018-11-07'),
  ('4400c8b8-80e2-48da-b2f1-eb42548a537d'::uuid, 'e6adccbc-b417-48b4-82cb-e11717835642'::uuid, 'ca38dc89-dd3d-4a95-9f0f-9b5292a323e6'::uuid, DATE '2022-11-09', 'day', 'IN', 'Robb Greene', '47', DATE '2022-11-09'),
  ('6c73c4bc-de06-4b62-afb1-47cc94daf13f'::uuid, '078b0615-f813-41e8-af5f-1d0c044463dd'::uuid, 'fcad2ac3-c7e5-49a7-8452-e7c951d3be87'::uuid, DATE '2014-11-05', 'day', 'IN', 'Doug Miller', '48', DATE '2014-11-05'),
  ('7f688f22-b469-4678-9663-9eec6b58cd9f'::uuid, 'a88bbec4-49c8-41b5-a70f-2cc34b45aab8'::uuid, 'b5a9a489-0784-428a-b1ed-81fd40e07ff5'::uuid, DATE '2020-01-01', 'year', 'IN', 'Joanna King', '49', DATE '2020-12-21'),
  ('c45340b8-db99-42ae-b27e-27bc8589bf63'::uuid, '74994b69-aba7-4c30-9e2b-0ab9a4e89f54'::uuid, 'eae88f55-a772-4aa7-9bae-8bc4e6c55ced'::uuid, DATE '2012-11-07', 'day', 'IN', 'Dale Devon', '5', DATE '2012-11-07'),
  ('4738abc2-1145-4d6d-a1df-4947b14542c1'::uuid, 'e818e12c-7312-4d0e-90be-55329b9ec543'::uuid, '7683de6a-e18c-42d2-9c90-6f5fe38f6932'::uuid, DATE '2022-11-09', 'day', 'IN', 'Lorissa Sweet', '50', DATE '2022-11-09'),
  ('803adf97-1da6-47cc-9c1f-f4d2838a2402'::uuid, '25d016b7-574a-49ea-854b-3aab8f6b3a86'::uuid, 'c777bab7-48a7-4960-8a2e-bd840e62acc7'::uuid, DATE '2024-11-06', 'day', 'IN', 'Tony Isa', '51', DATE '2024-11-06'),
  ('e57125e2-0083-4d1f-9a2b-fa13e156e72b'::uuid, '620160e2-1d50-45f2-b9ab-968b6be31820'::uuid, '7dad2d17-6a9d-49ec-9b5b-621b60f929d0'::uuid, DATE '2012-11-07', 'day', 'IN', 'Ben Smaltz', '52', DATE '2012-11-07'),
  ('9e8f6b43-c91c-4ede-a8eb-5c2b0370779e'::uuid, 'ed2f07db-66dc-4a58-ad28-baf2804b359c'::uuid, 'e869ec2a-2b8e-4b1f-a725-3f8cd4a2c48a'::uuid, DATE '2024-11-06', 'day', 'IN', 'Ethan Lawson', '53', DATE '2024-11-06'),
  ('67fc1cc2-9747-46e8-bf60-b866c51389e9'::uuid, '69ecd140-ae01-40cd-a572-b7f8841ea6ec'::uuid, '95e4f47c-a7e4-48c4-8b89-016c4cf3a44a'::uuid, DATE '2022-11-09', 'day', 'IN', 'Cory Criswell', '54', DATE '2022-11-09'),
  ('e7e28e25-9547-4fd3-8740-9ccd723000e0'::uuid, '32f967b7-387c-4e9e-a59f-d83eb5d5280d'::uuid, '0408c7bf-e5f9-4754-b978-ad45e317afca'::uuid, DATE '2022-11-09', 'day', 'IN', 'Lindsay Patterson', '55', DATE '2022-11-09'),
  ('e4b331aa-27e4-48bf-b051-48cca968ef22'::uuid, '6f1c705d-0db3-47b9-b59b-3b5be294338f'::uuid, '64652750-ddd9-434f-b869-e95290d9eea4'::uuid, DATE '2018-11-07', 'day', 'IN', 'Brad Barrett', '56', DATE '2018-11-07'),
  ('8e89b0d8-6056-41f8-8e83-a1914f33cdd8'::uuid, '791af72a-df9d-4521-878c-0bba6f9fbd11'::uuid, 'a8ef5f09-5bd2-4acb-9e83-549466878901'::uuid, DATE '2022-11-09', 'day', 'IN', 'Craig Haggard', '57', DATE '2022-11-09'),
  ('4924d3d8-0fb5-42cf-9fde-59655b633836'::uuid, '582c74bf-443a-442a-9c7b-e612480c3dd4'::uuid, '2f768304-a6f6-4b5a-b41d-000727f225a1'::uuid, DATE '2020-11-04', 'day', 'IN', 'Michelle Davis', '58', DATE '2020-11-04'),
  ('5e8795db-c04b-4553-9e6e-dacece6fd70d'::uuid, '73b00623-1466-4fc0-aa6a-322a4f3a4f3d'::uuid, '217b8c85-424b-41df-aa1b-7818425623d7'::uuid, DATE '2018-11-07', 'day', 'IN', 'Ryan Lauer', '59', DATE '2018-11-07'),
  ('66673c56-9cc4-40cb-a9f1-87689b4dfa8f'::uuid, 'a6da77c3-7820-4879-807b-7dce44c92be6'::uuid, 'fd414331-30b2-4be3-93f1-54b51af4ac49'::uuid, DATE '2020-11-04', 'day', 'IN', 'Maureen Bauer', '6', DATE '2020-11-04'),
  ('ab1089b9-9622-4369-96af-39d7c0c0bd3d'::uuid, '626ec4b0-815e-4514-8db4-d9b2a94a1ba1'::uuid, 'b0862650-00c3-480e-9d92-745fdae38121'::uuid, DATE '2018-11-07', 'day', 'IN', 'Matt Hostettler', '64', DATE '2018-11-07'),
  ('0b07dfec-27d9-44e7-96e4-20927c80e056'::uuid, '87040ce2-eb81-4629-b64f-10661a85de16'::uuid, '2a4695f6-047a-46bb-82f4-c7360b97f203'::uuid, DATE '2020-11-04', 'day', 'IN', 'Zach Payne', '66', DATE '2020-11-04'),
  ('93a89beb-99ab-4867-9a09-62ae862e0169'::uuid, 'b9225ef8-b423-42bb-b254-2f3e72619dbe'::uuid, 'cc05de9f-a03a-4049-8d7f-5e4c5b0677e2'::uuid, DATE '2023-01-01', 'year', 'IN', 'Alex Zimmerman', '67', DATE '2023-07-25'),
  ('a8b4c79a-1ae2-4af7-9b77-8708f9f3f9ae'::uuid, '4333d774-b25a-4c26-905b-ca604fa8216f'::uuid, 'ea05323c-8b6d-4b16-873c-083d9873889d'::uuid, DATE '2024-11-06', 'day', 'IN', 'Garrett Bascom', '68', DATE '2024-11-06'),
  ('cf16bce2-33e3-4bdf-9cc2-388bd460d83d'::uuid, '5b1c46e1-5d4f-4a63-8dbf-e5f564863177'::uuid, 'd758604c-9dd9-4a00-ac09-90713a7bc4be'::uuid, DATE '2012-11-07', 'day', 'IN', 'Jim Lucas', '69', DATE '2012-11-07'),
  ('1819a91e-e55a-4b19-b8e9-8ab312e29408'::uuid, '6f5b8175-824f-4677-abb3-aea3d9e8b8ae'::uuid, '6ab10a36-52d6-4d7a-b039-60416eb5fd3f'::uuid, DATE '2020-11-04', 'day', 'IN', 'Jake Teshka', '7', DATE '2020-11-04'),
  ('41b49e51-1b49-4d45-a6f0-734d22aad965'::uuid, '49a53ab9-754c-4871-81be-303e29557c87'::uuid, '066daefa-0c25-447b-8a80-e4007ee3103d'::uuid, DATE '2016-11-09', 'day', 'IN', 'Karen Engleman', '70', DATE '2016-11-09'),
  ('ae104c3a-8f65-429f-8da2-93a07686ac36'::uuid, 'bfc4bd8b-8df0-4ea3-a5cb-d0cecc586a24'::uuid, '96c44dcf-92c5-432f-bd5a-f8cf641ed432'::uuid, DATE '2024-01-01', 'year', 'IN', 'Wendy Dant Chesser', '71', DATE '2024-06-04'),
  ('4b9b834c-5d9f-42bd-9603-5dbd952c2682'::uuid, '96d9e3b2-b607-4c64-bcbf-e2e0fedb0bf9'::uuid, 'f58ce6de-755d-448f-9c0c-b21f9d386dad'::uuid, DATE '2008-11-05', 'day', 'IN', 'Edward Clere', '72', DATE '2008-11-05'),
  ('5d29d310-bae2-45d9-9fb0-68e0c1e062f3'::uuid, '549fb9a7-8045-4dbc-b100-3ed3bd6aaf0d'::uuid, 'c93d27ca-26e9-46a1-a261-ed127313d43b'::uuid, DATE '2022-11-09', 'day', 'IN', 'Jennifer Meltzer', '73', DATE '2022-11-09'),
  ('e5042102-1b2b-4a21-b8ed-7295dac92c4e'::uuid, 'd6a58f53-8540-47a2-a6c7-941fcaad7d17'::uuid, 'c94874d1-e92b-4b64-8c11-d0108d935583'::uuid, DATE '2017-01-01', 'year', 'IN', 'Steve Bartels', '74', DATE '2017-11-16'),
  ('f3e43188-8eaf-479a-8a61-cf1e35273569'::uuid, '2aba2b81-d818-4611-a0e2-c78465c2cb8a'::uuid, 'cd5fc12d-8d96-41e2-97ca-e00d28b1069a'::uuid, DATE '2020-11-04', 'day', 'IN', 'Cindy Ledbetter', '75', DATE '2020-11-04'),
  ('f4918b32-cb8c-469b-8b48-8b68d94959e9'::uuid, '1881c1d5-9fd8-4080-abfe-8372d53b3213'::uuid, 'b79f38f2-02a9-4659-b4df-9e12535a2255'::uuid, DATE '2010-11-03', 'day', 'IN', 'Wendy Mcnamara', '76', DATE '2010-11-03'),
  ('3135d52c-3aa3-4efe-a410-092b54f7ebbb'::uuid, '1d472d7b-c337-495e-9b57-2e878214ee7e'::uuid, '3e91e841-173c-4b60-bff2-a53774334d6a'::uuid, DATE '2024-11-06', 'day', 'IN', 'Alex Burton', '77', DATE '2024-11-06'),
  ('60ec97e7-f659-4542-adf7-0330fa7a1e62'::uuid, 'd976b921-e513-48f7-9d7b-51f9f8d01131'::uuid, 'bba53cbb-15de-432f-9d6e-d0ab431eac15'::uuid, DATE '2021-01-01', 'year', 'IN', 'Timothy O''brien', '78', DATE '2021-03-30'),
  ('87ee4990-0e2a-4301-97e6-0c21452768cc'::uuid, '9e556e36-d300-4bef-ac90-8df64db0b849'::uuid, '4f57bead-e464-4a26-bc14-49f9599f2086'::uuid, DATE '2008-11-05', 'day', 'IN', 'Matt Lehman', '79', DATE '2008-11-05'),
  ('a3486f10-aaaa-4277-905a-96bbec32277e'::uuid, '3ee24684-c20c-42cd-821c-d126382393a0'::uuid, '25b4eea9-089e-4a33-b39b-a6a7af676ac8'::uuid, DATE '2002-11-06', 'day', 'IN', 'Ryan Dvorak', '8', DATE '2002-11-06'),
  ('8d1eb930-8b35-4c30-bc2b-77e3106cb591'::uuid, '425f1da1-b5be-4136-a2db-f66df8757370'::uuid, '3dc58f52-11b7-43f3-80ce-64e4f82a0e7a'::uuid, DATE '2006-11-08', 'day', 'IN', 'Philip Giaquinta', '80', DATE '2006-11-08'),
  ('46f17d49-2ab8-4392-8b0e-c37917fb3a44'::uuid, '5dce6f15-5023-490d-a2cc-9fb9b7f96863'::uuid, 'a9bf758c-e902-40cc-ace0-b306c63eb936'::uuid, DATE '2012-11-07', 'day', 'IN', 'Martin Carbaugh', '81', DATE '2012-11-07'),
  ('8106ff45-4bbe-4f69-92c4-08ac9b568978'::uuid, 'ee9544d6-e907-48c6-90ed-b64bbc1a24a0'::uuid, '32fbb733-d65c-457b-8ef0-f52e1701d284'::uuid, DATE '2022-11-09', 'day', 'IN', 'Kyle Miller', '82', DATE '2022-11-09'),
  ('f3206c1a-bc87-43f3-a8ef-3101db9caf99'::uuid, 'd196b6ca-a0b6-4449-99c0-67f9cbb3c9e2'::uuid, '11a19d18-3b98-4b6a-b310-9ab4aba1f7c8'::uuid, DATE '2014-01-01', 'year', 'IN', 'Chris Judy', '83', DATE '2014-09-22'),
  ('99455cd6-a6ac-4d60-8367-9a16171d4f64'::uuid, '7f3aa504-262d-4509-aabf-f2e8cac682b1'::uuid, 'fb5368e7-35c6-4ae0-b97b-b2e1fb5fb9a6'::uuid, DATE '2010-11-03', 'day', 'IN', 'Robert Morris', '84', DATE '2010-11-03'),
  ('7b7a1f7a-12bb-44b7-bf09-0302299aa0bb'::uuid, '55403296-898c-4fde-b9f0-20738e79bd37'::uuid, '25b37d28-3c79-44bc-b5ee-6ff777d43c5e'::uuid, DATE '2016-11-09', 'day', 'IN', 'Dave Heine', '85', DATE '2016-11-09'),
  ('605df6ef-d4ad-4aa3-9943-98253206c0eb'::uuid, 'fc45e925-2594-498b-9a47-0efd95003771'::uuid, '3de8d183-2323-45d5-a178-4d24b8f56702'::uuid, DATE '2008-11-05', 'day', 'IN', 'Edward Delaney', '86', DATE '2008-11-05'),
  ('42840af2-08da-4911-9b37-58e58e5c6920'::uuid, 'e8eed3c9-27ca-4518-b1b9-c422c9995656'::uuid, '4810c896-5f26-41c4-837d-f1e8f5f6dc53'::uuid, DATE '2016-11-09', 'day', 'IN', 'Carey Hamilton', '87', DATE '2016-11-09'),
  ('9333fb69-c9bb-48fe-8b30-76ed2dd58369'::uuid, 'e7d4ab8d-c4b9-40c9-a606-20de622fc1e8'::uuid, '4e30ee0d-4b36-4337-889e-7a26e1fff510'::uuid, DATE '2020-01-01', 'year', 'IN', 'Chris Jeter', '88', DATE '2020-08-26'),
  ('6c025065-d38f-4cff-b90e-e153802972c3'::uuid, '2ae7f727-9e2c-42cd-8d71-196354679fd4'::uuid, '890e2fa1-bd19-43ae-b445-c92b80496710'::uuid, DATE '2020-11-04', 'day', 'IN', 'Mitch Gore', '89', DATE '2020-11-04'),
  ('3b048638-11bf-49de-b90a-c92e3c4da76d'::uuid, 'fee6bf99-e8e9-40eb-8cbf-7d73961f160e'::uuid, '7d57b1de-6690-44fe-a995-e430a3f7748e'::uuid, DATE '2025-01-01', 'year', 'IN', 'Randy Novak', '9', DATE '2025-10-22'),
  ('50e75252-01fd-4530-9a63-951381be7f66'::uuid, 'f2d497b2-005e-4a6d-8abf-fe5459254537'::uuid, 'c68d71a3-1ed0-4f20-804e-8d39fe0930e9'::uuid, DATE '2024-11-06', 'day', 'IN', 'Andrew Ireland', '90', DATE '2024-11-06'),
  ('63b44714-6360-4750-8799-303baa5b31d5'::uuid, 'dd704aff-ea11-4e9c-a290-3debbe40671e'::uuid, '5922a7c4-65a4-46da-acb2-6df183e596b2'::uuid, DATE '1992-11-04', 'day', 'IN', 'Robert Behning', '91', DATE '1992-11-04'),
  ('db565e81-6705-4ab0-8b01-1c994d56b826'::uuid, '930591c4-4315-40a0-86e1-5e983c8283ff'::uuid, '6a849ebb-4642-409f-98fc-4a85598fdd8c'::uuid, DATE '2020-11-04', 'day', 'IN', 'Renee Pack', '92', DATE '2020-11-04'),
  ('f3cc4804-1825-4f63-9531-a0fe25ec1f32'::uuid, '724bbb31-22d9-4cda-b126-4bbea4621b75'::uuid, 'cfcb73c9-7689-4df6-b29f-0a8112af1336'::uuid, DATE '2022-11-09', 'day', 'IN', 'Julie Mcguire', '93', DATE '2022-11-09'),
  ('bf72b076-eb51-47b6-aaed-72aa6d50ee8c'::uuid, '50230e51-529e-49d8-9788-ea490ac4dae0'::uuid, '5dd4fa3d-3348-4158-8d77-3b804c095a18'::uuid, DATE '2008-01-01', 'year', 'IN', 'Cherrish Pryor', '94', DATE '2008-11-04'),
  ('569d6cb6-b099-4c72-9e8e-56b887f397ba'::uuid, 'd4f07ab0-588b-4f4c-ba31-8ab0e4a68eb9'::uuid, '9613e582-652f-43d3-a986-0d941d3d2599'::uuid, DATE '2007-01-01', 'year', 'IN', 'John Bartlett', '95', DATE '2007-12-17'),
  ('d50435e0-9bac-4716-a52a-79ab6bccc4ea'::uuid, '085054aa-8e66-46c3-a41d-18e75de7eab6'::uuid, '6b6368a1-354d-4f28-9232-a6ec70198ab8'::uuid, DATE '2008-11-05', 'day', 'IN', 'Greg Taylor', '33', DATE '2008-11-05'),
  ('028af378-cc71-41d9-97b4-5404c20e12fa'::uuid, 'd32b3477-0951-4ba6-a359-3ca744adff72'::uuid, '97c61094-b962-48b2-b6ef-de96b5f9bb7a'::uuid, DATE '2012-11-07', 'day', 'IN', 'Rodric D Bray', '37', DATE '2012-11-07'),
  ('27abb507-60cd-426e-a40f-845846c4ee81'::uuid, '0e0178dc-ea70-415a-a739-880c33e8c9db'::uuid, 'f7327a6f-1eb9-4714-9b3f-519916b436d5'::uuid, DATE '2014-11-05', 'day', 'IN', 'Eric S Bassler', '39', DATE '2014-11-05'),
  ('ff554b2e-911d-464d-8bac-f55a5ca10ddc'::uuid, '09c567c5-b19f-41d4-b113-5982ad0df4e1'::uuid, '5aa536e1-faaa-485c-b6d8-0e4d99d16361'::uuid, DATE '2020-11-04', 'day', 'IN', 'Shelli Yoder', '40', DATE '2020-11-04'),
  ('b2041384-41d4-4b84-ac3f-1b202c1dbe6a'::uuid, 'ae285450-8e0b-43d9-a534-e747ea9baf0b'::uuid, '8f1088b4-48b5-40ed-95e6-16d8dabd2d33'::uuid, DATE '2016-11-09', 'day', 'IN', 'Eric A Koch', '44', DATE '2016-11-09'),
  ('9476bb7a-a24a-4a93-a6fa-2a0cfb2c12e4'::uuid, 'f30271df-0d04-4c78-8479-1862c46a4b40'::uuid, '3def4add-c5bb-44df-95af-ea2de6899b6c'::uuid, DATE '2022-11-09', 'day', 'IN', 'Andrea Hunley', '46', DATE '2022-11-09'),
  ('d9cfd725-fcf1-49e7-9cdb-647e4dc25943'::uuid, 'f6e34822-a2f9-4dc2-a289-61df36a1a98a'::uuid, 'b2b02a48-c4e0-4acd-a4c4-b0aecbba7a18'::uuid, DATE '2022-11-09', 'day', 'IN', 'Dan Dernulc', '1', DATE '2022-11-09'),
  ('a63fb12d-fa85-4728-a80b-d2be1f05c167'::uuid, 'bc77d5bf-5cb1-4722-9cc4-1ea42f70af70'::uuid, '275cabb1-7a15-4bcf-88b5-10469a721244'::uuid, DATE '2006-11-08', 'day', 'IN', 'David Niezgodski', '10', DATE '2006-11-08'),
  ('8a541388-f02c-464e-9099-df53ed1dfdfa'::uuid, '6eb6b42c-67f9-48a4-97af-65294cc842a7'::uuid, 'fe167afd-f670-4f13-9fee-2aa3fd6d048e'::uuid, DATE '2018-11-07', 'day', 'IN', 'Linda Rogers', '11', DATE '2018-11-07'),
  ('b85901ad-aadf-4a9f-9360-c2321186ada5'::uuid, 'e75bce55-63ab-48f7-90fa-9995f8d2cf3b'::uuid, '8d0af843-f21e-4ce8-8f6f-415fc4838f22'::uuid, DATE '2016-11-09', 'day', 'IN', 'Blake Doriot', '12', DATE '2016-11-09'),
  ('b7b82695-7b2c-44a0-89f4-8bf317c0fd2f'::uuid, 'a69aeb58-995a-470a-91ab-14c448709103'::uuid, '07114859-90ed-4ce8-9a20-f5cbb81bd2e5'::uuid, DATE '2010-01-01', 'year', 'IN', 'Susan Glick', '13', DATE '2010-12-16'),
  ('6bf4a5e5-5349-4832-a318-733d8b9d7a58'::uuid, '6b016387-e968-41bc-92f2-9238d4b70427'::uuid, '162def26-1875-44f6-8f46-1ac8128ead01'::uuid, DATE '2022-11-09', 'day', 'IN', 'Tyler Johnson', '14', DATE '2022-11-09'),
  ('5197e7f6-2a9c-4e59-ae1a-b2d986474db6'::uuid, '670f8b2c-76f5-4f08-82a9-e71a423278d5'::uuid, 'cdae21e5-88a2-4c55-aaa5-abe050abf4a3'::uuid, DATE '2014-11-05', 'day', 'IN', 'Liz Brown', '15', DATE '2014-11-05'),
  ('90757c6c-d64d-4036-a1ca-f5be36277ded'::uuid, 'f05e5e52-a80c-47f4-8d5e-561d6e5730fb'::uuid, '3b65fd20-b548-4b7a-89b6-49ea5757218c'::uuid, DATE '2018-01-01', 'year', 'IN', 'Justin Busch', '16', DATE '2018-11-06'),
  ('ce0702d1-4526-4a8f-af2a-b617f585ef61'::uuid, '8d185c37-1e77-4a10-973f-1ea8559983c4'::uuid, 'c348cec4-a31b-419e-8906-1f1b4dfaaff3'::uuid, DATE '2026-01-01', 'year', 'IN', 'Nick McKinley', '17', DATE '2026-02-09'),
  ('03bc5021-b2dc-42ae-902c-5a5d0f60cb43'::uuid, '897087f2-4301-4097-8245-5ccb22a0ab51'::uuid, '250a7ae0-f130-449e-9625-4c2d1512bbf6'::uuid, DATE '2019-01-01', 'year', 'IN', 'Stacey Donato', '18', DATE '2019-09-17'),
  ('40a35e50-bbe7-4258-8947-c0558e80ab84'::uuid, '8d0b1e43-d2c5-4c83-8f73-566bc82237e0'::uuid, '8b98d8e9-c41c-4722-80de-3bc5192656ee'::uuid, DATE '2008-01-01', 'year', 'IN', 'Travis Holdman', '19', DATE '2008-04-11'),
  ('9e5d25e9-c386-4754-9ace-1cca02eab092'::uuid, '1ca10b86-0477-4f4c-9cbc-d410cece1d61'::uuid, 'e8054d02-34c2-485b-b54a-47658cc269b7'::uuid, DATE '2008-11-05', 'day', 'IN', 'Lonnie Randolph', '2', DATE '2008-11-05'),
  ('a99a9635-f13d-4116-83b2-b228decf0684'::uuid, '6cd6f99d-42fe-4a1d-91cb-5794096e144e'::uuid, '4dcf4fa8-90f3-4717-9fa6-8e2fdbe9e602'::uuid, DATE '2020-11-04', 'day', 'IN', 'Scott Baldwin', '20', DATE '2020-11-04'),
  ('404789d6-a6c2-40f8-901f-611187c12ab7'::uuid, '61108337-2703-425b-8504-c3433eaaf2d1'::uuid, '6280a36a-9c26-4c22-a0d8-3ac06693fbfb'::uuid, DATE '2008-01-01', 'year', 'IN', 'James Buck', '21', DATE '2008-04-26'),
  ('39dc46c5-73f6-4a65-b72c-a65320f10c9c'::uuid, '32e7397b-3825-487b-b2cf-6760bb213541'::uuid, '27844ca9-5243-48e1-8053-c3ef4e12c0fe'::uuid, DATE '1998-11-04', 'day', 'IN', 'Ron Alting', '22', DATE '1998-11-04'),
  ('6b49f6a1-bd1a-4094-87f8-874efa229833'::uuid, '696d13bb-aec9-4924-aabc-66cc4860ad21'::uuid, '8a3eb0a4-fa2a-4918-bf67-8d9ff22253f3'::uuid, DATE '2022-11-09', 'day', 'IN', 'Spencer Deery', '23', DATE '2022-11-09'),
  ('cb0d2fd4-bab1-4498-bc1d-2b5c6efe5852'::uuid, '0a39769f-993e-420e-818d-aa2e4e12b1cf'::uuid, '46652b6e-6439-4047-8616-0ec86460a2a3'::uuid, DATE '2024-11-06', 'day', 'IN', 'Brett Clark', '24', DATE '2024-11-06'),
  ('fd0fb784-99a6-4da0-a56e-8c64d46ab26b'::uuid, 'e44d86ec-9ec0-49bb-a970-20a1f6243bec'::uuid, '5b09d9c2-ca04-4980-a6d6-6236ea0af802'::uuid, DATE '2022-11-09', 'day', 'IN', 'Mike Gaskill', '25', DATE '2022-11-09'),
  ('94148604-4f26-4edd-a914-5a61d9855435'::uuid, '542f4d7b-b409-4385-bbdd-564a97038ef6'::uuid, '96f697c8-8614-4bc3-b796-bcf02a0380a1'::uuid, DATE '2022-11-09', 'day', 'IN', 'Scott Alexander', '26', DATE '2022-11-09'),
  ('ee289bc6-bb7e-4d8e-aeb8-f5b1fd2c02df'::uuid, 'd4ace730-3f85-4533-bedb-0f3d87127aa3'::uuid, '5c6cb815-dfae-4883-91cf-c6428c7e2444'::uuid, DATE '2014-11-05', 'day', 'IN', 'Jeff Raatz', '27', DATE '2014-11-05'),
  ('3791c30c-8688-454c-b320-f5491c5576e5'::uuid, '726c755b-5e57-4491-bcbe-5aaaa9a80120'::uuid, '868ca671-3b41-4a1e-96a0-a5e3ad1c945b'::uuid, DATE '2012-11-07', 'day', 'IN', 'Michael Crider', '28', DATE '2012-11-07'),
  ('632f0e15-7ebd-4469-8aa6-3c7277ca9bd3'::uuid, 'b4ab3354-c6e8-4a29-8aae-938ec2da84dd'::uuid, '5e7e232c-25e2-46ea-a511-4b9a7ab58b21'::uuid, DATE '2018-11-07', 'day', 'IN', 'J.D. Ford', '29', DATE '2018-11-07'),
  ('f21f1660-d56b-4563-a2d8-ff74d563d81c'::uuid, 'd134381a-8b52-49d1-bbdb-41ef0a68225e'::uuid, 'e5a011bc-2107-4d33-a3d0-827cbacf9398'::uuid, DATE '2024-11-06', 'day', 'IN', 'Mark Spencer', '3', DATE '2024-11-06'),
  ('160e2ba5-87a4-475d-aa72-32efd91435a2'::uuid, '61c9efe8-0f74-4380-aba1-015682df210b'::uuid, '33e307e0-dc84-43c0-b842-de34268c206d'::uuid, DATE '2020-11-04', 'day', 'IN', 'Fady Qaddoura', '30', DATE '2020-11-04'),
  ('5aefd816-0a04-4f6e-9da9-32fd2855bd86'::uuid, '60f81720-a5c5-4ee3-ad17-b83a73f63f58'::uuid, 'eb94127d-d394-4704-a53b-1efb2db3bc60'::uuid, DATE '2020-01-01', 'year', 'IN', 'Kyle Walker', '31', DATE '2020-11-17'),
  ('e3530199-f5a0-4257-955e-8f502c2cacb3'::uuid, 'b3942191-36e3-4cfb-89c4-488d3f283775'::uuid, '7ac75846-3990-45d0-b74a-b85d6d672f61'::uuid, DATE '2016-11-09', 'day', 'IN', 'Aaron Freeman', '32', DATE '2016-11-09'),
  ('ed6e8f72-12b2-4879-b2ce-3090c01ce21a'::uuid, '4525d5f4-1799-41df-98a1-344c295aab2f'::uuid, '3032d172-6b07-4c16-82d3-7e4f31f88375'::uuid, DATE '2024-01-01', 'year', 'IN', 'La Keisha Jackson', '34', DATE '2024-04-24'),
  ('51d230a8-4e1e-45fa-8f7a-3fd43d142633'::uuid, '93c303b4-a6fa-4c50-b68c-3971078112e1'::uuid, 'debcc50e-5de4-4208-82da-9e1a2b704ebc'::uuid, DATE '2022-01-01', 'year', 'IN', 'Michael Young', '35', DATE '2022-07-28'),
  ('0b4aec4d-644f-4374-834b-744b0c79a628'::uuid, '679e9a1d-87ab-4fd7-9e00-d0608ff8f3d3'::uuid, '326c5247-950b-407d-a10b-1116c49098f0'::uuid, DATE '2023-01-01', 'year', 'IN', 'Cyndi Carrasco', '36', DATE '2023-11-01'),
  ('0479c96d-b227-43ce-a74e-da262b900ece'::uuid, '5811cd87-8fb3-461c-9885-683c5a110396'::uuid, 'b27f2dd8-fb3c-4797-aed5-ea904768e915'::uuid, DATE '2023-01-01', 'year', 'IN', 'Greg Goode', '38', DATE '2023-11-01'),
  ('4706007c-4de8-46b6-bb0e-7a0c84fa4705'::uuid, '014db973-12b6-46df-a683-882b161829da'::uuid, '4b938d2b-2e54-4fbc-b048-5406968644d2'::uuid, DATE '2021-01-01', 'year', 'IN', 'Rodney Pol', '4', DATE '2021-11-16'),
  ('b5bae27d-30a7-4326-a4c1-af9267796706'::uuid, '418fe9d6-8dfb-481d-9fda-c1227e71bb07'::uuid, '38aa44f1-2579-44fb-b520-f055f2edfd70'::uuid, DATE '2008-11-05', 'day', 'IN', 'Jean Leising', '42', DATE '2008-11-05'),
  ('a35fd6ca-efaa-49f1-b4fd-f0fe56d0a342'::uuid, '9a14b054-64fe-4f0e-a0b4-cb30264ec632'::uuid, 'c473defa-6492-4cf7-a7c1-5f9a836ab6ac'::uuid, DATE '2023-01-01', 'year', 'IN', 'Randy Maxwell', '43', DATE '2023-09-28'),
  ('5a3c8e9e-a23e-4668-87ca-357eec2bfd75'::uuid, 'b93ba475-ef99-4209-be1d-28cc3eae2399'::uuid, '8af9732c-8050-4732-acdf-6e2c8ed6e30b'::uuid, DATE '2018-11-07', 'day', 'IN', 'Chris Garten', '45', DATE '2018-11-07'),
  ('7f2816f2-60bf-4028-9f73-51a1b87cf492'::uuid, '4f8a7b64-73b3-45de-843e-5b2ded7a8490'::uuid, '1ea3c520-481e-4975-9fcb-ef1c508d680f'::uuid, DATE '2022-01-01', 'year', 'IN', 'Gary Byrne', '47', DATE '2022-02-14'),
  ('7f17a54a-8d9c-42a4-a6a7-4c243019918b'::uuid, '9740efdd-98b5-4f29-a515-327a749efdca'::uuid, '82bb4a77-7067-474f-a442-0b6c65988323'::uuid, DATE '2024-01-01', 'year', 'IN', 'Daryl Schmitt', '48', DATE '2024-09-10'),
  ('57501c9a-a95b-4a0f-b0e2-ada3c9da3540'::uuid, '5876edc2-bafb-41bb-a48a-271750c94422'::uuid, 'dfab8491-551f-4a3f-b76c-d220a9f4b23b'::uuid, DATE '2010-11-03', 'day', 'IN', 'James Tomes', '49', DATE '2010-11-03'),
  ('ba1cfb62-5c3d-4ec0-8045-acd5c654ac90'::uuid, '4e60187d-e3af-40a3-8a86-9639743d1b13'::uuid, 'cf6383ed-241b-4cbd-a51d-8bfe2eefdd3c'::uuid, DATE '2007-01-01', 'year', 'IN', 'Ed Charbonneau', '5', DATE '2007-06-09'),
  ('00153d46-9726-44f6-ae4f-0636ff545a6d'::uuid, 'd8ed7bde-83bc-4813-b90a-1b05c60f3938'::uuid, '34f7e7f3-84f9-484e-be41-e3300c18f7f1'::uuid, DATE '1992-11-04', 'day', 'IN', 'Vaneta Becker', '50', DATE '1992-11-04'),
  ('0e0e68b4-427c-453a-ac5e-7e10b577f4f6'::uuid, 'e07feaea-4d6f-4167-a8b9-1ae9180f0ff8'::uuid, '6e1a895d-a956-4806-8938-4977e34cac9a'::uuid, DATE '2014-11-05', 'day', 'IN', 'Rick Niemeyer', '6', DATE '2014-11-05'),
  ('200189bd-0970-4acf-a776-93145528c9b7'::uuid, 'd7362c6e-f572-4d9f-941a-44a3075445a2'::uuid, '5d57215a-7a47-4650-9c7b-47ff41d6322b'::uuid, DATE '2018-01-01', 'year', 'IN', 'Brian Buchanan', '7', DATE '2018-02-12'),
  ('495a166d-eb0b-48c6-b4fa-5e5917fa09bd'::uuid, '8587f8ff-0e7f-4b41-9df6-f39c11a34e5d'::uuid, '254be2be-bda5-40c3-b4de-fc261c3327b6'::uuid, DATE '2016-11-09', 'day', 'IN', 'Mike Bohacek', '8', DATE '2016-11-09'),
  ('3ac80dbf-36bc-439f-ac59-01824248b3ba'::uuid, '109811e6-4a7d-4293-88d9-6dd9b90edd98'::uuid, '25becdfe-46ec-4a8a-88ec-8c85eed418b5'::uuid, DATE '2004-11-03', 'day', 'IN', 'Ryan Mishler', '9', DATE '2004-11-03'),
  ('3681e21a-5d64-433b-8e81-2ac4c4abc140'::uuid, 'ba13159b-8b41-45a8-bd36-9e7696f7631d'::uuid, '1af14e38-da38-44ea-854d-3d8f1c615460'::uuid, DATE '2024-12-02', 'day', 'CA', 'Heather Hadwick', '1', DATE '2024-12-02'),
  ('fad5e20f-9a25-4618-977c-1a87adba4765'::uuid, '422eb261-3f7a-4a4d-82f2-da1d3616e6a3'::uuid, '7c23df4c-d105-4f48-8490-cb667a5e3382'::uuid, DATE '2022-12-05', 'day', 'CA', 'Stephanie Nguyen', '10', DATE '2022-12-05'),
  ('daa2afcf-8ed4-4a29-9b7d-972f15a38944'::uuid, 'dc4b9295-7a54-4309-ac0c-30b03ed34cc2'::uuid, 'fc8374d8-7186-4be8-9c36-f37df2e9c0d8'::uuid, DATE '2022-01-01', 'year', 'CA', 'Lori D. Wilson', '11', DATE '2022-04-06'),
  ('c594495e-af91-43fa-982d-cca8cb8d0db4'::uuid, 'a4020ea2-02d1-411b-b586-9b7c8dc4f90b'::uuid, 'ab26d178-4f69-4ffc-9485-ac03f87643e2'::uuid, DATE '2022-12-05', 'day', 'CA', 'Damon Connolly', '12', DATE '2022-12-05'),
  ('4d6c40c0-1ae1-4372-8d06-fb9272bd062c'::uuid, '49fae1a1-2b2f-41da-9c66-844ad084fa4a'::uuid, '6a36e92b-d953-4309-8423-1e0ba4e68b6f'::uuid, DATE '2024-12-02', 'day', 'CA', 'Rhodesia Ransom', '13', DATE '2024-12-02'),
  ('856a05d6-4089-4460-a455-e8f510e061f4'::uuid, '7b3dcdad-b119-4b25-8240-460f70244f9d'::uuid, '5821d0a9-672e-44c0-bac7-1a802a2e8368'::uuid, DATE '2022-12-05', 'day', 'CA', 'Buffy Wicks', '14', DATE '2022-12-05'),
  ('981d9cee-7ebd-497c-908f-f227aabe6b03'::uuid, '79f55eaa-b5dc-4368-91be-9046b0e96d74'::uuid, '52d3e817-03bf-4dd5-8a16-67b44acf23ac'::uuid, DATE '2024-12-02', 'day', 'CA', 'Anamarie Avila Farias', '15', DATE '2024-12-02'),
  ('dfbd9d7c-6d9b-4255-a0ec-ed2919026799'::uuid, 'b58a97c0-8ee8-4949-827d-c06946a12a4c'::uuid, '2cca193f-574d-4ec7-b0c8-e0fcd27d5eab'::uuid, DATE '2018-12-03', 'day', 'CA', 'Rebecca Bauer-Kahan', '16', DATE '2018-12-03'),
  ('109a2cb1-d04d-4d03-b972-76c195576410'::uuid, 'f11ac115-0c75-4fbf-baf8-d78ef703dc49'::uuid, '4c7d1cea-a6ce-4185-a977-c754800f491a'::uuid, DATE '2022-01-01', 'year', 'CA', 'Matt Haney', '17', DATE '2022-05-03'),
  ('24a5605f-5800-4698-b59d-c8e4965ce9a8'::uuid, 'f675394b-9e74-40ab-9a35-89aca8b4f9e9'::uuid, '0d70edc9-535c-4191-a222-fe57ebde4467'::uuid, DATE '2021-01-01', 'year', 'CA', 'Mia Bonta', '18', DATE '2021-09-07'),
  ('b8c2805e-1805-4a57-be61-f1b360c60a1c'::uuid, '43845b1b-7d1c-4034-ad31-0f7ec48da745'::uuid, '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, DATE '2024-12-02', 'day', 'CA', 'Catherine Stefani', '19', DATE '2024-12-02'),
  ('cf0aa7dd-2e62-4944-bad6-6cf0578af966'::uuid, '9d56e4b8-e010-45b6-826f-92e483830169'::uuid, 'd8c6901d-ad98-484e-b932-9ea77cfb677d'::uuid, DATE '2024-12-02', 'day', 'CA', 'Chris Rogers', '2', DATE '2024-12-02'),
  ('efeb8ade-12bd-43f7-9752-205a382f197a'::uuid, 'b306308a-593a-40ae-a05c-7eb9ecaf46ee'::uuid, '6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, DATE '2022-12-05', 'day', 'CA', 'Liz Ortega', '20', DATE '2022-12-05'),
  ('2793efa2-f8b7-41bb-ab3c-18589405d788'::uuid, '1e2d5919-ea9e-4c05-af12-c9ac1007d114'::uuid, 'fb44c938-26fd-40ca-9333-e842693a1ad4'::uuid, DATE '2022-12-05', 'day', 'CA', 'Diane Papan', '21', DATE '2022-12-05'),
  ('0d248773-be45-473d-a5ab-d50505ecedfc'::uuid, 'afcf6e4e-d54b-49bd-8539-731aac0c66aa'::uuid, '7520a629-a0ec-44b3-9460-c7e4574a897d'::uuid, DATE '2022-12-05', 'day', 'CA', 'Juan Alanis', '22', DATE '2022-12-05'),
  ('67d257c5-cc97-4ed7-86f4-516ef76a09f5'::uuid, '6bb9a929-fd7a-4fee-b28e-4faa7c3b95de'::uuid, '4cfacf31-d285-40ac-8373-e350912fddda'::uuid, DATE '2022-12-05', 'day', 'CA', 'Marc Berman', '23', DATE '2022-12-05'),
  ('d82c8bb3-adb1-40b3-a1e1-37c1bb5f830b'::uuid, '43dd153e-0834-434f-9577-f9bae44d8f89'::uuid, '525a5d79-d7a9-498a-b972-57fa517be375'::uuid, DATE '2022-12-05', 'day', 'CA', 'Alex Lee', '24', DATE '2022-12-05'),
  ('4d239bef-c58f-4a3f-92ac-113c87703873'::uuid, '3db4bfac-030f-4c8b-afbe-77c093e64ea9'::uuid, 'eb1a285e-fd86-4da1-a198-a66ad6a81be4'::uuid, DATE '2022-12-05', 'day', 'CA', 'Ash Kalra', '25', DATE '2022-12-05'),
  ('3c44f3d4-e99e-4548-96be-fb8de43d87d8'::uuid, '4b943fc3-4c68-4b2f-8a56-7159b3cc18ba'::uuid, 'bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, DATE '2024-12-02', 'day', 'CA', 'Patrick J. Ahrens', '26', DATE '2024-12-02'),
  ('8e0bb15e-ff42-4c2d-8664-0b0b55329806'::uuid, '134ff9e4-cd3e-4d20-a371-35aea15f88b9'::uuid, '2326fe1b-923d-4e2f-9598-0c8a23528df8'::uuid, DATE '2022-12-05', 'day', 'CA', 'Esmeralda Z. Soria', '27', DATE '2022-12-05'),
  ('8f617f59-03d2-4e06-b58a-e29648417364'::uuid, '4164cda9-e149-46c7-9b5a-7f1f75088ac0'::uuid, '190c3584-0826-4a5f-a2ad-104ff70ff259'::uuid, DATE '2022-12-05', 'day', 'CA', 'Gail Pellerin', '28', DATE '2022-12-05'),
  ('66615aa2-fe66-4a71-b76c-60b70dc72754'::uuid, 'c92c53b0-c0f9-4a30-a060-2996e90bf811'::uuid, '5a75d4fb-e4fe-441a-8658-e6eb57574fd4'::uuid, DATE '2022-12-05', 'day', 'CA', 'Robert Rivas', '29', DATE '2022-12-05'),
  ('8a6e7932-db0c-45a4-9542-b8e24d0924a1'::uuid, '0cc1657e-3912-4ae8-84d6-ae9c03bb1d63'::uuid, '2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid, DATE '2022-12-05', 'day', 'CA', 'Dawn Addis', '30', DATE '2022-12-05'),
  ('39762446-8d52-4883-88ef-ad942ed8e390'::uuid, '4a385343-5298-40bb-a78a-4c9a5e951cdb'::uuid, '9edab965-ac61-4227-a8d6-601c07821f53'::uuid, DATE '2016-01-01', 'year', 'CA', 'Dr. Joaquin Arambula', '31', DATE '2016-04-14'),
  ('e8dcb74c-b224-484e-8ce3-a1636c09e606'::uuid, 'f9f7497e-6ed9-4326-9391-5dc6eda76af7'::uuid, 'fcdd3836-bb89-44ec-920a-75a21c9d726f'::uuid, DATE '2025-01-01', 'year', 'CA', 'Stan Ellis', '32', DATE '2025-03-03'),
  ('861048bc-b458-4e5f-9d6e-aaf8b2e1f258'::uuid, '1f700d36-f535-40ed-94a4-8ff2fba7c34d'::uuid, '8566674a-3a3b-4c88-bba0-c9f42e4ff810'::uuid, DATE '2024-12-02', 'day', 'CA', 'Alexandra M. Macedo', '33', DATE '2024-12-02'),
  ('529ed8ce-b287-4b8c-8d84-ece0b83e8158'::uuid, '54a4ad72-bcd1-4fe1-b684-bfa7e72152fc'::uuid, 'e8bdd8a7-a1b2-43e3-afd4-df975980819e'::uuid, DATE '2022-12-05', 'day', 'CA', 'Tom Lackey', '34', DATE '2022-12-05'),
  ('21ac0501-8b39-46bd-8f94-4e1c74807406'::uuid, '2dfff08a-d688-4570-80ff-1f2eb165e62a'::uuid, '539874fc-489f-4643-9b1a-923aca6cc2c1'::uuid, DATE '2022-12-05', 'day', 'CA', 'Jasmeet Kaur Bains', '35', DATE '2022-12-05'),
  ('48482fef-ca5b-4d4c-ae2a-6432cc0e0d98'::uuid, 'c7fd48a8-f65d-4282-adc9-27ed5b468151'::uuid, '5ad32852-789e-4013-995b-6f0aa6a5a5d4'::uuid, DATE '2024-12-02', 'day', 'CA', 'Jeff Gonzalez', '36', DATE '2024-12-02'),
  ('db327b35-4395-42ac-93af-44d67784b4cd'::uuid, '6d0f0805-d61e-4961-933e-3cfbdbefa20e'::uuid, '21940b7c-2424-47e9-a649-077b0f827c2c'::uuid, DATE '2022-12-05', 'day', 'CA', 'Gregg Hart', '37', DATE '2022-12-05'),
  ('a1977170-d9a9-45a8-89d7-4217351c994a'::uuid, 'abbe5632-647e-4cb2-ab0c-6a870c3da012'::uuid, '8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, DATE '2022-12-05', 'day', 'CA', 'Steve Bennett', '38', DATE '2022-12-05'),
  ('04aabb70-9ac8-4bac-baa4-d1fd947fbc8b'::uuid, '35b83356-848d-49ee-8815-14c7885f7dbb'::uuid, 'b959d608-5674-467e-a1c8-3572c76a729b'::uuid, DATE '2022-12-05', 'day', 'CA', 'Juan Carrillo', '39', DATE '2022-12-05'),
  ('d651d32d-7ae6-48d7-a3bd-83368db3b1ba'::uuid, 'f4c83c0b-3c35-419b-a618-0e6c4c13fd38'::uuid, '8ba12ba5-ba07-48be-ae0e-88e1d1ef5257'::uuid, DATE '2016-12-05', 'day', 'CA', 'Cecilia M. Aguiar-Curry', '4', DATE '2016-12-05'),
  ('205fb142-0a46-461d-a474-a06d783d34ec'::uuid, 'e3c96374-ab47-4fa5-9a23-f1b17d1e393e'::uuid, 'd64c969e-f458-4387-98b5-1e7af8cb42f0'::uuid, DATE '2022-12-05', 'day', 'CA', 'Pilar Schiavo', '40', DATE '2022-12-05'),
  ('888d6ebf-112d-4ad0-b1c4-fffa7d1c76f5'::uuid, 'b5bca67c-a70d-496b-909e-cf33839ce017'::uuid, '0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e'::uuid, DATE '2024-12-02', 'day', 'CA', 'John Harabedian', '41', DATE '2024-12-02'),
  ('4f47cc90-d183-4655-83de-d915509a1a56'::uuid, '3752046e-327e-472d-8c0d-5ce65061e7a4'::uuid, '97285c92-b664-4687-a1e4-6d88cf9c7fe4'::uuid, DATE '2022-12-05', 'day', 'CA', 'Jacqui Irwin', '42', DATE '2022-12-05'),
  ('a67d7f3e-10f5-48f1-8185-894e803157b6'::uuid, 'ac6b849b-7b62-4ea8-912d-d009d9ed8090'::uuid, 'f9cbe210-a840-4924-b4aa-a5de0dc143ba'::uuid, DATE '2024-12-02', 'day', 'CA', 'Celeste Rodriguez', '43', DATE '2024-12-02'),
  ('540423d9-f8ce-47b5-81ab-f11a69be40b2'::uuid, '1854c5b3-a585-495f-a1f2-c4c79a8e7cac'::uuid, 'e31e6ebf-91ea-478f-b4dc-6974888bdffa'::uuid, DATE '2024-12-02', 'day', 'CA', 'Nick Schultz', '44', DATE '2024-12-02'),
  ('54be5a1f-bfbb-4e1f-95ac-254835cc7b95'::uuid, '927850b9-2c91-44f7-a6be-f4c81dc3b75d'::uuid, '01dd07dc-ded1-4ba5-aff3-2dc2b386af12'::uuid, DATE '2022-12-05', 'day', 'CA', 'James C. Ramos', '45', DATE '2022-12-05'),
  ('d060cb38-7ad8-4df5-a18f-c3ca3de47071'::uuid, '2d462db5-4c4d-4d52-90bb-572851612368'::uuid, 'f173ce9a-6941-4570-bd3f-97bc1157beaf'::uuid, DATE '2022-12-05', 'day', 'CA', 'Jesse Gabriel', '46', DATE '2022-12-05'),
  ('89fa84aa-2b20-4757-9417-a3edcac7880d'::uuid, 'fa86b35b-b6e8-4b0b-8eae-5e22a31db37e'::uuid, 'c6c04131-96f3-40d8-b881-e6c57f986d38'::uuid, DATE '2022-12-05', 'day', 'CA', 'Greg Wallis', '47', DATE '2022-12-05'),
  ('01442e6e-f789-4919-8a87-0e22b8a2a9fc'::uuid, '02cffd4c-9fd6-47c4-ae91-f33c0442efa2'::uuid, '51d15b77-71bb-475e-b86e-c6e1b37b869d'::uuid, DATE '2016-12-05', 'day', 'CA', 'Blanca E. Rubio', '48', DATE '2016-12-05'),
  ('4537df80-5204-4399-9ccb-415a8872ffb2'::uuid, '68b9d71e-fa8e-4f71-8fac-2e396818c6eb'::uuid, 'cacdb3e3-f716-4914-9e32-a95cc632af42'::uuid, DATE '2022-01-01', 'year', 'CA', 'Mike Fong', '49', DATE '2022-02-22'),
  ('f7bc3d48-690c-43a4-a08e-104ea6c1751c'::uuid, '1fc9ccc6-3a81-44e9-b2ed-092d0f79afdf'::uuid, '038b7624-492e-496c-8b97-0926ef4a4a1e'::uuid, DATE '2022-12-05', 'day', 'CA', 'Joe Patterson', '5', DATE '2022-12-05'),
  ('7ae938b6-88de-4bd6-8a64-6e8281b0856a'::uuid, 'cf32d02c-0670-428a-a8a7-ea3766437a57'::uuid, '8bfb459b-9823-4b0d-81f4-49cb97831a80'::uuid, DATE '2024-12-02', 'day', 'CA', 'Robert Garcia', '50', DATE '2024-12-02'),
  ('24368645-6c33-45f6-bb44-d62c66415807'::uuid, '7391433d-3597-487f-8355-f39bb5365079'::uuid, 'ff77225c-51f9-4628-acc3-020d40382d05'::uuid, DATE '2022-12-05', 'day', 'CA', 'Rick Chavez Zbur', '51', DATE '2022-12-05'),
  ('0581e1af-a430-4702-aac0-ae06a512016b'::uuid, '5df342df-1554-47f1-ade4-1007685f934b'::uuid, '685f2150-7b2a-4f94-992c-bf0cf23ffa69'::uuid, DATE '2024-12-02', 'day', 'CA', 'Jessica M. Caloza', '52', DATE '2024-12-02'),
  ('f71f7232-bc3d-4446-ba8b-8bea8f31fe20'::uuid, '454f55bc-6f3f-4e2f-8b74-78c0901abcf1'::uuid, '108dfd2c-571a-4fef-aaf2-621c3238eea6'::uuid, DATE '2024-12-02', 'day', 'CA', 'Michelle Rodriguez', '53', DATE '2024-12-02'),
  ('66c43a0b-5855-4bae-8c61-87fdf4596c9d'::uuid, 'a2f330df-16cd-42be-bcd5-006e57cf1d69'::uuid, '005d7df1-227e-4110-b254-ec835d5b5e95'::uuid, DATE '2024-12-02', 'day', 'CA', 'Mark Gonzalez', '54', DATE '2024-12-02'),
  ('4e26b0b8-4ba1-4976-adae-477d60373831'::uuid, 'be3bdca4-d290-474e-aa45-37b336719fa0'::uuid, '5cdd28b7-f8be-4968-bc1a-0e7928786980'::uuid, DATE '2022-12-05', 'day', 'CA', 'Isaac G. Bryan', '55', DATE '2022-12-05'),
  ('3a37513d-b9f3-4294-9067-3878930c6b4d'::uuid, '5badb726-42ee-4919-8574-884cc4e4e3e1'::uuid, '0afa998d-94e9-4af4-ba00-256c38869398'::uuid, DATE '2022-12-05', 'day', 'CA', 'Lisa Calderon', '56', DATE '2022-12-05'),
  ('c3df4dcd-cfa8-418d-8276-6478337a88aa'::uuid, '7d965633-60b5-419f-8c40-34e1077d2a77'::uuid, '3c2bfe51-9a53-4992-801b-138a1a8ce9ed'::uuid, DATE '2024-12-02', 'day', 'CA', 'Sade Elhawary', '57', DATE '2024-12-02'),
  ('7bd4d454-0a9e-49ab-95cb-c232cb89461d'::uuid, 'fa672e10-c60e-48ef-b636-ecded4465e72'::uuid, '30fee995-e2e3-42d6-9993-d000fd73b919'::uuid, DATE '2024-12-02', 'day', 'CA', 'Leticia Castillo', '58', DATE '2024-12-02'),
  ('e00529be-4db5-405f-b69a-3a65f3d351c4'::uuid, '43ae2686-e718-4044-aaf0-0ae153d4e5bf'::uuid, 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6'::uuid, DATE '2022-12-05', 'day', 'CA', 'Phillip Chen', '59', DATE '2022-12-05'),
  ('1d946c34-6a4c-4d5d-ae13-0152b2bb6658'::uuid, '11c6dfc5-e935-4094-a01d-1d30ef64f95d'::uuid, 'a7e904b1-ec37-4c43-8594-99d778e7351a'::uuid, DATE '2024-12-02', 'day', 'CA', 'Maggy Krell', '6', DATE '2024-12-02'),
  ('fe5a5521-3174-45d8-894f-ab93e004c184'::uuid, '3879816a-b7c9-4844-870a-34c3c33a96c2'::uuid, 'bbd7825a-6778-4cca-81c8-8ef3ded55965'::uuid, DATE '2022-12-05', 'day', 'CA', 'Dr. Corey A. Jackson', '60', DATE '2022-12-05'),
  ('c339476b-9cc2-4940-a55c-c68e99e4ede0'::uuid, '35d6cdde-1ce5-423c-9239-97a5b8e54666'::uuid, '522efd15-f5e2-4e1a-8708-aad87410637d'::uuid, DATE '2022-12-05', 'day', 'CA', 'Tina S. McKinnor', '61', DATE '2022-12-05'),
  ('7e793485-a6f4-46ec-badc-b27a800c7e7b'::uuid, 'c92f4112-2a0c-448d-b35d-39596daa1e55'::uuid, '1caa9043-2397-4f75-b430-acc0623d64d7'::uuid, DATE '2024-12-02', 'day', 'CA', 'Jose Luis Solache Jr.', '62', DATE '2024-12-02'),
  ('78980c57-24e9-4d78-b85c-9a8bdfd23289'::uuid, '9a14e79d-69df-418c-a040-60586b2f8891'::uuid, '3f200d93-74aa-4191-a275-77b64ff5b219'::uuid, DATE '2025-01-01', 'year', 'CA', 'Natasha Johnson', '63', DATE '2025-09-08'),
  ('4d0f7e77-bd37-47d1-a4d0-951b34c06f53'::uuid, '1f1502ce-0ab9-4b69-880b-adc8263aa223'::uuid, 'c9205ba1-d0c8-4f17-a165-fb2a8fdae742'::uuid, DATE '2022-12-05', 'day', 'CA', 'Blanca Pacheco', '64', DATE '2022-12-05'),
  ('3cd2091f-2df8-4adc-b4ab-374c46179277'::uuid, '7803f2a9-9dd2-4f45-8b85-1cf5fd29e785'::uuid, '6133e73c-4c33-4cfc-9fd3-de1382729f42'::uuid, DATE '2022-12-05', 'day', 'CA', 'Mike A. Gipson', '65', DATE '2022-12-05'),
  ('9312ad07-c720-4728-9d47-ff98eaf5d0ec'::uuid, 'e45c9d52-6288-4865-a2de-dadd73cc18e6'::uuid, 'ea803096-927f-41fe-98e1-deab56291810'::uuid, DATE '2016-12-05', 'day', 'CA', 'Al Muratsuchi', '66', DATE '2016-12-05'),
  ('ee73feb0-7738-4312-a8f1-e5f2f6871f64'::uuid, '4f3b86d7-7795-43ef-bf06-1d2191a9fad3'::uuid, '1e29ce86-9e02-4079-b50d-bb0d039613a2'::uuid, DATE '2022-12-05', 'day', 'CA', 'Sharon Quirk-Silva', '67', DATE '2022-12-05'),
  ('d25f7b67-e77e-4319-b8ca-28b91229ad8f'::uuid, '30ef8b70-23fb-4533-b4e1-a9ad1cfa9bef'::uuid, 'a1467b58-9cc8-4611-a03e-07defc1679bf'::uuid, DATE '2022-12-05', 'day', 'CA', 'Avelino Valencia', '68', DATE '2022-12-05'),
  ('ffbaa4c6-4be1-4b23-a741-4d8e49a864e0'::uuid, '5e24e873-5ddc-407f-b1b3-55037fad21fb'::uuid, '39d99fc2-b8ab-4846-8ff3-bcb65e16bee4'::uuid, DATE '2022-12-05', 'day', 'CA', 'Josh Lowenthal', '69', DATE '2022-12-05'),
  ('a9fddab7-d8da-4a83-8076-002e6afe6199'::uuid, 'c8ccc0ec-c339-438e-b5c7-74ac73803fe3'::uuid, 'acb2a944-dd73-484d-83e9-86362af0eb42'::uuid, DATE '2022-12-05', 'day', 'CA', 'Josh Hoover', '7', DATE '2022-12-05'),
  ('859d462a-82b1-4251-b7a4-40607b90eff8'::uuid, '094f7a7e-b9e4-4a27-9cad-3f456d11fdd6'::uuid, 'c2975ee6-7770-4c5f-809c-4e1245f2ab64'::uuid, DATE '2022-12-05', 'day', 'CA', 'Tri Ta', '70', DATE '2022-12-05'),
  ('c6be8f0b-6482-4f4f-b97d-7b32e9864108'::uuid, '1621afeb-6cb1-4368-98db-6e18b0723faa'::uuid, '62dfefeb-9979-445a-aee6-06cf7c03a8c0'::uuid, DATE '2022-12-05', 'day', 'CA', 'Kate Sanchez', '71', DATE '2022-12-05'),
  ('4e30b811-a5fd-4a01-af3d-9e17c8e82267'::uuid, 'e23ee62c-0e3d-406a-a201-be5c5219a374'::uuid, '9aa10096-180d-424b-8fc8-cca5796704a6'::uuid, DATE '2022-12-05', 'day', 'CA', 'Diane B. Dixon', '72', DATE '2022-12-05'),
  ('9f333054-48cf-4d32-b2c2-21e31f48e5c1'::uuid, '9cbc48f6-47c9-4435-b8b9-6201277c2aaa'::uuid, '065c6e87-8778-43ee-ab44-b9982a677aa7'::uuid, DATE '2022-12-05', 'day', 'CA', 'Cottie Petrie-Norris', '73', DATE '2022-12-05'),
  ('6fa36396-4ddd-4874-a2c4-3a036158dc61'::uuid, '406f82bd-66e1-4817-b1d5-3f732576f417'::uuid, '7778111f-551f-407f-87c7-e30268ea5e0a'::uuid, DATE '2022-12-05', 'day', 'CA', 'Laurie Davies', '74', DATE '2022-12-05'),
  ('2147869b-1ce9-44b4-b65c-a16978a79ba7'::uuid, 'fb3ae5e9-bc6e-4136-8450-a8bc82767431'::uuid, 'a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid, DATE '2024-12-02', 'day', 'CA', 'Carl DeMaio', '75', DATE '2024-12-02'),
  ('1e106e35-d115-44bf-9429-de5f72f267ae'::uuid, '82927e9d-6c17-43aa-b580-a7bc0ab81eda'::uuid, '9a927fae-60bf-41f9-8ec0-433cc98997fa'::uuid, DATE '2024-12-02', 'day', 'CA', 'Dr. Darshana R. Patel', '76', DATE '2024-12-02'),
  ('a8588600-cb9a-4314-b6f8-a8c01e4f90d1'::uuid, '7c2b0638-4953-4803-9d81-9a2d687063b9'::uuid, '0a9171c6-0676-4704-b825-a7e16c66f1c2'::uuid, DATE '2022-12-05', 'day', 'CA', 'Tasha Boerner', '77', DATE '2022-12-05'),
  ('9ecf636d-798a-457c-9dd5-ff96645e3153'::uuid, '5b95be8c-1634-43ab-acb5-f904b859a5ef'::uuid, '1ee95c1d-6127-494b-9f68-e8b3c975adee'::uuid, DATE '2020-12-07', 'day', 'CA', 'Christopher M. Ward', '78', DATE '2020-12-07'),
  ('654511fb-2faa-45ce-9c0d-d8f8ff6a98b9'::uuid, '3441b28c-eac0-462b-9a93-bf312ace0328'::uuid, 'cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2'::uuid, DATE '2024-12-02', 'day', 'CA', 'Dr. LaShae Sharp-Collins', '79', DATE '2024-12-02'),
  ('3fb19cd6-fff1-4ddc-a2d2-d0cffca19f27'::uuid, '823ebd68-325c-469c-a27f-2168fdb364fc'::uuid, '4db536d2-d624-4225-b5ff-d22b44c1e9a7'::uuid, DATE '2024-12-02', 'day', 'CA', 'David J. Tangipa', '8', DATE '2024-12-02'),
  ('5dc4edea-a284-400c-8603-c1602f14f84f'::uuid, '2a7ab2f1-c173-45ce-8589-ff3fc1c16abd'::uuid, 'e0451383-4594-4247-8297-acc388a7e0c3'::uuid, DATE '2022-01-01', 'year', 'CA', 'David A. Alvarez', '80', DATE '2022-06-15'),
  ('438a48b8-10a0-49b4-bde3-bdf6f61567d0'::uuid, '68830803-7f09-48b7-aab8-ba9e2fe10fe7'::uuid, 'a0c59a09-fa45-4765-b6c5-17843699991d'::uuid, DATE '2022-12-05', 'day', 'CA', 'Heath Flora', '9', DATE '2022-12-05'),
  ('198e7e3e-8906-4748-8fb4-4390a4c2c9d5'::uuid, '7a7d8d8e-3af2-4372-a943-6aa92c10fefb'::uuid, '4baa73c2-d38b-4d07-894f-1577d5ba43a3'::uuid, DATE '2022-12-05', 'day', 'CA', 'Caroline Menjivar', '20', DATE '2022-12-05'),
  ('49c66e9f-3692-4368-b123-54d25d3423b7'::uuid, 'e31dfcd0-d34f-4ecd-93cc-409d0e185687'::uuid, '863ef272-ea35-482b-aee2-447c06bd469d'::uuid, DATE '2025-01-01', 'year', 'CA', 'Tony Strickland', '36', DATE '2025-03-11'),
  ('c7df3ad9-0a6b-4057-a766-fbc692e6a4b5'::uuid, '3fde05a0-85bb-4979-a528-c87a05857b10'::uuid, 'c1215ce9-430e-411d-869c-353c93fe1cac'::uuid, DATE '2024-12-02', 'day', 'CA', 'Megan Dahle', '1', DATE '2024-12-02'),
  ('267d6f53-d3f2-4531-9976-cb052a2f78ab'::uuid, '429c8d57-1550-4fcf-9592-d6c166f443d7'::uuid, 'eb8b6aa3-a9d2-4792-8175-a105304da87f'::uuid, DATE '2016-12-05', 'day', 'CA', 'Scott Wiener', '11', DATE '2016-12-05'),
  ('29611acd-38ee-41bf-98f5-0b85b6f194af'::uuid, 'e38cdc56-9228-456b-ba4c-3fc0ab72f6cd'::uuid, '03ee06fb-9b51-41cc-8942-4632f3a724e3'::uuid, DATE '2022-12-05', 'day', 'CA', 'Shannon Grove', '12', DATE '2022-12-05'),
  ('09b3b48c-7c17-475b-a426-edf1b0a121e6'::uuid, '69fb6f34-c702-43fb-84fd-93418b521fe4'::uuid, '64eda290-d172-48de-8827-6ebca668cf5a'::uuid, DATE '2020-12-07', 'day', 'CA', 'Josh Becker', '13', DATE '2020-12-07'),
  ('5bda1819-1ec3-4397-8154-4cf8cb95e7a7'::uuid, 'd55ca4b0-d53f-42f5-9ed7-000d188e6634'::uuid, '8b15f324-ed8b-4cc9-92b4-fdaf07896b20'::uuid, DATE '2022-12-05', 'day', 'CA', 'Anna Caballero', '14', DATE '2022-12-05'),
  ('c845d727-aef6-45bf-a654-e2bd954382da'::uuid, '58c65b92-cdef-4c5b-a727-494dcbcb6019'::uuid, 'e0dc83f8-f72d-4869-8d79-532002408028'::uuid, DATE '2020-12-07', 'day', 'CA', 'Dave Cortese', '15', DATE '2020-12-07'),
  ('07a2681f-172c-4f79-aa56-e7e7849fa929'::uuid, '7e75e10d-f17f-4aa7-838a-985ff1a22834'::uuid, 'd3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid, DATE '2022-12-05', 'day', 'CA', 'Melissa Hurtado', '16', DATE '2022-12-05'),
  ('cae80af9-d34a-40a9-934e-c9f5a1d99ee3'::uuid, 'eaf4cad0-012a-48a6-8765-ca9020432782'::uuid, '178a41d4-42b5-4ffd-be06-d1059d54eacb'::uuid, DATE '2020-12-07', 'day', 'CA', 'John Laird', '17', DATE '2020-12-07'),
  ('41b54259-0b6e-431e-8503-53141898b833'::uuid, 'bfaacb00-1875-4c65-bbe9-5a5ab0034494'::uuid, '3a462896-e249-4c79-94b7-175bd2efcf73'::uuid, DATE '2022-12-05', 'day', 'CA', 'Steve Padilla', '18', DATE '2022-12-05'),
  ('ce04ae60-4a6c-4022-95b6-eeca340fbcd4'::uuid, '45dee346-e20b-4ce1-86de-f5af9577d2f4'::uuid, '562cf9a1-ad60-41d9-b9a1-4a19240c39b3'::uuid, DATE '2024-12-02', 'day', 'CA', 'Rosilicie Ochoa Bogh', '19', DATE '2024-12-02'),
  ('de2fb7c8-98d5-4057-89f3-63640dba55a4'::uuid, '8cf6fdd7-dd37-40b9-b548-22412b471560'::uuid, '974bfe8b-afb8-424c-bfd2-7805f033b1a0'::uuid, DATE '2014-12-01', 'day', 'CA', 'Mike McGuire', '2', DATE '2014-12-01'),
  ('95a48ba6-ca62-4c4f-8ca5-2dc5a9a8d994'::uuid, '889b94ca-7799-4f4c-948f-890386ceb414'::uuid, 'c7a56941-597a-456b-8fd8-e4bd840014c1'::uuid, DATE '2024-12-02', 'day', 'CA', 'Monique Limón', '21', DATE '2024-12-02'),
  ('4d657082-78c7-430a-a50b-39cbbd1e60b7'::uuid, '9705addc-6364-4439-9cc3-9fcbfeb4caaa'::uuid, 'b3937fff-ebcf-48d9-b20d-bdf98196e119'::uuid, DATE '2018-12-03', 'day', 'CA', 'Susan Rubio', '22', DATE '2018-12-03'),
  ('e2534331-72b1-4fda-82f0-c40db9b8c856'::uuid, '83592455-dc15-48f1-aa03-1d41b542dd15'::uuid, '7f3b03b0-b481-4ccf-a33e-1261daabc6e8'::uuid, DATE '2024-12-02', 'day', 'CA', 'Suzette Martinez Valladares', '23', DATE '2024-12-02'),
  ('d119ef57-6632-4187-a1f8-219bf7a66750'::uuid, '58c7cb0f-6409-4e6a-aa4f-1d146e88eb69'::uuid, '4486f856-118b-475c-83f0-078581a7b268'::uuid, DATE '2022-12-05', 'day', 'CA', 'Benjamin Allen', '24', DATE '2022-12-05'),
  ('d6894be2-84a8-489e-a697-caf8b9f88cbc'::uuid, '372ad298-8d89-4037-bb49-b8261371f06d'::uuid, '611c17c5-3c5f-4685-8c22-3b3fe75482ba'::uuid, DATE '2024-12-02', 'day', 'CA', 'Sasha Renée Pérez', '25', DATE '2024-12-02'),
  ('ef29a62d-5132-4dd6-8547-edbbd7c48eca'::uuid, '493a571f-b01b-4253-afbc-ffe3979f52bb'::uuid, 'c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid, DATE '2022-12-05', 'day', 'CA', 'Maria Elena Durazo', '26', DATE '2022-12-05'),
  ('1eff055a-f250-4d98-bd58-b0fa53f630c6'::uuid, 'e090aea1-8a60-4a53-b43f-ce7162477c4a'::uuid, 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'::uuid, DATE '2016-12-05', 'day', 'CA', 'Henry Stern', '27', DATE '2016-12-05'),
  ('e7213072-e667-4b0b-8a4c-f504805a6c9e'::uuid, '9a837448-d3d3-4c56-b2bf-8d5e41c22ab1'::uuid, 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'::uuid, DATE '2022-12-05', 'day', 'CA', 'Lola Smallwood-Cuevas', '28', DATE '2022-12-05'),
  ('f979535e-a454-4a63-8dea-46804dac4edc'::uuid, 'd16d1077-8460-4620-8b7c-c8ef17c5f50f'::uuid, '1571da4a-b832-4792-917c-184c155b1700'::uuid, DATE '2024-12-02', 'day', 'CA', 'Eloise Gómez Reyes', '29', DATE '2024-12-02'),
  ('16b635f5-74cd-4eaa-933f-3ed41f3e49a8'::uuid, '5974a330-9801-4606-b913-7dad263a3f3f'::uuid, '5c4d4194-a7a1-4efa-80cb-af848e338b8d'::uuid, DATE '2024-12-02', 'day', 'CA', 'Christopher Cabaldon', '3', DATE '2024-12-02'),
  ('10f294be-9ceb-40d8-9905-f3642ccb2f28'::uuid, 'a9864785-4397-4f86-94fd-b03bc54bb585'::uuid, '29e15a5d-d98f-4536-ad62-05b2612f30ca'::uuid, DATE '2022-12-05', 'day', 'CA', 'Bob Archuleta', '30', DATE '2022-12-05'),
  ('97fc1c35-48df-41b4-9542-6af47f2788fd'::uuid, 'd55b76a7-866d-42fd-96c2-c50065af1dd2'::uuid, '7e588ebb-d17c-43c6-9eef-558871b55330'::uuid, DATE '2024-12-02', 'day', 'CA', 'Sabrina Cervantes', '31', DATE '2024-12-02'),
  ('76565692-2e1c-4f1b-b75f-8bfe8c993063'::uuid, 'ff40b8f8-a89d-48f3-8934-02c641396e61'::uuid, '4fccbf85-d794-4cdc-a8b8-674ff1b48784'::uuid, DATE '2022-12-05', 'day', 'CA', 'Kelly Seyarto', '32', DATE '2022-12-05'),
  ('a4647c60-4d99-4b82-9115-c6df43e6de13'::uuid, 'a77cd5e4-d43d-4af1-b8e0-46ed80b979c6'::uuid, '1cede4d2-3075-4860-b133-1ab34cdacff5'::uuid, DATE '2019-01-01', 'year', 'CA', 'Lena Gonzalez', '33', DATE '2019-06-12'),
  ('07432257-5e10-43ab-850e-4914948cff0e'::uuid, '9d4dce25-ba2b-4835-9490-4ef4bc69d4a5'::uuid, '712be98b-a05d-4605-9603-cd5d86abfad1'::uuid, DATE '2018-12-03', 'day', 'CA', 'Thomas Umberg', '34', DATE '2018-12-03'),
  ('d160ea6f-3dd9-4b25-89d0-e9122ae47aff'::uuid, 'd2fc37a8-8dbe-4a55-8ef3-efb776e441ba'::uuid, '9edc0c37-f213-4aae-9212-c9cb4780d854'::uuid, DATE '2024-12-02', 'day', 'CA', 'Laura Richardson', '35', DATE '2024-12-02'),
  ('f1648df5-09cd-4842-b1c1-220bbd620d08'::uuid, 'e1a551cf-feb6-41a5-9103-10bfa61677e2'::uuid, '8dfb3b1f-622d-434d-9106-9eeb75bc9a66'::uuid, DATE '2024-12-02', 'day', 'CA', 'Steven "Steve" Choi', '37', DATE '2024-12-02'),
  ('c49b919c-f635-4947-846f-8229052b1882'::uuid, '76ce3998-b6e1-4fb3-9461-2ab82fff6f04'::uuid, 'fad61dc3-a3ad-4056-b2f2-1f5d32fb886d'::uuid, DATE '2022-12-05', 'day', 'CA', 'Catherine S. Blakespear', '38', DATE '2022-12-05'),
  ('91439ce8-8a80-4a94-bd38-6a9687bdca8d'::uuid, 'ebb79fbd-e21a-4cf0-9ec7-49062207eae1'::uuid, 'e5470008-3c0d-4970-a485-053621d8f0a6'::uuid, DATE '2024-12-02', 'day', 'CA', 'Akilah Weber Pierson', '39', DATE '2024-12-02'),
  ('1f366eb2-88ff-42da-9ebc-166194624c2e'::uuid, '6105b714-58fe-4ecd-824e-64411f915bff'::uuid, '6e2d2c6d-b96e-4916-a7c8-51a8f46629ba'::uuid, DATE '2022-12-05', 'day', 'CA', 'Marie Alvarado-Gil', '4', DATE '2022-12-05'),
  ('211a52e8-d133-4e66-9bc1-2ba0643ce397'::uuid, 'de1a8793-9a9c-4e65-a7c6-c08ddd809a98'::uuid, 'ee130fd3-649d-49e1-bda4-13d9bbed2f6c'::uuid, DATE '2022-12-05', 'day', 'CA', 'Brian W. Jones', '40', DATE '2022-12-05'),
  ('47320c61-3540-47c7-9745-28653ab2196b'::uuid, 'c8952cf4-85b9-4602-9edc-dfa0878583ff'::uuid, '0267f457-cd3f-4790-b0c8-76ec616de3f0'::uuid, DATE '2024-12-02', 'day', 'CA', 'Jerry McNerney', '5', DATE '2024-12-02'),
  ('98d9b751-f3dd-459a-ae1d-468b84570bb3'::uuid, 'db68eac2-f869-4eae-bffc-faae657d7eb1'::uuid, '22152e41-31b9-4700-9226-4e274c616f37'::uuid, DATE '2022-12-05', 'day', 'CA', 'Roger Niello', '6', DATE '2022-12-05'),
  ('fad12c2d-1734-4613-89ee-b3509c8dbd2e'::uuid, '3b0686f2-9dee-41ac-9a35-a3a1d6b90a13'::uuid, 'eeeaf1be-3372-4cf9-b3b6-d5d1dff42615'::uuid, DATE '2024-12-02', 'day', 'CA', 'Jesse Arreguín', '7', DATE '2024-12-02'),
  ('cb5e8624-5955-4950-a988-a99dccebd0ab'::uuid, 'e0314625-8c77-41da-9ddb-fa5d1a41217b'::uuid, '060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid, DATE '2022-12-05', 'day', 'CA', 'Angelique Ashby', '8', DATE '2022-12-05'),
  ('8668acc0-0487-4001-9e42-ee62336bf41a'::uuid, '2660a4e7-4572-408b-a4ea-3d1d01d169d1'::uuid, '29389f8b-de23-4312-af73-264289dc7774'::uuid, DATE '2024-12-02', 'day', 'CA', 'Tim Grayson', '9', DATE '2024-12-02');

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM ca0293_terms;
  IF v_n <> 267 THEN RAISE EXCEPTION 'CA_0293: expected 267 staged rows, found %', v_n; END IF;
END $$;

UPDATE essentials.office_terms ot
   SET term_start = t.term_start,
       start_precision = t.start_precision,
       source = ot.source || ' | term_start ' || t.start_precision || ' from OpenStates people@bf4caf1 (tenure start '
                || t.openstates_start || '), checked against the ' || t.state || ' legal term-start day and the official roster 2026-09-25 (CA_0293)'
  FROM ca0293_terms t
 WHERE ot.id = t.term_id AND ot.office_id = t.office_id AND ot.politician_id = t.politician_id
   AND ot.term_end IS NULL AND ot.term_start IS NULL AND ot.start_precision = 'unknown';

DO $$
DECLARE v_done int; v_day int; v_year int;
BEGIN
  SELECT count(*) FILTER (WHERE ot.term_start = t.term_start AND ot.start_precision = t.start_precision),
         count(*) FILTER (WHERE ot.start_precision = 'day' AND t.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year' AND t.start_precision = 'year')
    INTO v_done, v_day, v_year
    FROM ca0293_terms t JOIN essentials.office_terms ot ON ot.id = t.term_id;
  IF v_done <> 267 OR v_day <> 219 OR v_year <> 48 THEN
    RAISE EXCEPTION 'CA_0293: expected 267 dated terms (219 day / 48 year), found % (% day / % year)', v_done, v_day, v_year;
  END IF;
  IF EXISTS (SELECT 1 FROM ca0293_terms t JOIN essentials.office_terms ot ON ot.id = t.term_id WHERE ot.source LIKE '%| unverified%') THEN
    RAISE EXCEPTION 'CA_0293: a dated term carries an "| unverified" tag';
  END IF;
  -- Every dated tenure still belongs to the current holder of its seat.
  IF EXISTS (SELECT 1 FROM ca0293_terms t LEFT JOIN essentials.office_current_holder och
               ON och.office_id = t.office_id AND och.politician_id = t.politician_id WHERE och.office_id IS NULL) THEN
    RAISE EXCEPTION 'CA_0293: a dated term is no longer the current holder of its seat';
  END IF;
END $$;

COMMIT;
