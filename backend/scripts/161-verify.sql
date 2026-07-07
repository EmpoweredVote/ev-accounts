-- 161-verify.sql — Phase 161 read-only production gate (USHC3-02/03/04/05).
--
-- SELECT-only. Asserts the live state delivered across Phase 161's waves for the WA + AZ +
-- TN + MA 2026 US House field (37 districts: AZ 9, WA 10, TN 9, MA 9). Cloned from the
-- validated 156-verify.sql (per-state scoping + honest-skip-pin discipline) and
-- 158-verify.sql (multi-state structural gate shape), with a NEW TN severe-district
-- non-surfacing assertion block (no prior-phase precedent).
--
-- ============================================================================
-- PER-STATE SCOPING (the cross-state contamination trap):
--   AZ, WA, TN, MA are SEPARATE elections (MA reuses 9 PRE-EXISTING races under
--   '2026 Massachusetts General Election'; TN has TWO elections -- the surfacing
--   'TN 2026 Statewide General' and the deliberately withheld 'TN 2026 Congressional
--   Redistricting - Polygon Pending'). Every assertion is scoped by election id AND
--   d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('04','53','47','25').
--   NEVER write a cross-state or election-wide count.
--
-- TN SEVERE-DISTRICT WITHHOLDING (D-01b) — FLIPPED TO SURFACING 2026-07-07:
--   161-01's correspondence audit scored 5 of TN's 9 districts SEVERE (4704, 4705,
--   4706, 4708, 4709); 161-06 withheld them by pointing their races at the past-dated
--   "TN 2026 Congressional Redistricting - Polygon Pending" special. Phase 164.1-04
--   imported TN's 2026-vintage polygons (mtfcc='G5200V26', TNMap/HB 7003), passed the
--   D-10 3-layer verify bar, and migration 1247 re-pointed the 5 severe races to
--   'TN 2026 Statewide General'. CRITERION 6 now asserts ALL 9 TN districts SURFACING
--   (positive). The Polygon Pending election row persists as a historical artifact.
--
-- AZ ROSTER RECONCILIATION (applied by migration 1204, same session as this gate):
--   5 AZ candidates seeded active by migration 1188 (161-02) were discovered during 161-03's
--   stance research to be withdrawn/disqualified from the actual July 21, 2026 primary:
--   external_id -40108 (Ajluni), -40201 (Descheenie), -40402 (Davison), -40503 (Bracht),
--   -40602 (Bah). Migration 1204 set their race_candidates.candidate_status = 'withdrawn'.
--   This gate asserts all 5 are NOT active.
--
-- HONEST-SKIP PIN TABLES (whole-record stance skips; the 143 lesson -- pin by exact
-- external_id WITH the query's exact ORDER BY, or an ordering mismatch false-fails):
--   AZ (4 of 32 new candidates; the 5 ballot-ineligible above are EXCLUDED from this pin
--       list because they exit the active-scoped in-scope set entirely once withdrawn):
--     Alan Aversa (-40301), John Fillmore (-40405), Jereme Peters (-40603),
--     Daniel Butierez (-40701) -- see 161-03-SUMMARY.md "Genuine evidence-gap skips".
--   WA (14 of 60 new candidates) -- see 161-05-SUMMARY.md "Roster Reconciliation" table.
--   TN (40 of 73 new candidates: 21 from 161-07 TN-1..5 + 19 from 161-09 TN-6..9) -- see
--     161-07-SUMMARY.md / 161-09-SUMMARY.md "Whole-Record Honest Skips" tables.
--   MA (1 of 18 new candidates: R. Tyler MacAllister -250902) -- see 161-10-SUMMARY.md.
--   Total: 59 pinned whole-record stance skips. Full search-trail text lives in the four
--   SUMMARY.md files cited above (161-03/05/07/09/10) -- not re-duplicated here verbatim to
--   keep this gate file's size manageable; each pin's INSERT comment gives the one-line trail.
--
-- HEADSHOT HONEST-SKIP PINS (_img_skip, by external_id, ORDER BY external_id):
--   167 of 174 active new candidates (AZ 24, WA 57, TN 70, MA 16) have no free-license
--   portrait (obscure down-ballot challenger/minor-line, no dedicated Wikipedia bio page, or
--   a historical-homonym/wrong-person guard rejection) per the seeding waves'
--   `seed-{state}-house-headshots.py` runs (161-02/04/06/08-SUMMARY.md). Reconstructed live
--   against prod at gate-authoring time (matches each SUMMARY's documented skip COUNT
--   exactly: AZ 28-4=24 post-reconciliation, WA 57, TN 70, MA 16); the original per-candidate
--   JSON result files (`_{state}-house-headshot-results.json`) were session-scratch and are
--   no longer present on disk, but the live "active new candidate lacking an image" query
--   used to build this pin list is unambiguous and reproducible.
--
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. The only writes are
--   `CREATE TEMP TABLE ... ON COMMIT DROP` for diffing (149/150/155/156/158-verify.sql
--   precedent). SELECT-only against production; never `--commit`.
--
-- Run read-only:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/161-verify.sql
--
-- AZ election:  'AZ 2026 Statewide General'                              FIPS 04 / geo 0401..0409.
-- WA election:  'WA 2026 Statewide General'                              FIPS 53 / geo 5301..5310.
-- TN elections: 'TN 2026 Statewide General' (surfacing, 4 non-severe)    FIPS 47 / geo 4701..4709.
--               'TN 2026 Congressional Redistricting - Polygon Pending' (withheld, 5 severe)
-- MA election:  '2026 Massachusetts General Election' (PRE-EXISTING)     FIPS 25 / geo 2501..2509.

\set ON_ERROR_STOP on

DO $$
DECLARE
  az_eid            uuid;
  wa_eid            uuid;
  tn_gen_eid        uuid;
  tn_withheld_eid   uuid;
  ma_eid            uuid;
  v_az_races        int;
  v_wa_races        int;
  v_tn_races        int;
  v_ma_races        int;
  v_null_office     int;
  v_nullpid         int;
  v_dupname         int;
  v_party_cols      int;
  v_leaked          int;
  v_surfaced_ok     int;
  v_az_ineligible_active int;
  v_clark           int;
  v_pressley        int;
  v_no_image        int;
  v_image_detail    text;
  v_unsourced       int;
  v_uncovered       int;
  v_cov_detail      text;
BEGIN
  -- ==========================================================================
  -- Resolve all five election rows by exact name (4 states, TN has 2 elections).
  -- ==========================================================================
  SELECT id INTO az_eid          FROM essentials.elections WHERE name = 'AZ 2026 Statewide General';
  SELECT id INTO wa_eid          FROM essentials.elections WHERE name = 'WA 2026 Statewide General';
  SELECT id INTO tn_gen_eid      FROM essentials.elections WHERE name = 'TN 2026 Statewide General';
  SELECT id INTO tn_withheld_eid FROM essentials.elections WHERE name = 'TN 2026 Congressional Redistricting - Polygon Pending';
  SELECT id INTO ma_eid          FROM essentials.elections WHERE name = '2026 Massachusetts General Election';
  IF az_eid IS NULL OR wa_eid IS NULL OR tn_gen_eid IS NULL OR tn_withheld_eid IS NULL OR ma_eid IS NULL THEN
    RAISE EXCEPTION 'FAIL setup: one or more Phase-161 elections missing (az=%, wa=%, tn_gen=%, tn_withheld=%, ma=%)',
      az_eid, wa_eid, tn_gen_eid, tn_withheld_eid, ma_eid;
  END IF;

  -- ==========================================================================
  -- Combined Phase-161 House working set (all 4 states, LEFT JOIN candidates).
  -- Scoped by: election_id IN (5 eids) + NATIONAL_LOWER + geo prefix IN (04,53,47,25).
  -- st column distinguishes states; p.external_id included for band/pin checks.
  -- ==========================================================================
  CREATE TEMP TABLE _house ON COMMIT DROP AS
  SELECT CASE
           WHEN r.election_id = az_eid THEN 'AZ'
           WHEN r.election_id = wa_eid THEN 'WA'
           WHEN r.election_id IN (tn_gen_eid, tn_withheld_eid) THEN 'TN'
           ELSE 'MA'
         END              AS st,
         r.id             AS race_id,
         r.election_id    AS race_election_id,
         r.office_id      AS office_id,
         d.geo_id         AS geo_id,
         rc.id            AS rc_id,
         rc.politician_id,
         rc.full_name,
         rc.candidate_status,
         rc.is_incumbent,
         p.external_id
  FROM essentials.races r
  JOIN  essentials.offices o    ON o.id = r.office_id
  JOIN  essentials.districts d  ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  LEFT JOIN essentials.politicians p      ON p.id = rc.politician_id
  WHERE ( r.election_id IN (az_eid, wa_eid, tn_gen_eid, tn_withheld_eid, ma_eid) )
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) IN ('04', '53', '47', '25');

  -- ==========================================================================
  -- CRITERION 1 — exactly AZ 9 + WA 10 + TN 9 + MA 9 = 37 distinct NATIONAL_LOWER races.
  -- ==========================================================================
  SELECT COUNT(DISTINCT race_id) INTO v_az_races FROM _house WHERE st = 'AZ';
  SELECT COUNT(DISTINCT race_id) INTO v_wa_races FROM _house WHERE st = 'WA';
  SELECT COUNT(DISTINCT race_id) INTO v_tn_races FROM _house WHERE st = 'TN';
  SELECT COUNT(DISTINCT race_id) INTO v_ma_races FROM _house WHERE st = 'MA';
  IF v_az_races <> 9  THEN RAISE EXCEPTION 'FAIL scope: expected 9 AZ NATIONAL_LOWER races, got %', v_az_races; END IF;
  IF v_wa_races <> 10 THEN RAISE EXCEPTION 'FAIL scope: expected 10 WA NATIONAL_LOWER races, got %', v_wa_races; END IF;
  IF v_tn_races <> 9  THEN RAISE EXCEPTION 'FAIL scope: expected 9 TN NATIONAL_LOWER races, got %', v_tn_races; END IF;
  IF v_ma_races <> 9  THEN RAISE EXCEPTION 'FAIL scope: expected 9 MA NATIONAL_LOWER races, got %', v_ma_races; END IF;
  RAISE NOTICE 'PASS SCOPE: AZ 9 + WA 10 + TN 9 + MA 9 = 37 distinct NATIONAL_LOWER races';

  -- ==========================================================================
  -- CRITERION 2 — every House race has office_id NOT NULL (all 37).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_null_office FROM _house WHERE office_id IS NULL;
  IF v_null_office <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLOFFICE: % of 37 Phase-161 House race(s) have NULL office_id', v_null_office;
  END IF;
  RAISE NOTICE 'PASS NULLOFFICE: 0 of 37 Phase-161 House races have NULL office_id (incl. the 5 withheld severe-TN races -- office_id populated, only election_id withheld)';

  -- ==========================================================================
  -- CRITERION 3 — 0 active race_candidates with NULL politician_id.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_nullpid FROM _house
  WHERE candidate_status = 'active' AND politician_id IS NULL;
  IF v_nullpid <> 0 THEN
    RAISE EXCEPTION 'FAIL NULLPID: % active Phase-161 House race_candidates have NULL politician_id', v_nullpid;
  END IF;
  RAISE NOTICE 'PASS NULLPID: 0 active AZ/WA/TN/MA House candidates with NULL politician_id';

  -- ==========================================================================
  -- CRITERION 4 — 0 duplicate lower(full_name) among ACTIVE candidates WITHIN each state.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_dupname FROM (
    SELECT st, lower(full_name)
    FROM _house
    WHERE candidate_status = 'active'
    GROUP BY st, lower(full_name)
    HAVING COUNT(*) > 1
  ) q;
  IF v_dupname <> 0 THEN
    RAISE EXCEPTION 'FAIL DUPNAME: % duplicate full_name group(s) within a state among active candidates (incumbent-reuse / v2.4 dup-incumbent trap)', v_dupname;
  END IF;
  RAISE NOTICE 'PASS DUPNAME: 0 duplicate full_name within any state (AZ/WA/TN/MA) among active candidates -- incumbents reused, not duplicated';

  -- ==========================================================================
  -- CRITERION 5 — antipartisan structural invariant: race_candidates carries no
  --   party/party_affiliation column. Party lives on races.primary_party only.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_party_cols
  FROM information_schema.columns
  WHERE table_schema = 'essentials'
    AND table_name = 'race_candidates'
    AND column_name IN ('party', 'party_affiliation');
  IF v_party_cols <> 0 THEN
    RAISE EXCEPTION 'FAIL PARTY: essentials.race_candidates has % party/party_affiliation column(s) -- antipartisan invariant violated', v_party_cols;
  END IF;
  RAISE NOTICE 'PASS PARTY: race_candidates has no party/party_affiliation column (party reads from races.primary_party only)';

  -- ==========================================================================
  -- CRITERION 6 — TN all-districts-surfacing invariant.
  --   FLIPPED 2026-07-07 by Phase 164.1-04 (migration 1247): TN's 2026-vintage
  --   polygons (mtfcc='G5200V26') are imported and the D-10 3-layer bar passed,
  --   so the 5 formerly-withheld severe races (4704/4705/4706/4708/4709) were
  --   re-pointed from 'Polygon Pending' to the TN general. ALL 9 TN districts
  --   MUST now be wired to tn_gen_eid (per the 163-11 standing instruction).
  -- ==========================================================================
  SELECT COUNT(DISTINCT geo_id) INTO v_leaked
  FROM _house
  WHERE st = 'TN'
    AND race_election_id = tn_withheld_eid;
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'FAIL TN-STILL-WITHHELD: % TN race(s) still wired to Polygon Pending (expected 0 after the 164.1-04 un-withhold flip)', v_leaked;
  END IF;

  SELECT COUNT(DISTINCT geo_id) INTO v_surfaced_ok
  FROM _house
  WHERE st = 'TN'
    AND geo_id = ANY(ARRAY['4701', '4702', '4703', '4704', '4705', '4706', '4707', '4708', '4709'])
    AND race_election_id = tn_gen_eid;
  IF v_surfaced_ok <> 9 THEN
    RAISE EXCEPTION 'FAIL TN-SURFACING: expected all 9 TN districts wired to TN 2026 Statewide General, got %', v_surfaced_ok;
  END IF;
  RAISE NOTICE 'PASS TN-SURFACING: all 9 TN races (4701-4709) -> TN 2026 Statewide General (severe set un-withheld 2026-07-07 via mig 1247, G5200V26 polygons live)';

  -- ==========================================================================
  -- CRITERION 7 — AZ roster reconciliation: the 5 ballot-ineligible candidates
  --   (migration 1204) must NOT be active.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_az_ineligible_active
  FROM _house h
  WHERE h.st = 'AZ'
    AND h.external_id IN (-40108, -40201, -40402, -40503, -40602)
    AND h.candidate_status = 'active';
  IF v_az_ineligible_active <> 0 THEN
    RAISE EXCEPTION 'FAIL AZ-RECONCILE: % of the 5 ballot-ineligible AZ candidates (Ajluni/Descheenie/Davison/Bracht/Bah) are still active', v_az_ineligible_active;
  END IF;
  RAISE NOTICE 'PASS AZ-RECONCILE: all 5 ballot-ineligible AZ candidates (Ajluni -40108 / Descheenie -40201 / Davison -40402 / Bracht -40503 / Bah -40602) are NOT active (withdrawn, migration 1204)';

  -- ==========================================================================
  -- CRITERION 8 — MA: Clark (MA-5) and Pressley (MA-7) each have exactly ONE
  --   race_candidates row (no duplication onto the pre-existing races).
  -- ==========================================================================
  SELECT COUNT(*) INTO v_clark    FROM _house WHERE st = 'MA' AND geo_id = '2505' AND lower(full_name) = 'katherine clark';
  SELECT COUNT(*) INTO v_pressley FROM _house WHERE st = 'MA' AND geo_id = '2507' AND lower(full_name) = 'ayanna pressley';
  IF v_clark <> 1 THEN
    RAISE EXCEPTION 'FAIL MA-CLARK: expected exactly 1 Katherine Clark race_candidates row on MA-5, got %', v_clark;
  END IF;
  IF v_pressley <> 1 THEN
    RAISE EXCEPTION 'FAIL MA-PRESSLEY: expected exactly 1 Ayanna Pressley race_candidates row on MA-7, got %', v_pressley;
  END IF;
  RAISE NOTICE 'PASS MA-INCUMBENT-DEDUP: Clark (MA-5) and Pressley (MA-7) each have exactly 1 race_candidates row';

  -- ==========================================================================
  -- New-candidate (Phase-161 external_id band, ACTIVE only) working sets per state.
  --   AZ  -40901..-40101   WA  -531005..-530101   TN  -470910..-470101   MA  -250902..-250101
  -- ==========================================================================
  CREATE TEMP TABLE _new_cands ON COMMIT DROP AS
  SELECT DISTINCT h.st, h.politician_id, h.external_id
  FROM _house h
  WHERE h.candidate_status = 'active'
    AND ( (h.st = 'AZ' AND h.external_id BETWEEN -40901  AND -40101)
       OR (h.st = 'WA' AND h.external_id BETWEEN -531005 AND -530101)
       OR (h.st = 'TN' AND h.external_id BETWEEN -470910 AND -470101)
       OR (h.st = 'MA' AND h.external_id BETWEEN -250902 AND -250101) );

  -- ==========================================================================
  -- Whole-record stance honest-skip pins (_stance_skip, by politician_id resolved live
  --   from external_id -- exact UUID pin per the 143 lesson, ORDER BY politician_id).
  --   AZ 4 / WA 14 / TN 40 / MA 1 = 59 total. Full trails: 161-03/05/07/09/10-SUMMARY.md.
  -- ==========================================================================
  CREATE TEMP TABLE _stance_skip (politician_id uuid, external_id bigint, reason text) ON COMMIT DROP;
  INSERT INTO _stance_skip (politician_id, external_id, reason)
  SELECT p.id, p.external_id, v.reason
  FROM (VALUES
    -- AZ (161-03): 4 genuine evidence-gap skips (the 5 ballot-ineligible are excluded --
    -- they are no longer active, see CRITERION 7)
    (-40301::bigint, 'Alan Aversa AZ-3 -- no Candidate Connection survey, no site/socials beyond LinkedIn'),
    (-40405, 'John Fillmore AZ-4 -- no survey/site; only decade-old bill titles with no summaries'),
    (-40603, 'Jereme Peters AZ-6 -- no survey; Ballotpedia Contact section entirely absent'),
    (-40701, 'Daniel Butierez AZ-7 -- 2024 platform quoted by Ballotpedia is off-topic/too vague; live site failed to load'),
    -- WA (161-05): 14 whole-record skips
    (-531005, 'Chris D. Chung WA-10 -- no 2026 survey, parked GoDaddy site, 0 OpenFEC results'),
    (-531004, 'Derek Maynes WA-10 -- Ballotpedia content is a 2015 unrelated-office statement; no 2026 survey/site'),
    (-530901, 'Jacob Perasso WA-9 -- 2026 survey section exists with no submitted answers; no site'),
    (-530802, 'Spencer Meline WA-8 -- completed 2026 survey read in full, entirely generic bio, no chair match'),
    (-530703, 'Gwen Kirkland WA-7 -- no survey; only a walled LinkedIn link'),
    (-530701, 'David W. Blomstrom WA-7 -- extensive but incoherent/conspiratorial record, no usable federal-24 position'),
    (-530410, 'Elpidia Saavedra WA-4 -- no survey; only a walled Facebook link'),
    (-530405, 'Favian Valencia WA-4 -- site is marketing-level headlines only, no elaborating text'),
    (-530404, 'John C. Hughs WA-4 -- no survey; only a walled Facebook link'),
    (-530401, 'Jacek "Jack" Kobiesa WA-4 -- completed 2026 survey read in full, populist rhetoric, no chair match'),
    (-530307, 'Austin Braswell WA-3 -- no survey, no campaign website found'),
    (-530302, 'John P. Roco WA-3 -- IDENTITY RISK: Ballotpedia page dominated by an apparent 2016 Hawaii Senate run (cross-state homonym); no 2026 survey'),
    (-530105, 'Mary Silva WA-1 -- completed 2026 survey + 2024 statement read in full, entirely conspiratorial content, no chair match'),
    (-530103, 'James Etzkorn WA-1 -- completed 2026 survey read in full, detailed platform genuinely does not intersect any federal-24 topic'),
    -- TN (161-07 TN-1..5, 21 skips)
    (-470105, 'Richard G. Baker TN-1 -- bare Ballotpedia stub, no campaign website found'),
    (-470106, 'Chris Campbell TN-1 -- bare Ballotpedia stub, no campaign website found'),
    (-470107, 'Billy Cody TN-1 -- bare stub; Facebook page is slogan-only, no policy content'),
    (-470108, 'Tyler Brice Mitchell McClain TN-1 -- bare Ballotpedia stub, no campaign website found'),
    (-470302, 'Bryan Martin TN-3 -- bare Ballotpedia stub, no campaign website found'),
    (-470303, 'Dean Arnold TN-3 -- bare Ballotpedia stub, no campaign website found'),
    (-470305, 'Rodney Joe King TN-3 -- bare Ballotpedia stub, no campaign website found'),
    (-470307, 'Edward John Roland TN-3 -- bare Ballotpedia stub, no campaign website found'),
    (-470503, 'DeVante R. Hill TN-5 -- bare Ballotpedia stub, no campaign website found'),
    (-470507, 'James A. Johnson TN-5 -- bare Ballotpedia stub, no campaign website found'),
    (-470508, 'Micheal (Me-Haul) O''Leary TN-5 -- bare Ballotpedia stub, no campaign website found'),
    (-470202, 'Bruce Fine TN-2 -- survey + site checked, "fiscal responsibility"/debt concern with no specifics matching a chair'),
    (-470203, 'Adam Heimerman TN-2 -- survey checked, generic subsidy-redirection/due-process content, no chair match'),
    (-470306, 'Donnie Lynn Ownby TN-3 -- survey checked, term limits/education/foreign-aid generalities, no chair match'),
    (-470304, 'Jean Howard-Hill TN-3 -- only an incomplete 2024 survey; Facebook page has no policy content'),
    (-470401, 'Thomas E. Davis TN-4 -- survey checked, bare topic-name bullets with no elaboration matching a chair'),
    (-470403, 'Harold "Rocky" Jones TN-4 -- survey checked, term limits/insider-trading-ban content, none are federal-24 topics'),
    (-470405, 'Mike Cortese TN-4 -- site /issues 404s, /policies has only a donation page'),
    (-470410, 'Clay Faircloth TN-4 -- only a stale 2024 survey for a different district/party, context-mismatched'),
    (-470501, 'Charlie Hatcher TN-5 -- no 2026 survey; site is branding-only, no policy elaboration'),
    (-470502, 'Yolanda Cooper-Sutton TN-5 -- no 2026 survey; site content is generic, no specific mechanism'),
    -- TN (161-09 TN-6..9, 19 skips)
    (-470607, 'Christopher Martin Finley TN-6 -- bare Ballotpedia stub, no campaign website found'),
    (-470608, 'Miriam Leibowitz TN-6 -- bare Ballotpedia stub, no campaign website found'),
    (-470611, 'Angus Purdy TN-6 -- bare Ballotpedia stub, no campaign website found'),
    (-470705, 'Andrew J. Koontz TN-7 -- bare Ballotpedia stub, no campaign website found'),
    (-470706, 'Lowell Reynolds TN-7 -- 2026 survey checked, generic constitutional-accountability themes, no chair match'),
    (-470806, 'Wendell "Wells" Blankenship TN-8 -- bare Ballotpedia stub, no campaign website found'),
    (-470807, 'Antonio Futch TN-8 -- bare Ballotpedia stub, no campaign website found'),
    (-470810, 'Henry J. Ward, III TN-8 -- bare Ballotpedia stub (both slug variants), no campaign website found'),
    (-470910, 'Michelle Davis Head TN-9 -- bare Ballotpedia stub, BallotReady profile has no issue content'),
    (-470601, 'Natisha Brooks TN-6 -- 2020 survey (Senate run) + site content (2023 Mayor run) both context-mismatched'),
    (-470606, 'Mike Croley TN-6 -- 2025 survey checked, personal biography/values content, no chair match'),
    (-470701, 'Darden Copeland TN-7 -- 2025 survey checked, biography/term-limits content only, no chair match'),
    (-470703, 'Saletta Holloway TN-7 -- no 2026 survey; site /issues page empty/JS-blocked'),
    (-470803, 'Heidi Kuhn TN-8 -- 2026 survey checked, generic priority-list content; detailed content found is for a different race'),
    (-470804, 'Leonard Perkins TN-8 -- 2024+2026 surveys checked, bare topic-name lists with no elaboration'),
    (-470808, 'Pamela Jeanine "P." Moses TN-8 -- surveys focus on felon voting-rights restoration, no federal-24 chair addresses that specifically'),
    (-470809, 'Horace Taylor TN-8 -- 2026 survey checked, topic-label list only, no chair-matching direction'),
    (-470903, 'Jeremy Thompson TN-9 -- generic campaign-website content, no chair match'),
    (-470905, 'M. LaTroy A-Williams TN-9 -- local economic-development content across 3 cycles (2016-2026), no completed survey'),
    -- MA (161-10): 1 whole-record skip
    (-250902, 'R. Tyler MacAllister MA-9 -- 4 own-site pages + Ballotpedia (no survey) + local news all biography/single-word issue labels, no chair match')
  ) AS v(external_id, reason)
  JOIN essentials.politicians p ON p.external_id = v.external_id
  ORDER BY p.id;

  -- ==========================================================================
  -- Headshot honest-skip pins (_img_skip, by external_id, ORDER BY external_id -- the
  --   143 lesson). 167 total: AZ 24 (post-reconciliation) + WA 57 + TN 70 + MA 16.
  -- ==========================================================================
  CREATE TEMP TABLE _img_skip (external_id bigint) ON COMMIT DROP;
  INSERT INTO _img_skip (external_id) VALUES
    -- AZ (24, post-reconciliation; the 5 withdrawn ineligible candidates are excluded from
    -- this scope entirely by CRITERION 7's active filter, regardless of image status)
    (-40901),(-40802),(-40801),(-40701),(-40603),(-40601),(-40506),(-40505),(-40504),(-40502),
    (-40501),(-40404),(-40403),(-40401),(-40301),(-40203),(-40202),(-40110),(-40109),(-40107),
    (-40105),(-40104),(-40103),(-40102),
    -- WA (57)
    (-531005),(-531004),(-531003),(-531002),(-531001),(-530904),(-530903),(-530901),(-530805),
    (-530804),(-530803),(-530802),(-530801),(-530703),(-530702),(-530701),(-530604),(-530603),
    (-530602),(-530601),(-530511),(-530510),(-530509),(-530508),(-530507),(-530506),(-530505),
    (-530504),(-530503),(-530502),(-530501),(-530410),(-530409),(-530408),(-530407),(-530406),
    (-530405),(-530404),(-530403),(-530402),(-530401),(-530308),(-530307),(-530306),(-530304),
    (-530303),(-530302),(-530301),(-530203),(-530202),(-530201),(-530106),(-530105),(-530104),
    (-530103),(-530102),(-530101),
    -- TN (70)
    (-470910),(-470909),(-470908),(-470905),(-470904),(-470903),(-470902),(-470901),(-470810),
    (-470809),(-470808),(-470807),(-470806),(-470805),(-470804),(-470803),(-470802),(-470801),
    (-470706),(-470705),(-470704),(-470703),(-470701),(-470611),(-470610),(-470609),(-470608),
    (-470607),(-470606),(-470605),(-470604),(-470603),(-470602),(-470601),(-470508),(-470507),
    (-470506),(-470505),(-470504),(-470503),(-470502),(-470501),(-470410),(-470409),(-470408),
    (-470407),(-470406),(-470405),(-470404),(-470403),(-470402),(-470401),(-470307),(-470306),
    (-470305),(-470304),(-470303),(-470302),(-470301),(-470203),(-470202),(-470201),(-470108),
    (-470107),(-470106),(-470105),(-470104),(-470103),(-470102),(-470101),
    -- MA (16)
    (-250902),(-250901),(-250802),(-250801),(-250607),(-250605),(-250603),(-250602),(-250601),
    (-250502),(-250501),(-250402),(-250401),(-250301),(-250102),(-250101);

  -- ==========================================================================
  -- USHC3-04 — every active new candidate has a politician_images row, except pinned skips.
  -- ==========================================================================
  SELECT COUNT(*),
         string_agg(nc.st || ':' || nc.external_id, ', ' ORDER BY nc.external_id)
    INTO v_no_image, v_image_detail
  FROM _new_cands nc
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = nc.politician_id
  )
  AND nc.external_id NOT IN (SELECT external_id FROM _img_skip);
  IF v_no_image <> 0 THEN
    RAISE EXCEPTION 'FAIL HEADSHOT: % active new AZ/WA/TN/MA candidate(s) lack a politician_images row and are not pinned: %', v_no_image, v_image_detail;
  END IF;
  RAISE NOTICE 'PASS HEADSHOT: every active new AZ/WA/TN/MA candidate has a politician_images row or a pinned honest-skip (167 pinned)';

  -- ==========================================================================
  -- USHC3-05a — 0 unsourced stance rows for the in-scope (new-candidate) set.
  -- ==========================================================================
  SELECT COUNT(*) INTO v_unsourced
  FROM inform.politician_answers a
  JOIN _new_cands nc ON nc.politician_id = a.politician_id
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id
      AND c.topic_id = a.topic_id
      AND c.sources IS NOT NULL
      AND array_length(c.sources, 1) >= 1
  );
  IF v_unsourced <> 0 THEN
    RAISE EXCEPTION 'FAIL UNSOURCED: % unsourced stance row(s) in the in-scope AZ/WA/TN/MA new-candidate set', v_unsourced;
  END IF;
  RAISE NOTICE 'PASS UNSOURCED: 0 unsourced stance rows for the in-scope AZ/WA/TN/MA new-candidate set';

  -- ==========================================================================
  -- USHC3-05b — every in-scope new candidate has >=1 sourced federal stance OR is a
  --   pinned whole-record honest-skip (chairs-not-polarity; no full-24 coverage required).
  -- ==========================================================================
  SELECT COUNT(*),
         string_agg(x.who, ', ' ORDER BY x.politician_id)
    INTO v_uncovered, v_cov_detail
  FROM (
    SELECT nc.politician_id,
           nc.st || ':' || nc.external_id AS who,
           (SELECT COUNT(*) FROM inform.politician_answers a WHERE a.politician_id = nc.politician_id) AS ans_count
    FROM _new_cands nc
    WHERE nc.politician_id NOT IN (SELECT politician_id FROM _stance_skip)
  ) x
  WHERE x.ans_count < 1;
  IF v_uncovered <> 0 THEN
    RAISE EXCEPTION 'FAIL COVERAGE: % in-scope candidate(s) have 0 stances and are not pinned as whole-record honest-skip: %', v_uncovered, v_cov_detail;
  END IF;
  RAISE NOTICE 'PASS COVERAGE: every in-scope AZ/WA/TN/MA new candidate has >=1 sourced stance or is a pinned whole-record honest-skip (59 pinned)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED (USHC3-02/03/04/05, 37 districts: AZ 9 / WA 10 / TN 9 / MA 9, all 9 TN districts surfacing post-164.1 un-withhold)';
END $$;
