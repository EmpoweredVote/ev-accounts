-- CA_0223_netfile_mckenzie_stern_netfile_ids.sql
-- Point two confirmed la_county_netfile links at their NetFile filer ids, so the fixed adapter (PR #707) reads them:
--   Patrice Marshall McKenzie (politician_source 262ab47b-e3e1-4df6-bde2-871181e439cc): FPPC 1450349 -> NetFile 211581618
--   Amanda Stern              (politician_source b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b): FPPC 1472646 -> NetFile 212080164
--
-- WHY: netfileAdapter.ts maps a stored FPPC id to the NetFile filer id with IdSearch?aid=LACO&sosId=<id>. For these two
-- ids IdSearch returns no committee (measured 2026-09-24), so the adapter reads the id as a NetFile id, filings/byFiler
-- finds nothing, and both links load 0 rows. They still show the 53 + 12 rows the old Excel export loaded on
-- 2026-04-16. When IdSearch knows no committee, the adapter reads external_id as the NetFile id itself -- the same shape
-- as the seven links that already store 9-digit ids (Horvath, Luna, Prang, Mitchell, Guzman via CA_0179).
--
-- EVIDENCE (live NetFile API, agency LACO, 2026-09-24):
--   * The links' own seed notes name the committees: "Patrice Marshall McKenzie for Board of Education 2026" and
--     "Re-Elect Amanda Stern for School Board 2024". NetFile filers 211581618 and 212080164 carry exactly those names
--     (QuickNameSearch; filings/byFiler returns 10 and 13 filings, one filer name each).
--   * Every stored row matches a NetFile Schedule A row of that filer by date and amount: 53 of 53 (McKenzie) and
--     12 of 12 (Stern). So these are the same committees, not a name guess.
--   * McKenzie's committee holds 174 Schedule A rows at the source, 88 dated 2026 (last filing 2026-09-21). Stern's
--     holds 14, none in 2026.
--
-- EFFECT: none until the next la-county-netfile run. That run reads the full NetFile history for both, and upsert()
-- prunes the 65 Excel-era rows (keys "Filer_ID|Tran_ID") once the new rows are written.
--
-- notes is JSON text on these two rows (seed-la-county-netfile.ts); the evidence is added as a key so it stays valid
-- JSON. notes is public-read: no phone, no address.
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run (BEGIN...ROLLBACK) passed and
-- reverted; a planted wrong count tripped the post gate. Apply: UPDATE 1 + UPDATE 1; re-run: UPDATE 0 + UPDATE 0.
-- Verified after: 262ab47b -> 211581618 and b76c81e1 -> 212080164, both confirmed and tagged. The rows load on the
-- next la-county-netfile run (Render cron 2026-10-01 03:00 UTC unless run sooner).
--
-- ROLLBACK:
--   UPDATE transparent_motivations.politician_sources SET external_id = '1450349', notes = (notes::jsonb - 'relinked_by_CA_0223')::text, updated_at = now()
--    WHERE id = '262ab47b-e3e1-4df6-bde2-871181e439cc' AND external_id = '211581618';
--   UPDATE transparent_motivations.politician_sources SET external_id = '1472646', notes = (notes::jsonb - 'relinked_by_CA_0223')::text, updated_at = now()
--    WHERE id = 'b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b' AND external_id = '212080164';
--   (rows ingested under the new ids replace the Excel-era rows; a rollback after a run leaves the new rows in place)
-- IDEMPOTENT: each UPDATE matches only the old external_id; a re-run changes 0 rows and passes the gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each link is the confirmed la_county_netfile candidate committee we expect, on its old or its new id
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE (id, essentials_politician_id) IN (('262ab47b-e3e1-4df6-bde2-871181e439cc'::uuid, '2518c7a6-f526-4df2-8364-ded34b122f21'::uuid),
                                            ('b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b'::uuid, 'f9e80b26-9155-45cb-a1bc-83b35d0c70ec'::uuid))
     AND source_system = 'la_county_netfile' AND research_status = 'confirmed' AND source_type = 'candidate_committee'
     AND external_id IN ('1450349', '211581618', '1472646', '212080164');
  IF v_n <> 2 THEN RAISE EXCEPTION 'PRE: expected the 2 McKenzie/Stern links, found %', v_n; END IF;

  -- no OTHER link holds either NetFile id
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE external_id IN ('211581618', '212080164')
     AND id NOT IN ('262ab47b-e3e1-4df6-bde2-871181e439cc', 'b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b');
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other link(s) already hold NetFile 211581618/212080164', v_n; END IF;
END $$;

-- ─── 1. Re-point the two links ───────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET external_id = '211581618',
       notes = (notes::jsonb || jsonb_build_object('relinked_by_CA_0223',
         '2026-09-24: FPPC 1450349 -> NetFile filer 211581618 "Patrice Marshall McKenzie for Board of Education 2026"; '
         || 'IdSearch does not know the FPPC id; all 53 stored rows match this filer''s Schedule A by date and amount.'))::text,
       updated_at = now()
 WHERE id = '262ab47b-e3e1-4df6-bde2-871181e439cc' AND external_id = '1450349';

UPDATE transparent_motivations.politician_sources
   SET external_id = '212080164',
       notes = (notes::jsonb || jsonb_build_object('relinked_by_CA_0223',
         '2026-09-24: FPPC 1472646 -> NetFile filer 212080164 "Re-Elect Amanda Stern for School Board 2024"; '
         || 'IdSearch does not know the FPPC id; all 12 stored rows match this filer''s Schedule A by date and amount.'))::text,
       updated_at = now()
 WHERE id = 'b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b' AND external_id = '1472646';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE ((id = '262ab47b-e3e1-4df6-bde2-871181e439cc' AND external_id = '211581618')
       OR (id = 'b76c81e1-84fe-4237-8dd0-a98e7d3fbc3b' AND external_id = '212080164'))
     AND research_status = 'confirmed' AND (notes::jsonb) ? 'relinked_by_CA_0223';
  IF v_n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 links re-pointed, expected 2', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND external_id IN ('1450349', '1472646');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % la_county_netfile link(s) still hold the old FPPC ids', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed';
  IF v_n <> 184 THEN RAISE EXCEPTION 'POST: % confirmed la_county_netfile links, expected 184 (unchanged)', v_n; END IF;

  RAISE NOTICE 'CA_0223 applied: McKenzie -> 211581618, Stern -> 212080164';
END $$;

COMMIT;
