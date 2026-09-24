-- CA_0236_traci_park_1442937_ie_committee.sql
-- Re-type Traci Park's la_socrata link to committee 1442937 ("Traci Park for Safe Council District 11 2022") from
-- candidate_committee to ie_committee. It stays confirmed: the committee IS about her -- it is an independent committee
-- that supported her 2022 run, not a committee she controlled.
--
-- EVIDENCE: the Secretary of State's Cal-Access bulk export (2026-09-23) lists filer 1442937 as SUB_CATEGORY 40102,
-- PRIMARILY FORMED CANDIDATE, status TERMINATED 10/22/2022 -- recorded in
-- data/roster-audits/2026-09-23-full-name-committee-links-CA_0192.csv, where CA_0192 disputed the cal_access twin of
-- this same filer. The la_socrata link (LA City Ethics) was left as candidate_committee, so its receipts ($4,050,
-- 20 contributions, measured 2026-09-24) showed as her own fundraising. Opened as a follow-up by CA_0228 (#721).
--
-- WHY RE-TYPE AND NOT DISPUTE (operator decision, Chris Andrews, 2026-09-24): an ie_committee link that is confirmed is
-- read by getOutsideSpendingForPolitician (campaignFinanceService.ts) -- it shows the committee, its total and its top
-- donors under Outside Spending -- and is excluded from her own totals (OWN_FUNDRAISING, #714). That is what this
-- committee is. That read takes the name from notes::jsonb ->> 'cmt_nm', so the notes become a JSON object; the old
-- text is kept under previous_notes.
--
-- SWEEP: every filer id CA_0192, CA_0207 and CA_0212 found to be 40102 (105 ids) was checked against every confirmed
-- link in every source system on 2026-09-24. This is the only one still confirmed.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run x2 with a planted control (tripped);
--   re-run after the apply changed nothing. Verified: her confirmed candidate_committee total $2,688,392 -> $2,684,342;
--   the live summary API lists the committee ($4,050) under outside_spending.
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources
--      SET source_type = 'candidate_committee', notes = notes::jsonb ->> 'previous_notes'
--    WHERE id = 'ec42b073-6bfb-4900-be5e-0cb2becd7c11' AND notes IS JSON OBJECT
--      AND notes::jsonb ->> 'retyped_by' = 'CA_0236 (2026-09-24)';
-- IDEMPOTENT: guarded on source_type = 'candidate_committee'; a re-run changes nothing and every gate passes.

BEGIN;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.id = 'ec42b073-6bfb-4900-be5e-0cb2becd7c11' AND p.full_name = 'Traci Park' AND p.is_active
     AND ps.source_system = 'la_socrata' AND ps.external_id = '1442937' AND ps.research_status = 'confirmed'
     AND ((ps.source_type = 'candidate_committee' AND ps.notes = 'Traci Park for Safe Council District 11 2022 — seeded by 004-multi-committee')
          OR (ps.source_type = 'ie_committee' AND ps.notes IS JSON OBJECT AND ps.notes::jsonb ->> 'retyped_by' = 'CA_0236 (2026-09-24)'));
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the link is not in its reviewed state'; END IF;
END $$;

UPDATE transparent_motivations.politician_sources ps
   SET source_type = 'ie_committee',
       notes = jsonb_build_object(
         'cmt_nm', 'Traci Park for Safe Council District 11 2022',
         'retyped_by', 'CA_0236 (2026-09-24)',
         'retyped_reason', 'SOS Cal-Access lists filer 1442937 as PRIMARILY FORMED CANDIDATE (an independent committee that supported her 2022 run, not one she controlled); shown as outside spending, not her own fundraising.',
         'previous_notes', ps.notes)::text,
       updated_at = now()
 WHERE ps.id = 'ec42b073-6bfb-4900-be5e-0cb2becd7c11' AND ps.source_type = 'candidate_committee';

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE id = 'ec42b073-6bfb-4900-be5e-0cb2becd7c11' AND source_type = 'ie_committee' AND research_status = 'confirmed'
     AND notes::jsonb ->> 'cmt_nm' = 'Traci Park for Safe Council District 11 2022'
     AND notes::jsonb ->> 'retyped_by' = 'CA_0236 (2026-09-24)';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: link not re-typed'; END IF;
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE notes IS JSON OBJECT AND notes::jsonb ->> 'retyped_by' = 'CA_0236 (2026-09-24)';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % rows carry the CA_0236 marker', v_n; END IF;
  RAISE NOTICE 'CA_0236 applied: Traci Park 1442937 is now an ie_committee link';
END $$;

COMMIT;
