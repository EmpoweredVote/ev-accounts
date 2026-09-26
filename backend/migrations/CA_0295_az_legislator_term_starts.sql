BEGIN;

-- =============================================================================
-- CA_0295: office_terms.term_start for seated Arizona state legislators (term-date roster pass, AZ)
-- =============================================================================
-- Before: all 90 seated members (State Senate 30, House of Representatives 60) had an open-ended
-- office_terms row with term_start NULL, start_precision 'unknown' (ADR 0002 phase-2 backfill), so every
-- CONFIRM row for an Arizona legislator failed with `dates-imprecise` (found on the Gowan / HB 2552
-- shadow batch, 2026-09-26).
--
-- Method — the CA_0293 method (backend/scripts/term-dates-openstates.ts + scripts/lib/termStartRules.ts):
--   1. Candidate = start of the member's unbroken tenure in THIS seat (same chamber + district) from
--      OpenStates `people` @ bf4caf1 (2026-09-24). Arizona House districts have TWO members: the
--      OpenStates holder is the one whose surname matches our seat holder.
--   2. Legal rule (AZ): terms are two years from the first Monday in January after the election
--      (AZ Const. art. IV pt. 2 §21 — the first legislature held office "until the first Monday in
--      January, 1913"). Members take the oath when the legislature assembles, the second Monday in
--      January (A.R.S. 41-1101); OpenStates records that day. Either day → the constitutional first
--      Monday, start_precision 'day'. Any other date (a vacancy appointment) → the YEAR only,
--      start_precision 'year' ("Don't invent dates", CLAUDE.md).
--   3. Identity: our holder's surname must match the OpenStates holder AND the official roster read
--      2026-09-26 (azleg.gov/memberroster, saved in backend/data/term-dates/official/AZ-*.json).
--   Proposal file: backend/data/term-dates/2026-09-26-AZ-proposal.json.
--
-- Writes 90 rows: 79 at 'day' precision, 11 at 'year' precision (vacancy appointments a person may
-- later refine to the exact day from the official record). Only rows still NULL/'unknown' are touched,
-- matched by term id AND (office, politician) — idempotent; a seat that changed hands since the proposal
-- fails the post-verify, it is not overwritten.
--
-- Narrowing an open-ended range (NULL start → a date) can only remove overlap, never add it, so the
-- office_terms_no_overlap exclusion constraint cannot fail on this UPDATE.
-- The source note deliberately does NOT contain "| unverified" (office_holders_as_of skips those).
-- =============================================================================

CREATE TEMP TABLE ca0295_terms (term_id uuid, office_id uuid, politician_id uuid, term_start date,
  start_precision text, full_name text, chamber text, district text, openstates_start date) ON COMMIT DROP;
INSERT INTO ca0295_terms VALUES
  ('6b7b217d-fe81-4968-85e0-f8ea4a68771f'::uuid, 'ac15e728-b010-4cb1-ac0a-546f3a3a85e4'::uuid, 'b8c33072-6368-4465-8352-14e9fabddfbe'::uuid, DATE '2023-01-02', 'day', 'Selina Bliss', 'House of Representatives', '1', DATE '2023-01-09'),
  ('58f3dec3-3d2c-4f2f-abc1-884e6e609b47'::uuid, '0561b24d-9c8a-40b1-81a9-8b676e0d56fa'::uuid, '9cc152b6-c83b-4501-9e1a-2ab50e1db6a7'::uuid, DATE '2021-01-04', 'day', 'Quang H Nguyen', 'House of Representatives', '1', DATE '2021-01-11'),
  ('c4d7f6a8-b67a-418a-a014-75f95618d4f9'::uuid, '6ab27b15-07e8-4cc7-8d73-4005911090e5'::uuid, '92b03e09-8251-4eb8-a50e-966d52a592e1'::uuid, DATE '2025-01-06', 'day', 'Ralph Heap', 'House of Representatives', '10', DATE '2025-01-13'),
  ('2845b0c2-39c0-457f-9409-7ae019853944'::uuid, 'd3ba18e3-7656-43a6-8a77-40d3f77b7fe3'::uuid, '2af8f7d8-79ac-4668-9771-fdfff27ecc6c'::uuid, DATE '2025-01-06', 'day', 'Justin Olson', 'House of Representatives', '10', DATE '2025-01-13'),
  ('a9f7b50a-0674-49ee-a852-7afe19174a8f'::uuid, '4bb3485f-46f5-4fb3-9978-f9884118dae1'::uuid, '2b044f08-b5ce-4b15-993e-b90c16603c25'::uuid, DATE '2024-01-01', 'year', 'Junelle Cavero', 'House of Representatives', '11', DATE '2024-04-17'),
  ('7aa375b5-487e-4d0b-8118-8936988aad15'::uuid, 'd75c85d4-70de-4190-aa29-799672e0ab84'::uuid, 'fb949bda-e2f5-49ab-9069-a70da1fb13bd'::uuid, DATE '2023-01-02', 'day', 'Oscar De Los Santos', 'House of Representatives', '11', DATE '2023-01-09'),
  ('71f1c8a4-f2a1-4b02-bc51-2e8a7e7ab1d9'::uuid, 'a9c23bbd-ccd3-4278-b09f-d073f4acfeb5'::uuid, 'c2c49ac4-8d5e-46e3-b663-ac1677021a1b'::uuid, DATE '2023-01-02', 'day', 'Stacey Travers', 'House of Representatives', '12', DATE '2023-01-09'),
  ('a7285bd0-5092-4474-ac4d-c26112aa1065'::uuid, '8d1da137-2432-4e45-b6e9-b49ee10628fd'::uuid, '8dcf58fe-fea2-4dd4-81ac-542432b154cf'::uuid, DATE '2023-01-02', 'day', 'Patty Contreras', 'House of Representatives', '12', DATE '2023-01-09'),
  ('1b724b7d-dbd2-4006-81ba-47d912f4e207'::uuid, '2d574e6c-c30a-4897-8995-428b4968c690'::uuid, 'b813cb2d-f80e-4f53-83e0-fc0477ff3f3d'::uuid, DATE '2025-01-06', 'day', 'Jeff Weninger', 'House of Representatives', '13', DATE '2025-01-13'),
  ('dcf7067c-4cb0-4371-9f8e-ea8ecbc6c77a'::uuid, '74f6255e-04a3-481e-9a90-9fabcd9697f0'::uuid, '8edebfca-2e35-4424-85f8-f3ad498a2890'::uuid, DATE '2023-01-01', 'year', 'Julie Willoughby', 'House of Representatives', '13', DATE '2023-05-05'),
  ('f6e0566a-8fbb-446a-9674-69511bf501e1'::uuid, 'd3c77444-69e2-42ed-94d3-5a8766a22791'::uuid, '1f7399ee-2434-49dc-9a18-857bfa0e41f1'::uuid, DATE '2023-01-02', 'day', 'Laurin Hendrix', 'House of Representatives', '14', DATE '2023-01-09'),
  ('3106f7bd-fbc8-4c0b-ae6e-05a9e23ec3c1'::uuid, '4ab025fb-459d-4938-b7c7-786ef7947890'::uuid, '3769c4ad-3844-4ab6-9416-96b93c049b33'::uuid, DATE '2025-01-06', 'day', 'Khyl Powell', 'House of Representatives', '14', DATE '2025-01-13'),
  ('c737145e-225f-4aa8-9a68-b8002892e2eb'::uuid, '5f95f54d-d57c-4e3b-95ff-611505f721b3'::uuid, '9a81dfd3-b70b-45bf-8851-3907d6e12508'::uuid, DATE '2023-01-02', 'day', 'Neal Carter', 'House of Representatives', '15', DATE '2023-01-09'),
  ('8bb817a4-6aa9-463e-bcc7-4ee32b7bdaf8'::uuid, 'cec35532-6e47-49fc-842b-c7c0d6543641'::uuid, '29b130a2-1531-4b35-b79e-dc0e8e3c0b93'::uuid, DATE '2025-01-06', 'day', 'Michael Way', 'House of Representatives', '15', DATE '2025-01-13'),
  ('4e425067-12d4-4484-8448-d66ca3969522'::uuid, 'cfe55427-08a5-4f86-84f0-8bb0d3f264d3'::uuid, 'cacb84a8-4343-4919-a37c-dfcb6e050243'::uuid, DATE '2023-01-02', 'day', 'Teresa Martinez', 'House of Representatives', '16', DATE '2023-01-09'),
  ('0309ad44-26df-47b2-85aa-0691cfcaaed6'::uuid, 'cd64023e-0c39-470d-9510-1d4830fcb19f'::uuid, '5dd72969-087b-4db0-b2b1-ee87a1ef11b9'::uuid, DATE '2025-01-06', 'day', 'Chris Lopez', 'House of Representatives', '16', DATE '2025-01-13'),
  ('ef8ece28-acca-4b40-870c-533dec581bc6'::uuid, 'ffe0dcbf-575e-4224-8db5-d6635759bb60'::uuid, '6a1417b8-cdcd-43f2-a63d-533beaefc563'::uuid, DATE '2023-01-02', 'day', 'Rachel Keshel', 'House of Representatives', '17', DATE '2023-01-09'),
  ('b342cc73-14aa-45bf-9961-6a93c6836dd8'::uuid, 'ade613bd-6faf-4a93-a5c4-da8cdf82899e'::uuid, 'c72622ac-61d7-4e8b-83a8-565cfca045c0'::uuid, DATE '2025-01-06', 'day', 'Kevin Volk', 'House of Representatives', '17', DATE '2025-01-13'),
  ('a1809713-3665-45ec-987d-183b5a19347f'::uuid, 'e095dbc3-d588-400c-9816-667f414cf5e6'::uuid, 'ce872623-f6bd-4e90-9eba-239ed00c7491'::uuid, DATE '2023-01-02', 'day', 'Nancy Gutierrez', 'House of Representatives', '18', DATE '2023-01-09'),
  ('5e3bcba4-7920-46d8-8424-dbe7d0774e43'::uuid, '60ec357f-3c1b-4b58-82e7-447dd47bc111'::uuid, 'a7675f41-2e50-413c-9864-8a64969f47f9'::uuid, DATE '2023-01-02', 'day', 'Christopher Mathis', 'House of Representatives', '18', DATE '2023-01-09'),
  ('35364b38-1179-4fb1-83a7-67f195d7e188'::uuid, '8c909ec7-73d2-4488-8eb5-a72f4746f32b'::uuid, '0ac7beee-f298-4d41-8981-30c3c307fe3d'::uuid, DATE '2023-01-02', 'day', 'Lupe Diaz', 'House of Representatives', '19', DATE '2023-01-09'),
  ('b737b834-4b5b-4500-952a-2e79ae977f97'::uuid, 'b68ffd33-82dd-4eba-adee-6a853f7fc882'::uuid, '188c386e-087b-4587-9510-da7fc5805575'::uuid, DATE '2023-01-02', 'day', 'Gail Griffin', 'House of Representatives', '19', DATE '2023-01-09'),
  ('f515b18c-117d-4fcc-a4c1-525f34e491f1'::uuid, '8ae7931a-b76b-4ff0-99c8-5619ca6a10ff'::uuid, '729d1a1e-b58f-4a33-bf18-a0f11e3c5e04'::uuid, DATE '2023-01-02', 'day', 'Justin Wilmeth', 'House of Representatives', '2', DATE '2023-01-09'),
  ('bcd9b827-65fc-46be-a750-e1137b8a4069'::uuid, '7abf4f86-731b-41bf-851e-81bb19b52284'::uuid, '84bb6849-a68d-42e0-999d-dd0456b9d0b4'::uuid, DATE '2025-01-06', 'day', 'Stephanie Simacek', 'House of Representatives', '2', DATE '2025-01-13'),
  ('c20a31ad-432c-4031-a40f-8dba7f003264'::uuid, 'aba32819-62f2-41a5-a105-569b59d9ac5a'::uuid, 'e4460c64-fa27-4e05-96e8-cc005a478444'::uuid, DATE '2023-01-02', 'day', 'Alma Hernandez', 'House of Representatives', '20', DATE '2023-01-09'),
  ('5b413cde-59ed-4066-beb9-d0e92baa620f'::uuid, '77d6f370-ebd0-49c8-8627-ec4b2883fd7b'::uuid, '6dcc0e46-c944-480b-a432-7b36989d56e9'::uuid, DATE '2023-01-01', 'year', 'Betty J Villegas', 'House of Representatives', '20', DATE '2023-07-31'),
  ('28a3efdb-fce6-447d-bfac-fba01959f6a8'::uuid, 'bcdc8c0e-6ac0-497d-91d5-422b030dbc79'::uuid, '2405145c-f082-47f2-861d-d4efd19e8162'::uuid, DATE '2023-01-02', 'day', 'Stephanie Stahl Hamilton', 'House of Representatives', '21', DATE '2023-01-09'),
  ('a9d81e00-9012-4462-9460-88f45c01baad'::uuid, '2634b79e-b662-4841-bc71-3472e3b48d69'::uuid, '5e9c9ca6-5267-4d01-b19d-a7da775d89d9'::uuid, DATE '2023-01-02', 'day', 'Consuelo Hernandez', 'House of Representatives', '21', DATE '2023-01-09'),
  ('8d366e2f-0df3-4467-a574-ba235ff6e199'::uuid, 'a0e85220-d9d2-4cc1-b3bf-53423ce53711'::uuid, 'd5466317-d90a-41ce-ba20-30c12429dcb3'::uuid, DATE '2023-01-02', 'day', 'Lupe Contreras', 'House of Representatives', '22', DATE '2023-01-09'),
  ('474d4dd0-8bfc-4fc0-a759-8aa661e8f6dc'::uuid, '818567e1-d7a5-49fe-a8f1-a7b9d8937ae6'::uuid, '8d470040-0f53-4881-8b58-5e9563a85f94'::uuid, DATE '2024-01-01', 'year', 'Elda Luna-Nájera', 'House of Representatives', '22', DATE '2024-03-01'),
  ('3617fe29-f085-471e-8dbc-1eee73c3eed9'::uuid, '3faaee07-6dc2-42de-a9f4-019a9606366f'::uuid, '81b3d4cc-c502-4fbc-bd75-97773c39b2f5'::uuid, DATE '2023-01-02', 'day', 'Michele Peña', 'House of Representatives', '23', DATE '2023-01-09'),
  ('a3a54cf9-787f-459b-895f-cb3882b4b0ea'::uuid, 'dc40d9b5-cf75-48f3-9773-679b10a50899'::uuid, 'c37db938-9db2-47d5-b30e-7ac6a5f5c5ee'::uuid, DATE '2023-01-02', 'day', 'Mariana Sandoval', 'House of Representatives', '23', DATE '2023-01-09'),
  ('77c565bb-b2ce-428b-b32e-5e4f30035be9'::uuid, '2f24b0a5-2510-4d11-9810-0df5c4b28af2'::uuid, '8deb34b4-a40d-4d26-8d3a-1b5a9e9f07f9'::uuid, DATE '2023-01-02', 'day', 'Lydia Hernandez', 'House of Representatives', '24', DATE '2023-01-09'),
  ('294300d6-33ea-4537-aafa-196fbd652747'::uuid, 'cd393f8d-3ceb-4671-ab6b-e2196e3352b2'::uuid, '1d2e925a-299f-4504-a4de-815d7a2ee7a6'::uuid, DATE '2025-01-06', 'day', 'Anna Abeytia', 'House of Representatives', '24', DATE '2025-01-13'),
  ('22d3fa30-bf64-4950-91de-51a025c412ee'::uuid, '5d39ba29-4d41-4a41-b01c-0c48786c3675'::uuid, '86b6bbf3-cb81-4f8e-a44b-5c4ffe46df7a'::uuid, DATE '2023-01-02', 'day', 'Michael Carbone', 'House of Representatives', '25', DATE '2023-01-09'),
  ('b4a6db02-997d-4b6b-889d-8b1fa1d18384'::uuid, '3edfed74-dfa0-4fbc-8bf7-7136c12501bb'::uuid, '4176f760-3c74-4a55-8edc-b7897ee80e21'::uuid, DATE '2025-01-06', 'day', 'Nick Kupper', 'House of Representatives', '25', DATE '2025-01-13'),
  ('3bf33261-ff7f-4a13-a692-ddadcae7ef7f'::uuid, '3f0d3218-0f80-4c7e-9b3b-ea2c61746cd5'::uuid, '49b2db49-6438-437c-90ce-36b97670e30a'::uuid, DATE '2023-01-02', 'day', 'Cesar Aguilar', 'House of Representatives', '26', DATE '2023-01-09'),
  ('edeb1444-3648-4959-bfed-0bdd76bb314f'::uuid, '11b5bce2-70b7-4388-ab8a-f3a694e344dc'::uuid, '1482a2bc-75d8-4aee-865c-53378c415210'::uuid, DATE '2023-01-01', 'year', 'Quantá Crews', 'House of Representatives', '26', DATE '2023-06-07'),
  ('555d4158-8503-4ffd-97f5-a39a2d9cba31'::uuid, '6a51cf93-2e17-4461-9fe9-cfb9b007b61b'::uuid, '558dc1d6-0365-4707-8373-4ef188aff71c'::uuid, DATE '2025-01-06', 'day', 'Lisa Fink', 'House of Representatives', '27', DATE '2025-01-13'),
  ('dd713229-fa9a-4516-a105-6a1b5eb8cea2'::uuid, 'c6c04c6a-e637-4ce1-9170-9424c5dda192'::uuid, '9c481b8d-e373-4409-bccb-bde6534882da'::uuid, DATE '2025-01-06', 'day', 'Tony Rivero', 'House of Representatives', '27', DATE '2025-01-13'),
  ('4de8a002-43c4-4e4c-8549-92de64100cc5'::uuid, 'f7cad0ce-e9af-46a1-a39d-d5d4520d3879'::uuid, '43e734b4-4417-4dcd-91c9-f420f3a1b702'::uuid, DATE '2023-01-02', 'day', 'David Livingston', 'House of Representatives', '28', DATE '2023-01-09'),
  ('78e2ec0a-1107-4cd4-8c6f-efab62105925'::uuid, '87c65dff-fa5b-4d7a-a7bc-d78595d2f506'::uuid, '184bd445-9f61-4bd3-859f-22522c9ccabd'::uuid, DATE '2023-01-02', 'day', 'Beverly Pingerelli', 'House of Representatives', '28', DATE '2023-01-09'),
  ('44deb772-1b54-42c0-9458-b085f316664d'::uuid, '9d6fd1f4-0372-4576-a7d1-77b09eed2de4'::uuid, '47071c20-df9d-4f9d-9329-25faf64cd163'::uuid, DATE '2023-01-02', 'day', 'Steve Montenegro', 'House of Representatives', '29', DATE '2023-01-09'),
  ('262887b0-cecd-429f-be12-d867e2de6ab8'::uuid, 'f24344a4-241b-4555-8eee-31027d4c8437'::uuid, 'ee80504a-fe2d-45e1-8bbe-ce0a5042d2b8'::uuid, DATE '2025-01-06', 'day', 'James Taylor', 'House of Representatives', '29', DATE '2025-01-13'),
  ('a0fb930a-9910-4014-9ed7-df0eaa8d1ac5'::uuid, 'f04e0b05-9d07-4f0d-b4a9-c9dd784545fe'::uuid, '178470c3-94ea-442a-a558-7b3c841ce858'::uuid, DATE '2023-01-02', 'day', 'Alexander Kolodin', 'House of Representatives', '3', DATE '2023-01-09'),
  ('eab482f7-e64c-4e12-862e-8c795f1323dd'::uuid, '96813bd4-be49-4ee2-bee2-acfcb5d8675c'::uuid, '85937da6-85eb-4d10-946f-2ed3c391a9c9'::uuid, DATE '2026-01-01', 'year', 'Cody Reim', 'House of Representatives', '3', DATE '2026-03-18'),
  ('c510113a-5e3a-435b-8b9d-379a7dd483a3'::uuid, '7fbab045-07c3-4f8b-aedc-a1fe0bac21d9'::uuid, 'b1b97401-d1a9-4442-9f78-2749f1853f6e'::uuid, DATE '2023-01-02', 'day', 'Leo Biasiucci', 'House of Representatives', '30', DATE '2023-01-09'),
  ('f69c90b3-bc75-4bab-b225-bce0163c77c7'::uuid, 'ae116c94-7533-46d0-aa81-20106f5cb572'::uuid, '50d00238-5334-4616-ac43-72375f53df71'::uuid, DATE '2023-01-02', 'day', 'John Gillette', 'House of Representatives', '30', DATE '2023-01-09'),
  ('12e33966-2f80-4ae9-8133-add3347d9de2'::uuid, '4c6ec932-915f-4361-8564-3d7102af82ae'::uuid, '23675559-e2dd-4e26-abed-2f87954dc70e'::uuid, DATE '2025-01-06', 'day', 'Pamela Carter', 'House of Representatives', '4', DATE '2025-01-13'),
  ('55ee64af-c69d-4c73-8043-38eb7cbc53a1'::uuid, '4021cde6-9098-442f-8126-55f6377a328f'::uuid, '5293ff0f-0365-4943-89a5-f4017566c8dd'::uuid, DATE '2023-01-02', 'day', 'Matt Gress', 'House of Representatives', '4', DATE '2023-01-09'),
  ('7e45dc7f-5834-4fea-b825-a697ec2256b1'::uuid, 'cd1412f0-c4c7-4f2a-bbef-b22516834ed4'::uuid, '0df9cd85-3923-48bd-86c2-b7d4b31d510d'::uuid, DATE '2025-01-06', 'day', 'Aaron Márquez', 'House of Representatives', '5', DATE '2025-01-13'),
  ('1cedf970-9497-4c71-9851-379b55cdaba0'::uuid, 'a2f6412a-484e-44b1-9d31-bd172ad85472'::uuid, 'eb8215ef-5e68-431a-a5cf-c226e8c0abf1'::uuid, DATE '2024-01-01', 'year', 'Sarah Liguori', 'House of Representatives', '5', DATE '2024-02-08'),
  ('d5bb91aa-d85d-477b-9d03-9f0f0fe08365'::uuid, '518b5c7d-86ad-4d3a-90b0-4fb1b87cfbf4'::uuid, 'fe4cbf96-b145-48d7-9fcf-120e6b75c290'::uuid, DATE '2023-01-02', 'day', 'Mae Peshlakai', 'House of Representatives', '6', DATE '2023-01-09'),
  ('6c6609b0-c072-42cf-99f7-c34adb1262a6'::uuid, '7ea6b86e-7e98-468e-9518-3144a3a09053'::uuid, '47a75797-e525-4dd9-ab04-66dd4d667760'::uuid, DATE '2023-01-02', 'day', 'Myron Tsosie', 'House of Representatives', '6', DATE '2023-01-09'),
  ('f3a14633-3bce-44c4-8b0f-b6ea3a569958'::uuid, '45c71c81-9521-463b-ac13-e74c82c66057'::uuid, 'a88f4ecd-5c4f-4caf-a88c-1d06c92bfdc7'::uuid, DATE '2025-01-06', 'day', 'Walt Blackman', 'House of Representatives', '7', DATE '2025-01-13'),
  ('f10cebd8-07c5-4b0a-9144-e75b984573c4'::uuid, '5b4f6b5e-725a-44bf-8df2-768af2afa1db'::uuid, '9f5a84e0-0195-4459-ab6e-b3ae09404d2e'::uuid, DATE '2026-01-01', 'year', 'Sylvia Allen', 'House of Representatives', '7', DATE '2026-04-29'),
  ('5c10abde-d6c6-4942-b044-271443c6cad8'::uuid, 'eef94203-b5e2-4cb6-a2d7-fd8043a1ce0c'::uuid, 'd6f22ab7-5f0a-4d58-b53a-fd69bf4ad556'::uuid, DATE '2025-01-06', 'day', 'Janeen Connolly', 'House of Representatives', '8', DATE '2025-01-13'),
  ('674b6df6-5a44-4dba-8dab-3c8eebe6775a'::uuid, '94f56241-8eb9-40b2-a98b-c3f609924f50'::uuid, 'ea0e5f51-f963-45ef-a104-429af91e5f90'::uuid, DATE '2025-01-06', 'day', 'Brian Garcia', 'House of Representatives', '8', DATE '2025-01-13'),
  ('51f63068-9094-46c5-a7ca-abb4f42ae2a2'::uuid, '3a8c14ef-abb0-411c-b201-ee7f74fccee5'::uuid, '329dc518-7749-4671-b448-3ddaa396da9c'::uuid, DATE '2023-01-02', 'day', 'Seth Blattman', 'House of Representatives', '9', DATE '2023-01-09'),
  ('632fef8f-eae9-4540-8ea8-8f9a1d12e196'::uuid, '90010f9e-c0bc-496c-82bb-d02b2b65c04c'::uuid, 'e2bd3486-1fcf-4726-8df8-564ad8ef2b62'::uuid, DATE '2023-01-02', 'day', 'Lorena Austin', 'House of Representatives', '9', DATE '2023-01-09'),
  ('967294e6-4656-4b81-bf77-441d56df6d34'::uuid, '124f5425-d00d-4a54-8505-74e25b80cceb'::uuid, '489e2fc3-b47a-4304-b959-07e35f010da4'::uuid, DATE '2025-01-06', 'day', 'Mark Finchem', 'State Senate', '1', DATE '2025-01-13'),
  ('8f9f950f-5267-4f4c-bc7c-3af02e4698d3'::uuid, '163c526e-52ff-4a6d-9475-021a9099bc70'::uuid, '7ab7c163-bfac-4a95-8b94-22d1a4395522'::uuid, DATE '2023-01-02', 'day', 'David C. Farnsworth', 'State Senate', '10', DATE '2023-01-09'),
  ('7cb9d88d-799c-438b-967f-aa5664e2e383'::uuid, '8f7bea95-f64e-47c9-92f1-33f9abbcf29c'::uuid, 'f1b19116-3c6f-4c44-9faf-bc32db5fc5d2'::uuid, DATE '2023-01-02', 'day', 'Catherine Miranda', 'State Senate', '11', DATE '2023-01-09'),
  ('473dad9c-5172-4644-845e-ca94919cd5d5'::uuid, '29413af2-7eaa-48ee-ae8d-733cb0416b51'::uuid, 'feecd8fc-b007-450a-8779-8e6f68e80dd6'::uuid, DATE '2023-01-02', 'day', 'Denise "Mitzi" Epstein', 'State Senate', '12', DATE '2023-01-09'),
  ('ef01fe0a-a8f0-48d1-bfea-f782b0a39853'::uuid, '9e2dd4d3-2bc2-473d-b255-d418f11cb757'::uuid, '09ae25a4-9244-455a-960a-b95223bb52d8'::uuid, DATE '2023-01-02', 'day', 'J.D. Mesnard', 'State Senate', '13', DATE '2023-01-09'),
  ('4353802d-e9e4-4417-98e3-de76b9d7be19'::uuid, '8371ec8f-eb82-4726-81a1-fce6dab10808'::uuid, '49b806b1-f15d-4998-a94e-de542d9e323e'::uuid, DATE '2023-01-02', 'day', 'Warren Petersen', 'State Senate', '14', DATE '2023-01-09'),
  ('84485746-991d-4d87-8978-ff3ed4583058'::uuid, 'cd9644aa-ae19-4f20-bde2-6099f5ac57cc'::uuid, '66ca210e-deab-4d07-8a18-48f7079f6f9b'::uuid, DATE '2023-01-02', 'day', 'Jake Hoffman', 'State Senate', '15', DATE '2023-01-09'),
  ('d00a6ab5-3e78-48f9-9a00-ba515a9990f1'::uuid, '3451fbc8-ec4d-48c2-a93c-19f135d84bf3'::uuid, '8bbf9f70-adee-4801-ab19-7b78f9e70aa1'::uuid, DATE '2023-01-02', 'day', 'Thomas "T.J." Shope', 'State Senate', '16', DATE '2023-01-09'),
  ('2025b94d-50d9-4c89-a3c1-f7c843ced8eb'::uuid, '1c071d4b-1744-4677-880d-bc2c3ce5e4fa'::uuid, 'c2ee942d-72dc-4e50-8b78-dfe0a6ce8f93'::uuid, DATE '2025-01-06', 'day', 'Venden "Vince" Leach', 'State Senate', '17', DATE '2025-01-13'),
  ('aa9b8c91-1862-4511-974f-d6d953bc9e38'::uuid, 'ecd464a9-8592-4566-af67-742f46364ffe'::uuid, '179e2cdb-395e-4f7f-a5e1-775ff176ce64'::uuid, DATE '2023-01-02', 'day', 'Priya Sundareshan', 'State Senate', '18', DATE '2023-01-09'),
  ('fcf388fb-6e84-473f-b2a9-000d5a801603'::uuid, 'fe457319-058b-4dc5-8540-dac64a6a328f'::uuid, 'e71471f4-bef5-46ef-a1f2-f19f275b558d'::uuid, DATE '2023-01-02', 'day', 'David Gowan', 'State Senate', '19', DATE '2023-01-09'),
  ('5061b9ed-3129-4ee9-a4ef-fac05c338e22'::uuid, '6ddab4ec-20d4-4a25-a03f-6bf0dceb0be3'::uuid, '2785d691-2404-400e-8dde-bcc5a58e419b'::uuid, DATE '2023-01-01', 'year', 'Shawnna Bolick', 'State Senate', '2', DATE '2023-07-23'),
  ('b20f9bf5-9273-4134-bbfc-9144fc9500b3'::uuid, '41be187f-a14b-4ae6-9641-7b6f7a523599'::uuid, '82f31f9c-754b-4417-bc21-af295b2b4d2b'::uuid, DATE '2023-01-02', 'day', 'Sally Ann Gonzales', 'State Senate', '20', DATE '2023-01-09'),
  ('182eb11b-a959-4eb5-b6fa-0b467e5d0045'::uuid, 'c803118a-5434-414e-9795-d50fb770af61'::uuid, '8cbc6c91-4147-4831-ae0e-f4658ce282e8'::uuid, DATE '2023-01-02', 'day', 'Rosanna Gabaldón', 'State Senate', '21', DATE '2023-01-09'),
  ('cc5a2b2d-3b34-4dd1-96e7-856c8e4ad2b5'::uuid, '69161de6-f29f-4b38-b92c-7c2b471e59f2'::uuid, '901398ea-3180-4b6d-8ba4-9f0dd85d7bb1'::uuid, DATE '2023-01-02', 'day', 'Eva Diaz', 'State Senate', '22', DATE '2023-01-09'),
  ('de1526a6-4bf1-4ef3-8b42-894dc499e6d4'::uuid, '7498c0e1-8652-4f8d-a82d-52e8be764cb4'::uuid, '2aa0cf37-6c3a-405d-9cd2-0fafc7cf8636'::uuid, DATE '2023-01-02', 'day', 'Brian Fernandez', 'State Senate', '23', DATE '2023-01-09'),
  ('e1eaed90-1f3c-4bc9-8c09-32c57f2f3720'::uuid, '61fd47dd-1cd3-4be9-a53e-2558dd662edf'::uuid, 'bb540c4b-e5d2-40b9-bdaf-e41a721572f8'::uuid, DATE '2025-01-06', 'day', 'Analise Ortiz', 'State Senate', '24', DATE '2025-01-13'),
  ('4f37aa12-100f-4ab0-bf4b-857e24c6beab'::uuid, '2cd14bdb-de24-47b9-b5f7-02afa4038533'::uuid, 'ebef00e8-7722-4e9b-b5dc-ef95a41a9a40'::uuid, DATE '2025-01-06', 'day', 'Timothy "Tim" Dunn', 'State Senate', '25', DATE '2025-01-13'),
  ('62e45aeb-4cb5-47e3-b27d-561e0b204abd'::uuid, '2f52f6ed-eb9c-472d-9cb9-ba279ed96267'::uuid, '4046a3d6-87ba-41bb-afd8-422f017c851b'::uuid, DATE '2023-01-01', 'year', 'Flavio Bravo', 'State Senate', '26', DATE '2023-05-08'),
  ('44aea864-f0c3-422f-91d9-1d519334c153'::uuid, '3b68f8ca-249f-4e82-be6a-7cf9b190ac04'::uuid, '0b0dc6ea-ed45-45e6-9a59-41d1c8aeb53c'::uuid, DATE '2025-01-06', 'day', 'Kevin Payne', 'State Senate', '27', DATE '2025-01-13'),
  ('4dd81fc8-8542-43c2-ad41-ef4d9b88e3d7'::uuid, '9a6106f5-9ecc-4b66-8085-5395d7eaaf79'::uuid, '376698b5-a276-4977-b2c3-3d15a822f7d8'::uuid, DATE '2023-01-02', 'day', 'Frank Carroll', 'State Senate', '28', DATE '2023-01-09'),
  ('ef33b183-9cdd-4eaa-8095-43e2baed79de'::uuid, '2aed98f5-ab9e-49d3-b6be-e8fd257518cd'::uuid, '687e6f07-f71a-41b4-8525-b509b2cebb42'::uuid, DATE '2023-01-02', 'day', 'Janae Shamp', 'State Senate', '29', DATE '2023-01-09'),
  ('ae293f53-591d-47f5-b8f8-365cf9462368'::uuid, '80d6f6f6-c62b-46a8-ae32-725e8a8a8f06'::uuid, '4f7db8ce-def5-4225-b183-654f8f64cb9a'::uuid, DATE '2023-01-02', 'day', 'John Kavanagh', 'State Senate', '3', DATE '2023-01-09'),
  ('a8249e28-4efa-46ae-b0f1-40b6812d84b0'::uuid, 'd73f3e7b-05af-4593-a265-2c04062fb8c5'::uuid, '4fe779de-6a47-4321-82f1-ced096543a68'::uuid, DATE '2025-01-06', 'day', 'Hildy Angius', 'State Senate', '30', DATE '2025-01-13'),
  ('dbbc4d5b-8b6d-4380-86db-a70924a4a4ab'::uuid, 'd13d9c57-2851-48fb-a1a6-0b181f449453'::uuid, 'b769f53e-c9e5-4259-9e00-c20bfa945d15'::uuid, DATE '2025-01-06', 'day', 'Carine Werner', 'State Senate', '4', DATE '2025-01-13'),
  ('1760ab13-8c38-4138-8395-871364fd0780'::uuid, '1c197b51-fded-441e-a72a-de51329efe42'::uuid, '64520134-c1e3-44b1-aeb5-ed3e8762972d'::uuid, DATE '2023-01-02', 'day', 'Lela Alston', 'State Senate', '5', DATE '2023-01-09'),
  ('a53b34c1-b1e6-48f6-80df-c9b0b76929ba'::uuid, 'd60e1b27-c31c-4daf-8443-691f6d9d07ef'::uuid, '5443de2a-bad1-4271-a8ac-30e7443ff605'::uuid, DATE '2023-01-02', 'day', 'Theresa Hatathlie', 'State Senate', '6', DATE '2023-01-09'),
  ('0a04d432-bb15-444c-a1bf-acd669474a57'::uuid, '8a24929f-d3f4-4a39-b8e8-8fa104e6e3be'::uuid, '23b7d096-37ad-4b00-8291-c7f0640a22d2'::uuid, DATE '2023-01-02', 'day', 'Wendy Rogers', 'State Senate', '7', DATE '2023-01-09'),
  ('6f0cb9a9-4cc5-4b5d-bf34-45607709bd4d'::uuid, '74d0aeb0-1190-490d-9070-808285320941'::uuid, '68308cfb-52ff-4a9c-8363-9a582ea9a989'::uuid, DATE '2025-01-06', 'day', 'Lauren Kuby', 'State Senate', '8', DATE '2025-01-13'),
  ('82dff8ee-0c78-40a4-8ebd-d5775575e9bb'::uuid, 'd3a57fa6-1814-4bf0-832b-7d8a6a03fd18'::uuid, 'fef8eb85-8360-418d-8239-ccf3a823608b'::uuid, DATE '2025-01-01', 'year', 'Kiana Sears', 'State Senate', '9', DATE '2025-03-31');

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM ca0295_terms;
  IF v_n <> 90 THEN RAISE EXCEPTION 'CA_0295: expected 90 staged rows, found %', v_n; END IF;
END $$;

UPDATE essentials.office_terms ot
   SET term_start = t.term_start,
       start_precision = t.start_precision,
       source = ot.source || ' | term_start ' || t.start_precision || ' from OpenStates people@bf4caf1 (tenure start '
                || t.openstates_start || '), checked against the AZ legal term-start day and the official roster 2026-09-26 (CA_0295)'
  FROM ca0295_terms t
 WHERE ot.id = t.term_id AND ot.office_id = t.office_id AND ot.politician_id = t.politician_id
   AND ot.term_end IS NULL AND ot.term_start IS NULL AND ot.start_precision = 'unknown';

DO $$
DECLARE v_done int; v_day int; v_year int;
BEGIN
  SELECT count(*) FILTER (WHERE ot.term_start = t.term_start AND ot.start_precision = t.start_precision),
         count(*) FILTER (WHERE ot.start_precision = 'day' AND t.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year' AND t.start_precision = 'year')
    INTO v_done, v_day, v_year
    FROM ca0295_terms t JOIN essentials.office_terms ot ON ot.id = t.term_id;
  IF v_done <> 90 OR v_day <> 79 OR v_year <> 11 THEN
    RAISE EXCEPTION 'CA_0295: expected 90 dated terms (79 day / 11 year), found % (% day / % year)', v_done, v_day, v_year;
  END IF;
  IF EXISTS (SELECT 1 FROM ca0295_terms t JOIN essentials.office_terms ot ON ot.id = t.term_id WHERE ot.source LIKE '%| unverified%') THEN
    RAISE EXCEPTION 'CA_0295: a dated term carries an "| unverified" tag';
  END IF;
  -- Every dated tenure still belongs to the current holder of its seat.
  IF EXISTS (SELECT 1 FROM ca0295_terms t LEFT JOIN essentials.office_current_holder och
               ON och.office_id = t.office_id AND och.politician_id = t.politician_id WHERE och.office_id IS NULL) THEN
    RAISE EXCEPTION 'CA_0295: a dated term is no longer the current holder of its seat';
  END IF;
END $$;

COMMIT;
