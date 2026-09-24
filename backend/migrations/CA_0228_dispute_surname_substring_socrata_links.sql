-- CA_0228_dispute_surname_substring_socrata_links.sql
-- Dispute 33 CONFIRMED la_socrata links on 13 active politicians. None of the committees is the linked person's.
-- audit-socrata-committees.ts linked an LA City committee to a politician when the committee name CONTAINED the
-- politician's normalized surname as a substring; confirm-la-socrata.ts then AUTO-CONFIRMED any link whose committee
-- name contained the surname and whose cmt_type was 'C'. Neither step compared the committee's candidate (cand_name)
-- with the person. So "Ma" matched "Mack", "Matt", "Marisa", "Hellman"; "Fu" matched "Furutani"; "Ser" matched
-- "Serrano" and "Serena"; and a whole-word surname still matched a different person with that surname.
--
--   Francis De Leon Sanchez  10 links  3,043 rows  $2,292,079   Bell Gardens council member. Kevin de Leon 2020 + 2024
--                                                                (LA CD14), Ruby De Vera, Leonard Delpit, Ana Grande,
--                                                                Nelson Grande, Frederick Sutton, Richard Valdez, the AFT
--                                                                Solidarity Committee, and the Mexican & Asian American
--                                                                Leadership PAC (primarily formed for Kevin de Leon).
--   Gail Ruderman Feuer       1 link   2,183 rows  $1,301,922   2nd DCA justice. Mike Feuer for City Attorney 2013.
--   Fiona Ma                  9 links  1,701 rows  $1,216,907   State Treasurer. Mack, Szabo, Alcaraz x2, Hellman, Manley,
--                                                                Jumaane, Mavar, Manuel (LA City Council candidates).
--   David Fu                  1 link     937 rows    $419,306   Arcadia council. Warren Furutani (LA CD15, 2011).
--   Susan Ser                 3 links    595 rows    $348,783   LA Superior Court. Robert Serrano x2, Serena Oberstein.
--   Tim McOsker               1 link     426 rows    $268,594   LA CD15. Pat McOsker for City Council 2011 (a different
--                                                                candidate; Tim McOsker's own 2022 link stays confirmed).
--   Lee W. Tsao               1 link     298 rows    $223,089   LA Superior Court. Nick Patsaouras (Controller, 2009).
--   Victor M. Gordo           1 link     216 rows    $155,282   Pasadena mayor. Gordon Teuber (LA CD15, 2011).
--   Tim Sandoval              1 link     165 rows     $71,467   Pomona mayor. Danielle Sandoval (LA CD15, 2022).
--   Bruce Silverstein         2 links     91 rows     $22,483   Malibu council. Scott Silverstein (LA CD3, 2013 + 2022).
--   Robert Gin                1 link      86 rows     $14,039   Alhambra USD board. John Higginson (LA CD7, 2017).
--   Vincent Yu                1 link       4 rows        $700   Temple City council. Yuval Kremer (LA CD5, 2013).
--   Kelli M. Evans            1 link       2 rows          $0   CA Supreme Court. Mervin Evans for Mayor 2009.
--   TOTAL                    33 links  9,747 rows  $6,334,649 displayed as these people's fundraising / outside money.
--
-- FOUND BY a review of ALL 35 confirmed la_socrata links whose notes say linked_by audit-socrata-committees.ts (41
-- links in all; the other 6 were already disputed or not_applicable, incl. Elaine Lu's two, CA_0225). A whole-word
-- test (lower(cmt_nm) ~ '\m'||surname||'\M') splits them 27 substring / 8 whole-word -- but 6 of the 8 whole-word
-- matches are also wrong (Silverstein x2, Feuer, Evans, Pat McOsker, Sandoval), so the review read every row.
-- EVIDENCE (LA City Ethics open data, data.lacity.org, read 2026-09-24): m6g2-gc6c (contributions) gives cand_name and
-- seat_desc for every one of the 35 cmt_ids; br3a-db9a (statements) gives 1413452 as General Purpose and 1474094 as
-- Primarily Formed; 5mrt-4zhe (expenditures, local ids 22527 / 24936) shows AFT's gifts going to Karen Bass for Mayor
-- 2022, Malia Cohen for Controller and LAUSD board candidates, never a Bell Gardens race. Each person's seat is from
-- essentials.office_current_holder. Every row's reason is in its disputed_reason below.
-- THE OTHER 2 STAY CONFIRMED: Heather Hutt for City Council 2024 (cand_name "Hutt, Heather", CD10 -- her seat) and Tim
--   McOsker for City Council 2022 ("McOsker, Tim", CD15). The post-verify gate asserts both.
-- Francis De Leon Sanchez: the surname the script matched at link time is not recorded (none of the 10 names contains
--   "sanchez"); the name was different then. The person is NOT Kevin de Leon: the seat is Bell Gardens City Council.
-- ALSO CHECKED, NOT CHANGED: the 91 other confirmed la_socrata links (seed-la-city-confirmed.ts, relink-socrata-skipped.ts,
--   hand seeds) against m6g2-gc6c cand_name. All match their person, except for two reading artefacts: "Curren D. Price
--   Jr." (surname parsed as "Jr.") and 1442937 "Traci Park for Safe Council District 11 2022", a PRIMARILY FORMED
--   committee with no cand_name, stored as candidate_committee. That one is the CA_0212 class (independent committee
--   read as own money), not the substring defect, and is left for a separate check.
--
-- WHY 'disputed', NOT re-pointed or deleted: the admin API's value for a wrong link, as in CA_0166 - CA_0225. Every read
-- path and the ingestion scheduler require research_status = 'confirmed', so the money leaves these people's finance
-- sections and is not reloaded. The contribution rows stay, attached to the link, as the record. None of the committees'
-- candidates is re-pointed: Kevin de Leon, Mike Feuer and the others are not the Essentials rows these links are on.
-- A disputed row also keeps the cmt_id "already linked", so the audit script cannot re-create it.
-- AFTER THIS, 9 of the 13 have no confirmed finance link (Fiona Ma keeps 9 cal_access links; McOsker 3, Gordo 2, Gin 1),
-- and detectCoverageStatus reports no_data for them -- correct: none files with LA City Ethics.
-- NOTES: all 33 are plain JSON objects and get disputed_by / disputed_reason keys (as in CA_0212, CA_0225).
-- politician_sources is public-read: the reasons carry no phone number.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: NOT APPLIED -- awaiting operator approval. Dry run against prod 2026-09-24 (BEGIN ... ROLLBACK, body run twice):
--   run 1 disputed 33 and passed every gate; run 2 updated 0 and passed every gate; a snapshot of all 256 la_socrata
--   rows matched before and after, so the rollback reverted. Planted control (one committee name altered) tripped the
--   pre-flight (32 of 33). All 35 reviewed links and their outcome are in
--   data/roster-audits/2026-09-24-socrata-surname-substring-links-CA_0228.csv.
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'confirmed', notes = (notes::jsonb - 'disputed_by' - 'disputed_reason')::text
--    WHERE research_status = 'disputed' AND notes IS JSON OBJECT AND notes::jsonb ->> 'disputed_by' = 'CA_0228 (2026-09-24)';
-- IDEMPOTENT: the update is guarded on research_status = 'confirmed'; a re-run changes nothing and every gate passes.

BEGIN;

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, politician_id uuid, external_id text, source_type text, committee text, reason text) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('86f85b35-a916-47e0-9ceb-452483c6c705','7922b910-9586-4ced-8f71-3daa9f2595c3','1348687','candidate_committee','Scott Silverstein for City Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Scott Silverstein, a 2013 LA City Council District 3 candidate; Bruce Silverstein is a Malibu council member. Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('9dac1cdf-f877-4a43-97cc-34f74bc1bf87','7922b910-9586-4ced-8f71-3daa9f2595c3','1442077','candidate_committee','Scott Silverstein for City Council 2022',
   'LA City Ethics open data (2026-09-24): the committee of Scott Silverstein, a 2022 LA City Council District 3 candidate; Bruce Silverstein is a Malibu council member. Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('43ab3d44-d997-4edb-b351-5db6792c8a4f','fb1f120a-8821-4649-a209-03b6b77e0105','1340011','candidate_committee','Furutani for City Council 2011',
   'LA City Ethics open data (2026-09-24): the committee of Warren Furutani, a 2011 LA City Council District 15 candidate; David Fu is an Arcadia council member. Linked by audit-socrata-committees.ts because the surname "Fu" is a substring of "Furutani".'),
  ('1902e017-43fc-4b6a-8d20-8b6402db3efc','41ef8aaa-b604-4725-b46d-dab1656cc198','1292748','candidate_committee','Manley 4 Councilman Campaign',
   'LA City Ethics open data (2026-09-24): the committee of Mike Manley, a 2007 LA City Council District 10 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Manley".'),
  ('4632a1fe-29e3-4d13-9a14-ff32659897bc','41ef8aaa-b604-4725-b46d-dab1656cc198','1333054','candidate_committee','Jabari S. Jumaane for City Council 2011',
   'LA City Ethics open data (2026-09-24): the committee of Jabari Jumaane, a 2011 LA City Council District 8 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Jumaane".'),
  ('bc83c8bb-d0b6-44d7-9a0e-cbf6b85b2c34','41ef8aaa-b604-4725-b46d-dab1656cc198','1340357','candidate_committee','John Mavar for City Council 2011',
   'LA City Ethics open data (2026-09-24): the committee of John Mavar, a 2011 LA City Council District 15 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Mavar".'),
  ('6280a391-95e6-4c14-8722-ed0a3e5035db','41ef8aaa-b604-4725-b46d-dab1656cc198','1346350','candidate_committee','Emile Mack for City Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Emile Mack, a 2013 LA City Council District 13 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Mack".'),
  ('e4b34f69-656e-447a-9a13-a3c55f97bbed','41ef8aaa-b604-4725-b46d-dab1656cc198','1348750','candidate_committee','Matt Szabo for City Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Matt Szabo, a 2013 LA City Council District 13 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Matt".'),
  ('3676d6b7-6f91-4a9f-8ad7-6b2505cd96cd','41ef8aaa-b604-4725-b46d-dab1656cc198','1437338','candidate_committee','Hellman for City Council 2022',
   'LA City Ethics open data (2026-09-24): the committee of Mary Hellman, a 2022 LA City Council District 13 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Hellman".'),
  ('5697874a-6042-4785-87d7-83f6ece9b84a','41ef8aaa-b604-4725-b46d-dab1656cc198','1445187','candidate_committee','Manuel for City Council 2022',
   'LA City Ethics open data (2026-09-24): the committee of Chad Manuel, a 2022 LA City Council District 13 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Manuel".'),
  ('8d018a77-33ac-40c4-9797-f02c9e3360c5','41ef8aaa-b604-4725-b46d-dab1656cc198','1457146','candidate_committee','Marisa Alcaraz for City Council 2023',
   'LA City Ethics open data (2026-09-24): the committee of Marisa Alcaraz, a 2023 LA City Council District 6 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Marisa".'),
  ('4ba8040b-79f3-4f26-8c4c-706fab6f558f','41ef8aaa-b604-4725-b46d-dab1656cc198','1459819','candidate_committee','Marisa Alcaraz for City Council 2023 General',
   'LA City Ethics open data (2026-09-24): the committee of Marisa Alcaraz, a 2023 LA City Council District 6 candidate; Fiona Ma is the California State Treasurer. Linked by audit-socrata-committees.ts because the surname "Ma" is a substring of "Marisa".'),
  ('b92aad64-9689-4e9b-a8fd-75fa5592eebf','e086df00-1e48-4882-9594-82f4e9ee273c','1281290','candidate_committee','De Vera for City Council',
   'LA City Ethics open data (2026-09-24): the committee of Ruby De Vera, a 2005 LA City Council District 14 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('01e6c1f5-6755-48ae-8022-d44f1b14c601','e086df00-1e48-4882-9594-82f4e9ee273c','1349181','candidate_committee','Ana Grande for City Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Ana Grande, a 2013 LA City Council District 13 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('5fb4cec1-7e55-4122-abd9-e351f670808a','e086df00-1e48-4882-9594-82f4e9ee273c','1353001','candidate_committee','Committee to Elect Frederick Sutton to City Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Frederick Sutton, a 2013 LA City Council District 11 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('42b47fc4-e99e-4047-a995-656036354324','e086df00-1e48-4882-9594-82f4e9ee273c','1355801','candidate_committee','Richard Valdez for Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Richard Valdez, a 2013 LA City Council District 6 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('c042ce29-91e4-4773-9b18-f54d6d5f4d01','e086df00-1e48-4882-9594-82f4e9ee273c','1362709','candidate_committee','Delpit for City Council 2015',
   'LA City Ethics open data (2026-09-24): the committee of Leonard Delpit, a 2015 LA City Council District 8 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('fc203862-8ff8-46dc-826f-66b5cf02c8a4','e086df00-1e48-4882-9594-82f4e9ee273c','1413452','ie_committee','American Federation of Teachers Solidarity Committee',
   'LA City Ethics open data (2026-09-24): a general purpose committee (American Federation of Teachers); its expenditures (local id 22527) fund Karen Bass for LA Mayor 2022, Malia Cohen for Controller and LAUSD board candidates, never a Bell Gardens race; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('4ab0e68d-59c4-4af6-a8c4-246caaa0bf81','e086df00-1e48-4882-9594-82f4e9ee273c','1415916','candidate_committee','Kevin de Leon for City Council 2020',
   'LA City Ethics open data (2026-09-24): the committee of Kevin de Leon, a 2020 LA City Council District 14 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('ce681431-a55e-4a85-8905-8f2aef7a572a','e086df00-1e48-4882-9594-82f4e9ee273c','1463138','candidate_committee','Kevin de Leon for City Council 2024',
   'LA City Ethics open data (2026-09-24): the committee of Kevin de Leon, a 2024 LA City Council District 14 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('40aafa3a-c1ce-47ad-a9ff-7b00cc72c916','e086df00-1e48-4882-9594-82f4e9ee273c','1474094','ie_committee','The Mexican & Asian American Leadership PAC To Support De Leon for City Council 2024',
   'LA City Ethics open data (2026-09-24): a committee primarily formed to support Kevin de Leon for LA City Council District 14 in 2024; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('bf61d191-24ff-4f6a-95f5-10f232f5802f','e086df00-1e48-4882-9594-82f4e9ee273c','1483817','candidate_committee','GRANDE FOR CITY COUNCIL 2026',
   'LA City Ethics open data (2026-09-24): the committee of Nelson Grande, a 2026 LA City Council District 1 candidate; Francis De Leon Sanchez is a Bell Gardens council member. Linked by audit-socrata-committees.ts by a surname substring match (the name it matched then is not recorded); no LA City race is in Bell Gardens.'),
  ('c6457b68-5a63-40c0-bf5b-5790128cb2be','49492962-6351-400a-9ea2-53a8f045d77b','1341335','candidate_committee','Mike Feuer for City Attorney 2013',
   'LA City Ethics open data (2026-09-24): the committee of Michael Feuer, a 2013 LA City Attorney candidate; Gail Ruderman Feuer is a 2nd District Court of Appeal justice. Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('6a9b10de-4d27-4d0a-84cb-bc0c03264656','c2fa1611-f593-4be0-84dd-1c0e3754cef4','1307513','candidate_committee','Evans 2009 Community People',
   'LA City Ethics open data (2026-09-24): the committee of Mervin Evans, a 2009 LA City Mayor candidate; Kelli M. Evans is a California Supreme Court justice. Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('32cf2ea4-fe14-49b5-af19-4477e8dedd9b','0c4c3fd1-2298-4915-b2de-e12a2e50989c','1313452','candidate_committee','Nick Patsaouras ''09',
   'LA City Ethics open data (2026-09-24): the committee of Nick Patsaouras, a 2009 LA City Controller candidate; Lee W. Tsao is an LA County Superior Court judge. Linked by audit-socrata-committees.ts because the surname "Tsao" is a substring of "Patsaouras".'),
  ('3b11524f-a39f-429e-9bd9-3f87af172d91','f2a863a9-ce21-453a-9d2b-fc7282307eb0','1384070','candidate_committee','Johnny Higginson for City Council 2017',
   'LA City Ethics open data (2026-09-24): the committee of John Higginson, a 2017 LA City Council District 7 candidate; Robert Gin is an Alhambra Unified board member. Linked by audit-socrata-committees.ts because the surname "Gin" is a substring of "Higginson".'),
  ('1fa4ceac-43e3-4e8d-9d06-635922083509','f0db9057-2ad9-411b-8673-764123fa5466','1278506','candidate_committee','Serrano for City Council District 10',
   'LA City Ethics open data (2026-09-24): the committee of Robert Serrano, a 2005 LA City Council District 10 candidate; Susan Ser is an LA County Superior Court judge. Linked by audit-socrata-committees.ts because the surname "Ser" is a substring of "Serrano".'),
  ('08c174fc-eff1-4ec4-9695-189df440d80b','f0db9057-2ad9-411b-8673-764123fa5466','1293077','candidate_committee','Serrano for City Council',
   'LA City Ethics open data (2026-09-24): the committee of Robert Serrano, a 2007 LA City Council District 10 candidate; Susan Ser is an LA County Superior Court judge. Linked by audit-socrata-committees.ts because the surname "Ser" is a substring of "Serrano".'),
  ('8cd23ec4-db2c-4930-a772-509ec69d40fb','f0db9057-2ad9-411b-8673-764123fa5466','1463856','candidate_committee','Serena Oberstein for L.A. City Council 2024',
   'LA City Ethics open data (2026-09-24): the committee of Serena Oberstein, a 2024 LA City Council District 12 candidate; Susan Ser is an LA County Superior Court judge. Linked by audit-socrata-committees.ts because the surname "Ser" is a substring of "Serena".'),
  ('5ba1e87d-c826-4cae-a2ed-be7a7e030974','5cf02835-9024-4a00-80f7-bc2dcc3165df','1339987','candidate_committee','Pat McOsker for City Council 2011',
   'LA City Ethics open data (2026-09-24): the committee of Pat McOsker, a 2011 LA City Council District 15 candidate; Tim McOsker holds LA City Council District 15 (the Tim McOsker for City Council 2022 link stays confirmed). Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('6f8a37d1-0ca8-4e96-a901-09520b83f8cb','48f36a82-cb26-4701-ba08-5566533982cb','1438309','candidate_committee','Danielle Sandoval for City Council 2022',
   'LA City Ethics open data (2026-09-24): the committee of Danielle Sandoval, a 2022 LA City Council District 15 candidate; Tim Sandoval is the Mayor of Pomona. Linked by audit-socrata-committees.ts because the surname matches: a different person.'),
  ('701d0ec3-f349-4c42-81f1-11fd7d8880f2','447ef220-cb9e-4ade-aba8-9dea87ed9931','1340232','candidate_committee','Gordon Teuber for Council 2011',
   'LA City Ethics open data (2026-09-24): the committee of Gordon Teuber, a 2011 LA City Council District 15 candidate; Victor M. Gordo is the Mayor of Pasadena. Linked by audit-socrata-committees.ts because the surname "Gordo" is a substring of "Gordon".'),
  ('3a78e830-889a-458d-80a9-4b5cc6abf8ee','4bc0840f-a922-4d10-88ee-ef0f6c883af5','1353382','candidate_committee','Yuval Kremer for Council 2013',
   'LA City Ethics open data (2026-09-24): the committee of Yuval Kremer, a 2013 LA City Council District 5 candidate; Vincent Yu is a Temple City council member. Linked by audit-socrata-committees.ts because the surname "Yu" is a substring of "Yuval".');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
         WHERE p.is_active AND ps.research_status = 'confirmed') AS active_confirmed,
       (SELECT count(*) FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
         WHERE p.is_active AND ps.research_status = 'disputed') AS active_disputed,
       (SELECT count(*) FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id WHERE ps.research_status = 'confirmed') AS to_dispute,
       (SELECT sum((SELECT count(*) FROM transparent_motivations.contributions c WHERE c.politician_source_id = l.id)) FROM _link l) AS contributions;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_md5 text;
BEGIN
  SELECT count(*), md5(string_agg(id::text, ',' ORDER BY id)) INTO v_n, v_md5 FROM _link;
  IF v_n <> 33 OR v_md5 <> '897430131713a36ac28f650a621c8042' THEN RAISE EXCEPTION 'PRE: _link is not the reviewed 33 (% / %)', v_n, v_md5; END IF;

  -- each is the recorded (row, person, committee id, type, stored committee name), la_socrata, made by the audit script,
  -- on an active row, confirmed -- or already disputed by an earlier run of this file
  SELECT count(*) INTO v_n FROM _link l
    JOIN transparent_motivations.politician_sources ps ON ps.id = l.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.essentials_politician_id = l.politician_id AND p.is_active
     AND ps.source_system = 'la_socrata' AND ps.external_id = l.external_id AND ps.source_type = l.source_type
     AND ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'cmt_nm' = l.committee
     AND ps.notes::jsonb ->> 'linked_by' = 'audit-socrata-committees.ts'
     AND (ps.research_status = 'confirmed'
          OR (ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0228 (2026-09-24)'));
  IF v_n <> 33 THEN RAISE EXCEPTION 'PRE: % of 33 links match their reviewed record', v_n; END IF;

  -- each person still holds the seat the reason names (13 people, one current seat each)
  SELECT count(DISTINCT l.politician_id) INTO v_n FROM _link l
    JOIN essentials.office_current_holder och ON och.politician_id = l.politician_id;
  IF v_n <> 13 THEN RAISE EXCEPTION 'PRE: % of 13 people hold a current seat', v_n; END IF;
END $$;

-- ─── Dispute the 33 ──────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = (ps.notes::jsonb || jsonb_build_object('disputed_by', 'CA_0228 (2026-09-24)', 'disputed_reason', l.reason))::text,
       updated_at = now()
  FROM _link l
 WHERE ps.id = l.id AND ps.research_status = 'confirmed';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id
   WHERE ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0228 (2026-09-24)'
     AND ps.notes::jsonb ->> 'disputed_reason' = l.reason AND ps.notes::jsonb ->> 'cmt_nm' = l.committee;
  IF v_n <> 33 THEN RAISE EXCEPTION 'POST: % of 33 links disputed with the reason', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0228 (2026-09-24)' AND NOT EXISTS (SELECT 1 FROM _link l WHERE l.id = ps.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % link(s) outside _link carry the CA_0228 (2026-09-24) marker', v_n; END IF;

  -- the audit script's confirmed links are down to the 2 reviewed as correct: Heather Hutt 2024 and Tim McOsker 2022
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system = 'la_socrata' AND ps.research_status = 'confirmed'
     AND ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'linked_by' = 'audit-socrata-committees.ts';
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % confirmed audit-socrata-committees.ts links remain, expected 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE research_status = 'confirmed'
     AND (   (id = '98b8fc13-eada-4bfe-8d83-6fb0edff6316' AND essentials_politician_id = '29a8c85b-2572-463c-8034-8986615d7717' AND external_id = '1458184')
          OR (id = 'da8c80e6-9bc5-41fb-9e8c-c7db049b5920' AND essentials_politician_id = '5cf02835-9024-4a00-80f7-bc2dcc3165df' AND external_id = '1437071'));
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of the 2 kept links (Hutt 1458184, McOsker 1437071) are confirmed', v_n; END IF;

  -- exactly the links this run disputed moved from confirmed to disputed on active rows
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE p.is_active AND ps.research_status = 'confirmed';
  IF v_n <> b.active_confirmed - b.to_dispute THEN RAISE EXCEPTION 'POST: confirmed on active rows % -> %, expected -%', b.active_confirmed, v_n, b.to_dispute; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE p.is_active AND ps.research_status = 'disputed';
  IF v_n <> b.active_disputed + b.to_dispute THEN RAISE EXCEPTION 'POST: disputed on active rows % -> %, expected +%', b.active_disputed, v_n, b.to_dispute; END IF;

  -- status only: no contribution row moves or disappears
  SELECT sum((SELECT count(*) FROM transparent_motivations.contributions c WHERE c.politician_source_id = l.id)) INTO v_n FROM _link l;
  IF v_n IS DISTINCT FROM b.contributions THEN RAISE EXCEPTION 'POST: contributions on these links moved % -> %', b.contributions, v_n; END IF;

  RAISE NOTICE 'CA_0228 applied: % of 33 surname-substring la_socrata links disputed (were confirmed)', b.to_dispute;
END $$;

COMMIT;
