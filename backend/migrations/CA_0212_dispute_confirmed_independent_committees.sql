-- CA_0212_dispute_confirmed_independent_committees.sql
-- Dispute 11 cal_access links on ACTIVE rows that were already CONFIRMED before 2026-09-23 but are independent
-- committees: the Secretary of State lists each as PRIMARILY FORMED CANDIDATE (FILER_TO_FILER_TYPE_CD SUB_CATEGORY 40102),
-- a committee that supports or opposes the candidate without the candidate's control. Stored as the person's own
-- candidate_committee, their receipts showed as the person's fundraising -- including a committee to RECALL the person.
--
-- FOUND BY a check of all 173 older confirmed cal_access links on active rows against the Cal-Access bulk export
-- (https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip, 2026-09-23; downloaded with operator permission, not
-- committed) -- the same method as CA_0192 and CA_0207, which reviewed only needs_research links. These 11 came from
-- confirm-cal-access.ts and the seed-la-metro / seed-la-county-officials discovery seeders (deleted in #677 / #678),
-- which linked by name; a later check against the candidate's name passes an independent committee, because it names
-- its candidate too.
--   Gavin Newsom      NEWSOM; RAN ACTION FUND COMMITTEE TO RECALL GAVIN                      $33,173 displayed
--   Mike A. Gipson    GIPSON FOR ASSEMBLY 2022; CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE   $194,000 displayed
--   Kathryn Barger x2, Holly J. Mitchell x2, Rex Richardson x2, Jennifer Perez, Dr. Monica Sanchez (a slate committee),
--   Jeff Prang ("... (INDEPENDENT EXPENDITURE) ...")                                       $0 each today; the daily
--   cal-access job (16:00 UTC) would load their receipts as the person's own.
-- THE REST OF THE 173 STAY CONFIRMED: 51 controlled by the person with SOS reports; 104 controlled local committees with
-- no SOS reports (they load nothing and, since #681, show no false 'data pending'); 1 with no SOS reports; and 6 of
-- Jose Luis Solache Jr's own committees (the matcher first read his "Jr" as part of the surname -- reviewed by hand:
-- Assembly D62 / Senate D33 / Lynwood city council, all his).
--
-- WHY 'disputed': the admin API's own value for a wrong link, as in CA_0166 - CA_0207. Every read path and the
-- ingestion scheduler require research_status = 'confirmed', so the receipts stop showing as the person's fundraising
-- and are not reloaded. Nothing is deleted: the contribution rows stay, attached to the link, as the record.
-- NOTES: all 11 are plain JSON objects and get disputed_by / disputed_reason keys (IS JSON OBJECT branch, as in CA_0178).
-- politician_sources is public-read: the reason carries no phone number.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run x2 with a snapshot and a planted
--   control (tripped) right before the apply; re-run after it changed nothing. Verified after: 11 disputed; confirmed
--   totals Newsom $23,041,827 -> $23,008,654 and Gipson $2,451,052 -> $2,257,052 (the live API no longer lists
--   Gipson's 2022 cycle, whose only data was the PAC). All 173 links and their outcome are in
--   data/roster-audits/2026-09-24-older-confirmed-committee-links-CA_0212.csv.
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'confirmed', notes = (notes::jsonb - 'disputed_by' - 'disputed_reason')::text
--    WHERE research_status = 'disputed' AND notes IS JSON OBJECT AND notes::jsonb ->> 'disputed_by' = 'CA_0212 (2026-09-24)';
-- IDEMPOTENT: the update is guarded on research_status = 'confirmed'; a re-run changes nothing and every gate passes.

BEGIN;

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, politician_id uuid, external_id text, committee text) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('03741251-e6db-4f04-8fea-75fd3620a86f','b81d5aad-1765-47b5-88c8-fbe15cd8af9a','1433924','SANCHEZ, LUIS ALVARADO, ERIK LUTZ FOR CITY COUNCIL 2020; STRONG CITIES PAC TO SUPPORT MONICA'),
  ('ffe32d48-3903-4377-a456-f3daac53370a','f26309c8-2525-49b2-bdaf-62980cbb1853','1418587','NEWSOM; RAN ACTION FUND COMMITTEE TO RECALL GAVIN'),
  ('69658a9e-d85e-4be6-a4c6-fb2af585acd9','fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50','1421304','MITCHELL FOR COUNTY SUPERVISOR 2020, SPONSORED BY LA VOICE ACTION; WORKING FAMILIES FOR HOLLY'),
  ('b35cfc8b-1701-4df4-bc9b-8dd8935ac1b4','fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50','1424932','MITCHELL FOR LA SUPERVISOR 2020; COMMUNITIES UNITED FOR HOLLY'),
  ('7098fe98-de56-43c8-b4bc-337d97900e32','85233a92-ce12-4567-910e-be1776cd4aac','1366093','PRANG FOR L.A. COUNTY ASSESSOR 2014 (INDEPENDENT EXPENDITURE), FRIENDS OF JEFF'),
  ('5314c1cf-711f-4162-954f-591f6ea372a0','3ed36508-9ae9-41af-aaba-e5e39bb87aa7','1454775','PEREZ FOR NORWALK CITY COUNCIL 2022; COMMITTEE FOR A STRONG NORWALK: SUPPORTING JENNIFER'),
  ('f2181c17-b063-4e24-90f7-91d99de24ef4','122f1897-2dae-4f21-bee0-1c02c95e9e3a','1466175','BARGER FOR SUPERVISOR 2024 SPONSORED BY CARPENTERS UNIONS; BUILDING A BETTER FUTURE, SUPPORTING KATHRYN'),
  ('5cf16f26-902f-4dc6-bd01-bd61912c44be','122f1897-2dae-4f21-bee0-1c02c95e9e3a','1462438','BARGER FOR SUPERVISOR 2024 SPONSORED BY LABOR ORGANIZATIONS; WORKING FAMILIES AND FIRST RESPONDERS FOR KATHRYN'),
  ('d40629eb-00b9-406d-b4d5-08752a9bea20','6133e73c-4c33-4cfc-9fd3-de1382729f42','1448127','GIPSON FOR ASSEMBLY 2022; CALIFORNIANS FOR SOLUTIONS SUPPORTING MIKE'),
  ('a5542937-a5bb-44a0-9b78-e1c8e0f3c445','4c9d7584-4e07-46f7-8f8c-770afc8dce94','1447859','RICHARDSON FOR LONG BEACH MAYOR 2022; LONG BEACH BUSINESS ALLIANCE IN SUPPORT OF REX'),
  ('06c18a17-6348-4d78-ab6e-2e6f732fe987','4c9d7584-4e07-46f7-8f8c-770afc8dce94','1446966','RICHARDSON FOR MAYOR, KERR, RICKS-ODDIE AND CARUSO FOR CITY COUNCIL 2022, SPONSORED BY THE LOS ANGELES COUNTY FEDERATION OF LABOR, AFL-CIO; WORKING FAMILIES AND COMMUNITIES IN SUPPORT OF REX');

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
  IF v_n <> 11 OR v_md5 <> 'fd36e7f70cddfb7e8624e6115a430401' THEN RAISE EXCEPTION 'PRE: _link is not the reviewed 11 (% / %)', v_n, v_md5; END IF;

  -- each is the recorded (row, committee id, stored committee name), cal_access candidate_committee on an ACTIVE row,
  -- confirmed -- or already disputed by an earlier run of this file
  SELECT count(*) INTO v_n FROM _link l
    JOIN transparent_motivations.politician_sources ps ON ps.id = l.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.essentials_politician_id = l.politician_id AND ps.source_system = 'cal_access'
     AND ps.external_id = l.external_id AND ps.source_type = 'candidate_committee'
     AND ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'committee_name' = l.committee
     AND (ps.research_status = 'confirmed'
          OR (ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0212 (2026-09-24)'))
     AND p.is_active;
  IF v_n <> 11 THEN RAISE EXCEPTION 'PRE: % of 11 links match their reviewed record on an active row', v_n; END IF;
END $$;

-- ─── Dispute the 11 ──────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = (ps.notes::jsonb || jsonb_build_object('disputed_by', 'CA_0212 (2026-09-24)', 'disputed_reason', 'Cal-Access bulk export (2026-09-23): category PRIMARILY FORMED CANDIDATE -- an independent committee that supports or opposes this person, not a committee they control; its receipts are not their fundraising.'))::text,
       updated_at = now()
  FROM _link l
 WHERE ps.id = l.id AND ps.research_status = 'confirmed';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id
   WHERE ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0212 (2026-09-24)'
     AND ps.notes::jsonb ->> 'disputed_reason' = 'Cal-Access bulk export (2026-09-23): category PRIMARILY FORMED CANDIDATE -- an independent committee that supports or opposes this person, not a committee they control; its receipts are not their fundraising.';
  IF v_n <> 11 THEN RAISE EXCEPTION 'POST: % of 11 links disputed with the reason', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0212 (2026-09-24)' AND NOT EXISTS (SELECT 1 FROM _link l WHERE l.id = ps.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % link(s) outside _link carry the CA_0212 (2026-09-24) marker', v_n; END IF;

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

  RAISE NOTICE 'CA_0212 applied: 11 independent committees disputed (were confirmed)';
END $$;

COMMIT;
