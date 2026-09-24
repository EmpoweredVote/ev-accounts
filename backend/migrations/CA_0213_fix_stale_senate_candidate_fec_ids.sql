-- CA_0213_fix_stale_senate_candidate_fec_ids.sql
--
-- Three 2026 U.S. Senate candidates carry a confirmed `fec_senate` politician_sources row whose
-- external_id is the FEC candidate id from an EARLIER campaign. FEC registers a new candidate id
-- per campaign, and the old one keeps the same name, state and office, so a name search cannot
-- tell them apart:
--
--   Charles Booker (KY)  S0KY00420 (election_years 2020,2022, status P)  -> S6KY00385 (2026, C)
--   David Roth     (ID)  S2ID00178 (2022, P)                             -> S6ID00138 (2026, C)
--   John Sununu    (NH)  S0NH00201 (2002,2008, P)                        -> S6NH00208 (2026, C)
--
-- Checked against the FEC API 2026-09-23 (GET /v1/candidate/<id>/ and
-- /v1/candidate/<id>/totals/?cycle=2026&election_full=false):
--   * S6KY00385  BOOKER, CHARLES  principal committee C00929208 "BOOKER FOR THE COMMONWEALTH";
--                2025-26 receipts $1,099,509.09. Old S0KY00420: $7,863.07, last filed 2023-04-15.
--   * S6ID00138  ROTH, DAVID JORDAN  principal committee C00839720 "DAVID ROTH FOR IDAHO";
--                2025-26 receipts $14,626.74. Old S2ID00178: no 2025-26 totals.
--   * S6NH00208  SUNUNU, JOHN E  principal committee C00924092 "SUNUNU SENATOR";
--                2025-26 receipts $4,180,251.88. Old S0NH00201: no 2025-26 totals.
-- Each new id's FEC name matches the old id's exactly, in the same state.
--
-- HOW IT WAS FOUND. The first live `run-fec-finance-summary.ts --candidates-only` (after #676)
-- wrote Booker a 2026 finance_summary of $7,863 from the dormant id, and wrote Roth and Sununu
-- no total_raised at all. A sweep of all 50 Senate-candidate placeholder holders then asked FEC
-- whether each confirmed id's election_years include 2026: 47 do, these 3 do not, and each has
-- exactly one 2026 id under the same name and state.
--
-- ROOT CAUSE (not fixed here). fecResearch.searchFecCandidates searches FEC by name, state and
-- office with no election_year, and scoreMatch ignores election_years, so a returning
-- candidate's old and new ids tie. Fixing that is a separate code change.
--
-- WHY THE INGESTED CONTRIBUTIONS ARE LEFT ALONE. The rows already hanging off these three
-- politician_source ids came from the OLD campaigns' own committees (raw_record->>'committee_id'):
--   Booker  31,894 rows, cycles 2022-2026, all C00783274 "BOOKER FOR KENTUCKY"
--   Roth       434 rows, cycle 2022,       all C00808162 "DAVID ROTH FOR US SENATE"
--   Sununu   5,961 rows, cycles 2002-2016, all C00370031
-- Unlike CA_0203 (Marshall: two candidate ids, one committee), the new ids resolve to NEW
-- committees. The old rows are still true: each is a real contribution to the same person's
-- earlier Senate campaign, stamped with its own election_cycle, so the profile's cycle selector
-- keeps showing them under the cycles they belong to. Changing external_id changes which
-- candidate id the next scheduled FEC run (campaignFinanceScheduler.runAdapterForAll) resolves
-- committees from; the adapter upserts ON CONFLICT (data_source, source_transaction_id = sub_id),
-- so the new committees' rows arrive alongside, never duplicated.
--
-- Idempotent: each UPDATE is guarded on the row still carrying its old external_id, so a re-run
-- after this has applied is a no-op.
--
-- Follow-up after apply: `tsx scripts/run-fec-finance-summary.ts --candidates-only` to rewrite the
-- three finance_summary values from the corrected ids.

DO $$
DECLARE
  v_n int;
BEGIN
  SELECT count(*) INTO v_n
    FROM transparent_motivations.politician_sources
   WHERE source_system = 'fec_senate'
     AND research_status = 'confirmed'
     AND (   (id = '7f25303c-4683-4a1d-b6d9-2b3c04d8e962'
              AND essentials_politician_id = 'b5cc94df-2ba3-4057-8abd-5760383b286b'
              AND external_id IN ('S0KY00420', 'S6KY00385'))
          OR (id = '38da6c04-0828-4517-9073-cf40a08c3e01'
              AND essentials_politician_id = 'bc9ec968-d664-4987-8f9c-108f9ae51535'
              AND external_id IN ('S2ID00178', 'S6ID00138'))
          OR (id = 'e209afb4-f39e-4244-a9b5-01740deffc87'
              AND essentials_politician_id = 'ffb0dcac-385a-4df3-a441-cdbd0e713c1d'
              AND external_id IN ('S0NH00201', 'S6NH00208')));
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0213 pre-flight: expected 3 matching politician_sources rows, found %', v_n;
  END IF;

  -- The corrected ids must not already belong to some other source row.
  SELECT count(*) INTO v_n
    FROM transparent_motivations.politician_sources
   WHERE external_id IN ('S6KY00385', 'S6ID00138', 'S6NH00208')
     AND id NOT IN ('7f25303c-4683-4a1d-b6d9-2b3c04d8e962',
                    '38da6c04-0828-4517-9073-cf40a08c3e01',
                    'e209afb4-f39e-4244-a9b5-01740deffc87');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0213 pre-flight: % other politician_sources row(s) already carry a corrected id', v_n;
  END IF;
END $$;

UPDATE transparent_motivations.politician_sources
   SET external_id = 'S6KY00385',
       notes = concat_ws(E'\n', NULLIF(btrim(notes), ''),
               'CA_0213 (2026-09-23): external_id corrected from S0KY00420 (the 2020/2022 Senate '
               || 'candidate id, last filed 2023-04-15) to S6KY00385 (the 2026 id; committee '
               || 'C00929208 BOOKER FOR THE COMMONWEALTH). Contributions already ingested from '
               || 'C00783274 BOOKER FOR KENTUCKY are from the earlier campaigns and are left in place.')
 WHERE id = '7f25303c-4683-4a1d-b6d9-2b3c04d8e962'
   AND external_id = 'S0KY00420';

UPDATE transparent_motivations.politician_sources
   SET external_id = 'S6ID00138',
       notes = concat_ws(E'\n', NULLIF(btrim(notes), ''),
               'CA_0213 (2026-09-23): external_id corrected from S2ID00178 (the 2022 Senate '
               || 'candidate id) to S6ID00138 (the 2026 id; committee C00839720 DAVID ROTH FOR '
               || 'IDAHO). Contributions already ingested from C00808162 are from the 2022 campaign and '
               || 'are left in place.')
 WHERE id = '38da6c04-0828-4517-9073-cf40a08c3e01'
   AND external_id = 'S2ID00178';

UPDATE transparent_motivations.politician_sources
   SET external_id = 'S6NH00208',
       notes = concat_ws(E'\n', NULLIF(btrim(notes), ''),
               'CA_0213 (2026-09-23): external_id corrected from S0NH00201 (the 2002/2008 Senate '
               || 'candidate id) to S6NH00208 (the 2026 id; committee C00924092 SUNUNU SENATOR). '
               || 'Contributions already ingested from C00370031 are from the earlier campaigns and are '
               || 'left in place.')
 WHERE id = 'e209afb4-f39e-4244-a9b5-01740deffc87'
   AND external_id = 'S0NH00201';

DO $$
DECLARE
  v_n int;
BEGIN
  SELECT count(*) INTO v_n
    FROM transparent_motivations.politician_sources
   WHERE (id = '7f25303c-4683-4a1d-b6d9-2b3c04d8e962' AND external_id = 'S6KY00385')
      OR (id = '38da6c04-0828-4517-9073-cf40a08c3e01' AND external_id = 'S6ID00138')
      OR (id = 'e209afb4-f39e-4244-a9b5-01740deffc87' AND external_id = 'S6NH00208');
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0213: % of 3 rows carry the corrected external_id', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM transparent_motivations.politician_sources
   WHERE id IN ('7f25303c-4683-4a1d-b6d9-2b3c04d8e962',
                '38da6c04-0828-4517-9073-cf40a08c3e01',
                'e209afb4-f39e-4244-a9b5-01740deffc87')
     AND research_status = 'confirmed'
     AND source_system = 'fec_senate'
     AND notes LIKE '%CA_0213 (2026-09-23): external_id corrected%';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0213: provenance note or status missing on % of 3 rows', 3 - v_n;
  END IF;

  -- Contributions are untouched. Floors, not exact counts: the scheduler may ingest more rows
  -- before this applies, but nothing here removes one.
  IF (SELECT count(*) FROM transparent_motivations.contributions
       WHERE politician_source_id = '7f25303c-4683-4a1d-b6d9-2b3c04d8e962') < 31894
  OR (SELECT count(*) FROM transparent_motivations.contributions
       WHERE politician_source_id = '38da6c04-0828-4517-9073-cf40a08c3e01') < 434
  OR (SELECT count(*) FROM transparent_motivations.contributions
       WHERE politician_source_id = 'e209afb4-f39e-4244-a9b5-01740deffc87') < 5961 THEN
    RAISE EXCEPTION 'CA_0213: a contributions count fell below its 2026-09-23 floor';
  END IF;

  RAISE NOTICE 'CA_0213 OK: 3 fec_senate external_ids corrected; contributions left in place';
END $$;
