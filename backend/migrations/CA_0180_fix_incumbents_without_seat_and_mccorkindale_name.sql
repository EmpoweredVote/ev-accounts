-- CA_0180_fix_incumbents_without_seat_and_mccorkindale_name.sql
-- Fix five ACTIVE rows flagged is_incumbent that hold no seat (no office_terms row), and one row whose name is a
-- scrape error. Found during the CA_0178 review (2026-09-23), where these rows could only be judged on named-person
-- evidence because they had no seat.
--
--   A. Two DUPLICATES of sitting State Senators. Each person has a seated row (source NULL, holding the Senate seat,
--      carrying the race row and most compass answers) and a second 'cicero' row with no seat that carries the
--      person's committee links, social identifiers, office addresses and official site:
--        Caroline Menjivar  dup 27a358cd-d4d8-47d6-b2f1-6d984cb46b39  ->  seated 4baa73c2-d38b-4d07-894f-1577d5ba43a3 (SD 20)
--        Tony Strickland    dup b156be63-59f0-4caa-98d9-44ae7afccf79  ->  seated 863ef272-ea35-482b-aee2-447c06bd469d (SD 36)
--      Evidence: senate.ca.gov/senators lists "Caroline Menjivar", District 20, and "Tony Strickland", District 36
--      (read 2026-09-23). The dup rows' own urls are sd20.senate.ca.gov and sr36.senate.ca.gov.
--      Same shape as CC_0102: the SEATED row is the person; the dup's committee links move to it. Strickland's only
--      two confirmed committees (Cal-Access 1294413 "STRICKLAND FOR SENATE" and 1325751 "STRICKLAND FOR CONTROLLER
--      2010", $198,403 across 4 aggregate rows) sit on the dup today, so his seated profile shows no money; after this
--      file it does. The links keep their ids, so contributions and aggregates follow them unchanged.
--      Also moved: identifiers (6 + 7: votesmart, facebook, instagram, twitter, linkedin) and addresses (2 + 2:
--      Capitol and district offices) -- the seated rows have none -- and the dup's urls and photo_origin_url where
--      the seated row's are empty.
--      NOT moved: compass answers and their context. Menjivar's 7 dup answers are identical to the seated row's
--      (same topic, season and value). Strickland's are not: in Season 1 (CLOSED) the dup says 5 where the seated row
--      says 4 on Affordable Housing, Climate Change and Environment, Fossil Fuel Policy and Immigration, and the dup
--      alone answers School Vouchers (4). A closed season's answers are not rewritten here; they stay on the
--      deactivated dup, visible to nobody, and the conflict is a stance-review lead. The seated rows' own images
--      stay; the dups' images stay on the dups.
--      Then the dups are deactivated (is_active = false, is_incumbent = false), with a note. Nothing is deleted.
--   B. Three FORMER Santa Monica councilmembers still flagged incumbent: Phil Brock, Oscar de la Torre, Christine
--      Parra. Evidence: City of Santa Monica press release 2024-12-11 ("Lana Negrete selected as mayor, Caroline
--      Torosis as mayor pro tem, four new councilmembers installed"): Dan Hall, Ellis Raskin, Barry Snell and Natalya
--      Zernitskaya were installed on 2024-12-10, replacing "outgoing Mayor Phil Brock and outgoing Councilmembers
--      Gleam Davis, Oscar de la Torre, and Christine Parra". All seven seats in this DB are held by the current
--      members. House convention (CA_0156): a real former member stays ACTIVE with is_incumbent = false. No past term
--      is written: the seats are at-large slots whose current terms have unknown starts, so any dated past term
--      would be invented or would overlap. Phil Brock is also a Nov 2026 candidate (CA_0160 race row, politician_id
--      NULL); that row is not touched.
--   C. Hidden Hills: the row holding council seat 202dae43-8243-46ea-b1fa-3746ef6a1c9b is named "Laura McCorkindale
--      and Adam" (first_name "Laura McCorkindale and", last_name "Adam"). hiddenhills.gov/city-council lists Council
--      Member Laura McCorkindale and no member named Adam; The Acorn (2026-09-18) confirms she is a sitting member
--      whose seat is up in November 2026 (she is not running). Renamed to Laura McCorkindale. Its 51 committee links
--      were made on the token "ADAM"; they are already not_applicable (50) or disputed (1, CA_0178) and carry no money.
--
--   D. Links that the new facts make judgeable (CA_0178 left them 'needs_research' because these rows had no seat):
--      disputed here with the same suffix format, marker 'CA_0180 (2026-09-23)':
--        Menjivar   1347503, 1368081, 1381731, 1386808 -- Oakland City Council D7, San Leandro school board, Alameda
--                   County Board of Education, Oakland school board; filer area code 510 (East Bay). She represents
--                   the San Fernando Valley (SD 20).                                                        basis B
--        Strickland 1401620 -- "STRICKLAND FOR DISTRICT ATTORNEY 2018", filer area code 559 (Fresno); a county
--                   office he never held, far from his districts.                                            basis C
--        Brock      1472886 -- a committee supporting Hall, Raskin, Snell and Zernitskaya and OPPOSING Brock
--                   (Santa Monica 2024), not his own committee.                                              basis B
--        Parra      1431553, 1474116 -- State Center Community College board and Fowler City Council (Fresno
--                   County, filer area code 559), not Santa Monica.                                          basis B
--      Left as they are: the rest of these rows' links (their own campaigns, or nothing places them elsewhere).
--
-- LEASES: place:0670000 (Santa Monica) and place:0633518 (Hidden Hills) are held by another session of the same
-- operator ("LA city Nov 2026 races", CA_0160/CA_0165, merged). Not taken over; this file touches none of the race
-- rows, and every step is guarded on the pre-image below.
--
-- NOT IN SCOPE: the same defect on other rows. 1,822 active rows are flagged is_incumbent with no office_terms row
-- (1,303 with source NULL, 502 'manual', 17 other). Of the 'cicero'/'scraped' ones, this file fixes 5 of 9; the
-- other four are Eloy Morales Jr. (a duplicate of the seated Inglewood D3 row "Eloy Morales", carrying three
-- confirmed committees, $87,492), Jackie Goldberg and Mónica García (former LAUSD members), and George Dotson.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML). No DELETE. No office_terms change.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). The dry run was repeated right before the
-- apply; verified after: the seated Menjivar / Strickland rows hold 9 / 23 links, 6 / 7 identifiers, 2 / 2 addresses and
-- Strickland's $198,403 confirmed; both dups inactive with 0 links; Brock, de la Torre, Parra active and not
-- incumbent; the Hidden Hills row is Laura McCorkindale; 8 links disputed with the marker.
--
-- ROLLBACK (in this order):
--   1. UPDATE transparent_motivations.politician_sources SET research_status = 'needs_research',
--        notes = CASE WHEN notes IS JSON OBJECT THEN (notes::jsonb - 'disputed_by' - 'disputed_reason')::text
--                     ELSE left(notes, strpos(notes, ' | DISPUTED by CA_0180 (2026-09-23): ') - 1) END
--       WHERE research_status = 'disputed' AND strpos(notes, 'CA_0180 (2026-09-23)') > 0;
--   2. Re-point the _move, _ident and _addr ids below back to their dup row; set the dups' is_active and
--      is_incumbent back to true and clear the seated rows' copied urls / photo_origin_url; set the three Santa Monica rows' is_incumbent back to true; restore the Hidden Hills name
--      ('Laura McCorkindale and Adam', 'Laura McCorkindale and', 'Adam'); strip the 'CA_0180 (2026-09-23)' notes.
-- IDEMPOTENT: every step is guarded on its pre-image; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _pair (dup uuid PRIMARY KEY, keep uuid, who text, office uuid) ON COMMIT DROP;
INSERT INTO _pair VALUES
  ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', '4baa73c2-d38b-4d07-894f-1577d5ba43a3', 'Caroline Menjivar', '7a7d8d8e-3af2-4372-a943-6aa92c10fefb'),
  ('b156be63-59f0-4caa-98d9-44ae7afccf79', '863ef272-ea35-482b-aee2-447c06bd469d', 'Tony Strickland',   'e31dfcd0-d34f-4ecd-93cc-409d0e185687');

-- every committee link, identifier and address on the two dups (measured 2026-09-23: 9 + 23 links, 6 + 7
-- identifiers, 2 + 2 addresses), listed by id so a re-run and a rollback both know exactly what moved
CREATE TEMP TABLE _move (id uuid PRIMARY KEY, dup uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _move VALUES
  ('029facc2-b623-431c-b5ae-05d724dc43f9','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('0956732b-6991-4944-b45e-2a6dd51fbb8e','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('1663e7da-d93e-4137-87c9-2a712b00b379','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('780dd538-cda0-4729-b420-fa0e75de9dd0','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('b1f048a6-72c6-4be5-b5cf-bcdd5ef4ab8d','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('cba93f10-3487-41bf-b510-04e334f01245','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('da84ccce-ec5c-40a4-9892-2116c46ee4b6','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('daf08a77-fdeb-4541-8c5c-7fd5b5e2b475','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('f06d0e1b-ecd0-4b9a-9821-8d6b4a64f094','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('0f5ad76d-217e-4190-832b-8143ad9f9a98','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('17aa3bc0-3476-4530-8274-c609a2ff108e','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('1e652d51-6a6a-4dd6-8397-b87332b90752','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('37f2d9a1-4e60-4a75-bbe0-ce1fb5a86ca0','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('4debba49-de57-4915-898b-2d94ab9dafc7','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('5e5d5dc3-9ad9-4980-9697-905daf27068e','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('662c0d25-87e2-4419-abf8-ef21564f76a1','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('678c3403-dddf-4b26-84f2-db2a800c07ed','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('7cd12065-b658-475e-bc1e-490a03117d7a','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('82d0abd5-b9ed-41bf-9c7d-28feb7ea272e','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('904a3a9d-ee28-499a-9eda-72d0007013a5','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('91c1345e-bd07-4b6b-9cb4-2c6939b9efc4','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('a29c5547-4a69-4112-b7dc-df370713cac8','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('a3da9783-c64b-40fc-a69d-81db38d49d42','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('a6572654-305d-4dcf-9c9b-c3acdc846640','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('a728a5c3-94ab-48d3-ba79-846e7264dbea','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('aeb3955d-a806-478b-85d3-969c91859d92','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('b02989e7-8456-42e2-aa77-7256fb4ddfee','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('b27cb08c-268a-4b73-9c9d-5c6860b1cfce','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('b2d5883f-f1fa-4f37-a3f0-ed80a6cd98cc','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('b54f51ae-f399-4a69-a9f4-17e08ca9775d','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('c3ccd46f-5a6d-4944-a344-c78c6c1254d5','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('d54b74d3-2390-4635-89a5-3b8630880299','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d');
CREATE TEMP TABLE _ident (id uuid PRIMARY KEY, dup uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _ident VALUES
  ('38f25331-cbda-41bc-bc00-e91360a3f20f','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('94b23bf4-0924-4720-99e7-df1765f706d3','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('d8ea8479-fb49-4dd9-b64e-3334200840cc','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('dd46c2a9-7416-4c35-a689-46d795c1640b','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('f77982d3-dc98-49cd-a9df-e974e965282d','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('f7fa7831-97ef-4d0f-a186-75edf1153939','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('1d11cb66-d29f-48f9-939b-9a474807749a','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('2bcdc419-30cc-4ceb-be35-60f90da7ada9','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('44c3ad8b-0645-4186-b44c-719cbf54d9b6','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('762263b1-79c1-4586-aaf4-c471befd8289','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('8193ccf4-1e4b-49e5-8810-7ed7fab38b43','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('9100e394-0eb1-4d85-a809-f80d989cce2f','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('9e5609a2-22fe-4837-8671-0ad61de14a46','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d');
CREATE TEMP TABLE _addr (id uuid PRIMARY KEY, dup uuid, keep uuid) ON COMMIT DROP;
INSERT INTO _addr VALUES
  ('2f353f09-d9c6-4148-b290-887bece1a23e','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('7a9a56b0-7f6d-477d-83a3-20d4885fd8fd','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','4baa73c2-d38b-4d07-894f-1577d5ba43a3'),
  ('82f78085-fd34-48ca-8f58-c55854f3a9b5','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d'),
  ('9d274ecf-5e2f-4fc5-9543-b26902b9dd95','b156be63-59f0-4caa-98d9-44ae7afccf79','863ef272-ea35-482b-aee2-447c06bd469d');

CREATE TEMP TABLE _sm (id uuid PRIMARY KEY, full_name text) ON COMMIT DROP;
INSERT INTO _sm VALUES
  ('7714b7c6-9283-4ab8-802e-cbcfba5ddc96', 'Phil Brock'),
  ('86e513e7-d0a7-4419-8edd-6113629d7998', 'Oscar de la Torre'),
  ('2d47a965-81a2-4508-865c-06d45bf6ff42', 'Christine Parra');

CREATE TEMP TABLE _dis (id uuid PRIMARY KEY, politician_id uuid, external_id text, committee text, reason text) ON COMMIT DROP;
INSERT INTO _dis VALUES
  ('f06d0e1b-ecd0-4b9a-9821-8d6b4a64f094','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','1347503','MENJIVAR FOR OAKLAND CITY COUNCIL DISTRICT 7 - 2012',
   'surname-only auto-link: Cal-Access 1347503 "MENJIVAR FOR OAKLAND CITY COUNCIL DISTRICT 7 - 2012" -- a campaign for the Oakland City Council, not for the row''s seat; filer area code 510 (East Bay); this row is Caroline Menjivar, State Senator for District 20 (San Fernando Valley)'),
  ('029facc2-b623-431c-b5ae-05d724dc43f9','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','1368081','MENJIVAR FOR SCHOOL BOARD SAN LEANDRO 2014',
   'surname-only auto-link: Cal-Access 1368081 "MENJIVAR FOR SCHOOL BOARD SAN LEANDRO 2014" -- a campaign for the San Leandro school board (Alameda County), not for the row''s seat; filer area code 510 (East Bay); this row is Caroline Menjivar, State Senator for District 20 (San Fernando Valley)'),
  ('cba93f10-3487-41bf-b510-04e334f01245','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','1381731','MENJIVAR FOR ALAMEDA COUNTY BOARD ED. 3 2016',
   'surname-only auto-link: Cal-Access 1381731 "MENJIVAR FOR ALAMEDA COUNTY BOARD ED. 3 2016" -- a campaign for the Alameda County Board of Education, not for the row''s seat; filer area code 510 (East Bay); this row is Caroline Menjivar, State Senator for District 20 (San Fernando Valley)'),
  ('0956732b-6991-4944-b45e-2a6dd51fbb8e','27a358cd-d4d8-47d6-b2f1-6d984cb46b39','1386808','MENJIVAR FOR OAKLAND SCHOOL DISTRICT 5 2016',
   'surname-only auto-link: Cal-Access 1386808 "MENJIVAR FOR OAKLAND SCHOOL DISTRICT 5 2016" -- a campaign for the Oakland school board, not for the row''s seat; filer area code 510 (East Bay); this row is Caroline Menjivar, State Senator for District 20 (San Fernando Valley)'),
  ('d54b74d3-2390-4635-89a5-3b8630880299','b156be63-59f0-4caa-98d9-44ae7afccf79','1401620','STRICKLAND FOR DISTRICT ATTORNEY 2018',
   'surname-only auto-link: Cal-Access 1401620 "STRICKLAND FOR DISTRICT ATTORNEY 2018" -- a campaign for district attorney; filer area code 559 (Fresno) is outside the Los Angeles and Orange County region and nothing ties it to the row; this row is Tony Strickland, State Senator for District 36'),
  ('9ed193fc-5beb-413f-aecd-d00192230a3e','7714b7c6-9283-4ab8-802e-cbcfba5ddc96','1472886','HALL, RASKIN, SNELL, ZERNITSKAYA, AND AGAINST BROCK FOR CITY COUNCIL 2024, SPONSORED BY UNITE HERE LOCAL 11; RENTERS AND WORKERS FOR SANTA MONICA IN SUPPORT OF',
   'surname-only auto-link: Cal-Access 1472886 "HALL, RASKIN, SNELL, ZERNITSKAYA, AND AGAINST BROCK FOR CITY COUNCIL 2024, ..." -- a committee supporting Hall, Raskin, Snell and Zernitskaya and OPPOSING Brock, not the row''s own committee; filer area code 213 (Los Angeles); this row is Phil Brock, former Santa Monica City Council member (left 2024-12-10)'),
  ('8b4d98c2-45cd-4a1e-bcdd-2f7151e9cb9a','2d47a965-81a2-4508-865c-06d45bf6ff42','1431553','PARRA FOR STATE CENTER COMMUNITY COLLEGE TRUSTEE NO.3 2024',
   'surname-only auto-link: Cal-Access 1431553 "PARRA FOR STATE CENTER COMMUNITY COLLEGE TRUSTEE NO.3 2024" -- a campaign for the State Center Community College board (Fresno), not for the row''s seat; filer area code 559 (Fresno); this row is Christine Parra, former Santa Monica City Council member (left 2024-12-10)'),
  ('83ede2f6-80b3-439a-bca2-0471cac1b0a2','2d47a965-81a2-4508-865c-06d45bf6ff42','1474116','PARRA FOR FOWLER CITY COUNCIL 2024',
   'surname-only auto-link: Cal-Access 1474116 "PARRA FOR FOWLER CITY COUNCIL 2024" -- a campaign for the Fowler City Council (Fresno County), not for the row''s seat; filer area code 559 (Fresno); this row is Christine Parra, former Santa Monica City Council member (left 2024-12-10)');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
          JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
         WHERE ps.research_status = 'confirmed') AS confirmed_total;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- A. each seated row holds its Senate seat, is active and incumbent; each dup is the same name and holds nothing
  SELECT count(*) INTO v_n FROM _pair pr
    JOIN essentials.politicians k ON k.id = pr.keep AND k.full_name = pr.who AND k.is_active AND k.is_incumbent
    JOIN essentials.politicians d ON d.id = pr.dup AND d.full_name = pr.who AND d.source = 'cicero'
    JOIN essentials.office_current_holder och ON och.politician_id = pr.keep AND och.office_id = pr.office
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = pr.dup)
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id = pr.dup);
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 duplicate pairs match (seated row on its seat, dup holding no term or race)', v_n; END IF;

  -- the links to move: 9 + 23, each still on its dup (or already on its seated row, a re-run), and together they are
  -- every link either row of each pair holds; no link on a seated row collides with one on its dup
  SELECT count(*) INTO v_n FROM _move m JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
   WHERE ps.essentials_politician_id IN (m.dup, m.keep);
  IF v_n <> 32 THEN RAISE EXCEPTION 'PRE: % of 32 committee links are on their dup or seated row', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.essentials_politician_id IN (SELECT dup FROM _pair UNION SELECT keep FROM _pair)
     AND NOT EXISTS (SELECT 1 FROM _move m WHERE m.id = ps.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % link(s) on these rows were not reviewed', v_n; END IF;
  SELECT count(*) INTO v_n FROM _move m JOIN transparent_motivations.politician_sources a ON a.id = m.id
    JOIN transparent_motivations.politician_sources b ON b.essentials_politician_id = m.keep AND b.id <> a.id
         AND b.source_system = a.source_system AND b.external_id = a.external_id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % link(s) would collide on the seated row', v_n; END IF;

  SELECT count(*) INTO v_n FROM _ident x JOIN essentials.identifiers i ON i.id = x.id WHERE i.politician_id IN (x.dup, x.keep);
  IF v_n <> 13 THEN RAISE EXCEPTION 'PRE: % of 13 identifiers are on their dup or seated row', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.identifiers WHERE politician_id IN (SELECT dup FROM _pair UNION SELECT keep FROM _pair)
     AND id NOT IN (SELECT id FROM _ident);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % identifier(s) on these rows were not reviewed', v_n; END IF;
  SELECT count(*) INTO v_n FROM _addr x JOIN essentials.addresses a ON a.id = x.id WHERE a.politician_id IN (x.dup, x.keep);
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % of 4 addresses are on their dup or seated row', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.addresses WHERE politician_id IN (SELECT dup FROM _pair UNION SELECT keep FROM _pair)
     AND id NOT IN (SELECT id FROM _addr);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % address(es) on these rows were not reviewed', v_n; END IF;

  -- B. the three Santa Monica rows hold no term, and all seven Santa Monica seats are held by other people
  SELECT count(*) INTO v_n FROM _sm s JOIN essentials.politicians p ON p.id = s.id AND p.full_name = s.full_name AND p.is_active
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = s.id);
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 Santa Monica rows are the active, seatless rows reviewed', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name = 'City of Santa Monica, California, US' AND c.name = 'City Council'
     AND p.full_name IN ('Barry Snell','Caroline Torosis','Dan Hall','Ellis Raskin','Jesse Zwick','Lana Negrete','Natalya Zernitskaya');
  IF v_n <> 7 THEN RAISE EXCEPTION 'PRE: % of the 7 Santa Monica seats are held by the current members', v_n; END IF;

  -- C. the Hidden Hills row: still the scrape name (or already fixed by this file), still on its seat
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id AND och.office_id = '202dae43-8243-46ea-b1fa-3746ef6a1c9b'
   WHERE p.id = '12eebc77-777c-42fb-aad8-1080cd2bedbf' AND NOT p.full_name_manual_override
     AND ((p.full_name = 'Laura McCorkindale and Adam' AND p.first_name = 'Laura McCorkindale and' AND p.last_name = 'Adam')
          OR (p.full_name = 'Laura McCorkindale' AND p.first_name = 'Laura' AND p.last_name = 'McCorkindale'));
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the Hidden Hills row is not in its reviewed state'; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE full_name = 'Laura McCorkindale' AND id <> '12eebc77-777c-42fb-aad8-1080cd2bedbf';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: another row is already named Laura McCorkindale'; END IF;

  -- D. the links to dispute are the reviewed ones, on the reviewed rows (or already disputed by this file)
  SELECT count(*) INTO v_n FROM _dis x JOIN transparent_motivations.politician_sources ps ON ps.id = x.id
   WHERE ps.source_system = 'cal_access' AND ps.external_id = x.external_id
     AND COALESCE(split_part(ps.notes, ' | ', 1)::jsonb ->> 'committee_name', '') = x.committee
     AND (ps.essentials_politician_id = x.politician_id
          OR ps.essentials_politician_id IN (SELECT keep FROM _pair WHERE dup = x.politician_id))
     AND (ps.research_status = 'needs_research'
          OR (ps.research_status = 'disputed' AND strpos(ps.notes, 'CA_0180 (2026-09-23)') > 0));
  IF v_n <> 8 THEN RAISE EXCEPTION 'PRE: % of 8 links to dispute match their reviewed record', v_n; END IF;
END $$;

-- ─── A. Merge the two duplicate Senator rows into the seated rows ────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET essentials_politician_id = m.keep, updated_at = now()
  FROM _move m WHERE ps.id = m.id AND ps.essentials_politician_id = m.dup;

UPDATE essentials.identifiers i SET politician_id = x.keep FROM _ident x WHERE i.id = x.id AND i.politician_id = x.dup;
UPDATE essentials.addresses a  SET politician_id = x.keep FROM _addr  x WHERE a.id = x.id AND a.politician_id = x.dup;

UPDATE essentials.politicians k
   SET urls = d.urls
  FROM _pair pr JOIN essentials.politicians d ON d.id = pr.dup
 WHERE k.id = pr.keep AND COALESCE(cardinality(k.urls), 0) = 0 AND COALESCE(cardinality(d.urls), 0) > 0;
UPDATE essentials.politicians k
   SET photo_origin_url = d.photo_origin_url
  FROM _pair pr JOIN essentials.politicians d ON d.id = pr.dup
 WHERE k.id = pr.keep AND k.photo_origin_url IS NULL AND d.photo_origin_url IS NOT NULL;

UPDATE essentials.politicians d
   SET is_active = false, is_incumbent = false,
       notes = COALESCE(d.notes, ARRAY[]::text[]) || ('CA_0180 (2026-09-23): DUPLICATE of ' || pr.keep::text
               || ', the seated row for the same senator (senate.ca.gov/senators). Committee links, identifiers and '
               || 'addresses moved there; compass answers left here (Menjivar: identical to the seated row; Strickland: '
               || 'Season 1 conflicts on 4 topics plus 1 dup-only answer, a stance-review lead). Deactivated, not deleted.')
  FROM _pair pr
 WHERE d.id = pr.dup AND (d.is_active OR d.is_incumbent);

-- ─── B. Former Santa Monica councilmembers ────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET is_incumbent = false,
       notes = COALESCE(p.notes, ARRAY[]::text[]) || ('CA_0180 (2026-09-23): former Santa Monica City Council member; '
               || 'left 2024-12-10 when Hall, Raskin, Snell and Zernitskaya were installed (City of Santa Monica press '
               || 'release 2024-12-11). Holds no seat, so is_incumbent cleared; kept active (CA_0156 convention).')::text
  FROM _sm s WHERE p.id = s.id AND p.is_incumbent;

-- ─── C. Hidden Hills name ─────────────────────────────────────────────────────────────────────
UPDATE essentials.politicians p
   SET full_name = 'Laura McCorkindale', first_name = 'Laura', last_name = 'McCorkindale',
       notes = COALESCE(p.notes, ARRAY[]::text[]) || ('CA_0180 (2026-09-23): name was the scrape artefact "Laura '
               || 'McCorkindale and Adam"; hiddenhills.gov/city-council lists Council Member Laura McCorkindale and no '
               || 'member named Adam.')::text
 WHERE p.id = '12eebc77-777c-42fb-aad8-1080cd2bedbf' AND p.full_name = 'Laura McCorkindale and Adam'
   AND NOT p.full_name_manual_override;

-- ─── D. Dispute the 8 links the new facts place elsewhere ──────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = CASE WHEN ps.notes IS JSON OBJECT
                    THEN (ps.notes::jsonb || jsonb_build_object('disputed_by', 'CA_0180 (2026-09-23)', 'disputed_reason', x.reason))::text
                    ELSE ps.notes || ' | DISPUTED by CA_0180 (2026-09-23): ' || x.reason END,
       updated_at = now()
  FROM _dis x WHERE ps.id = x.id AND ps.research_status = 'needs_research';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_amt numeric;
BEGIN
  -- A. all 32 links are on the seated rows (9 Menjivar, 23 Strickland); the dups hold none
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '4baa73c2-d38b-4d07-894f-1577d5ba43a3';
  IF v_n <> 9 THEN RAISE EXCEPTION 'POST: seated Menjivar row has % links, expected 9', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id = '863ef272-ea35-482b-aee2-447c06bd469d';
  IF v_n <> 23 THEN RAISE EXCEPTION 'POST: seated Strickland row has % links, expected 23', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources WHERE essentials_politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % links still on the dup rows', v_n; END IF;
  -- Strickland's money now sits on the seated row, unchanged
  SELECT COALESCE(sum(a.total_amount), 0) INTO v_amt FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
   WHERE ps.essentials_politician_id = '863ef272-ea35-482b-aee2-447c06bd469d' AND ps.research_status = 'confirmed';
  IF v_amt <> 198403.00 THEN RAISE EXCEPTION 'POST: confirmed money on seated Strickland row is %, expected 198403.00', v_amt; END IF;

  SELECT count(*) INTO v_n FROM essentials.identifiers WHERE politician_id IN (SELECT keep FROM _pair);
  IF v_n <> 13 THEN RAISE EXCEPTION 'POST: % identifiers on the seated rows, expected 13', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.addresses WHERE politician_id IN (SELECT keep FROM _pair);
  IF v_n <> 4 THEN RAISE EXCEPTION 'POST: % addresses on the seated rows, expected 4', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians k JOIN _pair pr ON pr.keep = k.id
   WHERE cardinality(k.urls) > 0 AND k.photo_origin_url IS NOT NULL AND k.is_active AND k.is_incumbent;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 seated rows carry urls + photo_origin_url and stay active incumbents', v_n; END IF;

  -- the dups are deactivated with the note; their answers and context are still there (nothing deleted)
  SELECT count(*) INTO v_n FROM essentials.politicians d JOIN _pair pr ON pr.dup = d.id
   WHERE NOT d.is_active AND NOT d.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(d.notes) n WHERE n LIKE 'CA_0180 (2026-09-23): DUPLICATE of%');
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 dups deactivated with the note', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers WHERE politician_id IN (SELECT dup FROM _pair);
  IF v_n <> 14 THEN RAISE EXCEPTION 'POST: % answers left on the dups, expected 14 (untouched)', v_n; END IF;

  -- both Senate seats are still held by the seated rows
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och JOIN _pair pr ON pr.office = och.office_id AND pr.keep = och.politician_id;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 Senate seats still held by the seated rows', v_n; END IF;

  -- B. the three Santa Monica rows: active, not incumbent, noted
  SELECT count(*) INTO v_n FROM essentials.politicians p JOIN _sm s ON s.id = p.id
   WHERE p.is_active AND NOT p.is_incumbent
     AND EXISTS (SELECT 1 FROM unnest(p.notes) n WHERE n LIKE 'CA_0180 (2026-09-23): former Santa Monica%');
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 Santa Monica rows cleared', v_n; END IF;

  -- C. the Hidden Hills name, still on its seat
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id AND och.office_id = '202dae43-8243-46ea-b1fa-3746ef6a1c9b'
   WHERE p.id = '12eebc77-777c-42fb-aad8-1080cd2bedbf' AND p.full_name = 'Laura McCorkindale'
     AND p.first_name = 'Laura' AND p.last_name = 'McCorkindale';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: the Hidden Hills row is not renamed on its seat'; END IF;

  -- D. the 8 disputes, each with its reason; nothing else carries the marker
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _dis x ON x.id = ps.id
   WHERE ps.research_status = 'disputed'
     AND ((ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'disputed_reason' = x.reason)
          OR right(ps.notes, length(' | DISPUTED by CA_0180 (2026-09-23): ' || x.reason)) = ' | DISPUTED by CA_0180 (2026-09-23): ' || x.reason);
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: % of 8 links disputed with their reason', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE strpos(ps.notes, 'CA_0180 (2026-09-23)') > 0;
  IF v_n <> 8 THEN RAISE EXCEPTION 'POST: % links carry the CA_0180 marker, expected 8 (the moved links are not re-noted)', v_n; END IF;

  -- no money moved in total
  SELECT b.confirmed_total - (SELECT COALESCE(sum(a.total_amount), 0) FROM transparent_motivations.contribution_summary_agg a
                               JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
                              WHERE ps.research_status = 'confirmed')
    INTO v_amt FROM _before b;
  IF v_amt <> 0 THEN RAISE EXCEPTION 'POST: the confirmed total moved by %, expected 0', v_amt; END IF;

  RAISE NOTICE 'CA_0180 applied: 2 senator duplicates merged (32 links, 13 identifiers, 4 addresses), 3 Santa Monica rows cleared, Hidden Hills name fixed, 8 links disputed';
END $$;

COMMIT;
