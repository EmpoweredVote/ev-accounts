-- CA_0179_relink_guzman_high_school_board_2024.sql
-- Link the committee "Guzman for High School Board 2024" to Luis G. Guzman, El Monte Union High School District
-- Trustee Area 2 (active row 02370bdd-6b74-5814-bc64-a0b38524e23d), as a CONFIRMED la_county_netfile source.
--
-- WHY: the CA_0177 review found this committee auto-linked by surname to a CA_0159 no-evidence placeholder (Rosario
-- Guzman, Cal-Access 1475601, now 'disputed' by CA_0177) and recorded it as a lead: "probably Luis G. Guzman's (active
-- row, El Monte Union HSD Trustee Area 2, no committee link) -- only re-link with evidence". The evidence, fetched
-- 2026-09-23:
--   * LA County NetFile (netfile.com, agency LACO): IdSearch for SOS id 1475601 returns one committee, "Guzman for
--     High School Board 2024", NetFile filer 212060445, prior name "Guzman, Luis". Its filings list holds an FPPC 410
--     (2024-09-24), 460s from 2024-10-02 through 2026-07-22, and two FPPC 501 candidate statements filed by
--     "Guzman, Luis" (2024-08-06 and 2024-08-09).
--   * LA County RR/CC candidate list for the 2024-11-05 election (lavote.gov/Apps/CandidateList/Index?id=4324):
--     LUIS G. GUZMAN, El Monte, "EL MONTE UNION HIGH SCHOOL DISTRICT Governing Board Member, Trustee Area No. 2",
--     nomination filed 2024-08-06 -- the same day as the first 501. He is the only Guzman on that list for a
--     high-school board.
--   * Cal-Access 1475601: official name "GUZMAN FOR HIGH SCHOOL BOARD 2024", ACTIVE, filer area code 626 (San Gabriel
--     Valley, which includes El Monte). It has no electronic filings with the Secretary of State: the committee files
--     with the county, which is why the link is la_county_netfile and not cal_access.
--   * The row's seat (office 5ea819d1-4197-4295-99ec-b05ff78b451d) carries a term from 2024-12-01 sourced by CA_0158
--     to the same RR/CC list.
--
-- WHY 'confirmed': the filer record itself names him (the 501s) and the county names him for this seat; that is the
-- "a filer record ties it to this politician" test of the Cal-Access bucket-B posture. 'confirmed' arms the link:
-- the la_county_netfile scheduler will ingest its NetFile 460A transactions (the REST API covers about 2025 on) and the
-- read paths will display them.
--
-- WHY external_id 212060445 and not 1475601: netfileAdapter.ts calls filings/byFiler with ps.external_id, and that
-- endpoint takes the NetFile filer id -- measured: 212060445 returns the 11 filings, 1475601 returns none. The other
-- LA County links made since the NetFile REST move use the same 9-digit ids (Mitchell, Horvath, Luna, Prang).
--
-- NOT DONE: no cal_access link for 1475601 is added (it would ingest nothing), and the two inactive committee-named
-- rows that hold 1475601 are left alone (see CA_0178, NOT IN SCOPE). notes is public-read, so it carries no phone
-- number and no address.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews, who chose 'confirmed'). At the apply, NetFile
-- SearchCampaignTransactions returned no e-filed transactions for this committee, so the link loads $0 until some
-- appear. Verified after: one la_county_netfile 212060445 link, confirmed, on Luis G. Guzman.
--
-- ROLLBACK:
--   DELETE FROM transparent_motivations.politician_sources
--    WHERE essentials_politician_id = '02370bdd-6b74-5814-bc64-a0b38524e23d' AND source_system = 'la_county_netfile'
--      AND external_id = '212060445' AND strpos(notes, 'CA_0179 (2026-09-23)') > 0;
--   (first delete any ingestion_runs / contributions / contribution_summary_agg rows that arrived through it)
-- IDEMPOTENT: ON CONFLICT DO NOTHING on the (politician, system, external id) key; a re-run inserts 0 and passes.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- the row: active, named, and the current holder of El Monte UHSD Trustee Area 2
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
   WHERE p.id = '02370bdd-6b74-5814-bc64-a0b38524e23d' AND p.is_active AND p.full_name = 'Luis G. Guzman'
     AND och.office_id = '5ea819d1-4197-4295-99ec-b05ff78b451d';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Luis G. Guzman is not the active current holder of office 5ea819d1 (% rows)', v_n; END IF;

  -- the NetFile committee is not linked to anyone else (a link on this row from an earlier run is fine)
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND external_id = '212060445'
     AND essentials_politician_id <> '02370bdd-6b74-5814-bc64-a0b38524e23d';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: NetFile 212060445 is already linked to % other politician(s)', v_n; END IF;

  -- the wrong surname link to the placeholder is already disputed (CA_0177), so the committee is not attributed twice
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'cal_access' AND external_id = '1475601'
     AND essentials_politician_id = '093326fa-cf2e-4c6c-9522-66f7381b9e49'
     AND research_status = 'disputed' AND strpos(notes, 'CA_0177 (2026-09-23)') > 0;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the CA_0177 dispute of Cal-Access 1475601 on the placeholder row is missing'; END IF;

  -- no confirmed link anywhere carries this committee under its SOS id
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE external_id = '1475601' AND research_status = 'confirmed';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % confirmed link(s) already carry SOS id 1475601', v_n; END IF;
END $$;

-- ─── 1. Link the committee ─────────────────────────────────────────────────────────────────────
INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, source_type, notes, created_at, updated_at)
VALUES ('02370bdd-6b74-5814-bc64-a0b38524e23d', 'la_county_netfile', '212060445', 'confirmed', 'candidate_committee',
        'El Monte Union High School District Trustee Area 2 -- Guzman for High School Board 2024 | linked by CA_0179 '
        || '(2026-09-23): LA County NetFile committee 212060445 = SOS/FPPC 1475601 "GUZMAN FOR HIGH SCHOOL BOARD 2024"; '
        || 'its FPPC 501 statements (2024-08-06, 2024-08-09) are filed by "Guzman, Luis", and the LA County RR/CC '
        || 'candidate list for the 2024-11-05 election (lavote.gov CandidateList id 4324) names LUIS G. GUZMAN for El '
        || 'Monte UHSD Governing Board Member, Trustee Area No. 2, nomination filed 2024-08-06.',
        now(), now())
ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '02370bdd-6b74-5814-bc64-a0b38524e23d' AND source_system = 'la_county_netfile'
     AND external_id = '212060445' AND research_status = 'confirmed' AND source_type = 'candidate_committee'
     AND strpos(notes, 'CA_0179 (2026-09-23)') > 0;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % CA_0179 link(s) for Luis G. Guzman, expected 1', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND external_id = '212060445';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: NetFile 212060445 is linked % times, expected 1', v_n; END IF;

  -- the row now has exactly this one committee link
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '02370bdd-6b74-5814-bc64-a0b38524e23d';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Luis G. Guzman has % committee links, expected 1', v_n; END IF;

  RAISE NOTICE 'CA_0179 applied: Guzman for High School Board 2024 (NetFile 212060445) confirmed on Luis G. Guzman';
END $$;

COMMIT;
