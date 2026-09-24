-- CA_0225_dispute_elaine_lu_substring_socrata_links.sql
-- Dispute the two la_socrata links on Elaine Lu (Judge, Los Angeles County Superior Court). Neither committee is hers.
-- audit-socrata-committees.ts linked a committee to a politician when the committee name CONTAINED the politician's
-- normalized surname as a substring -- and "lu" is inside "soLUtions" and "LUca":
--   305aebb0  ie_committee         1405775  California Apartment Association Housing Solutions Committee   19 rows  $1,776,344
--   e24ee133  candidate_committee  1387052  US and Luca Barton for Council 2017                            31 rows  $3,094
--
-- EVIDENCE (LA City Ethics open data, data.lacity.org, read 2026-09-24):
--   1405775 is a GENERAL PURPOSE committee (City Campaign Statements Filed, br3a-db9a; no candidate). In City Campaign
--   Expenditures (5mrt-4zhe) it files under local id 21309: 848 rows, $6.37M. Its Schedule D names ~20 targets across
--   several jurisdictions -- 2022: Traci Park and Erin Darling (LA CD11), Tim McOsker (CD15), Mitch O'Farrell and Hugo
--   Soto-Martinez (CD13), plus Alameda, Santa Ana, San Mateo and Pomona races; 2023: Imelda Padilla (CD6); 2026: Jose
--   Ugarte, Traci Park, Tim Gaspar, Lisa Kaplan, Jennifer Chawla. NO row names Elaine Lu, a judge, or a court.
--   The 19 linked rows are the committee's own receipts (Schedule A, e.g. $430,000 from the CAA IE Committee), so they
--   cannot be re-pointed to one candidate either: the money funded every race above.
--   1387052 is the committee of Luca Barton, a 2017 LA City Council District 1 candidate (m6g2-gc6c: cand_name
--   "Barton, Luca"). Stored as candidate_committee, its $3,094 showed as Elaine Lu's own fundraising.
--   Both were promoted to confirmed by hand (1405775 by scripts/028-confirm-la-socrata-ie-pacs.ts) without a check
--   that the committee's candidate was the linked person.
--
-- WHY 'disputed', NOT re-pointed: the admin API's value for a wrong link, as in CA_0166 - CA_0212. Every read path and
-- the ingestion scheduler require research_status = 'confirmed' -- getOutsideSpendingForPolitician included -- so the
-- $1.78M leaves her outside-spending section and the $3,094 leaves her own fundraising. Nothing is deleted: the
-- contribution rows stay, attached to the link, as the record. Re-pointing 1405775 would repeat the defect (it has
-- no single candidate); Luca Barton is not an Essentials politician. After this she has no confirmed finance link, and
-- detectCoverageStatus reports no_data -- correct: an LA Superior Court judge does not file with LA City Ethics.
-- NOTES: both are plain JSON objects and get disputed_by / disputed_reason keys (as in CA_0212). politician_sources is
-- public-read: the reason carries no phone number.
-- The same substring match made ~27 more confirmed la_socrata links (e.g. Fiona Ma -> "Emile Mack", David Fu ->
-- "Furutani"). They are NOT touched here; they are a separate sweep.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: NOT APPLIED -- awaiting operator approval. Dry run against prod 2026-09-24 (BEGIN ... ROLLBACK, body run twice):
--   run 1 disputed 2 and passed every gate; run 2 updated 0 and passed every gate; a snapshot of both rows matched
--   before and after, so the rollback reverted. Planted control (one committee name altered) tripped the pre-flight.
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'confirmed', notes = (notes::jsonb - 'disputed_by' - 'disputed_reason')::text
--    WHERE research_status = 'disputed' AND notes IS JSON OBJECT AND notes::jsonb ->> 'disputed_by' = 'CA_0225 (2026-09-24)';
-- IDEMPOTENT: the update is guarded on research_status = 'confirmed'; a re-run changes nothing and every gate passes.

BEGIN;

CREATE TEMP TABLE _link (id uuid PRIMARY KEY, external_id text, source_type text, committee text, reason text) ON COMMIT DROP;
INSERT INTO _link VALUES
  ('305aebb0-1f76-4e5c-9184-bbbfd0598c52','1405775','ie_committee','California Apartment Association Housing Solutions Committee',
   'LA City Ethics open data (2026-09-24): a general purpose committee whose expenditures (local id 21309) name ~20 candidates in LA City, Alameda, Santa Ana, San Mateo and Pomona races, never Elaine Lu or any court race. Linked because the surname "Lu" is a substring of "Solutions".'),
  ('e24ee133-f239-4aa1-ae0d-4f1ce489ca9e','1387052','candidate_committee','US and Luca Barton for Council 2017',
   'LA City Ethics open data (2026-09-24): the committee of Luca Barton, a 2017 LA City Council District 1 candidate. Linked because the surname "Lu" is a substring of "Luca".');

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
  IF v_n <> 2 OR v_md5 <> '876e09cc893a9121f313c4602133d930' THEN RAISE EXCEPTION 'PRE: _link is not the reviewed 2 (% / %)', v_n, v_md5; END IF;

  -- each is the recorded (row, committee id, type, stored committee name), la_socrata, on Elaine Lu's active row,
  -- confirmed -- or already disputed by an earlier run of this file
  SELECT count(*) INTO v_n FROM _link l
    JOIN transparent_motivations.politician_sources ps ON ps.id = l.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.essentials_politician_id = 'a5228bd0-a584-4157-bc85-b7461966615a' AND p.full_name = 'Elaine Lu' AND p.is_active
     AND ps.source_system = 'la_socrata' AND ps.external_id = l.external_id AND ps.source_type = l.source_type
     AND ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'cmt_nm' = l.committee
     AND (ps.research_status = 'confirmed'
          OR (ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0225 (2026-09-24)'));
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 links match their reviewed record on Elaine Lu''s active row', v_n; END IF;

  -- she still holds the seat the evidence argues from
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
   WHERE och.politician_id = 'a5228bd0-a584-4157-bc85-b7461966615a' AND o.title = 'Judge, Los Angeles County Superior Court';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Elaine Lu holds % Superior Court seat(s), expected 1', v_n; END IF;
END $$;

-- ─── Dispute the 2 ───────────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'disputed',
       notes = (ps.notes::jsonb || jsonb_build_object('disputed_by', 'CA_0225 (2026-09-24)', 'disputed_reason', l.reason))::text,
       updated_at = now()
  FROM _link l
 WHERE ps.id = l.id AND ps.research_status = 'confirmed';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _link l ON l.id = ps.id
   WHERE ps.research_status = 'disputed' AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0225 (2026-09-24)'
     AND ps.notes::jsonb ->> 'disputed_reason' = l.reason AND ps.notes::jsonb ->> 'cmt_nm' = l.committee;
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 links disputed with the reason', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'disputed_by' = 'CA_0225 (2026-09-24)' AND NOT EXISTS (SELECT 1 FROM _link l WHERE l.id = ps.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % link(s) outside _link carry the CA_0225 (2026-09-24) marker', v_n; END IF;

  -- Elaine Lu has no confirmed finance link left, so nothing shows as her fundraising or outside spending
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'a5228bd0-a584-4157-bc85-b7461966615a' AND research_status = 'confirmed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: Elaine Lu still has % confirmed finance link(s)', v_n; END IF;

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

  RAISE NOTICE 'CA_0225 applied: % of 2 Elaine Lu la_socrata links disputed (were confirmed)', b.to_dispute;
END $$;

COMMIT;
