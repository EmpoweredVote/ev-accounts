-- Migration 1945 — contradiction check, ROUND FOUR: five MAPPING-SHAPED instruments, 79 rows.
--
-- Round three established that a queue group is only a MAPPING — one piece of evidence applied to
-- many members — when its rows share the SAME evidence, and that the cheap way to tell is the share
-- of rows whose source set is byte-identical. This pass was chosen by that score rather than by
-- group size, and it is the first pass where almost every row read was written.
--
--   rows  instrument                     ladder            decision                     written
--   ----  -----------------------------  ----------------  ---------------------------  -------
--      5  Texas HB 14 (89R)              fossil-fuels      withdraw all 5                     5
--     30  California SJR 7 (2025-26)     tariffs           withdraw 28; 2 already blank       28
--     15  California SB 314 (2023-24)    redistricting     re-seat 12, withdraw 2            14
--     14  California SB 57 (2025-26)     data-centers      withdraw all 14                   14
--      9  California SB 42               campaign-finance  withdraw all 9                     9
--
-- 76 rows written: 12 seated, 64 withdrawn. 1 row is left alone and 2 were already blanked.
-- Full record: data/stance-research/2026-10-26-contradiction-check-round-four/LEDGER.md
--
-- EVERY TARGET SERVES FROM THE CLOSED SEASON 1, so every write is an INSERT of a Season 2 row
-- (ADR 0005 section 1.6). Season 1 is not touched and the post-flight block proves it. Three of the
-- five ladders pin ONE revision across both seasons, so for those the Season 2 row is read against
-- the very ladder the row was researched against.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. TEXAS HB 14 (89R) -> fossil-fuels, SPONSOR, 5 rows: all 5 withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- The most mapping-shaped group in the whole queue: five rows, ONE citation, byte-identical.
-- The bill was read, not the title. capitol.texas.gov BillLookup for HB 14 of the 89th Regular
-- Session gives the caption "Relating to support for the development of the nuclear energy
-- industry" and the subject "Energy--Nuclear". NUCLEAR POWER IS NOT A FOSSIL FUEL, and every chair
-- on this ladder is about fossil fuel drilling and extraction:
--     c1 immediately ban all new fossil fuel drilling and extraction
--     c2 stop issuing new permits for fossil fuel drilling
--     c3 maintain current levels of fossil fuel production with existing environmental regulations
--     c4 expand fossil fuel drilling permits
--     c5 remove environmental restrictions and maximize fossil fuel extraction
-- An off-axis instrument is wrong at every rung, so the 3/4 split is not resolved by picking one.
--
-- ⚠ AND WHAT FILLED THE GAP IS WORSE THAN THE MISFILE. With the nuclear bill removed, what is left
-- in these rows is party and geography: "Democrats rarely advocate for new fossil fuel drilling
-- bans in Texas"; "As a rural Republican representing Bastrop/Caldwell counties"; "As a West Texas
-- banker representing Abilene-area counties". One row states the method outright:
--     "Insufficient direct fossil fuel drilling bill evidence - scoring 4 based on Republican
--      baseline and HB14 energy-expansion signal."
-- That is a party prior written into a voter-facing position. All five are blanked.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. CALIFORNIA SJR 7 (2025-26) -> tariffs, FOR, 16 rows: all 16 withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- One revision serves both seasons here, so the ladder below is the live one:
--     c1 eliminate all tariffs and pursue completely free trade with every country.
--     c2 reduce most tariffs while keeping some on products that harm the environment.
--     c3 use tariffs selectively to protect key American industries and jobs.
-- The resolution was read in full. Its operative RESOLVED clauses are three, and they urge the
-- President to rescind "the tariffs that he has imposed since taking office in January 2025" and
-- refund consumers; urge Congress to rescind them and to oppose "all future unilateral and
-- arbitrary tariff increases"; and direct transmittal. The argument is Congress's exclusive power
-- to "regulate Commerce with foreign Nations".
--
-- So the resolution opposes ONE administration's tariffs. It does not call for eliminating all
-- tariffs, mentions no environmental carve-out, and endorses no selective-tariff policy. Chairs 1,
-- 2 AND 3 all fail on its own text. The free-trade material - Eisenhower, Reagan, the "bipartisan
-- consensus among both major American political parties supporting free trade" - is confined to
-- WHEREAS clauses, and a findings clause is not an operative provision.
--
-- 🔑 THE ROWS DESCRIBE THE SAME RESOLUTION DIFFERENTLY, EACH TO FIT ITS CHAIR, and the hedges give
-- the method away:
--     chair 1  "Both resolutions call for eliminating tariffs and pursuing stable free trade"
--     chair 2  "while POTENTIALLY keeping targeted protections"
--     chair 2  "while POTENTIALLY supporting targeted ones for environmental or fair-trade purposes"
--     chair 3  "while LEAVING ROOM FOR targeted measures to protect American workers"
-- The vote proves the SIDE and not the RUNG, and this ladder has no chair for the side alone, so
-- the honest write is a blank rather than a pick. The only member-specific addition in the group is
-- the authorship of a bill requiring a STUDY of tariff impacts, which is not a tariff-level
-- position either.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. CALIFORNIA SB 314 (2023-24) -> redistricting, FOR, 13 rows: 12 re-seated
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔑 THE ONE PASS WHERE THE LONE DISSENTER WAS RIGHT AND THE OTHER TWELVE WERE WRONG.
-- One revision serves both seasons:
--     c1 independent citizens' commissions with no elected officials involved at any level.
--     c2 independent redistricting commissions with equal representation from both major parties.
-- SB 314 establishes the Citizens Redistricting Commission in the County of Sacramento, 14 members
-- and 2 non-voting alternates. Elections Code section 21595 as added: "A commission member shall be
-- ineligible for a period of five years beginning from the date of appointment to hold elective
-- public office at the federal, state, county, or city level in this state." Eight commissioners
-- are drawn from applicant subpools and those eight then "appoint six additional applicants". No
-- elected official is involved at any stage - that is chair 1.
--
-- Chair 2 fails because the Act says the opposite of "equal representation from both major
-- parties": "The political party preferences of the commission members ... shall be as PROPORTIONAL
-- AS POSSIBLE to the total number of voters who are registered with each political party in the
-- County of Sacramento, OR WHO DECLINE TO STATE or do not indicate a party preference".
--
-- ⚖ AND IT IS A REAL VOTE, NOT A LOCAL COURTESY. The bill was contested at every stage: Senate
-- 31-7 and 32-7, Assembly 62-18, with no committee vote unanimous after March. An aye is an
-- endorsement of the citizens-commission model.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- D. CALIFORNIA SB 57 (2025-26) -> data-centers, FOR, 11 rows: all 11 withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- "Electrical corporations: data centers: report." The Act authorises the Public Utilities
-- Commission to assess the extent to which electrical corporation costs from new data centre loads
-- "result in cost shifts to other electrical corporation customers", and requires the assessment to
-- be submitted to the Legislature and posted publicly on or before January 1, 2027. It is a study
-- and reporting mandate on a regulator, and it is the whole of the Act.
--
-- Against the Season 2 ladder it establishes nothing:
--     c1 moratorium                              - the Act imposes none
--     c2 bar cost pass-through to residential    - the Act bars none; it measures the shift
--     c3 impact assessments, cost-sharing and community benefits BEFORE APPROVAL
--                                                - the Act has no approval step at all
--     c4 ENCOURAGING development through STREAMLINED PERMITTING, with transparency
--                                                - the Act contains no permitting provision
-- Ten rows chose c3 and one chose c4, each quoting the half of the chair that the Act resembles and
-- passing over the half it does not. The other instruments in these rows - a regional energy market
-- bill, an AI transparency act, a greenhouse gas fund - are off this ladder too, and one row's
-- remaining support is a committee membership.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- E. CALIFORNIA "SB 42" -> campaign-finance, FOR, 9 rows: all 9 withdrawn
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE LEXICAL KEY MERGED TWO DIFFERENT BILLS OF THE SAME LEGISLATURE. The check scopes a
-- numeric bill by its legislature host but not by its SESSION, and this group contains both:
--
-- SIX rows cite 202520260SB42 - "Political Reform Act of 1974: public campaign financing:
-- California Fair Elections Act of 2026". It removes the existing prohibition on a candidate
-- accepting public funds, requires candidates who take them to abide by expenditure limits and
-- qualifying criteria, bars public funds from paying legal fees or repaying personal loans, and
-- raises the penalty for foreign-government contributions. It is a VOLUNTARY PUBLIC FINANCING
-- scheme. It does not strictly limit corporate donations or dark money (chair 2) and it does not
-- ban private money (chair 1).
--
-- ⚖ AND THIS LADDER HAS NO CHAIR FOR PUBLIC FINANCING, BY DESIGN. Topic revision v2r2's own note:
-- "Reworded the first option to state one position - banning private money - instead of also
-- requiring support for public campaign financing, which is a separate policy."
--
-- THREE rows cite 202320240SB42 and call it the "DISCLOSE Act", the "Fair Elections Act" or
-- "public campaign financing reform". The 2023-24 SB 42 is the Community Assistance, Recovery, and
-- Empowerment (CARE) Court Program Act, chaptered 09/27/24. The vote those rows cite is real - the
-- Assembly Floor passed it 75-0 on 08/29/24 - but the motion is "SB 42 Umberg Third Reading
-- Urgency", on a mental health measure.
--
-- 🔴 THIS IS A FAILURE NEITHER GATE CAN SEE. The citation is a valid primary source on the right
-- legislature's site, so check-stance-sources passes it; the reasoning names an act, so the
-- chair-evidence gate passes it. Only opening the cited page shows that it describes a different
-- bill. Recorded in the ledger as its own class.
--
-- ▶ OWED, NOT FIXED HERE. 41 people lose a position on these five topics. That is a coverage debt,
-- not an integrity one, and it is the same debt rounds two and three left behind.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Every one of them serves from the CLOSED Season 1 with nothing shadowing
-- it, so every write is an INSERT of a Season 2 row (ADR 0005 section 1.6). By ADR 0006 that row
-- is read against the SEASON 2 ladder, which is resolved from inform.season_questions and never
-- hard-coded. The Season 1 value, reasoning, sources and updated_at are carried along so the
-- guards and the post-flight block can prove nothing in the closed season moved.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1945_ins ON COMMIT DROP AS
SELECT x.politician_id, x.topic_id, x.op, x.value_after,
       sq.topic_revision_id  AS s2_revision,
       pa1.value             AS value_before,
       pa1.topic_revision_id AS s1_revision,
       pa1.updated_at        AS s1_updated_at,
       pc1.reasoning         AS reasoning_before,
       pc1.sources           AS sources_before
  FROM (VALUES
  ('155a62d8-9e8e-4231-94dc-823b9f15b30b'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'hb14-blank',0),  -- Eddie Morales: was chair 3
  ('099c7880-e909-4874-a257-cc8ca54ca7bd'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'hb14-blank',0),  -- Richard Hayes: was chair 4
  ('002f4446-75be-4860-935e-3cb65ce296fb'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'hb14-blank',0),  -- Stan Gerdes: was chair 4
  ('c41d17c7-ca70-4c7c-85d4-8e85e4288742'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'hb14-blank',0),  -- Stan Kitzman: was chair 4
  ('47cdb7af-9fff-487a-a6d1-23c66d21a414'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'hb14-blank',0),  -- Stan Lambert: was chair 4
  ('a1467b58-9cc8-4611-a03e-07defc1679bf'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Avelino Valencia: was chair 1
  ('065c6e87-8778-43ee-ab44-b9982a677aa7'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Cottie Petrie-Norris: was chair 1
  ('9a927fae-60bf-41f9-8ec0-433cc98997fa'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Dr. Darshana R. Patel: was chair 1
  ('cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Dr. LaShae Sharp-Collins: was chair 1
  ('5a75d4fb-e4fe-441a-8658-e6eb57574fd4'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Robert Rivas: was chair 1
  ('b3937fff-ebcf-48d9-b20d-bdf98196e119'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Susan Rubio: was chair 1
  ('0a9171c6-0676-4704-b825-a7e16c66f1c2'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Tasha Boerner: was chair 1
  ('2326fe1b-923d-4e2f-9598-0c8a23528df8'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Esmeralda Z. Soria: was chair 2
  ('7520a629-a0ec-44b3-9460-c7e4574a897d'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Juan Alanis: was chair 2
  ('611c17c5-3c5f-4685-8c22-3b3fe75482ba'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Sasha Renée Pérez: was chair 2
  ('712be98b-a05d-4605-9603-cd5d86abfad1'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Thomas Umberg: was chair 2
  ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Catherine S. Blakespear: was chair 3
  ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Henry Stern: was chair 3
  ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Jesse Arreguín: was chair 3
  ('178a41d4-42b5-4ffd-be06-d1059d54eacb'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- John Laird: was chair 3
  ('4fccbf85-d794-4cdc-a8b8-674ff1b48784'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Kelly Seyarto: was chair 3
  ('1cede4d2-3075-4860-b133-1ab34cdacff5'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Lena Gonzalez: was chair 3
  ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Lola Smallwood-Cuevas: was chair 3
  ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Maria Elena Durazo: was chair 3
  ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Marie Alvarado-Gil: was chair 3
  ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Melissa Hurtado: was chair 3
  ('974bfe8b-afb8-424c-bfd2-7805f033b1a0'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Mike McGuire: was chair 3
  ('c7a56941-597a-456b-8fd8-e4bd840014c1'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Monique Limón: was chair 3
  ('62dfefeb-9979-445a-aee6-06cf7c03a8c0'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Kate Sanchez: was chair 4
  ('c1215ce9-430e-411d-869c-353c93fe1cac'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Megan Dahle: was chair 4
  ('fcdd3836-bb89-44ec-920a-75a21c9d726f'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Stan Ellis: was chair 4
  ('7f3b03b0-b481-4ccf-a33e-1261daabc6e8'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Suzette Martinez Valladares: was chair 4
  ('c2975ee6-7770-4c5f-809c-4e1245f2ab64'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'sjr7-blank',0),  -- Tri Ta: was chair 4
  ('fad61dc3-a3ad-4056-b2f2-1f5d32fb886d'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Catherine S. Blakespear: was chair 2
  ('1571da4a-b832-4792-917c-184c155b1700'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Eloise Gómez Reyes: was chair 2
  ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Henry Stern: was chair 2
  ('178a41d4-42b5-4ffd-be06-d1059d54eacb'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- John Laird: was chair 2
  ('64eda290-d172-48de-8827-6ebca668cf5a'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Josh Becker: was chair 2
  ('1cede4d2-3075-4860-b133-1ab34cdacff5'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Lena Gonzalez: was chair 2
  ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Lola Smallwood-Cuevas: was chair 2
  ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Maria Elena Durazo: was chair 2
  ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Marie Alvarado-Gil: was chair 2
  ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Melissa Hurtado: was chair 2
  ('974bfe8b-afb8-424c-bfd2-7805f033b1a0'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Mike McGuire: was chair 2
  ('c7a56941-597a-456b-8fd8-e4bd840014c1'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-chair1',1),  -- Monique Limón: was chair 2
  ('4fccbf85-d794-4cdc-a8b8-674ff1b48784'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-blank',0),  -- Kelly Seyarto: was chair 4
  ('c1215ce9-430e-411d-869c-353c93fe1cac'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'sb314-blank',0),  -- Megan Dahle: was chair 5
  ('f26309c8-2525-49b2-bdaf-62980cbb1853'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Gavin Newsom: was chair 3
  ('f3671de4-514f-441c-8ad4-4a9ab7c65ae6'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Henry Stern: was chair 3
  ('178a41d4-42b5-4ffd-be06-d1059d54eacb'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- John Laird: was chair 3
  ('64eda290-d172-48de-8827-6ebca668cf5a'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Josh Becker: was chair 3
  ('9edc0c37-f213-4aae-9212-c9cb4780d854'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Laura Richardson: was chair 3
  ('1cede4d2-3075-4860-b133-1ab34cdacff5'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Lena Gonzalez: was chair 3
  ('cb9b6b95-ace4-4ae3-a7e6-ae2349abd741'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Lola Smallwood-Cuevas: was chair 3
  ('c7dc9c50-84c6-4bde-af06-e7f9d5167e93'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Maria Elena Durazo: was chair 3
  ('d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Melissa Hurtado: was chair 3
  ('974bfe8b-afb8-424c-bfd2-7805f033b1a0'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Mike McGuire: was chair 3
  ('c7a56941-597a-456b-8fd8-e4bd840014c1'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Monique Limón: was chair 3
  ('eeeaf1be-3372-4cf9-b3b6-d5d1dff42615'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Jesse Arreguín: was chair 4
  ('6e2d2c6d-b96e-4916-a7c8-51a8f46629ba'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Marie Alvarado-Gil: was chair 5
  ('c1215ce9-430e-411d-869c-353c93fe1cac'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'sb57-blank',0),  -- Megan Dahle: was chair 5
  ('a1467b58-9cc8-4611-a03e-07defc1679bf'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Avelino Valencia: was chair 2
  ('065c6e87-8778-43ee-ab44-b9982a677aa7'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Cottie Petrie-Norris: was chair 2
  ('9a927fae-60bf-41f9-8ec0-433cc98997fa'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Dr. Darshana R. Patel: was chair 2
  ('cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Dr. LaShae Sharp-Collins: was chair 2
  ('2326fe1b-923d-4e2f-9598-0c8a23528df8'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Esmeralda Z. Soria: was chair 2
  ('5a75d4fb-e4fe-441a-8658-e6eb57574fd4'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Robert Rivas: was chair 2
  ('611c17c5-3c5f-4685-8c22-3b3fe75482ba'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Sasha Renée Pérez: was chair 2
  ('3a462896-e249-4c79-94b7-175bd2efcf73'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Steve Padilla: was chair 2
  ('b3937fff-ebcf-48d9-b20d-bdf98196e119'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Susan Rubio: was chair 2
  ('0a9171c6-0676-4704-b825-a7e16c66f1c2'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Tasha Boerner: was chair 2
  ('712be98b-a05d-4605-9603-cd5d86abfad1'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Thomas Umberg: was chair 2
  ('7778111f-551f-407f-87c7-e30268ea5e0a'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Laurie Davies: was chair 3
  ('c6c04131-96f3-40d8-b881-e6c57f986d38'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Greg Wallis: was chair 4
  ('fcdd3836-bb89-44ec-920a-75a21c9d726f'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0),  -- Stan Ellis: was chair 4
  ('c2975ee6-7770-4c5f-809c-4e1245f2ab64'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,'sb42-blank',0)  -- Tri Ta: was chair 4
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = x.topic_id
   AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = x.topic_id
   AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = x.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target set must be exactly what was read, and every row must have something to keep.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1945_ins;
  IF n <> 76 THEN RAISE EXCEPTION 'migration 1945: expected 76 targets, found % — a Season 1 answer or context row is missing', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'hb14-blank';
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1945: hb14-blank expected 5, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sjr7-blank';
  IF n <> 28 THEN RAISE EXCEPTION 'migration 1945: sjr7-blank expected 28, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-chair1';
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1945: sb314-chair1 expected 12, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-blank';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1945: sb314-blank expected 2, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb57-blank';
  IF n <> 14 THEN RAISE EXCEPTION 'migration 1945: sb57-blank expected 14, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb42-blank';
  IF n <> 15 THEN RAISE EXCEPTION 'migration 1945: sb42-blank expected 15, found %', n; END IF;
  SELECT count(DISTINCT (politician_id, topic_id)) INTO n FROM mig1945_ins;
  IF n <> 76 THEN RAISE EXCEPTION 'migration 1945: duplicate (person, topic) pairs; % distinct of 76', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins
   WHERE reasoning_before IS NULL OR btrim(reasoning_before) = ''
      OR sources_before IS NULL OR cardinality(sources_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) have no reasoning or no citation to keep', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE reasoning_before LIKE '%migration 1945%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) already carry a 1945 notice — this file has run', n; END IF;
END $$;

-- GUARD 2 — every target must TODAY still sit on the chair the queue measured it at. If anything
-- re-researched these rows since 2026-10-26 the adjudication is stale and must not be applied.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'hb14-blank' AND value_before NOT IN (3,4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % hb14-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sjr7-blank' AND value_before NOT IN (1,2,3,4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sjr7-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-chair1' AND value_before NOT IN (2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb314-chair1 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-blank' AND value_before NOT IN (4,5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb314-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb57-blank' AND value_before NOT IN (3,4,5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb57-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb42-blank' AND value_before NOT IN (2,3,4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb42-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE value_before = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) are already blank', n; END IF;
END $$;

-- GUARD 3 — the reasoning must really name the thing the adjudication turned on. Without this the
-- file is a list of uuids and a clerical slip is undetectable.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'hb14-blank' AND reasoning_before !~ 'HB ?14';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % hb14-blank row(s) do not name HB 14', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sjr7-blank' AND reasoning_before !~ 'SJR ?7';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sjr7-blank row(s) do not name SJR 7', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-chair1' AND reasoning_before !~ 'SB ?314';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb314-chair1 row(s) do not name SB 314', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb314-blank' AND reasoning_before !~ 'SB ?314';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb314-blank row(s) do not name SB 314', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb57-blank' AND reasoning_before !~ 'SB ?57';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb57-blank row(s) do not name SB 57', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins WHERE op = 'sb42-blank' AND reasoning_before !~ 'SB ?42';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % sb42-blank row(s) do not name SB 42', n; END IF;
END $$;

-- GUARD 4 — THE LADDERS. A rung NUMBER means nothing outside one revision, and a rung_map can lie
-- (climate-change v2r3 and school-vouchers v2r3 both claim IDENTITY over rewritten rungs), so the
-- rung TEXTS are asserted here — including, for school-vouchers chair 4, the clause the Season 2
-- rewrite DELETED, which is the whole reason the Texas HB 3 dissenter moves.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1945: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1945: Season 1 is not closed'; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i WHERE i.topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
     AND (i.s1_revision <> 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid OR i.s2_revision <> 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % fossil-fuels row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i WHERE i.topic_id = '683c8084-2281-4920-a07c-18439b2dd413'::uuid
     AND (i.s1_revision <> '9f094155-f604-47e8-93db-54a3142420ca'::uuid OR i.s2_revision <> '9f094155-f604-47e8-93db-54a3142420ca'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % tariffs row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i WHERE i.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid
     AND (i.s1_revision <> 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid OR i.s2_revision <> 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % redistricting row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i WHERE i.topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid
     AND (i.s1_revision <> 'f6630c71-8ba8-464d-82d4-9079803d4e8b'::uuid OR i.s2_revision <> 'c48a03d6-b972-4f27-9a8a-d41b07f4a929'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % data-centers row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i WHERE i.topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid
     AND (i.s1_revision <> '58ebaab3-0849-446a-82f9-162f084e93e3'::uuid OR i.s2_revision <> 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % campaign-finance row(s) are not on the expected revisions', n; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'stop issuing new permits for fossil fuel drilling' THEN RAISE EXCEPTION 'migration 1945: Season 2 fossil-fuels chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c8e12b53-64f6-48ac-9c2d-0a3cf4d3df9b'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'expand fossil fuel drilling permits' THEN RAISE EXCEPTION 'migration 1945: Season 2 fossil-fuels chair 4 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '9f094155-f604-47e8-93db-54a3142420ca'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'eliminate all tariffs' THEN RAISE EXCEPTION 'migration 1945: Season 2 tariffs chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '9f094155-f604-47e8-93db-54a3142420ca'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'products that harm the environment' THEN RAISE EXCEPTION 'migration 1945: Season 2 tariffs chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '9f094155-f604-47e8-93db-54a3142420ca'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'use tariffs selectively' THEN RAISE EXCEPTION 'migration 1945: Season 2 tariffs chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'equal representation from both major parties' THEN RAISE EXCEPTION 'migration 1945: Season 1 redistricting chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'no elected officials involved at any level' THEN RAISE EXCEPTION 'migration 1945: Season 2 redistricting chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c7f973fc-33f5-4570-bfe2-bff4ac6141cc'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'equal representation from both major parties' THEN RAISE EXCEPTION 'migration 1945: Season 2 redistricting chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c48a03d6-b972-4f27-9a8a-d41b07f4a929'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'before approval' THEN RAISE EXCEPTION 'migration 1945: Season 2 data-centers chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'c48a03d6-b972-4f27-9a8a-d41b07f4a929'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'streamlined permitting' THEN RAISE EXCEPTION 'migration 1945: Season 2 data-centers chair 4 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '58ebaab3-0849-446a-82f9-162f084e93e3'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'require full disclosure of all political donations' THEN RAISE EXCEPTION 'migration 1945: Season 1 campaign-finance chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'corporate and dark-money spending' THEN RAISE EXCEPTION 'migration 1945: Season 2 campaign-finance chair 2 does not read as recorded: %', t; END IF;

  -- 🔑 THREE OF THESE LADDERS PIN ONE REVISION ACROSS BOTH SEASONS, so the Season 2 row written
  -- here is read against the very ladder the row was researched against, and no rung_map can come
  -- between them. Asserted rather than assumed, because it is why this file can reason directly
  -- from the Season 1 chair texts.
  SELECT count(*) INTO n FROM inform.season_questions a
    JOIN inform.season_questions b ON b.topic_id = a.topic_id
   WHERE a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND b.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND a.topic_id IN ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid)
     AND a.topic_revision_id = b.topic_revision_id;
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1945: expected fossil-fuels, tariffs and redistricting to share one revision across both seasons, found %', n; END IF;

  -- every chair this file writes must EXIST on the revision it is written against
  SELECT count(*) INTO n FROM mig1945_ins i
   WHERE i.value_after <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions cs
                      WHERE cs.topic_revision_id = i.s2_revision AND cs.value = i.value_after);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % row(s) would be seated on a chair that does not exist', n; END IF;
END $$;

-- GUARD 5 — these are inserts, so no target may already hold a Season 2 row; and nobody here may
-- be inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1945_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
                    AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) ALREADY have a Season 2 answer — somebody answered since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
                    AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) ALREADY have a Season 2 context row', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN essentials.politicians p ON p.id = i.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) are on inactive people', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins
   WHERE topic_id NOT IN ('a22215c3-6693-4bc2-b248-01aebba14570'::uuid,'683c8084-2281-4920-a07c-18439b2dd413'::uuid,'48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid,'4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid,'92730f69-ae57-401c-8ad1-2d07834a895d'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % target(s) are on an unexpected topic', n; END IF;
END $$;

-- GUARD 6 — POPULATIONS, NOT JUST TARGETS. Round three's guard of this kind FAILED on its first
-- run and found a defective row the check had never reported, because the check drops rows whose
-- side it cannot score. So this file does not ask "are my targets still as I read them"; it asks
-- "is every row that names this instrument accounted for". Each count below was measured on
-- 2026-10-26, and each is the FULL cohort naming that instrument on that ladder, in Season 1,
-- for an active person, at a non-blank chair.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'HB ?14';
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1945: expected 5 fossil-fuels rows naming HB 14, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = '683c8084-2281-4920-a07c-18439b2dd413'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'SJR ?7';
  IF n <> 30 THEN RAISE EXCEPTION 'migration 1945: expected 30 tariffs rows naming SJR 7, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'SB ?314';
  IF n <> 15 THEN RAISE EXCEPTION 'migration 1945: expected 15 redistricting rows naming SB 314, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'SB ?57';
  IF n <> 14 THEN RAISE EXCEPTION 'migration 1945: expected 14 data-centers rows naming SB 57, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value <> 0 AND p.is_active AND pc.reasoning ~ 'SB ?42';
  IF n <> 15 THEN RAISE EXCEPTION 'migration 1945: expected 15 campaign-finance rows naming SB 42, found % — re-read before writing', n; END IF;

  -- and every one of those rows must either be a target here or be the single row this file
  -- deliberately leaves alone, which is the redistricting row ALREADY on chair 1.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value <> 0 AND p.is_active
     AND ((pa.topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid     AND pc.reasoning ~ 'HB ?14')
       OR (pa.topic_id = '683c8084-2281-4920-a07c-18439b2dd413'::uuid          AND pc.reasoning ~ 'SJR ?7')
       OR (pa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid    AND pc.reasoning ~ 'SB ?314' AND pa.value <> 1)
       OR (pa.topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40'::uuid     AND pc.reasoning ~ 'SB ?57')
       OR (pa.topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid AND pc.reasoning ~ 'SB ?42'))
     AND NOT EXISTS (SELECT 1 FROM mig1945_ins i
                      WHERE i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id)
     -- ...unless an earlier pass already shadowed the row with a Season 2 answer, in which case the
     -- Season 1 row is history and not voter-facing. Two rows in the tariffs cohort are in exactly
     -- that state, both blanked by a previous audit for resting on an absence of evidence.
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers s2
                      WHERE s2.politician_id = pa.politician_id AND s2.topic_id = pa.topic_id
                        AND s2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % row(s) naming these instruments are neither targets nor already shadowed', n; END IF;

  -- the one row left alone: already on chair 1 of the redistricting ladder, which is where the Act
  -- puts it, so it needs no Season 2 row from this file.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
   WHERE pa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 1 AND pc.reasoning ~ 'SB ?314';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1945: expected exactly 1 SB 314 row already at chair 1, found %', n; END IF;

  -- 🔑 THE DELETED DISCLOSURE CHAIR. Season 1 campaign-finance chair 3 was "require full disclosure
  -- of all political donations"; Season 2 chair 3 is "Keep contribution limits at current levels",
  -- and the topic revision carries an IDENTITY rung_map over that replacement. Nothing in this file
  -- writes campaign-finance chair 3, and this guard makes the replacement explicit so a later pass
  -- cannot port a disclosure answer onto a limits chair by trusting the map.
  SELECT count(*) INTO n FROM inform.compass_stance_revisions
   WHERE topic_revision_id = 'ae53ba29-79eb-420f-aac6-ec99f8031ec6'::uuid AND value = 3 AND text ~* 'disclosure';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: Season 2 campaign-finance chair 3 mentions disclosure — the ladder moved, re-argue this file'; END IF;
  SELECT count(*) INTO n FROM mig1945_ins
   WHERE topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid AND value_after <> 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: this file must not seat any campaign-finance chair'; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. Two inserts. The Season 2 reasoning is the migration's notice followed by the ORIGINAL
-- prose, kept verbatim — a reader must be able to see what the row used to claim and why it moved.
-- Sources are carried across byte for byte; this file re-reads evidence, it never re-cites it.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_after
  FROM mig1945_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       CASE i.op
         WHEN 'hb14-blank' THEN '[migration 1945, 2026-10-26] Withdrawn. This row rests on co-authoring Texas HB 14 (89R), whose caption is "Relating to support for the development of the nuclear energy industry" and whose subject is Energy-Nuclear. Nuclear power is not a fossil fuel, and every chair on this ladder is about fossil fuel drilling and extraction permits, so the sponsorship is off-axis and wrong at every rung. What remained in this row was an inference from party and district; one row in the same group states outright that it is "scoring 4 based on Republican baseline". Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'sjr7-blank' THEN '[migration 1945, 2026-10-26] Withdrawn. This row rests on California SJR 7 (2025-26). Its operative RESOLVED clauses urge the President to rescind "the tariffs that he has imposed since taking office in January 2025" and urge Congress to rescind them and to oppose "future unilateral and arbitrary tariff increases". That is opposition to one administration''s tariffs, argued from Congress''s exclusive power to regulate foreign commerce. It does not call for eliminating all tariffs (chair 1), says nothing about keeping tariffs on environmentally harmful products (chair 2), and endorses no selective-tariff policy (chair 3). The free-trade language is confined to WHEREAS clauses, and a findings clause is not an operative provision. The vote proves the side and not the rung, and this ladder has no chair for the side alone. A vote AGAINST the resolution proves less still: it establishes no affirmative tariff policy, so chair 4 is not available to a no vote either. Some rows in this cohort rest on NO VOTE AT ALL - one states "was NVR (no vote recorded) ... no strong public stance was identified. Assigned 3". Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'sb314-chair1' THEN '[migration 1945, 2026-10-26] Re-seated from Season 1 chair 2 to chair 1. California SB 314 (2023-24) establishes the Citizens Redistricting Commission in the County of Sacramento. Elections Code section 21595 makes a commissioner ineligible to hold elective public office for five years from appointment, and the commission is built from applicant subpools rather than by officeholders, so no elected officials are involved: chair 1. Chair 2 claims "equal representation from both major parties" and the Act says the opposite - party preferences "shall be as proportional as possible to the total number of voters who are registered with each political party ... or who decline to state or do not indicate a party preference". The bill was contested, passing the Senate 31-7 and the Assembly 62-18, so an aye is an endorsement rather than a local courtesy. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'sb314-blank' THEN '[migration 1945, 2026-10-26] Withdrawn. This row rests on a vote AGAINST California SB 314 (2023-24), which establishes the Citizens Redistricting Commission in the County of Sacramento. A no vote proves opposition to that commission; it does not establish an affirmative preference for any other method of drawing districts, which is what chairs 4 and 5 assert. What carried the chair instead was a party prior - one row reads "aligns with the Republican preference for party-controlled redistricting" - and a description of the Act that it contradicts: the commission''s party preferences are "as proportional as possible" to county registration including voters who decline to state, not the "equal party representation" the row reports. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'sb57-blank' THEN '[migration 1945, 2026-10-26] Withdrawn. This row rests on a vote for California SB 57 (2025-26), "Electrical corporations: data centers: report". The Act authorises the Public Utilities Commission to assess whether data centre costs shift to other customers and requires that assessment to be given to the Legislature and posted publicly by 1 January 2027. It is a study and reporting mandate on a regulator. It imposes no moratorium (chair 1), bars no cost pass-through (chair 2), creates no impact assessment, cost-sharing agreement or community benefit requirement before approval of a data centre - it has no approval step at all (chair 3) - and contains no permitting provision, so it streamlines nothing (chair 4). Rows resting on a NO vote fare worse: opposing a study authorisation does not establish chair 5, and two of them describe the Act as requiring data centres "to fund their own power generation" or imposing assessments "before approval" - that is chair 2 and chair 3 text, not the Act. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'sb42-blank' THEN '[migration 1945, 2026-10-26] Withdrawn. This row rests on "SB 42", and one lexical key merged TWO DIFFERENT BILLS of the same California legislature. The 2025-26 SB 42 is the California Fair Elections Act of 2026, which removes the prohibition on candidates accepting public funds and sets qualifying criteria and expenditure limits for those who take them. It is a voluntary public financing scheme: it does not limit corporate donations or dark money (chair 2), nor ban private money (chair 1). This ladder has no chair for public financing, and that is deliberate - revision v2r2 records that chair 1 was reworded to drop public funding because it "is a separate policy". The 2023-24 SB 42, cited by some rows in this group as the "DISCLOSE Act" or a "campaign finance reform bill", is the Community Assistance, Recovery, and Empowerment (CARE) Court Program Act; the 75-0 vote of 08/29/24 is real but it is a vote on that mental health measure. A vote AGAINST the Fair Elections Act is not a vote to reduce restrictions on donations (chair 4) - it is a vote against a public funding option. And the clearest case in this cohort is a member who AUTHORED public campaign financing legislation: his position is real, well evidenced and simply has no chair on a ladder that measures how far private money is limited. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
       END || i.reasoning_before,
       i.sources_before
  FROM mig1945_ins i;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT. Everything below runs inside the same transaction, so a failure here rolls the
-- whole file back.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = i.value_after AND pa.topic_revision_id = i.s2_revision;
  IF n <> 76 THEN RAISE EXCEPTION 'migration 1945: % of 76 inserted answers are at their chair and revision', n; END IF;

  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> 0;
  IF n <> 12 THEN RAISE EXCEPTION 'migration 1945: expected 12 seated rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 64 THEN RAISE EXCEPTION 'migration 1945: expected 64 withdrawn rows, found %', n; END IF;

  -- the kept prose and the untouched citations
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % row(s) had their citations altered', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE strpos(pc.reasoning, i.reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % row(s) lost their original reasoning', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1945%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % row(s) carry no notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED. Not one value, not one word of reasoning, not one updated_at may move.
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at
      OR pa.topic_revision_id <> i.s1_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % Season 1 answer(s) MOVED — the closed season was written to', n; END IF;
  SELECT count(*) INTO n FROM mig1945_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1945: % Season 1 context row(s) were rewritten', n; END IF;

  -- and the row this file promised not to touch is still where it was
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
   WHERE pa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 1 AND pc.reasoning ~ 'SB ?314';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1945: the left-alone SB 314 row moved; found %', n; END IF;
END $$;

COMMIT;
