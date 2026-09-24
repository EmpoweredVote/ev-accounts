-- CA_0202_seed_ca_2026_general_legislature.sql
-- Seed the rest of the California Legislature onto 'CA 2026 Statewide General' (2026-11-03):
-- the 12 State Senate and 55 State Assembly races that CA_0132 / CA_0133 (LA-County districts only)
-- and CA_0201 (AD-3) did not cover. After this the general carries all 20 Senate races on the 2026
-- ballot (the even-numbered districts) and all 80 Assembly races. Same shape as CA_0133: reuse the
-- existing STATE_UPPER / STATE_LOWER offices; primary_party NULL (general; CA top-two, can be
-- same-party); party never stored (antipartisan).
--
-- 67 RACES / 130 CANDIDATES:
--   SD 2   Damon Connolly · Tief Gibbs   [open]
--   SD 4   Alexandra Duarte · Jaron Brandon   [open]
--   SD 6   Roger Niello (inc) · Sean Frame
--   SD 8   Angelique Ashby (inc) · Susan A Mason
--   SD 10  Linda R. Price · Scott Sakakihara   [open]
--   SD 12  Nathan Magsig · William Brown Jr.   [open]
--   SD 14  Darin S. DuPont · Esmeralda Soria   [open]
--   SD 16  Guillermo Asuncion Gonzalez · Melissa Hurtado (inc)
--   SD 18  Art Hodges · Steve Padilla (inc)
--   SD 32  Kelly Seyarto (inc) · Tiffanie Tate
--   SD 38  Catherine S. Blakespear (inc) · Laura Bassett
--   SD 40  Kristie Bruce-Lane · Mara Elliott   [open]
--   AD 1   Dianna Margaret James · Heather Hadwick (inc)
--   AD 2   Chris Rogers (inc) · Michael Greer
--   AD 4   Cecilia M. Aguiar-Curry (inc)   [ONE CANDIDATE]
--   AD 5   Joe Patterson (inc) · Neva Parker
--   AD 6   Jagtar Singh · Maggy Krell (inc)
--   AD 7   Amy L. Slavensky · Josh Hoover (inc)
--   AD 8   David Jariustokaeutulelei Tangipa (inc)   [ONE CANDIDATE]
--   AD 9   Heath Flora (inc) · Matthew Adams
--   AD 10  Stephanie Nguyen (inc) · Vinaya Singh
--   AD 11  Jenny Leilani Callison · Lori D Wilson (inc)
--   AD 12  Eric Lucan · Jackie Elward   [open]
--   AD 13  Rhodesia Ransom (inc) · Tom Patti
--   AD 14  Buffy Wicks (inc) · Mark Rendon
--   AD 15  Anamarie Avila Farias (inc) · Arthur Webb
--   AD 16  Joseph A. Rubay · Rebecca Bauer-Kahan (inc)
--   AD 17  Manuel Noris-Barrera · Matt Haney (inc)
--   AD 18  Andre Sandford · Mia Bonta (inc)
--   AD 19  Catherine Stefani (inc) · Philip Louis Wing
--   AD 20  Liz Ortega (inc) · Patricia Muga
--   AD 21  Diane Papan (inc) · Jabra J Muhawieh
--   AD 22  Juan Alanis (inc)   [ONE CANDIDATE]
--   AD 23  David G. Johnson · Marc Berman (inc)
--   AD 24  Alex Lee (inc) · Max Hsia
--   AD 25  Ash Kalra (inc) · Himat Singh Bainiwal
--   AD 26  Patrick Ahrens (inc) · Tim Gorsulowsky
--   AD 27  Brian Pacheco · Mike Murphy   [open]
--   AD 28  Carol Pefley · Gail Pellerin (inc)
--   AD 29  Dennis P. Sanchez · Robert Rivas (inc)
--   AD 30  Dawn Addis (inc) · Shannon Kessler
--   AD 31  Annalisa Perea · Jim Polsgrove   [open]
--   AD 32  David Couch   [open, ONE CANDIDATE]
--   AD 33  Alexandra (Ali) Macedo (inc) · Hipolito Angel Cerros
--   AD 35  Andrae Gonzales · Saul Ayon   [open]
--   AD 36  Ida S. Obeso-Martinez · Jeff Gonzalez (inc)
--   AD 37  Gregg Hart (inc) · Sari Domingues
--   AD 38  Michael MacDonald · Steve Bennett (inc)
--   AD 45  Greg Abdouch · James C. Ramos (inc)
--   AD 47  Greg Wallis (inc) · Leila Namvar
--   AD 50  Robert Garcia (inc) · Victoria Viveros Mageno
--   AD 58  Clarissa Cervantes · Leticia Castillo (inc)
--   AD 59  Phillip Chen (inc) · Victor Hernandez
--   AD 60  Corey A Jackson (inc) · Ed Delgado
--   AD 63  Kevin Akin · Natasha Johnson (inc)
--   AD 68  David Penaloza · Jessie Lopez   [open]
--   AD 70  Paula Swift · Tri Ta (inc)
--   AD 71  JJ Galvez · Kate Sanchez (inc)
--   AD 72  Chris Kluwe · Gracey Van Der Mark   [open]
--   AD 73  Cottie Petrie-Norris (inc) · Urson Russell
--   AD 74  Laurie Davies (inc) · Sergio Farias
--   AD 75  Carl DeMaio (inc) · Gerald C. Boursiquot
--   AD 76  Carrie S. Espinoza Villanueva · Darshana Patel (inc)
--   AD 77  Tasha Boerner (inc) · Trinity Hannaway
--   AD 78  Chris Ward (inc) · Payton Galvez
--   AD 79  Andrew Lawson · LaShae Sharp-Collins (inc)
--   AD 80  Alejandro Galicia · David A. Alvarez (inc)
--
-- INCUMBENTS. The certified list stars ("*") an incumbent seeking the same seat. All 54 starred
-- candidates here were matched to the CURRENT HOLDER of that office in office_current_holder before
-- this was written, with no mismatch -- so none of these seats carries stale occupancy. They link
-- to the holder's politicians row; seven names differ only in form (e.g. list 'Chris Ward' = holder
-- 'Christopher M. Ward', 'Corey A Jackson' = 'Dr. Corey A. Jackson'). Every other candidate is
-- politician_id NULL, as CA_0132/CA_0133 do for challengers and open-seat candidates -- including a
-- candidate who holds a DIFFERENT seat today. No politicians row is inserted here.
--
-- ONE-CANDIDATE RACES. AD 4, AD 8, AD 22, AD 32 each have a single certified
-- candidate. They are seeded as ordinary one-seat races with one candidate.
--
-- Ballot designations are left out, as every other CA 2026 general candidate leaves
-- occupational_designation NULL. last_name is the final token (house style), except
-- 'Van Der Mark'.
--
-- The 32 legislature races already seeded were used as the parser's positive control: its output
-- matched them exactly, names and incumbent stars included, before any of these rows were built.
--
-- SOURCE: California SoS Official Certified List of Candidates, 8/27/2026, "State Senate District N"
-- and "State Assembly Member District N". Read 2026-09-23 from the copy CA_0133's session retrieved
-- 2026-09-21 (PDF ModDate 2026-08-27, sha256 prefix 0e514ae7b14378b1).
--
-- IDEMPOTENCY: races on (election_id, position_name); candidates on (race_id, lower(full_name)).

BEGIN;

CREATE TEMP TABLE leg_race_seed (position_name text, office_id uuid) ON COMMIT DROP;
INSERT INTO leg_race_seed VALUES
  ('State Senate District 2','8cf6fdd7-dd37-40b9-b548-22412b471560'),
  ('State Senate District 4','6105b714-58fe-4ecd-824e-64411f915bff'),
  ('State Senate District 6','db68eac2-f869-4eae-bffc-faae657d7eb1'),
  ('State Senate District 8','e0314625-8c77-41da-9ddb-fa5d1a41217b'),
  ('State Senate District 10','402781ee-b5df-472f-b67c-485c07c4782f'),
  ('State Senate District 12','e38cdc56-9228-456b-ba4c-3fc0ab72f6cd'),
  ('State Senate District 14','d55ca4b0-d53f-42f5-9ed7-000d188e6634'),
  ('State Senate District 16','7e75e10d-f17f-4aa7-838a-985ff1a22834'),
  ('State Senate District 18','bfaacb00-1875-4c65-bbe9-5a5ab0034494'),
  ('State Senate District 32','ff40b8f8-a89d-48f3-8934-02c641396e61'),
  ('State Senate District 38','76ce3998-b6e1-4fb3-9461-2ab82fff6f04'),
  ('State Senate District 40','de1a8793-9a9c-4e65-a7c6-c08ddd809a98'),
  ('State Assembly District 1','ba13159b-8b41-45a8-bd36-9e7696f7631d'),
  ('State Assembly District 2','9d56e4b8-e010-45b6-826f-92e483830169'),
  ('State Assembly District 4','f4c83c0b-3c35-419b-a618-0e6c4c13fd38'),
  ('State Assembly District 5','1fc9ccc6-3a81-44e9-b2ed-092d0f79afdf'),
  ('State Assembly District 6','11c6dfc5-e935-4094-a01d-1d30ef64f95d'),
  ('State Assembly District 7','c8ccc0ec-c339-438e-b5c7-74ac73803fe3'),
  ('State Assembly District 8','823ebd68-325c-469c-a27f-2168fdb364fc'),
  ('State Assembly District 9','68830803-7f09-48b7-aab8-ba9e2fe10fe7'),
  ('State Assembly District 10','422eb261-3f7a-4a4d-82f2-da1d3616e6a3'),
  ('State Assembly District 11','dc4b9295-7a54-4309-ac0c-30b03ed34cc2'),
  ('State Assembly District 12','a4020ea2-02d1-411b-b586-9b7c8dc4f90b'),
  ('State Assembly District 13','49fae1a1-2b2f-41da-9c66-844ad084fa4a'),
  ('State Assembly District 14','7b3dcdad-b119-4b25-8240-460f70244f9d'),
  ('State Assembly District 15','79f55eaa-b5dc-4368-91be-9046b0e96d74'),
  ('State Assembly District 16','b58a97c0-8ee8-4949-827d-c06946a12a4c'),
  ('State Assembly District 17','f11ac115-0c75-4fbf-baf8-d78ef703dc49'),
  ('State Assembly District 18','f675394b-9e74-40ab-9a35-89aca8b4f9e9'),
  ('State Assembly District 19','43845b1b-7d1c-4034-ad31-0f7ec48da745'),
  ('State Assembly District 20','b306308a-593a-40ae-a05c-7eb9ecaf46ee'),
  ('State Assembly District 21','1e2d5919-ea9e-4c05-af12-c9ac1007d114'),
  ('State Assembly District 22','afcf6e4e-d54b-49bd-8539-731aac0c66aa'),
  ('State Assembly District 23','6bb9a929-fd7a-4fee-b28e-4faa7c3b95de'),
  ('State Assembly District 24','43dd153e-0834-434f-9577-f9bae44d8f89'),
  ('State Assembly District 25','3db4bfac-030f-4c8b-afbe-77c093e64ea9'),
  ('State Assembly District 26','4b943fc3-4c68-4b2f-8a56-7159b3cc18ba'),
  ('State Assembly District 27','134ff9e4-cd3e-4d20-a371-35aea15f88b9'),
  ('State Assembly District 28','4164cda9-e149-46c7-9b5a-7f1f75088ac0'),
  ('State Assembly District 29','c92c53b0-c0f9-4a30-a060-2996e90bf811'),
  ('State Assembly District 30','0cc1657e-3912-4ae8-84d6-ae9c03bb1d63'),
  ('State Assembly District 31','4a385343-5298-40bb-a78a-4c9a5e951cdb'),
  ('State Assembly District 32','f9f7497e-6ed9-4326-9391-5dc6eda76af7'),
  ('State Assembly District 33','1f700d36-f535-40ed-94a4-8ff2fba7c34d'),
  ('State Assembly District 35','2dfff08a-d688-4570-80ff-1f2eb165e62a'),
  ('State Assembly District 36','c7fd48a8-f65d-4282-adc9-27ed5b468151'),
  ('State Assembly District 37','6d0f0805-d61e-4961-933e-3cfbdbefa20e'),
  ('State Assembly District 38','abbe5632-647e-4cb2-ab0c-6a870c3da012'),
  ('State Assembly District 45','927850b9-2c91-44f7-a6be-f4c81dc3b75d'),
  ('State Assembly District 47','fa86b35b-b6e8-4b0b-8eae-5e22a31db37e'),
  ('State Assembly District 50','cf32d02c-0670-428a-a8a7-ea3766437a57'),
  ('State Assembly District 58','fa672e10-c60e-48ef-b636-ecded4465e72'),
  ('State Assembly District 59','43ae2686-e718-4044-aaf0-0ae153d4e5bf'),
  ('State Assembly District 60','3879816a-b7c9-4844-870a-34c3c33a96c2'),
  ('State Assembly District 63','9a14e79d-69df-418c-a040-60586b2f8891'),
  ('State Assembly District 68','30ef8b70-23fb-4533-b4e1-a9ad1cfa9bef'),
  ('State Assembly District 70','094f7a7e-b9e4-4a27-9cad-3f456d11fdd6'),
  ('State Assembly District 71','1621afeb-6cb1-4368-98db-6e18b0723faa'),
  ('State Assembly District 72','e23ee62c-0e3d-406a-a201-be5c5219a374'),
  ('State Assembly District 73','9cbc48f6-47c9-4435-b8b9-6201277c2aaa'),
  ('State Assembly District 74','406f82bd-66e1-4817-b1d5-3f732576f417'),
  ('State Assembly District 75','fb3ae5e9-bc6e-4136-8450-a8bc82767431'),
  ('State Assembly District 76','82927e9d-6c17-43aa-b580-a7bc0ab81eda'),
  ('State Assembly District 77','7c2b0638-4953-4803-9d81-9a2d687063b9'),
  ('State Assembly District 78','5b95be8c-1634-43ab-acb5-f904b859a5ef'),
  ('State Assembly District 79','3441b28c-eac0-462b-9a93-bf312ace0328'),
  ('State Assembly District 80','2a7ab2f1-c173-45ce-8589-ff3fc1c16abd');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, s.office_id, s.position_name, NULL, 1
FROM leg_race_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=s.position_name
);

CREATE TEMP TABLE leg_cand_seed
  (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO leg_cand_seed VALUES
  ('State Senate District 2','Damon Connolly','Damon','Connolly',false,NULL::uuid),
  ('State Senate District 2','Tief Gibbs','Tief','Gibbs',false,NULL::uuid),
  ('State Senate District 4','Alexandra Duarte','Alexandra','Duarte',false,NULL::uuid),
  ('State Senate District 4','Jaron Brandon','Jaron','Brandon',false,NULL::uuid),
  ('State Senate District 6','Roger Niello','Roger','Niello',true,'22152e41-31b9-4700-9226-4e274c616f37'::uuid),
  ('State Senate District 6','Sean Frame','Sean','Frame',false,NULL::uuid),
  ('State Senate District 8','Angelique Ashby','Angelique','Ashby',true,'060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb'::uuid),
  ('State Senate District 8','Susan A Mason','Susan','Mason',false,NULL::uuid),
  ('State Senate District 10','Linda R. Price','Linda','Price',false,NULL::uuid),
  ('State Senate District 10','Scott Sakakihara','Scott','Sakakihara',false,NULL::uuid),
  ('State Senate District 12','Nathan Magsig','Nathan','Magsig',false,NULL::uuid),
  ('State Senate District 12','William Brown Jr.','William','Brown',false,NULL::uuid),
  ('State Senate District 14','Darin S. DuPont','Darin','DuPont',false,NULL::uuid),
  ('State Senate District 14','Esmeralda Soria','Esmeralda','Soria',false,NULL::uuid),
  ('State Senate District 16','Guillermo Asuncion Gonzalez','Guillermo','Gonzalez',false,NULL::uuid),
  ('State Senate District 16','Melissa Hurtado','Melissa','Hurtado',true,'d3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26'::uuid),
  ('State Senate District 18','Art Hodges','Art','Hodges',false,NULL::uuid),
  ('State Senate District 18','Steve Padilla','Steve','Padilla',true,'3a462896-e249-4c79-94b7-175bd2efcf73'::uuid),
  ('State Senate District 32','Kelly Seyarto','Kelly','Seyarto',true,'4fccbf85-d794-4cdc-a8b8-674ff1b48784'::uuid),
  ('State Senate District 32','Tiffanie Tate','Tiffanie','Tate',false,NULL::uuid),
  ('State Senate District 38','Catherine S. Blakespear','Catherine','Blakespear',true,'fad61dc3-a3ad-4056-b2f2-1f5d32fb886d'::uuid),
  ('State Senate District 38','Laura Bassett','Laura','Bassett',false,NULL::uuid),
  ('State Senate District 40','Kristie Bruce-Lane','Kristie','Bruce-Lane',false,NULL::uuid),
  ('State Senate District 40','Mara Elliott','Mara','Elliott',false,NULL::uuid),
  ('State Assembly District 1','Dianna Margaret James','Dianna','James',false,NULL::uuid),
  ('State Assembly District 1','Heather Hadwick','Heather','Hadwick',true,'1af14e38-da38-44ea-854d-3d8f1c615460'::uuid),
  ('State Assembly District 2','Chris Rogers','Chris','Rogers',true,'d8c6901d-ad98-484e-b932-9ea77cfb677d'::uuid),
  ('State Assembly District 2','Michael Greer','Michael','Greer',false,NULL::uuid),
  ('State Assembly District 4','Cecilia M. Aguiar-Curry','Cecilia','Aguiar-Curry',true,'8ba12ba5-ba07-48be-ae0e-88e1d1ef5257'::uuid),
  ('State Assembly District 5','Joe Patterson','Joe','Patterson',true,'038b7624-492e-496c-8b97-0926ef4a4a1e'::uuid),
  ('State Assembly District 5','Neva Parker','Neva','Parker',false,NULL::uuid),
  ('State Assembly District 6','Jagtar Singh','Jagtar','Singh',false,NULL::uuid),
  ('State Assembly District 6','Maggy Krell','Maggy','Krell',true,'a7e904b1-ec37-4c43-8594-99d778e7351a'::uuid),
  ('State Assembly District 7','Amy L. Slavensky','Amy','Slavensky',false,NULL::uuid),
  ('State Assembly District 7','Josh Hoover','Josh','Hoover',true,'acb2a944-dd73-484d-83e9-86362af0eb42'::uuid),
  ('State Assembly District 8','David Jariustokaeutulelei Tangipa','David','Tangipa',true,'4db536d2-d624-4225-b5ff-d22b44c1e9a7'::uuid),
  ('State Assembly District 9','Heath Flora','Heath','Flora',true,'a0c59a09-fa45-4765-b6c5-17843699991d'::uuid),
  ('State Assembly District 9','Matthew Adams','Matthew','Adams',false,NULL::uuid),
  ('State Assembly District 10','Stephanie Nguyen','Stephanie','Nguyen',true,'7c23df4c-d105-4f48-8490-cb667a5e3382'::uuid),
  ('State Assembly District 10','Vinaya Singh','Vinaya','Singh',false,NULL::uuid),
  ('State Assembly District 11','Jenny Leilani Callison','Jenny','Callison',false,NULL::uuid),
  ('State Assembly District 11','Lori D Wilson','Lori','Wilson',true,'fc8374d8-7186-4be8-9c36-f37df2e9c0d8'::uuid),
  ('State Assembly District 12','Eric Lucan','Eric','Lucan',false,NULL::uuid),
  ('State Assembly District 12','Jackie Elward','Jackie','Elward',false,NULL::uuid),
  ('State Assembly District 13','Rhodesia Ransom','Rhodesia','Ransom',true,'6a36e92b-d953-4309-8423-1e0ba4e68b6f'::uuid),
  ('State Assembly District 13','Tom Patti','Tom','Patti',false,NULL::uuid),
  ('State Assembly District 14','Buffy Wicks','Buffy','Wicks',true,'5821d0a9-672e-44c0-bac7-1a802a2e8368'::uuid),
  ('State Assembly District 14','Mark Rendon','Mark','Rendon',false,NULL::uuid),
  ('State Assembly District 15','Anamarie Avila Farias','Anamarie','Farias',true,'52d3e817-03bf-4dd5-8a16-67b44acf23ac'::uuid),
  ('State Assembly District 15','Arthur Webb','Arthur','Webb',false,NULL::uuid),
  ('State Assembly District 16','Joseph A. Rubay','Joseph','Rubay',false,NULL::uuid),
  ('State Assembly District 16','Rebecca Bauer-Kahan','Rebecca','Bauer-Kahan',true,'2cca193f-574d-4ec7-b0c8-e0fcd27d5eab'::uuid),
  ('State Assembly District 17','Manuel Noris-Barrera','Manuel','Noris-Barrera',false,NULL::uuid),
  ('State Assembly District 17','Matt Haney','Matt','Haney',true,'4c7d1cea-a6ce-4185-a977-c754800f491a'::uuid),
  ('State Assembly District 18','Andre Sandford','Andre','Sandford',false,NULL::uuid),
  ('State Assembly District 18','Mia Bonta','Mia','Bonta',true,'0d70edc9-535c-4191-a222-fe57ebde4467'::uuid),
  ('State Assembly District 19','Catherine Stefani','Catherine','Stefani',true,'0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid),
  ('State Assembly District 19','Philip Louis Wing','Philip','Wing',false,NULL::uuid),
  ('State Assembly District 20','Liz Ortega','Liz','Ortega',true,'6730d01a-e87e-4177-9a2b-876b9c494774'::uuid),
  ('State Assembly District 20','Patricia Muga','Patricia','Muga',false,NULL::uuid),
  ('State Assembly District 21','Diane Papan','Diane','Papan',true,'fb44c938-26fd-40ca-9333-e842693a1ad4'::uuid),
  ('State Assembly District 21','Jabra J Muhawieh','Jabra','Muhawieh',false,NULL::uuid),
  ('State Assembly District 22','Juan Alanis','Juan','Alanis',true,'7520a629-a0ec-44b3-9460-c7e4574a897d'::uuid),
  ('State Assembly District 23','David G. Johnson','David','Johnson',false,NULL::uuid),
  ('State Assembly District 23','Marc Berman','Marc','Berman',true,'4cfacf31-d285-40ac-8373-e350912fddda'::uuid),
  ('State Assembly District 24','Alex Lee','Alex','Lee',true,'525a5d79-d7a9-498a-b972-57fa517be375'::uuid),
  ('State Assembly District 24','Max Hsia','Max','Hsia',false,NULL::uuid),
  ('State Assembly District 25','Ash Kalra','Ash','Kalra',true,'eb1a285e-fd86-4da1-a198-a66ad6a81be4'::uuid),
  ('State Assembly District 25','Himat Singh Bainiwal','Himat','Bainiwal',false,NULL::uuid),
  ('State Assembly District 26','Patrick Ahrens','Patrick','Ahrens',true,'bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid),
  ('State Assembly District 26','Tim Gorsulowsky','Tim','Gorsulowsky',false,NULL::uuid),
  ('State Assembly District 27','Brian Pacheco','Brian','Pacheco',false,NULL::uuid),
  ('State Assembly District 27','Mike Murphy','Mike','Murphy',false,NULL::uuid),
  ('State Assembly District 28','Carol Pefley','Carol','Pefley',false,NULL::uuid),
  ('State Assembly District 28','Gail Pellerin','Gail','Pellerin',true,'190c3584-0826-4a5f-a2ad-104ff70ff259'::uuid),
  ('State Assembly District 29','Dennis P. Sanchez','Dennis','Sanchez',false,NULL::uuid),
  ('State Assembly District 29','Robert Rivas','Robert','Rivas',true,'5a75d4fb-e4fe-441a-8658-e6eb57574fd4'::uuid),
  ('State Assembly District 30','Dawn Addis','Dawn','Addis',true,'2ba6e476-1d62-4ac5-a70d-f4bcbe704f39'::uuid),
  ('State Assembly District 30','Shannon Kessler','Shannon','Kessler',false,NULL::uuid),
  ('State Assembly District 31','Annalisa Perea','Annalisa','Perea',false,NULL::uuid),
  ('State Assembly District 31','Jim Polsgrove','Jim','Polsgrove',false,NULL::uuid),
  ('State Assembly District 32','David Couch','David','Couch',false,NULL::uuid),
  ('State Assembly District 33','Alexandra (Ali) Macedo','Alexandra','Macedo',true,'8566674a-3a3b-4c88-bba0-c9f42e4ff810'::uuid),
  ('State Assembly District 33','Hipolito Angel Cerros','Hipolito','Cerros',false,NULL::uuid),
  ('State Assembly District 35','Andrae Gonzales','Andrae','Gonzales',false,NULL::uuid),
  ('State Assembly District 35','Saul Ayon','Saul','Ayon',false,NULL::uuid),
  ('State Assembly District 36','Ida S. Obeso-Martinez','Ida','Obeso-Martinez',false,NULL::uuid),
  ('State Assembly District 36','Jeff Gonzalez','Jeff','Gonzalez',true,'5ad32852-789e-4013-995b-6f0aa6a5a5d4'::uuid),
  ('State Assembly District 37','Gregg Hart','Gregg','Hart',true,'21940b7c-2424-47e9-a649-077b0f827c2c'::uuid),
  ('State Assembly District 37','Sari Domingues','Sari','Domingues',false,NULL::uuid),
  ('State Assembly District 38','Michael MacDonald','Michael','MacDonald',false,NULL::uuid),
  ('State Assembly District 38','Steve Bennett','Steve','Bennett',true,'8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid),
  ('State Assembly District 45','Greg Abdouch','Greg','Abdouch',false,NULL::uuid),
  ('State Assembly District 45','James C. Ramos','James','Ramos',true,'01dd07dc-ded1-4ba5-aff3-2dc2b386af12'::uuid),
  ('State Assembly District 47','Greg Wallis','Greg','Wallis',true,'c6c04131-96f3-40d8-b881-e6c57f986d38'::uuid),
  ('State Assembly District 47','Leila Namvar','Leila','Namvar',false,NULL::uuid),
  ('State Assembly District 50','Robert Garcia','Robert','Garcia',true,'8bfb459b-9823-4b0d-81f4-49cb97831a80'::uuid),
  ('State Assembly District 50','Victoria Viveros Mageno','Victoria','Mageno',false,NULL::uuid),
  ('State Assembly District 58','Clarissa Cervantes','Clarissa','Cervantes',false,NULL::uuid),
  ('State Assembly District 58','Leticia Castillo','Leticia','Castillo',true,'30fee995-e2e3-42d6-9993-d000fd73b919'::uuid),
  ('State Assembly District 59','Phillip Chen','Phillip','Chen',true,'ed32efa5-b455-4323-a12f-5fe79bc4ffd6'::uuid),
  ('State Assembly District 59','Victor Hernandez','Victor','Hernandez',false,NULL::uuid),
  ('State Assembly District 60','Corey A Jackson','Corey','Jackson',true,'bbd7825a-6778-4cca-81c8-8ef3ded55965'::uuid),
  ('State Assembly District 60','Ed Delgado','Ed','Delgado',false,NULL::uuid),
  ('State Assembly District 63','Kevin Akin','Kevin','Akin',false,NULL::uuid),
  ('State Assembly District 63','Natasha Johnson','Natasha','Johnson',true,'3f200d93-74aa-4191-a275-77b64ff5b219'::uuid),
  ('State Assembly District 68','David Penaloza','David','Penaloza',false,NULL::uuid),
  ('State Assembly District 68','Jessie Lopez','Jessie','Lopez',false,NULL::uuid),
  ('State Assembly District 70','Paula Swift','Paula','Swift',false,NULL::uuid),
  ('State Assembly District 70','Tri Ta','Tri','Ta',true,'c2975ee6-7770-4c5f-809c-4e1245f2ab64'::uuid),
  ('State Assembly District 71','JJ Galvez','JJ','Galvez',false,NULL::uuid),
  ('State Assembly District 71','Kate Sanchez','Kate','Sanchez',true,'62dfefeb-9979-445a-aee6-06cf7c03a8c0'::uuid),
  ('State Assembly District 72','Chris Kluwe','Chris','Kluwe',false,NULL::uuid),
  ('State Assembly District 72','Gracey Van Der Mark','Gracey','Van Der Mark',false,NULL::uuid),
  ('State Assembly District 73','Cottie Petrie-Norris','Cottie','Petrie-Norris',true,'065c6e87-8778-43ee-ab44-b9982a677aa7'::uuid),
  ('State Assembly District 73','Urson Russell','Urson','Russell',false,NULL::uuid),
  ('State Assembly District 74','Laurie Davies','Laurie','Davies',true,'7778111f-551f-407f-87c7-e30268ea5e0a'::uuid),
  ('State Assembly District 74','Sergio Farias','Sergio','Farias',false,NULL::uuid),
  ('State Assembly District 75','Carl DeMaio','Carl','DeMaio',true,'a6d96375-a61c-4a13-9afa-99914456e8c2'::uuid),
  ('State Assembly District 75','Gerald C. Boursiquot','Gerald','Boursiquot',false,NULL::uuid),
  ('State Assembly District 76','Carrie S. Espinoza Villanueva','Carrie','Villanueva',false,NULL::uuid),
  ('State Assembly District 76','Darshana Patel','Darshana','Patel',true,'9a927fae-60bf-41f9-8ec0-433cc98997fa'::uuid),
  ('State Assembly District 77','Tasha Boerner','Tasha','Boerner',true,'0a9171c6-0676-4704-b825-a7e16c66f1c2'::uuid),
  ('State Assembly District 77','Trinity Hannaway','Trinity','Hannaway',false,NULL::uuid),
  ('State Assembly District 78','Chris Ward','Chris','Ward',true,'1ee95c1d-6127-494b-9f68-e8b3c975adee'::uuid),
  ('State Assembly District 78','Payton Galvez','Payton','Galvez',false,NULL::uuid),
  ('State Assembly District 79','Andrew Lawson','Andrew','Lawson',false,NULL::uuid),
  ('State Assembly District 79','LaShae Sharp-Collins','LaShae','Sharp-Collins',true,'cb2ae7a3-3b6a-462b-8fe8-47f3ce4cb7a2'::uuid),
  ('State Assembly District 80','Alejandro Galicia','Alejandro','Galicia',false,NULL::uuid),
  ('State Assembly District 80','David A. Alvarez','David','Alvarez',true,'e0451383-4594-4247-8297-acc388a7e0c3'::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf). Read 2026-09-23 (CA_0202).'
FROM leg_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- (1) the 67 seeded races, each on its own office, no party, one seat
  SELECT count(*) INTO v_n FROM essentials.races r JOIN leg_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND r.office_id=s.office_id AND r.primary_party IS NULL AND r.seats=1;
  IF v_n <> 67 THEN RAISE EXCEPTION 'seeded races: expected 67 on their offices, got %', v_n; END IF;

  -- (2) each race's office is the district its position_name names (no crossed wires)
  SELECT count(*) INTO v_n FROM essentials.races r JOIN leg_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND NOT ( upper(d.state)='CA'
           AND d.district_type = CASE WHEN s.position_name LIKE 'State Senate%' THEN 'STATE_UPPER' ELSE 'STATE_LOWER' END
           AND ltrim(substring(d.geo_id from 3), '0') = substring(s.position_name from '([0-9]+)$') );
  IF v_n <> 0 THEN RAISE EXCEPTION '% race(s) sit on the wrong district', v_n; END IF;

  -- (3) every seeded race resolves to its chamber's geofence (G5210 Senate / G5220 Assembly)
  SELECT count(*) INTO v_n FROM essentials.races r JOIN leg_race_seed s ON s.position_name=r.position_name
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND NOT (d.mtfcc = CASE WHEN d.district_type='STATE_UPPER' THEN 'G5210' ELSE 'G5220' END
              AND EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb WHERE gb.geo_id=d.geo_id AND gb.mtfcc=d.mtfcc));
  IF v_n <> 0 THEN RAISE EXCEPTION '% race(s) not resolvable to their chamber geofence', v_n; END IF;

  -- (4) exactly the certified candidates: 130 rows, no duplicates, the 4 one-candidate races
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN leg_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid;
  IF v_n <> 130 THEN RAISE EXCEPTION 'seeded candidates: expected 130, got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM (
    SELECT r.id FROM essentials.races r JOIN leg_race_seed s ON s.position_name=r.position_name
      LEFT JOIN essentials.race_candidates rc ON rc.race_id=r.id
     WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     GROUP BY r.id HAVING count(rc.id) NOT IN (1, 2)) x;
  IF v_n <> 0 THEN RAISE EXCEPTION '% seeded race(s) with other than 1 or 2 candidates', v_n; END IF;
  SELECT count(*) INTO v_n FROM (
    SELECT r.id FROM essentials.races r JOIN leg_race_seed s ON s.position_name=r.position_name
      JOIN essentials.race_candidates rc ON rc.race_id=r.id
     WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     GROUP BY r.id HAVING count(*)=1) x;
  IF v_n <> 4 THEN RAISE EXCEPTION 'one-candidate races: expected 4, got %', v_n; END IF;

  -- (5) incumbents: exactly 54, each the current holder of that race's office; nobody else linked
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN leg_race_seed s ON s.position_name=r.position_name
    JOIN essentials.office_current_holder och ON och.office_id=r.office_id AND och.politician_id=rc.politician_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND rc.is_incumbent;
  IF v_n <> 54 THEN RAISE EXCEPTION 'incumbents linked to the current holder: expected 54, got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN leg_race_seed s ON s.position_name=r.position_name
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND (rc.is_incumbent <> (rc.politician_id IS NOT NULL) OR rc.candidate_status <> 'active');
  IF v_n <> 0 THEN RAISE EXCEPTION '% candidate(s) linked without incumbency, or not active', v_n; END IF;

  -- (6) the general now carries the whole Legislature: 20 Senate + 80 Assembly races
  SELECT count(*) INTO v_n FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND c.name='California State Senate';
  IF v_n <> 20 THEN RAISE EXCEPTION 'CA 2026 general Senate races: expected 20, got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND c.name='California State Assembly';
  IF v_n <> 80 THEN RAISE EXCEPTION 'CA 2026 general Assembly races: expected 80, got %', v_n; END IF;
END $$;

COMMIT;
