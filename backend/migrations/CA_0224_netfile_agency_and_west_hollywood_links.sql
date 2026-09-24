-- CA_0224_netfile_agency_and_west_hollywood_links.sql
-- Give every la_county_netfile link the NetFile agency that holds its committee, and correct the three City of West
-- Hollywood links, which have read 0 rows on every run since they were seeded (2026-06-09).
--
-- FOUND 2026-09-24, after #707. NetFile hosts many filing officers, each under an agency code: LA County is LACO, the
-- City of West Hollywood is WEHO. netfileAdapter.ts sent a constant 'LACO' to all three endpoints, and a filer id asked
-- under the wrong agency answers like an unknown id -- nothing, HTTP 200. seed-la-county-city-netfile.ts found these
-- three committees under WEHO and wrote "agency=WEHO" into notes, which nothing reads.
--   185138647 John Erickson  "John Erickson for WH City Council 2020"                        25 filings, 459 Sched A rows
--   202019492 Chelsea Byers  "Chelsea Byers for West Hollywood City Council 2022"            15 filings, 282 Sched A rows
--   204740311 John Heilman   "Friends of John Heilman for West Hollywood City Council 2022"  20 filings, 30 Sched A rows
-- Measured on the live API (https://netfile.com/api/public/sites/api, filings/byFiler + SearchCampaignTransactions,
-- aid WEHO, 2026-09-24). Under LACO all three answer nothing, and QuickNameSearch finds none of the three people there.
-- All three hold seats today: Heilman is Mayor for 2026, Byers and Erickson are council members, and Byers is on the
-- November 2026 ballot.
--
-- WHAT CHANGES
--   1. New column politician_sources.netfile_agency. A CHECK makes it REQUIRED for source_system la_county_netfile and
--      NULL for every other system, so a link can never again be read under an agency nobody chose. The adapter throws
--      on a link without one instead of assuming LACO.
--   2. The 181 other la_county_netfile links get 'LACO'. That is measured, not assumed: the first REST run
--      (2026-09-24 02:48 UTC, #707) read every one of them under LACO -- 172 FPPC ids that IdSearch?aid=LACO maps, 7
--      NetFile ids with LACO filings, and McKenzie / Stern, loaded from the LA County Excel export and moved to their
--      LACO NetFile ids 211581618 / 212080164 by CA_0223.
--      The gate below refuses to run if any of them carries an "agency=" note other than these three.
--   3. Erickson 185138647 and Byers 202019492 are their own (controlled) committees: set WEHO, keep confirmed.
--   4. Heilman 204740311 is NOT his committee: it files Form 496 independent-expenditure reports, and its Schedule A
--      donors are real-estate firms funding that spending. Disputed, like CA_0212. Not re-typed as ie_committee: the
--      summary reads count every confirmed link as the person's own fundraising, and the outside-spending read joins
--      la_socrata links only, so an ie_committee link here would show those donors as Heilman's.
--   5. Three committees the people control get new confirmed candidate_committee links under WEHO:
--        210075987 Erickson  "Re-Elect John Erickson for WH City Council 2024"     19 filings to 2026-01-26 (his current term)
--        214522097 Byers     "Re-Elect Byers West Hollywood City Council 2026"     14 filings to 2026-09-23 (on the ballot)
--        202873881 Heilman   "John Heilman for West Hollywood City Council 2022"  21 filings to 2026-07-24, 304 Sched A rows
--      Left out on purpose: slate and independent committees that name them -- 212058093 "WeHo United, Erickson and
--      Hang ..." (files 496s), 204740262 "Friends of Chelsea Byers ... 2022" (files 496s), 217420250 "Friends of Chelsea
--      Byers, Helen Krieger, and Jonathan Cottrell" -- and Heilman's older committees (2017 162062861, 2020 185138254).
--
-- CONTRIBUTIONS: none move. The three existing links hold 0 rows. The next la-county-netfile run loads the WEHO rows
-- under data_source 'la_county_netfile' (the adapter's name; West Hollywood lies inside LA County).
-- DEPLOY ORDER: apply this BEFORE the adapter change deploys. The new code selects netfile_agency, and without the
-- column every source of the run fails. The old code ignores the column, so applying first is safe.
--
-- No migration runner exists; this file records SQL applied by hand (DDL + DML, one transaction).
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run x2 (BEGIN ... ROLLBACK, revert
--   confirmed) and a planted wrong filer id (tripped the pre-flight) before the apply. After: LACO 181 confirmed,
--   WEHO 5 confirmed + 1 disputed. The first re-run stopped at the "other agency" pre-flight, which did not yet skip
--   the three links this file adds (their notes say agency=WEHO); rolled back, gate fixed, re-run then changed nothing.
--
-- ROLLBACK:
--   DELETE FROM transparent_motivations.politician_sources
--    WHERE source_system = 'la_county_netfile' AND notes LIKE '%— seated by CA_0224 (2026-09-24)'
--      AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contributions c WHERE c.politician_source_id = politician_sources.id);
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'confirmed', notes = split_part(notes, ' — disputed by CA_0224', 1)
--    WHERE id = '428079c6-df8e-415e-ad79-2613e1dd751f';
--   ALTER TABLE transparent_motivations.politician_sources DROP CONSTRAINT politician_sources_netfile_agency_check,
--                                                          DROP COLUMN netfile_agency;
--   (Deploy the old adapter first: the new one needs the column.)
-- IDEMPOTENT: the column and CHECK are guarded, the updates only touch rows not yet in their end state, and the inserts
-- use ON CONFLICT DO NOTHING; a re-run changes nothing and every gate passes.

BEGIN;

ALTER TABLE transparent_motivations.politician_sources ADD COLUMN IF NOT EXISTS netfile_agency text;

COMMENT ON COLUMN transparent_motivations.politician_sources.netfile_agency IS
  'NetFile agency (filing officer) that holds this committee, e.g. LACO = LA County, WEHO = City of West Hollywood. '
  'Required for source_system la_county_netfile, NULL otherwise (CHECK). netfileAdapter sends it to every NetFile '
  'endpoint: under the wrong agency a filer id answers nothing, as the WEHO links did until CA_0224.';

-- The three West Hollywood links as found (row, person, filer id).
CREATE TEMP TABLE _weho (id uuid PRIMARY KEY, politician_id uuid, external_id text, person text) ON COMMIT DROP;
INSERT INTO _weho VALUES
  ('511cef2a-ee0c-4429-ad1c-8be731f552c2','29ccd743-6e37-42ec-8999-f1316fff3270','185138647','John Erickson'),
  ('d68a06f0-acf4-456e-9f96-ab8cefb98041','a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a','202019492','Chelsea Byers'),
  ('428079c6-df8e-415e-ad79-2613e1dd751f','ea0b6144-fea3-47a1-878b-8cee956a4c79','204740311','John Heilman');

-- The committees they control that get a link.
CREATE TEMP TABLE _new (politician_id uuid PRIMARY KEY, external_id text, committee text, office text) ON COMMIT DROP;
INSERT INTO _new VALUES
  ('29ccd743-6e37-42ec-8999-f1316fff3270','210075987','Re-Elect John Erickson for WH City Council 2024','Council Member'),
  ('a3aac8fc-d8cb-4cb7-b6be-e5b0fa97c15a','214522097','Re-Elect Byers West Hollywood City Council 2026','Council Member'),
  ('ea0b6144-fea3-47a1-878b-8cee956a4c79','202873881','John Heilman for West Hollywood City Council 2022','Mayor');

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile') AS netfile_links,
       (SELECT count(*) FROM transparent_motivations.politician_sources WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed') AS netfile_confirmed,
       (SELECT count(*) FROM transparent_motivations.politician_sources ps JOIN _new n
          ON n.politician_id = ps.essentials_politician_id AND n.external_id = ps.external_id AND ps.source_system = 'la_county_netfile') AS new_present,
       (SELECT count(*) FROM transparent_motivations.politician_sources WHERE id = '428079c6-df8e-415e-ad79-2613e1dd751f' AND research_status = 'confirmed') AS ie_confirmed,
       (SELECT count(*) FROM transparent_motivations.contributions WHERE data_source = 'la_county_netfile') AS netfile_rows;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  -- each of the three is the recorded la_county_netfile candidate_committee link, on an active incumbent, with
  -- "agency=WEHO" in its notes; Heilman's may already be disputed by an earlier run of this file
  SELECT count(*) INTO v_n FROM _weho w
    JOIN transparent_motivations.politician_sources ps ON ps.id = w.id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.essentials_politician_id = w.politician_id AND ps.source_system = 'la_county_netfile'
     AND ps.external_id = w.external_id AND ps.source_type = 'candidate_committee'
     AND p.full_name = w.person AND p.is_active AND p.is_incumbent
     AND ps.notes LIKE '%agency=WEHO%'
     AND (ps.research_status = 'confirmed'
          OR (w.external_id = '204740311' AND ps.research_status = 'disputed' AND ps.notes LIKE '%disputed by CA_0224 (2026-09-24)%'));
  IF v_n <> 3 THEN RAISE EXCEPTION 'PRE: % of 3 West Hollywood links match their recorded state', v_n; END IF;

  -- no other la_county_netfile link names an agency: the rest are the LACO links the 2026-09-24 run read
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps
   WHERE ps.source_system = 'la_county_netfile' AND ps.notes ~ 'agency=' AND ps.notes !~ 'agency=LACO\M'
     AND NOT EXISTS (SELECT 1 FROM _weho w WHERE w.id = ps.id)
     AND NOT EXISTS (SELECT 1 FROM _new n WHERE n.politician_id = ps.essentials_politician_id AND n.external_id = ps.external_id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other la_county_netfile link(s) name a non-LACO agency -- review them first', v_n; END IF;

  -- netfile_agency is still unset outside la_county_netfile (a re-run leaves it so too)
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system <> 'la_county_netfile' AND netfile_agency IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % non-NetFile link(s) carry a netfile_agency', v_n; END IF;
END $$;

-- ─── 1-3. Agency on every existing link ──────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources ps
   SET netfile_agency = 'WEHO', updated_at = now()
  FROM _weho w
 WHERE ps.id = w.id AND ps.netfile_agency IS DISTINCT FROM 'WEHO';

UPDATE transparent_motivations.politician_sources ps
   SET netfile_agency = 'LACO', updated_at = now()
 WHERE ps.source_system = 'la_county_netfile' AND ps.netfile_agency IS NULL
   AND NOT EXISTS (SELECT 1 FROM _weho w WHERE w.id = ps.id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'transparent_motivations.politician_sources'::regclass
                    AND conname = 'politician_sources_netfile_agency_check') THEN
    ALTER TABLE transparent_motivations.politician_sources
      ADD CONSTRAINT politician_sources_netfile_agency_check
      CHECK ((source_system = 'la_county_netfile') = (netfile_agency IS NOT NULL)
             AND (netfile_agency IS NULL OR netfile_agency ~ '^[A-Z0-9]{2,12}$'));
  END IF;
END $$;

-- ─── 4. Heilman's independent-expenditure committee ─────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET research_status = 'disputed',
       notes = notes || ' — disputed by CA_0224 (2026-09-24): "Friends of John Heilman for West Hollywood City Council 2022" '
                     || 'files Form 496 independent-expenditure reports; it is not a committee he controls, so its receipts are '
                     || 'not his fundraising. His own committee is 202873881.',
       updated_at = now()
 WHERE id = '428079c6-df8e-415e-ad79-2613e1dd751f' AND research_status = 'confirmed';

-- ─── 5. The committees they control ──────────────────────────────────────────────────────────────
INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, source_type, netfile_agency, notes, created_at, updated_at)
SELECT n.politician_id, 'la_county_netfile', n.external_id, 'confirmed', 'candidate_committee', 'WEHO',
       'City of West Hollywood — ' || n.office || ' — agency=WEHO — ' || n.committee || ' — seated by CA_0224 (2026-09-24)',
       now(), now()
  FROM _new n
ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; b record;
BEGIN
  SELECT * INTO b FROM _before;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND netfile_agency IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % la_county_netfile link(s) have no agency', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND netfile_agency = 'WEHO';
  IF v_n <> 6 THEN RAISE EXCEPTION 'POST: % WEHO links, expected 6 (3 found + 3 new)', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND netfile_agency = 'LACO';
  IF v_n <> b.netfile_links - b.new_present - 3 THEN
    RAISE EXCEPTION 'POST: % LACO links, expected % (all but the West Hollywood ones)', v_n, b.netfile_links - b.new_present - 3;
  END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND netfile_agency NOT IN ('LACO', 'WEHO');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % link(s) with an agency this file did not set', v_n; END IF;

  -- the new links: confirmed candidate committees on the right person, under WEHO
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources ps JOIN _new n
    ON n.politician_id = ps.essentials_politician_id AND n.external_id = ps.external_id
   WHERE ps.source_system = 'la_county_netfile' AND ps.research_status = 'confirmed'
     AND ps.source_type = 'candidate_committee' AND ps.netfile_agency = 'WEHO';
  IF v_n <> 3 THEN RAISE EXCEPTION 'POST: % of 3 new West Hollywood links confirmed under WEHO', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE id = '428079c6-df8e-415e-ad79-2613e1dd751f' AND research_status = 'disputed'
     AND notes LIKE '%disputed by CA_0224 (2026-09-24)%';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Heilman 204740311 is not disputed by CA_0224'; END IF;

  -- confirmed la_county_netfile links: -1 disputed, +3 new (on the first run; 0 and 0 on a re-run)
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE source_system = 'la_county_netfile' AND research_status = 'confirmed';
  IF v_n <> b.netfile_confirmed - b.ie_confirmed + (3 - b.new_present) THEN
    RAISE EXCEPTION 'POST: confirmed la_county_netfile % -> %, expected %', b.netfile_confirmed, v_n,
      b.netfile_confirmed - b.ie_confirmed + (3 - b.new_present);
  END IF;

  -- links only: no contribution row moves or disappears
  SELECT count(*) INTO v_n FROM transparent_motivations.contributions WHERE data_source = 'la_county_netfile';
  IF v_n <> b.netfile_rows THEN RAISE EXCEPTION 'POST: la_county_netfile contributions % -> %', b.netfile_rows, v_n; END IF;

  -- positive control: the CHECK refuses a NetFile link without an agency, and an agency on another system
  BEGIN
    INSERT INTO transparent_motivations.politician_sources (essentials_politician_id, source_system, external_id)
    VALUES ('29ccd743-6e37-42ec-8999-f1316fff3270', 'la_county_netfile', 'CA_0224-control');
    RAISE EXCEPTION 'POST: CHECK accepted a la_county_netfile link with no agency';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO transparent_motivations.politician_sources (essentials_politician_id, source_system, external_id, netfile_agency)
    VALUES ('29ccd743-6e37-42ec-8999-f1316fff3270', 'cal_access', 'CA_0224-control', 'LACO');
    RAISE EXCEPTION 'POST: CHECK accepted a netfile_agency on a cal_access link';
  EXCEPTION WHEN check_violation THEN NULL;
  END;

  RAISE NOTICE 'CA_0224 applied: netfile_agency on % links (6 WEHO), Heilman IE committee disputed, 3 WEHO links added', b.netfile_links + (3 - b.new_present);
END $$;

COMMIT;
