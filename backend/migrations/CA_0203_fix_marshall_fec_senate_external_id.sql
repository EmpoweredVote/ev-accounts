-- CA_0203_fix_marshall_fec_senate_external_id.sql
--
-- Roger Marshall (Senator, Kansas; essentials.politicians.full_name = 'Roger Marshall',
-- bioguide M001198) has one `transparent_motivations.politician_sources` row
-- (id c3bd6c4e-c8dc-43e6-8155-a7b5897e2dc9), source_system 'fec_senate', research_status
-- 'confirmed', carrying external_id 'H6KS01179'. That is his OLD HOUSE candidate ID (he
-- represented KS-01 2017-2021) -- an 'H'-prefixed id stored under 'fec_senate'. It is the
-- only confirmed fec_senate row on prod whose external_id does not start with 'S':
--
--   SELECT * FROM transparent_motivations.politician_sources
--    WHERE source_system='fec_senate' AND research_status='confirmed'
--      AND upper(left(external_id,1)) <> 'S';
--
-- His current FEC Senate candidate id is S0KS00315. Checked against the FEC API 2026-09-23:
--   * GET /v1/candidate/S0KS00315/  -> candidate_status 'C' (active), office 'S', cycles
--     through 2026, last_file_date 2026-09-11.
--   * GET /v1/candidate/S0KS00315/totals/?cycle=2026 -> receipts $4,009,074.73 (matches the
--     ~$4.0M figure this migration was scoped against).
--   * GET /v1/candidate/H6KS01179/  -> candidate_status 'P' (prior), last_file_date
--     2020-09-03.
--   * GET /v1/candidate/H6KS01179/totals/?cycle=2026 -> zero rows: no F3 filings are
--     summarized under this id for the current cycle.
--
-- WHY THE INGESTED CONTRIBUTIONS ARE LEFT ALONE. The 8,464 `contributions` rows already
-- hanging off this politician_source_id (2016-2026 cycles, $9,821,957.33, all data_source
-- 'fec') are NOT re-pointed, deleted or touched by this migration, because they are not
-- actually from a different, defunct House committee -- every one of them (checked via
-- raw_record->>'committee_id') was fetched from FEC committee C00576173, "KANSANS FOR
-- MARSHALL". That is Marshall's one and only principal campaign committee: FEC currently
-- classifies it committee_type 'S' (Senate), it has filed continuously since 2015
-- (last_f1_date 2026-09-02), and its own candidate_ids list carries BOTH H6KS01179 and
-- S0KS00315 -- he never got a new committee when he moved from the House to the Senate, only
-- a new FEC *candidate* registration. `fecAdapter.resolveCommitteeIds` resolves a candidate
-- id to its committee(s) and pulls Schedule A by committee, so ingestion under the old id
-- happened to reach the correct, current committee all along. Fixing the external_id changes
-- which candidate id future scheduler runs (`campaignFinanceScheduler.runAdapterForAll`)
-- resolve from -- not which committee, and not the history already ingested.
--
-- Sweep for the same defect class (2026-09-23): zero confirmed fec_house rows with an
-- external_id not starting with 'H'; the only source_system='fec' (legacy) rows are five
-- Virginia House members, all correctly H-prefixed. Roger Marshall is the only bad row.
--
-- Idempotent: the UPDATE is guarded on the row still carrying the old external_id, so a
-- re-run after this has applied is a no-op.

DO $$
DECLARE
  v_id   CONSTANT uuid := 'c3bd6c4e-c8dc-43e6-8155-a7b5897e2dc9';
  v_pol  CONSTANT uuid := '9df12eb2-bc9a-4083-8004-1af4167342ea';
  v_n    int;
BEGIN
  SELECT count(*) INTO v_n
    FROM transparent_motivations.politician_sources
   WHERE id = v_id
     AND essentials_politician_id = v_pol
     AND source_system = 'fec_senate'
     AND external_id IN ('H6KS01179', 'S0KS00315')
     AND research_status = 'confirmed';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CA_0203 pre-flight: expected exactly 1 matching politician_sources row for %, found %', v_id, v_n;
  END IF;
END $$;

UPDATE transparent_motivations.politician_sources
   SET external_id = 'S0KS00315',
       notes = btrim(coalesce(notes, '')) || E'\n'
               || 'CA_0203 (2026-09-23): external_id corrected from H6KS01179 (his old House '
               || 'candidate id, KS-01 2017-2021) to S0KS00315 (his current FEC Senate '
               || 'candidate id; FEC totals for cycle 2026 show $4,009,074.73 in receipts vs. '
               || 'zero filings under H6KS01179). Contributions already ingested are unaffected '
               || '-- both ids resolve to the same committee, C00576173 "KANSANS FOR MARSHALL".'
 WHERE id = 'c3bd6c4e-c8dc-43e6-8155-a7b5897e2dc9'
   AND external_id = 'H6KS01179';

DO $$
DECLARE
  v_id       CONSTANT uuid := 'c3bd6c4e-c8dc-43e6-8155-a7b5897e2dc9';
  v_extid    text;
  v_noted    int;
  v_contribs int;
BEGIN
  SELECT external_id INTO v_extid FROM transparent_motivations.politician_sources WHERE id = v_id;
  IF v_extid <> 'S0KS00315' THEN
    RAISE EXCEPTION 'CA_0203: external_id is %, expected S0KS00315', v_extid;
  END IF;

  SELECT count(*) INTO v_noted
    FROM transparent_motivations.politician_sources
   WHERE id = v_id AND notes LIKE '%CA_0203 (2026-09-23): external_id corrected%';
  IF v_noted <> 1 THEN
    RAISE EXCEPTION 'CA_0203: provenance note missing on %', v_id;
  END IF;

  -- The contributions already ingested must be untouched -- same count, still pointing here.
  SELECT count(*) INTO v_contribs
    FROM transparent_motivations.contributions
   WHERE politician_source_id = v_id;
  IF v_contribs <> 8464 THEN
    RAISE EXCEPTION 'CA_0203: % contribution row(s) on %, expected 8464 (unchanged)', v_contribs, v_id;
  END IF;

  RAISE NOTICE 'CA_0203 OK: external_id corrected to S0KS00315, 8464 contribution row(s) left in place';
END $$;
