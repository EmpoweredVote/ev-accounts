-- CA_0375_netfile_local_committee_ids.sql
-- Point the 15 la_county_netfile links that store a filer id of NetFile's retired REST API at the same committees'
-- NetFile local committee ids, so the adapter can read them from NetFile's Connect2 API.
--
-- FOUND 2026-11-12 (job-health alarm: ev-jobs-la-county-netfile, no proof of run since 2026-10-01). The 2026-11-01
-- run failed all 186 sources: every endpoint of https://netfile.com/api/public/sites/api now answers
-- "401 Unauthorized: A valid session is required." The adapter moves to the Connect2 public API
-- (https://netfile.com/Connect2/api/public), which still answers without a session and serves the same filing and
-- transaction ids (all 17,791 stored rows found there with identical amount, date, donor, employer, occupation).
-- Connect2 identifies a committee by its FPPC id (fppcId) and by NetFile's local committee id (localAgencyId, e.g.
-- "LACO-113718"). 172 links store an FPPC id and need nothing. These 15 store the REST API's 9-digit filer id, which
-- Connect2 does not know (CA_0223 moved McKenzie / Stern to such ids because the REST IdSearch knew neither FPPC id).
--
-- MAPPING (measured 2026-11-12): each link's committee name — read off its stored rows' filerName, or from its notes
-- for the two links with no rows — matched to exactly one entry of Connect2 campaign/list/filer for its agency.
-- Validated: reading each link by the new id returns every one of its stored rows (plus reports filed since 10-01).
--   old id     agency  new id        FPPC      committee                                                       rows
--   212060445  LACO    LACO-113034   1475601   Guzman for High School Board 2024                                  0
--   216784754  LACO    LACO-113716   1442721   LA County: Luna for Sheriff 2022                                1483
--   216784885  LACO    LACO-113718   1479270   LA County: Luna for Sheriff 2026                                1457
--   211581618  LACO    LACO-112624   1458084   Patrice Marshall McKenzie for Board of Education 2026            141
--   185138647  WEHO    WEHO-112647   1423886   John Erickson for WH City Council 2020                           459
--   210075987  WEHO    WEHO-112830   1462391   Re-Elect John Erickson for WH City Council 2024                  299
--   216785710  LACO    LACO-113730   1478761   LA County: Lindsey Horvath for Supervisor 2026                  3557
--   216785660  LACO    LACO-113729   1468607   LA County: Jeffrey Prang For Assessor 2022 - Officeholder Acct  1674
--   216785851  LACO    LACO-113732   1477771   LA County: Jeffrey Prang for Assessor 2026                      1457
--   202019492  WEHO    WEHO-112739   1443689   Chelsea Byers for West Hollywood City Council 2022               230
--   214522097  WEHO    WEHO-112884   1478834   Re-Elect Byers West Hollywood City Council 2026                  234
--   202873881  WEHO    WEHO-112742   1446639   John Heilman for West Hollywood City Council 2022                304
--   204740311  WEHO    WEHO-112760   Pending   Friends of John Heilman ... 2022 (disputed, CA_0224 — stays so)    0
--   212080164  LACO    LACO-113066   1472626   Re-Elect Amanda Stern for School Board 2024                       12
--   216787458  LACO    LACO-113736   1435302   LA County: Supervisor Holly J. Mitchell Officeholder 2020         372
-- The local id, not the FPPC id, because it is always set (Heilman's IE committee's FPPC id reads "Pending") and the
-- adapter takes a committee's rows by it in either case. No other link stores any of these 14 FPPC ids.
--
-- CONTRIBUTIONS: none move. The rows stay on the same politician_sources ids; their keys (<filingId>-<id>) are the
-- same in Connect2, so the next run refreshes them in place.
-- DEPLOY ORDER: either order works — the old adapter cannot read any link today. Apply this, deploy the adapter, then
-- run `la-county-netfile` once. Until both are in, the new adapter fails these 15 sources with a pointer here.
--
-- No migration runner exists; this file records SQL applied by hand (DML, one transaction).
-- STATUS: APPLIED to prod 2026-11-12 ~18:55 UTC after #1404 merged (operator approval: Chris Andrews). Gates passed; after: 15 local ids, 0 nine-digit ids, 187 links, contributions unchanged (17,791).
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources ps
--      SET external_id = split_part(split_part(ps.notes, ' — external_id was ', 2), ' (REST', 1),
--          notes = split_part(ps.notes, ' — CA_0375 (2026-11-12): ', 1), updated_at = now()
--    WHERE ps.source_system = 'la_county_netfile' AND ps.notes LIKE '% — CA_0375 (2026-11-12): %';
-- IDEMPOTENT: the update only touches rows still holding their old id; a re-run changes nothing and every gate passes.

BEGIN;

CREATE TEMP TABLE _map (id uuid PRIMARY KEY, agency text, old_id text, new_id text, committee text) ON COMMIT DROP;
INSERT INTO _map VALUES
  ('636b36fd-bf50-45a0-9a1e-877b494657f2','LACO','212060445','LACO-113034','Guzman for High School Board 2024'),
  ('a9a8b22b-bede-4dfd-998d-959aa13f2f16','LACO','216784754','LACO-113716','LA County: Luna for Sheriff 2022'),
  ('23453e15-1127-468c-ae5e-7f8b27761fbe','LACO','216784885','LACO-113718','LA County: Luna for Sheriff 2026'),
  ('262ab47b-e3e1-4df6-bde2-871181e439cc','LACO','211581618','LACO-112624','Patrice Marshall McKenzie for Board of Education 2026'),
  ('511cef2a-ee0c-4429-ad1c-8be731f552c2','WEHO','185138647','WEHO-112647','John Erickson for WH City Council 2020'),
  ('7650a081-f1bd-4aac-b0f4-df7a07d8cacc','WEHO','210075987','WEHO-112830','Re-Elect John Erickson for WH City Council 2024'),
  ('922580c8-36ec-4582-a8c3-f347f033f072','LACO','216785710','LACO-113730','LA County: Lindsey Horvath for Supervisor 2026'),
  ('fddf480f-60b4-46fa-94fa-7067ec037106','LACO','216785660','LACO-113729','LA County: Jeffrey Prang For Assessor 2022 - Officeholder Account'),
  ('2ad14f75-fd6b-4fff-ae71-66415c2d7edc','LACO','216785851','LACO-113732','LA County: Jeffrey Prang for Assessor 2026'),
  ('d68a06f0-acf4-456e-9f96-ab8cefb98041','WEHO','202019492','WEHO-112739','Chelsea Byers for West Hollywood City Council 2022'),
  ('6a1ec8cb-52b2-459e-ae38-c423dbbcb631','WEHO','214522097','WEHO-112884','Re-Elect Byers West Hollywood City Council 2026'),
  ('243508e6-6dae-4c80-b80b-95bf0d076c73','WEHO','202873881','WEHO-112742','John Heilman for West Hollywood City Council 2022'),
  ('428079c6-df8e-415e-ad79-2613e1dd751f','WEHO','204740311','WEHO-112760','Friends of John Heilman for West Hollywood City Council 2022'),
  ('b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b','LACO','212080164','LACO-113066','Re-Elect Amanda Stern for School Board 2024'),
  ('72000cbb-7b4a-42f0-8164-7fa5676a29d4','LACO','216787458','LACO-113736','LA County: Supervisor Holly J. Mitchell Officeholder 2020');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile') AS links,
       (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed') AS confirmed,
       (SELECT count(*) FROM transparent_motivations.contributions WHERE data_source = 'la_county_netfile') AS netfile_rows;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each of the 15 is the recorded la_county_netfile link under its agency, holding its old id or (re-run) the new one
  SELECT count(*) INTO v_n FROM _map m
    JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
   WHERE ps.source_system = 'la_county_netfile' AND ps.netfile_agency = m.agency
     AND ps.external_id IN (m.old_id, m.new_id);
  IF v_n <> 15 THEN RAISE EXCEPTION 'PRE: % of 15 links match their recorded state', v_n; END IF;

  -- they are all the 9-digit ids there are: no other link stores one the new adapter would refuse
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system = 'la_county_netfile' AND ps.external_id ~ '^\d{9}$'
     AND NOT EXISTS (SELECT 1 FROM _map m WHERE m.id = ps.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other link(s) store a 9-digit REST filer id -- map them too', v_n; END IF;

  -- no link of the same person already stores the new id (the unique index would refuse it)
  SELECT count(*) INTO v_n FROM _map m
    JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
    JOIN transparent_motivations.politician_sources o
      ON o.essentials_politician_id = ps.essentials_politician_id AND o.source_system = 'la_county_netfile'
     AND o.external_id = m.new_id AND o.id <> m.id;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % new id(s) already held by another link of the same person', v_n; END IF;
END $$;

-- ─── Re-point ────────────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET external_id = m.new_id,
       notes = coalesce(ps.notes, '') || ' — CA_0375 (2026-11-12): NetFile local committee id "' || m.committee
               || '" — external_id was ' || m.old_id || ' (REST API filer id; that API now requires a session)',
       updated_at = now()
  FROM _map m
 WHERE ps.id = m.id AND ps.external_id = m.old_id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM _map m
    JOIN transparent_motivations.politician_sources ps ON ps.id = m.id
   WHERE ps.external_id = m.new_id AND ps.notes LIKE '% — CA_0375 (2026-11-12): %external_id was ' || m.old_id || ' (REST%';
  IF v_n <> 15 THEN RAISE EXCEPTION 'POST: % of 15 links hold their new id', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND external_id !~ '^(\d{1,8}|[A-Z0-9]{2,12}-\d+)$';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % link(s) hold an id that is neither an FPPC id nor a local id', v_n; END IF;

  IF (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile') <> b.links
     OR (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed') <> b.confirmed
     OR (SELECT count(*) FROM transparent_motivations.contributions WHERE data_source = 'la_county_netfile') <> b.netfile_rows THEN
    RAISE EXCEPTION 'POST: link count, confirmed count or contribution count changed';
  END IF;
END $$;

COMMIT;
