-- 1929_langford_filer_1444644_to_joy_langford.sql
-- Cal-Access / LA County NetFile filer 1444644 ("LANGFORD FOR WATER BOARD 2026") belongs to
-- Joy Langford, Director of Division 1 on the Water Replenishment District of Southern California.
-- Re-homes its money, folds three committee-name-as-person stub rows into her, and removes a
-- duplicate source row.
--
-- WHY THIS WAS OPEN. Migration 1790 (Cal-Access bucket B, Track A) correctly purged this filer from
-- Kyle Langford: confirm-cal-access.ts had linked it on the LAST TOKEN of full_name, and the
-- official Cal-Access name "LANGFORD FOR WATER BOARD 2026" carries no given name, so the link could
-- not be proved right. 1790 detached it but had no candidate to re-home it to, and the surname-only
-- NetFile stub kept the money instead.
--
-- EVIDENCE THAT 1444644 IS JOY LANGFORD'S (fetched 2026-10-21, LA County NetFile public portal;
-- Cal-Access itself is behind Incapsula and refuses curl, headless Chromium and headful Chromium):
--   * netfile.com/public/LACO/campaign/search-by-id?id=1444644 -> one committee,
--     "Langford For Water Board 2026" (entity 208822164), prior name "LANGFORD FOR WATER BOARD 2022".
--     NetFile's own search parameter for this id is `sosId`, i.e. the Secretary of State filer id --
--     the same identifier space as cal_access.external_id.
--   * Candidate/officeholder search for "Langford" over agency LACO -> exactly ONE person in all of
--     Los Angeles County: "Langford, Joy" (entity 208822159).
--   * The decisive link, her own candidate page
--     /public/LACO/campaign/filingsByCandidate/208822159-Langford, Joy ("All Filings by Candidate -
--     Langford, Joy") lists all 16 filings, every one of them filed by "Langford For Water Board
--     2026" or its predecessor "LANGFORD FOR WATER BOARD 2022". That is NetFile's own
--     candidate->committee relation, not a name match.
--   * Corroboration from the filing history: an FPPC 410 on 2022-02-08 (the WRD board appointed her
--     in Feb 2022), the 2022-named committee through her Nov 2022 win, an FPPC 501 Candidate
--     Intention on 2024-04-09, and the rename to "2026" for the term ending December 2026.
--
-- WHAT MOVES. The money is on the la_county_netfile source, not the cal_access one: 1790 deleted the
-- cal_access contributions outright, so the $113,004.50 that decision file records is already gone
-- from the database. What is live is $56,074.49 over 25 contributions across two election cycles,
-- sitting on source 8d4ba302 under a politician row whose full_name is the bare surname "Langford".
-- contributions and contribution_summary_agg both key on politician_source_id, so re-pointing the
-- SOURCE's owner carries the money with it; no row in either table is touched here.
--
-- NOT TOUCHED: Kyle Langford (82b5989b-8989-462e-8c78-e29148b97c9a) and his three sources, and
-- "LANGFORD, FRIENDS OF DANI" / filer 1290691 (politician 61c8931f, source a2b0a288). That committee
-- names Dani Langford -- a different person -- and 1792 already flagged it correctly.
--
-- No migration runner exists; this file records SQL applied by hand via
-- mcp__supabase-local__execute_sql as `postgres`.

BEGIN;

DO $$
DECLARE n int; d numeric;
BEGIN
  -- Joy Langford exists, is active, and holds the WRD Division 1 seat.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'e569ab1d-d9cf-5364-82c8-faaca133921e' AND full_name = 'Joy Langford' AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1929 pre-check: Joy Langford not found as expected (got %)', n; END IF;

  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e' AND how_started = 'elected';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1929 pre-check: expected 1 elected WRD term for Joy Langford, got %', n; END IF;

  -- She currently has no campaign-finance link at all.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1929 pre-check: Joy Langford already has % source(s); re-check before re-running', n; END IF;

  -- The three sources we move or drop are the ones we expect, all on filer 1444644.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE id IN ('8d4ba302-2e7f-4b48-86c6-9b343491c046',
                '6f8cf7fd-f28d-4a42-9ddf-9fe36b086f3d',
                'e81265b9-e5e8-48fb-83fa-54eb4466a178')
     AND external_id = '1444644';
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1929 pre-check: expected 3 sources on filer 1444644, got %', n; END IF;

  -- The live money, before the move.
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g
   WHERE g.politician_source_id = '8d4ba302-2e7f-4b48-86c6-9b343491c046';
  IF d <> 56074.49 THEN RAISE EXCEPTION 'migration 1929 pre-check: netfile source displays %, expected 56074.49', d; END IF;

  -- The three stub politician rows carry nothing but those sources. Verified against all 28 FK
  -- references to essentials.politicians on 2026-10-21; this re-checks the ones that could plausibly
  -- have been written since.
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM essentials.office_terms
    UNION ALL SELECT politician_id FROM essentials.politician_images
    UNION ALL SELECT politician_id FROM essentials.race_candidates
    UNION ALL SELECT politician_id FROM essentials.politician_committees
    UNION ALL SELECT politician_id FROM inform.politician_answers
    UNION ALL SELECT politician_id FROM inform.politician_context
  ) r WHERE r.politician_id IN ('5a6a320d-d9c2-4a85-8800-3a0155e3daf2',
                                '0080add0-4a4d-4231-93c5-71988f605f44',
                                '5d787760-703f-4670-b2f9-2a3500d1a016');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1929 pre-check: stub rows now carry % attached record(s); stop and look', n; END IF;
END $$;

-- 1. The money. LA County NetFile filer 1444644 -> Joy Langford. Its research_status was already
--    'confirmed', which was false while it hung off a bare surname; it is true now and the basis
--    says why.
UPDATE transparent_motivations.politician_sources
   SET essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e',
       research_status = 'confirmed',
       notes = notes || ' | RE-HOMED (migration 1929, 2026-10-21): was attached to the surname-only'
                     || ' stub politician "Langford" (5a6a320d), which is not a person. LA County'
                     || ' NetFile''s candidate page for "Langford, Joy" (entity 208822159) lists'
                     || ' every filing by this committee, so filer 1444644 is Joy Langford''s.',
       updated_at = now()
 WHERE id = '8d4ba302-2e7f-4b48-86c6-9b343491c046';

-- 2. The Cal-Access link for the same filer -> Joy Langford, now provable.
UPDATE transparent_motivations.politician_sources
   SET essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e',
       research_status = 'confirmed',
       notes = notes || ' | RESOLVED (migration 1929, 2026-10-21): filer 1444644 belongs to Joy'
                     || ' Langford, WRD Division 1. The official Cal-Access name gives no given'
                     || ' name -- which is why migration 1790 purged it from Kyle Langford rather'
                     || ' than reassigning it -- but LA County NetFile indexes the same sosId under'
                     || ' candidate "Langford, Joy" (entity 208822159), the only Langford'
                     || ' candidate in the county.'
                     -- check-cal-access-attribution.mjs is a ratchet: a cal_access source that is
                     -- `confirmed` publishes on a voter's page, so anything newly confirmed must
                     -- carry a machine-readable trail. It matches "adjudicated_by" as a JSON KEY,
                     -- deliberately, so prose saying "adjudicated" does not satisfy it.
                     || ' | {"adjudicated_by":"chris@empowered.vote","adjudication":"LA County'
                     || ' NetFile candidate entity 208822159 (Langford, Joy) lists all 16 filings'
                     || ' by committee entity 208822164, sosId 1444644 -- the same filer id space'
                     || ' as cal_access.external_id. Cal-Access''s own candidate page was'
                     || ' unreachable (Incapsula refuses curl, headless and headful Chromium), so'
                     || ' the county agency that receives the filings was used instead.'
                     || ' Verified 2026-10-21."}',
       updated_at = now()
 WHERE id = '6f8cf7fd-f28d-4a42-9ddf-9fe36b086f3d';

-- 3. The duplicate. discover-cal-access-candidates.ts minted two identical rows for this filer,
--    each with its own stub politician. One is enough.
DELETE FROM transparent_motivations.politician_sources
 WHERE id = 'e81265b9-e5e8-48fb-83fa-54eb4466a178';

-- 4. The stub politician rows: a bare surname and two copies of a committee name. None is a person.
--    All three are now free of sources, and of every other reference.
DELETE FROM essentials.politicians
 WHERE id IN ('5a6a320d-d9c2-4a85-8800-3a0155e3daf2',
              '0080add0-4a4d-4231-93c5-71988f605f44',
              '5d787760-703f-4670-b2f9-2a3500d1a016');

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e';
  IF n <> 2 THEN RAISE EXCEPTION 'migration 1929 post-check: Joy Langford should hold 2 sources, has %', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g
    JOIN transparent_motivations.politician_sources ps ON ps.id = g.politician_source_id
   WHERE ps.essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e';
  IF d <> 56074.49 THEN RAISE EXCEPTION 'migration 1929 post-check: Joy Langford displays %, expected 56074.49', d; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
   WHERE ps.essentials_politician_id = 'e569ab1d-d9cf-5364-82c8-faaca133921e';
  IF n <> 25 THEN RAISE EXCEPTION 'migration 1929 post-check: expected 25 contributions, got %', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('5a6a320d-d9c2-4a85-8800-3a0155e3daf2',
                '0080add0-4a4d-4231-93c5-71988f605f44',
                '5d787760-703f-4670-b2f9-2a3500d1a016');
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1929 post-check: % stub row(s) survived', n; END IF;

  -- Kyle Langford and the Dani Langford committee are untouched.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '82b5989b-8989-462e-8c78-e29148b97c9a';
  IF n <> 3 THEN RAISE EXCEPTION 'migration 1929 post-check: Kyle Langford should still hold 3 sources, has %', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = '61c8931f-d5b4-4f58-b88f-7e8d2e30cbd7';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1929 post-check: the Dani Langford committee row should be untouched'; END IF;
END $$;

COMMIT;
