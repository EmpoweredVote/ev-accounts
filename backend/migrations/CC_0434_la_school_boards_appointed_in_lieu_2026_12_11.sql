-- CC_0434 — seat the LA County school board members appointed in lieu of election,
-- at the Educ. Code 5017 commencement of 2026-12-11.
--
-- 🟢 THE PATTERN THIS COPIES IS RENO'S, AND IT IS THE POINT. `CC_0387` wrote Reno's three terms
-- in advance at day precision; on 2026-11-13 the view flipped by itself and nobody had to be
-- awake. These 85 terms start on 2026-12-11, so until that date
-- `office_current_holder` keeps returning the sitting member and on the day it changes with no
-- further migration. ⚠ The flip happens at UTC midnight, which is 16:00 Pacific on 12-10.
--
-- ── WHY THESE PEOPLE ARE SEATED WITHOUT A RESULT ────────────────────────────────────────────
-- Their elections were CANCELLED. Under Elec. Code 10515 a county may cancel an election where
-- the candidates do not exceed the seats, and Educ. Code 5328 then seats those who filed as if
-- elected. So there is no vote to wait for and no certification to come: the outcome was settled
-- in August, and 2026-12-11 is simply when the term begins.
--
-- 🔴🔴 OUR OWN DATA CANNOT TELL A CANCELLED ELECTION FROM A HELD, UNCONTESTED ONE. Both are
-- one candidate against one seat, `result` NULL and `candidate_status` 'active'. They need
-- OPPOSITE handling — one is seated now, the other must be certified first — and the only thing
-- that distinguishes them is the county's own publication:
--
--   **FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION DUE TO INSUFFICIENCY
--   OF CANDIDATES**, Los Angeles County Registrar-Recorder/County Clerk, revised 8/25/2026
--   (content.lavote.gov/docs/rrcc/documents/canceled-elections-november-2026657f209d-ee3c-40ff-9167-8d1bd772b5c8.pdf)
--
-- 🟢 THE SHAPE AND THE AUTHORITY AGREE ROW FOR ROW. 96 of the 197 offices in the 2026-12-11
-- cohort match `candidates <= seats and no winner`; 96 appear on the county's final list; and
-- they are the SAME 96 — nothing is on one and not the other. That is why the shape predicate is
-- trusted here, and it is a measurement rather than an assumption. The reconciliation is
-- `backend/data/ca-2026-swearing-in/reconcile-12-11-cohort.mjs`.
--
-- ⚠ THE TENTATIVE LIST IS NOT THE FINAL ONE, AND BOTH ARE PUBLISHED. No school election was
-- un-cancelled between them, checked rather than assumed; the only row that left was a
-- placeholder reading "Information is forth coming" where the CITIES section had not yet been
-- compiled.
--
-- 🔴 A SCHOOL SEAT IS NOT ALWAYS UNDER A SCHOOL HEADING. The list files
-- "Pasadena (Pasadena Unified School District Board of Education 5)" under **CITIES**, because
-- that seat is consolidated with the city's election. A reader bounded to the four school
-- sections drops it silently, which is why the parser reads every section and the caller filters.
--
-- 🔴 THE ASTERISK ON THAT LIST IS A SECOND, OPPOSITE REASON. Its footnote reads "*Cancelled
-- Elections Due to No Candidates" — nobody filed, so there is nobody to appoint and the seat
-- becomes a vacancy for the board to fill. Gorman Joint Elementary (Full Term) is the only
-- school seat so marked, we hold no office for it, and it is NOT seated here. Seating an
-- asterisked row would invent an officeholder out of an empty race.
--
-- ── WHAT THIS FILE DELIBERATELY LEAVES OUT: 30 CANDIDACIES ───────────────────────────
--   El Monte City School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Monte City School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Monte City School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Rancho Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Rancho Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Rancho Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Segundo Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Segundo Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   El Segundo Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hawthorne School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hawthorne School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hawthorne School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hermosa Beach City School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hermosa Beach City School Board :: at-large board (3 of 3 seats) — no determinate office
--   Hermosa Beach City School Board :: at-large board (3 of 3 seats) — no determinate office
--   Manhattan Beach Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Manhattan Beach Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Manhattan Beach Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Norwalk-La Mirada Unified School Board - Trustee Area 5 :: candidate has no politician_id
--   Rosemead School Board :: at-large board (3 of 3 seats) — no determinate office
--   Rosemead School Board :: at-large board (3 of 3 seats) — no determinate office
--   Rosemead School Board :: at-large board (3 of 3 seats) — no determinate office
--   San Marino Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   San Marino Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   San Marino Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Walnut Valley Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Walnut Valley Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   Walnut Valley Unified School Board :: at-large board (3 of 3 seats) — no determinate office
--   West Covina Unified School Board :: at-large board (2 of 2 seats) — no determinate office
--   West Covina Unified School Board :: at-large board (2 of 2 seats) — no determinate office
--
-- 🔴 THE AT-LARGE BOARDS ARE A MODELLING PROBLEM, NOT A MISSING SOURCE. Each is FIVE office rows
-- all titled `Board Member`, all currently seated, and the race points at exactly ONE of them
-- while carrying `seats = 3`. Three people cannot enter one office, and nothing in the title
-- says which three of the five seats are up. The discriminator exists — the five rows carry
-- different `term_start` values, and El Monte City's own sources even record "Unexpired term
-- ending December 11, 2026" — so this is solvable, but choosing WHICH seat a NEWCOMER takes is a
-- claim about who replaced whom. That is a decision, so it is not guessed here. See
-- `backend/data/ca-2026-swearing-in/NOTES.md`.
--
-- ⚠ Norwalk-La Mirada Trustee Area 5's filed candidate has no `politicians` row, so there is no
-- person to seat. It needs a person created first and is the only one of its kind here.
--
-- @incumbency-decision: gated — this inserts an `essentials.office_terms` row per seat and
-- `seat_officeholder` closes each predecessor, so it writes dates on BOTH sides of 85 seatings.
--
-- Dry run: node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0434_la_school_boards_appointed_in_lieu_2026_12_11.sql

BEGIN;

-- The seatings this file performs. Generated by
-- backend/data/ca-2026-swearing-in/emit-cc0434-seating.mjs, which refuses every row described above.
CREATE TEMP TABLE cc0434_seatings ON COMMIT DROP AS
SELECT * FROM (VALUES
    ('70d06178-7488-4e81-8c09-8b5a6ac52551'::uuid, 'dc150a80-e4ab-4418-a09a-a341af6ac251'::uuid, 'Ernie Nishii', 'ABC Unified School Board - Trustee Area 3'),
    ('97cb9724-5fa3-4bfa-ac1d-ac9aee23ab0d'::uuid, 'f2715154-935c-434b-aff6-8a18f28bacad'::uuid, 'Olga Rios', 'ABC Unified School Board - Trustee Area 6'),
    ('8988a457-e7f9-438e-9d4c-a2011f2e3e6d'::uuid, 'b850d1d7-d65f-4fdb-8b8d-7e5d1725e60f'::uuid, 'Ken Pfalzgraf', 'Acton-Agua Dulce Unified School Board - Trustee Area 1'),
    ('ed2b10e2-5e04-4425-b870-87845fedde47'::uuid, 'b345335d-4598-45c1-baf7-138c5b566523'::uuid, 'Geraldine Rose Davis-Duzick', 'Acton-Agua Dulce Unified School Board - Trustee Area 2'),
    ('a41d946e-010d-4fab-8cf3-ff24e7e927c9'::uuid, '943a78a2-a347-4dfa-9e33-f4f6ee8fb970'::uuid, 'Nora Corona Hernandez', 'Alhambra Unified School Board - Trustee Area 2 (Special Election, unexpired term to Dec 2028)'),
    ('d92a0907-77ce-4d5a-afde-22586ccbac00'::uuid, 'c293c5d6-ec08-4676-a03a-0897cc5c555a'::uuid, 'Jennifer Love Tang', 'Alhambra Unified School Board - Trustee Area 4'),
    ('da06deec-0ce3-45f5-a21a-1cc1520d1560'::uuid, '28adb02d-31c9-4172-8e71-cf57846fa197'::uuid, 'Fred L. Chang', 'Alhambra Unified School Board - Trustee Area 5'),
    ('955d3a0a-60e8-4e2b-a389-0dc097edd092'::uuid, '6075a347-8818-5ec4-ad08-9a20518aa22b'::uuid, 'Carla Corona', 'Antelope Valley Joint Union High School Board - Trustee Area 4'),
    ('b071d0ff-5bce-410d-bfb9-fb25246c6618'::uuid, '46a41762-434e-506a-bf5e-c003c3ab828c'::uuid, 'Miguel Sanchez IV', 'Antelope Valley Joint Union High School Board - Trustee Area 5'),
    ('12664b50-03e4-4674-8039-91842da9dd42'::uuid, 'ca5f5d74-ff41-479f-a0b5-bfe7ee70b98a'::uuid, 'Cynthia Arvizo', 'Azusa Unified School Board - Trustee Area 1'),
    ('abc71d2d-29d3-47ec-bb00-57196a68025e'::uuid, '180a7677-5c29-4550-adae-3ddee9a7654e'::uuid, 'Sandra Benavides', 'Azusa Unified School Board - Trustee Area 3'),
    ('0cf876ec-cad5-47de-9976-9bb58a18a565'::uuid, '7bf55310-b753-43db-8838-6bd61095b3d9'::uuid, 'Amie Stewart', 'Bellflower Unified School Board - Trustee Area 1'),
    ('4698fc27-1d9d-450e-9205-af84a0a950f2'::uuid, 'b6870f69-34a2-417b-9251-efcc22817bec'::uuid, 'Derek Bahmanou', 'Bonita Unified School Board - Trustee Area 2'),
    ('b6db7900-474c-4775-82ed-5f6acf2edb5b'::uuid, 'ddb81d47-3c7e-4bb3-84e3-b4427ddf52e9'::uuid, 'Selina Garcia', 'Bonita Unified School Board - Trustee Area 3'),
    ('dc05ab2d-3536-4c10-ac39-3fb16138a833'::uuid, 'c7fb212d-50f3-49e0-85b2-7dbabe9fc35d'::uuid, 'George Michel Saikali', 'Burbank Unified School Board - Trustee Area 4'),
    ('d673dbbc-47b5-41f5-b4c5-1a54b2feef2f'::uuid, 'c8dace65-f8ae-5032-a2b7-4757a821a178'::uuid, 'Laura Pearson', 'Castaic Union School Board - Trustee Area B'),
    ('f5a4bfa6-184e-49e8-9618-6c339fa9c3f2'::uuid, 'd3243df7-a7b5-5f42-b277-c51b468e303e'::uuid, 'Vincent Titiriga', 'Castaic Union School Board - Trustee Area D'),
    ('5bb14f72-c6f8-4e3d-a11b-00b233b30312'::uuid, '02890a06-5e9e-550f-9812-1c2af9992041'::uuid, 'Mayreen Burk', 'Castaic Union School Board - Trustee Area E'),
    ('eac642a5-df3e-4e3b-b47f-e1ee738b0824'::uuid, 'fd6ce9a2-b7ef-52cb-8079-5428ad39cdab'::uuid, 'Marisela Ruiz', 'Centinela Valley Union High School Board - Trustee Area 1'),
    ('6245bff0-ee6a-4991-8792-09a35ad63290'::uuid, '148e431d-7313-47cc-ae4f-aadba0f7f33e'::uuid, 'Hugo Rojas', 'Centinela Valley Union High School Board - Trustee Area 2'),
    ('90db7b74-576a-44fb-acda-b0b9009e7c70'::uuid, '1d2f9313-f72f-5595-89a8-f41faa903db9'::uuid, 'Estefany A. Castañeda', 'Centinela Valley Union High School Board - Trustee Area 5'),
    ('64ed20c6-1647-5c0b-89e7-96a61cbc2119'::uuid, '5c2847a8-aace-5c87-8059-f6046573e2aa'::uuid, 'Shin Liu', 'Cerritos Community College Board - Trustee Area 5'),
    ('2df051b6-9896-5b40-bd30-b37e66c5e74e'::uuid, '48d4f532-32e4-5942-9479-e5d596715a3d'::uuid, 'Zurich Lewis', 'Cerritos Community College Board - Trustee Area 7'),
    ('0f38962d-d0fb-478d-87cc-45a17bcabd0e'::uuid, 'dc3d301b-e099-465e-9501-617d3d618c90'::uuid, 'Erica Landmann', 'Charter Oak Unified School Board - Trustee Area 1'),
    ('e57c4d4c-229a-42c2-8299-0e454c5e015d'::uuid, '8cfaf61f-a132-4822-88eb-c3b3cb33510f'::uuid, 'Gregg Peterson', 'Charter Oak Unified School Board - Trustee Area 4'),
    ('a6c5d610-57d1-5203-b87b-9ef892d4a425'::uuid, 'f2d03af4-a387-59cb-8186-54f6f515bb3f'::uuid, 'Anthony W. Contreras', 'Citrus Community College Board - Trustee Area 1'),
    ('5252c4de-e6aa-591e-8e0c-40351bdd8b76'::uuid, '4489bf61-5134-5742-9037-47240d626353'::uuid, 'Cheryl Alexander', 'Citrus Community College Board - Trustee Area 3'),
    ('e0f8f6ea-e6d3-447e-9412-c361a0608893'::uuid, '482a6c4f-03af-4bae-ba97-305730a7a21b'::uuid, 'Valerie Rountree', 'Claremont Unified School Board - Trustee Area 3'),
    ('a63f5e88-ae36-40c1-a0b6-03360c5007c0'::uuid, '86cda689-ec82-4dbe-b63e-a53508369139'::uuid, 'Alex McDonald', 'Claremont Unified School Board - Trustee Area 4'),
    ('8707f79f-8c1d-4584-8c2c-b2bb0ff0d072'::uuid, '43fc87d5-f714-4ab0-a914-af454f3ba1f4'::uuid, 'Rachael Robles', 'Covina-Valley Unified School Board - Trustee Area 2'),
    ('1ba6a053-5561-4886-b643-d96830454526'::uuid, 'c876e910-1a76-4a87-b632-a1209aa93448'::uuid, 'Tyrone Conde', 'Downey Unified School Board - Trustee Area 1'),
    ('e88ca57e-d1ce-4f3b-a84b-43b2dc979910'::uuid, 'f1a3e9aa-23fb-43cc-8960-7aaea0496a8e'::uuid, 'Nancy A. Swenson', 'Downey Unified School Board - Trustee Area 5'),
    ('6e252cd7-4b7e-4af2-a58b-1fa1f88f3e4e'::uuid, '2a20a861-c1c8-4879-9ac6-c38244e71f3a'::uuid, 'Norman Anderson', 'Duarte Unified School Board - Trustee Area 4'),
    ('89ce3183-4fe6-4c74-b174-d65cb4f35a29'::uuid, '19c3b72e-2b96-5e30-b58f-db7869af2ac7'::uuid, 'Roger L. Price', 'Eastside Union School Board - Trustee Area 3'),
    ('070f2183-8233-577a-8891-f1ea5022b07f'::uuid, '6e164a30-75f2-59bb-87cd-8cd8ccd9d4cb'::uuid, 'Nilo Vega Michelin', 'El Camino Community College Board - Trustee Area 2'),
    ('17fc9282-419e-4d49-95f2-182abce3f7bd'::uuid, '378cba56-08f7-5bba-ba64-22c1f515cfb7'::uuid, 'Andrew J. Yam', 'Garvey School Board - Trustee Area 1'),
    ('2a138c9d-d32e-43fc-885f-02a2aabee3f6'::uuid, 'dd2eccee-d3d8-5198-884d-c0758beb3b20'::uuid, 'Ronald Trabanino', 'Garvey School Board - Trustee Area 3'),
    ('f1fab2ab-232e-4cfa-8620-fc2c3515d4ce'::uuid, 'ada9a7d8-259e-5bbc-be3c-a9c911478e3e'::uuid, 'Paul Duran', 'Garvey School Board - Trustee Area 5'),
    ('49519a74-e017-4dc0-b754-a37be42a3b44'::uuid, 'ce756453-5ebb-456b-b679-0c5223bf5022'::uuid, 'Gary Clifford', 'Glendora Unified School Board - Trustee Area 1'),
    ('ab9bab74-fc52-422b-8f03-1e64c43b2309'::uuid, '13e95b04-a0ad-413b-b6a1-f86b740f9843'::uuid, 'Paul Lopez', 'Glendora Unified School Board - Trustee Area 3'),
    ('05e4d7ac-b5c9-4aee-b95d-dd975004a825'::uuid, '33587b77-1b7d-5c6b-ae0f-f811932a027a'::uuid, 'Terri Moss', 'Hughes-Elizabeth Lakes Union School Board - Trustee Area 1'),
    ('fed881cc-3877-451f-a9a2-683cb213cf94'::uuid, 'e4685a86-a0a7-5f9f-8a3d-53cf1865ab1e'::uuid, 'Raelyn Marshall', 'Hughes-Elizabeth Lakes Union School Board - Trustee Area 2'),
    ('7fe3c13b-7cc4-5e33-8f59-815485de9c17'::uuid, '40829ed9-4fed-5563-83b9-87750b90777f'::uuid, 'Lola Skelton', 'Hughes-Elizabeth Lakes Union School Board - Trustee Area 5'),
    ('4e651b41-ba63-4921-a8f8-64e2c62e4ce5'::uuid, 'ca090dea-fe42-598d-b90d-1cf441b83bf1'::uuid, 'Jullie Eutsler', 'Lancaster School Board - Trustee Area 4'),
    ('466a3b7d-0caa-4f9d-8405-708804d2cfa4'::uuid, '1275ebdd-c7ab-5b41-8932-143ada0bb53e'::uuid, 'Ann M. Phillips', 'Lawndale Elementary School Board - Trustee Area 4'),
    ('500de311-8d8a-5cb6-b832-1536cc0cc397'::uuid, '0272f4a5-c7c4-5d92-88ab-8605e0bf7278'::uuid, 'Uduak-Joe Ntuk', 'Long Beach Community College Board - Trustee Area 1'),
    ('d7208e52-1040-5910-9581-fda775102e72'::uuid, '52c4fafe-3d3b-5e04-9c49-5ed9c2d33433'::uuid, 'Sunny Zia', 'Long Beach Community College Board - Trustee Area 3'),
    ('5d6c83e8-721c-4a68-93ab-844a4d617dfc'::uuid, '8767c472-8a7b-4c77-af90-1eac4d0677bf'::uuid, 'Bryan Galarza', 'Los Nietos School Board - Trustee Area 4'),
    ('aafb5ed7-f658-47f5-9376-aa76bc0d668e'::uuid, 'de280cd0-7351-5719-91be-8b372e3d1dd9'::uuid, 'Catherine Martinez', 'Los Nietos School Board - Trustee Area 5'),
    ('1dde1c1c-67a6-4ae9-b35f-e720d39a8c21'::uuid, 'c2f102f0-82b2-485b-9276-fd860fcc3168'::uuid, 'William Wong', 'Monrovia Unified School Board - Trustee Area 3'),
    ('67ede8d7-0cd4-4e90-840d-043e27d57125'::uuid, 'b672f397-7296-4d8d-be03-a8067da640c1'::uuid, 'Carlos Cerdan', 'Montebello Unified School Board - Trustee Area 1'),
    ('f7e0f453-6f79-4784-a6de-bb82275775f3'::uuid, '4a3eceeb-f4b1-4b2a-80ed-d52fe3747401'::uuid, 'Jennifer Gutierrez', 'Montebello Unified School Board - Trustee Area 3'),
    ('597203e4-33e3-58d5-b94d-3663390a7248'::uuid, '3f1d7029-4a4f-500a-8433-0d9d6266e979'::uuid, 'Gary Chow', 'Mt. San Antonio Community College Board - Trustee Area 2'),
    ('667776f8-1054-5307-a56b-35ad6990ad93'::uuid, '5b4fcd90-0656-54d5-b248-d564bd8d9871'::uuid, 'Robert F. Hidalgo', 'Mt. San Antonio Community College Board - Trustee Area 4'),
    ('07f267b0-3568-5a85-ba9f-2b30a6091f61'::uuid, 'f9695574-91b2-482f-823d-0ee090298ee2'::uuid, 'Judy Chen Haggerty', 'Mt. San Antonio Community College Board - Trustee Area 6'),
    ('b53f0e78-928b-4677-bb10-a9a6085d79f1'::uuid, '1587a0fd-6dbd-4895-a90a-7958ac707c61'::uuid, 'Michelle Kampbell', 'Newhall School Board - Trustee Area 1'),
    ('082dc9f0-d88e-43cd-8f3d-68f836901447'::uuid, '3ae27906-e072-532a-86a8-c73c2654ed08'::uuid, 'Rachelle Haddoak', 'Newhall School Board - Trustee Area 2'),
    ('da853ec8-4d7a-42be-a419-c98a1197ca9d'::uuid, '4eeda961-af9c-587c-a277-32a6d4f02a72'::uuid, 'Ernesto Smith', 'Newhall School Board - Trustee Area 3'),
    ('0ec66343-9444-4474-8be2-9343f776304c'::uuid, '36460189-7e2c-411f-b6fd-81287a04971b'::uuid, 'Sonia Olmos', 'Paramount Unified School Board - Trustee Area 1'),
    ('8f3861f4-0a11-4ae9-b4cc-9c66ae515316'::uuid, '07b9a2d0-4202-4d27-ad22-465bf2c1fe95'::uuid, 'Tricia Bass-Riedel', 'Paramount Unified School Board - Trustee Area 5'),
    ('b1ca1bdb-856a-56aa-a519-68a89621038b'::uuid, '0b39b088-f4f2-587e-92f5-c942387bd9ce'::uuid, 'Alton Wang', 'Pasadena Area Community College Board - Trustee Area 7'),
    ('87635aa2-79bc-4d7d-b087-afb697329210'::uuid, '2518c7a6-f526-4df2-8364-ded34b122f21'::uuid, 'Patrice Marshall McKenzie', 'Pasadena Unified School Board - District 5'),
    ('d0a813bc-891d-4449-b085-a2dad5d34d7c'::uuid, '248c8eac-a348-4a0e-bb10-d670521ed05a'::uuid, 'Patricia Tye', 'Pomona Unified School Board - Trustee Area 5'),
    ('7e153d81-0c87-53bc-b9d1-b0f1a0c6ea4b'::uuid, 'f572f398-7a2d-58ff-899c-eb32285cef83'::uuid, 'Oscar Valladares', 'Rio Hondo Community College Board - Trustee Area 5'),
    ('048f1d08-2b01-5149-856e-e79bbadff8aa'::uuid, '823c68bb-f4fa-52ff-b2fe-bc626cd50aa4'::uuid, 'Carlos Guerrero', 'Santa Clarita Community College Board - Trustee Area 5'),
    ('5a946b9e-8e89-4410-8f96-d5105641eea8'::uuid, '09cda9d4-f94b-4830-b054-6eb13edce5fb'::uuid, 'Janis Ortega', 'South Pasadena Unified School Board - Trustee Area 1'),
    ('e8dd3801-1bdc-4a55-bd52-1c71c7a2f88f'::uuid, '00ee691c-85d9-4549-9063-542467f5e7f7'::uuid, 'Zahir Robb', 'South Pasadena Unified School Board - Trustee Area 4'),
    ('e93511a7-8d11-4b45-8f52-3eaea4c456d4'::uuid, '7b2a0ea7-cbf1-4d20-aa82-77161e9d781b'::uuid, 'Karen Tamis', 'South Pasadena Unified School Board - Trustee Area 5'),
    ('974a5638-0aec-4f36-b413-d8dfee2119e9'::uuid, '64faacf6-4f6a-59e6-9c30-0461cec53584'::uuid, 'Elizabeth Guillen', 'South Whittier School Board - Trustee Area 1'),
    ('21bafe9c-c44a-4c43-add7-7d9dd0dc211e'::uuid, '3c06bce9-b009-548d-a695-f783a0a1abfa'::uuid, 'Natalia Barajas', 'South Whittier School Board - Trustee Area 2'),
    ('ec1e490c-6ce7-4b7a-924c-be2fa974cc7a'::uuid, 'a545cd9e-d294-5bef-9a09-b6ce31a39a20'::uuid, 'Paola Jellings', 'Sulphur Springs Union School Board - Trustee Area 3'),
    ('1b70d3d4-d3b6-4aa8-934e-91812be9ff08'::uuid, '02c8d4a7-63ee-5965-9b37-121087b67380'::uuid, 'Ken Chase', 'Sulphur Springs Union School Board - Trustee Area 4'),
    ('b3349ce4-1d63-439f-be50-eb0ae9eac959'::uuid, 'd7e65bfb-5cb4-545b-a961-3dba3531beaf'::uuid, 'Lori MacDonald', 'Sulphur Springs Union School Board - Trustee Area 5'),
    ('cac7da84-c9ef-4199-b005-d2424549bfad'::uuid, '02305ab9-0643-43ab-8d69-ab631a6b0e21'::uuid, 'Vinson Bell', 'Temple City Unified School Board - Trustee Area 4'),
    ('f4960250-8342-47e9-96dc-31f839b0d546'::uuid, 'f127f879-2625-40b2-ab6e-672d494228e1'::uuid, 'Donna Georgino', 'Temple City Unified School Board - Trustee Area 5'),
    ('1d941c9d-5576-4a37-83f9-eb7a98d9b929'::uuid, '63aff15f-c913-4a61-a38c-cd1a2c800fce'::uuid, 'Catherine "Cat" Bones', 'Torrance Unified School Board - Trustee Area B (Special Election, unexpired term to Dec 2028)'),
    ('84e26ab7-fb02-494e-a10b-92c8ee800042'::uuid, 'ada011d6-e1a0-49e5-ba3a-244641f58e91'::uuid, 'James Han', 'Torrance Unified School Board - Trustee Area C'),
    ('f3e71c3d-adc2-4c32-83f4-2ff95c5dfa78'::uuid, 'd3b01f01-77f3-492b-8810-857259424d6c'::uuid, 'Dave Zygielbaum', 'Torrance Unified School Board - Trustee Area E'),
    ('29f8892a-3f92-4fce-a4a9-7e1fb40603e9'::uuid, 'f0afac39-cab0-5b7a-84f8-8a3c0ac90e1e'::uuid, 'Jennifer De Baca Sandoval', 'Whittier City School Board - Trustee Area 4'),
    ('42248683-bf61-4754-a9f0-daabe7f78741'::uuid, 'a8a5def3-8ce6-5a5a-b355-4ca27b94308c'::uuid, 'Russell Castañeda Calleros', 'Whittier Union High School Board - Trustee Area 1'),
    ('099677aa-53f4-4714-b408-b82189203bc5'::uuid, '4e444a1b-187f-5f22-8f6e-56508f5237c4'::uuid, 'Irma Rodríguez Moisa', 'Whittier Union High School Board - Trustee Area 4'),
    ('c4159526-076e-4cb8-9845-b2b1e9f9aab2'::uuid, '41076964-edd9-4e7b-866f-79680545bb2c'::uuid, 'Cherise Moore', 'William S. Hart Union High School Board - Trustee Area 3'),
    ('2df78c91-3f8b-58cb-bcf2-38120ecebcee'::uuid, '0acea6a3-2323-5423-a922-f5a71a0e9660'::uuid, 'Robert D. Miller', 'Wilsona School Board - Trustee Area 1'),
    ('5cdadc12-668f-4616-85f8-2f244481500c'::uuid, '6cc9f634-de00-5ff6-ae80-7a1dd7699bac'::uuid, 'Anne Misicka', 'Wilsona School Board - Trustee Area 2'),
    ('4f7c7b15-69b8-4bb7-aef2-fa97c50348a6'::uuid, '8d7aaefc-1b95-5214-b0b3-371a5f483dea'::uuid, 'Daniela Sanchez', 'Wilsona School Board - Trustee Area 3')
) AS t(office_id, politician_id, full_name, position_name);

-- 🔴 THE PLAN IS BOTH SIDES OF EVERY SEATING. `seat_officeholder` closes the predecessor's term,
-- so a scope naming only the arrivals would leave the outgoing members' dates unguarded.
CREATE TEMP TABLE cc0434_plan ON COMMIT DROP AS
SELECT politician_id FROM cc0434_seatings
UNION
SELECT och.politician_id
  FROM essentials.office_current_holder och
  JOIN cc0434_seatings s ON s.office_id = och.office_id
 WHERE och.politician_id IS NOT NULL;

-- ── Premise ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0434_seatings;
  IF v_n <> 85 THEN
    RAISE EXCEPTION 'CC_0434: expected 85 seatings, found %.', v_n;
  END IF;

  -- Every office must be in the 2026-12-11 cohort. If one is not, the generator has drifted from
  -- the swearing-in table and the whole premise of the date is gone.
  SELECT count(*) INTO v_bad
    FROM cc0434_seatings s
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_swearing_in si
                      WHERE si.office_id = s.office_id
                        AND si.election_date = DATE '2026-11-03'
                        AND si.swearing_in_date = DATE '2026-12-11');
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) are not in the 2026-12-11 cohort.', v_bad;
  END IF;

  -- One office must appear once. Two rows for one office would mean an at-large board slipped
  -- through the generator's refusal, and the second seating would silently displace the first.
  SELECT count(*) INTO v_bad FROM (
    SELECT office_id FROM cc0434_seatings GROUP BY office_id HAVING count(*) > 1) x;
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) appear more than once.', v_bad;
  END IF;

  -- Nobody may already hold a term starting on the target date: this must not run twice in a way
  -- that writes a second 2026-12-11 term.
  SELECT count(*) INTO v_bad
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_start = DATE '2026-12-11';
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0434: % office(s) already carry a 2026-12-11 term.', v_bad;
  END IF;
END $$;

-- @incumbency-decision: gated — see the header.
CREATE TEMP TABLE incumbency_before ON COMMIT DROP AS
SELECT rc.id              AS race_candidate_id,
       rc.politician_id,
       rc.is_incumbent    AS stored,
       EXISTS (SELECT 1 FROM essentials.office_terms t
                 JOIN essentials.offices o2 ON o2.id = t.office_id
                WHERE t.politician_id = rc.politician_id
                  AND (t.office_id = r.office_id
                       OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                  AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                  AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
              )            AS expected
  FROM essentials.race_candidates rc
  JOIN essentials.races     r  ON r.id  = rc.race_id
  JOIN essentials.offices   ro ON ro.id = r.office_id
  JOIN essentials.elections e  ON e.id  = r.election_id
 WHERE e.election_date >= CURRENT_DATE - INTERVAL '1 year'
   AND rc.politician_id IS NOT NULL
   AND rc.politician_id IN (SELECT politician_id FROM cc0434_plan);

-- Measure the occupancy drift metric before the writes, so the post-verify can gate on the DELTA
-- rather than on a total another session can move (CLAUDE.md).
CREATE TEMP TABLE cc0434_drift_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ── Change ───────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT * FROM cc0434_seatings ORDER BY position_name LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id,
      r.politician_id,
      DATE '2026-12-11',
      'CC_0434: appointed in lieu of election (Elec. Code 10515; seated as if elected, Educ. Code '
      '5328). LA County RR/CC, FINAL LIST OF CANCELED ELECTIONS, November 3, 2026 General '
      'Election, revised 8/25/2026. Term commences 2026-12-11 per Educ. Code 5017.',
      -- 🔴 'appointed', NOT 'elected'. No election was held for these seats; the county's own
      -- document is titled "APPOINTMENT IN LIEU OF ELECTION" and Elec. Code 10515 is an
      -- appointment power. The statute then DEEMS the appointee elected, which is why they take
      -- the seat for a full term — but how they started is an appointment, and that is the fact
      -- this column records.
      p_how_started => 'appointed',
      -- 🔴 MOST OF THESE PEOPLE ALREADY HOLD THE SEAT. An uncontested filing is usually the
      -- sitting member, so the helper's re-election guard fires on them by design: it refuses a
      -- second term for a current holder unless the caller says the re-election is intended.
      -- It is intended here, and the guard did its job — the first run of this file was refused.
      p_allow_reelection => true);
  END LOOP;
END $$;

-- 🔴 `seat_officeholder` DOES NOT CLEAR `is_vacant` — the names suggest symmetry and there is
-- none. A seat left held AND flagged emits a spurious all-NULL office row for the holder.
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id IN (SELECT office_id FROM cc0434_seatings)
   AND is_vacant;

-- ── Post-verify ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_seated int; v_closed int; v_before int; v_after int;
BEGIN
  SELECT count(*) INTO v_seated
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot
      ON ot.office_id = s.office_id AND ot.politician_id = s.politician_id
     AND ot.term_start = DATE '2026-12-11';
  IF v_seated <> 85 THEN
    RAISE EXCEPTION 'CC_0434: expected 85 terms starting 2026-12-11; found %.', v_seated;
  END IF;

  -- Every predecessor must close the day BEFORE, never on the day: two terms may not overlap.
  SELECT count(*) INTO v_closed
    FROM cc0434_seatings s
    JOIN essentials.office_terms ot ON ot.office_id = s.office_id
   WHERE ot.term_end = DATE '2026-12-10';
  RAISE NOTICE 'CC_0434: % predecessor term(s) closed at 2026-12-10', v_closed;

  -- 🔴 NOBODY IS IN OFFICE YET. The whole design is that these terms are in the future, so the
  -- current holder must be UNCHANGED today. If one of these people is already current, the date
  -- went in wrong and voters would be told the wrong officeholder for 26 days.
  IF EXISTS (
    SELECT 1 FROM cc0434_seatings s
      JOIN essentials.office_current_holder och ON och.office_id = s.office_id
     WHERE och.politician_id = s.politician_id
       -- 🔴 `term_start IS NULL` IS AN EARLIER TERM, AND LEAVING IT OUT MAKES THIS GATE LIE.
       -- `current_office_holders` reads a NULL start as "current" (`term_start IS NULL OR
       -- term_start <= CURRENT_DATE`), and a NULL never satisfies `< DATE`, so the first draft
       -- of this gate flagged 9 legitimately-sitting members as impossible and failed the dry
       -- run. The members were right and the comparison was NULL-unsafe.
       AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                        WHERE t.office_id = s.office_id AND t.politician_id = s.politician_id
                          AND (t.term_start IS NULL OR t.term_start < DATE '2026-12-11'))
  ) THEN
    RAISE EXCEPTION 'CC_0434: somebody seated here is already the CURRENT holder without an '
      'earlier term — a 2026-12-11 term must not be current before 2026-12-11.';
  END IF;

  -- No office may be flagged vacant and held at once.
  IF EXISTS (SELECT 1 FROM cc0434_seatings s
               JOIN essentials.offices o ON o.id = s.office_id
              WHERE o.is_vacant) THEN
    RAISE EXCEPTION 'CC_0434: an office seated here is still flagged is_vacant.';
  END IF;

  -- Drift must not rise. It may FALL, if an office here had no term row at all.
  SELECT unflagged INTO v_before FROM cc0434_drift_before;
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_after
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  RAISE NOTICE 'CC_0434: unflagged occupancy drift % -> %', v_before, v_after;
  IF v_after > v_before THEN
    RAISE EXCEPTION 'CC_0434: unflagged drift rose from % to %.', v_before, v_after;
  END IF;
END $$;


DO $$
DECLARE
  v_planned  int;
  v_scoped   int;
  v_people   int;
  v_created  int;
  v_repaired int;
  v_detail   text;
BEGIN
  SELECT count(*) INTO v_planned FROM cc0434_plan;   -- ⚠ REPLACE with your plan table
  SELECT count(DISTINCT politician_id), count(*) INTO v_people, v_scoped FROM incumbency_before;

  -- 🔴 AN EMPTY SCOPE PASSES EVERYTHING BELOW VACUOUSLY, AND IT HAS TWO OPPOSITE CAUSES. Either
  -- nobody you touched has run recently — the common, correct case — or your plan table is not the
  -- one the scope subquery reads, in which case this gate is switched off and looks identical.
  -- Counting the PLAN separately is what tells them apart: "4 planned, 0 with a race" is the first,
  -- "0 planned" is the second. Reading `incumbency_before` alone cannot distinguish them, which is
  -- how an earlier draft of this template reported a deliberately mis-pointed plan as fine.
  IF v_planned = 0 THEN
    RAISE EXCEPTION 'incumbency guard: the plan table is EMPTY, so this gate asserted nothing. '
      'Point it at the politicians whose office_terms rows this migration writes.';
  END IF;
  RAISE NOTICE 'incumbency guard: % person/people planned, % with a race row in the last year (% row(s))',
    v_planned, v_people, v_scoped;

  WITH after_state AS (
    SELECT rc.id              AS race_candidate_id,
           rc.is_incumbent    AS stored,
           EXISTS (SELECT 1 FROM essentials.office_terms t
                     JOIN essentials.offices o2 ON o2.id = t.office_id
                    WHERE t.politician_id = rc.politician_id
                      AND (t.office_id = r.office_id
                           OR (r.seats > 1 AND ro.chamber_id IS NOT NULL AND o2.chamber_id = ro.chamber_id))
                      AND (t.term_start IS NULL OR t.term_start <= e.election_date)
                      AND (t.term_end   IS NULL OR t.term_end   >= e.election_date)
                  )            AS expected
      FROM essentials.race_candidates rc
      JOIN essentials.races     r  ON r.id  = rc.race_id
      JOIN essentials.offices   ro ON ro.id = r.office_id
      JOIN essentials.elections e  ON e.id  = r.election_id
     WHERE rc.id IN (SELECT race_candidate_id FROM incumbency_before)
  ),
  cmp AS (
    SELECT b.race_candidate_id,
           b.politician_id,
           a.stored,
           a.expected,
           (b.stored IS DISTINCT FROM b.expected) AS drifted_before,
           (a.stored IS DISTINCT FROM a.expected) AS drifted_after
      FROM incumbency_before b
      JOIN after_state a USING (race_candidate_id)
  )
  SELECT count(*) FILTER (WHERE NOT c.drifted_before AND c.drifted_after),
         count(*) FILTER (WHERE c.drifted_before AND NOT c.drifted_after),
         string_agg(
           format('    %s — race_candidate %s says is_incumbent=%s, office_terms now say %s',
                  coalesce(p.full_name, '(unnamed)'), c.race_candidate_id, c.stored, c.expected),
           E'\n' ORDER BY coalesce(p.full_name, ''))
           FILTER (WHERE NOT c.drifted_before AND c.drifted_after)
    INTO v_created, v_repaired, v_detail
    FROM cmp c
    LEFT JOIN essentials.politicians p ON p.id = c.politician_id;

  IF v_repaired > 0 THEN
    RAISE NOTICE 'incumbency guard: % race row(s) that drifted BEFORE this migration now agree with office_terms', v_repaired;
  END IF;

  IF v_created > 0 THEN
    RAISE EXCEPTION E'incumbency guard: % race row(s) agreed with essentials.office_terms before this migration and contradict it now.\n%\n\nThis is what `check:incumbency` will say on the NEXT push to master, under somebody else''s name. Settle it here.\n  • Newcomer — the date is right and the race row is wrong. Set race_candidates.is_incumbent = false IN THIS MIGRATION.\n  • Re-elected — the race row is right and the DATE is wrong: you have written their latest term''s start as the start of their whole tenure. Leave term_start NULL, or write the real first term.\nThe two look identical from the predicate. Read the person. See CC_0396''s header for the worked split of seven such rows.',
      v_created, coalesce(v_detail, '    (no detail)');
  END IF;
END $$;

COMMIT;
